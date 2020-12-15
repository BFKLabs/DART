function [lat, lon, h] = aer2geodetic( ...
    az, elev, slantRange, lat0, lon0, h0, spheroid, angleUnit)
%AER2GEODETIC Local spherical AER to geodetic
%
%   [LAT, LON, H] = AER2GEODETIC(AZ, ELEV, SLANTRANGE, LAT0, LON0, H0, ...
%       SPHEROID) transforms point locations in 3-D from local spherical
%   coordinates (azimuth angle, elevation angle, slant range) to geodetic
%   coordinates (LAT, LON, H), given a local coordinate system defined by
%   the geodetic coordinates of its origin (LAT0, LON0, H0).  The geodetic
%   coordinates refer to the reference body specified by the spheroid
%   object, SPHEROID. The slant range and ellipsoidal height H0 must be
%   expressed in the same length unit as the spheroid.  Ellipsoidal height
%   H will be expressed in this unit, also.  The input azimuth and
%   elevation angles, and input and output latitude and longitude angles,
%   are in degrees by default.
%
%   [...] = AER2GEODETIC(..., angleUnit) uses the string angleUnit, which
%   matches either 'degrees' or 'radians', to specify the units of the
%   azimuth, elevation, latitude, and longitude angles.
%
%   The coordinate inputs must be the same size (but any of them can be
%   scalar).
%
%   Class support for inputs AZ, ELEV, SLANTRANGE, LAT0, LON0, H0:
%      float: double, single
%
%   See also AER2ECEF, ENU2GEODETIC, GEODETIC2AER, NED2GEODETIC

% Copyright 2012 The MathWorks, Inc.

inDegrees = (nargin < 8 || map.geodesy.isDegree(angleUnit));

[x, y, z] = aer2ecefFormula( ...
    az, elev, slantRange, lat0, lon0, h0, spheroid, inDegrees);

if inDegrees
    [lat, lon, h] = spheroid.ecef2geodetic(x, y, z);
else
    [lat, lon, h] = spheroid.ecef2geodetic(x, y, z, 'radian');
end
