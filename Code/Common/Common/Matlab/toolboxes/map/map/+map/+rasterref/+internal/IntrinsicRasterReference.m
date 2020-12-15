classdef IntrinsicRasterReference
%IntrinsicRaster Intrinsic coordinates for 2-D image or raster
%
%       FOR INTERNAL USE ONLY -- This class is intentionally
%       undocumented and is intended for use only within other toolbox
%       classes and functions. Its behavior may change, or the feature
%       itself may be removed in a future release.
%
%   For two-dimensional raster grids and images, IntrinsicRasterReference
%   objects encapsulate the aspects of spatial referencing that are
%   independent of any external spatial coordinate system.
%
%   map.rasterref.internal.IntrinsicRasterReference methods:
%     limits (Abstract)   - Limits of raster in intrinsic X and Y
%     sizesMatch          - True if object and raster/image are size-compatible
%     contains            - True if raster contains points
%     intrinsicToDiscrete - Transform intrinsic coordinates to discrete subscripts

% Copyright 2013 The MathWorks, Inc.

    %------------------------ Defining Properties -------------------------
    
    properties (Access = protected)
        % Number of rows and columns in associated raster
        NumRows    = 2;
        NumColumns = 2;
    end
        
    %-------------------------- Abstract Methods ---------------------------
    
    methods (Abstract)
        [xlimits, ylimits] = limits(I)
        [a, b, first, last] =  cropAndSubsampleLimits1D(I,d,f,limits)
    end
        
    %-------------------------- Ordinary Methods --------------------------
    
    methods
        
        function tf = sizesMatch(I, A)
            %sizesMatch True if object and raster/image are size-compatible
            %
            %   TF = sizesMatch(I,A) returns true if the sizes of A
            %   is consistent with the NumRows and NumColumns properties of
            %   object I.
            
            tf = (I.NumRows    == size(A,1)) && ...
                 (I.NumColumns == size(A,2));
        end
        
        
        function tf = contains(I, xi, yi)
            %contains True if raster contains points
            %
            %   TF = I.contains(xIntrinsic,yIntrinsic) accepts a set of
            %   point locations in intrinsic raster coordinates, defined
            %   by the arrays xIntrinsic and yIntrinsic, and returns a
            %   logical array TF having the same size as xIntrinsic and
            %   yIntrinsic such that TF(k) is true if and only if the
            %   point (xIntrinsic(k), yIntrinsic(k)) falls within the
            %   limits of the raster (or image) associated with the
            %   IntrinsicRaster2D object I.
            
            if (I.NumRows > 0) && (I.NumColumns > 0)
                [xlimits, ylimits] = limits(I);
                
                try
                    tf =  (xlimits(1) <= xi) & (xi <= xlimits(2)) ...
                        & (ylimits(1) <= yi) & (yi <= ylimits(2));
                catch e
                    if strcmp(e.identifier,'MATLAB:andOrXor:sizeMismatch') ...
                            || strcmp(e.identifier,'MATLAB:dimagree')
                        % Likely error.
                        error(message(...
                            'map:validate:inconsistentSizes','XI','YI'))
                    else
                        % Unexpected error.
                        rethrow(e)
                    end
                end
                
            else
                tf = false(size(xi));
            end
        end
        
        
        function [row, col] = intrinsicToDiscrete(I, xi, yi)
            %intrinsicToDiscrete Transform intrinsic coordinates to discrete subscripts
            %
            %   [ROW, COL] = intrinsicToDiscrete(I, xIntrinsic, yIntrinsic)
            %   returns the arrays ROW and COL which are the row and
            %   column subscripts of the cells that contain a set of
            %   points (xIntrinsic, yIntrinsic) for the raster (or
            %   image) associated with the IntrinsicRaster2D object I.
            %   xIntrinsic and yIntrinsic must have the same size. ROW
            %   and COL will have the same size as xIntrinsic and
            %   yIntrinsic. For an M-by-N raster, 1 <= ROW <= M and
            %   1 <= COL <= N, except when a point (xIntrinsic(k),
            %   yIntrinsic(k)) falls outside the image. Then both ROW(k)
            %   and COL(k) are NaN.
            
            outside = ~contains(I,xi,yi);
            
            row = min(round(yi), I.NumRows);
            col = min(round(xi), I.NumColumns);
            
            row(outside) = NaN;
            col(outside) = NaN;
        end
        
        
        function [rows, cols, firstxi, firstyi] = setupCropAndSubsample(...
                I, xlimits, ylimits, xSampleFactor, ySampleFactor)
            %setupCropAndSubsample Indices and new first corner for cropping/subsampling
            %
            %   Inputs
            %   ------
            %   xlimits - Requested limits in intrinsic X
            %   ylimits - Requested limits in intrinsic Y
            %   xSampleFactor - Sample factor in intrinsic X
            %   ySampleFactor - Sample factor in intrinsic Y
            %
            %     The requested limits can be specified in any order. The
            %     sample factors must be nonzero integers. A negative sign
            %     indicates a reversal of direction in the corresponding
            %     dimension.
            %
            %   Outputs
            %   -------
            %   rows - Vector of row indices
            %   cols - Vector of column indices
            %   firstxi - Intrinsic X location of new first corner
            %   firstxy - Intrinsic Y location of new first corner
            %
            %     The vectors of row and column indices indicate which
            %     elements are to be taken from the original raster during
            %     cropping and/or subsampling. Each is either monotonically
            %     increasing, if direction is not reversed, or monotonically
            %     decreasing, if it is.
            %
            %     The new first corner location (firstxi, firstyi) is
            %     relative to the intrinsic system of the original raster.
            
            validateattributes(xlimits,{'double'},{'real','finite','size',[1 2]})
            validateattributes(ylimits,{'double'},{'real','finite','size',[1 2]})
            validateattributes(xSampleFactor,{'double'},{'real','scalar','nonzero','integer'})
            validateattributes(ySampleFactor,{'double'},{'real','scalar','nonzero','integer'})
            
            % Computations in intrinsic X (across the columns)
            dim = 2;
            f = min(I.NumColumns, abs(xSampleFactor));
            [a,b,first,last] = cropAndSubsampleLimits1D(I,dim,f,xlimits);
            
            samedir = sign(xSampleFactor) > 0;
            if samedir
                firstxi = a;
                cols = first:f:last;
                if isempty(cols)
                    cols = first;
                end
            else
                firstxi = b;
                cols = last:-f:first;
                if isempty(cols)
                    cols = last;
                end
            end
            
            % Computations in intrinsic Y (down the columns)
            dim = 1;
            f = min(I.NumRows, abs(ySampleFactor));
            [a,b,first,last] = cropAndSubsampleLimits1D(I,dim,f,ylimits);
            
            samedir = sign(ySampleFactor) > 0;
            if samedir
                firstyi = a;
                rows = first:f:last;
                if isempty(rows)
                    rows = first;
                end
            else
                firstyi = b;
                rows = last:-f:first;
                if isempty(rows)
                    rows = last;
                end
            end
            
        end
        
    end
    
end
