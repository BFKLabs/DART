function [dispString, port, EngLibName] = privateimaqslgetdisplaystring(OutputPortsMode, ReturnedColorSpace)
%PRIVATEIMAQSLGETDISPLAYSTRING Return a display string for the From Video Device block.
%
%    [DISPSTRING PORT] = PRIVATEIMAQSLGETDISPLAYSTRING (OUTPUTPORTSMODE, RETURNEDCOLORSPACE) 
%    returns a display string, DISPSTRING and port information, PORT, for the 
%    From Video Device Image Acquisition block . 

%    SS 09-19-06
%    Copyright 2006-2012 The MathWorks, Inc.

% We are called every time the mask is initialized, 
% so the current block is always ours.
blk = gcb;
blkh = gcbh;

% Initialize
port = [];
EngLibName = '';

% Check if we're in the library. If so, don't display any dynamic info.
parentBlk = get_param(blk, 'Parent');

if strcmpi(parentBlk, 'imaqlib')
    % This check should be done inside the outer level if statement.
    % Not all blocks have a BlockDiagramType parameter (e.g. subsystems),
    % but if the parent is imaqlib, then it will.
    blkDiagType = get_param(gcs, 'BlockDiagramType');
    if strcmpi(blkDiagType, 'library')
        dispString = 'Image Acquisition';
        % Assign port id and labels inside library
        port(1).id = 1;
        port(1).label = '';        
        return;
    end
end

% Set the block handle.
allFields = set(blkh);
if isfield(allFields, 'EngXMLPath') % Update the Engine XML path.
    set_param(blk, 'EngXMLPath', fullfile(matlabroot, 'toolbox', 'imaq', 'imaq', 'private'));
end
if isfield(allFields, 'DevXMLPath') % Update the device XML path.
    set_param(blk, 'DevXMLPath', fullfile(matlabroot, 'toolbox', 'imaq', 'imaqadaptors', computer('arch')));
end
if isfield(allFields, 'EngLibPath') % Update the engine library path.
    set_param(blk, 'EngLibPath', fullfile(matlabroot, 'toolbox', 'imaq', 'imaqblks', 'imaqmex', computer('arch')));
end

% Generate dynamic info for the block:
%   - If no devices are present, indicate no device is selected.
%   - If a device is present, indicate the device name, format and source.
%
% Query the block for the device name and handle the case where no device
% is selected.
device = get_param(blk, 'Device');
if strcmpi(device, '(none)')
    % No devices are available, so don't bother
    % customizing the display string.
    dispString = sprintf('No available\ndevices');
    port(1).id = 1;
    port(1).label = '';
    return;
end

% Update device adaptor location - required if 3p adaptor
adaptorEndIndex = strfind(device, ' ');
if ~isempty(adaptorEndIndex)
    adaptor = device(1:adaptorEndIndex(1)-1);
    try
        info = imaqhwinfo(adaptor);
        [devLibPath, EngLibName] = fileparts(info.AdaptorDllName);
        set_param(blk, 'DevXMLPath', devLibPath);
    catch e  %#ok<NASGU>
        % Do nothing.
    end
end

% Extract the device name out of the "ADAPTOR ID (NAME)" string.
spIndex = strfind(device, '(');
if ~isempty(spIndex)
    % If an ID is present, strip the device name out.
    device = device( spIndex(1)+1:end-1 );
end

% Shorten the name if it's too long (arbitrarily set to N characters).
if length(device) > 15,
    device = [device(1:12) '...'];
end

% Create the new display string. Pad the end of each line with a space to
% avoid crowding the port text labels.
formatName = get_param(blk, 'VideoFormat');
if strcmp(formatName,'From camera file')
    cameraFile = get_param(blk,'CameraFile');
    [~, formatName] = fileparts(cameraFile);
end

% Shorten the name if it's too long (arbitrarily set to N characters).
if length(formatName) > 15,
    formatName = [formatName(1:12) '...'];
end

% Get the video source name.
sourceName = get_param(blk, 'VideoSource');
if length(sourceName) > 15,
    sourceName = [sourceName(1:12) '...'];
end
dispString = sprintf('%s\n%s\n%s', device, formatName, sourceName);

% If grayscale, display only one port.
if strcmp(formatName, '')
    numberPorts = 1;
    port(1).id = 1;
    port(1).label = '';
    port(2).id = 2;
    port(2).label = '';
    port(3).id = 3;
    port(3).label = '';    
else
    if strcmp(ReturnedColorSpace,'grayscale') || ...
            strcmp(OutputPortsMode, 'One multidimensional signal')
        numberPorts = 1;
        port(1).id = 1;
        port(1).label = '';
    else % Display ports depending on OutputPortsMode.
        numberPorts = 3;
        port(1).id = 1;
        port(2).id = 2;
        port(3).id = 3;
        if ismember(ReturnedColorSpace, {'rgb', 'bayer'})
            port(1).label = 'R';
            port(2).label = 'G';
            port(3).label = 'B';
        elseif strcmpi(ReturnedColorSpace,'YCbCr')
            port(1).label = 'Y';
            port(2).label = 'Cb';
            port(3).label = 'Cr';
        else
            % Assert as invalid color space is returned. 
            assert(false, 'imaq:imaqblks:InvalidColorSpace', 'Invalid Returned Color Space from the device.');
        end
    end
end

nMetadataPorts = 0;

% For a Kinect Depth device assign a name to the Output frame port
% Retrive the SelectedMetadata from the block mask
if( ~isempty(strfind(device,'Kinect Depth')))
    port(1).label = 'Depth Frame';
    metadata = get_param(blkh, 'SelectedMetadata');
    if ( ~isempty(metadata))
        [nMetadataPorts, port] = localGetPortInfo(metadata, port);
    end
end

nOutputPorts = numberPorts + nMetadataPorts;


% We need to build the 'MaskDisplay' in the Block Library
% based on the selection of channels.
maskDisplayString = localBuildMaskDisplayString(nOutputPorts);
set(blkh, 'MaskDisplay', maskDisplayString);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function maskDisplayString = localBuildMaskDisplayString(numberPorts)
%LOCALBUILDMASKDISPLAYSTRING Updates Mask Display String value
%
%    MASKDISPLAYSTRING = LOCALBUILDMASKDISPLAYSTRING(NUMBERPORTS)
%    updates MASKDISPLAYSTRING in the library model file.
%

% Build the MaskDisplayString in the block library based on NUMBERPORTS
maskDisplayString = 'disp(str);';
portType = '''output''';

% Loop through number of ports and update mask display string.
for idx = 1:numberPorts
    portID = sprintf('port(%d).id',idx);
    portLabel = sprintf('port(%d).label', idx);
    addStr = sprintf('\nport_label(%s,%s,%s);',portType, portID, portLabel);
    maskDisplayString = strcat(maskDisplayString, addStr);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [nMetadataPorts, port] = localGetPortInfo(metaData, port)
% LOCALGETPORTINFO populates the port structure using the semi-colon delimited metaData string    

    nImageDataPorts = length(port);
    ind = strfind(metaData, ';');
    nMetadataPorts = length(ind)+1;
    metadataCell = privateimaqslgetentries(metaData);
    for idx = nImageDataPorts+1:nMetadataPorts+nImageDataPorts
        port(idx).id = idx; %#ok<*AGROW>
        port(idx).label = metadataCell{idx-nImageDataPorts};
    end

end

