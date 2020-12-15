function [uEast, vNorth, wUp] = ecef2enuv(u, v, w, lat0, lon0, angleUnit)
%ECEF2ENUV Rotate vector from ECEF to local ENU
%
%   [uEast, vNorth, wUp] = ECEF2ENUV(U, V, W, LAT0, LON0) rotates a
%   Cartesian 3-vector with components U, V, W from a geocentric
%   Earth-Centered, Earth-Fixed (ECEF) system to a local east-north-up
%   (ENU) system with origin at latitude LAT0 and longitude LON0. The
%   origin latitude and longitude are assumed to be in units of degrees.
%
%   [...] = ECEF2ENUV(..., angleUnit) uses the string angleUnit, which
%   matches either 'degrees' or 'radians', to specify the units of the
%   local origin latitude and longitude.
%
%   The vector components must be the same size (but any of them can be
%   scalar).
%
%   Class support for vector components and angles:
%      float: double, single
%
%   See also ECEF2ENU, ECEF2NEDV, ENU2ECEFV

% Copyright 2012 The MathWorks, Inc.

if nargin < 6 || map.geodesy.isDegree(angleUnit)
    sinfun = @sind;
    cosfun = @cosd;
else
    sinfun = @sin;
    cosfun = @cos;
end

[uEast, vNorth, wUp] ...
    = ecef2enuvFormula(u, v, w, lat0, lon0, sinfun, cosfun);
