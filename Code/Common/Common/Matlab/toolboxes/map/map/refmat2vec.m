function refvec = refmat2vec(R,S)
%REFMAT2VEC Convert referencing matrix to referencing vector
%
%   REFMAT2VEC will be removed in a future release. Use
%   refmatToGeoRasterReference instead, which will construct a geographic
%   raster reference object.
%
%   REFVEC = REFMAT2VEC(R,S) converts a referencing matrix, R, to the 
%   referencing vector REFVEC.  R is a 3-by-2 referencing matrix defining a
%   2-dimensional affine transformation from pixel coordinates to
%   geographic coordinates.  S is the size of the data grid that is being
%   referenced. REFVEC is a 1-by-3 referencing vector with elements
%   [cells/angleunit north-latitude west-longitude].  
%
%   Example 
%   -------
%      % Verify the conversion of the geoid referencing vector to a
%      % referencing matrix.
%      load geoid
%      geoidrefvec
%      R = refvec2mat(geoidrefvec, size(geoid))
%      refvec = refmat2vec(R, size(geoid))
%
%   See also refmatToGeoRasterReference

% Copyright 1996-2013 The MathWorks, Inc.

% Check if R is a referencing vector
if numel(R) == 3
    try
        refvec = R;
        checkrefvec(refvec,mfilename,'REFVEC',1);
        return
    catch
    end
end

% Check the referencing matrix
checkrefmat(R,mfilename,'R',1);
if (R(1,1) ~= 0) || (R(2,2) ~= 0)
    error('map:refmat2vec:rotationInRefmat', 'R must be irrotational.');
end

if R(1,2) <= 0
    error('map:refmat2vec:rowNotIncreasing', ...
        'Row subscript must increase with latitude.')
end

if R(2,1) <= 0
    error('map:refmat2vec:colNotIncreasing', ...
        'Column subscript must increase with longitude.')       
end

if R(1,2) ~= R(2,1)
    error('map:refmat2vec:cellsNotSquare','Grid cells must be square.')
end

% Check the size
validateattributes(S, {'double'}, {'real','vector','finite'}, mfilename,'S',2)

% Calculate refvec
[lat, lon] = pix2latlon(R, S(1)+.5, .5);
[latm1, ~] = pix2latlon(R, S(1)-.5, .5);
refvec = [1/(lat-latm1) lat lon ];
