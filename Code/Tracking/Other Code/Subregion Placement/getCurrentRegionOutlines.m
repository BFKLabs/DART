function posO = getCurrentRegionOutlines(iMov)

% memory allocation
pG = iMov.posG;
isOld = isOldIntObjVer();
[nRow,nCol] = deal(iMov.pInfo.nRow,iMov.pInfo.nCol);
H = zeros(nRow,nCol);

% retrieves the axes object handle
hFig = findall(0,'tag','figFlyTrack');
hAx = findall(hFig,'type','Axes');
hVL = findall(hAx,'tag','hVert');
hHL = findall(hAx,'tag','hHorz');

% retrieves the position arrays for the vertical lines
vPos = arrayfun(@(x)(getIntObjPos(x,isOld)),hVL,'un',0);

% retrieves the line indices
if isOld
    iVL = arrayfun(@(x)(get(findobj(x,'tag','bottom line'),'UserData')),hVL);
else
    iVL = arrayfun(@(x)(get(x,'UserData')),hVL);
end

% sorts the line/position arrays in order
[~,iSV] = sort(iVL);
vPos = vPos(iSV);
xL0 = [pG(1),cellfun(@(x)(x(1)),vPos(:))',sum(pG([1,3]))];
W = repmat(diff(xL0),nRow,1);

% retrieves the position arrays for the horizontal lines
hPos = arrayfun(@(x)(getIntObjPos(x,isOld)),hHL,'un',0);
iHL = cell2mat(arrayfun(@(x)(get(x,'UserData')),hHL,'un',0));

% sorts the horizontal lines by column then row
[~,iSort] = sortrows(iHL);
[hPos,iHL] = deal(hPos(iSort),iHL(iSort,:));

% sets the region heights
for i = 1:nCol
    % sets the coordinates of the horizontal markers
    if isempty(iHL)
        % if there are no markers, then use an empty array
        yHL = [];
    else
        % otherwise, retrieve the coordinates of these markers
        ii = iHL(:,2) == i;
        yHL = cellfun(@(x)(x(1,2)),hPos(ii))';
    end
    
    % sets the height arrays
    H(:,i) = diff([pG(2),yHL,sum(pG([2,4]))]);
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