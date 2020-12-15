function supportPackageInstaller
% This is an internal wrapper function to fire support package installer
% from matlab for DAQ Support Packages

% Copyright 2013 The MathWorks, Inc.
%
hwconnectinstaller.launchInstaller('BaseProduct','Data Acquisition Toolbox');
end