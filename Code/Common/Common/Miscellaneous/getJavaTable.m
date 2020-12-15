% --- initialises the table java objects
function jTable = getJavaTable(hTable)

% initialisations
[iter,iterMx,jTable] = deal(1,10,[]);

% sets the table java object into the table handle
while (iter <= iterMx)
    try
        h = findjobj(hTable);
        jTable = h.getComponent(0).getComponent(0);
        return
    catch 
        pause(0.05);
        iter = iter + 1;
    end
end
        