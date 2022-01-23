classdef ConcatExptClass < handle
    
    % class properties
    properties
        % input arguments
        fObj
        sInfo
        
        % object property handles
        hFig
        hTable
        jTable
        hPopup
        hEdit
        hBut
        hPanelI
        hPanelEx
        hMenu
        
        % other important fields
        T0
        Tf
        tDur
        dtExpt
        iGrp
        Data
        bgCol
        isComb
        expFile = '';
        dtMax = [1,0,0,0];
        
        % fixed object dimensions
        dX = 10;
        dXH = 5;
        nCol = 6;
        fSz = 12;        
        nRowMx = 8;
        widFig = 640;
        widPopup = 90;
        widTxtI = 230;
        widTxtEx = 175;
        widEditEx = 290;
        widButEx = 130;
        hghtFig = 300;
        hghtPopup = 22;
        hghtTxt = 16;
        hghtBut = 25;
        hghtEdit = 22;
        hghtTable = 166;
        hghtPanelEx = 40;
        hghtPanelI = 230
        
        % dependent object dimensions
        nExpt
        widPanel
        isChange = false;
        
    end
    
    % class methods
    methods
        % --- class constructor
        function obj = ConcatExptClass(fObj)
            
            % sets the input arguments
            obj.fObj = fObj;
            obj.sInfo = fObj.sInfo;
            
            % initialises the class fields/GUI properties
            obj.initClassFields();
            obj.initObjProps()
            
            % centres the figure and makes it visible
            centreFigPosition(obj.hFig,2);
            setObjVisibility(obj.hFig,1);            
            
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
           
            % memory allocation
            obj.widPanel = obj.widFig - 2*obj.dX;  
            
            % resets the group names for each experiment
            for i = 1:length(obj.sInfo)
                obj.sInfo{i}.snTot.iMov.pInfo.gName = obj.sInfo{i}.gName;
            end
            
            % sets up the experimental info data fields
            obj.setupExptDataFields();
                            
            % determines which experiments can feasibly be concatenated
            obj.detCombineFeas();            
            
        end             
        
        % --- initialises the class fields
        function initObjProps(obj)
            
            % deletes any previous GUIs
            hPrev = findall(0,'tag','figConcateExpt');
            if ~isempty(hPrev); delete(hPrev); end            
           
            % --------------------------- %
            % --- MAIN FIGURE OBJECTS --- %
            % --------------------------- %            
            
            % creates the figure object
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % creates the figure object
            obj.hFig = figure('Position',fPos,'tag','figConcateExpt',...
                              'MenuBar','None','Toolbar','None',...
                              'Name','Experiment Concatenation Info',...
                              'NumberTitle','off','Visible','off',...
                              'Resize','off');   
            
            % ------------------------- %
            % --- MENU ITEM OBJECTS --- %
            % ------------------------- %            
            
            % creates the menu items
            obj.hMenu = uimenu(obj.hFig,'Label','File','Tag','menuFile');
            uimenu(obj.hMenu,'Label','Exit','Callback',{@obj.menuExit});
                          
            % --------------------------------------------------- %
            % --- EXPERIMENT CONCATENATION INFO PANEL OBJECTS --- %
            % --------------------------------------------------- %
                         
            % other initialisations
            txtStr = 'Combined Experiment Name:';            
            
            % creates the experiment combining data panel 
            pPosEx = [obj.dX,obj.dX,obj.widPanel,obj.hghtPanelEx];
            obj.hPanelEx = uipanel(obj.hFig,'Title','','Units',...
                                            'Pixels','Position',pPosEx); 
                                        
            % creates the text labels
            txtPosI = [obj.dXH,obj.dX+2,obj.widTxtEx,obj.hghtTxt];
            uicontrol(obj.hPanelEx,'Style','Text','String',txtStr,...
                            'FontWeight','Bold','FontUnits','Pixels',...
                            'FontSize',obj.fSz,'Position',txtPosI,...
                            'HorizontalAlignment','right');  
            
            % creates the edit labels            
            cbFcnEdit = {@obj.editCombName};            
            x0E = sum(txtPosI([1,3])) + obj.dXH;
            editPos = [x0E,obj.dX-1,obj.widEditEx,obj.hghtEdit];
            obj.hEdit = uicontrol(obj.hPanelEx,'Position',editPos,...
                            'Style','Edit','String','','Callback',...
                            cbFcnEdit,'HorizontalAlignment','left');    
                              
            % creates the button object
            butStr = 'Combine Selected';
            cbFcnBut = {@obj.buttonCombExpt};
            x0B = sum(editPos([1,3])) + obj.dXH;
            butPos = [x0B,obj.dX-2,obj.widButEx,obj.hghtBut];
            obj.hBut = uicontrol(obj.hPanelEx,'String',butStr,...
                            'FontWeight','Bold','FontUnits','Pixels',...
                            'FontSize',obj.fSz,'Position',butPos,...
                            'Callback',cbFcnBut);                                         
            
            % -------------------------------------------- %
            % --- EXPERIMENT INFORMATION PANEL OBJECTS --- %
            % -------------------------------------------- %                                       
            
            % other initialisations
            tMax = [10,23,59,59];
            cbFcnP = {@obj.popupDurChange};
            lStr = {'Days','Hours','Minutes','Seconds'};
            txtStrI = 'Max Inter-Experiment Time Difference: ';
            
            % creates the experiment information panel 
            y0 = sum(pPosEx([2,4])) + obj.dX;
            pPosI = [obj.dX,y0,obj.widPanel,obj.hghtPanelI];
            obj.hPanelI = uipanel(obj.hFig,'Title','','Units',...
                                           'Pixels','Position',pPosI);                                                                   
            
            % creates the text labels
            txtPosI = [obj.dXH,obj.dX,obj.widTxtI,obj.hghtTxt];
            uicontrol(obj.hPanelI,'Style','Text','String',txtStrI,...
                            'FontWeight','Bold','FontUnits','Pixels',...
                            'FontSize',obj.fSz,'Position',txtPosI,...
                            'HorizontalAlignment','right'); 
                        
            % creates the popup menu items
            for i = 1:length(tMax)
                % sets the x-location of the label/popupmenu
                xLbl = 235 + (i-1)*(obj.dXH + obj.widPopup);                
                
                % creates the popupmenu object
                iVal = obj.dtMax(i) + 1;
                pStr = arrayfun(@num2str,(0:tMax(i))','un',0);
                txtPosP = [xLbl,obj.dX-2,obj.widPopup,obj.hghtPopup];
                uicontrol(obj.hPanelI,'Style','PopupMenu','String',pStr,...
                                  'Callback',cbFcnP,'UserData',i,...
                                  'Position',txtPosP,'Value',iVal);
                                  
                % creates the popupmenu object
                txtPosL = [xLbl,3*obj.dX+2,obj.widPopup,obj.hghtTxt];
                uicontrol(obj.hPanelI,'Style','Text','String',lStr{i},...
                                  'Position',txtPosL,'FontWeight','Bold',...
                                  'FontUnits','Pixels','FontSize',obj.fSz,...
                                  'HorizontalAlignment','center');                                  
            end
            
            % disables the panels
            setPanelProps(obj.hPanelEx,'off')
            
            % -------------------------------------------- %
            % --- EXPERIMENT INFORMATION PANEL OBJECTS --- %
            % -------------------------------------------- %  
            
            % other initialisations
            y0T = 55;            
            
            % table properties
            colWid = {193,105,105,70,70,55};                        
            colEdit = [false(1,obj.nCol-1),true];
            colNames = {'Experiment','Start Time','Finish Time',...
                        'Duration','Difference','Include?'};
            colForm = [repmat({'char'},1,obj.nCol-1),{'logical'}];            
                    
            % creates the table object              
            tabPos = [obj.dX,y0T,obj.widPanel-2*obj.dX,obj.hghtTable];            
            obj.hTable = uitable(obj.hPanelI,'Position',tabPos,...
                        'ColumnName',colNames,'ColumnFormat',colForm,...
                        'ColumnEditable',colEdit,'RowName',[],...                            
                        'CellEditCallback',{@obj.tableExptInfo},...
                        'ColumnWidth',colWid,'tag','hTable');

            % sets up the table data fields
            obj.setupExptTableData(true);
            autoResizeTableColumns(obj.hTable);          
            
        end        
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %
        
        % --- callback function for altering the expt information table
        function tableExptInfo(obj,~,event)
            
            % retrieves the selected row index
            mStr = [];
            iRow = event.Indices(1);
            obj.isComb(iRow) = event.NewData;                                        
            
            % determines if the selected experimental is feasible
            if obj.iGrp(iRow) == 0
                mStr = ['Error! The selected experiment can''t be ',...
                        'concatenated with another.'];

            elseif length(unique(obj.iGrp(obj.isComb))) > 1
                mStr = ['Error! It is not possible to concatenate ',...
                        '2 different group types.'];
            end
            
            % determines if more than one group has been selected         
            if ~isempty(mStr)
                % outputs an error message to screen
                tStr = 'Infeasible Selection';
                waitfor(msgbox(mStr,tStr,'modal'))
                
                % if so, then reset the field value and exit
                obj.isComb(iRow) = false;
                
                % resets the table value
                DataT = get(obj.hTable,'Data');
                DataT{iRow,end} = false;
                set(obj.hTable,'Data',DataT)
                
                % exits the function
                return
            end
            
            % updates the button enabled properties
            obj.Data{iRow,end} = obj.isComb(iRow);
            setPanelProps(obj.hPanelEx,sum(obj.isComb)>1);
            
        end     
        
        % --- max duration popup menu item
        function popupDurChange(obj,hObject,~)
            
            % updates the max duration field
            nwVal = get(hObject,'Value') - 1;
            obj.dtMax(get(hObject,'UserData')) = nwVal;
            
            % resets the table data fields
            obj.detCombineFeas();
            obj.setupExptTableData();            
            
        end        
        
        % --- max duration popup menu item
        function editCombName(obj,hObject,~)
            
            % retrieves the new string
            nwStr = get(hObject,'String');
            
            % determines if the new string if valid
            if chkDirString(nwStr)
                % if so, then update the field
                obj.expFile = nwStr;
            else
                % otherwise, reset to the previous valid string
                set(hObject,'String',obj.expFile);
            end
            
        end
        
        % --- max duration popup menu item
        function buttonCombExpt(obj,hObject,event)
            
            % determines if the experiment name has been set
            if isempty(obj.expFile)
                % if not, then output an error to screen and exit
                mStr = ['Error! The combined experiment name ',...
                        'has not been set.'];
                waitfor(msgbox(mStr,'Empty Name Field','modal'))
                return
            end
            
            % determines if the included experiments are contiguous
            jGrp = getGroupIndex(obj.isComb);
            if length(jGrp) > 1
                % if not, output an error message to screen and exit
                mStr = 'Error! The selected experiments are not contiguous';
                waitfor(msgbox(mStr,'Concatenation Error','modal'));
                return
            end
            
            % creates a progress loadbar
            hLoad = ProgressLoadbar('Concatenating Experiment Data...');
            
            % concatenates the experimental data 
            obj.concatExptData();
            
            % sets up the experimental info data fields
            obj.setupExptDataFields();
                            
            % determines which experiments can feasibly be concatenated
            obj.detCombineFeas();
            obj.setupExptTableData();
            
            % house-keeping exercises
            obj.isChange = true;
            set(obj.hEdit,'String','');
            setPanelProps(obj.hPanelEx,'off');
            
            % closes the loadbar
            delete(hLoad)            
            
        end        
        
        % --- callback function for the close GUI menu item
        function menuExit(obj,~,~)
            
            % determines if any experiments were concatenated
            if obj.isChange 
                % if so, prompt the user if they want to apply said changes
                qStr = 'Are you sure you want to apply the changes?';
                uChoice = questdlg(qStr,'Update Changes?','Yes',...
                                        'No','Cancel','Yes');
                switch uChoice
                    case 'Yes'
                        % updates the main GUI  
                        obj.fObj.sInfo = obj.sInfo;
                        obj.fObj.updateSolnFileGUI(true);
                        obj.fObj.tableUpdate = true;
                        jTableMod = obj.fObj.jTable.getModel();
                        
                        % removes any excess rows
                        pause(0.05);
                        nRow0 = obj.fObj.jTable.getRowCount;
                        iRow0 = max(obj.fObj.nExp+1,obj.fObj.nExpMax+1);
                        for i = iRow0:nRow0
                            rmvInd = obj.fObj.jTable.getRowCount-1;
                            jTableMod.removeRow(rmvInd)
                            obj.fObj.jTable.repaint()
                        end
                        
                        % removes/clears the rows                        
                        for i = (obj.fObj.nExp+1):obj.fObj.nExpMax
                            obj.fObj.clearExptInfoTableRow(i) 
                        end

                        % resets the column widths
                        pause(0.05);
                        obj.fObj.resetExptTableBGColour(0);
                        obj.fObj.resetColumnWidths()

                        % repaints the table
                        obj.fObj.jPanel.repaint()
                        obj.fObj.jTable.repaint()            

                        % resets the table update flag
                        pause(0.05);
                        obj.fObj.tableUpdate = false;
                        
                    case 'Cancel'
                        % if the user cancelled, then exit
                        return
                
                end
            end
            
            % deletes the GUI
            delete(obj.hFig);
            
        end                       
        
        % --- concatenates the experimental data
        function concatExptData(obj)
            
            % sets the indices for the combining and pre/post experiments
            indC = find(obj.isComb);
            [i1,i2] = deal((1:(indC(1)-1))',((indC(end)+1):obj.nExpt)');
            
            % sets the combined solution data
            sInfoC = obj.sInfo(indC);
            sInfoNw = sInfoC{1};
            sInfoC{1} = [];
            
            % other initialisations
            nApp = length(sInfoNw.snTot.iMov.iR);
            
            % concatenates the data for each of the other experiments
            for i = 2:length(sInfoC)
                % combines the other fields
                dT = nanmedian(diff(sInfoNw.snTot.T{end}));
                tOfs = obj.dtExpt(indC(i)) + sInfoNw.snTot.T{end}(end);
                TNw = cellfun(@(x)(x+tOfs),sInfoC{i}.snTot.T,'un',0);
                
                % combines the time-point arrays
                TGap = [sInfoNw.snTot.T{end}(end);TNw{1}(1)] + dT*[1;-1];
                sInfoNw.snTot.T = [sInfoNw.snTot.T;TGap;TNw];                
                
                % appends the x/y-coordinate data
                for j = 1:nApp
                    % appends the x-coordinate data
                    if ~isempty(sInfoC{i}.snTot.Px)
                        xGap = NaN(2,size(sInfoNw.snTot.Px{j},2));
                        sInfoNw.snTot.Px{j} = [sInfoNw.snTot.Px{j};xGap;...
                                               sInfoC{i}.snTot.Px{j}];
                    end
                    
                    % appends the y-coordinate data
                    if ~isempty(sInfoC{i}.snTot.Py)
                        yGap = NaN(2,size(sInfoNw.snTot.Py{j},2));
                        sInfoNw.snTot.Py{j} = [sInfoNw.snTot.Py{j};yGap;...
                                               sInfoC{i}.snTot.Py{j}];                        
                    end                    
                end
                
                % concatenates the experimental stimuli data
                if ~isempty(sInfoC{i}.snTot.stimP)                    
                    sInfoNw = obj.concatStimInfo(sInfoNw,sInfoC{i},tOfs);
                end
                
                % combines the main struct fields                
                if i == length(sInfoC)
                    % resets the duration fields
                    sInfoNw.tDur = floor(sInfoNw.snTot.T{end}(end));
                    sInfoNw.tDurS = getExptDurString(sInfoNw.tDur);
                    
                    % resets the 
                    nVid = length(sInfoNw.snTot.T);
                    nFrmF = length(sInfoNw.snTot.T{end});
                    sInfoNw.iPara.indF = [nVid,nFrmF];
                    
                    % sets the final location time vectors
                    sInfoNw.iPara.Tf = sInfoC{i}.iPara.Tf;
                    sInfoNw.iPara.Tf0 = sInfoC{i}.iPara.Tf0;
                    
                    % updates the day/night flags
                    isDayNw = detDayNightTimePoints(sInfoNw.snTot);
                    sInfoNw.snTot.isDay = isDayNw;
                end
                
                % removes the temporary field
                sInfoC{i} = [];
            end              
                
            % resets the ID flag for the new data struct    
            sInfoNw.iTab = 2;
            sInfoNw.iID = length(i1) + 1;
            sInfoNw.expFile = obj.expFile;
            sInfoNw.expInfo = obj.fObj.initExptInfo(sInfoNw);
            
            % resets the ID flags for the subsequent experiments
            diID = length(indC);
            for i = (sInfoNw.iID+2):length(obj.sInfo)
                obj.sInfo{i}.iID = obj.sInfo{i}.iID - diID;
            end            
            
            % sets the final re-ordered array
            obj.sInfo = [obj.sInfo(i1);sInfoNw;obj.sInfo(i2)];            
            
        end
        
        % ------------------------------------------------ %
        % --- EXPERIMENTAL DATA FIELD UPDATE FUNCTIONS --- %
        % ------------------------------------------------ %          
        
        % --- resets the experiment data fields
        function setupExptDataFields(obj)
            
            % creates the table data array
            obj.nExpt = length(obj.sInfo);
            obj.Data = cell(obj.nExpt,obj.nCol);
            obj.isComb = false(obj.nExpt,1);
            
            % retrieves the information for each experiment
            exInfo = cellfun(@(x)(x.expInfo),obj.sInfo,'un',0);
            
            % retrieves the start/finish times for each expt
            obj.T0 = cellfun(@(x)(x.T0vec),exInfo,'un',0);
            obj.Tf = cellfun(@(x)(x.Tfvec),exInfo,'un',0);
            
            % sorts the experiments in chronological order
            [~,iS] = sort(cellfun(@(x)(datenum(x)),obj.T0));
            obj.sInfo = obj.sInfo(iS);
            [obj.T0,obj.Tf] = deal(obj.T0(iS),obj.Tf(iS));
            
            % retrieves/calculates the other fields
            obj.tDur = cellfun(@(x)(x.tDur),obj.sInfo);
            obj.dtExpt = [0;cellfun(@(t0,tf)(etime(t0,tf)),...
                                obj.T0(2:end),obj.Tf(1:end-1))];            
            
        end        
        
        % --- determines which experiments can be concatenated feasibly
        function detCombineFeas(obj)
            
            % retrieves the configuration info from each experiment
            isFound = false(obj.nExpt,1);
            [j0,obj.iGrp] = deal(1,zeros(obj.nExpt,1));
            inTol = obj.dtExpt < vec2sec(obj.dtMax);
            
            % sets up the region configuration structs
            pInfo = cellfun(@(x)(x.snTot.iMov.pInfo),obj.sInfo,'un',0);
            for i = 1:length(pInfo)
                pInfo{i} = rmfield(pInfo{i},'iGrp');
            end
            
            % keep looping until all experiments have been searched
            while any(~isFound)
                % determines the next experiment to search
                i0 = find(~isFound,1,'first');
                ii = (i0+1):obj.nExpt;
                
                % determines which subsequent experiments have the same 
                % region information data structs
                isEq = cellfun(@(x)(isequal(x,pInfo{i0})),pInfo(ii));
                if any(isEq)
                    % determines feasible groupings which are within the
                    % time tolerance
                    kGrp = getGroupIndex(isEq & inTol(ii));
                    if ~isempty(kGrp) && any(kGrp{1} == 1)                    
                        % if there is a match, then update the group match
                        jj = ii(isEq(kGrp{1}));
                        [obj.iGrp([i0,jj]),isFound(jj)] = deal(j0,true);
                        j0 = j0 + 1;
                    end
                end
                
                % update found flag for the candidate flag
                isFound(i0) = true;
            end
            
        end
        
        % --- sets up the experimental info table data fields
        function setupExptTableData(obj,isInit)
            
            % sets the initialisation flag
            if ~exist('isInit','var'); isInit = false; end
                            
            % sets the duration and start/finish time strings            
            tDurS = arrayfun(@(x)(getExptDurString(x)),obj.tDur,'un',0);
            T0Str = cellfun(@(x)(obj.getDateString(x)),obj.T0,'un',0);
            TfStr = cellfun(@(x)(obj.getDateString(x)),obj.Tf,'un',0);            
            
            % calculates the time difference between experiments
            dtExptStr = arrayfun(@(x)...
                                (getExptDurString(x)),obj.dtExpt,'un',0);                                                    
            dtExptStr{1} = '***';
                            
            % sets up the table data array
            obj.Data(:,1) = cellfun(@(x)(x.expFile),obj.sInfo,'un',0);
            obj.Data(:,2) = T0Str;
            obj.Data(:,3) = TfStr;
            obj.Data(:,4) = tDurS;
            obj.Data(:,5) = dtExptStr;  
            
            % sets the inclusion flag column
            if isInit
                obj.Data(:,end) = {false};
            else
                obj.isComb(obj.iGrp == 0) = false;
                obj.Data(:,end) = num2cell(obj.isComb);
            end
            
            % centres the table data
            obj.Data(:,4:5) = centreTableData(obj.Data(:,4:5));            

            % updates the table data/colour
            bgColNw = obj.setupTableColour();
            set(obj.hTable,'Data',obj.Data,'BackgroundColor',bgColNw)            
            
        end            
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %  
        
        % --- sets up the table background colours
        function bgCol = setupTableColour(obj)
            
            bgCol0 = getAllGroupColours(max(obj.iGrp));
            bgCol = cell2mat(arrayfun(@(x)(bgCol0(x+1,:)),obj.iGrp,'un',0));
            
        end                
        
    end
   
    % static class methods
    methods (Static)
        
        % --- converts the date vector to a string
        function dStr = getDateString(tVec)
            
            dStr = datestr(datenum(tVec),'dd-mmm-yy HH:MM:SS');
            
        end            
        
        % --- concatenates the stimuli timing information
        function sInfo0 = concatStimInfo(sInfo0,sInfoNw,dT)
            
            % sets the base/new stimuli protocols
            stimP0 = sInfo0.snTot.stimP;
            stimPNw = sInfoNw.snTot.stimP;
            
            % loops through each of the devices concatenating the data
            dType = fieldnames(stimP0);
            for i = 1:length(dType)
                % retrieves the base/new data fields
                dInfo0 = getStructField(stimP0,dType{i});
                dInfoNw = getStructField(stimPNw,dType{i});
                
                % loops through each channel appending the information
                chType = fieldnames(dInfo0);
                for j = 1:length(chType)
                    % retrieves the channel data information
                    chInfo0 = getStructField(dInfo0,chType{j});
                    chInfoNw = getStructField(dInfoNw,chType{j});
                    
                    % appends the stimuli data for the channel
                    chInfo0.Ts = [chInfo0.Ts;(chInfoNw.Ts + dT)];
                    chInfo0.Tf = [chInfo0.Tf;(chInfoNw.Tf + dT)];
                    chInfo0.iStim = [chInfo0.iStim;chInfoNw.iStim];
                    
                    % resets the channel data information
                    dInfo0 = setStructField(dInfo0,chType{j},chInfo0);
                end
                
                % resets the device information
                stimP0 = setStructField(stimP0,dType{i},dInfo0);
            end
            
            % resets the stimuli protocols for the base solution struct
            sInfo0.snTot.stimP = stimP0;            
            
        end
        
    end
end