function out = decimalToBinaryVector(decimalNumber,varargin)
%decimalToBinaryVector Convert decimal number to a binary vector.
%
%    decimalToBinaryVector(decimalNumber) returns the binary representation
%    of decimalNumber as a binary vector.  The most significant bit is
%    represented by the first column.  decimalNumber must be a non-negative
%    integer scalar.
%
%    decimalToBinaryVector(decimalNumber,numberOfBits) produces a binary
%    representation with numberOfBits bits.
%
%    decimalToBinaryVector(decimalNumber,numberOfBits,bitOrder) produces a
%    binary representation with numberOfBits bits with the specific order.
%    bitOrder can be:
%    'MSBFirst' -  The most significant bit is represented by
%    the first column. This is the default. 
%    'LSBFirst' - The least significant bit is represented by the first
%    column.
%
%    Example:
%       decimalToBinaryVector(23) returns [1 0 1 1 1 ]
%       decimalToBinaryVector(23,6) returns [0 1 0 1 1 1]
%       decimalToBinaryVector(23,6,'LSBFirst') returns [1 1 1 0 1 0]
%       decimalToBinaryVector(23,[],'LSBFirst') returns [1 1 1 0 1]
%
%    See also BINARYVECTORTODECIMAL, HEXTOBINARYVECTOR.
%

%    Copyright 2012 The MathWorks, Inc.

% Check for required argument.
if nargin < 1
    MException(message('daq:general:needsDecimalNumber')).throwAsCaller;
end

if nargin > 3
    MException(message('MATLAB:maxrhs')).throwAsCaller;
end

% Delegate work to the conversionUtility class in daq namespace.
conversionUtility = daq.ConversionUtility;

try
    out = conversionUtility.decimalToBinaryVector(decimalNumber,varargin{:});
catch e
    throwAsCaller(e)
end

