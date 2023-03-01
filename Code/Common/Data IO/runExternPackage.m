% --- runs the external package initialisation function
function varargout = runExternPackage(pFile,varargin)

% initialisations
pkgObj = [];

% if the package file doesn't exist, then exit
if ~exist(pFile,'file')
    % sets the output arguments (if required)
    if nargout == 1
        varargout{1} = [];        
    end
    
    % exits the function
    return
end

% determines if the package is valid
if isdeployed    
    % case is running through the executable
    pkgName = getStructField(load('ExternalPackages'),'pkgName');
    if isempty(pkgName)
        isOK = false;
    else
        isOK = any(cellfun(@(x)(strContains(x,pFile)),pkgName));        
    end    
else
    % case is running through DART    
    isOK = true;
end

% creates/runs the package initialisation functions (based on type)
if isOK
    switch pFile
        case 'CustomSignal' 
            % case is the custom signal object
            try
                % creates the class object and updates within the GUI
                handles = varargin{1};
                pkgObj = feval('CustomSignalObj',handles);   
                setappdata(handles.figExptSetup,'csObj',pkgObj);
            end

        case 'RunStreamPix' 
            % case is the custom signal object
            try
                % creates the class object and updates within the GUI
                pkgObj = feval('RunStreamPix');
                if pkgObj.ok
                    handles = varargin{1};
                    setappdata(handles.figExptSetup,'spixObj',pkgObj);                
                end
            end 
            
        case 'ExtnDevices' 
            % case is the custom signal object
            try
                % creates the class object and updates within the GUI
                pkgObj = feval('ExtnDevices');
                if ~pkgObj.ok
                    pkgObj = [];              
                end
            end                

        case 'RTTrack'
            % case is real-time tracking object
            switch class(varargin{1})
                case 'struct'
                    % sets the handle field
                    handles = varargin{1};            
                    switch varargin{2}
                        case 'Init'
                            % case is initialising the class object

                            % creates the class object and updates the GUI
                            pkgObj = feval('RTTrackObj',handles);                
                            setappdata(handles.figFlyRecord,'rtObj',pkgObj)

                            % runs the recording GUI opening function
                            pkgObj.recordGUIOpen();
                            
                        case 'InitAnalysis'
                            % case is initialising the analysis
                            pkgObj = getProgFileName('Code',...
                                        'External Apps','RTTrack',...
                                        'Analysis Functions');
                            
                    end
            end
            
        case 'AnalysisFunc'
            % case is the other analysis functions
            switch class(varargin{1})
                case 'struct'
                    switch varargin{2}
                        case {'InitAnalysis','OpenSolnFile'}
                            % case is initialising the analysis
                            pkgBase = getProgFileName('Code',...
                                        'External Apps','AnalysisFunc'); 
                            if ~exist(pkgBase,'dir')
                                % if the folder doesn't exist then exit
                                varargout{1} = pkgObj;
                                return
                            end
                            
                            % retrieves the sub-directory names
                            dInfo = dir(pkgBase);
                            dName = field2cell(dInfo,'name');
                            
                            % determines if there are any valid directories
                            isDir = field2cell(dInfo,'isdir',1) & ...
                                ~(strcmp(dName,'.') | strcmp(dName,'..'));                            
                            if any(isDir)
                                % if so, then set the package directories
                                pkgObj = cellfun(@(x)(fullfile...
                                    (pkgBase,x)),dName(isDir),'un',0);
                                if strcmp(varargin{2},'InitAnalysis')
                                    % if initialising, then exit
                                    varargout{1} = pkgObj;
                                    return
                                end
                                
                                % for each package, determine if there is a
                                % menu initialisation function (run if so)
                                for i = 1:length(pkgObj)
                                    % sets the initialisation function
                                    fPkg = getFileName(pkgObj{i});
                                    fInit = sprintf('init%s',fPkg);
                                    fPkgM = fullfile(pkgObj{i},'matlab');
                                    
                                    % if the file exists, then add it
                                    fFile = fullfile(fPkgM,[fInit,'.m']);
                                    if exist(fFile,'file')
                                        addpath(fPkgM)
                                        pkgObj = feval(fInit,varargin{3}); 
                                    end
                                end
                            end                            
                    end
            end
            
        case 'VideoCalibObj'
            % case is video calibration
            
            % creates the class object and updates within the GUI
            handles = varargin{1};
            pkgObj = feval('VideoCalibObj',handles.figFlyRecord);                
            setappdata(handles.figFlyRecord,'vcObj',pkgObj)

        case 'MultiTrack'
            % case is initialising the multi-tracking object
            switch class(varargin{1})
                case 'struct'
                    % case is initialising the tracking objects
                    switch varargin{2}
                        case 'Full'
                            % case is running the full multi-tracking
                            pkgObj = MultiTrackFull(varargin{1}); 
                            
                        case 'Init'
                            % case is initialising the multi-tracking
                            pkgObj = MultiTrackInit(varargin{1});
                        
                        case 'InitAnalysis'
                            % case is initialising the analysis
                            pkgObj = getProgFileName('Code',...
                                        'External Apps','MultiTrack',...
                                        'Analysis Functions');
                    end
                    
                case 'AnalysisOpt'
                    % case is initialising multi-tracking options
                    pkgObj = InitMultiTrackOptions(varargin{1});                    
                    
            end 
    end
end

% sets the output arguments
if exist('pkgObj','var') && (nargout == 1)
    varargout{1} = pkgObj;
end
