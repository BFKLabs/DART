% --- creates a circle template of radius R for the 2D cross-correlation
function IT = getCircleTemplate(R,varargin)

% initialisations and memory allocation
phi = linspace(0,2*pi,1001);
IT = zeros(2*R+1);

% sets the binary mask
if (nargin == 1)
    [X,Y] = deal(roundP(R*(cos(phi)+1)+1),roundP(R*(sin(phi)+1))+1); 
    IT(sub2ind(size(IT),Y,X)) = 1; 
else
    IT0 = IT; IT0(R+1,R+1) = 1;
    IT = bwdist(IT0) <= R;
end