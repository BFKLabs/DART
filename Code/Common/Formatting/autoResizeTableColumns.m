% --- function that set the auto resize column flag
function varargout = autoResizeTableColumns(hObj)

% global variables
global HWT

% retrieves the table java object and sets the resize flag
if isa(hObj,'javax.swing.JTable')
    jTable = hObj;
else
    jTable = getJavaTable(hObj);
    jTable.setAutoResizeMode(jTable.AUTO_RESIZE_ALL_COLUMNS);
end

% sets the row heights to the original
jTable.setRowHeight(HWT);
jTable.repaint();

% sets the output arguments (if required)
if nargout == 1
    varargout = {jTable};
end