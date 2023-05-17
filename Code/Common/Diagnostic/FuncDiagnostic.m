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
        hghtPanelI = 130;
        hghtPanelP = 140;
        hghtPanelFilt = 180; 
        hghtEdit = 21;
        hghtBut = 21;
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
        hSz = 12;
        tSz = 10;
        tLong = 12;
        tDurS = {'Short','Long'};
        tagStr = 'figFuncDiagnostic';
        isOldVer = verLessThan('matlab','9.10');
        
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
            obj.hghtPanelFcn = obj.hghtPanelF - 8*obj.dX;
            
            % calculates the figure dimensions
            obj.widFig = obj.widPanelO + 2*obj.dX;
            obj.hghtFig = obj.hghtPanelO + 2*obj.dX;
            
            % resets the font sizes (old version only)
            if obj.isOldVer
                obj.hSz = 13;
                obj.tSz = 12;
            end
            
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
            obj.hFig = createUIObj('figure','Position',fPos,...
                'tag',obj.tagStr,'MenuBar','None','Toolbar','None',...
                'Name',figName,'Resize','off','NumberTitle','off',...
                'Visible','off');
            
            % creates the experiment combining data panel
            pPos = [obj.dX*[1,1],obj.widPanelO,obj.hghtPanelO];
            if ~obj.isOldVer; pPos(2) = 150; end
            obj.hPanelO = createUIObj...
                ('panel',obj.hFig,'Title','','Position',pPos);
            
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
                'FontSize',obj.tSz,'Value',1);
                    
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
                    setObjEnable(obj.hTxtI{i},length(tFld) > 1)
                    
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
            
%             % ensures the function filter is always on top
%             uistack(obj.hPanelFilt,'top')            
            
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
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %
        
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
            
    end
    
end