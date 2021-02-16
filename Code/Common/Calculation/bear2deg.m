function phi = bear2deg(bear)

%
phi = (mod(bear,360)-90)*(pi/180);
phi(phi > pi) = phi(phi > pi) - 2*pi;