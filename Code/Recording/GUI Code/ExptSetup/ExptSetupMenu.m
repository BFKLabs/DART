classdef ExptSetupMenu < handle & dynamicprops
    
    % class properties
    properties
               
        % parent menu item class fields
        hMenuF
        hMenuE
        hMenuO
        
        % cell array class fields
        sStr = {'off','on'};
        mTagP = {'File','Expt','Opto'};
        mLblP = {'File','Experiment','Optogenetics'};
        fModeP = {'*.spl;*.exp;*.expp',...
                  'Protocol Data Files (*.spl, *.exp, *.expp)'};
        fModeS = {'*.expp','Stimulus Playlist Files (*.expp)'}
              
        % static string class fields
        mFldP = 'FEO';
        
    end
    
    % private class properties
    properties (Access = private)
        
        objB
        
    end    
    
    % class methods
    methods
        
        % --- class constructor
        function obj = ExptSetupMenu(objB)
            
            % input arguments
            obj.objB = objB;
            
            % initialises the class fields/objects
            obj.linkParentProps();
            obj.initClassFields();
            obj.initClassObjects();
                        
        end
        
        % --- initialises the class object fields with that parent object
        function linkParentProps(obj)
            
            % parent fields strings
            fldStr = {'hFig','hFigM','hTimerS','hTabGrpS','devType',...
                      'objT','infoObj','sTrainP','iExpt','iProg',...
                      'calcExptStimDurFcn','zoomPropFcn',...
                      'iTab','nCh','chInfo','isStimOnly'};
            
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
           
            % ------------------------------------------- %
            % --- CLASS OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------------- %            
            
            
        end
        
        % --- initialises the class objects
        function initClassObjects(obj)
            
            % creates the parent menu items
            for i = 1:length(obj.mTagP)
                mTag = sprintf('menu%s',obj.mTagP{i});
                obj.(sprintf('hMenu%s',obj.mFldP(i))) = ...
                    uimenu(obj.hFig,'Label',obj.mLblP{i},'Tag',mTag);
            end

            % ----------------------- %
            % --- FILE MENU ITEMS --- %
            % ----------------------- %
            
            % field initialisations
            accF = {'N','O','S','D','X'};            
            isSepF = [false,false,false,true,true];
            mLblF = {'New Protocol','Open Protocol','Save Protocol',...
                     'Disk Space Information','Exit'};
            mTagF = {'menuNewProto','menuOpenProto','menuSaveProto',...
                     'menuDiskSpace','menuExit'};
            cbFcnF = {@obj.menuNewProto,@obj.menuOpenProto,...
                      @obj.menuSaveProto,@obj.menuDiskSpace,@obj.menuExit};
                  
            % creates the file sub-menu items
            for i = 1:length(mLblF)
                uimenu(obj.hMenuF,'Label',mLblF{i},'Tag',mTagF{i},...
                    'Callback',cbFcnF{i},'Accelerator',accF{i},...
                    'Separator',obj.sStr{1+isSepF(i)});                
            end
                        
            % ----------------------------- %
            % --- EXPERIMENT MENU ITEMS --- %
            % ----------------------------- %
            
            % field initialisations
            accE = {'R'};
            mLblE = {'Run Experiment'};
            mTagE = {'menuRunExpt'};
            cbFcnE = {@obj.menuRunExpt};
            
            % creates the experiment sub-menu items
            for i = 1:length(mLblE)
                uimenu(obj.hMenuE,'Label',mLblE{i},'Tag',mTagE{i},...
                    'Callback',cbFcnE{i},'Accelerator',accE{i});                
            end                    
            
            % ------------------------------- %
            % --- OPTOGENETICS MENU ITEMS --- %
            % ------------------------------- %
            
            % field initialisations
            accO = {'L','W'};
            mLblO = {'IR Lights','White Lights'};
            mTagO = {'menuToggleIR','menuToggleWhite'};
            cbFcnO = {@obj.menuToggleIR,@obj.menuToggleWhite};
            
            % creates the experiment sub-menu items
            for i = 1:length(mLblO)
                uimenu(obj.hMenuO,'Label',mLblO{i},'Tag',mTagO{i},...
                    'Callback',cbFcnO{i},'Accelerator',accO{i});
            end
            
            % --------------------- %
            % --- TOOLBAR ITEMS --- %
            % --------------------- %
            
            % field initialisations
            hasSep = [false,false,false,true];
            tIcon = {'file_new','file_open','file_save','tool_zoom_in'};
            tLbl = {'New Protocol','Open Protocol',...
                    'Save Protocol','Axes Zoom'};
            tType = {'pushtool','pushtool','pushtool','toggletool'};
            tTag = {'toolNewProto','toolOpenProto',...
                    'toolSaveProto','toolZoom'};
            iconDir = fullfile(matlabroot,'toolbox','matlab','icons');
                
            % creates the toolbar object
            hTool = createUIObj('toolbar',obj.hFig);
            
            % creates the toolbar items
            for i = 1:length(tLbl)
                % creates the toolbar item object
                hObj = createUIObj(tType{i},hTool);    
                
                % sets the toolbar item callback function
                if strcmp(tType{i},'toggletool')
                    hObj.ClickedCallback = @obj.toggleZoom;
                else
                    hObj.ClickedCallback = cbFcnF{i};
                end                
                
                % sets the button icon data
                tIconF = fullfile(iconDir,sprintf('%s.png',tIcon{i}));                
                hObj.CData = obj.getToolbarIcon(tIconF);

                % sets the other toolbar properties                
                hObj.Tag = tTag{i};
                hObj.Tooltip = tLbl{i};                
                hObj.Separator = obj.sStr{1+hasSep(i)};                
            end
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % disables the appropriate menu items
            mTagOff = {'toolZoom','toolNewProto','toolOpenProto',...
                       'menuNewProto','menuOpenProto'};
            cellfun(@(x)(obj.setMenuItemEnable(x,0)),mTagOff);
                        
        end        

        % ------------------------------------ %
        % --- MENU ITEM CALLBACK FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- new protocol menu item callback function
        function menuNewProto(obj,varargin)
           
            % prompts user if they wish to continue clearing protocol
            tStr = 'Clear Current Protocol?';
            qStr = sprintf(['Are you sure you want to clear the ',...
                            'current experimental protocol?\nAny ',...
                            'unsaved changes will be lost and this ',...
                            'process can''t be reversed.']);            
            uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
            if ~strcmp(uChoice,'Yes')
                % if not, then exit
                return
            end

            % hides the main window
            setObjVisibility(obj.hFig,0);
            pause(0.01);            

            % removes any block selections
            if obj.iTab > 1
                feval(obj.hFig.WindowButtonDownFcn,[],[],'alt');
            end            
            
            % clears the experiment/stimuli train data structs
            obj.nCh = obj.objB.nCh0;
            obj.devType = obj.objB.devType0;
            obj.iExpt = initExptStruct(obj.objB);                                        
            
            % sets the window fields with the protocol data
            obj.objB.resetClassObjects([]);
            
            % re-shows the main window
            setObjVisibility(obj.hFig,1);            
            
        end
        
        % --- open protocol menu item callback function
        function menuOpenProto(obj,varargin)
           
            % field retrieval   
            sTrainNw = [];
            resetStimTrain = false;
            dDir = obj.iProg.DirPlay;
            tStr = 'Load Stimulus Playlist File';
            
            % prompts the user for the protool file           
            [fName,fDir,fIndex] = uigetfile(obj.fModeP,tStr,dDir);
            if fIndex == 0
                % exit if the user cancelled
                return
            end
            
            % hides the main window
            setObjVisibility(obj.hFig,0);
            pause(0.01);
            
            % removes any block selections
            if obj.iTab > 1
                feval(obj.hFig.WindowButtonDownFcn,[],[],'alt');
                if any(obj.iTab == [2,3])
                    obj.objT{obj.iTab}.objSM.setFillVisibility('off')
                end
            end
                        
            % loads the experiment protocol file
            fFile = fullfile(fDir,fName);
            fData = importdata(fFile,'-mat');    
            
            % loads the file (based on type)
            [~,fName,fExtn] = fileparts(fName);
            switch fExtn
                case '.exp'
                    % case is an old format experimental protocol file
                    iStimNw = fData.iStim;
                    [sTrainS,dTypeNw,nChNw] = convertStimData(fData);
                    [iExptNw,sTrainEx] = ...
                        obj.convertExptDataLocal(sTrainS,fData.iExpt);
                    
                    % sets up the stimuli train data struct
                    sTrainNw = obj.objB.initStimTrainPara();
                    [sTrainNw.S,sTrainNw.Ex] = del(sTrainS,sTrainEx);
                    
                case '.expp'
                    % case is an new format experimental protocol file                    
                    
                    % determines the experiment type
                    if isfield(fData,'iExpt')
                        % case is new format file
                        iExptNw = fData.iExpt;
                        isRecOnly = strcmp(iExptNw.Info.Type,'RecordOnly');
                    else
                        % case is old format file
                        isRecOnly = true;
                        iExptNw = fData;
                    end
                    
                    % sets the experiment dependent fields
                    if isRecOnly
                        % case is a recording only expt
                        
                        % case is a recording only expt
                        sTrainNw = [];
                        [dTypeNw,nChNw] = deal({'RecordOnly'},NaN);
                        iStimNw = initTotalStimParaStruct();
                        
                    else
                        % case is a stimuli based experiment
                        sTrainNw = fData.sTrain;                        
                        dTypeNw = unique(fData.chInfo(:,3),'stable');            
                        nChNw = cellfun(@(x)(...
                            sum(strcmp(fData.chInfo(:,3),x))),dTypeNw);                        
                        
                        % initialisese the stimuli data struct
                        if isfield(fData,'iStim')
                            % retrieves the field if available
                            iStimNw = fData.iStim;
                        else
                            % otherwise, create a new struct
                            iStimNw = initTotalStimParaStruct();
                        end
                    end
                    
                otherwise
                    % case is a stimuli protool file
                    
                    % retrieves the stimuli train/experiemnt info
                    [sTrainS,dTypeNw,nChNw] = convertStimData(fData);        
                    iExptNw = initExptStruct(obj.objB);
                    iStimNw = initTotalStimParaStruct();
                    
                    % other field initialisations
                    resetStimTrain = true;
            end
            
            % resets the experiment timing fields
            iExptNw = obj.resetExptTiming(obj.iExpt,iExptNw);
            iExptNw.Info.FileName = sprintf('%s%s',fName,fExtn);
            obj.isStimOnly = strcmp(iExptNw.Info.Type,'StimOnly');
                        
            % determines if the loaded stimuli train is feasible
            [sTrainNw,ok] = obj.checkStimuliTrain(sTrainNw,iExptNw);
            if ~ok
                % if there was an issue, then exit
                return
            end
            
            % resets the total stimuli data struct (if requried)
            if resetStimTrain
                % initialises the total stimuli data struct
                sTrainNw = obj.objB.initStimTrainPara();
                
                % sets the short-term stimuli
                sTrainNw.S = cell(length(sTrainS),1);
                for i = 1:length(sTrainS)
                    sTrainNw.S{i} = sTrainS(i);  
                end
            end
            
            % class field field update
            obj.nCh = nChNw;
            obj.iExpt = iExptNw;
            obj.infoObj.iStim = iStimNw;                       
            obj.devType = obj.objB.resetDevType(dTypeNw(:));            
            
            % stimuli dependnent experiment updates
            if isfield(fData,'chInfo')
                obj.chInfo = fData.chInfo;            
                obj.objB.resetDeviceInfo(fData);
            end
            
            % sets the window fields with the protocol data
            obj.objB.resetClassObjects(sTrainNw);
            
            % re-shows the main window
            setObjVisibility(obj.hFig,1);
            
        end            
        
        % --- save protocol menu item callback function             
        function menuSaveProto(obj,varargin)
           
            % determines if any stimuli trains have been saved
            if ~strcmp(obj.devType,'RecordOnly')
                if isempty(obj.sTrainP.Ex)
                    tStr = 'Stimuli Protocol Missing';
                    mStr = ['Warning. There are currently no stimuli ',...
                            'protocols set for this experiment. Do ',...
                            'you still wish to continue?'];
                    uChoice = questdlg(mStr,tStr,'Yes','No','Yes');
                    if ~strcmp(uChoice,'Yes')
                        % if the user cancelled, then exit
                        return
                    end
                end
            end  
            
            % prompts user for output file name
            dDir = obj.iProg.DirPlay;
            tStr= 'Set Protocol Filename';
            [fName,fDir,fIndex] = uiputfile(obj.fModeS,tStr,dDir);
            if fIndex
                % if successful, then update the 
                fFile = fullfile(fDir,fName);
                obj.iExpt.Info.FileName = fName;
                
                % updates the information panel fields
                obj.objT{1}.hObjI{1}.String = fName;
                
                % updates the block train parameters
                obj.updateBlockTrainPara();                
                
                % outputs the data to file
                obj.saveProtocolFile(fFile,...
                    obj.iExpt,obj.sTrainP,obj.chInfo,obj.infoObj.iStim);
            end
            
        end        
        
        % --- disk space information menu item callback function
        function menuDiskSpace(varargin)
           
            % opens the disk space dialog window
            DiskSpace()
            
        end
        
        % --- close window menu item callback function            
        function menuExit(obj,varargin)
           
            % prompts the user if they want to close the GUI
            qStr = 'Are you sure you want to exit the experiment setup?';
            uChoice = questdlg(qStr,'Close GUI?','Yes','No','Yes');
            if ~strcmp(uChoice,'Yes')
                % if the user cancelled, then exit
                return
            end        
            
            % deletes the experiment start timer object
            deleteTimerObjects(obj.objT{1}.hTimerS);
            
            % turns off the IR lights (if they are currently on)
            hMenuIR = obj.getMenuItem('menuToggleIR');
            if strcmp(get(hMenuIR,'Checked'),'on')
                obj.menuToggleIR();
            end
            
            % closes the GUI
            setObjVisibility(obj.hFig,0)
            pause(0.05);            
            
            % experiment-type specific updates
            switch obj.infoObj.exType
                case 'StimOnly'
                    % case is a stimui type expt (re-opens DART Main)
                    setObjVisibility(obj.infoObj.hFigM,'on')
                    
                otherwise
                    % case is a recording type expt (re-opens FlyRecord)
                    
                    % updates the main experiment/stimuli data structs
                    setappdata(obj.hFigM,'iExpt',obj.iExpt)
                    setappdata(obj.hFigM,'infoObj',obj.infoObj)
                    setappdata(obj.hFigM,'sTrain',obj.getExptTrainPara())                    
                    
                    % makes the main gui visible again
                    if ~isempty(obj.hFigM)
                        % re-enables the menu items
                        hFigMH = guidata(obj.hFigM);
                        setObjEnable(hFigMH.menuFile,'on');
                        setObjEnable(hFigMH.menuExpt,'on');
                        setObjEnable(hFigMH.menuOpto,'on');
                        
                        % sets focus to the recording gui
                        figure(obj.hFigM);
                    end
            end
            
            % deletes the figure
            delete(obj.hFig)            
            
        end        
        
        % --- run experiment menu item callback function            
        function menuRunExpt(obj,varargin)
            
            % starts the experiment run
            obj.objB.startExptRun();            
            
        end        
             
        % --- toggle IR light menu item callback function
        function menuToggleIR(obj,hMenu,varargin)
            
            % toggles the IR lights
            toggleOptoLights(obj.objB,hMenu,true)
            
        end        
        
        % --- toggle white light menu item callback function
        function menuToggleWhite(obj,hMenu,varargin)
            
            % toggles the white lights
            toggleOptoLights(obj.objB,hMenu,false)            
            
        end
        
        % --- toggle zoom toolbar item callback function
        function toggleZoom(obj,hMenu,~)
            
            obj.zoomPropFcn(get(hMenu,'State'))
            
        end
        
        % ------------------------------------ %
        % --- CLASS FIELD GETTER FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- retrieves the experiment stimuli train parameters
        function sTrain = getExptTrainPara(obj)
            
            sTrain = [];
            
        end
        
        % --- menu/toolbar item retrieval
        function hObj = getMenuItem(obj,mTag)
            
            hObj = findall(obj.hFig,'tag',mTag);
            
        end        
        
        % ------------------------------------ %
        % --- CLASS FIELD SETTER FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- sets the menu/toolbar item enabled properties
        function setMenuItemEnable(obj,mTag,state)
            
            setObjEnable(obj.getMenuItem(mTag),state)
            
        end
        
        % --- sets the menu/toolbar item enabled properties
        function setMenuItemVisible(obj,mTag,state)
            
            setObjVisibility(obj.getMenuItem(mTag),state)
            
        end        
        
        % --- sets the menu/toolbar item enabled properties
        function setMenuItemCheck(obj,mTag,state)
            
            % menu item retrieval
            hMenu = obj.getMenuItem(mTag);
            
            % sets the menu check (based on data type)
            if islogical(state)
                hMenu.Checked = obj.sStr{1+state};
            else
                hMenu.Checked = state;
            end
            
        end                                
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- determine if it is feasible to run the stimuli train
        function [sTrainNw,ok] = checkStimuliTrain(obj,sTrainNw,iExptNw)
        
            % initialisations
            ok = true;
            
            % exit if a record only experiment
            if isempty(sTrainNw)
                return
            else
                % reshapes the experimental data struct
                sTrainNw = obj.reshapeExptData(sTrainNw);
                if ~checkLoadedDeviceProps(obj.objB,sTrainNw)
                    ok = false;
                    return
                end
            end
            
            % ensures the stimuli timing/duration parameters are correct
            [sTrainNw,isChange] = checkStimuliTiming(iExptNw,sTrainNw);
            if isChange
                % alert the user if there was a change
                tStr = 'Stimuli Blocks Re-configured';
                mStr = sprintf(['This protocol was altered as one or ',...
                    'more stimuli blocks were infeasible.\n',...
                    'Re-save this experimental protocol file to ',...
                    'save these changes.']);
                waitfor(msgbox(mStr,tStr,'modal'))
            end      
            
            % sets the short-term protocol units to seconds
            if ~isempty(sTrainNw.S)
                for i = 1:length(sTrainNw.S)
                    sTrainNw.S{i}.tDurU = 's';
                end
            end
            
            % ensures that the short-term stimuli duration units are set to seconds
            if ~isempty(sTrainNw.Ex)
                for i = 1:length(sTrainNw.Ex)
                    if strContains(sTrainNw.Ex{i}.sType,'Short-Term')
                        sTrainNw.Ex{i}.sTrain.tDurU = 's';
                    else
                        sTrainNw.Ex{i}.sTrain.tDurU = 'h';                        
                    end
                end
            end            
            
        end
       
        % --- converts the experiment data from the old-format .exp files
        function [iExptNw,sTrainEx] = ...
                convertExptDataLocal(obj,sTrainS,iExpt0)
            
            % converts the data from the old to new format
            [iExptNw,sTrainEx] = obj.convertExptData(sTrainS,iExpt0);
            
            % updates the start time type
            objEx = obj.objT{4};                        
            set(objEx.hRadioS{1},'Value',~iExptNw.Timing.fixedT0)
            set(objEx.hRadioS{1},'Value',iExptNw.Timing.fixedT0)
            feval(objEx.hPanelS.SelectionChangedFcn);
            
        end
        
        % --- converts the experiment data from the old-format .exp files 
        function [iExptNw,sTrainEx] = convertExptData(obj,sTrainS,iExpt0)
            
            % initialisations
            tNow = datevec(now);
            nTrain = length(sTrainS);
            iExptNw = initExptStruct(obj.objB);

            % struct initialisations
            sTrainEx = struct('sName',[],'sType',[],...
                              'sParaEx',[],'sTrain',[]);

            % memory allocation
            [sTrainEx.sName,sTrainEx.sType] = deal(cell(nTrain,1));
            [sTrainEx.sTrain,sTrainEx.sParaEx] = deal(cell(nTrain,1));
            
            % updates the timing sub-struct fields
            iExptNw.Timing.Tp = iExpt0.Timing.Tp;
            iExptNw.Timing.Texp = iExpt0.Timing.Texp;
            iExptNw.Timing.fixedT0 = sign(iExpt0.Timing.T0(1)) > 0;
            [~,iExptNw.Timing.TexpU] = vec2time(iExptNw.Timing.Texp);
            
            % sets the experiment start time (ensures the time is feasible)
            iExptNw.Timing.T0 = [tNow(1:3),iExptNw.Timing.T0(4:5),0];
            if datenum(iExptNw.Timing.T0) < now
                iExptNw.Timing.T0(3) = iExptNw.Timing.T0(3) + 1;
            end
            
            % if there is no stimuli info then exit
            if isempty(sTrainS)
                sTrainEx = [];
                return
            end
            
            for i = 1:nTrain
                % sets the stimuli type
                sType = split(sTrainS.sName);
                if strcmp(sTrainS.chName{1},'All Ch')
                    % case is all channels are used
                    ii = 1;
                else
                    % otherwise, search for the channel index
                    iiR = regexp(sTrainS.chName{1},'\d','match','once');
                    ii = str2double(iiR);
                end
                
                % sets the description/parameters
                sTrainEx.sName{i} = sTrainS.sName;
                sTrainEx.sType{i} = sprintf('%s Stimuli',sType{1});
                sTrainEx.sTrain{i} = sTrainS(i);
                
                % retrieves the parameters
                sParaEx = struct('tOfs',NaN,'tOfsU','h','tDur',NaN,...
                    'tDurU',iExpt.Timing.TexpU,'nCount',NaN,'tStim',NaN,...
                    'sName',sprintf('Stimuli Train #%i',i));
                
                % sets the initial offset/stimuli counts
                tMltEx = getTimeMultiplier('h','s');
                sParaEx.tOfs = iExpt0.Stim(ii).Ts(1)*tMltEx;
                sParaEx.nCount = iExpt0.Stim(ii).nCount;
                
                % sets the inter-stimuli duration
                if length(iExpt0.Stim(ii).Ts) > 1
                    % case is a value is provided
                    FPS = iExpt0.Video.FPS;
                    dtStim = diff(iExpt0.Stim(ii).Ts([1,2]))/FPS;
                    sParaEx.tStim = sec2vec(dtStim);
                else
                    % otherwise, use the default value
                    sParaEx.tStim = [0,1,0,0];
                end
                
                % sets the duration (in hours)
                [tDurEx0,tDurExU] = ...
                    obj.calcExptStimDurFcn(sTrainS(i),sParaEx);
                
                % updates the field within the struct
                tMltDurEx = getTimeMultiplier(iExpt.Timing.TexpU,tDurExU);
                sParaEx.tDur = tDurEx0*tMltDurEx;
                sTrainEx.sParaEx{i} = sParaEx;
                
            end

        end

        % --- updates the train class field with the current block para
        function updateBlockTrainPara(obj)
            
            for i = 1:length(obj.sTrainP.Ex)
                if i == 1
                    pFld = fieldnames(obj.sTrainP.Ex{i}.sParaEx);
                    sBlk = obj.objT{4}.objSM.sBlk;
                end
                
                for j = 1:length(pFld)
                    obj.sTrainP.Ex{i}.sParaEx.(pFld{j}) = ...
                        sBlk{i}.sPara.(pFld{j});
                end
            end
            
        end        
        
    end
    
    % static class methods
    methods (Static)
        
        function CData = getToolbarIcon(tIconF)
            
            CData = double(imread(tIconF))/2^16;
            CData(CData == 0) = NaN;
            
        end        
        
        % --- resets the experiment timing field
        function iExptNw = resetExptTiming(iExpt0,iExptNw)
            
            % sets the current year/month/day
            T0 = clock;
            iExptNw.Timing.T0(1:3) = T0(1:3);
            
            % resets the day if not currently feasible
            if datenum(iExptNw.Timing.T0) < now
                T0new = addtodate(datenum(iExptNw.Timing.T0),1,'day');
                iExptNw.Timing.T0 = datevec(T0new);
            end
            
            % resets the original inter-video pause time
            iExptNw.Timing.Tp = iExpt0.Timing.Tp;
            
        end        
        
        % --- saves the experiment protocol file
        function saveProtocolFile(fFile,iExpt,sTrain,chInfo,iStim)
            
            save(fFile,'iExpt','sTrain','chInfo','iStim');
            
        end 
        
        % ---  reshapes the experimental data struct into a cell array
        function sTrain = reshapeExptData(sTrain0)
            
            % if new format data type then exit
            if iscell(sTrain0.Ex)
                sTrain = sTrain0;
                return
            end
            
            % reallocates memory 
            [sTrainEx,sTrain] = deal(sTrain0.Ex,sTrain0);
            sTrain.Ex = cell(length(sTrainEx.sName),1);
            
            % resets the data struct fields into a cell array
            for i = 1:length(sTrain.Ex)
                sTrain.Ex{i} = struct('sName',sTrainEx.sName{i},...
                                      'sType',sTrainEx.sType{i},...
                                      'sParaEx',sTrainEx.sParaEx(i),...
                                      'sTrain',sTrainEx.sTrain(i));                        
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