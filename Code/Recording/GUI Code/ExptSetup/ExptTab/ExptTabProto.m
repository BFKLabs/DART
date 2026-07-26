classdef ExptTabProto < ExptTab
    
    % class properties
    properties
        
        % experiment duration panel objects
        hPanelD
        hPopupD
        hButD
        
        % experiment start time panel objects
        hPanelS
        hRadioS
        
        % fixed start time panel objects
        hPanelF
        hPopupF                
        
        % stimuli repetition panel objects
        hPanelR
        
        % stimuli block panel objects
        hPanelB
        hButB
        hListB
        
        % fixed object dimensions
        hghtListB = 80;
        
        % calculated object dimensions
        hghtPanelD
        hghtPanelS
        hghtPanelF
        hghtPanelR
        hghtPanelB
        widPanelI
        widPanelF
        widObjD
        widButD
        hghtTabGrpR        
        widRadioS
        widPopupF
        widPopupI
        widListB
        widButB
                
        % numerical class fields
        nObjD = 4;
        nObjS = 2;
        nObjF = 3;
        nObjI = 4;
        nColB = 2;
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = ExptTabProto(objB,hTab)
            
            % creates the super-class object
            obj@ExptTab(objB,hTab,4);  
            
            % initialises the class fields/objects
            obj.initClassFields();
            start(obj.hTimer);
                        
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %        
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % deletes any previous timers
            obj.tagStr = 'hTimerExptTab';
            obj.clearPrevTimers(obj.tagStr);
           
            % timer object
            obj.hTimer = timer(...
                'StartDelay',1.5,...
                'TimerFcn',@obj.initClassObjects,...
                'Tag',obj.tagStr);
            
            % initialises the experiment duration/time units
            obj.tDurTotU = obj.iExpt.Timing.TexpU;
            obj.tDurTot = vec2time(obj.iExpt.Timing.Texp,obj.tDurTotU);              
            
            % ------------------------------------------- %
            % --- CLASS OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------------- %            
            
            % panel dimension calculations
            obj.widPanelI = obj.widPanel - obj.dX;
            obj.widPanelF = obj.widPanelI - obj.dX;
            obj.hghtPanelD = obj.hghtGrp + obj.dX/2 + 3*obj.hghtRow;
            obj.hghtPanelF = obj.dX/2 + 2*obj.hghtRow;
            obj.hghtPanelS = obj.hghtGrp + ...
                obj.dX + obj.hghtPanelF + 2*obj.hghtRadio;            
            obj.hghtPanelB = 1.5*obj.dX + obj.hghtListB + 2*obj.hghtBut;
            obj.hghtPanelR = obj.hghtPanel - (2.5*obj.dX + ...
                obj.hghtPanelB + obj.hghtPanelS + obj.hghtPanelD);
            
            % other object dimension calculations
            obj.widObjD = (obj.widPanelI - 2.5*obj.dX)/obj.nObjD;
            obj.widButD = obj.widPanelI - obj.dX;             
            obj.widRadioS = obj.widPanelI - 2*obj.dX; 
            obj.widPopupF = (obj.widPanelF - 2*obj.dX)/obj.nObjF;
            obj.widPopupI = (obj.widPanelI - 2.5*obj.dX)/obj.nObjI;
            obj.widListB = obj.widPanelI - obj.dX;
            obj.widButB = obj.widListB/obj.nColB;
            
        end
        
        % --- initialises the class objects
        function initClassObjects(obj,varargin)
        
            % --------------------------- %
            % --- STIMULI BLOCK PANEL --- %
            % --------------------------- % 
            
            % panel object
            pPosB = [obj.dX*[1,1]/2,obj.widPanelI,obj.hghtPanelB];
            obj.hPanelB = obj.setupHeadlessPanel(obj.hPanel,pPosB);
           
            % initialises the stimuli block panel objects
            obj.setupStimBlockPanel()
            
            % ------------------------------------------ %
            % --- STIMULI REPETITION PARAMETER PANEL --- %
            % ------------------------------------------ %
            
            % panel object
            yPosR = sum(pPosB([2,4])) + obj.dX/2;
            pPosR = [obj.dX/2,yPosR,obj.widPanelI,obj.hghtPanelR];
            obj.hPanelR = obj.setupHeadlessPanel(obj.hPanel,pPosR);
            
            % initialises the stimuli repetition panel objects
            obj.setupStimRepPanel() 
            
            % ----------------------------------- %
            % --- EXPERIMENT START TIME PANEL --- %
            % ----------------------------------- %
            
            % field initialisations
            tStrS = 'EXPERIMENT START TIME';
            
            % panel object
            yPosS = sum(pPosR([2,4])) + obj.dX/2;
            pPosS = [obj.dX/2,yPosS,obj.widPanelI,obj.hghtPanelS];
            obj.hPanelS = obj.setupHeadedPanel(obj.hPanel,pPosS,tStrS,1);
            
            % creates the fixed start time panel
            pPosF = [obj.dX*[1,1]/2,obj.widPanelF,obj.hghtPanelF];
            obj.hPanelF = obj.setupHeadlessPanel(obj.hPanelS,pPosF);
            
            % initialises the experiment start time panel objects
            obj.setupExptStartPanel()
            
            % --------------------------------- %
            % --- EXPERIMENT DURATION PANEL --- %
            % --------------------------------- %
            
            % field initialisations
            tStrD = 'EXPERIMENT DURATION';            
            
            % panel object
            yPosD = sum(pPosS([2,4])) + obj.dX/2;
            pPosD = [obj.dX/2,yPosD,obj.widPanelI,obj.hghtPanelD];
            obj.hPanelD = obj.setupHeadedPanel(obj.hPanel,pPosD,tStrD);
            
            % initialises the experiment duration panel objects
            obj.setupExptDurPanel() 
            
            % ----------------------- %
            % --- PLOT AXES PANEL --- %
            % ----------------------- %
            
            % creates the stimuli protocol axes object
            obj.objAx = ExptAxesProto(obj);
            obj.calcAxesGlobalCoords();
            
            % function handles
            obj.objSM.updateMinDurFcn = @obj.updateMinDurButtonProps;
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %            
        
            % sets the object callback functions/properties
            obj.setObjectCallbacks()
            obj.initObjectProps();            
            
            % initialises the object properties
            deleteTimerObjects(obj.hTimer);
            obj.isInit = true;            
            
%             % checks all tabs have been initialised
%             obj.dialogInitCheck();            
            
        end
        
        % --- initialises the object properties
        function initObjectProps(obj)
            
            % ----------------------------------------- %
            % --- EXPERIMENT DURATION PANEL OBJECTS --- %
            % ----------------------------------------- %            
            
            % sets the experiment duration start time
            obj.setDurTimeValues(obj.hPopupD,obj.iExpt.Timing.Texp);            
            
            % ------------------------------------------- %
            % --- EXPERIMENT START TIME PANEL OBJECTS --- %
            % ------------------------------------------- %            
            
            % sets the experiment start time popupmenu objects
            obj.setStartTimeValues(obj.hPopupF,2);            
            
            % resets the fixed start radio button
            set(obj.hRadioS{1},'Value',~obj.iExpt.Timing.fixedT0);            
            set(obj.hRadioS{2},'Value',obj.iExpt.Timing.fixedT0);
            obj.panelExptStartTime()
            
            % ------------------------------------------ %
            % --- STIMULI REPETITION PARAMETER PANEL --- %
            % ------------------------------------------ %
            
            % resets repetition parameter values...
            
            
            % ----------------------------------- %
            % --- STIMULI BLOCK PANEL OBJECTS --- %
            % ----------------------------------- %
            
            if obj.isInit
                % case is loading an experimental protocol
                            
            else
                % case is figure creation            

                % disables the non-add block button
                cellfun(@(x)(setObjEnable(x,0)),obj.hButB(2:end))
            end
            
            % enables the protocol menu items (recording only)
            obj.objM.setMenuItemEnable('menuNewProto','on');
            obj.objM.setMenuItemEnable('menuOpenProto','on');
            obj.objM.setMenuItemEnable('toolNewProto','on');
            obj.objM.setMenuItemEnable('toolOpenProto','on');
            
            % disables both panels
            obj.objR.setTabEnable(0);
            obj.objB.updateExptProtoTabProps();
            
        end
        
        % --- resets the object properties
        function resetObjectProps(obj,~,~,sTrainT)
            
            % field retrieval
            objR = obj.objSM.objR;
            TexpU = obj.iExpt.Timing.TexpU;
            
            % clears all stimuli objects/fields
            if ~isempty(obj.objSM.sBlk)
                obj.buttonDeleteAllStimObj();
                obj.sTrain = [];
            end
            
            % resets the axes total duration
            obj.objAx.resetTotalDuration();
            
            % creates the stimuli block objects
            nBlk = length(sTrainT.Ex);
            for i = 1:nBlk
                % calculates the time offset
                sParaB = sTrainT.Ex{i}.sParaEx;
                tOfsMlt = getTimeMultiplier(sParaB.tOfsU,TexpU);
                tOfsB = sParaB.tOfs/tOfsMlt;
                
                % updates the parameter tab index
                isL = startsWith(sTrainT.Ex{i}.sType,'L');
                objR.setParaTab(1+isL);
                objR.objT{1+isL}.setRepParaValue(sParaB);
                
                % updates the listbox selection
                sNameB = sTrainT.Ex{i}.sName;
                hListS = objR.objT{1+isL}.hListS;                
                hListS.Value = find(strcmp(hListS.String,sNameB));
                
                % creates the stimuli block objects
                obj.objSM.createBlockObj(tOfsB,i==nBlk);
                obj.addExptBlockObj();
                
                % remove block highlight
                obj.objSM.sBlk{i}.setBlockObjHighlight('off');
                hListS.Value = 1;
            end            
            
            % ensures all time offsets are set to zero
            for i = 1:length(objR.objT)
                if objR.objT{i}.tOfs > 0
                    objR.objT{i}.tOfs = 0;
                end
            end
            
            % resets the stimuli manager index fields
            obj.objSM.iSigS = NaN;
            [obj.objSM.iSigH,obj.objSM.iChH] = deal(-1);
            
            % removes the listbox highlight            
            set(obj.hListB,'Max',2,'Value',[]); 
%             obj.popupExptDur(obj.hPopupD{1},'1');
            obj.setPanelEnableProps('BlockProps',false);
            
            % resets the start/duration popupmenu fields
            obj.setStartTimeValues(obj.hPopupF,2)
            obj.setDurTimeValues(obj.hPopupD,obj.iExpt.Timing.Texp);
            
            % other house-keeping exercises
            deleteTimerObjects(obj.hTimer);      
            obj.objB.updateExptProtoTabProps();
            obj.updateMinDurButtonProps();
            
        end
        
        % --------------------------------------- %
        % --- PANEL OBJECT CREATION FUNCTIONS --- %
        % --------------------------------------- %  
        
        % --- initialises the experiment duration panel objects  
        function setupExptDurPanel(obj)
            
            % field initialisations
            bStrDD = 'Use Minimum Experiment Duration';                    
        
            % creates the min expt duration button
            pPosDB = [obj.dX*[1,1]/2,obj.widButD,obj.hghtBut];
            obj.hButD = obj.setupPushButton(obj.hPanelD,pPosDB,bStrDD);
            setObjEnable(obj.hButD,'off');

            % creates the popup duration group
            yPosDP = obj.dX + obj.hghtBut;
            obj.hPopupD = obj.setupDurationGroup(...
                obj.hPanelD,[obj.dX/2,yPosDP],obj.widObjD,1,true(1,4));                        
            
            % sets the object user data flags
            obj.setObjUserDataFlags(obj.hPopupD)
            
        end                
        
        % --- initialises the experiment start time panel objects
        function setupExptStartPanel(obj)
            
            % field initialisations
            rStrS = {'Non-Fixed Start Time','Fixed Start Time'};
            
            % creates the date group
            pPosF = obj.dX*[1,1]/2;
            obj.hPopupF = obj.setupDateGroup(...
                obj.hPanelF,pPosF,obj.widPopupF*ones(1,3),2);
            
            % sets the object user data flags
            obj.setObjUserDataFlags(obj.hPopupF)            
            
            % creates the radio button objects
            obj.hRadioS = cell(obj.nObjS,1);
            yPosSR = sum(obj.hPanelF.Position([2,4])) + obj.dX/2;
            for i = 1:obj.nObjS
                % global offset
                j = obj.nObjS - (i-1);

                % radio button creation                
                pPosSR = [obj.dX,yPosSR,obj.widRadioS,obj.hghtRadio];
                obj.hRadioS{j} = obj.setupRadioButton(...
                    obj.hPanelS,pPosSR,rStrS{j});
                
                % increments the vertical offset
                yPosSR = yPosSR + obj.hghtRadio;
            end
            
        end                                        
        
        % --- initialises the stimuli repetition panel objects
        function setupStimRepPanel(obj)
            
            % creates the stimuli parameter tab group
            obj.objR = ExptRepTabGroup(obj);
            
        end        

        % --- initialises the stimuli block panel objects
        function setupStimBlockPanel(obj)
        
            % field initialisations
            bStrB = {'Add Block','Deselect Block',...
                     'Delete Block','Delete All Blocks'};            
            
            % creates the listbox object
            pPosBL = [obj.dX*[1,1]/2,obj.widListB,obj.hghtListB];
            obj.hListB = obj.setupListBox(obj.hPanelB,pPosBL);
            
            % creates the main panel pushbutton objects
            obj.hButB = ...
                obj.setupButtonGrouping(obj.hPanelB,bStrB,obj.widButB,2);
            
        end        
        
        % --- sets the object callback functions
        function setObjectCallbacks(obj)
            
            % ----------------------------------------- %
            % --- EXPERIMENT DURATION PANEL OBJECTS --- %
            % ----------------------------------------- %
            
            % popupmenu group objects
            cellfun(@(x)(set(x,'Callback',@obj.popupExptDur)),obj.hPopupD)
            
            % pushbutton objects
            set(obj.hButD,'Callback',@obj.buttonUseMinDur);
            
            % ------------------------------------------- %
            % --- EXPERIMENT START TIME PANEL OBJECTS --- %
            % ------------------------------------------- %
            
            % button group objects
            set(obj.hPanelS,'SelectionChangedFcn',@obj.panelExptStartTime);
            
            % popupmenu objects
            cellfun(@(x)(set(x,...
                'Callback',@obj.popupExptStart)),obj.hPopupF)            
            
            % ----------------------------------- %
            % --- STIMULI BLOCK PANEL OBJECTS --- %
            % ----------------------------------- %

            % pushbutton objects
            set(obj.hButB{1},'Callback',@obj.buttonAddStimObj)
            set(obj.hButB{2},'Callback',@obj.buttonDeselectStimObj)
            set(obj.hButB{3},'Callback',@obj.buttonDeleteStimObj)
            set(obj.hButB{4},'Callback',@obj.buttonDeleteAllStimObj)                   
            
            % sets the listbox callback function
            obj.hListB.Callback = @obj.listStimBlock;
            
        end        
        
        % -------------------------------------- %
        % --- STIMULI BLOCK OBJECT FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- creates a new stimuli block object
        function createBlockObject(obj)
            
            % creates the train object
            obj.objSM.createBlockObj();
            
            %
            
            
        end
        
        % ----------------------------------------------------- %
        % --- EXPERIMENT DURATION OBJECT CALLBACK FUNCTIONS --- %
        % ----------------------------------------------------- %
        
        % --- minimum duration pushbutton callback function
        function buttonUseMinDur(obj,varargin)
            
            % re-calculates the minimum experiment duration
            tDurMinH = obj.getMinExptDuration('h');
            tDurMin = ceil(convertTime(tDurMinH,'h','s'));
            [obj.iExpt.Timing.Texp,Texp] = deal(sec2vec(tDurMin));
            
            % resets the duration fields
            obj.setDurTimeValues(obj.hPopupD,Texp)
            obj.setDurTimeValues(obj.objT{1}.hPopupD,Texp)
            
            % runs the experiment duration popupmenu callback
            obj.popupExptDur(obj.hPopupD{1});
            
            % disables the button
            setObjEnable(obj.hButD,'off');
            
        end   
        
        % ------------------------------------------------------- %
        % --- EXPERIMENT START TIME OBJECT CALLBACK FUNCTIONS --- %
        % ------------------------------------------------------- %        
        
        % --- experiment start time panel selection callback function
        function panelExptStartTime(obj,varargin)
            
            % field retrieval
            isFixed = obj.hRadioS{2}.Value;
            obj.iExpt.Timing.fixedT0 = isFixed;
            
            % updates the tab properties
            setPanelProps(obj.hPanelF,isFixed);
            obj.objT{1}.hCheckS.Value = isFixed;
            
%           % deselects any selected expt protocol blocks
%             figExptSetup_WindowButtonDownFcn(hFig, [], handles, 'alt')

            % resets the experimental time axis
            obj.objAx.resetAxesTimeProps();

        end        
        
        % --- experiment start time popupmenu callback function
        function popupExptStart(obj,hObj,~)
            
            % field retrieval
            iSel = hObj.UserData;
            [pStr,iVal] = deal(hObj.String,hObj.Value);
            
            % updates the start time (based on selection)
            switch iSel
                case 3
                    % case is the AM/PM selection
                    tHours = mod(obj.iExpt.Timing.T0(4)-1,12) + 1;
                    obj.iExpt.Timing.T0(4) = tHours + 12*(iVal-1);            
            
                otherwise
                    % case is the other popupmenu items
                    obj.iExpt.Timing.T0(iSel+3) = str2double(pStr{iVal});
            end
            
            % updates the information tab fields
            obj.objT{1}.hPopupS{iSel+2}.Value = iVal;
                    
            % resets the experimental time axis
            obj.objAx.resetAxesTimeProps();            
            
        end                    
        
        % ----------------------------------------------- %
        % --- STIMULI BLOCK OBJECT CALLBACK FUNCTIONS --- %
        % ----------------------------------------------- %
        
        % --- delete block pushbutton callback function
        function buttonDeleteStimObj(obj,varargin)
            
            % prompt user 
            tStr = 'Delete Stimuli Block';
            qStr = ['Are you sure you want to delete the currently ',...
                    'selected stimuli block?'];
            uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
            if ~strcmp(uChoice,'Yes')
                % exit if the user cancelled
                return
            end

            % deletes the currently selected stimuli block
            iBlkS = obj.objSM.iSigS;
            
            % de-selectes the object
            feval(obj.hFig.WindowButtonDownFcn,[],[],'alt');
            
            % deletes the block object and removes the information field
            obj.objSM.deleteBlockObj(iBlkS,true);
            obj.removeExptBlockInfo(iBlkS);            
            
            % determines if there are any stimuli objects set
            nTrainEx = length(obj.sTrain);  
            obj.setPanelEnableProps('DeleteBlock',nTrainEx>0,iBlkS);
            
            % updates the main preview axes
            feval(obj.hFig.WindowButtonMotionFcn);             
            
        end
        
        % --- delete all blocks pushbutton callback function
        function buttonDeleteAllStimObj(obj,varargin)
            
            % only prompt user if calling from a button press
            if ~isempty(varargin)
                % prompts the user if they wish to continue
                tStrQ = 'Delete All Stimuli Blocks?';
                qStr = ['Are you sure you want to completely clear ',...
                        'all the stimuli blocks?'];
                uChoice = questdlg(qStr,tStrQ,'Yes','No','Yes');
                if ~strcmp(uChoice,'Yes')
                    % if the user cancelled, then exit the function
                    return
                end
            end            
            
            % de-selects any highlighted stimuli train object
            feval(obj.hFig.WindowButtonDownFcn,[],[],'alt')            
            
            % deletes all stimuli train objects
            obj.objSM.deleteAllBlockObj();            
            
            % button property updates
            obj.setPanelEnableProps('DeleteAllBlock');           
            
        end        
        
        % --- stimuli block listbox callback function
        function listStimBlock(obj,hObj,~)
            
            % field retrieval
            iSelB = hObj.Value;
            sBlkB = obj.objSM.sBlk{iSelB};
            sTrainEx = obj.sTrainP.Ex{iSelB};
            
            % resets the signal block properties
            obj.objSM.setSignalBlockHighlight(sBlkB,'on');
            obj.objSM.updateExptBlockSelection(sBlkB);            
            obj.objSM.objR.resetSelectedBlockPara(sTrainEx);    
            
            % resets the block properties
            obj.setPanelEnableProps('BlockProps',true);
            
        end
        
        % ------------------------------------ %
        % --- CLASS FIELD GETTER FUNCTIONS --- %
        % ------------------------------------ %
        
        
        
        % ------------------------------------ %
        % --- CLASS FIELD GETTER FUNCTIONS --- %
        % ------------------------------------ %        
                    
        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- updates the information for stimuli block object, iBlkS
        function updateExptBlockInfo(obj,sTrainNw,iBlkS,iBlkT,isShort)
                        
            % ensures the stimuli name is correctly set
            hListEx = obj.objR.objT{2-isShort}.hListS;
            if ~strcmp(hListEx.String{iBlkS},sTrainNw.sName)
                hListEx.String{iBlkS} = sTrainNw.sName;                            
            end                        
            
            % determines
            for i = iBlkT(:)'
                % updates the stimuli train fields
                obj.objSM.sBlk{i}.sTrain = sTrainNw;
                obj.sTrain{i}.sTrain = sTrainNw;

                % recalculates/replots the stimuli trains
                obj.objSM.sBlk{i}.resetBlockProps();
                obj.objSM.resetBlockObjLimits(i);
            end
                        
        end
        
        % --- determines if the new update configuration is feasible
        function ok = checkExptBlockUpdate(obj,sTrainNw,iBlkS,isShort)
            
            % field retrieval
            ok = true;
            sName = cellfun(@(x)(x.sName),obj.sTrain,'un',0);
            iChB0 = cellfun(@(x)(x.iChB),obj.objSM.sBlk,'un',0);            
            
            % determines
            hasT = strcmp(sName,sTrainNw.sName);
            if any(hasT)
                % determines the new stimuli train channel indices
                chName = field2cell(sTrainNw.blkInfo,'chName');
                [~,iA] = intersect(sTrainNw.chName,chName);
                iChBNw = sort(iA);                
                
                % resets the block's channel indices
                iBlkT = find(hasT);
                for i = iBlkT(:)'
                    obj.objSM.sBlk{i}.updateChannelIndices(iChBNw);
                end                
                
                % other field retrieval
                tDurEx = obj.objSM.getExptDur();
                sLim = obj.objSM.getBlockObjLimits();
                iChB = cellfun(@(x)(x.iChB),obj.objSM.sBlk,'un',0);
                
                % determines if the new configuration is feasible
                for i = iBlkT(:)'
                    % field retrieval
                    sBlkT = obj.objSM.sBlk{i};
                    okBlk = ~setGroup(i,size(hasT));
                    
                    % calculates the stimuli block end-time
                    tDurBlk = obj.calcExptStimDurFcn(sTrainNw,sBlkT.sPara);
                    tBlkF = sLim(i,1) + tDurBlk;
                    if tBlkF > tDurEx
                        % case is the end time exceeds expt duration
                        ok = false;
                        break
                    end
                    
                    % determines if any other blocks have channels which
                    % match that of the stimuli block
                    iBlkM = cellfun(@(x)(...
                        ~isempty(intersect(sBlkT.iChB,x))),iChB) & okBlk;
                    if any(iBlkM)
                        % if so, 
                        dsLimF = sLim(iBlkM,1) - tBlkF;
                        dsLimS = sLim(i,1) - sLim(iBlkM,2);
                        ok = all((dsLimF > 0) | (dsLimS > 0));
                    end                    
                    
                end
            end
            
            % updates the program based on feasibility
            if ok
                % if feasible, then update the stimuli block info
                obj.updateExptBlockInfo(sTrainNw,iBlkS,iBlkT,isShort);
            else
                % otherwise, output an error message to screen
                obj.showError('Infeasble Stimuli Train');
            end
            
        end
        
        % --- appends the experimental block information to class storage
        function appendExptBlockInfo(obj,sParaExNew,sTrain)
            
            % memory allocation
            sTrainEx = struct('sName',[],'sType',[],...
                              'sParaEx',[],'sTrain',[]);
            
            % sets the block information data struct
            sTrainEx.sName = sTrain.sName;
            sTrainEx.sType = obj.objSM.objR.tStr{obj.objSM.objR.iTab};
            sTrainEx.sParaEx = sParaExNew;
            sTrainEx.sTrain = sTrain;
            
            % appends the field to the stimuli train field
            obj.sTrain{end+1} = sTrainEx;
            
        end
        
        % --- removes the experiment block informaton from class storage
        function removeExptBlockInfo(obj,iTrain)
            
            obj.sTrain = obj.sTrain((1:length(obj.sTrain)) ~= iTrain);
            
        end
        
        % --- updates the experimental protocol tab properties
        function addExptBlockObj(obj)
            
            % updates the listbox 
            idBlkID = cellfun(@(x)(x.idBlk),obj.objSM.sBlk(:));
            sName = arrayfun(@(x)(sprintf('Block #%i',x)),idBlkID,'un',0);
            [iSel,hMax,eState] = deal(length(sName),1,'on');
                            
            % updates the listbox properties
            setObjEnable(obj.hListB,eState);
            set(obj.hListB,'String',sName(:),'Value',iSel,'Max',hMax)
            
            % updates the other object properties
            obj.setPanelEnableProps('BlockProps',1,1);
            
        end
        
        % --- updates the stimuli train information
        function updateStimTrainInfo(obj,sNameNw,iTabEx)
            
            % updates the listbox values
            obj.objR.updateRepParaProps(sNameNw,iTabEx);
                        
            % enables tbe add-block button
            setObjEnable(obj.hButB{1},any(obj.objR.isOn))            
            
        end
        
        % --- removes any stimuli blocks with the stimuli train sNameRmv
        function removeExptBlocks(obj,sNameR)
            
            % if there are no blocks then exit
            if obj.objSM.nObj == 0
                return
            end
            
            % determines if there 
            sNameB = cellfun(@(x)(x.sTrain.sName),obj.objSM.sBlk,'un',0);
            iBlkS = find(strcmp(sNameB,sNameR));
            if isempty(iBlkS)
                % if there are no matches, then exit
                return
            end                      
            
            % deletes the block object and removes the information field
            for i = flip(iBlkS(:)')
                obj.objSM.deleteBlockObj(i,true);
                obj.removeExptBlockInfo(i);
            end
            
            % determines if there are any stimuli objects set
            nTrainEx = length(obj.sTrain);  
            obj.setPanelEnableProps('DeleteBlock',nTrainEx>0,iBlkS);    
            
            % updates the main preview axes
            feval(obj.hFig.WindowButtonMotionFcn);            
            
        end
        
        % --- calculates the global axes coordinates
        function calcAxesGlobalCoords(obj)
            
            % retrieves the global axes position vector
            pPosAxG = getpixelposition(obj.hAx,true);
            
            % calculates the global axes x/y limits
            obj.axPosX = pPosAxG(1) + [0,pPosAxG(3)];
            obj.axPosY = pPosAxG(2) + [0,pPosAxG(4)];
            
        end
        
        % --- clears the stimuli train data field
        function clearStimTrain(obj)
            
            obj.sTrain = [];
            
        end   
        
        % --- removes the stimuli object selection
        function removeStimObjSelect(obj)
            
            
            
        end                         
        
        % --- info tab fixed start time checkbox callback function
        function checkFixStart(obj,isFixed)
           
            % updates the radio button properties
            obj.hRadioS{1}.Value = ~isFixed;
            obj.hRadioS{2}.Value = isFixed;
            
            % runs the panel selection callback function
            obj.panelExptStartTime();
            
        end
        
        % --- updates the minimum duration button properties
        function updateMinDurButtonProps(obj)
            
            % field retrieval
            tDurEx = obj.objSM.getExptDur();            
            tLimBlk = obj.objSM.getBlockObjLimits();
            
            % sets fin
            if isempty(tLimBlk); tLimBlk = 0; end
            
            % updates the button properties
            useMinDur = (tLimBlk(end) < tDurEx);
            setObjEnable(obj.hButD,useMinDur);
            
        end             
        
    end    
    
end