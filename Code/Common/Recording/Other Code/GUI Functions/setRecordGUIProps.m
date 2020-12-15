% --- sets the gui properties given by the action given by typeStr
function varargout = setRecordGUIProps(handles,typeStr,varargin)

% class object retrieval
hFig = handles.figFlyRecord;
objDACInfo = getappdata(hFig,'objDACInfo');

% retrieves the computer host name
[~,hostname]= system('hostname');
isHome = strfind(hostname,'LankyG-PC');

% sets the object properties based on the type string
switch (typeStr)
    % --- OBJECT INITIALISATIONS --- %
    % ------------------------------ %
    
    case ('InitGUI') % case is initialising the GUI (common to full & test)        
        % clears the axes
        cla(handles.axesPreview); axis(handles.axesPreview,'off')
                
        % centres the figure
        centreFigPosition(handles.figFlyRecord);        
        
        % --------------------------------------------------- %
        % --- REMOVE ME LATER (only for testing purposes) --- %
        % --------------------------------------------------- %
        
        % determines if stimuli devices are set
        exptType = varargin{1};
        hasStim = strcmp(exptType,'RecordStim');
        
        % sets the valid hostname strings
        if (isfield(handles,'menuRTTrack'))
%             if (isRecStim)
                % determines if a valid computer is being run
                okStr = {'PC09412','PC09452','LankyG-PC','KCLC1NRYJ2'};
                [~,hostStr] = system('hostname');
                isRT = any(cellfun(@(x)(strContains(hostStr,x)),okStr));
                    
%             else
%                 % if recording only, then no real-time tracking
%                 isRT = false;
%             end

            % determines if the computer is valid for running RT-Tracking            
            if (isRT)
                % otherwise disable the realtime tracking menu item
                set(handles.menuRTTrack,'visible','on','enable','off')
                setObjVisibility(handles.panelRTTrack,'on')
            else
                % deletes the items
                setObjVisibility(handles.menuRTTrack,'off'); 
                setObjVisibility(handles.panelRTTrack,'off')                
            end
            
            % disables the real-time tracking parameter menu item
            setObjEnable(handles.menuRTPara,'off')
        end               
        
        % outputs the handles struct
        varargout{1} = handles;                           
            
    case 'InitGUIFullOnly' % case is initialiseing the GUI for full case
        
        if isempty(objDACInfo)
            % no devices are loaded
            isOpto = false;
        else
            % determines if any of the loaded devices are opto
            isOpto = strcmp(objDACInfo.sType,'Opto');
        end
        
        % determines if there are any        
        if any(isOpto)
            % IR string
            sStr = '3,000,000,000,000,050\n';

            % loops through each opto device turning on the IR lights
            hOpto = objDACInfo.Control(isOpto);
            for i = 1:length(hOpto)
                writeSerialString(hOpto{i},sStr);
            end
            
            % sets the toggle IR menu check
            set(handles.menuToggleIR,'Checked','On');
        else
            % makes the opto menu item invisible
            setObjVisibility(handles.menuOpto,'off');
        end
        
    case 'InitGUITestOnly' % case is initialising the GUI for testing
        
        % disables the adaptors menu item
        setObjEnable(handles.menuVideoProps,'off')
        setObjEnable(handles.menuTestRecord,'off')
        set(handles.toggleStartTracking,'visible','on','enable','off')
        
end