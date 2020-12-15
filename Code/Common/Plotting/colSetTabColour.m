% --- sets the tab colours for the index array, ind --- %
function col = colSetTabColour(N,varargin)

% sets the number of colours required to be determined
if (length(N) > 1)
    % case is an index array
    Nc = max(N); 
else
    % case is a single value
    Nc = N;
end

% initialisations
[colB,colRGB] = deal(num2cell(distinguishable_colors(Nc+1),2),char2rgb('k'));

% determines the colour schemes difference wrt the errorbar colour
[~,iSort] = sort(cellfun(@(x)(sum(abs(x-colRGB))),colB),'descend');

% sets the final bar graph face colour array
colB = colB(sort(iSort(1:(end-1))),:);
col = colB(N);

% sets the cell array as a string (if only element)
if (nargin == 1)
    col = col{1};
end