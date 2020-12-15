% --- 
function isInAx = detLegAxPos(hP,hAx,hLg)

% retrieves the panel position
set(hP,'Units','Pixel'); 
pP = get(hP,'position');
set(hP,'Units','Normalized'); 

% retrieves the axis/legend positions
[axP,lgP] = deal(get(hAx,'position'),get(hLg,'position'));
if (iscell(axP)); axP = cell2mat(axP); end
if (iscell(lgP)); lgP = cell2mat(lgP); end

if (strcmp(get(hLg,'Units'),'pixels'))
    % retrieves the panel position
    set(hP,'Units','Pixel'); 
    pP = get(hP,'position');
    set(hP,'Units','Normalized');

    % converts the legend position to normalized coordinates
    lgP = lgP./repmat(pP(3:4),length(hLg),2);
end

% sets the extremum of the axes object
[L,B,R,T] = deal(axP(:,1),axP(:,2),sum(axP(:,[1 3]),2),sum(axP(:,[2 4]),2));

% determines which legend objects are within the axes objects
isInAx = false(1,length(hLg));
for i = 1:length(hLg)
    % sets the extremum of the legend object
    [hL,hB] = deal(lgP(i,1),lgP(i,2));
    [hR,hT] = deal(sum(lgP(i,[1 3])),sum(lgP(i,[2 4])));
    
    % determines if the legend is within any of the axes
    isInAx(i) = any((hL < R) & (hR > L) & (hB < T) & (hT > B));
end
