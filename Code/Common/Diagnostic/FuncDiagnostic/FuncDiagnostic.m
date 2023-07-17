classdef FuncDiagnostic < handle
    
    % class properties
    properties
        
        % figure handle fields        
        hFigM        
        
        % main class fields
        plotD
        pData        
        pDataT
        snTot
        gPara
        
        % sub-class objects
        ffObj
        fTreeObj
        prObj
        
        % index/mapping arrays
        iCG
        indS
        indF        
        Imap
        ImapU
        sNode
        hEditL
        hSliderL
        logStr
        fExpt
        errData
        
        % class object handles fields
        hAx
        hFig
        hTreeF
        hPanelO
        hPanelI
        hPanelF
        hPanelD
        hPanelLO
        hPanelL
        hPanelP
        hPanelFcn
        hToggleFilt
        hPanelFilt  
        hTxtI
        hCheckGrp
        hPanelPC
        hButC
        hTxtP
        hMenu
        hTableD        
        
        % fixed object dimensions        
        dX = 10;        
        widPanelL = 400;
        widPanelR = 450;        
        widPanelFilt = 290; 
        hghtPanelO = 535;
        hghtPanelI = 130;
        hghtPanelP = 190;        
        hghtPanelFilt = 180; 
        hghtPanelPC = 40;
        hghtEdit = 21;
        hghtBut = 21;
        hghtTxt = 16;    
        widTxtI = 155;
        hdrHght = 29;                
        
        % variable object dimensions
        widFig
        widPanelO
        widPanelFcn        
        widButC
        widTableD
        hghtFig
        hghtPanelF
        hghtPanelD
        hghtPanelL
        hghtPanelFcn         
        hghtTableD     
        
        %
        fInd
        eInd
        pInd
        fStrS
        iSelS
        iScopeS
        pPosLI
        
        % boolean flag fields
        hasData
        useScope
        runDiag = false;
        
        % fixes scalar/string fields        
        nExp
        nColD
        logY0 = 6;
        hSz = 12;
        tSz = 10;
        nBut = 2;
        nRowD = 3;
        nRowMx = 15;  
        tPause = 1.0;
        tLong = 12;
        logSz = 13;
        widScr = 17;
        rowHght = 20;
        hghtLog = 212;
        tabStr = '  ';
        arrStr = char(8594);
        tDurS = {'Short','Long'};
        tagStr = 'figFuncDiagnostic';
        isOldVer = verLessThan('matlab','9.10');
        
        % function handles
        initAxes
                        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = FuncDiagnostic(hFigM)
            
            % sets the input arguments
            obj.hFigM = hFigM;            
            
            % sets the input arguments
            obj.snTot = getappdata(obj.hFigM,'snTot');
            obj.plotD = getappdata(obj.hFigM,'plotD');            
            obj.pData = getappdata(obj.hFigM,'pData');
            obj.pDataT = getappdata(obj.hFigM,'pDataT');
            obj.gPara = getappdata(obj.hFigM,'gPara');
            
            % initialises the class fields
            obj.initClassFields();
            obj.initObjProps();            
            
        end
        
        % --------------------------------------- %
        % --- OBJECT INITIALISATION FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % memory allocation
            obj.logStr = '';
            obj.nExp = length(obj.snTot);
            A = [true(1,obj.nRowD-1),obj.nExp>1];
            [obj.useScope,obj.hasData] = deal(A);

            % resets the font sizes (old version only)
            if obj.isOldVer
                obj.hSz = 13;
                obj.tSz = 12;                
                obj.hdrHght = 22;
                obj.rowHght = 18;
            end            
            
            % calculates the panel dimensions
            obj.widPanelFcn = obj.widPanelL - 2*obj.dX;
            obj.widPanelO = (obj.widPanelL + obj.widPanelR) + 3*obj.dX;            
            obj.hghtPanelF = obj.hghtPanelO - (obj.hghtPanelI + 2*obj.dX);           
            obj.hghtPanelFcn = obj.hghtPanelF - 8*obj.dX;            
            obj.widButC = (obj.widPanelR - (3 + obj.nBut)*obj.dX)/obj.nBut;            
            
            % calculates the table dimensions
            obj.widTableD = obj.widPanelR - 2*obj.dX;
            obj.hghtTableD = obj.hdrHght + obj.nRowD*obj.rowHght;            
            obj.hghtPanelD = 4*obj.dX + obj.hghtTableD;
            
            % calculates the height of the progress log panel
            hghtPanelT = obj.hghtPanelD + obj.hghtPanelP;
            obj.hghtPanelL = obj.hghtPanelO - (hghtPanelT + obj.dX);
            
            % calculates the figure dimensions
            obj.widFig = obj.widPanelO + 2*obj.dX;
            obj.hghtFig = obj.hghtPanelO + 2*obj.dX;                                    
            
            % function handle retrieval
            obj.initAxes = getappdata(obj.hFigM,'initAxesObject');
            
        end
        
        % --- initialises the class objects
        function initObjProps(obj)
            
            % deletes any previous GUIs
            hPrev = findall(0,'tag',obj.tagStr);
            if ~isempty(hPrev); delete(hPrev); end                                   
            
            % creates the loadbar
            lStr = 'Initialising Function Diagnostic Program...';
            h = ProgressLoadbar(lStr);                        
            
            % --------------------------- %
            % --- MAIN FIGURE OBJECTS --- %
            % --------------------------- %
            
            % creates the figure object
            figName = 'Analysis Function Diagnostic';
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % creates the figure object
            obj.hFig = createUIObj('figure','Position',fPos,...
                'tag',obj.tagStr,'MenuBar','None','Toolbar','None',...
                'Name',figName,'Resize','off','NumberTitle','off',...
                'Visible','off');
            
            % creates the experiment combining data panel
            pPos = [obj.dX*[1,1],obj.widPanelO,obj.hghtPanelO];
            obj.hPanelO = createUIObj...
                ('panel',obj.hFig,'Title','','Position',pPos);
            
            % sets the object into the figure
            setappdata(obj.hFig,'fObj',obj)            
            
            % ------------------------------- %
            % --- ANALYSIS FUNCTION PANEL --- %
            % ------------------------------- %
                                                
            % panel object properties        
            tStrL = 'Function Filter: ';
            tStrF = 'TESTING ANALYSIS FUNCTIONS';  
            tStrB = 'Open Analysis Function Filter';
            widTxtL = obj.widPanelL - (2*obj.dX + obj.widPanelFilt);
            
            % creates the experiment combining data panel
            pPosF = [obj.dX*[1,1],obj.widPanelL,obj.hghtPanelF];
            obj.hPanelF = createUIObj('panel',obj.hPanelO,'Title',...
                tStrF,'Position',pPosF,'FontSize',obj.hSz,...
                'FontWeight','bold');

            % creates the experiment combining data panel
            pPosFcn = [obj.dX*[1,3],obj.widPanelFcn,obj.hghtPanelFcn];
            obj.hPanelFcn = createUIObj('panel',obj.hPanelF,'Title','',...
                'Position',pPosFcn);   
                    
            % creates the sub-type grouping checkbox
            chkStr = 'Group Analysis Functions By Sub-Types';
            cPos = [obj.dX*[1,0.5],pPosFcn(3)-obj.dX,obj.hghtEdit];
            obj.hCheckGrp = createUIObj('checkbox',obj.hPanelF,...
                'Position',cPos,'FontWeight','Bold','String',chkStr,...
                'ValueChangedFcn',@obj.checkFuncGroup,...
                'FontSize',obj.tSz,'Value',false);
                    
            % creates the toggle button
            lPosB = obj.dX + widTxtL;
            yPosB = sum(pPosFcn([2,4])) + (1 + obj.dX/2);
            cbFcnB = @obj.toggleFilter;
            bPosB = [lPosB,yPosB,obj.widPanelFilt,obj.hghtBut];
            obj.hToggleFilt = createUIObj('togglebutton',obj.hPanelF,...
                'Position',bPosB,'FontWeight','Bold','FontSize',obj.tSz,...
                'Tag','toggleFuncFilter','ValueChangedFcn',cbFcnB,...
                'String',tStrB);
                    
            % creates the experiment combining data panel
            yPosFilt = yPosB - (obj.hghtPanelFilt - 1);            
            szFilt = [obj.widPanelFilt-1,obj.hghtPanelFilt];
            pPosFilt = [lPosB+1,yPosFilt,szFilt];
            obj.hPanelFilt = uipanel(obj.hPanelF,'Title','','Units',...
                'Pixels','Position',pPosFilt,'Visible','off',...
                'Tag','panelFuncFilter');                        
                    
            % creates the text label
            yPosL = yPosB + 1;
            tPosL = [obj.dX,yPosL,widTxtL,obj.hghtTxt];
            createUIObj('text',obj.hPanelF,'Position',tPosL,...
                'FontWeight','Bold','FontSize',obj.tSz,'String',tStrL,...
                'HorizontalAlignment','right');            
            
            % creates the function filter tree object
            if obj.isOldVer
                obj.ffObj = ...
                    FuncFilterTree(obj.hFig,obj.snTot,obj.pDataT);
            else
                obj.ffObj = ...
                    FuncDiagnosticFilter(obj.hFig,obj.snTot,obj.pDataT);
            end           
            
            % sets the function filter callback function
            set(obj.ffObj,'treeUpdateExtn',@obj.updateFuncFilter);
            
            % creates the diagnostic tree object
            obj.fTreeObj = FuncDiagnosticTree...
                (obj.ffObj,obj.hPanelFcn,obj.pDataT,obj.snTot);            
            obj.fTreeObj.extnSelectFcn = @obj.updateTableData;        
            
            % ------------------------------------ %
            % --- EXPERIMENTAL DATA INFO PANEL --- %
            % ------------------------------------ %
            
            % sets the text properties field
            if obj.isOldVer
                tFldP = 'String';
            else
                tFldP = 'Text';
            end
            
            % panel object properties
            tStrI = 'EXPERIMENTAL DATA INFORMATION';  
            hStrI = {'Experiment Count','Experiment Duration Type',...
                     'External Stimuli Type','Setup Configuration',...
                     'Experiment Names'};
            
            % creates the experiment combining data panel
            yPosI = sum(pPosF([2,4])) + obj.dX/2;
            pPosI = [obj.dX,yPosI,obj.widPanelL,obj.hghtPanelI];
            obj.hPanelI = uipanel(obj.hPanelO,'Title',tStrI,'Units',...
                        'Pixels','Position',pPosI,'FontUnits','Pixels',...
                        'FontSize',obj.hSz,'FontWeight','bold');            
                    
            % creates the 
            nFld = length(hStrI);
            obj.hTxtI = cell(nFld,1);
            for i = 1:nFld
                % sets the bottom coordinate of the object
                j = length(hStrI) - i;
                y0 = obj.dX*(0.5 + 2*j) + (obj.dX/2)*(i < nFld);
                
                % sets the object type fields
                switch i
                    case nFld
                        % case are the label/text fields
                        pTypeNw = {'T','P'};
                        
                    otherwise
                        % case are the label/text fields
                        pTypeNw = {'T','T'};
                end
                
                % creates
                [hTxtL,obj.hTxtI{i}] = obj.createObjPairs...
                          (obj.hPanelI,pTypeNw,obj.widTxtI,y0);
                
                % sets the label properties
                hStrIF = sprintf('%s: ',hStrI{i});
                set(hTxtL,'FontWeight','Bold','FontSize',obj.tSz,...
                          'HorizontalAlignment','right',tFldP,hStrIF)
                    
                % sets the information field
                tFld = obj.getInfoField(hStrI{i});
                set(obj.hTxtI{i},'FontSize',obj.tSz);
                if (i < nFld)
                    set(obj.hTxtI{i},...
                        tFldP,tFld,'HorizontalAlignment','Left');                
                else
                    % disables the popup menu (if only one expt)
                    obj.fExpt = tFld;                    
                    setObjEnable(obj.hTxtI{i},obj.nExp > 1)
                    
                    % sets the other properties
                    if obj.isOldVer
                        set(obj.hTxtI{i},'String',tFld,'Value',1);
                    else
                        set(obj.hTxtI{i},'Items',tFld,'Value',tFld{1});
                    end
                end
            end
                    
            % -------------------------------- %
            % --- SOLUTION FILE DATA PANEL --- %
            % -------------------------------- %
            
            % panel object properties
            lPosP = obj.widPanelL + 2*obj.dX;            
            tStrP = 'DIAGNOSTIC ANALYSIS PROGRESS'; 
            bStrPC = {'Start Diagnosis','Cancel Diagnosis'}; 
            cbFcnB = {@obj.startDiagnostic,@obj.cancelDiagnostic};
            
            % creates the experiment combining data panel
            obj.hPanelP = uipanel(obj.hPanelO,'Title',tStrP,'Units',...
                        'Pixels','FontUnits','Pixels',...
                        'FontSize',obj.hSz,'FontWeight','bold');                                                            
            
            % creates the control buttons
            widP = obj.widPanelR-2*obj.dX;
            pPosPC = [obj.dX*[1,1],widP,obj.hghtPanelPC];
            obj.hPanelPC = createUIObj('panel',obj.hPanelP,'Title','',...
                'Position',pPosPC);               
            
            % creates the diagnostic progress bar
            obj.prObj = FuncDiagnosticProg(obj.hPanelPC);
                    
            % resets the position of the progress panel
            pPosPr = get(obj.prObj.hPanel,'Position');
            hghtPanelPF = sum(pPosPr([2,4])) + 3*obj.dX;
            pPosP = [lPosP,obj.dX,obj.widPanelR,hghtPanelPF];
            set(obj.hPanelP,'Position',pPosP);
            
            % creates the control button objects
            for i = 1:obj.nBut
                lPosB = obj.dX + (i-1)*(obj.widButC + obj.dX);
                bPosPC = [lPosB,obj.dX,obj.widButC,obj.hghtBut];
                obj.hButC{i} = createUIObj('pushbutton',obj.hPanelPC,...
                    'Text',bStrPC{i},'Position',bPosPC,...
                    'FontWeight','Bold','ButtonPushedFcn',cbFcnB{i},...
                    'FontSize',obj.tSz);
                setObjEnable(obj.hButC{i},i==1);
            end            

            % -------------------------- %
            % --- PROGRESS LOG PANEL --- %
            % -------------------------- %            
            
            % panel object properties
            tStrL = 'PROGRESS LOG';
                        
            % creates the experiment combining data panel
            yPosL = sum(pPosP([2,4])) + obj.dX/2;
            pPosL = [lPosP,yPosL,obj.widPanelR,obj.hghtPanelL];
            obj.hPanelLO = uipanel(obj.hPanelO,'Title',tStrL,'Units',...
                        'Pixels','FontUnits','Pixels','Position',pPosL,...
                        'FontSize',obj.hSz,'FontWeight','bold');

            % creates the inner panel object
            obj.pPosLI = [0,0,pPosL(3:4)-[1,2*obj.dX]];
            obj.hPanelL = uipanel(obj.hPanelLO,'Units','Pixels',...
                        'Position',obj.pPosLI);
               
            % sets the panel scrolling to on (new version only)                    
            if ~obj.isOldVer
                set(obj.hPanelLO,'Scrollable','on');
                set(obj.hPanelL,'Scrollable','on');
            end                    
                    
            % creates the log editbox
            obj.hEditL = annotation(obj.hPanelL,'Textbox','Position',...
                        [0,0,1,1],'BackgroundColor',[1,1,1],...
                        'LineStyle','None','FontName','Courier',...
                        'FontUnits','Pixels','FontSize',10,...
                        'Units','Pixels','FaceAlpha',0.8);
            
            % -------------------------------- %
            % --- SOLUTION FILE DATA PANEL --- %
            % -------------------------------- %
            
            % panel object properties
            lPosP = obj.widPanelL + 2*obj.dX;            
            tStrP = 'DIAGNOSTIC ANALYSIS PARAMETERS';            
            
            % creates the experiment combining data panel
            yPosD = sum(pPosL([2,4])) + obj.dX/2;
            pPosD = [lPosP,yPosD,obj.widPanelR,obj.hghtPanelD];
            obj.hPanelD = uipanel(obj.hPanelO,'Title',tStrP,'Units',...
                        'Pixels','Position',pPosD,'FontUnits','Pixels',...
                        'FontSize',obj.hSz,'FontWeight','bold');                    
                    
            % creates the table object
            cWid = {90,90,95,81};
            cbFcnD = @obj.tableCellEdit;
            cEdit = [true,false,false,false];
            cForm = {'logical','char','char','char'};
            tPos = [obj.dX*[1,1],obj.widTableD,obj.hghtTableD];
            rName = {'Individual','Single Expt','Multi-Expt'};
            cName = {'Analyse?','Selected','Warnings','Errors'};               
            Data = cell(length(rName),length(cName));
            obj.hTableD = createUIObj('table',obj.hPanelD,...
                        'Position',tPos,'FontSize',10,...
                        'RowName',rName,'Data',Data,'FontName','FixedWidth',...
                        'ColumnWidth',cWid,'ColumnFormat',cForm,...
                        'ColumnEditable',cEdit,'CellEditCallback',cbFcnD);
            set(obj.hTableD,'ColumnName',cName);
                                
            % updates the table data
            obj.nColD = length(cName);
            obj.updateTableData();
            
            %
            if obj.isOldVer
                set(obj.hTableD,'FontSize',12)
                autoResizeTableColumns(obj.hTableD)
            end
            
            % ------------------------- %
            % --- MENU ITEM OBJECTS --- %
            % ------------------------- %            
            
            % creates the menu items
            obj.hMenu = uimenu(obj.hFig,'Label','File','Tag','menuFile');
            uimenu(obj.hMenu,'Label','Exit','Callback',@obj.menuExit,...
                             'Accelerator','X');                             
                    
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %                          
            
            % closes the loadbar
            delete(h.Control)            
            
            % pause for update
            pause(0.05);                        
            
            % centers the figure and makes it visible
            scrSz = get(0,'ScreenSize');            

            % resets the main gui position
            fPosM0 = get(obj.hFigM,'Position');
            fPosM = [scrSz(3)-fPosM0(3),41,fPosM0(3:4)];
            set(obj.hFigM,'Position',fPosM,'Visible','on');            
            
            % resets the position of the diagnostic window
            fPos0 = get(obj.hFig,'Position');            
            fPos = [1,scrSz(4)-(45+fPos0(4)),fPos0(3:4)];
            set(obj.hFig,'Position',fPos,'Visible','on');           
            
        end
        
        % --- creates the object pairs
        function [hObjL,hObjR] = createObjPairs(obj,hP,pType,widL,y0)
        
            % initialisations
            hObj = cell(1,2);
            pPos = get(hP,'Position');            
            
            % calculates the width/left dimensions
            widD = [widL,(pPos(3) - (2*obj.dX + widL))];
            leftD = obj.dX + [0,widD(1)];    
            
            % creates the object pairs
            for i = 1:length(hObj)
                % sets up the position vector
                pObj = [leftD(i),y0,widD(i),NaN];
                
                % creates the object based on type
                switch pType{i}
                    case 'T'
                        % case is a text label
                        pObj(4) = obj.hghtTxt;
                        pObj(2) = pObj(2) + 2;
                        pStyle = 'text';
                        
                    case 'C'
                        % case is a checkbox
                        pObj(4) = obj.hghtEdit;
                        pStyle = 'checkbox';
                        
                    case 'P'
                        % case is a popupmenu
                        pObj(4) = obj.hghtEdit;
                        pStyle = 'popupmenu';
                        
                    case 'B'
                        % case is a pushbutton
                        pObj(4) = obj.hghtBut;
                        pStyle = 'pushbutton';
                        
                    case 'E'
                        % case is an editbox
                        pObj(4) = obj.hghtEdit;
                        pStyle = 'edit';
                end
                
                % creates the object
                hObj{i} = createUIObj(pStyle,hP,'Position',pObj);
            end
            
            % sets the left/right objects
            [hObjL,hObjR] = deal(hObj{1},hObj{2});
            
        end            

        % ----------------------------------------- %
        % --- CONTROL BUTTON CALLBACK FUNCTIONS --- %
        % ----------------------------------------- %
        
        % --- start diagnostic button callback function
        function startDiagnostic(obj,hObj,~)

            % initialisations
            obj.errData = [];
            obj.prObj.nExp = obj.nExp;
            fldStr = fieldnames(obj.pDataT);
            prStr0 = 'Starting Function Diagnostic Analysis...';
            prStrF = 'Function Diagnostic Analysis Complete!';
            prStrEx = 'Function Diagnostic Analysis Cancelled...';
            [obj.fStrS,obj.iSelS] = obj.fTreeObj.getCurrentSelectedNodes();             
            
            % resets the diagnostic run flag
            obj.runDiag = true;  
            setObjEnable(hObj,0);
            setObjEnable(obj.hButC{2},1);
            
            % makes the parameter GUI invisible
            hPara = findall(0,'tag','figAnalysisPara');
            setObjVisibility(hPara,0);            
            
            % retrieves the currently selected functions
            obj.iScopeS = find(~cellfun(@isempty,obj.iSelS));
            obj.prObj.nPr(1) = double(obj.iScopeS(end) == 3) + ...
                           obj.nExp*length(intersect(obj.iScopeS,1:2));
            obj.prObj.iScope = obj.iScopeS;            
            obj.hTableD.Data(obj.iScopeS,3:4) = {0};
            
            % resets the table style
            if obj.isOldVer
                bgCol = get(obj.hTableD,'BackgroundColor');
                bgCol(obj.iScopeS,:) = 1;
                set(obj.hTableD,'BackgroundColor',bgCol)
            else
                s = uistyle('BackgroundColor','w','FontWeight','Normal');
                addStyle(obj.hTableD,s,'row',obj.iScopeS)               
            end
            
            % clears the progress log 
            obj.clearProgressLog();                        
            obj.updateProgressLog(prStr0)
            obj.updateProgressLog('Gap',0,'w')              

            % runs the analysis diagnostic for each analysis scope
            for i = 1:length(obj.iScopeS)
                % if the user has cancelled, then exit
                if ~obj.runDiag
                    obj.updateProgressLog(prStrEx,0,'r')
                    obj.cancelDiagnostic(obj.hButC{2});
                    return
                end
                
                % updates the progress log string
                iScope = obj.iScopeS(i);
                pStr = obj.getScopeString(fldStr{iScope});
                obj.updateProgressLog(pStr);
                obj.prObj.resetProgressFields(2:3);                
                obj.prObj.nPr(2) = obj.getExpCount(iScope);
                
                % runs the analysis diagnostic for each experiment
                for iExp = 1:obj.prObj.nPr(2)
                    % updates the progress log
                    pStrExp = obj.getExptString(obj.fExpt{iExp});
                    obj.updateProgressLog(pStrExp,1)
                    obj.prObj.resetProgressFields(3);
                    
                    % retrieves the plot data struct for the current scope                    
                    pDataS = obj.getPlotDataFields(iScope,iExp);
                    
                    % runs each analysis function
                    obj.prObj.nPr(3) = length(obj.iSelS{iScope});
                    for iFcn = 1:obj.prObj.nPr(3)
                        % if the user has cancelled, then exit
                        if ~obj.runDiag
                            obj.updateProgressLog('Gap',0,'w')
                            obj.updateProgressLog(prStrEx,0,'r')
                            obj.cancelDiagnostic(obj.hButC{2});
                            return
                        end                        
                        
                        % updates the function name string
                        snTotF = obj.getSolnDataStruct(iScope,iExp);                        
                        pDataF = pDataS{obj.iSelS{iScope}(iFcn)};
                        pStrF = obj.getFuncString(pDataF.Name);
                        obj.updateProgressLog(pStrF,2);                        
                        
                        % updates all progressbar fields
                        indSF = [iExp,iScope,iFcn];
                        obj.prObj.updateAllFields(indSF);
                        
                        % runs the analysis function calculation/plotting
                        obj.runAnalysisFunc(pDataF,snTotF,indSF);                        
                    end
                    
                    % creates a gap between log strings
                    obj.updateProgressLog('Gap',0,'w')
                end
            end
            
            % sets the final progress log string
            obj.updateProgressLog(prStrF,0,'g')
            obj.cancelDiagnostic(obj.hButC{2});
            warning ON VERBOSE            
            
        end        
        
        % --- cancel diagnostic button callback function
        function cancelDiagnostic(obj,hObj,~)
            
            % resets the diagnostic run flag
            obj.runDiag = false;
            setObjEnable(hObj,0);
            setObjEnable(obj.hButC{1},1);            
            
        end                
                
        % runs the analysis function calculation/plotting
        function runAnalysisFunc(obj,pDataF,snTotF,indSF)

            % initialises the plot axes
            lastwarn('');
            warning OFF VERBOSE
            obj.hAx = obj.initAxes(guidata(obj.hFigM));                     
            
            % -------------------------------------- %
            % --- ANALYSIS FUNCTION CALCULATIONS --- %
            % -------------------------------------- %                                    
            
            % runs the analysis function calculations
            obj.updateProgressLog('Running Calculations...',3)
            
            try
                % runs the analysis function calculations
                pltDC = feval(pDataF.cFcn,snTotF,pDataF,obj.gPara);
                
            catch ME
                % error was detected during the calculation process
                obj.updateProgressLog('Calculation Error Detected!!',4,'rb')
                obj.appendErrorData(ME,pDataF,indSF,true,true);
                obj.deleteProgBar();
                
                % retrieves the progressbar and deletes it
                return
            end            
            
            % retrieves the progressbar status
            if isempty(pltDC)
                obj.runDiag = false;
                return

            else
                % resets the current figure/axes objects
                set(0,'CurrentFigure',obj.hFigM)
                set(obj.hFigM,'CurrentAxes',obj.hAx);
            end
            
            % appends a warning (if one has been generated)
            [wMsg, wID] = lastwarn();            
            if ~isempty(wMsg)
                obj.updateProgressLog('Calculation Warning Detected!!',4,'rb')
                obj.appendErrorData({wMsg,wID},pDataF,indSF,true,false);
                lastwarn('');
            end
            
            % ---------------------------------- %
            % --- ANALYSIS FUNCTION PLOTTING --- %
            % ---------------------------------- %
            
            % plots the calculated results
            obj.updateProgressLog('Plotting Results...',3)                        
            
            try
                % runs the plotting function
                pDataNw = feval(pDataF.pFcn,snTotF,pDataF,{pltDC});
            
            catch ME
                % error was detected during the calculation process
                obj.updateProgressLog('Plotting Error Detected!!',4,'rb')
                obj.appendErrorData(ME,pDataF,indSF,false,true);
                return
            end 
            
            % pauses to view the plot
            pause(obj.tPause);            
            
            % appends a warning (if one has been generated)
            [wMsg, wID] = lastwarn();            
            if ~isempty(wMsg)
                obj.updateProgressLog('Plotting Warning Detected!!',4,'rb')
                obj.appendErrorData({wMsg,wID},pDataF,indSF,false,false);
                
            else
                % updates the plot data struct
                iFcn = obj.iSelS{indSF(2)}(indSF(3));
                obj.plotD{indSF(2)}{iFcn,indSF(1)} = {pltDC};
            end                        
            
        end
        
        % ------------------------------------- %
        % --- PROGRESS LOG UPDATE FUNCTIONS --- %
        % ------------------------------------- %        
        
        % --- updates the progress log panel
        function updateProgressLog(obj,nwStr0,nTab,sCol)
            
            % sets the string colour
            if ~exist('nTab','var'); nTab = 0; end
            if ~exist('sCol','var'); sCol = 'k'; end
            
            % appends the new string to the array
            baseStr = obj.setBaseString(nTab,sCol);
            obj.logStr{end+1} = sprintf('%s%s',baseStr,nwStr0);
            
            % updates the log string and the 
            set(obj.hEditL,'String',obj.logStr);
            obj.setProgressLogProps();
            pause(0.01);
            
        end
        
        % --- clears the progress log panel
        function clearProgressLog(obj)
            
            % clears the log strings
            obj.logStr = [];
            set(obj.hEditL,'String','');
            obj.setProgressLogProps();
            
            % creates the progressbar fields
            obj.prObj.resetProgressFields();
            
        end        
        
        % --- sets the progress log object position properties
        function setProgressLogProps(obj)
            
            % initialisations
            nRow = length(obj.hEditL.String);
            
            % sets the position vector (based on the row count)
            if nRow <= obj.nRowMx
                pPos = obj.pPosLI;
            else
                hghtPos = roundP(nRow*obj.logSz) + obj.logY0;
                pPos = [0,0,obj.pPosLI(3)-obj.widScr,hghtPos];
            end
        
            % sets the panel/textbox positions
            set(obj.hPanelL,'Position',pPos);
            set(obj.hEditL,'Position',[1,1,pPos(3:4)-2]);   
            
            if obj.isOldVer
                a = 1;
            else
                scroll(obj.hPanelLO,'bottom')
            end
            
        end
        
        % --------------------------------------- %
        % --- OTHER OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- the function filter toggle button callback
        function toggleFilter(obj, hObj, ~)
            
            % object handles
            isOpen = get(hObj,'Value');
            
            % sets the text field string
            if obj.isOldVer
                tFldP = 'String';
            else
                tFldP = 'Text';
            end

            % updates the funcion filter panel visibility
            setObjVisibility(obj.hPanelFilt,isOpen);

            % updates the toggle button string
            if isOpen
                set(hObj,tFldP,'Close Analysis Function Filter')
            else
                set(hObj,tFldP,'Open Analysis Function Filter')
            end            
            
        end
        
        % --- function sub-grouping checkbox callback
        function checkFuncGroup(obj, hObj, ~)
            
            obj.fTreeObj.useSubGrp = get(hObj,'Value');
            obj.updateFuncFilter();            
            
        end
        
        % --- table data cell edit callback 
        function tableCellEdit(obj,hTable,evnt)
            
            % field retrieval
            iLvl = evnt.Indices(1);            
            Data = get(hTable,'Data');
            bgCol = get(hTable,'BackgroundColor');
            
            % determines if the scope is feasible
            if obj.hasData(iLvl)
                % if so, update the tables background colour
                obj.useScope(iLvl) = evnt.NewData;
                bgCol(iLvl,:) = 0.94 + 0.06*evnt.NewData;
                set(hTable,'BackgroundColor',bgCol);                                
                
                % updates the function filter
                obj.updateFuncFilter();  
                
                % updates the table fields based on what was selected
                if evnt.NewData                    
                    % resets the table data
                    [~,iSel] = obj.fTreeObj.getCurrentSelectedNodes();
                    Data{iLvl,2} = length(iSel{iLvl});
                    Data(iLvl,3:4) = {0};                    
            
                else
                    % case is the box is being unchecked
                    Data(iLvl,2:4) = {'N/A'};
                end                                            
                
                % determines if the new value is feasible
                setObjEnable(obj.hButC{1},any(cell2mat(Data(:,1))))
                
            else
                % otherwise, reset the field value
                Data{iLvl,1} = evnt.PreviousData;
            end
            
            % resets the table data
            set(hTable,'Data',Data);            
            
        end                
        
        % --- exit menu item callback function
        function menuExit(obj,~,~)
            
            % deletes the diagnostic window
            delete(obj.hFig)              
            
        end        
        
        % --------------------------------------- %
        % --- PROGRESS STRING SETUP FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- sets the base string for the progress log panel
        function bStr = setBaseString(obj,nTab,sCol)
            
            % sets up the tab string
            tStr = '';            
            if nTab > 0
                tStr0 = repmat(obj.tabStr,1,nTab);
                tStr = sprintf('%s%s ',tStr0,obj.arrStr);
            end
            
            % sets up the combined colour/tab string
            bStr = [obj.getColString(sCol),tStr];
            
        end        
        
        % --- retrieves the experiment count based on the scope type
        function nExpS = getExpCount(obj,iScope)
            
            switch iScope
                case 3
                    % case is the multi-expt functions
                    nExpS = 1;
                    
                otherwise
                    % case is the individual fly/single expt functions
                    nExpS = obj.nExp;
            end
            
        end
        
        % --- retrieves the plot data fields for given scope/experiment
        function pDataS = getPlotDataFields(obj,iScope,iExp)
            
            switch iScope
                case 3
                    % case is the multi-expt functions
                    pDataS = obj.pData{iScope};
                    
                otherwise
                    % case is the individual fly/single expt functions
                    pDataS = obj.pData{iScope}(:,iExp);
            end
                    
        end        
        
        % --- retrieves the solution data fields for given scope/experiment
        function snTotF = getSolnDataStruct(obj,iScope,iExp)
            
            switch iScope
                case 3
                    % case is the multi-expt functions
                    snTotF = obj.snTot;
                    
                otherwise
                    % case is the individual fly/single expt functions
                    snTotF = reduceSolnStruct(obj.snTot(iExp));
            end            
            
        end
        
        % --- appends the error data struct fields
        function appendErrorData(obj,ME,pDataF,iSF,isCalc,isErr)
            
            % updates the error log
            obj.errData{end+1} = ...
                FuncErrorLog(obj.fExpt,ME,pDataF,iSF,isCalc,isErr);        
            
            % updates the table
            iC = 3 + double(isErr);
            obj.hTableD.Data{iSF(2),iC} = obj.hTableD.Data{iSF(2),iC} + 1;
            
            if obj.isOldVer
                a = 1;
            else
                s = uistyle('BackgroundColor','r','FontWeight','Bold');
                addStyle(obj.hTableD,s,'cell',[iSF(2),iC])
            end
                                    
        end
        
        % --- outputs all the errors to screen
        function outputAllErrors(obj)
            
            % if there are no errors then exit
            if isempty(obj.errData)
                return
            end
            
            % outputs all the messages
            clc
            cellfun(@(x)(x.outputErrorDetails),obj.errData);
            
            
        end
                
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- updates function for the analysis function filter 
        function updateFuncFilter(obj)
            
            % updates the function compatibility
            set(0,'CurrentFigure',obj.hFig);            
            obj.fTreeObj.setupExplorerTree(obj.useScope);
            obj.updateTableData();
            
        end
            
        % --- retrieves the experiment data field
        function tFld = getInfoField(obj,hStrI)
            
            % retrieves the info field based on the type
            switch hStrI
                case 'Experiment Count'
                    % case is the experiment count
                    tFld = num2str(length(obj.snTot));
                    
                case 'Experiment Duration Type'
                    % case is the experiment duration
                    Ts = arrayfun(@(x)(x.T{1}(1)),obj.snTot);
                    Tf = arrayfun(@(x)(x.T{end}(length(x.T{end}))),obj.snTot);
                    isLong = any((Tf - Ts) > obj.tLong);                    
                    tFld = sprintf('%s Experiment',obj.tDurS{1+isLong});
                    
                case 'External Stimuli Type'
                    % case is the stimuli type
                    stimP = obj.snTot(1).stimP;
                    if isempty(stimP)
                        % no external stimuli
                        tFld = 'No External Stimuli';
                    else
                        % external stimuli, so strip out the stimuli types
                        stimType = strjoin(fieldnames(stimP)','/');
                        tFld = sprintf('%s External Stimuli',stimType);
                    end
                    
                case 'Setup Configuration'
                    % case is the setup configuration
                    iMov = obj.snTot(1).iMov;
                    if iMov.is2D
                        if isempty(iMov.autoP)
                            % case is no region shape was used
                            tFld = 'General 2D Region Setup';
                        else
                            % sets the region string
                            switch iMov.autoP.Type
                                case {'Circle','Rectangle'}
                                    tFldS = iMov.autoP.Type;
                                case 'GeneralR'
                                    tFldS = 'General Repeating';
                                case 'GeneralC'
                                    tFldS = 'General Custom';
                            end
                            
                            % sets the final string
                            tFld = sprintf('2D Grid (%s Regions)',tFldS);
                        end
                    else
                        % case is a 1D experimental setup
                        tFld = '1D Test-Tube Assay';
                    end                    
        
                case 'Experiment Names'
                    % case is the experiment names
                    tFld = arr2vec(getappdata(obj.hFigM,'sName'));
                    
            end
            
        end                        
        
        % --- updates the table data
        function updateTableData(obj)
            
            % memory allocation
            bgCol = 0.94*ones(obj.nRowD,3);
            bgCol(~obj.hasData,:) = 0.8;
            Data = repmat({'N/A'},obj.nRowD,obj.nColD);
            Data(:,1) = {false};
            
            % retrieves the currently selected functions
            [~,iSel] = obj.fTreeObj.getCurrentSelectedNodes();            
            
            % resets the table data
            xiS = 1:length(iSel);
            for i = find(~cellfun(@isempty,iSel) & obj.useScope(xiS))
                Data{i,1} = true;
                Data{i,2} = length(iSel{i});
                Data(i,3:4) = {0};
                bgCol(i,:) = 1;
            end
                
            % resets the table data
            set(obj.hTableD,'Data',Data,'BackgroundColor',bgCol);
            
        end
        
    end
    
    % static class methods
    methods (Static)
        
        % --- sets up the tree node string
        function nodeStr = getNodeString(fStr,fVal)
            
            switch fStr
                case 'Dur'
                    % case is the duration requirement
                    switch fVal
                        case 'Short'
                            % case is short expts only
                            nodeStr = 'Short Experiment Functions';
                            
                        case 'Long'
                            % case is long expts only
                            nodeStr = 'Long Experiment Functions';
                            
                        case 'None'
                            % case is duration independent
                            nodeStr = 'Duration Independent Functions';
                    end
                    
                case 'Shape'
                    % case is the experiment shape requirement
                    switch fVal
                        case '1D'
                            % case is 1D expts
                            nodeStr = 'General 1D Functions';
                            
                        case '2D'
                            % case is 2D expts
                            nodeStr = 'General 2D Functions';
                            
                        case '2D (Circle)'
                            % case is 2D Circle expts
                            nodeStr = '2D (Circle) Functions';
                            
                        case '2D (General)'
                            % case is 2D General shape expts
                            nodeStr = '2D (General) Functions';
                            
                        case 'None'
                            % case is shape independent
                            nodeStr = 'Shape Independent Functions';
                    end
                    
                case 'Stim'
                    % case is the duration requirement
                    switch fVal
                        case 'Motor'
                            % case is motor stimuli expts
                            nodeStr = 'Motor Stimuli Functions';
                            
                        case 'Opto'
                            % case is opto stimuli expts
                            nodeStr = 'Opto Stimuli Functions';
                            
                        case 'None'
                            % case is stimuli independent expts
                            nodeStr = 'Stimuli Independent Functions';
                    end
                    
                case 'Spec'
                    % case is special experiments
                    switch fVal
                        case 'MT'
                            % case is multi-tracking
                            nodeStr = 'Multi-Tracking';
                            
                        case 'None'
                            % case is duration independent
                            nodeStr = 'Non-Speciality Functions';
                    end
                    
            end
            
        end                    
        
        % --- sets the latex colour string (based on the value of sCol)
        function cStr = getColString(sCol)
            
            switch sCol(1)
                case 'w'
                    % case is black
                    cStr = '\color{white}';
                
                case 'k'
                    % case is black
                    cStr = '\color{black}';                    
                    
                case 'r'
                    % case is red
                    cStr = '\color[rgb]{0.75,0.0,0.0}';
                    
                case 'g'
                    % case is green
                    cStr = '\color[rgb]{0.0,0.75,0.0}';
            end
            
            if length(sCol) == 1
                cStr = [cStr,' \rm'];
            else
                switch sCol(2)
                    case 'b'
                        cStr = [cStr,' \bf'];
                end
            end
            
        end
        
        % --- sets up the scope string
        function sStr = getScopeString(fStr)
            
            % sets the base string
            switch fStr
                case 'Indiv'
                    % case is individual analysis
                    bStr = 'Individual Fly';
                    
                case 'Pop'
                    % case is single experiment
                    bStr = 'Single Experiment';
                    
                case 'Multi'
                    % case is multi-experiment
                    bStr = 'Multi-Experiment';
                
            end
            
            % sets the scope string
            sStr = sprintf(' * Analysing %s Functions',bStr);
            
        end        
        
        % --- sets up the experiment string
        function exStr = getExptString(fName)
            
            fName = strrep(fName,'_',' ');
            exStr = sprintf('Analysing Experiment: "%s"',fName);
            
        end
        
        % --- sets up the function name strings
        function pStrF = getFuncString(pNameF)
           
            pStrF = sprintf('Running "%s"...',pNameF);
            
        end
        
        function deleteProgBar()
            
            hProg = findall(0,'type','figure','tag','ProgBar');
            delete(hProg);
            
        end
                
    end
    
end
