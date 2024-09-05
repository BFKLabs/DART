classdef DefDeviceProps < handle
    
    % class properties
    properties
        
        % input argument fields
        hFigM
        hLoad
        
        % object handle fields
        hFig
        hPanelG
        
        % enumeration property fields
        hPanelE
        hTableE
        hListE
        hTxtE
        hEditF
        
        % numerical property fields
        hPanelN
        hTableN
        
        % other device property fields
        hPanelO
        hPopupO
        hEditO
        
        % device property file fields
        hPanelD
        hEditD
        hButD
        
        % device preset file fields
        hPanelP
        hEditP
        hButP        
        
        % control button panel
        hPanelC
        hButC
        
        % fixed object dimensions
        dX = 10;
        hghtObj = 112;
        hghtPanelC = 40;
        hghtPanelD = 145;
        hghtPanelF = 55;
        widPanelO = 520;
        widPanelD = 505;
        widTxtO = 190;
        dimBut = 25;
        hghtRow = 25;
        hghtEdit = 22;                
        hghtTxt = 16;
        
        % calculated object dimensions
        widFig
        hghtFig
        hghtPanelG
        widButC
        widEditD
        widEditO
        
        % device property fields
        pInfo
        devName
        cProps
        cPropsT
        infoObj
        infoSrc  
        iExpt
        
        % parameter file fields
        psDir
        paraDir
        paraFile
        dpFile
        dpFile0        
        
        % table fields
        arrChr = char(8594);
        pStr = {'Num','ENum'};
        cWid = {228,35,71,72,72};
        cEdit = [false,true,false(1,3)];
        cName = {'Property','Use?','Value','Min','Max'};
        cForm = {'char','logical','char','char','char'};
        fModeD = {'*.dpf','Default Property File (*.dpf)'};
        fModeP = {'*.vpr','Default Preset File (*.vpr)'};
        
        % boolean class fields
        isChange        
        isWebCam        
        
        % fixed scalar class fields
        iSelT = 1;
        fSzH = 13;
        fSzT = 12;
        fSz = 10 + 2/3;
        rejCol = 0.8;
        
        % panel title strings
        tStrD = 'DEFAULT DEVICE PROPERTY FILE';        
        tStrP = 'DEFAULT DEVICE PRESET FILE';
        tStrM = 'NUMERICAL DEVICE PROPERTIES';
        tStrE = 'ENUMERATION DEVICE PROPERTIES';
        tStrO = 'OTHER DEVICE PROPERTIES';
        
        % other fixed text class fields
        tagStr = 'figDefProps';
        figStr = 'Default Device Properties';
        bStrC = {'Save','Reset','Clear Files','Close'};
        
    end
   
    % class methods
    methods
        
        % --- class constructor
        function obj = DefDeviceProps(hFigM)
            
            % mandatory field setup
            obj.paraFile = getParaFileName('DefProps.mat');              
            
            % sets the input arguments
            if ~exist('hFigM','var')              
                return
            end

            % sets the input arguments
            obj.hFigM = hFigM;
            
            % initialises the class fields and objects
            obj.initClassFields();
            obj.initClassObjects();
            
        end
            
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % field retrieval from main GUI
            iProg = getappdata(obj.hFigM,'iProg');
            
            % creates the loadbar object
            lStr = 'Retrieving Device Default Properties';
            obj.startLoadBar(lStr);            
            
            % retrieves the data struct/class objects
            obj.psDir = iProg.CamPara;
            obj.iExpt = getappdata(obj.hFigM,'iExpt');
            obj.infoObj = getappdata(obj.hFigM,'infoObj');
            obj.isWebCam = isa(obj.infoObj.objIMAQ,'webcam');
            obj.devName = obj.infoObj.objIMAQ.Name;            
            
            % retrieves the source information fields
            if obj.isWebCam
                % device is a webcam
                obj.pInfo = obj.infoObj.objIMAQ.pInfo;
                
            else
                % device is a regular camera
                sObj = getselectedsource(obj.infoObj.objIMAQ);
                obj.pInfo = propinfo(sObj);
            end
            
            % retrieves the source information fields
            obj.cProps = obj.getDeviceProps(obj.pInfo);                        
            
            % -------------------------------------- %
            % --- OBJECT DIMENSIONS CALCULATIONS --- %
            % -------------------------------------- %
            
            % calculates the other object dimensions
            obj.hghtPanelG = 3*obj.dX + ...
                (3*obj.hghtPanelF + 2*obj.hghtPanelD);
            obj.widEditD = obj.widPanelD - (obj.dimBut + 2.5*obj.dX);             
            obj.widEditO = obj.widPanelD/2 - (obj.widTxtO + obj.dX/2);
            
            % calculates the figure dimensions
            obj.widFig = obj.widPanelO + 2*obj.dX;
            obj.hghtFig = obj.hghtPanelG + obj.hghtPanelC + 3*obj.dX;
            
            % calculates the button widths
            nBut = length(obj.bStrC);
            obj.widButC = (obj.widPanelO - ((2 + (nBut-1)/2)*obj.dX))/nBut;
            obj.hButC = cell(nBut,1);                        
            
        end
        
        % --- initialises the class fields
        function initClassObjects(obj)
            
            % makes the main window invisible
            setObjVisibility(obj.hFigM,0);            
            
            % deletes any previous GUIs
            hPrev = findall(0,'tag',obj.tagStr);
            if ~isempty(hPrev); delete(hPrev); end
            
            % other field retrieval
            [pNum,pENum] = deal(obj.cProps.Num,obj.cProps.ENum);
            [pOther,pSet] = deal(obj.cProps.Other,obj.cProps.Preset);
            obj.cPropsT = {pNum,pENum,pOther,pSet};                       
            
            % --------------------------- %
            % --- MAIN FIGURE OBJECTS --- %
            % --------------------------- %
            
            % creates the figure object
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % creates the figure object
            obj.hFig = createUIObj('figure','Position',fPos,...
                'tag',obj.tagStr,'MenuBar','None','Toolbar','None',...
                'Name',obj.figStr,'Resize','off','NumberTitle','off',...
                'Visible','off'); 
            
            % ---------------------------- %
            % --- CONTROL BUTTON PANEL --- %
            % ---------------------------- %       
            
            % button property fields
            bFcnC = {@obj.saveDefProps,@obj.resetDefProps,...
                     @obj.clearDefFiles,@obj.closeWindow};            
            
            % creates the control button panel
            pPosC = [obj.dX*[1,1],obj.widPanelO,obj.hghtPanelC];
            obj.hPanelC = createUIObj('panel',obj.hFig,...
                'Title','','Position',pPosC);
            
            % creates the control button objects
            for i = 1:length(obj.hButC) 
                lPosBC = (1+(i-1)/2)*obj.dX + (i-1)*obj.widButC;
                pPosBC = [lPosBC,obj.dX-2,obj.widButC,obj.dimBut];
                obj.hButC{i} = createUIObj('pushbutton',obj.hPanelC,...
                    'Position',pPosBC,'FontWeight','Bold',...
                    'FontSize',obj.fSzT,'String',obj.bStrC{i},...
                    'Callback',bFcnC{i});
            end
            
            % resets the figure close request function
            obj.hFig.CloseRequestFcn = bFcnC{end};
            cellfun(@(x)(setObjEnable(x,0)),obj.hButC(2));            
            
            % ------------------------ %
            % --- MAIN OUTER PANEL --- %
            % ---------------=-------- %
            
            % creates the tab-group panel
            yPosG = sum(pPosC([2,4])) + obj.dX;
            pPosG = [obj.dX,yPosG,obj.widPanelO,obj.hghtPanelG];
            obj.hPanelG = createUIObj('panel',obj.hFig,...
                'Title','','Position',pPosG);             

            % ------------------------------------ %
            % --- OTHER PROPERTY PANEL OBJECTS --- %
            % ------------------------------------ %

            % initialisations
            txtStrO = 'Inter-Video Duration Pause (s): ';
            
            % creates the panel object
            pPosO = [obj.dX*[1,1]/2,obj.widPanelD,obj.hghtPanelF];
            obj.hPanelO = createUIObj('panel',obj.hPanelG,...
                  'FontSize',obj.fSzH,'Title',obj.tStrO,...
                  'FontWeight','Bold','Units','Pixels','Position',pPosO);
              
            % creates the text label object
            yObjO = obj.dX/2;
            pPosTO = [obj.dX/2,yObjO+3,obj.widTxtO,obj.hghtTxt];
            createUIObj('text',obj.hPanelO,...
                'Position',pPosTO,'String',txtStrO,...
                'FontUnits','Pixels','FontWeight','Bold',...
                'HorizontalAlignment','Right','FontSize',obj.fSz);
            
            % creates the parameter editbox object
            lEditTE = sum(pPosTO([1,3]));
            pEVal = num2str(obj.cProps.Other.Value{1});
            pPosEO = [lEditTE,yObjO+1,obj.widEditO,obj.hghtEdit];
            createUIObj('edit',obj.hPanelO,'Position',pPosEO,...
                'FontSize',obj.fSz,'String',pEVal,...
                'Callback',@obj.editOtherPara);            
            
            % ---------------------------------------- %
            % --- NUMERICAL PROPERTY PANEL OBJECTS --- %
            % ---------------------------------------- %
            
            % initialisations
            tDataM = [pNum.Name,num2cell(pNum.isUse),pNum.Value,...
                      num2cell(cell2mat(pNum.List))];            
                  
            % creates the panel object
            yPosN = sum(pPosO([2,4])) + obj.dX/2;
            pPosN = [obj.dX/2,yPosN,obj.widPanelD,obj.hghtPanelD];
            obj.hPanelN = createUIObj('panel',obj.hPanelG,...
                  'FontSize',obj.fSzH,'Title',obj.tStrM,...
                  'FontWeight','Bold','Units','Pixels','Position',pPosN);
            
            % creates the table object
            widTableN = obj.widPanelD-2*obj.dX;
            pPosTN = [obj.dX*[1,1],widTableN,obj.hghtObj];
            obj.hTableN = createUIObj('table',obj.hPanelN,...
                'Data',[],'Position',pPosTN,'ColumnName',obj.cName,...
                'ColumnEditable',obj.cEdit,'ColumnFormat',obj.cForm,...
                'RowName',[],'ColumnWidth',obj.cWid,'Data',tDataM,...
                'CellEditCallback',{@obj.tableCellEdit,0},'tag','Num',...
                'BackgroundColor',obj.getBGCol(pNum.isUse));        
            autoResizeTableColumns(obj.hTableN);
                                    
            % ------------------------------------------ %
            % --- ENUMERATION PROPERTY PANEL OBJECTS --- %
            % ------------------------------------------ %            
            
            % initialisations
            tDataE = [pENum.Name,num2cell(pENum.isUse)];
            
            % creates the panel object
            yPosE = sum(pPosN([2,4])) + obj.dX/2;
            pPosE = [obj.dX/2,yPosE,obj.widPanelD,obj.hghtPanelD];            
            obj.hPanelE = createUIObj('panel',obj.hPanelG,...
                'FontUnits','Pixels','FontSize',obj.fSz+1,...
                'FontWeight','Bold','Units','Pixels','Position',pPosE,...
                'Title',obj.tStrE); 
            
            % creates the table object
            xi = 1:2;
            widTableE = sum(cell2mat(obj.cWid(xi))) + 2;
            pPosTE = [obj.dX*[1,1],widTableE,obj.hghtObj];
            obj.hTableE = createUIObj('table',obj.hPanelE,...
                'Position',pPosTE,'ColumnName',obj.cName(xi),...
                'ColumnEditable',obj.cEdit(xi),'ColumnFormat',obj.cForm(xi),...
                'RowName',[],'ColumnWidth',obj.cWid,'Data',tDataE,...
                'CellEditCallback',{@obj.tableCellEdit,1},'tag','ENum',...
                'CellSelectionCallback',@obj.tableCellSelect,...
                'BackgroundColor',obj.getBGCol(pENum.isUse));        
            autoResizeTableColumns(obj.hTableE);            
            
            % creates the listbox object  
            hList = obj.hghtObj - 2*obj.dX;
            lList = sum(pPosTE([1,3])) + obj.dX/2;
            wList = obj.widPanelD - (lList + obj.dX);            
            pPosLE = [lList,obj.dX,wList,hList];
            obj.hListE = createUIObj('listbox',obj.hPanelE,...
                'Max',2,'Enable','Inactive','String',[],'Value',[],...
                'Tag','hListENum','UserData',pENum.List,'Position',pPosLE);
            
            % creates the text label object
            yList = sum(pPosLE([2,4]));
            pPosLT = [lList,yList,wList,2*obj.dX];
            obj.hTxtE = createUIObj('text',obj.hPanelE,...
                'Position',pPosLT,'String',obj.setupPropStr('N/A'),...
                'FontUnits','Pixels','FontWeight','Bold',...
                'HorizontalAlignment','Left','tag','hTextProp',...
                'FontSize',obj.fSz);

            % ----------------------------------------- %
            % --- DEFAULT PRESET FILE PANEL OBJECTS --- %
            % ----------------------------------------- %     
            
            % creates the device preset file selection panel
            yPosP = sum(pPosE([2,4])) + obj.dX/2;            
            [obj.hPanelP,obj.hEditP,obj.hButP] = ...
                obj.setupFileSelectPanel('Preset',yPosP,obj.tStrP,'');
            
            % ------------------------------------------- %
            % --- DEFAULT PROPERTY FILE PANEL OBJECTS --- %
            % ------------------------------------------- %
            
            % field retrieval
            obj.getDeviceDefFileName();
            obj.dpFile0 = obj.dpFile;
            
            % creates the device property file selection panel
            yPosD = sum(obj.hPanelP.Position([2,4])) + obj.dX/2;
            [obj.hPanelD,obj.hEditD,obj.hButD] = ...
                obj.setupFileSelectPanel('Prop',yPosD,obj.tStrD,obj.dpFile);
            obj.hButD.TooltipString = obj.dpFile;

            % ----------------------------------- %            
            % --- DEFAULT PRESET FILE UPDATES --- %
            % ----------------------------------- %
            
            % updates the other class fields/objects
            psFile = obj.checkDevPresetFile;
            if ~isempty(psFile)
                A = importdata(psFile,'-mat');
                obj.resetDefDevicePropValues(A);                
                obj.cPropsT(1:2) = {obj.cProps.Num,obj.cProps.ENum};
            end
            
            % updates the other class fields/objects            
            obj.hEditP.String = sprintf('  %s',psFile);
            obj.hButP.TooltipString = psFile;
            obj.hEditF = [obj.hEditD,obj.hEditP];                      
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % resets the clear file buttons
            obj.resetClearButtonProps();
            obj.resetEnumerationTableSelect();   
            
            % stops the loadbar object
            obj.stopLoadBar();
            
            % centers and refreshes the figure
            centerfig(obj.hFig);
            refresh(obj.hFig);
            
            % makes the window visible
            setObjVisibility(obj.hFig,1);            
            
        end   
        
        % creates the device property file selection panel
        function [hPanel,hEdit,hBut] = ...
                setupFileSelectPanel(obj,pType,yPos,hStr,eTxt0)
                
            % initialisations
            cbFcn = {@obj.setDefFile,pType};           
            eTxt = sprintf('  %s',eTxt0);
            
            % creates the outer information panel
            pPosD = [obj.dX/2,yPos,obj.widPanelD,obj.hghtPanelF];
            hPanel = createUIObj('panel',obj.hPanelG,...
                'Title',hStr,'Units','Pixels','FontUnits','Pixels',...
                'Position',pPosD,'FontSize',obj.fSz+1,'FontWeight','bold');
           
            % creates the editbox object
            pPosE = [obj.dX*[1,1],obj.widEditD,obj.hghtEdit];
            hEdit = createUIObj('edit',hPanel,...
                'Position',pPosE,'FontSize',obj.fSz,'String',eTxt,...
                'HorizontalAlignment','Left','Enable','Inactive');
            
            % creates the button object
            lPosB = sum(pPosE([1,3])) + obj.dX/2;
            pPosB = [lPosB,obj.dX-1,obj.dimBut*[1,1]];
            hBut = createUIObj('pushbutton',hPanel,...
                'String','...','Position',pPosB,'FontWeight','Bold',...
                'ButtonPushedFcn',cbFcn,'FontSize',obj.fSz);                        
            
        end
        
        % ----------------------------------------- %
        % --- GENERAL OBJECT CALLBACK FUNCTIONS --- %
        % ----------------------------------------- %        
        
        % --- table cell select callback function
        function tableCellSelect(obj,hTable,evnt)
            
            if isempty(evnt.Indices)
                return
            end
            
            % field retrieval
            iRow = evnt.Indices(1);
            ValueE = obj.cProps.ENum.Value{iRow};
            
            % resets the device strings
            obj.hListE.String = obj.cProps.ENum.List{iRow};
            obj.hListE.Value = find(strcmp(obj.hListE.String,ValueE));
            obj.hTxtE.String = obj.setupPropStr(hTable.Data{iRow,1});
            
        end        
        
        % --- table cell editting callback function
        function tableCellEdit(obj,hTable,evnt,isENum)
            
            % field retrieval
            iRow = evnt.Indices(1);
            isUseS = evnt.NewData;
            
            % resets the table background color
            hTable.BackgroundColor(iRow,:) = 1 - (~isUseS*(1-obj.rejCol));
            
            % retrieves the device properties
            j = 1 + isENum;
            obj.cProps.(obj.pStr{j}).isUse(iRow) = isUseS;               
                
            % determines if a change has occured
            obj.updateChangeFlags()

        end        
        
        % --- default property file setting callback function
        function setDefFile(obj,~,evnt,pType,varargin)
            
            % retrieves the filename/mode based on type
            [dFile,fMode] = obj.getDefFilePath(pType);  
            
            % prompts the user for the 
            if isempty(evnt)
                % case is running the function directly
                fFile = varargin{1};
                
            else
                % case is running the function via callback
                [fName,fDir,fIndex] = uigetfile(fMode,'Pick A File',dFile);
                if fIndex == 0
                    % if the user cancelled, then exit
                    return
                    
                elseif ~obj.checkFileName(fDir,fName)
                    % if the file name is invalid, then exit
                    return                
                    
                else
                    % otherwise, set the new default file name
                    fFile = fullfile(fDir,fName);
                end
            end           
            
            % starts the loadbar
            obj.startLoadBar('Updating Device Properties...');
            
            % checks the selected file is valid (based on type)
            if strcmp(pType,'Preset')
                % case is the default preset file
                if obj.checkDevicePresetFile(fFile)
                    % resets the preset file field
                    obj.hEditP.String = sprintf('  %s',fFile);
                    obj.hButP.TooltipString = fFile;
                    
                    % updates the parameter struct
                    obj.cProps.Preset = fFile;
                    obj.updateChangeFlags();
                end
                    
            else
                % case is the default property file
                [dpData,ok] = obj.checkPropFile(fFile);

                % checks if the selected file is valid
                if ok
                    % if so, update property fields and default para file
                    obj.updatePropFields(dpData);
                    obj.updateDefFile(fFile);

                    % updates the parameter struct
                    obj.dpFile = fFile;
                    obj.cPropsT = {dpData.Num,dpData.ENum,dpData.Other,[]};
                    if isfield(dpData,'Preset')
                        obj.cPropsT{end} = dpData.Preset;
                    end                    
                    
                    % updates the change flags                       
                    obj.updateChangeFlags();
                    obj.resetClearButtonProps();
                    obj.isChange = false;
                end                

            end
            
            % starts the loadbar
            obj.stopLoadBar();            
            
        end        
        
        % --- other parameter editbox callback function
        function editOtherPara(obj,hEdit,~)
            
            % field retrieval
            nwLim = [1,30];
            nwVal = str2double(hEdit.String);
            
            % determines if the new value is valid
            if chkEditValue(nwVal,nwLim,1)
                % if so, update the parameter fields and other object
                obj.cProps.Other.Value{1} = nwVal;
                
                % determines if a change has occured
                obj.updateChangeFlags()                
                
            else
                % otherwise, revert back to the previous valid value
                hEdit.String = num2str(obj.cProps.Other.Value{1});
            end
            
        end
        
        % ----------------------------------------- %
        % --- CONTROL BUTTON CALLBACK FUNCTIONS --- %
        % ----------------------------------------- %          
        
        % --- default device property save callback function
        function saveDefProps(obj,~,~)

            % field retrieval
            [dFile0,fMode] = obj.getDefFilePath('Prop');
            
            % if no file exists            
            if exist(dFile0,'file') == 2
                dFile = dFile0;
            else
                dName = [obj.devName,fMode{1}(2:end)];
                dFile = fullfile(obj.psDir,dName);
            end
            
            % prompts the user for the 
            [fName,fDir,fIndex] = uiputfile(fMode,'Pick A File',dFile);
            if fIndex == 0
                % if the user cancelled, then exit
                return
                
            elseif ~obj.checkFileName(fDir,fName)
                % if the file name is invalid, then exit
                return
            end
            
            % saves the default property file
            Num = obj.cProps.Num;            
            ENum = obj.cProps.ENum;
            Other = obj.cProps.Other;
            Preset = obj.cProps.Preset;            
            
            % resets the other parameters
            obj.resetOtherPara();            

            % saves the data to file
            dName = obj.devName;
            fFile = fullfile(fDir,fName);            
            save(fFile,'dName','ENum','Num','Other','Preset');
            
            % checks to see if the default and final files are the same
            if strcmp(dFile0,fFile)
                % resets the property panel
                obj.setDefFile([],[],'Prop',fFile);
                
            else
                % prompts the user if they want to update the default file
                tStr = 'Update Property File?';
                qStr = 'Do you want to update the default property file?';
                uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
                
                % if so, then update the default file properties
                if strcmp(uChoice,'Yes')
                    obj.setDefFile([],[],'Prop',fFile);
                end
                
                % resets the enumeration parameter table selection
                obj.resetEnumerationTableSelect()
            end      
            
            % applies the default device properties
            applyDefaultDeviceProps(obj.infoObj,obj.devName);            
            
            % updates the change flags
            obj.dpFile0 = obj.dpFile;            
            obj.updateChangeFlags()            
        
        end        

        % --- default device property reset callback function
        function resetDefProps(obj,~,event)
            
            % initialisations
            isUpdate = false;
            pType = double(~isempty(event));
            
            %
            switch pType
                case 0
                    % case is resetting all automatically
                    isUpdate = obj.isChange;
                
                case 1
                    % case is updating the current device
                    tStr = 'Reset Device Properties';
                    qStr = ['Do you want to reset the properties ',...
                            'for the current device?'];
                    uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
                    
                    % sets the update indices based on the selection
                    isUpdate = strcmp(uChoice,'Yes');                    
            end
            
            % determines if updating required
            if isUpdate
                % if so, update property fields and default para file
                dpData = struct('Num',obj.cPropsT{1},...
                                'ENum',obj.cPropsT{2},...
                                'Other',obj.cPropsT{3},...
                                'Preset',obj.cPropsT{4});
                obj.updatePropFields(dpData);
                
                % resets the other fields
                obj.dpFile = obj.dpFile0;                
                obj.hEditD.String = obj.dpFile;
                obj.updateDefFile(obj.dpFile0);
                
                % determines if a change has occured
                obj.updateChangeFlags();
                obj.resetClearButtonProps();
                
                % applies the default properties (dependent on having a
                % preset file)
                hasF = obj.hasFileField();
                applyDefaultDeviceProps(obj.infoObj,obj.devName,~hasF(2));                
            end
            
        end

        % --- clears the default file fields
        function clearDefFiles(obj,~,~)
                        
            % initialisations
            tStr = 'Reset Default Files?';            
            hasFile = obj.hasFileField();
            
            % sets up the question dialog box message string
            if all(hasFile)
                % case is both fields are set
                mStr = ['Do you want to reset A) the property file, ',...
                        'B) the preset file, or C) both default files?'];
                bStr = {'Property File','Preset File','Both Files'};                    
                
            elseif hasFile(1)
                % case is the property file is set only
                mStr = ['Are you sure you want to reset the ',...
                        'default property file?'];
                bStr = {'Reset Property File'};
                
            else
                % case is the preset file is set only
                mStr = ['Are you sure you want to reset the ',...
                        'default preset file?'];                
                bStr = {'Reset Preset File'};                
            end            
                
            % prompts the user if they want to clear the fields
            uChoice = QuestDlgMulti([bStr,{'Cancel'}],mStr,tStr);            
            if strcmp(uChoice,'Cancel')
                % if the user cancelled, then exit
                return
            end            
            
            % updates the default device preset file (if chosen)
            if any(strContains(uChoice,{'Preset','Both'}))
                % resets the parameter struct/object fields
                obj.cProps.Preset = [];
                obj.hEditP.String = '';                
                
                % applies the default device properties
                applyDefaultDeviceProps(obj.infoObj,obj.devName,1);
                obj.resetDefDevicePropValues()
                obj.resetEnumerationTableSelect()
                obj.updateChangeFlags();                
            end
            
            % updates the default property file (if chosen)
            if any(strContains(uChoice,{'Property','Both'}))
                % resets the file fields
                obj.isChange = false;
                [obj.dpFile,obj.hEditD.String] = deal('');
                obj.updateDefFile('');
            end            
            
            % resets the update button properties
            obj.resetClearButtonProps();
            
        end
        
        % --- close window callback function
        function closeWindow(obj,~,~)
            
            if obj.isChange
                % sets up the question string
                tStr = 'Confirm Close Window';
                qStr = ['There are changes that have not been saved. ',...
                        'Do you still want to continue?'];
                
                % prompts the use if they want to continue closing
                uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
                if strcmp(uChoice,'Yes')
                    % if so, reset the original properties
                    obj.resetDefProps([],[]);
                    
                else
                    % if the user cancelled, then exit
                    return
                end
                
            end
            
            % stops the loadbar object
            obj.stopLoadBar(1);            
            
            % deletes the figure
            delete(obj.hFig);            
            setObjVisibility(obj.hFigM,1);

        end
        
        % ---------------------------------------- %
        % --- DEFAULT PARAMETER FILE FUNCTIONS --- %
        % ---------------------------------------- %
        
        % --- updates the default property file
        function updateDefFile(obj,fFile)
            
            % updates the editbox string
            obj.hEditD.String = sprintf('  %s',fFile);
            obj.hButD.TooltipString = fFile;
            obj.dpFile = fFile;
            
            % updates the default property file
            obj.updateDefPropFile(fFile);
            obj.isChange = false;
            
        end
        
        % --- updates the property fields
        function updatePropFields(obj,dpData)
            
            % updates the enumeration parameter table properties
            obj.hTableE.Data(:,2) = num2cell(dpData.ENum.isUse);
            obj.hTableE.BackgroundColor = obj.getBGCol(dpData.ENum.isUse);
            
            % updates the numerical parameter table properties
            obj.hTableN.Data(:,2) = num2cell(dpData.Num.isUse);
            obj.hTableN.BackgroundColor = obj.getBGCol(dpData.Num.isUse);
            
            % resets the editbox values
            hEdit = findall(obj.hPanelO,'Style','Edit');
            for i = 1:length(hEdit)
                hEdit.String = num2str(dpData.Other.Value{i});                
            end
            
            % resets the preset file string
            if isfield(dpData,'Preset')
                obj.hEditP.String = sprintf('  %s',dpData.Preset);
                obj.cProps.Preset = dpData.Preset;
            else
                [obj.hEditP.String,obj.cProps.Preset] = deal([]);
            end
            
            % saves the default property file
            obj.cProps.Other = dpData.Other;            
            obj.cProps.Num.isUse = dpData.Num.isUse;
            obj.cProps.ENum.isUse = dpData.ENum.isUse;                        
            
            % resets the enumeration parameter table selection
            obj.resetOtherPara();            
            obj.resetDefDevicePropValues(dpData);
            obj.resetEnumerationTableSelect();            
            
        end
        
        % --- checks the property file matches the device
        function [dpData,ok] = checkPropFile(obj,fFile)
            
            % initialisations
            dpData = importdata(fFile,'-mat');
            ok = strcmp(obj.devName,dpData.dName);
            
            % if there was a mismatch, then output an error to screen
            if ~ok
                % stops the loadbar
                obj.stopLoadBar();                
                
                % outputs the error message to screen
                eStr = sprintf(['There is a discrepancy between the ',...
                    'selected device and property file:\n\n',...
                    ' %s Current Device: %s\n %s Selected File: %s\n\n',...
                    'Reselect or resave the correct property file'],...
                    obj.arrChr,obj.devName,obj.arrChr,dpData.dName);
                waitfor(msgbox(eStr,'Property File Error','modal'))
            end
            
        end
        
        % --- updates the default property file data
        function updateDefPropFile(obj,defFile)
            
            % field retrieval
            [dName,dFile] = deal({obj.devName},{defFile});
            
            if exist(obj.paraFile,'file')
                % if so, then append the data to file
                dInfo = load(obj.paraFile);
                
                % determines if there are any existing matches
                ii = strcmp(dInfo.dName,dName{1});
                if any(ii)
                    % if so, then reset the default file
                    if isempty(defFile)
                        % case is an empty file name (so remove device)
                        dInfo.dName = dInfo.dName(~ii);
                        dInfo.dFile = dInfo.dFile(~ii);
                    else
                        % otherwise, reset the default file name
                        dInfo.dFile{ii} = defFile;
                    end
                else
                    % otherwise, append to the list
                    dInfo.dName = [dInfo.dName(:);dName(1)];
                    dInfo.dFile = [dInfo.dFile(:);{defFile}];
                end
                
                % re-saves the parameter file
                save(obj.paraFile,'-struct','dInfo');
                
            else
                % saves the parameter file
                save(obj.paraFile,'dName','dFile');
            end
            
        end
        
        % --- resets the other parameter fields ino the main gui window
        function resetOtherPara(obj)
            
            obj.iExpt.Timing.Tp = obj.cProps.Other.Value{1};
            setappdata(obj.hFigM,'iExpt',obj.iExpt);
            
        end
        
        % --- resets the default device properties
        function resetDefDevicePropValues(obj,A)
                        
            % loads the preset file
            if ~exist('A','var')
                A = obj.infoObj.pInfo0;
                
            elseif isfield(A,'Num')
                % resets the values into cell arrays
                fNames = [A.Num.Name;A.ENum.Name];
                pVal = [A.Num.Value;A.ENum.Value];
                
                % resets the data struct
                A = struct('fldNames',[],'pVal',[]);
                [A.fldNames,A.pVal] = deal(fNames,pVal);
            end
            
            % determines the matching enumeration parameters
            [~,iE] = intersect(A.fldNames,obj.cProps.ENum.Name);
            obj.cProps.ENum.Value = A.pVal(iE);
            obj.resetEnumerationParaValues();
            
            % determines the matching numerical parameters
            [~,iN] = intersect(A.fldNames,obj.cProps.Num.Name);
            obj.cProps.Num.Value = A.pVal(iN);
            obj.hTableN.Data(:,3) = A.pVal(iN);
            
        end
        
        % --------------------------------- %
        % --- CAMERA PROPERTY FUNCTIONS --- %
        % --------------------------------- %        
        
        % --- retrieves the device properties
        function cP = getDeviceProps(obj,pInfoP,useFeas)

            % sets the default input arguments
            if ~exist('useFeas','var'); useFeas = true; end

            % memory allocation
            cP = struct('ENum',[],'Num',[],'Other',[],'Preset','');

            % retrieves the parameter fields
            pStrP = fieldnames(pInfoP);
            pType = cellfun(@(x)(pInfoP.(x).Type),pStrP,'un',0);
            pConst = cellfun(@(x)(pInfoP.(x).Constraint),pStrP,'un',0);
            pReadOnly = cellfun(@(x)(pInfoP.(x).ReadOnly),pStrP,'un',0);
            pAccess = cellfun(@(x)(pInfoP.(x).Accessible),pStrP);

            % determines feasible props (accessible and not read only)
            isF = pAccess & ~(strcmpi(pReadOnly,'always') | ...
                              strcmpi(pReadOnly,'currently'));

            % determines the enumeration/numeration properties
            isE = strcmp(pType,'string') & strcmp(pConst,'enum') & isF;
            isN = (strcmp(pType,'double') | strcmp(pType,'integer')) & isF;
            
            % ------------------------------ %
            % --- ENUMERATION PARAMETERS --- %
            % ------------------------------ %

            % sub-struct memory allocation
            cP.ENum = struct(...
                'Name',[],'Value',[],'List',[],'Count',NaN,'isUse',[]);
            
            % sets the device property fields
            EP = pStrP(isE);
            List0 = cellfun(@(x)(pInfoP.(x).ConstraintValue),EP,'un',0);
            Value0 = cellfun(@(x)(pInfoP.(x).DefaultValue),EP,'un',0);

            if useFeas
                iiEP = cellfun('length',List0) > 1;
            else
                iiEP = true(size(List0));
            end

            % removes any parameters the infeasible paramters
            [cP.ENum.Name,cP.ENum.Count] = deal(EP(iiEP),sum(iiEP));
            [cP.ENum.List,cP.ENum.Value] = deal(List0(iiEP),Value0(iiEP));            

            % sets the usage flags
            cP.ENum.isUse = obj.getPropUseFlags(cP.ENum,true);

            % ----------------------------- %
            % --- NUMERATION PARAMETERS --- %
            % ----------------------------- %
            
            % sub-struct memory allocation
            cP.Num = struct(...
                'Name',[],'Value',[],'List',[],'Count',NaN,'isUse',[]);

            % sets the device property fields
            NP = pStrP(isN);
            Value = cellfun(@(x)(pInfoP.(x).DefaultValue),NP,'un',0);
            List = cellfun(@(x)(pInfoP.(x).ConstraintValue),NP,'un',0);

            % removes any infeasible parameters
            iiNF = ~(cellfun('isempty',Value) | cellfun('isempty',List));
            if exist('pS','var')
                iiNF = iiNF & cellfun(@(x)(~any(strcmp(pS,x))),NP);
            end

            % removes any empty list/value fields
            [cP.Num.Value,cP.Num.List] = deal(Value(iiNF),List(iiNF));
            [cP.Num.Count,cP.Num.Name] = deal(sum(iiNF),NP(iiNF));

            % sets the usage flags
            cP.Num.isUse = obj.getPropUseFlags(cP.Num,false);

            % ------------------------ %
            % --- OTHER PARAMETERS --- %
            % ------------------------ %
            
            % sub-struct memory allocation
            cP.Other = struct(...
                'Name',[],'Value',[],'List',[],'Count',NaN,'isUse',[]);
            
            % sets the field values
            cP.Other.Count = 1;
            cP.Other.isUse = true;            
            cP.Other.Value = {obj.iExpt.Timing.Tp};            
            cP.Other.Name = 'Inter-Video Pause Duration (s)';
            
        end        
        
        % --- retrieves the property use flags
        function isUse = getPropUseFlags(obj,pProp,isENum)

            % memory allocation
            isUse = true(pProp.Count,1);
            
            % determines if the program default file exists
            if exist(obj.paraFile,'file')
                % if so, determine if there is a match for the device
                dpData = load(obj.paraFile);
                ii = strcmp(dpData.dName,obj.devName);
                if ~any(ii)
                    % if there are no matches, then exit
                    return

                elseif exist(dpData.dFile{ii},'file')
                    % if so, and the file exists, then load usage flags
                    pData = importdata(dpData.dFile{ii},'-mat');
                    if isENum
                        [~,iB] = intersect(pData.ENum.Name,pProp.Name);
                        isUse = pData.ENum.isUse(iB);
                    else
                        [~,iB] = intersect(pData.Num.Name,pProp.Name);
                        isUse = pData.Num.isUse(iB);
                    end

                else
                    % otherwise, remove the file
                    dpData.dName = dpData.dName(~ii);
                    dpData.dFile = dpData.dFile(~ii);
                    save(obj.paraFile,'-struct','dpData');
                end
            end

        end        
        
        % --- checks the preset file
        function ok = checkDevicePresetFile(obj,psFile)
            
            % data file loading
            ok = true;
            A = importdata(psFile);
            
            % determines the overlapping numerical parameters
            [~,iiN] = intersect(A.fldNames,obj.cProps.Num.Name);
            if length(iiN) ~= length(obj.cProps.Num.Name)
                % otherwise, flag a false value and exit
                [pStrE,ok] = deal('Numerical',false);
            end
            
            % determines the overlapping enumeration parameters
            [~,iiE] = intersect(A.fldNames,obj.cProps.ENum.Name);
            if length(iiE) ~= length(obj.cProps.ENum.Name)
                % otherwise, flag a false value
                [pStrE,ok] = deal('Enumeration',false);
            end

            if ok
                % if feasible, then update the fields
                obj.cProps.Num.Value = A.pVal(iiN);
                obj.cProps.ENum.Value = A.pVal(iiE);
                
                % resets the numerical parameter table data
                obj.hTableN.Data(:,3) = obj.cProps.Num.Value;
                
                % resets the enumeration parameter table selection
                obj.resetEnumerationParaValues();
                obj.resetEnumerationTableSelect();
                
            else
                % stops the loadbar
                obj.stopLoadBar();                
                
                % otherwise output an error message to screen
                tStr = 'Incompatible Preset File';
                eStr = sprintf(['The selected device preset file %s ',...
                                'parameters are incompatible with ',...
                                'the current recording device'],pStrE);
                waitfor(msgbox(eStr,tStr,'modal'));                
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
            
            pause(0.05);
            
        end
        
        % --- starts the loadbar object
        function stopLoadBar(obj,varargin)
            
            if isempty(varargin)
                setObjVisibility(obj.hLoad.Control,0);
            elseif ~isempty(obj.hLoad)
                delete(obj.hLoad.Control);
            end
            
        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- sets up the background colour array
        function bgCol = getBGCol(obj,isUse)
            
            bgCol = ones(length(isUse),3);
            bgCol(~isUse,:) = obj.rejCol;
            
        end        
        
        % --- retrieves the default file path
        function [dFile,fMode] = getDefFilePath(obj,pType)
            
            % field retrieval
            switch pType
                case 'Prop'
                    % case is the default property file
                    hEdit = obj.hEditD;
                    [dFile,fMode] = deal(obj.psDir,obj.fModeD);
                    
                case 'Preset'
                    % case is the default preset file
                    hEdit = obj.hEditP;                    
                    [dFile,fMode] = deal(obj.psDir,obj.fModeP);
            end
            
            % retrieves the current output file
            eStr = strtrim(hEdit.String);
            if ~isempty(eStr)
                if exist(eStr,'file')
                    dFile = eStr;
                end
            end
            
        end     
        
        % --- retrieves the default property file name for 
        function getDeviceDefFileName(obj)
            
            % initialisations
            obj.dpFile = '';
            
            % determines if the default property file exists
            if exist(obj.paraFile,'file')
                % if so, then load the data
                dpData = load(obj.paraFile);
                ii = strcmp(dpData.dName,obj.devName);                
                if any(ii)
                    % case is there is a matching file
                    if exist(dpData.dFile{ii},'file')
                        % if the file exists, then return the filename
                        obj.dpFile = dpData.dFile{ii};
                        
                    else
                        % otherwise, remove the name from the file
                        dpData.dName = dpData.dName(~ii);
                        dpData.dFile = dpData.dFile(~ii);
                        save(obj.paraFile,'-struct',dpData);
                    end
                end
            end
                
        end                
        
        % --- checks the preset file, pSet, exists and is valid
        function psFile = checkDevPresetFile(obj)
            
            % initialisations
            psFile = '';
            
            % if no preset file exists, then exit the function
            if isempty(obj.dpFile)
                return
            end
            
            % loads the device default property file
            A = importdata(obj.dpFile,'-mat');
            if ~isfield(A,'Preset')
                return
            end
            
            % determines if the preset file exists
            psFile = A.Preset;            
            if exist(psFile,'file')                
                % if so, update the parameter struct fields
                [obj.cProps.Preset,obj.cPropsT{4}] = deal(psFile);
                
            else
                % otherwise, outputs an error message to screen
                tStr = 'Missing Device Preset File';
                eStr = sprintf(['The following device preset file is ',...
                    'missing:\n\n  %s %s\n\nYou will need to reset ',...
                    'path to this device preset file.'],obj.arrChr,psFile);
                waitfor(msgbox(eStr,tStr,'modal'))
                        
                % resets the device preset file fields and exits
                [obj.cProps.Preset,obj.cPropsT{4},psFile] = deal(''); 
                return
            end
            
        end                
        
        % --- updates the change flags (based on the parameter change)
        function updateChangeFlags(obj)
            
            % memory allocation
            isChangeP = false(1,4);
            
            % retrieves the original/current use flags            
            for i = 1:length(isChangeP)
                switch i
                    case {1,2}
                        % case is the numeric/enumeration parameters
                        isUse0 = obj.cPropsT{i}.isUse;
                        isUseF = obj.cProps.(obj.pStr{i}).isUse;
                        isChangeP(i) = ~isequal(isUseF,isUse0);
                        
                    case 3
                        % case is the other parameters
                        Other0 = obj.cPropsT{i};
                        OtherF = obj.cProps.Other;
                        isChangeP(i) = ~isequal(Other0,OtherF);
                        
                    case 4
                        % case is the preset file
                        psFile0 = obj.cPropsT{i};
                        psFileF = obj.cProps.Preset;
                        isChangeP(i) = ~isequal(psFile0,psFileF);
                end
            end
            
            % determines if a difference between original/new flags
            obj.isChange = any(isChangeP) || ~strcmp(obj.dpFile,obj.dpFile0);
            setObjEnable(obj.hButC{2},obj.isChange);
            
        end        
        
        % --- resets the clear file buttons
        function resetClearButtonProps(obj)
                       
            setObjEnable(obj.hButC{3},any(obj.hasFileField()));
            
        end
        
        % --- resets the enumeration table selection
        function resetEnumerationTableSelect(obj)
            
            % sets the table selection
            setTableSelection(obj.hTableE,0,0)
            obj.tableCellSelect(obj.hTableE,struct('Indices',[1,1]));
           
        end        

        % --- resets the enumeration parameter values (for specific fields)
        function resetEnumerationParaValues(obj)

            % parameter specific updates
            for i = 1:length(obj.cProps.ENum.Name)
                switch obj.cProps.ENum.Name{i}
                    case 'BacklightCompensation'
                        if isnumeric(obj.cProps.ENum.Value{i})
                            eStr = {'off','on'};
                            obj.cProps.ENum.Value{i} = ...
                                eStr{1+obj.cProps.ENum.Value{i}};
                        end
                end
            end

        end        
        
        % --- determines if the default field fields are empty or not
        function hasField = hasFileField(obj)
            
            hasField = arrayfun(@(x)(~isempty(strtrim(x.String))),obj.hEditF);            
            
        end                
        
        % --- determines if the new .dpf file name is valid
        function isOK = checkFileName(obj,fDir,fName)
            
            % initialisations
            isOK = true;
            
            % otherwise, check the selected file is not already within
            % the default property file list
            if exist(obj.paraFile,'file')
                A = load(obj.paraFile);
                fFile = fullfile(fDir,fName);
                
            else
                % if there is no file, then exit
                return
            end
                
            % determines if the new file is within the file list
            isF = strcmp(A.dFile,fFile);
            if any(isF)
                % if so, then determine if current device is file list
                [isD,isOK] = deal(strcmp(A.dName,obj.devName),false);
                if any(isD)
                    % if so, set the ok flag if the current file is set
                    % for the current device
                    A = importdata(A.dFile{isD},'-mat');
                    isOK = isequal(obj.devName,A.dName);
                end
                
                % if the file name exists elsewhere, then out a message
                % to screen and exit the function
                if ~isOK
                    % outputs an error message to screen
                    tStr = 'Invalid Default File';
                    eStr = sprintf(['The selected default ',...
                        'file has already been set for ',...
                        'another device:\n\n %s File Name: %s\n ',...
                        '%s Device Name: %s\n\nSelect another ',...
                        'default property file.'],...
                        obj.arrChr,fName,obj.arrChr,A.dName{isF});
                    waitfor(msgbox(eStr,tStr,'modal'))
                end
            end
        end
        
    end
    
    % static class methods
    methods (Static)

        function pStrS = setupPropStr(pStr)
            
            pStrS = sprintf('%s',pStr);
        
        end       
        
    end    
    
end
        