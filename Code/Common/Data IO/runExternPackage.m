% --- runs the external package initialisation function
function varargout = runExternPackage(handles,pFile,pFunc,varargin)

% if the package file doesn't exist, then exit
if ~exist(pFile,'file')
    % sets the output arguments (if required)
    if nargout == 1
        varargout{1} = [];        
    end
    
    % exits the function
    return
end

% creates/runs the packagae initialisation functions (based on type)
switch pFile
    case 'CustomSignal' 
        % case is the custom signal object
        try
            % creates the class object and updates within the GUI
            pkgObj = CustomSignalObj(handles);   
            setappdata(handles.figExptSetup,'csObj',pkgObj);
        catch
            pkgObj = [];
        end
        
    case 'RTTrack'
        % case is real-time tracking object
        try
            % creates the class object and updates within the GUI
            pkgObj = RTTrackObj(handles);
            setappdata(handles.figFlyRecord,'rtObj',pkgObj)
            
            % runs the recording GUI opening function
            pkgObj.recordGUIOpen();
            
        catch 
            pkgObj = [];
        end
        
    case 'MultiTrack'
        % case is multi-tracking
        msgbox('Finish Me!')     
        
end

% sets the output arguments
if exist('pkgObj','var') && (nargout == 1)
    varargout{1} = pkgObj;
end