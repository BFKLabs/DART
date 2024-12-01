classdef StartPoint < handle
    
    % class properties
    properties
        
        % main figure class fields
        hFig
                
        % tracking start panel object class fields
        hPanelS
        hRadioS
        hTxtS
        hEditS
        
        % phase start panel object class fields
        hPanelP
        hTableP
        hEditP
        
        % control button object class fields
        hPanelC
        hButC        
        
        % fixed object dimension fields
        dX = 10;
		dHght = 20;		
        hghtTxt = 16;
		hghtBut = 25;
	    hghtEdit = 22;
	    hghtRow = 25;		
		hghtRadio = 20;
        hghtPanelC = 40;
        widPanel = 270;
        widRadioS = 20;
        widTxtS = [185,200];
        widTxtP = 80;
        
        % calculated object dimension fields
        hghtFig
        widFig
        hghtPanelS
        hghtPanelP        
        widPanelP
        hghtTableP        
        widTableP
        widEditP
        widEditS
        widButC
        
        % temporary value class fields
        nFrmS
        nFrmMx
        nTrk
        nTot
        iPh
        iFrm0
        isTrk
        iPhase0
        iStack0                
        indStart
        
        % boolean class fields
        isOK = true;
        
        % static scalar fields
        nPhase
        nButC = 2;
        nColP = 5;
        nEditP = 2;
        nRadioS = 2;
        fSzL = 12;
        fSz = 10 + 2/3;
        
        % static string fields
        tagStr = 'figStartPoint';
        figName = 'Restart From...';        
        
    end
    
    % private class properties
    properties (Access = private)
        
        objT
                
    end
    
    % class methods
    methods
    
        % --- class constructor
        function obj = StartPoint(objT)
            
            % sets the input arguments
            obj.objT = objT;
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initClassObjects();    
            
            % waits for the user response
            uiwait(obj.hFig);
            
        end

        % -------------------------------------- %        
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)            
            
            % field retrieval
            obj.nFrmS = getFrameStackSize();            
            obj.nFrmMx = size(obj.objT.pData.fPos{1}{1},1);            
            obj.iPhase0 = obj.objT.iPhase0;
            obj.iStack0 = max(1,obj.objT.nCountS);                        
            
            % other field retrieval
            obj.calcFrameIndex();
            obj.nPhase = size(obj.objT.iMov.iPhase,1);
            
            % retrieves the first valid region/tube index
            iApp0 = find(obj.objT.iMov.ok,1,'first');            
            if iscell(obj.objT.iMov.flyok)
                iTube0 = find(obj.objT.iMov.flyok{iApp0},1,'first');
            else
                iTube0 = find(obj.objT.iMov.flyok(:,iApp0),1,'first');
            end
            
            % determines which frames have been tracked
            obj.iPh = obj.objT.iMov.iPhase(obj.objT.iPhaseS,:);
            obj.isTrk = ~isnan(obj.objT.pData.fPos{iApp0}{iTube0}(:,1));
            
            % determines the total number of stacks per phase
            nFrmPh = diff(obj.iPh,[],2) + 1;
            obj.nTot = ceil(nFrmPh/obj.objT.nFrmS);
            
            % determines the number of tracked stacks per phase
            obj.nTrk = ceil(cellfun(@(x)(sum(...
               obj.isTrk(x(1):x(2)))),num2cell(obj.iPh,2))/obj.objT.nFrmS);            
            
            % ------------------------------------- %
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- %            
            
            % table/panel height dimension calculations
            if obj.nPhase == 1
                % case is there is only one phase
                obj.nRadioS = 1;                
                obj.widRadioS = 0;  
                obj.hghtPanelS = obj.dX + obj.hghtRow;
                obj.widPanel = obj.widPanel - 2*obj.dX;
                
            else
                % case is there are multiple phases
                obj.hghtTableP = calcTableHeight(obj.nPhase);
                obj.hghtPanelP = obj.hghtTableP + 1.5*obj.dX + obj.hghtRow;
                obj.hghtPanelS = obj.hghtPanelP + 2*obj.hghtRow+1.5*obj.dX;
            end
                
            % figure dimension calculations
            obj.hghtFig = obj.hghtPanelS + obj.hghtPanelC + 2*obj.dX;
            obj.widFig = obj.widPanel + 2*obj.dX;            
            
            % other object dimension calculations (common)
            obj.widEditS = obj.widPanel - ...
                (obj.widRadioS + obj.widTxtS(1) + 2*obj.dX);            
            obj.widButC = (obj.widPanel - 2.5*obj.dX)/obj.nButC;
            
            % other object dimension calculations (multi-phase only)
            if obj.nPhase > 1
                obj.widPanelP = obj.widPanel - obj.dX;
                obj.widTableP = obj.widPanelP - obj.dX;            
                obj.widEditP = (obj.widPanelP - 2*(obj.widTxtP+obj.dX))/2;
            end
            
        end
        
        % --- initialises the class objects
        function initClassObjects(obj)
            
            % deletes any previous GUIs
            hPrev = findall(0,'tag',obj.tagStr);
            if ~isempty(hPrev); delete(hPrev); end
            
            % callback function
            cbFcnP = @obj.editParaUpdate;
            
            % --------------------------- %
            % --- MAIN FIGURE OBJECTS --- %
            % --------------------------- %
            
            % creates the figure object
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % creates the figure object
            obj.hFig = createUIObj('figure','Position',fPos,...
                'tag',obj.tagStr,'MenuBar','None','Toolbar','None',...
                'Name',obj.figName,'NumberTitle','off','Visible','off',...
                'AutoResizeChildren','off','CloseRequestFcn',[]);   
            
            % ------------------------------ %
            % --- CONTROL BUTTON OBJECTS --- %
            % ------------------------------ %
            
            % initialisations
            bStrC = {'Continue','Cancel'};
            cbFcnC = {@obj.buttonContinue,@obj.buttonCancel};
            
            % creates the control button objects
            pPosC = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelC];
            obj.hPanelC = createUIObj(...
                'Panel',obj.hFig,'Position',pPosC,'Title',''); 
            
            % other initialisations
            obj.hButC = cell(length(bStrC),1);
            for i = 1:length(bStrC)
                % sets up the button position vector
                lBut = obj.dX + (i-1)*(obj.widButC + obj.dX/2);
                bPos = [lBut,obj.dX-2,obj.widButC,obj.hghtBut];
                
                % creates the button object
                obj.hButC{i} = createUIObj('Pushbutton',obj.hPanelC,...
                    'Position',bPos,'Callback',cbFcnC{i},...
                    'FontUnits','Pixels','FontSize',obj.fSzL,...
                    'FontWeight','Bold','String',bStrC{i});
            end
            
            % --------------------------------- %
            % --- START FRAME PANEL OBJECTS --- %
            % --------------------------------- %

            % initialisations
            pStrS = 'iFrm0';
            cbFcnS = @obj.panelStartPoint;
            tStrR = {'Start From Global Video Frame',...
                     'Start From Specific Video Phase'};
            
            % creates the panel object
            yPosS = sum(pPosC([2,4])) + obj.dX/2;
            pPosS = [obj.dX,yPosS,obj.widPanel,obj.hghtPanelS];
            obj.hPanelS = createUIObj('ButtonGroup',obj.hFig,...
                'Position',pPosS,'Title','','SelectionChangedFcn',cbFcnS);            
            
            % creates the phase panel object
            if obj.nPhase == 1
                % case is there is only a single phase
                yOfs = obj.dX/2 + 2;
                
            else
                % case is there are multiple phases
                pPosP = [obj.dX*[1,1]/2,obj.widPanelP,obj.hghtPanelP];
                obj.hPanelP = createUIObj(...
                    'Panel',obj.hPanelS,'Position',pPosP,'Title','');
                yOfs = sum(pPosP([2,4])) + obj.dX/2;
            end
            
            % creates the other objects
            [obj.hRadioS,obj.hTxtS] = deal(cell(obj.nRadioS,1));
            for i = 1:obj.nRadioS
                % sets up the radio button position vector
                j = obj.nRadioS - (i-1);
                tStr = sprintf('%s: ',tStrR{i});
                
                % creates the radio button object
                yPosR = (j-1)*obj.hghtRow + yOfs;
                if obj.nPhase == 1
                    % case is single phase video
                    pPosR = [obj.dX,0,0,0];
                    
                else
                    % case is multiple phase video
                    pPosR = [obj.dX,yPosR,obj.widRadioS,obj.hghtRadio];
                    obj.hRadioS{i} = createUIObj(...
                        'radiobutton',obj.hPanelS,'Position',pPosR,...
                        'String','','UserData',i,'Value',i==1);
                end
                
                % creates the text label
                lPosT = sum(pPosR([1,3]));
                pPosT = [lPosT,yPosR+1,obj.widTxtS(i),obj.hghtTxt];
                createUIObj('text',obj.hPanelS,...
                    'Position',pPosT,'String',tStr,...
                    'FontWeight','Bold','FontSize',obj.fSzL,...
                    'HorizontalAlignment','Left');
                
                % creates the frame index editbox (first button only)
                if i == 1
                    lPosE = sum(pPosT([1,3]));
                    pPosE = [lPosE,yPosR-1,obj.widEditS,obj.hghtEdit];
                    obj.hEditS = createUIObj('edit',obj.hPanelS,...
                        'Position',pPosE,'String',num2str(obj.iFrm0),...
                        'FontSize',obj.fSz,'UserData',pStrS,...
                        'Callback',cbFcnP);
                end
            end            
            
            % --------------------------------- %
            % --- START PHASE PANEL OBJECTS --- %
            % --------------------------------- %            

            % sets the phase panel object (multi-phase video only)
            if obj.nPhase > 1
                % initialisations
                pStrP = {'iPhase0','iStack0'};
                tStrP = {'Start Phase','Start Stack'};
                cHdrP = {'Phase','Start','Finish','Tracked','Total'};
                cFormP = repmat({'numeric'},1,obj.nColP);
                cEditP = false(1,obj.nColP);
                cWidP = {48,50,50,50,50};            

                % creates the label/editbox parameter combo groups
                obj.hEditP = cell(obj.nEditP,1);
                for i = 1:obj.nEditP
                    % creates the text label object
                    tStrPT = sprintf('%s: ',tStrP{i});
                    lPosPT = obj.dX/2 + (i-1)*...
                        (obj.widTxtP + obj.widEditP + obj.dX/2);
                    pPosPT = [lPosPT,obj.dX,obj.widTxtP,obj.hghtTxt];
                    createUIObj('text',obj.hPanelP,'Position',pPosPT,...
                        'String',tStrPT,'FontWeight','Bold',...
                        'FontSize',obj.fSzL,'HorizontalAlignment','Right');

                    % creates the editbox label object
                    pValPE = num2str(obj.(pStrP{i}));
                    lPosPE = sum(pPosPT([1,3]));
                    pPosPE = [lPosPE,obj.dX-2,obj.widEditP,obj.hghtEdit];
                    obj.hEditP{i} = createUIObj('edit',obj.hPanelP,...
                        'Position',pPosPE,'String',pValPE,...
                        'FontSize',obj.fSz,'UserData',pStrP{i},...
                        'Callback',cbFcnP);
                end

                % creates the table object
                yPosTP = obj.dX + obj.hghtRow;
                pPosTP = [obj.dX/2,yPosTP,obj.widTableP,obj.hghtTableP];
                obj.hTableP = createUIObj('table',obj.hPanelP,...
                    'Data',[],'Position',pPosTP,'ColumnName',cHdrP,...
                    'ColumnEditable',cEditP,'ColumnFormat',cFormP,...
                    'RowName',[],'ColumnWidth',cWidP);

                % updates the table fields
                tDataP = [(1:obj.nPhase)',obj.iPh,obj.nTrk,obj.nTot];
                obj.hTableP.Data = num2cell(tDataP);
                
                % resizes the table columns
                autoResizeTableColumns(obj.hTableP);
                
                % runs the start point selection callback function
                obj.panelStartPoint(obj.hPanelS, [])                   
            end
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % centers the figure and makes it visible
            centerfig(obj.hFig);
            refresh(obj.hFig);
            pause(0.05);
            
            % makes the figure visible
            set(obj.hFig,'Visible','on');
            
        end

        % --------------------------------- %        
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %
        
        % --- start point buttongroup selection callback function
        function panelStartPoint(obj, hObj, ~)
            
            % retrieves the handle of the selected radio button
            hRadio = hObj.SelectedObject;
            
            % updates the object properties based on the selection
            isFrameSel = hRadio.UserData == 1;
            setObjEnable(obj.hEditS,isFrameSel)
            setPanelProps(obj.hPanelP,~isFrameSel)
            
            % sets the table background colour based on the selection
            if isFrameSel
                % case is the global frame is selected
                bgCol = 0.81*[1,1,1];      
                
            else
                % sets the table background colours
                prTrk = obj.nTrk./obj.nTot;
                bgCol0 = {[1,0,0],[1,1,0],[0,1,0]};
                tType = 1 + (prTrk > 0) + (prTrk == 1);
                bgCol = cell2mat(arrayfun(@(x)(bgCol0{x}),tType(:),'un',0));
                
                % highlights the selected rows
                bgCol(obj.iPhase0,:) = 0.75*bgCol(obj.iPhase0,:);
            end
            
            % updates the table background colour
            obj.hTableP.BackgroundColor = bgCol;
            
        end
        
        % --- parameter editbox callback function
        function editParaUpdate(obj, hObj, ~)
            
            % field retrieval
            pStr = hObj.UserData;           
            pVal0 = obj.(pStr);
            nwVal = str2double(hObj.String);
            
            % retrieves the parameter limits (based on type)
            switch pStr
                case 'iFrm0'
                    % case is the start frame
                    nwLim = [1,length(obj.isTrk)];                
                
                case 'iPhase0'
                    % case is the start phase

                    % determine the feasible max phase count
                    nPhMax = find(obj.nTrk > 0,1,'last');
                    if obj.nTrk(nPhMax)/obj.nTot(nPhMax) == 1
                        % if phase is fully tracked, start on next phase
                        nPhMax = min(length(obj.nTot),nPhMax+1);
                    end
                    
                    % sets the phase limits
                    nwLim = [1,nPhMax];                    
                    
                case 'iStack0'
                    % case is the start stack
                    nwLim = [1,max(1,obj.nTrk(obj.iPhase0))];                    
            end
            
            % resets the lower limit if the upper limit is zero
            if nwLim(2) == 0; nwLim(1) = 0; end            
            
            % determines if the new value is valid
            if chkEditValue(nwVal,nwLim,1)
                % if so, then update the class field
                obj.(pStr) = nwVal;

                % updates other fields based on parameter being altered
                switch pStr                
                    case 'iFrm0'
                        % case is the frame index
                        
                        % determines if the selected frame has been tracked
                        if ~obj.isTrk(nwVal)
                            % if not, output an error to screen
                            tStr = 'Invalid Frame Index';
                            eStr = sprintf(['Error! The selected ',...
                                'frame has not yet been tracked.\nTry ',...
                                'again with an untracked frame index.']);
                            waitfor(msgbox(eStr,tStr,'modal'))
                            
                            % resets to the last valid value and exits
                            obj.(pStr) = pVal0;
                            hObj.String = num2str(obj.iFrm0);                            
                            return
                            
                        else
                            % otherwise, update the phase/stack fields
                            obj.calcPhaseIndex();
                            obj.hEditP{1}.String = num2str(obj.iPhase0);
                            obj.hEditP{2}.String = num2str(obj.iStack0);
                        end
                        
                    case 'iPhase0'
                        % case is the phase index
                        
                        % resets the stack index
                        if obj.iStack0 > obj.nTot(obj.iPhase0)
                            obj.iStack0 = obj.nTot(obj.iPhase0);
                            obj.hEditP{2}.String = num2str(obj.iStack0);
                        end
                        
                        % resets the frame index
                        obj.calcFrameIndex();
                        obj.hEditS.String = num2str(obj.iFrm0);
                        
                    case 'iStack0'
                        % case is the stack index
                        
                        % resets the frame index
                        obj.calcFrameIndex();
                        obj.hEditS.String = num2str(obj.iFrm0);
                end
            
                % resets the start point (if altering the phase)
                if strcmp(pStr,'iPhase0')
                    obj.panelStartPoint(obj.hPanelS,'1');
                end
                
            else
                % otherwise, reset to the last valid value
                hObj.String = num2str(obj.(pStr));
            end
            
        end
        
        % --- continue button callback function
        function buttonContinue(obj, ~, ~)
            
            % flag that the user chose to continue
            obj.isOK = true;
            obj.indStart = [obj.iPhase0,obj.iStack0];
            
            % deletes the dialog window
            delete(obj.hFig);            
            
        end
            
        % --- cancel button callback function
        function buttonCancel(obj, ~, ~)
            
            % flag that the user cancelled
            obj.isOK = false;
            
            % deletes the dialog window
            delete(obj.hFig);
            
        end       

        % ------------------------------- %        
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- calculates the frame index (from the phase/stack indices)
        function calcFrameIndex(obj)
           
            % field retrieval
            jPhase = obj.objT.iPhaseS(obj.iPhase0);            
            iFrmPh0 = obj.objT.iMov.iPhase(jPhase,1);
            
            % start frame calculation
            obj.iFrm0 = min(obj.nFrmMx,iFrmPh0+obj.nFrmS*(obj.iStack0-1));
            
        end
        
        % --- calculates the phase/stack indices (from the frame index)
        function calcPhaseIndex(obj)
            
            % phase index calculation
            iFrmG = obj.objT.iFrmG(obj.objT.iPhaseS);
            obj.iPhase0 = find(cellfun(@(x)(any(x==obj.iFrm0)),iFrmG));
            
            % phase stack index calculation            
            iPhaseS0 = obj.objT.iPhaseS(obj.iPhase0);
            iFrmPh0 = obj.objT.iMov.iPhase(iPhaseS0,1);
            obj.iStack0 = max(1,ceil((obj.iFrm0-iFrmPh0)/obj.nFrmS));
            
        end
    
    end
    
end