function out = hexToBinaryVector(hexString,varargin)
%hexToBinaryVector Convert hex number to a binary vector.
%
%    hexToBinaryVector(hexString) returns the binary representation
%    of hexString as a binary vector.  The most significant bit is
%    represented by the first column.  hexString must be a valid
%    hexadecimal character string. 
%
%    hexToBinaryVector(hexString,numberOfBits) produces a binary
%    representation with numberOfBits bits.
%
%    hexToBinaryVector(decimalNumber,numberOfBits,bitOrder) produces a
%    binary representation with numberOfBits bits with the specific order.
%    bitOrder can be:
%    'MSBFirst' -  The most significant bit is represented by
%    the first column. This is the default. 
%    'LSBFirst' - The least significant bit is represented by the first
%    column.
%
%    Example:
%       hexToBinaryVector('A1') returns [1 0 1 0 0 0 0 1]
%       hexToBinaryVector('A1',10) returns [ 0 0 1 0 1 0 0 0 0 1]
%       hexToBinaryVector('A1',10,'LSBFirst') returns [1 0 0 0 0 1 0 1 0 0]
%       hexToBinaryVector('A1',[],'LSBFirst') returns [1 0 0 0 0 1 0 1]
%
%    See also HEXTOBINARYVECTOR,BINARYVECTORTODECIMAL.
%
%    Copyright 2012 The MathWorks, Inc.

% Validate inputs
if nargin < 1
    MException(message('daq:general:needsHexNumber')).throwAsCaller;
end

if nargin > 3
    MException(message('MATLAB:maxrhs')).throwAsCaller;
end

% Delegate work to the conversionUtility class in daq namespace.
conversionUtility = daq.ConversionUtility;

try
    out = conversionUtility.hexToBinaryVector(hexString,varargin{:});
catch e
    throwAsCaller(e)
end
