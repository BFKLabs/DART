% --- retrieves the tab group position (based on the surroundin panel)
function tabPosD = getTabPosVector(hPanel,dPos)

% retrieves the panel position vector
pPos = get(hPanel,'Position');

% sets the tab position vector
tabPosD = [[9 10],pPos(3:4)-[20 18]];
if nargin == 2; tabPosD = tabPosD - dPos; end