% --- checks the new experiment name to see if it is unique and valid
function [ok,mStr] = checkNewExptName(sObj,nwStr,iExp)

% initialisations
B = setGroup(iExp,size(sObj));

switch class(sObj{1})
    case 'struct'
        expFile = cellfun(@(x)(x.expFile),sObj,'un',0);
    case 'char'
        expFile = sObj;
end

% determines if the filename is unique
if any(strcmp(expFile(~B),nwStr))   
    % if the file name is not unique then output an error message to screen
    ok = false;
    mStr = sprintf(['The filename "%s" is already in use. Please ',...
                    'retry with a unique filename.'],nwStr);
else
    % otherwise, check
    [ok,mStr] = chkDirString(nwStr);
end

% if there is only one output, and there is an error, then output the
% message to screen
if (nargout == 1) && ~isempty(mStr)
    waitfor(msgbox(mStr,'Invalid Experiment Name','modal'))
end