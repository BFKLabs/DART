% --- wrapper function for creating a tab group
function hTabGrp = createTabGroup()

if (isHG1)
    % case is for R2014a and earlier
    wState = warning('off','all');
    hTabGrp = uitabgroup('v0'); drawnow; pause(0.05);
    warning(wState);
else
    % case is for R2014b and later
    hTabGrp = uitabgroup(); drawnow; pause(0.05);
end