% --- wrapper function for the range function
function y = rangewr(x,dim)

try 
    if exist('dim','var')
        y = range(x,dim);
    else
        y = range(x);
    end
catch
    if exist('dim','var')
        y = max(x,[],dim) - min(x,[],dim);
    else
        y = max(x) - min(x);        
    end
end