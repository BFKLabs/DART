% --- removes any rows/columns which have empty elements over all 
%     experiments/group types
function plotD = removeEmptyElements(plotD, pStr)

% memory allocation
nApp = length(plotD);
[N,Y] = deal(cell(nApp,1));

% determine if there are no empty elements over all plot value types
for iStr = 1:length(pStr)
    % initialisations
    isChange = false;
    
    % loops through each group type determining the maximum dimensions
    for iApp = 1:nApp
        % retrieves the plot values and determines the maximum length of
        % the elements over all experiments
        Y{iApp} = eval(sprintf('plotD(iApp).%s', pStr{iStr}));
        N{iApp} = max(cellfun(@(x)(length(x)),Y{iApp}),[],3);
    end
    
    % pads any missing rows/columns with zeros so that all dimensions are
    % equal
    N = padRowCol(N);
    
    % determines the maximum array dimension size over all group types/days
    Nmx = max(cell2mat(reshape(N, [1,1,nApp])),[],3);
    [Cmx,Rmx] = deal(max(Nmx,[],1),max(Nmx,[],2));

    % determines if there are any rows without any valid values
    if any(Rmx == 0)
        % if so, then remove these rows for each sub-group
        [Y,isChange] = deal(cellfun(@(x)(x(Rmx>0,:,:)),Y,'un',0),true);
    end
    
    % determines if there are any columns without any valid values
    if any(Cmx == 0)
        % if so, then remove these rows for each sub-group
        [Y,isChange] = deal(cellfun(@(x)(x(:,Cmx>0,:)),Y,'un',0),true);
    end
    
    % updates the plotting data struct with the new values (if any change)
    if isChange
        for iApp = 1:nApp
            eval(sprintf('plotD(iApp).%s = Y{iApp};',pStr{iStr}))
        end
    end
end

% --- pads the size array so that all sub-groups have equal dimensions
function N = padRowCol(N)

% memory allocation
[szN,nApp] = deal(cell2mat(cellfun(@size,N,'un',0)),length(N));

% if there is any disparity between sub-groups, then pad the arrays
if any(range(szN,1) > 0)
    % determines the number of rows/columns to pad
    dszN = repmat(max(szN,[],1),nApp,1) - szN;
    for iApp = 1:nApp
        % there is a disparity in row count
        if dszN(iApp,1) > 0
            N{iApp} = [N{iApp};zeros(dszN(iApp,1),szN(iApp,2))];
        end
        
        % there is a disparity in column count
        if dszN(iApp,2) > 0
            N{iApp} = [N{iApp},zeros(szN(iApp,1),dszN(iApp,2))];
        end
    end
end

