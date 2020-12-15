function [a, b] = projaccess(direction, proj, c1, c2)
%PROJACCESS Process coordinates using PROJ.4 library
%
%   [X, Y] = PROJACCESS('FWD', PROJ, LAT, LON) applies the forward
%   transformation defined by the map projection in the PROJ structure,
%   converting locations given in latitude and longitude to a planar,
%   projected map coordinate system. PROJ may be either a map projection
%   MSTRUCT or a GeoTIFF INFO structure. The transformation is applied
%   using the PROJ.4 library.
%
%   [LAT, LON] = PROJACCESS('INV', PROJ, X, Y) applies the inverse
%   transformation defined by the map projection in the PROJ structure,
%   converting locations in a planar, projected map coordinate system to
%   latitudes and longitudes.
%
%   See also PROJFWD, PROJINV, PROJLIST

% Copyright 1996-2012 The MathWorks, Inc.

% The proj4lib MEX function expects vectors of class double.
% Preserve the class type of the returned values. The inputs to this
% function are expected to be either single or double.
if ~all(strcmp('double', {class(c1), class(c2)}))
    castToSingle = true;
    c1 = double(c1);
    c2 = double(c2);
else
    castToSingle = false;
end

% Find the NaN values and convert to 0. The PROJ.4 library does not accept
% NaN values.
c1NanIndex = find(isnan(c1));
c2NaNIndex = find(isnan(c2));
c1(c1NanIndex) = 0;
c2(c2NaNIndex) = 0;

% Convert the input GTIF structure to a string suitable for the PROJ.4
% library.
gtif  = proj2gtif(proj);
proj4 = gtif2proj4(gtif);

% Get the PROJ.4 folder name.
projFolderName = getProjFolderName();

% Process the points using PROJ.4
[a, b] = proj4lib(proj4, direction, c1, c2, projFolderName);

% Cast the values back to their original class type, if required.
% If any of the vectors are class single, then cast both back to single.
% (This is the same behavior as mfwdtran or minvtran).
if castToSingle
    a = single(a);
    b = single(b);
end

% Reset NaN indices.
% a: lat or x
% b: lon or y
a(c2NaNIndex) = NaN;
b(c1NanIndex) = NaN;

% Reshape output to the input and convert Inf to NaN.
a = reshape(a,size(c2));
a(a==Inf) = NaN;
b = reshape(b,size(c1));
b(b==Inf) = NaN;

%--------------------------------------------------------------------------

function name = getProjFolderName()
%
%   name = getProjFolderName() returns the full path name for the PROJ
%   folder: matlabroot/toolbox/map/mapproj/projdata/proj

% Obtain the PROJ folder name.
if isdeployed
    % <CTFDIR>
    pathstr = fileparts(which('mapproj/vgrint1.m'));
else
    % <matlabroot>/toolbox/map/mapproj
    pathstr = fullfile(matlabroot,'toolbox','map','mapproj');
end

% <pathstr>/projdata/proj/proj_def.dat
projFile = fullfile(pathstr,'projdata','proj','proj_def.dat');

name = checkFolder(projFile);

%--------------------------------------------------------------------------

function folderName = checkFolder(fname)
% Obtain the folder name from the input filename. If the file specified 
% the string, FNAME, is not found, return the default value, ''.
%
%  The GeoTIFF and PROJ.4 libraries will check the directory names for
%  empty if checkfilename returns with an error, i.e. if the projdata
%  directory is not found on the path. If the directory name is empty the
%  libraries will attempt to use MATLABROOT and the hardwired pathname for
%  the location of the proj data files.

try
    fileName = internal.map.checkfilename(fname, mfilename, 1);
    folderName  = fileparts(fileName);
catch e %#ok<NASGU>
    % An error occurred.
    % Set folderName to an empty string.
    folderName = '';
end
