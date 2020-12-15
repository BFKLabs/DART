classdef oblateSpheroid < spheroid
%oblateSpheroid Oblate ellipsoid of revolution
%
%   An oblate spheroid object encapsulates the interrelated intrinsic
%   properties of a oblate ellipsoid of revolution. An oblate spheroid is
%   symmetric about its polar axis and flattened at the poles, and includes
%   the perfect sphere as a special case.
%
%   oblateSpheroid properties:
%      SemimajorAxis - Equatorial radius of spheroid, a
%      SemiminorAxis - Distance from center of spheroid to pole, b
%      InverseFlattening - Reciprocal of flattening, 1/f = a /(a - b)
%      Eccentricity - First eccentricity of spheroid, ecc = sqrt(a^2 - b^2)/a
%
%   oblateSpheroid properties (read-only):
%      Flattening - Flattening of spheroid, f = (a - b)/a
%      ThirdFlattening - Third flattening of spheroid, n = (a - b)/(a + b)
%      MeanRadius - Mean radius of spheroid, (2*a + b)/3
%      SurfaceArea - Surface area of spheroid
%      Volume - Volume of spheroid
%
%   oblateSpheroid methods:
%      geodetic2ecef - Transform geodetic to geocentric (ECEF) coordinates
%      ecef2geodetic - Transform geocentric (ECEF) to geodetic coordinates
%      ecefOffset    - Cartesian ECEF offset between geodetic positions
%
%   The values of the first four geometric properties listed above can be
%   reset. However, only two parameters are actually needed to fully
%   characterize an oblate spheroid, so updates to these parameters are not
%   independent. Instead, they adhere to the following self-consistent
%   rules:
%
%    1. The only way to change the SemimajorAxis property is to set it
%       directly.
%
%    2. If the SemimajorAxis property is reset, the SemiminorAxis
%       property is updated as needed to preserve the aspect of the
%       spheroid. The values of the InverseFlattening and Eccentricity
%       properties are unchanged.
%
%    3. If any of the following three properties, SemiminorAxis,
%       InverseFlattening, or Eccentricity, are reset, then the values of
%       the other two properties are adjusted to match the new aspect.
%       The value of the SemimajorAxis property is unchanged.
%
%   In other words, given a oblate spheroid s, 
%
%       s.SemimajorAxis = a        updates semimajor and semiminor axes,
%                                  a and b
%
%       s.SemiminorAxis = b,       updates the semiminor axis, b, 
%       s.InverseFlatting = 1/f,   the eccentricity, ecc, and the inverse
%       or s.Eccentricity = ecc    flattening, 1/f
%
%   Note
%   ----
%   When you define a spheroid in terms of a and b (rather than a and 1/f
%   or a and ecc), a small loss of precision in the last few digits of f,
%   ecc, and n is possible. This is unavoidable, but does not affect the
%   results of practical computations.
%
%   Example
%   -------
%   % Start with a unit sphere by default.
%   s = oblateSpheroid
%
%   % Reset the semimajor axis to match the equatorial radius of the
%   % GRS 80 reference ellipsoid, resulting in a sphere with radius
%   % 6,378,137 meters.
%   s.SemimajorAxis = 6378137
%
%   % Reset the inverse flattening to the standard value for GRS 80,
%   % resulting in an oblate spheroid with a semiminor axis consistent
%   % with the value, 6,356,752.3141, tabulated in DMA Technical Memorandum
%   % 8358.1, "Datums, Ellipsoids, Grids, and Grid Reference Systems."
%   s.InverseFlattening = 298.257222101
%
%   See also referenceEllipsoid, referenceSphere.

% Copyright 2011-2012 The MathWorks, Inc.

    %------------------- Properties: Public + visible --------------------
    
    properties (Dependent = true, Access = public)
        %SemimajorAxis Equatorial radius of spheroid
        %
        %   Positive, finite scalar. When set to a new value, the
        %   SemiminorAxis property scales as needed to preserve the shape
        %   of the spheroid and the values of shape-related properties
        %   including InverseFlattening and Eccentricity.
        %
        %   Default value: 1
        SemimajorAxis
        
        %SemiminorAxis Distance from center of spheroid to pole
        %
        %   Nonnegative, finite scalar. Less than or equal to
        %   SemimajorAxis. When set to a new value, the SemimajorAxis
        %   property remains unchanged but the shape of the spheroid
        %   changes, and this is reflected in changes in the values of
        %   InverseFlattening, Eccentricity, and other shape-related
        %   properties.
        %
        %   Default value: 1
        SemiminorAxis
        
        %InverseFlattening Reciprocal of flattening
        %
        %   Inverse flattening of spheroid, 1/f = a/(a - b), where a and b
        %   are the semimajor and semiminor axes of the spheroid. Positive
        %   scalar in the interval [1 Inf]. A value of 1/f = Inf designates
        %   a perfect sphere. As 1/f value approaches 1, the spheroid
        %   approaches a flattened disk. When set to a new value, other
        %   shape-related properties are updated, including Eccentricity.
        %   The SemimajorAxis value is unaffected by changes to 1/f, but
        %   the value of the SemiminorAxis property adjusts to reflect the
        %   new shape.
        %
        %   Default value: Inf
        InverseFlattening
        
        %Eccentricity First eccentricity of spheroid
        %
        %   Normalized distance from center to foci in a meridional plane,
        %   ecc = sqrt(a^2 - b^2)/a, where a and b are the semimajor and
        %   semiminor axes of the spheroid.  Nonnegative scalar less than
        %   or equal to 1. A value of 0 designates a perfect sphere.  When
        %   set to a new value, other shape-related properties are updated,
        %   including InverseFlattening. The SemimajorAxis value is
        %   unaffected by changes to ecc, but the value of the
        %   SemiminorAxis property adjusts to reflect the new shape.
        %
        %   Default value: 0
        Eccentricity
    end
    
    properties (GetAccess = public, SetAccess = private)
        
        %Flattening Flattening of spheroid
        %
        %   Flattening of the oblate spheroid, f = (a - b) / a, where a
        %   and b are the semimajor and semiminor axes of the spheroid.
        Flattening = 0;
        
        
        %ThirdFlattening Third flattening of spheroid
        %
        %   Third flattening of the oblate spheroid, n = (a - b) / (a + b),
        %   where a and b are the semimajor and semiminor axes of the
        %   spheroid.
        ThirdFlattening = 0;
        
    end
    
    properties (Dependent = true, SetAccess = private)
        
        %MeanRadius Mean radius of oblate spheroid
        %
        %   Mean radius of the oblate spheroid, (2*a + b) / 3, where a
        %   and b are the semimajor and semiminor axes of the spheroid.
        %
        %   Example
        %   -------
        %   % Mean radius of the WGS 84 ellipsoid in meters
        %   format long g
        %   s = oblateSpheroid
        %   s.SemimajorAxis = 6378137
        %   s.InverseFlattening = 298.257223563
        %   radius = s.MeanRadius
        MeanRadius
        
        %SurfaceArea Surface area of oblate spheroid
        %
        %   Surface area of the oblate spheroid in units of area consistent
        %   with the unit of length used for the SemimajorAxis and
        %   SemiminorAxis properties.
        %
        %   Example
        %   -------
        %   % Surface area of a rather flat spheroid
        %   format long g
        %   s = oblateSpheroid
        %   s.SemiminorAxis = 1/2
        %   surfarea = s.SurfaceArea
        SurfaceArea
        
        
        %Volume  Volume of oblate spheroid
        %
        %   Volume of the oblate spheroid in units of volume consistent
        %   with the unit of length used for the SemimajorAxis and
        %   SemiminorAxis properties.
        %
        %   Example
        %   -------
        %   % Volume of a spheroid approximating the planet Mars,
        %   % in cubic meters
        %   format long g
        %   s = oblateSpheroid
        %   s.SemimajorAxis = 3396900 % Length in meters
        %   s.Eccentricity = 0.1105
        %   vol = s.Volume
        Volume
        
    end
    
    %-------------------------- Hidden properties -------------------------
    
    % Because of their interdependence, the 4 settable properties have to
    % be implemented as dependent properties. Their values are actually
    % stored in the following 4 hidden (and non-dependent) properties,
    % which are updated carefully by the set methods to ensure consistency
    % (both mutual consistency and consistency with the Flattening and
    % ThirdFlattening properties, as well).

    % The default values given below, together with the defaults for the
    % Flattening and ThirdFlattening properties, imply that the default
    % oblate sphere is the units sphere.  (An explicit constructor is not
    % needed and is omitted.)
    
    properties (Hidden = true, Access = protected)
        a = 1;        % Stores value of SemimajorAxis
        b = 1;        % Stores value of SemiminorAxis
        invf = Inf;   % Stores value of InverseFlattening
        ecc = 0;      % Stores value of Eccentricity
    end
    
    properties (Constant, Hidden, Access = protected)
        % Control the display of oblateSpheroid objects.
        
        DerivedProperties = {'Flattening','ThirdFlattening',...
            'MeanRadius','SurfaceArea','Volume'};
        
        DisplayFormat = 'longG';
    end
    
    %--------------------------- Get methods ------------------------------
    
    methods
        
        function a = get.SemimajorAxis(self)
            a = self.a;
        end
        
        function b = get.SemiminorAxis(self)
            b = self.b;
        end
        
        function invf = get.InverseFlattening(self)
            invf = self.invf;
        end
        
        function ecc = get.Eccentricity(self)
            ecc = self.ecc;
        end
        
        function radius = get.MeanRadius(self)
            radius = (2*self.a + self.b) / 3;
        end
        
        function surfarea = get.SurfaceArea(self)
            e = self.ecc;
            if e < 1e-10
                % Sphere (or nearly spherical ellipsoid)
                surfarea = 4 * pi * self.a^2;
            elseif e < 1
                % Intermediate
                s = (log((1+e)/(1-e))/e)/2;
                surfarea = 2 * pi * (self.a^2 + s * self.b^2);
            else
                % Flat, two-sided disk
                surfarea = 2 * pi * self.a^2;
            end
        end
        
        function vol = get.Volume(self)
            vol = (4*pi/3) * self.b * self.a^2;
        end
        
    end
    
    %---------------------------- Set methods -----------------------------
    
    methods
        
        function self = set.SemimajorAxis(self, a)
            validateattributes(a, ...
                {'double'}, {'real','positive','finite','scalar'}, ...
                '', 'SemimajorAxis');
            self.a = a;
            self.b = (1 - self.Flattening) * a;
        end
        
        
        function self = set.SemiminorAxis(self, b)
            validateattributes(b, ...
                {'double'}, {'real','nonnegative','finite','scalar'}, ...
                '', 'SemiminorAxis');
            a_ = self.a;
            map.internal.assert(b <= a_, ...
                'map:validate:expectedShorterSemiminorAxis')
            self.b = b;            
            self.ecc = sqrt(a_^2 - b^2) / a_;
            f = (a_ - b) / a_;
            self.invf = 1/f;
            self.Flattening = f;
            self.ThirdFlattening = f / (2 - f);
        end
        
        
        function self = set.InverseFlattening(self, invf)
            validateattributes(invf, {'double'}, ...
                {'real','scalar','>=',1},'','InverseFlattening');
            f  = 1 / invf;
            self.ecc  = sqrt((2 - f) * f);
            self.invf = invf;
            self.Flattening = f;
            self.ThirdFlattening = f / (2 - f);
            self.b = (1 - self.Flattening) * self.a;
        end
        
        
        function self = set.Eccentricity(self, ecc)
            validateattributes(ecc, {'double'}, ...
                {'real','nonnegative','scalar','<=',1},'','Eccentricity');
            self.ecc = ecc;
            e2 = ecc ^ 2;
            % The obvious formula for converting eccentricity to flattening
            % is f = 1 - sqrt(1 - e2), but the following is equivalent
            % algebraically and provides better numerical precision:
            f = e2 / (1 + sqrt(1 - e2));
            self.b = (1 - f) * self.a;
            self.invf = 1 / f;
            self.Flattening = f;
            self.ThirdFlattening = f / (2 - f);
        end
        
    end
       
    %------------------- 3-D Coordinate Transformations -------------------
    
    % Reference
    % ---------
    % Paul R. Wolf and Bon A. Dewitt, "Elements of Photogrammetry with
    % Applications in GIS," 3rd Ed., McGraw-Hill, 2000 (Appendix F-3).

    % The following 3 methods inherit their help from superclass spheroid.
    
    methods
        
        function [x, y, z] = geodetic2ecef(self, phi, lambda, h, angleUnit)
            
            if ~isobject(self) && nargin >= 4 && isa(h,'spheroid')
                % If we reach this line, MATLAB has dispatched this method
                % in response to a call to the global geodetic2ecef
                % function, which has the following syntax:
                %
                %    geodetic2ecef(PHI, LAMBDA, H, SPHEROID)
                %
                % Forward execution to that function, but call it such
                % that none of the inputs are spheroid objects.
                [x, y, z] = geodetic2ecef( ...
                    self, phi, lambda, [h.SemimajorAxis h.Eccentricity]);
                return
            end
            
            inDegrees = (nargin < 5 || map.geodesy.isDegree(angleUnit));
            [rho, z] = map.geodesy.internal.geodetic2cylindrical( ...
                phi, h, self.a, 1/self.invf, inDegrees);
            if inDegrees
                x = rho .* cosd(lambda);
                y = rho .* sind(lambda);
            else
                x = rho .* cos(lambda);
                y = rho .* sin(lambda);
            end
        end
        
        
        function [phi, lambda, h] = ecef2geodetic(self, x, y, z, angleUnit)
            
            if ~isobject(self) && nargin >= 4 && isa(z,'spheroid')
                % If we reach this line, MATLAB has dispatched this method
                % in response to a call to the global ecef2geodetic
                % function, which has the following syntax:
                %
                %    geodetic2ecef(X, Y, Z, SPHEROID)
                %
                % Forward execution to that function, but call it such
                % that none of the inputs are spheroid objects.
                [phi, lambda, h] = ecef2geodetic( ...
                    self, x, y, [z.SemimajorAxis z.Eccentricity]);
                return
            end
            
            inDegrees = (nargin < 5 || map.geodesy.isDegree(angleUnit));
            rho = hypot(x,y);
            [phi, h] = map.geodesy.internal.cylindrical2geodetic( ...
                rho, z, self.a, 1/self.invf, inDegrees);
            if inDegrees
                lambda = atan2d(y,x);
            else
                lambda = atan2(y,x);
            end
        end
        
        
        % ecefOffset: Implementation Notes from Rob Comer
        % -----------------------------------
        % In order to minimize numerical round off for points that are
        % closely-spaced relative to the dimensions of the reference
        % ellipsoid, use a sequence of computations that avoids computing a
        % small difference by subtracting two large numbers.  Rather than
        % convert each point to ECEF, then subtract, note that each ECEF
        % coordinate in the following formulas for x, y, and z:
        %
        %     N  = a ./ sqrt(1 - e2 * sin(phi).^2);
        %
        %     x = (N + h) .* cos(phi) .* cos(lambda);
        %     y = (N + h) .* cos(phi) .* sin(lambda);
        %     z = (N*(1 - e2) + h) .* sin(phi);
        %
        % contains a term that is a multiple of a and a term that is a
        % multiple of h.  For example,
        %
        %  x = a * cos(phi) * cos(lambda) * w + h * cos(phi) * cos(lambda);
        %
        % where w = 1 ./ sqrt(1 - e2 * sin(phi).^2).  Constructing x this
        % way for both x1 and x2, then taking the difference and factoring
        % out a gives:
        %
        %  dx = a * (cos(phi2) * cos(lambda2) * w1 - cos(phi1) * cos(lambda1) * w1)
        %       + (h2 * cos(phi2) * cos(lambda2) - h1 * cos(phi1) * cos(lambda1))

        function [deltaX, deltaY, deltaZ] = ecefOffset(self, ...
                phi1, lambda1, h1, phi2, lambda2, h2, angleUnit)
                        
            if nargin < 8 || map.geodesy.isDegree(angleUnit)
                sinfun = @sind;
                cosfun = @cosd;
            else
                sinfun = @sin;
                cosfun = @cos;
            end
            
            e2 = self.Eccentricity^2;
            
            s1 = sinfun(phi1);
            c1 = cosfun(phi1);
            
            s2 = sinfun(phi2);
            c2 = cosfun(phi2);
            
            p1 = c1 .* cosfun(lambda1);
            p2 = c2 .* cosfun(lambda2);
            
            q1 = c1 .* sinfun(lambda1);
            q2 = c2 .* sinfun(lambda2);
            
            w1 = 1 ./ sqrt(1 - e2 * s1.^2);
            w2 = 1 ./ sqrt(1 - e2 * s2.^2);
            
            deltaX =            self.a * (p2 .* w2 - p1 .* w1) + (h2 .* p2 - h1 .* p1);
            deltaY =            self.a * (q2 .* w2 - q1 .* w1) + (h2 .* q2 - h1 .* q1);
            deltaZ = (1 - e2) * self.a * (s2 .* w2 - s1 .* w1) + (h2 .* s2 - h1 .* s1);
        end
        
    end

end
