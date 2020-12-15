function varargout = setObjEnable(hObj,state)

if ishandle(hObj)
    if isa(state,'logical')
        eStr = {'off','on'};
        set(hObj,'enable',eStr{1+state})
    elseif ischar(state)
        set(hObj,'enable',state);
    end
end

if nargout == 1
    varargout{1} = hObj;
end