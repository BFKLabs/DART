function [info, Z] = sdtsIfc(filename)
% SDTSIfc Interface to the SDTS++ library
%
%   INFO = SDTSIFC(FILENAME) returns a structure whose fields contain
%   information about the contents of an SDTS data set.
%
%   [INFO, Z] = SDTSIFC(FILENAME) returns the INFO structure and reads the
%   Z data from a SDTS raster or DEM data set.  Z is a matrix containing
%   the elevation/data values.
%
%   FILENAME is a string that specifies the name of the SDTS catalog
%   directory file, such as 7783CATD.DDF.  The FILENAME may also include
%   the directory name.  If FILENAME does not include the directory, then
%   it must be in the current directory or in a directory on the MATLAB
%   path.
%
%   SDTSIFC is a wrapper function with no argument checking around the
%   SDTSMEX MEX-function. On Windows, the function must CD to the data
%   directory.
%    
%   Example
%   -------
%   info = sdtsIfc('9129CATD.DDF');
%
%   See also SDTSDEMREAD, SDTSINFO.

% Copyright 2005-2011 The MathWorks, Inc.


if ispc
    % On Windows only, CD to the data directory. When the function
    % terminates, onCleanup will restore the current directory.
    cwd = pwd;
    cdobj = onCleanup(@() cd(cwd));
    pathstr = fileparts(filename);
    cd(pathstr)
end

% Only read the Z data if requested.
switch nargout
    case {0,1}
        info = sdtsmex(filename);
    case 2
        [info, Z] = sdtsmex(filename);
end
