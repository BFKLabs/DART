function out = binaryVectorToDecimal(binaryVector,varargin)
%binaryVectorToDecimal Convert binary vector to a decimal number.
%
%    binaryVectorToDecimal(binaryVector) returns the decimal representation
%    of a binary vector. The binary number in first column is treated as
%    the most significant bit. binaryVector should be numeric vector
%    consisting of 0's and 1's
%
%    binaryVectorToDecimal(binaryVector, bitOrder) returns the decimal representation
%    of a binary vector with the specific order.
%    bitOrder can be:
%    'MSBFirst' -  The binary number in first column is treated as
%    the most significant bit. This is the default. 
%    'LSBFirst' - The binary number in first column is treated as
%    the least significant bit.
%
%    Example:
%       binaryVectorToDecimal([1 1 0]) returns 6
%       binaryVectorToDecimal([1 1 0],'LSBFirst') returns 3
%
%    See also DECIMALTOBINARYVECTOR, BINARYVECTORTOHEX.
%    Copyright 2012 The MathWorks, Inc.


% Validate inputs
if nargin < 1
    MException(message('daq:general:needsBinaryVector')).throwAsCaller;
end

if nargin > 2
    MException(message('MATLAB:maxrhs')).throwAsCaller;
end

% Delegate work to the conversionUtility class in daq namespace.
conversionUtility = daq.ConversionUtility;
try
    out = conversionUtility.binaryVectorToDecimal(binaryVector,varargin{:});
catch e
    throwAsCaller(e)
end

