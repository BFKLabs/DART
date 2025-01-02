classdef SerialNames < handle
    
    % class properties
    properties
        
        % input arguments
        hFigM
        
        % main class objects
        hFig
        
        % serial device panel objects
        hPanelD
        hTableD
        jTableD
        hEditD
        
        % control button panel objects
        hPanelC
        hButC
        
        % fixed dimension fields
        dX = 10;     
        hghtBut = 25;
        hghtHdr = 20;
        hghtRow = 25;
        widPanel = 380;
        widLblD = 120;
        
        % calculated dimension fields
        widFig
        hghtFig
        hghtPanelD
        hghtPanelC
        widTableD
        hghtTableD
        widButC
        
        % other important class fields
        sDevT
        
        % static class fields
        nDev
        nButC = 3;
        fSzH = 13;
        fSzL = 12;
        fSz = 10 + 2/3;
        
        % static string fields
        tagStr = 'figDeviceNames';
        figName = 'Serial Device Search Names';
        tHdrD = 'SERIAL DEVICE SEARCH LIST';
        baseDev = 'STMicroelectronics STLink Virtual COM Port';
                    
    end
    
    % class methods
    methods
        
        % --- class constuctor
        function obj = SerialNames(hFigM)
            
            % sets the input arguments
            obj.hFigM = hFigM;
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initClassObjects();            
            
            % clears the output object (if not required)
            if (nargout == 0) && ~isdeployed
                clear obj
            end            
            
        end        
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % retrieves
            A = load(getParaFileName('ProgPara.mat'));
            obj.sDevT = A.sDev;
            
            % field initialisation
            obj.nDev = length(obj.sDevT);
            
            % ------------------------------------- %
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- %

            % calculates the table dimensions
            obj.widTableD = obj.widPanel - 2*obj.dX;
            obj.hghtTableD = calcTableHeight(max(3,obj.nDev));          
            
            % calculates the panel dimensions
            obj.hghtPanelD = 1.5*obj.dX + ...
                obj.hghtRow + obj.hghtTableD + obj.hghtHdr;
            obj.hghtPanelC = obj.dX + obj.hghtRow;
            
            % figure dimension calculations
            obj.widFig = 2*obj.dX + obj.widPanel;
            obj.hghtFig = 3*obj.dX + obj.hghtPanelC + obj.hghtPanelD;

            % other object dimension calculations
            obj.widButC = (obj.widPanel - 2*obj.dX)/obj.nButC;
            
        end
        
        % --- initialises the class fields
        function initClassObjects(obj)
            
            % deletes any previous GUIs
            hPrev = findall(0,'tag',obj.tagStr);
            if ~isempty(hPrev); delete(hPrev); end
            
            % makes the main dialog window invisible
            setObjVisibility(obj.hFigM,0);
            
            % --------------------------- %
            % --- MAIN FIGURE OBJECTS --- %
            % --------------------------- %
            
            % creates the figure object
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % creates the figure object
            obj.hFig = createUIObj('figure','Position',fPos,...
                'tag',obj.tagStr,'MenuBar','None','Toolbar','None',...
                'Name',obj.figName,'Resize','on','NumberTitle','off',...
                'Visible','off','AutoResizeChildren','off',...
                'BusyAction','Cancel','GraphicsSmoothing','off',...
                'DoubleBuffer','off','Renderer','painters');            
        
            % ----------------------- %
            % --- SUB-PANEL SETUP --- %
            % ----------------------- %
                        
            % sets up the sub-panel objects
            obj.setupControlButtonPanel();
            obj.setupSerialDevicePanel();            
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %            
            
            % opens the class figure
            openClassFigure(obj.hFig);
            
        end              
        
        % ------------------------------------ %
        % --- PANEL OBJECT SETUP FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- sets up the control button parameter panel
        function setupControlButtonPanel(obj)
           
            % initialisations
            tStrB = {'Add Device','Remove Device','Close Window'};
            cbFcnB = {@obj.buttonAddDevice;@obj.buttonRemoveDevice;...
                      @obj.buttonCloseWindow};            
            
            % creates the panel object
            pPos = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelC];
            obj.hPanelC = createPanelObject(obj.hFig,pPos);
                  
            % creates the button object
            obj.hButC = createObjectRow(obj.hPanelC,obj.nButC,...
                'pushbutton',obj.widButC,'dxOfs',0,'yOfs',obj.dX/2,...
                'pStr',tStrB);
            cellfun(@(x,y)(set(x,'Callback',y)),obj.hButC,cbFcnB);
            
            % sets the button properties
            cellfun(@(x)(setObjEnable(x,0)),obj.hButC(1:2));
            
        end
        
        % --- sets up the serial device list panel
        function setupSerialDevicePanel(obj)
            
            % initialisations
            cWid = {325};
            cName = {'Serial Device Name'};
            tStrD = 'New Device Name';
            
            % callback functions
            cbFcnE = @obj.editDeviceName;
            cbFcnT = @obj.tableDeviceName;
            
            % creates the panel object
            yPos = sum(obj.hPanelC.Position([2,4])) + obj.dX;
            pPos = [obj.dX,yPos,obj.widPanel,obj.hghtPanelD];
            obj.hPanelD = createPanelObject(obj.hFig,pPos,obj.tHdrD);
            
            % creates the editbox object
            obj.hEditD = createObjectPair(obj.hPanelD,tStrD,...
                obj.widLblD,'edit','cbFcnM',cbFcnE);
            set(obj.hEditD,'HorizontalAlignment','Left');
            
            % creates the table object
            yPosT = sum(obj.hEditD.Position([2,4])) + obj.dX/2;
            pPosT = [obj.dX,yPosT,obj.widTableD,obj.hghtTableD];
            obj.hTableD = createUIObj('table',obj.hPanelD,...
                'Data',[],'Position',pPosT,'ColumnName',cName,...
                'ColumnEditable',false,'ColumnWidth',cWid,...
                'ColumnFormat',{'char'},'FontSize',obj.fSz,...
                'CellSelectionCallback',cbFcnT,'Data',obj.sDevT);            
            
            % auto-resizes the table columns
            autoResizeTableColumns(obj.hTableD);
            
        end
                
        % --------------------------------------- %
        % --- OTHER OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------------- %        

        % --- device name editbox callback function
        function editDeviceName(obj, ~, ~)
            
            nwStr = obj.getDeviceString;
            setObjEnable(obj.hButC{1},~isempty(nwStr));
            
        end
        
        % --- device name table cell selection callback function
        function tableDeviceName(obj, ~, ~)
            
            % retrieves the java table objects
            if isempty(obj.jTableD)
                obj.jTableD = getJavaTable(obj.hTableD);
            end
            
            % determines if a table row has been selected
            iSel = obj.jTableD.getSelectedRows;
            setObjEnable(obj.hButC{2},~isempty(iSel))            
            
        end        
        
        % --- close window button callback function
        function buttonAddDevice(obj, ~, ~)

            % prompts the user if they actually want to add the device name
            tStr = 'Add Device Name?';
            qStr = ['Are you sure you want to add the device name ',...
                    'to the search list?'];
            uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
            if ~strcmp(uChoice,'Yes')
                % if the user cancelled, then exit
                return
            end
            
            % makes the figure invisible (??)
            setObjVisibility(obj.hFig,0); 
            pause(0.05)
            
            % updates the parameter file
            pFile = getParaFileName('ProgPara.mat');
            sDev = [obj.hTableD.Data(:);{obj.getDeviceString()}];
            save(pFile,'sDev','-append');
            
            % resets the other object properties
            setObjEnable(obj.hButC{1},0);
            setObjEnable(obj.hButC{2},0);
            obj.hEditD.String = '';
            
            % resets the figure properties
            obj.sDevT = sDev;
            obj.resetFigureProps();            
            
            % makes the GUI visible again
            setObjVisibility(obj.hFig,'on');                         
                
        end
        
        % --- close window button callback function
        function buttonRemoveDevice(obj, ~, ~)
            
            % determines the row that has been selected
            iSel = obj.jTableD.getSelectedRows + 1;            
            
            % prompts the user if they actually want to remove the device name
            Data = obj.hTableD.Data;
            if strcmp(Data{iSel},obj.baseDev)
                % outputs and error to screen and exits
                tStr = 'Device Removal Error';
                eStr = ['This is a default serial device type ',...
                        'and can''t be removed.'];
                waitfor(errordlg(eStr,tStr,'modal'))
                
                % exits the function
                return
                
            else
                % prompts user if they want to remove device name
                tStr = 'Remove Device Name?';
                qStr = ['Are you sure you want to remove the device ',...
                        'name from the search list?'];
                uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
                if ~strcmp(uChoice,'Yes')
                    % if the user cancelled, then exit
                    return
                end
            end
            
            % makes the GUI invisible
            setObjVisibility(obj.hFig,'off'); 
            pause(0.05)            
            
            % updates the parameter file
            sDev = Data((1:length(Data)) ~= iSel);
            pFile = getParaFileName('ProgPara.mat');
            save(pFile,'sDev','-append');

            % resets the other object properties
            setObjEnable(obj.hButC{1},0);
            setObjEnable(obj.hButC{2},0);
            obj.hEditD.String = '';
            
            % resets the figure properties
            obj.sDevT = sDev;            
            obj.resetFigureProps();            
            
            % makes the GUI visible again
            setObjVisibility(obj.hFig,'on');             
            
        end        
              
        % --- close window button callback function
        function buttonCloseWindow(obj, ~, ~)
            
            % makes the main dialog window invisible
            setObjVisibility(obj.hFig,0);            
            setObjVisibility(obj.hFigM,1);
            
            % deletes the figure
            delete(obj.hFig)
            clear obj
            
        end
              
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %  
        
        % --- resets the figure properties
        function resetFigureProps(obj)
            
            % field initialisation
            obj.nDev = length(obj.sDevT);
            
            % retrieves the object positions
            tPos = obj.hTableD.Position;
            tHght0 = tPos(4);
            
            % resets the table properties
            if obj.nDev == 0
                % case is no devices have been set
                [tPos(4),Data] = deal(calcTableHeight(1),{''});
                
            else
                % case is at least one device has been set                
                [tPos(4),Data] = deal(calcTableHeight(obj.nDev),obj.sDevT);
            end
            
            % resets the panel object dimensions
            dHght = tPos(4) - tHght0;
            set(obj.hTableD,'Data',Data,'Position',tPos);
            resetObjPos(obj.hPanelD,'Height',dHght,1);
            resetObjPos(obj.hFig,'Height',dHght,1);
            
        end
        
        % --- retrieves the current device string
        function nwStr = getDeviceString(obj)
            
            % retrieves the device name string
            nwStr = get(obj.hEditD,'string');
            
            % removes the start/end white-spaces
            ii = regexp(nwStr,'\S');
            nwStr = nwStr(ii(1):ii(end));
            
        end
        
    end
    
end