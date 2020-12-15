% --- retrieves the java table dimensions for the header width/height and
%     the height of the normal table cells
function [H0,HW,W0] = getTableDimensions(jObjT)

% retrieves the table column header height
jTable = jObjT.getComponent(0).getComponent(0);  
Height = jTable.getTableHeader.getPreferredSize.getHeight();
H0 = Height + 2;

% retrieves the table cell height
try
    RowH = get(get(jTable,'RowHeights'),'RowHeights');
    HW = double(RowH(1));
catch
    HW = floor((jTable.getMinimumSize.height - Height)/3);        
end

% retrieves the table row header width
try
    rowHeaderViewport = jObjT.getComponent(4);
    rowHeader = rowHeaderViewport.getComponent(0);
    W0 = double(get(rowHeader,'Width') + 2);
catch
    W0 = 0;
end