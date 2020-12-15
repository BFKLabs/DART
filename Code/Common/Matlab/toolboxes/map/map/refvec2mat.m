function R = refvec2mat(refvec,S)
%REFVEC2MAT Convert referencing vector to referencing matrix
%
%   REFVEC2MAT will be removed in a future release. Use
%   refvecToGeoRasterReference instead, which will construct a geographic
%   raster reference object.
%
%   R = REFVEC2MAT(REFVEC,S) converts a referencing vector, REFVEC, to the 
%   referencing matrix R.  REFVEC is a 1-by-3 referencing vector with
%   elements [cells/angleunit north-latitude west-longitude]. S is the size
%   of the data grid that is being referenced. R is a 3-by-2 referencing
%   matrix defining a 2-dimensional affine transformation from pixel
%   coordinates to geographic coordinates.  
%
%   Example 
%   -------
%      % Convert the geoid referencing vector to a referencing matrix
%      load geoid;
%      R = refvec2mat(geoidrefvec, size(geoid))
%
%   See also refvecToGeoRasterReference

% Copyright 1996-2013 The MathWorks, Inc.

% Check if REFVEC is a referencing matrix
if numel(refvec) == 6
    try
        R = refvec;
        checkrefmat(R,mfilename,'R',1);
        return
    catch
    end
end

% Check the referencing vector
checkrefvec(refvec,mfilename,'REFVEC',1);

% Check the size
validateattributes(S,{'double'},{'real','vector','finite'},mfilename,'S',2)

% Calculate R
height = S(1);
cellsize = 1/refvec(1);
lat11 = refvec(2) + cellsize * (0.5 - height);
lon11 = refvec(3) + cellsize * 0.5;
R = makerefmat(lon11, lat11, cellsize, cellsize);
