classdef AnalysisParaClass < handle
    
    % class properties
    properties
        
        % class objects
        hFig
        hFigM
        hGUI
        
        % gui object fields
        hTab
        hPanel    
        hObj
        hTabG
        hVB
        nPmx
        Hpanel
        hChild
        
        % parameter struct fields
        pData
        
        % object dimensioning
        tDay
        pOfs = 5;
        hOfs = 25;
        hOfs2 = 20;
        B0 = 50;
        nTabMax = 10;
        hTabOfs = 35;
        dhTabOfs = 10;
        pHght = 25;
        
        % other array fields
        pStr = {'Calc','Plot','Sub','Time','StimRes'};
        
        % other scalar fields
        yOfs
        Hnew
        yNew
        tOfs
        HObjS
        wObjNw
        scrSz
        hasTab
        isOK = true;
        
    end
    
    % class methods
    methods

        % --- object constructor
        function obj = AnalysisParaClass(hFig,hGUI)
            
            % sets the main class objects
            obj.hFig = hFig;
            obj.hGUI = hGUI;            
            
            % creates a loadbar
            wStr = 'Initialising Function Parameter GUI...';
            hProg = ProgressLoadbar(wStr);
            
            % disables the update figure button
            setObjEnable(obj.hGUI.buttonUpdateFigure,'off');            
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initAnalysisGUI(true);
            
            % enables the update figure button
            setObjEnable(obj.hGUI.buttonUpdateFigure,'on');    
            
            % deletes the loadbar
            delete(hProg)
            
        end

        % --------------------------------------------- %
        % --- CLASS OBJECT INITIALISATION FUNCTIONS --- %
        % --------------------------------------------- %        
        
        % --- initialises all the object callback functions
        function initClassFields(obj)
            
            % field initialisations
            obj.nPmx = zeros(1,3);
            [obj.hTab,obj.hTabG,obj.hObj] = deal(cell(1,3));
            
            % sets the vertical box object handle
            hGUIF = guidata(obj.hFig);
            obj.hVB = hGUIF.panelVBox;
            obj.Hpanel = get(obj.hVB,'Heights');
            
            % sorts the child objects by their userdata indices
            hChild0 = get(obj.hVB,'Children');
            [~,iS] = sort(arrayfun(@(x)(get(x,'UserData')),hChild0));
            obj.hChild = hChild0(iS);            
            
            % retrieves all panel object handles
            obj.hPanel = cell(length(obj.pStr),1);            
            for i = 1:length(obj.pStr)
                tagStrP = sprintf('panel%sPara',obj.pStr{i});
                obj.hPanel{i} = findall(obj.hFig,'tag',tagStrP);
            end  
            
            % other field initialisations
            obj.hFigM = obj.hGUI.figFlyAnalysis;
            obj.scrSz = getPanelPosPix(0,'Pixels','ScreenSize');
            
            % table gap offset (fudge factor to make table look nice...)
            if (ispc)
                obj.tOfs = 2;
            else
                obj.tOfs = 4;
            end
            
            % sets the global parameter
            A = load(getParaFileName('ProgPara.mat'));
            obj.tDay = A.gPara.Tgrp0;
            
        end                
        
        % --- sets up and initialises the gui object
        function varargout = initAnalysisGUI(obj,isInit)
            
            % sets the default input argument
            if ~exist('isInit','var'); isInit = false; end
            
            % field retrieval            
            pData0 = getappdata(obj.hFigM,'pData'); 
            sPara0 = getappdata(obj.hFigM,'sPara');            

            % makes the gui invisible (if not initialising)
            if ~isInit
                setObjVisibility(obj.hFig,0);
                pause(0.05);
            end
            
            % deletes any axes objects on the parameter gui
            hAx0 = findall(obj.hFig,'type','Axes');
            if ~isempty(hAx0); delete(hAx0); end            
            
            % sets the panels for object removal           
            for i = 1:length(obj.hPanel)
                switch obj.pStr{i}
                    case {'Calc','Plot'}
                        % case is a plotting/calculation panel
                        
                        % removes all the current objects within the panels
                        iType = 1 + strcmp(obj.pStr{i},'Plot');
                        if ~isempty(obj.hTab{iType})
                            for j = 1:length(obj.hTab{iType})
                                hObjP = findobj(obj.hTab{iType}{j});
                                if ~isempty(hObjP)
                                    % deletes any objects that may exist
                                    objType = get(hObjP,'type');
                                    delete(hObjP(~strcmp(objType,'uitab')))  
                                end
                            end
                        end
                        
                    otherwise
                        % case are the other panel types
                        hObjP = findobj(obj.hPanel{i});
                        if ~isempty(hObjP)
                            % removes any non-panel objects 
                            objType = get(hObjP,'type');
                            delete(hObjP(~strcmp(objType,'uipanel')))
                        end
                        
                end
                
                % resets the visibility to on
                setObjVisibility(obj.hPanel{i},'on')
            end            
            
            % sets the selected indices
            [eInd,fInd,pInd] = getSelectedIndices(obj.hGUI);            
            
            % sets the plot data field
            if size(sPara0.pos,1) == 1
                % case is a single plot
                obj.pData = pData0{pInd}{fInd,eInd};
            else
                % case is multiple sub-plots                
                sInd = getappdata(obj.hFigM,'sInd');
                if isempty(sPara0.pData{sInd})
                    % current sub-plot is empty
                    obj.pData = pData0{pInd}{fInd,eInd};
                else
                    % current sub-plot is not empty
                    obj.pData = sPara0.pData{sInd};
                end                
            end            
            
            % initialises the GUI objects
            try
                obj.setupGUIObjects(isInit);
                obj.updateMainPara();
                
                % centres the gui to the middle of the string
                optFigPosition([obj.hFigM,obj.hFig])
                
            catch ME
                % re-centres the figure
                centreFigPosition(obj.hFig,2);
                
                % if there was an error, then try running the GUI again
                eStr = 'There was an error initialising the Analysis parameter GUI.';
                waitfor(errordlg(eStr,'GUI Initialisation Error','modal'))
            end
            
            % returns the parameter data struct
            if (nargout == 1)
                varargout{1} = obj.pData;
            end            
            
        end
        
        % -------------------------------------------- %        
        % --- SPECIAL PARAMETER CALLBACK FUNCTIONS --- %
        % -------------------------------------------- %
        
        % --- callback function for the time limit parameters                  
        function callbackTimeLimit(obj,hObject,~)
            
            % retrieves the user data
            uData = get(hObject,'UserData');

            % if the push-button, then reset the limits and exit the function
            if strcmp(get(hObject,'style'),'pushbutton')
                % retrieves the limit/values structs
                Lim = obj.pData.sP(uData).Lim;
                Value = obj.pData.sP(uData).Value;

                % resets the lower limit values
                Value.Lower = sec2vec(Lim(1)); Value.Lower(end) = 0;                        
                Value.Lower(end) = (Value.Lower(2) >= 12);
                Value.Lower(2) = mod(Value.Lower(2),12);
                obj.resetTimeObj('Lower',Value.Lower+1)

                % resets the upper limit values
                Value.Upper = sec2vec(Lim(2)); Value.Upper(end) = 0;
                Value.Upper(end) = (Value.Upper(2) >= 12);
                Value.Upper(2) = mod(Value.Upper(2),12);
                obj.resetTimeObj('Upper',Value.Upper+1)

                % updates the parameter struct
                obj.pData.sP(uData).Value = Value;    

                % updates the plot figure
                obj.pData = updatePlotFigure(obj.hFig,obj.pData);
                return
                
            else
                Lim = obj.pData.sP(uData{2}).Lim;
                Value = obj.pData.sP(uData{2}).Value;
            end

            % retrieves the new value
            Tadd = convertTime(12,'hrs','sec');
            nwVal = get(hObject,'Value');
            tVec = eval(sprintf('Value.%s',uData{3}));
            tVec(uData{1}) = nwVal - 1;

            % determines the new time
            tNew = vec2sec([tVec(1:3) 0]) + tVec(4)*Tadd;
            switch uData{3}
                case ('Lower')
                    % calculates the upper limit
                    pp = Value.Upper;
                    tHi = vec2sec([pp(1:3) 0]) + ...
                                        pp(4)*convertTime(12,'hrs','sec');

                    % checks to see if the new value is valid
                    if (tNew > tHi) || (tNew < Lim(1)) 
                        % outputs an error to screen
                        eStr = 'Error! Lower limit is not feasible.';
                        waitfor(errordlg(eStr,'Lower Limit Error','modal'))

                        % resets the previous valid value
                        set(hObject,'value',Value.Lower(uData{1})+1)
                        return
                    else
                        % updates the lower limit
                        Value.Lower = tVec;
                    end
                    
                case ('Upper')
                    % calculates the upper limit
                    pp = Value.Lower;
                    tLo = vec2sec([pp(1:3) 0]) + ...
                                        pp(4)*convertTime(12,'hrs','sec');

                    % checks to see if the new value is valid
                    if (tNew < tLo) || (tNew > Lim(2)) 
                        % outputs an error to screen
                        eStr = 'Error! Upper limit is not feasible.';
                        waitfor(errordlg(eStr,'Upper Limit Error','modal'))

                        % resets the previous valid value
                        set(hObject,'value',Value.Upper(uData{1})+1)
                        return
                    else
                        % updates the lower limit
                        Value.Upper = tVec;            
                    end        
            end

            % updates the parameter struct
            obj.pData.sP(uData{2}).Value = Value;

            % updates the main figure
            obj.postParaChange()            
            
        end
        
        % --- callback function for the subplot parameters
        function callbackSubPlot(obj,hObject,event)
           
            % retrieve the new parameter value and the overall parameter struct
            hP = findall(obj.hFig,'tag','panelSubPara');
            uData = get(hObject,'UserData');

            % updates the parameter based on the object type
            if strcmp(get(hObject,'type'),'uitable')
                % case is updating the plotting output boolean flags
                ind = event.Indices(1);
                Value = obj.pData.sP(uData).Value;

                % updates the data struct
                Value.isPlot(ind) = event.NewData;        
                [Value.nRow,Value.nCol] = detSubplotDim(sum(Value.isPlot));
                obj.pData.sP(uData).Value = Value;  
                
            elseif strcmp(get(hObject,'style'),'edit')
                % case is editing the row/column counts
                nwVal = str2double(get(hObject,'string'));
                Value = obj.pData.sP(uData{1}).Value;
                Lim = [1 sum(Value.isPlot)];

                % checks to see if the new value is valid
                if chkEditValue(nwVal,Lim,1)
                    % if so, then update the corresponding parameter
                    if uData{2} == 2
                        Value.nRow = nwVal;
                        Value.nCol = ceil(Lim(2)/Value.nRow);
                    else
                        Value.nCol = nwVal;
                        Value.nRow = ceil(Lim(2)/Value.nCol);
                    end

                    % updates the sub-struct values
                    obj.pData.sP(uData{1}).Value = Value;
                else
                    % resets the object string to the previous valid value
                    if uData{2} == 2
                        % case was the row count
                        set(hObject,'string',num2str(Value.nRow))
                    else
                        % case was the column count
                        set(hObject,'string',num2str(Value.nCol))
                    end
                    return
                end
            else
                % resets the trace combination flag value
                Value = obj.pData.sP(uData).Value;
                Value.isComb = get(hObject,'value'); 
                obj.pData.sP(uData).Value = Value;     
            end

            % updates the table based on the new selections
            hTable = findobj(get(hObject,'Parent'),'tag','hTable');
            set(hTable,'Data',obj.getSubplotTableData(Value))

            % resets the object string
            hRow = findobj(hP,'tag','nRow');
            hCol = findobj(hP,'tag','nCol');
            if Value.isComb
                set(setObjEnable(hRow,'off'),'string','1')
                set(setObjEnable(hCol,'off'),'string','1')    
            else
                set(setObjEnable(hRow,'on'),'string',num2str(Value.nRow))
                set(setObjEnable(hCol,'on'),'string',num2str(Value.nCol))
            end

            % updates the main figure
            obj.postParaChange()            
            
        end
        
        % --- callback function for the stimuli response parameters
        function callbackStimResponse(obj,hObject,event)
            
            % retrieve the parameter userdata
            uData = get(hObject,'UserData');

            % resets the userdata based on the storage type
            if iscell(uData); uData = uData{1}; end

            % determines if the table or dropdown menu is being accessed
            if isa(event,'matlab.ui.eventdata.CellEditData')
                isTable = true;
            else
                isTable = isfield(event,'NewData');
            end

            % updates the parameter data based on the object being updated
            if isTable
                % case is the data table
                nwData = event.NewData;
                [iRow,iCol] = deal(event.Indices(1),event.Indices(2));
                
                % updates the plot values                
                switch iCol
                    case (2) % case is setting the fit plotting flag
                        obj.pData.sP(uData).Lim.plotTrace(iRow) = nwData;
                    case (3) % case is setting the fit plotting flag
                        obj.pData.sP(uData).Lim.plotFit(iRow) = nwData;
                end
            else
                % otherwise, case is the dropdown menu
                if isfield(obj.pData.sP(uData).Lim,'appInd')
                    obj.pData.sP(uData).Lim.appInd = get(hObject,'value');
                else
                    obj.pData.sP(uData).Lim = get(hObject,'value');
                end
            end

            % updates the properties/axes based on the function type
            if strcmp(obj.pData.Name,'Multi-Dimensional Scaling')
                % flag that a recalculation is required
                resetRecalcObjProps(obj.hGUI,'Yes')
            else
                % updates the main figure
                obj.postParaChange()
            end            
            
        end
        
        % -------------------------------------------- %        
        % --- REGULAR PARAMETER CALLBACK FUNCTIONS --- %
        % -------------------------------------------- %
        
        % --- callback function for the numeric parameters 
        function callbackNumPara(obj,hObject,~)
            
            % retrieve the new parameter value and the overall parameter struct
            nwVal = str2double(get(hObject,'String'));

            % retrieves the corresponding indices and parameter values
            uData = get(hObject,'UserData');
            switch uData{2}
                case ('Calc')
                    % case is a calculation parameter
                    [fStr,isPlot] = deal('cP',false);
                    Lim = obj.pData.cP(uData{1}).Lim;                    
                    ValueOld = obj.pData.cP(uData{1}).Value;
                case ('Plot')
                    [fStr,isPlot] = deal('pP',true);
                    Lim = obj.pData.pP(uData{1}).Lim;
                    ValueOld = obj.pData.pP(uData{1}).Value;
            end

            % checks to see if the new value is valid
            if chkEditValue(nwVal,Lim(1:2),Lim(3))
                % if so, then update the parameter struct
                eval(sprintf('obj.pData.%s(uData{1}).Value = nwVal;',fStr))

                % updates the parameter enabled properties
                p = obj.resetParaEnable(eval(['obj.pData.',fStr]),uData{1});
                obj.pData = setStructField(obj.pData,fStr,p);

                % updates the main figure (if altering a plotting parameter)
                if isPlot
                    % updates the main figure
                    obj.postParaChange()
                else        
                    resetRecalcObjProps(obj.hGUI,'Yes')
                end 
            else
                % otherwise, reset the field to the last valid value
                set(hObject,'string',num2str(ValueOld))
            end            
            
        end
        
        % --- callback function for the list parameters 
        function callbackListPara(obj,hObject,~)
            
            % retrieve the new parameter value and overall parameter struct
            nwVal = get(hObject,'Value');
            uData = get(hObject,'UserData');
            stimStr = {'nGrp','nBin'};

            % retrieves the corresponding indices and parameter values            
            switch uData{2}
                case ('Calc')
                    % case is a calculation parameter
                    ind0 = obj.pData.cP(uData{1}).Value{1};
                    obj.pData.cP(uData{1}).Value{1} = nwVal;         
                    p = obj.pData.cP;
                    
                    % updates the parameter gui (dependent on parameter)
                    if any(strContains(stimStr,p(uData{1}).Para)) ...
                                && strcmp(obj.pData.sP(3).Type,'Stim')
                        % case is the bin/group count
                        pPara = p(uData{1}).Para;
                        obj.resizeStimRespTable(pPara,uData{1},ind0);
                        nNew = str2double(p(uData{1}).Value{2}{nwVal});
                        
                        % resets the table data                        
                        switch pPara
                            case ('nBin') 
                                % case is the sleep intensity metrics
                                nRow = 60/nNew;          
                                lStr = setTimeBinStrings(nNew,nRow,1);
                            case ('nGrp') 
                                % case is the time-grouped stimuli response
                                lStr = setTimeGroupStrings(nNew,obj.tDay);
                        end                        
                        
                        % retrieves the plot indices
                        pSelF = obj.pData.sP(3).Lim.plotFit;
                        pSelT = obj.pData.sP(3).Lim.plotTrace;
                        
                        % expands/contracts the selection array
                        dpSel = length(lStr) - length(pSelF);
                        if dpSel > 0
                            pSelF = [pSelF;false(dpSel,1)];
                            pSelT = [pSelT;false(dpSel,1)];
                        else
                            pSelF = pSelF(1:length(lStr));
                            pSelT = pSelT(1:length(lStr));
                        end
                        
                        % updates the special parameter flags
                        obj.pData.sP(3).Lim.plotFit = pSelF;
                        obj.pData.sP(3).Lim.plotTrace = pSelT;                        
                        
                        % resets the table data
                        Data = [lStr(:),num2cell([pSelT,pSelF])];
                        if strcmp(p(uData{1}).Para,'nBin')
                            Data = [Data,num2cell(pSelF)];
                        end
                        
                        % updates the table properties
                        hTable = findall(obj.hPanel{5},'type','uitable');                        
                        set(hTable,'Data',Data)
                    end

                case ('Plot')
                    % case is a plotting parameter
                    obj.pData.pP(uData{1}).Value{1} = nwVal;             
                    p = obj.pData.pP;
            end

            % updates the parameter enabled properties
            p = obj.resetParaEnable(p,uData{1});
            eval(sprintf('obj.pData.%sP = p;',lower(uData{2}(1))));

            % performs the updates
            switch uData{2}
                case ('Calc')
                    resetRecalcObjProps(obj.hGUI,'Yes')
                case ('Plot')
                    obj.postParaChange()   
            end

            % makes sure the analysis parameter GUI is visible again
            if strcmp(get(obj.hFig,'visible'),'off')
                setObjVisibility(obj.hFig,'on'); 
                pause(0.05);
            end            
            
        end
        
        % --- callback function for the boolean parameters 
        function callbackBoolPara(obj,hObject,~)
            
            % retrieve the new parameter value and overall parameter struct
            nwVal = get(hObject,'Value');
            uData = get(hObject,'UserData');

            % retrieves the corresponding indices and parameter values            
            switch uData{2}
                case ('Calc')
                    % case is a calculation parameter
                    obj.pData.cP(uData{1}).Value = nwVal;
                    p = obj.pData.cP;
                    
                case ('Plot')
                    % case is a plotting parameter
                    obj.pData.pP(uData{1}).Value = nwVal; 
                    p = obj.pData.pP;
            end

            % % makes the GUI invisible
            % setObjVisibility(handles.figAnalysisPara,'off'); pause(0.05);;

            % updates the parameter enabled properties
            p = obj.resetParaEnable(p,uData{1});
            eval(sprintf('obj.pData.%sP = p;',lower(uData{2}(1))));            

            % performs the updates
            switch uData{2}
                case ('Calc')
                    % case is a calculation parameter
                    resetRecalcObjProps(obj.hGUI,'Yes')
                    
                case ('Plot')
                    % case is a plotting parameter
                    obj.postParaChange()   
            end            
            
        end
        
        % --- updates the main figure after a parameter change
        function postParaChange(obj,pDataNw)
            
            % sets the default input arguments
            if ~exist('pDataNw','var'); pDataNw = obj.pData; end                       
            
            % retrieve the main GUI handles and resets the plot data struct
            sPara = getappdata(obj.hFigM,'sPara');
            plotD = getappdata(obj.hFigM,'plotD');
            
            % retrieves the selected indices
            [eInd,fInd,pInd] = getSelectedIndices(obj.hGUI);                         
            if isempty(plotD{pInd}{fInd,eInd})
                % return if there is no plot
                return
            end                                  
            
            % disables the listboxes
            setObjEnable(obj.hGUI.popupPlotType,'inactive'); 
            setObjEnable(obj.hGUI.popupExptIndex,'inactive'); 

%             % resets the toolbar
%             resetFcn = getappdata(obj.hFigM,'resetToolbarObj'); 
%             resetFcn(obj.hGUI)

            % updates the figure
            wState = warning('off','all');
            obj.pData = updatePlotFigure(obj.hFig,pDataNw);
            warning(wState);
            
            % disables the listboxes
            setObjEnable(obj.hGUI.popupPlotType,'on'); 
            setObjEnable(obj.hGUI.popupExptIndex,'on'); 

            % determines if there are multiple subplots 
            if size(sPara.pos,1) > 1
                % if so, then update the parameter data struct
                sPara.pData{getappdata(obj.hFigM,'sInd')} = pDataNw;
                setappdata(obj.hFigM,'sPara',sPara);
            end                        
            
        end                
        
        % --- resizes the stimuli response
        function resizeStimRespTable(obj,pPara,indP,ind0)
            
            % global variables
            global HWT H0T
            
            % object handles
            hPanelSR = obj.hPanel{5};
            cPV = obj.pData.cP(indP).Value;
            
            % determines the table/data array size offset
            hTable = findall(hPanelSR,'type','uitable');  
            tPos = get(hTable,'Position');
            Data = get(hTable,'Data');
            dN0 = size(Data,1) - (tPos(4)-H0T)/HWT;
        
            % retrieves the previous/new group counts                    
            N0 = str2double(cPV{2}{ind0});
            N1 = str2double(cPV{2}{cPV{1}}); 
            
            switch pPara
                case 'nBin'
                    % case is the bin count size
                    dN = 60/N1-60/N0;
                    
                case 'nGrp'
                    % case is the group count
                    dN = N1-N0;
            end
            
            % resets the box panel height
            dHght = (dN+dN0)*HWT;
            obj.Hpanel(4) = obj.Hpanel(4) + dHght;
            obj.resetBoxPanelHeight()              
            pause(0.05)
            
%             % resets the panel bottom/height properties
%             resetObjPos(hPanelSR,'height',dHght,1);
%             resetObjPos(hPanelSR,'bottom',-dHght,1);   
            
            % resets the figure properties
            resetObjPos(obj.hFig,'height',dHght,1);
            resetObjPos(obj.hFig,'bottom',-dHght,1);
            
            % resets the bottom locations of the objects
            resetObjPos(hTable,'height',dHght,1);                               
            
        end
            
        % --------------------------------- %        
        % --- MAIN GUI OBJECT FUNCTIONS --- %
        % --------------------------------- %
        
        % --- resets the gui panel dimensions
        function resetGUIObjects(obj)
            
            % panel left/width dimensions
            h = guidata(obj.hFig);
            [L,W,H,H2] = deal(10,315,55,10);

            % resets the panel positions
            set(h.panelCalcPara,'position',[L 135 W H])
            set(h.panelPlotPara,'position',[L 70 W H])
            set(h.panelSubPara,'position',[L 50 W H2])
            set(h.panelTimePara,'position',[L 30 W H2])
            set(h.panelStimResPara,'position',[L 10 W H2])            
            
        end
        
        % --- sets up the GUI objects based on the parameter data struct
        function setupGUIObjects(obj,isInit)
            
            % initialisations
            h = guidata(obj.hFig);
            plotD = getappdata(obj.hFigM,'plotD');
            [eInd,fInd,pInd] = getSelectedIndices(obj.hGUI);
            
            % memory allocation
            hObjF = cell(3,1);
            wMax = deal(zeros(1,3)); 
            fPos = get(obj.hFig,'position');
            
            % ----------------------------------- %
            % --- FUNCTION FIELD OBJECT SETUP --- %
            % ----------------------------------- %  
            
            % sets the function file fields
            set(h.textFuncName,'string',obj.pData.Func);
            resetObjExtent(h.textFuncName)

            % sets the function description fields
            set(h.textFuncDesc,'string',obj.pData.Name);
            resetObjExtent(h.textFuncDesc)

            % sets the calculation required string properties
            tStr = 'Yes';
            if all([eInd,fInd,pInd] > 0)
                % if there is previous data, then flag the a recalculation 
                % is not required
                if ~isempty(plotD{pInd}{fInd,eInd})
                    tStr = 'No';        
                end
            end

            % initialises the calculation required string
            set(h.textCalcReqd,'string','MOOOOOOOO');
            resetObjExtent(h.textCalcReqd)
            resetRecalcObjProps(obj.hGUI,tStr,h)

            % sets the function info field handles
            hObjF{1} = {h.textFuncNameL,h.textFuncName};
            hObjF{2} = {h.textFuncDescL,h.textFuncDesc};
            hObjF{3} = {h.textCalcReqdL,h.textCalcReqd};

            % calculates the object widths
            wObjF = retObjDimPos(hObjF,3);
            wObjFMx = max(cellfun(@(x)(sum(x)+3.5*obj.pOfs),wObjF));            
            
            % ------------------------------------------ %
            % --- CALCULATION/PARAMETER OBJECT SETUP --- %
            % ------------------------------------------ %            
            
            % creates the parameter object fields
            obj.setupParaObjects('Spec');
            obj.setupParaObjects('Plot');
            obj.setupParaObjects('Calc');
            
            % retrieves the GUI object width dimensions
            obj.hasTab = ~cellfun('isempty',obj.hObj);
            wObj = cellfun(@(x)(retObjDimPos(x,3)),obj.hObj(1:2),'un',0);
            
            % determines the maximum object widths over all objects/types
            for i = 1:2
                for j = find(~cellfun('isempty',obj.hObj{i})')
                    if length(obj.hObj{i}{j}) == 1
                        % case is a boolean parameter
                        wMax(3) = max(wMax(3),wObj{i}{j});
                    else
                        % case is a numeric/list parameter
                        if ~isempty(wObj{i}{j})
                            wMaxNw = wObj{i}{j};
                            wMax(1:2) = max(wMax(1:2),wMaxNw);
                        end
                    end
                end
            end

            % determines the overall maximum 
            wObjMx = max(sum(wMax(1:2))+obj.pOfs/2,wMax(3)) + 3*obj.pOfs;
            if (wObjFMx > wObjMx)
                % the function information fields are longer
                obj.wObjNw = wObjFMx;
                wMax(2) = (obj.wObjNw - ((5/2)*obj.pOfs + wMax(1)));
            else
                % the calculation/plotting parameter fields are longer
                obj.wObjNw = wObjMx;
            end            
            
            % --------------------------------- %
            % --- PANEL HEIGHT CALCULATIONS --- %
            % --------------------------------- %            
            
            % sets the calculation/plotting parameter sizes
            HObj = zeros(2,1);
            for i = 1:2
                if isempty(obj.hObj{i})
                     if i == 1
                        % deletes the time panel
                        setObjVisibility(h.panelCalcPara,'off');
                    else
                        % deletes the subplot panel
                        setObjVisibility(h.panelPlotPara,'off');            
                     end
                    
                    % resets the box panel height
                    obj.Hpanel(i+1) = 0;                         
                else
                    HObj(i) = obj.nPmx(i)*obj.hOfs+4*obj.pOfs;
                end
            end

            % sets the calculation/plotting parameters sizes
            obj.HObjS = zeros(length(obj.pData.sP),1);
            if isempty(obj.hObj{3})
                % if not set up, then delete the time/subplot panels
                setObjVisibility(h.panelTimePara,'off');
                setObjVisibility(h.panelSubPara,'off'); 
                setObjVisibility(h.panelStimResPara,'off'); 
                
                % resets the box panel height
                obj.Hpanel(4:6) = 0;               
                
            else
                for i = 1:length(obj.hObj{3})
                    if isempty(obj.hObj{3}{i})               
                        switch (i)
                            case (1) 
                                % deletes the time panel
                                setObjVisibility(h.panelTimePara,'off'); 
                                hPosNw = get(h.panelTimePara,'position');
                                dy0 = -(obj.pOfs+hPosNw(4));
                                resetObjPos(h.panelSubPara,'bottom',dy0,1);
                                
                            case (2) 
                                % deletes the subplot panel
                                setObjVisibility(h.panelSubPara,'off'); 
                                
                            case (3) 
                                % deletes the subplot panel
                                setObjVisibility(h.panelStimResPara,'off');                                 
                        end
                        
                        % resets the box panel height
                        obj.Hpanel(7-i) = 0;
                        
                    else
                        % retrieves the first valid handle from the array
                        i0 = find(~cellfun...
                                    (@isempty,obj.hObj{3}{i}),1,'first');
                        if ~isempty(i0)
                            if iscell(obj.hObj{3}{i}{i0}{1})
                                hh = obj.hObj{3}{i}{i0}{1}{1};
                            else
                                hh = obj.hObj{3}{i}{i0}{1};
                            end

                            % retrieves the parent panel position and 
                            % sets the new height
                            hPosNw = get(get(hh,'parent'),'position');
                            obj.HObjS(i) = hPosNw(4) + obj.pOfs;
                            
                        else
                            switch (i)
                                case (1) % deletes the time panel
                                    setObjVisibility(h.panelTimePara,0);                         
                                case (2) % deletes the subplot panel
                                    setObjVisibility(h.panelSubPara,0);     
                                case (3) % deletes the subplot panel
                                    setObjVisibility(h.panelStimResPara,0);                                                         
                            end
                            
                            % resets the box panel height
                            obj.Hpanel(7-i) = 0;
                        end
                    end
                end
            end                                

            % ------------------------ %            
            % --- TIME LIMIT PANEL --- %
            % ------------------------ %    
            
            % resets the time limit panel width
            if obj.pData.hasTime
                obj.resetTimeLimitPanel();
            end
            
            % ------------------------------- %  
            % --- SUBPLOT PARAMETER PANEL --- %
            % ------------------------------- %                       

            % resizes the subplot parameter panel
            if obj.pData.hasSP
                obj.resetSubplotPanel();
            end
            
            % ---------------------------------------- %            
            % --- STIMULI RESPONSE PARAMETER PANEL --- %
            % ---------------------------------------- %            
            
            % resizes the stimuli response panel
            if obj.pData.hasSR && ~isempty(obj.hObj{3}{3})
                obj.resetStimPanel();
            end

            % -------------------------------------------- %            
            % --- PLOTTING/CALCULATION PARAMETER PANEL --- %
            % -------------------------------------------- %
            
            % resizes the plotting parameter panel
            for i = 2:-1:1
                if HObj(i) > 0
                    obj.resetParaPanel(obj.hPanel{i},i);
                end
            end
            
            % ---------------------------------- %            
            % --- FUNCTION INFORMATION PANEL --- %
            % ---------------------------------- %            
            
            % retrieves the box panel heights
            HpanelNw = obj.getCurrentPanelHeights();            
            
            % calculates the new overall figure height
            Hfig = sum(HpanelNw);
            
            % resets the box panel heights
            obj.resetBoxPanelHeight();                                     
            
            % resets the function parameters panel
            resetObjPos(h.panelFuncInfo,'width',obj.wObjNw)
            
            % --------------------------------- %
            % --- GUI OBJECT RE-POSITIONING --- %
            % --------------------------------- %            
            
            % sets the new left/right                        
            [W1,W2] = deal(wMax(1),wMax(2));
            [L1,L2] = deal(obj.pOfs,obj.pOfs+W1);                                  
            
            % resets the figure dimensions            
            resetObjPos(obj.hFig,'width',obj.wObjNw)            
            resetObjPos(obj.hFig,'height',Hfig)             
            resetObjPos(obj.hFig,'bottom',sum(fPos([2,4]))-Hfig)
%             resetObjPos(obj.hFig,'bottom',50)
            
            % updates the locations of the non-boolean parameters
            for i = 1:2
                for j = 1:length(obj.hObj{i})
                    if length(obj.hObj{i}{j}) == 2
                        % resets the 1st objects location
                        resetObjPos(obj.hObj{i}{j}{1},'left',L1)
                        resetObjPos(obj.hObj{i}{j}{1},'width',W1)

                        % resets the 2nd objects location
                        Wnw = W2-15*obj.hasTab(i);
                        resetObjPos(obj.hObj{i}{j}{2},'left',L2)
                        resetObjPos(obj.hObj{i}{j}{2},'width',Wnw)        
                    end
                end

                if obj.hasTab(i)
                    resetObjPos(obj.hTabG{i},'width',obj.wObjNw-15);
                end
            end            
            
            % makes the gui visible again
            if ~isInit
                setObjVisibility(obj.hFig,'on')
            end            
            
        end
            
        % ----------------------------- %
        % --- PANEL OBJECT RESIZING --- %
        % ----------------------------- %
        
        % --- resets the time limit parameter panel
        function resetTimeLimitPanel(obj)
            
            % initialisations
            nP = 4;
            h = guidata(obj.hFig);
            hObjNw = obj.hObj{3}{1};   
            
            % resets the panel position                     
            resetObjPos(h.panelTimePara,'width',obj.wObjNw)         

            % sets the object width and the new left location
            Wobj = roundP((obj.wObjNw - nP*obj.pOfs)/nP,1);
            L0 = (obj.wObjNw - nP*Wobj) - (nP-1/2)*obj.pOfs;            

            % resets the button position
            bPos = get(hObjNw{1}{3}{2},'position');
            Lnw = (obj.wObjNw-obj.pOfs)-(bPos(3)+2*obj.pOfs);
            resetObjPos(hObjNw{1}{3}{2},'left',Lnw)        
            resetObjPos(hObjNw{1}{3}{2},'width',bPos(3)+2*obj.pOfs)        

            % updates the object positions
            for i = 1:length(hObjNw{1}{1})
                for j = 1:2        
                    % resets the popupmenu object position
                    resetObjPos(hObjNw{j}{1}{i},'Left',L0);
                    resetObjPos(hObjNw{j}{1}{i},'Width',Wobj);

                    % resets the text header object position
                    resetObjPos(hObjNw{j}{2}{i},'Left',L0);
                    resetObjPos(hObjNw{j}{2}{i},'Width',Wobj);        
                end

                % resets the left location
                L0 = L0 + ((1/2)*obj.pOfs + Wobj);        
            end            
            
        end
        
        % --- resets the subplot parameter panel
        function resetSubplotPanel(obj)
            
            % initialisations
            h = guidata(obj.hFig);
            hObjNw = obj.hObj{3}{2};
            WTab = obj.wObjNw - (2+obj.pOfs);            
            wTab = roundP(WTab/6,1);            
            
            % sets the table column width array
            if obj.pData.hasRC
                colWid = [(WTab-3.5*wTab-obj.tOfs) wTab wTab 1.5*wTab];
            else
                colWid = [(WTab-2*wTab-obj.tOfs) 2*wTab];
            end

            % updates the table properties
            resetObjPos(hObjNw{1}{1},'width',WTab)
            set(hObjNw{1}{1},'ColumnWidth',num2cell(colWid));    
            resetObjPos(h.panelSubPara,'width',obj.wObjNw)
            resetObjPos(h.panelSubPara,'bottom',obj.yNew)
            obj.yNew = obj.yNew + obj.HObjS(2); 

            % calculates the row/column horizontal offset
            if obj.pData.hasRC
                lObj = cell2mat(retObjDimPos(hObjNw(2:3),1)');       
                wObj = cell2mat(retObjDimPos(hObjNw(2:3),3)');    
                wObjOfs = roundP((obj.wObjNw - sum(wObj))/2,1) - 2*lObj(1);                           

                % resets the panel/object positions    )    
                for i = 2:3
                    for j = 1:length(hObjNw{i})
                        resetObjPos(hObjNw{i}{j},...
                                        'Left',lObj((i-2)*2+j)+wObjOfs)
                    end
                end                 
            end            
            
        end
        
        % --- resets the stimuli response parameter panel
        function resetStimPanel(obj)
            
            % sets the column width offset
            h = guidata(obj.hFig);
            hObjNw = obj.hObj{3}{3};
            if ~isempty(hObjNw{1})
                % other initialisations
                updateStruct = false;
                nRow = size(get(hObjNw{1}{1},'Data'),1);
                wOfs = (17+20*ismac)*(nRow>10) + 2;
                [WTab,wTabL] = deal(obj.wObjNw - (2+obj.pOfs),70);   

                % sets the stimuli response type
                if isstruct(obj.pData.sP(3).Lim)
                    pType = obj.pData.sP(3).Lim.type;
                else
                    pType = obj.pData.sP(3).Lim;
                end    

                % calculates the text/popup box widths                                          
                switch (pType)
                    case {0,2} % case is the double column table
                        % sets the table column widths
                        colWid = [(WTab-1.5*wTabL-(obj.tOfs-2))-wOfs,...
                                  (1.5*wTabL)];    

                        % sets the new data struct
                        if (pType == 0)
                            updateStruct = true;
                            [a,b] = deal(true(nRow,1));
                        else
                            if isstruct(obj.pData.sP(3).Lim)
                                % resets the metric boolean flags
                                a = obj.pData.sP(3).Lim.plotTrace;
                                b = obj.pData.sP(3).Lim.plotFit;
                            else
                                % otherwise, initialise new values
                                updateStruct = true;
                                [a,b] = deal(true(nRow,1));
                            end
                        end
                    case (1) % case is the triple column table
                        % sets the table column widths
                        colWid = [(WTab-2*wTabL-(obj.tOfs-2))-wOfs,...
                                  wTabL,wTabL];    
                        if isstruct(obj.pData.sP(3).Lim)
                            nRowPr = length(obj.pData.sP(3).Lim.plotTrace);
                        else
                            nRowPr = -1;
                        end

                        % sets the new data struct
                        if (nRow == nRowPr)
                            % resets the metric boolean flags from last time
                            a = obj.pData.sP(3).Lim.plotTrace;
                            b = obj.pData.sP(3).Lim.plotFit;
                        else          
                            updateStruct = true;
                            [a,b] = deal([true;false(nRow-1,1)],false(nRow,1));                        
                        end
                end

                % resets the plot trace/fit data
                if updateStruct
                    obj.pData.sP(3).Lim = struct('plotTrace',a,...
                                'plotFit',b,'appInd',1,'type',pType);            
                end

                % updates the table properties
                resetObjPos(hObjNw{1}{1},'width',WTab)
                set(hObjNw{1}{1},'ColumnWidth',num2cell(colWid)); 
                autoResizeTableColumns(hObjNw{1}{1})
            end

            % updates the popup menu (if it exists)
            if length(hObjNw) > 1                
                txtPos = get(hObjNw{2}{1},'position');
                Lnw = sum(txtPos([1 3]))+obj.pOfs;
                resetObjPos(hObjNw{2}{2},'left',Lnw)
            end

            % resets the panel dimensions
            resetObjPos(h.panelStimResPara,'width',obj.wObjNw)
            
        end
        
        % --- resets the plotting parameter panel
        function resetParaPanel(obj,hPB,ind)
            
            % retrieves the panel object
            hP = findall(hPB,'tag','hPanelS');
            isShow = ~get(hPB,'Minimized');
            
            % sets the new locations
            N = 2;
            HNew = obj.nPmx(ind)*obj.hOfs + N*obj.pOfs + ...
                   obj.hTabOfs*(~isempty(obj.hTabG{ind}));    
            obj.Hpanel(ind+1) = HNew*isShow + obj.pHght;
               
            % resets the panel position
            resetObjPos(hP,'width',obj.wObjNw)
            resetObjPos(hP,'height',HNew)            

            % resets the tab group position
            if obj.hasTab(ind)
                HnwG = HNew-N*obj.pOfs;
                resetObjPos(obj.hTabG{ind},'height',HnwG)  
            end

            % increment the vertical offset
            obj.yNew = obj.yNew + (HNew+obj.pOfs);                
            set(hP,'UserData',HNew)
            
        end        
        
        % ---------------------------------- %        
        % --- PARAMETER OBJECT FUNCTIONS --- %
        % ---------------------------------- %        
        
        % --- sets up the parameter objects
        function setupParaObjects(obj,Type)

            % parameters            
            [dX,dY,dY0] = deal(5,3,5); 
            [obj.yOfs,obj.Hnew,obj.yNew] = deal(0,0,obj.pOfs);
            
            % retrieves the total solution data struct
            h = guidata(obj.hFig);

            % sets the panel handles and parameter struct
            switch Type
                case ('Calc') 
                    % case is a calculation parameter
                    [hPB0,p,iType] = deal(h.panelCalcPara,obj.pData.cP,1);        
                case ('Plot') 
                    % case is a plotting parameters
                    [hPB0,p,iType] = deal(h.panelPlotPara,obj.pData.pP,2);        
                case ('Spec') 
                    % case is a speciality parameters
                    [p,obj.yOfs,iType] = deal(obj.pData.sP,obj.pOfs,3);        
            end            
            
            % memory allocation
            nPara = length(p);            
            obj.hObj{iType} = cell(nPara,1);            
            if nPara == 0
                % if there are no parameters, then exit
                return
                
            else   
                % retrieves the fixed parameter flags
                iFree = find(~field2cell(p,'isFixed',1));
                
                % sets the update parameter indices
                if strcmp(Type,'Spec')
                    % case is a speciality parameter field                    
                    ind = (1:nPara)';
                    
                else
                    % determines the unique parameter type fields
                    tStr = field2cell(p(iFree),'Tab');        
                    [tStrU,~,C] = unique(tStr);
                    if isempty(tStrU{1}); tStrU{1} = '1 - General'; end

                    % determines the unique parameter indices
                    xiU = 1:length(tStrU);
                    tInd = arrayfun(@(x)(iFree(C == x)),xiU,'un',0);
                    ind = combineNumericCells...
                                (cellfun(@(x)(x(end:-1:1)),tInd,'un',0));                
                end                                
            end    
            
            % sets the maximum number of parameters
            [nPmx0,nTab] = size(ind);   
            
            % creates the calculation/plotting tab panels
            if iType < 3
                % sets the initial tab position vector
                obj.nPmx(iType) = nPmx0;
                hP0 = findall(hPB0,'tag','hPanelS');
                
                pPos = get(hP0,'Position');
                panelHght = get(hP0,'UserData');
                tPos = [dX,dY,pPos(3)-2*dX,panelHght-(2*dY+dY0)];                   
                
                % creates the master tab group and sets the properties                
                if isempty(obj.hTabG{iType})
                    % if the tab group does not exist, create a new one
                    tStr = sprintf('tab%s',Type);
                    obj.hTabG{iType} = createTabPanelGroup(hP0,1);
                    set(obj.hTabG{iType},'tag',tStr,'Position',tPos)                               

                    % memory allocation
                    [hTabP,N,i0] = deal(cell(obj.nTabMax,1),obj.nTabMax,1);

                    % creates the new tab panels                                    
                    for j = i0:N
                        hTabP{j} = createNewTabPanel...
                                        (obj.hTabG{iType},1,'UserData',j);  
                    end        

                    % updates the tab object array
                    obj.hTab{iType} = hTabP;
                    
                else
                    % otherwise, reset the tab position
                    set(obj.hTabG{iType},'Position',tPos)    
                    hTabP = obj.hTab{iType};                
                end     

                % sets the tab panel parent objects
                isOn = setGroup((1:nTab)',size(hTabP));
                cellfun(@(x)(set(x,'Parent',obj.hTabG{iType})),hTabP(isOn))
                cellfun(@(x)(set(x,'Parent',[])),hTabP(~isOn))                  
                
            end
            
            % creates the required parameter fields over all tabs
            for j = 1:nTab
                % determines the last parameter in the list
                indF = find(~isnan(ind(:,j)),1,'last');
                if ~isempty(obj.hTabG{iType})
                    set(hTabP{j},'Title',tStrU{j}(5:end))
                end                
            
                % creates the parameters for the current list
                for k = 1:indF
                    % retrieves the parameter struct fields
                    i = ind(k,j);
                    
                    % ----------------------------- %
                    % --- SPECIALITY PARAMETERS --- %
                    % ----------------------------- %   
                    
                    switch p(i).Type
                        case 'Time'
                            % case is the time parameter panel                            
                            obj.setupTimePara(p(i),i);
                            
                        case 'Subplot'
                            % case is the subplot parameter panel
                            obj.setupSubplotPara(p(i),i);
                            
                        case 'Stim'
                            % case is the stimuli parameter panel
                            obj.setupStimPara(p(i),i);
                            
                        otherwise
                            % case is a calculation/plotting panel
                            yNw = obj.pOfs+((k-1)+(nPmx0-indF))*obj.hOfs;
                            
                            % sets the tab panel object
                            if ~(strcmp(p(i).Type,'None') || ...
                                                ~isempty(obj.hTabG{iType}))
                                hTabNw = hPanel0;                                 
                            elseif exist('hTabP','var')
                                hTabNw = hTabP{j};
                            else
                                hTabNw = [];
                            end                            
                            
                            % sets up the plot object
                            obj.setupCalcPlotPara...
                                        (hTabNw,p(i),i,iType,yNw,{i,Type});
                            
                    end
                end                
            end
            
            % if plotting/calculation parameters, then set the initial
            % parameter enabled properties (based on initial values)
            if iType < 3
                % determines the parameters with enabled prop fields
                Enable = field2cell(p,'Enable');
                indE = ~cellfun('isempty',Enable);
                if ~any(indE); return; end
    
                % determines the indices of the parent parameter objects
                % and runs the parameter enabled check
                iSelP0 = cellfun(@(x)(x{1}),Enable(indE),'un',0);
                isC = cellfun(@iscell,iSelP0);
                iSelP0(isC) = cellfun(@(x)(cell2cell(x)),iSelP0(isC),'un',0);
                                
                % resets the enabled properties for the associated objects
                iSelP = cell2cell(iSelP0);
                if iscell(iSelP)
                    iSelP = cell2mat(iSelP(cellfun(@isnumeric,iSelP)));
                end
                
                iSelP = unique(iSelP);
                for i = iSelP(iSelP>0)'                    
                    p = obj.resetParaEnable(p,i);               
                end
                    
                % resets the parameters
                switch iType 
                    case 1
                        % case is the calculation parameters
                        obj.pData.cP = p;
                        
                    case 2
                        % case is the plotting parameters
                        obj.pData.pP = p;                        
                end
                
            end
                
        end
        
        % --- sets up the time parameters
        function setupTimePara(obj,p,indP)
          
            % if the object is empty then exit    
            if ~isempty(obj.hObj{3}{1})   
                return
            end
            
            % sets the callback function handle  
            h = guidata(obj.hFig);
            fPos = get(obj.hFig,'position');
            pPos = get(h.panelTimePara,'position');
            [hPB,hP,iP] = obj.getPanelObjHandles('panelTimePara');
            isShow = ~get(hPB,'Minimized');
            
            % sets the lower time limit objects
            hObjNw = cell(2,1);            
            hObjNw{1} = obj.createTimeLimitObj(hP,p.Value,'Lower',indP);            
            hObjNw{2} = obj.createTimeLimitObj(hP,p.Value,'Upper',indP);
            
            % increments the height/vertical offset
            HNew = 2*(2*obj.hOfs2 + obj.hOfs + obj.pOfs) + obj.pOfs;   

            % resets the panel dimensions
            set(hP,'UserData',HNew)
            resetObjPos(obj.hFig,'height',fPos(4)+(HNew-pPos(4)))
            resetObjPos(hP,'height',HNew);     
            obj.Hpanel(iP) = isShow*HNew + obj.pHght;       
            
            % updates the object field
            obj.hObj{3}{1} = hObjNw;            
            
        end
        
        % --- sets up the subplot parameter panel
        function setupSubplotPara(obj,p,indP)
            
            % if the object is empty then exit
            if ~isempty(obj.hObj{3}{2})
                return
            end
            
            % ------------------------------------------- %
            % --- INITIALISATIONS & MEMORY ALLOCATION --- %
            % ------------------------------------------- %            
            
            % initialisations
            Value = p.Value;
            nApp = length(Value.isPlot);    
            cbFcn = @obj.callbackSubPlot;
            [hPB,hP,iP] = obj.getPanelObjHandles('panelSubPara');
            isShow = ~get(hPB,'Minimized');
            
            % determines if the can combine trace flag is set
            if Value.canComb    
                % if so, create the check box and set the offset value
                [hObjNw,cOfs] = deal(cell(4,1),obj.hOfs);
                hObjNw{4}{1} = obj.createNewObj(hP,obj.pOfs,'CheckBox',...
                                'Combine All Traces Into Single Figure',...
                                Value.isComb);
                set(hObjNw{4}{1},'callback',cbFcn,'UserData',indP);
            else
                % otherwise, set the offset value to zero
                [hObjNw,cOfs] = deal(cell(3,1),0);                
            end
            
            % calculates the new subplot panel height dimension
            pPos = get(hP,'position');
            Htab = calcTableHeight(nApp,0,Value.hasRC); 
            obj.Hnew = Htab + 2*obj.pOfs + cOfs;            
                        
            % creates the objects for the row/column input
            if Value.hasRC                    
                % sets up the row parameters
                hObjNw{2}{1} = obj.createNewObj...
                            (hP,obj.Hnew,'Text','# Rows');
                hObjNw{2}{2} = obj.createNewObj...
                            (hP,obj.Hnew,'Edit',num2str(Value.nRow));

                % sets up the column parameters
                hObjNw{3}{1} = obj.createNewObj...
                            (hP,obj.Hnew,'Text','# Column');
                hObjNw{3}{2} = obj.createNewObj...
                            (hP,obj.Hnew,'Edit',num2str(Value.nCol));            

                % increments the height by the new object
                obj.Hnew = obj.Hnew + obj.pOfs + obj.hOfs;
                
                % sets the table properties
                colNames = {'Name','Row','Col','Include?'};
                colForm = {'char','char','char','logical'};
                colEdit = [false(1,3) true]; 
            else
                % sets the table properties
                colNames = {'Name','Include?'};
                colForm = {'char','logical'};
                colEdit = [false true];
                
                % sets the tab height
                Htab = Htab + nApp;                
            end                   
            
            % -------------------------- %
            % --- TABLE OBJECT SETUP --- %
            % -------------------------- %
            
            % creates the table            
            fSz = 11;  
            tStr = {'nRow','nCol'};
            figPos = get(obj.hFig,'Position');
            tabPos = [1 cOfs 200 Htab];  
            
            % creates the table object
            tData = obj.getSubplotTableData(Value);
            hObjNw{1}{1} = uitable(hP,'Position',tabPos,...
                        'ColumnName',colNames,'ColumnFormat',colForm,...
                        'ColumnEditable',colEdit,'RowName',[],...
                        'CellEditCallback',cbFcn,'UserData',indP,...
                        'Data',tData,'tag','hTable',...
                        'FontUnits','pixels','FontSize',fSz);                                
            autoResizeTableColumns(hObjNw{1}{1})            
            
            % resets the object widths of the row/column counts
            if Value.hasRC 
                L0 = obj.pOfs; 
                for l = 2:3
                    % resets the editbox width
                    set(hObjNw{l}{2},'Callback',cbFcn,'UserData',...
                                        {indP,l},'tag',tStr{l-1})
                    resetObjPos(hObjNw{l}{2},'Width',50);

                    % resets the left location of the objects
                    for kk = 1:2
                        % resets the object's left location
                        resetObjPos(hObjNw{l}{kk},'Left',L0);

                        % calculates the left location for the next object
                        objPos = get(hObjNw{l}{kk},'position');
                        L0 = L0 + (objPos(3) + obj.pOfs/2);
                    end
                end
            end            
            
            % resets the panel dimensions
            set(hP,'UserData',obj.Hnew)
            resetObjPos(obj.hFig,'height',figPos(4)+(obj.Hnew-pPos(4)))
            resetObjPos(hP,'height',obj.Hnew);     
            obj.Hpanel(iP) = isShow*obj.Hnew + obj.pHght;                                                        
            
            % updates the object field
            obj.hObj{3}{2} = hObjNw;
            
        end
        
        % --- retrieves the panel object handles for the tag, tagStr
        function [hPB,hP,iP] = getPanelObjHandles(obj,tagStr)
            
            % retrieves the outer and inner panel object handles
            hPB = findall(obj.hFig,'tag',tagStr);
            hP = findall(hPB,'tag','hPanelS');
            
            % retrieves the index of the panel
            iP = get(hPB,'UserData');        
        
        end
            
        % --- resets the box panel height
        function resetBoxPanelHeight(obj)            
            
            % determines which box panels are maximises
            HpanelNw = obj.getCurrentPanelHeights();
            
            % resets the panel heights
            set(obj.hVB,'Heights',HpanelNw,'MinimumHeights',HpanelNw);            
            
        end
        
        % --- sets up the time parameters
        function setupStimPara(obj,p,indP)
            
            % if the object is not empty then exit
            if ~isempty(obj.hObj{3}{3})
                return
            end
            
            % ------------------------------------------- %
            % --- INITIALISATIONS & MEMORY ALLOCATION --- %
            % ------------------------------------------- %            
            
            % initialisations
            figPos = get(obj.hFig,'Position');
            cbFcn = @obj.callbackStimResponse;
            [hPB,hP,iP] = obj.getPanelObjHandles('panelStimResPara');            
            isShow = ~get(hPB,'Minimized');
            snTotT = getappdata(obj.hFigM,'snTot');
            
            % retrieves the experiment/scope indices
            [eInd,~,pInd] = getSelectedIndices(obj.hGUI);            
            
            % determines if the experiments can be combined
            canComb = (~obj.pData.hasSP || obj.pData.hasSR) && ...
                      ((obj.pData.nApp > 1) && ~strcmp(p.Para,'appName'));
            if canComb                
                % retrieves the currently selected solution file
                snTot = getappdata(obj.hFigM,'snTot');
                if (pInd == 3)
                    snTotL = snTot(eInd);
                else
                    snTotL = reduceSolnAppPara(snTot(eInd));
                end                
                
                % sets the selected parameter value
                if isstruct(obj.pData.sP(3).Lim)
                    if isfield(obj.pData.sP(3).Lim,'appInd')
                        pVal = obj.pData.sP(3).Lim.appInd;
                    else
                        pVal = obj.pData.sP(3).Lim;
                    end
                else
                    pVal = 1;
                end                
                
                % other initialisations
                [hObjNw,cOfs] = deal(cell(2,1),obj.hOfs);                    
                lStr = snTotL.iMov.pInfo.gName;
                if obj.pData.useAll
                    lStr = [lStr;{'All Genotypes'}];
                end                
                
                % creates the popup menu/label objects
                hObjNw{2}{1} = obj.createNewObj(hP,obj.pOfs,'Text',...
                                'Currently Viewing');                   
                hObjNw{2}{2} = obj.createNewObj(hP,obj.pOfs,...
                                'PopupMenu',lStr,1);                            
                set(hObjNw{2}{1},'tag','hTextS');
                set(hObjNw{2}{2},'callback',cbFcn,'UserData',indP,...
                                  'Value',pVal,'tag','hPopupS'); 
                              
            else
                % otherwise, set the offset value to zero
                [hObjNw,cOfs] = deal(cell(1,1),0);                
            end
            
            if isstruct(p.Lim)
                if isfield(p.Lim,'type')
                    pType = p.Lim.type;
                else
                    pType = 1;
                end
            else
                pType = p.Lim;
            end 
            
            % retrieves the matching parameter value
            if ~isempty(obj.pData.sP(3).Para)
                pPara = field2cell(obj.pData.cP,'Para');
                ii = cellfun(@(x)(strcmp(x,p.Para)),pPara);
                if any(ii)               
                    cP = obj.pData.cP(ii);                
                    if strcmp(cP.Type,'List')
                        nNew = str2double(cP.Value{2}{cP.Value{1}});
                    else
                        nNew = cP.Value; 
                    end
                end

                % sets the column 
                switch p.Para
                    case ('nBin') 
                        % case is the sleep intensity metrics
                        nRow = 60/nNew;          
                        lStr = setTimeBinStrings(nNew,nRow,1);
                    case ('nGrp') 
                        % case is the time-grouped stimuli response
                        nRow = nNew;
                        lStr = setTimeGroupStrings(nNew,obj.tDay);
                    case {'appName','appNameS'}                        
                        lStr = snTotT(1).iMov.pInfo.gName;
                        if (pInd ~= 3)                            
                            lStr = lStr(snTotT(eInd).iMov.ok);
                        end
                        nRow = length(lStr);
                end        

                % calculates the table height
                nRowNw = min(nRow,10);
                
            else                               
                switch pType
                    case {1,3}
                        obj.Hnew = cOfs + 2*obj.pOfs; 
                        nRowNw = 0;
                        
                    case (2)
                        % sets the label strings    
                        lStr = {'Sleep Bouts','Sleep Duration',...
                                'Avg Bout Duration','Wake Activity',...
                                'Response Amplitude',...
                                'Inactivation Time Constant',...
                                'Pre-Stim Avg Speed',...
                                'Post-Stim Avg Speed',...
                                'Pre-/Post-Stim Avg Ratio'}';

                        % retrieves the global parameters 
                        gPara = getappdata(obj.hFigM,'gPara');                            

                        % determines if there are any stimuli events. if
                        % not, then remove the stimuli reponse fields
                        stimP = field2cell(snTotT,'stimP');
                        hasStim = any(~cellfun('isempty',stimP));
                        if strcmp(gPara.movType,'Midline Crossing') ...
                                                || ~hasStim
                            lStr = lStr(1:4);
                        end

                        % sets the number of table rows
                        [nRowNw,nRow] = deal(length(lStr));
                        
                    otherwise
                        obj.Hnew = cOfs + 2*obj.pOfs; 
                        nRowNw = 0;
                end
            end        
            
            % sets the table up depending on the type       
            pPos = get(hP,'position');                
            if nRowNw > 0
                % calculates the new table height
                Htab = calcTableHeight(nRowNw,0,true); 
                
                % sets the table properties (based on the parameter type)
                switch pType
                    case (0)
                        colNames = {'Group Name','Show Markers'};
                        colForm = {'char','logical'};
                        colEdit = [false true];         
                        DataNw = num2cell(true(nRow,1)); 
                        
                    case (1)                
                        colNames = {'Group Name','Plot Trace','Plot Fit'};
                        colForm = {'char','logical','logical'};
                        colEdit = [false true(1,2)];                                

                        if ~isstruct(obj.pData.sP(3).Lim)
                            DataNw = num2cell(false(nRow,2));
                            DataNw{1,1} = true;                            
                        else
                            % otherwise, set the limit values
                            sPL = obj.pData.sP(3).Lim;
                            DataNw = num2cell([sPL.plotTrace,sPL.plotFit]);      

                            if size(DataNw,1) ~= length(lStr)                                           
                                DataNw = num2cell(false(nRow,2));
                                DataNw{1,1} = true;                                                                       
                            end
                        end
                        
                    case (2)
                        colNames = {'Metric Name','Include?'};
                        colForm = {'char','logical'};
                        colEdit = [false true];         
                        DataNw = num2cell(true(nRow,1)); 
                end

                % sets the new table height and adds this to the total
                % figure height
                if (cOfs + Htab) == 0
                    obj.hObj{3}{3} = []; 
                    return
                else
                    obj.Hnew = Htab + obj.pOfs + (cOfs+3);                 
                end

                % sets the table properties
                if ~isempty(DataNw)
                    tabPos = [1 (cOfs+obj.pOfs) 300 Htab];

                    % sets the data array
                    Data = [lStr,DataNw];

                    % creates the table object
                    hObjNw{1}{1} = uitable(hP,'Position',tabPos,...
                            'ColumnName',colNames,'ColumnFormat',colForm,...
                            'ColumnEditable',colEdit,'RowName',[],...
                            'CellEditCallback',cbFcn,...
                            'UserData',indP,'Data',Data,'tag','hTable');

                    % if the stimuli separated stimuli response panel,
                    % then reset the userdata field
                    if strcmp(p.Para,'appNameS')
                        [~,nStim] = hasEqualStimProtocol(snTotT);
                        iPlot = false(nStim,2); iPlot(1) = true;
                        sStr = arrayfun(@(x)...
                            (sprintf('Stimuli #%i',x)),(1:nStim)','un',0);

                        % sets the object user data
                        uData = [{indP},cell(1,2)];
                        uData{2} = Data;
                        uData{3} = [sStr,num2cell(iPlot)];
                        set(hObjNw{1}{1},'UserData',uData)
                    end
                end
            end       
            
            % resets the panel location      
            set(hP,'UserData',obj.Hnew)            
            resetObjPos(obj.hFig,'height',figPos(4)+(obj.Hnew-pPos(4)))
            resetObjPos(hP,'height',obj.Hnew);
            obj.Hpanel(iP) = isShow*obj.Hnew + obj.pHght;
            
            % updates the object field
            obj.hObj{3}{3} = hObjNw;
            
        end   
        
        % --- sets up the time parameters
        function setupCalcPlotPara(obj,hTabP,p,indP,iType,yNew,uD)
         
            % sets the new height and increments the index
            [isValid,Enable] = deal(true,p.Enable);
            [Name,TTstr,Value] = deal(p.Name,p.TTstr,p.Value);
            
            % creates the objects for all of the parameters in the group
            switch p.Type
                case ('Number') % case is a numeric parameter
                    % creates the title and editbox object
                    obj.hObj{iType}{indP}{1} = ...
                            obj.createNewObj(hTabP,yNew,'Text',Name);
                    obj.hObj{iType}{indP}{2} = obj.createNewObj...
                            (hTabP,yNew,'Edit',num2str(Value),[],p.Para);            

                    % sets the callback function handle
                    cbFcn = @obj.callbackNumPara;

                case ('List') % case is a list parameter
                    % creates the title and popup-box object
                    obj.hObj{iType}{indP}{1} = ...
                            obj.createNewObj(hTabP,yNew,'Text',Name);
                    obj.hObj{iType}{indP}{2} = obj.createNewObj(hTabP,...
                            yNew,'PopupMenu',Value{2},Value{1},p.Para);

                    % sets the callback function handle
                    cbFcn = @obj.callbackListPara;

                case ('Boolean') % case is a boolean parameter
                    % creates the checkbox object
                    obj.hObj{iType}{indP}{1} = obj.createNewObj...
                            (hTabP,yNew,'CheckBox',Name,Value,p.Para);

                    % sets the callback function handle
                    cbFcn = @obj.callbackBoolPara;

                otherwise 
                    isValid = false;
            end

            % if there is a tool-tip string, then add it to the text object
            if ~isempty(TTstr)
                set(obj.hObj{iType}{indP}{1},'ToolTipString',TTstr)
            end

            % sets the callback function for the current object
            if isValid
                set(obj.hObj{iType}{indP}{end},...
                                    'Callback',cbFcn,'UserData',uD)       
            end        
            
%             % resets the enabled properties of the objects
%             if ~isempty(Enable)
%                 % disables the object if the enabled field is NaN
%                 if iscell(Enable{1})
%                     isOn = true;
%                 else
%                     isOn = all(~isnan(Enable{1}));
%                 end
%                     
%                 cellfun(@(x)(setObjEnable(x,isOn)),obj.hObj{iType}{indP})
%             else
%                 % otherwise, enable the object
%                 try
%                     cellfun(@(x)(setObjEnable(x,1)),obj.hObj{iType}{indP})
%                 end
%             end
            
        end             
        
        % --- creates the time limit objects
        function hObjNw = createTimeLimitObj(obj,hP,Value,Type,ind)
            
            % memory allocation
            hObjNw = cell(3,1); 
            hObjNw(1:2) = {cell(1,4)};
            pNw = getStructField(Value,Type);
            cbFcn = @obj.callbackTimeLimit;

            % sets the y-offset and parameter fields            
            switch (Type)
                case ('Lower')
                    % case is the lower time limit
                    hObjNw{3} = cell(1,2);  
                    pNw = Value.Lower;
                    y0 = (3/2)*obj.pOfs+(2*obj.hOfs2+obj.hOfs);
                    y1 = (y0+obj.hOfs+obj.hOfs2);

                    % creates the pushbutton object
                    bStr = 'Reset Limits';
                    hObjNw{3}{2} = ...
                                obj.createNewObj(hP,y1,'PushButton',bStr);
                    set(hObjNw{3}{2},'Callback',cbFcn,'UserData',ind)
                    
                case ('Upper')
                    % case is the upper time limit
                    [y0,pNw] = deal(obj.pOfs,Value.Upper);
            end

            % sets the date strings
            dStr = [arrayfun(@(x)(sprintf('0%i',x)),(0:9)','un',0);...
                    arrayfun(@num2str,(10:59)','un',0)];  

            % memory allocation
            nDay = Value.Upper(1);
            sStr = {'Day','Hours','Mins','AM/PM'};
            pStrNw = {arrayfun(@(x)(num2str(x)),(0:nDay)','un',0);...
                      arrayfun(@(x)(num2str(x)),(0:11)','un',0);...
                      dStr;{'AM';'PM'}};

            % creates the header text object
            obj.yNew = y0 + (obj.hOfs + obj.hOfs2);
            tStr = sprintf('%s TIME LIMIT',upper(Type));
            hObjNw{3}{1} = obj.createNewObj(hP,obj.yNew,'Text',tStr);        

            % creates the popup-menu/header text objects
            for i = 1:length(sStr)
                % creates the objects
                hObjNw{1}{i} = obj.createNewObj...
                                (hP,y0,'PopupMenu',pStrNw{i},pNw(i)+1);
                hObjNw{2}{i} = obj.createNewObj...
                                (hP,y0+obj.hOfs,'TextHeader',sStr{i});

                % sets the popup menu callback function
                set(hObjNw{1}{i},'Callback',cbFcn,'UserData',...
                                    {i,ind,Type},'tag',Type)
            end   
            
        end
        
        % --- creates the new ui control object and sets the 
        %     string/position fields
        function hObjP = createNewObj(obj,hP,yNew,Style,Name,Value,Para)

            % initialisations
            [Wmin,fW,fSz] = deal([],'Normal',12);

            % sets the actual object height
            switch Style
                case {'Text','TextHeader'}
                    [H,Wofs,yOfs0,fW] = deal(17,0,0,'bold');
                case ('Edit')
                    [H,Wofs,yOfs0,Wmin,fSz] = deal(23,2,2,120,11);
                case ('CheckBox')
                    [H,Wofs,yOfs0,fW] = deal(23,22,2,'bold');
                case ('PopupMenu')
                    [H,Wofs,yOfs0,fSz] = deal(23,20+(25*ismac),2,11);        
                case ('PushButton')
                    [H,Wofs,yOfs0,fW] = deal(23,3,0,'bold');                
            end

            % sets the temporary 
            yNew = yNew - yOfs0;
            if strcmp(Style,'PopupMenu')
                hTemp = cellfun(@(x)(uicontrol...
                        ('Style','Text','String',x,'Position',...
                         [obj.pOfs yNew length(x)*10 H])),Name,'un',0);
            else
                % sets the position vector
                PosNw = [obj.pOfs yNew length(Name)*10 H];

                % creates the text object
                if strcmp(Style,'TextHeader')
                    hTemp = {uicontrol('Style','Text','String',Name,...
                                'Position',PosNw,'Parent',hP,...
                                'HorizontalAlignment','Center')};            
                else
                    hTemp = {uicontrol('Style','Text','Parent',hP,...
                                'Position',PosNw,'String',[Name,': '],...
                                'HorizontalAlignment','Right')}; 
                end
            end

            % determines the maximum extent width over all the objects
            cellfun(@(x)(set(x,'FontUnits','Pixels','FontWeight',...
                                fW,'FontSize',12)),hTemp)
            pExt = cellfun(@(x)(get(x,'Extent')),hTemp,'un',0);    
            Wnw = max(cellfun(@(x)(x(3)+Wofs),pExt));

            % ensures the minimum width is at least Wmin (if value is set)
            if ~isempty(Wmin)
                Wnw = max(Wmin,Wnw);
            end

            % creates the ui control object
            if any(strcmp({'Text','TextHeader'},Style))
                % object is already a text 
                hObjP = hTemp{1};
                set(hObjP,'Position',[obj.pOfs yNew Wnw H]);
                
            else
                % otherwise, delete the old objects and create the new one
                cellfun(@delete,hTemp)
                pPos = [obj.pOfs yNew Wnw H];
                hObjP = uicontrol('Parent',hP,'Style',Style,...
                                 'String',Name,'Position',pPos);

                % if the value field was provided, then set that as well
                if exist('Value','var')
                    if ~isempty(Value)
                        set(hObjP,'Value',Value)
                    end
                end
            end

            % sets the other fields
            set(hObjP,'FontUnits','Pixels','FontWeight',fW,'FontSize',fSz)
            if exist('Para','var'); set(hObjP,'Tag',Para); end

        end
        
        % --- updates the special panel properties base on type/selection
        function setSpecialPanelProps(obj,pStr,offInd,Value)

            % updates the special panel properties for each element in the list
            for i = 1:length(pStr)
                % loop initialisation flag    
                [isUpdate,isOff] = deal(true,any(Value == offInd));

                % retrieves the objects/performs actions based on type
                switch (pStr{i})
                    case ('SR') 
                        % case is the stimuli response parameters
                        hP = findall(obj.hFig,'tag','panelStimResPara');
                        
                    case ('SP') 
                        % case is the subplot parameters
                        hP = findall(obj.hFig,'tag','panelSubPara');
                        
                    case ('SRS') 
                        % case is the short stimuli reponse parameters
                        
                        % initialisations
                        [isUpdate,updatePara] = deal(false,true);
                        hP = findall(obj.hFig,'tag','panelStimResPara');

                        % retrieves the table object properties
                        hTable = findall(hP,'tag','hTable');
                        Data = get(hTable,'Data');
                        uData = get(hTable,'UserData');

                        % updates table fields/userdata based on selection
                        if isOff
                            uData{2} = Data;                
                            set(hTable,'Data',uData{3});
                        else
                            if (strcmp(Data{1,1},'Stimuli #1'))
                                uData{3} = Data;                
                                set(hTable,'Data',uData{2});
                            else
                                updatePara = false;
                            end                                
                        end

                        % resets the table user data fields
                        set(hTable,'UserData',uData);

                        % updates the plotting parameter struct
                        if updatePara
                            % updates the plotting data in the gui
                            obj.pData.sP(uData{1}).Lim.plotTrace = ...
                                            cell2mat(uData{2+isOff}(:,2));
                            obj.pData.sP(uData{1}).Lim.plotFit = ...
                                            cell2mat(uData{2+isOff}(:,3));

                            % retrieves the currently selected indices
                            h = guidata(obj.hFigM);
                            [eInd,fInd,pInd] = getSelectedIndices(h);
                                        
                            % updates the data within the main gui
                            pData0 = getappdata(obj.hFigM,'pData');                                                          
                            pData0{pInd}{fInd,eInd} = obj.pData;
                            setappdata(obj.hFig,'pData',pData0)                                
                        end

                        % updates the enabled properties of the other objects
                        hObjNw = [findall(hP,'tag','hPopupS');...
                                  findall(hP,'tag','hTextS')];
                        setObjEnable(hObjNw,isOff)            
                end

                % updates the panel properties (if not reset above)
                if isUpdate
                    setPanelProps(hP,isOff)
                end            
            end

        end
        
        % ------------------------------- %        
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- resets the enabled properties of the GUI objects wrt a change 
        %     in the value of another parameter (i.e., listbox changes)
        function p = resetParaEnable(obj,p,iSel)
            
            % initialsations
            hObj0 = [];

            % sets the enables properties
            for i = 1:length(p)
                if ~isempty(p(i).Enable)                       
                    % sets the parameter indices and enabled strings
                    [pInd,onInd] = deal(p(i).Enable{1},p(i).Enable{2});     
                    if size(p(i).Enable,2) == 2
                        enInd = true(size(pInd));
                    else
                        enInd = p(i).Enable{3};
                    end           
                    
                    % converts any numeric cell arrays to a numeric array
                    if iscell(pInd) && isnumeric(pInd{1})
                        [pInd,onInd] = deal(cell2mat(pInd),cell2mat(onInd));
                    end

                    % if the parameter index matches that being changed, 
                    % then update the enabled properties of the objects
                    if iscell(pInd)
                        % retrieves the current parameter value
                        if strcmp(p(i).Type,'List')
                            % case is a list parameter
                            Value = p(i).Value{1};
                        else
                            % case is the other parameters
                            Value = p(i).Value;
                        end

                        % updates the special parameter panel objects            
                        cellfun(@(x,y)(obj.setSpecialPanelProps...
                                            (x,y,Value)),pInd,onInd);                                
                    
                    elseif any(pInd == iSel)
                        % sets the parameter indices and enabled strings
                        isOn = true;
                        pT = {'Type','Value','isFixed','Para'}; 
                        [Type,Val,isF,pP] = field2cell(p(pInd),pT);
                        hObjP = cellfun(@(x)...
                                (findall(obj.hFig,'tag',x)),pP,'un',0);

                        for k = 1:length(Type)
                            % retrieves the current value of the parameter
                            switch Type{k}
                                case {'List','FixedList'} % 
                                    if iscell(Val{k})
                                        pVal = Val{k}{1};
                                    else
                                        pVal = Val{k};
                                    end
                                case ('Boolean') %
                                    pVal = Val{k} + 1;
                            end

                            % sets the indices to check
                            if iscell(onInd)
                                % index array is a cell array
                                onIndNw = onInd{k};
                            else
                                % index array is a numerical array
                                onIndNw = onInd;
                            end

                            % sets the new enabled flag
                            if isF{k}
                                isOn = isOn && any(pVal == onIndNw);
                                
                            elseif strcmp(get(hObjP{k},'enable'),'on')                
                                isOn = isOn && any(pVal == onIndNw);

                            elseif enInd(k)
                                isOn = false;

                            end   

                            % if not on, then exit the loop
                            if ~isOn; break; end
                        end

                        % sets the enabled properties 
                        hObj0 = findall(obj.hFig,'Tag',p(i).Para);
                        hText = findall(obj.hFig,'String',[p(i).Name,': ']);
                        setObjEnable([hObj0;hText],isOn);

                        % if a boolean parameter is being disabled, then 
                        % also set the checkbox value to false
                        if ~isOn && strcmp(p(i).Type,'Boolean')
                            set(hObj0,'Value',false)
                            p(i).Value = false;
                        end                                   
                    end
                end
            end

            % updates the tab enabled properties
            if ~isempty(hObj0)
                updateTabEnabledProps(hObj0); 
            end            
            
        end        
        
        % --- updates the parameter field within the main gui
        function updateMainPara(obj)
        
            % initialisations
            [eInd0,fInd0,pInd0] = getSelectedIndices(obj.hGUI);
            
            % updates field within the main gui
            pData0 = getappdata(obj.hFigM,'pData');
            pData0{pInd0}{fInd0,eInd0} = obj.pData;            
            setappdata(obj.hFigM,'pData',pData0)  
                        
        end
        
        % --- updates the plot data within the class object
        function updatePlotData(obj,pDataNw)
           
            obj.pData = pDataNw;
            setappdata(obj.hFig,'pObj',obj);
            
        end
        
        % --- resets the time limit popup objects values 
        function resetTimeObj(obj,Type,iVal)

            % retrieves the popup object handles and resets their values
            hPanelT = findall(obj.hFig,'tag','panelTimePara');
            hPop = findobj(hPanelT,'tag',Type);
            for i = 1:length(hPop)
                uData = get(hPop(i),'UserData');
                set(hPop(i),'Value',iVal(uData{1}))
            end

        end
        
        % --- retrieves the current heights of the box panel objects
        function HpanelNw = getCurrentPanelHeights(obj)
            
            % determines which box panels are maximises
            isShow = obj.Hpanel > 0;
            isMax = ~arrayfun(@(x)(x.Minimized),obj.hChild);
            HpanelNw = obj.Hpanel.*isMax;  
            HpanelNw(isShow) = max(HpanelNw(isShow),obj.pHght);            
            
        end        
        
    end
    
    % static class methods
    methods (Static)
        
        % --- retrieves the subplot table data (based on the selections) 
        function Data = getSubplotTableData(Sub)

            % if not combining traces, then update the table with the data
            if Sub.hasRC
                A = repmat({'N/A'},length(Sub.isPlot),2);
                if ~Sub.isComb
                    % determines the new row/column indices
                    xi = (1:sum(Sub.isPlot))';
                    iRow = (floor((xi-1)/Sub.nCol)+1);
                    iCol = (mod((xi-1),Sub.nCol)+1);

                    % sets the row/column indices
                    xiI = num2cell([iRow,iCol]);
                    A(Sub.isPlot,:) = cellfun(@num2str,xiI,'un',0);
                end    
            else
                % sets the final data struct
                A = [];
            end

            % sets the final data struct
            Data = [Sub.Name,A,num2cell(logical(Sub.isPlot))];

        end
        
    end
    
end
