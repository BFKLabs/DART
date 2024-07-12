classdef DefDeviceProps < handle
    
    % class properties
    properties
        
        % input argument fields
        hFigM
        
        % object handle fields
        hFig
        hPanelG
        
        % enumeration property fields
        hPanelE
        hTableE
        hListE
        hTxtE
        
        % numerical property fields        
        hPanelN
        hTableN
        
        % device property file
        hPanelD
        hEditD
        hButD
        
        % control button panel
        hPanelC
        hButC
        
        % fixed object dimensions
        dX = 10;
        hghtObj = 112;
        hghtPanelG = 365;
        hghtPanelC = 40;
        hghtPanelD = 145;
        hghtPanelF = 55;
        widPanelO = 520;
        widPanelD = 505;
        dimBut = 25;
        hghtRow = 25;
        hghtEdit = 22;
        
        % calculated object dimensions
        widFig
        hghtFig
        widButC
        
        % device property fields
        pInfo
        devName
        cProps
        cPropsT
        infoObj
        infoSrc                
        
        % parameter file fields
        psDir
        paraDir
        paraFile
        
        % table fields
        arrChr = char(8594);
        pStr = {'Num','ENum'};
        cWid = {228,35,71,72,72};
        cEdit = [false,true,false(1,3)];
        cName = {'Property','Use?','Value','Min','Max'};
        cForm = {'char','logical','char','char','char'};
        fMode = {'*.dpf','Default Property File (*.dpf)'};
        
        % boolean class fields
        isChange        
        isWebCam        
        
        % fixed scalar class fields
        iSelT = 1;
        fSzH = 13;
        fSzT = 12;
        fSz = 10 + 2/3;
        rejCol = 0.8;
        
        % fixed text class fields
        tagStr = 'figDefProps';
        figStr = 'Default Device Properties';
        bStrC = {'Save','Reset','Close'};
        
    end
   
    % class methods
    methods
        
        % --- class constructor
        function obj = DefDeviceProps(hFigM)

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
            
            % retrieves the data struct/class objects
            obj.psDir = iProg.CamPara;
            obj.infoObj = getappdata(obj.hFigM,'infoObj');
            obj.isWebCam = isa(obj.infoObj.objIMAQ,'webcam');
            obj.paraFile = getParaFileName('DefProps.mat');
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
            
            % deletes any previous GUIs
            hPrev = findall(0,'tag',obj.tagStr);
            if ~isempty(hPrev); delete(hPrev); end
            
            % other field retrieval
            [pNum,pENum] = deal(obj.cProps.Num,obj.cProps.ENum);
            obj.cPropsT = {pNum,pENum};
            
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
            bFcnC = {@obj.saveDefProps,...
                     @obj.resetDefProps,...
                     @obj.closeWindow};            
            
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
            
            % ---------------------------------------- %
            % --- NUMERICAL PROPERTY PANEL OBJECTS --- %
            % ---------------------------------------- %
            
            % initialisations
            tStrM = 'NUMERICAL DEVICE PROPERTIES';
            tDataM = [pNum.Name,num2cell(pNum.isUse),pNum.Value,...
                      num2cell(cell2mat(pNum.List))];
            
            % creates the panel object
            pPosN = [obj.dX*[1,1]/2,obj.widPanelD,obj.hghtPanelD];            
            obj.hPanelN = createUIObj('panel',obj.hPanelG,...
                'FontUnits','Pixels','FontSize',obj.fSzH,'Title',tStrM,...
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
            tStrE = 'ENUMERATION DEVICE PROPERTIES';
            tDataE = [pENum.Name,num2cell(pENum.isUse)];
            
            % creates the panel object
            yPosE = sum(pPosN([2,4])) + obj.dX/2;
            pPosE = [obj.dX/2,yPosE,obj.widPanelD,obj.hghtPanelD];            
            obj.hPanelE = createUIObj('panel',obj.hPanelG,...
                'FontUnits','Pixels','FontSize',obj.fSz+1,...
                'FontWeight','Bold','Units','Pixels','Position',pPosE,...
                'Title',tStrE); 
            
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
            
            % ------------------------------------------- %
            % --- DEFAULT PROPERTY FILE PANEL OBJECTS --- %
            % ------------------------------------------- %
            
            % creates the figure object
            tStrD = 'DEFAULT DEVICE PROPERTY FILE';   
            dpFile = obj.getDeviceDefFileName();
            
            % creates the outer information panel
            yPosD = sum(pPosE([2,4])) + obj.dX/2;
            pPosD = [obj.dX/2,yPosD,obj.widPanelD,obj.hghtPanelF];
            obj.hPanelD = createUIObj('panel',obj.hPanelG,...
                'Title',tStrD,'Units','Pixels','FontUnits','Pixels',...
                'Position',pPosD,'FontSize',obj.fSz+1,...
                'FontWeight','bold');
           
            % creates the editbox object
            wEdit = obj.widPanelD - (obj.dimBut + 2.5*obj.dX);
            pPosE = [obj.dX*[1,1],wEdit,obj.hghtEdit];
            obj.hEditD = createUIObj('edit',obj.hPanelD,...
                'Position',pPosE,'FontSize',obj.fSz,'String',dpFile,...
                'HorizontalAlignment','Left','Enable','Inactive',...
                'Tag','hDefFile');
            
            % creates the button object
            lPosB = sum(pPosE([1,3])) + obj.dX/2;
            pPosB = [lPosB,obj.dX-1,obj.dimBut*[1,1]];
            obj.hButD = createUIObj('pushbutton',obj.hPanelD,...
                'String','...','Position',pPosB,'FontWeight','Bold',...
                'ButtonPushedFcn',@obj.setDefFile,'FontSize',obj.fSz);            
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % centers and refreshes the figure
            centerfig(obj.hFig);
            refresh(obj.hFig);
            
            % makes the window visible
            setObjVisibility(obj.hFig,1);            
            
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
        function setDefFile(obj,~,evnt,varargin)
            
            % field retrieval
            dFile = obj.getDefFilePath();                
            
            % prompts the user for the 
            if isempty(evnt)
                % case is running the function directly
                fFile = varargin{1};
                
            else
                % case is running the function via callback
                [fName,fDir,fIndex] = uigetfile(...
                    obj.fMode,'Pick A File',dFile);
                if fIndex == 0
                    return
                end
                
                % prompts the user for the new default directory
                fFile = fullfile(fDir,fName);
            end           
            
            % checks if the selected file is valid
            [dpData,ok] = obj.checkPropFile(fFile);
            if ok
                % if so, update property fields and default para file
                obj.updatePropFields(dpData);
                obj.updateDefFile(obj.hEditD,fFile);
                
                % determines if a change has occured
                obj.cPropsT = {dpData.Num,dpData.ENum};
                obj.updateChangeFlags();
            end            
            
        end        
        
        % ----------------------------------------- %
        % --- CONTROL BUTTON CALLBACK FUNCTIONS --- %
        % ----------------------------------------- %          
        
        % --- default device property save callback function
        function saveDefProps(obj,~,~)

            % field retrieval
            dFile = obj.getDefFilePath();
            
            % prompts the user for the 
            [fName,fDir,fIndex] = uiputfile(obj.fMode,'Pick A File',dFile);
            if fIndex == 0
                return
            end
            
            % saves the default property file
            Num = obj.cProps.Num;            
            ENum = obj.cProps.ENum;

            % saves the data to file
            dName = obj.devName;
            fFile = fullfile(fDir,fName);
            save(fFile,'dName','ENum','Num');
            
            % checks to see if the default and final files are the same
            if strcmp(dFile,fFile)
                % resets the property panel
                obj.setDefFile([],[],fFile);
                
            else
                % prompts the user if they want to update the default file
                tStr = 'Update Property File?';
                qStr = 'Do you want to update the default property file?';
                uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
                
                % if so, then update the default file properties
                if strcmp(uChoice,'Yes')
                    obj.setDefFile([],[],fFile);
                end
            end      
            
            % updates the change flags
            obj.updateChangeFlags()            
        
        end        

        % --- default device property reset callback function
        function resetDefProps(obj,~,event)

            % initialisations
            isUpdate = false;

            % determines if the current tab has been reset
            if isempty(event)
                % case is force resetting all changed
                pType = 0;
                
            elseif obj.isChange
                % case is the current tab can be reset
                pType = 1;                
            end
            
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
                dpData = struct('Num',obj.cPropsT{1},'ENum',obj.cPropsT{2});
                obj.updatePropFields(dpData);
                
                % determines if a change has occured
                obj.updateChangeFlags();
            end
            
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
            
            % deletes the figure
            delete(obj.hFig);

        end
        
        % ---------------------------------------- %
        % --- DEFAULT PARAMETER FILE FUNCTIONS --- %
        % ---------------------------------------- %
        
        % --- updates the default property file
        function updateDefFile(obj,hEdit,fFile)
            
            % updates the editbox string
            hEdit.String = sprintf('  %s',fFile);
            
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
            
            % saves the default property file
            obj.cProps.Num.isUse = dpData.Num.isUse;
            obj.cProps.ENum.isUse = dpData.ENum.isUse;
            
            % resets the other objects
            obj.hTxtE.String = 'N/A';            
            [obj.hListE.String,obj.hListE.Value] = deal([]);
            
        end
        
        % --- checks the property file matches the device
        function [dpData,ok] = checkPropFile(obj,fFile)
            
            % initialisations
            dpData = importdata(fFile,'-mat');
            ok = strcmp(obj.devName,dpData.dName);
            
            % if there was a mismatch, then output an error to screen
            if ~ok
                % outputs the error message to screen
                eStr = sprintf(['There is a discrepancy between the ',...
                    'selected device tab and property file:\n\n',...
                    ' %s Current Tab: %s\n %s Selected File: %s\n\n',...
                    'Either reselect the correct property file, or ',...
                    'select the correct tab'],obj.arrChr,...
                    obj.devName,obj.arrChr,dpData.dName);
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
                    dInfo.dFile{ii} = defFile;
                else
                    % otherwise, append to the list
                    dInfo.dName{end+1} = dName{1};
                    dInfo.dFile{end+1} = defFile;
                end
                
                % re-saves the parameter file
                save(obj.paraFile,'-struct','dInfo');
                
            else
                % saves the parameter file
                save(obj.paraFile,'dName','dFile');
            end
            
        end
        
        % --------------------------------- %
        % --- CAMERA PROPERTY FUNCTIONS --- %
        % --------------------------------- %        
        
        % --- retrieves the device properties
        function cP = getDeviceProps(obj,pInfoP,useFeas)

            % sets the default input arguments
            if ~exist('useFeas','var'); useFeas = true; end

            % memory allocation
            cP = struct('ENum',[],'Num',[]);

            % sub-struct memory allocation
            cP.Num = struct(...
                'Name',[],'Value',[],'List',[],'Count',NaN,'isUse',[]);
            cP.ENum = struct(...
                'Name',[],'Value',[],'List',[],'Count',NaN,'isUse',[]);

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
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- sets up the background colour array
        function bgCol = getBGCol(obj,isUse)
            
            bgCol = ones(length(isUse),3);
            bgCol(~isUse,:) = obj.rejCol;
            
        end        
        
        % --- retrieves the default file path
        function dFile = getDefFilePath(obj)
            
            % field retrieval
            dFile = obj.psDir;
            
            % retrieves the current output file
            eStr = strtrim(obj.hEditD.String);
            if ~isempty(eStr)
                if exist(eStr,'file')
                    dFile = eStr;
                end
            end
            
        end     
        
        % --- retrieves the default property file name for 
        function dpFile = getDeviceDefFileName(obj)
            
            % initialisations
            dpFile = '';
            
            % determines if the default property file exists
            if exist(obj.paraFile,'file')
                % if so, then load the data
                dpData = load(obj.paraFile);
                ii = strcmp(dpData.dName,obj.devName);                
                if any(ii)
                    % case is there is a matching file
                    if exist(dpData.dFile{ii},'file')
                        % if the file exists, then return the filename
                        dpFile = dpData.dFile{ii};
                        
                    else
                        % otherwise, remove the name from the file
                        dpData.dName = dpData.dName(~ii);
                        dpData.dFile = dpData.dFile(~ii);
                        save(obj.paraFile,'-struct',dpData);
                    end
                end
            end
                
        end        
        
        % --- updates the change flags (based on the parameter change)
        function updateChangeFlags(obj)
            
            % memory allocation
            isChangeP = false(1,2);
            
            % retrieves the original/current use flags            
            for i = 1:length(isChangeP)
                isUse0 = obj.cPropsT{i}.isUse;
                isUseF = obj.cProps.(obj.pStr{i}).isUse;
                isChangeP(i) = ~isequal(isUseF,isUse0);
            end
            
            % determines if a difference between original/new flags
            obj.isChange = any(isChangeP);
            setObjEnable(obj.hButC{2},obj.isChange);
            
        end        
        
    end
    
    % static class methods
    methods (Static)

        function pStrS = setupPropStr(pStr)
            
            pStrS = sprintf('%s',pStr);
        
        end
        
    end    
    
end
        