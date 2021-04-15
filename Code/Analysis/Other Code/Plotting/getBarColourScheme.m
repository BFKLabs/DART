% --- gets the bar colour scheme such that is doesn't clash with the 
%     colour of the error bar
function colB = getBarColourScheme(N,colErr)

% initialisations
[colB,colRGB] = deal(num2cell(distinguishable_colors(N+1),2),char2rgb(colErr));

% determines the colour schemes difference wrt the errorbar colour
[~,iSort] = sort(cellfun(@(x)(sum(abs(x-colRGB))),colB),'descend');

% sets the final bar graph face colour array
colB = colB(sort(iSort(1:end-1)),:);