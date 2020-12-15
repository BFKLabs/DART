classdef IntrinsicPostingsReference < map.rasterref.internal.IntrinsicRasterReference
%IntrinsicRaster Intrinsic coordinates for raster of postings
%
%       FOR INTERNAL USE ONLY -- This class is intentionally
%       undocumented and is intended for use only within other toolbox
%       classes and functions. Its behavior may change, or the feature
%       itself may be removed in a future release.
%
%   For two-dimensional postings-type raster grids, IntrinsicCellsReference
%   objects implement and encapsulate the aspects of spatial referencing
%   that are independent of any external spatial coordinate system.
%
%   map.rasterref.internal.IntrinsicPostingsReference properties:
%     RasterSize - Number of rows and columns, as a 1-by-2 vector
%
%   map.rasterref.internal.IntrinsicPostingsReference methods:
%     limits              - Limits of raster in intrinsic X and Y
%     sizesMatch          - True if object and raster/image are size-compatible
%     contains            - True if raster contains points
%     intrinsicToDiscrete - Transform intrinsic coordinates to discrete subscripts
%
%     For an M-by-N raster of postings, contains(I,x,y) is true only when
%     both of the following are true:
%
%              1 <= x <= M
%              1 <= y <= N

% Copyright 2013 The MathWorks, Inc.

    properties (Dependent)
        %RasterSize Number of rows and columns, as a 1-by-2 vector
        RasterSize
    end
    
    methods
        function rasterSize = get.RasterSize(I)
            rasterSize = [I.NumRows I.NumColumns];
        end
        
        
        function I = set.RasterSize(I, rasterSize)
            validateattributes(rasterSize, {'double'}, ...
                {'row', 'positive', 'integer', 'finite'},'','RasterSize')
            
            map.internal.assert(numel(rasterSize) >= 2, ...
                'map:spatialref:invalidRasterSize','RasterSize')
            
            if any(rasterSize < 2)
                msg = message('map:spatialref:oneColumnOrRowOfPostings', ...
                    'RasterInterpretation','postings','RasterSize');
                throwAsCaller(MException(msg.Identifier,'%s',msg.getString()))
            end
            
            % Update properties on which RasterSize depends
            I.NumRows    = rasterSize(1);
            I.NumColumns = rasterSize(2);
        end
        
        
        function [xlimits, ylimits] = limits(I)
            xlimits = [1 I.NumColumns];
            ylimits = [1 I.NumRows];
        end
        
        
        function [a, b, first, last] = cropAndSubsampleLimits1D(~,~,~,~,~)
            assert(false,'map:setupCropAndSubsample:postingsNotSupported', ...
                'Postings are not supported by the setupCropAndSubsample method')
        end
    end
end
