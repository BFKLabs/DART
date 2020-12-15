% --- sets the header string array based on the row/group names -- %
function hStr = setHeaderGroupNames(grpName,sgrpName,tStr)

% sets the default prefix string
if (nargin == 2); tStr = 'Type = '; end
if (isnan(grpName{1})); grpName = {''}; end

% memory allocation
[nGrp,nSub] = deal(length(grpName),length(sgrpName));
hStr = repmat({num2cell(NaN(2,nSub))},1,nGrp);
sgrpName = reshape(sgrpName,1,nSub);

% sets the group name and 
for i = 1:nGrp
    [hStr{i}{1,1},hStr{i}(2,:)] = deal(sprintf('%s%s',tStr,grpName{i}),sgrpName);
end
