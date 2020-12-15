function [xNorth, yEast, zDown] = aer2ned(az, elev, slantRange, angleUnit)
%AER2NED Local spherical AER to Cartesian NED
%
%   [xNorth, yEast, zDown] = AER2NED(az, elev, slantRange) transforms point
%   locations in 3-D from local spherical coordinates (azimuth angle,
%   elevation angle, slantRange) to local Cartesian coordinates (xNorth,
%   yEast, zDown). The input angles are assumed to be in degrees.
%
%   [...] = AER2NED(..., angleUnit) uses the string angleUnit, which
%   matches either 'degrees' or 'radians', to specify the units of the
%   azimuth and elevation angles.
%
%   The coordinate inputs must be the same size (but any of them can be
%   scalar).
%
%   See NED2AER for a description of the north-east-down (NED) local 3-D
%   Cartesian coordinate system, and for definitions of the azimuth angle,
%   elevation angle, and slant range.
%
%   The transformation is similar to SPH2CART, except that the input angles
%   are in degrees by default and the Z-axis is directed downward.
%
%   Class support for inputs az, elev, slantRange:
%      float: double, single
%
%   See also AER2ENU, NED2AER

% Copyright 2012 The MathWorks, Inc.

if nargin < 4 || map.geodesy.isDegree(angleUnit)
    sinfun = @sind;
    cosfun = @cosd;
else
    sinfun = @sin;
    cosfun = @cos;
end

[yEast, xNorth, zUp] = aer2enuFormula(az, elev, slantRange, sinfun, cosfun);
zDown = -zUp;
