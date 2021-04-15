% --- determines if the image needs to be rotated given the state of the
%     rotate image flag and the rotation angle
function isRot90 = detIfRotImage(iMov)

% determines if the image needs to be rotated given the flags
if isfield(iMov,'useRot')
    % case is use the useRot flag
    isRot90 = logical(iMov.useRot*(abs(iMov.rotPhi) > 45));
    
elseif isfield(iMov,'rot90')   
    % case is using the rot90 flag (obsolete form)
    isRot90 = iMov.rot90;
    
else
    % otherwise, return a false flag
    isRot90 = false;    
end