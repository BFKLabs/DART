% --- loads the default preset data file
function varargout = loadDefaultPresetData(dName)

% initialisations
varargout = cell(nargout,1);

try 
    % attempts to create the default device property object
    objDP = DefDeviceProps();
    
    % if the parameter file doesn't exists, then return 
    if ~exist(objDP.paraFile,'file')
        return
    end
    
catch
    % if this failed, then exit
    return
end

% loads the data file
dpData = load(objDP.paraFile);
if ~isfield(dpData,'dName') || ~isfield(dpData,'dFile')
    % if it doesn't have the correct format, then exit
    return    
end

% determines the matching device in the device list 
iDevD = strcmp(dpData.dName,dName);
if ~any(iDevD)
    % if there are no matching default properties for this device listed in
    % the main data file, then exit
    return
    
elseif ~exist(dpData.dFile{iDevD},'file')
    % if the default property file doesn't exist, then exit
    return
end

% loads the device specific property file
varargout{1} = importdata(dpData.dFile{iDevD},'-mat');
if ~isfield(varargout{1},'Preset') || ~exist(varargout{1}.Preset,'file')
    % if there are no presets for the file, or the file doesn't exist, then
    % exit the function
    return
    
elseif nargout == 1
    % if only retrieving the default properties then exit
    return    
end

% loads the device preset data file
varargout{2} = importdata(varargout{1}.Preset,'-mat');