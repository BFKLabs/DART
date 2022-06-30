% --- resets the y-axis scale of a bar plot
function resetYAxisScale(hAx,Y,Ymx)

% parameters
[maxAxR,nTick] = deal(50,6);

% determines if the values are of roughly the same order
if max(Y(:),[],'omitnan')/median(Y(:),'omitnan') > maxAxR
    % if not, then use a log scale
    set(hAx,'yscale','log');
else            
    % otherwise, set a standard axis scale
    if nargin == 2
        setStandardYAxis(hAx,Y,nTick);         
    else
        setStandardYAxis(hAx,Y,nTick,Ymx);         
    end
end