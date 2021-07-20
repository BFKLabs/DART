% --- retrieves the selected row/column indices from the table, hTable
function [iRow,iCol] = getTableCellSelection(hTable)

% retrieves the table java object
jScroll = findjobj(hTable);
jTable = jScroll.getViewport.getView;

% retrieves the selected row/column indices
[iRow,iCol] = deal(jTable.getSelectedRow+1,jTable.getSelectedColumn+1);