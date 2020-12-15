% --- retrieves the output metric indices
function varargout = getOutputIndices(pData,Type)

% determines the elements of the output data array that are cells
oP = pData.oP(:,3);
isC = find(cellfun(@iscell,oP));

% sets output indices based on the data type
switch (Type)
    case ('Stats') % case is statistic calculations
        
        % retrieves the stats components of the output data array
        isC = isC(cellfun(@length,oP(isC)) == 3);
        A = cell2cell(oP(isC));
        
        % resets the 
        isN = ~cellfun(@isnan,A(:,1));
        [A(isN,1),A(~isN,1)] = deal(pData.oP(cell2mat(A(isN)),2),{[]});
        
        % sets the output arguments
        varargout{1} = isC;
        [varargout{2},varargout{3}] = deal(A(:,1),A(:,2));        
        
        % converts any non-NaN values to logicals
        B = cell2mat(A(:,3));
        [varargout{4},ii] = deal(false(size(B)),~isnan(B));
        varargout{4}(ii) = logical(B(ii));
        
    case ('Metric') % case is the metrics output
        
        % removes the cell elements from the array
        oP(isC) = {NaN}; oP = cell2mat(oP);
        
        % determines the independent/dependent variable indices
        xInd = find(oP == 0);
        yInd = cellfun(@(x)(find(oP==x)),num2cell(xInd),'un',0);
        
        % sets the output arguments
        [varargout{1},varargout{2}] = deal(xInd,yInd);
        
    case ('RawData') % case is the raw data output
        
        % removes the cell elements from the array
        oP(isC) = {0}; oP = cell2mat(oP);
        
        % sets the output arguments
        varargout{1} = find(isnan(oP));  

    case ('BaseIndex') % case is the base indices
        
        % removes the cell elements from the array
        oP(isC) = {NaN}; oP = cell2mat(oP);        
        
        % determines the independent/dependent variable indices
        varargout{1} = find(oP == 0);        
        
    case ('MetricMD') % case is the multi-dimension metric
        
        % retrieves the stats components of the output data array
        isC = isC(cellfun(@length,oP(isC)) == 2);
        [C,~,IC] = unique(cell2mat(cell2cell(oP(isC))),'rows');
                
        % sets the unique x/y indices for the multi-dimensional data
        [xInd,yInd] = deal(num2cell(C,2),cell(size(C,1),1));
        for i = 1:length(yInd); yInd{i} = isC(IC == i); end
        
        % sets the output arguments
        [varargout{1},varargout{2}] = deal(xInd,yInd);
        
end