% --- retrieves the tab group position (based on the surroundin panel)
function tabPosD = getTabPosVector(hPanel,dPos)

% retrieves the panel position vector
pPos = get(hPanel,'Position');

% sets the tab position vector
tabPosD = [[3 5]+(~isHG1)*[6 5],pPos(3:4)-([10 8]+10*(~isHG1))];
if nargin == 2; tabPosD = tabPosD - dPos; end