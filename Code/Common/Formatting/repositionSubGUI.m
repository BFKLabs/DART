% --- respositions the sub-gui so that it is "reasonably" place with
%     respect to the main gui, hFig
function repositionSubGUI(hFigMain,hFigSub)

% parameters
dX = 10;

% initialisations
scrSz = get(0,'ScreenSize');
fPosM = get(hFigMain,'Position');
fPosS = get(hFigSub,'Position');

% calculates the left/top position of the sub-gui
[fRight,fTop] = deal(sum(fPosM([1,3])),sum(fPosM([2,4])));

% determines which side of the gui has more space
if fPosM(1) >= (scrSz(3) - fRight)
    % case is the left side has more space
    Lnw = max(0,fPosM(1)-(fPosM(3)+2*dX));
else
    % case is right of the gui has more space
    Lnw = min(scrSz(3)-fPosS(3),fRight+2*dX);
end

% repositions the sub-gui
resetObjPos(hFigSub,'Left',Lnw)
resetObjPos(hFigSub,'Bottom',fTop-(fPosS(4)+2*dX));