function Y = convertVarSizedArrays(Y0,nMax)

% sets the default input arguments
if ~exist('nMax','var')
    nMax = max(arr2vec(cellfun(@(x)(max(cellfun(@length,x))),Y0)));
end

% memory allocation
Y = cell(size(Y0));
for i = 1:numel(Y0)
    YT = combineNumericCells(Y0{i});
    Y{i} = num2cell([YT;NaN(nMax-size(YT,1),size(YT,2))],2)';
end