% --- retrieves the downsample rate
function nDS = getDownSampleRate(iMov)

% determines if the downsample rate has been set
if (isfield(iMov,'nDS'))
    % if the field is set, then return the downsample rate
    nDS = iMov.nDS;
else
    % otherwise, return a downsample rate of 1
    nDS = 1;
end