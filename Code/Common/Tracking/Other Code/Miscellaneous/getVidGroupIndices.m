% --- retrieves the video group indices (if they exist)
function vGrp = getVidGroupIndices(iMov)

% check to see if the video group field exists within the data struct
if isfield(iMov,'vGrp')
    % if so, return the array
    vGrp = iMov.vGrp;
else
    % otherwise, returh an empty array
    vGrp = [];
end