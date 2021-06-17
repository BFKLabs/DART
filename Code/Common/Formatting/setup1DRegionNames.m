% --- creates the 1D region names
function rName = setup1DRegionNames(pInfo,Type)

% sets the 1D region names
[nR,nC] = deal(pInfo.nRow,pInfo.nCol);

% sets the region names
switch Type
    case 1
        rName = cell2cell(arrayfun(@(x)(arrayfun(@(y)(sprintf...
               ('Row %i/Column %i',x,y)),(1:nC)','un',0)),(1:nR)','un',0));
            
    case 2        
        rName = cell2cell(arrayfun(@(x)(arrayfun(@(y)(sprintf...
               ('Row %i/Col %i',x,y)),(1:nC)','un',0)),(1:nR)','un',0));    
            
    case 3
        rName = cell2cell(arrayfun(@(x)(arrayfun(@(y)(sprintf...
               ('R%i/C%i',x,y)),(1:nC)','un',0)),(1:nR)','un',0));           
        
end