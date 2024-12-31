classdef StimInfo < handle & dynamicprops
    
    % class properties
    properties
        
        % main figure class object
        hFigM
        hAxM
        hEditM        
        
        % main class objects
        hFig
        hPanelO
        
        % stimuli device panel objects
        hPanelD
        hListD
        
        % device channel listbox objects
        hPanelC
        hListC
        
        % stimuli tab group objects
        hPanelT
        hTabGrpT
        hTabT
        
        % block information panel objects
        hPanelB
        hTableB
        
        % fixed dimension fields
        dX = 10;
        hghtRow = 25;
        hghtHdr = 20;
        hghtList = 60;
        widPanelDC = 140;
        widPanelT = 240;
        widPanelB = 450;
        widLblT = 115;
        
        % calculated dimension fields
        widFig
        hghtFig
        hghtPanelO
        widPanelO
        hghtPanel
        hghtPanelDC
        widList
        widTabGrpT
        hghtTabGrpT
        widTableB
        hghtObj        
        widButC
        
        % stimuli information class fields
        T
        sPara
        sData
        stimP
        dType
        chName
        nStimMax
        
        % other class fields
        nCh
        nDev
        nStim        
        sTab = 1;
        
        % boolean class fields
        isOK = true;
        
        % static class fields
        nLblT = 5;
        nColT = 6;
        fSzH = 13;
        fSzL = 12;
        fSz = 10 + 2/3;
        
        % static string fields
        tagStr = 'figStimInfo';
        figName = 'Stimuli Event Information';
        tHdrD = 'STIMULI DEVICE';
        tHdrC = 'CHANNEL TYPE';
        
    end
    
    % private class properties
    properties (Access = private)
        
        objB
        
    end    
    
    % class methods
    methods
        
        % --- class constuctor
        function obj = StimInfo(objB)
            
            % sets the input arguments
            obj.objB = objB;
            
            % initialises the class fields/objects
            obj.linkParentProps();
            obj.initClassFields();
            
            if obj.isOK
                % initialises the class objects
                obj.initClassObjects();
                
                % clears the output object (if not required)
                if (nargout == 0) && ~isdeployed
                    clear obj
                end 
            end            
            
        end        
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class object fields with that parent object
        function linkParentProps(obj)
            
            % parent fields strings
            fldStr = {'iMov','iData'};
            
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
        
            % determines if there is any stimuli information
            if isempty(obj.iData.stimP)
                % if not, then output an error message to screen
                tStr = 'Stimuli Protocol View Error';
                mStr = 'There is no stimuli information for this video.';
                waitfor(errordlg(mStr,tStr,'modal'))
                
                % resets the flag and exit
                obj.isOK = false;
                return                
            end

            % --------------------------------- %
            % --- STIMULI INFORMATION SETUP --- %
            % --------------------------------- %                                         
            
            % sets the stimuli fields
            obj.stimP = obj.iData.stimP;            
            obj.sPara = obj.iData.sTrainEx;
            obj.T = obj.iData.Tv(obj.iData.Frm0:obj.iMov.sRate:end);

            % stimuli information setup
            dType0 = fieldnames(obj.stimP);               
            obj.nDev = length(dType0);               
            
            % determines the channel/stimuli count over all devices
            pFldD = fieldnames(obj.stimP);            
            [nStim0,obj.nCh] = deal(cell(1,obj.nDev),zeros(1,obj.nDev));
            for i = 1:obj.nDev
                % determins the channel counts
                pFldC = fieldnames(obj.stimP.(pFldD{i}));
                obj.nCh(i) = length(pFldC);
                
                % retrieves the stimuli count
                nStim0{i} = cellfun(@(x)(...
                    length(obj.stimP.(pFldD{i}).(x).Ts)),pFldC(:));
            end
            
            % sets the channel stimuli count
            obj.nStim = combineNumericCells(nStim0);
            
            % determines the stimuli information for each device
            obj.nStimMax = 0;
            [hasStimD,chNameT] = deal(false(obj.nDev,1),cell(obj.nDev,1));
            for iDev = 1:obj.nDev
                % retrieves the channels names for the current device
                stimPD = getStructField(obj.stimP,dType0{iDev});
                chName0 = fieldnames(stimPD);
                
                % removes any channels with no stimuli events
                stimPC = cellfun(@(x)(stimPD.(x)),chName0,'un',0);
                nStimC = cellfun(@(x)(length(x.Ts)),stimPC);                
                hasStimC = nStimC > 0;
                obj.nStimMax = max(max(nStimC),obj.nStimMax);
                
                % reduces down the 
                chNameT{iDev} = chName0(hasStimC);
                hasStimD(iDev) = any(hasStimC);                
            end
            
            % resets the device type/channel name fields
            obj.dType = dType0(hasStimD);            
            obj.chName = chNameT(hasStimD);            
            
            % ----------------------------------- %
            % --- OTHER FIELD INITIALISATIONS --- %
            % ----------------------------------- %
            
            % memory allocation
            obj.hTabT = cell(obj.nStimMax,1);            
            
            % main figure object handles
            obj.hFigM = findall(0,'tag','figFlyTrack');
            obj.hAxM = findobj(obj.hFigM,'tag','imgAxes');            
            obj.hEditM = findobj(obj.hFigM,'tag','frmCountEdit');
            
            % ------------------------------------- %
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- %
            
            % other panel dimension calculations
            obj.hghtPanelDC = obj.dX + obj.hghtHdr + obj.hghtList;
            obj.hghtPanel = 0.5*obj.dX + 2*obj.hghtPanelDC;
            
            % calculates the outer panel dimensions
            obj.hghtPanelO = obj.hghtPanel + obj.dX;
            obj.widPanelO = 2*obj.dX + ...
                (obj.widPanelDC + obj.widPanelT + obj.widPanelB);
            
            % figure dimension calculations
            obj.widFig = obj.widPanelO + 2*obj.dX;
            obj.hghtFig = obj.hghtPanelO + 2*obj.dX;
            
            % other object dimension calculations
            obj.hghtObj = obj.hghtPanel - obj.dX;            
            obj.widList = obj.widPanelDC - 1.5*obj.dX;           
            obj.widTableB = obj.widPanelB - obj.dX;
            obj.widTabGrpT = obj.widPanelT - obj.dX;
            obj.widButC = (obj.widTabGrpT - obj.dX)/2;
            
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
            
            % creates the other panel
            pPosO = [obj.dX*[1,1],obj.widPanelO,obj.hghtPanelO];
            obj.hPanelO = createPanelObject(obj.hFig,pPosO);
            
            % ----------------------- %
            % --- SUB-PANEL SETUP --- %
            % ----------------------- %
            
            % sets up the sub-panel objects
            obj.setupDeviceInfoPanels();
            obj.setupStimInfoPanel();
            obj.setupStimTablePanel();
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %            
            
            % sets up the menu item objects
            obj.setupMenuItems();            
            
            % opens the class figure
            openClassFigure(obj.hFig);
            
        end      
        
        % --- sets up the menu item objects
        function setupMenuItems(obj)
            
            hMenuF = uimenu(obj.hFig,'Label','File');
            uimenu(hMenuF,'Label','Close Window',...
                'Accelerator','X','Callback',@obj.menuCloseWindow);
            
        end
        
        % --- sets up the stimuli information tab
        function setupStimuliTab(obj,iTab)
            
            % initialisations
            cbFcnB = {@obj.buttonStartFrame;@obj.buttonFinishFrame};
            tLbl = {'Start Frame','Finish Frame','Event Time Stamp',...
                    'Train Duration','Stim Train Count'};
            
            % creates the button objects
            hObjB = createObjectRow(obj.hTabT{iTab},2,...
                'pushbutton',obj.widButC,'dxOfs',0,'xOfs',obj.dX/2,...
                'yOfs',obj.dX/2,'pStr',tLbl(1:2));
            cellfun(@(x,y)(set(x,'Callback',y)),hObjB,cbFcnB);
            
            % creates the stimuli information text labels
            yOfs0 = obj.dX + obj.hghtRow;
            for i = 1:obj.nLblT
                % calculates the vertical offset
                j = obj.nLblT - (i-1);
                yOfs = yOfs0 + (j-1)*(obj.hghtRow-3);
                
                % creates the text label object
                hTxt = createObjectPair(obj.hTabT{iTab},tLbl{i},...
                    obj.widLblT,'text','xOfs',obj.dX/2,'yOfs',yOfs);
                set(hTxt,'UserData',i,'FontSize',obj.fSzL);
            end
            
        end
        
        % ------------------------------------ %
        % --- PANEL OBJECT SETUP FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- sets up the device information panel objects
        function setupDeviceInfoPanels(obj)
            
            % initialisations
            pPosL = [obj.dX*[1,1]/2,obj.widList,obj.hghtList];            
            
            % function handles
            cbFcnD = @obj.listDeviceSelect;
            cbFcnC = @obj.listChannelSelect;                       
            
            % creates the device channel panel objects
            pPosC = [obj.dX*[1,1]/2,obj.widPanelDC,obj.hghtPanelDC];
            obj.hPanelC = createPanelObject(...
                obj.hPanelO,pPosC,obj.tHdrC,'FontSize',obj.fSzL);

            % creates the listbox object
            obj.hListC = createUIObj('listbox',obj.hPanelC,...
                'FontUnits','Pixels','FontSize',obj.fSz,'Position',pPosL,...
                'Callback',cbFcnC,'String',obj.chName{1}(:),'Value',1);
            
            % creates the device channel panel objects
            yPosD = sum(pPosC([2,4])) + obj.dX/2;
            pPosD = [obj.dX/2,yPosD,obj.widPanelDC,obj.hghtPanelDC];
            obj.hPanelD = createPanelObject(...
                obj.hPanelO,pPosD,obj.tHdrD,'FontSize',obj.fSzL);
            
            % creates the listbox object
            obj.hListD = createUIObj('listbox',obj.hPanelD,...
                'FontUnits','Pixels','FontSize',obj.fSz,'Position',pPosL,...
                'Callback',cbFcnD,'String',obj.dType(:),'Value',1);
                    
        end
        
        % --- sets up the stimuli train information panel objects
        function setupStimInfoPanel(obj)
            
            % function handles
            cbFcnT = @obj.stimEventTabChange;
        
            % creates the panel object
            xPos = sum(obj.hPanelD.Position([1,3])) + obj.dX/2;
            pPos = [xPos,obj.dX/2,obj.widPanelT,obj.hghtPanel];
            obj.hPanelT = createPanelObject(obj.hPanelO,pPos);
            
            % tab-group object setup
            pPosT = [obj.dX*[1,1]/2,obj.widTabGrpT,obj.hghtObj];
            obj.hTabGrpT = createUIObj('tabgroup',obj.hPanelT,...
                'Position',pPosT,'SelectionChangedFcn',cbFcnT);
            
            % stimuli information panel tab setup
            obj.hTabT = cell(obj.nStimMax,1);
            for i = 1:obj.nStimMax
                % creates the tab object
                tStr = sprintf('#%i',i);
                obj.hTabT{i} = createNewTab(...
                    obj.hTabGrpT,'Title',tStr,'UserData',i);
                
                % sets up the stimuli tab
                obj.setupStimuliTab(i);
                obj.updateEventFields(i);
            end
            
        end
            
        % --- sets up the stimuli results table panel objects
        function setupStimTablePanel(obj)
            
            % initialisations
            cEdit = false(1,obj.nColT);            
            cName = {'Type','Count','Period (s)',...
                     'Amplitude (%)','Offset (s)','Duration (s)'};
            cWid = {60, 55, 'auto', 'auto', 55, 'auto'};
            
            % creates the panel object
            xPos = sum(obj.hPanelT.Position([1,3])) + obj.dX/2;
            pPos = [xPos,obj.dX/2,obj.widPanelB,obj.hghtPanel];
            obj.hPanelB = createPanelObject(obj.hPanelO,pPos);                        
            
            % creates the table object
            pPosT = [obj.dX*[1,1]/2,obj.widTableB,obj.hghtObj];
            obj.hTableB = createUIObj('table',obj.hPanelB,...
                    'Data',[],'Position',pPosT,'ColumnName',cName,...
                    'ColumnEditable',cEdit,'ColumnWidth',cWid,...
                    'FontSize',obj.fSz);
            autoResizeTableColumns(obj.hTableB);
            
            % updates the stimuli parameter table information
            obj.updateStimParaTable(1);
            
        end
        
        % ------------------------------------ %
        % --- MENU ITEM CALLBACK FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- close window menu item callback function
        function menuCloseWindow(obj, ~, ~)
            
            delete(obj.hFig);
            
        end
                
        % --------------------------------------- %
        % --- OTHER OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- stimuli train tab group callback function
        function stimEventTabChange(obj, ~, ~)
            
            % updates the channel tab index
            obj.sTab = obj.hTabGrpT.SelectedTab.UserData;                       
            
        end        
           
        % --- device listbox callback function
        function listDeviceSelect(obj, hList, ~)        
        
            % field retrieval
            iSel = hList.Value;
            
            % updates the channel listbox
            set(obj.hListD,'String',obj.chName{iSel}(:),'Value',1);
            obj.listChannelSelect([], []);
            
        end
        
        % --- channel listbox callback function
        function listChannelSelect(obj, ~, ~)
            
            % retrieves the stimuli information
            [dT0,chN0] = obj.getSelectedListFields();
            stimPC = obj.stimP.(dT0).(chN0);
            nStimCh = length(stimPC.Ts);
            
            % updates the select tab
            obj.sTab = min(nStimCh,obj.sTab);
            obj.hTabGrpT.SelectedTab = obj.hTabT{obj.sTab};
            
            % resets the tab visibility
            xiCh = 1:nStimCh;
            cellfun(@(x)(set(x,'Parent',obj.hTabGrpT)),obj.hTabT(xiCh))
            cellfun(@(x)(set(x,'Parent',[])),obj.hTabT((nStimCh+1):end))            
            
            % updates the stimuli parameter table
            obj.updateStimParaTable(obj.sTab);
            
        end        
        
        % --- start frame pushbutton callback function
        function buttonStartFrame(obj, ~, ~)
            
            hTxt = findall(...
                obj.hTabT{obj.sTab},'Style','Text','UserData',1);
            obj.updateMainImageFrame(hTxt);
            
        end
        
        % --- start frame pushbutton callback function
        function buttonFinishFrame(obj, ~, ~)
            
            hTxt = findall(...
                obj.hTabT{obj.sTab},'Style','Text','UserData',2);
            obj.updateMainImageFrame(hTxt);
            
        end        

        % ------------------------------- %        
        % --- OBJECT UPDATE FUNCTIONS --- %
        % ------------------------------- %
        
        % --- updates the stimulus events fields
        function updateEventFields(obj,iTabS)
            
            % sets the default input arguments
            if ~exist('iTabS','var'); iTabS = obj.sTab; end

            % retrieves channel information (for currently selected device)
            [dT0,chN0] = obj.getSelectedListFields(); 
            stimPC = obj.stimP.(dT0).(chN0);
            
            % start/time time/index field retrieval
            Ts = max(0,stimPC.Ts(iTabS));
            Tf = min(stimPC.Tf(iTabS),obj.T(end));
            iFrm0 = argMin(abs(obj.T-Ts));
            iFrmF = argMin(abs(obj.T-Tf));
            
            % determines the stimuli time stamp/duration time strings
            [~,~,C1] = calcTimeDifference(obj.T(iFrm0));
            [~,~,C2] = calcTimeDifference(Tf-Ts);
            
            % stimuli train retrieval
            blkInfo = obj.getSelectBlockInfo(iTabS);
            
            % sets the tab label strings
            tLblS = {num2str(iFrm0),num2str(iFrmF),...
                     sprintf('%s:%s:%s',C1{2},C1{3},C1{4}),...
                     sprintf('%s:%s:%s',C2{2},C2{3},C2{4}),...
                     num2str(length(blkInfo))};
                 
            % updates the text labels
            for i = 1:length(tLblS)
                hTxt = findobj(obj.hTabT{iTabS},'UserData',i,'Style','Text');
                hTxt.String = tLblS{i};
            end                                         
            
        end
        
        % --- updates the stimuli parameter table
        function updateStimParaTable(obj,iTab)
            
            % retrieves the currently selected block info
            blkInfo = obj.getSelectBlockInfo(iTab);
            
            % data retrieval
            sT = field2cell(blkInfo,'sType');
            sP = field2cell(blkInfo,'sPara',1);
            sTF = cellfun(@(x)(obj.convertSignalTypes(x)),sT,'un',0);
           
            % sets the signal parameter table data
            sD = cell(length(sP),obj.nColT-1);
            for i = 1:length(sP)
                % calculates the time multipliers
                tMltD = getTimeMultiplier('s',sP(i).tDurU);
                tMltO = getTimeMultiplier('s',sP(i).tOfsU);
                
                % sets the signal independent fields
                sD{i,1} = num2str(sP(i).nCount);
                sD{i,4} = sprintf('%s',obj.setCellEntry(sP(i).tOfs*tMltO));
                sD{i,5} = sprintf('%s',obj.setCellEntry(sP(i).tDur*tMltD));
                
                % sets the signal dependent fields
                if strcmp(sT{i},'Square')
                    % calculates the off/on duty cycle durations time multipliers
                    tMltOff = getTimeMultiplier('s',sP(i).tDurOffU);
                    tMltOn = getTimeMultiplier('s',sP(i).tDurOnU);
                    
                    % sets the values for the amplitude/cycle duration
                    tStrOn = obj.setCellEntry(sP(i).tDurOn*tMltOn);
                    if sP(i).nCount == 1
                        sD{i,2} = sprintf('%s',tStrOn);
                    else
                        tStrOff = obj.setCellEntry(sP(i).tDurOff*tMltOff);
                        sD{i,2} = sprintf('%s/%s',tStrOff,tStrOn);
                    end
                    
                    sD{i,3} = obj.setCellEntry(sP(i).sAmp);
                else
                    % calculates the duty cycle duration time multiplier
                    tMltC = getTimeMultiplier('s',sP(i).tCycleU);
                    
                    % sets the cycle duration
                    sD{i,2} = obj.setCellEntry(sP(i).tCycle*tMltC);
                    
                    % sets the signal amplitude
                    sStrOn = obj.setCellEntry(sP(i).sAmp1);
                    if sP(i).sAmp0 == 0
                        % case is there is a zero base amplitude
                        sD{i,3} = sprintf('%s',sStrOn);
                        
                    else
                        % case is there is a non-zero base amplitude
                        sStrOff = obj.setCellEntry(sP(i).sAmp0);
                        sD{i,3} = sprintf('%s/%s',sStrOff,sStrOn);
                    end
                end
            end
            
            % sets up the table data
            setHorizAlignedTable(obj.hTableB,[sTF(:),sD]);
            
        end
            
        % --- updates the main image
        function updateMainImageFrame(obj,hTxt)
            
            % updates the main window frame index
            obj.iData.cFrm = str2double(hTxt.String);
            obj.hEditM.String = num2str(obj.iData.cFrm);
            
            % updates the main image axis
            axes(obj.hAxM)
            obj.objB.dispImage(guidata(obj.hFigM))
            
            % resets the figure to stimulus info GUI
            figure(obj.hFig)            
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        

        % --- retrieves the selected list fields
        function [dT0,chN0] = getSelectedListFields(obj)
            
            [iSelD,iSelC] = deal(obj.hListD.Value,obj.hListC.Value);
            [dT0,chN0] = deal(obj.dType{iSelD},obj.chName{iSelD}{iSelC});
            
        end

        % --- retrieves the selected stimuli block information
        function blkInfo = getSelectBlockInfo(obj,iTabS)
            
            % retrieves the stimuli information
            [dT0,chN0] = obj.getSelectedListFields();
            stimPC = obj.stimP.(dT0).(chN0);
            
            % field retrieval            
            indS = stimPC.iStim(iTabS);
            sTrain = obj.sPara.sTrain(indS);
            blkInfoS = obj.sPara.sTrain(indS).blkInfo;
            
            % sets the device type (removes any spaces/#'s)
            dType0 = field2cell(blkInfoS,'devType');
            dT = cellfun(@(x)(regexprep(x,'[ #]','')),dType0,'un',0);
            
            % retrieves the block information pertaining to the current channel
            if strcmp(chN0,'Ch')
                % if all channels are the same, then use the first one that matches the
                % current device type
                isM = find(strcmp(dT,dT0),1,'first');
                blkInfo = sTrain.blkInfo(isM);
                
            else
                % otherwise, determine all blocks that correspond to the current
                % device/channel name
                chName0 = field2cell(blkInfoS,'chName');
                chN = cellfun(@(x)(strrep(x,' #','')),chName0,'un',0);
                chN = strrep(chN,'All Ch','AllCh');
                
                isM = strcmp(dT,dT0) & strcmp(chN,chN0);
                blkInfo = sTrain.blkInfo(isM);
            end
            
        end
        
    end
    
    % class methods
    methods (Static)
        
        % --- converts the signal types
        function sType = convertSignalTypes(sType)
            
            switch sType
                case 'SineWave'
                    sType = 'Sine';
            end
            
        end
        
        % --- sets the text for a numerical value, tVal
        function tStr = setCellEntry(tVal)
            
            % rounds the value to 0.001 and converts to a string
            tStr = num2str(roundP(tVal,0.001));
            
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