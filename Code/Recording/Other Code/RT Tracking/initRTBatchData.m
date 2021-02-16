% --- initialises the real-time batch processing data struct
function rtData = initRTBatchData(handles,iMov)

% disables the enable batch-processing menu item (can only be enabled when
% the user has specified an suitable executable)
setObjEnable(handles.menuEnableBP,'off')
if (isempty(iMov))
    % disables the batch-processing menu items
    setObjEnable(handles.menuBP,'off')
    set(setObjEnable(handles.textBatchProcess,'off'),'string','N/A')
    
    % returns an empty struct
    rtData = [];
else
    % enables the batch processing menu item
    setObjEnable(handles.menuBP,'on')    
    
    % allocates memory for the fields
    rtData = struct('exeFile',[],'exeDir',[],'iMov',iMov,'vPara',[],...
                    'Info',[],'Video',[]);
end

