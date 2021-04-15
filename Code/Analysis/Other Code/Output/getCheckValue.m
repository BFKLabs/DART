% --- retrieves the current value of the checkbox (based on selection and
%     the enabled status)
function chkVal = getCheckValue(hCheck)

% determines if the checkbox is enabled
if (strcmp(get(hCheck,'enable'),'on'))
    % if so, then retrieve the current value
    chkVal = get(hCheck,'value') > 0;
else
    % checkbox is disabled, so value is false
    chkVal = false;
end