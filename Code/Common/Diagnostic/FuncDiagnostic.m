classdef FuncDiagnostic < handle
    
    % class properties
    properties
        
        % main class fields
        hFigM
        pDataT
        snTot
        
        % sub-class objects
        ffObj
        fTreeObj
        
        % index/mapping arrays
        iCG
        indS
        indF        
        Imap
        ImapU
        sNode
        
        % class object handles fields
        hFig
        hTreeF
        hPanelO
        hPanelI
        hPanelF
        hPanelD
        hPanelP
        hPanelFcn
        hToggleFilt
        hPanelFilt  
        hTxtI
        hCheckGrp
        
        % fixed object dimensions        
        dX = 10;
        widPanelL = 400;
        widPanelR = 340;        
        widPanelFilt = 290; 
        hghtPanelO = 550;
        hghtPanelI = 140;
        hghtPanelP = 140;
        hghtPanelFilt = 180; 
        hghtEdit = 21;
        hghtBut = 25;
        hghtTxt = 16;    
        widTxtI = 155;
        
        % variable object dimensions
        widFig
        widPanelO
        widPanelFcn        
        hghtFig
        hghtPanelF
        hghtPanelD
        hghtPanelFcn         
                
        % other scalar/string fields
        hSz = 13;
        tSz = 12;
        gCol = (240/255)*[1 1 1];
        tagStr = 'figFuncDiagnostic';
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = FuncDiagnostic(hFigM,snTot,pDataT)
            
            % sets the input arguments
            obj.hFigM = hFigM;
            obj.snTot = snTot;
            obj.pDataT = pDataT;
            
            % initialises the class fields
            obj.initClassFields();
            obj.initObjProps();
            
        end
        
        % --------------------------------------- %
        % --- OBJECT INITIALISATION FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % calculates the panel dimensions
            obj.widPanelFcn = obj.widPanelL - 2*obj.dX;
            obj.widPanelO = (obj.widPanelL + obj.widPanelR) + 3*obj.dX;            
            obj.hghtPanelF = obj.hghtPanelO - (obj.hghtPanelI + 2*obj.dX);
            obj.hghtPanelD = obj.hghtPanelO - (obj.hghtPanelP + 2*obj.dX);
            obj.hghtPanelFcn = obj.hghtPanelF - 9*obj.dX;
            
            % calculates the figure dimensions
            obj.widFig = obj.widPanelO + 2*obj.dX;
            obj.hghtFig = obj.hghtPanelO + 2*obj.dX;
            
        end
        
        % --- initialises the class objects
        function initObjProps(obj)
            
            % deletes any previous GUIs
            hPrev = findall(0,'tag',obj.tagStr);
            if ~isempty(hPrev); delete(hPrev); end                       
            
            % --------------------------- %
            % --- MAIN FIGURE OBJECTS --- %
            % --------------------------- %
            
            % creates the figure object
            figName = 'Analysis Function Diagnostic';
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % creates the figure object
            obj.hFig = figure('Position',fPos,'tag',obj.tagStr,...
                              'MenuBar','None','Toolbar','None',...
                              'Name',figName,'Resize','off',...
                              'NumberTitle','off','Visible','off');
            
            % creates the experiment combining data panel
            pPos = [obj.dX*[1,1],obj.widPanelO,obj.hghtPanelO];
            obj.hPanelO = uipanel(obj.hFig,'Title','','Units',...
                                           'Pixels','Position',pPos);                        
            
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
            obj.hPanelF = uipanel(obj.hPanelO,'Title',tStrF,'Units',...
                        'Pixels','Position',pPosF,'FontUnits','Pixels',...
                        'FontSize',obj.hSz,'FontWeight','bold');

            % creates the experiment combining data panel
            pPosFcn = [obj.dX*[1,4],obj.widPanelFcn,obj.hghtPanelFcn];
            obj.hPanelFcn = uipanel(obj.hPanelF,'Title','','Units',...
                        'Pixels','Position',pPosFcn);   
                    
            % creates the sub-type grouping checkbox
            chkStr = 'Group Analysis Functions By Sub-Types';
            cPos = [obj.dX*[1,1],pPosFcn(3)-2*obj.dX,obj.hghtEdit];
            obj.hCheckGrp = uicontrol(obj.hPanelF,'Style','CheckBox',...
                'Units','Pixels','Position',cPos,'FontWeight','Bold',...
                'FontUnits','Pixels','FontSize',obj.tSz,'Value',1,...
                'Callback',@obj.checkFuncGroup,'String',chkStr);
                    
            % creates the toggle button
            lPosB = obj.dX + widTxtL;
            yPosB = sum(pPosFcn([2,4])) + 1;
            cbFcnB = @obj.toggleFilter;
            bPosB = [lPosB,yPosB,obj.widPanelFilt,obj.hghtBut];
            obj.hToggleFilt = uicontrol(obj.hPanelF,'Style',...
                        'ToggleButton','Position',bPosB,'FontUnits',...
                        'Pixels','FontWeight','Bold','FontSize',obj.tSz,...
                        'String',tStrB,'Tag','toggleFuncFilter',...
                        'Callback',cbFcnB);
                    
            % creates the experiment combining data panel
            yPosFilt = yPosB - (obj.hghtPanelFilt - 1);            
            szFilt = [obj.widPanelFilt-1,obj.hghtPanelFilt];
            pPosFilt = [lPosB+1,yPosFilt,szFilt];
            obj.hPanelFilt = uipanel(obj.hPanelF,'Title','','Units',...
                        'Pixels','Position',pPosFilt,'Visible','off',...
                        'Tag','panelFuncFilter');                        
                    
            % creates the text label
            yPosL = yPosB + (obj.dX/2 - 1);
            tPosL = [obj.dX,yPosL,widTxtL,obj.hghtTxt];
            uicontrol(obj.hPanelF,'Style','Text','Position',tPosL,...
                        'FontUnits','Pixels','FontWeight','Bold',...
                        'FontSize',obj.tSz,'String',tStrL,...
                        'HorizontalAlignment','right');            
            
            % creates the function filter tree object
            obj.ffObj = FuncFilterTree(obj.hFig,obj.snTot,obj.pDataT);
            set(obj.ffObj,'treeUpdateExtn',@obj.updateFuncFilter);
            
            % creates the diagnostic tree object
            obj.fTreeObj = FuncDiagnosticTree...
                (obj.ffObj,obj.hPanelFcn,obj.pDataT,obj.snTot);            
                        
            % ------------------------------------ %
            % --- EXPERIMENTAL DATA INFO PANEL --- %
            % ------------------------------------ %
            
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
                y0 = obj.dX*(1 + 2*j) + (obj.dX/2)*(i < nFld);
                
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
                set(hTxtL,'FontUnits','Pixels','FontWeight','Bold',...
                        'FontSize',obj.tSz,'String',hStrIF,...
                        'HorizontalAlignment','right')
                    
                % sets the information field
                tFld = obj.getInfoField(hStrI{i});
                set(obj.hTxtI{i},'String',tFld,'FontUnits','Pixels',...
                        'FontSize',obj.tSz,'HorizontalAlignment','Left');                    
                if (i == nFld) && (length(tFld) == 1)
                    % disables the popup menu (if only one expt)
                    setObjEnable(obj.hTxtI{i},0)
                end
            end
                    
            % -------------------------------- %
            % --- SOLUTION FILE DATA PANEL --- %
            % -------------------------------- %
            
            % panel object properties
            lPosP = obj.widPanelL + 2*obj.dX;            
            tStrP = 'DIAGNOSTIC ANALYSIS PROGRESS';            
            
            % creates the experiment combining data panel
            pPosP = [lPosP,obj.dX,obj.widPanelR,obj.hghtPanelP];
            obj.hPanelP = uipanel(obj.hPanelO,'Title',tStrP,'Units',...
                        'Pixels','Position',pPosP,'FontUnits','Pixels',...
                        'FontSize',obj.hSz,'FontWeight','bold');                    
            
            % -------------------------------- %
            % --- SOLUTION FILE DATA PANEL --- %
            % -------------------------------- %
            
            % panel object properties
            lPosP = obj.widPanelL + 2*obj.dX;            
            tStrP = 'DIAGNOSTIC ANALYSIS PARAMETERS';            
            
            % creates the experiment combining data panel
            yPosD = sum(pPosP([2,4])) + obj.dX/2;
            pPosD = [lPosP,yPosD,obj.widPanelR,obj.hghtPanelD];
            obj.hPanelD = uipanel(obj.hPanelO,'Title',tStrP,'Units',...
                        'Pixels','Position',pPosD,'FontUnits','Pixels',...
                        'FontSize',obj.hSz,'FontWeight','bold');                    
                    
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %                          
            
            % ensures the function filter is always on top
            uistack(obj.hPanelFilt,'top')            
            
            % centers the figure and makes it visible
            centreFigPosition(obj.hFig,2);
            setObjVisibility(obj.hFig,1);                          
                          
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
                        pObj(2) = pObj(2) + 1;
                        [pStr,pObj(4)] = deal('Text',obj.hghtTxt);
                        
                    case 'C'
                        % case is a checkbox
                        [pStr,pObj(4)] = deal('CheckBox',obj.hghtEdit);
                        
                    case 'P'
                        % case is a checkbox
                        [pStr,pObj(4)] = deal('PopupMenu',obj.hghtEdit);                        
                        
                    case 'B'
                        % case is a pushbutton
                        [pStr,pObj(4)] = deal('PushButton',obj.hghtBut);
                        
                    case 'E'
                        % case is an editbox
                        [pStr,pObj(4)] = deal('Edit',obj.hghtEdit);                        
                end
                
                % creates the object
                hObj{i} = uicontrol...
                    (hP,'Units','Pixels','Style',pStr,'Position',pObj);
            end
            
            % sets the left/right objects
            [hObjL,hObjR] = deal(hObj{1},hObj{2});
            
        end
            
        % --- retrieves the experiment data field
        function tFld = getInfoField(obj,hStrI)
           
            % REMOVE ME
            tFld = 'Finish Me!';
            
            % retrieves the info field based on the type
            switch hStrI
                case 'Experiment Count'
                    % case is the experiment count
                    tFld = num2str(length(obj.snTot));
                    
                case 'Experiment Duration Type'
                    
                case 'External Stimuli Type'
                    
                case 'Setup Configuration'
        
                case 'Experiment Names'
                    % case is the experiment names
                    tFld = arr2vec(getappdata(obj.hFigM,'sName'));
                    
            end
            
        end
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %
        
        % --- the function filter toggle button
        function toggleFilter(obj, hObj, ~)
            
            % object handles
            isOpen = get(hObj,'Value');

            % updates the funcion filter panel visibility
            setObjVisibility(obj.hPanelFilt,isOpen);

            % updates the toggle button string
            if isOpen
                set(hObj,'String','Close Analysis Function Filter')
            else
                set(hObj,'String','Open Analysis Function Filter')
            end            
            
        end
        
        % --- 
        function checkFuncGroup(obj, hObj, ~)
            
            obj.fTreeObj.useSubGrp = get(hObj,'Value');
            obj.updateFuncFilter();            
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- updates function for the analysis function filter 
        function updateFuncFilter(obj)
            
            % updates the function compatibility
            set(0,'CurrentFigure',obj.hFig);            
            obj.fTreeObj.setupExplorerTree();
            
        end
            
        % --- closes the window
        function close(obj)
            
            delete(obj.hFig)
            
        end
        
    end
    
    %
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
            
    end
    
end