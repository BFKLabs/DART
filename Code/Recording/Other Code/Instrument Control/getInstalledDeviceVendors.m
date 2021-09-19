% --- retrieves the installed device vendors
function [dStr,varargout] = getInstalledDeviceVendors(varargin)

try
    % determines the currently detected vendors
    dVendor = daqvendorlist;    
catch
    % clears the screen of the error message
    pause(0.05); 
    clc
    
    % if there is an error, then exit
    [dStr,varargout{1}] = deal([],[]);
    return    
end    

% retrieves the ID strings of the operational vendors
isOper = true(length(dVendor),1);
[dStr,fStr] = deal(cell(length(dVendor),1));
for i = 1:length(dStr)
    if (get(dVendor(i),'IsOperational'))
        dStr{i} = get(dVendor(i),'ID');
        fStr{i} = get(dVendor(i),'FullName');
    else
        isOper(i) = false;
    end
end

% removes any non-operational devices
if (nargin == 1)
    % removes the non-operational devices
    [dStr,fStr,dInfo] = deal(dStr(isOper),fStr(isOper),daqlist);        
    if (isempty(dInfo))
        % sets the final function outputs 
        [dStr,varargout{1}] = deal([],[]);        
    else
        % matches the device information with the vendor strings
        isOK = false(length(dStr),1);
        for i = 1:length(dInfo)
            vTemp = get(dInfo(i),'Vendor');
            isOK(strcmp(fStr,get(vTemp,'FullName'))) = true;
        end

        % sets the final function outputs 
        [dStr,varargout{1}] = deal(dStr(isOK),dInfo);
    end
else
    varargout{1} = isOper;
end