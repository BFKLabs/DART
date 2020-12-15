function In = normImg(I,Ilim)

% converts the image to a double
I = double(I);

% determines the max/min pixel intensity values
if (nargin == 1)
    [mx,mn] = deal(nanmax(I(:)),nanmin(I(:)));
else
    [mx,mn] = deal(Ilim(2),Ilim(1));
end

% calculates the normalised pixel intensity
In = (I - mn)/(mx - mn);
if (nargin == 2)
    [In(In < 0),In(In > 1)] = deal(0,1);
end