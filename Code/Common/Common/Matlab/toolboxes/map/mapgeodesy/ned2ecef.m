function [x, y, z] = ned2ecef( ...
    xNorth, yEast, zDown, lat0, lon0, h0, spheroid, angleUnit)
%NED2ECEF Local Cartesian NED to geocentric ECEF
%
%   [X, Y, Z] = NED2ECEF(xNorth, yEast, zDown, LAT0, LON0, H0, SPHEROID)
%   transforms point locations in 3-D from local Cartesian coordinates
%   (xNorth, yEast, zDown) to geocentric Earth-Centered Earth-Fixed (ECEF)
%   coordinates (X, Y, Z), given a local coordinate system defined by the
%   geodetic coordinates of its origin (LAT0, LON0, H0).  The geodetic
%   coordinates refer to the reference body specified by the spheroid
%   object, SPHEROID.  Inputs xNorth, yEast, zDown, and ellipsoidal height
%   H0 must be expressed in the same length unit as the spheroid.  Outputs
%   X, Y, and Z will be expressed in this unit, also.  The input latitude
%   and longitude angles are in degrees by default.
%
%   [...] = NED2ECEF(..., angleUnit) uses the string angleUnit, which
%   matches either 'degrees' or 'radians', to specify the units of the
%   latitude and longitude angles.
%
%   The coordinate inputs must be the same size (but any of them can be
%   scalar).
%
%   Class support for inputs xNorth, yEast, zDown, LAT0, LON0, H0:
%      float: double, single
%
%   See also AER2ECEF, ECEF2NED, ENU2ECEF, NED2GEODETIC

% Copyright 2012 The MathWorks, Inc.

inDegrees = (nargin < 8 || map.geodesy.isDegree(angleUnit));

[x, y, z] = enu2ecefFormula( ...
    yEast, xNorth, -zDown, lat0, lon0, h0, spheroid, inDegrees);
