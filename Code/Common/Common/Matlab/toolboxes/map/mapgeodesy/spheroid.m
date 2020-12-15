classdef spheroid < matlab.mixin.CustomDisplay
%SPHEROID Abstract superclass for oblateSpheroid and referenceSphere
%
%   This class customizes the display for its subclasses, which must define
%   DerivedProperties and DisplayFormat properties.
%
%   It also declares the syntax and provides the MATLAB help for three 3-D
%   geometric transformation methods.
%   
%   SPHEROID methods:
%      geodetic2ecef - Transform geodetic to geocentric (ECEF) coordinates
%      ecef2geodetic - Transform geocentric (ECEF) to geodetic coordinates
%      ecefOffset    - Cartesian ECEF offset between geodetic positions
%
% See also oblateSpheroid, referenceEllipsoid, referenceSphere

% Copyright 2012 The MathWorks, Inc.

%-------------------------- Customize disp ----------------------------

properties (Constant, Abstract, Hidden, Access = protected)
    % Cell string listing names "derived" properties, to be displayed with
    % their values suppressed (even for scalar objects).
    DerivedProperties
    
    % Custom format string: '', or a string accepted by the FORMAT
    % function('short', 'longG', ...).  If non-empty, it is used to
    % override the current display formatting for floating point values.
    DisplayFormat
end

properties (Constant, Hidden, Access = private)
    % Use the map:geodesy message catalog to construct the "derived
    % properties header," to enable localization. This message has a
    % constant string, so optimize by caching the message object here and
    % avoiding the need for access each time disp is called on a subclass
    % instance.
    DerivedPropertiesHeaderMessage ...
        = message('map:geodesy:derivedSpheroidPropertiesHeader');
end

methods (Access = protected)
    
    function displayScalarObject(self)
        % (1) Overload the default and suppress display of "derived"
        %     properties, without making them hidden.
        %
        % (2) When non-empty, use the specified DisplayFormat instead of
        %     the current format setting.
        
        header = getHeader(self);
        disp(header);
        
        % Construct a structure that contains the defining properties and
        % their values, and excludes the derived properties.
        definingProperties = setdiff( ...
            properties(self), self.DerivedProperties, 'stable');
        
        values = cellfun(@(propertyName) self.(propertyName), ...
            definingProperties, 'UniformOutput', false);
        
        s = cell2struct(values, definingProperties, 1);
        
        % Manage numerical display format for defining properties.
        if ~isempty(self.DisplayFormat)
            fmt = get(0,'format');
            clean = onCleanup(@() format(fmt));
            format(self.DisplayFormat)
        end
        
        disp(s);
        
        % Display names only for derived properties, taking care to be
        % consistent with the current format spacing.
        looseSpacing = strcmp(get(0,'FormatSpacing'),'loose');
        if ~looseSpacing
            % We want a vertical space before the "derived properties
            % header" in any case.  It comes automatically with 'loose',
            % but needs to be added with 'compact'.
            fprintf('\n')
        end
        fprintf('  %s\n\n', getString(self.DerivedPropertiesHeaderMessage))
        fprintf('    %s\n', self.DerivedProperties{:})
        if looseSpacing
            % Add a trailing newline only when spacing is loose.
            fprintf('\n')
        end
        
        footer = getFooter(self);
        if ~isempty(footer)
            disp(footer);
        end
    end
    
    function header = getHeader(self)
        if ~isscalar(self)
            header = getHeader@matlab.mixin.CustomDisplay(self);
        else
            % Use the map:geodesy message catalog to construct the custom
            % header, to enable localization.
            className = matlab.mixin.CustomDisplay.getClassNameForHeader(self);
            msg = message('map:geodesy:definingSpheroidPropertiesHeader', className);
            header = sprintf('%s\n', getString(msg));
        end
    end
    
end

%----------------- Help for 3-D Transformation Methods --------------------

methods (Abstract = true)
  
%GEODETIC2ECEF Transform geodetic to geocentric (ECEF) coordinates
%
%   [X, Y, Z] = GEODETIC2ECEF(SPHEROID, LAT, LON, H) transforms geodetic
%   point locations specified by the geodetic coordinate arrays LAT
%   (geodetic latitude), LON (longitude), and H (ellipsoidal height) to
%   geocentric Earth-Centered Earth-Fixed (ECEF) Cartesian coordinates X,
%   Y, and Z.  The geodetic coordinates refer to the reference body
%   specified by the spheroid object, SPHEROID.  H must be expressed in the
%   same length unit as the spheroid.  X, Y, and Z will be expressed in
%   these units also.
%
%   [...] = GEODETIC2ECEF(..., angleUnit) uses the string angleUnit, which
%   matches either 'degrees' or 'radians', to specify the units of the
%   latitude and longitude coordinates.
%
%   The coordinate inputs must be the same size (but any of them can be
%   scalar).
%
%   The geocentric Cartesian (ECEF) coordinate system is fixed with respect
%   to the Earth, with its origin at the center of the spheroid and its
%   positive X-, Y-, and Z-axes intersecting the surface at the following
%   points:
%
%               LAT   LON
%      X-axis:    0     0     (Equator at the Prime Meridian)
%      Y-axis:    0    90     (Equator at 90-degrees East)
%      Z-axis:   90     0     (North Pole)
%
%   Class support for inputs LAT, LON, H:
%      float: double, single
%
%   See also spheroid/ECEF2GEODETIC, spheroid/ecefOffset
[x, y, z] = geodetic2ecef(spheroid, lat, lon, h, angleUnit)

%ECEF2GEODETIC Transform geocentric (ECEF) to geodetic coordinates
%
%   [LAT, LON, H] = ECEF2GEODETIC(SPHEROID, X, Y, Z) transforms point
%   locations in geocentric Earth-Centered Earth-Fixed (ECEF) Cartesian
%   coordinates, stored in the coordinate arrays X, Y, and Z, to geodetic
%   coordinates LAT (geodetic latitude), LON (longitude), and H
%   (ellipsoidal height). The geodetic coordinates refer to the reference
%   body specified by the spheroid object, SPHEROID. X, Y, and Z must be
%   expressed in the same unit of length as the spheroid.  H will be
%   expressed this unit, also.
%
%   [...] = ECEF2GEODETIC(..., angleUnit) uses the string angleUnit, which
%   matches either 'degrees' or 'radians', to specify the units of the
%   latitude and longitude coordinates.
%
%   The coordinate inputs must be the same size (but any of them can be
%   scalar).
%
%   Class support for inputs X, Y, Z:
%      float: double, single
%
%   See also spheroid/GEODETIC2ECEF, spheroid/ecefOffset
[lat, lon, h] = ecef2geodetic(spheroid, x, y, z, angleUnit)

%ecefOffset Cartesian ECEF offset between geodetic positions
%
%   [deltaX, deltaY, deltaZ] = ecefOffset(SPHEROID, ...
%       LAT1, LON1, H1, LAT2, LON2, H2) returns the offset from the
%   geodetic position specified by LAT1, LON1, and H1 to the position
%   specified by LAT2, LON2, and H2, as a Cartesian 3-vector with
%   components deltaX, deltaY, deltaZ.  The geodetic latitudes, longitudes,
%   and heights refer to the reference body specified by the spheroid
%   object, SPHEROID.  The components deltaX, deltaY, and deltaZ refer to a
%   spheroid-centric Earth-Centered Earth-Fixed (ECEF) Cartesian system. H1
%   and H2 must be expressed in the same length unit as the spheroid.
%   deltaX, deltaY, and deltaZ will be expressed in these units, also.
%
%   [...] = ecefOffset(..., angleUnit) uses the string angleUnit, which
%   matches either 'degrees' or 'radians', to specify the units of the
%   latitude and longitude coordinates.
%
%   The coordinate inputs must be the same size (but any of them can be
%   scalar).
%
%   Class support for inputs LAT1, LON1, H1, LAT2, LON2, H2:
%      float: double, single
%
%   See also spheroid/GEODETIC2ECEF, spheroid/ECEF2GEODETIC
[deltaX, deltaY, deltaZ] = ecefOffset(spheroid, ...
    lat1, lon1, h1, lat2, lon2, h2, angleUnit)

end
end
