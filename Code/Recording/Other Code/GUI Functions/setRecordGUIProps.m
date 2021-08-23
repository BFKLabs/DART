% --- sets the gui properties given by the action given by typeStr
function varargout = setRecordGUIProps(handles,typeStr,varargin)

% class object retrieval
hFig = handles.output;
objDAQ = getappdata(hFig,'objDAQ');

% sets the object properties based on the type string
switch (typeStr)
    % ------------------------------ %    
    % --- OBJECT INITIALISATIONS --- %
    % ------------------------------ %
    
    case ('InitGUI') % case is initialising the GUI (common to full & test)        
        % clears the preview axes
        cla(handles.axesPreview); 
        axis(handles.axesPreview,'off')
                
        % centres the figure
        centreFigPosition(hFig);        
        
        % --------------------------------------------------- %
        % --- REMOVE ME LATER (only for testing purposes) --- %
        % --------------------------------------------------- %
        
        % determines if stimuli devices are set
        exptType = varargin{1};
        hasStim = strcmp(exptType,'RecordStim');
        
%         % sets the valid hostname strings
%         if isfield(handles,'menuRTTrack')
% %             if (isRecStim)
%                 % determines if a valid computer is being run
%                 okStr = {'PC09412','PC09452','LankyG-PC'};
%                 [~,hostStr] = system('hostname');
%                 isRT = any(cellfun(@(x)(strContains(hostStr,x)),okStr));
%                     
% %             else
% %                 % if recording only, then no real-time tracking
% %                 isRT = false;
% %             end
% 
%             % determines if the computer is valid for running RT-Tracking            
%             if isRT
%                 % otherwise disable the realtime tracking menu item
%                 set(setObjEnable(handles.menuRTTrack,'off'),'visible','on')
%             else
%                 % deletes the items
%                 setObjVisibility(handles.menuRTTrack,'off');             
%             end
%             
%             % disables the real-time tracking parameter menu item
%             setObjEnable(handles.menuRTPara,'off')
%         end               
        
        % outputs the handles struct
        varargout{1} = handles;                           
            
    case 'InitOptoMenuItems' % case is initialiseing the GUI for full case
        
        if isempty(objDAQ)
            % no devices are loaded
            isOpto = false;
        else
            % determines if any of the loaded devices are opto
            isOpto = strcmp(objDAQ.sType,'Opto');
        end
        
        % determines if there are any        
        if any(isOpto)
            % IR string
            sStr = '3,000,000,000,000,050\n';

            % loops through each opto device turning on the IR lights
            hOpto = objDAQ.Control(isOpto);
            for i = 1:length(hOpto)
                % if the device is closed, then open it
                if strcmp(get(hOpto{i},'Status'),'closed')
                    fopen(hOpto{i});
                end
                
                % turns on the IR lights
                writeSerialString(hOpto{i},sStr);
            end
            
            % sets the toggle IR menu check
            set(handles.menuToggleIR,'Checked','On');
            setObjVisibility(handles.menuOpto,'on');
        else
            % makes the opto menu item invisible
            setObjVisibility(handles.menuOpto,'off');
        end
        
    case 'InitGUITestOnly' % case is initialising the GUI for testing
        
        % disables the adaptors menu item
        setObjEnable(handles.menuVideoProps,'off')
        setObjEnable(handles.menuTestRecord,'off')
        
end
