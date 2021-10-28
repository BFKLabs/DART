function posO = getCurrentRegionOutlines(iMov)

% memory allocation
pG = iMov.posG;
frmSz = getCurrentImageDim();
[nRow,nCol] = deal(iMov.pInfo.nRow,iMov.pInfo.nCol);
H = zeros(nRow,nCol);

% retrieves the axes object handle
hFig = findall(0,'tag','figFlyTrack');
hAx = findall(hFig,'type','Axes');

% retrieves the position arrays for the vertical lines
hVL = findall(hAx,'tag','hVert');
vPos = arrayfun(@(x)(getLinePos(x)),hVL,'un',0);
iVL = arrayfun(@(x)(get(findobj(x,'tag','bottom line'),'UserData')),hVL);

% sorts the line/position arrays in order
[~,iSV] = sort(iVL);
vPos = vPos(iSV);
xL0 = [pG(1),cellfun(@(x)(x(1)),vPos(:))',sum(pG([1,3]))];
W = repmat(diff(xL0),nRow,1);

% retrieves the position arrays for the horizontal lines
hHL = findall(hAx,'tag','hHorz');
hPos = arrayfun(@(x)(getLinePos(x)),hHL,'un',0);
iHL = cell2mat(arrayfun(@(x)(get(x,'UserData')),hHL,'un',0));

% sorts the horizontal lines by column then row
[~,iSort] = sortrows(iHL);
[hPos,iHL] = deal(hPos(iSort),iHL(iSort,:));

% sets the region heights
for i = 1:nCol
    ii = iHL(:,2) == i;
    yL0 = [pG(2),cellfun(@(x)(x(1,2)),hPos(ii))',sum(pG([2,4]))];
    H(:,i) = diff(yL0);
end

% calculates the outline coordinates of each regions
posO = cell(nRow,nCol);
for i = 1:nRow
    for j = 1:nCol
        x0 = pG(1)+sum(W(i,1:j-1));
        y0 = (pG(2)+sum(H(1:i-1,j)));
        posO{i,j} = [x0,y0,W(i,j),H(i,j)];
    end
end

% sets the final outline positional vector array
posO = arr2vec(posO')';
a = 1;

% --- retrieves the line positions
function lPos = getLinePos(hLine)

hAPI = iptgetapi(hLine);
lPos = hAPI.getPosition();