% --- calculates the fontsize ratio (takes into account original and new
%     dimensions for a given axes)
function fR = getFontSizeRatio()

% global variables
global regSz newSz

if isempty(newSz) || isempty(regSz)
    fR = 1;
else
    fR = min(newSz(3:4)./regSz(3:4))*get(0,'ScreenPixelsPerInch')/72;
end