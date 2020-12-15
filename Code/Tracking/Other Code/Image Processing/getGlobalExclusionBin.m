% --- 
function BwT = getGlobalExclusionBin(iMov)

% sets up the global exclusion mask
hAx = findall(findall(0,'tag','figFlyTrack'),'type','axes');

%
BwT = false(size(get(findall(hAx,'type','image'),'cdata')));
for i = 1:length(iMov.iR)
    % 
    szL = [length(iMov.iR{i}),length(iMov.iC{i})];
    
    %
    BwG = getExclusionBin(iMov,szL,i);
    BwT(iMov.iR{i},iMov.iC{i}) = BwT(iMov.iR{i},iMov.iC{i}) + BwG;
end