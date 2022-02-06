% --- calculates the frame translation offset for the frame indices, iFrm
function pOfsT = calcFrameOffset(phInfo,iFrmR,iAppR)

% sets the default input arguments
if ~exist('iAppR','var'); iAppR = 1:length(phInfo.pOfs); end

% memory allocation
pOfsT = zeros(length(phInfo.pOfs),2);

% field retrieval
for iApp = iAppR(:)'
    if phInfo.hasT(iApp)
        p = phInfo.pOfs{iApp};
        pOfsT(iApp,:) = interp1(phInfo.iFrm0,p,iFrmR,'linear','extrap');
    end
end
