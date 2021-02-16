% --- converts an angle in degrees to a bearing
function bear = deg2bear(phi,type)

% sets the calculation type
if (nargin == 1); type = 'xy'; end

% memory allocation
bear = zeros(size(phi));

% sets the radius to bearing scale factor
r2d = 180/pi;

% 
switch (type)
    case ('xy')
        phi = mod(phi-pi,2*pi);
        ii = phi > 3*pi/2;
        
        bear(ii) = (7*pi/2 - phi(ii))*r2d;
        bear(~ii) = (3*pi/2 - phi(~ii))*r2d;
    case ('ij')
        % converts the 
        phi = mod(phi+pi,2*pi)-pi;
        ii = phi < -pi/2; 
        
        bear(ii) = ((5*pi/2)+phi(ii))*r2d;
        bear(~ii) = ((pi/2)+phi(~ii))*r2d;                
end
