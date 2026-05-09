% retrieves the controller type from the new devices
function [isOK,sType] = detValidSerialContollerV3(hS,vStr)

% initialisations
[nChk,tOut] = deal(10,0.2);
[isOK,sType] = deal(false,'inuse');

% opens the serial controlle
if isa(hS,'serial')
    try
        fopen(hS);
    catch ME
        if (strcmp(ME.identifier,'MATLAB:serial:fopen:opfailed'))
            % if the device is already in use, then return an empty array        
            return
        else
            rethrow(ME);
        end
    end
end

% keep checking for the device output string
for i = 1:nChk
    if isa(hS,'serial')
        if hS.BytesAvailable > 0
            % retrieves the device type
            sType = fscanf(hS,'%s');
            break
    
        else
            % otherwise, pause for a little bit
            pause(tOut)
        end
    elseif isa(hS,'internal.Serialport')
        if hS.NumBytesAvailable > 0
            % retrieves the device type
            sType = hS.readline();
            break
    
        else
            % otherwise, pause for a little bit
            pause(tOut)
        end
    end
end

%
switch sType
    case ('HT2modularv0.1')
        sType = 'HTControllerV3';
    otherwise
        sType = [];
end

% determines if the serial controller matches the valid string array
if (nargin == 2)
    isOK = any(strcmp(vStr,sType));
else
    isOK = true;
end

% flushes the device and closes the device
fclose(hS);