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

if isVidDev(infoObj.objIMAQ)
    % case is a video device object
    applyVideoDeviceProps(infoObj.objIMAQ,psData);
    return

elseif infoObj.isWebCam
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

% --- applies the video device properties
function applyVideoDeviceProps(objIMAQ,psData)

% field retrieval
devProps = objIMAQ.DeviceProperties;

% attempts to set the parameter value (ignore any errors)
for i = 1:length(psData.fldNames)
    try        
        % only update the field if they are not equal
        pVal0 = devProps.(psData.fldNames{i});
        pValS = convertParaValue(psData.pVal{i},psData.fldNames{i});
        if ~isequal(pVal0,pValS)
            objIMAQ.DeviceProperties.(psData.fldNames{i}) = pValS;
        end        
    catch
    end
end

% --- parameter conversion function
function pVal = convertParaValue(pVal,pStr)

% initialisations
eStr = {'off','on'};

% converts the parameter based on type
switch pStr
    case 'BacklightCompensation'
        % case is backlight compensation
        if isnumeric(pVal)
            pVal = eStr{1+pVal};
        end
        
end