% --- resets the width of a vertically orientated legend
function lgP = resetVertLegendWidth(hLg,lgP)

% retrieves the legend position (if not provided)
pW = 0.97;
if (nargin == 1); lgP = get(hLg,'position'); end

% retrieves the extents of the legend text objects
if (isHG1)
    hText = findall(hLg,'type','text');
    hText = hText(~cellfun(@isempty,get(hText,'string')));
else
    return
end

% retrieves the position of the text
hPosT = get(hText,'extent');    
if (iscell(hPosT)); hPosT = cell2mat(hPosT); end
hPosT = hPosT(all(hPosT(:,3:4) < 1,2),:);

% resets the width of the legend object
Wmax = max(sum(hPosT(:,[1 3]),2));
dW = max(0,pW-Wmax);
lgP(3) = (1-dW)*lgP(3);

% resets the legend position 
if (nargin == 1); set(hLg,'position',lgP); end
