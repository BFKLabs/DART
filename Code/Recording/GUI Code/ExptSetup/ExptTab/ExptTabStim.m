classdef ExptTabStim < ExptTab
    
    % class properties
    properties
        
        % sub-class objects
        objC
        
        % stimuli parameter panel objects
        hPanelP
        hPopupP
        hEditP
        hButP
        
        % stimuli signal panel objects
        hPanelS
        hButS      
        
        % stimuli channel panel objects
        hPanelC
        hButC
        
        % stimuli train panel objects
        hPanelT
        hListT
        hButT   
        hButTT
        objTM
        
        % fixed object dimensions
        hghtListT0 = 145;
        widTxtPN = 90;
        widPopupPS = 32;         
        xPopupPS = 141;        
        
        % calculated object dimensions
        hghtPanelP
        hghtPanelS
        hghtPanelC
        hghtPanelT
        widPanelI                
        widEditPN
        widTxtPS
        widEditPS
        widObjF
        widObjH
        hghtTabGrpP
        hghtListT      
        
        % function handle class fields
        addCustomTab        
        
        % stimuli parameter class fields
        sName    
        
        % boolean class fields
        isShort        
        
        % numerical class fields
        nCol = 2;        
        
        % static string fields
        tStr = {'Long','Short'};
        
    end        
        
    % class methods
    methods
        
        % --- class constructor
        function obj = ExptTabStim(objB,hTab,iType)
            
            % creates the super-class object
            obj@ExptTab(objB,hTab,iType);               
            
            % input arguments
            obj.isShort = iType == 2;
            
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
            sufStr = obj.tStr{1+obj.isShort}(1);
            obj.tagStr = sprintf('hTimerStimTab%s',sufStr);
            obj.clearPrevTimers(obj.tagStr);            
            
            % timer object
            obj.hTimer = timer(...
                'StartDelay',1 - obj.isShort*0.5,...
                'TimerFcn',@obj.initClassObjects,...
                'Tag',obj.tagStr);             
           
            % duration specific initialisations
            if obj.isShort
                % case is a short-term stimuli
                [prStr,obj.tDurTotU] = deal('Short','s');
                
            else
                % case is a long-term stimuli
                [prStr,obj.tDurTotU] = deal('Long','h');
            end
            
            % other parameter field initialisations
            obj.tDurTot = 1 + 9*obj.isShort;
            obj.sName = sprintf('%s-Term Signal #1',prStr);            
            
            % ------------------------------------------- %
            % --- CLASS OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------------- %

            % object pre-calculations
            obj.hghtListT = obj.hghtListT0 - 3*obj.isShort*obj.dX;            
            
            % panel dimension calculations
            obj.hghtPanelC = obj.dX + obj.hghtBut;            
            obj.hghtPanelS = obj.hghtPanelC + obj.hghtBut;
            obj.hghtPanelT = obj.hghtListT0 + 1.5*obj.dX + 2*obj.hghtBut;            
            obj.hghtPanelP = obj.hghtPanel - (2.5*obj.dX + ...
                obj.hghtPanelC + obj.hghtPanelS + obj.hghtPanelT);
            obj.widPanelI = obj.widPanel - obj.dX;

            % other object dimensions calculations
            obj.widEditPN = obj.widPanelI - (1.5*obj.dX + obj.widTxtPN);             
            obj.widObjF = obj.widPanelI - obj.dX;
            obj.widObjH = obj.widObjF/2; 
            obj.hghtTabGrpP = obj.hghtPanelP - 4*(obj.dX/2 + obj.hghtBut);            
            obj.widEditPS = 95 + obj.isShort*25;
            obj.widTxtPS = obj.widPanelI - (1.5*obj.dX + obj.widEditPS);
            
        end
        
        % --- initialises the class objects
        function initClassObjects(obj,varargin)
        
            % --------------------------- %
            % --- STIMULI TRAIN PANEL --- %
            % --------------------------- %

            % panel object
            pPosT = [obj.dX*[1,1]/2,obj.widPanelI,obj.hghtPanelT];
            obj.hPanelT = obj.setupHeadlessPanel(obj.hPanel,pPosT);

            % initialises the stimuli train panel objects
            obj.setupStimTrainPanel()               
            
            % --------------------------- %
            % --- CLEAR CHANNEL PANEL --- %
            % --------------------------- %
            
            % panel object
            yPosC = sum(pPosT([2,4])) + obj.dX/2;
            pPosC = [obj.dX/2,yPosC,obj.widPanelI,obj.hghtPanelC];
            obj.hPanelC = obj.setupHeadlessPanel(obj.hPanel,pPosC);
            
            % initialises the stimuli channel panel objects
            obj.setupStimChannelPanel()
            
            % ------------------------------ %
            % --- SIGNAL OPERATION PANEL --- %
            % ------------------------------ %
            
            % panel object
            yPosS = sum(pPosC([2,4])) + obj.dX/2;
            pPosS = [obj.dX/2,yPosS,obj.widPanelI,obj.hghtPanelS];
            obj.hPanelS = obj.setupHeadlessPanel(obj.hPanel,pPosS);
            
            % initialises the stimuli signal panel objects
            obj.setupStimSignalPanel()            
            
            % ------------------------------ %
            % --- SIGNAL PARAMETER PANEL --- %
            % ------------------------------ %
            
            % panel object
            yPosP = sum(pPosS([2,4])) + obj.dX/2;
            pPosP = [obj.dX/2,yPosP,obj.widPanelI,obj.hghtPanelP];
            obj.hPanelP = obj.setupHeadlessPanel(obj.hPanel,pPosP);            
            
            % initialises the signal parameter panel objects
            obj.setupSignalParaPanel()
            
            % ----------------------- %
            % --- PLOT AXES PANEL --- %
            % ----------------------- %
            
            % creates the stimuli protocol axes object
            obj.objAx = ExptAxesStim(obj);

            % creates the test marker (short-term stimuli only)
            if obj.isShort
                obj.objTM = TestMarker(obj);                            
            end     
                        
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %            
            
            % sets the object callback functions/properties
            obj.setObjectCallbacks()
            obj.initObjectProps();
            
            % other house-keeping exercises
            deleteTimerObjects(obj.hTimer);
            obj.isInit = true;               
            
%             % checks all tabs have been initialised
%             obj.dialogInitCheck();            
            
        end                     

        % --- initialises the object properties
        function initObjectProps(obj)

            % --------------------------------------- %
            % --- STIMULI PARAMETER PANEL OBJECTS --- %
            % --------------------------------------- %            

            % main editbox fields
            obj.hEditP{1}.String = obj.sName;
            obj.hEditP{2}.String = num2str(obj.tDurTot);
            
            % signal units popupmenu fields
            if ~obj.isShort
                setParaObjValue(obj,obj.hPopupP);
            end
            
            % ------------------------------------ %
            % --- STIMULI SIGNAL PANEL OBJECTS --- %
            % ------------------------------------ %

            if obj.isInit
                % case is loading an experimental protocol
                
            else
                % case is figure creation

                % disables the non-add signal pushbuttons
                cellfun(@(x)(setObjEnable(x,0)),obj.hButS(2:end));
            end
            
            % -------------------=----------------- %
            % --- STIMULI CHANNEL PANEL OBJECTS --- %
            % --------------------=---------------- %
            
            if obj.isInit
                % case is loading an experimental protocol
                
            else
                % case is figure creation 
                
                % disables the panel properties
                setPanelProps(obj.hPanelC,0)
            end
            
            % ----------------------------------- %
            % --- STIMULI TRAIN PANEL OBJECTS --- %
            % ----------------------------------- %            
            
            if obj.isInit
                % case is loading an experimental protocol
                
            else
                % case is figure creation 
                
                % disables the panel properties
                setPanelProps(obj.hPanelT,0)
            end
            
        end        
        
        % --- resets the object properties
        function resetObjectProps(obj,~,~,sTrainT)
            
            % field retrieval
            obj.sTrain = sTrainT.(obj.tStr{1+obj.isShort}(1));            
            obj.updateExptTabFcn();
            
            % other common property updates
            set(obj.hListT,'String',[],'Max',2,'Value',[]);            
            
            % determines if there are any stored stimuli trains
            if isempty(obj.sTrain)
                % case is no stimuli train is set
                
                % resets the name string
                tStrT = obj.tStr{1+obj.isShort};                
                [obj.tDurTot,obj.tDurTotU] = deal(1,'h');
                obj.sName = sprintf('%s-Term Stimuli #1',tStrT);
                
                % deletes all stimuli train objects
                obj.initObjectProps();
                obj.buttonClearAll();
                
                % re-enables the tab object
                obj.jTabGrpS.setEnabledAt(obj.iType-1,1)
                
                % exits the function
                return
            end
            
            % resets the axes limits
            obj.sName = obj.sTrain{1}.sName;
            obj.tDurTot = obj.sTrain{1}.tDur;
            obj.tDurTotU = obj.sTrain{1}.tDurU;
            obj.objAx.resetTotalDuration();                        
            
            % signal units popupmenu fields
            if ~obj.isShort
                setParaObjValue(obj,obj.hPopupP);
            end                                    
            
            % resets the listbox properties
            sNameT = cellfun(@(x)(x.sName),obj.sTrain,'un',0);
            set(obj.hListT,'String',sNameT(:),'Max',1,'Value',1);
            
            % other listbox property updates
            obj.setPanelEnableProps('ListTrain',1);            
            
            % resets the stimuli train 
            obj.objSM.resetStimuliTrain(obj.sTrain{1});  
            obj.listStimTrain();
            
            % updates the expt information/protocol properties
            obj.objT{1}.setFeasFlag('StimProto',1,0)            
            obj.objT{4}.updateStimTrainInfo(sNameT(:),2-obj.isShort);            
            
            % sets the minimum duration button properties
            obj.updateMinDurButtonProps();            
            
            % other house-keeping exercises
            deleteTimerObjects(obj.hTimer);            
            obj.jTabGrpS.setEnabledAt(obj.iType-1,1)
            
        end            
        
        % --------------------------------------- %
        % --- PANEL OBJECT CREATION FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- initialises the signal parameter panel objects
        function setupSignalParaPanel(obj)
            
            % field initialisations
            tStrPN = 'Stimuli Name';
            bStrPM = 'Use Minimum Signal Duration';
            bStrPR = 'Restore Default Parameters';
            yPosP = obj.hPanelP.Position(4) - (obj.dX/2 + obj.hghtRow);            
                                    
            % memory allocation
            [obj.hButP,obj.hEditP] = deal(cell(2,1));
            tStrPD = sprintf('Total Train Duration (%s)',obj.getDurStr());            
            
            % creates the stimuli name 
            ePosPN = [obj.dX/2,yPosP];
            obj.hEditP{1} = obj.setupEditGroup(...
                obj.hPanelP,ePosPN,tStrPN,[obj.widTxtPN,obj.widEditPN]);
            
            % creates the stimuli name 
            yPosP = yPosP - obj.hghtRow;
            ePosPD = [obj.dX/2,yPosP];
            obj.hEditP{2} = obj.setupEditGroup(...
                obj.hPanelP,ePosPD,tStrPD,[obj.widTxtPS,obj.widEditPS]);
            
            % creates the duration popup-menu (long-term stimuli only)
            if ~obj.isShort
                pStr = {'m','h'};
                pPosPD = [obj.xPopupPS,yPosP,obj.widPopupPS,obj.hghtPopup];
                obj.hPopupP = obj.setupPopupMenu(obj.hPanelP,pPosPD,pStr); 
                obj.hPopupP.UserData = 'tDurTotU';
            end
            
            % creates the stimuli name 
            yPosP = yPosP - (obj.hghtRow + obj.dX/2);
            bPosPM = [obj.dX/2,yPosP,obj.widObjF,obj.hghtBut];
            obj.hButP{1} = obj.setupPushButton(obj.hPanelP,bPosPM,bStrPM);
            
            % creates the default parameters button
            bPosPR = [obj.dX*[1,1]/2,obj.widObjF,obj.hghtBut];
            obj.hButP{2} = obj.setupPushButton(obj.hPanelP,bPosPR,bStrPR);            
        
            % creates the stimuli parameter tab group
            cellfun(@(h)(setObjEnable(h,'off')),obj.hButP);
            obj.objP = ExptParaTabGroup(obj);
            
        end       
           
        % --- initialises the signal operation panel objects
        function setupStimSignalPanel(obj)

            % field initialisations
            bStrS = {'Add Signal','Deselect Signal',...
                     'Copy Signal','Delete Signal'};            

            % creates the button objects
            obj.hButS = ...
                obj.setupButtonGrouping(obj.hPanelS,bStrS,obj.widObjH,2);
            
        end        
        
        % --- initialises the stimuli channel panel objects
        function setupStimChannelPanel(obj)
        
            % field initialisations
            bStrC = {'Clear Channel','Clear All Signals'};
        
            % creates the button objects
            obj.hButC = ...
                obj.setupButtonGrouping(obj.hPanelC,bStrC,obj.widObjH,2);            
                                    
        end           
        
        % --- initialises the stimuli train panel objects
        function setupStimTrainPanel(obj)
        
            % field initialisations
            yPosTL = obj.dX/2;        
            bStrTT = 'Test Stimuli Train';
            bStrT = {'Save New Train','Update Train',...
                     'Repeat Train','Delete Train'};
            
            % test stimuli button object creation (short-term only)
            if obj.isShort
                % creates the button object
                pPosTB = [obj.dX*[1,1]/2,obj.widObjF,obj.hghtBut];
                obj.hButTT = obj.setupPushButton(obj.hPanelT,pPosTB,bStrTT);                

                % sets the vertical offset
                yPosTL = obj.dX + obj.hghtRow;                
            end
            
            % creates the listbox object
            pPosTL = [obj.dX/2,yPosTL,obj.widObjF,obj.hghtListT];
            obj.hListT = obj.setupListBox(obj.hPanelT,pPosTL);
            
            % creates the main panel pushbutton objects
            obj.hButT = ...
                obj.setupButtonGrouping(obj.hPanelT,bStrT,obj.widObjH,2);
            
        end        
        
        % --- sets the object callback functions
        function setObjectCallbacks(obj)

            % --------------------------------------- %
            % --- STIMULI PARAMETER PANEL OBJECTS --- %
            % --------------------------------------- %
            
            % editbox objects
            set(obj.hEditP{1},'Callback',@obj.editStimName);
            set(obj.hEditP{2},'Callback',@obj.editTotalDur);

            % pushbutton objects
            set(obj.hButP{1},'Callback',@obj.buttonUseMinDur);
            set(obj.hButP{2},'Callback',@obj.buttonRestoreDefPara);

            % long-term stimuli only objects
            if ~obj.isShort
                set(obj.hPopupP,'Callback',@obj.popupTotalDurUnits);
            end
            
            % ------------------------------------ %
            % --- STIMULI SIGNAL PANEL OBJECTS --- %
            % ------------------------------------ %

            % pushbutton objects
            set(obj.hButS{1},'Callback',@obj.buttonAddStimObj)
            set(obj.hButS{2},'Callback',@obj.buttonDeselectStimObj)
            set(obj.hButS{3},'Callback',@obj.buttonCopyStimObj)
            set(obj.hButS{4},'Callback',@obj.buttonDeleteStimObj)
            
            % -------------------=----------------- %
            % --- STIMULI CHANNEL PANEL OBJECTS --- %
            % --------------------=---------------- %
            
            % pushbutton objects
            set(obj.hButC{1},'Callback',@obj.buttonClearChannel)
            set(obj.hButC{2},'Callback',@obj.buttonClearAll)
            
            % ----------------------------------- %
            % --- STIMULI TRAIN PANEL OBJECTS --- %
            % ----------------------------------- %
           
            % pushbutton objects
            set(obj.hButT{1},'Callback',@obj.buttonSaveTrain)
            set(obj.hButT{2},'Callback',@obj.buttonUpdateTrain)
            set(obj.hButT{3},'Callback',@obj.buttonRepeatTrain)
            set(obj.hButT{4},'Callback',@obj.buttonDeleteTrain)
            
            % sets the listbox callback function
            obj.hListT.Callback = @obj.listStimTrain;
            
            % stimuli test button properties (short-term stimuli only)
            if obj.isShort
                obj.hButTT.Callback = @obj.buttonTestTrain;
            end
            
        end      

        % -------------------------------------- %
        % --- STIMULI TRAIN OBJECT FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- creates a new stimuli train object
        function createTrainObject(obj)
            
            % creates the train object
            obj.objSM.createTrainObj();
            
            % enables the clear all/save train buttons
            setObjEnable(obj.hButC{2},'on')
            setObjEnable(obj.hButT{1},'on')
            
            % sets the minimum duration button properties
            obj.updateMinDurButtonProps();
            
            % enables the stimuli train test (short-term protocol only)
            if obj.isShort
                setObjEnable(obj.hButTT,'on')
            end                         
            
        end
        
        % -------------------------------------------- %
        % --- STIMULI PARAMETER CALLBACK FUNCTIONS --- %
        % -------------------------------------------- %
        
        % --- stimuli name editbox callback function
        function editStimName(obj,hObj,~)
            
            % updates the stimuli name field
            obj.sName = hObj.String;
            
        end        
        
        % --- stimuli total duration editbox callback function
        function editTotalDur(obj,varargin)
            
            % field retrieval
            nwVal = str2double(obj.hEditP{2}.String);
            nwLim = [obj.objSM.getOverallStimDur(),obj.objAx.axLimMax];
            
            % determines if the new value is valid
            if chkEditValue(nwVal,nwLim,0)
                % updates the total duration field (editbox callback)
                if ~isempty(varargin)
                    obj.tDurTot = nwVal;
                end
                
                % other object property updates
                setObjEnable(obj.hButP{2},obj.tDurTot ~= nwLim(1));
                
            else
                % otherwise, reset to the last valid value
                obj.hEditP{2}.String = num2str(obj.tDurTot);
            end
            
        end        
        
        % --- stimuli total duration units popupmenu callback function
        function popupTotalDurUnits(obj,hObj,~)
            
            % retrieves the corresponding parameter values
            pStr = hObj.UserData;
            [pDur0,pUnit0] = deal(obj.(pStr(1:end-1)),obj.(pStr));
            
            % calculates the time multiplier between time units
            pUnitNw = hObj.String{hObj.Value};
            tMltDur = getTimeMultiplier(pUnitNw,pUnit0);
            pDur = pDur0*tMltDur; 
            
            % class field update
            obj.(pStr) = pUnitNw;
            obj.(pStr(1:end-1)) = pDur;  
            
            % resets the time-dependent components of the stimuli objects
            for iCh = 1:length(obj.objSM.objS)
                % channel object retrieval
                objSC = obj.objSM.objS{iCh};
                if objSC.nObj == 0
                    % if no stimuli objects then continue
                    continue
                end
                                
                % resets the time dependent parameters
                obj.objSM.iChH = iCh;                
                for iBlk = 1:objSC.nObj
                    % block handle retrieval
                    sBlkNw = objSC.sBlk{iBlk};
    
                    % updates the stimuli block fields
                    sBlkNw.sPara.(pStr) = pUnitNw;                    
                    sBlkNw.alterTrainPara(sBlkNw.sPara,{'tOfs','tDur'});
                end
                
                % resets the stimuli object limits
                obj.objSM.objS{iCh}.resetTrainObjLimits();
            end
            
            % updates the other class objects
            obj.hEditP{2}.String = num2str(pDur);            
            
            % resets the axes zoom
            zoom(obj.hFig,'reset');            
            
        end        
        
        % --- minimum duration pushbutton callback function
        function buttonUseMinDur(obj,varargin)
            
            % retrieves the minimum stimuli duration
            if ~isempty(varargin)
                % case is running from the button callback
                tDurMin = obj.objSM.getOverallStimDur();
                if isnan(tDurMin)
                    setObjEnable(obj.hButP{1},'off');
                    return
                else
                    obj.tDurTot = tDurMin;
                end
            else
                % case is running the function directly
                tDurMin = obj.tDurTot;
            end
            
            % updates the duration editbox string
            obj.hEditP{2}.String = num2str(tDurMin);
            obj.editTotalDur();
            
        end
        
        % --- minimum duration pushbutton callback function
        function buttonRestoreDefPara(obj,varargin)
            
            % prompts the user if they want to reset the parameters
            tStrQ = 'Reset Parameters?';
            qStr = ['Are you sure you want to reset parameters to ',...
                    'their default values?'];
            uChoice = questdlg(qStr,tStrQ,'Yes','No','Yes');
            if ~strcmp(uChoice,'Yes')
                % if the user cancelled, then exit the function
                return
            end            
            
            % updates the stimuli parameter block
            sBlkS = obj.objSM.getSelectedTrain();
            if isempty(sBlkS)
                % resets the default paramters
                obj.objP.resetDefPara();                
                
            else
                % retrieves the default parameters (ignore time offsets)
                sPara0 = obj.objSM.objP.getDefParaStruct();
                sPara0.tOfs = sBlkS.sPara.tOfs;
                sPara0.tOfsU = sBlkS.sPara.tOfsU;
                
                % resets the default parameters
                obj.objP.resetSelectedTrainPara(sPara0);
                sBlkS.alterTrainPara(sPara0);
                obj.objSM.resetSelectedObjLimits();                
            end
            
            % disables the button
            setObjEnable(obj.hButP{2},0);
            
        end                
        
        % ------------------------------------------------ %
        % --- STIMULI SIGNAL OBJECT CALLBACK FUNCTIONS --- %
        % ------------------------------------------------ %
        
        % --- copy signal pushbutton callback function
        function buttonCopyStimObj(obj,varargin)
            
            % field retrieval
            [iChS,iBlkS] = deal(obj.objSM.iSigS(1),obj.objSM.iSigS(2));
            chName = flip(obj.chInfo(:,2));
            sBlkS = obj.objSM.getSelectedTrain();
            
            % channel/block ignore binary masks
            BignCh = setGroup(iChS,size(chName));
            BignBlk = setGroup(iBlkS,size(obj.objSM.objS{iChS}.sBlk));            
            
            % determines if it is feasible to copy within channels
            tLim = obj.objSM.objS{iChS}.getTrainObjLimits;           
            if (iBlkS == length(BignBlk))
                tFeas = obj.tDurTot - tLim(iBlkS,2);                
            else
                tFeas = tLim(iBlkS+1,1) - tLim(iBlkS,2);
            end
            
            % retrieves the other channel blocks
            sBlkT = cellfun(@(x)(x.sBlk(:)),obj.objSM.objS,'un',0);
            sBlkT = cell2cell(sBlkT(~BignCh));            
            
            % determines if there are any overlapping blocks
            if ~isempty(sBlkT)
                rPosT = cell2mat(cellfun(...
                    @(x)(x.rPos(1)+[0,x.rPos(3)]),sBlkT,'un',0));
                isOL = ~((rPosT(:,2) < sBlkS.rPos(1)) | ...
                         (rPosT(:,1) > sum(sBlkS.rPos([1,3]))));
                
                % if so, then ignore the corresponding channels
                if any(isOL)
                    BignCh(cellfun(@(x)(x.iCh),sBlkT(isOL))) = true;
                end                
            end            
            
            % determines the indices of the non-selected channels
            iChC = find(~BignCh);
            
            % determines the indices of the channels to copy
            objCS = CopySignal(iChC,chName,sBlkS,tFeas,obj.tDurTotU);
            if ~objCS.isCopy
                % if the user cancelled, then exit the function
                return
                
            elseif objCS.isWCopy
                % case is copying within a channel
                
                % field retrieval
                sParaS = sBlkS.sPara;
                tOfs0 = sParaS.tOfs;
                dtOfs = objCS.tOfs + sParaS.tDur*objCS.tMltOfs;
                
                % creates the train objects
                for iObj = 1:objCS.nCount
                    % field update                    
                    isReset = iObj == objCS.nCount;
                    sParaS.tOfs = tOfs0 + iObj*dtOfs;
                    
                    % creates the new stimuli train object
                    obj.objSM.objS{iChS}.createTrainObj(sParaS,isReset);
                end
                
            else
                % case is copying between channels
                
                % field retrieval
                sParaS = sBlkS.sPara;
                iChH0 = obj.objSM.iChH;
                
                % copies the signal between channels
                for iChC = objCS.iChCopy(:)'
                    % field update
                    obj.objSM.iChH = iChC;
                    obj.objSM.objS{iChC}.createTrainObj(sParaS,true);
                end
                
                % resets the channel flag
                obj.objSM.iChH = iChH0;
                
            end
            
        end
        
        % --- delete signal pushbutton callback function
        function buttonDeleteStimObj(obj,varargin)
            
            % prompts the user if they want to delete the stimuli object
            tStrQ = 'Delete Stimuli Object?';
            qStr = ['Are you sure you want to delete the currently ',...
                    'selected stimuli object?'];
            uChoice = questdlg(qStr,tStrQ,'Yes','No','Yes');
            if ~strcmp(uChoice,'Yes')
                % exit if the user cancelled
                return
            end
            
            % retrieves the stimuli block
            [iChS,iBlkS] = deal(obj.objSM.iSigS(1),obj.objSM.iSigS(2));
            obj.objSM.objS{iChS}.deleteStimObj(iBlkS,true);
            
            % de-selectes the object
            feval(obj.hFig.WindowButtonDownFcn,[],[],'alt');
            obj.objSM.setFillVisibility('off');

            % determines if there are any stimuli objects set
            hasStim = obj.objSM.getTotalStimCount() > 0;  
            obj.setPanelEnableProps('DeleteTrain',hasStim);
            
            % updates the main preview axes
            feval(obj.hFig.WindowButtonMotionFcn);            
            
        end     
        
        % ------------------------------------------------ %
        % --- SIGNAL CHANNEL OBJECT CALLBACK FUNCTIONS --- %
        % ------------------------------------------------ %
        
        % --- clear channel pushbutton callback function
        function buttonClearChannel(obj,hObj,~)
            
            % prompts the user if they want to delete the stimuli object
            tStrQ = 'Delete Channel Stimuli Object?';
            qStr = ['Are you sure you want to delete all ',...
                    'objects from the selected channel?'];
            uChoice = questdlg(qStr,tStrQ,'Yes','No','Yes');
            if ~strcmp(uChoice,'Yes')
                % exit if the user cancelled
                return
            end   
            
            % retrieves the stimuli block
            iChS = obj.objSM.iSigS(1);
            
            % de-selectes the object
            feval(obj.hFig.WindowButtonDownFcn,[],[],'alt');
                            
            % deletes all stimuli objects within the channel
            obj.objSM.objS{iChS}.deleteChannelStimObj();
            
            % determines if there are any stimuli objects set
            hasStim = obj.objSM.getTotalStimCount() > 0;  
            obj.setPanelEnableProps('ClearChannel',hasStim);
            
            % other property updates
            setObjEnable(hObj,0);
            
        end        
        
        % --- clear all signals pushbutton callback function
        function buttonClearAll(obj,varargin)
            
            % only prompt user if calling from a button press
            if ~isempty(varargin)
                % prompts the user if they wish to continue
                tStrQ = 'Clear All Stimuli?';
                qStr = ['Are you sure you want to completely clear ',...
                        'the current stimuli train configuration?'];
                uChoice = questdlg(qStr,tStrQ,'Yes','No','Yes');
                if ~strcmp(uChoice,'Yes')
                    % if the user cancelled, then exit the function
                    return
                end
            end
            
            % de-selects any highlighted stimuli train object
            feval(obj.hFig.WindowButtonDownFcn,[],[],'alt')
            obj.objSM.setFillVisibility('off');
            
            % deletes all stimuli train objects
            obj.objSM.deleteAllTrainObj();
            
            % button property updates
            obj.setPanelEnableProps('DeleteAllTrain');
                        
            % removes all entries from the parameter train listbox
            if ~isempty(varargin)
                set(obj.hListT,'Enable','on','Max',2,'Value',[]);
            end                   
            
        end        
        
        % ----------------------------------------------- %
        % --- STIMULI TRAIN OBJECT CALLBACK FUNCTIONS --- %
        % ----------------------------------------------- %
        
        % --- save train pushbutton callback function
        function buttonSaveTrain(obj,varargin)
            
            % field retrieval
            sTrainNw = obj.objSM.getStimTrainInfo();
            
            if isempty(obj.hListT.String)
                % case is there are no trains stored
                sNameNw = {sTrainNw.sName};
                
            else
                % otherwise, determine if the train name is unique
                sNamePr = obj.hListT.String;
                if any(strcmp(sNamePr,sTrainNw.sName))
                    % if there is a duplicate name, then output an error
                    tStrE = 'Duplicate Train Names';
                    eStr = ['Stimuli train name already exists! ',...
                            'Re-enter a unique name before attempting ',...
                            'to add the stimuli train to the stored list.'];
                    waitfor(msgbox(eStr,tStrE,'modal'))
                        
                    % exits the function
                    return
                else
                    % otherwise, append the name to the list
                    sNameNw = [sNamePr(:);sTrainNw.sName];
                end
            end
                
            % appends the stimuli train information to the class field
            obj.sTrain{end+1} = sTrainNw;  
            obj.updateExptTabFcn();                        
            
            % other object property updates
            set(obj.hListT,'String',sNameNw,...
                'Max',1,'Value',length(sNameNw),'Enable','on');            
            obj.setPanelEnableProps('SaveTrain',true);

            % updates the expt protocol tab stimuli train information 
            obj.objT{4}.updateStimTrainInfo(sNameNw,obj.iType-1);
            
            % updates the stimuli protocol flag
            obj.objB.setFeasFlag('StimProto',true);                     
            
        end        
        
        % --- update train pushbutton callback function
        function buttonUpdateTrain(obj,varargin)
            
            % field retrieval
            objEx = obj.objT{4};
            iSelS = obj.hListT.Value;
            sTrainNw = obj.objSM.getStimTrainInfo();             
            
            % determines if the new stimuli train is feasible
            if objEx.checkExptBlockUpdate(sTrainNw,iSelS,obj.isShort)            
                % resets the train class field
                obj.sTrain{iSelS} = sTrainNw;
                obj.hListT.String{iSelS} = sTrainNw.sName;          
            end            
            
        end
        
        % --- repeat train pushbutton callback function
        function buttonRepeatTrain(obj,hObj,~)
            
            
            
        end
        
        % --- delete train pushbutton callback function
        function buttonDeleteTrain(obj,varargin)
            
            % prompts the user if they want to delete the stimuli object
            tStrQ = 'Delete Stimuli Train?';
            qStr = ['Are you sure you want to delete the currently ',...
                    'selected stimuli train?'];
            uChoice = questdlg(qStr,tStrQ,'Yes','No','Yes');
            if ~strcmp(uChoice,'Yes')
                % exit if the user cancelled
                return
            end
            
            % field retrieval
            iSelD = obj.hListT.Value;
            lStrT = obj.hListT.String;
            
            % resets the listbox selection
            indT = (1:length(obj.sTrain)) ~= iSelD;            
            set(obj.hListT,'String',lStrT(indT),'Max',2,'Value',[]);
            
            % updates the expt protocol tab stimuli train information
            obj.objT{4}.removeExptBlocks(lStrT{iSelD});
            obj.objT{4}.updateStimTrainInfo(lStrT(indT),obj.iType-1)            
            
            % clears all stimuli objects
            obj.buttonClearAll()                                    
            
            % removes the stimuli train object
            obj.sTrain = obj.sTrain(indT);             
            obj.updateExptTabFcn();
            
            % updates the stimuli protocol flag
            hasTrain = obj.objB.getTotalTrainCount() > 0;
            obj.objB.setFeasFlag('StimProto',hasTrain);            
            
            % property object update (if no valid trains left)
            if ~any(indT)
                
            end                       
            
        end
        
        % --- stimuli train listbox callback function
        function listStimTrain(obj,varargin)
            
            % field retrieval
            iSelS = obj.hListT.Value;
            sTrainS = obj.sTrain{iSelS};
            
            % removes any selections
            feval(obj.hFig.WindowButtonDownFcn,[],[],'alt');
            obj.objSM.setFillVisibility('off')
            
            % ensures the stimuli duration meets minimum requirements
            tDurMin = obj.objSM.getMinTrainDuration(sTrainS);
            if tDurMin > obj.tDurTot
                obj.tDurTot = tDurMin;
                feval(obj.hButP{1}.Callback);
                pause(0.05);
            end
            
            % resets the stimuli train
            obj.objSM.resetStimuliTrain(sTrainS);
            
            % resets the stimuli property object fields
            obj.hEditP{1}.String = sTrainS.sName;
            obj.hEditP{2}.String = num2str(sTrainS.tDur);
            
            % long-term stimuli property updates
            if ~obj.isShort
                obj.hPopupP.Value = 1 + strcmp(sTrainS.tDurU,'h');
            end
            
            % resets the parameter fields
            obj.objP.resetSelectedTrainPara(sTrainS.blkInfo(1).sPara);
            
            % resets the axis limits
            [obj.tDurTot,obj.tDurTotU] = deal(sTrainS.tDur,sTrainS.tDurU);
            obj.objAx.resetTotalDuration();
            
            % resets the other object properties
            obj.hListT.Max = 1;
            setPanelProps(obj.hPanelT,1);
            obj.setPanelEnableProps('ListTrain',true);
            
        end        
        
        % --- test stimuli train pushbutton callback function
        function buttonTestTrain(obj,varargin)
            
            if startsWith(obj.hButTT.String,'Test')
                % case is starting the test
                obj.hButTT.String = 'Stop Stimuli Test';
                
            else
                % case is stopping the stimuli
                obj.hButTT.String = 'Test Stimuli Train';
                pause(0.01);                
                return
            end
            
            % ------------------------- %
            % --- TEST DEVICE SETUP --- %
            % ------------------------- %
            
            % retrieves the current stimuli train information
            sTrainC = obj.objSM.getStimTrainInfo();
            
            % sets up the signals for the devices 
            iStim = obj.infoObj.iStim;
            objDAQ = obj.infoObj.objDAQ; 
            sRate = field2cell(iStim.oPara,'sRate',1);
            xySig = setupDACSignal(sTrainC,obj.chInfo,1./sRate);
            
            % determines the unique device indices
            iDev = find(cellfun(@(x)(...
                ~all(cellfun('isempty',x(:,1)))),xySig));
            
            % determines if the serial
            if ~obj.infoObj.isTest
                if any(strcmp(objDAQ.dType{iDev(1)},'Serial'))
                    % sets the sample rate for the device(s)
                    if max(iDev) > length(iStim.oPara)
                        sRate = iStim.oPara(1).sRate*ones(length(iDev),1);
                    else
                        sRate = field2cell(iStim.oPara(iDev),'sRate',1);
                    end

                    % if so, set up the serial controller devices
                    objDev = {setupSerialDevice(objDAQ,'Test',xySig(iDev),sRate,iDev)};

                else
                    % creates a loadbar
                    h = ProgressLoadbar('Setting Up External Devices...');

                    % creates the external device timer objects
                    if isempty(obj.objED)
                        % if there was an error, then set an empty array
                        objDev = {[]};
                    else
                        % setsup the external devices for the stimuli test
                        obj.objED.setupExtnDeviceTest(objDAQ,xySig,iDev)
                        objDev = {obj.objED.objD};
                    end

                    % closes the loadbar
                    delete(h);
                    if isempty(objDev{1})
                        % outputs any error to screen
                        tStrE = 'Device Setup Error';
                        eStr = ['There was an error in detecting the ',...
                                'external devices.'];
                        waitfor(msgbox(eStr,tStrE,'modal'))

                        % resets the toggle button properties
                        set(obj.hButTT,'String','Test Stimuli Train',...
                                       'Value',0);
                        return
                    end                         

                end
                
            end
            
            % ----------------------- %
            % --- DEVICE TEST RUN --- %
            % ----------------------- %  
            
            % resets the test timer properties
            obj.objTM.resetTimerProps();
            
            % runs all output devices
            if obj.infoObj.isTest
                obj.objTM.startTimer();
            elseif ~isempty(objDev)
                runOutputDevices(objDev,1:length(objDev)); 
            end                   
            
        end
                    
        % ------------------------------------ %
        % --- CLASS FIELD GETTER FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- retrieves the inter-parenthesis string
        function tStrD = getDurStr(obj)
            
            % tab specific initialisations
            if obj.isShort
                tStrD = 's';
            else
                tStrD = '           ';
            end
            
        end
        
        % ------------------------------------ %
        % --- CLASS FIELD SETTER FUNCTIONS --- %
        % ------------------------------------ %        

                
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %    
        
        % --- adds in a custom signal tab
        function addCustomSignalTab(obj,sObj)
            
            obj.objP.addParaTab(sObj.sName,sObj);
            
        end
        
        % --- updates the minimum duration button properties
        function updateMinDurButtonProps(obj)
            
            tDurTr = obj.objSM.getOverallStimDur();
            useMinDur = ~isnan(tDurTr) && (tDurTr < obj.tDurTot);
            setObjEnable(obj.hButP{1},useMinDur);
            
        end        
        
        % --- clears the stimuli train data field
        function clearStimTrain(obj)
            
            obj.sTrain = [];
            obj.updateExptTabFcn();
            
        end           
        
    end
    
end