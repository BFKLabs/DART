function B = imclose(varargin) %#codegen
%IMCLOSE Morphologically close image.
%   IM2 = IMCLOSE(IM,SE) performs morphological closing on the
%   grayscale or binary image IM with the structuring element SE.  SE
%   must be a single structuring element object, as opposed to an array
%   of objects.
%
%   IMCLOSE(IM,NHOOD) performs closing with the structuring element
%   STREL(NHOOD), where NHOOD is an array of 0s and 1s that specifies the
%   structuring element neighborhood.
%
%   The morphological close operation is a dilation followed by an erosion,
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
%   Use IMCLOSE on cirles.png image to join the circles together by filling
%   in the gaps between the circles and by smoothening their outer edges.
%   Use a disk structuring element to preserve the circular nature of the
%   object. Choose the disk element to have a radius of 10 pixels so that
%   the largest gap gets filled.
%
%       originalBW = imread('circles.png');
%       figure, imshow(originalBW);
%       se = strel('disk',10);
%       closeBW = imclose(originalBW,se);
%       figure, imshow(closeBW);
%
%   See also IMDILATE, IMERODE, IMOPEN, STREL.

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

outputImage = imerode(imdilate(inputImage,SE,packopt,M),SE,packopt,M);

if pre_pack
    B = bwunpack(outputImage,M);
else
    B = outputImage;
end

function [A,se,pre_pack] = ParseInputs(varargin)

narginchk(2,2);

% Get the required inputs and check them for validity.
A = varargin{1};
validateattributes(A, {'numeric' 'logical'}, {'real' 'nonsparse'}, ...
    mfilename, 'I or BW', 1); %#ok<EMCA>
se = images.internal.strelcheck(varargin{2}, mfilename, 'SE', 2);
coder.internal.errorIf((length(se(:)) > 1), 'images:imclose:nonscalarStrel');

strel_is_flat = isflat(se);
input_is_logical = islogical(A);
input_is_2d = ismatrix(A);
strel_is_2d = ismatrix(getnhood(se));
is_binary_op = input_is_logical;

coder.internal.errorIf((input_is_logical && ~strel_is_flat), 'images:imclose:binaryImageWithNonflatStrel');

pre_pack = is_binary_op && input_is_2d && strel_is_2d;
