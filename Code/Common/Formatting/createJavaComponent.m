function [jSP,hC] = createJavaComponent(jSP0,tPos,hParent)

% turns off the warnings
wState = warning('off','MATLAB:ui:javacomponent:FunctionToBeRemoved');

% runs the javacomponent function (based on input arguments
switch nargin
    case 1
        [jSP,hC] = javacomponent(jSP0);
    case 2
        [jSP,hC] = javacomponent(jSP0, tPos);
    case 3
        [jSP,hC] = javacomponent(jSP0, tPos, hParent);
end

% resets the warning status
warning(wState);