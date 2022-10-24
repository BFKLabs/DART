% --- determines the data group sizes
function [nGrp,ii,VarX] = detDataGroupSize(iData,plotD,ind,varargin)

% sets the default input arguments
if ~exist('ind','var'); ind = []; end

% initialisations
if isempty(ind); ind = 1:length(iData.yVar); end
ii = ones(length(ind),1);

% determines which independent variables are group variables
iiG = strcmp(field2cell(iData.xVar,'Type'),'Group');

% determines if the data is time bin grouped
if any(iiG)
    % determines if there is more than one grouping variable type
    Var = unique(field2cell(iData.xVar(iiG),'Var'));
    nGrp = zeros(size(Var));
    
    % sets the group sizes (for each variable)
    VarX = cell(length(nGrp),1);
    for i = 1:length(nGrp)
        VarX{i} = getStructField(plotD(1),Var{i});
        nGrp(i) = length(VarX{i});
    end
    
    %
    if length(nGrp) > 1
        % determines the stat data structs
        yVar = iData.yVar(ind);
        if nargin == 3
            isS = ~cellfun(@isempty,field2cell(yVar,'Stats'));
            XX = field2cell(yVar(isS),'Stats');
        else
            isX = ~cellfun(@isempty,field2cell(yVar,'xDep'));
            XX = field2cell(yVar(isX),'xDep');
        end
        
        % 
        if isempty(XX)
            % no groups, so set count to 1
            [nGrp,VarX] = deal(1,[]);            
        else
            % resets the group count size
            if nargin == 2
                ii = cellfun(@(x)(find...
                        (cellfun(@(y)(any(strcmp(x,y))),Var))),XX,'un',0);
                nGrp = nGrp(unique(cell2mat(ii)));
            else
                ii = cellfun(@(x)(find...
                        (cellfun(@(y)(any(strcmp(x,y))),Var))),XX,'un',0);
                ii = cell2mat(ii(~cellfun(@isempty,ii)));                
                [nGrp,VarX] = deal(nGrp(ii),VarX(unique(ii,'stable')));
            end
        end
    end
else
    % no groups, so set count to 1
    [nGrp,VarX] = deal(1,[]);
end
