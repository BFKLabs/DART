% --- tracks a single fly for a given sub-region 
function [fPosF,IRmx,iGrpF] = segSingleSubRegion(IRT,fPosPr0,dTol,Nsz)

% 
if ~exist('Nsz','var'); Nsz = 100; end

% parameters
ndTol = 3;
prTol = 1.25;
nFrmPr = 5;

% memory allocation
[nFrm,szL,hZ] = deal(length(IRT),size(IRT{1}),3/2);
[fPosF,iGrpF,IRmx] = deal(NaN(nFrm,2),cell(nFrm,1),NaN(nFrm,1));

% thresholds the image for each frame
BwG = cellfun(@(x)(imregionalmax(x)),IRT,'un',0);
% IRTmx = cellfun(@(x)(max(x(:))),IRT,'un',0);

% thresholds the groups
pTolT = cellfun(@(x)(getNthSortedValue(x(:),Nsz)),IRT,'un',0);
iGrp = cellfun(@(B,x,pT)(getGroupIndex...
                (B.*bwmorph(x>=pT,'majority'))),BwG,IRT,pTolT,'un',0);

%
for iFrm = 1:nFrm
    % retrieves the previous frame coordinate array and from this
    % extrapolates the blobs location
    fPosPr = getPrevFramePos(fPosPr0,fPosF,iFrm,nFrmPr);    
    fPosEx = extrapBlobPos(fPosPr);    
    
    % determines the location of the blob on the current frame  
    if isempty(iGrp{iFrm})
        % if there are no thresholded images, then use the location from
        % the previous frame (only if not empty)
        if ~isempty(fPosPr)
            fPosF(iFrm,:) = fPosPr(end,:);
        end        
    else
        % calculates the location of the blobs from the current frame
        iGrpFrm0 = cell2cell(iGrp{iFrm});
        [iGrpFrm,fP] = getFramePoints(IRT{iFrm},iGrpFrm0,szL,dTol/2);        
        
        %
        if isnan(fPosEx(1))
            % if there is no valid extrapolation estimate, then use the
            % blob group with the highest residual
            imx = argMax(IRT{iFrm}(iGrpFrm));
            
            % updates the data for the current frame
            fPosF(iFrm,:) = fP(imx,:);
            iGrpF{iFrm} = iGrpFrm(imx);
            IRmx(iFrm) = IRT{iFrm}(iGrpF{iFrm});
            
        else
            % otherwise, calculate the distance between the extrapolated
            % coordinates and the blobs on the current frame
            DpEx = pdist2(fPosEx,fP)';
            Z = ((IRT{iFrm}(iGrpFrm)/pTolT{iFrm}).^hZ)./(1+(DpEx/dTol)).^2;            
            [~,imx] = max(Z);

            % updates the blob indices/residual value for the frame
            iGrpF{iFrm} = iGrpFrm(imx);
            IRmx(iFrm) = IRT{iFrm}(iGrpF{iFrm});

            % updates the blob location for the frame
            Dmn = DpEx(imx);
            if Dmn < dTol
                % if the closest blob is within tolerance, then update the
                % information for the frame
                fPosF(iFrm,:) = fP(imx,:);
            else
                % if the blob has moved significantly (i.e., a "jump") then
                % determine if the object residual is signficant to warrant
                % the jump in location 
                if (IRmx(iFrm)/pTolT{iFrm} > prTol) && (Dmn/dTol <= ndTol)
                    % if the residual is high enough (and the distance is
                    % not too extreme) then accept the jump in location
                    fPosF(iFrm,:) = fP(imx,:);
                else
                    % otherwise, use the previous frame coordinates
                    fPosF(iFrm,:) = fPosPr(end,:);
                end
            end
        end
    end
end

% --- extrapolates the blob position from the previous points
function fPosNw = extrapBlobPos(fPosPr)

if size(fPosPr,1) <= 1
    % if there are insufficient previous points then return NaNs
    fPosNw = NaN(1,2);
else
    % otherwise, return the extrapolated values
    nP = min(size(fPosPr,1),5);    
    fPosPr = fPosPr((end-(nP-1)):end,:);
    fPosNw = [extrapSignal(fPosPr(:,1)),extrapSignal(fPosPr(:,2))];
end

% --- extrapolates the signal
function xExt = extrapSignal(x)

% determines the range of the signal values
isN = isnan(x);
if all(isN)
    % if all the values are NaN's then return a NaN value
    xExt = NaN;
    
elseif range(x) == 0
    % if the range is zero, return the first value
    xExt = x(1);
else
    % otherwise, set up the extrapolation filter
    x = x(~isN);
    a = arburg(x,length(x)-1);
    [~, zf] = filter(-[0 a(2:end)], 1, x);

    % calculates the extrapolated signal value
    xExt = filter([0 0], -a, 0, zf);
end

% --- retrieves the previous frame positions 
function fPosPr = getPrevFramePos(fPosPr0,fPosF,iFrm,nFrm)

% stack size
nFrm = max(nFrm,size(fPosPr0,1));

% 
[xi1,xi2] = deal(iFrm:size(fPosPr0,1),max(1,iFrm-nFrm):iFrm-1);
fPosPr = [fPosPr0(xi1,:);fPosF(xi2,:)];

% --- retrieves the n-th sorted value from the array, I
function p = getNthSortedValue(I,N)

if isempty(I)
    p = 0;
else                        
    Is = sort(I(:),'descend');
    p = Is(min(numel(I),N));
end

% --- retrieves the points from the current frame (reduces any points that
%     are close to others on the frame)
function [iGrp,fP] = getFramePoints(IR,iGrp,szL,dTol)

% determines the 
[yP,xP] = ind2sub(szL,iGrp);
fP = [xP(:),yP(:)]; 

%
if size(fP,1) > 1
    % calculates the distance between the points
    Dp = pdist2(fP,fP);
    Dp(tril(Dp)==0) = dTol;
    
    % if any points are too close to each other, then use the point with
    % the highest residual
    isClose = Dp < dTol;
    if any(isClose(:))
        jGrp = [];
        [i1,i2] = find(isClose);
        
        % 
        for i = 1:length(i1)
            if isempty(jGrp)
                jGrp = {[i1(i),i2(i)]};
            else
                % otherwise, determine the index 
                j1 = cellfun(@(x)(any(x==i1(i))),jGrp);
                j2 = cellfun(@(x)(any(x==i2(i))),jGrp);
                
                %
                if ~any(j1)
                    if any(j2)
                        jGrp{j2}(end+1) = i1(i);
                    else
                        jGrp{end+1} = [i1(i),i2(i)];
                    end
                elseif ~any(j2)
                    if any(j1)
                        jGrp{j1}(end+1) = i2(i);
                    else
                        jGrp{end+1} = [i1(i),i2(i)];
                    end
                end
            end
        end
        
        % from the groupings, reduce the points down to the point with the
        % highest pixel intesity
        isKeep = true(length(iGrp),1);
        for i = 1:length(jGrp)
            isKeep(jGrp{i}) = false;
            isKeep(jGrp{i}(argMax(IR(iGrp(jGrp{i}))))) = true;
        end
        
        % reduces down the arrays to the required values
        [iGrp,fP] = deal(iGrp(isKeep),fP(isKeep,:));
    end
end
