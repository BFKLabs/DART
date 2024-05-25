classdef TimeCycle < handle
    
    % class properties
    properties
        
        % input arguments
        hFigM
        
        % object handle fields
        hFig
        hPanelP
        hPanelBG
        hRadio
        hPanelF
        hPanelV
        hTableV
        jTableV
        hButV
        hButM
        hPanelC
        hButC
        
        % fixed object dimension fields
        dX = 10;
        dR0 = 22;
        dRW = 18;
        hghtRow = 25;
        hghtTxt = 16;
        hghtEdit = 21;
        hghtChk = 21;
        hghtPopup = 23;
        hghtRadio = 25;
        hghtBut = 25;
        widFig = 330;
        widTxtF = 95;
        widTxtP = 150;
        hghtPanelC = 40;
        
        % calculated object dimension fields
        hghtFig
        hghtPanelP
        widPanelBG
        hghtPanelBG
        widPanel 
        widRadio
        hghtPanelF
        widEditF
        hghtPanelV
        widTableV
        hghtTableV
        widButV
        widPopupP
        widChkP
        widButC
        
        % other class fields
        tcPara
        tcPara0
        tCycleA = [];
        
        % boolean class fields
        canClick = false;
        isUpdating = false;
        useRelTime = true;
        
        % static class fields
        nRow = 0;
        nButV = 3;
        nButM = 2;
        nButC = 2;
        nParaF = 2;
        nParaP = 2;
        nRowMax = 6;        
        fSzL = 12;
        fSz = 10 + 2/3;
        
        % static array fields
        tStrF = {'Light','Dark'};        
        pStrF = {'tOn','tOff'};
        pStrP = {'tCycle0','useRelTime'};
        
        % static string fields
        tagStr = 'figTimeCycle';                
        figName = 'Experiment Time Cycle';        
        tStrF0 = 'Cycle (h): ';
        rStrR0 = 'Light/Dark Cycle Duration';
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = TimeCycle(hFigM)
            
            % sets the input arguments
            obj.hFigM = hFigM;
            
            % initialises the class objects/fields
            obj.initClassFields();  
            obj.initClassObjects();            
            
            % clears the output object (if not required)
            if nargout == 0
                clear obj
            end            
            
        end

        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % memory allocation
            obj.hRadio = cell(2,1);
            obj.hButV = cell(obj.nButV,1); 
            obj.hButM = cell(obj.nButM,1);

            % --------------------------- %
            % --- PARAMETER RETRIEVAL --- %
            % --------------------------- %
            
            % retrieves the solution file data structs
            switch obj.hFigM.Tag
                case 'figOpenSoln'
                    % case is loading from the file load window
                    sObj = getappdata(obj.hFigM,'sObj');
                    snTot = cellfun(@(x)(x.snTot),sObj.sInfo,'un',0);
                    
                case 'figFlyCombine'
                    % case is the data combining window
                    sInfo = getappdata(obj.hFigM,'sInfo');
                    snTot = cellfun(@(x)(x.snTot),sInfo,'un',0);
                    
                case 'figFlyAnalysis'
                    % case is the quantitative analysis window                    
                    snTot = num2cell(getappdata(obj.hFigM,'snTot'));
            end
            
            % determines which experiments have the time cycle fields
            hasTC = cellfun(@(x)(isfield(x,'tcPara')),snTot);
            if any(hasTC)
                % retrieves the time cycle parameter struct
                tcP = cellfun(@(x)(x.tcPara),snTot(hasTC),'un',0);
                if length(tcP) == 1
                    % case is there is only one parameter struct
                    obj.tcPara = tcP{1};
                else
                    % case is there are multiple parameter structs
                    xiT = 1:length(tcP);
                    pMatch = arrayfun(@(y)(mean(cellfun(...
                        @(x)(isequal(tcP{y},x)),tcP(xiT~=y)))),xiT);                    
                    obj.tcPara = tcP{argMax(pMatch)};
                end
                
            else
                % if there are no matches, then set the default data struct
                obj.tcPara = setupTimeCyclePara();
            end
            
            % sets the row count
            obj.nRow = size(obj.tcPara.tCycleR,1);
            if obj.nRow > 0
                obj.recalcAbsTimes();
            end
            
            % sets the original parameter struct
            obj.tcPara0 = obj.tcPara;
            
            % ------------------------------ %
            % --- DIMENSION CALCULATIONS --- %
            % ------------------------------ %
            
            % calculates the variable dimensions
            obj.widPanelBG = obj.widFig - 2*obj.dX;
            obj.widPanel = obj.widPanelBG - 2*obj.dX;
            obj.widRadio = obj.widPanelBG - 2*obj.dX;
            
            % parameter panel objects
            obj.hghtPanelP = obj.nParaP*obj.hghtRow + 1.5*obj.dX;
            obj.widChkP = obj.widPanelBG - 2*obj.dX;
            obj.widPopupP = (obj.widPanelBG - (obj.widTxtP + 3*obj.dX))/3;
            
            % calculates the control button sizes
            obj.widButC = (obj.widPanelBG - ...
                (2+(obj.nButC-1)/2)*obj.dX)/obj.nButC;
            
            % variable duration panel objects            
            obj.widTableV = obj.widPanel - (2*obj.dX + obj.hghtBut);
            obj.hghtTableV = obj.dR0 + obj.nRowMax*obj.dRW;
            obj.widButV = (obj.widPanel - ...
                (1 + (obj.nButV-1)/2)*obj.dX)/obj.nButV;
            obj.hghtPanelV = obj.hghtTableV + 4.5*obj.dX;
            
            % fixed duration panel objects
            obj.hghtPanelF = obj.hghtRow + obj.dX;
            obj.widEditF = (obj.widPanel - (1.5*obj.dX + 2*obj.widTxtF))/2;
            
            % calculates the other object heights
            obj.hghtPanelBG = obj.hghtPanelF + ...
                obj.hghtPanelV + 2*obj.hghtRadio + 2*obj.dX;
            obj.hghtFig = obj.hghtPanelBG + ...
                obj.hghtPanelP + obj.hghtPanelC + 3*obj.dX;
            
        end
        
        % --- initialises the class objects
        function initClassObjects(obj)
            
            % removes any previous GUIs
            hFigPr = findall(0,'tag',obj.tagStr);
            if ~isempty(hFigPr); delete(hFigPr); end
            
            % --------------------------- %
            % --- MAIN FIGURE OBJECTS --- %
            % --------------------------- % 
            
            % creates the figure object
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % creates the figure object
            obj.hFig = createUIObj('figure','Position',fPos,...
                'tag',obj.tagStr,'MenuBar','None','Toolbar','None',...
                'Name',obj.figName,'Resize','off','NumberTitle','off',...
                'Visible','off','CloseRequestFcn',[]);
            
            % ------------------------------------ %
            % --- CONTROL BUTTON PANEL OBJECTS --- %
            % ------------------------------------ %
            
            % initialisations
            bStrC = {'Update Parameters','Close Window'};
            cbFcnC = {@obj.updatePara,@obj.closeWindow};
            
            % creates the panel object
            pPosC = [obj.dX*[1,1],obj.widPanelBG,obj.hghtPanelC];
            obj.hPanelC = createUIObj(...
                'Panel',obj.hFig,'Title','','Position',pPosC);
            
            % creates the button object
            for i = 1:obj.nButC
                % sets up the positional vector
                lPosB = obj.dX*(1+(i-1)/2) + (i-1)*obj.widButC;
                pPosB = [lPosB,obj.dX-2,obj.widButC,obj.hghtBut];
                
                % creates the button objects
                obj.hButC{i} = createUIObj('pushbutton',obj.hPanelC,...
                    'String',bStrC{i},'Position',pPosB,...
                    'FontWeight','Bold','FontSize',obj.fSzL,...
                    'ButtonPushedFcn',cbFcnC{i});
            end
            
            % --------------------------------------- %
            % --- VARIABLE DURATION PANEL OBJECTS --- %
            % --------------------------------------- %
            
            % initialisations           
            bStrM = {char(9650),char(9660)};
            bStrV = {'Add','Remove','Clear All'};
            cHdrV = {'Light Cycle (h)','Dark Cycle (h)'};            
            cbFcnB = {@obj.addTableRow,@obj.removeTableRow,@obj.clearAll};            
                        
            % sets the parameter specific table properties
            if obj.useRelTime
                tDataV = obj.tcPara.tCycleR;
                cEdit = true(1,2);
                cForm = {'numeric','numeric'};
            else
                tDataV = obj.tCycleA;
                cEdit = false(1,2);                
                cForm = {'char','char'};
            end
            
            % creates the main panel object
            yPosV = sum(pPosC([2,4])) + obj.dX;            
            pPosBG = [obj.dX,yPosV,obj.widPanelBG,obj.hghtPanelBG];
            obj.hPanelBG = createUIObj(...
                'ButtonGroup',obj.hFig,'Title','','Position',pPosBG,...
                'SelectionChangedFcn',@obj.panelSelectChanged);            
            
            % creates the panel object
            pPosV = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelV];
            obj.hPanelV = createUIObj(...
                'Panel',obj.hPanelBG,'Title','','Position',pPosV);
            
            % creates the push-button objects
            for i = 1:obj.nButV
                % sets up the position vector
                lPosB = obj.dX*(i/2) + (i-1)*obj.widButV; 
                pPosB = [lPosB,obj.dX-2,obj.widButV,obj.hghtBut];
                
                % creates the button object
                obj.hButV{i} = createUIObj('pushbutton',obj.hPanelV,...
                    'String',bStrV{i},'Position',pPosB,'FontWeight','Bold',...
                    'ButtonPushedFcn',cbFcnB{i},'FontSize',obj.fSzL);
            end            
            
            % variable table object
            pPosTV = [obj.dX*[0.5,4],obj.widTableV,obj.hghtTableV];
            obj.hTableV = createUIObj('table',obj.hPanelV,...
                'Position',pPosTV,'ColumnEdit',true,...
                'CellSelectionCallback',@obj.tableCellSelect,...
                'CellEditCallback',@obj.tableCellEdit,...
                'KeyPressFcn',@obj.tableKeyPress,...
                'KeyReleaseFcn',@obj.tableKeyRelease,...
                'ColumnName',cHdrV,'ColumnFormat',cForm,...
                'ColumnEditable',cEdit,'Data',tDataV);
            
            % creates the list reorder buttons
            lPosM = sum(pPosTV([1,3])) + obj.dX/2;
            for i = 1:obj.nButM
                % sets up the button positional vector
                yPosM = mean(pPosTV([2,4])) + 1.5*(1-2*(i-1))*obj.dX; 
                pPosM = [lPosM,yPosM,obj.hghtBut*[1,1]];
                
                % creates the button object
                obj.hButM{i} = createUIObj('pushbutton',obj.hPanelV,...
                    'String',bStrM{i},'Position',pPosM,'Enable','off',...
                    'FontWeight','Bold','FontSize',obj.fSzL,...
                    'ButtonPushedFcn',{@obj.buttonReorderCycle,i==2});
            end
            
            % creates the radio button
            [obj.hRadio{2},pPosRV] = ...
                obj.createRadioButton('Variable',sum(pPosV([2,4])));
            
            % automatically resizes the table
            autoResizeTableColumns(obj.hTableV);
            
            % ------------------------------------ %
            % --- FIXED DURATION PANEL OBJECTS --- %
            % ------------------------------------ %
            
            % creates the panel object
            yPosF = sum(pPosRV([2,4])) + obj.dX/2;
            pPosF = [obj.dX,yPosF,obj.widPanel,obj.hghtPanelF];
            obj.hPanelF = createUIObj(...
                'Panel',obj.hPanelBG,'Title','','Position',pPosF);
            
            % creates the label/editbox objects
            xiF = 1:obj.nParaF;
            arrayfun(@(x)(obj.createLabelEdit(x)),xiF);
            
            % creates the radio button
            obj.hRadio{1} = ...
                obj.createRadioButton('Fixed',sum(pPosF([2,4])));            
            
            % ------------------------------- %
            % --- PARAMETER PANEL OBJECTS --- %
            % ------------------------------- %
            
            % initialisations
            tStrP = {'Lighting Cycle Start Time: ',...
                     'Define Variable Cycles Using Relative Time'};
            
            % creates the panel object
            yPosP = sum(pPosBG([2,4])) + obj.dX;
            pPosP = [obj.dX,yPosP,obj.widPanelBG,obj.hghtPanelP];
            obj.hPanelP = createUIObj(...
                'Panel',obj.hFig,'Title','','Position',pPosP);            
            
            % creates the popupmenu items
            for i = 1:obj.nParaP
                % sets the objects bottom coordinate
                yObj0 = obj.dX + (i-1)*obj.hghtRow;
                
                % creates the objects
                if strcmp(obj.pStrP{i},'tCycle0')
                    % case is creating the popup-time object
                    obj.createLabelTime(i,tStrP{i});
                    
                else
                    % case is creating a checkbox object
                    pVal = obj.(obj.pStrP{i});
                    pObj = [obj.dX,yObj0,obj.widChkP,obj.hghtChk];
                    createUIObj('checkbox',obj.hPanelP,...
                        'String',tStrP{i},'Position',pObj,...
                        'FontWeight','Bold','FontSize',obj.fSzL,...
                        'Callback',@obj.checkGenPara,...
                        'UserData',obj.pStrP{i},'Value',pVal);
                end
            end
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %            
            
            % updates the button group selection properties 
            set(obj.hRadio{1},'Value',obj.tcPara.isFixed);            
            obj.panelSelectChanged(obj.hPanelBG,[]);            

            % disables the update/reset buttons
            setObjEnable(obj.hButC{1},0);
            
            % centers the figure and makes it visible
            centerfig(obj.hFig);
            refresh(obj.hFig);
            pause(0.05);
            
            % makes the figure visible
            set(obj.hFig,'Visible','on');   
            
            % retrieves the table java handle
            jScroll = findjobj(obj.hTableV);             
            obj.jTableV = jScroll.getComponent(0).getComponent(0);            
                        
        end
        
        % ------------------------------------ %
        % --- MENU ITEM CALLBACK FUNCTIONS --- %
        % ----------------=------------------- %        

        % --- updates the cycle duration parameter        
        function updatePara(obj,~,~)

            % updates the solution fields (depending on the opening window)
            % retrieves the solution file data structs
            switch obj.hFigM.Tag
                case 'figOpenSoln'
                    % case is loading from the file load window
                    
                    % retrieves and updates fields within solution data
                    sObj = getappdata(obj.hFigM,'sObj');
                    for i = 1:length(sObj.sInfo)
                        sObj.sInfo{i}.snTot.tcPara = obj.tcPara;
                    end                    
                    
                    % updates the field within the master window
                    setappdata(obj.hFigM,'sObj',sObj)                    
                    
                case 'figFlyCombine'
                    % case is the data combining window
                    
                    % retrieves and updates fields within solution data
                    sInfo = getappdata(obj.hFigM,'sInfo');
                    for i = 1:length(sInfo)
                        sInfo{i}.snTot.tcPara = obj.tcPara;
                    end
                    
                    % updates the field within the master window
                    setappdata(obj.hFigM,'sInfo',sInfo)
                    
                case 'figFlyAnalysis'
                    % case is the quantitative analysis window

                    % retrieves and updates fields within solution data
                    snTot = getappdata(obj.hFigM,'snTot');
                    for i = 1:length(snTot)
                        snTot(i).tcPara = obj.tcPara;
                    end                    
                    
                    % updates the field within the master window
                    setappdata(obj.hFigM,'snTot',snTot)
            end
            
            % resets the class object fields
            obj.tcPara0 = obj.tcPara;            
            
            % updates the other fields
            obj.setUpdateParaProps();
            
        end
        
        % --- close window callback function
        function closeWindow(obj,~,~)
            
            % determines if there are outstanding changes
            if strcmp(obj.hButC{1}.Enable,'on')
                % if so, prompts the user if they want to update
                tStr = 'Update Changes?';
                qStr = 'Do you want to update the changes you have made?';
                uChoice = questdlg(qStr,tStr,'Yes','No','Cancel','Yes');
                
                % updates based on the user's choice
                switch uChoice
                    case 'Yes'
                        % user chose to update changes
                        obj.updatePara([],[]);
                        
                    case 'Cancel'
                        % user chose to cancel
                        return
                end                
            end
            
            % closes the window
            delete(obj.hFig);
            
        end

        % --------------------------------------------------- %
        % --- GENERAL PARAMETER OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------------------------- %        
        
        % --- general parameter checkbox callback function
        function checkGenPara(obj,hCheck,~)
            
            % field retrieval
            nwVal = hCheck.Value;            
            pStr = hCheck.UserData;
            
            % updates the parameter specific properties
            switch pStr
                case 'useRelTime'
                    % updates the parameter field
                    obj.useRelTime = nwVal;
                    
                    % sets the value specific values
                    if nwVal
                        cEdit = true(1,2);
                        cForm = {'numeric','numeric'};
                    else
                        cEdit = false(1,2);
                        cForm = {'char','char'};
                    end
                    
                    % case is using the relative light cycle
                    set(obj.hTableV,'ColumnEditable',cEdit,...
                        'ColumnFormat',cForm)
                    obj.resetTableData();
            end
            
            % retrieves the selected table row
            setObjEnable(obj.hButV{2},0);
            obj.setReorderButtonProps(NaN);
            
        end
        
        % --- cycle start time popup menu
        function popupStartTime(obj,hPopup,~)
            
            % field retrieval
            obj.tcPara.tCycle0(hPopup.UserData) = hPopup.Value - 1;
                        
            % resets the table data
            obj.recalcAbsTimes();
            obj.resetTableData();            
                        
            % updates the other fields
            setObjEnable(obj.hButV{2},0);
            obj.setUpdateParaProps();            
            obj.setReorderButtonProps(NaN);            
            
        end
        
        % --------------------------------------------------------- %
        % --- VARIABLE DURATION PANEL OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------------------------------- %
        
        % --- table key press callback function
        function tableKeyPress(obj,~,evnt)
            
            % exit using relative time
            if obj.useRelTime; return; end
            
            % determines if the key being pressed is the alt key
            obj.canClick = strcmp(evnt.Key,'alt');
            
        end
        
        % --- table key release callback function
        function tableKeyRelease(obj,~,~)
            
            % exit using relative time
            if obj.useRelTime; return; end
            
            % resets the click flag
            obj.canClick = false;
            
        end        
        
        % --- variable duration table cell selection callback function
        function tableCellSelect(obj,~,evnt)            
                  
            % sets the program update flag
            if isempty(evnt.Indices)
                return
            else
                [iR,iC] = deal(evnt.Indices(1),evnt.Indices(2));
                obj.setReorderButtonProps(iR);
            end                                                
            
            % enables the remove day button
            if obj.useRelTime
                % case is using relative time
                setObjEnable(obj.hButV{2},1);                
                
            elseif obj.canClick
                % case is using absolute time
                if isequal([iR,iC],[1,1])
                    return
                end
                
                % prompts the user to set the new cycle time
                objT = TimeSelect(obj.time2vec(obj.tCycleA{iR,iC}));
                if objT.isOK        
                    % calculates the difference between times
                    T0 = datetime(obj.tCycleA{iR,iC},'Format','hh:mm a');
                    T1 = obj.vec2time(objT.tVec,1);
                    dT = hours(T0 - T1);
                    
                    % amends the time difference if too large
                    if dT > obj.tcPara.tCycleR{iR,iC}
                        dT = dT - 24;
                    end
                    
                    % resets the time value
                    tNew = mod(obj.tcPara.tCycleR{iR,iC} - dT,24);
                    obj.tcPara.tCycleR{iR,iC} = tNew;                    
                    
                    % resets the table values
                    obj.recalcAbsTimes();
                    obj.resetTableData();
                end               
                
                % resets the click flag
                obj.canClick = false;
            end
            
        end
        
        % --- variable duration table cell edit callback function
        function tableCellEdit(obj,hTable,evnt)
                        
            % field retrieval
            nwVal = evnt.NewData;
            [iRow,iCol] = deal(evnt.Indices(1),evnt.Indices(2));
            
            % determines if the new value is valid
            if chkEditValue(nwVal,[1,100],false)                
                % if so, then update the flags/arrays
                obj.tcPara.tCycleR{iRow,iCol} = nwVal;
                obj.recalcAbsTimes();
                
                % disables the update/reset buttons
                obj.setUpdateParaProps();
                
            else
                % otherwise, revert back to the previous data value
                hTable.Data{iRow,iCol} = evnt.PreviousData;
                setObjEnable(obj.hButV{2},0);
                obj.setReorderButtonProps(NaN);
            end
            
            % resets the update flag
            obj.isUpdating = false;
            
        end        
        
        % --- add table row push button callback function
        function addTableRow(obj,~,~) 
            
            % updates the table data
            if obj.nRow > 0
                % case is the table has data
                Data0 = obj.hTableV.Data;
                if any(cellfun('isempty',Data0(:)))
                    % if any cells are empty, then output an error
                    tStr = 'Empty Cells Detected';
                    mStr = ['Make sure all table cells are ',...
                           'full before adding rows'];
                    waitfor(msgbox(mStr,tStr,'modal'));
                    
                    % exits the function
                    return
                end
            end
            
            % updates the table data & other variables
            obj.nRow = obj.nRow + 1;
            [iRow,iCol] = obj.getSelectedTableIndices();            
            
            % appends a new table row 
            obj.tcPara.tCycleR = [obj.tcPara.tCycleR;{12,12}];            
            
            % recalculates and resets the table data
            obj.recalcAbsTimes();
            obj.resetTableData();
            
            % disables the update/reset buttons
            setObjEnable(obj.hButV{2},0);
            setObjEnable(obj.hButV{3},1);
            obj.setUpdateParaProps();
            obj.setReorderButtonProps(NaN);

            % resets the table selection
            drawnow
            obj.jTableV.changeSelection(iRow-1,iCol-1,0,0)            
            
        end
        
        % --- remove table row push button callback function
        function removeTableRow(obj,hBut,~)
            
            % retrieves the selected table row
            iRow = obj.getSelectedTableRow();
            
            % reduces the table data/storage arrays
            B = ~setGroup(iRow,[obj.nRow,1]);
            if any(B)
                obj.tcPara.tCycleR = obj.tcPara.tCycleR(B,:);
            else
                obj.tcPara.tCycleR = [];
            end

            % recalculates and resets the table data            
            obj.recalcAbsTimes();
            obj.resetTableData();
                        
            % updates the other fields
            obj.nRow = obj.nRow - 1;
            
            % sets the button properties
            setObjEnable(hBut,0);
            obj.setUpdateParaProps();
            setObjEnable(obj.hButV{3},obj.nRow>0);
            obj.setReorderButtonProps(NaN);            
            
        end        
        
        % --- clear all table entries button callback function
        function clearAll(obj,~,~)
            
            % prompts if the user want to clear all entries
            tStr = 'Confirm Clear All';
            qStr = 'Are you sure you want to clear all cycle entries?';
            uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
            
            % if the user cancelled, then exit
            if ~strcmp(uChoice,'Yes'); return; end
            
            % reduces the table data/storage arrays
            obj.hTableV.Data = [];
            [obj.tcPara.tCycleR,obj.tCycleA] = deal([]);
            
            % updates the other fields
            obj.nRow = 0;
            
            % sets the button properties               
            obj.setUpdateParaProps();            
            obj.setReorderButtonProps(NaN);            
            cellfun(@(x)(setObjEnable(x,0)),obj.hButV(2:3))            
            
        end
        
        % --- reorder duration cycle list button callback functions
        function buttonReorderCycle(obj,~,~,isDown)
            
            % retrieves the selected table row
            iR = 1:obj.nRow;
            [iRow,iCol] = obj.getSelectedTableIndices();
            iRowNw = iRow + (1 - 2*(~isDown));
            
            % sets the new indices            
            xiR = iRow + [-(~isDown),isDown];
            iR(xiR) = iR(flip(xiR));            
            
            % reorders the storage arrays
            obj.tcPara.tCycleR = obj.tcPara.tCycleR(iR,:);
            
            % recalculates and resets the table data
            obj.recalcAbsTimes();
            obj.resetTableData();            
                        
            % disables the update/reset buttons
            obj.setUpdateParaProps();
            setObjEnable(obj.hButV{2},iRow > 0);
            
            % updates the button properties               
            obj.setReorderButtonProps(iRowNw);
            
            % resets the table selection
            drawnow            
            obj.jTableV.changeSelection(iRowNw-1,iCol-1,0,0)
            
        end
        
        % --- recalculates the absolute cycle times
        function recalcAbsTimes(obj)
            
            % if there are no values, then exit
            if isempty(obj.tcPara.tCycleR)
                return
            end
            
            % field retrieval
            sz = size(obj.tcPara.tCycleR);
            tR = arr2vec(obj.tcPara.tCycleR');
            tDT = obj.vec2time(obj.tcPara.tCycle0,1);            
                        
            % memory allocation
            A = cell(length(tR),1);
            A{1} = tDT;            
            
            % calculates the cumulative duration
            for i = 2:length(tR)
                A{i} = A{i-1} + hours(tR{i});
            end
            
            % sets the final array
            A = cellfun(@char,A,'un',0);
            obj.tCycleA = reshape(A,flip(sz))';
            
        end
        
        % --- resets the variable cycle duration table data
        function resetTableData(obj)

            % resets the table data
            if obj.useRelTime
                obj.hTableV.Data = obj.tcPara.tCycleR;
            else
                obj.hTableV.Data = obj.tCycleA;
            end

        end        
        
        % --------------------------------------- %
        % --- OTHER OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- panel selection change callback function
        function panelSelectChanged(obj,hPanel,evnt)
            
            % determines if the cycle duration is fixed
            hRadioS = hPanel.SelectedObject;
            obj.tcPara.isFixed = strcmp(hRadioS.UserData,'Fixed');
                        
            % updates the panel properties based on choice
            if obj.tcPara.isFixed
                % case is fixed cycle duration
                setPanelProps(obj.hPanelF,1);
                setPanelProps(obj.hPanelV,0);
                
                % disables the update/reset buttons
                obj.setUpdateParaProps();
                
            else
                % case is variable cycle duration                
                setPanelProps(obj.hPanelV,1);
                setPanelProps(obj.hPanelF,0);
                
                % retrieves the selected row index
                if isempty(obj.jTableV)
                    [iRow,iRowP] = deal(0,NaN);
                else                    
                    [iRow,iRowP] = deal(obj.getSelectedTableRow());                    
                end
                
                % retrieves the updates the button properties
                setObjEnable(obj.hButV{2},iRow > 0);
                setObjEnable(obj.hButV{3},obj.nRow > 0);
                obj.setReorderButtonProps(iRowP);                
                obj.setUpdateParaProps();
            end
            
        end        
        
        % --- cycle duration editbox callback function
        function editCycleDur(obj,hEdit,~)
            
            % field retrieval
            pStr = hEdit.UserData;            
            nwVal = str2double(hEdit.String);
            
            % determines if the new value is valid
            if chkEditValue(nwVal,[0,100],0)
                % if so, then update the parameter value
                obj.tcPara.(pStr) = nwVal;
                obj.setUpdateParaProps();
                
            else
                % otherwise, reset to the last valid value
                hEdit.String = num2str(obj.tcPara.(pStr));
            end
            
        end                

        % --------------------------------- %
        % --- TABLE SELECTION FUNCTIONS --- %
        % --------------------------------- %        
        
        % --- retrieves the selected table row index
        function iRow = getSelectedTableRow(obj)
            
            iRow = obj.jTableV.getSelectedRow + 1;
            
        end
        
        % --- retrieves the selected table column index
        function iCol = getSelectedTableCol(obj)
            
            iCol = obj.jTableV.getSelectedColumn + 1;
            
        end        
                
        % --- retrieves the selected table row/column indices
        function [iRow,iCol] = getSelectedTableIndices(obj)
            
            iRow = obj.getSelectedTableRow();
            iCol = obj.getSelectedTableCol();
            
        end        
        
        % --------------------------------- %
        % --- OBJECT CREATION FUNCTIONS --- %
        % --------------------------------- %        
        
        % --- creates the radio button objects
        function [hRad,pPosR] = createRadioButton(obj,tStr,yPosR)

            % radio button properties
            rStrR = sprintf('%s %s',tStr,obj.rStrR0);            
            pPosR = [obj.dX,yPosR,obj.widRadio,obj.hghtRadio];
            
            % creates the radio button
            hRad = createUIObj(...
                'Radio',obj.hPanelBG,'String',rStrR,...
                'FontUnits','Pixels','FontWeight','Bold',...
                'FontSize',obj.fSzL,'Position',pPosR,...
                'UserData',tStr);

        end
        
        % --- creates the text/editbox group objects
        function createLabelEdit(obj,iRow)
           
            % calculates
            lF0 = (iRow-1)*(obj.widTxtF + obj.widEditF) + obj.dX/2;
            
            % creates the text objects
            pPosT = [lF0,obj.dX-1,obj.widTxtF,obj.hghtTxt];
            tStrT = sprintf('%s %s',obj.tStrF{iRow},obj.tStrF0);            
            createUIObj('text',obj.hPanelF,'Position',pPosT,...
                'FontWeight','Bold','FontUnits','Pixels',...
                'FontSize',obj.fSzL,'HorizontalAlignment','Right',...
                'String',tStrT);
            
            % creates the edit objects
            lPosE = sum(pPosT([1,3]));
            pValE = num2str(obj.tcPara.(obj.pStrF{iRow}));
            pPosE = [lPosE,obj.dX-3,obj.widEditF,obj.hghtEdit];
            createUIObj('edit',obj.hPanelF,'Position',pPosE,...
                'FontUnits','Pixels','FontSize',obj.fSz,...
                'UserData',obj.pStrF{iRow},'String',pValE,...
                'Callback',@obj.editCycleDur);            
            
        end
        
        % --- creates the label popupmenu group objects
        function createLabelTime(obj,iRow,tStrP)
            
            % bottom coordinate value
            yPosT = obj.dX + (iRow-1)*obj.hghtRow;            
            
            % creates the text objects
            pPosT = [obj.dX,yPosT,obj.widTxtP,obj.hghtTxt];            
            createUIObj('text',obj.hPanelP,'Position',pPosT,...
                'FontWeight','Bold','FontUnits','Pixels',...
                'FontSize',obj.fSzL,'HorizontalAlignment','Right',...
                'String',tStrP);
            
            % creates the popup menu items
            lPosPP = sum(pPosT([1,3]));
            for i = 1:3
                % sets the popup menu strings
                switch i
                    case 3
                        % case is the am/pm field
                        pStrPP = {'AM';'PM'};
                        
                    otherwise
                        % case is the hours/minutes fields
                        if i == 1
                            xiT = (0:11)';
                        else
                            xiT = (0:59)';
                        end
                            
                        % sets the final popup menu strings
                        pStrPP = arrayfun(@(x)...
                            (obj.setupTimeValue(x)),xiT,'un',0);
                end
                
                % creates the popup menu items
                pPosPP = [lPosPP,yPosT-3,obj.widPopupP,obj.hghtPopup];
                createUIObj('popupmenu',obj.hPanelP,'Position',pPosPP,...
                    'FontUnits','Pixels','FontSize',obj.fSz,...
                    'String',pStrPP,'Callback',@obj.popupStartTime,...
                    'UserData',i);
                
                % creates the hour/minute separator
                if i == 2
                    pPosG = [(lPosPP-4),yPosT,3,obj.hghtTxt];
                    createUIObj('text',obj.hPanelP,'Position',pPosG,...
                        'FontWeight','Bold','FontUnits','Pixels',...
                        'FontSize',obj.fSzL,'String',':',...
                        'HorizontalAlignment','Center');                    
                end
                
                % increments the left position
                lPosPP = sum(pPosPP([1,3])) + obj.dX/2;
            end
            
            % updates the popup menu item values
            obj.resetTimePopupValues();
            
        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- resets the time popup values
        function resetTimePopupValues(obj)
                        
            % resets the popupmenu values
            hPP = findall(obj.hPanelP,'style','popupmenu');
            for j = 1:length(hPP)
                % retrieves the popup menu item
                i = hPP(j).UserData;
                hPP(j).Value = obj.tcPara.tCycle0(i) + 1;
            end
            
        end        
        
        % --- sets the reorder button properties
        function setReorderButtonProps(obj,iRow)
            
            if isnan(iRow)
                cellfun(@(x)(setObjEnable(x,0)),obj.hButM)
            else
                setObjEnable(obj.hButM{1},iRow > 1);                
                setObjEnable(obj.hButM{2},iRow < obj.nRow);
            end
            
        end        
        
        % --- deselects the group name table
        function deselectCycleTable(obj)
            
            % stops the cell editting
            jCellEdit = obj.jTableV.getCellEditor();
            if ~isempty(jCellEdit)
                jCellEdit.stopCellEditing();
            end
        
        end                  
        
        % --- sets the update parameter button properties
        function setUpdateParaProps(obj)
            
            % determines if the start time is the same
            [tcP,tcP0] = deal(obj.tcPara,obj.tcPara0);
            isOn = ~isequal(tcP0.tCycle0,tcP.tCycle0);
            
            % sets the cycle duration type specific parameters
            if ~isOn
                if tcP.isFixed
                    % case is fixed light cycle
                    tC = [tcP.tOn,tcP.tOff];
                    tC0 = [tcP0.tOn,tcP0.tOff];
                    isOn = ~isequal(tC,tC0);
                else
                    % case is variable light cycle
                    isOn = ~isequal(tcP.tCycleR,tcP0.tCycleR);
                end
            end
            
            % sets the enabled properties
            setObjEnable(obj.hButC{1},isOn);
            
        end
        
    end
    
    % static class methods
    methods (Static)
        
        % --- sets up the time value string
        function tStr = setupTimeValue(tVal)
            
            if tVal == 0
                % case is zero
                tStr = '00';
                
            elseif tVal < 10
                % case is time less than 10
                tStr = ['0',num2str(tVal)];
                
            else
                % other case types
                tStr = num2str(tVal);
            end
            
        end
        
        % --- converts the time vector to a time string (HH:MM AMPM)
        function tStr = vec2time(tVec0,useDT)
            
            % sets the default input arguments
            if ~exist('useDT','var'); useDT = false; end
            
            % sets up the time vector
            tNow = datevec(datetime('now'));
            tVec = [tNow(1:3),tVec0(1)+12*tVec0(3),tVec0(2),0];
            
            % sets the time string
            tStr = datetime(tVec,'Format','hh:mm a');
            if ~useDT; tStr = char(tStr); end
            
        end
        
        % --- converts a date string to a time vector
        function tVec = time2vec(tStr,useFull)
            
            % sets the 
            if ~exist('useFull','var'); useFull = false; end
            
            % converts the string to a vector
            tVec0 = datevec(tStr);            
            
            % sets the final time vector
            if useFull
                tVec = tVec0;
            else
                isPM = double(tVec0(4) >= 12);            
                tVec = [tVec0(4:5)-[12*isPM,0],isPM];
                if useFull; tVec = [tVec0(1:3),tVec]; end
            end
            
        end
        
    end
    
end