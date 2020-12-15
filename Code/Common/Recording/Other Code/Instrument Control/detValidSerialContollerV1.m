% --- determines if a controller is valid
function [isOK,sType] = detValidSerialContollerV1(hS,vStr)

% opens the serial controller
try
    fopen(hS);
catch ME
    if (strcmp(ME.identifier,'MATLAB:serial:fopen:opfailed'))
        % if the device is already in use, then return an empty array
        [isOK,sType] = deal(false,'InUse');
        return
    else
        rethrow(ME);
    end
end

% flushes the input/output buffers
flushoutput(hS); pause(0.05);
flushinput(hS); pause(0.05);
serialbreak(hS); pause(0.20);

% retrieves the type string from the controller
if (hS.BytesAvailable == 0)
    % no string, so is probably a motor controller
    if (nargout == 1)
        sType = 'Motor';
    else
        sType = 'Not Applicable';
    end
else
    % otherwise, read in the type string
    sType = fscanf(hS,'%s');
    flushoutput(hS); 
    flushinput(hS);
end

% determines if the serial controller matches the valid string array
if (nargin == 2)
    isOK = any(strcmp(vStr,sType));
else
    isOK = true;
end

% flushes the device and closes the device
fclose(hS);