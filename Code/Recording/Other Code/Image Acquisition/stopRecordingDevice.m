% --- stop the recording device/timer (based on the camera type)
function stopRecordingDevice(obj,saveStopFcn)

% sets the default input argument
if ~exist('rmvCB','var'); saveStopFcn = false; end

%
if obj.isWebCam
    % determines if the object is value
    if isstruct(obj.objIMAQ.hTimer)
        isV = true;
    else
        isV = isvalid(obj.objIMAQ.hTimer);
    end
    
    % case is a webcam object
    if ~isempty(obj.objIMAQ.hTimer) && isV         
        % stops the device
        if isstruct(obj.objIMAQ.hTimer)
            % turns off the running object
            obj.objIMAQ.hTimer.Running = 'off';

            % resets the camera stop function
            if ~saveStopFcn
                stopFcn = obj.objIMAQ.hTimer.StopFcn{1};
                exObj = obj.objIMAQ.hTimer.StopFcn{2};
                stopFcn(exObj.hTimerExpt,[],exObj);
            end
            
        else
            % stores the camera stop function (if required)
            if saveStopFcn
                sFunc = obj.objIMAQ.hTimer.stopFcn;
                obj.objIMAQ.hTimer.stopFcn = [];
            end
            
            % stops the timer object
            stop(obj.objIMAQ.hTimer)
            
            % resets the camera stop function
            if saveStopFcn
                obj.objIMAQ.hTimer.StopFcn = sFunc;
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
    
    % resets the camera stop function
    if saveStopFcn
        obj.objIMAQ.StopFcn = sFunc;
    end
end
