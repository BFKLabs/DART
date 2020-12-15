% --- combines a cell array, cStr, by its components parts. the seperator
%     string, sepStr, is used to space the values
function cStr = combineString(Str,sepStr)

% sets the seperator string (if not provided
if (nargin == 1)
    sepStr = '-';
end

% ensures the string is a cell array
if (~iscell(Str))
    Str = {Str};
end

% adds the new strings to the combined string
cStr = [];
for i = 1:length(Str)
    % adds on the new string
    cStr = [cStr,Str{i}];
    
    % adds in the seperator string (if not the final cell entry)
    if (i < length(Str))
        cStr = [cStr,sepStr];
    end
end
