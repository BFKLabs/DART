% --- initialises the real-time batch processing data struct
function rtData = initRTBatchData(handles,iMov)

% disables the enable batch-processing menu item (can only be enabled when
% the user has specified an suitable executable)
set(handles.menuEnableBP,'enable','off')
if (isempty(iMov))
    % disables the batch-processing menu items
    set(handles.menuBP,'enable','off')
    set(handles.textBatchProcess,'enable','off','string','N/A')
    
    % returns an empty struct
    rtData = [];
else
    % enables the batch processing menu item
    set(handles.menuBP,'enable','on')    
    
    % allocates memory for the fields
    rtData = struct('exeFile',[],'exeDir',[],'iMov',iMov,'vPara',[],...
                    'Info',[],'Video',[]);
end

