% --- retrieves the significant pixel neighbouring indices
function [indN,Imap] = getNeighbourIndices(xB,yB,sz,varargin)

% if only the linear indices are provided, then calculate the sub-scripts
if (isempty(yB)); [yB,xB] = ind2sub(sz,xB); end

% creates a sparse matrix for the mutual information calculations
nB = length(xB);

% creates the index map array
Imap = NaN(sz); for i = 1:nB; Imap(yB(i),xB(i)) = i; end

% sets the x/y neighbourhood offset
[dX,dY] = meshgrid(-1:1);
[dX,dY] = deal(dX((1:numel(dX))~=5),dY((1:numel(dY))~=5));

% sets the neighbouring indices for each point
xN = cellfun(@(x)(x+dX),num2cell(xB),'UniformOutput',0);
yN = cellfun(@(y)(y+dY),num2cell(yB),'UniformOutput',0);
indG = cellfun(@(x,y)(sub2ind(sz,y,x)'),xN,yN,'UniformOutput',0);

% sets the overall mapping indices
indN = cellfun(@(x)(Imap(x(~isnan(Imap(x))))),indG,'UniformOutput',0);
if (nargin == 3)
    indN = cellfun(@(x,y)(x(x>y)'),indN,num2cell(1:nB)','UniformOutput',0);
end