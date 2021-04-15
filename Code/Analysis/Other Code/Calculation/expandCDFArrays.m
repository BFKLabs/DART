% --- expands the cumulative distribution arrays 
function [xF,fF] = expandCDFArrays(xCDF,fCDF)

% determines the CDF array that has the greatest length
[~,imx] = max(cellfun(@(x)(x(end)),xCDF));
nMax = ceil(xCDF{imx}(end));

% memory allocation
[xF,fF] = deal((0:nMax)',zeros(nMax+1,length(xCDF)));

% expansion of the f-values
for i = 1:length(xCDF)
    xi = 0:ceil(xCDF{i}(end));
    fF(xi+1,i) = max(0,interp1(xCDF{i},fCDF{i},xi,'linear','extrap'));
end

