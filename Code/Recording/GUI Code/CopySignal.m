classdef CopySignal < handle
    
    % class properties
    properties
        
        % input arguments
        iCh
        nCh 
        tDurB
        tFeas
        chName
        
        % stimuli blob object fields
        sBlk        
        tBlkL
        tMltOfs
        tMltDur
        tDurTotU
        
        % stimuli copying parameters
        sPara
        iChCopy
        tOfs = 1;
        nCount = 1;        
        
        % main class objects
        hFig
        
        % copy channel panel objects
        hPanelCh
        hRadioCh
        
        % within channel copy panel objects
        hPanelW
        hEditW
        
        % between channel copy panel objects
        hPanelB        
        
        % within channel copy panel objects
        hPanelC
        hButC       
        
        % boolean class fields
        isWCopy        
        isCopy = true;
        canWCopy = true;        
        
        % fixed dimension fields
        dX = 10;   
        hghtTxt = 16;
        hghtRadio = 22;
        hghtChk = 22;
        hghtRow = 25;
        widPanel = 195;
        widTxtW = 105;
        
        % calculated dimension fields
        widFig
        hghtFig
        hghtPanelCh
        hghtPanelW
        hghtPanelB
        hghtPanelC
        widPanelI
        widRadioCh
        widChkB
        widButC
        
        % static class fields
        nChB
        nRadioCh
        nRowW = 2;
        nButC = 2;                
        fSzH = 13;
        fSzL = 12;
        fSz = 10 + 2/3;
        
        % static string fields
        tagStr = 'figCopySignal';
        figName = 'Channel Copy';
        
    end
    
    % class methods
    methods
        
        % --- class constuctor
        function obj = CopySignal(iCh,chName,sBlk,tFeas,tDurTotU)
            
            % sets the input arguments
            obj.iCh = iCh;
            obj.sBlk = sBlk;
            obj.tFeas = tFeas;             
            obj.tDurTotU = tDurTotU;
            
            % other field initialisations
            obj.chName = chName(iCh);
            obj.nCh = length(chName);
            obj.tBlkL = calcSignalBlockLimits({sBlk.hRectS});
            obj.tDurB = diff(obj.tBlkL);
            
            % calculates the temporal parameter multipliers
            obj.tMltOfs = getTimeMultiplier(sBlk.sPara.tOfsU,tDurTotU);
            obj.tMltDur = getTimeMultiplier(sBlk.sPara.tDurU,tDurTotU);
            
            % initialises the class fields/objects
            obj.initClassFields();
            if obj.isCopy
                obj.initClassObjects();
            else
                return
            end
            
            % clears the output object (if not required)
            if (nargout == 0) && ~isdeployed
                clear obj
            end            
            
            % waits for user input to continue...
            uiwait(obj.hFig);
            
        end        
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % array dimensioning
            obj.nChB = length(obj.chName);                        
            obj.canWCopy = obj.tFeas >= obj.tDurB;
            obj.nRadioCh = double(obj.canWCopy) + (obj.nChB > 0);

            % if there are no feasible locations then exit
            if (obj.nChB == 0) && ~obj.canWCopy
                % case there is no feasible position to copy the block
                tStr = 'Infeasible Channel Copy';
                eStr = ['It is not feasible to copy the ',...
                    'selected block. Either select another stimuli ',...
                    'block or make space around the selected block.'];
                waitfor(msgbox(eStr,tStr,'modal'))

                % closes the class object
                obj.isCopy = false;
                return
            end            
            
            % memory allocation
            obj.hRadioCh = cell(obj.nRadioCh,1);
            obj.hEditW = cell(obj.nRowW,1);
            obj.hButC = cell(obj.nButC,1);
                        
            % ---------------------------------------- %            
            % --- STIMULI PARAMETER INITIALISATION --- %
            % ---------------------------------------- %
                                    
            % determines if the current signal block configuration allows 
            % for at least one more copy to be placed afterwards
            obj.tOfs = min(obj.tOfs,(obj.tFeas-obj.tDurB)*obj.tMltOfs);
            
            % ------------------------------------- %
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- %            
            
            % other panel dimension calculations
            obj.hghtPanelW = obj.canWCopy*(...
                obj.nRowW*obj.hghtRow + obj.dX/2);
            obj.hghtPanelB = (obj.nChB*obj.hghtRow + obj.dX)*(obj.nChB>0);
            obj.hghtPanelCh = obj.dX/2 + ...
                obj.hghtPanelB + obj.hghtPanelW + obj.nRadioCh*obj.hghtRow;
            obj.hghtPanelC = obj.dX + obj.hghtRow;
            
            % figure dimension calculations
            obj.widFig = obj.widPanel + 2*obj.dX;
            obj.hghtFig = 3*obj.dX + obj.hghtPanelC + obj.hghtPanelCh;
            
            % other object dimension calculations
            obj.widPanelI = obj.widPanel - obj.dX;
            obj.widRadioCh = obj.widPanel - 2*obj.dX;
            obj.widChkB = obj.widPanelI - obj.dX;
            obj.widButC = (obj.widPanel - obj.dX)/obj.nButC;           
            
        end
        
        % --- initialises the class fields
        function initClassObjects(obj)
            
            % deletes any previous GUIs
            hPrev = findall(0,'tag',obj.tagStr);
            if ~isempty(hPrev); delete(hPrev); end
            
            % --------------------------- %
            % --- MAIN FIGURE OBJECTS --- %
            % --------------------------- %
            
            % creates the figure object
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % creates the figure object
            obj.hFig = createUIObj('figure','Position',fPos,...
                'tag',obj.tagStr,'MenuBar','None','Toolbar','None',...
                'Name',obj.figName,'Resize','on','NumberTitle','off',...
                'Visible','off','AutoResizeChildren','off',...
                'BusyAction','Cancel','GraphicsSmoothing','off',...
                'DoubleBuffer','off','Renderer','painters','CloseReq',[]);            

            % ----------------------- %
            % --- SUB-PANEL SETUP --- %
            % ----------------------- %            
            
            % sets up the sub-panels
            obj.setupControlButtonPanel();
            obj.setupCopyChannelPanel();            
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %                        
            
            % opens the class figure
            openClassFigure(obj.hFig);
            
        end
        
        % ------------------------------------ %
        % --- PANEL OBJECT SETUP FUNCTIONS --- %
        % ------------------------------------ %        
        
        % --- sets up the control button panel objects
        function setupControlButtonPanel(obj)
            
            % initialisations
            tStrB = {'Copy','Cancel'};
            cbFcnB = {@obj.buttonCopy;@obj.buttonCancel};
            
            % creates the panel object
            pPos = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelC];
            obj.hPanelC = createPanelObject(obj.hFig,pPos);
            
            % creates the button objects
            obj.hButC = createObjectRow(obj.hPanelC,obj.nButC,...
                'pushbutton',obj.widButC,'xOfs',obj.dX/2,...
                'yOfs',obj.dX/2,'dxOfs',0,'pStr',tStrB);
            cellfun(@(x,y)(set(x,'Callback',y)),obj.hButC,cbFcnB);
            
        end        
        
        % --- sets up the control button panel objects
        function setupCopyChannelPanel(obj)
            
            % initialisations
            pStrW = {'nCount','tOfs'};
            tStrW = {'Repetition Count',''};
            tStrCh = {'Copy Within Channel','Copy Between Channels'};
            cbFcnW = @obj.editWithinUpdate;
            cbFcnB = @obj.checkBetweenUpdate;
            
            % sets the offset time field
            tStrW{2} = sprintf('Offset Time (%s)',obj.sBlk.sPara.tOfsU);
            
            % creates the panel object
            yPos = sum(obj.hPanelC.Position([2,4])) + obj.dX;
            pPos = [obj.dX,yPos,obj.widPanel,obj.hghtPanelCh];
            obj.hPanelCh = createPanelObject(...
                obj.hFig,pPos,[],'pType','buttongroup');
            obj.hPanelCh.SelectionChangedFcn = @obj.panelSelectChange;
            
            % creates the between channel panel objects
            if obj.nChB > 0
                % copy between channel panel objects
                pPosB = [obj.dX*[1,1]/2,obj.widPanelI,obj.hghtPanelB];
                obj.hPanelB = createPanelObject(obj.hPanelCh,pPosB);

                % creates all of the checkbox objects
                for i = 1:obj.nChB
                    % sets up the position vector
                    yOfs = obj.dX/2 + (i-1)*obj.hghtRow;
                    pPosC = [obj.dX,yOfs,obj.widChkB,obj.hghtChk];                

                    % creates the checkbox object
                    tStrC = sprintf('Channel #%i (%s)',...
                        (obj.nCh+1)-obj.iCh(i),obj.chName{i});
                    createUIObj('checkbox',obj.hPanelB,...
                        'Position',pPosC,'FontUnits','Pixels',...
                        'FontWeight','Bold','FontSize',obj.fSzL,...
                        'Callback',cbFcnB,'UserData',obj.iCh(i),...
                        'String',tStrC,'Value',1);
                end
            else
                % case is there is no feasible between channel locations
                pPosB = [0,obj.dX/2-obj.hghtRow,0,0];
            end
            
            % copy between channel panel objects
            if obj.canWCopy
                yPosW = sum(pPosB([2,4])) + obj.hghtRow;
                pPosW = [obj.dX/2,yPosW,obj.widPanelI,obj.hghtPanelW];
                obj.hPanelW = createPanelObject(obj.hPanelCh,pPosW);
            
                % creates the within channel copy editbox objects
                for i = 1:obj.nRowW
                    % calculates the vertical offset
                    j = obj.nRowW - (i-1);
                    yOfs = obj.dX/2 + (j-1)*obj.hghtRow + 2;
                    pStrE = num2str(obj.(pStrW{i}));

                    % sets up the editbox object                
                    obj.hEditW{i} = createObjectPair(obj.hPanelW,...
                        tStrW{i},obj.widTxtW,'edit','yOfs',yOfs,...
                        'hghtEdit',20,'fSzM',obj.fSz,'cbFcnM',cbFcnW);
                    set(obj.hEditW{i},'UserData',pStrW{i},'String',pStrE);
                end            
            end

            % creates the radio button objects
            yOfs0 = obj.dX/2 + obj.hghtPanelB*obj.canWCopy + 2;
            for i = 1:obj.nRadioCh
                % sets the vertical offset
                j = i;
                if (obj.nChB == 0) || ~obj.canWCopy
                    % case is there no feasible between channel locations
                    j = 1 + (obj.nChB > 0);
                    yPosR = yOfs0 + (obj.hghtPanelW + obj.hghtPanelB);
                else
                    % case is the top radio button
                    yPosR = yOfs0 + (i == 1)*(obj.hghtPanelW + obj.hghtRow);
                end

                % creates the radio button object
                pPosR = [obj.dX,yPosR,obj.widRadioCh,obj.hghtRadio];
                obj.hRadioCh{i} = createUIObj('radiobutton',...
                    obj.hPanelCh,'Position',pPosR,'String',tStrCh{j},...
                    'FontUnits','Pixels','FontWeight','Bold',...
                    'FontSize',obj.fSzL,'Value',i==1);                
            end
            
            % sets the radio button properties
            setObjEnable(obj.hRadioCh{1},obj.nRadioCh > 1);
            
%             % if not able to copying within channel, then disable objects
%             if ~obj.canWCopy
%                 setObjEnable(obj.hRadioCh{1},0);                
%                 obj.hPanelCh.SelectedObject = obj.hRadioCh{2};
%             end
            
            % updates the panel properties
            obj.panelSelectChange([],[]);
            
        end                        
        
        % --------------------------------------- %
        % --- OTHER OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- panel radio button group selection change callback function
        function panelSelectChange(obj, ~, ~)
            
            % field retrieval
            rStr = obj.hPanelCh.SelectedObject.String;
            obj.isWCopy = strContains(rStr,'Within');
            
            % updates the within/between panel object properties
            setPanelProps(obj.hPanelW,obj.isWCopy)
            setPanelProps(obj.hPanelB,~obj.isWCopy)   
            
            % sets the continue button properties
            nSel = length(findall(obj.hPanelB,'Value',1));
            setObjEnable(obj.hButC{1},obj.isWCopy || (nSel > 0));
            
        end
        
        % --- within channel copy editbox callback function
        function editWithinUpdate(obj, hEdit, ~)
            
            % field retrieval
            pStr = hEdit.UserData;
            nwVal = str2double(hEdit.String);            
            
            % sets up the parameter limits/integer flags
            switch pStr
                case 'nCount'
                    % case is the repetition counts
                    [nwLim,isInt] = deal([1,inf],1);
                    
                case 'tOfs'
                    % case is the offset time
                    [nwLim,isInt] = deal([0,inf],0);
            end
            
            % determines if the new value is valid
            if chkEditValue(nwVal,nwLim,isInt)
                % if valid, then set the new value
                prVal = obj.(pStr);
                obj.(pStr) = nwVal;
                
                if obj.detIfParaFeas()
                    % if the parameter is feasible, then exit the function
                    return
                else
                    % otherwise, revert back to the previous value
                    obj.(pStr) = prVal;
                end
            end
            
            % as there was an error, revert back to the previous value
            hEdit.String = num2str(obj.(pStr));
            
        end

        % --- between channel copy checkbox callback function
        function checkBetweenUpdate(obj, ~, ~)
            
            hChkS = findall(obj.hPanelB,'Value',1);
            setObjEnable(obj.hButC{1},~isempty(hChkS));
            
        end        
        
        % --- copy channel button callback function
        function buttonCopy(obj, ~, ~)
            
            % field retrieval
            hChkS = findall(obj.hPanelB,'style','checkbox','value',1);
            uData = arrayfun(@(x)(x.UserData),hChkS);
            
            % resets the copying flag
            obj.isCopy = true;                   
            obj.iChCopy = sort(uData); 
            
            % deletes the dialog window
            delete(obj.hFig);
            clear obj            
            
        end        
        
        % --- cancel channel button callback function
        function buttonCancel(obj, ~, ~)
            
            % resets the copying flag
            obj.isCopy = false;
            
            % deletes the dialog window
            delete(obj.hFig);
            clear obj
            
        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- determines if the new configuration is feasible
        function isFeas = detIfParaFeas(obj)
                        
            % calculates the new 
            dtNw = obj.nCount*(obj.tDurB*obj.tMltDur + ...
                               obj.tOfs/obj.tMltOfs);
            isFeas = dtNw < obj.tFeas;
            
            % if configuration is infeasible, then output an error msg
            if ~isFeas
                eStr = sprintf(['The new parameter configuration is ',...
                    'infeasible:\n\n * Feasible End-Point (%s) = %.4f\n',...
                    ' * New Configuration End-Point (%s) = %.4f'],...
                    obj.tDurTotU,obj.tFeas+obj.tBlkL(2),obj.tDurTotU,... 
                    dtNw+obj.tBlkL(2));
                waitfor(errordlg(eStr,'Infeasible Parameters','modal'))
            end
            
        end
        
    end
    
end