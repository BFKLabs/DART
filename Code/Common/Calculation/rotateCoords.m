% --- rotates the 2D coordinates in X
function [Xr,Yr] = rotateCoords(X,Y,dPhi)

% determines if the new values are valid
if isnan(X)
    % if not, then return an NaN array
    Xr = [NaN NaN];
else
    % sets up the 2D rotational matrix
    R = [[cos(dPhi) sin(dPhi)];[-sin(dPhi) cos(dPhi)]];
    Xr = (R*[X(:) Y(:)]')';
end
    
% sets the output coordinates into 2 arrays (if required)
if (nargout == 2)
    Yr = Xr(:,2);
    Xr = Xr(:,1);    
end