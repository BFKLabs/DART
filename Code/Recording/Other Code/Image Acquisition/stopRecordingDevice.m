% --- stop the recording device/timer (based on the camera type)
function stopRecordingDevice(obj,saveStopFcn,relVidDev)

% sets the default input argument
isVidDev = isa(obj.objIMAQ,'imaq.VideoDevice');
if ~exist('rmvCB','var'); saveStopFcn = false; end
if ~exist('relVidDev','var'); relVidDev = true; end

%
if obj.isTest
    % case is running a test
    return
    
elseif obj.isWebCam || isVidDev
    % determines if the object is value
    if isempty(obj.hTimer)
        isV = false;
    elseif isstruct(obj.hTimer)
        isV = true;
    else
        isV = isvalid(obj.hTimer);
    end
    
    % releases the video device
    if isVidDev && relVidDev
        release(obj.objIMAQ)
    end    
    
    % case is a webcam object
    if ~isempty(obj.hTimer) && isV         
        % stops the device
        if isstruct(obj.hTimer)
            % turns off the running object
            obj.hTimer.Running = 'off';

            % resets the camera stop function
            if ~saveStopFcn
                stopFcn = obj.hTimer.StopFcn{1};
                exObj = obj.hTimer.StopFcn{2};
                stopFcn(exObj.hTimerExpt,[],exObj);
            end
            
        else
            % stores the camera stop function (if required)
            if saveStopFcn
                sFunc = obj.hTimer.stopFcn;
                obj.hTimer.stopFcn = [];
            end
            
            % stops the timer object
            stop(obj.hTimer)
            
            % resets the camera stop function
            if saveStopFcn
                obj.hTimer.StopFcn = sFunc;
            end
        end        
    end
else
    % stores the camera stop function (if required)
    if saveStopFcn
        sFunc = obj.objIMAQ.stopFcn; 
        obj.objIMAQ.stopFcn = [];
    end
    
    % stops the device
    stop(obj.objIMAQ)
    pause(0.05);
    
    % resets the camera stop function
    if saveStopFcn
        obj.objIMAQ.StopFcn = sFunc;
    end
end
