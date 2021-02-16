% --- horizontally aligns the data within a table
function setHorizAlignedTable(hTable,tData0)

% sets up the html prefix strings for each cell
cWid = getTableColumnWidths(hTable);
hStr = repmat(arrayfun(@(x)(sprintf(...
                '<html><tr align=center><td width=%d>',x)),...
                cWid,'un',0),size(tData0,1),1);   
            
% converts the strings to html-strings
tData = cellfun(@(x,y)(sprintf('%s%s',x,y)),hStr,tData0,'un',0); 

% updates the table data
set(hTable,'Data',tData);