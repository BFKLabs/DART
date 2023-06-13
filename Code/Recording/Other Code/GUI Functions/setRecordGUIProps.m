% --- sets the gui properties given by the action given by typeStr
function varargout = setRecordGUIProps(handles,typeStr,varargin)

% class object retrieval
hFig = handles.output;
objDAQ = getappdata(hFig,'objDAQ');
infoObj = getappdata(hFig,'infoObj');

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
        
        % sets the menu item enabled properties
        setObjEnable(handles.menuExpt,~infoObj.isTest);
        setObjEnable(handles.menuAdaptors,~infoObj.isTest);            
        
        % --------------------------------------------------- %
        % --- REMOVE ME LATER (only for testing purposes) --- %
        % --------------------------------------------------- %                    
        
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
            dType = 0;
        else
            % determines if any of the loaded devices are opto
            dType = strcmp(objDAQ.sType,'HTControllerV1') + ...
                    2*strcmp(objDAQ.sType,'Opto');
        end
        
        % determines if there are any  
        iDev = find(dType > 0);
        if ~isempty(iDev)
            % IR string
            dType = dType(iDev);
            hDev = objDAQ.Control(iDev);            
            sStr = {sprintf('4,%f\n',100),'3,000,000,000,000,050\n'};

            % loops through each opto device turning on the IR lights
            for i = 1:length(hDev)
                % if the device is closed, then open it
                if strcmp(get(hDev{i},'Status'),'closed')
                    fopen(hDev{i});
                end
                
                % turns on the IR lights
                writeSerialString(hDev{i},sStr{dType(i)});
            end
            
            % sets the toggle IR menu check
            set(handles.menuToggleIR,'Checked','On');
            setObjVisibility(handles.menuToggleWhite,any(dType==2))
            setObjVisibility(handles.menuOpto,'on');

            % runs a test pulse (HT1 controllers only)
            isHT1 = dType == 1;            
            if any(isHT1)
                objHT1 = setupHT1TestPulse(objDAQ,iDev(isHT1));
                runOutputDevices(objHT1,1:length(objHT1));
            end

        else
            % makes the opto menu item invisible
            setObjVisibility(handles.menuOpto,'off');
        end
        
    case 'InitGUITestOnly' % case is initialising the GUI for testing
        
        % disables the adaptors menu item
        setObjEnable(handles.menuVideoProps,'off')
        setObjEnable(handles.menuTestRecord,'off')
        
end
