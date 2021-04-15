% --- splits up a string, Str, by its white spaces and returns the
%     constituent components in the cell array, sStr
function sStr = splitStringRegExp(Str,sStr)

% ensures the string is not a cell array
if (iscell(Str))
    Str = Str{1};
end

% determines the indices of the non-white regions in the string
if (length(sStr) == 1)
    if (strcmp(sStr,'\') || strcmp(sStr,'/'))    
        ind = strfind(Str,sStr)';
    else
        ind = regexp(Str,sprintf('[%s]',sStr))';
    end
else
    ind = regexp(Str,sprintf('[%s]',sStr))';
end

% calculates the indices of the non-contigious non-white space indices and
% determines the index bands that the strings belong to
indGrp = num2cell([[1;(ind+1)],[(ind-1);length(Str)]],2);

% sets the sub-strings
sStr = cellfun(@(x)(Str(x(1):x(2))),indGrp,'un',false);
