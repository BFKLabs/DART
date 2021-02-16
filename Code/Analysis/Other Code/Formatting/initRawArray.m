% --- initialises the raw data array(s) for the analysis calculations
function plotD = initRawArray(plotD,Y,pStr)

% initialises the arrays for each of the 
for i = 1:length(pStr)
    for j = 1:length(plotD)
        % retrieves the array for the current group
        pStrNw = sprintf('plotD(j).%s',pStr{i});
        Ynw = eval(pStrNw);        
        
        % resets the array
        Ynw(:) = {Y};
        eval(sprintf('plotD(j).%s = Ynw;',pStr{i}));
    end
end