classdef ProgDefaultDef < handle
    
    % class properties
    properties
        
        % main object handles        
        hFig 
        hFigM
        dType        
        ProgDef                  
        
        % data I/O folder objects
        nIO
        wStrIO
        hPanelIO
        hEditIO
        hButIO
        
        % program data folder objects
        nPr
        wStrPr
        hPanelPr
        hEditPr
        hButPr
        
        % control button objects
        hPanelC
        hButC        
        
        % fixed object dimensions
        dX = 10;
        dXH = 5;
        dhOfs = 30;
        widFig = 620;
        widButC = 100;
        widPanelC = 340;
        widEdit = 520;
        hghtBut = 25;
        hghtPanel = 60;
        hghtEdit = 22;
        hghtPanelC = 40;
        pSz = 13;
        tSz = 12;
        dSz = 10.667;
        isMain = false;
        
        % variable object dimensions
        hghtFig
        widPanel
        widPanelO
        hghtPanelIO
        hghtPanelPr
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = ProgDefaultDef(hFigM,dType,defDir0)
            
            % sets the default input argument
            if exist('defDir0','var')
                obj.ProgDef = defDir0;
                obj.isMain = true; 
            end
            
            % sets the input arguments
            obj.hFigM = hFigM;
            obj.dType = dType;
            
            % creates the class fields/object properties
            obj.initClassFields();
            obj.initObjProps();
            
            % centres the figure and makes it visible
            centreFigPosition(obj.hFig);
            setObjVisibility(obj.hFig,1);
            
            % if running from the main GUI, force a halt on the figure
            if obj.isMain
                uiwait(obj.hFig);
            end
            
        end
        
        % --------------------------------- %
        % --- INITIALISATIONS FUNCTIONS --- %
        % --------------------------------- %        
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % initialisations
            nGap = 2;

            % retrieves the default directory field strings
            [obj.wStrIO,obj.wStrPr] = obj.getDirFieldStrings();
            [obj.nIO,obj.nPr] = deal(size(obj.wStrIO,1),size(obj.wStrPr,1));            

            % updates the default directory
            if ~obj.isMain
                switch obj.dType
                    case 'Analysis'
                        % case is the analysis default directories
                        iData = getappdata(obj.hFigM,'iData');
                        obj.ProgDef = iData.ProgDef;                

                    case {'Combine','Recording'}
                        % case is the recording/combining default directories
                        obj.ProgDef = getappdata(obj.hFigM,'iProg');                    

                    case 'DART'
                        % case is the main program default directories
                        mObj = getappdata(obj.hFigM,'mObj');
                        obj.ProgDef = mObj.getProgDefField('DART');

                    case 'Tracking'
                        % case is the tracking default directories
                        obj.ProgDef = obj.hFigM.iData.ProgDef;

                end            
            end
            
            % calculates the height of the data I/O default panel
            if obj.nIO > 0
                nGap = nGap + 1;
                obj.hghtPanelIO = obj.nIO*(obj.hghtPanel + obj.dXH) + ...
                                  obj.dhOfs;
            else
                obj.hghtPanelIO = 0;
            end
            
            % calculates the height of the program default panel
            if obj.nPr > 0
                nGap = nGap + 1;
                obj.hghtPanelPr = obj.nPr*(obj.hghtPanel + obj.dXH) + ...
                                  obj.dhOfs;
            else
                obj.hghtPanelPr = 0;
            end
            
            % calculates the height of the figure
            obj.hghtFig = obj.hghtPanelIO + obj.hghtPanelPr + ...
                          obj.hghtPanelC + nGap*obj.dX;                        
            
            % calculates the outer/inner panel widths
            obj.widPanelO = obj.widFig - 2*obj.dX;
            obj.widPanel = obj.widPanelO - 2*obj.dX;
            
        end
        
        % --- initialises the class object properties
        function initObjProps(obj)
            
            % deletes any previous default directory GUIs
            hPrev = findall(0,'tag','figProgDef');
            if ~isempty(hPrev); delete(hPrev); end            
            
            % --------------------------- %
            % --- MAIN FIGURE OBJECTS --- %
            % --------------------------- %
            
            % creates the figure object
            fPos = [100,100,obj.widFig,obj.hghtFig];
            fName = sprintf('%s GUI Default Directories',obj.dType);            
            
            % creates the figure object
            obj.hFig = figure('Position',fPos,'tag','figProgDef',...
                              'MenuBar','None','Toolbar','None',...
                              'Name',fName,'NumberTitle','off',...
                              'Visible','off','Resize','off',...
                              'CloseRequestFcn',{@obj.buttonCancel},...
                              'WindowStyle','modal'); 
            
            % creates the control button panel            
            x0 = obj.widFig - (obj.dX + obj.widPanelC);
            pPosC = [x0,obj.dX,obj.widPanelC,obj.hghtPanelC]; 
            
            % creates the panel object
            obj.hPanelC = uipanel(obj.hFig,'Title','','Units',...
                                           'Pixels','Position',pPosC);            
               
            % creates the program default directory panel
            pPosPr = pPosC;
            if obj.nPr > 0          
                % sets up the panel object properties
                y0Pr = sum(pPosC([2,4])) + obj.dX;
                tStr = 'PROGRAM DATA FILE DIRECTORIES';
                pPosPr = [obj.dX,y0Pr,obj.widPanelO,obj.hghtPanelPr];
                
                % creates the panel object
                obj.hPanelPr = uipanel(obj.hFig,'Title',tStr,'Units',...
                               'Pixels','Position',pPosPr,'FontWeight',...
                               'Bold','FontUnits','Pixels',...
                               'FontSize',obj.pSz);
            end                        
            
            % creates the data I/O default directory panel
            if obj.nIO > 0                
                % sets up the panel object properties
                y0IO = sum(pPosPr([2,4])) + obj.dX;
                tStr = 'INPUT/OUTPUT DATA FILE DIRECTORIES';
                pPosIO = [obj.dX,y0IO,obj.widPanelO,obj.hghtPanelIO];
                
                % creates the panel object                
                obj.hPanelIO = uipanel(obj.hFig,'Title',tStr,'Units',...
                               'Pixels','Position',pPosIO,'FontWeight',...
                               'Bold','FontUnits','Pixels',...
                               'FontSize',obj.pSz);
            end            
            
            % --------------------------------- %
            % --- DEFAULT DIRECTORY OBJECTS --- %
            % --------------------------------- %            
            
            % creates the I/O and program default directory panels
            arrayfun(@(x)(obj.createDefDirPanel(1,x)),1:obj.nIO)
            arrayfun(@(x)(obj.createDefDirPanel(2,x)),1:obj.nPr)
            
            % ------------------------------ %
            % --- CONTROL BUTTON OBJECTS --- %
            % ------------------------------ %
            
            % sets the control button strings/tag strings
            bStrC = {'Reset Default','Update','Cancel'};
            bFcn = {@obj.buttonReset,@obj.buttonUpdate,@obj.buttonCancel};
            
            % creates the control button objects
            for i = 1:length(bStrC)
                % sets the button properties
                x0 = obj.dX + (i-1)*(obj.widButC + obj.dX);
                bPos = [x0,obj.dX-2,obj.widButC,obj.hghtBut];
                
                % creates the button objects
                obj.hButC{i} = uicontrol(obj.hPanelC,'Position',bPos,...
                                'Callback',bFcn{i},'String',bStrC{i},...
                                'FontWeight','Bold','FontUnits','Pixels',...
                                'FontSize',obj.tSz);
                setObjEnable(obj.hButC{i},i==3);
            end
                
        end        
        
        % --- creates the default directory panel
        function createDefDirPanel(obj,iType,iDir)
            
            % creates the panel object
            switch iType
                case 1
                    % case is the I/O data directories
                    wStr = obj.wStrIO(iDir,:);
                    hParent = obj.hPanelIO;                    
                    
                case 2
                    % case is the program data directories
                    wStr = obj.wStrPr(iDir,:);
                    hParent = obj.hPanelPr;
                    
            end
            
            % calculates the vertical location of the panel
            pPosO = get(hParent,'Position');
            yPosP = (pPosO(4) + obj.dX) - ...
                    (iDir*(obj.dXH+obj.hghtPanel) + obj.dhOfs);
            
            % creates the outer panel object     
            tagStr = sprintf('panel%s',wStr{1});
            pStr = sprintf('%s DIRECTORIES',wStr{2});            
            pPos = [obj.dX,yPosP,obj.widPanel,obj.hghtPanel];
            hP = uipanel(hParent,'Title',pStr,'Units','Pixels',...
                            'Position',pPos,'FontWeight','Bold',...
                            'FontUnit','Pixels','FontSize',obj.tSz,...
                            'tag',tagStr);
            
            % creates the editbox object
            dirName = getStructField(obj.ProgDef,wStr{1});
            ePos = [3*obj.dXH,obj.dX,obj.widEdit,obj.hghtEdit];
            uicontrol(hP,'Style','Edit','UserData',wStr{1},...
                         'Position',ePos,'FontUnits','Pixels',...
                         'FontSize',obj.dSz,'Enable','Inactive',...
                         'HorizontalAlignment','left',...
                         'String',['  ',dirName],'tag',wStr{1});

            % creates the editbox object
            bFcn = {@obj.setDefDir};
            bPos = [sum(ePos([1,3]))+obj.dX,obj.dX,obj.hghtBut*[1,1]];
            uicontrol(hP,'Style','PushButton','UserData',wStr{1},...
                         'Position',bPos,'FontUnits','Pixels',...
                         'FontSize',obj.tSz,'String','...',...
                         'FontWeight','Bold','Callback',bFcn);                             
                             
        end
        
        % ----------------------------------------- %
        % --- CONTROL BUTTON CALLBACK FUNCTIONS --- %
        % ----------------------------------------- %
        
        % --- Executes on button press in buttonReset.
        function buttonReset(obj,~,~)
            
            % case is running from the main DART GUI (update is done
            % within main GUI itself)
            if obj.isMain
                obj.buttonUpdate()
                return
            end
            
            % determines if the program defaults have been set
            pFile = getParaFileName('ProgDef.mat');
            objH = getappdata(findall(0,'tag','figDART'),'mObj');
            
            % updates the main gui button userdata properties
            if ~strcmp(obj.dType,'DART')
                hButD = findall(objH.hFig,'Style','PushButton');
                tStr = arrayfun(@(x)(get(x,'tag')),hButD,'un',0);
                isB = strContains(tStr,obj.dType(1:(end-3)));
                set(hButD(isB),'UserData',obj.ProgDef);
            end
            
            % updates the default directory defaults file
            ProgDef0 = objH.getDefaultDirStruct(); 
            ProgDef0 = setStructField(ProgDef0,obj.dType,obj.ProgDef);
            objH.setDefaultDirStruct(ProgDef0);
            
            % re-saves the program default data struct file 
            ProgDef = ProgDef0;
            save(pFile,'ProgDef')
            
            % updates and closes the GUI
            obj.buttonUpdate();
            
        end
        
        % - -- Executes on button press in buttonUpdate.
        function buttonUpdate(obj,~,~)
            
            % updates the default directory
            if ~obj.isMain
                switch obj.dType
                    case 'Analysis'
                        % case is the analysis default directories
                        iData = getappdata(obj.hFigM,'iData');
                        iData.ProgDef = obj.ProgDef;
                        setappdata(obj.hFigM,'iData',iData)
                        setappdata(obj.hFigM,'iProg',obj.ProgDef)

                    case {'Recording','Combine'}
                        % case is recording/combining default directories
                        setappdata(obj.hFigM,'iProg',obj.ProgDef);                    

                    case 'DART'
                        % case is the main program default directories
                        PD = getappdata(obj.hFigM,'ProgDef');
                        PD.DART = obj.ProgDef;
                        setappdata(obj.hFigM,'ProgDef',PD)

                    case 'Tracking'
                        % case is the tracking default directories
                        obj.hFigM.iData.ProgDef = obj.ProgDef;                    

                end
            end

            % closes the figure
            delete(obj.hFig)            
            
        end
        
        % --- Executes on button press in buttonCancel.
        function buttonCancel(obj,~,~)

            % closes the figure
            delete(obj.hFig)            
            
        end
        
        % -------------------------------- %
        % --- OTHER CALLBACK FUNCTIONS --- %
        % -------------------------------- %        
        
        % --- callback function for the default directory setting buttons
        function setDefDir(obj,hObject,~)
            
            % retrieves the default directory corresponding to the current object
            wStr = get(hObject,'UserData');
            dDir = getStructField(obj.ProgDef,wStr);
            
            % prompts the user for the new default directory
            dirName = uigetdir(dDir,'Set The Default Path');
            if dirName
                % updates the default directory path
                obj.ProgDef = setStructField(obj.ProgDef,wStr,dirName);                

                % updates the field string and associated object properties
                hEdit = findobj(obj.hFig,'tag',wStr,'Style','Edit');                
                set(hEdit,'string',['  ',dirName])
                obj.setOtherButtons();
            end
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- sets the enabled properties of the update/reset buttons
        function setOtherButtons(obj)
            
            % determines
            pFld = fieldnames(obj.ProgDef);
            allSet = all(cellfun(@(x)(~isempty...
                                (getStructField(obj.ProgDef,x))),pFld));
            
            % sets the enabled properties depending if all the directories have been
            % set correctly
            cellfun(@(x)(setObjEnable(x,allSet)),obj.hButC(1:2))
                            
        end

        % --- retrieves the directory field string array
        function [wStrIO,wStrPr] = getDirFieldStrings(obj)
        
            % initialisations
            [wStrIO,wStrPr] = deal([]);
            
            % sets the field string based on the program component
            switch obj.dType
                case 'DART'
                    % case is the main gui
                    wStrPr = {'DirVer','PROGRAM VERSIONS'};
                    
                case 'Analysis'
                    % case is the analysis gui
                    wStrIO = {'DirSoln','VIDEO SOLUTION FILE';...
                              'DirComb','EXPERIMENT SOLUTION FILE';...
                              'OutFig','ANALYSIS FIGURES OUTPUT';...
                              'OutData','ANALYSIS DATA OUTPUT'};
                    wStrPr = {'DirFunc','ANALYSIS FUNCTION FILE';...
                              'TempFile','TEMPORARY DATA FILE';...
                              'TempData','TEMPORARY CALCULATED DATA'};
                    
                case 'Combine'
                    % case is the data combining gui
                    wStrIO = {'DirSoln','VIDEO SOLUTION FILE';...
                              'DirComb','EXPERIMENT SOLUTION FILE'};
                    wStrPr = {'TempFile','TEMPORARY DATA FILE'};
       
                case 'Recording'
                    % case is the recording gui
                    wStrIO = {'DirMov','RECORDED VIDEO FILE'};
                    wStrPr = {'StimPlot','VIDEO CAMERA PRESETS';...
                              'DirPlay','STIMULI PLAYLIST FILES';...
                              'CamPara','STIMULI  TRAIN TRACE'};
                    
                case 'Tracking'                    
                    % case is the fly tracking gui
                    wStrIO = {'DirMov','RECORDED VIDEO FILE';...
                              'DirSoln','VIDEO SOLUTION FILE'};
                    wStrPr = {'TempFile','TEMPORARY IMAGE STACK'};
                    
            end
        end        
        
    end   
    
end
