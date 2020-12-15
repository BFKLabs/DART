function [u, v, w] = enu2ecefv(uEast, vNorth, wUp, lat0, lon0, angleUnit)
%ENU2ECEFV Rotate vector from local ENU to ECEF
%
%   [U, V, W] = ENU2ECEFV(uEast, vNorth, wUp, LAT0, LON0) rotates a
%   Cartesian 3-vector with components uEast, vNorth, wUp from a local
%   east-north-up (ENU) system with origin at latitude LAT0 and longitude
%   LON0 to a geocentric Earth-Centered, Earth-Fixed (ECEF) system. The
%   origin latitude and longitude are assumed to be in units of degrees.
%
%   [...] = ENU2ECEFV(..., angleUnit) uses the string angleUnit, which
%   matches either 'degrees' or 'radians', to specify the units of the
%   local origin latitude and longitude.
%
%   The vector components must be the same size (but any of them can be
%   scalar).
%
%   Class support for vector components and angles:
%      float: double, single
%
%   See also ECEF2ENU, ENU2ECEF, NED2ECEFV

% Copyright 2012 The MathWorks, Inc.

if nargin < 6 || map.geodesy.isDegree(angleUnit)
    sinfun = @sind;
    cosfun = @cosd;
else
    sinfun = @sin;
    cosfun = @cos;
end

[u, v, w] ...
    = enu2ecefvFormula(uEast, vNorth, wUp, lat0, lon0, sinfun, cosfun);
