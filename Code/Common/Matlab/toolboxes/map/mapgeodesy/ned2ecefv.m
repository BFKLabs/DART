function [u, v, w] = ned2ecefv(uNorth, vEast, wDown, lat0, lon0, angleUnit)
%NED2ECEFV Rotate vector from local NED to ECEF
%
%   [U, V, W] = NED2ECEFV(uNorth, vEast, wDown, LAT0, LON0) rotates a
%   Cartesian 3-vector with components uNorth, vEast, wDown from a local
%   north-east-down (NED) system with origin at latitude LAT0 and longitude
%   LON0 to a geocentric Earth-Centered, Earth-Fixed (ECEF) system. The
%   origin latitude and longitude are assumed to be in units of degrees.
%
%   [...] = NED2ECEFV(..., angleUnit) uses the string angleUnit, which
%   matches either 'degrees' or 'radians', to specify the units of the
%   local origin latitude and longitude.
%
%   The vector components must be the same size (but any of them can be
%   scalar).
%
%   Class support for vector components and angles:
%      float: double, single
%
%   See also ECEF2NED, ENU2ECEFV, NED2ECEF

% Copyright 2012 The MathWorks, Inc.

if nargin < 6 || map.geodesy.isDegree(angleUnit)
    sinfun = @sind;
    cosfun = @cosd;
else
    sinfun = @sin;
    cosfun = @cos;
end

[u, v, w] ...
    = enu2ecefvFormula(vEast, uNorth, -wDown, lat0, lon0, sinfun, cosfun);
