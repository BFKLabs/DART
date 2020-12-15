classdef MapRasterReference ...
    < map.rasterref.internal.MapRasterReferenceAlias
%MapRasterReference (abstract) Reference raster to map coordinates

% Most of the content of this file was copied from the file
% map/+spatialref/MapRasterReference.m, which was introduced in R2011a.

% Copyright 2010-2013 The MathWorks, Inc.
    
    %------------------- Properties: Public + visible --------------------
    
    properties (Dependent = true)
        %XWorldLimits - Limits of raster in world X [xMin xMax]
        %
        %    XWorldLimits is a two-element row vector.
        XWorldLimits
        
        %YWorldLimits - Limits of raster in world Y [yMin yMax]
        %
        %    YWorldLimits is a two-element row vector.
        YWorldLimits
        
        %RasterSize Number of cells or samples in each spatial dimension
        %
        %   RasterSize is a two-element vector [M N] specifying the
        %   number of rows (M) and columns (N) of the raster or image
        %   associated with the referencing object. In addition, for
        %   convenience, you may assign a size vector having more than
        %   two elements to RasterSize. This flexibility enables
        %   assignments like R.RasterSize = size(RGB), for example, where
        %   RGB is M-by-N-by-3. However, in such cases, only the first two
        %   elements of the size vector will actually be stored. The higher
        %   (non-spatial) dimensions will be ignored. M and N must be
        %   positive in all cases and must be 2 or greater when
        %   RasterInterpretation is 'postings'.
        RasterSize
        
        %ColumnsStartFrom Edge from which column indexing starts
        %
        %   ColumnsStartFrom is a string that equals 'south' or 'north'.
        ColumnsStartFrom
        
        %RowsStartFrom Edge from which row indexing starts
        %
        %   RowsStartFrom is a string that equals 'west' or 'east'.
        RowsStartFrom
    end

    properties (Dependent = true, SetAccess = private)
        %RasterExtentInWorldX - Full extent in along-row direction
        %
        %   RasterExtentInWorldX is the extent of the full raster
        %   or image as measured in the world system in a direction
        %   parallel to its rows. In the case of a rectilinear geometry,
        %   which is most typical, this is the horizontal direction
        %   (east-west).
        RasterExtentInWorldX
        
        %RasterExtentInWorldY - Full extent in along-column direction
        %
        %   RasterExtentInWorldY is the extent of the full raster
        %   or image as measured in the world system in a direction
        %   parallel to its columns. In the case of a rectilinear
        %   geometry, which is most typical, this is the vertical
        %   direction (north-south).
        RasterExtentInWorldY
    end
    
    properties (Abstract, SetAccess = protected, Transient = true)
        XIntrinsicLimits;  % Limits of raster in intrinsic X [xMin xMax]
        YIntrinsicLimits;  % Limits of raster in intrinsic Y [yMin yMax]
    end

    properties (Dependent = true, SetAccess = private)
        %TransformationType - Transformation type: 'rectilinear' or 'affine'
        %
        %   TransformationType is a string describing the type of geometric
        %   relationship between the intrinsic coordinate system and the
        %   world coordinate system. Its value is 'rectilinear' when world
        %   X depends only on intrinsic X and vice versa, and world Y
        %   depends only on intrinsic Y and vice versa. When the value is
        %   'rectilinear', the image will display without rotation
        %   (although it may be flipped) in the world system. Otherwise the
        %   value is 'affine'.
        TransformationType
    end
    
    properties (Constant = true)
        %CoordinateSystemType - Type of external system (constant: 'planar')
        %
        %   CoordinateSystemType describes the type of coordinate system
        %   to which the image or raster is referenced. It is a constant
        %   string with value 'planar'.
        CoordinateSystemType = 'planar';
    end
    
    %----------------- Properties: Protected + hidden --------------------

    properties (Access = protected, Hidden)
        % The world limits, column/row direction, delta, raster size, and
        % transformation type properties, along with all the methods except
        % for sizesMatch, depend on a hidden geometric transformation
        % object stored in the Transformation property. It is not
        % initialized, because until the subclass constructor runs, we
        % cannot tell if Transformation will hold an instance of a
        % map.rasterref.internal.RectilinearTransformation object or an
        % instance of a map.rasterref.internal.AffineTransformation
        % object.
        Transformation
    end
    
    properties (Abstract, Access = protected, Hidden)
        Intrinsic
    end
    
    %---------------- Constructor and ordinary methods --------------------
    
    methods
        
        function R = MapRasterReference(rasterSize)
            % Initialize intrinsic and transient properties.
            
            if nargin > 0
                % Set intrinsic properties on which RasterSize depends
                I = R.Intrinsic;
                try
                    I.RasterSize = rasterSize;
                catch e
                    rethrow(e)
                end
                R.Intrinsic = I;
            end
            
            % Set transient properties.
            [xlimits, ylimits] = limits(R.Intrinsic);
            R.XIntrinsicLimits = xlimits;
            R.YIntrinsicLimits = ylimits;
        end
        
        
        function tf = sizesMatch(R,A)
            %sizesMatch True if object and raster or image are size-compatible
            %
            %   TF = sizesMatch(R,A) returns true if the size of the raster
            %   (or image) A is consistent with the RasterSize property of
            %   the referencing object R. That is,
            %
            %           R.RasterSize == [size(A,1) size(A,2)].
            
            tf = sizesMatch(R.Intrinsic, A);
        end
        
        
        function [xw, yw] = intrinsicToWorld(R, xi, yi)
            %intrinsicToWorld Convert from intrinsic to world coordinates
            %
            %   [xWorld, yWorld] = intrinsicToWorld(R, ...
            %   xIntrinsic, yIntrinsic) maps point locations from the
            %   intrinsic system (xIntrinsic, yIntrinsic) to the world
            %   system (xWorld, yWorld) based on the relationship
            %   defined by the referencing object R. The input may
            %   include values that fall completely outside limits of
            %   the raster (or image) in the intrinsic system. In this
            %   case world X and Y are extrapolated outside the bounds
            %   of the image in the world system.
            
            map.internal.validateCoordinatePairs(xi, yi, ...
                [class(R), '.intrinsicToWorld'], ...
                'xIntrinsic', 'yIntrinsic')
            
            [xw, yw] = R.Transformation.intrinsicToWorld(xi, yi);
        end
        
        
        function [xi, yi] = worldToIntrinsic(R, xw, yw)
            %worldToIntrinsic Convert from world to intrinsic coordinates
            %
            %   [xIntrinsic, yIntrinsic] = worldToIntrinsic(R, ...
            %   xWorld, yWorld) maps point locations from the
            %   world system (xWorld, yWorld) to the intrinsic
            %   system (xIntrinsic, yIntrinsic) based on the relationship
            %   defined by the referencing object R. The input may
            %   include values that fall completely outside limits of
            %   the raster (or image) in the world system. In this
            %   case world X and Y are extrapolated outside the bounds
            %   of the image in the intrinsic system.
            
            map.internal.validateCoordinatePairs(xw, yw, ...
                [class(R), '.worldToIntrinsic'], ...
                'xWorld', 'yWorld')
            
            [xi, yi] = R.Transformation.worldToIntrinsic(xw, yw);
        end
        
        
        function [row,col] = worldToDiscrete(R, xw, yw)
            %worldToDiscrete Transform map to discrete coordinates
            %
            %   [I,J] = worldToDiscrete(R, xWorld, yWorld) returns the
            %   subscript arrays I and J. When the referencing object R has
            %   RasterInterpretation 'cells', these are the row and column
            %   subscripts of the raster cells (or image pixels) containing
            %   each element of a set of points given their world
            %   coordinates (xWorld, yWorld).  If R.RasterInterpretation is
            %   'postings', then the subscripts refer to the nearest sample
            %   point (posting). xWorld and yWorld must have the same size.
            %   I and J will have the same size as xWorld and yWorld. For
            %   an M-by-N raster, 1 <= I <= M and 1 <= J <= N, except when
            %   a point xWorld(k), yWorld(k) falls outside the image, as
            %   defined by R.contains(xWorld, yWorld), then
            %   both I(k) and J(k) are NaN.
            
            map.internal.validateCoordinatePairs(xw, yw, ...
                [class(R), '.worldToDiscrete'], ...
                'xWorld', 'yWorld')
            
            [xi, yi] = R.Transformation.worldToIntrinsic(xw, yw);
            [row, col] = R.Intrinsic.intrinsicToDiscrete(xi, yi);
        end
        
        
        function tf = contains(R, xw, yw)
            %contains True if raster contains points in world coordinate system
            %
            %   TF = contains(R, xWorld, yWorld) returns a logical array TF
            %   having the same size as xWorld, yWorld such that TF(k) is
            %   true if and only if the point (xWorld(k), yWorld(k)) falls
            %   within the bounds of the raster associated with
            %   referencing object R.
            
            map.internal.validateCoordinatePairs(xw, yw, ...
                [class(R), '.contains'], ...
                'xWorld', 'yWorld')
            
            [xi, yi] = R.Transformation.worldToIntrinsic(xw, yw);
            tf = R.Intrinsic.contains(xi, yi);
        end
        
        
        function xw = firstCornerX(R)
            %firstCornerX - World X coordinate of the (1,1) corner of the raster
            %
            %   firstCornerX(R) returns the world X coordinate of the
            %   outermost corner of the first cell (1,1) of the raster
            %   associated with referencing object R (if
            %   R.RasterInterpretation is 'cells') or the first sample
            %   point (if R.RasterInterpretation is 'postings').
            xw = R.Transformation.TiePointWorld(1);
        end
        
        
        function yw = firstCornerY(R)
            %firstCornerY - World Y coordinate of the (1,1) corner of the raster
            %
            %   firstCornerY(R) returns the world Y coordinate of the
            %   outermost corner of the first cell (1,1) of the raster
            %   associated with referencing object R (if
            %   R.RasterInterpretation is 'cells') or the first sample
            %   point (if R.RasterInterpretation is 'postings').
            yw = R.Transformation.TiePointWorld(2);
        end
        
        
        function W = worldFileMatrix(R)
            %worldFileMatrix - World file parameters for transformation
            %
            %   W = worldFileMatrix(R) returns a 2-by-3 world file matrix.
            %   Each of the 6 elements in W matches one of the lines in a
            %   world file corresponding to the rectilinear or affine
            %   transformation defined by the referencing object R.
            %
            %   Given W with the form:
            %
            %                    W = [A B C;
            %                         D E F],
            %
            %   a point (xi, yi) in intrinsic coordinates maps to a point
            %   (xw, yw) in planar world coordinates like this:
            %
            %         xw = A * (xi - 1) + B * (yi - 1) + C
            %         yw = D * (xi - 1) + E * (yi - 1) + F.
            %
            %   Or, more compactly, [xw yw]' = W * [(xi - 1) (yi - 1) 1]'.
            %   The -1s allow the world file matrix to work with the
            %   Mapping Toolbox convention for intrinsic coordinates, which
            %   is consistent with the 1-based indexing used throughout
            %   MATLAB. W is stored in a world file with one term per line
            %   in column-major order: A, D, B, E, C, F.  That is, a world
            %   file contains the elements of W in the following order:
            %
            %         W(1,1)
            %         W(2,1)
            %         W(1,2)
            %         W(2,2)
            %         W(1,3)
            %         W(2,3).
            %
            %   The expressions above hold for both affine and rectilinear
            %   transformations, but whenever R.TransformationType is
            %   'rectilinear', B, D, W(2,1) and W(1,2) are identically 0.
            %
            %   See also WORLDFILEREAD, WORLDFILEWRITE.
            
            J = R.Transformation.jacobianMatrix();
            [c, f] = R.intrinsicToWorld(1,1);
            W = [J  [c; f]];
        end
        
    end
    
    %-------------------------- Set methods ----------------------------
    
    methods
        
        function R = set.RasterSize(R, rasterSize)
            
            % Current dimensions in intrinsic system.
            currentIntrinsicWidth  = diff(R.XIntrinsicLimits);
            currentIntrinsicHeight = diff(R.YIntrinsicLimits);
            
            % Update intrinsic properties on which RasterSize depends
            I = R.Intrinsic;
            try
                I.RasterSize = rasterSize;
            catch e
                rethrow(e)
            end
            R.Intrinsic = I;

            % Update transient properties.
            [xlimits, ylimits] = limits(R.Intrinsic);
            R.XIntrinsicLimits = xlimits;
            R.YIntrinsicLimits = ylimits;
            
            % Rescale the columns of the Jacobian matrix, as appropriate.
            R = rescaleJacobian(R, ...
                currentIntrinsicWidth, currentIntrinsicHeight);
        end
        
        
        function R = set.XWorldLimits(R, xWorldLimits)
            validateattributes(xWorldLimits, ...
                {'double'}, {'real','row','finite','size', [1 2]}, ...
                [class(R) '.set.XWorldLimits'], ...
                'xWorldLimits')
            
            map.internal.assert(xWorldLimits(1) < xWorldLimits(2), ...
                'map:spatialref:expectedAscendingLimits','xWorldLimits')
            
            currentXWorldLimits = R.getXWorldLimits();
            
            % Take differences of limits (widths of bounding
            % rectangles); these will be positive numbers.
            difference = diff(xWorldLimits);
            currentDifference = diff(currentXWorldLimits);
            
            % Scale the first row of the Jacobian matrix to match the
            % change in world X extent.
            J = R.Transformation.Jacobian;
            N = J.Numerator;
            D = J.Denominator;
            N(1,:) = N(1,:) * difference;
            D(1,:) = D(1,:) * currentDifference;
            J.Numerator = N;
            J.Denominator = D;
            R.Transformation.Jacobian = J;
            
            % Reset the X component of the tie point to take care of
            % any translation that is also occurring.
            currentTiePointX = R.Transformation.TiePointWorld(1);
            newTiePointX = xWorldLimits(1) ...
                + (currentTiePointX - currentXWorldLimits(1)) ...
                * difference / currentDifference;
            
            R.Transformation.TiePointWorld(1) = newTiePointX;
        end
        
        
        function R = set.YWorldLimits(R, yWorldLimits)
            
            validateattributes(yWorldLimits, ...
                {'double'}, {'real','row','finite','size', [1 2]}, ...
                [class(R) '.set.YWorldLimits'], ...
                'yWorldLimits')
            
            map.internal.assert(yWorldLimits(1) < yWorldLimits(2), ...
                'map:spatialref:expectedAscendingLimits','YWorldLimits')
            
            currentYWorldLimits = R.getYWorldLimits();
            
            % Take differences of limits (widths of bounding
            % rectangle); these will be positive numbers.
            difference = diff(yWorldLimits);
            currentDifference = diff(currentYWorldLimits);
            
            % Scale the second row of the Jacobian matrix to match the
            % change in world Y extent.
            J = R.Transformation.Jacobian;
            N = J.Numerator;
            D = J.Denominator;
            N(2,:) = N(2,:) * difference;
            D(2,:) = D(2,:) * currentDifference;
            J.Numerator = N;
            J.Denominator = D;
            R.Transformation.Jacobian = J;
            
            % Reset the Y component of the tie point to take care of
            % any translation that is also occurring.
            currentTiePointY = R.Transformation.TiePointWorld(2);
            newTiePointY = yWorldLimits(1) ...
                + (currentTiePointY - currentYWorldLimits(1)) ...
                * difference / currentDifference;
            
            R.Transformation.TiePointWorld(2) = newTiePointY;
        end
        
        
        function R = set.ColumnsStartFrom(R, edge)
            edge = validatestring(edge, {'south','north'});
            
            reverseRasterColumns = xor( ...
                R.columnsRunSouthToNorth(), strcmp(edge, 'south'));
            if reverseRasterColumns
                % The current (end,1) corner will become the new tie point
                % in the world coordinates.
                [newTiePointX, newTiePointY] ...
                    = R.Transformation.intrinsicToWorld( ...
                    R.XIntrinsicLimits(1), R.YIntrinsicLimits(2));
                
                R.Transformation.TiePointWorld...
                    = [newTiePointX; newTiePointY];
                
                % Change the sign of the second column of the
                % Jacobian matrix.
                J = R.Transformation.Jacobian;
                J.Numerator(:,2) = -J.Numerator(:,2);
                R.Transformation.Jacobian = J;
            end
        end
        
        
        function R = set.RowsStartFrom(R, edge)
            edge = validatestring(edge, {'east','west'});
            
            reverseRasterRows = xor( ...
                R.rowsRunWestToEast(), strcmp(edge, 'west'));
            if reverseRasterRows
                % The current (1,end) corner will become the new tie point
                % in the world coordinates.
                [newTiePointX, newTiePointY] ...
                    = R.Transformation.intrinsicToWorld( ...
                    R.XIntrinsicLimits(2), R.YIntrinsicLimits(1));
                
                R.Transformation.TiePointWorld...
                    = [newTiePointX; newTiePointY];
                % Change the sign of the first column of the
                % Jacobian matrix.
                J = R.Transformation.Jacobian;
                J.Numerator(:,1) = -J.Numerator(:,1);
                R.Transformation.Jacobian = J;
            end
        end
        
    end
    
    %----------------- Get methods for public properties ------------------
    
    methods
        
        function rasterSize = get.RasterSize(R)
            rasterSize = R.Intrinsic.RasterSize;
        end
        
        
        function limits = get.XWorldLimits(R)
            limits = R.getXWorldLimits();
        end
        
        
        function limits = get.YWorldLimits(R)
            limits = R.getYWorldLimits();
        end
        
        
        function edge = get.ColumnsStartFrom(R)
            if R.columnsRunSouthToNorth()
                edge = 'south';
            else
                edge = 'north';
            end
        end
        
        
        function edge = get.RowsStartFrom(R)
            if R.rowsRunWestToEast()
                edge = 'west';
            else
                edge = 'east';
            end
        end
        
        
        function width = get.RasterExtentInWorldX(R)
            width = abs(R.DeltaX) * diff(R.XIntrinsicLimits);
        end
        
        
        function height = get.RasterExtentInWorldY(R)
            height = abs(R.DeltaY) * diff(R.YIntrinsicLimits);
        end
        
        
        function type = get.TransformationType(R)
            type =  R.Transformation.TransformationType;
        end
        
    end

    %------------------- Private/protected methods ------------------------
    
    methods (Access = protected)
        
        function S = encodeInStructure(R)
            % Encode the state of the map raster reference object R into
            % structure S.
            
            T = R.Transformation;
            
            S = struct( ...
                'RasterSize',          R.RasterSize, ...
                'TransformationType',  R.TransformationType, ...
                'TiePointIntrinsic',   T.TiePointIntrinsic, ...
                'TiePointWorld',       T.TiePointWorld);
            
            % The presence/absence of several fields depends on the
            % geometric transformation type.
            if strcmp(S.TransformationType,'rectilinear')
                S.DeltaNumerator   = T.DeltaNumerator;
                S.DeltaDenominator = T.DeltaDenominator;
            else
                % TransformationType is 'affine'
                S.Jacobian = T.Jacobian;
            end
        end
        
        
        function R = restoreFromStructure(R, S)
            % Restore map raster reference object R to the state defined by
            % the scalar structure S.
            
            % Avoid triggering any set methods, except for the
            % set.RasterSize method of the Intrinsic object (not
            % set.RasterSize method of the map raster reference object).
            
            % Update the intrinsic properties on which RasterSize depends,
            % without using its set method. (Avoid the set.RasterSize
            % method of the map raster reference object.)
            I = R.Intrinsic;
            I.RasterSize = S.RasterSize;
            R.Intrinsic = I;

            % Update transient properties.
            [xlimits, ylimits] = limits(R.Intrinsic);
            R.XIntrinsicLimits = xlimits;
            R.YIntrinsicLimits = ylimits;
            
            % Construct a transformation object
            if strcmp(S.TransformationType,'rectilinear')
                % TransformationType is 'rectilinear'; avoid setting
                % the Jacobian property, because that invokes
                % map.rasterref.internal.simplifyRatio, which could
                % change behavior in a future release.
                T = map.rasterref.internal.RectilinearTransformation;
                T.DeltaNumerator   = S.DeltaNumerator;
                T.DeltaDenominator = S.DeltaDenominator;
            else
                % TransformationType is 'affine'; OK to use the
                % set.Jacobian method.
                T = map.rasterref.internal.AffineTransformation;
                T.Jacobian = S.Jacobian;
            end
            T.TiePointIntrinsic = S.TiePointIntrinsic;
            T.TiePointWorld     = S.TiePointWorld;
            
            % Assign the transformation object to R
            R.Transformation = T;
        end
        
    end
    
    
    methods (Access = private)
        
        function R = rescaleJacobian(R, ...
                previousIntrinsicWidth, previousIntrinsicHeight)
            % Update the Jacobian matrix in response to a change in the
            % intrinsic dimensions of the raster (which could be due to a
            % change in RasterSize or in RasterInterpretation).
            
            % New dimensions in intrinsic system.
            [xlimits, ylimits] = limits(R.Intrinsic);
            newIntrinsicWidth  = diff(xlimits);
            newIntrinsicHeight = diff(ylimits);
            
            % Rescale the columns of the Jacobian matrix, as appropriate.
            J = R.Transformation.Jacobian;
            N = J.Numerator;
            D = J.Denominator;
            
            if previousIntrinsicWidth > 0 && newIntrinsicWidth > 0
                % This is the typical case. Scale the first column of the
                % Jacobian matrix such that the raster continues to fit
                % exactly within the current limits. In all other cases
                % simply leave the Jacobian matrix as-is.
                N(:,1) = N(:,1) * previousIntrinsicWidth;
                D(:,1) = D(:,1) * newIntrinsicWidth;
            end
            
            if previousIntrinsicHeight > 0 && newIntrinsicHeight > 0
                % This is the typical case. Scale the second column of the
                % Jacobian matrix such that the raster continues to fit
                % exactly within the current limits. In all other cases
                % simply leave the Jacobian matrix as-is.
                N(:,2) = N(:,2) * previousIntrinsicHeight;
                D(:,2) = D(:,2) * newIntrinsicHeight;
            end
            
            J.Numerator = N;
            J.Denominator = D;
            R.Transformation.Jacobian = J;
        end
        
        
        function limits = getXWorldLimits(R)
            % X-limits of bounding rectangle in world system
            xi = R.XIntrinsicLimits([1 1 2 2]);
            yi = R.YIntrinsicLimits([1 2 1 2]);
            [xw, ~] = R.Transformation.intrinsicToWorld(xi, yi);
            limits = [min(xw), max(xw)];
        end
        
        
        function limits = getYWorldLimits(R)
            % Y-limits of bounding rectangle in world system
            xi = R.XIntrinsicLimits([1 1 2 2]);
            yi = R.YIntrinsicLimits([1 2 1 2]);
            [~, yw] = R.intrinsicToWorld(xi, yi);
            limits = [min(yw), max(yw)];
        end
        
        
        function tf = rowsRunWestToEast(R)
            % True if and only if rows start from due west,
            % +/- an angle of pi/2.
            
            % Angle between intrinsic X axis and world X axis
            J = R.Transformation.jacobianMatrix();
            alpha = atan2(J(2,1), J(1,1));
            
            tf = (-pi/2 < alpha && alpha <= pi/2);
        end
        
        
        function tf = columnsRunSouthToNorth(R)
            % True if and only if columns start from due south,
            % +/- an angle of pi/2.
            
            % Angle between intrinsic Y axis and world Y axis
            J = R.Transformation.jacobianMatrix();
            beta = atan2(J(1,2), J(2,2));
            
            tf = -pi/2 < beta && beta <= pi/2;
        end
        
    end
    
end
