% --- determines if the initial detection process is complete
function isDetected = initDetectCompleted(iMov)

% retrieves the direct-detection data struct
if isfield(iMov,'ddD')
    % if the field is set, then return the field value
    ddD = iMov.ddD;
else
    % otherwise, set an empty field
    ddD = [];
end

% returns a flag indicating if either is empty
isDetected = ~isempty(iMov.Ibg) || ~isempty(ddD);