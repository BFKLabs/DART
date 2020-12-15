function installgenicam(installDir)
% INSTALLGENICAM Installs the GenICam software on Windows.
%    INSTALLGENICAM installs the GenICam software on Windows to the default
%    installation directory and configures the necessary environment
%    variables.  This installation process requires administrator privileges
%    on Windows Vista and Windows 7.  The installation process will attempt
%    to ask for the necessary rights to complete the application.  If this
%    fails, it may be necessary to run MATLAB with administrative
%    privileges and repeat the installation process.
%
%    INSTALLGENICAM(INSTALLDIR) installs the GenICam software into the
%    directory specified by INSTALLDIR.  This directory does not need to
%    exist prior to calling INSTALLGENICAM.
%
%    The GenICam software is needed by the Image Acquisition Toolbox gige
%    adaptor in order to access GigE Vision compliant cameras.  This
%    function installs the necessary software and configures the
%    environment variables so the toolbox is able to use it.

% Copyright 2010-2012 The MathWorks, Inc.

narginchk(0,1);

if ~ispc
    error(message('imaq:genicaminstall:platform'));
end

% /S is a silent install.
installOptions = ' /S';
if nargin == 1
    % If a directory was provided, install into that directory.
    installOptions = [installOptions ' /D=' installDir];
end

installerExeDir = fullfile(toolboxdir('imaq'), 'imaqextern', 'drivers', computer('arch'), 'genicam');

switch computer('arch')
    case 'win32'
        installerExeFile = 'GenICam_VC80_Win32_i86_v2_3_0.exe';
    case 'win64'
        installerExeFile = 'GenICam_VC80_Win64_x64_v2_3_0.exe';
end

installerCmd = fullfile(installerExeDir, installerExeFile);
installerCmd = ['call "' installerCmd '"' installOptions];

try
    status = system(installerCmd);
catch ex
    error(message('imaq:genicaminstall:error', ex.message));
end

if (status == 0)
    successMessage = message('imaq:genicaminstall:success');
    disp(getString(successMessage));
else
    error(message('imaq:genicaminstall:unknownerror'));
end
    
