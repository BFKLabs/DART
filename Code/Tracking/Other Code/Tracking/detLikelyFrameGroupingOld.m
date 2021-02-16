function fPos = detLikelyFrameGrouping(Isub0,ImgL,fPos0,iGrp,jGrp)

% parameters
dTol = 5;
pW = 0.75;
xcTol = 0.65;
sz = size(ImgL{1});
szL = size(Isub0{1});
nFrm = length(iGrp);
[fPos,iMatch] = deal([]);

% determines the mean position of the objects within each group
fPosT = cell2mat(fPos0);
fPosG = cell2mat(cellfun(@(x)...
                        (roundP(nanmean(fPosT(x,:),1))),jGrp(:),'un',0));
                    
% determines if there is significant movement over all frames
if all(range(fPosG,1) < dTol)
    % if not, then flag the object is stationary and exit the function
    return
else
    % calculates the distance between the point groups
    D = pdist2(fPosG,fPosG);
    IGrpMn = cellfun(@(x)(calcImageStackFcn(Isub0(x))),jGrp,'un',0);
end

% calculates the max residual values for each grouping
BR = bwmorph(setGroup(floor(szL/2)+1,szL),'dilate');
IGrpR = cellfun(@(I)(max(I(BR))),IGrpMn);

% sets up the frame/group mapping index array
Imap = zeros(nFrm,length(jGrp)); 
for i = 1:length(jGrp)
    Imap(getFrameMatch(iGrp,jGrp{i}),i) = i; 
end

%

% % determines if any frames uniquely map to a single object
% isUniq = sum(Imap>0,2) == 1;
% if ~any(isUniq)
% determines all the likely groupings
ind0 = find(Imap(1,:)); 
indG = cell2mat(cellfun(@(x)([find(x,1,'first'),...
                        find(x,1,'last')]),num2cell(Imap,1)','un',0));    

% determines the feasible groupings over all frames
kGrp = cell(1,length(ind0));
for i = 1:length(ind0)
    kGrp{i} = findFeasFrameGroupings(indG,i,size(Imap,1));
end

% combines all groupings into a single array
kGrp = cell2mat(kGrp);
if isempty(kGrp)
    % if there are no valid groupings then exit
    return
end

% determines the unique groupings and frame/group mapping arrays
kGrpT = cellfun(@(x)(unique(x)),num2cell(kGrp,1),'un',0);
iGrpT = cellfun(@(x)(cell2mat(jGrp(x))'),kGrpT,'un',0);

% calculates the cross-correlation/residual values at the maxima points
IGrpMnR = cellfun(@(x)(calcImageStackFcn(Isub0(x))),kGrpT,'un',0);
ZGrpXC = cellfun(@(I,x)(mean(cellfun(@(y)...
            (max(max(normxcorr2(y,I)))),Isub0(x)))),IGrpMnR,kGrpT);
IGrpMnRT = cellfun(@(x)(mean(IGrpR(x))),kGrpT);   

% sets the frame indices of the reference/candidate groups
iMx = argMax(IGrpMnRT(:).*ZGrpXC(:));
if ZGrpXC(iMx) < xcTol
    % if the correlation value for the best grouping is too low then exit
    return
end

% calculates an initial estimate of the background
ImgTmp = cellfun(@(x,y)(setTempBGImage(x,y)),ImgL(:),...
                    num2cell(fPosT(iGrpT{iMx},:),2),'un',0);
Ibg0 = calcInterpolatedImage(calcImageStackFcn(ImgTmp));       

% calculates the background subtracted images
IR = cellfun(@(x)(max(0,x-Ibg0)),ImgL,'un',0);

%
[reCalc,iMatch] = deal(false(nFrm,1),NaN(nFrm,1));
[fPos,BGrp] = deal(NaN(nFrm,2),cell(nFrm,1));
for i = 1:nFrm
    % thresholds the image for the most likely groups
    BGrp{i} = IR{i}>pW*max(IR{i}(:));
    iGrpB = getGroupIndex(BGrp{i});
    iP = sub2ind(sz,fPosT(iGrp{i},2),fPosT(iGrp{i},1));    
    
    if length(iGrpB) > 1
        % if more than one binary group was thresholded, then determine the
        % most likely group 
        isThresh = BGrp{i}(iP);
        if sum(isThresh) == 1
            iMatch(i) = iGrp{i}(isThresh);
            fPos(i,:) = fPosT(iGrp{i}(isThresh),:);
        else
            % flag that a recalculation is necessary
            reCalc(i) = true;
        end
        
    else    
        %
        isThresh = BGrp{i}(iP);
        if ~any(isThresh)
            % the thresholded residual does not contain of the candidate points
            % so the point must be new
            iMx = argMax(IR{i}(:).*BGrp{i}(:));
            [fPos(i,2),fPos(i,1)] = ind2sub(sz,iMx);
            
        else
            % if more than one candidate coordinate has been thresholded, then
            % remove the ambiguous point(s)
            if sum(isThresh) > 1
                ii = find(isThresh);
                isThresh = setGroup(ii(argMax(IR{i}(iP(ii)))),size(iP));
            end

            % sets the position into the final array
            iMatch(i) = iGrp{i}(isThresh);
            fPos(i,:) = fPosT(iGrp{i}(isThresh),:);
        end
    end
end

% determines if any ambiguities need to be resolved
if all(isnan(iMatch))    
    %
    fPos = [];
    
elseif any(reCalc)
    %
    for i = find(reCalc(:)')
        I = Isub0(iMatch(~isnan(iMatch)));
        Ixc = cellfun(@(x)(nanmean(cellfun(@(y)...
                    (max(max(normxcorr2(y,x)))),I))),Isub0(iGrp{i}));
        
        iMx = argMax(Ixc);
        fPos(i,:) = fPosT(iGrp{i}(iMx),:);
        iMatch(i) = iGrp{i}(iMx);
    end
end

% --- calculates the temporary background image
function ImgL = setTempBGImage(ImgL,fPos)

% parameters
pW = 0.5;
nDil = 2;

%
iPos = sub2ind(size(ImgL),fPos(:,2),fPos(:,1));
Brmv0 = ImgL > pW*ImgL(iPos);
[~,Brmv] = detGroupOverlap(Brmv0,fPos);

% removes the region surrounding the object
ImgL(bwmorph(Brmv,'dilate',nDil)) = NaN;

% --- 
function iFrm = getFrameMatch(iGrp,iObj)

if length(iObj) > 1
    iFrm = arrayfun(@(x)(getFrameMatch(iGrp,x)),iObj);
else
    iFrm = find(cellfun(@(y)(any(y==iObj)),iGrp));
end

function kGrp = findFeasFrameGroupings(indG,iNw,nFrm,kGrp)

% memory allocation
if nargin < 4
    kGrp = {zeros(nFrm,1)};
end

%
kGrp{1}(indG(iNw,1):indG(iNw,2)) = iNw;
if indG(iNw,2) == nFrm
    % if the new group encompasses the last frame then exit
    return
else
    iM = find(indG(:,1) == (indG(iNw,2)+1));
end

if isempty(iM)    
    kGrp{1}(:) = NaN;
else
    % for each potential grouping, determine if there is a feasible group
    kGrp = repmat(kGrp,1,length(iM));
    for i = 1:length(iM)
        kGrp(i) = findFeasFrameGroupings(indG,iM(i),nFrm,kGrp(i));
    end
    
    % removes any infeasible groupings
    kGrp = {cell2mat(kGrp(~cellfun(@isempty,kGrp)))};
end

% 
if nargin < 4
    kGrp = cell2mat(kGrp);
    kGrp = kGrp(:,~all(isnan(kGrp),1));
end

%
function Ip = getPointValue(I,fPosT,jGrp)

%
pMn = roundP(nanmean(fPosT(jGrp,:),1));
Ip = I(sub2ind(size(I),pMn(2),pMn(1)));