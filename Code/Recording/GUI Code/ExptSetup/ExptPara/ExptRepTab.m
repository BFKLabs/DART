classdef ExptRepTab < handle & dynamicprops
    
    % class properties
    properties
    
        % class object handles
        hTab
        hObjP
        hEditP
        hPopupP
        hEditOfs
        
        % stimuli interval panel objects
        hPanelS
        hPopupS
        hListS        
        
        % parameter character fields       
        dType
        dStr
        dStrT
        sName
        sPara0
        
        % unit time multipliers
        tMltD
        tMltO
        
        % fixed object dimensions
        dxPopupP = 44;
        widPopup = 32;        
        widEdit = 60;                
        
        % calculated object dimensions
        hghtPanelS
        hghtList
        widTxt
        widObjF        
        widPopupS
        xPopupP
        
        % numerical class fields       
        nPara = 3;
        nPopup = 2;
        nPopupS = 4;
        
        % boolean class fields
        isShort
        isUpdating = false;
        
        % cell array fields
        tStr = {'Long','Short'};
        ppStr = {'d','h','m','s'};
        
        % parameter fields
        pFldC = {'nCount','tOfs','tOfsU','tDur','tDurU','tRep','tStim'};    
        
    end
    
    % private class properties
    properties (Access = private)
        
        objB
        
    end
    
    % observable class properties
    properties (SetObservable)
        
        % count parameters
        nCount        
        
        % time-based parameters
        tOfs
        tDur        
        tRep
        tStim
        
        % signal units parameters
        tOfsU
        tDurU
        
    end    
    
    % class methods
    methods
        
        % --- class constructor
        function obj = ExptRepTab(objB,isShort)
            
            % input arguments
            obj.objB = objB;  
            obj.isShort = isShort;
            
            % initialises the class fields/objects
            obj.linkParentProps();
            obj.initClassFields();
            obj.initClassObjects();    
            obj.setListenerFunc();
            
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %        
        
        % --- initialises the class object fields with that parent object
        function linkParentProps(obj)
            
            % parent fields strings
            fldStr = {'hFig','hButD','dX','hghtGrp','hghtLbl','hghtRow',...
                 'hghtTxt','hghtPopup','hghtEdit','hTabGrp','sTrainP',...
                 'fSz','fSzL','yGap','objSM','iExpt','calcExptStimDurFcn'};
            
            % connects the base/child objects
            for propname = fldStr
                metaprop = addprop(obj, propname{1});
                metaprop.SetMethod = @(obj, varargin) ...
                    SetDispatch(obj, propname{1}, varargin{:});
                metaprop.GetMethod = @(obj)GetDispatch(obj, propname{1});
            end
            
        end      
        
        % --- initialises the class fields
        function initClassFields(obj)
                        
            % popup menu memory allocation
            obj.hPopupP = cell(obj.nPopup,1); 
                        
            % ------------------------------------------- %
            % --- CLASS OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------------- %
            
            % parent object dimensions
            tgPos = obj.hTabGrp.Position;            
            
            % panel/listbox dimension calculations
            obj.hghtPanelS = obj.hghtLbl + 2*obj.hghtRow - obj.dX/2;
            obj.hghtList = tgPos(4) - ...
                (obj.hghtGrp + obj.hghtPanelS + 2.5*obj.dX + 3*obj.hghtRow); 
            
            % other object dimension calculations
            obj.widObjF = tgPos(3) - obj.dX;            
            obj.widTxt = tgPos(3) - (1.5*obj.dX + obj.widEdit);
            obj.xPopupP = (obj.dX/2 + obj.widTxt) - obj.dxPopupP;
            obj.widPopupS = (obj.widObjF - 2.5*obj.dX)/obj.nPopupS;
            
        end
        
        % --- initialises the class objects
        function initClassObjects(obj)
                        
            % field retrieval
            objBP = obj.objB.objB;
            tStrS = 'STIMULI REPETITION INTERVAL';

            % ------------------------------------- %
            % --- STIMULI REPETITION TAB OBJECT --- %
            % ------------------------------------- %
            
            % creates the tab object
            ttStr = sprintf('%s-Term Stimuli',obj.tStr{1+obj.isShort});
            obj.hTab = createNewTabPanel(obj.hTabGrp,1,'Title',ttStr);
            set(obj.hTab,'UserData',2-obj.isShort);

            % ------------------------------------------- %
            % --- STIMULI REPETITION INTERVAL OBJECTS --- %
            % ------------------------------------------- %
            
            % creates the listbox object
            lPos = [obj.dX*[1,1]/2,obj.widObjF,obj.hghtList];
            obj.hListS = objBP.setupListBox(obj.hTab,lPos);
            
            % creates the panel object
            yPosS = sum(lPos([2,4])) + obj.dX/2;
            pPosS = [obj.dX/2,yPosS,obj.widObjF,obj.hghtPanelS];
            obj.hPanelS = objBP.setupHeadedPanel(obj.hTab,pPosS,tStrS);
            
            % creates the duration panel group
            obj.hPopupS = objBP.setupDurationGroup(...
                obj.hPanelS,obj.dX*[1,1]/2,obj.widPopupS,2,true(1,4));
            
            % initialises the stimuli repetition interval parameters
            obj.initOtherRepPara();
            obj.initStimRepIntPara();            
            
            % ------------------------------------- %
            % --- STIMULI REPETITION PARAMETERS --- %
            % ------------------------------------- %
            
            % field retrieval
            pInfo = obj.getTabParaInfo();
            pFld = fieldnames(pInfo);
            wObjP = [obj.widTxt,obj.widEdit];
            
            % callback functions
            cbFcnE = @obj.editStimRepPara;
            cbFcnP = @obj.popupStimRepUnits;            
            
            % memory allocation
            yPos0 = sum(pPosS([2,4])) + obj.dX/2;
            obj.hEditP = cell(obj.nPara,1); 
            for i = 1:obj.nPara
                % creates the editbox group
                j = obj.nPara - (i-1);
                obj.hEditP{j} = objBP.setupEditGroup(...
                    obj.hTab,[obj.dX/2,yPos0],pInfo.(pFld{j}),wObjP);
                set(obj.hEditP{j},'UserData',pFld{j},'Callback',cbFcnE);
                
                % creates the popupmenu object (long-term stimuli only)
                if (j > 1)
                    % popup menu properties 
                    pFldU = sprintf('%sU',pFld{j});
                    pPosP = [obj.xPopupP,yPos0,obj.widPopup,obj.hghtPopup];

                    % creates the popupmenu item
                    obj.hPopupP{j-1} = ...
                        objBP.setupPopupMenu(obj.hTab,pPosP,obj.ppStr);
                    set(obj.hPopupP{j-1},...
                        'UserData',pFldU,'Callback',cbFcnP);
                end
                
                % sets the time offset editbox
                if strcmp(pFld{j},'tOfs')
                    obj.hEditOfs = obj.hEditP{j};
                end                
                
                % increments the vertical offset
                yPos0 = yPos0 + obj.hghtRow;
            end            
            
            % sets the repetition parameter objects
            hObjP0 = setdiff(findall(obj.hTab),findall(obj.hPanelS));
            hasE = arrayfun(@(x)(isprop(x,'Enable')),hObjP0); 
            obj.hObjP = hObjP0(hasE);
            
            % sets up the default stimuli parameter fields
            obj.setupRepParaFields();            
            
        end        
        
        % --- sets the listener function
        function setListenerFunc(obj)
            
            % retrieves observable parameter information
            mc = ?ExptRepTab;
            isObs = arrayfun(@(x)(x.SetObservable),mc.PropertyList);
            pStr = arrayfun(@(x)(x.Name),mc.PropertyList(isObs),'un',0);
                                    
            % sets the parameter listener functions
            for i = 1:length(pStr)
                addlistener(obj,pStr{i},'PostSet',...
                    @(s,e)obj.alterRepPara(s,e,pStr{i}));
            end
            
        end
        
        % ------------------------------------------ %
        % --- TAB FIELD INITIALISATION FUNCTIONS --- %
        % ------------------------------------------ %
        
        % --- initialises the stimuli repetition interval parameter objects
        function initStimRepIntPara(obj,varargin)

            % field retrieval
            objBP = obj.objB.objB;
            cbFcnP = @obj.popupStimRepInt;

            % sets the popupmenu callback functions
            cellfun(@(h)(set(h,'Callback',cbFcnP)),obj.hPopupS);
            
            % sets the popupmenu values/user flags            
            objBP.setObjUserDataFlags(obj.hPopupS);

        end
        
        % --- initialises the other repetition parameter objects
        function initOtherRepPara(obj,varargin)

            % sets the listbox parameters
            obj.hListS.Callback = @obj.listStimTrain;

        end        
        
        % ------------------------------------------ %
        % --- TAB FIELD INITIALISATION FUNCTIONS --- %
        % ------------------------------------------ %         
        
        % --- sets up the stimuli parameter fields
        function setupRepParaFields(obj,sParaNw)
            
            % retrieves the default parameter values
            if exist('sParaNw','var')
                obj.setRepParaValue(sParaNw);
            else
                obj.getDefParaValue();  
                obj.sPara0 = obj.copyRepParaValue();
            end
            
            % resets the parameter object value/fields
            for i = 1:length(obj.hEditP)
                setParaObjValue(obj,obj.hEditP{i});
            end

            % updates the duration par
            for i = 1:length(obj.hPopupP)
                setParaObjValue(obj,obj.hPopupP{i});
            end                            
            
            % sets the popupmenu item parameters (long-term stimuli only)
            if ~obj.isShort
                obj.setDurTimeValues();
            end
            
            % resets the inter-stimuli duration popupmenu items
            obj.setDurTimeValues();        
            obj.tMltD = obj.calcExptTimeMultiplier(obj.tDurU);
            obj.tMltO = obj.calcExptTimeMultiplier(obj.tOfsU);
            
        end        
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %
        
        % --- stimuli repetition interval editbox callback function
        function ok = editStimRepPara(obj,hObj,~)
            
            % initialisations
            ok = true;
            
            % field retrieval
            pStr = hObj.UserData;
            prVal = obj.(pStr);
            nwVal = str2double(hObj.String);   
            
            % parameter field retrieval
            [nwLim,isInt] = obj.getParaLimits(pStr);              
            [sParaS,sParaPr] = deal(obj.copyRepParaValue());            

            % determines if the new value is valid
            if chkEditValue(nwVal,nwLim,isInt)
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%    SIGNAL DURATION/COUNT UPDATE    %%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                
                
                % initialisations
                upDur = false;
                pStrU = {pStr};
                
                % field update/retrieval
                sParaS.(pStr) = nwVal;
                sTrainC = obj.getSelectedBlockInfo();
                [~,~,tBlkOfs,tBlkDur] = ...
                    obj.calcExptStimDurFcn(sTrainC,sParaS);
                
                % pre-calculations
                dnCount = (sParaS.nCount - 1);                
                tDurS = max(tBlkOfs + tBlkDur);                
                
                %
                switch pStr
                    case 'tDur'
                        % case is the block duration is being altered
                        
                        % recalculates the inter-stimuli interval
                        tDurNw = sParaS.tDur;
                        tDurINw = (tDurNw - obj.tMltD*tDurS)/dnCount; 
                        
                        % resets the interstimuli and block durations
                        obj.tStim = ...
                            obj.setupExptTimeVector(tDurINw/obj.tMltD);
                        pStrU{end+1} = 'tStim';
                        
                        % recalculates the stimuli block duration
                        tDurF = dnCount*tDurINw + obj.tMltD*tDurS;
                        if abs(tDurF - tDurNw) > 1e-6
                            % recalculate if major discrepancy
                            upDur = true;
                            [nwVal,obj.tDur] = deal(tDurF);
                        end
                        
                    case {'tOfs','nCount'}
                        % case is the time offset/stimuli rep count
                        
                        % field updates
                        [upDur,pStrU{end+1}] = deal(true,'tDur');
                        
                        % recalculates 
                        tDurI = vec2time(obj.tStim,obj.iExpt.Timing.TexpU);                        
                        obj.tDur = (dnCount*tDurI + tDurS)*obj.tMltD;
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%    PARAMETER STRUCT UPDATE    %%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                
                
                % updates the parameter field
                obj.(pStr) = nwVal;
                
                % checks the signal duration is valid
                [eState,tDurMin] = obj.checkSignalDur();
                if eState > 0
                    % state specific property updates
                    switch eState
                        case 2
                            % runs the minimum duration selection button
                            obj.iExpt.Timing.Texp = ...
                                obj.setupExptTimeVector(tDurMin);
                            feval(obj.hButD.Callback);
                    end
                    
                    % updates the duration field/properties
                    if upDur
                        hEditD = obj.getObjHandle('tDur');
                        set(hEditD,'String',num2str(round(obj.tDur,3)));
                    end                    
                    
                    % updates the inter-stimuli duration objects
                    if ~isempty(intersect(pStrU,{'tStim'}))
                        obj.setDurTimeValues();
                    end
                    
                    % updates the selected block signal parameters
                    if ~isnan(obj.objSM.iSigS)
                        sBlkS = obj.objSM.sBlk{obj.objSM.iSigS};
                        sBlkS.alterBlockPara(obj,pStrU);
                    end   
                    
                    % sets the other object properties
                    obj.objSM.updateMinDurFcn()
                    
                    % exits the function
                    return                    
                    
                else         
                    % otherwise, reset the original parameters
                    obj.setRepParaValue(sParaPr)
                end                
            end
            
            % if there was an error, then reset previous valid value
            [hObj.String,ok] = deal(num2str(prVal),false);            
            
        end
        
        % --- stimuli repetition unit popupmenu callback function
        function popupStimRepUnits(obj,hObj,~)
            
            % retrieves the corresponding parameter values
            pStr = hObj.UserData;
            [pDur0,pUnit0] = deal(obj.(pStr(1:end-1)),obj.(pStr));
            
            % calculates the time multiplier between time units
            pUnitNw = hObj.String{hObj.Value};
            pDurNw = pDur0*getTimeMultiplier(pUnitNw,pUnit0);

            % class field update
            obj.(pStr) = pUnitNw;
            obj.(pStr(1:end-1)) = pDurNw;
            
            % updates the duration editbox fields
            hObjDur = findall(obj.hTab,'UserData',pStr(1:end-1));            
            hObjDur.String = num2str(pDurNw); 
            
            % updates the selected stimuli object
            if ~isnan(obj.objSM.iSigS)
                sBlkS = obj.objSM.sBlk{obj.objSM.iSigS};
                sBlkS.sPara.(pStr) = pUnitNw;
                sBlkS.sPara.(pStr(1:end-1)) = pDurNw;
            end            
            
        end        
        
        % --- stimuli repetition interval popupmenu callback function
        function popupStimRepInt(obj,hObj,~)
            
            % field retrieval
            iTime = hObj.UserData;
            nwVal = str2double(hObj.String{hObj.Value});
            [sParaPr,sParaS] = deal(obj.copyRepParaValue());
            
            % updates the parameter value
            [obj.tStim(iTime),sParaS.tStim(iTime)] = deal(nwVal);            
            
            % calculates the 
            sTrainC = obj.getSelectedBlockInfo();
            obj.tDur = obj.calcExptStimDurFcn(sTrainC,sParaS)*obj.tMltD;
            
            % checks the signal duration is valid
            [eState,tDurMin] = obj.checkSignalDur();
            if eState > 0
                % state specific property updates
                switch eState
                    case 2
                        % runs the minimum duration selection button
                        obj.iExpt.Timing.Texp = ...
                            obj.setupExptTimeVector(tDurMin);
                        feval(obj.hButD.Callback);
                end                
                
                % updates the selected block signal parameters
                if ~isnan(obj.objSM.iSigS)
                    sBlkS = obj.objSM.sBlk{obj.objSM.iSigS};
                    sBlkS.alterBlockPara(obj,{'tStim','tDur'});
                end
                
            else
                % otherwise, reset the original parameters
                obj.setRepParaValue(sParaPr)
                obj.setDurTimeValues();
            end
            
        end
        
        % --- stimuli train listbox callback function
        function listStimTrain(obj,varargin)
            
            
            
        end
        
        % ------------------------------------------- %
        % --- PARAMETER UPDATE LISTENER FUNCTIONS --- %
        % ------------------------------------------- %
        
        % --- repetition parameter update listener function
        function alterRepPara(obj,~,~,pStr)
            
            % if manually updating fields, then exit
            if obj.isUpdating
                return
            end
            
            % parameter specific updates
            switch pStr
                case 'tOfs'
                    % case is the time offset
                    obj.hEditOfs.String = num2str(obj.tOfs);
                    
                case 'tDur'
                    % case is the stimuli block duration
                    hEditDur = findall(...
                        obj.hTab,'UserData',pStr,'style','edit');
                    hEditDur.String = num2str(obj.tDur);
                    
                case {'tRep','tStim'}
                    % case is the repetition parameters
                    obj.calcStimBlockDur();
                    
                case 'tDurU'
                    % case is the duration 
                    obj.calcStimBlockDur();                    
                    obj.tMltD = obj.calcExptTimeMultiplier(obj.tDurU);
                    
                case 'tOfsU'
                    % case is the initial offset
                    obj.tMltO = obj.calcExptTimeMultiplier(obj.tOfsU);
            end
            
        end
        
        % ------------------------------ %
        % --- CLASS GETTER FUNCTIONS --- %
        % ------------------------------ %
        
        % --- retrieves the parameter information for tab, tType
        function pInfo = getTabParaInfo(obj)
            
            % retrieves the suffix string
            sStr = obj.getDurString();            
            
            % parameter object struct
            pInfo = struct(...
                'nCount','Stimuli Repetition Count',...
                'tOfs',sprintf('Initial Signal Offset (%s)',sStr),...
                'tDur',sprintf('Train Duration (%s)',sStr));
            
        end  
        
        % --- retrieves the default parameter values
        function getDefParaValue(obj)

            % common parameters
            obj.isUpdating = true;            
            
            % parmaeter initialisations
            obj.tDur = 0;
            obj.sName = [];
            obj.tStim = [0,1,0,0];
            obj.nCount = 1 + obj.isShort;
            [obj.tOfsU,obj.tDurU] = deal('h');                                               
                                             
            % common parameters
            obj.isUpdating = false;
            obj.tOfs = 0;
            
        end
        
        % --- retrieves the currently selected block info
        function sTrainEx = getSelectedBlockInfo(obj)
            
            % field retrieval
            iSel = obj.hListS.Value;
            
            % returns stimuli train corresponding to the current selection
            if isempty(iSel)
                % case is no listbox entry is selected
                sTrainEx = [];
            else
                % retrieves the stimuli train parameter struct
                if obj.isShort
                    sTrainEx = obj.sTrainP.S{iSel};
                else
                    sTrainEx = obj.sTrainP.L{iSel};
                end                
            end
            
        end        
        
        % --- retrieves the object handle corresponding to parameter, pStr
        function hObj = getObjHandle(obj,pStrH,tStrH)
                        
            if exist('tStrH','var')
                hObj = findobj(obj.hTab,'UserData',pStrH,'Tag',tStrH);                
            else
                hObj = findobj(obj.hTab,'UserData',pStrH);
            end
            
        end        
        
        % ------------------------------ %
        % --- CLASS SETTER FUNCTIONS --- %
        % ------------------------------ %
        
        % --- copies the values from the parameter class object, sParaNw
        function setRepParaValue(obj,sParaNw)
                        
            for i = 1:length(obj.pFldC)
                if isfield(sParaNw,obj.pFldC{i})
                    obj.(obj.pFldC{i}) = sParaNw.(obj.pFldC{i});
                end
            end            
            
        end                
        
        % --- sets the repetition parameter properties
        function setRepParaProps(obj,eState)
            
            setPanelProps(obj.hPanelS,eState);
            setObjEnable(obj.hObjP,eState)
            
        end          
        
        % --- sets the duration popupmenu item values
        function setDurTimeValues(obj)
            
            for i = 1:length(obj.hPopupS)
                set(obj.hPopupS{i},'Value',obj.tStim(i)+1);
            end
            
        end                  
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- calculates the stimuli block duration
        function calcStimBlockDur(obj)
            
            % field retrieval
            sTrainEx = obj.getSelectedBlockInfo();
            if isempty(sTrainEx)
                % case is there is no currently selected block
                obj.tDur = NaN;
                
            else
                % calculates the stimuli block duration
                sParaC = obj.copyRepParaValue();
                obj.tDur = ...
                    obj.tMltD*obj.calcExptStimDurFcn(sTrainEx,sParaC);                
            end                        
            
        end  
        
        % --- sets up the experiment time vector
        function Texp = setupExptTimeVector(obj,tDurEx)
            
            % memory allocation
            Texp = zeros(1,4);            
            tDurExH = convertTime(tDurEx,obj.iExpt.Timing.TexpU,'h');
            
            % converts the hour to dd:hh:mm:ss format
            tDurH = hours(tDurExH);
            tDurH.Format = 'dd:hh:mm:ss';
            
            % stores the final time vector
            TexpP = cellfun(@str2double,strsplit(char(tDurH),':'));
            Texp((5-length(TexpP)):end) = TexpP;
            
        end
        
        % --- outputs the parameter values to a data struct, sParaC
        function sParaC = copyRepParaValue(obj)
            
            % memory allocation
            sParaC = struct();
            
            % field retrieval to data struct
            for i = 1:length(obj.pFldC)
                sParaC.(obj.pFldC{i}) = obj.(obj.pFldC{i});
            end
            
        end                
        
        % --- checks the signal duration is feasible
        function [eState,tDurMin] = checkSignalDur(obj)
            
            % field retrieval and initialisations
            [eState,errType] = deal(1,0);
            
            % calculates the scaled time offset/total duration
            tOfsNw = obj.tOfs/obj.tMltO; 
            if isnan(obj.objSM.iSigS)
                % case is no stimuli blocks selected (so use full train)
                [tHi,addStr] = deal(obj.objSM.getExptDur(),'');

            else
                % otherwise, get the selected stimuli block
                
                % retrieves the currently selected block
                sBlkS = obj.objSM.sBlk{obj.objSM.iSigS};
                
                % initial point within an existing block
                tHi = sBlkS.sLim(2);
                if (tOfsNw < sBlkS.sLim(1))
                    [eState,errType] = deal(0,1);
                end                
                
                % sets the additional string to the error message
                addStr = sprintf(['\n * De-select the currently ',...
                                  'selected stimuli signal object']);                   
            end
            
            % determines if the duration of the stimuli train is feasible
            if eState
                errType = 2;                
                eState = double((obj.tDur/obj.tMltD) <= (tHi - tOfsNw));
            end
            
            % determines if the signal duration exceeds the max duration
            tDurMin = (obj.tDur + tOfsNw)/obj.tMltD;
            
            % outputs the error message
            if ~eState
                % initialisations
                tStrErr = 'Infeasible Signal Parameters';
                
                switch errType
                    case 1
                        % case is signal offset is less than lower limit
                        eStr = sprintf(['The signal offset (%.2f%s) ',...
                            'lies an existing signal block. Re-select ',...
                            'another value which is feasible.'],...
                            tOfsNw,obj.tDurU);
                        waitfor(msgbox(eStr,tStrErr,'modal'))
                        
                    case 2
                        % case is upper time exceeds total signal duration
                        tStrE = 'Invalid Signal Offset';
                        eStr = sprintf(['The signal offset (%.2f%s) ',...
                            'and signal duration (%.2f%s) must be ',...
                            'less than the stimuli upper time limit ',...
                            '(%.2f%s). To overcome this issue either:',...
                            '\n\n * Reduce the "Signal Cycle Count"\n',...
                            ' * Alter the "Initial Signal Offset"\n',...
                            ' * Reset the parameters by selecting ',...
                            '"Restore Default Parameters"%s'],...
                            tOfsNw,obj.tDurU,obj.tDur,obj.tDurU,...
                            tHi,obj.tDurU,addStr);                        
                        waitfor(msgbox(eStr,tStrE,'modal'))
                        
%                         % adds in the question part of the message
%                         eStr = sprintf(['%s\n\nAlternatively, would ',...
%                             'you like to expand the Signal Duration ',...
%                             'to match the new configuration?'],eStr);
%                         
%                         % prompts the user if they wish to reset the 
%                         % parameter, or expand the total signal duration
%                         uChoice = questdlg(eStr,tStrErr,'Reset Parameter',...
%                             'Expand Duration','Reset Parameter');
%                         eState = 2*strcmp(uChoice,'Expand Duration');
                end
            end
            
        end    
        
        % --- calculates the time multiplier
        function tMlt = calcExptTimeMultiplier(obj,tUnit0)
        
             tMlt = getTimeMultiplier(tUnit0,obj.iExpt.Timing.TexpU);
            
        end        
        
    end
    
    % static class methods
    methods (Static)
        
        % --- retrieves the duration string
        function sStr = getDurString()
           
            sStr = '           ';
                        
        end        
        
        % --- signal parameter limits/integer flags
        function [nwLim,isInt] = getParaLimits(pStr)
            
            % initialisations
            isInt = false;
            
            % sets the parameter limits (based on type)
            switch pStr
                case 'nCount'
                    % case is the signal cycle count
                    [nwLim,isInt] = deal([1,inf],true);
                    
                case 'tOfs'
                    % signal offset
                    nwLim = [0,inf];
                    
                case 'tDur'
                    % case is the other stimuli temporal parameters
                    nwLim = [0.01,inf];                    
            end
            
        end        
        
    end
    
    % private class methods
    methods (Access = private)
        
        % --- sets a class object field
        function SetDispatch(obj, propname, varargin)
            obj.objB.(propname) = varargin{:};
        end
        
        % --- gets a class object field
        function varargout = GetDispatch(obj, propname)
            varargout{:} = obj.objB.(propname);
        end
        
    end    
    
end