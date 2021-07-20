% --- combines the numeric arrays in the cell array into a 2D array, Y -- %
function Y = combineNumericCells(Yc,varargin)

%
if iscell(Yc{1})
    Yc = cellfun(@(x)(cell2mat(x(:))),Yc,'un',0);
end

% array indexing
sz = cellfun(@(x)(size(x)),reshape(Yc,length(Yc),1),'un',0);
sz = cell2mat(sz);

% determines which of the dimensions the array is to be joined across
if (nargin == 1)
    ii = prod(sz,2) > 0;
    sz(~ii,:) = 0;
    
    %
    dsz = range(sz(ii,:),1);    
    if (all(dsz == 0))
        [~,imn] = min(sz(find(ii,1,'first'),:));
    else
        imn = find(dsz == 0);
    end
    
    jmn = (1:2) ~= imn;
else
    [jmn,imn] = deal(1,2);
end

% memory allocation    
[nCol,nRow] = deal(length(Yc),max(sz(:,jmn)));
[Y,iOfs] = deal(NaN(nRow,sum(sz(:,imn))),0);

% sets the values into the total numeric array
for i = 1:nCol
    iCol = iOfs+(1:max(1,sz(i,imn)));
    if (prod(sz(i,:)) > 0)
        Y(1:sz(i,jmn),iCol) = reshape(Yc{i},sz(i,jmn),sz(i,imn));
    end
    iOfs = iCol(end);
end
