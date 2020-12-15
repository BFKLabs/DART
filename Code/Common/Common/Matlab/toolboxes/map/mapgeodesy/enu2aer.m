function [az, elev, slantRange] = enu2aer(xEast, yNorth, zUp, angleUnit)
%ENU2AER Local Cartesian ENU to spherical AER
%
%   [az, elev, slantRange] = ENU2AER(xEast, yNorth, zUp) transforms point
%   locations in 3-D from local Cartesian coordinates (xEast, yNorth, zUp)
%   to local spherical coordinates (azimuth angle, elevation angle, slant
%   range). The output angles are returned in degrees.
%
%   [...] = ENU2AER(..., angleUnit) uses the string angleUnit, which
%   matches either 'degrees' or 'radians', to specify the units of the
%   output angles.
%
%   The coordinate inputs must be the same size (but any of them can be
%   scalar).
%
%   East-north-up (ENU) system is a right-handed local Cartesian system
%   with the X-axis directed east and parallel to the local tangent plane,
%   the Y-axis directed north, and the Z-axis directed upward along the
%   local normal to the ellipsoid.
%
%   As always, the azimuth angle is measured clockwise (east) from north,
%   from the perspective of a viewer looking down on the local horizontal
%   plane. Equivalently, in the case of ENU, it is measured clockwise from
%   the positive Y-axis in the direction of the positive X-axis. The
%   elevation angle is the angle between a vector from the origin and the
%   local horizontal plane. The slant range is the 3-D Euclidean distance
%   from the origin.
%
%   The transformation is similar to CART2SPH, except that the output
%   angles are in degrees by default and the first output angle is measured
%   clockwise from the positive Y-axis rather than counterclockwise from
%   the positive X-axis, and has a value in the open interval [0 360) in
%   degrees, or [0 2*pi) in radians.
%
%   Class support for inputs xEast, yNorth, zUp:
%      float: double, single
%
%   See also AER2ENU, NED2AER

% Copyright 2012 The MathWorks, Inc.

if nargin < 4 || map.geodesy.isDegree(angleUnit)
    atan2fun = @atan2d;
else
    atan2fun = @atan2;
end

[az, elev, slantRange] = enu2aerFormula(xEast, yNorth, zUp, atan2fun);
