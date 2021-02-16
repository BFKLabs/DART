% --- returns the actual column widths (from the uitable java object)
function cWid = getTableColumnWidths(hTable)

% retrieves the tables underlying java object handles
jVP = findjobj(hTable);
jTable = jVP.getViewport.getView;

% memory allocation
nCol = jTable.getColumnCount;
cWid = zeros(1,nCol);

% retrieves the widths for each column
for i = 1:nCol
    cWid(i) = jTable.getColumnModel.getColumn(i-1).getWidth;
end