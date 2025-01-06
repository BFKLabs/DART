classdef SerialConfig < handle
    
    % class properties
    properties
        
        % main window object class fields
        hFigM
        
        % serial port information
        comA
        comD
        pStr
        diskStr
        
        % main class objects
        hFig
        
        % com port information panel
        hPanelI
        hTxtI
        
        % connected device information panel
        hPanelD
        hTableD
        hTxtD
        
        % control button panel
        hPanelC
        hButC
        
        % fixed dimension fields
        dX = 10;        
        hghtTxt = 16;
        hghtRow = 25;
        hghtHdr = 20;
        widPanel = 440; 
        widLblI = 130;        
        
        % calculated dimension fields
        widFig
        hghtFig
        hghtPanelI
        hghtPanelD
        hghtPanelC
        widTableD
        hghtTableD
        widTxtD
        widButC
        
        % static class fields
        nDev
        nTxtI = 2;
        nButC = 3;
        fSzH = 13;
        fSzL = 12;
        fSz = 10 + 2/3;
        
        % static string fields
        tagStr = 'figSerialConfig';
        figName = 'Serial Device Configuration';
        tHdrI = 'COM PORT INFORMATION';
        tHdrD = 'CONNECTED DEVICE INFORMATION';
        lStr = 'Detecting Serial Port Information...';
        
    end
    
    % class methods
    methods
        
        % --- class constuctor
        function obj = SerialConfig(hFigM)
            
            % sets the input arguments
            obj.hFigM = hFigM;
            
            % creates the loadbar object
            hLoad = ProgressLoadbar(obj.lStr);
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initClassObjects();
            
            % deletes the loadbar
            delete(hLoad);
            
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
            
            % ------------------------------- %            
            % --- SERIAL PORT INFORMATION --- %
            % ------------------------------- %
            
            % retrieves the serial device strings from the parameter file
            A = load(getParaFileName('ProgPara.mat'));            
            
            % determines the serial port information
            [obj.comA,obj.comD] = getSerialPortInfo();
            obj.pStr = findSerialPort(A.sDev,1);            

            % ----------------------------- %            
            % --- OTHER INITIALISATIONS --- %
            % ----------------------------- %
            
            % array dimensioning
            obj.nDev = size(obj.pStr,1);
            
            % memory allocation
            obj.hTxtI = cell(obj.nTxtI,1);
            obj.hButC = cell(obj.nButC,1);            
            
            % ------------------------------------- %
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- %
            
            % calculates the 
            if obj.nDev == 0
                % case is devices have not been detected
                obj.hghtPanelD = 2*obj.hghtHdr + obj.dX;
                obj.widTxtD = obj.widPanel - 2*obj.dX;
                
            else
                % case is devices have been detected
                obj.widTableD = obj.widPanel - 1.5*obj.dX;                
                obj.hghtTableD = calcTableHeight(obj.nDev);
                obj.hghtPanelD = obj.hghtTableD + obj.dX + obj.hghtHdr;
            end
            
            % calculates the other panel dimensions
            obj.hghtPanelC = obj.dX + obj.hghtRow;
            obj.hghtPanelI = obj.dX + 3*obj.hghtHdr;
            
            % calculates the figure dimensions
            obj.widFig = obj.widPanel + 2*obj.dX;
            obj.hghtFig = 4*obj.dX + ...
                obj.hghtPanelI + obj.hghtPanelD + obj.hghtPanelC;            
            
            % other object dimension calculations
            obj.widButC = (obj.widPanel - obj.dX)/obj.nButC;
            
        end
        
        % --- initialises the class fields
        function initClassObjects(obj)
            
            % deletes any previous GUIs
            hPrev = findall(0,'tag',obj.tagStr);
            if ~isempty(hPrev); delete(hPrev); end
            
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
            obj.setupDeviceInfoPanel();
            obj.setupSerialInfoPanel();
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %                      
            
            % opens the class figure
            openClassFigure(obj.hFig);
            
        end
        
        % ------------------------------------ %
        % --- PANEL OBJECT SETUP FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- sets up the serial information panel
        function setupSerialInfoPanel(obj)
            
            % initialisations
            tStrL = {'Detected COM Ports','Available COM Ports'};
            
            % creates the panel object
            yPos = sum(obj.hPanelD.Position([2,4])) + obj.dX;
            pPos = [obj.dX,yPos,obj.widPanel,obj.hghtPanelI];
            obj.hPanelI = createPanelObject(obj.hFig,pPos,obj.tHdrI);           
            
            % creates the text label objects
            for i = 1:obj.nTxtI
                yOfs = obj.dX + (i-1)*obj.hghtHdr;
                obj.hTxtI{i} = createObjectPair(obj.hPanelI,tStrL{i},...
                    obj.widLblI,'text','yOfs',yOfs,'xOfs',obj.dX/2,...
                    'fSzM',obj.fSzL);
            end
            
            % sets the detected/available strings
            obj.hTxtI{1}.String = obj.setFullString(obj.comD,'Detected');
            obj.hTxtI{2}.String = obj.setFullString(obj.comA,'Available');            
            
        end
            
        % --- sets up the serial information panel
        function setupDeviceInfoPanel(obj)                    
            
            % initialisations
            tStr = 'No Suitable Serial Devices Found Connected To Computer';
            
            % creates the panel object
            yPos = sum(obj.hPanelC.Position([2,4])) + obj.dX;
            pPos = [obj.dX,yPos,obj.widPanel,obj.hghtPanelD];
            obj.hPanelD = createPanelObject(obj.hFig,pPos,obj.tHdrD);            
            
            % creates the panel object (based on devices detected)
            if obj.nDev == 0
                % case is no devices were connected
                
                % creates the text object
                pPosT = [obj.dX,obj.dX-2,obj.widTxtD,obj.hghtTxt];
                createUIObj('text',obj.hPanelD,'Position',pPosT,...
                    'FontUnits','Pixels','FontWeight','Bold',...
                    'FontSize',obj.fSzL,'String',tStr);
                
            else
                % case is devices were connected
                
                % sets up the table properties
                cWid = {230,45,40,80};
                cEdit = [false,false,false,false];
                cForm = {'char','char','char','char'};
                cName = {'Serial Device Name','Port ID','Drive','Type'};                
                tData = obj.pStr(:,[2,1,4,5]);
                obj.diskStr = obj.pStr(:,4);
                
                % creates the table object
                pPosT = [obj.dX*[1,1]/2,obj.widTableD,obj.hghtTableD];
                obj.hTableD = createUIObj('table',obj.hPanelD,...
                    'Data',tData,'Position',pPosT,'ColumnName',cName,...
                    'ColumnEditable',cEdit,'ColumnWidth',cWid,...
                    'ColumnFormat',cForm,'FontSize',obj.fSz,...
                    'CellSelectionCallback',@obj.tableCellSelect);
                    
                % sets the other table properties
                autoResizeTableColumns(obj.hTableD);
            end
        end
            
        % --- sets up the serial information panel
        function setupControlButtonPanel(obj)
            
            % initialisations
            bStrC = {'Configure COM Ports',...
                     'Set Device Names','Close Window'};
            cbFcnB = {@obj.buttonConfigPorts;@obj.buttonSetNames;...
                      @obj.buttonCloseWindow};
            
            % creates the panel object
            pPos = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelC];
            obj.hPanelC = createPanelObject(obj.hFig,pPos);
            
            % creates the button objects
            obj.hButC = createObjectRow(obj.hPanelC,obj.nButC,...
                'pushbutton',obj.widButC,'yOfs',obj.dX/2,...
                'pStr',bStrC,'xOfs',obj.dX/2,'dxOfs',0);
            
            % updates the other object properties
            cellfun(@(x,y)(set(x,'Callback',y)),obj.hButC,cbFcnB);
            
        end
        
        % --------------------------------------- %
        % --- OTHER OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- device table cell selection callback function
        function tableCellSelect(obj, ~, evnt)
            
            % if the indices are empty, then exit
            if isempty(evnt.Indices); return; end
            
            % sets selected row/column indices and serial build directory
            Data = obj.hTableD.Data;
            utilDir = getProgFileName(...
                'Code','Common','Utilities','Serial Builds');
            [iRow,iCol] = deal(evnt.Indices(1),evnt.Indices(2));            
            
            % only enable updating if the type column has been selected (and the
            % serial device is a V1 serial controller)
            if (iCol == 4) && ~strcmp(Data{iRow,3},'N/A')
                % prompt the user for the serial binary file
                [fName,fDir,fIndex] = uigetfile(...
                    {'*.bin','Serial Device Binary Files (*.bin)'},...
                    'Select A Serial Device Binary File',utilDir);
                if fIndex
                    % creates a loadbar
                    h = ProgressLoadbar('Updating Serial Device Binary File...');
                    
                    % copies over the binary file. waits until done
                    copyfile(fullfile(fDir,fName),obj.diskStr{iRow});
                    pause(5.0);
                    
                    % updates the table
                    Data{iRow,iCol} = getSerialDeviceType(Data{iRow,2});
                    obj.hTableD.Data = Data;
                    
                    % closes the loadbar
                    try delete(h); catch; end
                end
            end
            
        end                
            
        % --- set device name button callback functions
        function buttonSetNames(obj, ~, ~)
           
            % opens the serial device names GUI
            SerialNames(obj.hFig)
            
        end        
            
        % --- close window button callback functions
        function buttonCloseWindow(obj, ~, ~)
           
            % makes the main GUI visible again
            setObjVisibility(obj.hFig,0);
            setObjVisibility(obj.hFigM,1);
            
            % deletes the class object
            obj.deleteClass();
            
        end        

        % ------------------------------- %        
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- deletes the class object
        function deleteClass(obj)
            
            % deletes the class figure
            delete(obj.hFig)
                        
            % delete/clears the class object
            delete(obj)
            clear obj)
            
        end
        
    end
    
    % class methods
    methods (Static)
        
        % --- sets the full information strings
        function fStr = setFullString(sStr,Type)
            
            % determines if the the input string is empty
            if isempty(sStr)
                % if so, then output a generic string
                fStr = sprintf('No COM Ports %s',Type);
            else
                % appends the strings to each other with a comma separation
                fStr = sStr{1};
                for i = 2:length(sStr)
                    fStr = sprintf('%s, %s',fStr,sStr{i});
                end
            end
        
        end
        
        % --- configure COM ports button callback functions
        function buttonConfigPorts(~, ~)
            
            % creates a message box to guide user in reconfiguring device
            tStr = 'Serial COM Port Number Alteration Process';
            mStr = sprintf(['To alter the COM Port Number of a Serial ',...
                'Device, you will need to perform the following steps ',...
                'within the Device Manager:\n\n 1) Expand the ',...
                '"Ports (COMS & LPT)" tree tab\n 2) Select the serial ',...
                'device you wish to reconfigure\n 3) Right-Click and ',...
                'select the "Properties" menu item\n 4) Select the ',...
                '"Port Settings" tab from the popup-window\n 5) Click ',...
                'the "Advanced" click button\n 6) Select the new "COM ',...
                'Port Number" from the drop-down list\n 7) Select ',...
                '"OK" and exit the Properties menu item\n\nOnce ',...
                'the alteration process is complete, you will need ',...
                'to reboot the computer so that the changes can ',...
                'take hold. Until you do this, the newly selected ',...
                'COM Port will not be available for use.']);
            msgbox(mStr,tStr)
            
            % opens the device manager
            system('devmgmt.msc');
            
        end        
            
    end    
    
end