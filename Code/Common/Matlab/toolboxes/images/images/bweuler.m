function e = bweuler(a,n)
%BWEULER Euler number of binary image.
%   EUL = BWEULER(BW,N) returns the Euler number for the binary
%   image BW. EUL is a scalar whose value is the number of
%   objects in the image minus the total number of holes in those
%   objects.  N can have a value of either 4 or 8, where 4
%   specifies 4-connected objects and 8 specifies 8-connected
%   objects; if the argument is omitted, it defaults to 8. 
%
%   Class Support
%   -------------
%   BW can be numeric or logical and it must be real, nonsparse 
%   and two-dimensional.
%   EUL is of class double.
%
%   Example
%   -------
%       BW = imread('circles.png');
%       figure, imshow(BW)
%       bweuler(BW)
%
%   See also BWPERIM, BWMORPH.

%   Copyright 1993-2012 The MathWorks, Inc.

% Reference: William Pratt, Digital Image Processing, John Wiley
% and Sons, 1991, pp. 630-634.
  
narginchk(1,2);

validateattributes(a,{'numeric' 'logical'},{'nonsparse' 'real' '2d'},...
              mfilename, 'BW', 1);

if nargin < 2 
    n = 8; 
else
    validateattributes(n,{'double'},{'scalar' 'real' 'integer'},...
                  mfilename, 'N', 2);
end

if n~=8 && n~=4
    error(message('images:bweuler:invalidN'))
end

if n==4,
    lut = 4*[0 0.25 0.25 0 0.25 0  .5 -0.25 0.25  0.5  0 -0.25 0 ...
             -0.25 -0.25 0] + 2;
else
    lut = 4*[0 0.25 0.25 0 0.25 0 -.5 -0.25 0.25 -0.5  0 -0.25 0 ...
             -0.25 -0.25 0] + 2;
end

% Need to zero-pad the input
b = padarray(a,[1 1],'both');

weights = bwlookup(b,lut);
e = (sum(weights(:),[],'double') - 2*numel(b)) / 4;
