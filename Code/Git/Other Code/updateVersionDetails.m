% --- updates the version details
function updateVersionDetails(handles,gHist,iCurr)    

% retrieves the reset branch object handles
hMenuR = findall(handles.menuBranch,'tag','Reset');

% retrieves the status string/colour
if iCurr == 1
    sStr = 'Currently Up To Date';
    sCol = 'k';   
    set(hMenuR,'enable','off')
else
    eStr = {char(32),'s '};
    sStr = sprintf('%i Version%sBehind Latest',iCurr-1,eStr{1+(iCurr>2)});
    sCol = 'r';
    set(hMenuR,'enable','on')
end       

% updates the label strings
set(handles.textVerStatus,'string',sStr,'foregroundcolor',sCol)
set(handles.textVerDate,'string',datestr(gHist.DateNum,1))
set(handles.textVerComment,'string',gHist.Comment)