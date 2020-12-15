function result = renderCellArrayOfStringsToString(cellArray,separator) 
    % renderCellArrayOfStringsToString convert cell array to string
    % renderCellArrayOfStringsToString(CELLARRAY,SEPARATOR) Takes
    % vector CELLARRAY of strings and turns it into a string, with
    % each item in CELLARRAY separated by SEPARATOR.

    %   Copyright 2010 The MathWorks, Inc.

    assert(nargin==2 &&...
        iscellstr(cellArray) &&...
        isvector(cellArray) &&...
        ischar(separator))

    % Force to nx1
    if(size(cellArray,1)~=1)
        cellArray = cellArray';
    end

    % Insert the separator into a second row
    cellArray(2,:) = {separator};

    % Reshape the matrix to a vector, which puts the separators
    % between the original strings
    cellArray = reshape(cellArray,1,numel(cellArray));

    % Delete the last separator
    cellArray(end) = [];

    % Render them to a string
    result = cell2mat(cellArray);
end
