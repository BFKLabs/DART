classdef ExptTabInfo < ExptTab
    
    % class properties
    properties
        
        % experiment info panel objects
        hPanelI
        hTxtI
        hObjI
        hButI
        
        % start time panel objects
        hPanelS
        hPopupS
        hTxtS
        hCheckS
        
        % experiment duration panel objects
        hPanelD
        hPopupD        
        
        % video recording parameter panel objects
        hPanelR
        hPopupRF
        hEditRF
        hSliderRF
        hPopupRD
        hPopupRC

        % video resolution panel objects
        hPanelV
        hPopupV
        hObjV  
        hTxtV
        
        % frame count panel objects
        hPanelF
        hTxtF
        hTxtFL
        hTxtFB
        hButF
        
        % experimental summary panel objects
        hPanelE
        hCheckE
        hTxtE
        
        % other important class fields
        hTimerS        
        
        % fixed object dimensions
        widPanelI = 500;
        widTxtI = 140;
        widPopupS = [90,55,55,55,60];
        widTxtSS = [170,110];
        widPopupD = 83;
        widTxtRL = 145;
        widTxtRR = 100;
        widPopupRD = 50;
        widPopupRC = 150;
        widPopupV = 150;
        widTxtV = [60,50,50];
        widTxtF = [170,80];        
        widCheckE = 250;
        widTxtEL = 155;
                        
        % calculated panel dimensions   
        widPanelRI
        hghtPanelI
        hghtPanelS
        hghtPanelD
        hghtPanelR
        hghtPanelV
        hghtPanelF
        hghtPanelE        
        
        % other calculated object dimensions
        widEditI
        widTxtSL
        widCheckS
        widTxtD
        widObjR
        widObjV
        widTxtFB
        widButF
        widTxtE
        
        % boolean class fields
        hasVid                        
        
        % numerical index/flag class fields
        t2sStatus = -1;
        
        % static numerical class fields
        nObjD = 4;
        nTxtE = 2;
        nChkE = 6;
        
        % numerical parameter fields
        fpsMax = 200;
        fgCol = {ones(1,3),zeros(1,3)};
        bgCol = {(128/255)*ones(1,3),0.94*ones(1,3)};
        
        % fixed string class fields
        uCol = 'rk';
        tagTimerS = 'hTimerStart';
        
    end
        
    % class methods
    methods
        
        % --- class constructor
        function obj = ExptTabInfo(objB,hTab)
            
            % creates the super-class object
            obj@ExptTab(objB,hTab,1);  
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initClassObjects();
            start(obj.hTimer);          
            
        end

        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % deletes any previous timers
            obj.tagStr = 'hTimerInfoTab';
            obj.clearPrevTimers(obj.tagStr);
            
            % timer object
            obj.hTimer = timer(...
                'StartDelay',0.2,...
                'TimerFcn',@obj.initObjectProps,...
                'Tag',obj.tagStr);              
            
            % creates the experiment start timer
            obj.initExptStartTimer();            
            
            % ------------------------------------------- %
            % --- CLASS OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------------- %            
            
            % calculated sub-panel dimensions
            obj.hghtPanelV = obj.hghtGrp + obj.dX + obj.hghtRow;
            obj.hghtPanelF = obj.hghtRow + obj.dX;            
            
            % calculated panel dimensions        
            obj.widPanelRI = obj.widPanelI - obj.dX;
            obj.hghtPanelI = obj.hghtGrp + obj.dX + 4*obj.hghtRow;
            obj.hghtPanelS = obj.hghtGrp + obj.dX/2 + 3*obj.hghtRow;
            obj.hghtPanelD = obj.hghtGrp + 2*obj.hghtRow;
            obj.hghtPanelR = obj.hghtGrp + 1.5*obj.dX + ...
                obj.hghtPanelV + obj.hghtPanelF + 3*obj.hghtRow;
            obj.hghtPanelE = obj.hghtGrp + 4*obj.hghtRow; 

            % other calculated object dimensions
            obj.widEditI = obj.widPanelI - ...
                (2.5*obj.dX + obj.widTxtI + obj.hghtBut);
            obj.widTxtSL = obj.widPanelI - (sum(obj.widPopupS) + ...
                (3 + length(obj.widPopupS))*obj.dX/2);
            obj.widCheckS = obj.widPanelI - ...
                (sum(obj.widTxtSS) + 2.5*obj.dX);
            obj.widTxtD = obj.widPanelI - (3.5*obj.dX + 4*obj.widPopupD);
            obj.widObjR = obj.widPanelI - (3*obj.dX + ...
                obj.widTxtRL + obj.widTxtRR + 3*obj.widPopupRD);
            obj.widObjV = (obj.widPanelRI - ...
                (obj.widPopupV + sum(obj.widTxtV) + 2.5*obj.dX))/3;
            obj.widTxtFB = sum(obj.widTxtF) + 2*obj.dX;
            obj.widButF = obj.widPanelRI - (obj.widTxtFB + 2*obj.dX);
            obj.widTxtE = (obj.widPanelI - (2*obj.widTxtEL + 3*obj.dX))/2;
            
        end
        
        % --- initialises the class objects
        function initClassObjects(obj)

            % -------------------------------- %
            % --- EXPERIMENT SUMMARY PANEL --- %
            % -------------------------------- %
            
            % field initialisations
            tStrE = 'EXPERIMENT SUMMARY';
            
            % creates the outer panel object
            pPosE = [obj.dX*[1,1]/2,obj.widPanelI,obj.hghtPanelE];
            obj.hPanelE = obj.setupHeadedPanel(obj.hPanelO,pPosE,tStrE);
            
            % initialises the experiment summary panel objects
            obj.setupExptSummaryPanel()

            % --------------------------------------- %
            % --- VIDEO RECORDING PARAMETER PANEL --- %
            % --------------------------------------- %
            
            % field initialisations
            tStrR = 'VIDEO RECORDING PARAMETERS';
            tStrV = 'OUTPUT VIDEO RESOLUTION';
            
            % sets up the sub-panel position vectors
            pPosF = [obj.dX*[1,1]/2,obj.widPanelRI,obj.hghtPanelF];            
            yPosV = sum(pPosF([2,4])) + obj.dX/2;
            pPosV = [obj.dX/2,yPosV,obj.widPanelRI,obj.hghtPanelV];            
            
            % creates the outer panel object
            yPosR = sum(pPosE([2,4])) + obj.dX/2;
            pPosR = [obj.dX/2,yPosR,obj.widPanelI,obj.hghtPanelR];
            obj.hPanelR = obj.setupHeadedPanel(obj.hPanelO,pPosR,tStrR);
                        
            % ------------------------------------------ %
            % --- VIDEO PLACEMENT OPTIMISATION PANEL --- %
            % ------------------------------------------ %
            
            % frame count panel
            obj.hPanelF = obj.setupHeadlessPanel(obj.hPanelR,pPosF);
            
            % initialises the video placement optimisation panel objects
            obj.setupVideoOptPanel()
            
            % ------------------------------ %
            % --- VIDEO RESOLUTION PANEL --- %
            % ------------------------------ %
            
            % video resolution panel
            obj.hPanelV = obj.setupHeadedPanel(obj.hPanelR,pPosV,tStrV);
            
            % creates video resolution/parameter panel objects
            obj.setupVideoResPanel()            
            obj.setupVideoParaPanel()            
                        
            % --------------------------------- %
            % --- EXPERIMENT DURATION PANEL --- %
            % --------------------------------- %
            
            % field initialisations
            tStrD = 'EXPERIMENT DURATION';
            
            % creates the outer panel object
            yPosD = sum(pPosR([2,4])) + obj.dX/2;
            pPosD = [obj.dX/2,yPosD,obj.widPanelI,obj.hghtPanelD];
            obj.hPanelD = obj.setupHeadedPanel(obj.hPanelO,pPosD,tStrD);

            % initialises the experiment duration panel objects
            obj.setupExptDurPanel()            
            
            % ----------------------------------- %
            % --- EXPERIMENT START TIME PANEL --- %
            % ----------------------------------- %
            
            % field initialisations
            tStrS = 'EXPERIMENT START TIME';
            
            % creates the outer panel object
            yPosS = sum(pPosD([2,4])) + obj.dX/2;
            pPosS = [obj.dX/2,yPosS,obj.widPanelI,obj.hghtPanelS];
            obj.hPanelS = obj.setupHeadedPanel(obj.hPanelO,pPosS,tStrS);
            
            % initialises the experiment start time panel objects
            obj.setupExptStartPanel()
            
            % ------------------------------------ %
            % --- EXPERIMENT INFORMATION PANEL --- %
            % ------------------------------------ %
            
            % field initialisations
            tStrI = 'EXPERIMENT INFORMATION';
            
            % creates the outer panel object
            yPosI = sum(pPosS([2,4])) + obj.dX/2;
            pPosI = [obj.dX/2,yPosI,obj.widPanelI,obj.hghtPanelI];
            obj.hPanelI = obj.setupHeadedPanel(obj.hPanelO,pPosI,tStrI);
            
            % initialises the experiment information panel objects
            obj.setupExptInfoPanel()            
            
            % sets the object callback functions
            obj.setObjectCallbacks()            
            
        end        
        
        % --- initialises the experiment start timer
        function initExptStartTimer(obj)
            
            % deletes previous timers
            obj.clearPrevTimers(obj.tagTimerS);
            
            % creates the timer object
            obj.hTimerS = timer('Period',1,'TasksToExecute',inf,...
                'ExecutionMode','FixedRate','Tag',obj.tagTimerS,...
                'StartDelay',0.1,'TimerFcn',@obj.timeToStart);                        
            
        end         

        % --- initialises the object properties
        function initObjectProps(obj,varargin)
                    
            % field initialisations
            hasStim = ~strcmp(obj.iExpt.Info.Type,'RecordOnly');
            
            % if recording only, disable the stimuli-dependent checkboxes
            cellfun(@(x)(setObjEnable(x,hasStim)),obj.hCheckE(5:6));
            
            % ------------------------------------ %
            % --- EXPERIMENT INFORMATION PANEL --- %
            % ------------------------------------ %            
            
            % initialises the experiment information fields
            obj.initExptInfoFields()
            
            % ----------------------------------- %
            % --- EXPERIMENT START TIME PANEL --- %
            % ----------------------------------- %
            
            % initialises the start time popupmenu values
            obj.setStartTimeValues(obj.hPopupS);                        
            
            % if loading/restarting then reset the checkbox value
            if obj.isInit
                obj.hCheckS.Value = obj.iExpt.Timing.fixedT0;
                obj.checkFixStart();
            end
            
            % --------------------------------- %
            % --- EXPERIMENT DURATION PANEL --- %
            % --------------------------------- %
            
            % setsthe experiment duration popupmenu values
            obj.setDurTimeValues(obj.hPopupD,obj.iExpt.Timing.Texp);
            
            % performs the minimum expt duration check
            if obj.isInit
                % case is the dialog window has been initialise
                obj.minExptDurCheck()
                
            else
                % otherwise, automatically set the flag to true
                obj.setFeasFlag('ExptDur',true,false);                
            end
            
            % ------------------------------------------ %
            % --- VIDEO PLACEMENT OPTIMISATION PANEL --- %
            % ------------------------------------------ %
            
            % if a stimuli only experiment, then disable recording panel
            setPanelProps(obj.hPanelR,~obj.isStimOnly)            
            
            % ------------------------------ %
            % --- VIDEO RESOLUTION PANEL --- %
            % ------------------------------ %
                        
            if obj.infoObj.hasIMAQ
                % if recording experiment, update the popupmenu
                obj.popupCustRes();                
            else
                % if a stimuli only expt, then disable the panel
                setPanelProps(obj.hPanelV,'off')
            end
                                  
            % --------------------------------------- %
            % --- VIDEO RECORDING PARAMETER PANEL --- %
            % --------------------------------------- %
            
            % initialises the video parameter fields            
            obj.initVideoParaFields();            
            
            % -------------------------------- %
            % --- EXPERIMENT SUMMARY PANEL --- %
            % -------------------------------- %                                    
            
            % if recording only, disable the stimuli-dependent checkboxes
            if obj.isStimOnly
                setObjEnable(obj.hCheckE{4},0);
                cellfun(@(x)(set(x,'String','N/A')),obj.hTxtE);
                setObjEnable(findall(obj.hPanelE,'Style','Text'),'off');
            else
                obj.setFeasFlag('RecordPara',true,false)
            end    
            
            %
            if hasStim
                anyStim = ~isempty(obj.sTrainP.S) || ...
                          ~isempty(obj.sTrainP.L);
                obj.setFeasFlag('StimProto',anyStim,false)
                obj.setFeasFlag('AllStimProto',~isempty(obj.sTrainP.Ex))
            end
        
            % updates the experiment feasibility flags
            if obj.isInit            
                obj.checkExptFeas()            
            end
            
            % retrieves the table group java object
            if isempty(obj.jTabGrpS)
                % retrieves the tab group java handle
                obj.jTabGrpS = getTabGroupJavaObj(obj.objB.hTabGrpS);
                
                % disables the experimental protocol tab panel
                if length(obj.objB.hTabS) == 4
                    obj.jTabGrpS.setEnabledAt(3,0);
                end     
                
                % deletes the loadbar
                delete(obj.hProg);
                
                % centres the figure and makes it visible
                centerfig(obj.hFig);
                setObjVisibility(obj.hFig,1);
            end            
            
            % ------------------------------- %            
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            if ~obj.isInit
                % starts the timer           
                start(obj.hTimerS);

                % flag that the tab has been initialised
                deleteTimerObjects(obj.hTimer);
                obj.isInit = true;
            end
            
        end
        
        % --------------------------------------- %
        % --- PANEL OBJECT CREATION FUNCTIONS --- %
        % --------------------------------------- %

        % --- initialises the experiment information panel objects
        function setupExptInfoPanel(obj)
            
            % field initialisations
            tStrI = {'Protocol Filename','Base Output Directory',...
                     'Experiment Title','Base Video Filename'};
            
            % memory allocation
            nObjI = length(tStrI);
            [obj.hObjI,obj.hTxtI] = deal(cell(nObjI,1));
            
            % creates the experiment information object fields
            [wObjI,yOfsI] = deal([obj.widTxtI,obj.widEditI],obj.dX);
            for i = 1:nObjI
                % global row index
                j = nObjI - (i-1);
                
                % creates the text label/editbox groups
                if strcmp(tStrI{j},'Protocol Filename')
                    % case is the text label field
                    [obj.hObjI{j},obj.hTxtI{j}] = ...
                        obj.setupTxtLabelGroup(obj.hPanelI,...
                        [obj.dX,yOfsI+3],tStrI{j},wObjI,1);
                    
                else
                    % case is the editbox fields
                    [obj.hObjI{j},obj.hTxtI{j}] = obj.setupEditGroup(...
                        obj.hPanelI,[obj.dX,yOfsI],tStrI{j},wObjI,1);
                    
                    % if the output directory, then create the pushbutton
                    if strcmp(tStrI{j},'Base Output Directory')
                        xPosB = sum(obj.hObjI{j}.Position([1,3]))+obj.dX/2;
                        pPosB = [xPosB,yOfsI,obj.hghtBut*[1,1]];
                        obj.hButI = ...
                            obj.setupPushButton(obj.hPanelI,pPosB,'...');
                        obj.hButI.FontSize = 1.5*obj.fSz;
                    end
                    
                    % increments the vertical offset
                    yOfsI = yOfsI + obj.hghtRow;
                end                                
            end
            
            % sets the other object properties
            obj.hObjI{2}.Enable = 'Inactive';
            
        end         

        % --- initialises the experiment start time panel objects
        function setupExptStartPanel(obj)
            
            % field initialisations
            tStrSS = 'Experiment Start Time';
            tStrSL = 'Time To Start (DD:HH:MM:SS)';
            cStrS = 'Fixed Experiment Start Time';
            
            % creates the text label
            obj.hTxtS = obj.setupTxtLabelGroup(...
                obj.hPanelS,obj.dX*[1,1],tStrSL,obj.widTxtSS);
            obj.hTxtS.BackgroundColor = 'g';
            
            % creates the checkbox object
            xPosS = sum(obj.hTxtS.Position([1,3])) + obj.dX/2;
            cPosS = [xPosS,obj.dX,obj.widCheckS,obj.hghtCheck];
            obj.hCheckS = obj.setupCheckBox(obj.hPanelS,cPosS,cStrS);
            
            % creates the date group text label
            yPosS = obj.dX + obj.hghtRow;
            pPosST = [obj.dX/2,yPosS+2,obj.widTxtSL,obj.hghtTxt];
            obj.setupTextLabel(obj.hPanelS,pPosST,tStrSS);
            
            % creates the date group
            pPosS = [sum(pPosST([1,3]))+obj.dX/2,yPosS];
            obj.hPopupS = obj.setupDateGroup(...
                obj.hPanelS,pPosS,obj.widPopupS,1);
            
            % runs the experiment start timer function
            obj.timeToStart();
            
        end        
        
        % --- initialises the experiment duration panel objects  
        function setupExptDurPanel(obj)
            
            % object labels
            tStrD = 'Experiment Duration';            
            
            % creates the text label
            pPosTD = [obj.dX/2,obj.dX+2,obj.widTxtD,obj.hghtTxt];
            obj.setupTextLabel(obj.hPanelD,pPosTD,tStrD);
            
            % creates the popup duration group
            xPosPD = sum(pPosTD([1,3]));
            obj.hPopupD = obj.setupDurationGroup(...
                obj.hPanelD,[xPosPD,obj.dX],obj.widPopupD,1,true(1,4));            
            
        end                                            
        
        % --- initialises the video parameter panel objects
        function setupVideoParaPanel(obj)
            
            % field initialisations
            tStrRC = 'Video Compression';
            tStrRF = 'Video Frame Rate (fps)';
            tStrRD = 'Max Duration';
            
            % vertical offset calculation
            yPosR = sum(obj.hPanelV.Position([2,4])) + obj.dX;
            
            % creates the video compression popupmenu group
            pPosRC = [obj.dX,yPosR];
            obj.hPopupRC = obj.setupPopupGroup(...
                obj.hPanelR,pPosRC,tStrRC,[obj.widTxtRL,obj.widPopupRC]);            
            
            % creates the frame rate popupmenu group
            yPosR = yPosR + (obj.hghtRow + obj.dX/2);
            pPosRF = [obj.dX,yPosR];
            obj.hPopupRF = obj.setupPopupGroup(...
                obj.hPanelR,pPosRF,tStrRF,[obj.widTxtRL,obj.widObjR]);               
            
            % creates the frame-rate slider
            pPosRS = obj.hPopupRF.Position;
            pPosRS([2,4]) = [pPosRS(2)-3,obj.hghtSlider];
            obj.hSliderRF = obj.setupSlider(obj.hPanelR,pPosRS);
            
            % creates the frame-rate editbox
            pPosRE = pPosRS;
            pPosRE([2,4]) = [sum(pPosRS([2,4]))+2,obj.hghtEdit];
            obj.hEditRF = obj.setupEditBox(obj.hPanelR,pPosRE);
            
            % creates the text label
            xPosRT = sum(obj.hPopupRF.Position([1,3]));
            pPosRT = [xPosRT,yPosR+2,obj.widTxtRR,obj.hghtTxt];
            obj.setupTextLabel(obj.hPanelR,pPosRT,tStrRD);
            
            % creates the popupmenu duration group
            xPosRD = xPosRT + obj.widTxtRR;
            obj.hPopupRD = obj.setupDurationGroup(...
                obj.hPanelR,[xPosRD,yPosR],obj.widPopupRD,3);
            
            % sets the free frame-rate object visibility
            setObjVisibility(obj.hSliderRF,'off');
            setObjVisibility(obj.hEditRF,'off');            
            
        end
        
        % --- initialises the video resolution panel objects        
        function setupVideoResPanel(obj)
            
            % field initialisations
            uDataL = {'bSz','W','H'};
            pStrC = {'Use Original Image',...
                     'Use Pixel Binning',...
                     'Use Custom Resolution'};
            pStrVL = {'Bin Size','Width','Height'};                        

            % creates the video resolution type popupmenu 
            pPosVC = [obj.dX,obj.dX-2,obj.widPopupV,obj.hghtPopup];
            obj.hPopupV = obj.setupPopupMenu(obj.hPanelV,pPosVC,pStrC);

            % creates the editbox/popupmenu object groups
            xPosV = sum(pPosVC([1,3])) + obj.dX/2;
            [obj.hObjV,obj.hTxtV] = deal(cell(length(pStrC),1));
            for i = 1:length(pStrC)
                % sets up the position/object width vectors
                pPosV = [xPosV,obj.dX-2];
                wObjV = [obj.widTxtV(i),obj.widObjV];
                
                % creates the object groups
                if strcmp(uDataL{i},'bSz')
                    % case is a popupmenu group
                    [obj.hObjV{i},obj.hTxtV{i}] = obj.setupPopupGroup(...
                        obj.hPanelV,pPosV,pStrVL{i},wObjV,{'N/A'});
                else
                    % case is an editbox group                    
                    [obj.hObjV{i},obj.hTxtV{i}] = obj.setupEditGroup(...
                        obj.hPanelV,pPosV,pStrVL{i},wObjV); 
                end
                
                % sets the common properties
                obj.hObjV{i}.UserData = uDataL{i};                
                
                % increments the horizontal offset
                xPosV = xPosV + sum(wObjV);                
            end            
            
        end        
                       
        % --- initialises the video placement optimisation panel objects
        function setupVideoOptPanel(obj)
            
            % field initialisations
            tStrF = 'Approx. Max Video Frames';
            bStrF = 'Optimise Video Placement';
            
            % creates the background text object
            tPosFB = [obj.dX/2*[1,1],obj.widTxtFB,obj.hghtRow];
            obj.hTxtFB = obj.setupTextObject(obj.hPanelF,tPosFB,'');
            
            % creates the max video frame text label
            tPosFL = obj.dX*[1.5,1];
            [obj.hTxtF,obj.hTxtFL] = obj.setupTxtLabelGroup(...
                obj.hPanelF,tPosFL,tStrF,obj.widTxtF);            
                        
            % creates the button object
            xPosBF = sum(obj.hTxtFB.Position([1,3])) + obj.dX/2;
            bPosF = [xPosBF,obj.dX/2,obj.widButF,obj.hghtBut];
            obj.hButF = obj.setupPushButton(obj.hPanelF,bPosF,bStrF);
            
        end        
        
        % --- initialises the experiment summary panel objects
        function setupExptSummaryPanel(obj)
           
            % object labels
            cStrE = {'Unique Output Directory',...
                     'Feasible Experiment Duration',...
                     'Feasible Experiment Start Time',...
                     'Recording Parameters Set Correctly',...
                     'Feasible Stimuli Protocol',...
                     'All Stimuli Protocols Specified'};
            tStrE = {'Approx. Total Video Size',...
                     'Total Video Count'};
            
            % memory allocation
            obj.hTxtE = cell(obj.nTxtE,1);
            obj.hCheckE = cell(obj.nChkE,1);
            
            % creates the text label group
            [xPosT,wTxtT] = deal(obj.dX,[obj.widTxtEL,obj.widTxtE]);
            for i = 1:obj.nTxtE
                pPosT = [xPosT,obj.dX];
                obj.hTxtE{i} = obj.setupTxtLabelGroup(...
                    obj.hPanelE,pPosT,tStrE{i},wTxtT,1);
                xPosT = xPosT + (obj.dX + sum(wTxtT));
            end
            
            % creates the checkboxs
            yPosE = obj.dX + obj.hghtRow + 2*(obj.hghtCheck + 1);
            for i = 1:obj.nChkE
                % column index
                iCol = mod(i-1,2) + 1;
                
                % creates the checkbox object
                xPosE = obj.dX + (iCol-1)*(obj.widCheckE - 2*obj.dX);
                pPosE = [xPosE,yPosE,obj.widCheckE,obj.hghtCheck];
                obj.hCheckE{i} = ...
                    obj.setupCheckBox(obj.hPanelE,pPosE,cStrE{i});
                set(obj.hCheckE{i},'Enable','Inactive')
                
                % decrements the vertical offset
                if iCol == 2
                    yPosE = yPosE - (obj.hghtCheck + 1);
                end
            end            
            
        end                
           
        % --- sets the object callback functions
        function setObjectCallbacks(obj)
            
            % ------------------------------------ %
            % --- EXPERIMENT INFORMATION PANEL --- %
            % ------------------------------------ % 
            
            % editbox objects
            obj.hObjI{3}.Callback = @obj.editExptTitle;
            obj.hObjI{4}.Callback = @obj.editBaseFilename;
            
            % pushbutton objects
            obj.hButI.Callback = @obj.buttonOutDir;                
            
            % ----------------------------------- %
            % --- EXPERIMENT START TIME PANEL --- %
            % ----------------------------------- %
            
            % checkbox objects
            obj.hCheckS.Callback = @obj.checkFixStart;
            
            % popupmenu group objects
            cellfun(@(x)(...
                set(x,'Callback',@obj.popupExptStart)),obj.hPopupS)
            
            % --------------------------------- %
            % --- EXPERIMENT DURATION PANEL --- %
            % --------------------------------- %
            
            % popupmenu group objects
            cellfun(@(x)(set(x,'Callback',@obj.popupExptDur)),obj.hPopupD)
            
            % ------------------------------------------ %
            % --- VIDEO PLACEMENT OPTIMISATION PANEL --- %
            % ------------------------------------------ %
            
            % pushbutton objects
            obj.hButF.Callback = @obj.buttonOptPlace;
            
            % ------------------------------ %
            % --- VIDEO RESOLUTION PANEL --- %
            % ------------------------------ %
            
            % popupmenu object
            obj.hPopupV.Callback = @obj.popupCustRes;
            
            % editbox/popupmenu objects
            for i = 1:length(obj.hObjV)
                if strcmp(obj.hObjV{i}.UserData,'bSz')
                    % case is the pixel binning size popupmenu
                    obj.hObjV{i}.Callback = @obj.popupBinSize;
                else
                    % case is the custom dimension editboxes
                    obj.hObjV{i}.Callback = @obj.editResDim;
                end
            end
            
            % --------------------------------------- %
            % --- VIDEO RECORDING PARAMETER PANEL --- %
            % --------------------------------------- %
            
            % popupmenu objects
            set(obj.hPopupRC,'Callback',@obj.popupVidCompress);
            set(obj.hPopupRF,'Callback',@obj.popupFrmRate);
            
            % popupmenu group objects
            cellfun(@(x)(set(x,'Callback',@obj.popupVidDur)),obj.hPopupRD)
            
            % slider object
            set(obj.hSliderRF,'Callback',@obj.sliderFrmRate);
            
            % editbox object
            set(obj.hEditRF,'Callback',@obj.editFrmRate);
                        
        end
        
        % -------------------------------------------- %
        % --- PANEL FIELD INITIALISATION FUNCTIONS --- %
        % -------------------------------------------- %
        
        % --- initialises the experimental information fields
        function initExptInfoFields(obj)
            
            % if a stimuli only expt, then disable objects and exit
            if ~obj.infoObj.hasIMAQ
                setObjEnable(obj.hObjI{4},'off');
                setObjEnable(obj.hTxtI{4},'off');
                setObjEnable(obj.hCheckE{4},'off');
            end
            
            % sets the experiment protocol file name field
            if isempty(obj.iExpt.Info.FileName)
                obj.hObjI{1}.String = 'N/A';
            else
                obj.hObjI{1}.String = obj.iExpt.Info.FileName;
            end
            
            % updates the output directory field and string
            if isempty(obj.iExpt.Info.Title) || ~obj.isInit
                obj.resetExptTitle();                
            end
            
            % field retrieval
            [obj.iExpt.Info.OutDir,oD] = deal(obj.iProg.DirMov);
            [exT,bfN] = deal(obj.iExpt.Info.Title,obj.iExpt.Info.BaseName);
            
            % performs the unique experiment directory check
            obj.uniqueExptDirCheck(false);
            
            % updates the experiment title/base file name fields
            set(obj.hButI,'ToolTipString',oD);
            set(obj.hObjI{2},'String',obj.addGap(oD),'ToolTipString',oD);
            set(obj.hObjI{3},'String',obj.addGap(exT),'ToolTipString',exT);
            set(obj.hObjI{4},'String',obj.addGap(bfN),'ToolTipString',bfN);
            
        end        
        
        % --- initialises the video parameter fields
        function initVideoParaFields(obj)
        
            % updates the text label foreground/background colours
            ii = 1 + obj.isStimOnly;
            hObjT = {obj.hTxtF,obj.hTxtFL,obj.hTxtFB};
            cellfun(@(h)(set(h,'BackgroundColor',obj.bgCol{ii})),hObjT);
            cellfun(@(h)(set(h,'ForegroundColor',obj.fgCol{ii})),hObjT);
        
            % sets up the pixel binning values
            if obj.isStimOnly
                obj.hObjV{1}.String = {'N/A'};
            else
                vRes = getVideoResolution(obj.infoObj.objIMAQ,1);
                obj.hObjV{1}.String = obj.setupPixelBinningValues(vRes);
            end            
        
            % resets the panel properties
            setPanelProps(obj.hPanelF,~obj.isStimOnly,obj.hTxtFB);            
            setPanelProps(obj.hPanelR,~obj.isStimOnly)
            
            %
            obj.hPopupV.Value = 1;
            setObjEnable(obj.hPopupV,~obj.isStimOnly);
            
            % if a stimuli only expt, then disable objects and exit
            if obj.isStimOnly
                % disables the fields/objects
                obj.iExpt.Video.FPS = NaN;
                obj.setFrameRateObjProps(false)      
                cellfun(@(h)(set(h,'String','N/A')),obj.hObjV(2:3))
                return
            end
            
            % -------------------------- %
            % --- FRAME RATE OBJECTS --- %
            % -------------------------- %
            
            % field retrieval
            [fRate,isVarFPS] = obj.getCameraFrameRate();
            
            % sets up the camera frame rate objects
            if isVarFPS
                % case is a variable frame rate camera
                
                % initialises the frame rate slider
                srcObj = getselectedsource(obj.infoObj.objIMAQ);
                initFrameRateSlider(...
                    obj.hSliderRF,srcObj,obj.iExpt.Video.FPS)
                
                % runs the frame rate slider callback function
                obj.sliderFrmRate()
                
            else
                % case is a fixed frame rate camera
                fRateS = arrayfun(@num2str,fRate,'un',0);                
                iSel = find(fRate == obj.iExpt.Video.FPS);
                if isempty(iSel)
                    % if there are no matches, use the first value instead
                    obj.iExpt.Video.FPS = fRate(1);                    
                    set(obj.hPopupRF,'string',fRateS,'value',1)
                else
                    % otherwise, set the popupmenu properties
                    set(obj.hPopupRF,'string',fRateS,'value',iSel)
                end
                
                % recalculates the video timing
                obj.calcVidTiming();
                
            end
            
            % updates the frame rate object visibility
            obj.setFrameRateObjProps(isVarFPS)
            
            % ---------------------------------- %
            % --- MAX VIDEO DURATION OBJECTS --- %
            % ---------------------------------- %
            
            % field retrieval
            Dmax = obj.iExpt.Video.Dmax;
            
            % updates the popupmenu duration fields
            for i = 1:length(obj.hPopupRD)
                % sets up the popupmenu strings
                switch i
                    case 1
                        % case is the hours field
                        ppStr = obj.setupNumStringArray(12,1);
                        
                    case 2
                        % case is the minutes field
                        ppStr = obj.setupNumStringArray(59,1);
                end
                
                % updates the popup menu properties
                set(obj.hPopupRD{i},'String',ppStr,'Value',Dmax(i)+1);
            end
            
            % runs the video duration popupmenu callback
            obj.popupVidDur()
            
            % --------------------------------- %
            % --- VIDEO COMPRESSION OBJECTS --- %
            % --------------------------------- %
            
            % sets up the video compression popupmenu
            setupVideoCompressionPopup(obj.infoObj.objIMAQ,obj.hPopupRC)
            
            % determines the matching popupmenu item
            iSel = strcmp(obj.hPopupRC.String,obj.iExpt.Video.vCompress);
            if any(iSel)
                % case is there is a match
                obj.hPopupRC.Value = find(iSel);
                
            else
                % case is not match so use the first type
                obj.hPopupRC.Value = 1;
            end
            
        end                
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %
        
        % --- base experiment directory change callback function
        function buttonOutDir(obj,varargin)
            
            % field retrieval
            dDir = obj.iExpt.Info.OutDir;
            
            % prompts the user for the new default directory
            outDir = uigetdir(dDir,'Set The Default Path');
            if outDir
                % otherwise, update the directory string names
                obj.iExpt.Info.OutDir = outDir;

                % resets the enabled properties of the buttons
                set(obj.hObjI{2},'String',obj.addGap(outDir))
                set(obj.hButI,'ToolTipstring',outDir)
                obj.editExptTitle();

                % updates the video timing
                obj.calcVidTiming();
            end            
            
        end        
        
        % --- experiment title editbox change callback function
        function editExptTitle(obj,varargin)
            
            if ~isempty(varargin)
                % determines if the new string is valid
                nwStr = strtrim(obj.hObjI{3}.String);
                if chkDirString(nwStr)
                    % if so, then update the expt title field
                    obj.iExpt.Info.Title = nwStr;
                    set(obj.hObjI{3},'String',obj.addGap(nwStr),...
                                    'ToolTipString',nwStr);
                
                else
                    % otherwise, revert back to the last valid value
                    obj.hObjI{3}.String = obj.addGap(obj.iExpt.Info.Title);
                end
                    
            end
            
            % performs the unique experiment directory check
            obj.uniqueExptDirCheck(~isempty(varargin));
            
        end 
                
        % --- base filename editbox change callback function
        function editBaseFilename(obj,varargin)
            
            % retrieves the string
            nwStr = strtrim(obj.hObjI{4}.String);
            if chkDirString(nwStr)                
                % updates the info title and the experimental protocol data struct
                obj.iExpt.Info.BaseName = nwStr;
                set(obj.objI{4},'String',obj.addGap(nwStr),...
                                'ToolTipString',nwStr);
            else
                % otherwise, reset the string to the last valid string
                obj.objI{4}.String = obj.addGap(iExpt.Info.BaseName);
            end
            
        end        
        
        % --- experiment start popupmenu change callback function
        function popupExptStart(obj,hObject,~)
            
            % field retrieval
            iSel = hObject.UserData;
            [pStr,iVal] = deal(hObject.String,hObject.Value);
            
            % updates the start time (based on selection)
            switch iSel
                case 5
                    % case is the AM/PM selection
                    tHours = mod(obj.iExpt.Timing.T0(4)-1,12) + 1;
                    obj.iExpt.Timing.T0(4) = tHours + 12*(iVal-1);

                otherwise
                    % case is the other popupmenu items
                    obj.iExpt.Timing.T0(iSel+1) = str2double(pStr{iVal});
            end
            
            % updates the start time
            if obj.iExpt.Timing.fixedT0
                obj.timeToStart()
            end
            
            % updates the experimental protocol tab fields
            if iSel <= 3 
                obj.objT{4}.hPopupF{iSel-2}.Value = iVal;
                obj.objT{4}.objAx.resetAxesTimeProps();
            end
            
        end        
        
        % --- fix experiment start checkbox callback function
        function checkFixStart(obj,varargin)
            
            % updates the experiment protocol tab properties
            obj.objT{4}.checkFixStart(obj.hCheckS.Value);
            
            % runs the time to start callback function
            obj.timeToStart()                        
            
        end                        
        
        % --- frame rate slider change callback function
        function popupFrmRate(obj,varargin)
            
            % field retrieval
            iSel = get(obj.hPopupRF,'Value');
            fList = get(obj.hPopupRF,'String');
            
            % updates the FPS field
            obj.iExpt.Video.FPS = str2double(fList{iSel});
            
            % recalculates the video timing
            obj.calcVidTiming();
            
        end        
        
        % --- frame rate slider change callback function
        function sliderFrmRate(obj,hObj,~)
            
            % field retrieval
            nwVal = round(get(hObj,'Value'),1);                                
            srcObj = get(obj.infoObj.objIMAQ,'Source');
            [fpsLim,fpsFld] = obj.getFrameRateLimits(srcObj);
            
            % converts the value to a character (if required)
            prVal = get(srcObj,fpsFld); 
            if ischar(prVal)
                % determines the matching fps value
                fpsLimC = cellfun(@str2double,fpsLim);
                ii = fpsLimC == iExpt.Video.FPS;        
                if ~any(ii)
                    % if there are not any matches, then determine the closest
                    nwVal = fpsLim{argMin(abs(fpsLimC - iExpt.Video.FPS))};
                else
                    % otherwise, use the matching value
                    nwVal = fpsLim{ii};
                end

                % sets the numerical values
                nwValN = str2double(nwVal);
                set(hObject,'Value',nwValN)    
            else
                % case is a numerical value
                [nwVal,nwValN] = deal(max(min(nwVal,fpsLim(2)),fpsLim(1)));
            end            
            
            % updates the frame rate
            obj.iExpt.Video.FPS = nwValN;
            obj.hEditRF.String = num2str(obj.iExpt.Video.FPS);
            
            % recalculates the video timing
            set(srcObj,fpsFld,nwVal);
            obj.calcVidTiming();
            
        end                  
        
        % --- frame rate editbox change callback function
        function editFrmRate(obj,hObj,~)
            
            % field retrieval
            nwVal = str2double(get(hObj,'String'));    
            srcObj = get(obj.infoObj.objIMAQ,'Source');            
            [fpsLim0,fpsFld] = obj.getFrameRateLimits(srcObj);
            
            % converts cell array to numerical array
            if iscell(fpsLim0)
                fpsLim = cellfun(@str2double,fpsLim0);
            else
                fpsLim = fpsLim0;
            end            
            
            % determines if the new value is valid
            if chkEditValue(nwVal,fpsLim,0)
                % updates the camera frame rate (based on type)
                if ischar(class(get(srcObj,fpsFld)))
                    % retrieves the constraint values
                    fpsInfo = propinfo(srcObj,fpsFld);
                    cVal0 = sort(fpsInfo.ConstraintValue);
                    if iscell(cVal0)
                        % retrieves the list values
                        cVal = cellfun(@str2double,cVal0);
                        
                        % determines if the value matches
                        ii = cVal == nwVal;
                        if ~any(ii)
                            % if no match, then set the closest value
                            ii = argMin(abs(cVal - nwVal));
                            nwVal = cVal(ii);
                            set(hObject,'String',nwVal)
                        end
                        
                        % sets the final source value
                        srcVal = fpsLim0{ii};
                    else
                        % sets the source object update values
                        srcVal = nwVal;
                    end
                    
                    % updates the source object
                    set(srcObj,fpsFld,srcVal);
                    
                else
                    % case is the other types
                    set(srcObj,fpsFld,nwVal);
                end
                
                % updates the parameter value
                obj.iExpt.Video.FPS = nwVal;
                obj.hSliderRF.Value = nwVal;
                obj.calcVidTiming();
                
            else
                % otherwise, reset the editbox value
                hObj.String = num2str(obj.iExpt.Video.FPS);
            end
            
        end
        
        % --- video duration popupmenu callback function
        function popupVidDur(obj,hObject,~)
            
            % default input arguments
            if ~exist('hObject','var')
                hObject = obj.hPopupRD{1};
            end
            
            % field retrieval
            iVal = get(hObject,'Value');
            iSel = get(hObject,'UserData');
            D0 = obj.iExpt.Video.Dmax(iSel);
            
            % updates the new selection value
            obj.iExpt.Video.Dmax(iSel) = iVal - 1;
            if sum(obj.iExpt.Video.Dmax) == 0
                % if the video duration is zero, then output an error
                obj.showError('Incorrect Video Duration')
                
                % resets the popup menu value
                obj.iExpt.Video.Dmax(iSel) = D0;
                set(hObject,'value',D0+1)
                
            else
                % determine if the video duration exceeds the expt
                tVid = vec2sec([0,obj.iExpt.Video.Dmax]);
                if tVid > vec2sec(obj.iExpt.Timing.Texp)
                    obj.resetDurTimeValues(obj.hPopupRD,true);
                end
                
                % recalculates the video timing
                obj.calcVidTiming();
            end
            
        end        
        
        % --- video compression popupmenu change callback function 
        function popupVidCompress(obj,hObject,~)
            
            % field retrieval
            iSel = get(hObject,'Value');
            ppStr = get(hObject,'String');
            
            % updates the compression string type
            obj.iExpt.Video.vCompress = ppStr{iSel};
            
            % recalculates the video timing
            obj.calcVidTiming();            
            
        end
        
        % --- custom resolution popupmenu change callback function
        function popupCustRes(obj,varargin)
            
            % updates the struct field
            [obj.resInfo.rType,rT] = deal(obj.hPopupV.Value);  
            
            % updates the object enabled properties
            setObjEnable(obj.hTxtV{1},(rT==2));
            setObjEnable(obj.hObjV{1},(rT==2));
            cellfun(@(x)(setObjEnable(x,rT==3)),obj.hTxtV(2:3))
            cellfun(@(x)(setObjEnable(x,rT==3)),obj.hObjV(2:3))
                        
            % retrieves the editbox value (based on the user choice type)
            vRes = getVideoResolution(obj.infoObj.objIMAQ,1);
            switch obj.resInfo.rType
                case 1
                    % case is using the default resolution
                    eVal = vRes;                    
                    
                case 2
                    % case is pixel binning
                    obj.resInfo.bSz = 2^obj.hObjV{1,1}.Value;
                    eVal = vRes/obj.resInfo.bSz;
                    
                case 3
                    % case is using the custom resolution
                    eVal = getStructFields(obj.resInfo,{'W','H'},1);
            end
            
            % updates the editbox values
            eStr = arrayfun(@num2str,eVal(:),'un',0);
            cellfun(@(h,v)(set(h,'String',v)),obj.hObjV(2:3),eStr)
            
            % recalculates the video timing
            obj.calcVidTiming();
        end
        
        % --- pixel binning popupmenu change callback function
        function popupBinSize(obj,varargin)
            
            % resets the resolution information data struct
            obj.resInfo.bSz = 2^obj.hObjV{1}.Value;
            
            % resets the editbox values
            eVal = num2cell(getVideoResolution(...
                obj.infoObj.objIMAQ,1)/obj.resInfo.bSz)';
            cellfun(@(h,v)(set(h,'String',num2str(v))),obj.hObjV(2:3),eVal)            
            
            % recalculates the video timing
            obj.calcVidTiming();
            
        end              
        
        % --- custom resolution editbox change callback function
        function editResDim(obj,hObject,~)
            
            % field retrieval
            pStr = hObject.UserData;
            vRes = obj.objB.getRecordingResolution();                        
            nwVal = str2double(get(hObject,'String'));            
            nwLim = [20,vRes(1+strcmp({'W','H'},pStr))];
            
            % determines if the new value is valid
            if chkEditValue(nwVal,nwLim,1)                            
                % if so, update the parameter field
                obj.resInfo.(pStr) = nwVal;
                
                % recalculates the video timing
                obj.calcVidTiming();

            else
                % otherwise, reset to the last valid value
                set(hObject,'String',num2str(obj.resInfo.(pStr)));
            end
            
        end
        
        % --- video optimal placement pushbutton callback function
        function buttonOptPlace(obj,varargin)
            
            
            
        end

        % ------------------------------ %
        % --- VIDEO TIMING FUNCTIONS --- %
        % ------------------------------ %        
        
        % --- calculate video timing wrapper function 
        function mStr = calcVidTiming(obj,varargin)
            
            % if this is a stimuli only expt, then exit the function
            mStr = [];
            if obj.isStimOnly
                return
            end   
            
            % FINISH ME!
            rType = 'FixedDur';
            
            % field retrieval
            isCheck = true;
            [Timing,VV] = deal(obj.iExpt.Timing,obj.iExpt.Video);
            hasStim = ~isempty(obj.sTrainP.Ex);
            
            % if the number of frames
            tExp = vec2sec(Timing.Texp);
            tVid = vec2sec([0,VV.Dmax]);
            
            % case is experiment duration is less than max video duration
            if (tExp < tVid) && strcmp(obj.iExpt.Info.Type,'RecordOnly')
                % resets the video information fields
                obj.iExpt.Video.Tf = ceil(tExp*VV.FPS);
                [obj.iExpt.Video.nCount,obj.iExpt.Video.Ts] = deal(1);
            
                % updates the information fields
                nFrmT = ceil((obj.iExpt.Video.Tf-1)*VV.FPS);
                fSizeT = obj.estTotalVideoSize(nFrmT);
                obj.updateInfoFields(nFrmT,fSizeT,0,1)
                
                % exits the function
                return
            end
            
            % calculates video start times based on setup type
            switch rType
                case 'BtwnStim'
                    % case is recording between the stimuli
                    obj.calcBtwnStimTimes();   
                    
                case 'OnStim'
                    % case is recording on the stimuli
                    obj.calcOnStimTimes();
                    
                case 'FixedDur'
                    % case is recording fixed duration
                    if isempty(varargin)
                        % case is calculating the fixed duration times
                        obj.calcFixedDurTimes();
                    else
                        % case is optimising the fixed duration times
                        obj.optFixedDurTimes();
                    end
                    
                    % check to see if the video parameters are feasible
                    if ~hasStim
                        if (isnan(obj.iExpt.Video.nCount) || ...
                                 (obj.iExpt.Video.nCount == 0))
                            isCheck = false;
                        end
                    end                                                            
            end
            
            % updates the video parameter feasibility flag
            if ~obj.isStimOnly
                obj.setFeasFlag('RecordPara',isCheck);
            end
            
            % field retrieval
            VV = obj.iExpt.Video;
            outDir = obj.iExpt.Info.OutDir;
            
            % pre-calculations            
            nFrmT = sum(ceil((VV.Tf-VV.Ts)*VV.FPS));
            nFrmMax = ceil(max(VV.Tf-VV.Ts)*VV.FPS);
            fSizeT = obj.estTotalVideoSize(nFrmT);
            
            % determines the currently selected volume (from the video file output)
            vInfo = getDiskVolumeInfo();
            iVol = cellfun(@(x)(startsWith(outDir,x)),vInfo(:,1));
            isWarn = fSizeT > vInfo{iVol,3};
            
            % updates the information fields
            obj.updateInfoFields(nFrmMax,fSizeT,isWarn,VV.nCount);
                         
            % flag warning if estimated disk space is exceeded
            if isWarn && obj.isInit
                % if so, then output a message to screen
                mStr = sprintf(['Warning! The estimated total disk ',...
                    'space required for the experiment exceeds the ',...
                    'free space:\n\n* Estimated Required Space ',...
                    '= %.2fGB\n * Free Space on %s = %.2fGB\n\n'],...
                    fSizeT,vInfo{iVol,1},vInfo{iVol,3});

                % outputs message to screen (if not outputting to screen)
                if nargout == 0
                    mStr = sprintf(['%sEither select another drive ',...
                        'for video file output, select another video ',...
                        'compression type, or reduce the experiment ',...
                        'duration.'],mStr);        
                    waitfor(msgbox(mStr,'Disk Space Warning','modal'))   
                end                
            end
            
        end        
        
        % --- calculates the fixed duration video start times
        function calcFixedDurTimes(obj)
            
            % --- The fixed duration video files assumes that:
            %      A) the videos start on the first frame
            %      B) the final video will be of variable length
            
            % field retrieval
            TT = obj.iExpt.Timing;
            tFix = vec2sec([0,obj.iExpt.Video.Dmax]);
            
            % updates the video parameter sub-struct into the experimental data struct
            obj.calcFixedDurIndices(tFix,vec2sec(TT.Texp),TT.Tp);
            
        end
        
        % --- calculates the fixed duration video start times
        function optFixedDurTimes(obj)
            
            
            
        end        

        % --- calculates the indices of the fixed duration videos --- %
        function calcFixedDurIndices(obj,tFix,tExp,tPause)
            
            % calculates the total number of videos, and allocated memory for the video
            % start/finish times
            VV = obj.iExpt.Video;
            VV.nCount = ceil(tExp/(tFix + tPause));
            [VV.Ts,VV.Tf] = deal(zeros(VV.nCount,1));
            
            % loops through all the videos setting the start/stop times
            for i = 1:VV.nCount
                % sets the start time index (based on the video index)
                if (i == 1)
                    % case if the first video
                    VV.Ts(i) = 0;
                else
                    % case is the other videos
                    VV.Ts(i) = VV.Tf(i-1) + tPause;
                end
                
                % sets the finish time index (ensures the max index is nFrmTot)
                VV.Tf(i) = min(VV.Ts(i) + tFix,tExp);
            end
        
            % resets the data struct field
            obj.iExpt.Video = VV;
            
        end
        
        % --- estimates the size of all videos (each with frame count, nFrmVid and
        %     frame size, szFrm, using compression type, vComp
        function fSizeTot = estTotalVideoSize(obj,nFrmTot)
            
            % sets the binning size
            if obj.resInfo.rType == 2
                % case is using pixel binning
                bSz = obj.resInfo.bSz;
            else
                % otherwise case
                bSz = 1;
            end
            
            % calculates the total frames
            szFrm = getVideoResolution(obj.infoObj.objIMAQ)/bSz;
            fSize0 = 3*nFrmTot*prod(szFrm);
            
            % calculates the total estimated file size
            switch obj.iExpt.Video.vCompress
                case 'Grayscale AVI'
                    % case is grayscale avi
                    fSizeTot = (1/2)*fSize0/3;
                    
                case 'Uncompressed AVI'
                    % case is uncompressed avi
                    fSizeTot = fSize0;
                    
                case 'Archival'
                    % case is archival compression
                    fSizeTot = (1/4)*fSize0;
                    
                case 'Motion JPEG 2000'
                    % case is mj2 compressions
                    fSizeTot = (4/20)*fSize0;
                    
                case 'Motion JPEG AVI'
                    % case is motion jpeg compression
                    fSizeTot = (1/55)*fSize0;
                    
                case 'MPEG-4'
                    % case is mpeg-4 compression
                    fSizeTot = (1/90)*fSize0;
            end
        
            % converts from bytes to gigabytes
            fSizeTot = fSizeTot/(1024^3);            
            
        end
        
        % ------------------------------------ %
        % --- CLASS FIELD GETTER FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- retrieves the camera frame rate properties
        function [fRate,isVarFPS] = getCameraFrameRate(obj,returnSel)
            
            % field retrieval
            [isVarFPS,iSel] = deal(false,1);
            FPS = obj.iExpt.Video.FPS;
            
            % retrieves the camera frame rate
            if obj.infoObj.isTest
                % case is running in testing mode
                fRate = {num2str(FPS)};
            
            elseif obj.infoObj.isWebCam
                % case is running a webcam
                [~,fRate,iSel] = detWebcamFrameRate(obj.infoObj.objIMAQ,FPS);

            else
                fRate = obj.infoObj.fRate;
                if ~isVidDev(obj.infoObj.objIMAQ)
                    isVarFPS = detIfFrameRateVariable(obj.infoObj.objIMAQ);                    
                end
            end
                            
            %
            if exist('returnSel','var') && returnSel
                fRate = str2double(fRate{iSel});
            end
            
        end
        
        % ------------------------------------ %
        % --- CLASS FIELD SETTER FUNCTIONS --- %
        % ------------------------------------ %                
        
        % --- sets the feasibility flag for type, fType
        function setFeasFlag(obj,fType,fFlag,chkFeas)
            
            % default input arguments
            if ~exist('chkFeas','var')
                chkFeas = true;
            end                        
            
            switch fType
                case 'UniqueDir'
                    % case is the unique directory check
                    iChk = 1;
                    
                case 'ExptDur'
                    % case is the experiment duration check
                    iChk = 2;
                    
                case 'StartTime'
                    % case is the experiment start time check
                    iChk = 3;                    
                    
                case 'RecordPara'
                    % case is the recording parameter check
                    iChk = 4;                    
                    
                case 'StimProto'
                    % case is the stimuli protocol feasibility check                   
                    iChk = 5;                    
                    
                case 'AllStimProto'
                    % case is the total stimuli protocol check
                    iChk = 6;                    
            end                        
            
            % update the checkbox if there is a flag discrepancy
            if xor(obj.hCheckE{iChk}.Value,fFlag)
                obj.hCheckE{iChk}.Value = fFlag;
                
                % runs the feasibility check (if required)
                if chkFeas
                    obj.checkExptFeas();
                end
            end
            
        end
                
        % --- sets the time to start label field
        function setStartTimeField(obj,tStr,tCol)
            
            set(obj.hTxtS,'String',tStr,'BackgroundColor',tCol);
            
        end
        
        % --- sets the frame rate object properties
        function setFrameRateObjProps(obj,isVarFPS)
            
            setObjVisibility(obj.hEditRF,isVarFPS)
            setObjVisibility(obj.hSliderRF,isVarFPS)
            setObjVisibility(obj.hPopupRF,~isVarFPS)
            
        end                        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- determines if the current expt directory is unique
        function isUniq = uniqueExptDirCheck(obj,outErr)
            
            % determines if the current directory is unique
            exDir = fullfile(obj.iExpt.Info.OutDir,obj.iExpt.Info.Title);
            isUniq = ~exist(exDir,'dir');
            
            % updates the other object properties
            obj.hTxtI{3}.ForegroundColor = obj.uCol(1+isUniq);
            obj.setFeasFlag('UniqueDir',isUniq,obj.isInit);
            
            % outputs an error (if required and not unique)
            if outErr && ~isUniq
                obj.showError('Existing Output Directory');
            end
            
        end
        
        % --- determines if the expt duration is feasible
        function minExptDurCheck(obj)
            
            % if still initialising then exit
            if isempty(obj.objT{4}.objSM)
                return
            end
            
            % retrieves the current tab index and stimulus timing type 
            tMin = obj.getMinExptDuration(); 
            
            % determines if the min expt duration is feasible
            if tMin == 0
                isFeas = true;
            else
                % calculates the min duration values/strings
                Timing = obj.iExpt.Timing;
                isFeas = vec2time(Timing.Texp,Timing.TexpU) >= tMin;
            end
            
            % updates the feasibility flag
            obj.setFeasFlag('ExptDur',isFeas,obj.isInit);
            
        end
        
        % --- experiment start timer callback function
        function timeToStart(obj,varargin)
            
            if ~isvalid(obj.hFig)
                deleteTimerObjects(obj.hTimerS)
                return
            end
            
            % field initialisations
            [isFeas,strCol,dtStr] = deal(true,'g','N/A');
            
            % determines if the current start time is feasible
            if obj.hCheckS.Value
                % case is non-fixed start time
                [nwTime,T0] = deal(clock,obj.iExpt.Timing.T0);
                
                % calculates the experiment start time difference
                [dT,~,TS] = calcTimeDifference(T0,nwTime);
                dtStr = obj.setTimeDiffString(dT,TS);                                
                
                % determines if the time is feasible
                isFeas = dT >= 0;
                if ~isFeas
                    % if not feasible, set colour to red
                    strCol = 'r';                    
                end
            end
            
            % updates the start time field and feasibility flag
            obj.setStartTimeField(dtStr,strCol);            
            obj.setFeasFlag('StartTime',isFeas);            
            
        end
        
        % --- overall experiment feasibility check function
        function checkExptFeas(obj)

            % retrieves the checkbox values
            chkVal = cellfun(@(x)(get(x,'Value')),obj.hCheckE);
            eFlag = cellfun(@(x)(get(x,'Enable')),obj.hCheckE,'un',0);
            isFeas = all(chkVal(~strcmp(eFlag,'off')));
                        
            % updates the menu items based on feasibility
            obj.objM.setMenuItemEnable('menuRunExpt',isFeas);
            obj.objM.setMenuItemEnable('menuSaveProto',isFeas);
            obj.objM.setMenuItemEnable('toolSaveProto',isFeas);           
            
        end        

        % --- resets the experiment title class field
        function resetExptTitle(obj)
            
            dStr = datestr(now,'dd-mmm-yyyy');
            exTitle = sprintf('New Experiment (%s)',dStr);
            obj.iExpt.Info.Title = exTitle;
            
        end
        
        % --- retrieves the frame rate limits
        function [fpsLim,fpsFld] = getFrameRateLimits(obj,srcObj)
                          
            % retrieves the property information   
            fpsFld = getCameraRatePara(srcObj);
            fpsInfo = propinfo(srcObj,fpsFld);
            
            % retrieves the limit values
            if iscell(fpsInfo.ConstraintValue)
                fpsLim0 = sort(fpsInfo.ConstraintValue);
                fpsLim = fpsLim0([1,end]);
            else
                fpsLim = fpsInfo.ConstraintValue;
                fpsLim(2) = min(fpsLim(2),obj.fpsMax);
            end            
            
        end        

        % --- updates the video size/count fields
        function updateInfoFields(obj,nFrmMax,fSizeT,isWarn,nCountV)
            
            % class object field updates
            set(obj.hTxtF,'String',num2str(nFrmMax));
            set(obj.hTxtE{1},'String',sprintf('%.2fGB',fSizeT),...
                'ForegroundColor',obj.uCol(2-isWarn));
            set(obj.hTxtE{2},'String',num2str(nCountV));
            
        end
        
    end
    
    % static class methods
    methods (Static)

        % --- sets up the time to start string
        function dtStr = setTimeDiffString(dT,TS)
            
            % ensures the day string is positive
            if (dT < 0)
                TS{1} = TS{1}(2:end);
            end
            
            % sets up the time difference string
            dtStr = sprintf('%s:%s:%s:%s',TS{1},TS{2},TS{3},TS{4});
            
        end
        
        % --- adds a gap to the string, tStr
        function tStrG = addGap(tStr)
            
            tStrG = sprintf('  %s',tStr);
            
        end
        
        % --- sets the pixel binning value string
        function pStrVB = setupPixelBinningValues(vRes)
            
            % initialisations
            nMax = 0;
            
            % keep incrementing nMax until divisor not divisble by 2
            while true
                if all(mod(vRes/2^(nMax+1),1) == 0)
                    % resolution division is integer
                    nMax = nMax + 1;
                else
                    % otherwise, exit the loop
                    break
                end
            end
                        
            % sets up the string array
            pStrVB = arrayfun(@num2str,2.^(1:nMax),'un',0)';
            
        end        
        
    end
           
end