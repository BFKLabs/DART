% --- reorders all the arrays within a struct, Str, such that the array
%     elements for i1/i2 are swapped --- %
function Str = reorderArrays(Str,i1,i2)

% retrieves the struct field names
fStr = fieldnames(Str);

% reorders the cell/struct
for i = 1:length(fStr)
    % retrieves the struct fields
    sStr = eval(sprintf('Str.%s;',fStr{i}));
    
    % reorders if necessary
    if (iscell(sStr))
        % variable is a cell array
        [sStr{i1},sStr{i2}] = deal(sStr{i2},sStr{i1});
    elseif (isstruct(sStr))
        % variable is a struct array
        [sStr(i1),sStr(i2)] = deal(sStr(i2),sStr(i1));
    elseif (numel(sStr) >= max(i1,i2))
        % variable is another array
        [sStr(i1),sStr(i2)] = deal(sStr(i2),sStr(i1));
    end
    
    % updates the field again
    eval(sprintf('Str.%s = sStr;',fStr{i}));
end