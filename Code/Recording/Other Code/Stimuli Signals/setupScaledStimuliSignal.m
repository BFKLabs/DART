% --- calculates the scaled stimuli signals
function [xS,yS] = setupScaledStimuliSignal(hAx,sParaS,iCh,sType,useTOfs)

% global variables
global yGap

% calculates the actual stimuli signal values
yLim = get(hAx,'ylim');
[xS0,yS0] = setupStimuliSignal(sParaS,sType,1/100);
if isempty(yGap); yGap = 0; end

% determines the pixel-to-data scale factors
axPos = get(hAx,'Position');
[pX,pY] = deal(sParaS.tDur/axPos(3),diff(yLim)/axPos(4));

% calculates the time offset (if required)
if useTOfs
    tOfs = sParaS.tOfs*getTimeMultiplier(sParaS.tDurU,sParaS.tOfsU);
else
    tOfs = 0;
end

% scales the x/y coordinates to the axes/channel coordinates
dX = diff(xS0([1,end]));
xS = (roundP(tOfs,0.01)+pX) + (dX-2*pX)*(xS0-xS0(1))/dX;
yS = ((pY+yGap)+(iCh-1)) + (1-(yGap+3*pY))*yS0/100;