% --- horizontally aligns the data within a table
function setHorizAlignedTable(hTable,tData0)

% if there is no data, then reset the table and exit the function
if isempty(tData0)
    set(hTable,'Data',[]);
    return
end

% ensures all numeric values have been converted to strings
ii = cellfun(@isnumeric,tData0);
tData0(ii) = cellfun(@num2str,tData0(ii),'un',0);

% sets up the html prefix strings for each cell
cWid = getTableColumnWidths(hTable);
hStr = repmat(arrayfun(@(x)(sprintf(...
                '<html><tr align=center><td width=%d>',x)),...
                cWid,'un',0),size(tData0,1),1);   
            
% converts the strings to html-strings
tData = cellfun(@(x,y)(sprintf('%s%s',x,y)),hStr,tData0,'un',0); 

% updates the table data
set(hTable,'Data',tData);