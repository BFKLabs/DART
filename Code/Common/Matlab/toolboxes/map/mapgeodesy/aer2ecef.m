function [x, y, z] = aer2ecef( ...
    az, elev, slantRange, lat0, lon0, h0, spheroid, angleUnit)
%AER2ECEF Local spherical AER to geocentric ECEF
%
%   [X, Y, Z] = AER2ECEF(AZ, ELEV, SLANTRANGE, LAT0, LON0, H0, SPHEROID)
%   transforms point locations in 3-D from local spherical coordinates
%   (azimuth angle, elevation angle, slant range) to geocentric
%   Earth-Centered Earth-Fixed (ECEF) coordinates (X, Y, Z), given a local
%   coordinate system defined by the geodetic coordinates of its origin
%   (LAT0, LON0, H0).  The geodetic coordinates refer to the reference body
%   specified by the spheroid object, SPHEROID.  The slant range and
%   ellipsoidal height H0 must be expressed in the same length unit as the
%   spheroid.  Outputs X, Y, and Z will be expressed in this unit, also.
%   The input azimuth, elevation, latitude, and longitude angles are in
%   degrees by default.
%
%   [...] = AER2ECEF(..., angleUnit)  uses the string angleUnit, which
%   matches either 'degrees' or 'radians', to specify the units of the
%   azimuth, elevation, latitude, and longitude angles.
%
%   The coordinate inputs must be the same size (but any of them can be
%   scalar).
%
%   Class support for inputs AZ, ELEV, SLANTRANGE, LAT0, LON0, H0:
%      float: double, single
%
%   See also AER2GEODETIC, ECEF2AER, ENU2ECEF, NED2ECEF

% Copyright 2012 The MathWorks, Inc.

inDegrees = (nargin < 8 || map.geodesy.isDegree(angleUnit));

[x, y, z] = aer2ecefFormula( ...
    az, elev, slantRange, lat0, lon0, h0, spheroid, inDegrees);
