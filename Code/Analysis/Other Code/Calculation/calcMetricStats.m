% --- calculates the metrics for each of those specified in the plot data
%     struct that start with the variable name, vName
function p = calcMetricStats(p,vName,cType,useAll)

% retrieves the fields names of the plot data struct
fName = fieldnames(p);
if (nargin < 3); cType = 4; end
if (nargin < 4); useAll = false; end

% determines the statistical metrics that need to be calculated
ii = find(cellfun(@(x)(strContains(x,sprintf('%s_',vName))),fName))';

% determines the metric variables that match the input variable name
if (isempty(ii))
    % if there are no valid metrics, then exit
    return
else
    % retrieves the values from the data struct
    Y0 = eval(sprintf('p.%s',vName'));    
    if (useAll)
        % combines the data over all day (if required)
        isN = [];
        if (isnumeric(Y0))
            Y0 = num2cell(Y0);
        else
            Y0 = cellfun(@(x)(cell2mat(x)),num2cell(Y0,1),'un',0);
        end
    end   
    
    % removes any infinite values
    Y0 = cellfun(@(x)(x.*(~isinf(x))),Y0,'un',0);
    
    % resets the data arrays for the final calculations
    switch (cType)
        case (1) % case is taking metrics over all days (separate expts)
            Y = cell(size(Y0,3),1);
            for i = length(Y)
                Y{i} = reshape(Y0(:,:,i),[1 1 size(Y0,1)*size(Y0,2)]);
            end
        case (2) % case is taking metrics over all expts (separate days)
            Y = cell(size(Y0,1),1);
            for i = 1:length(Y)
                Y{i} = reshape(Y0(i,:,:),[1 1 size(Y0,2)*size(Y0,3)]);
            end
        case (3) % case is take metrics over all day & expts (multi-dimensional)
            Y0 = cell2cell(cellfun(@(x)(num2cell(x,2)),Y0,'un',0)); 
            Y = {reshape(Y0,[1 1 numel(Y0)])};
        case (4) % case is take metrics over all day & expts (single dimensional)
            Y = {reshape(Y0,[1 1 numel(Y0)])};    
        case (5) % case is metrics overall days & expts (single value/group)
            Y0 = num2cell(cell2mat(Y0(:)),2);
            Y = {reshape(Y0,[1 1 numel(Y0)])};    
        case (6) %
            Y = cellfun(@(x)(reshape(x,[1 1 length(x)])),Y0,'un',0);
    end
    
    % removes empty arrays and combines cell arrays into numerical arrays
    if (~any(cType == 6))
        Y = cellfun(@(x)(combineNumericCells3(x(~cellfun(@isempty,x)))),Y,'un',0);
    end
end

% calculates the metrics for all the specifed types
for i = ii
    % loops through each of the variables calculating the metrics
    fNw = fName{i}((length(vName)+2):end);
    switch (fNw)    
        case ('mn') % case is the mean            
            A = cellfun(@(x)(mean(x,3,'omitnan')),Y,'un',0);
        case ('md') % case is the median
            A = cellfun(@(x)(median(x,3,'omitnan')),Y,'un',0);
        case ('lq') % case is the lower quartile       
            A = cellfun(@(x)(quantile(x,0.25,3)),Y,'un',0);            
        case ('uq') % case is the upper quartile           
            A = cellfun(@(x)(quantile(x,0.75,3)),Y,'un',0);
        case ('rng') % case is the range            
            A = cellfun(@(x)(rangewr(x,3)),Y,'un',0);
        case ('ci') % case is the 95% confidence interval            
            A = cellfun(@(x)(prctile(x,[2.5,97.5],3)),Y,'un',0);            
        case ('sd') % case is the standard deviation            
            A = cellfun(@(x)(std(x,[],3,'omitnan')),Y,'un',0);            
        case ('sem') % case is the standard error mean
            N = cellfun(@(x)(size(x,3)),Y,'un',0);
            A = cellfun(@(x,n)(std(x,[],3,'omitnan')/sqrt(n)),Y,N,'un',0);            
        case ('min') % case is the minimum
            A = cellfun(@(x)(min(x,[],3,'omitnan')),Y,'un',0);            
        case ('max') % case is the maximum            
            A = cellfun(@(x)(max(x,[],3,'omitnan')),Y,'un',0);                
    end
        
    % determines if the data has been combined over all data
    if useAll
        % if so, then set the valid (non-NaN) time points
        if isempty(isN); isN = ~isnan(A{1}); end
        
        % sets the final values
        A = cellfun(@(x)(x(isN,:)),A,'un',0);
    end    
    
    % updates the plot data struct with the new values
    switch cType
        case (6)
            eval(sprintf('p.%s_%s = cell2mat(A);',vName,fNw));
        case {3,4}
            eval(sprintf('p.%s_%s = A{1};',vName,fNw));    
        otherwise
            eval(sprintf('p.%s_%s = A;',vName,fNw));
    end
end

