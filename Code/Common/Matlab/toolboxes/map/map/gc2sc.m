function [newlat,newlong,range]=gc2sc(lat,long,az,units)
%GC2SC  Center and radius of great circle
%
%  [LAT,LON,RADIUS] = GC2SC(LAT0,LON0,AZ) converts a great circle from
%  great circle notation (i.e., lat, lon, azimuth, where (lat, lon) is
%  on the circle) to small circle notation (i.e., lat, lon, radius,
%  where (lat, lon) is the center of the circle and radius is 90 degrees,
%  which is a definition of a great circle).  A great circle has two
%  centers and one is chosen arbitrarily.  The other is its antipode.
%  All inputs and outputs are in units of degrees.
%
%  [LAT,LON,RADIUS] = GC2SC(LAT0,LON0,AZ,ANGLEUNITS) uses the string
%  ANGLEUNITS to specify the angle units of the inputs and outputs.
%  ANGLEUNITS can equal either 'degrees' or 'radians'.
%
%  MAT = GC2SC(...) returns a single output, where MAT = [LAT LON RADIUS].
%
%  See also SCXSC, GCXGC, GCXSC.

% Copyright 1996-2011 The MathWorks, Inc.
% Written by:  E. Brown, E. Byrns

error(nargchk(3, 4, nargin, 'struct'))

if nargin == 3
	units='degrees';
end

%  Convert input angles to radians

[lat, long, az] = toRadians(units, lat, long, az);

% Zenith lies orthogonal to the path of the great circle, at 90 degrees distance

[newlat,newlong] = reckon('gc',lat,long,pi/2*ones(size(lat)),...
                          az+pi/2,'radians');
range = pi/2*ones(size(lat));

%  Convert output to proper units

newlong = npi2pi(newlong,'radians','exact');

[newlat, newlong, range] = fromRadians(units, newlat, newlong, range);

%  Set output arguments if necessary

if nargout < 3;  newlat = [newlat newlong range];  end
