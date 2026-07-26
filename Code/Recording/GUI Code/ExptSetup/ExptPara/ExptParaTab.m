classdef ExptParaTab < handle & dynamicprops
    
    % class properties
    properties
    
        % class object handles
        hTab
        hEdit
        hPopup
        hCheck
        
        % time offset object handles
        hEditOfs
        hPopupOfs
        
        % parameter character fields
        dType
        dStr
        dStrT
        pInfo
        sPara0
        sObj
        
        % fixed object dimensions
        dimChk = 20;
        widPopup = 32;        
        dxPopup = 44;
        
        % calculated object dimensions        
        widTxt
        widTxtR
        widEdit
        widEditR
        xPopup
        xPopupC
        
        % numerical class fields       
        nPara = 6;
        nCheck = 3;
        nPopup = 0;        
        
        % boolean class fields
        isRand
        isCustom
        isUpdating = false;
        
        % parameter class fields
        tMin = 0.01;
        sAmpMin = 0.1;
        
        % cell array fields
        uType = {'s','m','h'};
        sType = {'Random','Square'};
        tStrSW = {'tDurOffL','tDurOff','tDurOffU'};
        
        % parameter fields
        pFldC = {'sAmp','sAmp0','sAmp1','nCount','nCycle',...
                 'tOfs','tOfsU','tDur','tDurU','tCycle','tCycleU',...
                 'tDurOn','tDurOnU','tDurOff','tDurOffU','dType'};        
        
    end
    
    % private class properties
    properties (Access = private)
        
        objB
        
    end
    
    % observable class properties
    properties (SetObservable)
        
        % signal amplitude parameters
        sAmp
        sAmp0
        sAmp1
        
        % signel count parameters
        nCount
        nCycle
        
        % signal time-based parameters
        tOfs
        tDur
        tDurOn
        tDurOff
        tCycle
        
        % signal units parameters
        tOfsU
        tDurU
        tDurOnU
        tDurOffU
        tCycleU
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = ExptParaTab(objB,dType,sObj)
            
            % input arguments
            obj.objB = objB;      
            obj.dType = dType;
            obj.sObj = sObj;
            
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
            fldStr = {'hFig','objSM','hTabGrp','hButP','hEditP',...
                'tDurTotU','tDurTot','dX','fSz','fSzL','isShort',...
                'hghtGrp','hghtLbl','hghtRow',...
                'hghtTxt','hghtPopup','hghtEdit'};
            
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
            
            % field initialisations
            obj.isCustom = ~isempty(obj.sObj);
            obj.isRand = strcmp(obj.dType,'Random');            
            
            % popup menu memory allocation (long-stimuli only)
            if ~obj.isShort
                obj.nPopup = 2 + any(strcmp(obj.sType,obj.dType));
                obj.hPopup = cell(obj.nPopup,1);
            end
            
            % ------------------------------------------- %
            % --- CLASS OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------------- %
            
            % parent object dimensions
            tgPos = obj.hTabGrp.Position;
            
            % other object dimension calculations
            if obj.isRand
                % calculates the object width dimensions
                obj.widEditR = 40*[1,1];
                obj.widEdit = sum(obj.widEditR) + obj.dX/2;
                obj.widTxt = tgPos(3) - (1.5*obj.dX + obj.widEdit);
                obj.widTxtR = obj.widTxt - obj.dimChk;
                
                % calculates the object horizontal offset
                obj.xPopup = obj.dX/2 + obj.widTxt - obj.dxPopup;
                obj.xPopupC = obj.xPopup - obj.dimChk;
            else
                % calculates the object width dimensions
                obj.widEdit = 60;                
                obj.widTxt = tgPos(3) - (1.5*obj.dX + obj.widEdit);

                % calculates the object horizontal offset                
                obj.xPopup = obj.dX/2 + obj.widTxt - obj.dxPopup;
            end
            
        end
        
        % --- initialises the class objects
        function initClassObjects(obj)
                        
            % creates the tab object
            obj.hTab = createNewTabPanel(...
                obj.hTabGrp,1,'Title',obj.dType,'UserData',obj.isCustom);                    
            
            % initialises the stimuli parameter tab objects/fields
            obj.initStimParaTab();
            obj.setupStimParaFields();
            
        end
        
        % --- sets the listener function
        function setListenerFunc(obj)
            
            % retrieves observable parameter information
            mc = ?ExptParaTab;
            isObs = arrayfun(@(x)(x.SetObservable),mc.PropertyList);
            pStr = arrayfun(@(x)(x.Name),mc.PropertyList(isObs),'un',0);
                                    
            % sets the parameter listener functions
            for i = 1:length(pStr)
                addlistener(obj,pStr{i},'PostSet',...
                    @(s,e)obj.alterStimPara(s,e,pStr{i}));
            end
            
        end     
        
        % ------------------------------------- %
        % --- TAB OBJECT CREATION FUNCTIONS --- %
        % ------------------------------------- %        
        
        % --- initialises the stimuli parameter tab
        function initStimParaTab(obj)
            
            % field retrieval
            objBP = obj.objB.objB;                        
            
            % memory allocation
            iPopup = 1;
            obj.getTabParaInfo();
            pFld = fieldnames(obj.pInfo);
            setPP = startsWith(pFld,'t') & ~strcmp(pFld,'tDur');
            
            % common callback functions
            cbFcn = @obj.editStimPara;            
            
            % sets up the object width vectors
            if obj.isRand
                % case is a random stimuli
                
                % object dimensions
                wObjP = [obj.widTxt,obj.widEdit];
                wObjR = [obj.widTxt,obj.widEditR];
                wObjRC = [obj.widTxtR,obj.dimChk,obj.widEditR];
                
                % memory allocation
                obj.hCheck = cell(obj.nCheck,1);
                
                % callback functions
                cbFcnC = @obj.checkRandStimPara;
                cbFcnMx = {@obj.editRandStimPara,true};
                cbFcnMn = {@obj.editRandStimPara,false};                
            else
                % case is non-random stimuli
                
                % object dimensions                
                wObjP = [obj.widTxt,obj.widEdit];                
            end            
            
            % creates the stimuli parameter objects
            obj.hEdit = cell(obj.nPara,1+obj.isRand);            
            for i = 1:obj.nPara
                % global index
                j = obj.nPara - (i-1);
                yPos = obj.dX/2 + (i-1)*obj.hghtRow;
                pStr = obj.pInfo.(pFld{j});
                
                % creates the parameter group objects
                if obj.isRand
                    % case is random stimuli
                    switch j
                        case {1,2,3}
                            % optional random stimuli parameters fields
                            [obj.hEdit(j,:),obj.hCheck{j}] = ...
                                objBP.setupDblChkEditGroup(...
                                    obj.hTab,[obj.dX/2,yPos],pStr,wObjRC);
                                
                            % sets the other object properties
                            set(obj.hEdit{j,1},'tag','hEditMin',...
                                'UserData',pFld{j},'Callback',cbFcnMn)
                            set(obj.hEdit{j,2},'tag','hEditMax',...
                                'UserData',pFld{j},'Callback',cbFcnMx)
                            set(obj.hCheck{j},'tag','hCheckR',...
                                'UserData',pFld{j},'Callback',cbFcnC);
                            
                        case 4
                            % compulsory random stimuli parameters fields
                            obj.hEdit(j,:) = objBP.setupDblEditGroup(...
                                obj.hTab,[obj.dX/2,yPos],pStr,wObjR);
                            
                            % sets the other object properties
                            set(obj.hEdit{j,1},'tag','hEditMin',...
                                'UserData',pFld{j},'Callback',cbFcnMn)
                            set(obj.hEdit{j,2},'tag','hEditMax',...
                                'UserData',pFld{j},'Callback',cbFcnMx)
                            
                        otherwise
                            % non-random stimuli parameter fields
                            [obj.hEdit{j,1},hTxt] = objBP.setupEditGroup(...
                                obj.hTab,[obj.dX/2,yPos],pStr,wObjP);
                            
                            % sets the other object properties
                            set(obj.hEdit{j,1},...
                                'UserData',pFld{j},'Callback',cbFcn)
                    end
                else
                    % case is a non-random stimuli
                    [obj.hEdit{j},hTxt] = objBP.setupEditGroup(...
                        obj.hTab,[obj.dX/2,yPos],pStr,wObjP);
                    set(obj.hEdit{j},...
                        'UserData',pFld{j},'Callback',cbFcn)
                end
                
                % sets the time offset editbox
                if strcmp(pFld{j},'tOfs')
                    obj.hEditOfs = obj.hEdit{j};
                end
                
                % creates the duration popup menu item (long-term stimuli)
                if ~obj.isShort && setPP(j)
                    % sets up the position vector
                    pPosP = [obj.xPopup,yPos,obj.widPopup,obj.hghtPopup];
                    if obj.isRand && any([2,3] == j)
                        % special case (random time parameter & checkbox)
                        pPosP(1) = obj.xPopupC;
                    end
                        
                    % creates the popupmenu item
                    pFldU = sprintf('%sU',pFld{j});
                    obj.hPopup{iPopup} = objBP.setupPopupMenu(...
                        obj.hTab,pPosP,obj.uType);
                    set(obj.hPopup{iPopup},'UserData',pFldU,...
                        'Callback',@obj.popupTimeUnits);
                    
                    % sets the time offset popup
                    if strcmp(pFldU,'tOfsU')
                        obj.hPopupOfs = obj.hPopup{iPopup};
                    end
                    
                    % increments the popup index
                    iPopup = iPopup + 1;                    
                end
                
                % makes the text label red (for total duration)
                set(hTxt,'UserData',sprintf('%sL',pFld{j}));
                if i == 1
                    hTxt.ForegroundColor = 'r';
                end
            end            
            
        end        

        % ------------------------------------------ %
        % --- TAB FIELD INITIALISATION FUNCTIONS --- %
        % ------------------------------------------ %        
        
        % --- sets up the stimuli parameter fields
        function setupStimParaFields(obj,sParaNw)
            
            % retrieves the default parameter values
            if exist('sParaNw','var')
                obj.setParaValue(sParaNw);
            else
                obj.getDefParaValue();  
                obj.sPara0 = obj.copyParaValue();
            end
            
            % resets the parameter object value/fields
            for i = 1:obj.nPara
                if obj.isRand
                    % case is random square wave stimuli 
                    
                    % sets the editbox value
                    for j = 1:size(obj.hEdit,2)
                        if ~isempty(obj.hEdit{i,j})
                            setParaObjValue(obj,obj.hEdit{i,j},j);
                        end
                    end
                    
                    % sets the checkbox value
                    if i <= obj.nCheck
                        setParaObjValue(obj,obj.hCheck{i});
                        setObjEnable(obj.hEdit{i,2},obj.hCheck{i}.Value);
                    end
                else
                    % case is the other stimuli types
                    setParaObjValue(obj,obj.hEdit{i});
                end
            end
            
            % sets the popupmenu item parameters (long-term stimuli only)
            if ~obj.isShort
                for i = 1:length(obj.hPopup)
                    setParaObjValue(obj,obj.hPopup{i});
                end                
            end
            
        end

        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %
                
        % --- stimuli parameter editbox callback function        
        function ok = editStimPara(obj,hObj,~)
           
            % initialisations
            ok = true;
            
            % field retrieval
            pStr = hObj.UserData;
            prVal = obj.(pStr);
            nwVal = str2double(hObj.String);   
            
            % parameter field retrieval
            sParaPr = obj.copyParaValue();
            [nwLim,isInt] = obj.getParaLimits(pStr);
            
            % determines if the new value is valid
            if chkEditValue(nwVal,nwLim,isInt)
                % updates the parameter field
                obj.(pStr) = nwVal;
                
                % checks/updates the stimuli property fields
                isSW = strcmp(obj.dType,'Square') || obj.isRand;
                [upDur,upC] = obj.checkTemporalFields(pStr,isSW);
                
                % checks the signal duration is valid
                [eState,tDurMin] = obj.checkSignalDur();
                if eState > 0
                    % state specific property updates
                    switch eState
                        case 2
                            % runs the minimum duration selection button
                            obj.tDurTot = tDurMin;
                            feval(obj.hButP{1}.Callback);
                    end
                    
                    % update parameter fields
                    pStrU = {pStr};
                    
                    % duration parameter field updates
                    if upDur
                        pStrU{end+1} = 'tDur';
                        hEditD = obj.getObjHandle('tDur');
                        set(hEditD,'String',num2str(round(obj.tDur,3)));                        
                    end
                    
                    % cycle count parameter field updates
                    if upC
                        pStrU{end+1} = 'nCount';   
                        if obj.isRand
                            % case is a non-random stimuli
                            obj.calcRandCountRange()
                            
                            % updates the minimum cycle count
                            hEditMn = obj.getObjHandle('nCount','hEditMin');
                            set(hEditMn,'String',num2str(obj.nCount(1)));
                            
                            % updates the maximum cycle count
                            hEditMx = obj.getObjHandle('nCount','hEditMax');
                            set(hEditMx,'String',num2str(obj.nCount(2)));
                            
                        else
                            % case is a non-random stimuli
                            hEditC = obj.getObjHandle('nCount');
                            set(hEditC,'String',num2str(obj.nCount));
                        end
                    end
                    
                    % square wave field updates
                    if isSW && ~obj.isRand
                        hObjSW = cell2cell(cellfun(@(x)...
                                (obj.getObjHandle(x)),obj.tStrSW,'un',0));
                        setObjEnable(hObjSW,any(obj.nCount>1))
                    end
                    
                    % resets the selected signal object parameters
                    sBlkS = obj.objSM.getSelectedTrain();
                    if ~isempty(sBlkS)
                        sBlkS.alterTrainPara(obj,pStrU);
                    end
                    
                    % other general object property updates
                    setObjEnable(obj.hButP{1},eState==1);
                    setObjEnable(obj.hButP{2},obj.isParaChange())

                    % exits the function
                    return
                    
                else
                    % resets the original parameters
                    obj.setParaValue(sParaPr);
                end
                
            end
            
            % if there was an error, then reset previous valid value
            [hObj.String,ok] = deal(num2str(prVal),false);
            
        end         
        
        % --- random parameter editbox callback function 
        function ok = editRandStimPara(obj,hObj,~,isMax)
           
            % field retrieval
            pStr = hObj.UserData;            
            prVal = obj.(pStr);            
            nwVal = str2double(hObj.String);
            sParaPr = obj.copyParaValue();
            
            % other initialisations
            ok = true;
            [isRandP,isRandC] = deal(length(prVal) == 3,false);
            
            % determines the parameter index value
            if isRandP
                if prVal(end) > 0
                    % case is the parameter value is fixed
                    ipVal = 3;
                else
                    % case is the parameter value is random
                    [isRandC,ipVal] = deal(true,1 + isMax);
                end
            else
                % case is a fixed parameter value
                ipVal = 1;
            end
            
            % determines if the new value is valid
            nwLim = obj.getRandParaLimits(pStr,prVal,isRandC,ipVal);
            if chkEditValue(nwVal,nwLim,0)
                % if so, then update the parameter within the sub-struct
                obj.(pStr)(ipVal) = nwVal;
                
                % checks the temporal fields are set correctly
                obj.checkTemporalFields(pStr,true);                
                
                % checks the signal duration is valid
                [eState,tDurMin] = obj.checkSignalDur();
                if eState > 0
                    % updates the count range fields
                    if startsWith(pStr,'tD')
                        obj.calcRandCountRange()
                        obj.updateRandCountFields();
                    end
                    
                    % state specific property updates
                    switch eState
                        case 2
                            % runs the minimum duration selection button
                            obj.tDurTot = tDurMin;
                            feval(obj.hButP{1}.Callback);
                    end                    
                    
                    % resets the selected signal object parameters
                    sBlkS = obj.objSM.getSelectedTrain();
                    if ~isempty(sBlkS)
                        sBlkS.alterTrainPara(obj.copyParaValue());
                    end
                    
                    % other general object property updates
                    setObjEnable(obj.hButP{1},eState==1);
                    setObjEnable(obj.hButP{2},obj.isParaChange())
                    
                    % exits the function
                    return
                else 
                    % resets the original parameters
                    obj.setParaValue(sParaPr);
                end
            end

            % flag that there was an error 
            ok = false;
            set(hObj,'string',num2str(prVal(ipVal)))            
                
        end          
        
        % --- random parameter checkbox callback function
        function checkRandStimPara(obj,hObj,~)
           
            % retrieves the corresponding parameter values
            pStr = hObj.UserData;
            
            % updates the parameter field
            pMlt = (1 - 2*hObj.Value);
            obj.(pStr)(end) = pMlt*abs(obj.(pStr)(end));
            
            % recalculates the random count range
            obj.calcRandCountRange();
            
            % updates the parameter/count fields
            obj.updateRandParaField(pStr,0);
            obj.updateRandCountFields();
            
            % updates the stimuli train properties
            if ~isempty(obj.objSM)
                sBlkS = obj.objSM.getSelectedTrain();
                if ~isempty(sBlkS)
                    sBlkS.alterTrainPara(obj.copyParaValue());
                end
            end
            
        end                  
        
        % --- time units popupmenu callback function
        function popupTimeUnits(obj,hObj,~)
           
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
            if length(hObjDur) == 1
                hObjDur.String = num2str(pDurNw);                
            else
                % min/max editbox handle retrieval
                hEditMin = findobj(hObjDur,'tag','hEditMin');
                hEditMax = findobj(hObjDur,'tag','hEditMax');                
                
                % updates the editbox strings
                if pDurNw(end) < 0
                    % case is using random limits
                    set(hEditMin,'String',num2str(pDurNw(1)));
                    set(hEditMax,'String',num2str(pDurNw(2)),'Enable','on')
                else
                    % case is using fixed value
                    set(hEditMin,'String',num2str(pDurNw(3)));
                    set(hEditMax,'String','','Enable','on')                    
                end
                
            end
            
            % updates the selected stimuli object
            sBlkS = obj.objSM.getSelectedTrain();
            if ~isempty(sBlkS)
                sBlkS.sPara.(pStr) = pUnitNw;
                sBlkS.sPara.(pStr(1:end-1)) = pDurNw;
            end
            
            % resets the default parameter button properties
            setObjEnable(obj.hButP{2},obj.isParaChange())            
            
        end            
        
        % ------------------------------------------- %
        % --- PARAMETER UPDATE LISTENER FUNCTIONS --- %
        % ------------------------------------------- %
        
        % --- stimuli parameter alteration listener function
        function alterStimPara(obj,~,~,pStr)
            
            % if manually updating fields, then exit
            if obj.isUpdating
                return
            end
            
            % parameter specific updates
            switch pStr
                case 'tOfs'
                    % case is the time offset
                    obj.hEditOfs.String = num2str(obj.tOfs);
            end
            
        end
        
        % -------------------------------- %
        % --- RANDOM STIMULI FUNCTIONS --- %
        % -------------------------------- %        
        
        % --- calculates the stimuli count range
        function calcRandCountRange(obj)
            
            % calculates the on/off time scale factors
            tMltOn = getTimeMultiplier(obj.tDurTotU,obj.tDurOnU);
            tMltOff = getTimeMultiplier(obj.tDurTotU,obj.tDurOffU);
            
            % retrieves the signal on durations
            if obj.tDurOn(3) > 0
                tOn = tMltOn*obj.tDurOn(3);
            else
                tOn = tMltOn*obj.tDurOn(1:2);
            end

            % retrieves the signal off durations
            if obj.tDurOff(3) > 0
                tOff = tMltOff*obj.tDurOff(3);
            else
                tOff = tMltOff*obj.tDurOff(1:2);
            end
            
            % calculates the count range
            nCount0 = flip((obj.tDur + tOff)./(tOff + tOn));
            if length(nCount0) == 1
                % case is non-random cycle count
                obj.nCount = floor(nCount0)*[1,1];
            else
                % case is a random cycle count
                obj.nCount = [ceil(nCount0(1)),floor(nCount0(2))];
            end            
            
        end        
        
        % --- updates the random parameter fields
        function updateRandParaField(obj,pStr,updateCheck)
            
            % sets the default input parameters
            if ~exist('updateCheck','var'); updateCheck = true; end
            
            % field/object handle retrieval
            pVal = obj.(pStr);
            hEditMin = obj.getObjHandle(pStr,'hEditMin');
            hEditMax = obj.getObjHandle(pStr,'hEditMax');
            
            % updates the editbox string/properties
            if pVal(end) < 0
                % case is the parameter is random
                set(hEditMin,'String',num2str(pVal(1)))
                set(hEditMax,'String',num2str(pVal(2)),'Enable','on')
                
            else
                % case is the parameter is fixed
                set(hEditMin,'String',num2str(pVal(end)))
                set(hEditMax,'String','','Enable','off')                
            end
            
            % updates the checkbox value (if required)
            if updateCheck
                hCheckR = obj.getObjHandle(pStr,'hCheckR');
                hCheckR.Value = pVal(end) < 0;
            end
            
        end
        
        % --- updates the random count fields
        function updateRandCountFields(obj)
            
            % field retrieval
            eStr = {'off','inactive'};
            isRandC = abs(diff(obj.nCount)) > 0;
            
            % retrieves the editbox object handles
            hEditMin = obj.getObjHandle('nCount','hEditMin');
            hEditMax = obj.getObjHandle('nCount','hEditMax');
            
            % resets the editbox values/properties
            set(hEditMin,'String',num2str(obj.nCount(1)));
            set(hEditMax,'String',num2str(obj.nCount(2)),...
                         'Enable',eStr{1+isRandC});
            
        end
        
        % ------------------------------ %
        % --- CLASS GETTER FUNCTIONS --- %
        % ------------------------------ %
        
        % --- retrieves the parameter information for tab, tType
        function getTabParaInfo(obj)
            
            % retrieves the suffix string
            sStr = obj.getDurString();            
            
            % sets the stimuli specific parameter fields
            switch obj.dType
                case {'Square','Random'}
                    % case is square waves
                    obj.pInfo = struct(...
                        'sAmp','Signal Amplitude (%)',...
                        'tDurOn',sprintf('On Cycle Duration (%s)',sStr),...
                        'tDurOff',sprintf('Off Cycle Duration (%s)',sStr));                   
                    
                otherwise
                    % case is the other stimuli type
                    obj.pInfo = struct(...
                        'sAmp0','Signal Start Amplitude (%)',...
                        'sAmp1','Signal Max Amplitude (%)',...
                        'tCycle',sprintf('Cycle Duration (%s)',sStr));
                    
                    % stimuli type specific parameter fields
                    if strcmp(obj.dType,'Ramp')
                        obj.pInfo.('sAmp1') = 'Signal Stop Amplitude (%)';
                    elseif obj.isCustom
                        obj.pInfo.('sAmp0') = 'Signal Baseline Amplitude (%)';
                    end
            end                        
            
            % sets the other common parameter fields
            obj.pInfo.('nCount') = 'Signal Cycle Count';            
            obj.pInfo.('tOfs') = sprintf('Initial Signal Offset (%s)',sStr);            
            
            % signal duration field
            if obj.isShort
                obj.pInfo.('tDur') = sprintf('Signal Train Duration (s)');
            else
                obj.pInfo.('tDur') = sprintf('Signal Train Duration (h)');                
            end                        
            
        end
        
        % --- retrieves the default parameter values
        function getDefParaValue(obj)
            
            % signal-type based parameters
            if obj.isShort
                % case is short-term stimuli 
                [nC0,tC0,tUnits0] = deal(3,0.5,'s');
                
            else
                % case is long-term stimuli 
                [nC0,tC0,tUnits0] = deal(3,0.1,'h');
            end            
                                             
            % common parameters
            obj.isUpdating = true;
            
            % sets the default parameters based on type
            switch obj.dType
                case 'Square'
                    % case is the square stimuli signals
                    
                    % signal parameters
                    obj.sAmp = 100;
                    obj.nCount = nC0;
                    [obj.tDurOn,obj.tDurOff] = deal(tC0);
                    
                    % temporal units
                    [obj.tDurU,obj.tOfsU] = deal(tUnits0);
                    [obj.tDurOnU,obj.tDurOffU] = deal(tUnits0);                    
                    
                case 'Random'
                    % case is the random square stimuli signals
                    
                    % other initialisations
                    tDurC = tC0*[0.25,1,-1];
                    obj.tDur = 5*tC0;
                    
                    % signal parameters
                    obj.sAmp = [25,100,-100];
                    obj.nCount = [0,0];
                    [obj.tDurOn,obj.tDurOff] = deal(tDurC);
                    
                    % temporal units
                    [obj.tDurU,obj.tOfsU] = deal(tUnits0);
                    [obj.tDurOnU,obj.tDurOffU] = deal(tUnits0);
                    obj.calcRandCountRange();
                    
                otherwise
                    % case is the other stimuli signal types

                    % signal amplitude parameters                    
                    [obj.sAmp0,obj.sAmp1] = deal(0,100);
                    
                    % signal cycle duration/count parameters
                    if obj.isCustom
                        [obj.tCycle,obj.nCount] = deal(2,1);                        
                    else
                        [obj.tCycle,obj.nCount] = deal(tC0,nC0);
                    end
                    
                    % temporal units
                    [obj.tCycleU,obj.tDurU,obj.tOfsU] = deal(tUnits0);
            end
            
            % resets the update flag
            obj.isUpdating = false;
            obj.tOfs = 0;            
                
            % calculates the signal duration\
            obj.calcSignalDur();            
            
        end        
        
        % --- retrieves the duration string
        function sStr = getDurString(obj)
           
            if obj.isShort
                sStr = 's';
            else
                sStr = '           ';
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
        
        % --- signal parameter limits/integer flags
        function [nwLim,isInt] = ...
                getRandParaLimits(obj,pStr,pVal,isRandC,ipVal)
            
            % initialisations
            isInt = false;
            
            % sets the parameter value limits
            switch pStr
                case 'tOfs'
                    % case is the signal offset
                    nwLim = [0,inf];
                    
                case 'tDur'
                    % case is the signal duration
                    nwLim = [obj.tMin,inf];
                    
                case 'tDurOn'
                    % case is the cycle on duration
                    if isRandC
                        % case is the parameter value is random
                        if ipVal == 1
                            % case is the minimum value is being altered
                            nwLim = [obj.tMin,pVal(2)];
                        else
                            % case is the maximum value is being altered
                            nwLim = [pVal(1),inf];
                        end
                    else
                        % case is the parameter value is fixed
                        nwLim = [obj.tMin,inf];
                    end
                    
                case 'tDurOff'
                    % case is the cycle off duration
                    if isRandC
                        % case is the parameter value is random
                        if ipVal == 1
                            % case is the minimum value is being altered
                            nwLim = [obj.tMin,pVal(2)];
                        else
                            % case is the maximum value is being altered
                            nwLim = [pVal(1),inf];
                        end
                    else
                        % case is the parameter value is fixed
                        nwLim = [obj.tMin,inf];
                    end
                    
                case 'sAmp'
                    % case is the signal amplitude
                    if isRandC
                        % case is the parameter value is random
                        if ipVal == 1
                            % case is the minimum value is being altered
                            nwLim = [obj.sAmpMin,pVal(2)];
                        else
                            % case is the maximum value is being altered
                            nwLim = [pVal(1),100];
                        end
                    else
                        % case is the parameter value is fixed
                        nwLim = [obj.sAmpMin,100];
                    end
                    
            end
            
        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %                
        
        % --- copies the values from the parameter class object, sParaNw
        function setParaValue(obj,sParaNw)
                        
            for i = 1:length(obj.pFldC)
                if isfield(sParaNw,obj.pFldC{i})
                    obj.(obj.pFldC{i}) = sParaNw.(obj.pFldC{i});
                end
            end            
            
        end
        
        % --- outputs the parameter values to a data struct, sParaC
        function sParaC = copyParaValue(obj)
            
            % memory allocation
            sParaC = struct('sObj',obj.sObj);
            
            % field retrieval to data struct
            for i = 1:length(obj.pFldC)
                sParaC.(obj.pFldC{i}) = obj.(obj.pFldC{i});
            end
            
        end
        
        % --- determines if there has been a change in parameters
        function isChange = isParaChange(obj)
            
            % retrieves the current parameter values (ignores time offset)
            sParaC = obj.copyParaValue();
            sParaC.tOfs = obj.sPara0.tOfs;
            
            % determines if there is a change in parameter structs
            isChange = ~isequal(sParaC,obj.sPara0);
            
        end
        
        % --- checks the signal duration is feasible
        function [eState,tDurMin] = checkSignalDur(obj)
            
            % field retrieval and initialisations
            [eState,errType] = deal(1,0);
            tDurMlt = getTimeMultiplier(obj.tDurU,obj.tDurTotU);
            
            % calculates the scaled time offset/total duration
            tOfsNw = obj.tOfs*getTimeMultiplier(obj.tDurU,obj.tOfsU);
            tDurTotNw = obj.tDurTot*tDurMlt;
            
            % retrieves the currently selected block
            sBlkS = obj.objSM.getSelectedTrain();
            if isempty(sBlkS)
                % case is no stimuli blocks selected (so use full train)
                [tHi,addStr] = deal(tDurTotNw,'');
            else
                % otherwise, get the selected stimuli block
                
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
                eState = double((obj.tDur <= (tHi - tOfsNw)));
            end
            
            % determines if the signal duration exceeds the max duration
            tDurMin = (obj.tDur + tOfsNw)/tDurMlt;
            
            % outputs the error message
            if ~eState
                % initialisations
                tStr = 'Infeasible Signal Parameters';
                
                switch errType
                    case 1
                        % case is signal offset is less than lower limit
                        eStr = sprintf(['The signal offset (%.2f%s) ',...
                            'lies an existing signal block. Re-select ',...
                            'another value which is feasible.'],...
                            tOfsNw,obj.tDurU);
                        waitfor(msgbox(eStr,tStr,'modal'))
                        
                    case 2
                        % case is upper time exceeds total signal duration
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
                        
                        % adds in the question part of the message
                        eStr = sprintf(['%s\n\nAlternatively, would ',...
                            'you like to expand the Signal Duration ',...
                            'to match the new configuration?'],eStr);
                        
                        % prompts the user if they wish to reset the 
                        % parameter, or expand the total signal duration
                        uChoice = questdlg(eStr,tStr,'Reset Parameter',...
                            'Expand Duration','Reset Parameter');
                        eState = 2*strcmp(uChoice,'Expand Duration');
                end
            end
            
        end
                
        % --- performs the temporal field checks
        function [upDur,upC] = checkTemporalFields(obj,pStr,isSW)
            
            % initialisation
            [upDur,upC] = deal(false);
            
            % scales the time values dependent on the signal type
            if isSW
                % case is the squarewave signals
                [~,tDurOnNw,tDurOffNw] = scaleTimePara(obj,isSW);
            else
                % case is the non-squarewave signals
                [~,tCycleNw] = scaleTimePara(obj,isSW);
            end
            
            switch pStr
                case {'tDurOn','tDurOff'} 
                    % case is the square on/off duration
                    
                    % flag that both the duration/count need updating
                    [upDur,upC] = deal(true);
                    
                    % recalculates the signal duration
                    tDurNw = tDurOnNw.*obj.nCount + ...
                             tDurOffNw.*(obj.nCount-1);
                    
                    % recalculates the cycle count
                    if obj.isRand
                        obj.nCount = (tDurNw + tDurOffNw)./...
                            (tDurOffNw + tDurOnNw);
                        if mod(obj.nCount,1) ~= 0
                            % if the count is not an integer then recalculate
                            obj.nCount = max(1,floor(obj.nCount));
                            obj.tDur = tDurOnNw*obj.nCount + ...
                                       tDurOffNw*(obj.nCount-1);
                        end
                    else
                        obj.tDur = tDurNw;
                    end
                    
                case 'tCycle' % case is the non-square cycle duration
                    
                    % flag that the duration needs updating
                    upDur = true;
                    
                    % recalculates the signal duration
                    obj.tDur = obj.nCount*tCycleNw;
                    
                case 'tDur' % case is the signal duration
                    
                    % flag that the count needs updating
                    upC = true;
                    
                    % recalculates the repetition count
                    if isSW
                        % case is for the square waveforms
                        obj.nCount = (obj.tDur + tDurOffNw)/...
                                     (tDurOffNw + tDurOnNw);
                        if mod(obj.nCount,1) ~= 0
                            % if count is not an integer then recalculate
                            obj.nCount = max(1,floor(obj.nCount));
                            if ~strcmp(obj.dType,'Random')
                                upDur = true;
                                obj.tDur = tDurOnNw*obj.nCount + ...
                                           tDurOffNw*(obj.nCount-1);
                            end                            
                        end
                        
                    else
                        % case is the other waveforms
                        obj.nCount = obj.tDur/tCycleNw;
                        if mod(obj.nCount,1) ~= 0
                            % if count not an integer then recalculate
                            obj.nCount = max(1,floor(obj.nCount));
                            obj.tDur = tCycleNw*obj.nCount;
                            
                            % flag that the duration needs updating
                            upDur = true;
                        end
                    end
                    
                case 'nCount' % case is the total cycle count
                    
                    % flag that the duration needs updating
                    upDur = true;
                    
                    % recalculates the entire signal duration
                    if isSW
                        % case is a squarewave
                        obj.tDur = tDurOnNw*obj.nCount + ...
                                   tDurOffNw*(obj.nCount-1);
                        
                    else
                        % case is the other waveforms
                        obj.tDur = tCycleNw*obj.nCount;
                    end
                    
            end
            
        end
        
        % --- calculates the signal duration
        function calcSignalDur(obj)
            
            switch obj.dType
                case 'Square'
                    % case is the square stimuli signals
                    tOn = obj.tDurOn*obj.nCount;
                    tOff = obj.tDurOff*(obj.nCount-1);
                    obj.tDur = obj.tOfs + tOn + tOff;
                    
                case 'Random'
                    % case is the random square stimuli signals
                    nCount0 = flip(obj.nCount);
                    tOn = obj.tDurOn(1:2).*nCount0;
                    tOff = obj.tDurOff(1:2).*(nCount0-1);
                    obj.tDur = obj.tOfs + mean(tOn + tOff);
                    
                otherwise
                    % case is the other stimuli signal types
                    obj.tDur = obj.tOfs + obj.tCycle*obj.nCount;
            end            
            
        end        
        
    end
    
    % static class methods
    methods (Static)
        
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
                    
                case {'tDurOn','tDurOff','tDur','tCycle'}
                    % case is the other stimuli temporal parameters
                    nwLim = [0.01,inf];
                    
                case {'sAmp','sAmp0','sAmp1'}
                    % case is the signal amplitude parameters
                    nwLim = [0,100];
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