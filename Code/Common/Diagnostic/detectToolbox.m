% --- determines if the toolbox, tbName, is installed
function hasTB = detectToolbox(tbName)

A = ver;
hasTB = any(strcmp({A.Name},tbName));