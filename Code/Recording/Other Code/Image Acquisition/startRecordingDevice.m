% --- stop the recording device/timer (based on the camera type)
function startRecordingDevice(obj)

if obj.isWebCam
    % case is a webcam object
    if ~isempty(obj.objIMAQ.hTimer) 
        if isstruct(obj.objIMAQ.hTimer)            
            % sets the running flag
            obj.objIMAQ.hTimer.Running = 'on';            
            
            % runs the trigger function
            trigFcn = obj.objIMAQ.hTimer.TriggerFcn{1};
            exObj = obj.objIMAQ.hTimer.TriggerFcn{2};
            trigFcn(exObj.hTimerExpt,[],exObj);
            
        elseif isvalid(obj.objIMAQ.hTimer)
            % case is a timer object
            start(obj.objIMAQ.hTimer)
        end
    end
else
    % case is a videoinput object
    start(obj.objIMAQ)
end
