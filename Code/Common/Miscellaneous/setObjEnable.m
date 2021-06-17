function varargout = setObjEnable(hObj,state)

% determines if any handles are actually provided to the function
if isempty(hObj)
    % if not, then set the output handle (if required)
    if nargout == 1
        varargout{1} = hObj;
    end    
    
    % exits the function
    return
end

if iscell(hObj)
    % case is the array is stored in a cell array
    isOK = cellfun(@isvalid,hObj);
    if all(isOK)
        if isa(state,'logical') || isnumeric(state)
            % case is the state is either logical or numerical
            eStr = {'off','on'};
            cellfun(@(x)(set(x,'enable',eStr{1+(state>0)})),hObj)
        
        elseif ischar(state)
            % case is the state is a string
            cellfun(@(x)(set(x,'enable',state)),hObj)
        end
    end    
    
else
    % case is the array is stored in a non-cell array
    if all(isvalid(hObj)) && isprop(hObj(1),'enable')
        if isa(state,'logical') || isnumeric(state)
            % case is the state is either logical or numerical
            eStr = {'off','on'};
            set(hObj,'enable',eStr{1+(state>0)})
            
        elseif ischar(state)
            % case is the state is a string
            set(hObj,'enable',state);
        end
    end
end

if nargout == 1
    varargout{1} = hObj;
end
