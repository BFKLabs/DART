function out = binaryVectorToHex(binaryVector,varargin)
%binaryVectorToHex Convert binary vector to a hexadecimal character string.
%
%    binaryVectorToHex(binaryVector) returns the hexadecimal representation
%    of a binary vector. The binary number in first column is treated as
%    the most significant bit. binaryVector should be numeric vector
%    consisting of 0's and 1's
%
%    binaryVectorToHex(binaryVector, bitOrder) returns the hexadecimal
%    representation of a binary vector with the specific order. bitOrder can
%    be: 
%    'MSBFirst' -  The binary number in first column is treated as the
%    most significant bit. This is the default. 
%    'LSBFirst' - The binary number in first column is treated as the least
%    significant bit.
%
%    Example:
%       binaryVectorToHex([1 1 0 0]) returns 'C'
%       binaryVectorToHex([1 1 0 0],'LSBFirst') returns '3'
%
%    See also HEXTOBINARYVECTOR, BINARYVECTORTODECIMAL.
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
    hexCellArray = conversionUtility.binaryVectorToHex(binaryVector,varargin{:});
    if numel(hexCellArray) == 1
        out = hexCellArray{1};
    else
        out = hexCellArray;
    end
catch e
    throwAsCaller(e)
end
