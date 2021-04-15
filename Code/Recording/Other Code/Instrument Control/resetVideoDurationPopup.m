% --- resets the video duration popup menu properties
function iExpt = resetVideoDurationPopup(handles,iExpt,isVerbose,Dmax)

 % if so, then output a message to screen
if isVerbose
    mStr = {'Maximum video duration exceeds experiment duration.';...
            'Resetting video duration equal to the experiment duration.'};
    waitfor(msgbox(mStr,'Video Duration Reset','modal'));
end

% resets the video duration to the experiment duration
if nargin < 4
    iExpt.Video.Dmax = iExpt.Timing.Texp(2:end);   
else
    iExpt.Video.Dmax = Dmax;
end

% resets the video duration popup menu
set(handles.popupVidHour,'value',iExpt.Video.Dmax(1)+1)
set(handles.popupVidMin,'value',iExpt.Video.Dmax(2)+1)
set(handles.popupVidSec,'value',iExpt.Video.Dmax(3)+1)