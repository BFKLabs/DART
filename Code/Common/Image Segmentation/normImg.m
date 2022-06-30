function In = normImg(I,Ilim)

% converts the image to a double
I = double(I);

% determines the max/min pixel intensity values
if nargin == 1
    [mx,mn] = deal(max(I(:),[],'omitnan'),min(I(:),[],'omitnan'));
elseif length(Ilim) == 1 
    [mx,mn] = deal(max(I(:),[],'omitnan'),0);
else
    [mx,mn] = deal(Ilim(2),Ilim(1));
end

%
if (mx - mn) == 0
    In = ones(size(I));
else
    % calculates the normalised pixel intensity
    In = (I - mn)/(mx - mn);
    if nargin == 2
        [In(In < 0),In(In > 1)] = deal(0,1);
    end
end