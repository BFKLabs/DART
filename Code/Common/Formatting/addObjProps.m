function varargout = addObjProps(hObj,varargin)

% if the incorrect input arguments are given, then output an error to
% screen and exit the function
nArg = length(varargin);
if mod(nArg,2) == 1
    eStr = 'Error! The pair/field values have not been input correctly.';
    waitfor(msgbox(eStr,'Add Property Error','modal'))
    return
end

% adds the property field/values to the object
for i = 1:nArg/2
    i0 = 2*(i-1);
    hObj = addObjProp(hObj,varargin{i0+1},varargin{i0+2});
end

% returns the object (if required)
if nargout == 1
    varargout{1} = hObj;
end