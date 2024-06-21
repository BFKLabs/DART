function isHT1 = isHT1Controller(iData)

% field retrieval
if ~isfield(iData,'iExpt')
    isHT1 = false;
elseif isfield(iData.iExpt,'Device')
    Device = iData.iExpt.Device;
    isHT1 = any(strContains(Device.DAQ,'HTControllerV1')) || ...
            any(strContains(Device.DAQ,'HTControllerV2'));
else
    isHT1 = false;
end