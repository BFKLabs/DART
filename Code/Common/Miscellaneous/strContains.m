% --- wrapper function for determining if a string has a pattern. this is
%     necessary because there are 2 different ways of determining this
%     depending on the version of Matlab being used
function hasPat = strContains(str,pat)

if iscell(pat)
    hasPat = cellfun(@(x)(strContains(str,x)),pat);
    return
elseif isempty(pat)
    hasPat = false;
    return
elseif iscell(str)
    hasPat = false(size(str));
    isOK = ~cellfun('isempty',str);
    hasPat(isOK) = cellfun(@(x)(strContains(x,pat)),str(isOK));
    return
end

try
    % attempts to use the newer version of the function
    hasPat = contains(str,pat);
catch
    % if that fails, use the older version of the function
    hasPat = ~isempty(strfind(str,pat));
end