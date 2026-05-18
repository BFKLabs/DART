% --- stop the recording device/timer (based on the camera type)
function startRecordingDevice(obj)

if obj.isWebCam || obj.isMemLog
    % case is a webcam object
    if ~isempty(obj.hTimer) 
        if isstruct(obj.hTimer)            
            % sets the running flag
            obj.hTimer.Running = 'on';            
            
            % runs the trigger function
            trigFcn = obj.hTimer.TriggerFcn{1};
            exObj = obj.hTimer.TriggerFcn{2};
            trigFcn(exObj.hTimerExpt,[],exObj);
            
        elseif isvalid(obj.hTimer)
            % case is a timer object
            start(obj.hTimer)
        end
    end
else
    % case is a videoinput object
    start(obj.objIMAQ)
end
