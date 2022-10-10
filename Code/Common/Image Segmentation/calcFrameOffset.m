% --- calculates the frame translation offset for the frame indices, iFrm
function pOfsT = calcFrameOffset(phInfo,iFrmR,iAppR)

% sets the default input arguments
if ~exist('iAppR','var'); iAppR = 1:length(phInfo.pOfs); end

if max(iAppR) <= length(phInfo.hasT)
    hasT = phInfo.hasT;
else
    hasT = false(max(iAppR),1);
end   

% memory allocation
pOfsT = zeros(length(iAppR),2);

% field retrieval
for i = 1:length(iAppR)
    if hasT(iAppR(i))
        p = phInfo.pOfs{iAppR(i)};
        pOfsT(i,:) = interp1(phInfo.iFrm0,p,iFrmR,'linear','extrap');
    end
end
