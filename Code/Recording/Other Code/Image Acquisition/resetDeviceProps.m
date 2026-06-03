% --- resets the device properties for the source object
function resetDeviceProps(obj,pValNw)

% initialisations
sStr = {'auto'};
isVD = isVidDev(obj.sObj);
isF = false(size(pValNw,1),1);

% device property value retrieval
if isVD
    % case is an imaq.VideoDevice object
    
    % retrieves the original parameter values
    dProps = obj.sObj.DeviceProperties;
    pVal0 = cellfun(@(x)(dProps.(x)),pValNw(:,1),'un',0);
    
    % pauses the preview timer (if running
    if obj.prObj.isOn
        obj.prObj.isPauseTimer = true;
        release(obj.sObj);        
    end
else
    % case is another recording device
    pVal0 = cellfun(@(x)(get(obj.sObj,x)),pValNw(:,1),'un',0);
end

% ---------------------------------------- %
% --- ENUMERATION PARAMETER PROPERTIES --- %
% ---------------------------------------- %

% memory allocaion
isE = cellfun(@ischar,pValNw(:,2));
for i = find(isE(:)')
    % flags the device has been updated
    isF(i) = true;    
    
    % updates the device property (if different from current)
    if ~isequal(pValNw{i,2},pVal0{i})
        updateDeviceProps(obj,pValNw{i,1},pValNw{i,2},isVD);
    end
        
    % determines if there are any associated parameters
    isM = cellfun(@(x)(startsWith(pValNw{i,1},x)),pValNw(:,1)) & ~isE;
    if any(isM)
        % if so, determines if the enumertion parameter is auto
        isAuto = any(startsWith(sStr,pValNw{i,2}));
        if ~isAuto && ~isequal(pValNw{isM,2},pVal0{isM})
            updateDeviceProps(obj,pValNw{isM,1},pValNw{isM,2},isVD);
        end
        
        % resets the update flag
        isF(isM) = true;
    end
end

% -------------------------------------- %
% --- NUMERICAL PARAMETER PROPERTIES --- %
% -------------------------------------- %

% updates the numerical parameters (if any)
for i = find(~isM(:)')
    % updates the device property (if different from current)
    if ~isequal(pValNw{i,2},pVal0{i})
        updateDeviceProps(obj,pValNw{i,1},pValNw{i,2},isVD);
    end
end

% ------------------------------- %
% --- HOUSE-KEEPING EXERCISES --- %
% ------------------------------- %

% restarts the preview timer (if running)
if obj.prObj.isOn
    step(obj.sObj);
    obj.prObj.isPauseTimer = false;
end

% --- updates the device properties
function updateDeviceProps(obj,fName,pVal,isVD)

% field retrieval
if isnumeric(pVal)    
    try
        % resets the camera properties value
        if isVD
            obj.sObj.DeviceProperties.(fName) = pVal;
        else
            set(obj.sObj,fName,pVal);
        end
           
        % resets the editbox value
        updateObjectProps(obj.hObj,fName,num2str(pVal),0);
        
    catch        
        try
            % if there was an error, then revert back to the previous value
            if isVD
                pValPr = obj.sObj.DeviceProperties.(fName);
            else
                pValPr = get(obj.sObj,fName);
            end
                
            updateObjectProps(obj.hObj,fName,num2str(pValPr),0);
        catch
            % if there was an error, then ignore...
        end
    end
    
else
    try
        % resets the camera properties value
        if isVD
            obj.sObj.DeviceProperties.(fName) = pVal;
        else
            set(obj.sObj,fName,pVal);            
        end
        
        % resets the object value        
        updateObjectProps(obj.hObj,fName,pVal,1);
        
    catch
        try
            % if there was an error, then revert back to the previous value
            if isVD
                pValPr = obj.sObj.DeviceProperties.(fName);
            else
                pValPr = get(obj.sObj,fName);
            end
            
            % resets the object value            
            updateObjectProps(obj.hObj,fName,pValPr,1);
        catch
            % if there was an error, then ignore...            
        end
    end
end

% --- updates any associated object properties
function updateObjectProps(hObj,fName,pVal,isENum)

% if there are no valid objects, then exit
if isempty(hObj); return; end

% determines the parameter object index
iType = 1 + double(isENum);
fStrP = cellfun(@(x)(x.UserData.Name),hObj{iType},'un',0);
iSelP = strcmp(fStrP,fName);

% resets the object parameter value
hObjP = hObj{iType}{iSelP};
if isENum
    % case is an enumeration parameter
    iSelPP = strcmp(hObjP.String,pVal);
    if any(iSelPP)
        hObjP.Value = find(iSelPP);
    end
    
else
    % case is a numercal parameter
    hObjP.String = pVal;
end
