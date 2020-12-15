function B = imopen(varargin) %#codegen
%IMOPEN Morphologically open image.
%   IM2 = IMOPEN(IM,SE) performs morphological opening on the grayscale
%   or binary image IM with the structuring element SE.  SE must be a
%   single structuring element object, as opposed to an array of
%   objects.
%
%   IM2 = IMOPEN(IM,NHOOD) performs opening with the structuring element
%   STREL(NHOOD), where NHOOD is an array of 0s and 1s that specifies the
%   structuring element neighborhood.
%
%   The morphological open operation is an erosion followed by a dilation,
%   using the same structuring element for both operations.
%
%   Class Support
%   -------------
%   IM can be any numeric or logical class and any dimension, and must be
%   nonsparse.  If IM is logical, then SE must be flat.  IM2 has the same
%   class as IM.
%
%   Example
%   -------
%   Remove snowflakes having a radius less than 5 pixels by opening it with
%   a disk-shaped structuring element having a 5 pixel radius.
%
%       original = imread('snowflakes.png');
%       se = strel('disk',5);
%       afterOpening = imopen(original,se);
%       figure, imshow(original), figure, imshow(afterOpening,[])
%
%   See also IMCLOSE, IMDILATE, IMERODE, STREL.

%   Copyright 1993-2013 The MathWorks, Inc.

[A,SE,pre_pack] = ParseInputs(varargin{:});

M = size(A,1);
if pre_pack
    inputImage = bwpack(A);
    packopt = 'ispacked';
else
    inputImage = A;
    packopt = 'notpacked';
end

outputImage = imdilate(imerode(inputImage,SE,packopt,M),SE,packopt,M);

if pre_pack
    B = bwunpack(outputImage,M);
else
    B = outputImage;
end

function [A,se,pre_pack] = ParseInputs(varargin)

narginchk(2,2);

% Get the required inputs and check them for validity.
A = varargin{1};
validateattributes(A, {'numeric' 'logical'}, {'real' 'nonsparse'}, mfilename, ...
              'I or BW', 1); %#ok<EMCA>
se = images.internal.strelcheck(varargin{2}, mfilename, 'SE', 2);

coder.internal.errorIf((length(se(:)) > 1), 'images:imopen:nonscalarStrel');


strel_is_flat = isflat(se);
input_is_logical = islogical(A);
input_is_2d = ismatrix(A);
strel_is_2d = ismatrix(getnhood(se));
is_binary_op = input_is_logical;

coder.internal.errorIf((input_is_logical && ~strel_is_flat), 'images:imopen:binaryImageWithNonflatStrel');

pre_pack = is_binary_op && input_is_2d && strel_is_2d;
