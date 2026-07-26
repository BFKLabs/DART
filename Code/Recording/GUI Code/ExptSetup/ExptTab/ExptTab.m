classdef ExptTab < handle & dynamicprops
    
    % class properties
    properties
        
        % main class object handles
        hTab
        hPanelO
        hTimer
        
        % sub-class fields
        objAx       
        objSM
        objP
        objR
        
        % information panel class fields
        hPanel
        
        % axes panel class fields
        hPanelAx        
        hAx        

        % fixed object dimensions
        xAx = 70;
        yAx = 65;
        widPanel = 300;
        
        % calculated object dimensions
        hghtPanelO
        hghtPanel        
        widPanelO
        widPanelAx
        hghtAx
        widAx
        pAx
        
        % function handle class fields
        setPanelPropFcn
        clearTimerFcn        
        
        % boolean class fields
        isInit = false;
        
        % numerical class fields
        iType
        
        % static string class fields
        tagStr
        defMouseCursor = 'fleur';
        tStrS = {'','S','L','Ex'};

    end
    
    % observable class properties
    properties (SetObservable)
        
        % stimuli train fields
        sTrain
        
        % time-dependent parameter fields
        tDurTot
        tDurTotU
        
    end    
    
    % protected class properties
    properties (Access = protected)
        
        objB
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = ExptTab(objB,hTab,iType)
            
            % input arguments
            obj.objB = objB;
            obj.hTab = hTab;
            obj.iType = iType;
            
            % initialises the class fields/objects
            obj.linkParentProps();
            obj.initTabFields();
            obj.initTabObjects();
            obj.setListenerFunc();
                        
        end        
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class object fields with that parent object
        function linkParentProps(obj)
            
            % parent fields strings
            fldStr = {'hFig','hFigM','infoObj','objM','objT','objEx',...
                'objCS','iExpt','iProg','resInfo','iTab','isHLOn',...
                'hghtGrp','hghtLbl','hghtRow','hghtSlider',...
                'hghtBut','hghtTxt','hghtPopup','hghtEdit',...
                'hghtCheck','hghtRadio','axPosX','axPosY'...
                'mouseMoveFcn','mType','mpStrDef','isMouseDown',...
                'nCh','chName','chID','chInfo','chCol','sTrainP',...
                'dX','fSz','fSzL','fSzH','nDev','jTabGrpS',...
                'updateExptTabFcn','isOverAxesFcn','isStimOnly',...
                'calcExptStimDurFcn','hProg','objED'};
            
            % connects the base/child objects
            for propname = fldStr
                metaprop = addprop(obj, propname{1});
                metaprop.SetMethod = @(obj, varargin) ...
                    SetDispatch(obj, propname{1}, varargin{:});
                metaprop.GetMethod = @(obj)GetDispatch(obj, propname{1});
            end
            
        end
        
        % --- initialises the class fields
        function initTabFields(obj)
            
            % function handle fields
            obj.clearTimerFcn = @obj.clearPrevTimers;
            obj.setPanelPropFcn = @obj.setPanelEnableProps;
            
            % outer panel dimensions
            pPosT = getpixelposition(obj.hTab);
            obj.widPanelO = pPosT(3) - obj.dX;
            obj.hghtPanelO = pPosT(4) - (2*obj.dX + obj.hghtGrp);

            % other panel dimensions
            obj.hghtPanel = obj.hghtPanelO - obj.dX;
            obj.widPanelAx = obj.widPanelO - (1.5*obj.dX + obj.widPanel);
            
            % axes dimensions
            obj.hghtAx = obj.hghtPanel - (obj.dX + obj.yAx); 
            obj.widAx = obj.widPanelAx - (obj.dX + obj.xAx);
            obj.pAx = [obj.xAx,obj.yAx,obj.widAx,obj.hghtAx];
            
        end
        
        % --- initialises the class objects
        function initTabObjects(obj)

            % ------------------------- %
            % --- OUTER PANEL SETUP --- %
            % ------------------------- %
            
            % creates the experiment combining data panel
            pPosO = [obj.dX*[1,1]/2,obj.widPanelO,obj.hghtPanelO];
            obj.hPanelO = obj.setupHeadlessPanel(obj.hTab,pPosO);
            
            % exit if information tab
            if obj.iType == 1
                return
            end
            
            % ------------------------ %
            % --- INFO PANEL SETUP --- %
            % ------------------------ %
            
            % outer information panel
            pPosI = [obj.dX*[1,1]/2,obj.widPanel,obj.hghtPanel];
            obj.hPanel = obj.setupHeadlessPanel(obj.hPanelO,pPosI);
            
            % ------------------------ %
            % --- AXES PANEL SETUP --- %
            % ------------------------ %
            
            % outer information panel
            xPosAx = sum(pPosI([1,3])) + obj.dX/2;
            pPosAx = [xPosAx,obj.dX/2,obj.widPanelAx,obj.hghtPanel];
            obj.hPanelAx = obj.setupHeadlessPanel(obj.hPanelO,pPosAx);            
                        
        end
        
        % --- sets the listener function
        function setListenerFunc(obj)
            
            % retrieves observable parameter information
            mc = ?ExptTab;
            isObs = arrayfun(@(x)(x.SetObservable),mc.PropertyList);
            pStr = arrayfun(@(x)(x.Name),mc.PropertyList(isObs),'un',0);
                                    
            % sets the parameter listener functions
            for i = 1:length(pStr)
                addlistener(obj,pStr{i},'PostSet',...
                    @(s,e)obj.alterTabPara(s,e,pStr{i}));
            end
            
        end           

        % ------------------=------------------ %
        % --- SINGLE OBJECT SETUP FUNCTIONS --- %
        % ------------------------------------- %

        % --- creates text label object
        function hTxt = setupTextObject(obj,hP,pPosT,tStr,isLA)
            
            % default input arguments
            if ~exist('isLA','var')
                isLA = false;
            end
                        
            % object creation
            hTxt = createUIObj('text',hP,'String',tStr,...
                'Position',pPosT,'FontWeight','Bold','FontSize',obj.fSzL);
            
            % sets the horizontal alignment flags
            if isLA
                hTxt.HorizontalAlignment = 'Left';
            else
                hTxt.HorizontalAlignment = 'Center';                
            end
            
        end        
        
        % --- creates text label object
        function hTxt = setupTextLabel(obj,hP,pPosT,tStr)
            
            % field setup
            tStr = sprintf('%s: ',tStr);
            
            % object creation
            hTxt = createUIObj('text',hP,'String',tStr,...
                'Position',pPosT,'FontWeight','Bold',...
                'FontSize',obj.fSzL,'HorizontalAlignment','Right');
            
        end
        
        % --- creates editbox object
        function hEdit = setupEditBox(obj,hP,pPosE,tStr,isLA)
            
            % object creation
            hEdit = createUIObj('edit',hP,'Position',pPosE,...
                'FontSize',obj.fSz,'HorizontalAlignment','Center');                                                
            
            % sets the editbox value (if provided)
            if exist('tStr','var')
                hEdit.String = tStr;                
            end
            
            % sets the editbox alignment
            if exist('isLA','var') && isLA
                hEdit.HorizontalAlignment = 'Left';
            else
                hEdit.HorizontalAlignment = 'Center';
            end            
            
        end
        
        % --- creates the checkbox object
        function hChk = setupCheckBox(obj,hP,pPosC,cStr)

            % object creation            
            hChk = createUIObj('checkbox',hP,'String',cStr,...
                'Position',pPosC,'FontWeight','Bold',...
                'FontSize',obj.fSzL);
            
        end
        
        % --- creates the pushbutton object
        function hBut = setupPushButton(obj,hP,pPosB,bStr)
            
            hBut = createUIObj('pushbutton',hP,...
                'Position',pPosB,'FontSize',obj.fSzL,...
                'String',bStr,'FontWeight','bold');
            
        end
        
        % --- creates the checkbox object
        function hPopup = setupPopupMenu(obj,hP,pPosP,pStr)
            
            % object creation
            hPopup = createUIObj('Popupmenu',hP,'Position',pPosP,...
                'FontSize',obj.fSz);
            
            % sets the other checkbox fields
            if exist('pStr','var') && ~isempty(pStr)
                hPopup.String = pStr;
            else
                hPopup.String = {''};                
            end
            
        end        
        
        % --- creates the listbox object
        function hList = setupListBox(obj,hP,pPosL,lStr)
            
            % object creation
            hList = createUIObj('Listbox',hP,'Position',pPosL,...
                'FontSize',obj.fSz);
            
            % sets the listbox strings (if available)
            if ~exist('lStr','var') || isempty(lStr)
                set(hList,'Max',2,'String',[],'Value',[]);            
            else
                set(hList,'String',lStr);
            end
            
        end
        
        % --- creates the radiobutton object
        function hRadio = setupRadioButton(obj,hP,pPosR,rStr)
            
            hRadio = createUIObj('radiobutton',hP,...
                'Position',pPosR,'FontSize',obj.fSzL,...
                'FontWeight','Bold','String',rStr);            
            
        end        
        
        % --- creates a headed panel object
        function hPanel = setupHeadedPanel(obj,hP,pPos,tStr,isBG)

            % sets the panel type flag
            if exist('isBG','var') && isBG
                % case is a buttongroup
                pType = 'buttongroup';
            else
                % case is a panel
                pType = 'panel';
            end                  
            
            hPanel = createUIObj(pType,hP,'FontSize',obj.fSzH,...
                'Title',tStr,'Position',pPos,'FontWeight','Bold',...
                'Units','Pixels');        
        
        end                
        
        % -------------------------------------- %
        % --- SPECIAL OBJECT SETUP FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- sets up the text/label group
        function [hTxt,hTxtL] = setupTxtLabelGroup(obj,hP,pPosT,tStrL,wTxt,isLA)
            
            % default input arguments
            if ~exist('isLA','var')
                isLA = false;
            end
                        
            % creates the text label object
            pPosTL = [pPosT(1:2),wTxt(1),obj.hghtTxt];
            hTxtL = obj.setupTextLabel(hP,pPosTL,tStrL);
            
            % creates the text label object
            xPosT = sum(pPosTL([1,3]));
            pPosT = [xPosT,pPosT(2),wTxt(2),obj.hghtTxt];
            hTxt = obj.setupTextObject(hP,pPosT,'N/A',isLA);
                        
        end        
        
        % --- sets up the text/popupmenu group
        function [hPopup,hTxt] = ...
                setupPopupGroup(obj,hP,pPos,tStrL,wObj,tStrP)
        
            % creates the text label
            pPosT = [pPos(1),pPos(2)+2,wObj(1),obj.hghtTxt];
            hTxt = obj.setupTextLabel(hP,pPosT,tStrL);
             
            % creates the popupmenu item
            pPosP = [sum(pPosT([1,3])),pPos(2),wObj(2),obj.hghtPopup];
            hPopup = obj.setupPopupMenu(hP,pPosP);
            
            % sets the popupmenu string list (if provided)
            if exist('tStrP','var')
                hPopup.String = tStrP;
            end            
            
        end
        
        % --- sets up the text/editbox group
        function [hEdit,hTxt] = setupEditGroup(obj,hP,pPos,tStrL,wObj,isLA)
        
            % default input arguments
            if ~exist('isLA','var')
                isLA = false;
            end            
            
            % creates the text label
            pPosT = [pPos(1),pPos(2)+2,wObj(1),obj.hghtTxt];
            hTxt = obj.setupTextLabel(hP,pPosT,tStrL);
             
            % creates the popupmenu item
            pPosP = [sum(pPosT([1,3])),pPos(2),wObj(2),obj.hghtPopup];
            hEdit = obj.setupEditBox(hP,pPosP,'',isLA);
            
            % sets the popupmenu string list (if provided)
            if exist('tStrP','var')
                hEdit.String = tStrP;
            end            
            
        end        
        
        % --- sets up the text/double editbox group
        function [hEdit,hTxt] = setupDblEditGroup(obj,hP,pPos,tStrL,wObj)
            
            % creates the text label
            pPosT = [pPos(1),pPos(2)+2,wObj(1),obj.hghtTxt];
            hTxt = obj.setupTextLabel(hP,pPosT,tStrL);
            
            % creates the popupmenu item
            hEdit = cell(1,2);
            xPosP = sum(pPosT([1,3]));
            for i = 1:length(hEdit)
                pPosP = [xPosP,pPos(2),wObj(i+1),obj.hghtPopup];
                hEdit{i} = obj.setupEditBox(hP,pPosP);
                xPosP = xPosP + (wObj(i+1) + obj.dX/2);
            end
            
        end        

        % --- sets up the text/double editbox group
        function [hEdit,hCheck,hTxt] = ...
                setupDblChkEditGroup(obj,hP,pPos,tStrL,wObj)
            
            % creates the text label
            pPosT = [pPos(1),pPos(2)+2,wObj(1),obj.hghtTxt];
            hTxt = obj.setupTextLabel(hP,pPosT,tStrL);
            
            % creates the checkbox
            xPosC = sum(pPosT([1,3]));
            pPosC = [xPosC,pPos(2),wObj(2)*[1,1]];
            hCheck = obj.setupCheckBox(hP,pPosC,'');
            
            % creates the popupmenu item
            hEdit = cell(1,2);
            xPosP = sum(pPosC([1,3]));
            for i = 1:length(hEdit)
                pPosP = [xPosP,pPos(2),wObj(i+2),obj.hghtPopup];
                hEdit{i} = obj.setupEditBox(hP,pPosP);
                xPosP = xPosP + (wObj(i+2) + obj.dX/2);
            end
            
        end        
        
        % --- sets up the duration popupmenu group
        function hPopup = setupDurationGroup(obj,hP,pPos0,wObj,iType,isZD)
            
            % default input arguments
            if ~exist('isZD','var')
                isZD = [true,false,true,true];
            end
            
            % field initialisation
            tDurD = [30,12,59,59];            
            
            % sets the grouping type fields
            switch iType
                case 1
                    % case is the full duration grouping
                    tStrD = {'Days','Hours','Minutes','Seconds'}; 
                    tDurD(2) = 23;
                    
                case 2
                    % case is the full duration grouping
                    tStrD = {'Days','Hours','Mins','Secs'};                     
                    
                case 3
                    % case is the partial duration grouping
                    tStrD = {'Hrs','Mins','Secs'};
                    [tDurD,isZD] = deal(tDurD(2:end),isZD(2:end));
            end            
            
            % memory allocation
            xPosD = pPos0(1);
            nPopup = length(tStrD);
            hPopup = cell(nPopup,1);
            
            % creates the popup/text label objects
            for i = 1:nPopup
                % creates the popup object
                pStrP = obj.setupNumStringArray(tDurD(i),isZD(i));
                pPosP = [xPosD,pPos0(2),wObj,obj.hghtPopup];
                hPopup{i} = obj.setupPopupMenu(hP,pPosP,pStrP);
                hPopup{i}.UserData = i;
                
                % creates the label
                pPosP([2,4]) = [(pPosP(2)+obj.hghtRow),obj.hghtTxt];
                obj.setupTextObject(hP,pPosP,tStrD{i});
                
                % increments the left offset
                xPosD = xPosD + (wObj + obj.dX/2);
            end
            
        end
        
        % --- sets up the date popupmenu group
        function hPopup = setupDateGroup(obj,hP,pPos0,wObj,iType)
            
            % field initialisation
            tStrD = {'Month','Day','Time','','AM/PM'};

            % field reduction (if reduced date group)
            if iType == 2
                tStrD = tStrD(3:end);
            end
            
            % memory allocation
            xPosD = pPos0(1);
            yPosD = pPos0(2)+obj.hghtRow;
            nPopup = length(tStrD);
            hPopup = cell(nPopup,1);
            
            % creates the popup/text label objects
            for i = 1:nPopup
                % sets the popup strings
                switch tStrD{i}
                    case 'Month'
                        % case is the month field
                        pStrP = obj.getMonthStrings();
                        
                    case 'Day'
                        % case is the day field
                        pStrP = obj.setupNumStringArray(30,0);
                        
                    case 'AM/PM'
                        % case is the AM/PM field
                        pStrP = {'AM','PM'};
                        
                    case 'Time'
                        % case is the hours field
                        pStrP = obj.setupNumStringArray(12,0);
                        
                    otherwise
                        % case is the minutes field
                        pStrP = obj.setupNumStringArray(59,1);
                end                
                
                % creates the popup object                                
                pPosP = [xPosD,pPos0(2),wObj(i),obj.hghtPopup];
                hPopup{i} = obj.setupPopupMenu(hP,pPosP,pStrP);                
                hPopup{i}.UserData = i;
                
                % creates the label
                if isempty(tStrD{i})
                    % case is the separator
                    pPosP = [xPosD-4,pPos0(2)+2,3,obj.hghtTxt];
                    obj.setupTextObject(hP,pPosP,':');
                elseif strcmp(tStrD{i},'Time')
                    % case is the time field
                    pPosT = [xPosD,yPosD,sum(wObj(i+(0:1))),obj.hghtTxt];
                    obj.setupTextObject(hP,pPosT,tStrD{i});                    
                else
                    % case is the other field
                    pPosP([2,4]) = [yPosD,obj.hghtTxt];
                    obj.setupTextObject(hP,pPosP,tStrD{i});                    
                end
                
                % increments the left offset
                xPosD = xPosD + (wObj(i) + obj.dX/2);                
            end
            
        end
        
        % --- sets up a multi-column button group
        function hBut = setupButtonGrouping(obj,hP,bStr,wBut,nCol,yPosB)
            
            % default input arguments
            if ~exist('yPosB','var')
                yPosB = hP.Position(4) - (obj.dX/2 + obj.hghtBut);                
            end
                        
            % button group creation
            hBut = cell(length(bStr),1);                        
            for i = 1:length(bStr)
                % column index
                iCol = mod(i-1,2) + 1;
                
                % button creation
                xPosB = obj.dX/2 + (iCol-1)*wBut;
                pPosB = [xPosB,yPosB,wBut,obj.hghtBut];
                hBut{i} = obj.setupPushButton(hP,pPosB,bStr{i});
                
                % decrements the vertical offset
                if iCol == nCol
                    yPosB = yPosB - obj.hghtBut;
                end                
            end
            
        end        

        % ---------------------------------------- %
        % --- COMMON OBJECT CALLBACK FUNCTIONS --- %
        % ---------------------------------------- %        
        
        % --- add signal pushbutton callback function
        function buttonAddStimObj(obj,varargin)
                                            
            if obj.iType == 4
                % case is the experiment protocol tabs                
                
                % determines if the new block placement is feasible
                tLimF = obj.objSM.newBlockObjCheck();
                if ~isempty(tLimF)
                    % if so, then create a new stimuli block
                    obj.objSM.createBlockObj(tLimF);
                    obj.addExptBlockObj();
                    
                    % updates the stimuli device inclusion flags
                    obj.objB.setFeasFlag('StimProto',true);   % => finish me!
                end
                
            else
                % case is the stimuli protocol tabs
                
                % flag that a stimuli train object is being added
                obj.objB.figButtonDownFcn([],[],'alt');
                obj.mType = 1;

                % updates the mouse cursor
                obj.objSM.resetCustomMousePointer();
            end
            
        end
        
        % --- deselect signal pushbutton callback function
        function buttonDeselectStimObj(obj,hObj,~)
            
            % deselects the current object
            feval(obj.hFig.WindowButtonDownFcn,[],[],'alt');
            
            % disables the button
            setObjEnable(hObj,'off');
            
        end        
        
        % ------------------------------------------- %
        % --- PARAMETER UPDATE LISTENER FUNCTIONS --- %
        % ------------------------------------------- %
        
        % --- repetition parameter update listener function
        function alterTabPara(obj,~,~,pStr)
            
            switch pStr
                case {'tDurTot','tDurTotU'}
                    if ~isempty(obj.objAx)
                        obj.objAx.resetTotalDuration();
                    end
                                        
                case 'sTrain'
                    % case is the stimuli train
                    obj.sTrainP.(obj.tStrS{obj.iType}) = obj.sTrain;
            end
            
        end                
        
        % ----------------------------------- %
        % --- MAIN FIGURE EVENT FUNCTIONS --- %
        % ----------------------------------- %        
        
        % --- mouse motion callback function
        function exptTabMouseMove(obj,hHover)
            
            % if no hover object, then remove highlight            
            if isempty(hHover)
                if ~any(obj.mType == [3,5])
                    obj.removeChannelHighlight(true);
                elseif obj.mType == 5
                    obj.mpStrDef = 'arrow';                    
                end
                    
                return
            end
            
            switch obj.mType
                case 2
                    % case is the placement of a stimuli train
                    obj.objSM.exptTrainPlace(hHover);

                case 3
                    % case is the movement of a stimuli train
                    obj.objSM.exptTrainMove(hHover);                

                case 4
                    % case is the placement of a stimuli block
                    obj.objSM.exptBlockPlace(hHover);

                case 5
                    % case is the movement of a stimuli block
                    obj.objSM.exptBlockMove(hHover);
            end
            
        end
        
        % --- resets the channel highlight
        function resetChannelHighlight(obj,hHoverCh)

            %
            if obj.iType < 4
                obj.objSM.removeAllChannelHighlights();
            end
            
            % resets the channel highlight
            if ~any(obj.mType == [3,5])
                obj.objSM.resetChannelHighlight(hHoverCh);
            end
            
        end
        
        % --- removes the stimuli block object highlight
        function removeChannelHighlight(obj,resetCursor)
            
            % removes the channel highlight
            obj.objSM.removeChannelHighlight(resetCursor);
            
        end        
        
        % --- stimuli block feasibility check
        function stimObjCheck(obj)
            
            if obj.objSM.isStimObjFeas()
                obj.objSM.updateTempStimObj();
                obj.mType = 2*(1 + (obj.iTab == 4));
            else
                obj.mType = 1;
                obj.objSM.sBlkT.setObjVisibility(0);
                obj.objSM.objDL.setLineVisible('off');
            end
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %                          
    
%         % --- dialog initialisation check function
%         function dialogInitCheck(obj)
%             
%             if all(cellfun(@(x)(x.isInit),obj.objT)) 
%                 
%             end
%             
%         end        
        
        % --- sets the panel enabled properties
        function setPanelEnableProps(obj,actType,isOn,varargin)
                                   
            switch actType
                case 'BlockProps'
                    % case is the expt protocol block panel objects
                    
                    % sets the button properties
                    setObjEnable(obj.hButB{1},~isOn)
                    cellfun(@(x)(setObjEnable(x,isOn)),obj.hButB(2:3));
                    
                    % enables the delete button (if flagged)
                    if ~isempty(varargin)
                        setObjEnable(obj.hButB{4},~isempty(obj.sTrain))
                    end                    
                
                case 'SignalProps'
                    % case is the signal stimuli panel objects
                    
                    % sets the button properties
                    setObjEnable(obj.hButS{1},~isOn)
                    cellfun(@(x)(setObjEnable(x,isOn)),obj.hButS(2:3));
                    setObjEnable(obj.hButC{1},isOn)                    
                    
                    % enables the delete button (if flagged)
                    if ~isempty(varargin)
                        setObjEnable(obj.hButS{4},isOn)
                    end
                    
                case {'SaveTrain'}
                    % case is saving a stimuli train
                    
                    % common properties
                    cellfun(@(h)(setObjEnable(h,isOn)),obj.hButT(2:4))
                    
                case {'ListTrain'}
                    
                    % 
                    obj.setPanelEnableProps('SaveTrain',isOn)
                    obj.setPanelEnableProps('DeleteTrain',isOn)
                    
                case {'DeleteTrain','ClearChannel'}
                    % case is deleting train/clearing channel
                    
                    % common property updates
                    setObjEnable(obj.hButC{2},isOn);
                    
                    % stimuli tab only property updates
                    if obj.iType < 4
                        setObjEnable(obj.hButT{1},isOn);
                    end
                    
                    % short-term stimuli only property updates
                    if obj.isShort
                        setObjEnable(obj.hButTT,isOn);
                    end
                    
                case 'DeleteAllTrain'
                    % case is deleting all train objects
                    
                    % button property updates
                    setObjEnable(obj.hButP{1},'off')
                    setObjEnable(obj.hButS{4},'off')
                    setObjEnable(obj.hButC{2},'off')
                    setPanelProps(obj.hPanelT,'off',{obj.hListT});
                    
                case 'DeleteBlock'
                    % case is deleting a single block
                    
                    % field retrieval
                    iBlkS = varargin{1};
                    
                    % common property updates
                    setObjEnable(obj.hButB{1},'on');
                    cellfun(@(x)(setObjEnable(x,'off')),obj.hButB(2:3))
                    setObjEnable(obj.hButB{4},isOn);
                    
                    % resets the listbox strings
                    indL = ~setGroup(iBlkS(:),size(obj.hListB.String));
                    set(obj.hListB,'Max',2,'Value',[],...
                        'String',obj.hListB.String(indL));
                    
                    % updates the feasibility flags
                    obj.objT{1}.setFeasFlag('AllStimProto',isOn);
                    
                case 'DeleteAllBlock'
                    % case is deleting all block objects
                    
                    % removes all blocks from the list
                    indL = 1:length(obj.hListB.String);
                    obj.setPanelEnableProps('DeleteBlock',false,indL);
                    
            end
            
        end        
        
        % --- retrieves the minimum experiment duration
        function tMin = getMinExptDuration(obj,tUnitsC)
                               
            % retrieves the signal blocks for the
            if ~obj.infoObj.hasDAQ || (obj.objT{4}.objSM.nObj == 0)
                % case is there are no experiment signal blocks
                tMin = 0;
            else
                % case is there are experiment signal blocks
                sBlk = obj.objT{4}.objSM.sBlk;
                sPos = cell2mat(cellfun(@(x)(...
                    x.hRectS.getPosition()),sBlk(:),'un',0));
                [tOfsB,tDurB] = deal(sPos(:,1),sPos(:,3));                
                
                % ensures all durations have the same units
                tUnits = cellfun(@(x)(x.tDurTotU(1)),sBlk,'un',0);
                if length(unique(tUnits)) > 1
                    tOfsB = cellfun(@(x,y)(convertTime(...
                        x,y,tUnits{1})),num2cell(tOfsB),tUnits);
                    tDurB = cellfun(@(x,y)(convertTime(...
                        x,y,tUnits{1})),num2cell(tDurB),tUnits);
                end
                
                % calculates the overall minimum durations
                tMin = max(tOfsB+tDurB);                
                if exist('tUnitsC','var')
                    tMin = convertTime(tMin,tUnits{1},tUnitsC);
                end
            end
            
        end        
        
        % --- sets the start time popupmenu item values
        function setStartTimeValues(obj,hPopup,iOfs)
            
            % default input arguments
            if ~exist('iOfs','var'); iOfs = 0; end
            
            % field retrieval
            tStart = obj.iExpt.Timing.T0;
            
            % updates the popup menu items based on their type/value
            for i = 1:length(hPopup)
                j = i + iOfs;
                switch j
                    case {1,2} % case is the month/day popup menus
                        set(hPopup{i},'Value',tStart(j+1));
                        
                    case 3 % case is the hour popup menu
                        set(hPopup{i},'Value',mod(tStart(j+1)-1,12)+1);
                        
                    case 5 % case is the AM/PM popup menu
                        set(hPopup{i},'Value',1+(tStart(4)>=12))                        
                        
                    otherwise % case is the other menus
                        set(hPopup{i},'Value',tStart(j+1)+1);
                end
            end
            
        end        
        
        % --- experiment duration popupmenu change callback function
        function popupExptDur(obj,hObject,evnt)
            
            % field retrieval
            iFld = hObject.UserData;
            Timing = obj.iExpt.Timing;
            [pStr,iVal] = deal(hObject.String,hObject.Value);
            [T0,tMin] = deal(Timing.Texp(iFld),0);
            
            % experiment duration field update
            if exist('evnt','var')
                % updates the experiment duration field
                obj.iExpt.Timing.Texp(iFld) = str2double(pStr{iVal});
                if ~isnumeric(evnt)
                    % if a popupmenu event, then calculate min expt time
                    tMin = obj.getMinExptDuration();
                end
            end
            
            % total experiment duration (in seconds)
            tExp = vec2time(obj.iExpt.Timing.Texp,Timing.TexpU);

            % determines if the expt duration is feasible
            if tExp == 0
                % case is a zero duration experiment error
                obj.showError('Zero Experiment Duration')
                
            elseif tExp >= tMin                
                % updates the complementary expt duration popupmenu object
                if isequal(obj.objT{1}.hPanelD,hObject.Parent)
                    % case is the expt info popupmenu was updated
                    obj.objT{4}.hPopupD{iFld}.Value = iVal;
                else
                    % otherwise the expt protocol popupmenu was updated
                    obj.objT{1}.hPopupD{iFld}.Value = iVal;
                end
                
                % updates the expt protocol plot axes/tab object properties
                [~,obj.iExpt.Timing.TexpU] = vec2time(obj.iExpt.Timing.Texp);
                obj.objT{1}.calcVidTiming();
                
                % stimuli-dependent field updates
                if obj.infoObj.hasDAQ
                    obj.objT{4}.objAx.resetTotalDuration();
                    setObjEnable(obj.objT{4}.hButD,tExp>tMin);
                end
                
                % determine if the video duration exceeds the expt
                tVid = vec2sec([0,obj.iExpt.Video.Dmax]);
                if tVid > vec2sec(obj.iExpt.Timing.Texp)
                    obj.resetDurTimeValues(obj.objT{1}.hPopupRD);                    
                end                
                
                % exits the function
                return
                
            else
                % case is the experiment doesn't meet required minimum
                tExpV = obj.getTimeVectorString(tExp,Timing.TexpU);
                tMinV = obj.getTimeVectorString(tMin,Timing.TexpU);
                obj.showError('Infeasible Experiment Duration',tExpV,tMinV)
            end
            
            % reset the duration to the last valid value
            obj.iExpt.Timing.Texp(iFld) = T0;
            set(hObject,'Value',T0+1);
                        
        end        
        
        % --- resets video duration popupmenu values
        function resetDurTimeValues(obj,hPopup,showErr,Dmax)
            
            % outputs an error message (if stated)
            if exist('showErr','var') && showErr
                tStr = 'Video Duration Reset';
                eStr = {['Maximum video duration exceeds ',...
                         'experiment duration.'];...
                        ['Resetting video duration equal to ',...
                         'the experiment duration.']};
                waitfor(msgbox(eStr,tStr,'modal'));
            end
            
            % resets the video duration to the experiment duration
            if exist('Dmax','var')
                obj.iExpt.Video.Dmax = Dmax;
            else
                obj.iExpt.Video.Dmax = obj.iExpt.Timing.Texp(2:end);
            end
            
            % resets the duration popupmenu values
            obj.setDurTimeValues(hPopup,obj.iExpt.Video.Dmax);
            
        end
            
        % --- object property reset timer wrapper function
        function resetObjectPropsTimer(obj,sTrainT)
            
            % disables the panel 
            obj.jTabGrpS.setEnabledAt(obj.iType-1,0)               
            
            % timer object
            obj.hTimer = timer(...
                'StartDelay',0.1*(obj.iType-1),...
                'TimerFcn',{@obj.resetObjectProps,sTrainT},...
                'Tag',obj.tagStr);                        
            
            % starts the timer object
            start(obj.hTimer);
            
        end
        
    end
    
    % static class methods
    methods (Static)
        
        % --- shows the error message associated with title string, tStr
        function showError(tStr,varargin)
            
            % sets the error string based on title string
            switch tStr
                case 'Incorrect Video Duration'
                    % case is invalid video duration
                    eStr = ['Error! Video duration must be ',...
                            'greater than zero.'];
                        
                case 'Existing Output Directory'
                    % case is output directory already exists 
                    eStr = {['Warning! Output directory ',...
                             'already exists.'];...
                            ['Enter a unique directory to enable ',...
                             'experiment start.']};
                         
                case 'Zero Experiment Duration'
                    % case is a zero-duration experiment error
                    eStr = ['The experiment duration must be ',...
                            'greater than zero.'];
                    
                case 'Infeasible Experiment Duration'
                    % case is an infeasible experiment duration
                    [tExpV,tMinV] = deal(varargin{1},varargin{2});
                    eStr = sprintf(['The specified experiment ',...
                            'duration (%s) does not include all ',...
                            'experiment stimuli blocks (%s). To ',...
                            'remedy this either:\n\n * Set a longer ',...
                            'experiment duration\n * Delete or move ',...
                            'one or more experiment stimuli blocks.'],...
                            tExpV,tMinV);  
                        
                case 'Infeasble Stimuli Train'
                    % case is an infeasible stimuli train
                    eStr = sprintf(['The new stimuli train parameters ',...
                            'now makes the experimental protocol ',...
                            'infeasible. To remedy this either:\n\n',...
                            ' * Delete or move the dependent ',...
                            'experimental blocks\n * Set a different ',...
                            'stimuli train configuration']);
            end
            
            % displays the error message
            waitfor(msgbox(eStr,tStr,'modal'))
            
        end
        
        % --- sets up the number string array
        function nArr = setupNumStringArray(nMax,isZero)
            
            % --- converts the number value to a string
            function nStr = convertNumStr(nVal)
                
                if nVal < 10
                    nStr = sprintf('0%i',nVal);
                else
                    nStr = num2str(nVal);
                end
                
            end
            
            % sets up the number string array
            xiN = (1-isZero):nMax;
            nArr = arrayfun(@(x)(convertNumStr(x)),xiN(:),'un',0);
            
        end        
        
        % --- creates a headless panel object
        function hPanel = setupHeadlessPanel(hP,pPos,isBG)
            
            % sets the panel type flag
            if exist('isBG','var') && isBG
                % case is a buttongroup
                pType = 'buttongroup';
            else
                % case is a panel
                pType = 'panel';
            end
            
            % creates the panel object
            hPanel = createUIObj(pType,...
                hP,'Title','','Units','Pixels','Position',pPos);
            
        end
        
        % --- creates the slider object
        function hSlider = setupSlider(hP,pPosS,pRng)
            
            % default input arguments
            if ~exist('pRng','var')
                pRng = [0, 1];
            end
            
            hSlider = createUIObj('slider',hP,...
                'Position',pPosS,'Min',pRng(1),'Max',pRng(2));
            
        end        
        
        % --- retrieves the month strings
        function mStr = getMonthStrings()
           
            mStr = month(datetime(2024, 1:12, 1)', 'name');
            
        end        
        
        % --- sets the object user data flags
        function setObjUserDataFlags(hObj,iOfs)
            
            % default input arguments
            if ~exist('iOfs','var'); iOfs = 0; end
            
            % sets the object userdata flags
            for i = 1:length(hObj)
                hObj{i}.UserData = i + iOfs;
            end
            
        end
        
        % --- sets the duration popupmenu item values
        function setDurTimeValues(hPopup,tVec)
            
            for i = 1:length(hPopup)
                set(hPopup{i},'Value',tVec(i)+1);
            end
            
        end                
        
        % --- deletes any previous timers with tag, tagStr
        function clearPrevTimers(tagStr)
            
            % deletes any old timer objects
            hTimerPr = timerfindall('tag',tagStr);
            if ~isempty(hTimerPr)
                deleteTimerObjects(hTimerPr)
            end
            
        end       
        
        % --- converts the time (in units, tUnits) to a time vector string
        function tVecStr = getTimeVectorString(t0,tUnits)
            
            % initialisations
            tVecStr = '';
            
            % converts time to seconds and then converts to a time vector
            tVec = sec2vec(t0*getTimeMultiplier('s',tUnits));
            
            %
            for i = 1:length(tVec)-1
                if (tVec(i) > 0) || ~isempty(tVecStr)
                    % sets the new string based on the time value
                    if tVec(i) == 0
                        % case is the new value is zero
                        nwStr = '00';
                    elseif tVec(i) < 10
                        % case is the new value is less than 10
                        nwStr = sprintf('0%i',tVec(i));
                    else
                        % case is the new value is >= 10
                        nwStr = sprintf('%i',tVec(i));
                    end
                    
                    if isempty(tVecStr)
                        tVecStr = nwStr;
                    else
                        tVecStr = sprintf('%s:%s',tVecStr,nwStr);
                    end
                end
                
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