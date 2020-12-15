% --- runs the DAC/Serial output devices
function runOutputDevices(objDAC,iDAC,varargin)

% sets the DAC indices
if (nargin < 2); iDAC = 1:length(objDAC); end

% runs the output device based on the type
for i = 1:length(iDAC)
    if (isa(objDAC{iDAC(i)},'analogoutput'))
        % object is a DAC device 
        if (nargin == 3)
            runDACDeviceOld(objDAC(iDAC(i)),iDAC(i),1)
        else
            runDACDeviceOld(objDAC(iDAC(i)),iDAC(i))            
        end
    else
        % object is a timer
        if (nargin == 3)
            runTimedDevice(objDAC(iDAC(i)),1)            
        else
            runTimedDevice(objDAC(iDAC(i)))            
        end
    end
end