function varargout = setObjEnable(hObj,state)

if isempty(hObj)
    if nargout == 1
        varargout{1} = hObj;
    end    
    return
end

if iscell(hObj)
    isOK = cellfun(@isvalid,hObj);
    if all(isOK)
        if isa(state,'logical') || isnumeric(state)
            eStr = {'off','on'};
            cellfun(@(x)(set(x,'enable',eStr{1+(state>0)})),hObj)
        elseif ischar(state)
            cellfun(@(x)(set(x,'enable',state)),hObj)
        end
    end    
    
else
    if all(isvalid(hObj))
        if isa(state,'logical') || isnumeric(state)
            eStr = {'off','on'};
            set(hObj,'enable',eStr{1+(state>0)})
        elseif ischar(state)
            set(hObj,'enable',state);
        end
    end
end

if nargout == 1
    varargout{1} = hObj;
end
