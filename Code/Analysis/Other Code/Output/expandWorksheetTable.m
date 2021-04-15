% --- ensures a minimum size of the worksheet table
function Data = expandWorksheetTable(Data)

% minimum row/column count
[rMin,cMin] = deal(50,26);

% ensures the table has a minimum size
[rSz,cSz] = size(Data);
if (rSz < rMin); [Data,rSz] = deal([Data;repmat({''},rMin-rSz,cSz)],rMin); end
if (cSz < cMin); Data = [Data,repmat({''},rSz,cMin-cSz)]; end