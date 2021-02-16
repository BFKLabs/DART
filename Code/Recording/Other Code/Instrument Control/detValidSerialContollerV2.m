% retrieves the controller type from the new devices
function [isOK,sType] = detValidSerialContollerV2(hS,vStr)

% opens the serial controller
try
    fopen(hS);
catch ME
    if (strcmp(ME.identifier,'MATLAB:serial:fopen:opfailed'))
        % if the device is already in use, then return an empty array
        [isOK,sType] = deal(false,'inuse');
        return
    else
        rethrow(ME);
    end
end

% initialisations
[i_retry,max_retry,cont] = deal(0,10,true);

% prints the type message to the controller
fprintf(hS,sprintf('0,000,000,000,000,000\n'),'async');

% keep running until either the controller type has been read, or until the
% maximum number of retries has been met
while cont
    % checks to see if the buffer information is available
    if (hS.BytesAvailable == 0)
        % if not, increment the retry counter
        i_retry = i_retry + 1;
        if i_retry > max_retry
            % if the max number of retries has been encountered then exit
            [sType, cont] = deal('inuse', false);    
        else
            % otherwise, pause for a little bit
            pause(0.1)
        end
    else
        % otherwise, read in the type string and sets the controller type
        % based on the information that has been set
        sType = lower(fscanf(hS,'%s'));
        
        % exits the loop
        cont = false;
    end
end

% determines if the serial controller matches the valid string array
if (nargin == 2)
    isOK = any(strcmp(cellfun(@lower,vStr,'un',0),sType));
else
    isOK = true;
end

% flushes the device and closes the device
fclose(hS);
