% --- splits up a string, Str, by its white spaces and returns the
%     constituent components in the cell array, sStr
function sStr = splitString(Str)

% ensures the string is not a cell array
if (iscell(Str))
    Str = Str{1};
end

% determines the indices of the non-white regions in the string
ind = regexp(Str,'\S');

% calculates the indices of the non-contigious non-white space indices and
% determines the index bands that the strings belong to
ii = find(diff(ind)>1)';
indGrp = num2cell([[1;(ind(ii+1)')] [ind(ii)';ind(end)]],2);

% sets the sub-strings
sStr = cellfun(@(x)(Str(x(1):x(2))),indGrp,'un',false);
