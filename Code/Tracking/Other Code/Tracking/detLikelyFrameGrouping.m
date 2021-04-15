% --- determines the likely frame groupings
function fPos = detLikelyFrameGrouping(Isub0,dImgQ,iGrp,fPos0)

% parameters and initialisations
xcTol = 0.825;
fPos = [];
fPosT = cell2cell(fPos0);
[nImg,nFrm] = deal(length(Isub0),length(dImgQ));

% memory allocation
Ixc = NaN(nImg);
iBest = zeros(nFrm,nImg);

% calculates the maximum correlation value for all likely points on each of
% the frames from the image stack
for i = 1:nFrm
    % sets the indices of the points not within the current frame
    ii = cell2mat(iGrp((1:nFrm)~=i)');  
    
    % calculates the max cross-correlations values between the current 
    % object and the objects on all other frames
    for j = 1:length(iGrp{i})
        k = iGrp{i}(j);
        Ixc(ii,k) = cellfun(@(x)(calcMaxCorr(x,Isub0{k})),Isub0(ii));
    end
end

% calculates the overall objective function values (cross-correlation
% multiplied by the residual value at the maxima point)
Imx = cellfun(@(I,x)(I(sub2ind(size(I),x(:,2),x(:,1)))),dImgQ,fPos0,'un',0);
Zxc = Ixc.*repmat(cell2mat(Imx),1,nImg);

% determines the best frame groupings for all objects (over all frames)
for j = 1:nImg
    for i = 1:nFrm
        if any(j == iGrp{i})
            % current object exists on this frame
            iBest(i,j) = j;
        else
            % otherwise, determine the objects on this frame that have the
            % highest object function value
            iMx = argMax(Zxc(iGrp{i},j));
            iBest(i,j) = iGrp{i}(iMx);
        end
    end
end

% determines the unique groupings from the best matches
[iBestU,~,iC] = unique(iBest','rows');
indC = arrayfun(@(x)(find(iC==x)),1:max(iC),'un',0);

% calculates the cross-correlation/object function
IxcGC = calcGroupingMetrics(Ixc,iBest,indC);
ZxcGC = calcGroupingMetrics(Zxc,iBest,indC);
iMx = argMax(ZxcGC);
jMx = argMax(IxcGC);

% if the xcorr value of the best solution is below tolerance, then exit
% the function
if IxcGC(iMx) > xcTol
    fPos = fPosT(iBestU(iMx,:),:);
end

% --- calculates the metric values for the specified indices, incC
function IGC = calcGroupingMetrics(I,iBest,indC)

IG = cellfun(@(x,y)(x(y)),num2cell(I,1),num2cell(iBest,1),'un',0);
IGC = cellfun(@(x)(nanmean(nanmax(cell2mat(IG(x)),[],2))),indC);

% --- calculates the max correlation values between the images I1 & I2
function IxcMx = calcMaxCorr(I1,I2)

Ixc = normxcorr2(I1,I2);
IxcMx = max(Ixc(:));
