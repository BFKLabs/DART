classdef VideoPara < handle
   
    % class properties
    properties
        
        % external object handles
        hMain
        hFigM               
        
        % class objects/data structs
        iProg        
        srcObj
        infoObj
        infoSrc        
        
        % object handles
        hFig
        hPanel
        hPanelC
        hTxt
        hObj
        hButC
        hObjEN
        hLoad
        
        % fixed object dimensions
        dX = 10;
        hGap = 5;
        widFig = 300;
        hghtFig = 150;
        hghtTxt = 18;
        hghtEdit = 20;
        hghtPop = 20;
        hghtBut = 25;
        hghtPanelC = 40;
        
        % calculated object dimensions        
        widTxt
        widObj
        widBut
        widPanel                
        hghtPanel        
        
        % array fields
        iR
        iC
        isEnum
        isNum
        isFeas
        cVal0
        hasP
        igFld
        igName
        nPara
        nRow
        pVal0
        sInfo
        widTxtMx
        widObjMx
        isWebCam
        sObj
        
        % scalar/string fields
        nCol
        eStr0
        pSz = 13;
        tSz = 12;           
        pHght = 25;
        isOK = true;
        lArr = char(8594);
        tagStr = 'figVideoPara';
        
    end
    
    % class methods
    methods
        
        % --- class constructor 
        function obj = VideoPara(hMain)
            
            % sets the input arguments
            obj.hMain = hMain;
            obj.hFigM = hMain.figFlyRecord;            
            
            % initialises the class fields/objects
            obj.initClassFields();            
            if obj.isOK
                % if everything is ok, then create the class objects
                obj.initClassObjects();
            end
            
        end
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % retrieves the data struct/class objects
            obj.iProg = getappdata(obj.hFigM,'iProg');
            obj.infoObj = getappdata(obj.hFigM,'infoObj');
            obj.isWebCam = isa(obj.infoObj.objIMAQ,'webcam');
            
            % creates the loadbar object
            lStr = 'Retrieving Device Default Properties';
            obj.startLoadBar(lStr);
            
            % retrieves the source information fields
            if obj.isWebCam
                obj.sObj = obj.infoObj.objIMAQ;
                obj.infoSrc = combineDataStruct(obj.sObj.pInfo);
            else
                obj.srcObj = getselectedsource(obj.infoObj.objIMAQ);
                obj.infoSrc = combineDataStruct(propinfo(obj.srcObj));
                obj.sObj = obj.srcObj;
            end
            
            % retrieves the field names and the original property values
            fType = field2cell(obj.infoSrc,'Type');
            fConstraint = field2cell(obj.infoSrc,'Constraint');
            fReadOnly = field2cell(obj.infoSrc,'ReadOnly');
            
            % determines which parameters are enumeration/numeric
            obj.isEnum = strcmp(fType,'string') & ...
                         strcmp(fConstraint,'enum') & ...
                         ~strcmp(fReadOnly,'always');
            obj.isNum = (strcmp(fType,'double') | ...
                         strcmp(fType,'integer')) & ...
                         ~strcmp(fReadOnly,'always');
                     
            % applies the default device properties
            obj.applyDefDeviceProps();
                     
            % if there are no valid parameters, then exit the function
            if ~any(obj.isEnum) && ~any(obj.isNum)                
                % outputs a warning to screen
                tStr = 'No Feasible Camera Parameters';
                wStr = 'Camera does not have any feasible parameters!';
                waitfor(warndlg(wStr,tStr,'modal'))
                
                % exits with a false flag
                obj.isOK = false;
                return
            end                                    

            % memory allocation
            [A,B] = deal(zeros(1,2),cell(1,2));
            [obj.sInfo,obj.hTxt,obj.hObj,obj.isFeas,obj.cVal0] = deal(B);
            [obj.nPara,obj.nRow,obj.hghtPanel] = deal(A);
            [obj.widTxtMx,obj.widObjMx] = deal(A);
            obj.hasP = [any(obj.isNum),any(obj.isEnum)];
            
            % sets the calculated dimensions
            obj.widPanel = obj.widFig - 2*obj.dX;
                     
            % sets up the camera fields to ignore            
            obj.getIgnoredFieldInfo();            
            
            % sets the source object handle and original parameter values 
            % into the GUI
            if obj.isWebCam
                % case is a webcam object
                fStr = field2cell(obj.infoSrc,'Name');
                pStr0 = fieldnames(obj.infoObj.objIMAQ);                
                [pStr,iA,~] = intersect(fStr,pStr0,'Stable');
                
                % reduces down the arrays
                obj.isNum = obj.isNum(iA);
                obj.isEnum = obj.isEnum(iA);
                obj.infoSrc = obj.infoSrc(iA);               
                
            else
                % case is another camera type
                pStr = fieldnames(obj.sObj);
            end
            
            % memory allocation
            okP = true(size(pStr));
            obj.pVal0 = cell(length(okP),2);

            % retrieves the original parameter values
            for i = 1:length(okP)
                try
                    obj.pVal0(i,:) = {pStr{i},get(obj.sObj,pStr{i})};
                catch
                    okP(i) = false;
                end
            end

            % sets the combined array
            obj.pVal0 = obj.pVal0(okP,:);            
            
            % --- PROPERTY FEASIBILITY CALCULATIONS --- %
            
            % case is the enumeration parameters
            sInfoENum = obj.infoSrc(obj.isEnum);
            obj.cVal0{1} = field2cell(sInfoENum,'ConstraintValue');
            obj.isFeas{1} = cellfun('length',obj.cVal0{1}) > 1;

            % case is the numerical parameters
            sInfoNum = obj.infoSrc(obj.isNum);                
            sInfoNum = obj.appendOtherNumPara(sInfoNum);            
            obj.cVal0{2} = arrayfun(@(x)...
                (double(x.ConstraintValue)),sInfoNum(:),'un',0);
            obj.isFeas{2} = diff(cell2mat(obj.cVal0{2}),[],2) > 0;
            
            % calculates the optimal column count
            fPos = get(0,'ScreenSize');
            nParaT = sum(cellfun(@sum,obj.isFeas));
            hghtT = fPos(4) - (7*obj.dX + obj.hghtPanelC);
            obj.nCol = max(2,ceil(obj.pHght*nParaT/hghtT));

            % disable warnings
            warning('off','imaq:gige:adaptorPropertyHealed')

        end
        
        % --- initialises the class fields
        function initClassObjects(obj)            
            
            % deletes any previous objects
            hFigPr = findall(0,'tag',obj.tagStr);
            if ~isempty(hFigPr); delete(hFigPr); end
            
            % -------------------------- %
            % --- CLASS FIGURE SETUP --- %
            % -------------------------- %
            
            % creates the figure object
            fStr = 'Video Recording Parameters';
            fPos = [100*[1,1],obj.widFig,obj.hghtFig];
            obj.hFig = figure('Position',fPos,'tag',obj.tagStr,...
                              'MenuBar','None','Toolbar','None',...
                              'Name',fStr,'NumberTitle','off',...
                              'Visible','off','Resize','off',...
                              'CloseRequestFcn',[]); 
                          
            % ------------------------------ %
            % --- CONTROL BUTTON OBJECTS --- %
            % ------------------------------ % 
            
            % initialisations
            bStrBC = {'Load Preset','Save Presets',...
                      'Reset Original','Close Window'};
            cFcnBC = {@obj.buttonLoad,@obj.buttonSave,...
                      @obj.buttonReset,@obj.buttonClose};
                        
            % creates the control button panel
            pPosC = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelC];
            obj.hPanelC = uipanel(obj.hFig,'Title','','Units',...
                                           'Pixel','Position',pPosC);
            
            % creates the control button objects
            obj.hButC = cell(length(bStrBC),1);
            bPosC = [obj.dX,obj.dX-2,obj.widPanel-2*obj.dX,obj.hghtBut];
            for i = 1:length(bStrBC)
                obj.hButC{i} = uicontrol(obj.hPanelC,'Style','PushButton',...
                                'Units','Pixels','Position',bPosC,...
                                'Callback',cFcnBC{i},'FontWeight','Bold',...
                                'FontUnits','Pixels','FontSize',obj.tSz,...
                                'String',bStrBC{i});                
            end  
            
            % sets up the initial panel position vectors
            y0 = sum(pPosC([2,4]));
            hPanel0 = obj.hghtFig - (y0 + 2*obj.dX);
            pPos0 = [obj.dX+[0,y0],obj.widPanel,hPanel0];
            
            % ----------------------------------------- %
            % --- NUMERICAL PARAMETER PANEL OBJECTS --- %
            % ----------------------------------------- % 
                        
            % title strings
            tStr = {'NUMERICAL PARAMETERS','ENUMERATION PARAMETERS'};
            
            % creates the panels and objects
            for i = 1:2
                % sets up the numerical parameters (if any)
                if any(obj.hasP(i))
                    % creates the panel object                    
                    obj.hPanel{i} = uipanel('Title',tStr{i},'Units',...
                        'pixels','FontWeight','bold','Parent',obj.hFig,...
                        'Position',pPos0,'tag','panelNumPara',...
                        'BorderType','etchedin','FontUnits','pixels',...
                        'FontSize',obj.pSz);
                    
                    % sets up the numerical parameter objects
                    [obj.hTxt{i},obj.hObj{i}] = ...
                        obj.setupParaObj(obj.hPanel{i},i==2);
                end
            end       
            
            % --------------------------------------------- %
            % --- OBJECT REDIMENSIONING & REPOSITIONING --- %
            % --------------------------------------------- %      
            
            % calculates the max
            widTxtT = max(obj.widTxtMx);
            widObjT = max(obj.widObjMx);
            widT = widTxtT + widObjT;
            
            % recalculates the figure/panel dimensions
            obj.widPanel = 2*obj.dX + (obj.nCol-1)*obj.hGap + obj.nCol*widT;
            obj.hghtFig = 2*obj.dX + obj.hghtPanelC;
            obj.widFig = obj.widPanel + 2*obj.dX;
            
            % sets the text/parameter object left locations
            xiN = (1:obj.nCol);
            lTxt = arrayfun(@(x)(obj.dX+(x-1)*(widT+obj.hGap)),xiN,'un',0);
            lObj = cellfun(@(x)(x+widTxtT),lTxt,'un',0);
            
            % resets the object dimensions
            for i = find(obj.hasP)
                % resets the widths of the text/parameter objects
                cellfun(@(h)(obj.resetObjDim(h,3,widTxtT)),obj.hTxt{i})
                cellfun(@(h,l)...
                    (obj.resetObjDim(h,1,l)),obj.hTxt{i},lTxt(obj.iC{i})')
                
                % resets the widths of the text/parameter objects
                cellfun(@(h)(obj.resetObjDim(h,3,widObjT)),obj.hObj{i})
                cellfun(@(h,l)...
                    (obj.resetObjDim(h,1,l)),obj.hObj{i},lObj(obj.iC{i})')                
                
                % resets the figure height
                obj.resetObjDim(obj.hPanel{i},2,obj.hghtFig);
                obj.resetObjDim(obj.hPanel{i},3,obj.widPanel);
                obj.hghtFig = obj.hghtFig + (obj.dX + obj.hghtPanel(i));
            end
            
            % recalculates the button width
            nBut = length(obj.hButC);
            obj.widBut = (obj.widPanel - (2+(nBut-1)/2)*obj.dX)/nBut;
            
            % resets the left/width locations of the buttons
            lButC = arrayfun(@(x)...
                ((1+(x-1)/2)*obj.dX+(x-1)*obj.widBut),1:nBut,'un',0);
            cellfun(@(h)(obj.resetObjDim(h,3,obj.widBut)),obj.hButC)
            cellfun(@(h,l)(obj.resetObjDim(h,1,l)),obj.hButC,lButC(:))
            
            % resets the figure/control panels dimensions
            obj.resetObjDim(obj.hPanelC,3,obj.widPanel)            
            obj.resetObjDim(obj.hFig,4,obj.hghtFig);
            obj.resetObjDim(obj.hFig,3,obj.widFig);            
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
                      
            % sets the enumeration parameters
            obj.setEnumParaDepObjects();     
            obj.updateEnumParaDepObjects();  
            setObjEnable(obj.hButC{3},'off')
            
            % disables the real-time tracking menu item (if available)
            if isfield(obj.hMain,'menuRTTrack')
                obj.eStr0 = get(obj.hMain.menuRTTrack,'enable');
                setObjEnable(obj.hMain.menuRTTrack,'off')
            end
            
            % stops the loadbar
            obj.stopLoadBar();
            
            % makes the main gui visible again
            centreFigPosition(obj.hFig,2);
            setObjVisibility(obj.hFig,1);
            
        end    
        
        % --- sets up the enumeration parameter dependent objects
        function setEnumParaDepObjects(obj)
        
            % retrieves the parameter 
            eInfoSrc = obj.infoSrc(obj.isEnum); 
            fStrE = field2cell(eInfoSrc(obj.isFeas{1}),'Name');
            fStrN = cellfun(@(x)(x.UserData.Name),obj.hObj{1},'un',0);
            
            % sets the 
            obj.hObjEN = cell(length(fStrE),2);
            for i = 1:length(fStrE)
                isS = cellfun(@(x)(startsWith(fStrE{i},x)),fStrN);
                if any(isS)
                    obj.hObjEN{i,1} = obj.hTxt{1}{isS};
                    obj.hObjEN{i,2} = obj.hObj{1}{isS};
                end
            end
            
        end
        
        % --- updates the enumeration parameter dependent objects
        function updateEnumParaDepObjects(obj,iDev)
            
            % search string list
            sStr = {'auto'};
            
            % sets the default input arguments
            if ~exist('iDev','var'); iDev = 1:size(obj.hObjEN,1); end
        
            % updates the properties for the dependent object
            for i = iDev(:)'
                % if there is no dependent object, then continue
                if isempty(obj.hObjEN{i,1})
                    continue
                end
                
                % determines if the "auto" flag has been selected
                lStrS = obj.hObj{2}{i}.String{obj.hObj{2}{i}.Value};
                isOn = ~any(strcmp(sStr,lStrS));                
                cellfun(@(x)(setObjEnable(x,isOn)),obj.hObjEN(i,:))
            end
            
        end            
        
        % ---------------------------------- %
        % --- PARAMETER OBJECT CALLBACKS --- %
        % ---------------------------------- %
        
        % --- runs on editing one of the numerical parameters
        function editCallback(obj, hObj, ~)
            
            % field retrieval
            srcInfo = get(hObj,'UserData');
            nwVal = str2double(get(hObj,'string'));
            prVal = get(obj.sObj,srcInfo.Name);
            
            % retrieves the source information struct for the parameter
            if obj.isWebCam
                fName = field2cell(obj.infoSrc,'Name');
                srcInfoNw = obj.infoSrc(strcmp(fName,srcInfo.Name));
            else                
                srcInfoNw = propinfo(obj.srcObj,srcInfo.Name);
            end
            
            % retrieves the current parameters constraints values
            nwLim = srcInfoNw.ConstraintValue;
%             isInt = all(mod(nwLim,1) == 0);
            
            % check to see if the new value is valid
            if chkEditValue(nwVal,nwLim,false)
                try
                    % if so, then update the camera parameters
                    set(obj.sObj,srcInfo.Name,nwVal)    
                    obj.specialParaUpdate(srcInfo.Name,nwVal)
                    
                    % enables the reset button
                    setObjEnable(obj.hButC{3},'on')
                catch
                    % otherwise, outputs the error message and reset
                    % the to last valid values
                    obj.outputUpdateErrorMsg()
                    set(hObj,'string',num2str(prVal))
                end
            else
                % otherwise, reset to the previous value
                set(hObj,'string',num2str(prVal))
            end
            
        end
        
        % --- runs on editing one of the enumeration parameters
        function popupCallback(obj, hObj, ~)
            
            % retrieves the source object and related information
            srcInfo = get(hObj,'UserData');
            
            % retrieves the current property value
            lStr = get(hObj,'String');
            nwVal = lStr{get(hObj,'value')};
            prVal = get(obj.sObj,srcInfo.Name);
            
            try
                % updates the relevant field in the source object
                if obj.isWebCam
                    switch srcInfo.Name
                        case 'BacklightCompensation'
                            % case is the backlight compensation
                            isOn = strcmp(nwVal,'on');
                            set(obj.sObj,srcInfo.Name,isOn)
                            
                        otherwise
                            % case is the other parameters
                            set(obj.sObj,srcInfo.Name,nwVal)
                    end
                    
                else
                    % case is the other camer types
                    set(obj.sObj,srcInfo.Name,nwVal)
                end                
                
                % updates the dependent enumeration parameters
                fStrE = cellfun(@(x)(x.UserData.Name),obj.hObj{2},'un',0);
                iDevE = find(strcmp(fStrE,srcInfo.Name));
                obj.updateEnumParaDepObjects(iDevE)
                
                % enables the reset button
                obj.specialParaUpdate(srcInfo.Name,nwVal)                
                setObjEnable(obj.hButC{3},'on')
                
            catch
                % otherwise, output an error and resets last valid value
                obj.outputUpdateErrorMsg();
                set(hObj,'Value',find(strcmp(lStr,prVal)))
            end
            
        end
        
        % --- runs on updating editPauseTime
        function editPauseTime(obj, hObj, ~)
            
            % sets the new value and the parameter limits
            nwVal = str2double(get(hObj,'string'));
            nwLim = [5 600];
            
            % retrieves the experimental data struct
            iExpt = getappdata(obj.hFigM,'iExpt');
            
            % check to see if the new value is valid
            if chkEditValue(nwVal,nwLim,1)
                % if so, then update the video pause time
                iExpt.Timing.Tp = nwVal;
                setappdata(obj.hFigM,'iExpt',iExpt)
            else
                % if not, the reset to the previous valid value
                set(hObj,'string',num2str(iExpt.Timing.Tp));
            end
            
        end                        
        
        % ----------------------------------------- %
        % --- CONTROL BUTTON CALLBACK FUNCTIONS --- %
        % ----------------------------------------- %          

        % --- Executes on button press in load button
        function buttonLoad(obj, ~, ~)
            
            % prompts the user for the camera preset file
            [fName,fDir,fIndex] = uigetfile(...
                {'*.vpr','Video Preset Files (*.vpr)'},...
                'Load Stimulus Playlist File',obj.iProg.CamPara);
            if (fIndex ~= 0)
                % determines the preset file feasibility
                fFile = fullfile(fDir,fName);
                [missP,infoSrcNw,vprData] = ...
                    obj.detPresetFileFeasibility(fFile);
                
                if missP
                    % if not, then exit with an error
                    tStr = 'Invalid Camera Presets';
                    eStr = 'Camera presets do not match video properties.';
                    waitfor(errordlg(eStr,tStr,'modal'))
                    return
                    
                else
                    % resets the parameter struct and updates the fields
                    obj.infoSrc = infoSrcNw;
                    obj.pVal0 = [vprData.fldNames(:),vprData.pVal(:)];
                    obj.buttonReset(obj.hButC{3},[])
                end
                
                % resets the enumeration parameter dependent objects
                obj.updateEnumParaDepObjects();
            end
            
        end                
        
        % --- Executes on button press in save button
        function buttonSave(obj, ~, ~)
            
            % sets the default file name
            fDate = datestr(now,'dd-mmm-yyyy');            
            devName = obj.infoObj.objIMAQ.Name;            
            defName = sprintf('%s (%s).vpr',devName,fDate);
            defFile = fullfile(obj.iProg.CamPara,defName);
            
            % prompts the user for the camera preset file
            [fName,fDir,fIndex] = uiputfile(...
                {'*.vpr','Video Preset Files (*.vpr)'},...
                'Save Stimulus Playlist File',defFile);
            if (fIndex ~= 0)
                % if the file exists, then determine if the preset file is
                % the same as the current device
                fFile = fullfile(fDir,fName);
                if exist(fFile,'file')
                    % determines device name exists in the preset file
                    A = importdata(fFile,'-mat');
                    if isfield(A,'devName')
                        % case is the device name field is set
                        isFeasD = strcmp(A.devName,devName);
                        if ~isFeasD
                            eStr = sprintf(['There is a mismatch ',...
                                'between the current device and the ',...
                                'file you are attempting to overwrite:',...
                                '\n\n %s Current Device: %s\n\n ',...
                                '%s Preset File Device: %s\n\n',...
                                'You will need to select another ',...
                                'preset file name'],obj.iArr,devName,...
                                obj.lArr,A.devName);                        
                        end
                        
                    else                        
                        % case is the device name field is missing
                        isFeasD = ~obj.detPresetFileFeasibility(fFile);                        
                        if ~isFeasD
                            eStr = sprintf(['There is a mismatch ',...
                                'between the current device and the ',...
                                'file you are attempting to overwrite:',...
                                '\n\n %s Current Device: %s\n\n ',...
                                'You will need to select another ',...
                                'preset file name'],obj.lArr,devName);
                        end
                    end
                    
                    % outputs an error message (if an error was made)
                    if exist('eStr','var')
                        % if the device names do not align, then 
                        tStr = 'File Overwrite Error';
                        waitfor(msgbox(eStr,tStr,'modal'))

                        % exits the function
                        return
                    end                    
                end
                
                % retrieves the current parameter values and field names
                if obj.isWebCam
                    fldNames = getWebCamProps(obj.infoObj.objIMAQ);
                else
                    fldNames = fieldnames(obj.srcObj);
                end

                % memory allocation
                okP = true(size(fldNames));
                pVal = cell(size(fldNames));

                % retrieves the valid parameters
                for i = 1:length(okP)
                    try
                        pVal{i} = get(obj.sObj,fldNames{i});
                    catch
                        okP(i) = false;
                    end
                end

                % removes the invalid parameters
                [pVal,fldNames] = deal(pVal(okP),fldNames(okP));
                
                % removes the parent object from the struct
                ii = ~cellfun(@(x)(strcmp(x,'Parent')),fldNames);
                [fldNames,pVal] = deal(fldNames(ii),pVal(ii));
                
                % saves the field names/parameter values to file
                save(fFile,'pVal','fldNames','devName')
            end
            
        end        
        
        % --- Executes on button press in reset button
        function buttonReset(obj, hObj, ~)
            
            % other initialisations
            wState = warning('off','all');
            
            % determines if the video preview is running
            vidOn = get(obj.hMain.toggleVideoPreview,'Value');
            if vidOn
                % if so, then turn it off
                toggleFcn = getappdata(obj.hFigM,'toggleVideoPreview');
                set(obj.hMain.toggleVideoPreview,'Value',false)
                toggleFcn(obj.hMain.toggleVideoPreview,[],obj.hMain);
            end

            % sets up the device parameter struct
            pValF = obj.pVal0;
            for i = 1:size(pValF,1)
                % resets the values of any ignored fields
                indP = strcmp(obj.igName,pValF{i,1});
                if any(indP)
                    pValF{i,2} = obj.igFld{indP}{2};
                end
            end
            
            % resets the camera ROI (if necessary)
            resetCameraROIPara(obj.infoObj.objIMAQ);                    
            resetDeviceProps(obj.sObj,pValF,obj.hObj);            
            obj.updateEnumParaDepObjects();                
            
            % resets the video properties (if calibrating)
            vcObj = getappdata(obj.hFigM,'vcObj');
            if ~isempty(vcObj)
                vcObj.resetVideoProp()
            end
            
            % turns the video preview back on (if already on)
            if vidOn
                set(obj.hMain.toggleVideoPreview,'Value',true)
                toggleFcn(obj.hMain.toggleVideoPreview,[],obj.hMain);
            end
            
            % reverts the warning back to their original state
            setObjEnable(hObj,'off')
            warning(wState)
            
        end        
        
        % --- Executes on button press in close button
        function buttonClose(obj, ~, ~)
            
            % resets the real-time tracking menu item enabled properties
            if isfield(obj.hMain,'menuRTTrack')
                setObjEnable(obj.hMain.menuRTTrack,obj.eStr0)
            end
            
            % deletes the sub-GUI
            obj.stopLoadBar(1);
            delete(obj.hFig);
            
        end               

        % ----------------------- %        
        % --- OTHER FUNCTIONS --- %
        % ----------------------- %   

        % --- sets up the parameter in the panel, hE
        function [hTxt,hObj] = setupParaObj(obj,hP,isE)
        
            % overall index
            k = isE + 1;            
            [hTxt,hObj] = deal([]);    
            iExpt = getappdata(obj.hFigM,'iExpt');
            
            % --- DATA PRE-PROCESSING --- %            
            
            % pre-processes the data based on the parameter type
            if isE
                % if there are no parameters then exit
                if ~any(obj.isEnum)
                    return
                end
                
                % case is the numerical parameters
                sInfoENum = obj.infoSrc(obj.isEnum);                
                sInfo0 = sInfoENum(obj.isFeas{1});
                cVal = obj.cVal0{1}(obj.isFeas{1});
                
            else                
                % if there are no parameters then exit
                if ~any(obj.isNum)
                    return
                end
                
                % sets the source information struct
                sInfoNum = obj.infoSrc(obj.isNum);                
                sInfoNum = obj.appendOtherNumPara(sInfoNum);   
                sInfo0 = sInfoNum(obj.isFeas{2});
                cVal = obj.cVal0{2}(obj.isFeas{2});
            end            
            
            % removes any fields which have been flagged for being ignored
            sFld = field2cell(sInfo0,'Name');
            isKeep = true(length(sFld),1);
            for i = 1:length(obj.igFld)
                % determines if ignored field exists in camera properties
                isKeepNw = ~strcmp(sFld,obj.igFld{i}{1});
                isKeep = isKeep & isKeepNw;
                
                % if the field exists, then set the fixed field value
                if any(~isKeepNw)
                    set(obj.srcObj,obj.igFld{i}{1},obj.igFld{i}{2});
                end
            end            

            % sets the source info and parameter/row counts
            cVal = cVal(isKeep);
            obj.sInfo{k} = sInfo0(isKeep);
            obj.nPara(k) = length(obj.sInfo{k});
            obj.nRow(k) = ceil(obj.nPara(k)/obj.nCol);                        
            
            % sets up the row/column indices for each parameter
            xiP = 1:obj.nPara(k);
            [obj.iC{k},iR0] = ind2sub([obj.nCol,obj.nRow(k)],xiP);
            obj.iR{k} = (iR0(end) + 1) - iR0;
            
            % resets the panel height
            obj.hghtPanel(k) = obj.nRow(k)*obj.pHght + 3*obj.dX;
            obj.resetObjDim(hP,4,obj.hghtPanel(k))
            
            % --- TEXT OBJECT CREATION --- %                        
            
            % retrieves the field strings strings
            tStr = splitUpperCase(field2cell(obj.sInfo{k},'Name'));
            
            % creates the text objects
            hTxt = cellfun(@(t)(obj.createTextObj(hP,t)),tStr,'un',0);
            obj.widTxtMx(k) = obj.getMaxObjWidths(hTxt);                

            % resets the bottom location of the text labels
            yTxt = obj.dX + (obj.iR{k}-1)*obj.pHght;            
            cellfun(@(h,y)(obj.resetObjDim(h,2,y)),hTxt,num2cell(yTxt(:)));
            cellfun(@(h)(obj.resetObjDim(h,4,obj.hghtTxt)),hTxt)
            
            % --- PARAMETER OBJECT CREATION --- %                           
            
            % retrieves the parameter value
            sInfoC = num2cell(obj.sInfo{k});            
            pVal = cellfun(@(x)(obj.getParaVal(x)),sInfoC,'un',0);  
            
            %
            if isE
                % determines the selected index
                iSel = cellfun(@(x,y)...
                    (obj.getSelIndex(x,y)),cVal,pVal,'un',0);
                
                % creates the popup objects
                cbFcn = @obj.popupCallback;
                hObj = cellfun(@(p,i,s)(obj.createPopupObj...
                    (hP,p,i,s,cbFcn)),cVal(:),iSel(:),sInfoC,'un',0);                
                
                % calculates maximum parameter object width
                widTxtP = max(cellfun...
                    (@(h,p)(obj.calcPopupWidth(hP,h,p)),hObj,cVal));                                
                obj.widObjMx(k) = max(40,widTxtP);

            else                
                % sets up the tooltip strings
                pVal{end} = iExpt.Timing.Tp;                                
                ttStr = cellfun(@(p,pL,s)(obj.setupTTString...
                    (s,pL,p)),pVal(:),cVal(:),sInfoC,'un',0);
                
                % creates the edit objects
                cbFcn = @obj.editCallback;
                hObj = cellfun(@(p,tt,s)(obj.createEditObj...
                    (hP,p,tt,s,cbFcn)),pVal(:),ttStr,sInfoC,'un',0);
                
                % resets the heights of the objects
                set(hObj{end},'Callback',@obj.editPauseTime);
                cellfun(@(h)(obj.resetObjDim(h,4,obj.hghtEdit)),hObj)
                cellfun(@(h,t)(set(h,'TooltipString',t)),hTxt,ttStr);

                % calculates maximum parameter object width
                obj.widObjMx(k) = max(40,obj.getMaxObjWidths(hObj,0));                
            end            
            
            % resets the bottom location of the objects
            yObj = yTxt + 2*isE;
            cellfun(@(h,y)(obj.resetObjDim(h,2,y)),hObj,num2cell(yObj(:)));
            
        end                
        
        % --- sets up the tooltip string
        function ttStr = setupTTString(obj,sInfo,pL,pV)
            
            try
                ttStr = sprintf(['%s\n %s Lower Limit = %s',...
                    '\n %s Upper Limit = %s',...
                    '\n %s Initial Value = %s'],...
                    sInfo.Name,obj.lArr,num2str(pL(1)),...
                    obj.lArr,num2str(pL(2)),obj.lArr,num2str(pV));
            catch
                ttStr = '';
            end
            
        end

        % ------------------------- %
        % --- LOADBAR FUNCTIONS --- %
        % ------------------------- %
        
        % --- starts the loadbar object
        function startLoadBar(obj,lStr)
            
            if isempty(obj.hLoad)
                obj.hLoad = ProgressLoadbar(lStr);
            else
                obj.hLoad.StatusMessage = lStr;
                setObjVisibility(obj.hLoad.Control,1);
            end
            
        end
        
        % --- starts the loadbar object
        function stopLoadBar(obj,varargin)
            
            if isempty(varargin)
                setObjVisibility(obj.hLoad.Control,0);
            elseif ~isempty(obj.hLoad)
                delete(obj.hLoad.Control);
            end
            
        end
        
        % ------------------------------------------- %        
        % --- DIMENSION/FIELD RETRIEVAL FUNCTIONS --- %
        % ------------------------------------------- %        
        
        % --- calculates the width of the popup menus
        function widPop = calcPopupWidth(obj,hP,hPopup,pStr)

            % parameters
            dWid = 35;

            % creates the dummy text objects
            fSz = get(hPopup,'FontSize');
            hTxtP = cellfun(@(t)(obj.createTextObj(hP,t)),pStr,'un',0);
            cellfun(@(x)(set(x,'FontUnits','Pixels','FontSize',fSz)),hTxtP)

            % retrieves the max text object width and deletes the objects
            widPop = max(cellfun(@(h)(obj.getObjDim(h,3,0)),hTxtP)) + dWid;
            cellfun(@delete,hTxtP)

        end        
        
        % --- calculates the max object width
        function widObj = getMaxObjWidths(obj,hObj,isE)
            
            if ~exist('isE','var'); isE = false; end
            
            if isempty(hObj)
                widObj = 0;
            else
                widObj = max(cellfun(@(h)(obj.getObjDim(h,3,isE)),hObj));
            end
            
        end                
        
        % --- retrieves the value for the given parameter
        function pVal = getParaVal(obj,sInfo)
            
            try
                if obj.isWebCam
                    % case is the other parameters
                    pVal = get(obj.infoObj.objIMAQ,sInfo.Name);
                    
                    switch sInfo.Name
                        case 'BacklightCompensation'
                            % case is the backlight compensation
                            eStr = {'off','on'};
                            pVal = eStr{1+pVal};
                    end
                else
                    pVal = get(obj.srcObj,sInfo.Name);
                end
            catch
                pVal = {'Not Applicable'};
            end
            
        end        
        
        % ------------------------------- %        
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %          
        
        % --- post parameter update function (for specific parameters)
        function specialParaUpdate(obj,pName,pVal)
                        
            % updates the video ROI (depending on camera type)
            switch get(obj.infoObj.objIMAQ,'Name')
                case 'Allied Vision 1800 U-501m NIR'
                    switch pName
                        case {'AutoModeRegionOffsetX',...
                              'AutoModeRegionOffsetY',...
                              'AutoModeRegionWidth',...
                              'AutoModeRegionHeight'}
                            resetCameraROI(obj.hMain,obj.infoObj.objIMAQ)
                    end
            end
            
            % if video calibrating is on, then update the calibration info
            vcObj = getappdata(obj.hFigM,'vcObj');            
            if ~isempty(vcObj) && vcObj.isOpen
                vcObj.appendVideoProp(pName,pVal);
            end
            
        end                
            
        % --- outputs the update error message
        function outputUpdateErrorMsg(obj)
            
            % field retrieval
            if obj.isWebCam
                isPr = false;
                pFldStr = obj.infoObj.objIMAQ.Name;
            else
                pFldStr = obj.infoSrc.Name;
                isPr = strcmp(get(obj.infoObj.objIMAQ,'Previewing'),'on');
            end
            
            % if update failed, then determine if camera is previewing
            if isPr
                % if so, then prompt the user to turn off the camera
                eStr = sprintf(['The "%s" property can only be ',...
                    'altered when not previewing. Turn off ',...
                    'the video preview and try again.'],pFldStr);
                waitfor(msgbox(eStr,'Video Property Update Error','modal'))
            else
                % otherwise, a critical error has occured with the camera
                tStr = 'Video Property Update Error';
                eStr = sprintf(['The "%s" property could not be ',...
                    'correctly. Please ensure the camera is ',...
                    'operating correctly and try again.'],pFldStr);
                waitfor(errordlg(eStr,tStr,'modal'))
            end
            
        end        
        
        % --- retrieves the ignored field information
        function getIgnoredFieldInfo(obj)
            
            % initialisations
            try
                pROI = obj.infoObj.objIMAQ.pROI;                
            catch
                pROI = get(obj.infoObj.objIMAQ,'ROIPosition');
            end
            
            % sets the ignored field information/names
            obj.igFld = {{'AcquisitionFrameRateEnable','True'},...
                         {'AutoModeRegionOffsetX',pROI(1)},...
                         {'AutoModeRegionOffsetY',pROI(2)},...
                         {'AutoModeRegionWidth',pROI(3)},...
                         {'AutoModeRegionHeight',pROI(4)}};
            obj.igName = cellfun(@(x)(x{1}),obj.igFld,'un',0);
            
        end        
                
        % --- applies the default device properties
        function applyDefDeviceProps(obj)
            
            % loads the default data fields
            dName = obj.infoObj.objIMAQ.Name;
            dpData = loadDefaultPresetData(dName);
            if isempty(dpData)
                % if there is no default device properties, then exit
                return
            end
            
            % retrieves the parameter field names
            fStr = field2cell(obj.infoSrc,'Name');
            
            % removes the non-useable
            if dpData.Num.Count > 0
                [~,iN] = intersect(fStr,dpData.Num.Name);
                obj.isNum(iN(~dpData.Num.isUse)) = false;
            end
            
            % updates the enumeration parameters
            if dpData.ENum.Count > 0
                [~,iE] = intersect(fStr,dpData.ENum.Name);
                obj.isEnum(iE(~dpData.ENum.isUse)) = false;
            end
            
        end
        
        % --- determines the preset file feasibility
        function [missP,infoSrcNw,vprData] = ...
                        detPresetFileFeasibility(obj,fFile)

            % loads the video preset data file
            vprData = importdata(fFile);

            % retrieves the source object information 
            if obj.isWebCam
                [fldNames,infoSrcNw] = ...
                    getWebCamProps(obj.infoObj.objIMAQ);
            else
                pInfo = propinfo(obj.srcObj);
                [infoSrcNw,fldNames] = combineDataStruct(pInfo);
            end

            % determines if camera properties match that from file
            missP = ~(isempty(setdiff(fldNames,vprData.fldNames)) || ... 
                      isempty(setdiff(vprData.fldNames,fldNames)));
            if ~missP
                [~,iB] = intersect(vprData.fldNames,fldNames);
                vprData.fldNames = vprData.fldNames(iB);
                vprData.pVal = vprData.pVal(iB);
            end

        end                
        
    end    
    
    % static class methods
    methods (Static)
        
        % --- creates the text object
        function hTxt = createTextObj(hP,tStr)
            
            % creates the text object
            tStrF = sprintf('%s: ',tStr);
            hTxt = uicontrol('Style','text','Parent',hP,...
                             'HorizontalAlignment','Right',...
                             'String',tStrF,'Fontweight','bold',...
                             'TooltipString',tStr,'FontUnits','Pixels',...
                             'FontSize',12);
            
        end  
        
        % --- creates the edit object
        function hEdit = createEditObj(hP,pVal,ttStr,sInfo,cbFcn)
        
            % creates the new editbox
            hEdit = uicontrol('Style','edit','Parent',hP,'String',pVal,...
                              'UserData',sInfo,'BackgroundColor','w',...
                              'HorizontalAlignment','Center',...
                              'TooltipString',ttStr,'Callback',cbFcn);
            
        end
           
        % --- creates the popup object
        function hPopup = createPopupObj(hP,lStr,iSel,sInfo,cbFcn)
        
            % creates the new editbox
            hPopup = uicontrol('Style','popupmenu','String',lStr,...
                           'BackgroundColor','w','Value',iSel,...
                           'UserData',sInfo,'Parent',hP,...
                           'TooltipString',sInfo.Name,'Callback',cbFcn);
            
        end        
        
        % --- retrieves the object dimensions
        function dVal = getObjDim(hObj,iDim,usePos)

            if ~exist('usePos','var'); usePos = false; end
           
            % retrieves the object dimensions
            if any(iDim == [1,2]) || usePos
                % case is the left/bottom dimensions
                pDim = get(hObj,'Position');
                
            else
                % case is the width/height dimensions
                pDim = get(hObj,'Extent');
            end
            
            % returns the dimension value
            dVal = pDim(iDim);                            
            
        end
        
        % --- resets the object dimensions (for the ith component)
        function resetObjDim(hObj,iDim,dVal)
            
            pPos = get(hObj,'Position');
            pPos(iDim) = dVal;
            set(hObj,'Position',pPos);
            
        end                
        
        % --- gets the popup menu selected index
        function iSel = getSelIndex(sArr,sStr)
            
            ii = strcmp(sArr,sStr);
            if any(ii)
                iSel = find(ii);
            else
                iSel = 1;
            end
            
        end
        
        % --- appends the other numerical parameters
        function sInfoN = appendOtherNumPara(sInfoN)
           
            % creates a copy of the sub-struct fields
            sInfoNw = sInfoN(1);
            sInfoNw.Name = 'Inter Video Pause';
            sInfoNw.ConstraintValue = [5 600];
            
            % appends the new field to the struct
            sInfoN(end+1) = sInfoNw;
            
        end            
        
    end
    
end
