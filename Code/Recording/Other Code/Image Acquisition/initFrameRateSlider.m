% --- initialises the frame rate slider object
function initFrameRateSlider(hSlider,srcObj,fRateNum)

% parameters
pW = 0.1;
dFPS = 0.01;

% retrieves the
fpsFld = getCameraRatePara(srcObj);
fpsInfo = propinfo(srcObj,fpsFld);
fpsLim = fpsInfo.ConstraintValue;

% determines the rounded frame rate limits
fpsLimR = round(fpsLim,1);
ii = abs(fpsLim - fpsLimR) > dFPS;
for i = find(ii(:)')
    if i == 1
        % case is the lower limit
        fpsLimR(i) = ceil(fpsLim(i)/pW)*pW;
    else
        % case is the upper limit
        fpsLimR(i) = floor(fpsLim(i)/pW)*pW;
    end
end

% sets the slider properties
fRateNum = max(min(fRateNum,fpsLimR(2)),fpsLimR(1));
set(hSlider,'Min',fpsLimR(1),'Max',fpsLimR(2),'Value',fRateNum,...
            'SliderStep',(pW/diff(fpsLimR))*[1,1]);    
