% --- determines if the 1D setup has a custom grid configuration
function isCust = detIfCustomGrid(iMov)

% determines if there is a custom grid setup
if is2DCheck(iMov) || detMltTrkStatus(iMov)
    % if using a 2D or multi-tracking setup, then flag as not custom
    isCust = false;

elseif isfield(iMov,'pInfo') && isfield(iMov.pInfo,'isFixed')
    % case is the custom grid field exists
    isCust = iMov.pInfo.isFixed;
    
else
    % case is the custom grid field does not exist
    isCust = false;
end