function varargout = size(obj,varargin)
%SIZE Size of data acquisition object.  
%
%    D = SIZE(OBJ), for M-by-N data acquisition object, OBJ, returns the
%    two-element row vector D = [M, N] containing the number of rows and
%    columns in the data acquisition object, OBJ.  
%
%    [M,N] = SIZE(OBJ) returns the number of rows and columns in separate
%    output variables.  
%
%    [M1,M2,M3,...,MN] = SIZE(OBJ) returns the length of the first N dimensions
%    of OBJ.
%
%    M = SIZE(OBJ,DIM) returns the length of the dimension specified by the 
%    scalar DIM.  For example, SIZE(OBJ,1) returns the number of rows.
% 
%    See also DAQHELP, DAQCHILD/LENGTH.
%

%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.9.2.7 $  $Date: 2008/06/16 16:35:07 $

% Error checking.
if ~isa(obj, 'daqchild')
    error('daq:size:invalidType', 'OBJ must be a data acquisition object.')
end

% Determine the number of output arguments.
numOut = nargout;
if (numOut == 0)
    % If zero output modify to 1 (ans) so that the expression below
    % evaluates without error.
    numOut = 1;
end

% Call the builtin size function on the UDD object.  The uddobject field
% of the object indicates the number of objects that are concatenated
% together.
[varargout{1:numOut}] = builtin('size', daqgetfield(obj,'uddobject'), varargin{:});
