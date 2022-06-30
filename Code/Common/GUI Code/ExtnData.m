classdef ExtnData < handle
    
    % class properties
    properties
        
        % main class fields
        hObjM  
        isCombine
                
        % gui object handles
        hFig        
        hPanel
        hBut
        hButC
        hTabP
        hTabEx
        hTabGrpP
        hTabGrpEx
        hMenuS
        hMenuC
        hMenuH
        hMenuR
        hMenuX
        
        % array class fields
        exD
        exDR
        exD0
        
        % scalar class fields
        nExp
        iExp = 1;
        iPara = NaN;
        
        % derived dimensions values                
        widFig
        hghtFig
        hghtTable
        
        % fixed parameter values
        dX = 10;
        dY = 25;
        tSz = 12;
        bSz = 25;
        hghtTxt = 16;
        hghtEdit = 22;
        widBut = 30;       
        widPanel = 400;
        hghtButC = 25;
        hghtPanelP = 330;
        hghtPanelC = 40;
        widTxtRC = 120; 
        widTxtF = 120;
        nRowT = 8;
        
    end
    
    % class methods
    methods
        
        % class constructor
        function obj = ExtnData(hObjM)
            
            % sets the input arguments
            obj.hObjM = hObjM;
            obj.isCombine = isa(hObjM,'matlab.ui.Figure');
            
            % initialises the class fields
            obj.initClassFields();
            obj.initClassObjects();
            
            % centres the figurea and makes it visible
%             centreFigPosition(obj.hFig);
            setObjVisibility(obj.hFig,1);
            
        end
        
        % --------------------------------------- %
        % --- CLASS OBJECT CREATION FUNCTIONS --- %
        % --------------------------------------- %        
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % global variables
            global H0T HWT
            
            % retrieves the solution data structs
            if obj.isCombine
                sInfo = getappdata(obj.hObjM,'sInfo');
            else
                sInfo = obj.hObjM.sInfo;
            end
            
            % memory allocation
            obj.nExp = length(sInfo);
            [obj.hTabGrpP,obj.hTabEx,obj.hTabP] = deal(cell(obj.nExp,1));
            
            % calculates the derived object dimensions
            obj.widFig = (obj.widPanel + obj.widBut) + 3*obj.dX;
            obj.hghtFig = obj.hghtPanelP + obj.hghtPanelC + 3*obj.dX;
            obj.hghtTable = H0T + obj.nRowT*HWT;
            
            % retrieves the external data from the solution data structs
            obj.exD = cell(obj.nExp,1);
            for i = 1:obj.nExp
                snTot = sInfo{i}.snTot;
                if isfield(snTot,'exD') && ~isempty(snTot.exD)
                    obj.exD{i} = snTot.exD;
                end
            end
            
            % sets a copy of the original parameters
            [obj.exDR,obj.exD0] = deal(obj.exD);
            
            % updates the parameter index field (if data available)
            if ~isempty(obj.exD{1})
                obj.iPara = 1;
            end
                
        end
        
        % --- initialises the class objects
        function initClassObjects(obj)
            
            % creates the figure object
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % removes any previous GUIs
            hFigPr = findall(0,'tag','figExtnData');
            if ~isempty(hFigPr); delete(hFigPr); end
            
            % creates the figure object
            fStr = 'External Data Input';
            obj.hFig = figure('Position',fPos,'tag','figExtnData',...
                              'MenuBar','None','Toolbar','None',...
                              'Name',fStr,'NumberTitle','off',...
                              'Visible','off','Resize','off',...
                              'CloseRequestFcn',@obj.closeFigure);                        

            % --------------------------------- %
            % --- ADD/REMOVE BUTTON OBJECTS --- %
            % --------------------------------- %
                                      
            % creates the add/delete parameter pushbuttons
            bStr = {char(8722),'+'};
            ttStr = {'Remove Data Field','Add Data Field'};
            cbFcnB = {@obj.deletePara,@obj.addPara};
            y0 = obj.hghtFig/2 - (obj.dX/2 + obj.widBut);
            yOfs = (obj.dX + obj.widBut);
                        
            for i = 1:length(cbFcnB)
                bPos = [obj.dX,y0+(i-1)*yOfs,obj.widBut*[1,1]];
                obj.hBut{i} = uicontrol(obj.hFig,'Style','Pushbutton',...
                       'String',bStr{i},'Units','Pixels','Position',bPos,...
                       'FontUnits','Pixels','FontSize',obj.bSz,...
                       'FontWeight','bold','HorizontalAlignment',...
                       'Center','ToolTipString',ttStr{i},...
                       'Callback',cbFcnB{i});
            end      
            
            % sets the remove button enabled properties
            setObjEnable(obj.hBut{1},~isempty(obj.exD{1}));                          
                          
            % ------------------------------------ %
            % --- OTHER CONTROL BUTTON OBJECTS --- %
            % ------------------------------------ %                            
                          
            % creates the control button panel
            lPos = 2*obj.dX + obj.widBut;
            pPosC = [lPos,obj.dX,obj.widPanel,obj.hghtPanelC];
            hPanelC = uipanel(obj.hFig,'Title','','Units',...
                                       'Pixel','Position',pPosC);
            
            % creates
            nStrBC = 3;
            bStrBC = {'Update Current','Update All','Close Window'};
            cFcnBC = {@obj.updateCurrent,@obj.updateAll,@obj.closeFigure};                               
            widButC = (obj.widPanel - (nStrBC+1)*obj.dX)/nStrBC;
            
            % creates the control button objects
            obj.hButC = cell(length(bStrBC),1);
            for i = 1:length(bStrBC)
                lPosC = obj.dX + (i-1)*(obj.dX + widButC);
                bPosC = [lPosC,obj.dX-2,widButC,obj.hghtButC];
                obj.hButC{i} = uicontrol(hPanelC,'Style','PushButton',...
                                'Units','Pixels','Position',bPosC,...
                                'Callback',cFcnBC{i},'FontWeight','Bold',...
                                'FontUnits','Pixels','FontSize',obj.tSz,...
                                'String',bStrBC{i});                
            end
            
            % set the update button enabled properties
            obj.updateButtonProps()
            
            % ----------------------------------- %
            % --- PARAMETER TAB GROUP OBJECTS --- %
            % ----------------------------------- %                
            
            % creates the outer panel
            yPos = sum(pPosC([2,4])) + obj.dX;
            pPos = [lPos,yPos,obj.widPanel,obj.hghtPanelP];
            obj.hPanel = uipanel(obj.hFig,'Title','','Units',...
                                          'Pixel','Position',pPos);
            expFile = cellfun(@(x)(x.expFile),obj.hObjM.sInfo,'un',0);
            
            % creates a tab panel group            
            tabPos = getTabPosVector(obj.hPanel,[5,5,-10,-5]);
            obj.hTabGrpEx = createTabPanelGroup(obj.hPanel,1);
            set(obj.hTabGrpEx,'Position',tabPos,'tag','hTabGrp',...
                              'SelectionChangedFcn',@obj.tabChangeExpt)
                                        
            % creates the experiment tab groups
            for i = 1:obj.nExp
                % creates the experiment tab group object
                tStr = sprintf('Expt #%i',i);
                obj.hTabEx{i} = createNewTab(obj.hTabGrpEx,...
                                           'Title',tStr,'UserData',i,...
                                           'TooltipString',expFile{i});
                pause(0.1)
                
                % creates the inner panel object
                pPosP = [obj.dX/2*[1,1],tabPos(3:4)-[1.5*obj.dX,4*obj.dX]];
                hPanelP = uipanel(obj.hTabEx{i},'Title','',...
                                        'Units','Pixel','Position',pPosP);
                                    
                % creates a tab panel group            
                tabPosP = getTabPosVector(hPanelP,[5,5,-10,-5]);
                obj.hTabGrpP{i} = createTabPanelGroup(hPanelP,1);
                set(obj.hTabGrpP{i},'Position',tabPosP,'tag','hTabGrpP',...
                                  'SelectionChangedFcn',@obj.tabChangePara)
                                    
                % creates the parameter panel 
                obj.hTabP{i} = cell(length(obj.exD{i}),1);
                if isempty(obj.exD{i})
                    % if no data fields, then make the tab group invisible
                    setObjVisibility(obj.hTabGrpP{i},0)
                else
                    % otherwise, create tabs for each data field
                    for j = 1:length(obj.exD{i})
                        obj.createNewParaTab(i,j);
                    end
                end
            end                
            
            % ------------------------- %
            % --- FILE MENU OBJECTS --- %
            % ------------------------- %            
                       
            % creates the main menu item
            hMenuP = uimenu('Label','File');
            
            % creates the file load menu items
            hMenuL = uimenu(hMenuP,'Label','Load...');            
            uimenu(hMenuL,'Label','Data Field Template',...
                          'Callback',@obj.loadDataTemplate);
            uimenu(hMenuL,'Label','External Data File',...
                          'Callback',@obj.loadDataFile);                      
            
            % creates the file save menu items
            hMenuSP = uimenu(hMenuP,'Label','Save...');
            obj.hMenuS = uimenu(hMenuSP,'Label','Data Field Template',...
                                        'Callback',@obj.saveDataTemplate);
                      
            % creates the other menu items
            obj.hMenuC = uimenu(hMenuP,'Label','Clear Experiment Data',...
                        'Callback',@obj.clearExptData,'Separator','on');
            obj.hMenuR = uimenu(hMenuP,'Label','Restore Original Data',...
                        'Callback',@obj.restoreOrigData,'Enable','off');
            obj.hMenuH = uimenu(hMenuP,'Label','Set Header String',...
                        'Callback',@obj.alterColHeader);
            obj.hMenuX = uimenu(hMenuP,'Label','Close Window','Callback',...
                        @obj.closeFigure,'Separator','on');
        end        
            
        % --- creates the new parameter tab
        function createNewParaTab(obj,iExp,iPara)
        
            % field retrieval and other initialisations
            hP = obj.hTabGrpP{iExp};
            tabPos = get(hP,'Position');
            pStrRC = {'nRow','nCol'};
            tStrRC = {'Field Row Count: ','Field Column Count: '};            
            hStr = obj.exD{iExp}{iPara}.hStr(:)';
            
            % creates the parameter tab group object
            tStrP = sprintf('Para #%i',iPara);
            [obj.hTabP{iExp}{iPara},hTP] = deal(createNewTab...
                                    (hP,'Title',tStrP,'UserData',iPara));
        
            % creates the table object
            tData = obj.exD{iExp}{iPara}.Data;
            cEdit = true(1,size(tData,2));
            tPos = [obj.dX/2*[1,1],(tabPos(3)-1.5*obj.dX),obj.hghtTable];
            hTable = uitable(hTP,'Units','Pixels','Position',tPos,...
                       'FontUnits','Pixels','FontSize',obj.tSz,...
                       'UserData',{iExp,iPara},'Data',tData,...
                       'CellEditCallback',@obj.tableChange,...
                       'ColumnEditable',cEdit,'Tag','hTableP',...
                       'BackgroundColor',[1,1,1],'tag','hTableP',...
                       'ColumnName',hStr);
            autoResizeTableColumns(hTable);
                   
            % derived dimension calculations
            y0 = sum(tPos([2,4])) + obj.dX;            
            widEditRC = (tPos(3)/2 - (obj.widTxtRC + obj.dX));
            
            for i = 1:2
                % creates the text object
                lPosRC = (i-1)*(tPos(3)/2);
                tPosRC = [lPosRC,y0,obj.widTxtRC,obj.hghtTxt];
                uicontrol(hTP,'Style','Text','String',tStrRC{i},...
                              'Units','Pixels','Position',tPosRC,...
                              'FontWeight','Bold','FontUnits','Pixels',...
                              'HorizontalAlignment','right',...
                              'FontSize',obj.tSz);              
                          
                % creates the editbox object
                lPosRC2 = sum(tPosRC([1,3]));
                pStrXC = getFieldValue(obj.exD{iExp}{iPara},pStrRC{i});
                ePosRC = [lPosRC2,y0-2,widEditRC,obj.hghtEdit];
                uicontrol(hTP,'Style','Edit','String',num2str(pStrXC),...
                              'Units','Pixels','Position',ePosRC,...
                              'FontUnits','Pixels','FontSize',obj.tSz,...
                              'HorizontalAlignment','Center',...
                              'Callback',@obj.editParaField,...
                              'UserData',pStrRC{i});                
                          
                if i == 1
                    % creates the data field name text object
                    tPosF = [lPosRC,y0+obj.dY,obj.widTxtF,obj.hghtTxt];
                    tStrF = 'Data Field Name: ';
                    uicontrol(hTP,'Style','Text','String',tStrF,...
                                  'Units','Pixels','Position',tPosF,...
                                  'FontWeight','Bold','FontUnits','Pixels',...
                                  'HorizontalAlignment','right',...
                                  'FontSize',obj.tSz); 
                                                            
                    % creates the editbox object
                    lPosF2 = sum(tPosF([1,3]));
                    widEditF = tPos(3) - (lPosF2 + obj.dX);
                    pStrF = obj.exD{iExp}{iPara}.pStr;
                    ePosF = [lPosF2,y0+obj.dY-2,widEditF,obj.hghtEdit];
                    uicontrol(hTP,'Style','Edit','String',pStrF,...
                                  'Units','Pixels','Position',ePosF,...
                                  'FontUnits','Pixels','FontSize',obj.tSz,...
                                  'HorizontalAlignment','Center',...
                                  'Callback',@obj.editParaName,...
                                  'UserData','pStr',...
                                  'tag','hEditF');          
                end                          
                          
            end
                          
        end
                                   
        % ------------------------------------ %
        % --- TAB GROUP CALLBACK FUNCTIONS --- %
        % ------------------------------------ %

        % --- experiment tab change callback function
        function tabChangeExpt(obj,hObj,~)
            
            % retrieves the experiment index
            obj.iExp = get(get(hObj,'SelectedTab'),'UserData');
            
            % retrieves the parameter index
            if isempty(obj.exD{obj.iExp})
                % resets the parameter index
                obj.iPara = NaN;
                
                % updates the button/tab group properties
                setObjEnable(obj.hBut{1},0);
                setObjVisibility(obj.hTabGrpP{obj.iExp},0)
            else         
                % resets the selected parameter index
                obj.resetParaIndex()
                
                % updates the button/tab group properties
                setObjEnable(obj.hBut{1},1);
                setObjVisibility(obj.hTabGrpP{obj.iExp},1)
            end
            
            % updates the control button properties
            obj.updateButtonProps();
            
        end
        
        % --- parameter tab change callback function
        function tabChangePara(obj,hObj,~)
            
            % retrieves the experiment index
            obj.iPara = get(get(hObj,'SelectedTab'),'UserData');
            
            % updates the control button properties
            obj.updateButtonProps();            
            
        end        
        
        % ------------------------------------------ %
        % --- FIELD PARAMETER CALLBACK FUNCTIONS --- %
        % ------------------------------------------ %        
        
        % --- add parameter button callback function
        function addPara(obj,~,~)
            
            % appends an empty data struct and updates the para index
            obj.exD{obj.iExp}{end+1} = obj.initExtnDataStruct;
            obj.exD0{obj.iExp}{end+1} = obj.exD{obj.iExp}{end};
            obj.iPara = length(obj.exD{obj.iExp});            
            
            % creates the new parameter tab            
            obj.createNewParaTab(obj.iExp,obj.iPara);            
            set(obj.hTabGrpP{obj.iExp},...
                            'SelectedTab',obj.hTabP{obj.iExp}{obj.iPara})
            setObjVisibility(obj.hTabGrpP{obj.iExp},1)
            obj.updateButtonProps();
            
            % enables the delete parameter button
            setObjEnable(obj.hBut{1},1);
            
        end        
        
        % --- delete parameter button callback function
        function deletePara(obj,hObj,~)
            
            % prompts the user if they wish to remove the data field
            qStr = 'Are you sure you want to remove this data field?';
            uChoice = questdlg(qStr,'Remove Data Field?','Yes','No','Yes');
            if ~strcmp(uChoice,'Yes')
                % if the user cancelled, then exit
                return
            end
                
            % deletes the tab objects
            delete(obj.hTabP{obj.iExp}{obj.iPara});
            
            % renames the subsequent tabs
            exDT = obj.exD{obj.iExp};
            for i = (obj.iPara+1):length(exDT)
                tStr = sprintf('Para #%i',i-1);
                set(obj.hTabP{obj.iExp}{i},'Title',tStr,'UserData',i-1)                
            end
            
            % removes the class fields pertaining to the removed field
            B = ~setGroup(obj.iPara,size(exDT));
            obj.exD{obj.iExp} = exDT(B);
            obj.exDR{obj.iExp} = obj.exDR{obj.iExp}(B);
            obj.hTabP{obj.iExp} = obj.hTabP{obj.iExp}(B);
            obj.updateSolnFile(obj.iExp);
            
            % resets the selected parameter index
            obj.resetParaIndex()
            
            % disables the button if no more parameters for expt
            setObjEnable(hObj,any(B));
            setObjVisibility(obj.hTabGrpP{obj.iExp},any(B));
            obj.updateButtonProps();
            
        end
        
        % --- callback function for a data field name update
        function editParaName(obj,hObj,~)
            
            % initialisations
            iP = get(get(hObj,'Parent'),'UserData');
            nwVal = get(hObj,'String');            
            
            % check the new string doesn't contain special characters
            [ok,eStr] = chkDirString(nwVal,1);
            if ok
                % check the string also doesn't start with a number
                if isnan(str2double(nwVal(1)))
                    % checks if there are any duplicate entries
                    B = ~setGroup(iP,[length(obj.exD{obj.iExp}),1]);
                    pStrO = cellfun(@(x)(x.pStr),obj.exD{obj.iExp}(B),'un',0);                    
                    if ~any(strcmp(pStrO,nwVal))                    
                        % if so, then update the parameter fields
                        obj.exD{obj.iExp}{iP}.pStr = nwVal;

                        % updates the control button properties
                        obj.updateButtonProps();
                        return
                        
                    else
                        % otherwise, set the error string
                        eStr = 'Duplicate data field names have been detected.';
                    end
                else
                    % otherwise, set the error string
                    eStr = 'Data field name can''t start with a number.';
                end
            end
            
            % outputs the error message to screen and resets the string
            waitfor(msgbox(eStr,'Naming Error','modal'))
            set(hObj,'String',obj.exD{obj.iExp}{iP}.pStr);            
            
        end
        
        % --- callback function for a data field parameter update
        function editParaField(obj,hObj,~)
           
            % initialisations
            pStr = get(hObj,'UserData');            
            iP = get(get(hObj,'Parent'),'UserData');
            nwVal = str2double(get(hObj,'String'));
            
            % determines if the new value is valid
            if chkEditValue(nwVal,[1,inf],1)
                % if so, then update the parameters
                obj.exD{obj.iExp}{iP} = ...
                        setStructField(obj.exD{obj.iExp}{iP},pStr,nwVal);
                    
                % updates the data array and disables the update buttons
                obj.reshapeDataArray(obj.iExp,iP);
                obj.updateButtonProps();
                
            else
                % otherwise, revert to the last valid value
                pVal0 = getStructField(obj.exD{obj.iExp}{iP},pStr);
                set(hObj,'String',num2str(pVal0));
            end
            
        end        
        
        % --- parameter table cell edit callback function
        function tableChange(obj,hObj,evnt)
           
            % field retrieval
            iP = get(get(hObj,'Parent'),'UserData');
            [iR,iC] = deal(evnt.Indices(1),evnt.Indices(2));
            
            % updates the data field
            obj.exD{obj.iExp}{iP}.Data{iR,iC} = evnt.NewData;
            
            % enables the update buttons
            cellfun(@(x)(setObjEnable(x,1)),obj.hButC(1:2))
            
        end

        % ----------------------------------------- %
        % --- CONTROL BUTTON CALLBACK FUNCTIONS --- %
        % ----------------------------------------- %          
        
        % --- current parameter update function
        function updateCurrent(obj,~,~)
           
            if obj.checkExptDataFields()
                % resets the external data struct for the experiment
                if isequal(obj.exDR{obj.iExp},obj.exD{obj.iExp})
                    % if the data structs are equal for all data fields
                    % within the expt, then update
                    obj.updateSolnFile(obj.iExp);
                end
                
                % updates the button properties
                obj.updateButtonProps();
            end
                
        end
            
        % --- all parameter update function
        function updateAll(obj,~,~)
           
            % loops through all experiments updating the parameters
            % (flagging any parameters which are incorrect)
            for i = 1:obj.nExp
                for j = 1:length(obj.exD{i})
                    % determines if the data field is filled out correctly
                    if obj.checkExptDataFields(i,j)                        
                        if isequal(obj.exDR{i},obj.exD{i})
                            % updates the solution file (if all data fields
                            % match within the experiment)
                            obj.updateSolnFile(i);
                        end
                    else
                        % otherwise, exit the function
                        return
                    end
                end
            end
            
            % updates the button properties
            obj.updateButtonProps();            
                
        end        

        % ----------------------------------------- %
        % --- EXPERIMENT ERROR OUTPUT FUNCTIONS --- %
        % ----------------------------------------- %        
        
        % --- shows the field name error
        function showFieldNameError(obj,iExp,iPara)
            
            % changes the experiment/parameter tabs (if not matching)
            if ~isequal([iExp,iPara],[obj.iExp,obj.iPara])
                obj.resetOpenTabs(iExp,iPara);                
            end
            
            % retrieves the editbox object handle
            hEdit = findall(obj.hFig,'Tag','hEditF');
            set(hEdit,'BackgroundColor','r');
            
            % output an error to screen
            eStr = 'The data name field is not allowed to be empty.';
            waitfor(msgbox(eStr,'Update Error','modal'))
                                 
            % resets the editbox background color
            set(hEdit,'BackgroundColor','w');
            
        end

        % --- shows the data table error
        function showDataTableError(obj,iExp,iPara,isER,isEC)
        
            % changes the experiment/parameter tabs (if not matching)
            if ~isequal([iExp,iPara],[obj.iExp,obj.iPara])
                obj.resetOpenTabs(iExp,iPara);
            end            
            
            % initialisations
            Data = obj.exD{iExp}{iPara}.Data;
            
            % retrieves the table java object
            hTableP = findall(obj.hTabP{iExp}{iPara},'Tag','hTableP');
            jTableP = getJavaTable(hTableP);

            % removes all selection
            jTableP.changeSelection(-1,-1,false,false)
            
            % determines the cells which belong to an empty row/column
            B = false(size(Data)); 
            [B(isER,:),B(:,isEC)] = deal(true);
            [iy,ix] = find(B);
            
            % changes the table selection
            for i = 1:length(ix)
                jTableP.changeSelection(iy(i)-1,ix(i)-1,true,false);
            end
            
            % output an error to screen
            eStr = 'At least one row/column in the data table is empty.';
            waitfor(msgbox(eStr,'Update Error','modal'))
            
            % removes all selection
            jTableP.changeSelection(-1,-1,false,false)            
            
        end
            
        % ------------------------------------ %
        % --- MENU ITEM CALLBACK FUNCTIONS --- %
        % ------------------------------------ %                     
        
        % --- data field template load callback function
        function loadDataTemplate(obj,~,evnt)
                        
            if ~isempty(evnt)
                % loads the data file (if function called via menu item)
                tStr = 'Load Data Template File';
                fMode = {'*.exd','Date Template File (*.exd)'};
                iProg = getappdata(findall(0,'tag','figDART'),'ProgDef');

                % prompts the user for the movie filename
                dStr = iProg.Analysis.OutData;                        
                [fName,fDir,fIndex] = uigetfile(fMode,tStr,dStr);
                if fIndex == 0
                    % if the user cancelled, then exit the function
                    return
                end            

                % loads the data file
                fFile = fullfile(fDir,fName);
                obj.exD{obj.iExp} = importdata(fFile,'-mat');
                obj.exDR{obj.iExp} = obj.exD{obj.iExp};
            end
            
            % retrieves the new/original data field counts
            nexD = length(obj.exD{obj.iExp});
            nexDR = length(obj.hTabP{obj.iExp});

            % removes any extraneous tabs
            if nexDR > nexD
                % removes the tab fields from the class object
                BB = ~setGroup((nexD+1):nexDR,[nexDR,1]);
                cellfun(@delete,obj.hTabP{obj.iExp}(~BB))                
                obj.hTabP{obj.iExp} = obj.hTabP{obj.iExp}(BB);
                
                % resets the selected parameter index
                obj.resetParaIndex()                
            end
            
            % resets the parameter tab panels
            for iP = 1:nexD
                % adds in a new tab panel (if required)
                if iP > nexDR
                    obj.createNewParaTab(obj.iExp,iP)
                end
                
                % resets the information in the tab panel
                obj.resetTabPanelPara(iP);
            end            
            
            % resets the parameter index
            obj.resetParaIndex();           
            
            % updates the required flags
            obj.updateSolnFile(obj.iExp);
            if ~isempty(evnt)
                obj.updateButtonProps();
            end
            
            % makes the tab visible again
            setObjVisibility(obj.hTabGrpP{obj.iExp},nexD>0)
            
        end        
        
        % --- external data file load callback function
        function loadDataFile(obj,hObj,evnt)
        
            % initialisations
            tStr = 'Load External Data File';
            fMode = {'*.csv','Comma Delimited (*.csv)';...
                     '*.txt','Text File (*.txt)'};
            iProg = getappdata(findall(0,'tag','figDART'),'ProgDef');
            
            % prompts the user for the movie filename
            dStr = iProg.Analysis.OutData;                        
            [fName,fDir,fIndex] = uigetfile(fMode,tStr,dStr);            
            if fIndex == 0
                % if the user cancelled, then exit the function
                return
            else
                % otherwise, determine if the data file has a header row
                qStr = 'Does the data file have header row(s)?';
                uChoice = questdlg(qStr,'Header Row?','Yes','No','Yes');
                hasHeader = strcmp(uChoice,'Yes');
            end              
            
            % opens the external data file (based on type)
            exFile = fullfile(fDir,fName);            
            switch fMode{fIndex,1}
                case '*.csv'
                    % case is a csv file
                    fData = readCSVFile(exFile);
                    
                case '*.txt'
                    % case is a data file
                    a = csvread(exFile);
                    
            end
            
        end            
        
        % --- data field template save callback function        
        function saveDataTemplate(obj,~,~)
        
            % initialisations
            tStr = 'Save Data Template File';
            fMode = {'*.exd','Date Template File (*.exd)'};
            iProg = getappdata(findall(0,'tag','figDART'),'ProgDef');
            
            % prompts the user for the movie filename
            dStr = iProg.Analysis.OutData;                        
            [fName,fDir,fIndex] = uiputfile(fMode,tStr,dStr);
            if fIndex == 0
                % if the user cancelled, then exit the function
                return
            end
                
            % outputs the data to file
            exDS = obj.exD{obj.iExp};
            save(fullfile(fDir,fName),'exDS');
            
        end        
        
        % --- clear all data callback function
        function clearExptData(obj,~,~)
        
            % prompts the user if they wish to clear the data
            qStr = 'Do you wish to clear the experiment''s external data?';
            uChoice = questdlg(qStr,'Clear All Data?','Yes','No','Yes');
            if ~strcmp(uChoice,'Yes')
                % if the user cancelled, then exit
                return
            end
            
            % deletes the tab panels
            cellfun(@delete,obj.hTabP{obj.iExp})
            
            % clears the other fields
            obj.iPara = NaN;
            obj.exD{obj.iExp} = [];
            obj.exDR{obj.iExp} = [];
            obj.hTabP{obj.iExp} = [];
            obj.updateSolnFile(obj.iExp);
            
            % makes the tab group invisible
            setObjVisibility(obj.hTabGrpP{obj.iExp},0);
            obj.updateButtonProps();            
            
        end        
        
        % --- clear all data callback function
        function restoreOrigData(obj,~,~)
            
            % prompts the user if they wish to clear the data
            qStr = 'Do you wish to restore the original external data?';
            uChoice = questdlg(qStr,'Restore Original?','Yes','No','Yes');
            if ~strcmp(uChoice,'Yes')
                % if the user cancelled, then exit
                return
            end            
            
            % stores the original experiment index
            iExp0 = obj.iExp;
            
            % resets the data fields for each experiment
            for i = 1:length(obj.exD0)
                % resets the external data structs
                [obj.exD{i},obj.exDR{i}] = deal(obj.exD0{i});
                
                % updates the data field
                obj.iExp = i;
                obj.loadDataTemplate([],[])
            end            
            
            % resets the original experiment index
            obj.iExp = iExp0;            
            
            % updates the button properties
            obj.resetParaIndex();
            obj.updateButtonProps();            
            
        end
        
        % --- figure close callback function
        function closeFigure(obj,~,~)
            
            % checks if there are any outstanding changes
            if strcmp(get(obj.hButC{2},'Enable'),'on')
                % if so, prompt if they wish to update first
                qStr = 'Do you want to update the changes before exiting?';
                uChoice = questdlg(qStr,'Update Changes?','Yes','No','Yes');
                                    
                % exit if the user wishes to update changes                
                if strcmp(uChoice,'Yes')
                    return
                end
            end
            
            % deletes the gui
            delete(obj.hFig)
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %             
        
        % --- retrieves the solution data struct
        function sInfo = getSolnDataStruct(obj,iExp)
            
            % retrieves the solution data structs
            if obj.isCombine
                sInfo0 = getappdata(obj.hObjM,'sInfo');
            else
                sInfo0 = obj.hObjM.sInfo;
            end
            
            % returns the solution struct for the experiment, iExp
            sInfo = sInfo0{iExp};
            
        end
        
        % --- reshapes the data array and table
        function reshapeDataArray(obj,iExp,iP)
            
            % field retrieval
            exDT = obj.exD{iExp}{iP};
            [szNw,szPr] = deal([exDT.nRow,exDT.nCol],size(exDT.Data));
            
            % reshapes the data array based on the new size
            dsz = szNw - szPr;
            if any(dsz > 0)
                % case is the data array has been expanded
                nwRow = cell(dsz(1),szNw(2));
                nwCol = cell(szNw(1),dsz(2));
                exDT.Data = [[exDT.Data;nwRow],nwCol];
                
                % reduces the header strings (if reducing column count)
                if szNw(2) > szPr(2)
                    xiC = (szPr(2)+1):szNw(2);
                    hStrNw = arrayfun(@(x)(sprintf('Col #%i',x)),xiC,'un',0);
                    exDT.hStr = [exDT.hStr,hStrNw];
                end                
            else
                % case is the data array has been reduced                
                [iR,iC] = deal(1:szNw(1),1:szNw(2));
                exDT.Data = exDT.Data(iR,iC);
                
                % reduces the header strings (if reducing column count)
                if szNw(2) < szPr(2)
                    exDT.hStr = exDT.hStr(iC);
                end
            end           
            
            % resets the data and updates the table
            obj.exD{iExp}{iP} = exDT;
            hTable = findall(obj.hTabP{iExp}{iP},'tag','hTableP');
            set(hTable,'Data',exDT.Data,'ColumnName',exDT.hStr(:)');
            
        end
        
        % --- updates the update button enabled properties
        function updateButtonProps(obj)
            
            if isnan(obj.iPara)
                % case is there are no parameters
                cellfun(@(x)(setObjEnable(x,0)),obj.hButC(1:2))
                setObjEnable(obj.hMenuS,0);               
                setObjEnable(obj.hMenuC,0);
                setObjEnable(obj.hMenuH,0);
                setObjEnable(obj.hBut{1},0);
                
            else
                % determines which 
                isEq = cellfun(@(x,y)(isequal(x,y)),obj.exDR,obj.exD);
                
                % sets the update current data field button enabled props
                if isEq(obj.iExp)
                    setObjEnable(obj.hButC{1},false)
                else
                    exDT = obj.exD{obj.iExp};
                    exDRT = obj.exDR{obj.iExp};
                    
                    if isempty(exDT) || isempty(exDRT)
                        isEqP = false;
                    else
                        isEqP = isequal(exDT{obj.iPara},exDRT{obj.iPara});
                    end
                        
                    setObjEnable(obj.hButC{1},~isEqP)                    
                end

                % updates the update all button enabled props
                updateA = any(~isEq); 
                setObjEnable(obj.hButC{2},updateA)                
                
                % updates the save menu enabled props                
                updateM = all(isEq);
                setObjEnable(obj.hMenuS,updateM)  
                
                % updates the remove parameter button enabled props
                hasD = ~isempty(obj.exD{obj.iExp});                
                setObjEnable(obj.hMenuC,hasD);
                setObjEnable(obj.hMenuH,hasD);
                setObjEnable(obj.hBut{1},hasD);                
            end
            
            % sets the restore original menu item enabled properties
            setObjEnable(obj.hMenuR,~isequal(obj.exDR,obj.exD0));
            
        end
        
        % --- resets the open experiment/data field tabs
        function resetOpenTabs(obj,iExp,iPara)

            if iExp ~= obj.iExp
                % updates both the experiment/parameter tab
                set(obj.hTabGrpEx,'SelectedTab',obj.hTabEx{iExp})
                set(obj.hTabGrpP{iExp},'SelectedTab',...
                                              obj.hTabP{iExp}{iPara})
            else
                % otherwise, only update the parameter tab
                set(obj.hTabGrpP{iExp},'SelectedTab',...
                                              obj.hTabP{iExp}{iPara})
            end

            % resets the experiment/parameter indices
            [obj.iExp,obj.iPara] = deal(iExp,iPara);        
            
        end        
           
        % --- resets the data fields for the tab panel
        function resetTabPanelPara(obj,iP)
            
            % retrieves the 
            exDT = obj.exD{obj.iExp}{iP};
            hTabPT = obj.hTabP{obj.iExp}{iP};
            
            % updates the data field name string
            hEditF = findall(hTabPT,'userdata','pStr');
            set(hEditF,'String',exDT.pStr);
            
            % sets the row count field
            hEditR = findall(hTabPT,'userdata','nRow');
            set(hEditR,'String',num2str(exDT.nRow));
            
            % sets the column count field
            hEditC = findall(hTabPT,'userdata','nCol');
            set(hEditC,'String',num2str(exDT.nCol));
            
            % sets the table data
            hTableP = findall(hTabPT,'tag','hTableP');
            set(hTableP,'Data',exDT.Data,'ColumnName',exDT.hStr(:)');
            
        end        
        
        % --- updates the external data field in the solution file
        function updateSolnFile(obj,iExp)
        
            % retrieves the solution data fields
            if obj.isCombine
                % case is operating from the data combining gui
                sInfo = getappdata(obj.hObjM,'sInfo');
            else
                % case is operating from the solution 
                sInfo = obj.hObjM.sInfo;
            end
                
            % updates the external data field
            sInfo{iExp}.snTot.exD = obj.exD{iExp};

            
            % retrieves the solution data fields
            if obj.isCombine
                % case is operating from the data combining gui
                setappdata(obj.hObjM,'sInfo',sInfo);
            else
                % case is operating from the solution 
                obj.hObjM.sInfo = sInfo;
            end
            
        end        
        
        % --- determines if the data fields for the experiment has 
        %     been set correctly
        function ok = checkExptDataFields(obj,iExp,iPara)
            
            % sets the experiment/parameter index if not provided
            if ~exist('iExp','var')
                [iExp,iPara] = deal(obj.iExp,obj.iPara);
            end
            
            % initialisations
            ok = false;
            exDT = obj.exD{iExp}{iPara};
            
            % determines if the experiment fields have been filled
            if isempty(exDT.pStr)
                % case is the data field name is empty
                obj.showFieldNameError(iExp,iPara);
            else
                % otherwise, determine any data row/column is empty
                isE = cellfun(@isempty,exDT.Data);
                [isER,isEC] = deal(all(isE,2),all(isE,1));                
                if any(isER) || any(isEC)
                    % case is at least one row/column is empty
                    obj.showDataTableError(iExp,iPara,isER,isEC);
                else
                    % otherwise, flag everything is correct
                    ok = true;
                    obj.exDR{iExp}{iPara} = exDT;
                end
            end            
            
        end        
        
        % --- opens the GUI to allow user to alter column headers
        function alterColHeader(obj,~,~)
            
            ExtnDataHeader(obj);
            
        end
        
        % --- resets the selected parameter index
        function resetParaIndex(obj)
            
            hTabPS = get(obj.hTabGrpP{obj.iExp},'SelectedTab');
            obj.iPara = get(hTabPS,'UserData');            
        
        end        
        
    end
    
    % static class methods
    methods (Static)
        
        % --- initialises the external data struct
        function exD = initExtnDataStruct()
            
            exD = struct('pStr',[],'nRow',1,'nCol',1,'Data',[],'hStr',[]);
            [exD.Data,exD.hStr] = deal({[]},{'Col #1'});
            
        end        
        
    end    
    
end