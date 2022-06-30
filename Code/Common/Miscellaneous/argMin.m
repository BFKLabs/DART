% --- returns the index of the minimum argument from a vector x
function imn = argMin(x,varargin)

if isnan(x)
    imn = NaN;
else
    [~,imn] = min(x,[],'omitnan');
    if (nargin == 2) && (length(imn) > 1)
        imn = imn(1); 
    end
end
