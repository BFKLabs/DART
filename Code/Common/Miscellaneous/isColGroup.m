% --- determines if the tube regions are grouped by column or rows
function isCol = isColGroup(iMov)

isCol = iscell(iMov.iCT{1});