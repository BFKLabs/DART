% --- retrieves the solution viewing GUI font sizes   
function [axSz,lblSz,tSz] = detSolnViewFontSizes(handles)

% global variables
global regSz

% determines the font ratio
newSz = get(handles.panelImg,'position');
fR = min(newSz(3:4)./regSz(3:4))*get(0,'ScreenPixelsPerInch')/72;

% sets the axis/label font sizes
if (ismac)
    [axSz,lblSz,tSz] = deal(20*fR,26*fR,30*fR);
else
    [axSz,lblSz,tSz] = deal(14*fR,18*fR,22*fR);    
end