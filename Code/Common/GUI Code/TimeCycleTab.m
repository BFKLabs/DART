classdef TimeCycleTab < dynamicprops & handle
    
    % class properties
    properties
        
        % parent class fields
        hTab
        iTab
        exName
        tcPara
        tcPara0
        
        % main parameter object fields
        hPanelP
        hPanelBG
        hRadio
        hPanelN
        hPanelF
        hPanelV
        hTableV
        jTableV
        hButV
        hButM
        hChkP
        hChkF
        
        % fixed dimension fields
        widTxtF = 95;     
        widTxtP = 130;        
        widTxtNL = 45;
        
        % panel object dimension fields        
        widPanelT
        widPanelO
        widPanelI
        
        % other object calclated dimension fields         
        widEditF      
        widRadio
        widChkP
        widPopupP
        widButV
        widTableV
        
        % other class fields
        tCycleA = [];        
        
        % boolean class fields
        isFixedDur
        isInit = false;
        useRelTime = true;        
        
        % static scalar fields
        nRow = 1;                
        
        % static character fields
        tStrF0 = 'Cycle (h): ';        
        tStrF = {'Light','Dark'};        
        pStrF = {'tOn','tOff'};
        pStrP = {'tCycle0','useRelTime'};
        bStrM = {char(9650),char(9660)};
        bStrV = {'Add','Remove','Reset'};
        cHdrV = {'Light Cycle (h)','Dark Cycle (h)'};        
        rStrR0 = 'Light/Dark Cycle Duration';
        tStrTL = 'Name: ';
        
    end
    
    % private class properties
    properties (Access = private)
        
        objB
        
    end    
    
    % class methods
    methods
    
        % --- class constructor
        function obj = TimeCycleTab(objB,iTab)
        
            % sets the input arguments
            obj.objB = objB;
            obj.iTab = iTab;
            obj.exName = objB.exName{iTab};
            [obj.tcPara,obj.tcPara0] = deal(objB.tcPara0{iTab});
            
            % initialises the class objects and fields
            obj.linkParentProps();
            obj.initClassFields();
            obj.initClassObjects();
            
            % flag that the object has been initialised
            obj.isInit = true;
            
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class object fields with that parent object
        function linkParentProps(obj)
            
            % parent fields strings
            fldStr = {'hTabG','hButC','isUpdating','canClick',...
                      'dX','nParaF','nButV','nButM','nParaP',...  
                      'hghtPanelBG','hghtPanelV','hghtPanelF',...
                      'hghtTableV','hghtPanelP','hghtPanelN',...
                      'hghtBut','hghtRadio','hghtTxt','hghtEdit',...
                      'hghtRow','hghtPopup','hghtChk','fSzL','fSz'};
            
            % connects the base/child objects
            for propname = fldStr
                metaprop = addprop(obj, propname{1});
                metaprop.SetMethod = @(obj, varargin) ...
                    SetDispatch(obj, propname{1}, varargin{:});
                metaprop.GetMethod = @(obj)GetDispatch(obj, propname{1});
            end            
            
        end
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % memory allocation
            obj.hRadio = cell(2,1);
            obj.hButV = cell(obj.nButV,1);
            obj.hButM = cell(obj.nButM,1);
            
            % calculated object dimensions
            obj.widPanelT = obj.hTabG.Position(3);
            obj.widPanelO = obj.widPanelT - obj.dX;
            obj.widPanelI = obj.widPanelO - obj.dX;            
            obj.widRadio = obj.widPanelO - 2*obj.dX;
            
            % parameter panel objects
            obj.widChkP = obj.widPanelO - 2*obj.dX;
            obj.widPopupP = (obj.widPanelO - (obj.widTxtP + 3*obj.dX))/3;                        
            
            % fixed duration panel objects
            obj.widEditF = (obj.widPanelI - (1.5*obj.dX + 2*obj.widTxtF))/2;
            
            % variable duration panel objects            
            obj.widTableV = obj.widPanelI - (2*obj.dX + obj.hghtBut);
            obj.widButV = (obj.widPanelI - ...
                (1 + (obj.nButV-1)/2)*obj.dX)/obj.nButV;            
            
            % sets the row count
            obj.nRow = size(obj.tcPara.tCycleR,1);
            obj.recalcAbsTimes();
            
            % sets the fixed duration flag
            obj.recalcFixedDurFlag();
            
        end        
        
        % --- initialises the class objects
        function initClassObjects(obj)            
            
            % ----------------------------- %
            % --- MAIN TAB OBJECT SETUP --- %
            % ----------------------------- %
            
            % creates the tab object
            tStr = sprintf('Expt #%i',obj.iTab);
            obj.hTab = createNewTabPanel(...
                obj.hTabG,1,'title',tStr,'UserData',obj.iTab);
            
            % --------------------------------------- %
            % --- VARIABLE DURATION PANEL OBJECTS --- %
            % --------------------------------------- %
            
            % initialisations
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
            pPosBG = [obj.dX*[1,1]/2,obj.widPanelO,obj.hghtPanelBG];
            obj.hPanelBG = createUIObj(...
                'ButtonGroup',obj.hTab,'Title','','Position',pPosBG,...
                'SelectionChangedFcn',@obj.panelSelectChanged);
            
            % creates the panel object
            pPosV = [obj.dX*[1,1]/2,obj.widPanelI,obj.hghtPanelV];
            obj.hPanelV = createUIObj(...
                'Panel',obj.hPanelBG,'Title','','Position',pPosV);
            
            % creates the push-button objects
            for i = 1:obj.nButV
                % sets up the position vector
                lPosB = obj.dX*(i/2) + (i-1)*obj.widButV;
                pPosB = [lPosB,obj.dX-2,obj.widButV,obj.hghtBut];
                
                % creates the button object
                obj.hButV{i} = createUIObj('pushbutton',obj.hPanelV,...
                    'String',obj.bStrV{i},'Position',pPosB,...
                    'FontWeight','Bold','FontSize',obj.fSzL,...
                    'ButtonPushedFcn',cbFcnB{i});
            end
            
            % variable table object
            pPosTV = [obj.dX*[0.5,4],obj.widTableV,obj.hghtTableV];
            obj.hTableV = createUIObj('table',obj.hPanelV,...
                'Position',pPosTV,'ColumnEdit',true,...
                'CellSelectionCallback',@obj.tableCellSelect,...
                'CellEditCallback',@obj.tableCellEdit,...
                'KeyPressFcn',@obj.tableKeyPress,...
                'KeyReleaseFcn',@obj.tableKeyRelease,...
                'ColumnName',obj.cHdrV,'ColumnFormat',cForm,...
                'ColumnEditable',cEdit,'Data',tDataV,...
                'BackgroundColor',ones(1,3));
            
            % creates the list reorder buttons
            lPosM = sum(pPosTV([1,3])) + obj.dX/2;
            for i = 1:obj.nButM
                % sets up the button positional vector
                yPosM = mean(pPosTV([2,4])) + 1.5*(1-2*(i-1))*obj.dX;
                pPosM = [lPosM,yPosM,obj.hghtBut*[1,1]];
                
                % creates the button object
                obj.hButM{i} = createUIObj('pushbutton',obj.hPanelV,...
                    'ButtonPushedFcn',{@obj.buttonReorderCycle,i==2},...
                    'String',obj.bStrM{i},'Position',pPosM,...
                    'FontWeight','Bold','FontSize',obj.fSzL,...
                    'Enable','off');
            end
            
            % creates the radio button
            [obj.hRadio{2},pPosRV] = ...
                obj.createRadioButton('Variable',sum(pPosV([2,4])));
            
            % automatically resizes the table
            autoResizeTableColumns(obj.hTableV);
             
            % ------------------------------------ %
            % --- FIXED DURATION PANEL OBJECTS --- %
            % ---------------------------\--------- %
            
            % creates the panel object
            yPosF = sum(pPosRV([2,4]));
            pPosF = [obj.dX/2,yPosF,obj.widPanelI,obj.hghtPanelF];
            obj.hPanelF = createUIObj(...
                'Panel',obj.hPanelBG,'Title','','Position',pPosF);
            
            % creates the checkbox object
            tStrC = 'Fix Light/Dark Cycle Duration To 24 Hours';
            pPosC = [obj.dX,obj.dX/2-1,obj.widChkP,obj.hghtChk];
            obj.hChkF = createUIObj('checkbox',obj.hPanelF,...
                'Position',pPosC,'Value',obj.isFixedDur,...
                'FontWeight','Bold','FontSize',obj.fSzL,...
                'Callback',@obj.checkFixCycleDur,...
                'String',tStrC);                        
            
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
            tStrP = {'Light Cycle Start Time: ',...
                     'Define Variable Cycles Using Relative Time'};
            
            % creates the panel object
            yPosP = sum(pPosBG([2,4])) + obj.dX/2;
            pPosP = [obj.dX/2,yPosP,obj.widPanelO,obj.hghtPanelP];
            obj.hPanelP = createUIObj(...
                'Panel',obj.hTab,'Title','','Position',pPosP);
            
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
                    pPosC = [obj.dX,yObj0,obj.widChkP,obj.hghtChk];
                    obj.hChkP = createUIObj('checkbox',obj.hPanelP,...
                        'String',tStrP{i},'Position',pPosC,...
                        'FontWeight','Bold','FontSize',obj.fSzL,...
                        'UserData',obj.pStrP{i},'Value',pVal,...
                        'Callback',@obj.checkGenPara);
                end
            end
            
            % ------------------------------------- %
            % --- EXPERIMENT NAME PANEL OBJECTS --- %
            % ------------------------------------- %  
            
            % field retrieval
            
            
            % creates the panel object
            yPosN = sum(pPosP([2,4])) + obj.dX/2;
            pPosN = [obj.dX/2,yPosN,obj.widPanelO,obj.hghtPanelN];
            obj.hPanelN = createUIObj(...
                'Panel',obj.hTab,'Title','','Position',pPosN);            
            
            % creates the experiment label
            yPosNL = obj.dX/2 + 3;
            pPosNL = [obj.dX/2,yPosNL,obj.widTxtNL,obj.hghtTxt];
            createUIObj('text',obj.hPanelN,'Position',pPosNL,...
                'FontWeight','Bold','FontUnits','Pixels',...
                'FontSize',obj.fSzL,'HorizontalAlignment','Right',...
                'String',obj.tStrTL);   
            
            % creates the experiment name field
            lPosN = sum(pPosNL([1,3]));
            widTxtN = obj.widPanelO - (obj.dX + obj.widTxtNL);
            pPosN = [lPosN,yPosNL,widTxtN,obj.hghtTxt];
            createUIObj('text',obj.hPanelN,'Position',pPosN,...
                'FontWeight','Normal','FontUnits','Pixels',...
                'FontSize',obj.fSzL,'HorizontalAlignment','Left',...
                'String',obj.exName);
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % updates the button group selection properties
            set(obj.hRadio{1},'Value',obj.tcPara.isFixed);
            obj.panelSelectChanged(obj.hPanelBG,[]);
            
            % retrieves the table java handle
            jScroll = findjobj(obj.hTableV);
            obj.jTableV = jScroll.getComponent(0).getComponent(0);
            
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
            
            % calculates the left/bottom locations
            yPosT = obj.dX + obj.hghtRow;            
            lPosT = (iRow - 1)*(obj.widTxtF + obj.widEditF) + obj.dX/2;
            
            % creates the text objects
            pPosT = [lPosT,yPosT-1,obj.widTxtF,obj.hghtTxt];
            tStrT = sprintf('%s %s',obj.tStrF{iRow},obj.tStrF0);            
            createUIObj('text',obj.hPanelF,'Position',pPosT,...
                'FontWeight','Bold','FontUnits','Pixels',...
                'FontSize',obj.fSzL,'HorizontalAlignment','Right',...
                'String',tStrT);
            
            % creates the edit objects
            lPosE = sum(pPosT([1,3]));
            pValE = num2str(obj.tcPara.(obj.pStrF{iRow}));
            pPosE = [lPosE,yPosT-3,obj.widEditF,obj.hghtEdit];
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
                            xiT = (1:12)';
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
            iOfs = double(hPopup.UserData > 1);
            obj.tcPara.tCycle0(hPopup.UserData) = hPopup.Value - iOfs;
                        
            % resets the table data
            obj.recalcAbsTimes();
            obj.resetTableData();            
                        
            % updates the other fields
            setObjEnable(obj.hButV{2},0);
            obj.objB.setUpdateParaProps();            
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
                setObjEnable(obj.hButV{2},obj.nRow>1);                
                
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
                obj.objB.setUpdateParaProps();
                
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
            if obj.nRow > 1
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
            obj.objB.setUpdateParaProps();
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
            obj.objB.setUpdateParaProps();
            setObjEnable(obj.hButV{3},obj.nRow>1);
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
            [obj.tcPara.tCycleR,obj.tCycleA] = deal({12,12});
            obj.hTableV.Data = obj.tcPara.tCycleR;
            
            % updates the other fields
            obj.nRow = 1;
            
            % sets the button properties               
            obj.objB.setUpdateParaProps();            
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
            obj.objB.setUpdateParaProps();
            setObjEnable(obj.hButV{2},iRow > 0);
            
            % updates the button properties               
            obj.setReorderButtonProps(iRowNw);
            
            % resets the table selection
            drawnow            
            obj.jTableV.changeSelection(iRowNw-1,iCol-1,0,0)
            
        end        
        
        % --------------------------------------- %
        % --- OTHER OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- panel selection change callback function
        function panelSelectChanged(obj,hPanel,~)
            
            % determines if the cycle duration is fixed
            hRadioS = hPanel.SelectedObject;
            obj.tcPara.isFixed = strcmp(hRadioS.UserData,'Fixed');
                        
            % updates the panel properties based on choice
            if obj.tcPara.isFixed
                % case is fixed cycle duration
                setPanelProps(obj.hPanelF,1);
                setPanelProps(obj.hPanelV,0);
                
                % disables the update/reset buttons
                if obj.isInit
                    obj.objB.setUpdateParaProps();
                end
                
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
                setObjEnable(obj.hButV{3},obj.nRow > 1);
                obj.setReorderButtonProps(iRowP);
                
                % resets the update parameter button properties
                if obj.isInit
                    obj.objB.setUpdateParaProps();
                end
            end
            
        end        
        
        % --- cycle duration editbox callback function
        function editCycleDur(obj,hEdit,~)
            
            % field retrieval
            pStr = hEdit.UserData;            
            nwVal = str2double(hEdit.String);
            
            %
            if obj.isFixedDur
                nwLim = [0,24];
            else
                nwLim = [0,100];
            end
            
            % determines if the new value is valid
            if chkEditValue(nwVal,nwLim,0)
                % if so, then update the parameter value
                obj.tcPara.(pStr) = nwVal;                
                
                % updates the other parameter field (if fixed duration)
                if obj.isFixedDur
                    % sets the parameter string for the other field
                    switch pStr
                        case 'tOn'
                            pStrO = 'tOff';                            

                        case 'tOff'
                            pStrO = 'tOn';
                    end
                    
                    % resets the other parameter value
                    obj.tcPara.(pStrO) = 24 - nwVal;
                    hEdit = findall(obj.hPanelF,'UserData',pStrO);
                    hEdit.String = num2str(obj.tcPara.(pStrO));
                end
                
                % resets the update parameter properties
                obj.objB.setUpdateParaProps();
                
            else
                % otherwise, reset to the last valid value
                hEdit.String = num2str(obj.tcPara.(pStr));
            end
            
        end 
        
        % --- fixed cycle duration callback function
        function checkFixCycleDur(obj,hCheck,~)
            
            % updates the parameter value
            obj.isFixedDur = hCheck.Value;
            
            %
            if obj.isFixedDur
                % calculates the total cycle duration
                dTot = obj.tcPara.tOn + obj.tcPara.tOff;
                
                % if the total duration doesn't equal 24 hours, then reset
                % the duration parameters
                if dTot ~= 24
                    % initialisations
                    pTot = dTot/24;
                    pStrE = {'tOn','tOff'};
                    
                    % resets the parameter/editbox strings
                    for i = 1:length(pStrE)
                        % resets the parameter value
                        obj.tcPara.(pStrE{i}) = obj.tcPara.(pStrE{i})/pTot;
                        
                        % resets the corresponding editbox value
                        hEdit = findall(obj.hPanelF,'UserData',pStrE{i});
                        hEdit.String = num2str(obj.tcPara.(pStrE{i}));
                    end
                end
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

        % ------------------------------------------- %        
        % --- PARAMETER FIELD RESETTING FUNCTIONS --- %
        % ------------------------------------------- %
        
        % --- resets the time popup values
        function resetTimePopupValues(obj)
            
            % resets the popupmenu values
            hPP = findall(obj.hPanelP,'style','popupmenu');
            for j = 1:length(hPP)
                % retrieves the popup menu item
                i = hPP(j).UserData;
                iOfs = (i > 1);
                hPP(j).Value = obj.tcPara.tCycle0(i) + iOfs;
            end
            
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
        
        % --- resets the original parameters
        function resetOrigPara(obj)
           
            obj.tcPara0 = obj.tcPara;
            
        end        
        
        % --- resets all the parameter fields
        function resetAllParaFields(obj)
                        
            % resets the checkbox values
            obj.recalcFixedDurFlag();
            obj.hChkF.Value = obj.isFixedDur;
            obj.hChkP.Value = obj.useRelTime;
            
            % resets the fixed time cycle values
            for i = 1:length(obj.pStrF)
                hEdit = findall(obj.hPanelF,'UserData',obj.pStrF{i});
                hEdit.String = num2str(obj.tcPara.(obj.pStrF{i}));
            end
            
            % resets the radio button properties
            obj.hRadio{1}.Value = double(obj.tcPara.isFixed);
            obj.hRadio{2}.Value = double(~obj.tcPara.isFixed);
            obj.panelSelectChanged(obj.hPanelBG,[]);            
            
            % resets the other parameter fields
            obj.resetTimePopupValues();
            obj.resetTableData();
            drawnow
            
        end             
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
                
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
        function isOn = getUpdateParaProps(obj)
            
            % determines if the start time is the same
            [tcP,tcP0] = deal(obj.tcPara,obj.tcPara0);            
            isFC = ~isequal(tcP0.isFixed,tcP.isFixed);
            isOn = ~isequal(tcP0.tCycle0,tcP.tCycle0) || isFC;
            
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
                
            elseif ~tcP.isFixed
                isOn = ~isempty(tcP.tCycleR);
            end            
            
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
        
        % --- recalculates the fixed duration flag
        function recalcFixedDurFlag(obj)
            
            obj.isFixedDur = obj.tcPara.tOn + obj.tcPara.tOff == 24;
            
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
    
    % private class methods
    methods (Access = private)
        
        % --- sets a class object field
        function SetDispatch(obj, propname, varargin)
            obj.objB.(propname) = varargin{:};
        end
        
        % --- gets a class object field
        function varargout = GetDispatch(obj, propname)
            varargout{:} = obj.objB.(propname);
        end
        
    end    
    
end