% --- sets the raw data values into the plotting data struct, plotD
function plotD = setRawDataValues...
                            (plotD,snTot,Y,indD,pStr,iExpt,iApp,Type,mlt)

% initialisations
if ~exist('mlt','var'); mlt = 1; end
fok = snTot.iMov.flyok{iApp};

% sets up the raw data array
switch Type
    case (1) 
        % case is pre-day separated data
        Yr = setupRawDataArray(Y,indD);
    
    case (2) 
        % case is post-day separated data
        Yr = cell2cell(cellfun(@(x)(num2cell(...
                            cell2mat(x(:)),1)),num2cell(Y,2),'un',0));
        if (size(Yr{1},2) == 1)
            Yr = cellfun(@(x)(x'),Yr,'un',0);
        end
        
    case (3) 
        %
        xi = num2cell(1:length(fok));
        A = cellfun(@(x)(Y(x,:)),indD,'un',0);
        isE = cellfun('isempty',A);
        
        A(isE) = cellfun(@(x)(NaN(1,size(x,2))),A(isE),'un',0);
        Yr = cell2cell(cellfun(@(z)(cellfun(@(y)...
                    (combineNumericCells(y)),num2cell(cellfun...
                    (@(x)(x(:,z)),A,'un',0),2),'un',0)),xi,'un',0),0);
end

% sets the values into the raw data array
Yr = cellfun(@(x)(mlt*x),Yr,'un',0);
if size(plotD.(pStr),3) > 1
    [xiR,xiC] = deal(1:size(Yr,1),1:size(Yr,2));
    plotD.(pStr)(xiR,xiC,iExpt) = Yr;
else
    plotD.(pStr) = Yr;
end

% --- sets up the raw data array (separates data by day)
function Yr = setupRawDataArray(Y,indD0)

% determines the valid (non-NaN) indices
indOK = find(~isnan(indD0));
indD = indD0(indOK);

% if the input data is a cell array, then combine to a numeric array
% Y = Y(indD(indOK),:);
if (iscell(Y))
    % if there is a mis-match in the length of the data/valid index
    % arrays, then reshape the arrays so that they match
    if ((length(indOK)) ~= length(Y)); Y = Y(1:length(indOK)); end
%     Y = Y(isN(indD(indOK))); 
    
    % converts the cell array to a numerical array
    Y = cell2mat(Y);
end

% memory allocation
Yr = cell(size(indD0,2),size(Y,2));
for i = 1:size(Y,2)
    % sets the values into a temporary array
    Ytmp = NaN(size(indD0));
    Ytmp(~isnan(indD0)) = Y(:,i);
    
    % sets the final values into reshaped array
    Yr(:,i) = reshape(num2cell(Ytmp,1),[size(Yr,1),1]);
end
