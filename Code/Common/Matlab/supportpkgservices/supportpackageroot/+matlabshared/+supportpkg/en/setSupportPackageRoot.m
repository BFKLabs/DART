% MATLABSHARED.SUPPORTPKG.SETSUPPORTPACKAGEROOT(INSTALLDIR) - Set the
% support package root directory that Support Package Installer will use to
% install all support packages to.
%
%   MATLABSHARED.SUPPORTPKG.SETSUPPORTPACKAGEROOT(INSTALLDIR) will set the
%   current support package root directory to the location specified by
%   INSTALLDIR. INSTALLDIR is the full path to the desired support package
%   installation root. INSTALLDIR cannot be empty. If INSTALLDIR doesn't
%   exist, this function will try to create the directory.
%
%   This function requires adminstrative privileges and wlll throw an error
%   if the support package root cannot be changed.
%
%   This function cannot be used while the Support Package Installer is
%   open. Close the Installer before trying to use this function.
%
%   On changing the root successfully, the following changes will take
%   places immediately: i. Support packages from the previous support
%   package root will be unloaded. ii. Any support packages available in
%   the new support packages root directory will be loaded iii. MATLAB will
%   be refreshed. Note that the above changes, if successful, will persist
%   and be available to all users of this MATLAB installation.
%
% 	Example:
%       On Windows:
% 
%       mySpRoot = 'C:\MySupportPackages';
%       matlabshared.supportpkg.setSupportPackageRoot(mySpRoot);
%
%   Copyright 2015 The MathWorks, Inc.

 %   Copyright 2015 The MathWorks, Inc.

