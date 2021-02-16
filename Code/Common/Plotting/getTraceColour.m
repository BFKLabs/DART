% --- sets the tab colours for the index array, ind --- %
function col = getTraceColour(ind,varargin)

% memory allocation
col = cell(length(ind),1);

% sets the colours for all the indices
for i = 1:length(ind)
    switch (ind(i))
        case (0) % not a valid index
            eStr = 'Not a valid colour index!';
            waitfor(errordlg(eStr,'Invalid Colour Index','modal'))
            col{i} = [];
        case (1) % colour is blue
            col{i} = 'b';
        case (2) % colour is red
            col{i} = 'r';            
        case (3) % colour is green
            col{i} = 'g';
        case (4) % colour is cyan
            col{i} = 'm';
        case (5) % colour is black
            col{i} = 'k';
        otherwise % make up some other colours
            col{i} = rand(1,3);
    end    
end

% sets the cell array as a string (if only element)
if (length(ind) == 1) && (nargin == 1)
    col = col{1};
end