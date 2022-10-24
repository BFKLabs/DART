% --- sets the group header strings
function mStr = setupSignalHeaderString(iData,mStrH,mStrN,appName,xGrp)

% retrieves the apparatus names
nApp = length(appName);

% expands the group names by day/night (if required)
if iData.sepGrp
    xGrp = cell2cell(cellfun(@(y)(cellfun(@(x)(sprintf('%s %s',x,y)),...
            xGrp,'UniformOutput',0)),{'(D)';'(N)'},'UniformOutput',0))';    
end
 
% expands the group strings to match the height of the header strings
[nGrp,xGrp] = deal(length(xGrp),xGrp(:)');
xGrp = [{'Bin Group'},repmat([xGrp,{''}],1,nApp)];

% combines the metric strings into a single array
mStr = combineCellArrays(mStrH,xGrp,0);
mStr(1:length(mStrH),1) = mStrH;

% sets the final group header strings
for i = 1:nApp
    % combines the header with the group strings
    iC = (i-1)*(nGrp+1) + (1:nGrp);
    mStr(2:3,iC+1) = repmat([appName(i);mStrN(i)],1,nGrp);
end