function imaqsupport(varargin)
% IMAQSUPPORT Image Acquisition Toolbox troubleshooting utility.
%
%    IMAQSUPPORT, returns diagnostic information for all installed hardware
%    adaptors and saves output to text file 'imaqsupport.txt' in the current
%    folder.
%
%    IMAQSUPPORT('ADAPTOR'), returns diagnostic information for hardware adaptor,
%    'ADAPTOR', and saves output to text file, 'imaqsupport.txt' in the
%    current folder.
%
%    IMAQSUPPORT('ADAPTOR','FILENAME'), returns diagnostic information for hardware
%    adaptor, 'ADAPTOR', and saves the results to the text file FILENAME in the
%    current folder.
%
%    Examples:
%       imaqsupport
%       imaqsupport('winvideo')
%       imaqsupport('winvideo','myfile.txt')
%
%   See also IMAQHWINFO, VIDEOINPUT.

%   KL 10-24-02
%   Copyright 2001-2013 The MathWorks, Inc.

filename = 'imaqsupport.txt'; %default text file name
hwInfo=imaqhwinfo;
switch nargin,
    case 0,
        adaptors=hwInfo.InstalledAdaptors;
    case 1,
        adaptors=varargin(1);
    case 2,
        adaptors=varargin(1);
        filename = varargin{2};
    otherwise,
        narginchk(0, 2);
end % switch

% Check that adaptor string is contained in a cell.
if ~iscellstr(adaptors),
    error(message('imaq:imaqsupport:stringAdaptor'));
end

% Check that filename is a string.
if (~ischar(filename))
    error(message('imaq:imaqsupport:stringFilename'));
end

% Deletes text file, 'FILENAME', if one already exists.
if ~isempty(dir(filename))
    try
        delete(filename);
    catch err  
        error(message('imaq:imaqsupport:filedelete'));
    end
end % if

% Opens 'FILENAME' for writing
fid = fopen(filename,'wt');
if (fid==-1)
    error(message('imaq:imaqsupport:fileopen'));
end
c = onCleanup(@()fclose(fid));

% Display message to command window.
disp('Generating diagnostic information ...');

% Variables cr and sp represent strings that are repeatedly called.
cr = sprintf('\n');
sp = '----------';

% MATLAB, OS, Java, and IMAQ Toolbox version information
fprintf(fid, evalc('ver(''imaq'')'));

switch computer
    case 'PCWIN64'
        archPath = 'win64';
    case 'PCWIN'
        archPath = 'win32';
    otherwise
        archPath = lower(computer);
end

fprintf(fid, [cr, sp, 'DATE/TIME', sp, cr, cr, '%s', cr, cr], datestr(now));

spPkgDir = fullfile(privateGetMatlabRoot, 'toolbox', 'imaq', 'supportpackages');
isSBMode = exist(spPkgDir, 'dir');

% DirectX version information
if ispc
    adaptor = which ('mwwinvideoimaq.dll');
    fprintf(fid, [cr, sp, 'DIRECTX', sp, cr]);

    if ~isempty(adaptor)
        fprintf(fid, [cr,'DirectX Version: %s', cr, cr], mexdxver(adaptor));        
    else
        fprintf(fid, [cr,'DirectX Version: %s', cr, cr], 'OS Generic Video Support Package not installed');
    end
end

%Standalone device detection information
if ispc
    detectionApplication = fullfile(matlabroot, 'toolbox', 'imaq', 'imaqextern', 'utilities', 'detectDevices', archPath, 'detectDevices.exe');
    detectionApplication = ['"' detectionApplication '"'];
    [~, detectionOutput] = system([detectionApplication ' -nopause']);
    fprintf(fid, [cr, sp, 'STAND ALONE HARDWARE DETECTION', sp, cr, cr, '%s'], detectionOutput);
end

% IMAQ Hardware information
imaqhwinfostr = evalc('disp(imaqhwinfo)');
fprintf(fid, [cr, sp, 'AVAILABLE HARDWARE', sp, cr, cr, '%s'], imaqhwinfostr);

thirdpartystr = evalc('imaqregister');
fprintf(fid, [cr, sp, 'THIRD PARTY ADAPTORS REGISTERED WITH IMAQREGISTER', sp, cr, cr, '%s'], thirdpartystr);

% Display IMAQ adaptor and device information
for adaptorcount = 1:length(adaptors),
    adaptorname = adaptors{adaptorcount};
    fprintf(fid, [cr, sp,'%s ADAPTOR', sp, cr, cr], upper(adaptorname));
    
    % IMAQ Adaptor info
    try
        adaptorInfo = imaqhwinfo(adaptorname); %imaqhwinfo for adaptor
    catch err
        % invalid adaptor name
        throw(err);
    end %try
    
    if ~isempty(adaptorInfo)
        fprintf(fid, ['Adaptor Name: %s', cr], adaptorInfo.AdaptorName);
        fprintf(fid, ['Adaptor DLL: %s', cr, cr], adaptorInfo.AdaptorDllName);
    end
    
    % IMAQHWINFO for adaptor
    imaqhwadaptstr = evalc(['disp(imaqhwinfo(''',adaptorname,'''))']);
    fprintf(fid, ['IMAQHWINFO: ', cr, '%s'], imaqhwadaptstr);
    
    % IMAQ Device info
    fprintf(fid, [cr, 'Available Devices: ', cr]);
    if ~isempty(adaptorInfo)
        for devicecount = 1:length(adaptorInfo.DeviceInfo),
            fprintf(fid, [cr, '\tDevice Name: %s', cr], ...
                adaptorInfo.DeviceInfo(devicecount).DeviceName);
            fprintf(fid, ['\tDevice ID: %i', cr], ...
                adaptorInfo.DeviceInfo(devicecount).DeviceID);
            fprintf(fid, ['\tDevice File Supported: %i', cr], ...
                adaptorInfo.DeviceInfo(devicecount).DeviceFileSupported);
            fprintf(fid, ['\tDefault Format: %s', cr], ...
                adaptorInfo.DeviceInfo(devicecount).DefaultFormat);
            fprintf(fid, ['\tSupported Formats: ', cr, cr, '%s'], ...
                evalc('disp(adaptorInfo.DeviceInfo(devicecount).SupportedFormats'')'));
        end % for
    end % if
    
end % for

% Display existing videoinput objects

fprintf(fid, [cr, cr, sp, 'EXISTING VIDEOINPUT OBJECT DISPLAY', sp, cr, cr]);

vidobjs = imaqfind;
if ~isempty(vidobjs)
    for objectcount = 1:length(vidobjs)
        displayVideoinputObjInfo(vidobjs(objectcount), true);
    end
else
    fprintf(fid, cr);
end

% Create video input objects for all devices and formats.

% cycle through list of adaptors
for adaptorcount = 1:length(adaptors),
    adaptorname = adaptors{adaptorcount};
    adaptorInfo = imaqhwinfo(adaptorname); %imaqhwinfo for adaptor
    fprintf(fid, [sp,'VIDEOINPUT OBJECT CREATION - ', upper(adaptorname), sp, cr]);
    if length(adaptorInfo.DeviceInfo) < 1
        fprintf(fid, [cr cr]);
        continue;
    end
    
    % cycle through list of devices
    for devicecount = 1:length(adaptorInfo.DeviceInfo)
        adaptorID = num2str(adaptorInfo.DeviceInfo(devicecount).DeviceID);
        fprintf(fid, cr);
        
        % cycle through list of formats
        for formatcount = 1:length(adaptorInfo.DeviceInfo(devicecount).SupportedFormats),
            currentformat = adaptorInfo.DeviceInfo(devicecount).SupportedFormats{formatcount};
            evalstr = ['videoinput(''', adaptorname,''', ',adaptorID,', ''',currentformat,''')'];
            fprintf(fid, evalstr);
            
            % Try to create videoinput object
            % If successful, then it is necessary to delete the object
            % otherwise objects remain in memory after function exits.
            vidobj = [];
            try
                evalc(['vidobj = ', evalstr]);
                fprintf(fid, ['--SUCCEEDED', cr]);
                displayVideoinputObjInfo(vidobj, (formatcount == 1));
                delete(vidobj);
            catch err
                fprintf(fid, ['--FAILED', cr, err.message, cr, cr]);
            end %try
            
        end%for
        
    end % for
    
end % for

% MATLABROOT directory
fprintf(fid, [cr, sp, 'MATLAB ROOT DIRECTORY', sp, cr, cr]);
fprintf(fid, ['\t%s', cr], privateGetMatlabRoot);

% MATLAB path
fprintf(fid, [cr, sp, 'MATLAB PATH', sp, cr, cr]);
fprintf(fid, '%s', evalc('path'));


% Print out the contents of support packages installed adaptors directory
for adaptorcount = 1:length(adaptors)
    currentAdaptorInfo = imaqhwinfo(adaptors{adaptorcount});
    currentAdaptorFullPath = currentAdaptorInfo.AdaptorDllName;
    currentAdaptorDir = fileparts(currentAdaptorFullPath);
    fprintf(fid, [cr, sp, strrep(upper(currentAdaptorDir), '\', '\\'), ' Directory', sp, cr, cr]);
    
    if ispc
        [~, adaptorDirContents]=system(['dir ' currentAdaptorDir]);
    else
        [~, adaptorDirContents]=system(['ls -l ' currentAdaptorDir]);
    end
    
    fprintf(fid, sprintf('%s', strrep(adaptorDirContents, '\', '\\')));
end % for 

if ~ispc
    fprintf(fid, [cr, sp, 'Adaptor Dependencies', sp, cr, cr]);
    previousWorkingDir = pwd;
    for adaptorcount = 1:length(adaptors)
        currentAdaptorInfo = imaqhwinfo(adaptors{adaptorcount});
        currentAdaptorFullPath = currentAdaptorInfo.AdaptorDllName;
        currentAdaptorDir = fileparts(currentAdaptorFullPath);
        cd(currentAdaptorDir);
        adaptorFiles = []; %#ok<NASGU>
        if ismac
            adaptorFiles = dir('*.dylib');
            depTool = 'xcrun otool -L ';
        else
            adaptorFiles = dir('*.so');
            depTool = 'ldd ';
        end
        for aa = 1:length(adaptorFiles)
            [~, libInfo] = system([depTool  adaptorFiles(aa).name]);
            fprintf(fid, ['Dependencies for %s: ', cr, '%s', cr, cr], adaptorFiles(aa).name, libInfo);
        end
    end
    cd(previousWorkingDir);
    
    thirdPartyAdaptors = imaqregister;
    for aa = 1:length(thirdPartyAdaptors)
        [~, libInfo] = system([depTool  thirdPartyAdaptors{aa}]);
        fprintf(fid, ['Dependencies for %s: ', cr, '%s', cr, cr], thirdPartyAdaptors{aa}, libInfo);
    end
end

% IMAQMEM information
imaqmemstr = evalc('disp(imaqmem)');
fprintf(fid, [cr, cr, sp, 'IMAGE ACQUISITION MEMORY INFORMATION', sp, cr, cr, '%s'], imaqmemstr);

% CPU information
fprintf(fid, [cr, sp, 'CPU/SYSTEM INFORMATION', sp, cr, cr]);
if ispc
    fprintf(fid, [cr, sp, sp, 'CPUINFO', sp, sp, cr, cr]);
    try
        NET.addAssembly('mscorlib');
        localMachineRoot = Microsoft.Win32.Registry.LocalMachine;
        cpuParent = localMachineRoot.OpenSubKey('HARDWARE\DESCRIPTION\SYSTEM\CentralProcessor');
        processors = cpuParent.GetSubKeyNames();
        totalLogicalCPUs = cpuParent.SubKeyCount();
        for cpuid = 1:totalLogicalCPUs
            fprintf(fid, ['CPU %d: %s' cr], cpuid, cpuParent.OpenSubKey(processors(cpuid)).GetValue('ProcessorNameString').char);
        end
    catch %#ok<CTCH>
    end
    
    fprintf(fid, [cr, sp, sp, 'SYSTEMINFO', sp, sp, cr, cr]);
    [~, systemInfo]=system('systeminfo');
    fprintf(fid, sprintf('%s', strrep(systemInfo, '\', '\\')));
elseif ismac
    fprintf(fid, [cr, sp, sp, 'SYSTEM_PROFILER', sp, sp, cr, cr]);
    [~, systemInfo]=system('system_profiler SPHardwareDataType SPNetworkDataType SPEthernetDataType SPFireWireDataType SPFirewallDataType SPUSBDataType');
    fprintf(fid, sprintf('%s', systemInfo));
    
    fprintf(fid, [cr, sp, sp, 'SYSCTL', sp, sp, cr, cr]);
    [~, systemInfo]=system('sysctl -a kern.ipc.maxsockbuf');
    fprintf(fid, sprintf('%s', systemInfo));
    [~, systemInfo]=system('sysctl -a net.inet.udp.recvspace');
    fprintf(fid, sprintf('%s', systemInfo));
else % Linux
    fprintf(fid, [cr, sp, sp, '/PROC/CPUINFO', sp, sp, cr, cr]);
    [~, systemInfo]=system('cat /proc/cpuinfo');
    fprintf(fid, sprintf('%s', systemInfo));
    
    fprintf(fid, [cr, sp, sp, '/LIB/LIBC.SO.6', sp, sp, cr, cr]);
    [~, systemInfo]=system('/lib/libc.so.6 -version');
    fprintf(fid, sprintf('%s', systemInfo));
    
    fprintf(fid, [cr, sp, sp, '/PROC/SYS/KERNEL/TAINTED', sp, sp, cr, cr]);
    [~, systemInfo]=system('cat /proc/sys/kernel/tainted');
    fprintf(fid, sprintf('%s', systemInfo));
    
    fprintf(fid, [cr, sp, sp, 'SYSCTL', sp, sp, cr, cr]);
    [~, systemInfo]=system('sysctl net.core.rmem_default');
    fprintf(fid, sprintf('%s', systemInfo));
    [~, systemInfo]=system('sysctl net.core.rmem_max');
    fprintf(fid, sprintf('%s', systemInfo));
    
    fprintf(fid, [cr, sp, sp, 'DMESG for USB', sp, sp, cr, cr]);
    [~, systemInfo]=system('dmesg | grep -i usb');
    fprintf(fid, sprintf('%s', systemInfo));
end

fprintf(fid, [cr, sp, 'SETTINGS', sp, cr, cr]);
if ismac
    fprintf(fid, 'Framegrab Timeout = %d\n', imaqmex('feature', '-macvideoFramegrabDuringDeviceDiscoveryTimeout'));
end
if ispc
    fprintf(fid, 'Use Little Endian DCAM = %d\n', imaqmex('feature', '-useDCAMLittleEndian'));
end
fprintf(fid, 'Packet Timeout = %d\n', imaqmex('feature', '-gigePacketAckTimeout'));
fprintf(fid, 'Heartbeat Timeout = %d\n', imaqmex('feature', '-gigeHeartbeatTimeout'));
fprintf(fid, 'Packet Retries = %d\n', imaqmex('feature', '-gigeCommandPacketRetries'));
fprintf(fid, 'Disable Force IP = %d\n', imaqmex('feature', '-gigeDisableForceIP'));
fprintf(fid, 'Disable Packet Resend = %d\n', imaqmex('feature', '-gigeDisablePacketResend'));
fprintf(fid, 'Preview Full Bit Depth = %d\n', imaqmex('feature', '-previewFullBitDepth'));

% Dynamic loader path information:
%       on Windows this is PATH
%       on Linux this is LD_LIBRARY_PATH
%       on Mac OS X this is LD_LIBRARY_PATH, DYLD_LIBRARY_PATH, or
%           DYLD_FALLBACK_LIBRARY_PATH
fprintf(fid, [cr, sp, 'DYNAMIC LOADER PATH', sp, cr, cr]);
if ispc
    fprintf(fid, [cr, sp, sp, 'PATH', sp, sp, cr, cr]);
    fprintf(fid, '%s', strrep(getenv('PATH'), ';', cr));
elseif ismac
    fprintf(fid, [cr, sp, sp, 'LD_LIBRARY_PATH', sp, sp, cr, cr]);
    fprintf(fid, '%s', [strrep(getenv('LD_LIBRARY_PATH'), ':', cr), cr]);
    fprintf(fid, [cr, sp, sp, 'DYLD_LIBRARY_PATH', sp, sp, cr, cr]);
    fprintf(fid, '%s', [strrep(getenv('DYLD_LIBRARY_PATH'), ':', cr), cr]);
    fprintf(fid, [cr, sp, sp, 'DYLD_FALLBACK_LIBRARY_PATH', sp, sp, cr, cr]);
    fprintf(fid, '%s', [strrep(getenv('DYLD_FALLBACK_LIBRARY_PATH'), ':', cr), cr]);
else % Linux
    fprintf(fid, [cr, sp, sp, 'LD_LIBRARY_PATH', sp, sp, cr, cr]);
    fprintf(fid, '%s', [strrep(getenv('LD_LIBRARY_PATH'), ':', cr), cr]);
end

fprintf(fid, [cr, sp, 'ENVIRONMENT VARIABLES', sp, cr, cr]);

fprintf(fid, [cr, sp, sp, 'GENICAM', sp, sp, cr, cr]);

fprintf(fid, 'GENICAM_CACHE_V2_3 = %s\n', getenv('GENICAM_CACHE_V2_3'));
if exist(getenv('GENICAM_CACHE_V2_3'), 'dir')
    fprintf(fid, '\t %s present.\n', getenv('GENICAM_CACHE_V2_3'));
else
    fprintf(fid, '\t If the value of GENICAM_CACHE_V2_3 (%s) is correct, then it needs to be created.\n', getenv('GENICAM_CACHE_V2_3'));
end

fprintf(fid, '\nGENICAM_LOG_CONFIG_V2_3 = %s\n', getenv('GENICAM_LOG_CONFIG_V2_3'));
if exist(getenv('GENICAM_LOG_CONFIG_V2_3'), 'file')
    fprintf(fid, '\t %s present.\n', getenv('GENICAM_LOG_CONFIG_V2_3'));
else
    fprintf(fid, '\t %s missing.\n', getenv('GENICAM_LOG_CONFIG_V2_3'));
    fprintf(fid, '\t If the value of GENICAM_LOG_CONFIG_V2_3 (%s) is correct, then GenICam may need to be reinstalled.\n', getenv('GENICAM_LOG_CONFIG_V2_3'));
end

fprintf(fid, '\nGENICAM_ROOT_V2_3 = %s\n', getenv('GENICAM_ROOT_V2_3'));
if exist(getenv('GENICAM_ROOT_V2_3'), 'dir')
    fprintf(fid, '\t %s present.\n', getenv('GENICAM_ROOT_V2_3'));
    % Check for GCBase_MD_VC80_v2_3.dll, GenApi_MD_VC80_v2_3.dll
    if strcmp(computer('arch'), 'win32')
        if ~exist(fullfile(getenv('GENICAM_ROOT_V2_3'), 'bin', 'Win32_i86', 'GCBase_MD_VC80_v2_3.dll'), 'file')
            fprintf(fid, '\t\t!!! %s not present in %s.\n\t\t    Uninstall GenICam and rerun <MATLABROOT>\\toolbox\\imaq\\imaqextern\\installgenicam.m\n', 'GCBase_MD_VC80_v2_3.dll', getenv('GENICAM_ROOT_V2_3'));
        end
        if ~exist(fullfile(getenv('GENICAM_ROOT_V2_3'), 'bin', 'Win32_i86', 'GenApi_MD_VC80_v2_3.dll'), 'file')
            fprintf(fid, '\t\t!!! %s not present in %s.\n\t\t    Uninstall GenICam and rerun <MATLABROOT>\\toolbox\\imaq\\imaqextern\\installgenicam.m\n', 'GenApi_MD_VC80_v2_3.dll', getenv('GENICAM_ROOT_V2_3'));
        end
    elseif strcmp(computer('arch'), 'win64')
        if ~exist(fullfile(getenv('GENICAM_ROOT_V2_3'), 'bin', 'Win64_x64', 'GCBase_MD_VC80_v2_3.dll'), 'file')
            fprintf(fid, '\t\t!!! %s not present in %s.\n\t\t    Uninstall GenICam and rerun <MATLABROOT>\\toolbox\\imaq\\imaqextern\\installgenicam.m\n', 'GCBase_MD_VC80_v2_3.dll', getenv('GENICAM_ROOT_V2_3'));
        end
        if ~exist(fullfile(getenv('GENICAM_ROOT_V2_3'), 'bin', 'Win64_x64', 'GenApi_MD_VC80_v2_3.dll'), 'file')
            fprintf(fid, '\t\t!!! %s not present in %s.\n\t\t    Uninstall GenICam and rerun <MATLABROOT>\\toolbox\\imaq\\imaqextern\\installgenicam.m\n', 'GenApi_MD_VC80_v2_3.dll', getenv('GENICAM_ROOT_V2_3'));
        end
    end
else
    fprintf(fid, '\t %s missing.\n', getenv('GENICAM_ROOT_V2_3'));
    fprintf(fid, '\t If the value of GENICAM_ROOT_V2_3 (%s) is correct, then GenICam may need to be reinstalled.\n', getenv('GENICAM_ROOT_V2_3'));
end

fprintf(fid, '\nMWIMAQ_GENICAM_XML_FILES = %s\n', getenv('MWIMAQ_GENICAM_XML_FILES'));
if exist(getenv('MWIMAQ_GENICAM_XML_FILES'), 'dir')
    fprintf(fid, '\t %s present.\n', getenv('MWIMAQ_GENICAM_XML_FILES'));
    
    % Print out the contents of the MWIMAQ_GENICAM_XML_FILES directory.
    fprintf(fid, [cr, sp, strrep(upper(getenv('MWIMAQ_GENICAM_XML_FILES')), '\', '\\'), ' Directory', sp, cr, cr]);
    if ispc
        [~, xmlDirContents]=system(['dir ' getenv('MWIMAQ_GENICAM_XML_FILES')]);
    else
        [~, xmlDirContents]=system(['ls -l ' getenv('MWIMAQ_GENICAM_XML_FILES')]);
    end
    fprintf(fid, sprintf('%s', strrep(xmlDirContents, '\', '\\')));
end

if ~ismac
    fprintf(fid, [cr, sp, sp, 'GENTL', sp, sp, cr, cr]);
    
    if isempty(strfind(computer,'64'))
        gentlPath = getenv('GENICAM_GENTL32_PATH');
        fprintf(fid, 'GENICAM_GENTL32_PATH = %s\n', gentlPath);
    else
        gentlPath = getenv('GENICAM_GENTL64_PATH');
        fprintf(fid, 'GENICAM_GENTL64_PATH = %s\n', gentlPath);
    end
    
    checkGenTLProducers(gentlPath);
end
 
% End of the test
fprintf(fid, [cr, sp, sp,'END TEST', sp, sp, cr]);
fprintf(fid, [cr, 'This information has been saved in the text file: ', cr, ...
    '%s', cr], filename);
fprintf(fid, [cr, 'If any errors occurred, please e-mail this information to:', cr, ...
    'support@mathworks.com', cr]);

% Display text output to user
if ~isdeployed
    edit(filename);
end
% end imaqsupport

    function checkGenTLProducers(pathToCheck)
        remain = pathToCheck;
        while ~isempty(remain)
            [genTLProdDir, remain] = strtok(remain, pathsep); %#ok<STTOK>
            if ~isempty(genTLProdDir)
                ctiFile = dir(fullfile(genTLProdDir, filesep, '*.cti'));
                if ~isempty(ctiFile)
                    fprintf(fid, '\nProducer found = %s\n', fullfile(genTLProdDir, filesep, ctiFile.name));
                else
                    fprintf(fid, '\nNo producers found in %s\n', genTLProdDir);
                end
            end
        end
    end

    function displayVideoinputObjInfo(vidobj, printHWInfo)
        if printHWInfo
            hwInfo = imaqhwinfo(vidobj);
            fprintf(fid, ['\tAdaptor Name: %s', cr], ...
                hwInfo.AdaptorName);
            fprintf(fid, ['\tDevice Name: %s', cr], ...
                hwInfo.DeviceName);
            fprintf(fid, ['\tDevice ID: %i', cr], ...
                vidobj.DeviceID);
            fprintf(fid, ['\tVideoFormat: %s', cr], ...
                vidobj.VideoFormat);
            fprintf(fid, ['\tMax Height: %i', cr], ...
                hwInfo.MaxHeight);
            fprintf(fid, ['\tMax Width: %i', cr], ...
                hwInfo.MaxWidth);
            fprintf(fid, ['\tNative Data Type: %s', cr], ...
                hwInfo.NativeDataType);
            fprintf(fid, ['\tTotal Sources: %i', cr], ...
                hwInfo.TotalSources);
            fprintf(fid, ['\tVendor Driver Description: %s', cr], ...
                hwInfo.VendorDriverDescription);
            fprintf(fid, ['\tVendor Driver Version: %s', cr, cr], ...
                hwInfo.VendorDriverVersion);
        end
        fprintf(fid, ['Current device specific property settings (using GET)' cr]);
        srcpropvals=evalc('get(getselectedsource(vidobj))');
        fprintf(fid, '%s', srcpropvals);
        fprintf(fid, ['Available device specific property settings (using SET)' cr]);
        srcpropvals=evalc('set(getselectedsource(vidobj))');
        fprintf(fid, ['%s' cr], srcpropvals);
    end

end
