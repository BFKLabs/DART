% --- function that set the auto resize column flag
function autoResizeTableColumns(hTable)

% global variables
global HWT

% retrieves the table java object and sets the resize flag
jTable = getJavaTable(hTable);
jTable.setAutoResizeMode(jTable.AUTO_RESIZE_ALL_COLUMNS);

% sets the row heights to the original
jTable.setRowHeight(HWT);
jTable.repaint();