% --- returns the index of the minimum argument from a vector x
function imx = argMax(x,varargin)

if (isnan(x))
    imx = NaN;
else
    [~,imx] = nanmax(x);
    if ((nargin == 2) && (length(imx) > 1))
        imx = imx(1); 
    end
end
