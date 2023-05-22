% --- retrieves the list of camera frame rate numbers/strings
function [fRate,fRateS,iSel,cFPSS] = detCameraFrameRate(srcObj,FPS)

% retrieves the video input device object
objIMAQ = get(srcObj,'parent');

% retrieves the camera object handle
if strContains(objIMAQ.Name,'UV155xLE-C')
    % temporary fix for webcam (offset rate by 5/6)
%     W = (5/6);
    W = 1;
    [fRate,iSel] = deal(str2double(srcObj.FrameRate)*W,1);
    cFPSS = num2str(roundP(fRate,0.001));
    
elseif isprop(srcObj,'AcquisitionFrameRate')
    % case is the Allied Vision Camera
    [fRate,iSel] = deal(srcObj.AcquisitionFrameRate,1);
%     fRateM = mod(fRate,1);
%     if min(fRateM,1-fRateM) < 0.01
%         fRate = roundP(fRate);
%     else
%         fRate = floor(fRate);
%     end
    
    % sets the string version of the frame rate
    cFPSS = num2str(roundP(fRate,0.001));
    
else
    % sets the frame rate depending on the camera type
    try
        % retrieves the camera frame rate strings
        cFPS = get(srcObj,'FrameRate');
        pInfo = propinfo(srcObj,'FrameRate'); 
        fRateTmp = pInfo.ConstraintValue;    

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
    catch
        % set the image acquisition device properties based on camera type    
        switch get(objIMAQ,'Name')
            case ('USB 2861 Device') % TECHview camera
                % retrieves the current camera resolution
                vRes = getVideoResolution(objIMAQ);           
                switch vRes(1)
                    case (176)
                        fRate = 29;
                    case (352)
                        fRate = 25 + 4*(vRes(2) == 480);
                    case (480)
                        fRate = 25 + 4*(vRes(2) == 480);
                    case (640)
                        fRate = 29;
                    case (720)
                        fRate = 25;
                end
            otherwise
                % keep prompting for frame rate until an integer is entered
                while (1)
                    fRate = str2double(inputdlg(...
                                'Enter the camera frame rate (frames/sec)',...
                                'Frame Rate',1,{'10'}));
                    eStr = [];
                    if (isempty(fRate))
                        % entered value is not valid
                        eStr = 'Error! Frame rate must input a positive integer.';                    
                    elseif (isnan(fRate))
                        % entered value is not a number
                        eStr = 'Error! Frame rate must be a numerical value.';
                    elseif (mod(fRate,1) ~= 0)
                        % entered value is not an integer
                        eStr = 'Error! Frame rate must be an integer value.';
                    elseif (fRate < 1)
                        % entered value is not valid
                        eStr = 'Error! Frame rate must input a positive integer.';
                    end

                    % if there was an error then output it to screen
                    if (~isempty(eStr))
                        waitfor(errordlg(eStr,'Invalid Frame Rate','modal'))                    
                    else
                        % value is valid, so exit the loop
                        break
                    end
                end
        end

        % sets the selection index to a value of 1
        if (nargin == 2)
            iSel = 1;
        end    

        % sets the frame rate string
        cFPSS = num2str(fRate);
    end
end
    
% sets the frame rate strings
fRateS = arrayfun(@num2str,fRate,'un',0); 
