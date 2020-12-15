function [latbin,lonbin,count] = hista(lats,lons,binarea,ellipsoid,units)
%HISTA  Histogram for geographic points with equal-area bins
%
%   [LAT,LON,CT] = HISTA(LAT0,LON0) computes a spatial histogram of
%   geographic data using equal area binning.  The bin area is 100 square
%   kilometers.  The outputs are the location of bins in which the data was
%   accumulated, as well as the number of occurrences in each bin. The
%   input and output latitudes and longitudes are in units of degrees.
%
%   [LAT,LON,CT] = HISTA(LAT0,LON0,BINAREA) uses the bin size specified by
%   the input BINAREA, which must be in square kilometers.
%
%   [LAT,LON,CT] = HISTA(LAT0,LON0,BINAREA,ELLIPSOID) assumes the data is
%   distributed on the reference ellipsoid defined by ELLIPSOID. ELLIPSOID
%   is a reference ellipsoid (oblate spheroid) object, a reference sphere
%   object, or a vector of the form [semimajor_axis, eccentricity].
%
%   [LAT,LON,CT] = HISTA(..., ANGLEUNITS) uses the string ANGLEUNITS to
%   define the angle units of the inputs and outputs.  ANGLEUNITS can be
%   'degrees' or 'radians'.
%
%  See also HISTR.

% Copyright 1996-2011 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

narginchk(2,5)
if nargin == 2
    binarea = 100;
    ellipsoid = [1 0];
    units = 'degrees';
elseif nargin == 3
    ellipsoid = [1 0];
    units = 'degrees';
elseif nargin == 4
    if ischar(ellipsoid)
        units = ellipsoid;
        ellipsoid = [1 0];
    else
        units = 'degrees';
    end
end

if ~isequal(size(lats),size(lons))
    error(message('map:validate:inconsistentSizes2','HISTA','LAT','LON'))
end

validateattributes(binarea,{'double'},{'positive','finite','scalar'}, ...
    'HISTA', 'BINAREA', 3)

binarea = ignoreComplex(binarea, mfilename, 'binarea');

%  Convert to degrees and ensure column vectors
%  Ensure that the longitude data is between -180 and 180

[lats, lons] = toDegrees(units, lats(:), lons(:));
lons = wrapTo180(lons);

%  Compute the mean of the input data. Center the matrix on the
%  mean to avoid problems like the north pole getting multiple 
%  bins.

datamean = meanm(lats,lons,ellipsoid,'degrees');

%  Convert to equal area coordinates

[x,y] = grn2eqa(lats,lons,datamean,ellipsoid,'degrees');

%  Determine the length of a side of the bin in radians

lenside = km2deg(sqrt(binarea));

%  Determine the delta in x and y direction.  Remember lenside is in radians

[xdel,ydel] = grn2eqa(lenside,lenside,[0 0 0],ellipsoid,'degrees');

%  Determine the x and y limits of the equal area map

xlim = [min(x-xdel) max(x+xdel)];
ylim = [min(y-ydel) max(y+ydel)];

%  Construct a sparse matrix to bin the data into

[map,refvec] = spzerom(ylim,xlim,1/xdel);

%  Bin the data into the sparse matrix
  
indx = setpostn(map,refvec,y,x);
for i = 1:length(indx)
    map(indx(i)) = map(indx(i)) + 1;
end

%  Determine the locations of the binned data

[row,col,count] = find(map); 
[ybin,xbin]     = setltln(map,refvec,row,col);

%  Transform the xbin and ybin back to Greenwich

[latbin,lonbin] = eqa2grn(xbin,ybin,datamean,ellipsoid,'degrees');

%  Convert back to the proper units

[latbin, lonbin] = fromDegrees(units, latbin, lonbin);
