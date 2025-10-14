function isHT = isHTController(iData)

% field retrieval
if ~isfield(iData,'iExpt')
    % case is there is no experimental information
    isHT = false;
    
elseif isfield(iData.iExpt,'Device')
    % case is there is device experimental information
    Device = iData.iExpt.Device;
    isHT = any(strContains(Device.DAQ,'HTControllerV1')) || ...
           any(strContains(Device.DAQ,'HTControllerV2')) || ...
           any(strContains(Device.IMAQ,'daA3840-45um')) || ...
           any(strContains(Device.IMAQ,'UV155xLE-C'));
       
else
    % otherwise, recording device is not HT
    isHT = false;
end