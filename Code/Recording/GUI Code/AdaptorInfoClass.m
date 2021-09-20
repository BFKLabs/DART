classdef AdaptorInfoClass < handle
    
    % propertes
    properties
        % main class objects
        hFig
        hFigM
        hGUI
        iType
        reqdConfig           
        
        % external device objects
        extnObj
        
        % device class objects
        iStim
        objDAQ
        objIMAQ
        objIMAQDev        
        exType
        
        % other data storage arrays
        vSelIMAQ
        vStrIMAQ
        vIndIMAQ
        vSelDAQ
        vStrDAQ
        sFormat
        sInd
        nCh
        
        % other class objects
        hLoad
        pFile        
                
        % object dimensions
        dY = 5;
        Htext = 18;
        Hmax
        Wmax        
        
        % other scalar/boolean fields
        ok = true;
        nDAQMin
        nDAQMax = 7;
        nChMin
        nChMax = 2;        
        isInit
        isSet = false;
        hasDAQ
        hasIMAQ = true; 
        onlyDAQ        
        vStr = {'Motor','Opto'};
        
    end

    % class methods
    methods
        % class constructor
        function obj = AdaptorInfoClass(hFig,iType,reqdConfig)
            
            % sets the main object fields
            obj.hFig = hFig;
            obj.hGUI = guidata(hFig);
            obj.hFigM = getappdata(hFig,'hFigM');
            obj.iType = iType;            
            obj.reqdConfig = reqdConfig;            
            
            % creates the loadbar figure
            obj.hLoad = ProgressLoadbar('Initialising GUI Objects...');
            
            % initialises the class/gui object properties
            obj.initClassFields();
            obj.initObjCallbacks();
            obj.initObjProps();
            
            % initialises the imaq device information
            obj.initIMAQInfo();
            if ~obj.ok; return; end
            
            % initialises the daq device information
            obj.initDAQInfo();    
            if ~obj.ok; return; end
            
            % performs the final initialisation checks
            obj.finalInitCheck()
    
        end
        
        % --- initialises the class object fields
        function initClassFields(obj)
            
            % global variables
            global mainProgDir     
            
            % initialises the parameter file path
            obj.pFile = fullfile(mainProgDir,'Para Files','ProgPara.mat');
           
            % iType convention
            %  =1 - running directly from DART
            %  =2 - running from FlyRecord or ExptSetup (devices loaded)
            %  =3 - running from ExptSetup/checkLoadedDeviceProps.m            
            obj.onlyDAQ = obj.iType == 3;
            obj.isInit = obj.iType == 1;
            
            % retrieves the maximum screen dimensions
            scrSz = get(0,'Screensize');
            [obj.Wmax,obj.Hmax] = deal(scrSz(3),scrSz(4));   
            
            % external device initialisations
            obj.extnObj = feval('runExternPackage','ExtnDevices');
            
        end
        
        % --- initialises the class object fields
        function initObjCallbacks(obj)
            
            % objects with normal callback functions
            cbObj = {'popupVidResolution','listDACObj','listIMAQObj'};
            for i = 1:length(cbObj)
                hObj = getStructField(obj.hGUI,cbObj{i});
                cbFcn = eval(sprintf('@obj.%sCB',cbObj{i}));
                set(hObj,'Callback',cbFcn)
            end            
            
            % objects with cell selection callback functions
            csObj = {'panelExptType'};
            for i = 1:length(csObj)
                hObj = getStructField(obj.hGUI,csObj{i});
                cbFcn = eval(sprintf('@obj.%sSC',csObj{i}));
                set(hObj,'SelectionChangeFcn',cbFcn)
            end                        
            
        end        
        
        % --- initialises the object properties
        function initObjProps(obj)
            
            % object handle retrieval
            handles = obj.hGUI;
            hPopupRes = handles.popupVidResolution;
            hTextRes = handles.textVidResolution;            
            hPanelOuter = handles.panelOuter;
            hPanelDAQ = handles.panelDACObj;
            hPanelIMAQ = handles.panelIMAQObj;
            hPanelExpt = handles.panelExptType;
            hPanelDAQReqd = handles.panelUSBRequire;
            hButtonC = handles.buttonConnect;            
            
            % sets the object properties
            setObjEnable(hTextRes,'off')
            set(hPopupRes,'enable','off','string',{' '},'value',1)   
            
            % if there is the 3rd flag, then readjust the GUI
            if obj.onlyDAQ                
                % sets the minimum number of USB devices/channels
                obj.nChMin = obj.reqdConfig.nCh;
                obj.nDAQMin = obj.reqdConfig.nDev;                
                obj.objDAQ = getappdata(obj.hFigM,'objDAQ');
                
                % sets the previous device selections
                if ~isempty(obj.objDAQ)
                    obj.vSelDAQ = obj.objDAQ.vSelDAQ;
                end
                
                % determines the criteria properties
                [crStr,crCol] = obj.detCriteriaProps(obj.reqdConfig,...
                                                     obj.objDAQ);                    
                
                % initialisations and setting of the input arguments
                Hpanel = obj.dY + (2+obj.nDAQMin)*obj.Htext;  
                Hpanel0 = cell2mat(retObjDimPos({hPanelDAQReqd},4));
                HpO = cell2mat(retObjDimPos({hPanelOuter},4));                              

                % sets up the min USB device channel strings
                hTextL = findobj(hPanelDAQe,'style','text');
                for k = 1:length(hTextL)
                    % retrieves the dimensions of the header text object
                    hTextC = findobj(hTextL,'UserData',k);
                    tPosC = get(hTextC,'Position');

                    % creates the text objects for each row
                    for i = 1:obj.nDAQMin
                        % inverted row index
                        j = obj.nDAQMin - (i-1); 

                        % sets the text string based on the values
                        switch k
                            case 1 % case is the channel index
                                txtStr = num2str(i);

                            case 2 % case is the device type
                                txtStr = obj.reqdConfig.dType{i};

                            case 3 % case is the min channel count
                                switch obj.reqdConfig.dType{i}
                                    case 'Opto' 
                                        % case is the opto device
                                        txtStr = 'N/A';

                                    otherwise
                                        % case is the other device types
                                        nChTxt = obj.reqdConfig.nCh(i);
                                        txtStr = num2str(nChTxt);

                                end

                            case 4 % case is the criteria met flag
                                txtStr = crStr{i};

                        end

                        % creates the min channel text string label
                        tPos = [tPosC(1),obj.dY+(j-1)*obj.Htext,tPosC(3:4)];
                        uicontrol('Parent',hPanel, 'Style', 'text',...
                                  'String',txtStr,'FontUnits','pixels',...
                                  'HorizontalAlignment','center',...
                                  'UserData',[i,k],'Position',tPos,...
                                  'FontSize',12,'FontWeight','bold',...
                                  'ForegroundColor',crCol{i},...
                                  'tag','hTextReqd');
                    end

                    % updates the position of the title header
                    tPosC(2) = obj.dY+(obj.nDAQMin*obj.Htext);
                    set(hTextC,'Position',tPosC);
                end

                % deletes the IMAQ object
                delete(hPanelIMAQ)
                delete(hPanelExpt)                

                % readjusts the location of the figure/GUI panels
                dH = Hpanel - Hpanel0;
                resetObjPos(hPanelDAQ,'bottom',dH,1)
                resetObjPos(hPanelDAQReqd,'height',dH,1)      

                % resets the outer/figure heights
                pPos = get(hPanelDAQ,'position');
                dHO = HpO - (sum(pPos([2 4])) + obj.dY);
                resetObjPos(hPanelOuter,'height',-dHO,1)                
                resetObjPos(hObject,'height',-dHO,1)  
                
                % readjusts the control button locations and properties 
                setObjEnable(hButtonC,all(strcmp(crStr,'All')))
                set(handles.buttonExit,'String','Cancel')
                
            else
                % if not DAQ only, then delete the USB requirements panel 
                % and readjusts the GUI
                Hpanel0 = cell2mat(retObjDimPos({hPanelDAQReqd},4));
                delete(hPanelDAQReqd)

                % readjusts the location of the figure/GUI panels
                dYnw = Hpanel0 + 10;
                resetObjPos(obj.hFig,'height',-dYnw,1)
                resetObjPos(hPanelOuter,'height',-dYnw,1)
                resetObjPos(hPanelExpt,'bottom',-dYnw,1)
                resetObjPos(hPanelIMAQ,'bottom',-dYnw,1)
                resetObjPos(hPanelDAQ,'bottom',-dYnw,1)    
            end

            % sets up the channel count array/button properties
            obj.nCh = zeros(obj.nDAQMax,1);
            if obj.isSet
                if ~isempty(obj.objDAQ)
                    obj.nCh(obj.objDAQ.vSelDAQ) = ...
                            obj.objDAQ.nChannel(obj.objDAQ.vSelDAQ);
                end
            else
                % sets the stimulus struct
                if obj.isInit
                    % resets all the image/data acquisition objects
                    try
                        daqreset; 
                        pause(0.1); 
                    end

                    % sets the exit button string
                    set(handles.buttonExit,'String','Exit Program')
                else
                    % case is the gui is not being initialised
                    set(handles.buttonExit,'string','Cancel');        
                end
            end            
            
        end
        
        % --- initialises the devce information
        function initIMAQInfo(obj)
            
            % if only checking devices, then exit
            if obj.onlyDAQ; return; end
            
            % updates the loadbar string
            loadStr = 'Initialising Image Acquisition Devices...';
            obj.hLoad.StatusMessage = loadStr;                        

            try
                % retrieves the image aquisition hardware information
                imaqInfo = imaqhwinfo;
            catch
                % if there was an error then output a message to screen
                
                
                % exit flagging an error
                obj.ok = false;
                return
            end
            
            % of there are no recording devices then exit
            if isempty(imaqInfo.InstalledAdaptors)                
                obj.hasIMAQ = false;
                return
            end
            
            % object retrieval
            handles = obj.hGUI;            
            
            % determines the adaptor string names
            adaptStr = imaqInfo.InstalledAdaptors;
            nAdapt = length(adaptStr);
            isOK = false(nAdapt,1);   
            nInfo = zeros(nAdapt,1);
            [obj.objIMAQDev,obj.sFormat,vStrIMAQ0] = deal(cell(nAdapt,1));
                  
            % loops through the adaptor strings retrieving the device names
            for i = 1:length(adaptStr)                
                try 
                    % attempts to retrieve the device info
                    devInfo = imaqhwinfo(adaptStr{i});                    
                    if ~isempty(devInfo.DeviceInfo)
                        % if available then set the imaq device information                    
                        obj.objIMAQDev{i} = devInfo.DeviceInfo;
                        isOK(i) = true;
                        nInfo(i) = length(obj.objIMAQDev{i});
                        vStrIMAQ0{i} = obj.objIMAQDev{i}.DeviceName;
                        obj.sFormat{i} = obj.detFeasCamFormat(i);
                    end
                catch
                    % case is an error occured retrieving the information
                    isOK(i) = false;
                end
            end
            
            % clears the screen
            clc
            
            % if there are no feasible recording devices, then exit
            if ~any(isOK)
                obj.hasIMAQ = false;
                return
            end                    
            
            % removes the infeasible devices and reduces
            obj.objIMAQDev = obj.objIMAQDev(isOK);
            obj.sFormat = cell2cell(obj.sFormat(isOK));
            obj.sInd = ones(length(obj.sFormat),1);
            obj.vIndIMAQ = cell2mat(arrayfun(@(i,n)([i*ones(n,1),...
                            (1:n)']),(1:sum(isOK))',nInfo(isOK),'un',0));
            
            % sets the name strings within the list box
            vStrIMAQ0 = vStrIMAQ0(isOK);
            obj.vStrIMAQ = cellfun(@(x,y)(sprintf('%i - %s',x,y)),...
                    num2cell(1:length(vStrIMAQ0))',vStrIMAQ0(:),'un',0);            
            set(handles.listIMAQObj,'String',obj.vStrIMAQ,'value',[])
            
        end
        
        % --- initialises the devce information
        function initDAQInfo(obj)
            
            % updates the loadbar string
            loadStr = 'Initialising Data Acquisition Devices...';
            obj.hLoad.StatusMessage = loadStr;            
            
            % object retrieval
            handles = obj.hGUI;
            
            % determines the attached data acquisition objects
            [obj.objDAQ,obj.hasDAQ] = obj.detConnectedDevice();              
            if ~obj.hasDAQ
                % case is no external devices were detected
                if obj.onlyDAQ
                    % if running in DAC only mode, then prompt the user 
                    % that they need to attach a device before continuing            
                    eStr = sprintf(['Error! There are no external ',...
                            'devices detected.\nYou must attach a ',...
                            'device before trying again.']);
                    waitfor(msgbox(eStr,'No Devices Attached?','modal'))

                    % closes the adaptor information GUI 
                    obj.ok = false;
                end                
                
                % exits the function
                return; 
            end                
            
            % if so, initialise the DAC/serial object listbox 
            isS = strcmp(obj.objDAQ.dType,'Serial');
            obj.nChMax = 2*(1+isS);
            obj.vStrDAQ = cell(length(isS),1);

            % determines the adaptor string names for the serial objects       
            pStr = cellfun(@(x)(get(x,'Port')),obj.objDAQ.Control,'un',0);
            if any(isS)
                % sets the device name strings
                obj.vStrDAQ(isS) = cellfun(@(x,y,z)...
                    (sprintf('%i - %s (%s)',x,y,z)),...
                    num2cell(find(isS(:))),obj.objDAQ.BoardNames(isS),...
                    pStr(isS),'un',false);
            end

            % determines the adaptor string names for the daq objects
            if any(~isS)
                % sets the device name strings
                indD = num2cell(find(~isS));
                bName = obj.objDAQ.BoardNames(~isS);            
                obj.vStrDAQ(~isS) = cellfun(@(x,y,z)...
                           (sprintf('%i - %s (DAC %i)',x,y,z)),...
                           indD(:),bName(:),num2cell(1:sum(~isS))','un',0);  

                % determines if the objects are the new format. if so, 
                % then set the maximum number of channels
                if ~verLessThan('matlab','9.2')
                    ii = find(~isS);
                    a = obj.objDAQ.ObjectConstructorName(~isS,:);
                    for i = 1:size(a,1)
                        obj.nChMax(ii(i)) = length(a{i,3}.chName);
                    end
                end
            end
            
            % initialises the device channel count editbox
            obj.nDAQMax = min(obj.nDAQMax,length(obj.vStrDAQ));
            obj.initChannelEdit();    
            
            % sets the list/channel values (if adaptors have been set)
            if obj.isSet
                set(handles.listDACObj,'value',obj.objDAQ.vSelDAQ)
                for i = 1:length(obj.objDAQ.vSelDAQ)
                    j = obj.objDAQ.vSelDAQ(i);
                    hEdit = findobj(handles.panelDACObj,...
                                            'style','edit','UserData',j);
                    if isnan(nChannel(j))
                        obj.setEditProp(j,'opto')
                    else
                        nChStr = num2str(nChannel(j));
                        set(hEdit,'backgroundcolor','w','enable','on',...
                                  'ForegroundColor','k','string',nChStr)
                    end
                end
            end            

            % sets the name strings within the list box
            set(handles.listDACObj,'String',obj.vStrDAQ,'value',[])         
            
        end   

        % --- initialises the properties of the channel count editboxes
        function initChannelEdit(obj)

            % initialises the editboxes
            obj.setEditProp(1:obj.nDAQMax,'inactive')

            % loops through all of the edit boxes setting up callbacks
            for i = 1:obj.nDAQMax
                % retrieves the next edit box handle
                hObjNw = findobj('style','edit','userdata',i);

                % if optogenetics serial device, then preset value to NaN
                if i <= length(obj.objDAQ.sType)
                    if strcmp(obj.objDAQ.sType{i},'Opto')
                        set(hObjNw,'string','N/A')
                        obj.nCh(i) = NaN;
                    end
                end

                % sets the editbox callback function
                set(hObjNw,'Callback',@obj.editChannelUpdate)
            end

        end
        
        % --- performs the final initialisation checks
        function finalInitCheck(obj)
            
            % updates the loadbar string
            loadStr = 'Final Housekeeping Exercises...';
            obj.hLoad.StatusMessage = loadStr;             
            
            % object retrieval
            handles = obj.hGUI;
           
            % if there are no attached recording objects, then return an
            % error and exit the function
            if ~(obj.hasDAQ || obj.hasIMAQ)
                % deletes the loadbar
                try; delete(obj.hLoad); end

                % outputs the error message
                tStr = 'No Video/External Devices Detected';
                eStr = sprintf(['No video or other external devices ',...
                    'were detected!\nPlease ensure that either a ',...
                    'recording device or an external stimuli ',...
                    'delivering device is attached before attempting ',...
                    'to record an experiment.']);
                waitfor(errordlg(eStr,tStr,'modal'))

                % cancels the GUI with an empty array 
                obj.ok = false;
                return
            end                        
            
            % sets the experiment radio buttons based
            setObjEnable(handles.radioRecordStim,obj.hasDAQ && obj.hasIMAQ)
            setObjEnable(handles.radioRecordOnly,obj.hasIMAQ)
            setObjEnable(handles.radioStimOnly,obj.hasDAQ)

            % sets the radio button of the first valid experiment type
            if obj.hasIMAQ
                set(handles.radioRecordOnly,'value',1)
            else
                set(handles.radioStimOnly,'value',1)
            end    
            
            % runs the panel selection change update function
            if ~obj.onlyDAQ
                obj.panelExptTypeSC(handles.panelExptType, '1')
            end
            
            % deletes the loadbar
            try; delete(obj.hLoad); end            
            
        end
        
        % --------------------------------- %        
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %        
        
        % --- Executes when selected object is changed in panelExptType.
        function listIMAQObjCB(obj, hObject, eventdata)
           
            % initialisations
            handles = obj.hGUI;
            hButtonC = handles.buttonConnect;
            vSelIMAQNw = get(hObject,'Value');
            recordOnly = strcmp(obj.exType,'RecordOnly');
            
            % sets the current user selection            
            if isempty(vSelIMAQNw)
                setObjEnable(hButtonC,'off')
                return
            else
                obj.vSelIMAQ = vSelIMAQNw;
            end

            % determines if the data/image acquisition objects are
            % selected from the list            
            notOK = length(obj.vSelIMAQ) ~= 1;
            if ~recordOnly
                % case is a stimuli and recording expt
                notOK = notOK || isempty(obj.vSelDAQ);
            end
            
            % if required info is set, then enable the connection button
            if notOK
                setObjEnable(hButtonC,0)
            else
                canConnect = recordOnly || ...
                            (~(isempty(obj.vSelDAQ) || ...
                               any(obj.nCh(obj.vSelDAQ) == 0)));
                setObjEnable(hButtonC,canConnect)
            end

            % updates the drop-down box
            if ~isa(eventdata,'char')                
                % sets the video resolution/format strings
                popStr = obj.sFormat{obj.vSelIMAQ};
                
                % updates the object properties
                setObjEnable(handles.textVidResolution,'on')
                set(handles.popupVidResolution,'string',popStr,'max',1)
                setObjEnable(handles.popupVidResolution,length(popStr)>1)
                
                if obj.sInd(obj.vSelIMAQ) > 0
                    % updates the selection
                    iResNew = obj.sInd(obj.vSelIMAQ);
                    set(handles.popupVidResolution,'value',iResNew)
                else
                    % otherwise sets the value to be the non-selected value
                    set(handles.popupVidResolution,'value',1)
                end
            end            
            
        end           
        
        % --- Executes when selected object is changed in panelExptType.
        function popupVidResolutionCB(obj, hObject, ~)
            
            % updates the selection            
            obj.sInd(obj.vSelIMAQ) = get(hObject,'value');
            
        end   
        
        % --- Executes when selected object is changed in panelExptType.
        function listDACObjCB(obj, hObject, ~)

            % sets the current user selection
            handles = obj.hGUI;
            obj.vSelDAQ = get(hObject,'Value');
            isOpto = strcmp(obj.objDAQ.sType,'Opto');
            stimOnly = strcmp(obj.exType,'StimOnly');

            % sets the flags of the edit boxes that need to be updated
            [ii,jj] = deal(true(obj.nDAQMax,1),false(obj.nDAQMax,1));
            [ii(obj.vSelDAQ),jj(isOpto)] = deal(false,true);

            % resets the edit-box properties
            obj.setEditProp(find(ii),'inactive')
            obj.setEditProp(find(~ii & ~jj),'on')
            obj.setEditProp(find(~ii & jj),'opto')
            pause(0.01); drawnow

            % determines if it is feasible for the user to connect
            if obj.onlyDAQ
                % updates the requirement strings (for DAQ only)
                obj.updateReqdStrings(handles)
            else
                % determines if the data/image acquisition objects are
                % selected from the list
                notOK = isempty(obj.vSelDAQ);
                if ~stimOnly
                    % case is a stimuli and recording expt
                    notOK = notOK || isempty(obj.vSelIMAQ);
                end
                
                if notOK
                    % case is a IMAQ/DAQ device was not selected
                    setObjEnable(handles.buttonConnect,'off')
                else
                    % determines if the correct configuration is set
                    canConnect = all((obj.nCh(obj.vSelDAQ)>0) | ...
                                            isnan(obj.nCh(obj.vSelDAQ)));
                    setObjEnable(handles.buttonConnect,canConnect)
                end
            end            
            
        end           
        
        % --- callback function for updating the channel count edit boxes
        function editChannelUpdate(obj, hObject, ~)

            % retrieves the required data structs
            iCh = get(hObject,'UserData');
            handles = obj.hGUI;

            % retrieves the new value and determines if it is valid
            nwVal = str2double(get(hObject,'string'));
            if chkEditValue(nwVal,[0 obj.nChMax(iCh)],1)
                % sets the new value if valid
                obj.nCh(iCh) = nwVal;

                % check to see if only the DAC objects are being set
                if obj.onlyDAQ
                    % retrieves the
                    obj.updateReqdStrings()
                else
                    % otherwise, check to see if the IMAQ object has been 
                    % set AND at least one channel has been provided for 
                    % each DAC device
                    canConnect = ~(any(obj.nCh(obj.vSelDAQ) == 0) || ...
                                   isempty(obj.vSelIMAQ));
                    setObjEnable(handles.buttonConnect,canConnect)
                end
            else
                % otherwise, revert back to the previous valid value
                set(hObject,'string',num2str(obj.nCh(iCh)));
            end            
            
        end           
        
        % ----------------------------------------- %        
        % --- OBJECT SELECTION CHANGE FUNCTIONS --- %
        % ----------------------------------------- %        

        % --- Executes when selected object is changed in panelExptType.
        function panelExptTypeSC(obj, hObject, eventdata)
            
            % initialisations
            handles = obj.hGUI;
            hPanel = handles.panelDACObj;
            hPopup = handles.popupVidResolution;

            % retrieves the experiment type
            if isa(eventdata,'char')
                obj.exType = get(get(hObject,'SelectedObject'),'UserData');
            else
                obj.exType = get(eventdata.NewValue,'UserData');
            end

            % sets the DAC object panel enabled
            switch obj.exType
                case ('RecordOnly') % case is recording only
                    % disables the DAQ panel
                    setPanelProps(handles.panelDACObj,'off')
                    setPanelProps(handles.panelIMAQObj,'on',hPopup)

                    % clears the DAQ listbox/device selection lists
                    set(handles.listDACObj,'value',[])
                    obj.vSelDAQ = deal([]);                    

                    % updates the camera object list properties
                    [obj.hasDAQ,obj.hasIMAQ] = deal(false,true);
                    obj.listIMAQObjCB(handles.listIMAQObj,'1')

                case ('StimOnly') % case is stimuli only
                    % disables the DAQ panel
                    setPanelProps(handles.panelDACObj,'on')
                    setPanelProps(handles.panelIMAQObj,'off')
                    
                    % disables the video resolution popupmenu
                    set(hPopup,'enable','off','String',{' '},'Value',1)   
                    
                    % updates the camera/DAC object list properties
                    obj.listDACObjCB(handles.listDACObj, [])                    
                    
                    % clears the DAQ listbox/device selection lists
                    [obj.hasDAQ,obj.hasIMAQ] = deal(true,false);
                    set(handles.listIMAQObj,'value',[])
                    obj.vSelIMAQ = deal([]);                    

                otherwise % case is the other buttons
                    % otherwise, disable the panel
                    setPanelProps(handles.panelDACObj,'on') 
                    setPanelProps(handles.panelIMAQObj,'on',hPopup)

                    % updates the camera/DAC object list properties
                    [obj.hasDAQ,obj.hasIMAQ] = deal(true);
                    obj.listIMAQObjCB(handles.listIMAQObj, '1')
                    obj.listDACObjCB(handles.listDACObj, [])

                    % disables the non-DAC editbox entries
                    nChF = length(obj.nCh);
                    hCheck = cellfun(@(x)(findall(hPanel,'UserData',x)),...
                                num2cell((obj.nDAQMax+1):nChF),'un',0);
                    cellfun(@(x)(setObjEnable(x,'Inactive')),hCheck)
            end           
            
        end
        
        % ----------------------- %        
        % --- OTHER FUNCTIONS --- %
        % ----------------------- %
        
        % --- determines the required device criteria strings/colours
        function [crStr,crCol] = detCriteriaProps(obj,varargin)
        
            % initialisations
            nDev = obj.reqdConfig.nDev;
            crStr = repmat({'None'},nDev,1);
            crCol = repmat({'r'},nDev,1);

            % retrieves the device name/channel counts
            switch length(varargin)
                case 0
                    % case is the device channel type/count is not provided
                    nChD = obj.objDAQ.nChannel;
                    sTypeD = obj.objDAQ.sType(obj.objDAQ.vSelDAC);

                case 2
                    % case is the device channel type/count is provided
                    [sTypeD,nChD] = deal(varargin{1},varargin{2});
            end

            % retrieves the device name/channel counts
            isFound = false(length(sTypeD),1);

            % for each required device, determine if a matching device 
            % already exists. if so, update the criteria string/colours
            for i = 1:nDev
                isMatch = strcmp(sTypeD(:),...
                                obj.reqdConfig.dType{i}) & ~isFound(:);
                if any(isMatch)
                    % sets the row flag and updates the criteria flag
                    crStr{i} = 'Device';
                    iRow = find(isMatch,1,'first');
                    isFound(iRow) = true;

                    % determines if the channel count is correct
                    switch sTypeD{iRow}
                        case 'Opto'
                            % case is the opto device (fixed channel count)
                            okD = true;
                        otherwise
                            % case is some other device type
                            okD = nChD(iRow) >= obj.reqdConfig.nCh(i);
                    end

                    % updates the criteria strings/colours (if met)
                    if okD
                        [crStr{i},crCol{i}] = deal('All','k');
                    end
                end
            end     
        end
            
        % --- determines the feasible camera formats --- %
        function sFormat = detFeasCamFormat(obj,iAdapt)

            % sets the upper limit on the camera
            imaqInfoDev = obj.objIMAQDev{iAdapt};
            sFormat = cell(length(imaqInfoDev),1);

            % sets the camera formats (for each camera type)
            for i = 1:length(sFormat)
                % determines the supported strings
                A = imaqInfoDev(i).SupportedFormats;
                if any(strContains(A,'_x'))
                    sFormatS = cellfun(@(x)...
                                (splitStringRegExp(x,'_x')'),A,'un',0);

                    % removes the non-feasible camera settings
                    if length(sFormatS{1}) == 3
                        isFeas = cellfun(@(x)(...
                                (str2double(x{2}) <= obj.Wmax)) && ...
                                (str2double(x{3}) <= obj.Hmax),sFormatS);
                        sFormat{i} = A(isFeas);
                    end
                elseif any(strContains(A,'Mono8'))
                    % removes any non Mono8 fields
                    A = A(:);
                    hasMono = strContains(A,'Mono');
                    isMono8 = strContains(A,'Mono8');
                    sFormat{i} = [A(~hasMono);A(isMono8)];
                else
                    sFormat{i} = A(:);
                end
            end
            
        end
        
        % --- determines if there are any external devices connected
        function [daqInfo,hasDevice] = detConnectedDevice(obj)
            
            % retrieves the serial device strings from the parameter file
            A = load(obj.pFile);

            % initialisations
            [hasDevice,sStr] = deal(false,A.sDev);
            daqInfo = obj.initDAQInfoStruct();
            
            % --------------------------------- %
            % --- EXTERNAL DEVICE DETECTION --- %
            % --------------------------------- %   
            
            % determines the external devices (if available)
            if ~isempty(obj.extnObj)
                daqInfo = obj.extnObj.detectExtnDevices(daqInfo); 
                hasDevice = ~isempty(obj.extnObj.devStr);
            end

            % -------------------------------------- %
            % --- BFKLAB SERIAL DEVICE DETECTION --- %
            % -------------------------------------- %
            
            % closes and deletes any open serial ports
            hh = instrfind();
            if ~isempty(hh)
                fclose(hh);
                delete(hh);
            end

            % if there are any valid devices then retrieve their details
            pStr = findSerialPort(sStr);
            if ~isempty(pStr)
                % sets the object details                    
                daqInfo = appendSerialInfo(daqInfo,pStr,obj.vStr);  
                hasDevice = ~isempty(daqInfo.Control) || hasDevice;
            end        
        end
        
        % --- updates the required device strings/colours
        function updateReqdStrings(obj)

            % initialisations
            nCol = 4;
            handles = obj.hGUI;
            hPanel = handles.panelUSBRequire;

            % determines the criteria properties
            iSelDAQ = obj.vSelDAQ;
            [crStr,crCol] = obj.detCriteriaProps(...
                            obj.objDAQ.sType(iSelDAQ),obj.nCh(iSelDAQ));

            % updates the criteria colours/strings for each required device
            for i = 1:length(crStr)
                hTxt = arrayfun(@(x)(findobj...
                            (hPanel,'UserData',[i,x])),1:nCol,'un',0);
                cellfun(@(x)(set(x,'ForegroundColor',crCol{i})),hTxt);
                set(hTxt{nCol},'string',crStr{i})   
            end

            % sets the connect button enabled properties
            allOK = all(strcmp(crStr,'All'));
            setObjEnable(handles.buttonConnect,allOK)

        end
        
        % --- updates the channel edit box properties --- %
        function setEditProp(obj,ind,state)

            % if there are no indices, then exit the function
            if isempty(ind)
                return;
            end

            % retrieves the edit boxes corresponding to the indices
            hEdit = cellfun(@(x)(findobj('Style','Edit','UserData',x)),...
                                 num2cell(ind),'un',0);
            hEdit = reshape(hEdit,length(ind),1);

            % sets the edit box enabled state
            switch (state)
                case ('inactive')
                    [bCol,fCol] = deal(0.5*[1 1 1],'w');    
                case ('on')
                    [bCol,fCol] = deal('w','k');
                otherwise
                    [bCol,fCol,state] = deal(0.8*[1 1 1],'k','inactive');
            end

            % sets the new edit strings
            editStr = arrayfun(@num2str,obj.nCh(ind),'un',0);
            editStr(isnan(obj.nCh(ind))) = {'N/A'};

            % otherwise, reset the editbox background and string
            cellfun(@(x)(setObjEnable(x,state)),hEdit)
            cellfun(@(x,y)(set(x,'BackgroundColor',bCol,'String',y,...
                                 'ForegroundColor',fCol)),hEdit,editStr);

        end
        
    end
    
    % static class methods
    methods (Static)        
        
        % --- initialises the daq information structs
        function objDAQInfo = initDAQInfoStruct()

            objDAQInfo = struct('BoardNames',[],'InstalledBoardIds',[],...
                                'ObjectConstructorName',[],'Control',[],...
                                'dType',[],'sType',[]);
                            
        end
        
    end
    
end
