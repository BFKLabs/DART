% --- retrieves the list of webcam frame rate numbers/strings
function [fRate,fRateS,iSel,cFPSS] = detWebcamFrameRate(objIMAQ,FPS)

% parameters
fRateMax = 10;

% retrieves the webcam frame rate properties
pInfo = objIMAQ.pInfo.FrameRate; 
fRateTmp = pInfo.ConstraintValue;    
cFPS = min(fRateMax,str2double(pInfo.DefaultValue));

% resorts the frame rate array
fRate0 = sort(cellfun(@(x)(str2double(x)),fRateTmp));
fRate = unique([arr2vec(min(fRate0,fRateMax));fRateMax]);

% sets the selection index
if nargin >= 2
    if isempty(FPS)
        iSel = find(fRate == cFPS);
    else
        iSel = find(fRate == FPS);
        if isempty(iSel)
            iSel = find(fRate == cFPS);
        end
    end
end

% sets the frame rate strings
fRateS = arrayfun(@num2str,fRate,'un',0); 
cFPSS = fRateS{iSel};