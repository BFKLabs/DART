function [pathlist, vendorOrXML] = privateAdaptorSearch
%PRIVATEADAPTORSEARCH Locate image acquisition adaptors.
% 
%    [PATHS, VENDORS, ERR] = PRIVATEADAPTORSEARCH locates all available image 
%    acquisition adaptor files and returns the path to each in cell array 
%    PATHS. VENDORS is a cell array of the vendor name for each path 
%    returned. If an error occurs, an error flag is returned in ERR.
%
%    The sequence for locating adaptor related files are as follows:
%       1) Determine if the path to the adaptor files was provided.
%       2) Locate MathWorks supplied adaptors in the imaqadaptors directory.
%       3) Locate third-party adaptors in the imaqexternal directory.
%
%    PRIVATEADAPTORSEARCH is used internally by the toolbox engine. It is
%    not intended to be used directly by an end user.
%

%    CP 9-01-01
%    Copyright 2001-2013 The MathWorks, Inc.

if ispc
    osExt = '.dll';
    osDir = computer;
    if (strcmp(osDir,'PCWIN64'))
        osDir = 'win64';
    else
        osDir = 'win32';
    end        
elseif strfind(computer, 'GLNX')
    osExt = '.so';
    osDir = lower(computer);
elseif strfind(computer, 'MAC')
    osExt = '.dylib';
    osDir = lower(computer);
else
    error(message('imaq:privateAdaptorSearch:invalidOS'));
end

% Define the toolbox root location.
imaqRoot = which(['imaqmex.' mexext], '-all');

% Define adaptor directory locations.
mwAdaptorDir = [fileparts(imaqRoot{1}) 'adaptors'];

% Initialize variable:
adaptorPaths = {};
vendorNames = {};
wildFile = ['*' osExt];

% Step (1):
% No adaptor provided as an input.

% Step (2):
% Start by performing a wildcard search (ex. *.dll)
% for any MathWorks adaptors.
tlbxSearchPath = fullfile(mwAdaptorDir, osDir, wildFile);
searchPath = tlbxSearchPath;
dirList = dir(searchPath);

[adaptorPaths, vendorNames] = localUpdateAdaptorList(dirList, osExt, mwAdaptorDir, adaptorPaths, vendorNames);

%********
% Step (3):
% @TODO: The following section looks inside the support package to add the adaptors. 
% We should remove this code (if no longer required by test code) after all
% support packages are created.
%********
% Add adaptors from the supportpackages area.
startDir = fullfile(toolboxdir('imaq'), 'supportpackages');
adaptorList = dir(startDir);
for idx = 1:length(adaptorList)
    sppkgAdaptorDir = fullfile(startDir, adaptorList(idx).name, 'adaptor');
    adaptorSearchPath = fullfile(sppkgAdaptorDir, osDir, wildFile);
    filesList = dir(adaptorSearchPath);
    
    [adaptorPaths, vendorNames] = localUpdateAdaptorList(filesList, osExt, sppkgAdaptorDir, adaptorPaths, vendorNames);
end

% Step (4):
% Look for adaptors installed using support packages.
adaptorFilesList = localgetadaptorfileslist;
% Append the OS extension.
adaptorFilesList = strcat(adaptorFilesList, osExt);
for idx = 1:length(adaptorFilesList)
    outDir = which(adaptorFilesList{idx});
    if isempty(outDir) % Adaptor not found on path.
        continue;
    end
    
    rootVendorName = strrep(adaptorFilesList{idx}, 'mw', '');
    rootVendorName = strrep(rootVendorName, ['imaq' osExt], '');
    
    [isPresent, index] = ismember(rootVendorName, vendorNames);
    
    if isPresent
        adaptorPaths{index} = outDir; 
    else
        adaptorPaths = [adaptorPaths {outDir}]; %#ok<AGROW>
        vendorNames = [vendorNames {rootVendorName}]; %#ok<AGROW>    
    end
end

% Step (5):
% Check for externally registered adaptors.
try
    registeredAdaptors = privateGetSetUserPrefAdaptors;
catch exception
    if (strcmp(exception.identifier, 'MATLAB:javachk:featureNotAvailable'))
        registeredAdaptors = {};
        warnstate = warning('off', 'backtrace');
        oc = onCleanup(@()warning(warnstate));
        warning(message('imaq:imaqregister:nojvm'));
        clear('oc');
    else 
        throw(exception)
    end
end
        
for i = 1:length(registeredAdaptors)
    [~, adaptorName] = fileparts(registeredAdaptors{i});
    adaptorPaths = [adaptorPaths registeredAdaptors(i)]; %#ok<AGROW>
    vendorNames = [vendorNames {adaptorName}]; %#ok<AGROW>
end

% Use lower case names for adaptors.
vendorOrXML = lower(vendorNames);
pathlist = adaptorPaths;
%**************************************************************************
function [adaptorPaths, vendorNames] = localUpdateAdaptorList(dirList, osExt, adaptorDir, adaptorPaths, vendorNames)
for i=1:length(dirList)
    adaptorFileName = dirList(i).name;
    % Make sure it's the correct extension. DIR returns files
    % like *.dllfoobar. Also make sure file is prepended with
    % 'mw':
    %       'mw' + vendor name + 'imaq' + '.dll'
    extLen = length(osExt);
    extCorrect = strcmp(adaptorFileName(end-extLen+1:end), osExt);
    prepended = strcmp(adaptorFileName(1:2), 'mw');
    appended = strcmp(adaptorFileName(end-extLen-3:end-extLen), 'imaq');
    if extCorrect && prepended && appended,
        rootVendorName = strrep(adaptorFileName, 'mw', '');
        rootVendorName = strrep(rootVendorName, ['imaq' osExt], '');
        
        [isPresent, index] = ismember(rootVendorName, vendorNames);

        if isPresent
            adaptorPaths{index} = fullfile(adaptorDir,...
                computer('arch'), adaptorFileName); 
        else
            adaptorPaths = [adaptorPaths {fullfile(adaptorDir,...
                computer('arch'), adaptorFileName)}]; %#ok<AGROW>
            vendorNames = [vendorNames {rootVendorName}]; %#ok<AGROW>
        end            
    end
end
%**************************************************************************
function adaptorFiles = localgetadaptorfileslist
        
arch = computer('arch');
switch arch
    case 'win32'
        adaptorList = {'dalsaifc' 'dalsa' 'dcam' 'dt' ...
                       'gentl' 'gige' 'hamamatsu' 'kinect' ...
                       'matrox' 'ni' 'pointgrey' 'qimaging' 'winvideo'};
    case 'win64'
        adaptorList = {'dalsa' 'dcam' 'gentl' 'gige' 'hamamatsu' 'kinect' ...
                       'matrox' 'ni' 'pointgrey' 'qimaging' 'winvideo'};        
    case 'maci64'
        adaptorList = {'dcam' 'gige' 'macvideo'};
    case 'glnxa64'
        adaptorList = {'dcam' 'gentl' 'gige' 'linuxvideo'};
    otherwise
        assert(false, 'Unsupported platform');
end

% Form the file names without extension
adaptorFiles = strcat('mw', adaptorList, 'imaq');
%**************************************************************************