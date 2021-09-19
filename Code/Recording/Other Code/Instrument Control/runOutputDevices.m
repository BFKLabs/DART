% --- runs the DAC/Serial output devices
function runOutputDevices(objDAC,iDAC,varargin)

% sets the DAC indices
if (nargin < 2); iDAC = 1:length(objDAC); end

% runs the output device based on the type
for i = 1:length(iDAC)
    % object is a timer
    if (nargin == 3)
        runTimedDevice(objDAC(iDAC(i)),1)            
    else
        runTimedDevice(objDAC(iDAC(i)))
    end
end
