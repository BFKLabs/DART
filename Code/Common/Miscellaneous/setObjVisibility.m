function varargout = setObjVisibility(hObj,state)

if isempty(hObj)
    return
end

if iscell(hObj)
    hObj = rmvEmptyCells(hObj);
    if isempty(hObj)
        isOK = false;
    else
        try
            isOK = cellfun(@isvalid,hObj);
        catch
            isOK = cellfun(@(x)(isprop(x,'UserData')),hObj);
            if ~any(isOK); return; end
        end
    end
    
    if all(isOK)
        if isa(state,'logical') || isnumeric(state)
            eStr = {'off','on'};
            cellfun(@(x)(set(x,'visible',eStr{1+(state>0)})),hObj)
        elseif ischar(state)
            cellfun(@(x)(set(x,'visible',state)),hObj)
        end
    end    
    
else
    hObj = hObj(~arrayfun(@isempty,hObj));
    if isempty(hObj)
        isOK = false;
    else
        try
            isOK = isvalid(hObj);
        catch
            isOK = isprop(hObj,'UserData');
            if ~isOK; return; end
        end
    end
    
    if all(isOK)
        if isa(state,'logical') || isnumeric(state)
            eStr = {'off','on'};
            set(hObj,'visible',eStr{1+(state>0)})
        elseif ischar(state)
            set(hObj,'visible',state);
        end
    end
end

if nargout == 1
    varargout{1} = hObj;
end
