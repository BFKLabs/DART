% --- initialises the frame rate slider object
function initFrameRateSlider(hSlider,srcObj,fRateNum)

% parameters
pW = 0.1;
dFPS = 0.01;
fpsMax = 200;

% retrieves the
fpsFld = getCameraRatePara(srcObj);
fpsInfo = propinfo(srcObj,fpsFld);

% sets the fps limit
if iscell(fpsInfo.ConstraintValue)
    fpsLim0 = sort(cellfun(@str2double,fpsInfo.ConstraintValue));
    fpsLim = fpsLim0([1,end]);
else
    fpsLim = fpsInfo.ConstraintValue;
    fpsLim(2) = min(fpsLim(2),fpsMax);
end

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
if diff(fpsLimR) == 0
    dS = 1e-6;
    set(hSlider,'Min',fpsLimR(1),'Max',fpsLimR(1)+dS,'Value',fRateNum,...
                'SliderStep',dS*[1,1],'enable','off');       
else
    set(hSlider,'Min',fpsLimR(1),'Max',fpsLimR(2),'Value',fRateNum,...
                'SliderStep',(pW/diff(fpsLimR))*[1,1],'enable','on');    
end
