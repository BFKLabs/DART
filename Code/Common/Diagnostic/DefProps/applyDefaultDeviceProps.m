% --- applies the default device properties (if any)
function applyDefaultDeviceProps(infoObj,devName,useOrig)

% sets the default inputs
if ~exist('useOrig','var'); useOrig = false; end

% loads any default device property preset data (if any exists)
if useOrig
    % case is using the original device properties
    psData = infoObj.pInfo0;
    
else
    % case is using the default preset file
    [~,psData] = loadDefaultPresetData(devName);
    if isempty(psData)
        return
    end
end

if infoObj.isWebCam
    % case is using a webcam
    sObj = infoObj.objIMAQ;
    
else
    % case is using a different image acquisition device
    sObj = getselectedsource(infoObj.objIMAQ);        
end

% attempts to set the parameter value (ignore any errors)
for i = 1:length(psData.fldNames)
    try
        % only update the field if they are not equal
        pVal0 = get(sObj,psData.fldNames{i});
        if ~isequal(pVal0,psData.pVal{i})
            set(sObj,psData.fldNames{i},psData.pVal{i})
        end
    catch
    end
end