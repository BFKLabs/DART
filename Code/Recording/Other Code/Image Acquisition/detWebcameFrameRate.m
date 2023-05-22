% --- retrieves the list of webcam frame rate numbers/strings
function [fRate,fRateS,iSel,cFPSS] = detWebcameFrameRate(objIMAQ,FPS)

% retrieves the webcam frame rate properties
pInfo = objIMAQ.pInfo.FrameRate; 
fRateTmp = pInfo.ConstraintValue;    
cFPS = pInfo.DefaultValue;

% resorts the frame rate array
[fRate,ii] = sort(cellfun(@(x)(str2double(x)),fRateTmp));
fRateTmp = fRateTmp(ii);

% sets the selection index
if nargin >= 2
    if isempty(FPS)
        iSel = find(fRate == str2double(cFPS));
    else
        iSel = find(fRate == FPS);
        if isempty(iSel)
            iSel = find(fRate == str2double(cFPS));
        end
    end
end

% sets the frame rate string
cFPSS = fRateTmp{iSel};

% sets the frame rate strings
fRateS = arrayfun(@num2str,fRate,'un',0); 