% --- determines if the user is using multi-fly tracking
function useChk = useDistCheck(iMov)

% default argument value
useChk0 = true;

if ~isfield(iMov,'bgP')
    % background detection parameters are not present
    useChk = useChk0;
elseif ~isfield(iMov.bgP.pTrack,'distChk')
    % distance check parameter field is missing
    useChk = useChk0;
else
    % otherwise, return the field value
    useChk = iMov.bgP.pTrack.distChk;    
end