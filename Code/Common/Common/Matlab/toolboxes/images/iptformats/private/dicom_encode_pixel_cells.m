function pixel_cells = dicom_encode_pixel_cells(X, map)
%DICOM_ENCODE_PIXEL_CELLS   Convert an image to pixel cells.
%   PIXCELLS = DICOM_ENCODE_PIXEL_CELLS(X, MAP) convert the image X with
%   colormap MAP to a sequence of DICOM pixel cells.

%   Copyright 1993-2010 The MathWorks, Inc.


% Images are stored across then down.  If there are multiple samples,
% keep all samples for each pixel contiguously stored.
X = permute(X, [3 2 1 4]);

% Convert to correct output type.
if (islogical(X))

   
    warning(message('images:dicom_encode_pixel_cells:scalingLogicalData'));
    
    tmp = uint8(X);
    tmp(X) = 255;
    
    X = tmp;
    
elseif (isa(X, 'double'))
   
    if (isempty(map))
        
        % RGB or Grayscale.
        X = uint16(65535 * X);
        
    else
       
        if (size(X, 1) == 1)
            
            % Indexed.
            X = uint16(X - 1);
            
        elseif (size(X, 1) == 4)
            
            % RGBA
            X(1:3, :, :) = X(1:3, :, :) * 65535;
            X(4, :, :)   = X(4, :, :) - 1;
            X = uint16(X);
            
        end
            
        
    end
    
end
    
pixel_cells = X(:);
 
