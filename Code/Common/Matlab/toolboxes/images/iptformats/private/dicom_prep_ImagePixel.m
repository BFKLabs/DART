function metadata = dicom_prep_ImagePixel(metadata, X, map, txfr, dictionary)
%DICOM_PREP_IMAGEPIXEL  Set necessary values for Image Pixel module.
%
%   See PS 3.3 Sec C.7.6.3

%   Copyright 1993-2013 The MathWorks, Inc.

metadata(1).(dicom_name_lookup('0028', '0002', dictionary)) = size(X, 3);
metadata.(dicom_name_lookup('0028', '0004', dictionary)) = getPhotometricInterp(metadata, X, map, txfr, dictionary);
metadata.(dicom_name_lookup('0028', '0010', dictionary)) = size(X, 1);
metadata.(dicom_name_lookup('0028', '0011', dictionary)) = size(X, 2);

[ba, bs, hb, pr] = getPixelStorage(X, txfr);
metadata.(dicom_name_lookup('0028', '0100', dictionary)) = ba;
metadata.(dicom_name_lookup('0028', '0101', dictionary)) = bs;
metadata.(dicom_name_lookup('0028', '0102', dictionary)) = hb;
metadata.(dicom_name_lookup('0028', '0103', dictionary)) = pr;

metadata.(dicom_name_lookup('7FE0', '0010', dictionary)) = encodePixelData(metadata, X, map, txfr, dictionary);

% Values that depend on the number of samples present.
if (metadata.(dicom_name_lookup('0028', '0002', dictionary)) > 1)

    metadata.(dicom_name_lookup('0028', '0006', dictionary)) = 0;  % Interleaved pixels.
                                                       
else
  
    % Don't include min/max pixel value for multisample images.
    [minPix, maxPix] = determineMinMax(txfr, X, metadata.(dicom_name_lookup('7FE0', '0010', dictionary)));
    metadata.(dicom_name_lookup('0028', '0106', dictionary)) = minPix;
    metadata.(dicom_name_lookup('0028', '0107', dictionary)) = maxPix;
    
end

if (~isempty(map))
    [rdes, gdes, bdes, rdata, gdata, bdata] = processColormap(X, map);
    metadata.(dicom_name_lookup('0028', '1101', dictionary)) = rdes;
    metadata.(dicom_name_lookup('0028', '1102', dictionary)) = gdes;
    metadata.(dicom_name_lookup('0028', '1103', dictionary)) = bdes;
    metadata.(dicom_name_lookup('0028', '1201', dictionary)) = rdata;
    metadata.(dicom_name_lookup('0028', '1202', dictionary)) = gdata;
    metadata.(dicom_name_lookup('0028', '1203', dictionary)) = bdata;
end

% Technically (0028,0008) isn't part of the Image Pixel module, but it's
% fundamental to several overlapping, optional modules that we don't
% have "prep" functions for yet; and we need to put the right value when
% copying metadata.
if ((isfield(metadata, dicom_name_lookup('0028', '0008', dictionary))) || ...
    (size(X,4) > 1))
  
    % Add the attribute if it isn't present and there's more than one frame.
    metadata.(dicom_name_lookup('0028', '0008', dictionary)) = size(X, 4);
    
end


function pInt = getPhotometricInterp(metadata, X, map, txfr, dictionary)
%GETPHOTOMETRICINTERP   Get the string code for the image's photometric interp

if (isempty(map))
    
    if (size(X, 3) == 1)
        
        % 0 is black.  Grayscale images should always have a value of
        % 'MONOCHROME1' or 'MONOCHROME2', regardless of compression. The
        % default should be consistent with IPT's interpretation that the
        % "minimum is black," which is 'MONOCHROME2'.
        pIntFieldname = dicom_name_lookup('0028', '0004', dictionary);
        if isfield(metadata, pIntFieldname)
            switch (metadata.(pIntFieldname))
            case {'MONOCHROME1', 'MONOCHROME2'}
                pInt = metadata.(pIntFieldname);
            otherwise
                pInt = 'MONOCHROME2';
            end
        else
            pInt = 'MONOCHROME2';
        end
        
    elseif (size(X, 3) == 3)
        
        switch (txfr)
        case {'1.2.840.10008.1.2.4.50'
              '1.2.840.10008.1.2.4.51'
              '1.2.840.10008.1.2.4.52'
              '1.2.840.10008.1.2.4.53'
              '1.2.840.10008.1.2.4.54'
              '1.2.840.10008.1.2.4.55'
              '1.2.840.10008.1.2.4.56'
              '1.2.840.10008.1.2.4.57'
              '1.2.840.10008.1.2.4.58'
              '1.2.840.10008.1.2.4.59'
              '1.2.840.10008.1.2.4.60'
              '1.2.840.10008.1.2.4.61'
              '1.2.840.10008.1.2.4.62'
              '1.2.840.10008.1.2.4.63'
              '1.2.840.10008.1.2.4.64'
              '1.2.840.10008.1.2.4.65'
              '1.2.840.10008.1.2.4.66'
              '1.2.840.10008.1.2.4.70'
              '1.2.840.10008.1.2.4.80'
              '1.2.840.10008.1.2.4.81'}
      
            pInt = 'YBR_FULL_422';

        case {'1.2.840.10008.1.2.4.90'
              '1.2.840.10008.1.2.4.92'}

            % See PS 3.5 Sec. 8.2.4
            pInt = 'YBR_RCT';
         
        case {'1.2.840.10008.1.2.4.91'
              '1.2.840.10008.1.2.4.93'}

            % See PS 3.5 Sec. 8.2.4
            pInt = 'YBR_ICT';
         
        otherwise
            
            pInt = 'RGB';
            
        end
        
    else
        
        error(message('images:dicom_prep_ImagePixel:photoInterp'))
        
    end
    
else
    
    if (size(X, 3) == 1)
        pInt = 'PALETTE COLOR';
    elseif (size(X, 3) == 4)
        pInt = 'RGBA';
    else
        error(message('images:dicom_prep_ImagePixel:photoInterp'))
    end
    
end



function [ba, bs, hb, pr] = getPixelStorage(X, txfr)
%GETPIXELSTORAGE   Get details about the pixel cells.

switch (class(X))
case {'uint8', 'logical'}
    ba = 8;
    bs = 8;
    pr = 0;
    
case {'int8'}
    ba = 8;
    bs = 8;
    pr = 1;
    
case {'uint16'}
    ba = 16;
    bs = 16;
    pr = 0;
    
case {'int16'}
    ba = 16;
    bs = 16;
    pr = 1;
    
case {'uint32'}
    ba = 32;
    bs = 32;
    pr = 0;
    
case {'int32'}
    ba = 32;
    bs = 32;
    pr = 1;
    
case {'double'}
    
    switch (txfr)
    case '1.2.840.10008.1.2.4.50'
        ba = 8;
        bs = 8;
        pr = 0;
        
    otherwise
        % Customers report that UINT8 data isn't large enough.
        ba = 16;
        bs = 16;
        pr = 0;
        
    end
    
otherwise

    error(message('images:dicom_prep_ImagePixel:bitDepth'))
    
end

hb = ba - 1;



function [rdes, gdes, bdes, rdata, gdata, bdata] = processColormap(X, map)
%PROCESSCOLORMAP  Turn a MATLAB colormap into a DICOM colormap.

% Always use 16-bits.

% First descriptor: number of rows in the table.
map_rows = size(map, 1);

if (map_rows == (2^16))
    map_rows = 0;
end

% Second descriptor: index to start row mapping. Always 0 for MATLAB's use
% of colormaps.

% Third descriptor: bit-depth.
map_bits = 16;

rdes = [map_rows 0 map_bits];
gdes = rdes;
bdes = rdes;

% PS 3.3 Sec. C.7.6.3.1.6 says data must span the full range.
rdata = uint16(map(:, 1) .* (2 ^ map_bits - 1));
gdata = uint16(map(:, 2) .* (2 ^ map_bits - 1));
bdata = uint16(map(:, 3) .* (2 ^ map_bits - 1));



function pixelData = encodePixelData(metadata, X, map, txfr, dictionary)
%ENCODEPIXELCELLS   Turn a MATLAB image into DICOM-encoded pixel data.

%
% Rescale logical and double data.
%
switch (txfr)
case {'1.2.840.10008.1.2.4.50'
      '1.2.840.10008.1.2.4.51'
      '1.2.840.10008.1.2.4.52'
      '1.2.840.10008.1.2.4.53'
      '1.2.840.10008.1.2.4.54'
      '1.2.840.10008.1.2.4.55'
      '1.2.840.10008.1.2.4.56'
      '1.2.840.10008.1.2.4.57'
      '1.2.840.10008.1.2.4.58'
      '1.2.840.10008.1.2.4.59'
      '1.2.840.10008.1.2.4.60'
      '1.2.840.10008.1.2.4.61'
      '1.2.840.10008.1.2.4.62'
      '1.2.840.10008.1.2.4.63'
      '1.2.840.10008.1.2.4.64'
      '1.2.840.10008.1.2.4.65'
      '1.2.840.10008.1.2.4.66'
      '1.2.840.10008.1.2.4.70'
      '1.2.840.10008.1.2.4.80'
      '1.2.840.10008.1.2.4.81'
      '1.2.840.10008.1.2.4.90'
      '1.2.840.10008.1.2.4.91'}

    % Let IMWRITE handle all of the transformations.
    pixelCells = X;
    
otherwise

    % Handle the special syntaxes where endianness changes for pixels.
    X = changePixelEndian(X, txfr, metadata, dictionary);
    
    pixelCells = dicom_encode_pixel_cells(X, map);
    
end

%
% Encode pixels.
%
uid_details = dicom_uid_decode(txfr);
if (uid_details.Compressed)
    
    % Compress the pixel cells and add delimiters.
    pixelData = dicom_compress_pixel_cells(pixelCells, txfr, ...
                                    metadata.(dicom_name_lookup('0028','0100', dictionary)), ...
                                    size(X));
    pixelData = dicom_encode_attrs(pixelData, txfr, dicom_uid_decode(txfr));
    pixelData = pixelData{1};  % Encoding produces a cell array.
    
else
    
    pixelData = pixelCells;
    
end



function out = changePixelEndian(in, txfr, metadata, dictionary)
%CHANGEPIXELENDIAN   Swap pixel bytes for special transfer syntaxes

uid_details = dicom_uid_decode(txfr);

% After this function, the pixel data should be in the right order so that
% dicom_encode_attr can translate it directly to the output endianness.
% Special syntaxes where (a) the pixel endianness doesn't match the
% endianness of the rest of the metadata or (b) 32-bit data is being
% written on a big-endian machine to a little-endian transfer syntax
% require "pre-work" on the pixels to allow correct encoding later.
in_class = class(in);
if (~isequal(uid_details.Endian, uid_details.PixelEndian))

    % Pixel data is stored OB (unswapped) iff bits/sample <= 8, otherwise
    % it's stored OW (swapped).  When swapping OW data, words are swapped
    % not the entire data.  So a 32-bit sample with bytes (ABCD) becomes
    % (BADC).
    
    if (metadata.(dicom_name_lookup('0028', '0100', dictionary)) <= 16)  % BitsAllocated
        out = dicom_typecast(in(:), 'uint8', true);
        out = dicom_typecast(out, in_class);
    else
        out = dicom_typecast(in(:), 'uint16', false);
        out = dicom_typecast(out, 'uint8', true);
        out = dicom_typecast(out, in_class);
    end
    
    out = reshape(out, size(in));
    
else
    
    [c, m, endian] = computer;
    if (isequal(endian, 'B') && ...
        isequal(uid_details.PixelEndian, 'ieee-le') && ...
        metadata.(dicom_name_lookup('0028', '0100', dictionary)) > 16)

        % The pixels need to look like the final little-endian
        % representation, which will then be undone and redone.
        out = dicom_typecast(in(:), 'uint16', true);
        out = dicom_typecast(out, 'uint8', true);
        out = dicom_typecast(out, in_class);
    
        out = reshape(out, size(in));
        
    else
        out = in;
    end
    
end



function [minPix, maxPix] = determineMinMax(txfr, X, pixelData)

details = dicom_uid_decode(txfr);
if (details.Compressed)
  
    % Look at actual data for compressed pixels.
    minPix = min(X(:));
    maxPix = max(X(:));
  
else
  
    % Look at encoded data for uncompressed pixels.
    minPix = min(pixelData(:));
    maxPix = max(pixelData(:));
    
end
 
