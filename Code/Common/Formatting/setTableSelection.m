% --- removes the selection from the table, hTable
function setTableSelection(hTable,iRow,iCol)

% removes the selection highlight
jScroll = findjobj(hTable);
jTable = jScroll.getComponent(0).getComponent(0);
jTable.changeSelection(iRow,iCol,false,false);