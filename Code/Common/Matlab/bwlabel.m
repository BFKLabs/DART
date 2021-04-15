function [L,numComponents] = bwlabel(BW,mode) 
%BWLABEL Label connected components in binary image. 
%   L = BWLABEL(BW,N) returns a matrix L, of the same size as BW, 
%   containing labels for the connected components in BW. N can 
%   have a value of either 4 or 8, where 4 specifies 4-connected 
%   objects and 8 specifies 8-connected objects; if the argument 
%   is omitted, it defaults to 8.  
% 
%   The elements of L are integer values greater than or equal to 
%   0.  The pixels labeled 0 are the background.  The pixels 
%   labeled 1 make up one object, the pixels labeled 2 make up a 
%   second object, and so on.  
% 
%   [L,NUM] = BWLABEL(BW,N) returns in NUM the number of 
%   connected objects found in BW. 
% 
%   Class Support 
%   ------------- 
%   The input image BW can be of class double or uint8. The 
%   output matrix L is of class double. 
% 
%   Example 
%   ------- 
%       BW = [1 1 1 0 0 0 0 0 
%             1 1 1 0 1 1 0 0 
%             1 1 1 0 1 1 0 0 
%             1 1 1 0 0 0 1 0 
%             1 1 1 0 0 0 1 0 
%             1 1 1 0 0 0 1 0 
%             1 1 1 0 0 1 1 0 
%             1 1 1 0 0 0 0 0]; 
%       L = bwlabel(BW,4); 
%       [r,c] = find(L == 2); 
% 
%   See also BWEULER. 
 
%   Steven L. Eddins, August 1995 
%   Copyright 1993-1998 The MathWorks, Inc.  All Rights Reserved. 
%   $Revision: 1.14 $  $Date: 1997/11/24 15:34:07 $ 
 
if (nargin < 2) 
    mode =8; 
end 
 
[M,N] = size(BW); 
 
% 
% Compute run-length encoding 
% 
rowZeros = logical(repmat(uint8(0), 1, size(BW,2))); 
BW1 = [rowZeros ; BW]; 
BW2 = [BW ; rowZeros];   % BW1 and BW2 are now uint8 arrays 
temp = BW2 > BW1; 
[sr,sc] = find(temp); 
[er,ec] = find(BW2 < BW1); 
numRuns = length(sr); 
if (numRuns == 0) 
    runs = []; 
else 
    runs = [sc sr (er-1)]; 
end 
runsPerCol = sum(temp,1); 
cumRunsPerCol = cumsum(runsPerCol); 
 
%  
% First labeling pass 
% 
labels = zeros(numRuns,1); 
A = sparse([],[],[],numRuns,numRuns,3*numRuns); 
currentLabel = 1; 
currentColumn = 1; 
lastColRuns = []; 
first = 1; 
last = 0; 
for k = 1:numRuns 
    column = runs(k,1); 
    rowStart = runs(k,2); 
    rowEnd = runs(k,3); 
    if (column ~= currentColumn) 
        % We've started a new column.  Extract the runs 
        % belonging to the previous column. 
        last = cumRunsPerCol(column - 1); 
        first = last - runsPerCol(column - 1) + 1; 
        lastColRuns = runs(first:last,:); 
        currentColumn = column; 
    end 
    if (isempty(lastColRuns)) 
        labels(k) = currentLabel; 
        currentLabel = currentLabel + 1; 
    else 
        if (mode == 8) 
            % Find eight-connected objects 
            overlaps = find(((rowEnd >= (lastColRuns(:,2)-1)) & ... 
                    (rowStart <= (lastColRuns(:,3)+1)))); 
        else 
            overlaps = find(((rowEnd >= lastColRuns(:,2)) & ... 
                    (rowStart <= lastColRuns(:,3)))); 
        end 
        if (isempty(overlaps)) 
            labels(k) = currentLabel; 
            currentLabel = currentLabel + 1; 
        elseif (length(overlaps) == 1) 
            labels(k) = labels(first + overlaps - 1); 
        else 
            firstIdx = first + overlaps(1) - 1; 
            labels(k) = labels(firstIdx); 
            for n = 2:length(overlaps) 
                nIdx = first + overlaps(n) - 1; 
                if (labels(firstIdx) ~= labels(nIdx)) 
                    i = labels(firstIdx); 
                    j = labels(nIdx); 
                    A(i,j) = A(i,j) + 1; 
                    A(j,i) = A(j,i) + 1; 
                end 
            end 
        end 
    end 
end 
numLabels = currentLabel - 1; 
 
% Resolve equivalence classes 
A = A(1:numLabels, 1:numLabels); 
newLabels = 1:numLabels; 
for i = 1:numLabels 
    % Find all labels equivalent to i. 
    % Use a queue-based breadth-first search starting from the 
    % node i.  The vector equivs holds the queue. 
    equivs = find(A(:,i)); 
    while (~isempty(equivs)) 
        j = equivs(1); 
        newEquivs = find(A(:,j)); 
        if (~isempty(newEquivs)) 
            newEquivs(newEquivs == i) = []; 
            equivs = [equivs ; newEquivs]; 
        end 
        newLabels(j) = newLabels(i); 
        A(:,j) = 0; 
        A(j,:) = 0; 
        equivs(1) = []; 
    end 
end 
 
% Now we have a set of labels, but the set 
% may skip some numbers.  We want the set 
% to go from 1 to numComponents. 
[newLabels,sortIdx] = sort(newLabels); 
newLabels = 1 + cumsum(diff([1 newLabels]) ~= 0); 
newLabels(sortIdx) = newLabels; 
 
% Create the output image and fill in each run 
% with its label. 
L = zeros(M,N); 
for k = 1:numRuns 
    column = runs(k,1); 
    rowStart = runs(k,2); 
    rowEnd = runs(k,3); 
    L(rowStart:rowEnd,column) = newLabels(labels(k)); 
end 
 
numComponents = max(newLabels); 