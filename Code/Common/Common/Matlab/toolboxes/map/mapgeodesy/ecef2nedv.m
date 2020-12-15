function [uNorth, vEast, wDown] = ecef2nedv(u, v, w, lat0, lon0, angleUnit)
%ECEF2NEDV Rotate vector from ECEF to local NED
%
%   [uNorth, vEast, wDown] = ECEF2NEDV(U, V, W, LAT0, LON0) rotates a
%   Cartesian 3-vector with components U, V, W from a geocentric
%   Earth-Centered, Earth-Fixed (ECEF) system to a local north-east-down
%   (NED) system with origin at latitude LAT0 and longitude LON0. The
%   origin latitude and longitude are assumed to be in units of degrees.
%
%   [...] = ECEF2NEDV(..., angleUnit) uses the string angleUnit, which
%   matches either 'degrees' or 'radians', to specify the units of the
%   local origin latitude and longitude.
%
%   The vector components must be the same size (but any of them can be
%   scalar).
%
%   Class support for vector components and angles:
%      float: double, single
%
%   See also ECEF2ENUV, ECEF2NED, NED2ECEFV

% Copyright 2012 The MathWorks, Inc.

if nargin < 6 || map.geodesy.isDegree(angleUnit)
    sinfun = @sind;
    cosfun = @cosd;
else
    sinfun = @sin;
    cosfun = @cos;
end

[vEast, uNorth, wUp] ...
    = ecef2enuvFormula(u, v, w, lat0, lon0, sinfun, cosfun);

wDown = -wUp;
