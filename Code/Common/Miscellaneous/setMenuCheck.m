function varargout = setMenuCheck(hObj,state)

if isempty(hObj)
    % if not, then set the output handle (if required)
    if nargout == 1
        varargout{1} = hObj;
    end    
    
    % exits the function
    return
end

% updates the enabled properties (based on the input state)
if isa(state,'logical') || isnumeric(state)
    % case is the state is either logical or numerical
    eStr = {'off','on'};
    set(hObj,'Checked',eStr{1+(state>0)})
    
elseif ischar(state)
    % case is the state is a string
    set(hObj,'Checked',state)
end