function Z = imapplymatrix(multiplier, I, varargin)
%IMAPPLYMATRIX  Linear combination of color channels.
%    Y = IMAPPLYMATRIX(M, X) compute the linear combination of the rows
%    of M with the color channels of X.  If X is m-by-n-by-p, M must be
%    q-by-p, where q is in the range [1,p].  The output datatype is the
%    same as the type of X.
%
%    Y = IMAPPLYMATRIX(M, X, C) compute the linear combination of the rows
%    of M with the color channels of X, adding the corresponding constant
%    value from C to each combination.  C can either be a vector with the
%    same number of elements as the number of rows in M, or it is a scalar
%    applied to every channel.  The output datatype is the same as the type
%    of X.
%
%    Y = IMAPPLYMATRIX(..., OUTPUT_TYPE) returns the result of the linear
%    combination in an array of type OUTPUT_TYPE.
%
%    Example
%    -------
%
%    % Quick and dirty conversion of RGB values to grayscale.
%    RGB = imread('peppers.png');
%    M = [0.30, 0.59, 0.11];
%    gray = imapplymatrix(M, RGB);
%    figure
%    subplot(1,2,1), imshow(RGB), title('Original RGB')
%    subplot(1,2,2), imshow(gray), title('Grayscale conversion')
%
%    See also imlincomb, immultiply

%   Copyright 2010-2011 The MathWorks, Inc.

if (isempty(I))

    Z = reshape([], size(I));
    return
    
end

[constants, outputClass] = parseVarargin(I, multiplier, varargin{:});

multiplierDims = size(multiplier);

if (multiplierDims(1) > multiplierDims(2))

    error(message('images:imapplymatrix:unsupportedMultiplierSize'));

elseif (ndims(I) > 3)
    
    error(message('images:imapplymatrix:unsupportedHigherDimension'));
      
elseif (ndims(multiplier) > 2)
    
    error(message('images:imapplymatrix:multiplierNot2D'));
      
end

origImageDims = size(I);
I = reshape(I, origImageDims(1) * origImageDims(2), size(I,3));

if (isempty(constants))
    constants = zeros(size(multiplier,1), 1);
end

if (isempty(outputClass))
    outputClass = class(I);
else
    checkOutputClass(outputClass);
end

% Ensure the constants are in a column vector.
if ((size(constants,2) ~= 1) && (size(constants,1) ~= 1))

    error(message('images:imapplymatrix:constantsNotVector'));

else
    constants = constants(:);
end

if (numel(constants) ~= multiplierDims(1))
    
    error(message('images:imapplymatrix:numberOfConstants'))
    
elseif (size(I,2) ~= multiplierDims(2))
    
    error(message('images:imapplymatrix:dimensionsMustAgree'))
    
end

% Compute and return to original orientation.
Z = imapplymatrixc(I, multiplier', constants, outputClass);
Z = reshape(Z, origImageDims(1), origImageDims(2), [ ]);



function [constants, outputClass] = parseVarargin(I, multiplier, varargin)

if (nargin == 4)

    if (isa(varargin{1}, 'double'))
        constants = varargin{1};
    else
        error(message('images:imapplymatrix:badConstants'))
    end

    if (ischar(varargin{2}))
        outputClass = varargin{2};
    else
        error(message('images:imapplymatrix:badOutputClass'))
    end

elseif (nargin == 3)

    if (ischar(varargin{1}))
        outputClass = varargin{1};
        constants = [];
    elseif (isa(varargin{1}, 'double'))
        constants = varargin{1};
        outputClass = '';
    else
        error(message('images:imapplymatrix:badExtraArgument'))
    end

elseif (nargin == 2)

    constants = [];
    outputClass = '';

else

    error(message('images:imapplymatrix:wrongArgCount'))

end



function checkOutputClass(outputClass)

switch (outputClass)
case {'uint8' 'uint16' 'uint32' 'int8' 'int16' 'int32' 'single' 'double'}
    % No problem.
    
otherwise
    error(message('images:imapplymatrix:invalidOutputClass'))

end
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [images, scalars, output_class] = ParseInputs(varargin)
  
narginchk(2, Inf);

if ischar(varargin{end})
  valid_strings = {'uint8' 'uint16' 'uint32' 'int8' 'int16' 'int32' ...
                   'single' 'double'};
  output_class = validatestring(varargin{end}, valid_strings, mfilename, ...
                              'OUTPUT_CLASS', 3);
  varargin(end) = [];
else
  if islogical(varargin{2})
    output_class = 'double';
  else
    output_class = class(varargin{2});
  end
end

%check images
images = varargin(2:2:end);
if ~iscell(images) || isempty(images)
  displayInternalError('images');
end

% assign and check scalars
for p = 1:2:length(varargin)
  validateattributes(varargin{p}, {'double'}, {'real' 'nonsparse' 'scalar'}, ...
                mfilename, sprintf('K%d', (p+1)/2), p);
end
scalars = [varargin{1:2:end}];

%make sure it is a vector
if ( ndims(scalars)~=2 || (all(size(scalars)~=1) && any(size(scalars)~=0)) )
  displayInternalError('scalars');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function displayInternalError(string)

error(message('images:imapplymatrix:internalError', upper( string )));
