% --- removes the selection from the table, hTable
function removeTableSelection(hTable)

% removes the selection highlight
jScroll = findjobj(hTable);
jTable = jScroll.getComponent(0).getComponent(0);
jTable.changeSelection(-1,-1,false,false);