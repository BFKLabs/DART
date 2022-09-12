% --- determines if the user is using multi-fly tracking
function useChk = useDistCheck(iMov)

% default argument value
useChk0 = 1;

if ~isfield(iMov,'bgP')
    % background detection parameters are not present
    useChk = useChk0;
elseif ~isfield(iMov.bgP.pTrack,'distChk')
    % distance check parameter field is missing
    useChk = useChk0;
else
    % otherwise, return the field value
    useChk = double(iMov.bgP.pTrack.distChk);
    if is2DCheck(iMov)
        % distance check is not uni-directional for 2D
        useChk = min(1,useChk);    
    end
end
