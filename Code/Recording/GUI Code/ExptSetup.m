function varargout = ExptSetup(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @ExptSetup_OpeningFcn, ...
    'gui_OutputFcn',  @ExptSetup_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before ExptSetup is made visible.
function ExptSetup_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for ExptSetup
handles.output = hObject;
setObjVisibility(hObject,'off');

% global variables
global axLimMax mType dyMax isUpdating isCreateBlk
global objOff mpStrDef hSigTmp hSigSel iSigObj
global t2sStatus updateList isInit
[axLimMax,mType,dyMax,isUpdating,isCreateBlk] = deal(900,0,2.5,false,false);
[objOff,mpStrDef,hSigTmp,hSigSel,iSigObj] = deal(true,'arrow',[],[],0);
[t2sStatus,updateList,isInit] = deal(-1,true,true);

% initialisations
hProg = [];
stimOnly = false;

% sets the input arguments
switch length(varargin)
    case 1
        % case is running a video dependent experiment

        % sets the input variables
        hMain = varargin{1};        

        % loads the required structs/data objects from the main GUI
        iMov = getappdata(hMain,'iMov');    
        iProg = getappdata(hMain,'iProg');      
        infoObj = getappdata(hMain,'infoObj');
        
    case 2    
        % case is running a stimuli only experiment

        % sets the input variables
        infoObj = varargin{1};
        hProg = varargin{2};
        
        % sets the data acquistion objects into the gui
        [objDAQ,objDAQ0] = reduceDevInfo(infoObj.objDAQ);
        setappdata(hObject,'objDAQ',objDAQ)   
        setappdata(hObject,'objDAQ0',objDAQ0)             

        % loads the required structs/data objects from the main GUI
        [iMov,hMain,stimOnly] = deal([],infoObj.hFigM,true);    
        iProg = getappdata(hMain,'ProgDefNew');             

end

% makes the main gui invisible
setObjVisibility(hMain,'off')        

% sets the device/channel count information (dependent on expt/devices)
switch infoObj.exType
    case 'RecordOnly'
        % case is a recording only experiment

        % sets the device type to record only
        [devType,nCh] = deal({'RecordOnly'},NaN);

    case {'RecordStim','StimOnly'} 
        % case is a stimuli dependent experiment

        % retrives the device types from the device information struct
        devType = resetDevType(infoObj.objDAQ.sType);
        nCh = infoObj.objDAQ.nChannel;
        extnObj = feval('runExternPackage','ExtnDevices');

        % sets the device channel counts
        infoObj.iStim.nChannel(1:length(nCh)) = nCh;
        
        % updates the opto menu gui properties
        setRecordGUIProps(handles,'InitOptoMenuItems') 
        
        % sets the external device class object
        setappdata(hObject,'extnObj',extnObj);

end

% sets the function handles into the gui
setappdata(hObject,'afterExptFunc',@afterExptFunc)
setappdata(hObject,'getProtoTypeStr',@getProtoTypeStr);
setappdata(hObject,'editSingleStimPara',@editSingleStimPara);             
setappdata(hObject,'addCustomSignalTab',@addCustomSignalTab);

% sets the other important fields
setappdata(hObject,'nCh0',nCh)   
setappdata(hObject,'iMov',iMov)
setappdata(hObject,'hMain',hMain)      
setappdata(hObject,'iProg',iProg)
setappdata(hObject,'infoObj',infoObj)
setappdata(hObject,'devType',devType)
setappdata(hObject,'devType0',devType)
setappdata(hObject,'stimOnly',stimOnly)

% initialises the GUI object properties
initObjProps(handles,devType,nCh,true,hProg)

% if a recording experiment, then set the image resolution info
if ~stimOnly
    setupCustResObjects(handles)
end

% makes the gui visible
setObjVisibility(hObject,'on')
pause(0.05);

% resets the full experiment panel titles (this fixes a weird bug
% where the objects within the panels drop down by around 20 pixels?)
resetFullExptPanels(handles)
isInit = false;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ExptSetup wait for user response (see UIRESUME)
% uiwait(handles.figExptSetup);

% --- Outputs from this function are returned to the command line.
function varargout = ExptSetup_OutputFcn(hObject, eventdata, handles)

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes when user attempts to close figExptSetup.
function figExptSetup_CloseRequestFcn(hFig, eventdata, handles)

% runs the exit menu item
menuExit_Callback(handles.menuExit, [], handles)

% --- Executes on mouse motion over figure - except title and menu.
function figExptSetup_WindowButtonMotionFcn(hFig, eventdata, handles)

% global variables
global mType mpStrDef isInit

% if initialising the axes, then exit
if isInit; return; end

% ignore mouse clicjs on the experiment information tab
hTabSel = get(getappdata(hFig,'hTabGrp'),'SelectedTab');
if get(hTabSel,'UserData') == 1
    % case is the experiment information tab is selected
    mpStrDef = 'arrow';
else
    % Modify mouse pointer over axes
    mPos = get(hFig,'CurrentPoint');
    if isOverAxes(mPos)
        hHover = findAxesHoverObjects(hFig);
        if mType == 4
            % case is the placement of an experiment block
            exptPlaceMouseMove(hFig,hHover)

        elseif mType == 5 
            % case is the setting of an experiment block
            exptSetMouseMove(hFig,hHover)

        elseif ~isempty(hHover)
            %
            isChP = arrayfun(@(x)(strContains(...
                                    get(x,'tag'),'chFill')),hHover);        

            % if objects are being hovered over, then update the axes
            % properties based on the type of action being performed
            switch mType
                case {0,1} % case is a normal mouse movement
                    normalMouseMove(hFig,hHover,isChP)

                case {2} % case is the placement of a stimuli block
                    stimPlaceMouseMove(hFig,hHover,isChP)

                case {3} % case is the setting of a stimuli block
                    stimSetMouseMove(hFig,hHover,isChP)                                   

            end
        else
            % if not over anything important then turn off the block 
            % highlights (not if the signal/experiment block has been set)        
            mpStrDef = 'arrow';
            if ~any(mType == [3,5])
                turnOffFillObj(hFig)
            end
        end
    else    
        % if not over the axes then turn off the block highlights (not if 
        % the signal/experiment block has been set)
        mpStrDef = 'arrow';    
        if ~any(mType == [3,5])
            turnOffFillObj(hFig)
        end
    end
end

% sets the mouse pointer dependent on type
if isnumeric(mpStrDef)
    % case is a custom pointer
    set(hFig,'PointerShapeCData',mpStrDef,'Pointer','custom')
else
    % case is a pointer string
    set(hFig,'Pointer',mpStrDef);
end

% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figExptSetup_WindowButtonDownFcn(hFig, ~, handles, selType)

% global variables
global mpStrDef mType hSigSel iSigObj isReleased nProto

% sets the selection type (if not provided)
if nargin < 4; selType = get(hFig,'SelectionType'); end

% ignore mouse clicjs on the experiment information tab
hTabSel = get(getappdata(hFig,'hTabGrp'),'SelectedTab');
if (get(hTabSel,'UserData') == 1) && (nargin < 4)
    return
end

% updates the gui properties based on the selection/mouse hover type
switch selType
    case 'alt'
        % resets the mouse pointer and selection type
        if mType > 0
            % turns off all the fill objects
            turnOffFillObj(hFig)
            
            % resets the mouse pointer/movement index
            [mpStrDef,mType] = deal('arrow',0);
        end
        
        % determines if the mouse is not currently over the plot axes AND
        % if there is a currently selected object
        %         if ~isOverAxes(get(hFig,'CurrentPoint')) && ~isempty(hSigSel)
        if ~isempty(hSigSel)
            % if so, then disable the objects properties
            setSelectedSignalProps(handles,'off')
        end        
        
    case 'normal'        
        isReleased = false;
        switch mType
            case 0
                % determines if a signal object is currently being hovered
                % over. if so, then update the selection properties
                if iSigObj > 0
                    % if there is a currently selected object, then disable
                    % the highlight properties
                    if ~isempty(hSigSel)
                        setSelectedSignalProps(handles,'off',1)
                    end
                    
                    % turns on the properties for selected signal block
                    setSelectedSignalProps(handles,'on')
                end
                
            case 2 % case is a signal block is being placed
                
                % resets the mouse hover type flag
                mType = 0;
                
                % creates the signal object
                createSignalObject(hFig);
                
                % enables the clear all/save train buttons
                setObjEnableProps(hFig,'buttonClearAll','on')
                setObjEnableProps(hFig,'buttonSaveTrain','on')
                
                % enables the stimuli train test (short-term protocol only)
                if strcmp(getProtoTypeStr(getappdata(hFig,'pType')),'S')
                    setObjEnable(handles.buttonTestTrain,'on')
                end                
                
            case {3,5} % case is a signal block has been selected and moved
                
                % makes the distance line markers visible;
                uData = get(hSigSel,'UserData');
                
                %
                mPos = get(hFig,'CurrentPoint');                
                if isOverAxes(mPos)
                    % determines if there are an signal blocks being
                    % hovered over 
                    hHover = findAxesHoverObjects(hFig);
                    hSigBlkNw = findobj(hHover,'tag','hSigBlk');
                    if ~isempty(hSigBlkNw)     
                        % retrieves the user data from the signal block
                        uDataH = get(hSigBlkNw,'UserData');
                        iCh = uData{indFcn('iCh')};
                        
                        % determine if a change is signal block has been
                        % made (depending on the block type)
                        if length(iCh) == 1
                            % case is a stimuli block
                            isChange = ~isequal(iCh,uDataH{indFcn('iCh')});
                        else
                            % case is an experiment block
                            isChange = uData{indFcn('iBlk')} ~= ...
                                       uDataH{indFcn('iBlk')};
                        end
                        
                        if isChange
                            uData = toggleExptObjSelection(hFig,hSigBlkNw);
                        end
                    end
                end                
                
                % if the is still holding down the mouse then make the
                % distance line markers visible
                if ~isReleased && isOverAxes(get(hFig,'CurrentPoint'))
                    hDL = uData{indFcn('hDL')};
                    iProto = getProtocolIndex(hFig);
                    
                    if iProto(nProto)
                        cellfun(@(x)(setObjVisibility(x,'on')),hDL);
                    else
                        cellfun(@(x)(setObjVisibility(x,'on')),hDL);
                    end
                end
                
%             case 4 % case is an experiment block is being placed
% 
%                 % resets the mouse hover type flag
%                 mType = 0;
%                 
%                 % creates the signal object
%                 createExptObject(hFig)  
                
%             case 5 %
%                 
%                 % makes the distance line markers visible
%                 uData = get(hSigSel,'UserData');
%                 hDL = uData{indFcn('hDL')};
%                 
%                 % if the is still holding down the mouse then make the
%                 % distance line markers visible
%                 if ~isReleased
%                     cellfun(@(x)(setObjVisibility(x,'on')),hDL(:,1));
%                 end                
                
        end
        
end

% runs the windows button motion function to update the mouse location
figExptSetup_WindowButtonMotionFcn(hFig, [], handles)

% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figExptSetup_WindowButtonUpFcn(hFig, eventdata, handles)

% global variables
global mType hSigSel iSigObj isReleased
isReleased = true;

switch mType
    case {3,5} % case is a signal block has been selected and moved
        
        % hides the distance line markers
        uData = get(hSigSel,'UserData');
        cellfun(@(x)(setObjVisibility(x,'off')),uData{indFcn('hDL')});                       
        
        % resets the time limits for the signal blocks
        resetSignalBlockTimeLimits(hFig,hSigSel);
        iSigObj = 0;       
        
end

%-------------------------------------------------------------------------%
%                       MENU ITEM CALLBACK FUNCTIONS                      %
%-------------------------------------------------------------------------%

% -------------------------------------------------------------------------
function menuNewProto_Callback(hObject, eventdata, handles)

% prompts the user if they wish to continue clearing the current protocol
uChoice = questdlg(sprintf(['Are you sure you want to clear the current ',...
                    'experimental protocol?\nAny unsaved changes will ',...
                    'be lost and this process can''t be reversed.']),...
                    'Clear Current Protocol?','Yes','No','Yes');
if ~strcmp(uChoice,'Yes'); return; end     

% sets the other important fields
hFig = handles.figExptSetup;
devType = getappdata(hFig,'devType0');
nCh = getappdata(hFig,'nCh0');

% resets the other fields  
setappdata(hFig,'pType','Experiment Information')  
setappdata(hFig,'sTrain',initStimTrainPara())  

% sets up and sets the experiment info data struct
iExpt = initExptStruct(hFig);
setappdata(hFig,'iExpt',iExpt)

% updates the start time type (based on whether there is a fixed start)
hPanel = handles.panelExptStartTime;
set(handles.radioFreeExptStart,'Value',~iExpt.Timing.fixedT0)
set(handles.radioFixedStartTime,'Value',iExpt.Timing.fixedT0)
panelExptStartTime_SelectionChangedFcn(hPanel, '1', handles)

% initialises the GUI object properties
pType0 = getappdata(hFig,'pType');
initObjProps(handles,devType,nCh,false)

% resets the selected tab 
tabSelected(findall(hFig,'Title',pType0), [], handles)

% -------------------------------------------------------------------------
function menuOpenProto_Callback(hObject, eventdata, handles)

% initialisations 
hFig = handles.figExptSetup;  
iProg = getappdata(hFig,'iProg');
infoObj = getappdata(hFig,'infoObj');

% retrieves the default directory
if isempty(iProg)
    dDir = pwd;
else
    dDir = iProg.DirPlay;
end

% prompts the user for the output file name/directory
[fName,fDir,fIndex] = uigetfile(...
    {'*.spl;*.exp;*.expp','Protocol Data Files (*.spl, *.exp, *.expp)'},...
    'Load Stimulus Playlist File',dDir);
if fIndex == 0
    % if the user cancelled, then exit the function
    return
end
    
% flag intialisation
resetStimTrain = true;

% removes any currently selected signal blocks
figExptSetup_WindowButtonDownFcn(hFig, [], handles, 'alt')

% loads the stimulus playlist file
fData = importdata(fullfile(fDir,fName));
[~,fName,fExtn] = fileparts(fName);                
switch fExtn
    case '.exp'
        % if the experimental protocol file was loaded, then set 
        % the experimental/stimulus playlist structs       
        iStim = fData.iStim;
        [sTrainS,dType,nCh] = convertStimData(fData);            
        [iExpt,sTrainEx] = ...
                        convertExptDataLocal(handles,sTrainS,fData.iExpt); 

        % sets up the train data struct
        sTrain = struct('S',[],'L',[],'Ex',[]);
        [sTrain.S,sTrain.Ex] = deal(sTrainS,sTrainEx);
                    
    case '.expp'
        %
        resetStimTrain = false;   
        if isfield(fData,'iExpt')
            [iExpt,sTrain] = deal(fData.iExpt,fData.sTrain);
            dType = unique(fData.chInfo(:,3),'stable');            
            nCh = cellfun(@(x)(sum(strcmp(fData.chInfo(:,3),x))),dType);

            % initialisese the stimuli data struct
            if isfield(fData,'iStim')
                % retrieves the field if available
                iStim = fData.iStim;
            else
                % otherwise, create a new struct
                iStim = initTotalStimParaStruct();
            end
        else
            [iExpt,sTrain] = deal(fData,[]);
            [dType,nCh] = deal({'RecordOnly'},NaN);
            iStim = initTotalStimParaStruct();
        end

    otherwise
        % otherwise, set the stimulus protocol playlist and sets 
        % up the experimental playlist struct
        [sTrainS,dType,nCh] = convertStimData(fData);        
        iExpt = initExptStruct(objIMAQ,exptType);
        iStim = initTotalStimParaStruct();
        sTrainEx = [];
end

% ensures the start time to this day
T0 = clock;
iExpt.Timing.T0(1:3) = T0(1:3);
if datenum(iExpt.Timing.T0) < now
    % if the start time is before now, then add a day to the time
    T0new = addtodate(datenum(iExpt.Timing.T0),1,'day');
    iExpt.Timing.T0 = datevec(T0new);
end

% determines if the currently loaded device properties are sufficient
% to run this experiment
if ~isempty(sTrain)
    ok = checkLoadedDeviceProps(hFig,sTrain);
    if ~ok
        % if not, or the user cancels, then exit the function
        return
    end
    
    % ensures the stimuli timing/duration parameters are correct
    [sTrain,isChange] = checkStimuliTiming(iExpt,sTrain);
    if isChange
        % alert the user if there was a change
        mStr = sprintf(['This protocol was altered as one or more ',...
                        'stimuli blocks were infeasible.\n',...
                        'Re-save this experimental protocol file to ',...
                        'save these changes.']);
        waitfor(msgbox(mStr,'Stimuli Blocks Re-configured','modal'))
    end    
end

% sets the experiment file name
iExpt.Info.FileName = sprintf('%s%s',fName,fExtn);        
if resetStimTrain
    % initalises and sets the stimuli train data   
    sTrain = initStimTrainPara();
    sTrain.S = cell(length(sTrainS),1);

    for i = 1:length(sTrainS)
        % adds in the short-term protocol parameters
        sTrain.S{i} = sTrainS(i);             
    end

    % adds in the experiment protocol parameters (if any)
    if ~isempty(sTrainEx)
        sTrain(i).Ex = sTrainEx(i); 
    end        
end    

if ~isempty(sTrain)
    % sets the short-term protocol units to seconds
    if ~isempty(sTrain.S)
        for i = 1:length(sTrain.S)
            sTrain.S{i}.tDurU = 's';
        end
    end

    % ensures that the short-term stimuli duration units are set to seconds
    if ~isempty(sTrain.Ex)
        for i = 1:length(sTrain.Ex.sType)
            if strContains(sTrain.Ex.sType{i},'Short-Term')
                sTrain.Ex.sTrain(i).tDurU = 's';
            end
        end
    end
end

% updates the stimuli parameter struct
infoObj.iStim = iStim;

% updates the loaded data within the gui    
setappdata(hFig,'iExpt',iExpt)
setappdata(hFig,'sTrain',sTrain)
setappdata(hFig,'infoObj',infoObj)

% initialises the object properties
pType0 = getappdata(hFig,'pType');
initObjProps(handles,dType(:)',nCh,false)

% resets the selected tab 
tabSelected(findall(hFig,'Title',pType0), [], handles)

% -------------------------------------------------------------------------
function menuSaveProto_Callback(hObject, eventdata, handles)

% initialisations 
hFig = handles.figExptSetup;  
iProg = getappdata(hFig,'iProg');
sTrain = storeExptTrainPara(hFig);

% determines if any stimuli trains have been saved
if ~strcmp(getappdata(hFig,'devType'),'RecordOnly')
    if all(cellfun('isempty',getStructFields(sTrain)))
        wStr = ['Warning. There are currently no stimuli protocols set ',...
                'for this experiment. Do you still wish to continue?'];
        uChoice = questdlg(wStr,'No Protocols Set?','Yes','No','Yes');
        if ~strcmp(uChoice,'Yes')
            % if the user cancelled, then exit
            return
        end
    end
end

% retrieves the default directory
if isempty(iProg)
    dDir = pwd;
else
    dDir = iProg.DirPlay;
end

% prompts the user for the output file name/directory
fType = {'*.expp','Stimulus Playlist Files (*.expp)'};
[fName,fDir,fIndex] = uiputfile(fType,'Save Experiment Protocol File',dDir);
if (fIndex ~= 0)
    % if the user didn't cancel, then 
    iExpt = getappdata(hFig,'iExpt');
    sTrain = storeExptTrainPara(hFig);
    chInfo = getappdata(hFig,'chInfo');
    infoObj = getappdata(hFig,'infoObj');    
    
    % sets the experiment file name
    iStim = infoObj.iStim;
    iExpt.Info.FileName = fName;   
    set(handles.textFileName,'String',fName);
    
    % updates the stimuli train parameter struct
    setappdata(hFig,'sTrain',sTrain)
    
    % outputs the experimental protocol data to file
    fFile = fullfile(fDir,fName);
    save(fFile,'iExpt','sTrain','chInfo','iStim');        
end

% -------------------------------------------------------------------------
function menuDiskSpace_Callback(hObject, eventdata, handles)

% runs the disk space gui
DiskSpace()

% -------------------------------------------------------------------------
function menuExit_Callback(hObject, eventdata, handles)

% prompts the user if they want to close the GUI
qStr = 'Are you sure you want to close the GUI?';
uChoice = questdlg(qStr,'Close GUI?','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    % if the user cancelled, then exit
    return
end

% initialisations
hFig = handles.figExptSetup;
hMain = getappdata(hFig,'hMain');
iExpt = getappdata(hFig,'iExpt');
infoObj = getappdata(hFig,'infoObj');

% stops the timer object
try
    timerObj = getappdata(hFig,'timerObj');
    stop(timerObj)
    delete(timerObj)
end

% if the IR lights are on, then turn them off (opto only)
if strcmp(get(handles.menuOpto,'Visible'),'on')
    if strcmp(get(handles.menuToggleIR,'Checked'),'on')
        menuToggleIR_Callback(handles.menuToggleIR, '1', handles)    
    end    
end

switch infoObj.exType
    case 'StimOnly'
        % closes the GUI
        delete(hFig)
        pause(0.05);        
        
        % case is a stimui type expt (re-opens DART)
        setObjVisibility(infoObj.hFigM,'on')
        
    otherwise
        % case is a recording type expt (re-opens FlyRecord)
        
        % if so, then update the experiment/stimuli train data structs
        setappdata(hMain,'iExpt',iExpt)
        setappdata(hMain,'infoObj',infoObj)
        setappdata(hMain,'sTrain',storeExptTrainPara(hFig))

        % closes the GUI
        delete(hFig)
        pause(0.05);        
        
        % makes the main gui visible again
        if ~isempty(hMain)
            % re-enables the menu items
            hMainH = guidata(hMain);
            setObjEnable(hMainH.menuFile,'on');
            setObjEnable(hMainH.menuExpt,'on');
            setObjEnable(hMainH.menuOpto,'on');

            % sets focus to the recording gui
            figure(hMain); 
        end
end

% -------------------------------------------------------------------------
function menuRunExpt_Callback(hObject, eventdata, handles)

% retrieves the fly record GUI handles
hFig = handles.figExptSetup;
iExpt = getappdata(hFig,'iExpt');
infoObj = getappdata(hFig,'infoObj');
timerObj = getappdata(hFig,'timerObj');

% stops the experiment start-time timer
stop(timerObj)

% checks the video resolution is feasible (exit if not)
if infoObj.hasIMAQ
    % sets the main gui to be the recording gui
    hMain = getappdata(hFig,'hMain');
    
    if ~checkVideoResolution(infoObj.objIMAQ,iExpt.Video)
        start(timerObj)
        return
    end

    % determines if there is feasible space to store the experiment's videos
    mStr = calcVideoTiming(handles);
    if ~isempty(mStr)
        % if not, then prompt the user if they wish to continue
        mStr = sprintf(['%sDo you still wish to continue with ',...
                        'the experiment?'],mStr);
        uChoice = questdlg(mStr,'Low Space Warning!','Yes','No','Yes');
        if ~strcmp(uChoice,'Yes')
            % if not, then exit the experiment
            start(timerObj)
            return
        end
    end
else
    % sets the main gui to be the experiment setup gui
    hMain = hFig;    
end

% determines if the stimuli protocol has been set (record-stim expts only)
if infoObj.hasDAQ
    % updates the experiment data struct with the experiment type
    iExpt = getappdata(hMain,'iExpt');    
    
    % if this is a record-stim expt, then determine if the experimental
    % stimuli protocol has been set
    sTrain = getappdata(hFig,'sTrain');    
    if isempty(sTrain.Ex)
        % if not, prompt the user if they wish to continue
        tStr = 'Stimuli Protocol Missing?';
        qStr = sprintf(['A stimuli protocol has not been set for this ',...
                        'experiment, despite external devices being ',...
                        'detected.\n\nAre you sure you want to continue?']);
        uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
        if strcmp(uChoice,'Yes')
            % resets the experiment type flag to record only
            exptType = 'RecordOnly';
            
        else
            start(timerObj)
            return
        end
        
    else
        % otherwise, sets the experiment type to Recording + Stimuli
        exptType = 'RecordStim';            
    end    
    
    % updates the alter parameter menu item (if package is available)
    spixObj = getappdata(hFig,'spixObj');
    if ~isempty(spixObj)
        spixObj.setVideoTime(vec2sec(iExpt.Timing.Texp))
    end    
    
    % updates the experiment information
    iExpt.Info.Type = exptType;
    setappdata(hMain,'iExpt',iExpt)
end

% disables the video preview button (if recording video)
if infoObj.hasIMAQ
    hMainH = guidata(hMain);
    if get(hMainH.toggleVideoPreview,'Value')
        % retrieves the toggle button callback function
        toggleFcn = getappdata(hMain,'toggleVideoPreview');

        % unchecks the box and runs the callback function
        set(hMainH.toggleVideoPreview,'Value',0)
        toggleFcn(hMainH.toggleVideoPreview,'1',guidata(hMain))
    end
    
    % disables the relevant objects
    setObjEnable(hMainH.toggleVideoPreview,'off')
    setObjEnable(hMainH.menuAdaptors,'off')
    setObjEnable(hMainH.menuCalibrate,'off')    
end

% makes the experimental info GUI invisible
setObjVisibility(hFig,'off')
if infoObj.hasIMAQ
    if ~isempty(hMain); figure(hMain); end
end

% initialises and runs the experiment object
exObj = RunExptObj(hMain,'Expt',hFig,false,false);
setappdata(hFig,'exObj',exObj)
exObj.startExptObj()

% --------------------------------------------------------------------
function menuToggleIR_Callback(hObject, eventdata, handles)

% toggles the IR lights
toggleOptoLights(handles,hObject,true)

% --------------------------------------------------------------------
function menuToggleWhite_Callback(hObject, eventdata, handles)

% toggles the white lights
toggleOptoLights(handles,hObject,false)

% --- function that runs after the experiment is complete --- %
function afterExptFunc(hFig)

% retrieves the timer object
handles = guidata(hFig);
exObj = getappdata(hFig,'exObj');
infoObj = getappdata(hFig,'infoObj');
hMainH = guidata(getappdata(hFig,'hMain'));
    
% turns off the camera (if still running)
if infoObj.hasIMAQ
    if isDeviceRunning(infoObj)
        stopRecordingDevice(infoObj)
    end
    
    % converts the videos (if required)
    exObj.convertExptVideos();

    % re-enables the video preview button
    setObjEnable(hMainH.toggleVideoPreview,'on')
    setObjEnable(hMainH.menuAdaptors,'on')
    setObjEnable(hMainH.menuCalibrate,'on')
end

% deletes the experiment object struct
setObjVisibility(exObj.hMain,'off')
setappdata(hFig,'exObj',[])

% updates the experiment title string
editExptTitle_Callback(handles.editExptTitle, '1', handles)
setObjVisibility(hFig,'on');

try 
    start(getappdata(hFig,'timerObj'))
catch ME
    initTimerObj(handles)
    start(getappdata(hFig,'timerObj'))
end

% --- adds in a custom signal tab
function ok = addCustomSignalTab(handles,sObj,isLoading)

% object retrieval 
ok = true;
dType = {'S','L'};
hFig = handles.figExptSetup;
	  
% creates the parameter tab/objects for the short/long-term 
% protocol tabs    
for i = 1:2
	% retrieves the parameter struct (based on duration type)
	sPara = getParaStruct(hFig,dType{i});
    if isfield(sPara,sObj.sName)
        % if the signal type already exists, then output an error to screen
        mStr = sprintf(['The signal type "%s" is already included ',...
                        'in the signal list.'],sObj.sName);
        waitfor(msgbox(mStr,'Signal Already Exists','modal'))
                    
        % if the signal type already exists, then exit the function
        ok = false;
        return
    end
    
    % appends the new signal type to the parameter struct
    sPara = setupSignalPara...
                    (sPara,sObj.sName,dType{i},copyClassObj(sObj));

    % retrieves the tab group object
    hTab = getappdata(hFig,sprintf('hTab%s',dType{i}));
    hTabGrp = getappdata(hFig,sprintf('hTabGrp%s',dType{i}));

    % creates a new tab panel
    nTab = length(hTab)+1;
    hTab{end+1} = createNewTabPanel(...
                    hTabGrp,1,'title',sObj.sName,'UserData',nTab);
    set(hTab{nTab},'ButtonDownFcn',...
                    {@tabSelectedPara,handles,dType{i}}) 
    if isLoading
        set(hTabGrp,'SelectedTab',hTab{nTab})
    end

    % creates the parameter objects for the current tab
    createParaObj(handles,hTab{nTab},sPara,dType{i});
    setappdata(hFig,sprintf('sPara%s',dType{i}),sPara)

    % updates the tab group array
    setappdata(hFig,sprintf('hTab%s',dType{i}),hTab);
end

% updates the signal type into the gui
setappdata(hFig,'sType',sObj.sName)

%-------------------------------------------------------------------------%
%                        TOOLBAR CALLBACK FUNCTIONS                       %
%-------------------------------------------------------------------------%

% --------------------------------------------------------------------
function buttonNewProto_ClickedCallback(hObject, eventdata, handles)

% runs the new protocol menu item
menuNewProto_Callback(handles.menuNewProto, [], handles)

% -------------------------------------------------------------------------
function buttonOpenProto_ClickedCallback(hObject, eventdata, handles)

% runs the open protocol menu item
menuOpenProto_Callback(handles.menuSaveProto, [], handles)

% -------------------------------------------------------------------------
function buttonSaveProto_ClickedCallback(hObject, eventdata, handles)

% runs the save protocol menu item
menuSaveProto_Callback(handles.menuOpenProto, [], handles)

% -------------------------------------------------------------------------
function toggleZoomAxes_ClickedCallback(hObject, eventdata, handles)

% updates the axes zoom properties
setAxesZoomProperties(handles,get(hObject,'State'))

%-------------------------------------------------------------------------%
%                 EXPERIMENT INFO TAB CALLBACK FUNCTIONS                  %
%-------------------------------------------------------------------------%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    EXPERIMENT INFORMATION PARAMETER CALLBACKS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in buttonOutDir.
function buttonOutDir_Callback(hObject, eventdata, handles)

% retrieves the experimental protocol data struct
hFig = handles.figExptSetup;
iExpt = getappdata(hFig,'iExpt');

% prompts the user for the new default directory
dirName = uigetdir(iExpt.Info.OutDir,'Set The Default Path');
if dirName
    % otherwise, update the directory string names
    iExpt.Info.OutDir = dirName;
    setappdata(hFig,'iExpt',iExpt);
       
    % resets the enabled properties of the buttons
    set(handles.editOutDir,'string',['  ',dirName],...
                           'tooltipstring',dirName)
    set(handles.editOutDir,'tooltipstring',dirName)    
    editExptTitle_Callback(handles.editExptTitle, '1', handles)
    
    % updates the video timing
    calcVideoTiming(handles);
end

% --- Executes on updating editExptTitle.
function editExptTitle_Callback(hObject, eventdata, handles)

% retrieves the experimental protocol data struct
hFig = handles.figExptSetup;
iExpt = getappdata(hFig,'iExpt');

% only update if usser has updated the edit box
if (~isa(eventdata,'char'))
    % retrieves the string and checks if it is valid
    nwStr = get(hObject,'string');
    if (chkDirString(nwStr))
        % sets the indices of the white/non-white space
        [ind,indT] = deal(regexp(nwStr,' '),regexp(nwStr,'[\w]')); 

        % determines if there are any white-spaces before the text
        ind = ind(ind < indT(1));
        if (isempty(ind))
            % if not, then set the first letter to be the first
            indS = 1;
        else
            % otherwise, set the first letter to be after the last space
            indS = ind(find(diff([ind 1e10])>1,1,'first'))+1;
        end

        % updates the info title and the experimental protocol data struct
        iExpt.Info.Title = nwStr(indS:end);
        set(hObject,'string',['  ',iExpt.Info.Title],...
                    'tooltipstring',iExpt.Info.Title)
        setappdata(hFig,'iExpt',iExpt)
    else
        % resets the title string and exits the function
        set(hObject,'string',['  ',iExpt.Info.Title])
        return
    end
end

% check to see if the output directory is unique
nwExptDir = fullfile(iExpt.Info.OutDir,iExpt.Info.Title);
if (exist(nwExptDir,'dir'))
    % updates the unique directory check box and experiment title colour
    isUniq = false;
    set(handles.textExptTitle,'foregroundcolor','r');
    
    % if the user changed the title, then diplay a warning
    if (~isa(eventdata,'char'))
        wStr = {'Warning! Output directory already exists.';...
                'Enter a unique directory to enable experiment to start.'};
        waitfor(warndlg(wStr,'Existing Output Directory','modal'))
    end
else
    % updates the unique directory check box and experiment title colour
    isUniq = true;
    set(handles.textExptTitle,'foregroundcolor','k');        
end

% updates the unique directory flag
updateFeasFlag(handles,'checkUniqDir',isUniq)

% --- Executes on updating editBaseName.
function editBaseName_Callback(hObject, eventdata, handles)

% retrieves the experimental protocol data struct
hFig = handles.figExptSetup;
iExpt = getappdata(hFig,'iExpt');

% retrieves the string
nwStr = get(hObject,'string');
if (chkDirString(nwStr))
    % determines if the first point where there is any empty space
    ind = regexp(nwStr,' '); 
    if (isempty(ind))
        ind = 0;
    end

    % updates the info title and the experimental protocol data struct
    iExpt.Info.BaseName = nwStr((ind(end)+1):end);
    set(hObject,'string',['  ',iExpt.Info.BaseName],...
                'tooltipstring',iExpt.Info.BaseName)
    setappdata(hFig,'iExpt',iExpt)
else
    % otherwise, reset the string to the last valid string
    set(hObject,'string',['  ',iExpt.Info.BaseName])    
end

% --- Executes on button press in checkFixStart.
function checkFixStart_Callback(hObject, eventdata, handles)

% updates the 
set(handles.radioFreeExptStart,'Value',~get(hObject,'Value'));
set(handles.radioFixedStartTime,'Value',get(hObject,'Value'));

% runs the experiment 
hPanel = handles.panelExptStartTime;
panelExptStartTime_SelectionChangedFcn(hPanel, '1', handles)

% --- Executes on selection change in popupStartDay.
function popupVideoDuration(hObject, eventdata, handles, varargin)

% loads the data struct
hFig = handles.figExptSetup;
iExpt = getappdata(hFig,'iExpt');
iSel = get(hObject,'UserData');
D0 = iExpt.Video.Dmax(iSel);

% updates the new selection
iExpt.Video.Dmax(iSel) = get(hObject,'value') - 1;
if (sum(iExpt.Video.Dmax) == 0)
    % if the video duration is zero, then output an error to screen
    eStr = 'Error! Video duration must be greater than zero.';
    waitfor(msgbox(eStr,'Incorrect Video Duration','modal'))
    
    % resets the popup menu value
    set(hObject,'value',D0+1)
else
    % otherwise determine if the duration of the video exceeds the experiment
    if (vec2sec([0,iExpt.Video.Dmax]) > vec2sec(iExpt.Timing.Texp)) 
        isVerbose = isempty(varargin);
        iExpt = resetVideoDurationPopup(handles,iExpt,isVerbose);        
    end        
    
    % updates the experiment data struct
    setappdata(hFig,'iExpt',iExpt)

    % sets the fixed duration panel properties
    calcVideoTiming(handles);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    VIDEO RECORDING PARAMETER CALLBACKS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on selection change in popupFrmRate.
function popupFrmRate_Callback(hObject, eventdata, handles)

% loads the data struct and frame list strings
hFig = handles.figExptSetup;
iExpt = getappdata(hFig,'iExpt');
fList = get(hObject,'String');

% updates the experimental data struct 
iExpt.Video.FPS = str2double(fList(get(hObject,'Value')));
setappdata(hFig,'iExpt',iExpt);

% recalculates the video timing
calcVideoTiming(handles);  

% --- Executes on slider movement.
function sliderFrmRate_Callback(hObject, eventdata, handles)

% object retrieval
hFig = handles.figExptSetup;
iExpt = getappdata(hFig,'iExpt');
infoObj = getappdata(hFig,'infoObj');
nwVal = round(get(hObject,'Value'),1);

% sets the camera frame rate
srcObj = get(infoObj.objIMAQ,'Source');
fpsFld = getCameraRatePara(srcObj);
fpsLim = getFrameRateLimits(srcObj,fpsFld);

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
iExpt.Video.FPS = nwValN;
set(handles.editFrmRate,'String',num2str(iExpt.Video.FPS))
setappdata(hFig,'iExpt',iExpt);

% recalculates the video timing
set(srcObj,fpsFld,nwVal);
calcVideoTiming(handles);  

% --- Executes on updating editFrmRate
function editFrmRate_Callback(hObject, eventdata, handles)

% object retrieval
hFig = handles.figExptSetup;
iExpt = getappdata(hFig,'iExpt');
infoObj = getappdata(hFig,'infoObj');
nwVal = str2double(get(hObject,'String'));

% sets the camera frame rate
srcObj = get(infoObj.objIMAQ,'Source');
fpsFld = getCameraRatePara(srcObj);
fpsLim0 = getFrameRateLimits(srcObj,fpsFld);

% converts the limits to numbers (if required)
if iscell(fpsLim0)
    fpsLim = cellfun(@str2double,fpsLim0);
else
    fpsLim = fpsLim0;
end

% determines if the new value is valid
if chkEditValue(nwVal,fpsLim,0)   
    % converts the value to a character (if required)
    if ischar(class(get(srcObj,fpsFld)))
        fpsInfo = propinfo(srcObj,fpsFld);
        cVal = cellfun(@str2double,sort(fpsInfo.ConstraintValue));

        % determines if the value matches
        ii = cVal == nwVal;       
        if ~any(ii)
            ii = argMin(abs(cVal - nwVal));
            nwVal = cVal(ii);
            set(hObject,'String',nwVal)
        end
        
        set(srcObj,fpsFld,fpsLim0{ii});
    else
        set(srcObj,fpsFld,nwVal);
    end
    
    % updates the parameter value
    iExpt.Video.FPS = nwVal;
    setappdata(hFig,'iExpt',iExpt);    
    
    % recalculates the video timing
    set(handles.sliderFrmRate,'Value',nwVal)
    calcVideoTiming(handles);
else
    % otherwise, reset the edit value
    set(handles.editFrmRate,'String',num2str(iExpt.Video.FPS))
end

% --- Executes on selection change in popupVideoCompression.
function popupVideoCompression_Callback(hObject, eventdata, handles)

% retrieves the experimental data struct
hFig = handles.figExptSetup;
iSel = get(hObject,'Value');
pStr = getappdata(hObject,'pStr');
iExpt = getappdata(hFig,'iExpt');

% updates the compression string type
iExpt.Video.vCompress = pStr{iSel};
setappdata(hFig,'iExpt',iExpt);

% updates the calculation video timing
calcVideoTiming(handles);

% --- Executes on button press in buttonOptPlace.
function buttonOptPlace_Callback(hObject, eventdata, handles)

% initialisations
hFig = handles.figExptSetup;
devType = getappdata(hFig,'devType');
iExpt = getappdata(hFig,'iExpt');

% retrieves the important timing/video fields
nCount = iExpt.Video.nCount;
tExp = vec2sec(iExpt.Timing.Texp);
tP = iExpt.Timing.Tp;

%
switch devType{1}
    case 'RecordOnly'
        % case is a recording only experiment
        
        % recalculates the maximum duration of the videos
        Dmax0 = sec2vec(ceil((tExp - (nCount-1)*tP)/nCount));        
        if Dmax0(1) > 0
            Dmax0(2) = 24*Dmax0(1);
        end
            
        % updates the 
        DmaxNw = Dmax0(2:end);
        
    otherwise
        % case is a stimuli dependent experiment
        
        % REMOVE ME LATER
        DmaxNw = iExpt.Video.Dmax;
        
end

% resets the video duration properties
iExpt = resetVideoDurationPopup(handles,iExpt,false,DmaxNw);
setappdata(hFig,'iExpt',iExpt);

% resets the video parameters
popupVideoDuration(handles.popupVidHour, [], handles, 1)

% --- retrieves the frame rate limits
function fpsLim = getFrameRateLimits(srcObj,fpsFld)

% parameters
fpsMax = 200;

% retrieves the property information
fpsInfo = propinfo(srcObj,fpsFld);

% retrieves the limit values
if iscell(fpsInfo.ConstraintValue)
    fpsLim0 = sort(fpsInfo.ConstraintValue);   
    fpsLim = fpsLim0([1,end]);
else
    fpsLim = fpsInfo.ConstraintValue;
    fpsLim(2) = min(fpsLim(2),fpsMax);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    VIDEO RESOLUTION OBJECT CALLBACKS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in checkCustRes.
function checkCustRes_Callback(hObject, eventdata, handles)

% field retrieval
hFig = handles.figExptSetup;
hText = findall(handles.panelVideoRes,'Style','Text');
hEdit = findall(handles.panelVideoRes,'Style','Edit');

% updates the struct field
resInfo = getappdata(hFig,'resInfo');
resInfo.useCust = get(hObject,'Value');
setappdata(hFig,'resInfo',resInfo)

% updates the object enabled properties
arrayfun(@(x)(setObjEnable(x,resInfo.useCust)),hText)
arrayfun(@(x)(setObjEnable(x,resInfo.useCust)),hEdit)

% retrieves the editbox value (based on the user choice type)
if resInfo.useCust
    % case is using the custom resolution
    resInfo = getappdata(hFig,'resInfo');
    eVal = getStructFields(resInfo,{'W','H'},1);
else
    % case is using the default resolution
    infoObj = getappdata(hFig,'infoObj');
    if infoObj.isWebCam
        eVal = infoObj.objIMAQ.pROI(3:4);
    else
        eVal = infoObj.objIMAQ.VideoResolution;
    end
end

% updates the editbox values
arrayfun(@(h,v)(set(h,'String',num2str(v))),hEdit(:),eVal(:));

% --- Executes on editbox update
function editResDim(hObject, eventdata, handles)

% field retrieval
hFig = handles.figExptSetup;
pStr = get(hObject,'UserData');
infoObj = getappdata(hFig,'infoObj');
resInfo = getappdata(hFig,'resInfo');

% retrieves the new value
nwVal = str2double(get(hObject,'String'));
vRes = getRecordingResolution(infoObj);

% determines if the new value is valid
if chkEditValue(nwVal,[20,vRes(strcmp({'W','H'},pStr))],1)
    % if so, then update the data struct
    resInfo = setStructField(resInfo,pStr,nwVal);
    setappdata(hFig,'resInfo',resInfo)
else
    % otherwise, reset to the last valid value
    set(hObject,'String',num2str(getStructField(resInfo,pStr)));
end

%-------------------------------------------------------------------------%
%                    WINDOWS MOTION CALLBACK FUNCTIONS                    %
%-------------------------------------------------------------------------%

% --- case is the mouse is moving normally (no stimuli block created)
function normalMouseMove(hFig,hHover,isChP)

% global variables
global mType mpStrDef objOff

% determines if the mouse is hovering over a channel
if ~any(isChP)
    % turns off all the fill objects (if signal block not selected)
    turnOffFillObj(hFig)
    
else    
    % change the mouse pointer to indicated a channel is being hovered over
    [mpStrDef,objOff] = deal('hand',false);
    
    % checks the current channel is highlighted correctly
    checkCurrentChannelHighlight(hFig,hHover,isChP)
    
    % if adding a new block, then determine if the current location is
    % feasible for adding a new block
    if mType == 1
        % determines if it is feasible to add a new block (i.e., the new 
        % block doesn't overlap an existing blocks)
        iCh = getappdata(hFig,'iCh');    
        if isFeasSigBlockPos(hFig,iCh)
            % if so, then create the new signal object block
            mType = 2*(1 + (find(getProtocolIndex(hFig)) == 4));
            createTempSignalObject(hFig,iCh)
        end        
    end
    
    % resets the current stimuli block highlight
    checkCurrentStimBlockHighlight(hFig,hHover)
end
    
% --- mouse movement function for placing a stimuli block
function stimPlaceMouseMove(hFig,hHover,isChP)

% global variables
global mpStrDef objOff

% determines if the mouse is hovering over a channel
if ~any(isChP)
    % turns off all the fill objects (if signal block not selected)
    turnOffFillObj(hFig)
else    
    % change the mouse pointer to indicated a channel is being hovered over
    [mpStrDef,objOff] = deal('hand',false);
    
    % checks the current channel is highlighted correctly
    checkCurrentChannelHighlight(hFig,hHover,isChP)
    
    % checks if the stimuli block is highlighted correctly
    checkCurrentStimBlockHighlight(hFig,hHover)
    checkCurrentTempBlockChannel(hFig,hHover)
    checkTempBlockLimits(hFig)
end

% --- mouse movement function for setting a stimuli block
function stimSetMouseMove(hFig,hHover,isChP)

% global variables
global mpStrDef objOff

% determines if the mouse is hovering over a channel
if any(isChP)  
    % change the mouse pointer to indicated a channel is being hovered over
    [mpStrDef,objOff] = deal('hand',false);
    
    % checks the current stimuli block highlight
    checkCurrentStimBlockHighlight(hFig,hHover)
end

% --- mouse movement function for placing an experiment block
function exptPlaceMouseMove(hFig,hHover)

% global variables
global hSigTmp mpStrDef objOff

%
pPos = hSigTmp.getPosition();
mPos = get(get(hFig,'CurrentAxes'),'CurrentPoint');
isWithin = (mPos(1,2)>pPos(2)) && (mPos(1,2)<sum(pPos([2,4])));

% determines if the mouse is hovering over a channel
if ~isWithin
    % turns off all the fill objects (if signal block not selected)
    turnOffFillObj(hFig)
else    
    % change the mouse pointer to indicated a channel is being hovered over
    [mpStrDef,objOff] = deal('hand',false);

    %
    checkCurrentStimBlockHighlight(hFig, hHover)
    checkTempBlockLimits(hFig)
end

% --- mouse movement function for setting an experiment block
function exptSetMouseMove(hFig,hHover)

% global variables
global hSigSel mpStrDef objOff

%
pPos = hSigSel.getPosition();
mPos = get(get(hFig,'CurrentAxes'),'CurrentPoint');
isWithin = (mPos(1,2)>pPos(2)) && (mPos(1,2)<sum(pPos([2,4])));

% determines if the mouse is hovering over a channel
if ~isWithin
    % turns off all the fill objects (if signal block not selected)
    turnOffFillObj(hFig)
else    
    % change the mouse pointer to indicated a channel is being hovered over
    [mpStrDef,objOff] = deal('hand',false);
    
    % checks the current stimuli block highlight
    checkCurrentStimBlockHighlight(hFig,hHover)
end

%-------------------------------------------------------------------------%
%                         OTHER CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    TAB OBJECT CALLBACKS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- callback function for selecting the protocol tabs
function tabSelected(hObj, ~, handles)

% global variables
global mpStrDef mType
[mpStrDef,mType] = deal('arrow',0);

% de-selects any selected groups
hFig = handles.figExptSetup;
figExptSetup_WindowButtonDownFcn(hFig, [], handles, 'alt')

% updates the mouse pointer
set(handles.figExptSetup,'Pointer',mpStrDef)

% updates the protocol type into the GUI
pType = get(hObj,'Title');
setappdata(hFig,'pType',pType)

% retrieves the selected signal type from the parameter tab
dType = getProtoTypeStr(pType);
hTabG = getappdata(hFig,sprintf('hTabGrp%s',dType));
sType = get(get(hTabG,'SelectedTab'),'Title');

%
if strcmp(dType,'Ex')
    hListEx = getProtoObj(hFig,'listStimTrainEx',sType(1));
    setappdata(hFig,'hListEx',hListEx)
end

% updates the zoom toggle button enabled properties 
iProto = getProtocolIndex(hFig);
setObjEnable(handles.toggleZoomAxes,~iProto(1));

% updates the current axes based on the select tab
set(hFig,'CurrentAxes',getProtoAxes(handles,pType))
setappdata(hFig,'sType',sType)

% updates the alter parameter menu item (if package is available)
csObj = getappdata(hFig,'csObj');
if ~isempty(csObj)
    csObj.updateAlterParaEnable()
end

% --- callback function for selecting the single stimuli tabs
function tabSelectedPara(hObj, ~, handles, dType)

% de-selects any selected groups
hFig = handles.figExptSetup;
figExptSetup_WindowButtonDownFcn(hFig, [], handles, 'alt')

% updates the signal type into the GUI
setappdata(hFig,'sType',get(hObj,'Title'))

% updates the alter parameter menu item (if package is available)
csObj = getappdata(hFig,'csObj');
if ~isempty(csObj)
    try
        csObj.updateAlterParaEnable()
    catch
        setappdata(hFig,'csObj',[])
    end
end

% --- callback function for selecting the experiment protocol tab
function tabSelectedExpt(hObj, eventdata, handles)

% de-selects any selected groups
hFig = handles.figExptSetup;
if ~ischar(eventdata)    
    figExptSetup_WindowButtonDownFcn(hFig, [], handles, 'alt')
    
    % retrieves the currently selected listbox object handle
    sType = get(hObj,'Title');
    setappdata(hFig,'sType',sType)
else
    % otherwise, retrieve the currently selected title
    hTabG = getappdata(hFig,'hTabGrpEx');
    sType = get(get(hTabG,'SelectedTab'),'Title');
end

% updates the signal type into the GUI
hListEx = getProtoObj(hFig,'listStimTrainEx',sType(1));
setappdata(hFig,'hListEx',hListEx)

% sets the add signal button properties dependent on whether there are any
% stimuli trains for the given protocol type
hasStim = ~isempty(get(hListEx,'String'));
setObjEnableProps(hFig,'buttonClearAll',hasStim);
setObjEnableProps(hFig,'buttonAddSig',hasStim);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    PARAMETER OBJECT CALLBACKS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- updates on editing the stimuli name editbox
function editStimName(hObject, eventdata, handles, dType)

% sets the parameter string
sParaStr = sprintf('sPara%s',dType);

% retrieves the parameter data struct
hFig = handles.figExptSetup;

% updates the parameter struct with the new name string
sPara = getappdata(hFig,sParaStr);
sPara.sName = get(hObject,'string');
setappdata(hFig,sParaStr,sPara)

% --- updates on editing the stimuli duration editbox
function editTotalDur(hObject, eventdata, handles, dType)

% global variables
global axLimMax

% initialisations
switch dType
    case 'S'
        % case is the short-term protocol
        isRound = true;
        [sParaStr,hAx] = deal('sParaS',handles.axesProtoS);
        
    case 'L'
        % case is the long-term protocol
        isRound = false;
        [sParaStr,hAx] = deal('sParaL',handles.axesProtoL);
end

% retrieves the parameter data struct
hFig = handles.figExptSetup;
sPara = getappdata(hFig,sParaStr);

% determines if the new value is valid
nwVal = str2double(get(hObject,'string'));
if chkEditValue(nwVal,[getMinTrainDuration(hFig,isRound),axLimMax],false)
    % if so, then update the parameter value into the data struct
    sPara.tDur = nwVal;
    setappdata(hFig,sParaStr,sPara)
    
    % resets the axes properties
    resetAxesProps(hAx,sPara.tDur)
    setObjEnableProps(hFig,'buttonUseMinSig','on')
    
    % updates the time limits on the signal blocks
    iProto = getProtocolIndex(hFig);
    sigBlk = getappdata(hFig,'sigBlk');
    for i = 1:length(sigBlk{iProto})
        if ~isempty(sigBlk{iProto}{i})
            resetSignalBlockTimeLimits(hFig,sigBlk{iProto}{i}{1});
        end
    end
    
    % exits the function
    return
end

% if there was an error, then reset the parameter to the last valid value
set(hObject,'string',num2str(sPara.tDur))

% --- Executes on selection change in popupTotalDurU.
function popupTotalDurU(hObject, eventdata, handles)

% updates the current selection
nDP = 0.001;
[iSel,lStr] = deal(get(hObject,'Value'),get(hObject,'String'));

% retrieves the parameter struct
hFig = handles.figExptSetup;
sPara = getappdata(hFig,'sParaL');
hAx = handles.axesProtoL;

% calculates the time multiplier
tDur0 = sPara.tDurU;
tMlt = getTimeMultiplier(lStr{iSel},sPara.tDurU);

% updates the parameter struct
sPara.tDur = roundP(sPara.tDur*tMlt,nDP);
sPara.tDurU = lStr{iSel};
setappdata(hFig,'sParaL',sPara);

% deselects any selected experimental protocol groups
pType0 = getappdata(hFig,'pType');
setappdata(hFig,'pType','Experiment Stimuli Protocol')
figExptSetup_WindowButtonDownFcn(hFig, [], handles, 'alt')
setappdata(hFig,'pType',pType0)

% resets the axes properties
resetExptTimeAxes(handles,'L',tDur0)

% updates the values
set(handles.editTotalDurL,'string',num2str(sPara.tDur));

% --- updates on editing a single stimuli parameter editbox
function ok = editSingleStimPara(hObject, eventdata, handles, dType)

% global variables
global hSigSel

% initialisations
ok = true;
eStr = {'off','on'};
pStr = get(hObject,'UserData');

% retrieves the important field values from the gui
hFig = handles.figExptSetup;
sType = getappdata(hFig,'sType');
isSW = strcmp(sType,'Square');

% retrieves the selected signal type from the parameter tab
hTab = getCurrentSignalParaTab(handles);

% retrieves the signal sub-struct
sParaStr = sprintf('sPara%s',dType);
sPara = getappdata(hFig,sParaStr);
sParaS = eval(sprintf('sPara.%s',sType));

% sets the parameter value limits
isInt = 0;
switch pStr
    case 'nCount'
        % case is the signal cycle count
        [nwLim,isInt] = deal([1,inf],1);
        
    case 'tOfs'
        % case is the signal offset
        nwLim = [0,inf];        
        
    case {'tDurOn','tDurOff','tDur','tCycle'}
        % case is the signal duration
        nwLim = [0.01,inf];        
        
    case {'sAmp','sAmp0','sAmp1'}
        % case is the signal amplitude
        nwLim = [0,100];
end

% retrieves the new value and determines if it is valid
nwVal = str2double(get(hObject,'string'));
if chkEditValue(nwVal,nwLim,isInt)
    % if so, then update the parameter within the struct
    eval(sprintf('sParaS.%s = nwVal;',pStr));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%    SIGNAL DURATION/COUNT UPDATE    %%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % initialisation
    [updateDur,updateCount] = deal(false);
    
    % scales the time values dependent on the signal type
    if isSW
        % case is the squarewave signals
        [~,tDurOn,tDurOff] = scaleTimePara(sParaS,isSW);
    else
        % case is the non-squarewave signals
        [~,tCycle] = scaleTimePara(sParaS,isSW);
    end
    
    % ensures that there are an integer number of cycle counts (if the
    % parameter being altered is a temporal parameter)
    switch pStr
        case {'tDurOn','tDurOff'} % case is the square on/off duration
            
            % flag that both the duration/count need updating
            [updateDur,updateCount] = deal(true);
            
            % recalculates the signal duration
            sParaS.tDur = tDurOn*sParaS.nCount + ...
                          tDurOff*(sParaS.nCount-1);
            
            % recalculates the cycle count
            sParaS.nCount = (sParaS.tDur + tDurOff)/...
                            (tDurOff + tDurOn);
            if mod(sParaS.nCount,1) ~= 0
                % if the count is not an integer then recalculate
                sParaS.nCount = max(1,floor(sParaS.nCount));
                sParaS.tDur = tDurOn*sParaS.nCount + ...
                              tDurOff*(sParaS.nCount-1);
            end
            
        case 'tCycle' % case is the non-square cycle duration
            
            % flag that the duration needs updating
            updateDur = true;
            
            % recalculates the signal duration
            sParaS.tDur = sParaS.nCount*tCycle;
            
        case 'tDur' % case is the signal duration
            
            % flag that the count needs updating
            updateCount = true;
            
            % recalculates the repetition count
            if isSW
                % case is for the square waveforms
                sParaS.nCount = (sParaS.tDur + tDurOff)/...
                                (tDurOff + tDurOn);
                if mod(sParaS.nCount,1) ~= 0
                    % if the count is not an integer then recalculate
                    sParaS.nCount = max(1,floor(sParaS.nCount));
                    sParaS.tDur = tDurOn*sParaS.nCount + ...
                                  tDurOff*(sParaS.nCount-1);
                    
                    % flag that the duration needs updating
                    updateDur = true;
                end
                
            else
                % case is the other waveforms
                sParaS.nCount = sParaS.tDur/tCycle;
                if mod(sParaS.nCount,1) ~= 0
                    % if the count is not an integer then recalculate
                    sParaS.nCount = max(1,floor(sParaS.nCount));
                    sParaS.tDur = tCycle*sParaS.nCount;
                    
                    % flag that the duration needs updating
                    updateDur = true;
                end
            end
            
        case 'nCount' % case is the total cycle count
            
            % flag that the duration needs updating
            updateDur = true;
            
            % recalculates the entire signal duration
            if isSW
                % case is a squarewave
                sParaS.tDur = tDurOn*sParaS.nCount + ...
                              tDurOff*(sParaS.nCount-1);
                
            else
                % case is the other waveforms
                sParaS.tDur = tCycle*sParaS.nCount;
            end
            
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%    PARAMETER STRUCT UPDATE    %%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % checks the signal duration is valid
    [eState,tDurMin] = checkSignalDur(hFig,sParaS,sPara);
    if eState > 0
        % if so, then update the parameter struct
        eval(sprintf('sPara.%s = sParaS;',sType));
        setappdata(hFig,sParaStr,sPara)        
        
        % enables the use minimum signal duration button
        switch eState
            case 2
                % runs the minimum duration selection button
                hButton = getProtoObj(hFig,'buttonUseMinSig',dType);
                buttonUseMinSig(hButton, '1', handles, tDurMin)
        end
        
        % updates the other object properties
        setObjEnableProps(hFig,'buttonUseMinSig',eState==1)        
        
        % updates the signal duration (if required)
        if updateDur
            set(findobj(hTab,'UserData','tDur'),...
                'string',getEditResetString(sParaS.tDur))
        end
        
        % updates the signal duration (if required)
        if updateCount
            set(findobj(hTab,'UserData','nCount'),...
                'string',num2str(sParaS.nCount))
        end
        
        % updates the off-cycle duration objects (square-wave only)
        if isSW
            set(findobj(hTab,'UserData','tDurOffL'),...
                'enable',eStr{1+(sParaS.nCount>1)})
            set(findobj(hTab,'UserData','tDurOff'),...
                'enable',eStr{1+(sParaS.nCount>1)})
            set(findobj(hTab,'UserData','tDurOffU'),...
                'enable',eStr{1+(sParaS.nCount>1)})
        end
        
        % enables the reset parameter button
        setObjEnableProps(hFig,'buttonResetPara','on')
        
        % if there is a stimuli object selected, then update it
        if ~isempty(hSigSel)
            updateStimObjPara(hFig,sParaS);
        end
        
        % exits the function
        return
    end
end

% if there was an error, then reset to the original parameter value
[ok,pStr] = deal(false,sprintf('sPara.%s.%s',sType,pStr));
set(hObject,'string',num2str(eval(pStr)))

% --- updates on changing the stimuli duration units popupmenu
function popupStimTimeUnits(hObject, eventdata, handles, dType)

% global variables
global hSigSel

% initialisations
hFig = handles.figExptSetup;
pStr = get(hObject,'UserData');
sType = getappdata(handles.figExptSetup,'sType');

% retrieves the popupmenu
[lStr,iSel] = deal(get(hObject,'string'),get(hObject,'value'));

% retrieves the selected signal type from the parameter tab
dType = getProtoTypeStr(getappdata(handles.figExptSetup,'pType'));
hTabG = getappdata(handles.figExptSetup,sprintf('hTabGrp%s',dType));
hTab = get(hTabG,'SelectedTab');

% retrieves the signal sub-struct
sParaStr = sprintf('sPara%s',dType);
[sPara,sPara0] = deal(getappdata(hFig,sParaStr));

% converts the temporal duration to the new time units
pStrD = sprintf('sPara.%s.%s',sType,pStr(1:end-1));
tMlt = getTimeMultiplier(eval(sprintf('%sU',pStrD)),lStr{iSel});
eval(sprintf('%s = %s/tMlt;',pStrD,pStrD));

% updates the parameter struct with the new duration units
eval(sprintf('sPara.%s.%s = lStr{iSel};',sType,pStr))
setappdata(hFig,sParaStr,sPara)

% 
hPara = findobj(hTab,'UserData',pStr(1:end-1));
set(hPara,'string',getEditResetString(eval(pStrD)))

% updates the parameter field
if editSingleStimPara(hPara, [], handles, dType)
    % if there is a stimuli train object selected, then update the
    % parameters for this object
    if ~isempty(hSigSel)
        uData = get(hSigSel,'UserData');
        uData{indFcn('sPara')} = eval(sprintf('sPara.%s',sType));
        set(hSigSel,'UserData',uData)
    end    
    
else
    % if the new values were not feasible, then reset the popupmenu
    tUnits0 = eval(sprintf('sPara0.%s.%s;',sType,pStr));
    tDur0 = eval(sprintf('sPara0.%s.%s;',sType,pStr(1:end-1)));
    jSel = find(strcmp(lStr,tUnits0));
    set(hObject,'value',jSel)
    
    % updates the parameter struct into the GUI
    set(hPara,'string',getEditResetString(tDur0));
    eval(sprintf('sPara.%s.%s = lStr{jSel};',sType,pStr))
    setappdata(hFig,sParaStr,sPara)
end

% --- Executes on button press in buttonResetParaS/L.
function buttonResetPara(hObject, eventdata, handles)

% global variables
global hSigSel

% prompts the user if they want to reset the parameters
uChoice = questdlg(['Are you sure you want to reset parameters to ',...
    'their default values?'],'Reset Parameters?',...
    'Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    % if the user cancelled, then exit the function
    return
end

% initialisations
hFig = handles.figExptSetup;
sType = getappdata(hFig,'sType');
dType = getProtoTypeStr(getappdata(hFig,'pType'));

% retrieves the default parameter for the given duration/signal type
sParaD = setupSingleStimPara(dType);
sParaDS = eval(sprintf('sParaD.%s',sType));

% retrieves the currently selected signal parameter tab object
hTab = getCurrentSignalParaTab(handles);
resetSignalPara(hTab,sParaDS)

% updates the parameter struct with the default values
updateParaSignalField(hFig,dType,sType,sParaDS)

%
if ~isempty(hSigSel)
    uData = get(hSigSel,'UserData');
    uData{indFcn('sPara')} = sParaDS;
    set(hSigSel,'UserData',uData)
    
    updateStimObjPara(hFig,sParaDS);    
end

% disables the button
setObjEnable(hObject,'off')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    SIGNAL CONTROL BUTTON CALLBACK FUNCTIONS    %%%%
%%%%%F%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press for buttonUseMinSigS/L/Ex
function buttonUseMinSig(hObject, eventdata, handles, tMin)

% global parameters
global nProto

% retrieves the current signal type
hFig = handles.figExptSetup;
pType = getappdata(hFig,'pType');
sigBlk = getappdata(hFig,'sigBlk');
iExpt = getappdata(hFig,'iExpt');
iProto = getProtocolIndex(hFig);
dType = getProtoTypeStr(pType);

% retrieves the minimum experiment duration (if not provided)
if ~exist('tMin','var')
    tMin = getMinExptDuration(hFig,false);
end

% retrieves the signal block object
if tMin == 0
    % if there are no signal blocks the output a message to screen
    mStr = ['There are no stimuli blocks set so there ',...
            'is no minimum duration.'];
    waitfor(msgbox(mStr,'No Stimuli Blocks Placed'))
    
    % exits the function
    return
end

% retrieves the protocol data struct
sParaF = getProtocolParaInfo(hFig,pType);
if iProto(nProto)
    % case is updating for an experiment       
    
    % sets/calculates the new experiment duration time vector
    if length(tMin) == 4
        TexpNw = tMin;
        [~,iExpt.Timing.TexpU] = vec2time(TexpNw);
    else
        TexpNw = time2vec(tMin,iExpt.Timing.TexpU);
    end
    
    % updates the parameter struct with the new duration         
    iExpt.Timing.Texp = addTime(TexpNw,[0,0,0,1]);
    setappdata(hFig,'iExpt',iExpt);
    
    % updates the plot axes with the new duration
    hPopup = findobj(handles.panelExptDurEx,...
                     'style','popupmenu','UserData',1);
    popupExptDuration(hPopup, '1', handles)     
    
    % sets the popup duration values
    iExpt = getappdata(hFig,'iExpt');
    setDurPopupValues(handles.panelExptDurEx,iExpt.Timing.Texp)
    setDurPopupValues(handles.panelExptDurInfo,iExpt.Timing.Texp)
    
    % retrieves the signal block objects
    resetSignalBlockTimeLimits(hFig)
    
else
    % case is updating for a short/long-term protocol 
    
    % updates the parameter struct with the new duration        
    sParaF.tDur = tMin;
    
    % updates the parameter struct into the gui
    sPara = getappdata(hFig,sprintf('sPara%s',dType));
    eval('sPara = sParaF;')
    setappdata(hFig,sprintf('sPara%s',dType),sPara);
    
    % updates the time limits on the signal blocks
    iProto = getProtocolIndex(hFig);
    sigBlk = getappdata(hFig,'sigBlk');
    for i = 1:length(sigBlk{iProto})
        if ~isempty(sigBlk{iProto}{i})
            resetSignalBlockTimeLimits(hFig,sigBlk{iProto}{i}{1});
        end
    end    
   
    % updates the total duration string
    hEdit = getProtoObj(hFig,'editTotalDur');
    set(hEdit,'string',num2str(tMin));
    editTotalDur(hEdit, '1', handles, dType)    
end

% disables the button
pause(0.05);
setObjEnable(hObject,'off')

% --- Executes on button press in buttonAddSigS/L.
function buttonAddSig(hObject, eventdata, handles, dType)

% global variables
global mpStrDef mType nProto

% retrieves the current signal type
hFig = handles.figExptSetup;
iProto = getProtocolIndex(hFig);
sType = getappdata(hFig,'sType');

%
if iProto(nProto)
    % if an experiment block is being added, then determine if it is
    % actually feasible to place a block
    tLimF = checkExptBlockPlacement(hFig);
    if ~isempty(tLimF)        
        % creates the experiment object            
        [uData,rPos] = setupExptObjectInfo(hFig,tLimF);
        createExptObject(hFig,uData,rPos,1);              
        
        % updates the stimuli device inclusion flag
        hasAllStim = detStimTrainFeas(hFig);
        updateFeasFlag(handles,'checkStimFeas',hasAllStim)        
    end        
else
    % flag that a signal is being added
    mType = 1;

    % updates the mouse pointer to the signal type
    mpStrDef = setupCustomMousePointer(sType);
    if isempty(mpStrDef)
        mpStrDef = 'fleur';
        set(hFig,'Pointer',mpStrDef)
    else
        set(hFig,'PointerShapeCData',mpStrDef,'Pointer','custom')
    end
end

% --- Executes on button press in buttonAddSigS/L.
function buttonDeselectSig(hObject, eventdata, handles)

% removes the signal block hightlight
hFig = handles.figExptSetup;
figExptSetup_WindowButtonDownFcn(hFig, [], handles, 'alt')

% disables the button
setObjEnable(hObject,'off')

% --- Executes on button press in buttonCopySigS/L.
function buttonCopySig(hObject, eventdata, handles)

% global variables
global yGap

% retrieves the channel names
hFig = handles.figExptSetup;
iCh = getappdata(hFig,'iCh');
chInfo = getappdata(hFig,'chInfo');
sPara = getProtocolParaInfo(hFig,getappdata(hFig,'pType'));

% 
sigBlk = getappdata(hFig,'sigBlk');
iProto = getProtocolIndex(hFig);
sBlk = sigBlk{iProto}{iCh};

% sets the indices of the other channels that are not selected
chName = chInfo(end:-1:1,2);
iChC = (1:length(chName));
iChC = iChC(iChC ~= iCh);

% determines the indices of the channels to copy
[isWC,sParaC,iChCopy] = CopySignal(iChC,chName(iChC),sBlk,sPara.tDur);
if isempty(iChCopy)
    % if the user cancelled, then exit the function
    return
    
elseif isWC
    % case is copying within a channel
    
    % determines the time limits of the entire signal
    tLimBlk = calcSignalBlockLimits(sBlk);
    dtLim = diff(tLimBlk);
    tOfs = sParaC.tOfs;
    
    % copies the signal block information
    for i = 1:length(sBlk)
        % retrieves the signal block userdata
        uData = get(sBlk{i},'UserData');  
        sPara = uData{indFcn('sPara')};
        rPos0 = sBlk{i}.getPosition();
        
        for j = 1:sParaC.nCount
            % updates the signal parameter struct in the user data field
            sPara.tOfs = rPos0(1) + j*(dtLim + tOfs);
            uData{indFcn('sPara')} = sPara;
            
            % creates the new signal obkect
            isReset = (j==sParaC.nCount) && (i==length(sBlk));
            createSignalObject(hFig,uData(1:5),rPos0,isReset);
        end
    end
        
else
    % case is copying between channels
    
    % copies the signal block information
    for j = 1:length(iChCopy)
        % deletes the signal blocks within the channel
        deleteChannelSignalBlocks(hFig,iProto,iChCopy(j));
        
        % creates the signal blocks for all signals within the channel
        for i = 1:length(sBlk)
            % retrieves the signal block userdata
            uData0 = get(sBlk{i},'UserData');        

            % creates the new signal object
            [uData,rPos] = deal(uData0(1:5),sBlk{i}.getPosition());
            uData{indFcn('iCh')} = iChCopy(j);
            rPos(2) = (iChCopy(j)-1)+yGap;
            
            % creates the stimuli signal blocks
            isReset = (j==length(iChCopy)) && (i==length(sBlk));
            createSignalObject(hFig,uData,rPos,isReset);  
        end    
    end
end

% --- Executes on button press in buttonDelSigS/L.
function buttonDelSig(hObject, eventdata, handles)

% global variables
global hSigSel

% prompts the user if they wish to continue
uChoice = questdlg(['Are you sure you want to delete the ',...
    'currently selected stimuli object?'],...
    'Clear Current Stimuli Object?','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    % if the user cancelled, then exit the function
    return
end

% initialisations
eStr = {'off','on'};
hFig = handles.figExptSetup;
sigBlk = getappdata(hFig,'sigBlk');
iProto = getProtocolIndex(hFig);

% retrieves the userdata from the block to be deleted
uData = get(hSigSel,'UserData');
iCh = uData{indFcn('iCh')};
rmvBlk = cellfun(@(x)(isequal(hSigSel,x)),sigBlk{iProto}{iCh});

% ensures the signal block has been deselected
figExptSetup_WindowButtonDownFcn(hFig, [], handles, 'alt')

% updates the signal block within the storage array
deleteSignalBlock(sigBlk{iProto}{iCh}{rmvBlk});
sigBlk{iProto}{iCh} = sigBlk{iProto}{iCh}(~rmvBlk);
setappdata(hFig,'sigBlk',sigBlk)

% resets the stimuli blocks for the current channel
if any(~rmvBlk)
    resetSignalBlockTimeLimits(hFig,sigBlk{iProto}{iCh}{1})
end

% updates the enabled properties of the delete all/save buttons
anyStim = ~isempty(cell2cell(sigBlk{iProto}));
setObjEnableProps(hFig,'buttonClearAll',anyStim);
setObjEnableProps(hFig,'buttonSaveTrain',anyStim);
setObjEnableProps(hFig,'buttonUseMinSig',anyStim);

% enables the stimuli train test (short-term protocol only)
if strcmp(getProtoTypeStr(getappdata(hFig,'pType')),'S')
    setObjEnable(handles.buttonTestTrain,anyStim)
end

% deletes the current signal block
figExptSetup_WindowButtonMotionFcn(hFig, [], handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    OBJECT DELETEION CALLBACK FUNCTIONS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in buttonClearChanS/L.
function buttonClearChan(hObject, eventdata, handles)

% global variables
global hSigSel nProto iSigObj

% prompts the user if they wish to continue
uChoice = questdlg(['Are you sure you want to delete the ',...
    'currently selected stimuli channel?'],...
    'Clear Current Stimuli Channel?','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    % if the user cancelled, then exit the function
    return
end

% initialisations
hSigSel0 = hSigSel;
hFig = handles.figExptSetup;
uData = get(hSigSel,'UserData');
iCh = uData{indFcn('iCh')};
iProto = getProtocolIndex(hFig);
pStr = getProtoTypeStr(getappdata(hFig,'pType'));

% de-selects the currently selected object
figExptSetup_WindowButtonDownFcn(hFig, [], handles, 'alt');

% deletes the signal blocks for the current channel 
if iProto(nProto)
    % determines the group to be removed
    sBlk = getSignalBlock(hFig);
    isMatch = cellfun(@(x)(isequal(hSigSel0,x)),sBlk);
    anyStim = any(~isMatch);
    
    % retrieves the signal block/protocol index
    sigBlk = getappdata(hFig,'sigBlk');
    sigBlk{iProto} = sBlk(~isMatch);    
    setappdata(hFig,'sigBlk',sigBlk)
    
    % removes the experiment protocol train information     
    sTrain = getappdata(hFig,'sTrain');
    sTrain.Ex.sName = sTrain.Ex.sName(~isMatch);
    sTrain.Ex.sType = sTrain.Ex.sType(~isMatch);
    sTrain.Ex.sParaEx = sTrain.Ex.sParaEx(~isMatch);
    sTrain.Ex.sTrain = sTrain.Ex.sTrain(~isMatch);    
    setappdata(hFig,'sTrain',sTrain)
    
    % deletes the blocks from the selected stimuli
    deleteSignalBlock(sBlk{isMatch})   
    iSigObj = 0;
    
    % resets the listbox strings
    hList = getProtoObj(hFig,'listStimTrain');
    if anyStim
        lStr = get(hList,'String');
        set(hList,'String',lStr(~isMatch),'Value',[],'Max',2)
    else
        set(hList,'String',[],'Value',[],'Max',2,'enable','off')        
    end
        
    % updates the stimuli device inclusion flag
    hasAllStim = detStimTrainFeas(hFig);
    updateFeasFlag(handles,'checkStimFeas',hasAllStim)        
    
else
    % case is a short/long-protocol signal deletion
    sigBlk = deleteChannelSignalBlocks(hFig,iProto,iCh);
    anyStim = ~isempty(cell2cell(sigBlk{iProto}));
end

% updates the enabled properties of the delete all/save buttons
setObjEnable(hObject,'off')
setObjEnableProps(hFig,'buttonClearAll',anyStim);
setObjEnableProps(hFig,'buttonUseMinSig',anyStim);

% enables the save stimuli train button (short/long-term protocol only)
if ~strcmp(pStr,'Ex')
    setObjEnableProps(hFig,'buttonSaveTrain',anyStim);
end

% enables the stimuli train test (short-term protocol only)
if strcmp(pStr,'S')
    setObjEnable(handles.buttonTestTrain,anyStim)
end

% --- Executes on button press in buttonClearAllS/L.
function buttonClearAll(hObject, eventdata, handles)

% global parameters
global nProto iSigObj

% only prompt user if calling from a button press
if ~ischar(eventdata)
    % prompts the user if they wish to continue
    uChoice = questdlg(['Are you sure you want to completely clear ',...
        'the current stimuli train configuration?'],...
        'Clear All Stimuli?','Yes','No','Yes');
    if ~strcmp(uChoice,'Yes')
        % if the user cancelled, then exit the function
        return
    end
end

% de-selects any existing stimuli objects
hFig = handles.figExptSetup;
figExptSetup_WindowButtonDownFcn(hFig, [], handles, 'alt');

% initialisations
sigBlk = getappdata(hFig,'sigBlk');
iProto = getProtocolIndex(hFig);

% deletes all of the existing signal block objects
if iProto(nProto)    
    % removes the signal selection index
    iSigObj = 0;
    
    % case is removing all 
    if ~isempty(sigBlk{iProto})
        cellfun(@(x)(deleteSignalBlock(x)),sigBlk{iProto})
        sigBlk{iProto} = [];  
    end
    
    % resets the listbox strings
    hList = getProtoObj(hFig,'listStimTrain');
    set(setObjEnable(hList,'off'),'String',[],'Value',[],'Max',2)
    
    % removes the experiment protocol train information 
    sTrain = getappdata(hFig,'sTrain');
    sTrain.Ex = [];
    setappdata(hFig,'sTrain',sTrain)    
   
    % updates the stimuli device inclusion flag
    updateFeasFlag(handles,'checkStimFeas',false)    
    
else
    for iCh = 1:length(sigBlk{iProto})
        if ~isempty(sigBlk{iProto}{iCh})
            cellfun(@(x)(deleteSignalBlock(x)),sigBlk{iProto}{iCh})
            sigBlk{iProto}{iCh} = [];
        end
    end
end

% updates the signal block array into the gui
setappdata(hFig,'sigBlk',sigBlk)

% disables all the relevant buttons
setObjEnable(hObject,'off')
setObjEnableProps(hFig,'buttonDelSig','off')

% updates the stimuli train panel properties
hPanel = getProtoObj(hFig,'panelStimTrain');
hList = findobj(hPanel,'style','listbox');
setPanelProps(hPanel,'off',{hList});

% removes all entries from the parameter train listbox
if ~ischar(eventdata)
    set(setObjEnable(hList,'on'),'Max',2,'Value',[])
end

% enables the stimuli train test (short-term protocol only)
setObjEnable(getProtoObj(hFig,'buttonUseMinSig'),'off')
if strcmp(getProtoTypeStr(getappdata(hFig,'pType')),'S')
    setObjEnable(handles.buttonTestTrain,'off')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    SIGNAL TRAIN CALLBACK FUNCTIONS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in buttonSaveTrainS/L.
function buttonSaveTrain(hObject, eventdata, handles)

% initialisations
hFig = handles.figExptSetup;
sTrain = getappdata(hFig,'sTrain');
hTabEx = getappdata(hFig,'hTabEx');
hTabGrpEx = getappdata(hFig,'hTabGrpEx');
dType = getProtoTypeStr(getappdata(hFig,'pType'));
hList = getProtoObj(hFig,'listStimTrain');
hListEx = findobj(hFig,'tag',sprintf('listStimTrainEx%s',dType));

% retrieves the current stimuli train information
sTrainC = getStimTrainInfo(handles);

% determines if the stimuli train name is unique
sTrainP = eval(sprintf('sTrain.%s',dType));
if isempty(sTrainP)
    % if there are no stored trains, then train is unique
    sName = {sTrainC.sName};
else
    % otherwise, compare the existing train names against the new train
    sName = cellfun(@(x)(x.sName),sTrainP,'un',0);
    if any(strcmp(sName,sTrainC.sName))
        % if there are duplicate train names then output an error to screen
        eStr = ['Stimuli train name already exists! Re-enter a unique ',...
            'name before attempting to add the stimuli train ',...
            'to the stored list.'];
        waitfor(msgbox(eStr,'Duplicate Train Names','modal'))
        
        % exits the function
        return
    else
        % otherwise, append the new name to the list
        sName = [sName(:);sTrainC.sName];
    end
end

% updates the data struct with the new stimuli train
sTrainP{end+1} = sTrainC;
eval(sprintf('sTrain.%s = sTrainP;',dType))
setappdata(hFig,'sTrain',sTrain)

% enables the objects for the corresponding expt protocol parameter tab
iTabEx = cellfun(@(x)(startsWith(get(x,'Title'),dType)),hTabEx);
setExptProtoTabProps(hTabEx{iTabEx},'on')

% updates the list string/values
set(hList,'String',sName,'Max',1,'Value',length(sName),'enable','on')
set(hListEx,'String',sName,'Max',1,'Value',length(sName),'enable','on')

% resets the stimuli offset time popup menus
resetStimOffsetTime(handles,sTrainC,dType)

% determines if the selected experiment protocol tab has any stimuli trains
sTypeEx = get(get(hTabGrpEx,'SelectedTab'),'Title');
if isempty(eval(sprintf('sTrain.%s',sTypeEx(1))))
    % if not, then change the selected tab to the protocol that does have
    % stored stimuli trains
    set(hTabGrpEx,'SelectedTab',hTabEx{iTabEx})
end

% enables the delete/update train buttons
setObjEnableProps(hFig,'buttonDeleteTrain','on')
setObjEnableProps(hFig,'buttonUpdateTrain','on')
setObjEnable(handles.buttonAddSigEx,'on')

% updates the stimuli protocol feasibility flag
updateFeasFlag(handles,'checkProtoFeas',true)  

% updates the experiment tab properties
setExptTabProps(hFig)

% --- resets the stimuli offset time popup menus
function resetStimOffsetTime(handles,sTrainC,dType)

% initialisations
hFig = handles.figExptSetup;
hPanelP = getProtoObj(hFig,'panelStimInt',dType);
tDurMax = calcMaxStimTrainDur(sTrainC);

% if the duration of the stimuli offset time is less than the current
% stimuli block, then update the offset
if tDurMax > vec2sec(getPopupDurValues(hPanelP))
    % updates the duration popup values
    tStimNw = sec2vec(tDurMax);
    setDurPopupValues(hPanelP,tStimNw)
    
    % updates the experimental stimuli offset time vector
    sParaEx = getappdata(hFig,'sParaEx');
    eval(sprintf('sParaEx.%s.tStim = tStimNw;',dType));
    setappdata(hFig,'sParaEx',sParaEx)
end

% --- calculates the maximum duration of the signal blocks within a train
function tDurMax = calcMaxStimTrainDur(sTrainC)

% initialisations
tDurMax = 0;
sPara = field2cell(sTrainC.blkInfo,'sPara');

% calculates the overall maximum time of all the signal blocks
for i = 1:length(sPara)
    tOfs = sPara{i}.tOfs*getTimeMultiplier('s',sPara{i}.tOfsU);
    tDur = sPara{i}.tDur*getTimeMultiplier('s',sPara{i}.tDurU);
    tDurMax = max(tDurMax,tOfs+tDur);
end

% --- Executes on button press in buttonSaveTrainS/L.
function buttonDeleteTrain(hObject, eventdata, handles)

% initialisations
hFig = handles.figExptSetup;
sTrain = getappdata(hFig,'sTrain');
hList = getProtoObj(hFig,'listStimTrain');
hListEx = getProtoObj(hFig,'listStimTrainEx');
dType = getProtoTypeStr(getappdata(hFig,'pType'));
[lStr,iSel] = deal(get(hList,'String'),get(hList,'Value'));

% retrieves the stimuli train parameter struct
sTrainP = eval(sprintf('sTrain.%s',dType));
ii = (1:length(sTrainP)) ~= get(hList,'Value');

% deletes any associated experiment stimuli train objects
deleteStimTrainObjects(hFig,sTrainP{~ii});

% updates the stimuli train parameter struct
eval(sprintf('sTrain.%s = sTrainP(ii);',dType))
setappdata(hFig,'sTrain',sTrain)

% updates the stimuli protocol feasibility flag
hasStim = ~isempty(sTrain.S) || ~isempty(sTrain.L);
updateFeasFlag(handles,'checkProtoFeas',hasStim) 

% updates the experiment tab properties
setExptTabProps(hFig)

% updates the delete train buttons
if any(ii)
    % updates the listbox properties
    iSel = min(iSel,sum(ii));
    set(hList,'String',lStr(ii),'Max',1,'Value',iSel);
    set(hListEx,'String',lStr(ii),'Max',2,'Value',[]);
    
    % updates the stimuli train objects
    listStimTrain(hList, [], handles)
    
else
    % updates the listbox
    set(hList,'String','','Max',2,'Value',[]);
    set(hListEx,'String','','Max',2,'Value',[]);
    set(getProtoObj(hFig,'','Ex'),'Max',2,'Value',[]);
    
    % deletes all the current axes stimuli blocks
    hClearAll = getProtoObj(hFig,'buttonClearAll');
    buttonClearAll(hClearAll,'1', handles)    
    
    % disables the update/delete buttons and stimuli train listbox
    setObjEnable(hObject,'off')
    setObjEnableProps(hFig,'buttonUpdateTrain','off')
    setObjEnableProps(hFig,'listStimTrain','off')
    
    %
    hTab = get(hListEx,'Parent');
    setPanelProps(hTab,'off')
    setPanelProps(findobj(hTab,'type','uipanel'),'off')
    
    % disables the add signal button (if the current protocol is selected)
    hTabG = getappdata(hFig,'hTabGrpEx');
    if isequal(hTabG.SelectedTab,get(hListEx,'Parent'))
        setObjEnable(getProtoObj(hFig,'buttonAddSig','Ex'),'off')
    end
    
    % enables the stimuli train test (short-term protocol only)
    if strcmp(getProtoTypeStr(getappdata(hFig,'pType')),'S')
        setObjEnable(handles.buttonTestTrain,'off')
    end
end

% --- Executes on button press in buttonUpdateTrainS/L.
function buttonUpdateTrain(hObject, eventdata, handles)

% global parameters
global hSigSel

% initialisations
hFig = handles.figExptSetup;
sTrain = getappdata(hFig,'sTrain');
dType = getProtoTypeStr(getappdata(hFig,'pType'));

% retrieves the currently selected list item
hList = getProtoObj(hFig,'listStimTrain');
[iSel,lStr] = deal(get(hList,'Value'),get(hList,'String'));

% retrieves the current and new stimuli train protocols
sTrainP = eval(sprintf('sTrain.%s',dType));
sTrainP0 = sTrainP{iSel};
sTrainPnw = getStimTrainInfo(handles);

% updates the data struct with stimuli train parameter struct
sTrainP{iSel} = sTrainPnw;
eval(sprintf('sTrain.%s = sTrainP;',dType))

% determines if the new stimuli train is feasible
if checkStimTrainUpdateFeas(hFig,sTrain)
    % if so, then update the stimuli train data struct
    setappdata(hFig,'sTrain',sTrain)
    
    % resets the stimuli train objects
    resetStimTrainObjects(hFig,sTrainP0,sTrainPnw,dType);
else
    % otherwise, revert back to the last 
    iBlk = find(strcmp(sTrain.Ex.sName,lStr{iSel}),1,'first');
    blkInfo = sTrain.Ex.sTrain(iBlk).blkInfo(1);  
    
    % resets the signal parameters
    hTabG = getappdata(hFig,sprintf('hTabGrp%s',dType));
    hTab = findobj(hTabG,'Title',blkInfo.sType);    
    resetSignalPara(hTab,blkInfo.sPara)
    
    % resets the stimuli train parameter struct sub-field
    sTrainP{iSel} = sTrainP0;
    eval(sprintf('sTrain.%s = sTrainP;',dType))
    setappdata(hFig,'sTrain',sTrain)
    
    % if there is a stimuli object selected, then reset it
    if ~isempty(hSigSel)
        updateStimObjPara(hFig,blkInfo.sPara);
    end
end

% --- checks that the stimuli train update is feasible
function ok = checkStimTrainUpdateFeas(hFig,sTrain)

% initialisations
iExpt = getappdata(hFig,'iExpt');
sParaEx = getappdata(hFig,'sParaEx');

% if there are no experiment stimuli trains, then exit the function
if isempty(sTrain.Ex)
    ok = true;
    return
end

% retrieves the offset times for each stimuli block
tOfs = field2cell(sTrain.Ex.sParaEx,'tOfs',1);

% calculates the maximum stimuli block extent
tMax = 0;
for i = 1:length(sTrain.Ex.sName)
    % calculates the duration/units of the current stimuli block
    sTrainP = eval(sprintf('sTrain.%s',sTrain.Ex.sType{i}(1)));
    ii = cellfun(@(x)(strcmp(x.sName,sTrain.Ex.sName{i})),sTrainP);
    [tDur,tUnits] = calcExptStimDuration(hFig,sTrainP{ii},sParaEx);
    
    % calculates the overall maximum duration
    tMlt = getTimeMultiplier(iExpt.Timing.TexpU,tUnits);
    tMax = max(tDur*tMlt+tOfs(i),tMax);
end

% calculates the experiment duration (using the experiment units)
tMltEx = getTimeMultiplier(iExpt.Timing.TexpU,'s');
tDurEx = vec2sec(iExpt.Timing.Texp)*tMltEx;

% determines if the new stimuli train is feasible
ok = tDurEx > tMax;
if ~ok
    % if the parameters are infeasible, then output an error to screen
    eStr = sprintf(['The new stimuli train parameters are not ',...
                    'feasible. The stimuli train parameters are going ',...
                    'to be reverted back to the last valid values.']);
    waitfor(msgbox(eStr,'Infeasible Stimuli Train Parameters','modal'))
end

% --- Executes on button press in buttonRepeatTrainS/L.
function buttonRepeatTrain(hObject, eventdata, handles)

% FINISH ME!
a = 1;

% --- Executes on selecting listStimTrainS/L.
function listStimTrain(hObject, eventdata, handles)

% retrieves the
hFig = handles.figExptSetup;

sTrain = getappdata(hFig,'sTrain');
dType = getProtoTypeStr(getappdata(hFig,'pType'));
iSel = get(hObject,'Value');

% ensures only single selection is available
set(hObject,'max',1);

% updates the parameters based on the protocol type
if strcmp(dType,'Ex')
    % toggles the experiment object selection properties
    sBlk0 = getSignalBlock(hFig);
    if isvalid(sBlk0{iSel})
        toggleExptObjSelection(hFig,sBlk0{iSel},false);
    end
    
else
    % updates the stimuli train for the current train
    sTrainP = eval(sprintf('sTrain.%s',dType));
    setupStimTrainObj(handles,sTrainP{get(hObject,'Value')},dType)
end

% --- Executes on button press in buttonTestTrain.
function buttonTestTrain_Callback(hObject, eventdata, handles)

% global variables
global timerTest 

if ~get(hObject,'value')
    % if the test is already running, then pause and stop (prevents the 
    % user from the test straight away)
    pause(0.1)
    set(hObject,'string','Test Stimuli Train');    
    return
else
    % otherwise, change the button text
    set(hObject,'string','Stop Stimuli Test');    
end

% initialisations
hFig = handles.figExptSetup;

% retrieves the parameter data struct
chInfo = getappdata(hFig,'chInfo');
infoObj = getappdata(hFig,'infoObj');
extnObj = getappdata(hFig,'extnObj');

% retrieves the current stimuli train information
sTrainC = getStimTrainInfo(handles);

% ------------------------- %
% --- TEST DEVICE SETUP --- %
% ------------------------- %

% sets up the signals for the devices 
iStim = infoObj.iStim;
objDAQ = infoObj.objDAQ; 
sRate = field2cell(iStim.oPara,'sRate',1);
xySig = setupDACSignal(sTrainC,chInfo,1./sRate);

% determines the unique device indices
iDev = find(cellfun(@(x)(~all(cellfun('isempty',x(:,1)))),xySig));

% sets the sample rate for the device(s)
if max(iDev) > length(iStim.oPara)
    sRate = iStim.oPara(1).sRate*ones(length(iDev),1);
else
    sRate = field2cell(iStim.oPara(iDev),'sRate',1);
end

% determines if the serial 
if any(strcmp(objDAQ.dType{iDev(1)},'Serial'))
    % if so, set up the serial controller devices
    objDev = {setupSerialDevice(objDAQ,'Test',xySig(iDev),sRate,iDev)}; 
    
else
    % creates a loadbar
    h = ProgressLoadbar('Setting Up External Devices...');
    
    % creates the external device timer objects    
    if isempty(extnObj)
        % if there was an error, then set an empty array
        objDev = {[]};
    else
        % setsup the external devices for the stimuli test
        extnObj.setupExtnDeviceTest(objDAQ,xySig,iDev)
        objDev = {extnObj.objD};        
    end

    % closes the loadbar
    delete(h); 
    if isempty(objDev{1})
        % if there was in error in setup, then output an error to screen
        eStr = 'There was an error in detecting the external devices.';
        waitfor(msgbox(eStr,'Device Setup Error','modal'))
        
        % resets the toggle button properties
        set(hObject,'string','Test Stimuli Train','Value',0);   
        return
    end
end

% ------------------------ %
% --- DAC SIGNAL SETUP --- %
% ------------------------ %

% creates the test marker timer object
timerTest = createStimTestMarker(hFig,hObject,sTrainC);

% runs the devices (if any are available)
if ~isempty(objDev); runOutputDevices(objDev,1:length(objDev)); end
timerTest = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    SIGNAL OBJECT MOVEMENT CALLBACKS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- case is moving the signal patch object
function moveTempSignalObj(rPos,hFig)

% global variables
global hSigTmp
uData = get(hSigTmp,'UserData');
[tLim,iCh] = deal(uData{indFcn('tLim')},uData{indFcn('iCh')}(1));

% updates the time offset box
set(hSigTmp,'UserData',updateTimeOffset(hFig,uData,rPos(1)))

% makes the distance line markers visible (for the current channel)
hDL = getappdata(hFig,'hDL');
hDLnw = hDL{getProtocolIndex(hFig)}(iCh,[1,3]);
cellfun(@(x)(setObjVisibility(x,'on')),hDLnw);

% retrieves the current position of the line-marker
pDL = hDLnw{1}.getPosition();

% sets the position
hDLnw{1}.setPosition([tLim(1),rPos(1)],pDL(:,2));
hDLnw{2}.setPosition([rPos(1)+rPos(3),tLim(2)],pDL(:,2));

% --- case is moving the signal patch object
function moveSignalObj(rPos,hFig)

% global variables
global hSigSel

% if there is no selected signal object, then exit
if isempty(hSigSel); return; end

% retrieves the user data objects
uData = get(hSigSel,'UserData');
hObjOfs = uData{indFcn('hObjOfs')};
[tLim,pdX] = deal(uData{indFcn('tLim')},uData{indFcn('pDX')});
[hDL,hSigObj] = deal(uData{indFcn('hDL')},uData{indFcn('hSigObj')});

% updates the time offset box
set(hSigSel,'UserData',updateTimeOffset(hFig,uData,rPos(1)))

% updates the position of the patch object
xData = get(hSigObj,'xData');
if iscell(xData)
    cellfun(@(h,x,dx)(set(h,'xData',(x-x(1))-(dx-rPos(1)))),...
                num2cell(hSigObj),xData,num2cell(pdX));
else
    set(hSigObj,'xData',(xData-xData(1))+(pdX+rPos(1)))
end

% retrieves the current position of the line-marker
pDL = hDL{1}.getPosition();
setObjEnable(hObjOfs{2},'on')
setObjEnable(hObjOfs{3},'on')

% sets the position
hDL{1}.setPosition([tLim(1),rPos(1)],pDL(:,2));
hDL{2}.setPosition([rPos(1)+rPos(3),tLim(2)],pDL(:,2));

% --- case is moving the signal patch object
function moveExptObj(rPos,forceUpdate)

% global variables
global hSigSel isCreateBlk nProto

%
if nargin < 2; forceUpdate = false; end

% block is still being created so exit
if isCreateBlk && (~forceUpdate); return; end
if isempty(hSigSel); return; end

% retrieves the user data objects
uData = get(hSigSel,'UserData');
% rPos(1) = max(0,rPos(1));
[tLim,pdX] = deal(uData{indFcn('tLim')},uData{indFcn('pDX')});
[hDL,hSigObj] = deal(uData{indFcn('hDL')},uData{indFcn('hSigObj')});

% updates the time offset box
hFig = findall(0,'tag','figExptSetup');
uDataH = updateTimeOffset(hFig,uData,rPos(1));
set(hSigSel,'UserData',uDataH)

% %
% sigBlk = getappdata(hFig,'sigBlk');
% isMatch = cellfun(@(x)(isequal(hSigSel,x)),sigBlk{nProto});
% set(sigBlk{nProto}{isMatch},'UserData',uDataH);

% updates the position of the patch object
xData = arrayfun(@(x)(get(x,'xData')),hSigObj,'un',0);
cellfun(@(h,x,dx)(set(h,'xData',(x-x(1))+dx)),...
                num2cell(hSigObj),xData,num2cell(pdX+rPos(1)));

% retrieves the current position of the line-marker
pDL = hDL{1}.getPosition();

% sets the position
hDL{1}.setPosition([tLim(1),rPos(1)],pDL(:,2));
hDL{2}.setPosition([sum(rPos([1,3])),tLim(2)],pDL(:,2));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    STIMULI TEST TIMER CALLBACK FUNCTIONS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- the signal test start callback function
function startTest(obj, event, hSigTest)

% turns on the signal test line
setObjVisibility(hSigTest,'on');

% --- the signal test timer callback function
function timerTest(obj, event, hButton, hSigTest)

% determines if the toggle button has be clicked again
if ~get(hButton,'Value')
    % if so, stop the timer object
    stop(obj)
    pause(0.05)
else
    % otherwise, update the location of the signal test line
    xData = get(obj,'TasksExecuted')*get(obj,'Period');
    set(hSigTest,'xData',xData*[1,1])
end

% --- the signal test stop callback function
function stopTest(obj, event, hButton, hSigTest)

% turns off the signal test line
setObjVisibility(hSigTest,'off');
set(hButton,'Value',0,'String','Test Stimuli Train');

% deletes the timer object
delete(obj)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    EXPERIMENT PROTOCOL OBJECT CALLBACK FUNCTIONS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- updates on editing an experiment stimuli parameter editbox
function listExptStimPara(hObject, eventdata, handles, dType)

% finish me?
a = 1;

% --- updates on editing an experiment stimuli parameter editbox
function editExptStimPara(hObject, eventdata, handles, dType)

% global variables
global hSigSel

% initialisations
hFig = handles.figExptSetup;
pStr = get(hObject,'UserData');
iExpt = getappdata(hFig,'iExpt');
[sPara,sPara0] = deal(getappdata(hFig,'sParaEx'));

% sets the parameter limits/integer flag
switch pStr
    case 'nCount'
        [nwLim,isInt] = deal([1,inf],1);
        
    case 'tOfs'
        [nwLim,isInt] = deal([0,inf],0);
        
    case 'tDur'
        [nwLim,isInt] = deal([0,inf],0);
end

% determines if the new value is valid
nwVal = str2double(get(hObject,'String'));
if chkEditValue(nwVal,nwLim,isInt)
    % if so, then update the parameter struct with the new value
    sPara = setExptParaValue(sPara,pStr,nwVal,dType);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%    SIGNAL DURATION/COUNT UPDATE    %%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % initialisation
    [updateDur,updateCount] = deal(false);
    sParaS = eval(sprintf('sPara.%s',dType'));
    
    % retrieves the stimuli duration
    sTrainS = getSelectedSignalTrainInfo(hFig);
    [~,tUnits,tBlkOfs,tBlkDur] = ...
                        calcExptStimDuration(hFig,sTrainS,sPara); 
    tDurStim = max(tBlkOfs+tBlkDur);
    
    % calculates the scaled time between sucessive stimuli trains
    tIntV = getExptParaValue(sPara,'tStim',dType);
    tInt = vec2time(tIntV,iExpt.Timing.TexpU); 
    tMltDur = getTimeMultiplier(sParaS.tDurU,tUnits);
    
    %
    switch pStr
        case 'tDur'
            % flag that the repetition count needs updating
            updateCount = true;
            
            % recalculates the signal repetition count
            tDur = sParaS.tDur/tMltDur;            
            nCount = (tDur - tDurStim)/tInt + 1;
            
            % determines if the repetition count is an integer            
            if mod(nCount,0) > 0
                % if not, flag that the duration editbox needs updating
                updateDur = true;
                
                % updates the repetition count
                nCount = max(1,floor(nCount));
                sPara = setExptParaValue(sPara,'nCount',nCount,dType);
                
                % updates the signal train duration
                tDur = tMltDur*((nCount-1)*tInt + tDurStim);
                sPara = setExptParaValue(sPara,'tDur',tDur,dType);
            end
            
        case {'tOfs','nCount'}
            % flag that the duration editbox needs updating
            updateDur = true;            
            
            % retrieves the time offset/repetition count
            nCount = getExptParaValue(sPara,'nCount',dType);
            tDur = tMltDur*((nCount-1)*tInt + tDurStim);            
            
            % recalculates the signal train duration             
            sPara = setExptParaValue(sPara,'tDur',tDur,dType);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%    PARAMETER STRUCT UPDATE    %%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    

    % if so, then update the parameter struct with the new value
    setappdata(hFig,'sParaEx',sPara)     
    
    % determines if the stimuli train duration is valid
    [eState,tDurMin] = checkExptStimTrainDur(hFig,sPara);
    if eState > 0
          
        % retrieves the selected signal type from the parameter tab
        hTab = getCurrentSignalParaTab(handles);        

        % enables the use minimum signal duration button
        switch eState
            case 2
                % runs the minimum duration selection button
                hButton = getProtoObj(hFig,'buttonUseMinSig','Ex');
                buttonUseMinSig(hButton,'1',handles,tDurMin{2})
        end        
        
        % updates the other object properties
        setObjEnableProps(hFig,'buttonUseMinSig',eState==1)
        
        % updates the signal duration (if required)
        if updateDur
            set(findobj(hTab,'UserData','tDur'),...
                        'string',getEditResetString(tDur))
        end
        
        % updates the signal duration (if required)
        if updateCount
            set(findobj(hTab,'UserData','nCount'),...
                        'string',num2str(nCount))
        end        
        
        % if a signal block is selected, then update the properties
        if ~isempty(hSigSel)
            updateExptObjPara(hFig,eval(sprintf('sPara.%s',dType)));           
        end
        
        % exits the function
        return
    end
end

% if so, then update the parameter struct with the new value
setappdata(hFig,'sParaEx',sPara0) 

% otherwise, reset the editbox to the last valid value
prevVal = eval(sprintf('sPara0.%s.%s;',dType,pStr));
set(hObject,'string',getEditResetString(prevVal))

% --- Executes when selected object is changed in panelInfoStartTime.
function panelExptStartTime_SelectionChangedFcn(...
                                hObject, eventdata, handles, varargin)

% initialisations
eStr = {'off','on'};
hFig = handles.figExptSetup;

% determines if the fixed start time radiobutton was selected
if ischar(eventdata)
    hRadio = findobj(hObject,'Value',1,'Style','RadioButton');
else
    hRadio = eventdata.NewValue;
end

% updates the start time enabled properties
isFixed = strcmp(get(hRadio,'tag'),'radioFixedStartTime');
setPanelProps(handles.panelStartTimeEx,eStr{1+isFixed});
set(handles.checkFixStart,'Value',isFixed)

% updates the experiment parameter data struct
iExpt = getappdata(hFig,'iExpt');
iExpt.Timing.fixedT0 = isFixed;
setappdata(hFig,'iExpt',iExpt)

% resets the experiment time axes
if isempty(varargin)
    % deselects any selected experimental protocol groups
    pType0 = getappdata(hFig,'pType');
    setappdata(hFig,'pType','Experiment Stimuli Protocol')
    figExptSetup_WindowButtonDownFcn(hFig, [], handles, 'alt')
    setappdata(hFig,'pType',pType0)    
    
    % resets the experiment time axis and the protocol type flag
    resetExptTimeAxes(handles,'Ex');
end

% --- callback function for updating the experiment duration popup boxes.
function popupExptDuration(hObject, eventdata, handles, dType)

% initialisations
hFig = handles.figExptSetup;
iType = get(hObject,'UserData');
iSel = get(hObject,'Value');

% updates the parameters 
[iExpt,iExpt0] = deal(getappdata(hFig,'iExpt'));
if ~ischar(eventdata)
    iExpt.Timing.Texp(iType) = get(hObject,'Value') - 1;
    if nargin == 3
        tMin = 0;
    else
        tMin = getMinExptDuration(hFig,false);
    end 
else
    tMin = 0;
end

% calculates the experiment time
tExp = vec2time(iExpt.Timing.Texp,iExpt.Timing.TexpU);

% determines the maximum extent of all signal blocks
if tExp == 0
    % experiment duration must have a lower limit
    eStr = 'The experiment duration must be greater than zero.';
    waitfor(msgbox(eStr,'Infeasible Experiment Duration','modal'))  
    
elseif tExp >= tMin
    % if so, then update the parameter struct 
    TexpU0 = iExpt.Timing.TexpU;
    [~,iExpt.Timing.TexpU] = vec2time(iExpt.Timing.Texp);
    setappdata(hFig,'iExpt',iExpt)

    % updates the corresponding experiment duration popup menu item
    ptStr = get(hObject,'tag');
    if strContains(ptStr,'Info')
        % case is updating the experiment protocol duration popup
        hPopup = findobj(hFig,'tag',sprintf('%sEx',ptStr(1:end-4)));
    else
        % case is updating the information duration popup
        hPopup = findobj(hFig,'tag',sprintf('%sInfo',ptStr(1:end-2)));
    end

    % deselects any selected experimental protocol groups
    pType0 = getappdata(hFig,'pType');
    setappdata(hFig,'pType','Experiment Stimuli Protocol')
    figExptSetup_WindowButtonDownFcn(hFig, [], handles, 'alt')
    setappdata(hFig,'pType',pType0)    
    
    % resets the experiment time axes
    set(hPopup,'Value',iSel)
    resetExptTimeAxes(handles,'Ex',TexpU0)   

    % updates the use minimum duration button enabled properties
    setObjEnable(getProtoObj(hFig,'buttonUseMinSig'),'on')
    return
    
else
    % if not, then output an error screen
    tExpV = getTimeVectorString(tExp,iExpt.Timing.TexpU);
    tMinV = getTimeVectorString(tMin,iExpt.Timing.TexpU);
    eStr = sprintf(['The specified experiment duration (%s) does not ',...
            'include all experiment stimuli blocks (%s). To ',...
            'remedy this either:\n\n * Set a longer experiment duration',...
            '\n * Delete or move one or more experiment stimuli blocks.'],...
            tExpV,tMinV);
    waitfor(msgbox(eStr,'Infeasible Experiment Duration','modal'))    
end

% reset the duration to the last valid value
set(hObject,'Value',iExpt0.Timing.Texp(iType)+1);

% --- Executes on selection change in popupStartDayInfo.
function popupStartTime(hObject, eventdata, handles)

% initialisations
hFig = handles.figExptSetup;
iSel = get(hObject,'Value');
iType = get(hObject,'UserData');
iExpt = getappdata(hFig,'iExpt');

% sets the start time vector
switch (iType)
    case (1) 
        % resets the hour value based on the AM/PM popup         
        iHour = get(handles.popupStartHourInfo,'Value');
        iExpt.Timing.T0(4) = iHour + 12*(iSel-1);    
    
    case (2) 
        % case is the month was selected
        
        % sets the day strings
        dMax = getMonthDayCount(iSel);
        dStr = getTimeDurationString(dMax,1);
        
        % ensures the day is at most the maximum value, and resets the day
        % popup menu string list/value
        [iExpt.Timing.T0(3),dVal] = deal(min(iExpt.Timing.T0(3),dMax)); 
        iExpt.Timing.T0(iType) = iSel;
        
        % updates the data popup menus
        set(handles.popupStartDayInfo,'string',dStr,'Value',dVal);
        
    case (3) % case is the day was selected
        % updates the value
        iExpt.Timing.T0(iType) = iSel;
        
    case (4) % case is the hours was selected
        % recalculates the hour
        isPM = get(handles.popupStartAMPMEx,'Value');
        iExpt.Timing.T0(iType) = 12*isPM + iSel;
                
    case (5) % case is the minutes was selected
        % updates the value
        iExpt.Timing.T0(iType) = iSel - 1;                
end

% updates the corresponding experiment duration popup menu item
ptStr = get(hObject,'tag');
if strContains(ptStr,'Info')
    % updates the experiment protocol duration popup
    hPopup = findobj(hFig,'tag',sprintf('%sEx',ptStr(1:end-4)));
else
    % updates the information duration popup
    hPopup = findobj(hFig,'tag',sprintf('%sInfo',ptStr(1:end-2)));
end

% if the popup object exists, then update it value
if ~isempty(hPopup)
    set(hPopup,'Value',iSel)
end

% deselects any selected experimental protocol groups
pType0 = getappdata(hFig,'pType');
setappdata(hFig,'pType','Experiment Stimuli Protocol')
figExptSetup_WindowButtonDownFcn(hFig, [], handles, 'alt')
setappdata(hFig,'pType',pType0)

% updates the parameter struct and resets the experiment time axes
setappdata(hFig,'iExpt',iExpt);
resetExptTimeAxes(handles,'Ex')

% --- Executes on selection change for an experiment time unit popup
function popupExptTimeUnits(hObject, eventdata, handles, dType)

%
hFig = handles.figExptSetup;
sParaEx = getappdata(hFig,'sParaEx');
sPara = eval(sprintf('sParaEx.%s',dType));

% retrieves the old/new units
pStr = get(hObject,'UserData');
[lStr,iSel] = deal(get(hObject,'string'),get(hObject,'value'));
[tUnitsOld,tUnitsNw] = deal(eval(sprintf('sPara.%s',pStr)),lStr{iSel});

% calculates the new time (scaled to the new units)
tMlt = getTimeMultiplier(tUnitsNw,tUnitsOld);
nwTime = eval(sprintf('sPara.%s*tMlt',pStr(1:end-1)));

%
eval(sprintf('sPara.%s = tUnitsNw;',pStr));
eval(sprintf('sPara.%s = nwTime;',pStr(1:end-1)));

% updates the associated
hEdit = findobj(get(hObject,'Parent'),'UserData',pStr(1:end-1));
set(hEdit,'string',getEditResetString(nwTime))

% updates the parameter struct within the gui
eval(sprintf('sParaEx.%s=sPara;',dType))
setappdata(hFig,'sParaEx',sParaEx)

% --- callback function for updating the experiment duration popup boxes.
function popupStimDuration(hObject, eventdata, handles, dType)

% global variables
global hSigSel

% loads the experimental protocol data struct
hFig = handles.figExptSetup;
iType = get(hObject,'UserData');
[sPara,sPara0] = deal(getappdata(hFig,'sParaEx'));

% updates the parameters 
sParaS = eval(sprintf('sPara.%s',dType));
sParaS.tStim(iType) = get(hObject,'Value') - 1;
eval(sprintf('sPara.%s = sParaS;',dType))

% determines if the new value is valid
[eState,tDurMin] = checkExptStimTrainDur(hFig,sPara);
if eState > 0
    % if so, then update parameter struct
    tDurNw = vec2time(tDurMin{1},sParaS.tDurU);
    eval(sprintf('sPara.%s.tDur = tDurNw;',dType))
    setappdata(hFig,'sParaEx',sPara)
    
    % enables the use minimum signal duration button
    switch eState
        case 2
            % runs the minimum duration selection button
            hButton = getProtoObj(hFig,'buttonUseMinSig','Ex');
            buttonUseMinSig(hButton, '1', handles, tDurMin{2})
    end
    
    % updates the other object properties
    setObjEnableProps(hFig,'buttonUseMinSig',eState==1)    
    
    % retrieves the currently selected parameter tab handle
    sType = getappdata(hFig,'sType');
    hTab = findobj(getappdata(hFig,'hTabGrpEx'),'Title',sType);  
    
    % updates the signal duration 
    hEditDur = findobj(hTab,'UserData','tDur');
    set(hEditDur,'string',num2str(tDurNw))
    
    % if a signal block is selected, then update the properties
    if isempty(hSigSel)
        % updates the signal duration field    
        hEditCount = findobj(hTab,'UserData','nCount');
        editExptStimPara(hEditCount, '1', handles, sType(1))
        
    else
        updateExptObjPara(hFig,sParaS);       
    end
else
    % otherwise, revert back to the last valid value
    prevVal = eval(sprintf('sPara0.%s.tStim(iType)',dType));
    set(hObject,'Value',prevVal+1)
end            

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    OBJECT INITIALSIATION/CREATION FUNCTIONS   %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- initialises the GUI object properties
function initObjProps(handles,devType,nCh,isInit,h)

% global variables
global chCol nProto figPos0 nParaMax initObj

% retrieves the current figure position
initObj = true;
hFig = handles.figExptSetup;
hMain = getappdata(hFig,'hMain');
infoObj = getappdata(hFig,'infoObj');

% creates the load bar
if isInit
    % case is the gui is being opened
    mStr = 'Initialising Experiment Setup GUI...';
    if isempty(h)
        % case is a progress loadbar has not been provided
        h = ProgressLoadbar(mStr);
    else
        % otherwise, update the progress loadbar
        h.StatusMessage = mStr;
    end
else
    % case is a new experimental protocol is being opened
    setObjVisibility(hFig,'off');
    h = ProgressLoadbar('Resetting Experiment Setup GUI...');    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    INITIALISATIONS & PRE-PROCESSING    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialisations
nParaMax = 6;
hasStim = true;
hasVid = ~strcmp(infoObj.exType,'StimOnly');
nDev = length(devType);
eStr = {'off','on'};
devType = cellfun(@(x)(removeDeviceTypeNumbers(x)),devType(:),'un',0);

% string arrays
dType = {'Info','S','L','Ex'};  
dStr = {'Seconds','Hours','Hours'};
tStr = {'Experiment Information',...
        'Short-Term Stimuli Protocol',...
        'Long-Term Stimuli Protocol',...
        'Experiment Stimuli Protocol'};

% sets the axes time limits
if isInit
    % case is if initialising
    figPos0 = get(hFig,'Position');
    
    % initialises the experiment information struct    
    if isempty(hMain)
        iExpt = initExptStruct(hFig);
    else
        iExpt = getappdata(hMain,'iExpt');   
        if isempty(iExpt)
            iExpt = initExptStruct(hFig);
        end
    end
    
    % creates the custom-signal object (if package available)
    feval('runExternPackage','CustomSignalObj',handles);     
    
    % updates the experiment information data struct into the gui
    setappdata(hFig,'iExpt',iExpt)    
    
else
    % case is not initialising
    
    % retrieves the protocol/train parameter structs    
    sParaS = getappdata(hFig,'sParaS');
    sParaL = getappdata(hFig,'sParaL');
    sParaEx = getappdata(hFig,'sParaEx');
    sTrain = getappdata(hFig,'sTrain');
    iExpt = getappdata(hFig,'iExpt');
    
    % initialises the axes limits 
    tDurExp = vec2time(iExpt.Timing.Texp,iExpt.Timing.TexpU);
    tLim = [sParaS.tDur,sParaL.tDur,tDurExp];
    pType0 = getappdata(hFig,'pType');
    
    % updates the axes time limits using the train
    if ~isempty(sTrain)
        sFld = fieldnames(sTrain);
        for i = 1:length(sFld)
            sTrainP = eval(sprintf('sTrain.%s',sFld{i}));
            if ~isempty(sTrainP)
                if strcmp(sFld{i},'Ex')
                    [tLim(i),dStr{i}] = vec2time(iExpt.Timing.Texp);
                else
                    tLim(i) = sTrainP{1}.tDur;
                end
            end
        end
    end
    
    % ensures any clear all buttons are run (if they are enabled)    
    for i = 2:3
        % retrieves the clear all button object handle
        setappdata(hFig,'pType',tStr{i});
        hBut = getProtoObj(hFig,'buttonClearAll',dType{i});
        if strcmp(get(hBut,'Enable'),'on')
            % if enabled, then clear all
            buttonClearAll(hBut, '1', handles)
        end
    end
    
    % resets the original protocol type
    setappdata(hFig,'pType',pType0);
end

% calculates the axes global coordinates
calcAxesGlobalCoords(handles)

% sets up the axis properties based on the connected device
chName = cell(1,nDev);
for i = 1:nDev
    switch devType{i}
        case 'Opto' 
            % case is the optogenetic device
            chName{i} = getOptoChannelNames();
            nCh(i) = length(chName{i});

        case 'Motor'
            % case is a motor device
            chName{i} = getMotorChannelNames(nCh(i),1);        

        case 'RecordOnly' 
            % case is recording only 
            [chName{i},hasStim] = deal([],false);

    end
end

% initialises the stimuli channel information array
if strcmp(devType{1},'RecordOnly')
    % if recording only, then no need to set the channel info array
    chInfo = [];
    
else
    % otherwise, setup the device type strings
    [devTypeT,isFound] = deal(devType,false(nDev,1));
    for i = 1:nDev
        if ~isFound(i)
            % determines if there are multiple devices of the same type
            ii = find(strcmp(devType,devTypeT{i}));
            if length(ii) > 1
                % if so, then replace their names with numbered names
                devTypeT(ii) = arrayfun(@(x)(sprintf('%s %i',...
                                    devTypeT{i},x)),1:length(ii),'un',0);                
            end
            
            % flag that all devices of the current type have been flagged
            isFound(ii) = true;
        end
    end
    
    % sets the device channel information array
    chID = cellfun(@(i,x)(i*ones(length(x),1)),...
                            num2cell(1:nDev),chName,'un',0);                                               
    chInfo = cell2cell(cellfun(@(i,x)([num2cell(i),x(:),...
                            devTypeT(i)]),chID,chName,'un',0));
end

% retrieves the channel colours
chCol = getChannelCol(devType,nCh(1:length(devType)));

% sets the tab title strings
tStrS = {'Square','Ramp','Triangle','SineWave'};
hPanel = {handles.panelFullExptInfo,...
          handles.panelProtoS,...
          handles.panelProtoL,...
          handles.panelProtoEx};
hAx = {[],...
       handles.axesProtoS,...
       handles.axesProtoL,...
       handles.axesProtoEx};

% array dimensioning
nProto = length(tStr);

if isInit
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%    PROTOCOL PANEL INITIALISATION    %%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % initialisations      
    bStr = {'buttonAddSig','buttonDeselectSig','buttonCopySig',...
            'buttonDelSig','buttonResetPara','buttonClearChan',...
            'buttonClearAll','buttonSaveTrain','buttonDeleteTrain',...
            'buttonUpdateTrain','buttonRepeatTrain','listStimTrain',...
            'buttonUseMinSig'};    
    
    % sets the object positions
    tabPos = getTabPosVector(handles.panelOuter,[5,5,-10,-5]);

    % creates a tab panel group
    hTabGrp = createTabPanelGroup(handles.panelOuter,1);
    set(hTabGrp,'position',tabPos,'tag','hTabGrp')
    
    % creates the tabs for each code difference type
    hTab = cell(nProto,1);
    for i = 1:nProto
        % creates a new tab panel
        hTab{i} = createNewTabPanel(...
                           hTabGrp,1,'title',tStr{i},'UserData',i);
        set(hTab{i},'ButtonDownFcn',{@tabSelected,handles})
        set(hPanel{i},'Parent',hTab{i}) 
        
        % sets the signal control button properties
        if i > 1
            for j = 1:length(bStr)
                % determines if the object exists
                hB = findobj(hPanel{i},'tag',...
                                       sprintf('%s%s',bStr{j},dType{i}));               
                if ~isempty(hB)
                    % if so, then set the button properties
                    set(hB,'Callback',{str2func(bStr{j}),handles},...
                           'Enable',eStr{1+((j==1)&&(i<nProto))});
                end    
            end
        end
    end

    % retrieves the table group java object
    jTab = getTabGroupJavaObj(hTabGrp);

    % updates the objects into the GUI
    setappdata(hFig,'jTab',jTab)
    setappdata(hFig,'hTab',hTab)
    setappdata(hFig,'hTabGrp',hTabGrp)  
    pause(0.05);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%    SINGLE PROTOCOL TAB INITIALISATION    %%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % sets the parameter data structs into the GUI
    setappdata(hFig,'sParaS',setupSingleStimPara('S'))
    setappdata(hFig,'sParaL',setupSingleStimPara('L'))

    % parameters
    [pHght,pGap,tHght] = deal(20,5,30);

    % memory allocation
    tDurArr = {'s','h'};
    [hTabGrp,hTab,jTab] = deal(cell(length(dType),1));

    % creates the parameter tab/objects for the short/long-term 
    % protocol tabs
    for i = 2:nProto-1
        % retrieves the parameter struct (based on duration type)
        sPara = getParaStruct(hFig,dType{i});
        tDur = tDurArr{1+strcmp(dType(i),'L')};

        % retrieves the objects specific to the tab
        hPanel = getProtoObj(hFig,'panelPara',dType{i});
        hButUseMS = getProtoObj(hFig,'buttonUseMinSig',dType{i});
        hEditName = getProtoObj(hFig,'editStimName',dType{i});
        hEditDur = getProtoObj(hFig,'editTotalDur',dType{i});
        hTextDur = getProtoObj(hFig,'textStimDur',dType{i});        

        % sets the callback functions for the name/duration editboxes
        set(hEditName,'Callback',{@editStimName,handles,dType{i}},...
                      'String',sPara.sName)
        set(hEditDur,'Callback',{@editTotalDur,handles,dType{i}})
        
        if strcmp(dType{i},'S')
            txtStr = sprintf('Total Train Duration (%s): ',tDur);
            set(hTextDur,'String',txtStr);
        else
            iSel = 1 + strcmp(sPara.tDurU,'h');
            set(handles.popupTotalDurU,'Value',iSel)
        end

        % sets the tab group position
        bPos = get(hButUseMS,'Position');
        tPosS = getTabPosVector(hPanel,[5,5,-10,-5]);
        tPosS(4) = (pHght + pGap)*nParaMax + (pGap+tHght);
        tPosS(2) = bPos(2) - (tPosS(4)+pGap);

        % creates a tab panel group
        hTabGrp{i} = createTabPanelGroup(hPanel,1);
        set(hTabGrp{i},'position',tPosS,'tag',sprintf('hTab%s',dType{i}))

        % creates the tabs for each default signal type
        hTab{i} = cell(length(tStrS),1);
        for j = 1:length(tStrS)
            % creates a new tab panel
            hTab{i}{j} = createNewTabPanel(...
                            hTabGrp{i},1,'title',tStrS{j},'UserData',j);
            set(hTab{i}{j},'ButtonDownFcn',...
                            {@tabSelectedPara,handles,dType{i}})

            % creates the parameter objects for the current tab
            createParaObj(handles,hTab{i}{j},sPara,dType{i});
        end

        % retrieves the table group java object
        jTab{i} = getTabGroupJavaObj(hTabGrp{i});   

        % updates the objects into the GUI
        setappdata(hFig,sprintf('jTab%s',dType{i}),jTab{i})
        setappdata(hFig,sprintf('hTab%s',dType{i}),hTab{i})
        setappdata(hFig,sprintf('hTabGrp%s',dType{i}),hTabGrp{i})
    end       
    
    % pause to update
    pause(0.05);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%    EXPERIMENT PROTOCOL TAB INITIALISATION    %%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    
    % initialisations
    tStrEx = {'Short-Term Stimuli','Long-Term Stimuli'};    
    
    % sets the parameter data structs into the GUI
    sParaEx = setupExptProtoPara();
    setappdata(hFig,'sParaEx',sParaEx)

    % retrieves the objects specific to the tab
    hPanel = handles.panelParaEx;
    hPanelBlk = handles.panelExptBlock;
    hPanelTime = handles.panelInfoStartTime;    
    
    % sets the tab group position
    pPosB = get(hPanelBlk,'Position');
    pPosT = get(hPanelTime,'Position');    
    tPosS = getTabPosVector(hPanel,[5,5,-10,-5]);
    tPosS(4) = (pPosT(2)-sum(pPosB([2,4]))) - (5+2*pGap);
    tPosS(2) = sum(pPosB([2,4])) + pGap;    
    
    % creates a tab panel group
    hTabGrpEx = createTabPanelGroup(hPanel,1);
    set(hTabGrpEx,'position',tPosS,'tag','hTabEx')
    
    % creates the tabs for each code difference type
    hTabEx = cell(length(tStrEx),1);    
    for j = 1:length(tStrEx)
        % creates a new tab panel
        hTabEx{j} = createNewTabPanel(...
                        hTabGrpEx,1,'title',tStrEx{j},'UserData',j);
        set(hTabEx{j},'ButtonDownFcn',{@tabSelectedExpt,handles})

        % sets up the experimental protocol parameter objects             
        initDurObjProps(handles,'Stim',tStrEx{j}(1))
        setupExptProtoObj(handles,hTabEx{j},sParaEx,tStrEx{j}(1))        
    end    
    
    % retrieves the table group java object
    jTabEx = getTabGroupJavaObj(hTabGrpEx);

    % updates the objects into the GUI
    setappdata(hFig,'jTabEx',jTabEx)
    setappdata(hFig,'hTabEx',hTabEx)
    setappdata(hFig,'hTabGrpEx',hTabGrpEx)    
    
    % initalises the duration objects
    initDurObjProps(handles,'Dur','Ex')
    
    % sets the other properties
    setPanelProps(handles.panelStartTimeEx,'off')
    initExptStartProps(handles,'Ex')
    initExptStartProps(handles,'Info')
    
    % sets the original motion function into the GUI
    setappdata(hFig,'motionFcn',get(hFig,'WindowButtonMotionFcn'))
    
    % initialises the timer object
    initTimerObj(handles)       

    % initialises the axes limits 
    sParaS = getappdata(hFig,'sParaS');
    sParaL = getappdata(hFig,'sParaL');
    tDurExp = vec2time(iExpt.Timing.Texp,iExpt.Timing.TexpU);
    tLim = [sParaS.tDur,sParaL.tDur,tDurExp];
    
else
    % retrieves the experiment data struct
    if ~isempty(sTrain)
        resetAllProtoTabPara(hFig,'S');
        resetAllProtoTabPara(hFig,'L');
        resetAllProtoTabPara(hFig,'Ex'); 

        % retrieves the experiment parameter tab group handle
        hTabGrpEx = getappdata(hFig,'hTabGrpEx');    
    end
    
    % resets the selected signal tabs
    resetSigTabSelect(hFig);
end

% pause to update
pause(0.05);

% resets the signal block array
if hasStim
    sigBlk = cell(nProto,1);
    sigBlk(1:3) = repmat({cell(sum(nCh),1)},3,1);
    sigBlk{4} = [];
    setappdata(hFig,'sigBlk',sigBlk);
end

% initalises the experiment duration objects for the info tab
initDurObjProps(handles,'Dur','Info')

% sets the time popup values for the given panels
setDurPopupValues(handles.panelExptDurInfo,iExpt.Timing.Texp);
setStartTimeValues(handles.panelInfoStartTime,iExpt.Timing.T0);

% sets the stimuli dependent popup object values (if stimuli available)
if hasStim   
    setDurPopupValues(handles.panelStimIntS,sParaEx.S.tStim);
    setDurPopupValues(handles.panelStimIntL,sParaEx.L.tStim);    
    setDurPopupValues(handles.panelExptDurEx,iExpt.Timing.Texp);
    setStartTimeValues(handles.panelStartTimeEx,iExpt.Timing.T0);
end

% sets the protocol type strings
setappdata(hFig,'pTypeT',tStr)

% starts the timer
try 
    start(getappdata(hFig,'timerObj'))
catch
    initTimerObj(handles)
    start(getappdata(hFig,'timerObj'))
end

% pause to update
pause(0.05);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    PLOT AXES INITIALISATION    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% retrieves the tab java-object handle
jTab = getappdata(hFig,'jTab');  
hTab = getappdata(hFig,'hTab');  
hTabG = getappdata(hFig,'hTabGrp');

% creates the tabs for each code difference type
if hasStim    
    % resets the parents tag from the protocol tabs (non-init only)
    if ~isInit
        cellfun(@(x)(set(x,'Parent',hTabG)),hTab(2:end))
        resetTabParentHandle(hFig);  
    end
    
    % creates the zoom object
    hZoom = initZoomObject(hFig);    
    
    % initialises the plot axes
    hDL = cell(nProto,1);
    for j = 2:nProto
        i = j-1;
        set(hFig,'CurrentAxes',hAx{j})
        hDL{j} = initPlotAxis(handles,hAx{j},tLim(i),devType,chInfo,...
                              dStr{i},isInit);
                          
        try
            % sets up the zoom constraint
            setAxesZoomConstraint(hZoom,hAx{j},'x');
        end
    end    

    % updates the objects into the GUI
    setappdata(hFig,'iCh',-1)
    setappdata(hFig,'hDL',hDL)
    setappdata(hFig,'chInfo',chInfo)    
    setappdata(hFig,'hZoom',hZoom);    
    
    % retrieves the stimuli train parameter struct
    if isInit
        if isempty(hMain)
            % if the main gui is not provided, then set an empty struct
            sTrain = [];
        else
            % otherwise, retrieve the stimuli train data from the main gui
            sTrain = getappdata(hMain,'sTrain');
        end
    else
        % otherwise, retrieve the stimuli train data from the gui
        sTrain = getappdata(hFig,'sTrain');
    end

    % determines if there are any custom signals (if so, then add these
    % tabs to the signal type tabs on the protocol tabs)
    sObjC = detCustomSignals(hFig,sTrain);
    for j = 1:length(sObjC)
        addCustomSignalTab(handles,sObjC{j},0);
    end
    
    % initialises the stimuli train (initialisation only)
    if isInit                
        setappdata(hFig,'sType',tStrS{1})  
        setappdata(hFig,'pType',tStr{1})          
        
        % retrieves the stimuli train        
        if isempty(sTrain)       
            % if none exists, then initalise
            setappdata(hFig,'sTrain',initStimTrainPara())  
        else
            % otherwise, use current stimuli train
            setappdata(hFig,'sTrain',sTrain)
        end
        
    else
        % initialisations   
        hTab = get(hTabG,'SelectedTab');
        pTypeStr = getProtoTypeStr(get(hTab,'Title'));                        
        
        % updates the protocol type
        setappdata(hFig,'pType',get(get(hTabG,'SelectedTab'),'Title'))
        
        % updates the axes flag (if not the information tab)
        if ~strcmp(pTypeStr,'Info')
            % retrieve the tab group based on the protocol type
            if strcmp(pTypeStr,'Ex')
                % case is the experiment protocol
                hTabGrpS = hTabGrpEx;
            else
                % case is the short/long-term protocols
                hTabGrpS = getappdata(hFig,sprintf('hTabGrp%s',pTypeStr));
            end

            % resets the signal type string based on the open protocol tab
            hTabCurr = get(hTabGrpS,'SelectedTab');
            setappdata(hFig,'sType',get(hTabCurr,'Title'))
            set(hFig,'CurrentAxes',findobj(hTab,'type','axes'))
        end        
    end           
    
    % checks the stimuli-dependent feasibility flags
    updateFeasFlag(handles,'checkProtoFeas',true)
    updateFeasFlag(handles,'checkStimFeas',true)    
    
    % initialises the stimuli train objects (if any)
    if ~isempty(sTrain)
        % if there are stimuli trains, then create thema
        initStimTrainObj(hFig)        
        
        % initialise the experiment stimuli train tab object properties
        initExptTrainObj(hFig)   
        
        % determines if there is any experiment stimuli train information
        if isempty(sTrain.Ex)
            % if not, then determine if the expt protocol tab is selected
            iProto = getProtocolIndex(hFig);
            if iProto(nProto)
                % if so, then selected the expt information tab instead
                hTabG = getappdata(hFig,'hTabGrp');
                hTabNw = findobj(hTabG,'Title','Experiment Information');
                set(hTabG,'SelectedTab',hTabNw)
            end             
        end        
    end   
    
    % sets the current axes to the short protocol axes
    set(hFig,'CurrentAxes',hAx{1})   
    try; arrayfun(@(x)(jTab.setEnabledAt(x-1,1)),2:nProto-1); end
    setExptTabProps(hFig)          
    
else
    % sets the enabled tabs 
    cellfun(@(x)(set(x,'Parent',[])),hTab(2:nProto))  
    
    % sets the selected tab to be the information tab    
    hTabG.SelectedTab = findobj(hTabG,'Title','Experiment Information');        
    
    % sets the protocol type as the info tab
    setappdata(hFig,'pType',tStr{1})
    
    % checks the stimuli-dependent feasibility flags
    updateFeasFlag(handles,'checkProtoFeas',false)
    updateFeasFlag(handles,'checkStimFeas',false)    
end

% updates the zoom toggle button enabled properties 
iProto = getProtocolIndex(hFig);
setObjEnable(handles.toggleZoomAxes,hasStim && ~iProto(1));

% updates the experiment protocol enabled properties
if hasStim
    tabSelectedExpt(get(hTabGrpEx,'SelectedTab'), '1', handles)
end

% pause to update
pause(0.05);

% updates the figure positon
setFigurePosition(handles,hasStim)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    EXPERIMENT INFORMATION OBJECT INITIALISATION    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% intialises the experiment info fields
setExptInfoFields(handles,devType,hasVid)

% runs the feasibility check
editExptTitle_Callback(handles.editExptTitle, '1', handles)
updateFeasFlag(handles,'checkVidFeas',true)
initObj = false;

% deletes the progressbar
delete(h)

% makes the GUI visible again
if isInit
%     feval('runExternPackage','RunStreamPix',handles);     
else
    setObjVisibility(hFig,'on'); 
end

% --- updates the figure positon
function setFigurePosition(handles,hasStim)

% global parameters
global figPos0 figdX

% initialisations
hFig = handles.figExptSetup;
figPos = get(hFig,'Position');
hTabG = getappdata(hFig,'hTabGrp');

%
if hasStim
    % case is the experiment does have stimuli
    
    % if the figure is already full size, then exit the function
    if figPos(3) == figPos0(3)
        return
    else
        dX = -figdX;
    end    
else
    % case is the experiment is recording only

    % if the figure is already reduced size, then exit the function
    if figPos(3) ~= figPos0(3)
        return
    else
        % determines the width by which
        pPosI = get(handles.panelExptInfo,'Position');
        pPosO = get(handles.panelFullExptInfo,'Position'); 
        [figdX,dX] = deal(pPosI(3)-pPosO(3) + 10);

%         % ensures the experiment info tab has units in pixels
%         set(hTab{1},'Units','Pixels');        
    end    
end

% 
resetObjPos(handles.panelOuter,'width',dX,1)
resetObjPos(handles.panelFullExptInfo,'width',dX,1)
resetObjPos(hTabG,'width',dX,1);
resetObjPos(hFig,'width',dX,1)

% --- resets the protocol tab parent handle
function resetTabParentHandle(hFig)

% initialisations
dStr = {'S','L','Ex'};

for i = 1:length(dStr)
    % retrieves the tab/tab group handles for 
    hTab = getappdata(hFig,sprintf('hTab%s',dStr{i}));
    hTabG = getappdata(hFig,sprintf('hTabGrp%s',dStr{i}));
    cellfun(@(x)(set(x,'Parent',hTabG)),hTab)   
    
    % resets the parent objects
    set(hTabG,'Parent',getProtoObj(hFig,'panelProto',dStr{i}));
    set(hTabG,'Parent',getProtoObj(hFig,'panelPara',dStr{i}));            
end

% --- resets the signal tab selection to the square wave tab
function resetSigTabSelect(hFig)

% global variables
global hSigSel

% resets the selected signal field
hSigSel0 = hSigSel;
hSigSel = [];

% initialisations
pType = {'S','L'};
handles = guidata(hFig);

% loops through each protocol type resetting the selected tab
for i = 1:length(pType)
    % retrieves the signal/group tab handles
    hTabG = getappdata(hFig,sprintf('hTabGrp%s',pType{i}));
    hTab = findall(hTabG,'title','Square');
    set(hTabG,'SelectedTab',hTab)
    
    % runs the signal tab selection callback function
    tabSelectedPara(hTab, '1', handles, pType{i});
end

% resets the selected object handle
hSigSel = hSigSel0;

% --- resets all the protocol tab parameters
function resetAllProtoTabPara(hFig,pType)

% initalisations
isExpt = strcmp(pType,'Ex');

% retrieves the tab group
hTabGrp = getappdata(hFig,sprintf('hTabGrp%s',pType));
hTab = get(hTabGrp,'Children');

% retrieves the signal parameters for the current protocol type
if isExpt
    % case is the experiment protocol
    sPara = getappdata(hFig,'sParaEx');
else
    % initialisations
    isChange = false;
    
    % case is the short/long-term protocols    
    sPara = getProtocolParaInfo(hFig,pType);
    sParaDef = setupSingleStimPara(pType);             
    
    % adds in any custom signal fields
    fStr = fieldnames(sPara);
    isCustom = cellfun(@(x)(isfield(getStructField(sPara,x),'sObj')),fStr);
    for i = find(isCustom(:)')
        sParaDef = setupSignalPara(sParaDef,fStr{i},pType);
    end
end

% resets the signal parameters for each sub-type
for i = 1:length(hTab)
    % retrieves the parameter sub-struct (dependent on type)
    hTabTitle = get(hTab(i),'Title');
    if isExpt
        % case is the experiment protocol
        sParaS = eval(sprintf('sPara.%s',hTabTitle(1)));
    else
        % case is the short/long-term protocols
        sParaS = getStructField(sPara,hTabTitle);
        sParaDefS = getStructField(sParaDef,hTabTitle); 
        isChange = isChange || ~isequal(sParaS,sParaDefS);
    end
    
    % resets the signal parameters
    resetSignalPara(hTab(i),sParaS)
end    

% updates the short/long-term protocol main parameters
if ~isExpt
    % updates the experiment name 
    hEditName = getProtoObj(hFig,'editStimName',pType);
    set(hEditName,'string',num2str(sPara.sName))
    
    % updates the experiment duration    
    hEditDur = getProtoObj(hFig,'editTotalDur',pType);
    set(hEditDur,'string',num2str(sPara.tDur))
    
    % updates the reset parameter button enabled properties
    hButReset = getProtoObj(hFig,'buttonResetPara',pType);
    setObjEnable(hButReset,isChange)
end

% --- initialises the stimuli signal plot axis
function hDL = initPlotAxis(handles,hAx,tLim,devType,chInfo,dStr,isInit)

% global variables
global axLimMax yGap chCol

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    INITIALISATION & PRE-PROCESSING    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clears the axes
if isempty(chInfo)
    % clears the axes and returns a 
    cla(hAx)
    hDL = [];
    
    % exits the function
    return
end

% sets the x-axis label
if get(handles.checkFixStart,'value')
    % case is fixed start experiment
    xLbl = 'Time';
else
    % case is non-fixed start experiment
    xLbl = sprintf('Time (%s)',dStr);
end

% initialisations
nCh = size(chInfo,1);
[fszAx,fszLbl,fszAxLbl] = deal(12,14,16);
[xx,ii,jj] = deal([0,tLim],[1,1,2,2],[1,2,2,1]);

% memory allocation
hDL = cell(nCh,3);

% sets the x/y axis limits & x-axis tick marks
xLim = calcAxisLimits(tLim,'x');
yLim = calcAxisLimits(nCh,'y');
yGap = 0.04*yLim(2);

% sets the axis properties
yTick = (1:nCh) - (0.5 - yGap/2);
set(hAx,'box','on','xlim',xLim,'ylim',yLim,'ytick',yTick,...
        'yticklabel',chInfo(end:-1:1,2),'TickLength',[0,0],...
        'FontSize',fszAx,'FontWeight','bold')
ytickangle(hAx,0);

% sets the x-axis label
xlabel(hAx,xLbl,'FontSize',fszLbl,'FontWeight','bold','tag','xLabel');

% if not initialising, then clear the plot axes
if ~isInit; cla(hAx); end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    PLOT AXES SETUP    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% turns on the axis hold
hold(hAx,'on')
sID = cell2mat(chInfo(end:-1:1,1));
hPlt = [];

% plots the
for i = 0:nCh
    % plots the edge markers
    plot(hAx,axLimMax*[-1,1],(i+yGap)*[1,1],'k:')
    
    % 
    if i < nCh
        % creates the marker line        
        if i > 0
            if sID(i+1) ~= sID(i)
                hPlt(end+1) = plot(hAx,axLimMax*[-1,1],i*[1,1],...
                                   'k','linewidth',2);
            else
                plot(hAx,axLimMax*[-1,1],i*[1,1],'k:')
            end
        end
        
        % creates the new patch
        yy = [(i+yGap),(i+1)];
        patch(hAx,xx(ii),yy(jj),[0,0,0],'UserData',i+1,...
            'EdgeColor',chCol{i+1},'FaceAlpha',0,...
            'LineWidth',2,'tag','chFill','visible','off');
        
        % creates the distance line objects for the current channel
        yL = (i+yGap/2)*[1,1];
        hDL{i+1,1} = createDistLine(hAx,[0,0.01],yL);
        hDL{i+1,2} = createDistLine(hAx,[0,0.01],yL);
        hDL{i+1,3} = createDistLine(hAx,[0,0.01],yL);
    end
end

% plots the start/end time markers
plot(hAx,[0,0],yLim,'k','tag','hLine0')
plot(hAx,tLim*[1,1],yLim,'k','tag','hLine1')

% parameters
tHght = 28;

%
axPos = get(hAx,'Position');
axTIns = get(hAx,'TightInset');
xTxt = xLim(1) - diff(xLim)*(axTIns(1)+3*tHght/4)/axPos(3);

% memory allocation
sIDU = unique(cell2mat(chInfo(:,1)));
nDev = length(sIDU);
hText = zeros(nDev,1);

% inserts the text label for each device
for i = 1:nDev
    % determines the match and new 
    iMatch = find(sID==sIDU(i));
    devType = chInfo{size(chInfo,1)-(iMatch(1)-1),3};
    
    % creates the text object
    hText(i) = text(hAx,xTxt,mean(yTick(iMatch)),devType,...
                    'FontSize',fszAxLbl,'FontWeight','bold',...
                    'Rotation',90,'HorizontalAlignment','Center');
end

% resets the positions of the axis to accomodate the device titles
set(hText,'Units','Pixels')
tPos = get(hText(1),'Extent');
dPos = ceil(5 - (axPos(1)+tPos(1)));
resetObjPos(hAx,'left',dPos,1)
resetObjPos(hAx,'width',-dPos,1)

% adds in the stimuli test line (short-term protocols only)
if strcmp(get(hAx,'tag'),'axesProtoS')
    plot(hAx,[0,0],yLim,'r','linewidth',2,'tag','hSigTest','visible','off');
end

% creates the distance line objects for each channel
for i = 1:nCh    
    yL = (i+yGap/2)*[1,1];
    hDL{i+1,1} = createDistLine(hAx,[0,0.01],yL);
    hDL{i+1,2} = createDistLine(hAx,[0,0.01],yL);
    hDL{i+1,3} = createDistLine(hAx,[0,0.01],yL);    
end

%
if ~isempty(hPlt)
    arrayfun(@(x)(uistack(x,'bottom')),hPlt)
end

% turns the axis hold off
hold(hAx,'off')

% --- sets up the experiment start objects
function initExptStartProps(handles,pStr)

% initialisations
hFig = handles.figExptSetup;
dStr = {'AMPM','Month','Day','Hour','Min'};

% sets up the time values strings for each of the popup menus
for i = 1:length(dStr)
    % retrieves the popup handle
    tagStr = sprintf('popupStart%s%s',dStr{i},pStr);
    hPopup = findobj(hFig,'tag',tagStr);
    
    % if the popup item exists then 
    if ~isempty(hPopup)
        % sets the duration string based on the type
        switch dStr{i}
            case 'AMPM' % case is the AM/PM popup
                durStr = {'AM','PM'};            
            
            case 'Month' % case is the month popup
                durStr = getMonthStrings();
                
            case 'Day' % case is the day popup
                durStr = getTimeDurationString(31,1);
                
            case 'Hour' % case is the hour popup
                durStr = getTimeDurationString(12,1);
                
            case 'Min' % case is the minute popup
                durStr = getTimeDurationString(60);               
                
        end
        
        % sets the strings/properties of the popup object
        cbFcn = {@popupStartTime,handles};
        set(hPopup,'String',durStr,'UserData',i,'Callback',cbFcn)
    end   
end

% --- initialises the stimuli train objects
function initStimTrainObj(hFig)

% initialisations
dType = {'S','L'};
pType0 = getappdata(hFig,'pType');
sTrain = getappdata(hFig,'sTrain');
pTypeT = getappdata(hFig,'pTypeT'); 
hTabEx = getappdata(hFig,'hTabEx');
handles = guidata(hFig);

% memory allocation
hasTrain = true(length(dType),1);

% sets up the stimuli train objects
for i = 1:length(dType)
    % retrieves the list/panel objects for the current protocol
    hList = getProtoObj(hFig,'listStimTrain',dType{i});
    hPanel = getProtoObj(hFig,'panelStimTrain',dType{i});
    hListEx = findobj(hTabEx{i},'style','listbox');

    % determines if there are any stimuli trains for protocol
    sTrainP = eval(sprintf('sTrain.%s',dType{i}));
    if ~isempty(sTrainP)     
        %
        sName = cellfun(@(x)(x.sName),sTrainP,'un',0);
        set(hListEx,'String',sName,'Value',1,'Max',1);
        setObjEnable(handles.buttonAddSigEx,'on')
        
        % updates the objects/strings into the gui
        hAx = getProtoObj(hFig,'axesProto',dType{i});
        set(hFig,'CurrentAxes',hAx)
        setappdata(hFig,'pType',pTypeT{i+1})

        % updates the stimuli list 
        sName = cellfun(@(x)(x.sName),sTrainP,'un',0);
        set(hList,'string',sName(:),'value',1,'max',1,'enable','on')
        
        % sets up the stimuli train objects
        setupStimTrainObj(guidata(hFig),sTrainP{1},dType{i},1)
        
        % resets the plot axes time limits
        hEdit = getProtoObj(hFig,'editTotalDur',dType{i});
        editTotalDur(hEdit, '1', handles, dType{i});
        
        % enables the clear all signals button
        hButClear = getProtoObj(hFig,'buttonClearAll',dType{i});
        setObjEnable(hButClear,'on');
    else
        % otherwise, clear the listbox
        set(hList,'string','','value',[],'max',2,'enable','off')   
        set(hListEx,'string','','Value',[],'Max',2);
        hasTrain(i) = false;
    end

    % sets the stimuli train panel enabled properties   
    hPanelEx = findobj(hTabEx{i},'type','uipanel');
    setPanelProps(hTabEx{i},~isempty(sTrainP)) 
    setPanelProps(hPanelEx,~isempty(sTrainP)) 
    setPanelProps(hPanel,~isempty(sTrainP))        
end

% sets the add button enabled properties
setObjEnableProps(hFig,'buttonAddSig',1)
% setObjEnableProps(hFig,'buttonAddSig',any(hasTrain))

% resets the protocol tab string
setappdata(hFig,'pType',pType0);

% --- initialises the experiment signal block objects
function initExptTrainObj(hFig)

% global variables
global yGap

% updates the experiment duration information
handles = guidata(hFig);
dType = getProtoTypeStr(getappdata(hFig,'pType'));
popupExptDuration(handles.popupDurDayInfo, '1', handles)

% initialisations
handles = guidata(hFig);
iExpt = getappdata(hFig,'iExpt');
sTrain = getappdata(hFig,'sTrain');
sParaEx = getappdata(hFig,'sParaEx');
sTrainEx = sTrain.Ex;
[tExp,t0] = deal(iExpt.Timing.Texp,iExpt.Timing.T0);

% updates the current axes to the experimental protocol tab
set(hFig,'CurrentAxes',handles.axesProtoEx)
setappdata(hFig,'pType','Experiment Stimuli Protocol')

% updates the experiment stimuli train information
hList = getProtoObj(hFig,'listStimTrain');
if ~isfield(sTrainEx,'sName')
    % no trains, set reset the list
    set(hList,'String',[],'Value',[],'Max',2);
    
    % exits the function
    return

else   
    % if there are trains, then set the list
    nTrain = length(sTrainEx.sName);
    set(hList,'String',sTrainEx.sName(:),'Value',nTrain,'Max',1);

end

% sets the experiment protocol tab fields
setDurPopupValues(handles.panelExptDurEx,tExp)
set(handles.radioFixedStartTime,'Value',iExpt.Timing.fixedT0)

% sets the experiment info tab fields
setDurPopupValues(handles.panelExptDurInfo,tExp)
setStartTimeValues(handles.panelInfoStartTime,t0)

% creates all the stimuli objects in the experiment protocol train
tExpU = iExpt.Timing.TexpU;
for i = 1:nTrain
    % if a valid region was selected, then create the new expt object
    sType = sTrainEx.sType{i};
    sTrainS = sTrainEx.sTrain(i);
    sP = sTrainEx.sParaEx(i);
    iCh = getBlockChannelIndices(hFig,sTrainS);

    % 
    tMltEx = getTimeMultiplier(tExpU,sP.tDurU);
    tMltOfs = getTimeMultiplier(tExpU,sP.tOfsU);
    
    % calculates the experiment duration
    tDurEx = tMltEx*calcExptStimDuration(hFig,sTrainS,sP,tExp);

    % creates the experiment object   
    tOfs = sP.tOfs*tMltOfs;
    tLimF = tOfs + [0,sP.tDur*tMltEx];
    rPos = [tLimF(1),((iCh(1)-1)+yGap),tDurEx,(range(iCh)+1)-yGap];
    uData = setupUserDataArray(hFig,tLimF,sTrainS,sType,iCh([1,end]));
    
    % updates the experiment parameter struct with the incoming parameters
    eval(sprintf('sParaEx.%s=sTrainEx.sParaEx(i);',sType(1)));
    setappdata(hFig,'sParaEx',sParaEx)
    
    % creates the new block object and updates the parameters
    createExptObject(hFig,uData,rPos,i==nTrain,false,false);
    
    % resets the parameters for the current experiment signal block
    hTab = findobj(getappdata(hFig,'hTabGrpEx'),'Title',sType);
    resetSignalPara(hTab,sTrainEx.sParaEx(i))   
end

% --- creates the single stimuli protocol parameter objects
function createParaObj(handles,hTabS,sPara,dType)

% global variables
global nParaMax

% initialisations/parameters
tStr = get(hTabS,'Title');
[eWid,eHght,lHght] = deal(60,20,16);
[xGap,yGap,x0,xOfs] = deal(0,5,5,10);
dtStr = {'s','m','h'};
gapStr = '           ';
popupStr = {'tDurOn','tDurOff','tCycle','tOfs'};

% determines the dependent dimensions
tPos = get(get(hTabS,'parent'),'position');
lWid = tPos(3) - (x0+xGap+eWid+xOfs);
dyL = (eHght-lHght)/2;

% sets the duration string based on protocol type
switch dType
    case 'S'
        % case is a short-term protocol
        [dStr,dStrT] = deal('s');
        
    case 'L'
        % case is a long-term protocol
        [dStr,dStrT] = deal(gapStr,'h');
        
end

% sets the label/parameter strings based on the stimuli type
switch tStr
    case 'Square'
        % case is a square-wave
        lStr = {'Signal Amplitude (%)',...
                sprintf('On Cycle Duration (%s)',dStr),...
                sprintf('Off Cycle Duration (%s)',dStr),...
                sprintf('Initial Signal Offset (%s)',dStr),...
                'Signal Cycle Count',...                
                sprintf('Signal Train Duration (%s)',dStrT)};
        pStr = {'sAmp','tDurOn','tDurOff','tOfs','nCount','tDur'};
        
    case 'Ramp'
        % case is a ramp
        lStr = {'Signal Start Amplitude (%)',...
                'Signal Stop Amplitude (%)',...
                sprintf('Cycle Duration (%s)',dStr),...
                sprintf('Initial Signal Offset (%s)',dStr),...
                'Signal Cycle Count',...                
                sprintf('Signal Train Duration (%s)',dStrT)};
        pStr = {'sAmp0','sAmp1','tCycle','tOfs','nCount','tDur'};
        
    case 'Triangle'
        % case is a triangle wave
        lStr = {'Signal Start Amplitude (%)',...
                'Signal Mid-Cycle Amplitude (%)',...
                sprintf('Cycle Duration (%s)',dStr),...
                sprintf('Initial Signal Offset (%s)',dStr),...
                'Signal Cycle Count',...
                sprintf('Signal Train Duration (%s)',dStrT)};
        pStr = {'sAmp0','sAmp1','tCycle','tOfs','nCount','tDur'};
        
    case 'SineWave'
        % case is a sinusoidal wave
        lStr = {'Signal Start Amplitude (%)',...
                'Signal Mid-Cycle Amplitude (%)',...
                sprintf('Cycle Duration (%s)',dStr),...
                sprintf('Initial Signal Offset (%s)',dStr),...
                'Signal Cycle Count',...
                sprintf('Signal Train Duration (%s)',dStrT)};
        pStr = {'sAmp0','sAmp1','tCycle','tOfs','nCount','tDur'};
        
    otherwise
        % case is a custom signal type     
        lStr = {'Signal Start Amplitude (%)',...
                'Maximum Amplitude (%)',...
                sprintf('Cycle Duration (%s)',dStr),...
                sprintf('Initial Signal Offset (%s)',dStr),...
                'Signal Cycle Count',...
                sprintf('Signal Train Duration (%s)',dStrT)};
        pStr = {'sAmp0','sAmp1','tCycle','tOfs','nCount','tDur'};        
        
end

% creates all the parameter objects for the current stimuli signal type
for i = 1:length(lStr)
    % sets the object dimensions
    yPos = yGap + (nParaMax-i)*(yGap+eHght);
    lPos = [x0,(yPos+dyL),lWid,lHght];
    ePos = [(x0+lWid+xGap),yPos,eWid,eHght];
    
    % sets the font colour
    if strcmp(pStr{i},'tDur')
        % case is the total signal duration
        fCol = 'r';
    else
        % case is the other parameters
        fCol = 'k';
    end
    
    % creates the label objects
    uicontrol('style','text','string',sprintf('%s: ',lStr{i}),...
        'horizontalalignment','right','position',lPos,...
        'parent',hTabS,'FontUnits','pixels','FontSize',12,...
        'FontWeight','bold','ForegroundColor',fCol,...
        'UserData',sprintf('%sL',pStr{i}));
    
    % creates the editbox object
    sParaS = num2str(eval(sprintf('sPara.%s.%s',tStr,pStr{i})));
    hEdit = uicontrol('style','edit','string',sParaS,'position',ePos,...
        'parent',hTabS,'userdata',pStr{i});
    set(hEdit,'Callback',{@editSingleStimPara,handles,dType})
    
    % creates the duration dropdown box (long-term protocol duration only)
    if strcmp(dType,'L') && any(strcmp(popupStr,pStr{i}))
        % sets the duration object position vector
        dPos = [ePos(1)-44,ePos(2)+1,32,eHght];
        
        % creates the object and sets the callback function
        hUnits = uicontrol('style','popupmenu','string',dtStr(:),...
            'position',dPos,'parent',hTabS,'value',3,...
            'UserData',sprintf('%sU',pStr{i}));
        set(hUnits,'Callback',{@popupStimTimeUnits,handles,dType})
    end
end

% --- creates the experimental protocol parameter objects
function setupExptProtoObj(handles,hTab,sPara,dType)

% initialisations
gapStr = '           ';
hFig = handles.figExptSetup;
[x0,xOfs,eWid,eHght,lHght] = deal(5,0,50,20,16);
sParaT = eval(sprintf('sPara.%s',dType));
dtStr = {'s','m','h','d'};

% sets the panel parent 
hPanelI = findobj(hFig,'tag',sprintf('panelStimInt%s',dType));
set(hPanelI,'Parent',hTab)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    STIMULI LISTBOX SETUP    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialisations
pPos = get(hPanelI,'Position');
lbPos = [x0,x0,pPos(3)-x0,50];

% creates the listbox object
lbStr = sprintf('listStimTrainEx%s',dType);
hList = uicontrol('style','listbox','max',2,'value',[],'parent',hTab,...
                  'position',lbPos,'enable','off','tag',lbStr);
set(hList,'Callback',{@listExptStimPara,handles,dType})     

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    STIMULI INTERVAL PANEL SETUP    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% updates the position of the stimuli panel within the tab group
[pPos(1),pPos(2),pPos(3)] = deal(x0,sum(lbPos([2,4]))+x0,pPos(3)-x0);
set(hPanelI,'Position',pPos)         

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    PARAMETER EDITBOX SETUP    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% sets the object dimensions
dHght = 25;
dyL = (eHght-lHght)/2;
lWid = pPos(3) - (x0+eWid+xOfs);
yPos = sum(pPos([2,4]))+x0;
lPos0 = [x0,(yPos+dyL),lWid,lHght];
ePos0 = [(x0+lWid),yPos,eWid,eHght];

% sets the object parameter/labels
pStr = {'tDur','tOfs','nCount'};
popupStr = {'tDur','tOfs'};
lStr = {sprintf('Train Duration (%s)',gapStr),...
        sprintf('Initial Signal Offset (%s)',gapStr),...
        'Stimuli Repetition Count'};        

% creates the parameter text/editbox objects
for i = 1:length(pStr)
    % recalculates the height
    [ePos,lPos] = deal(ePos0,lPos0);
    [ePos(2),lPos(2)] = deal(ePos(2)+(i-1)*dHght,lPos(2)+(i-1)*dHght);
    
    % creates the label objects    
    uicontrol('style','text','string',sprintf('%s: ',lStr{i}),...
              'horizontalalignment','right','position',lPos,...
              'parent',hTab,'FontUnits','pixels','FontSize',12,...
              'FontWeight','bold');

    % creates the editbox object
    pVal = eval(sprintf('sParaT.%s',pStr{i}));
    hEdit = uicontrol('style','edit','string',num2str(pVal),...
                      'position',ePos,'parent',hTab,'userdata',pStr{i});
    set(hEdit,'Callback',{@editExptStimPara,handles,dType})
    
    % creates the duration dropdown box (long-term protocol duration only)
    if any(strcmp(popupStr,pStr{i}))
        % sets the duration object position vector
        dPos = [ePos(1)-44,ePos(2)+1,32,eHght];
        pUnits = eval(sprintf('sParaT.%sU',pStr{i}));
        iSel = find(strcmpi(dtStr,pUnits(1)));
        
        % creates the object and sets the callback function
        hUnits = uicontrol('style','popupmenu','string',dtStr(:),...
            'position',dPos,'parent',hTab,'value',iSel,...
            'UserData',sprintf('%sU',pStr{i}));
        set(hUnits,'Callback',{@popupExptTimeUnits,handles,dType})
    end    
end

% disables all objects within the tab object
setExptProtoTabProps(hTab,'off')

% --- initialises the experimental duration object properties --- %
function initDurObjProps(handles,pStr,pStr2)

% sets the function string based on the popup string type
switch (pStr)
    case ('Dur') % case is the experiment duration
        bFunc = {@popupExptDuration,handles,pStr2};
    case ('Stim') % case is the stimulus ISI duration       
        bFunc = {@popupStimDuration,handles,pStr2};
end

% sets the variable edit box string names
objStr = {'Day','Hour','Min','Sec'};
vMax = [30,23,59,59];    

% initalises all the experimental duration object properties
for i = 1:length(objStr)
    % retrieves the edit box handle
    objStrNw = sprintf('popup%s%s',pStr,objStr{i});
    if nargin == 3; objStrNw = sprintf('%s%s',objStrNw,pStr2); end
    hObj = findobj(handles.figExptSetup,'tag',objStrNw);    
    
    % sets popup list string list
    dStr = getTimeDurationString(vMax(i));            
        
    % sets the callback function, string and value
    set(hObj,'Callback',bFunc,'UserData',i,'String',dStr)
end

% --- creates the distance line object
function hAPI = createDistLine(hAx,xL,yL)

% creates the distance line object
hDL = imdistline(hAx,xL,yL);

% sets the object properties
set(hDL,'tag','chDist','hittest','off','visible','off');

% sets the individual component properties
set(findobj(hDL,'type','Text'),'Margin',1)
setObjVisibility(findobj(hDL,'tag','top line'),'off')
set(findobj(hDL,'tag','bottom line'),'LineWidth',1,'Color','k',...
    'hittest','off')
set(findobj(hDL,'tag','end point 1'),'Marker','.','Color','k',...
    'hittest','off')
set(findobj(hDL,'tag','end point 2'),'Marker','.','Color','k',...
    'hittest','off')
set(findobj(hDL,'tag','distance label'),'FontUnits','Pixels',...
    'FontSize',11,'FontWeight','bold','hittest','off')

% returns the API object handle
hAPI = iptgetapi(hDL);

% --- runs the stimuli test marker line
function hTimer = createStimTestMarker(hFig,hObject,sTrainC)

% parameters
tPeriod = 0.1;

% deletes any previous stimuli markers
hTimerOld = timerfindall('tag','hStimMarker');
if ~isempty(hTimerOld) 
    deleteTimerObjects(hTimerOld)
end

% retrieves the stimuli train info and the timer count
nCount = ceil(sTrainC.tDur/tPeriod);

% sets up the timer object
hSigTest = findobj(get(hFig,'CurrentAxes'),'tag','hSigTest');
hTimer = timer('ExecutionMode','fixedRate','BusyMode','drop',...
    'Period',tPeriod,'TasksToExecute',nCount,'tag','hStimMarker',...
    'StartFcn',{@startTest,hSigTest},...
    'TimerFcn',{@timerTest,hObject,hSigTest},...
    'StopFcn',{@stopTest,hObject,hSigTest});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    EXPERIMENT INFORMATION OBJECT FUNCTIONS   %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- sets the experiment information fields
function setExptInfoFields(handles,devType,hasVid)

% initialisations
sdTypes = {'Opto','Motor'};
hasStim = any(cellfun(@(x)(any(strcmp(sdTypes,x))),devType));

% initialises the experiment information panel
initExptSetupProps(handles)

% initialises the experiment video parameters (if recording)
if hasVid
    % initialises the video parameter properties
    initVideoParaProps(handles)
else
    % disables the recording parameter panels
    setPanelProps(handles.panelVideoPara,'off')
    setPanelProps(handles.panelVideoRes,'off')
    setPanelProps(handles.panelFixedDur,'off')
    
    % disables the video parameter feasibility checkbox
    setObjEnable(handles.checkVidFeas,'off')
    setObjEnable(handles.textBaseName,'off')
    setObjEnable(handles.editBaseName,'off')  
    
    % removes the variable frame rate objects
    setObjVisibility(handles.editFrmRate,'off');
    setObjVisibility(handles.sliderFrmRate,'off');
    
    % disables the video count/frame text labels
    set(handles.textFrmCountL,'enable','off')
    set(handles.textFrmCount,'string','N/A','enable','off')
    set(handles.textVidCountL,'enable','off')
    set(handles.textVidCount,'string','N/A','enable','off')
end

% sets the enabled properties of the 
setObjEnable(handles.checkProtoFeas,hasStim)
setObjEnable(handles.checkStimFeas,hasStim)

% updates the recording parameters
if hasVid
    % sets the fixed duration panel properties
    calcVideoTiming(handles);
end

% updates the minimum duration fields
updateMinDurFields(handles)

% --- initialises the experimental information fields
function initExptSetupProps(handles)

% loads the program data struct
hFig = handles.figExptSetup;
iProg = getappdata(hFig,'iProg');
iExpt = getappdata(hFig,'iExpt');

% updates the output directory field and string
if (isempty(iExpt.Info.Title))
    iExpt.Info.Title = ['New Experiment (',datestr(now,'dd-mmm-yyyy'),')'];
end

% sets the file name field
if isempty(iExpt.Info.FileName)
    set(handles.textFileName,'String','N/A');
else
    set(handles.textFileName,'String',iExpt.Info.FileName);
end

% check to see if the output directory is unique
nwExptDir = fullfile(iExpt.Info.OutDir,iExpt.Info.Title);
if (exist(nwExptDir,'dir'))
    % updates the unique directory check box and experiment title colour
    isUniq = false;
    set(handles.textExptTitle,'foregroundcolor','r');
else
    % updates the unique directory check box and experiment title colour
    isUniq = true;
    set(handles.textExptTitle,'foregroundcolor','k');        
end 

% updates the unique directory flag
updateFeasFlag(handles,'checkUniqDir',isUniq)

% sets the editbox strings
set(handles.editExptTitle,'string',['  ',iExpt.Info.Title],...
                          'tooltipstring',iExpt.Info.Title);
set(handles.editBaseName,'string',['  ',iExpt.Info.BaseName],...
                          'tooltipstring',iExpt.Info.BaseName);

% updates the unique directory feasibility flag                      
updateFeasFlag(handles,'checkUniqDir',true)    

% updates the output directory field and string
if isempty(iProg)
    iExpt.Info.OutDir = pwd;
else
    iExpt.Info.OutDir = iProg.DirMov;
end

% updates the output directory properties
set(handles.editOutDir,'string',['  ',iExpt.Info.OutDir],...
                        'tooltipstring',iExpt.Info.OutDir);
set(handles.buttonOutDir,'tooltipstring',iExpt.Info.OutDir);    

% updates the experimental protocol data struct
setappdata(hFig,'iExpt',iExpt);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    VIDEO RECORDING PANEL INITIALISATIONS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- initialises the experimental information fields
function initVideoParaProps(handles)

% global variables
global isUpdate
isUpdate0 = isUpdate;

% retrieves the experimental duration data struct
hFig = handles.figExptSetup;
iExpt = getappdata(hFig,'iExpt');
infoObj = getappdata(hFig,'infoObj');
hPopup = handles.popupFrmRate;
hSlider = handles.sliderFrmRate;
hEdit = handles.editFrmRate;

% other initialisations
Dmax = iExpt.Video.Dmax;

% sets the frame rate box
if infoObj.hasIMAQ
    % retrieves the camera frame rate
    FPS = iExpt.Video.FPS;
    if infoObj.isWebCam
        % sets the frame rate values/selections
        isVarFPS = false;
        [~,fRate,~] = detWebcamFrameRate(infoObj.objIMAQ,FPS);
    else
        % sets the frame rate values/selections
        isVarFPS = detIfFrameRateVariable(infoObj.objIMAQ);
        srcObj = getselectedsource(infoObj.objIMAQ);
        [~,fRate,~] = detCameraFrameRate(srcObj,FPS);
    end
        
    % sets up the camera frame rate objects
%     isVarFPS = true;
    if isVarFPS
        % case is a variable frame rate camera
        initFrameRateSlider(hSlider,srcObj,iExpt.Video.FPS)
        sliderFrmRate_Callback(hSlider, [], handles) 
        setObjVisibility(hPopup,'off')
    else
        % case is a fixed frame rate camera
        iSel = find(strcmp(fRate,num2str(iExpt.Video.FPS)));
        if isempty(iSel)
            % if there are no matches, use the first value instead
            set(hPopup,'string',fRate,'value',1)
            
            % resets the field within the experimental data struct
            iExpt.Video.FPS = str2double(fRate{1});
            setappdata(hFig,'iExpt',iExpt)
        else
            set(hPopup,'string',fRate,'value',iSel)
        end
        
        % runs the frame rate popup callback function
        popupFrmRate_Callback(hPopup, [], handles)
    end

    % initalises the hour string
    [a,b] = deal(num2cell(0:9)',num2cell(10:12)');
    hourStr = [cellfun(@(x)(sprintf('0%i',x)),a,'un',false);
               cellfun(@num2str,b,'un',false)];
    set(handles.popupVidHour,'String',hourStr,'Value',...
                              Dmax(1)+1,'UserData',1);

    % initalises the minute string
    [a,b] = deal(num2cell(0:9)',num2cell(10:59)');
    msStr = [cellfun(@(x)(sprintf('0%i',x)),a,'un',false);
              cellfun(@num2str,b,'un',false)];
    set(handles.popupVidMin,'String',msStr,'Value',Dmax(2)+1,'UserData',2);
    set(handles.popupVidSec,'String',msStr,'Value',Dmax(3)+1,'UserData',3);

    % initalises all the start time popup object properties
    for i = 1:3
        % retrieves the popup menu handle
        hObj = findobj(handles.panelVideoPara,'Style',...
                                        'popupmenu','UserData',i);

        % sets the callback function
        set(hObj,'Callback',{@popupVideoDuration,handles})
    end

    % updates the video duration
    isUpdate = false;
    popupVideoDuration(handles.popupVidHour, '1', handles, 1)
    isUpdate = isUpdate0;

    % % disables the fixed duration panel
    % setAllVideoProps(handles,'off')

    % sets up the video compression popup menu
    hPopup = handles.popupVideoCompression;
    setupVideoCompressionPopup(infoObj.objIMAQ,hPopup)
    ii = strcmp(getappdata(hPopup,'pStr'),iExpt.Video.vCompress);

    % sets the popup menu value
    if ~any(ii)
        set(hPopup,'value',1);
    else
        set(hPopup,'value',find(ii));
    end        
    
    % sets the object visibility flags
    setObjVisibility(hEdit,isVarFPS)
    setObjVisibility(hSlider,isVarFPS)    
else
    % retrieves the frame rate and set the object visibility flags 
    iExpt.Video.FPS = NaN; 
    setObjVisibility(hEdit,0)
    setObjVisibility(hSlider,0)       
end

% updates the video data struct
setappdata(hFig,'iExpt',iExpt)

% --- sets the save/run menu item enabled properties --- %
function updateFeasFlag(handles,pStrChk,chkVal)

% initialisations
hFig = handles.figExptSetup;

% updates the feasibility flag to the new check value
set(eval(sprintf('handles.%s',pStrChk)),'Value',chkVal)

% sets the feasibility flag
if any(strcmp(getappdata(hFig,'devType'),'RecordOnly'))
    % case is a recording only experiment
    isFeas = get(handles.checkUniqDir,'Value') && ...
             get(handles.checkDurFeas,'Value') && ...
             get(handles.checkStartFeas,'Value') && ...
             get(handles.checkVidFeas,'Value');        
else
    % case is a stimuli based experiment
    isFeas = get(handles.checkUniqDir,'Value') && ...
             get(handles.checkDurFeas,'Value') && ...
             get(handles.checkStartFeas,'Value') && ... 
             get(handles.checkVidFeas,'Value') && ...
             get(handles.checkProtoFeas,'Value') && ...
             get(handles.checkStimFeas,'Value');            
end
     
% sets the enabled strings (based on the feasibility)
setObjEnable(handles.menuSaveProto,isFeas)
setObjEnable(handles.buttonSaveProto,isFeas)
setObjEnable(handles.menuStartExpt,isFeas)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    STIMULI SIGNAL OBJECT FUNCTIONS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- creates a signal stimuli object
function createSignalObject(hFig,uData,rPos,resetLimits,addOffset)

% global variables
global chCol hSigTmp mpStrDef nProto

% sets the default input values
if nargin < 2
    uData = get(hSigTmp,'UserData');
    rPos = hSigTmp.getPosition();
    resetLimits = true;
end

% sets the add offset flag
if nargin < 5
    addOffset = false;
end

% retrieves the important data arrays/structs
hAx = get(hFig,'CurrentAxes');
iProto = getProtocolIndex(hFig);
sigBlk = getappdata(hFig,'sigBlk');
sPara = uData{indFcn('sPara')};

% retrieves the important fields from the user data array
iCh = uData{indFcn('iCh')};
[sParaS,sType] = deal(uData{indFcn('sPara')},uData{indFcn('sType')});

% retrieves the signal parameter struct (based on stimuli protocol type)
if iProto(nProto-1)
    sParaP = getappdata(hFig,'sParaL');
else
    sParaP = getappdata(hFig,'sParaS');
end

% retrieves the stimuli signal and converts to the axis coordinates
tMlt = getTimeMultiplier(sParaP.tDurU,sParaS.tDurU);
[xS,yS] = setupScaledStimuliSignal(hAx,sParaS,iCh,sType,1);
xS = xS*tMlt;
if addOffset; xS = xS + rPos(1); end

% turns the axis hold on
hold(hAx,'on');

% creates the new signal object
if detIfUsePatch(hAx,xS,yS)
    % if there are not too many cycle counts, then use a patch
    hSigObj = patch(hAx,xS([1:end,1]),yS([1:end,1]),chCol{iCh},...
                    'linewidth',1,'FaceAlpha',0.2,'EdgeColor',chCol{iCh});
else
    % otherwise, draw the signal using a line
    hSigObj = plot(hAx,xS([1:end,1]),yS([1:end,1]));
    set(hSigObj,'Color',chCol{iCh})
end

% turns the axis hold off
hold(hAx,'off');

% makes the distance line markers visible
hDL = getappdata(hFig,'hDL');
hDLnw = hDL{getProtocolIndex(hFig)}(iCh,[1,3]);

% creates the line object
rPos(1) = sPara.tOfs*tMlt;
iBlkNw = max(getSignalBlockIndices(sigBlk{iProto}{iCh}))+1;
uData = [uData,{xS(1)-rPos(1),iBlkNw,hDLnw,hSigObj}];

% creates the imrect object
hSigBlk = createSignalRectObj(hFig,uData,rPos,1);
set(hSigBlk,'tag','hSigBlk');

% resets the patch properties of the new signal block
hSigPatch = findobj(hSigBlk,'tag','patch');
set(hSigPatch,'LineWidth',3,'EdgeColor','k','FaceAlpha',0.01,...
              'LineStyle','none')

% updates the signal block data array
sigBlk{iProto}{iCh}{end+1} = hSigBlk;
setappdata(hFig,'sigBlk',sigBlk)

% enables the use minimum signal duration button
setObjEnable(getProtoObj(hFig,'buttonUseMinSig'),'on')

% resets the signal block time limits (if required)
if resetLimits
    resetSignalBlockTimeLimits(hFig,hSigBlk);
end

% removes the signal API and resets the mouse pointer
if ~isempty(hSigTmp)
    turnOffFillObj(hFig,true)
    mpStrDef = 'arrow';
end

% --- creates an experiment stimuli train object
function hSigBlk = createExptObject(hFig,uData0,rPos,resetLimits,...
                                    addTrain,showHighlight)

% global variables
global chCol hSigTmp mpStrDef nProto

% sets the default input values
if nargin < 5; addTrain = true; end
if nargin < 6; showHighlight = true; end
if nargin < 2
    uData0 = get(hSigTmp,'UserData');
    rPos = hSigTmp.getPosition();
    resetLimits = true;
end

% object handle/data field retrieval
hAx = get(hFig,'CurrentAxes');
iExpt = getappdata(hFig,'iExpt');
sigBlk = getappdata(hFig,'sigBlk');
sParaEx = getappdata(hFig,'sParaEx');
sTrain = getappdata(hFig,'sTrain');

% retrieves the important fields from the user data array
iCh = uData0{indFcn('iCh')};
[sTrainS,sType] = deal(uData0{indFcn('sPara')},uData0{indFcn('sType')});

% retrieves the full experiment signal
sPara = uData0{indFcn('sPara')};
sParaExP = getStructField(sParaEx,sType(1));
xyData = setupFullExptSignal(hFig,sTrainS,sParaExP);
iChObj = find(~cellfun('isempty',xyData));

% memory allocation for the signal offset/object handles
[nChObj,nChTot] = deal(length(iChObj),length(sTrainS.chName));
[dX,hSigObj] = deal(zeros(nChObj,1));

% turns the axis hold on
hold(hAx,'on');

% creates the new signal object
for i = 1:length(iChObj)
    % sets the actual channel index
    iChNw = iChObj(i);
    j = (nChTot+1) - iChNw;
    
    % appends on the start location of the group
    dX(i) = xyData{iChNw}(1,1);
    xS = xyData{iChNw}(:,1)+rPos(1);
    yS = xyData{iChNw}(:,2); 
    
    if detIfUsePatch(hAx,xS,yS)
        hSigObj(i) = patch(hAx,xS,yS,chCol{j},'FaceAlpha',0.2,...
                           'EdgeColor',chCol{j},'LineWidth',1);        
    else
        hSigObj(i) = plot(hAx,xS([1:end,1]),yS([1:end,1]));
        set(hSigObj(i),'Color',chCol{j});                      
    end
end

% turns the axis hold off
hold(hAx,'off');

% makes the distance line markers visible
hDL = getappdata(hFig,'hDL');
hDLnw = hDL{getProtocolIndex(hFig)}(iCh(1),[1,3]);

% retrieves the parameter struct
sParaExObj = eval(sprintf('sParaEx.%s',sType(1)));
if nargout == 0
    % sets the stimuli object name (if not being set elsewhere)
    sParaExObj.sName = getFeasBlockName(sigBlk{nProto});
    iBlkNw = max(getSignalBlockIndices(sigBlk{nProto}))+1;
else
    iBlkNw = NaN;
end

% appends the experiment stimuli train information for the new stimuli
if addTrain
    addExptStimTrainInfo(hFig,sTrainS,sParaExObj,sParaEx);
end

% creates the line object
uData = [uData0,{dX,iBlkNw,hDLnw,hSigObj,sParaExObj}];

% creates the imrect object
hSigBlk = createSignalRectObj(hFig,uData,rPos,2);
set(hSigBlk,'tag','hSigBlk');

% resets the patch properties of the new signal block
hSigPatch = findobj(hSigBlk,'tag','patch');
set(hSigPatch,'LineWidth',3,'EdgeColor','k','FaceAlpha',0.01,...
              'LineStyle','None')

% updates the signal block data array
if nargout == 0
    % creates the new and stores the new experiment stimuli object handle
    sigBlk{nProto}{end+1} = hSigBlk;
    setappdata(hFig,'sigBlk',sigBlk)

    % sets the listbox strings
    hListT = getProtoObj(hFig,'listStimTrain');
    uData0 = cellfun(@(x)(get(x,'UserData')),sigBlk{nProto},'un',0);
    sName = cellfun(@(x)(x{indFcn('sParaEx')}.sName),uData0(:),'un',0);
    set(hListT,'String',sName(:),'Value',length(sName),...
               'Max',1,'Enable','on')
end

% enables the clear all signals button
setObjEnable(getProtoObj(hFig,'buttonClearAll'),'on')

% resets the signal block time limits (if required)
if resetLimits; resetSignalBlockTimeLimits(hFig,hSigBlk); end

% updates the experiment block selection
if showHighlight; updateExptBlockSelection(hFig,hSigBlk); end
setObjEnable(getProtoObj(hFig,'buttonUseMinSig'),'on')

% removes the signal API and resets the mouse pointer
if ~isempty(hSigTmp)
    turnOffFillObj(hFig,true)
    mpStrDef = 'arrow';
end

% --- adds the new stimuli train information to the experiment data struct 
function addExptStimTrainInfo(hFig,sTrainS,sPara,sParaEx)

% initialisations
sTrain = getappdata(hFig,'sTrain');

% retrieves the selected experiment protocol stimuli type
hTabG = getappdata(hFig,'hTabGrpEx');
sType = get(get(hTabG,'SelectedTab'),'Title');

% initialises/updates the train fields
if isempty(sTrain.Ex)
    % initialises the struct
    sTrain.Ex = struct('sName',[],'sType',[],...
                       'sParaEx',sPara,'sTrain',sTrainS); 
                         
    % sets the name/type fields
    sTrain.Ex.sName = {sTrainS.sName};
    sTrain.Ex.sType = {sType};
    
else
    % updates the name, experiment and signal parameters
    sTrain.Ex.sName{end+1} = sTrainS.sName;
    sTrain.Ex.sType{end+1} = sType;
    sTrain.Ex.sParaEx(end+1) = sPara;
    sTrain.Ex.sTrain(end+1) = sTrainS;
    
end

% updates the macro experiment parameters
pFld = fieldnames(sParaEx);
for i = 1:length(pFld)
    nwVal = eval(sprintf('sParaEx.%s',pFld{i}));
    if ~isstruct(nwVal)
        % only add non-struct fields
        eval(sprintf('sTrain.Ex.%s = nwVal;',pFld{i}));
    end
end

% updates the train information struct
setappdata(hFig,'sTrain',sTrain);

% --- determines the next feasible experimental stimuli block name
function blkStr = getFeasBlockName(sigBlk)

% deterines if there are any experimental stimuli blocks present
if isempty(sigBlk)
    % no other blocks are present
    iBlk = 1;
else
    % one or more blocks are present
    
    % retrieves the existing train names
    uData = cellfun(@(x)(get(x,'UserData')),sigBlk,'un',0);
    sName = cellfun(@(x)(x{indFcn('sParaEx')}.sName),uData(:),'un',0);
    
    % retrieves the index of the next valid box
    iMatch = cellfun(@(x)(...
                 regexp(x,'Stimuli Train #','split')),sName(:),'un',0);
    iBlk = max(cellfun(@(x)(str2double(x{2})),iMatch)) + 1;
end

% returns the new block name string 
blkStr = sprintf('Stimuli Train #%i',iBlk);

% --- creates a signal object patch for the channel index, iCh
function createTempSignalObject(hFig,iCh)

% global variables
global yGap hSigTmp mType

% retrieves the protocol type and associated axes handle
hAx = get(hFig,'CurrentAxes');

pType = getappdata(hFig,'pType');
sType = getappdata(hFig,'sType');

% retrieves the current mouse location
mPos = get(hAx,'CurrentPoint');

switch pType
    case 'Experiment Stimuli Protocol'
        % retrieves the stimuli train object for selected item
        sTrainS = getSelectedSignalTrainInfo(hFig);         
        
        % determines the 
        cOfs = 1 + length(sTrainS.chName);
        chName = field2cell(sTrainS.blkInfo,'chName');
        iChS = cellfun(@(x)(cOfs-find(strcmp(sTrainS.chName,x))),chName);        
        
        % if the user is not within the required block range then exit
        [iChMin,iChMax] = deal(min(iChS),max(iChS));
        if iCh > iChMax || iCh < iChMin
            mType = 1;
            return
        end
        
        % makes the fill object invisible
        setObjVisibility(findobj(hAx,'tag','chFill'),'off');
        
        % retrieves parameter information for the current protocol/signal
        iExpt = getappdata(hFig,'iExpt');
        sPara = getProtocolParaInfo(hFig,pType);   
        tDurFull = vec2time(iExpt.Timing.Texp,iExpt.Timing.TexpU);                                    
        
        % determines the overall duration of the full stimuli protocol
        tDurStim = calcExptStimDuration(hFig,sTrainS,sPara);                
        
        % retrieves the stimuli block storage array for the current channel
        sBlk = getSignalBlock(hFig,iCh);  
        sbLim = getValidExptBlockLimits(sBlk,mPos(1,1),tDurFull);
        
        % sets the initial location of the object
        mPos = get(hAx,'CurrentPoint');
        if mPos(1,1) < tDurStim/2
            % case is the patch is too close to the start of the stimuli
            x0 = 0;
        elseif mPos(1,1) > (tDurFull - tDurStim/2)
            % case is the patch is too close to the stimuli end
            x0 = roundP(tDurFull - tDurStim,0.01);
        else
            % case is the mouse is far from the stimuli edges
            x0 = roundP(mPos(1,1) - tDurStim/2,0.01);
        end        
        
        %
        iChMin = min(iChS);
        sbLim = [max(sbLim(iChS,1)),min(sbLim(iChS,2))];
        
        % sets up the position/userdata for the imrect object        
        rPos = [x0,((iChMin-1)+yGap),tDurStim,(range(iChS)+1)-yGap];
        uData = setupUserDataArray(hFig,sbLim,sTrainS,sType,[iChMin,iChMax]);
        
        % creates the imrect object
        hSigTmp = createSignalRectObj(hFig,uData,rPos,0);  
        mType = 4;
        
    otherwise % case is the short/long-term protocols
        
        % retrieves parameter information for the current protocol/signal
        sPara = getProtocolParaInfo(hFig,pType);
        sParaS = getSignalParaInfo(sPara,sType);
        
        % retrieves the stimuli block storage array for the current channel
        sigBlk = getappdata(hFig,'sigBlk');
        sBlk = sigBlk{getProtocolIndex(hFig)}{iCh};
        
        % determines the stimuli block limits
        sbLim = getValidStimBlockLimits(hFig,sBlk,mPos(1,1),sPara.tDur);
        
        % sets the initial location of the object        
        if mPos(1,1) < sParaS.tDur/2
            % case is the patch is too close to the start of the stimuli
            x0 = 0;
        elseif mPos(1,1) > (sPara.tDur-sParaS.tDur/2)
            % case is the patch is too close to the stimuli end
            x0 = roundP(sPara.tDur - sParaS.tDur,0.01);
        else
            % case is the mouse is far from the stimuli edges
            x0 = roundP(mPos(1,1) - sParaS.tDur/2,0.01);
        end
        
        % sets up the position/userdata for the imrect object
        tMlt = getTimeMultiplier(sPara.tDurU,sParaS.tDurU);
        rPos = [tMlt*x0,((iCh-1)+yGap),tMlt*sParaS.tDur,1-yGap];
        uData = setupUserDataArray(hFig,sbLim,sParaS,sType,iCh);
        
        % creates the imrect object
        hSigTmp = createSignalRectObj(hFig,uData,rPos,0);
end

% --- creates the signal imrect object
function hSig = createSignalRectObj(hFig,uData,rPos,rType)

% global variables
global yGap

% initialisations
[tLim,iCh] = deal(uData{indFcn('tLim')},uData{indFcn('iCh')});

% creates the imrect object
hAx = get(hFig,'CurrentAxes');
hRect = imrect(hAx,rPos);

% updates the time offset box
% uData = updateTimeOffset(hFig,uData);
uData = updateTimeOffset(hFig,uData,rPos(1));

% resets the object properties of the imrect object
set(findobj(hRect),'uicontextmenu',[])
setObjVisibility(findobj(hRect,'type','Line'),'off')
set(findobj(hRect,'type','Patch'),'EdgeColor','k','FaceColor',0.8*[1,1,1])

% sets the constraint/movement callback functions
switch rType
    case 0
        hRect.addNewPositionCallback(@(p)moveTempSignalObj(p,hFig));
    case 1    
        hRect.addNewPositionCallback(@(p)moveSignalObj(p,hFig));
    case 2
        hRect.addNewPositionCallback(@(p)moveExptObj(p));
end

% creates the constraint function
yL = [((iCh(1)-1)+yGap),iCh(end)];

% creates the api object and sets the userdata and contraint function
hSig = iptgetapi(hRect);
set(hSig,'UserData',uData);
hSig.setPositionConstraintFcn(makeConstrainToRectFcn('imrect',tLim,yL))

% --- updates the time offset editbox value
function uData = updateTimeOffset(hFig,uData,tOfs)

% updates the editbox values
[hObjOfs,sPara,sType] = deal(uData{indFcn('hObjOfs')},...
                uData{indFcn('sPara')},uData{indFcn('sType')});            

% retrieves the parameter string
dType = getProtoTypeStr(getappdata(hFig,'pType'));
sParaStr = sprintf('sPara%s',dType);
sParaF = getappdata(hFig,sParaStr);

% updates the parameter struct with the new parameter (protocol dependent)
if strcmp(dType,'Ex')
    % case is for experiment info blocks
    iExpt = getappdata(hFig,'iExpt');
    sType = getStimuliTypeString(hFig,'Ex');    
    
    %
    tOfsU = lower(eval(sprintf('sParaF.%s.tOfsU(1)',sType(1))));
    tOfsNw = tOfs/getTimeMultiplier(iExpt.Timing.TexpU,tOfsU);
    
    % updates the time offset into the parameter struct
    eval(sprintf('sParaF.%s.tOfs=tOfsNw;',sType(1)))
    
%     %
%     iParaEx = indFcn('sParaEx');
%     if length(uData) >= iParaEx
%         uData{iParaEx} = eval(sprintf('sParaF.%s',sType(1)));
%     end
    
else
    % case is for short/long-term stimuli blocks
    if nargin < 3; tOfs = sPara.tOfs; end
    tMlt0 = getTimeMultiplier(sParaF.tDurU,sPara.tDurU);
    tOfsNw = tOfs*getTimeMultiplier(sPara.tOfsU,sPara.tDurU)/tMlt0;   
    
    % updates the parameter struct
    eval('sPara.tOfs=tOfsNw;')
    eval(sprintf('sParaF.%s = sPara;',sType))
end

% updates the editbox with the new value
set(hObjOfs{1},'String',getEditResetString(tOfsNw))
setObjEnable(hObjOfs{2},'on')

% updates the parameters field for the userdata array
uData{indFcn('sPara')} = sPara;

% updates the parameter struct into the gui
setappdata(hFig,sParaStr,sParaF)

% --- makrs all the channel fill objects invisible
function turnOffFillObj(hFig,forceUpdate)

% global variables
global objOff mType hSigTmp hSigSel
if nargin == 1; forceUpdate = false; end
if (~forceUpdate && objOff); return; end

% flag that all objects are invisible
objOff = true;

% if setting the signal object patch, then delete the patch and
% reset the mouse-type flag
if ~isempty(hSigTmp)
    delete(hSigTmp)
    hSigTmp = [];
    
    if ~forceUpdate
        mType = 1;
    end
end

% makes all the fill objects/distance markers off
hAx = get(hFig,'CurrentAxes');
setObjVisibility(findobj(hAx,'tag','chDist'),'off');
setObjVisibility(findobj(hAx,'tag','chFill'),'off');
setappdata(hFig,'iCh',-1)

% turns off any signal block highlights (if no blocks are selected)
if isempty(hSigSel)
    setSignalBlockHightlight(hFig,'off')
end

% --- sets the signal block highlights
function setSignalBlockHightlight(hObj,bState)

% global variables
global iSigObj nProto

% sets the block highlight based on the value of bState
switch bState
    case 'on' % case is turning on the highlights
        
        % determines if a block has already been highlighted
        uData = get(hObj,'UserData');
        if iSigObj > 0
            % if so, then determine if the block highlighted corresponds to
            % the one currently being hovered over
            if uData{indFcn('iBlk')} ~= iSigObj
                % if not, then reset the block highlights
                setSignalBlockHightlight(gcf,'off')
                iSigObj = uData{indFcn('iBlk')};
            end
        else
            % otherwise, set the current block to be the highlighted block            
            iSigObj = uData{indFcn('iBlk')};
        end
        
        % sets the signal block highlights
        hP = findobj(hObj,'tag','patch');
        set(hP,'LineStyle','-')
        
    case 'off' % case is turning off the highlights
        
        % resets the signal block index to zero (no object highlighted)
        iSigObj = 0;
        
        % retrieves the signal block handles
        iProto = getProtocolIndex(hObj);
        sigBlk = getappdata(hObj,'sigBlk');
        
        hSB = sigBlk{iProto};
        if ~iProto(nProto)
            hSB = cell2cell(hSB);
        end
        
        if ~isempty(hSB)
            % if there are signal blocks, turn off their highlights
            hP = cellfun(@(x)(findobj(x,'tag','patch')),hSB,'un',0);

            % resets the properties of the patches
            cellfun(@(x)(set(x,'LineStyle','none')),hP)
        end
end

% --- retrieves the stimuli positions
function sPos = getStimBlockPositions(sBlk)

% retrieves the positions of the stimuli blocks
sPos = cell2mat(cellfun(@(x)(x.getPosition()),sBlk,'un',0)');

% sorts the positions by the left positions of the stimuli blocks
[~,iSort] = sort(sPos(:,1));
sPos = sPos(iSort,:);

% --- determines the valid time range for the stimuli blocks for a given
%     channel and mouse x-position, mX
function sbLim = getValidStimBlockLimits(hFig,sBlk,mX,tDur,iBlk)

% ensures the signal block is stored in a cell array
if ~iscell(sBlk) && ~isempty(sBlk); sBlk = {sBlk}; end

% converts a time vector to a single value
if length(tDur) == 4    
    iExpt = getappdata(hFig,'iExpt');
    [tDur0,tDurU] = vec2time(tDur);
    tDur = tDur0*getTimeMultiplier(iExpt.Timing.TexpU,tDurU(1));
end

%
if nargin == 5
    % retrieves the 
    indCh = indFcn('iCh');
    uData = cell2cell(cellfun(@(x)(get(x,'UserData')),sBlk,'un',0));
    
    ii = (1:length(sBlk))~=iBlk;
    [uDataB,uDataC] = deal(uData{~ii,indCh},uData(ii,indCh));
    
    jj = find(ii(:));
    indB = uDataB(1):uDataB(end);
    hasCh = cellfun(@(x)(any(intersect(x(1):x(end),indB))),uDataC);
    sBlk = sBlk(sort([iBlk;jj(hasCh)]));
end

% if the position value is an array, then calculate lower/upper limits
if length(mX) == 4
    % calculates the lower/upper limits
    tLo = getValidStimBlockLimits(hFig,sBlk,mX(1),tDur);
    tHi = getValidStimBlockLimits(hFig,sBlk,mX(1)+mX(3)/2,tDur);
    sbLim = [tLo(1),tHi(2)];
    
    % exits the function
    return
end

% determines if there are any valid stimuli blocks
if isempty(sBlk)
    % if not, then set the full stimuli channel range
    sbLim = [0,tDur];
else
    % otherwise, retrieves the position of the existing signal blocks
    sPos = getStimBlockPositions(sBlk);
    
    % determines which signal block that the mouse is to the left of
    iLeft = find(mX <= sPos(:,1),1,'first');
    if isempty(iLeft)
        % case is the mouse is after the last signal block
        sbLim = roundP([sum(sPos(end,[1,3])),tDur],0.01);
    elseif iLeft == 1
        % case is the mouseis before the first signal block
        sbLim = roundP([0,sPos(1,1)],0.01);
    else
        % case is the mouse is between existing signal blocks
        sbLim = roundP([sum(sPos(iLeft-1,[1,3])),sPos(iLeft,1)],0.01);
    end
end

% --- determines the valid time range for the stimuli blocks for a given
%     stimuli block and mouse x-position, mX
function sbLim = getValidExptBlockLimits(sBlk,mX,tDur)

% global variables
global chCol
nCh = length(chCol);

% converts a time vector to a single value
if length(tDur) == 4
    tDur = vec2time(tDur);    
end

% if not, then set the full stimuli channel range
sbLim = repmat([0,tDur],nCh,1);

% determines if there are any valid stimuli blocks
if ~isempty(sBlk)
    % retrieves the positions of the existing blocks
    sPos = getStimBlockPositions(sBlk);
    chLim = cell(nCh,1);
    
    % retrieves the lower/upper limits 
    for i = 1:size(sPos,1)           
        xL = [sPos(i,1),sum(sPos(i,[1,3]))];
        ii = ceil(sPos(i,2)):sum(sPos(i,[2,4]));
        for j = 1:length(ii)
            chLim{ii(j)} = [chLim{ii(j)};xL];
        end
    end
    
    % sorts the limits for each channel in chronological order (if there is
    % more than one object for that row)
    for i = 1:nCh
        %
        if ~isempty(chLim{i})
            if size(chLim{i},1) > 1
                [~,iSort] = sort(chLim{i}(:,1));
                chLim{i} = chLim{i}(iSort,:);
            end

            %        
            iLeft = find(mX <= chLim{i}(:,1),1,'first');
            if isempty(iLeft)
                % case is the mouse is after the last signal block
                sbLim(i,:) = [chLim{i}(end,2),tDur];
            elseif iLeft == 1
                % case is the mouseis before the first signal block
                sbLim(i,:) = [0,chLim{i}(1,1)];
            else
                % case is the mouse is between existing signal blocks
                sbLim(i,:) = [chLim{i}(iLeft-1,2),chLim{i}(iLeft,1)];
            end
        end
    end
end

% --- deletes the current signal block
function deleteSignalBlock(hSigBlk)

% only delete the block if it is still valid
if isvalid(hSigBlk)
    % retrieves the signal block object userdata array
    uData = get(hSigBlk,'UserData');

    % deletes the signal and block objects
    hSigObj = uData{indFcn('hSigObj')};
    if iscell(hSigObj)
        cellfun(@delete,hSigObj)
    else
        delete(hSigObj)
    end
        
    delete(hSigBlk)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    SIGNAL DURATION FUNCTIONS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- checks whether the signal durations are less than the max duration
function [ok,tDurMin] = checkSignalDur(hFig,sPara,sParaD)

% global variables
global hSigSel

% initialisations
[ok,eType] = deal(1,0);
tDurMlt = getTimeMultiplier(sPara.tDurU,sParaD.tDurU);
tOfs = sPara.tOfs*getTimeMultiplier(sPara.tDurU,sPara.tOfsU);
tDur = sParaD.tDur*tDurMlt;

if isempty(hSigSel)
    % if no stimuli blocks are selected, the use the full stimuli train
    % duration to determine feasibility
    [tUpper,addStr] = deal(tDur,'');
else
    
    % retrieves signal block for the currently selected channel
    uData = get(hSigSel,'UserData');
    sigBlk = getappdata(hFig,'sigBlk');
    sBlkCh = sigBlk{getProtocolIndex(hFig)}{uData{indFcn('iCh')}(1)};
    
    % otherwise, use the limits of the selected stimuli block to determine
    % if the duration is feasible
    sPos = hSigSel.getPosition();
    tLimLo = getValidStimBlockLimits(hFig,sBlkCh,sPos(1),tDur);
    tLimHi = getValidStimBlockLimits(hFig,sBlkCh,sPos(1)+sPos(3)/2,tDur);
    tUpper = tLimHi(2);
    
    % initial point within an existing block
    if (tOfs < tLimLo(1))
        [ok,eType] = deal(0,1);
    end
    
    % sets the additional string to the error message
    addStr = sprintf(['\n * De-select the currently selected',...
                      'stimuli signal object']);    
end

% determines if the duration of the stimuli train if feasible
if ok > 0 
    ok = double((sPara.tDur <= (tUpper - tOfs)));
    eType = 2;
end

% determines if the signal duration exceeds the max duration
tDurMin = (sPara.tDur + tOfs)/tDurMlt;
if ok == 0
    % initialisations
    tDurU = sPara.tDurU;
    tStr = 'Infeasible Signal Parameters';
    
    switch eType
        case 1
            % case is the signal offset is less than the lower limit
            eStr = sprintf(['The signal offset (%.2f%s) lies ',...
                'an existing signal block. Re-select another value ',...
                'which is feasible.'],tOfs,tDurU);
            waitfor(msgbox(eStr,tStr,'modal'))
            
        case 2
            % case is the upper time exceeds the total signal duration
            eStr = sprintf(['The signal offset (%.2f%s) and signal ',...
                'duration (%.2f%s) must be less than the stimuli upper ',...
                'time limit (%.2f%s). To overcome this issue either:\n\n',...
                ' * Reduce the "Signal Cycle Count"\n',...
                ' * Alter the "Initial Signal Offset"\n',...
                ' * Reset the parameters by selecting "Restore ',...
                'Default Parameters"%s'],...
                tOfs,tDurU,sPara.tDur,tDurU,tUpper,tDurU,addStr);
                        
            % adds in the question part of the message
            eStr = sprintf(['%s\n\nAlternatively, would you like to ',...
                'expand the Total Signal Duration to match the new ',...
                'configuration?'],eStr);
            
            % prompts the user if they wish to reset the parameter, or
            % expand the total signal duration
            uChoice = questdlg(eStr,tStr,'Reset Parameter',...
                                'Expand Duration','Reset Parameter');
            ok = 2*double(strcmp(uChoice,'Expand Duration'));
    end    
end

% --- determines if the stimuli 
function [ok,tDurMin] = checkExptStimTrainDur(hFig,sPara)

% global variables
global hSigSel

% initalisations
[ok,tDurMin] = deal(1,NaN);
sType = getappdata(hFig,'sType');
iExpt = getappdata(hFig,'iExpt');
hPanelP = getProtoObj(hFig,'panelStimInt',sType(1));

% calculates the stimuli/full experiment durations
sTrainS = getSelectedSignalTrainInfo(hFig);
tDurStim = calcExptStimDuration(hFig,sTrainS,sPara);
tDurFull = vec2time(iExpt.Timing.Texp,iExpt.Timing.TexpU);
tMltDur = getTimeMultiplier('s',iExpt.Timing.TexpU);

% retrieves the signal parameter struct
tOfs = getExptTimeOffset(hFig);

% determines if the stimuli train block duration is less than stimuli block
% duration (only if there are repetitions of the stimuli block)
nCount = eval(sprintf('sPara.%s.nCount',sType(1)));
if nCount > 1
    % calcuates the stimuli train block duration
    tDurBlk = calcMaxStimTrainDur(sTrainS);
    
    % determines if the stimuli offset is ok
    if tDurBlk > vec2sec(getPopupDurValues(hPanelP))
        % if the stimuli train duration is less than the repetition 
        % duration then output an error to screen
        [~,~,Ts] = calcTimeDifference(sec2vec(tDurBlk),[0,0,0,0]);
        eStr = sprintf(['The stimuli repetition offset must be at ',... 
                        'least (%s:%s:%s:%s)'],Ts{1},Ts{2},Ts{3},Ts{4});

        % output the error to screen
        waitfor(msgbox(eStr,'Invalid Stimuli Offset Duration','modal'))
        ok = 0;
        return
    end    
end

% % initialisations
% 
% tDurMax = calcMaxStimTrainDur(sTrainC);
% 
% % if the duration of the stimuli offset time is less than the current
% % stimuli block, then update the offset
% if tDurMax > vec2sec(getPopupDurValues(hPanelP))
%     % updates the duration popup values
%     tStimNw = sec2vec(tDurMax);
%     setDurPopupValues(hPanelP,tStimNw)
%     
%     % updates the experimental stimuli offset time vector
%     sParaEx = getappdata(hFig,'sParaEx');
%     eval(sprintf('sParaEx.%s.tStim = tStimNw;',dType));
%     setappdata(hFig,'sParaEx',sParaEx)
% end

% tDurMinS = tMltDur*(tOfs+tDurStim);
tDurMinS = tMltDur*tDurStim;
tDurMinTot = tMltDur*(tDurStim+tOfs);
tDurMin = {sec2vec(ceil(tDurMinS)),sec2vec(ceil(tDurMinTot))};

%
if ~isempty(hSigSel)   
%     % case is there are no stimuli blocks placed
%     tLimF = checkExptBlockPlacement(hFig,tDurStim);    
%     if isempty(tLimF)
%         % if there are no feasible regions to place then flag the error
%         ok = 0;        
%         eStr = sprintf(['There are no feasible locations to include a ',...
%                         'new stimuli block of this type/size']);        
%     end
%     
% else
    % otherwise, retrieves the time limits for the current block
    sBlk = getSignalBlock(hFig);
    sPos = hSigSel.getPosition();
    tLim = getValidStimBlockLimits(hFig,sBlk,sPos,tDurFull);
    
    % determines if the limits for the selected blocks are sufficient to
    % include the size of the stimuli block
    if tLim(2) < (tDurStim+tOfs)
        % if not, then create an error message for screen
        ok = -double((tDurFull-tLim(2)) > 0.01);
        eStr = sprintf(['The signal properties are such that the ',...
                        'currently selected block can''t feasibly fit ',...
                        'within its current limits.']);
            
    else        
        % otherwise, determine if the stimuli+offset is less than the upper
        % block temporal limit
        ok = double(roundP(tOfs+tDurStim,0.01) <= tLim(2));        
        if ok == 0
            % if not, then create an error message for screen
            eStr = sprintf(['The initial offset must be less than ',...
                            '(%.2f) hours for the currently selected ',...
                            'block to fit within limits.'],...
                            roundP(tLim(2)-tDurStim,0.01));
        end
    end
end

% if so, then output an error to screen
tStr = 'Infeasible Signal Parameters';
switch ok
    case 0
        % appends the remedy
        eStr = sprintf(['To remedy this issue either:%s\n\n ',...
                        '* Decrease the stimuli interval\n ',...
                        '* Decrease the repetition count'],eStr);   

        % adds in the question part of the message
        eStr = sprintf(['%s\n\nAlternatively, would you like to ',...
            'expand the Total Signal Duration to match the new ',...
            'configuration?'],eStr);

        % prompts the user if they wish to reset the parameter, or
        % expand the total signal duration        
        uChoice = questdlg(eStr,tStr,'Reset Parameter',...
                            'Expand Duration','Reset Parameter');
        ok = 2*double(strcmp(uChoice,'Expand Duration'));    
        
    case -1
        % otherwise output the error to screen
        waitfor(msgbox(eStr,tStr,'modal'))
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    SIGNAL PARAMETER FUNCTIONS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- initialises the stimuli train parameter struct
function sTrain = initStimTrainPara()

% memory allocation
sTrain = struct('S',[],'L',[],'Ex',[]);

% --- stores the current stimuli train
function sTrain = getStimTrainInfo(handles)

% initialisations
hFig = handles.figExptSetup;
sigBlk = getappdata(hFig,'sigBlk');
chInfo = getappdata(hFig,'chInfo');
sPara = getProtocolParaInfo(hFig,getappdata(hFig,'pType'));

% retrieves the signal block information/count
sigBlkP = sigBlk{getProtocolIndex(hFig)};
nBlk = length(cell2cell(sigBlkP));

% memory allocation
chName = chInfo(end:-1:1,2);
devType = chInfo(end:-1:1,3);
blkInfo = struct('chName',[],'devType',[],'sPara',[],'sType',[]);
sTrain = struct('sName',[],'chName',[],'tDur',[],'tDurU',[],'blkInfo',[]);

% sets the main signal information
sTrain.sName = get(getProtoObj(hFig,'editStimName'),'string');
sTrain.chName = chInfo(:,2);
sTrain.devType = chInfo(:,3);
sTrain.tDur = sPara.tDur;
sTrain.tDurU = sPara.tDurU;
sTrain.blkInfo = repmat(blkInfo,nBlk,1);

% retrieves the information for each of the signal blocks
iBlk = 1;
for i = 1:length(sigBlkP)
    for j = 1:length(sigBlkP{i})
        % retrieves the signal block userdata
        uData = get(sigBlkP{i}{j},'UserData');
        
        % sets the information for the signal block
        sTrain.blkInfo(iBlk).chName = chName{i};
        sTrain.blkInfo(iBlk).devType = devType{i};
        sTrain.blkInfo(iBlk).sPara = uData{indFcn('sPara')};
        sTrain.blkInfo(iBlk).sType = uData{indFcn('sType')};
        
        % increments the counter
        iBlk = iBlk + 1;
    end
end

% --- sets up the stimuli train objects for the data struct, sTrain
function setupStimTrainObj(handles,sTrain,dType,varargin)

% global variables
global yGap

% creates the load bar
if nargin == 3
    h = ProgressLoadbar('Creates Stimuli Train Object...');
end

% initialisations
chName = sTrain.chName(end:-1:1);
devType = sTrain.devType(end:-1:1);
tLim = [0,sTrain.tDur];
nBlk = length(sTrain.blkInfo);
hFig = handles.figExptSetup;
iProto = getProtocolIndex(hFig);
pType = getappdata(hFig,'pType');

% updates the stimuli train name/duration
set(getProtoObj(hFig,'editStimName'),'String',sTrain.sName)
set(getProtoObj(hFig,'editTotalDur'),'String',num2str(sTrain.tDur))

% updates the 
if strcmp(dType,'L')    
    hPopup = handles.popupTotalDurU;
    set(hPopup,'Value',1+strcmp(sTrain.tDurU,'h'))
end

% deletes all the current axes stimuli blocks
hClearAll = getProtoObj(hFig,'buttonClearAll');
buttonClearAll(hClearAll, '1', handles)

% creates the signal block objects (for all blocks in the stimuli train)
for iBlk = 1:nBlk
    % retrieves the information for the current block    
    sType = sTrain.blkInfo(iBlk).sType;
    sPara = sTrain.blkInfo(iBlk).sPara;
    tOfs = sPara.tOfs;
    iCh = find(strcmp(chName,sTrain.blkInfo(iBlk).chName) & ...
               strcmp(devType,sTrain.blkInfo(iBlk).devType));
    
    % sets the time multiplier
    if iBlk == 1
        if strcmp(dType,'L')
            tMlt = getTimeMultiplier(sTrain.tDurU,sPara.tDurU);
        else
            tMlt = 1;
        end
        
        % updates the protocol duration/units
        sParaP = getProtocolParaInfo(hFig,getappdata(hFig,'pType'));
        [sParaP.tDur,sParaP.tDurU] = deal(sTrain.tDur,sTrain.tDurU);
        setappdata(hFig,sprintf('sPara%s',dType),sParaP);
    end
           
    % sets up the object position and user-data arrays    
    rPos = [tOfs*tMlt,((iCh-1)+yGap),sPara.tDur*tMlt,1-yGap];
    uData = setupUserDataArray(hFig,tLim,sPara,sType,iCh);
    
    % creates the signal object
    createSignalObject(hFig,uData,rPos,false);    
end

% sets the parameter fields for the first stimuli block
hTabG = getappdata(hFig,sprintf('hTabGrp%s',dType));
hTab = findobj(hTabG,'Title',sTrain.blkInfo(1).sType);
set(hTabG,'SelectedTab',hTab)
resetSignalPara(hTab,sTrain.blkInfo(1).sPara)

% resets the limits of the signal block
sigBlk = getappdata(hFig,'sigBlk');
for iCh = 1:length(chName)
    if ~isempty(sigBlk{iProto}{iCh})
        resetSignalBlockTimeLimits(hFig,sigBlk{iProto}{iCh}{1})
    end
end

% enables the stimuli train panel and clear all button
hPanel = getProtoObj(hFig,'panelStimTrain');
setPanelProps(hPanel,'on');
setObjEnable(getProtoObj(hFig,'buttonClearAll'),'on');

% deletes the loadbar (if one was created)
if exist('h','var')
    delete(h)
end

% --- sets up the single parameter data struct
function sPara = setupSingleStimPara(pType)

% initialisations based on the protocol type
switch pType
    case 'S' % case is a short-term protocol        
        [sName,tUnits,tDur] = deal('Short-Term Signal #1','s',10);
        
    case 'L' % case is a long-term protocol        
        [sName,tUnits,tDur] = deal('Long-Term Signal #1','h',1);
        
end

% creates the parameter struct
sPara = struct('Square',[],'Ramp',[],'Triangle',[],'SineWave',[],...
               'tDur',tDur,'tDurU',tUnits,'sName',sName);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    PARAMETER STRUCT FIELD INITIALISATION    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% sets the sub-parameter fields
sPara = setupSignalPara(sPara,'Square',pType);
sPara = setupSignalPara(sPara,'Ramp',pType);
sPara = setupSignalPara(sPara,'Triangle',pType);
sPara = setupSignalPara(sPara,'SineWave',pType);
    
% --- sets up the signal parameters (for the signal type, sType and
%     protocol type, pType)
function sPara = setupSignalPara(sPara,sType,pType,sObj)

% default input arguments
if ~exist('sObj','var'); sObj = []; end
      
% sets the base signal parameters based on the protocol type
switch pType
    case 'S'
        [nC,tC,tUnits] = deal(3,0.5,'s');
    case 'L'
        [nC,tC,tUnits] = deal(3,0.1,'h');
end        

switch sType
    case 'Square'
        % case is the square wave
        sP = struct('sAmp',100,'tDurOn',tC,...
                    'tDurOff',tC,'tOfs',0,'nCount',nC);        
        sP.tDur = sP.tOfs + sP.tDurOn*sP.nCount + sP.tDurOff*(sP.nCount-1);
        
        % temporal units
        [sP.tDurU,sP.tOfsU,sP.tDurOnU,sP.tDurOffU] = deal(tUnits);       
        
    otherwise
        % case is the other signal types
        sP = struct('sAmp0',0,'sAmp1',100,...
                    'tCycle',tC,'tOfs',0,'nCount',nC);
        sP.tDur = sP.tOfs + sP.tCycle*sP.nCount;
        
        % temporal units
        [sP.tCycleU,sP.tDurU,sP.tOfsU] = deal(tUnits);      
end

% sets the signal object (if not empty)
if ~isempty(sObj); sP.sObj = copyClassObj(sObj); end

% appends the signal parameter sub-struct to the overall struct
eval(sprintf('sPara.%s = sP;',sType));                 

% --- sets up the experiment protocol parameter data struct
function sPara = setupExptProtoPara()

% creates the parameter struct
sParaI = struct('tOfs',0,'tOfsU','h','tDur',0,'tDurU','h',...
                'nCount',2,'tStim',[0,1,0,0],'sName',[]);
sPara = struct('S',[],'L',[]); 
[sPara.S,sPara.L] = deal(sParaI); 

% sets the long-term protocol repetition value to 1
sPara.L.nCount = 1;
           
% --- retrieves the parameter struct based on the type
function sPara = getParaStruct(hFig,dType)

%
sPara = getappdata(hFig,sprintf('sPara%s',dType));

% --- resets the signal parameters for a given parameter tab, hTab
function resetSignalPara(hTab,sPara)

% retrieves the parameter struct fieldnames
pFld = fieldnames(sPara);

% resets the parameter objects to that given in sPara
for i = 1:length(pFld)
    % retrieves the parameter value for the current field
    sParaNw = eval(sprintf('sPara.%s',pFld{i}));
    
    % updates the parameter object(s) based on type
    if length(sParaNw) > 1 && isnumeric(sParaNw)
        % case is the stimuli interval duration 
        hPanelStim = findobj(hTab,'type','uipanel');
        setDurPopupValues(hPanelStim,sParaNw)
    else
        % case is other paramter types        
        
        % updates the parameter with the current value (if it exists)
        hPara = findobj(hTab,'UserData',pFld{i});
        if ~isempty(hPara)        
            switch get(hPara,'style')
                case 'edit'
                    % case is the parameter is numeric
                    set(hPara,'string',num2str(sParaNw))

                case 'popupmenu'
                    % case is the parameter is a popupmenu
                    iSel = find(strcmpi(get(hPara,'String'),sParaNw(1)));
                    set(hPara,'Value',iSel)

            end
        end
    end
end

% --- resets the experiment protocol parameter fields
function resetExptPara(hFig,hTab,sPara)

% resets all the signal parameters
resetSignalPara(hTab,sPara)

% --- updates the signal sub-field for a given parameter struct
function updateParaSignalField(hFig,dType,sType,sParaS)

% initialisations


% sets the parameter struct name string
sParaStr = sprintf('sPara%s',dType);

% retrieves the parameter struct,
sPara = setStructField(getappdata(hFig,sParaStr),sType,sParaS);
setappdata(hFig,sParaStr,sPara)

% --- updates the experiment sub-field for a given parameter struct
function updateParaExptField(hFig,dType,sType,sParaS)

% sets the parameter struct name string
sParaStr = sprintf('sPara%s',dType);

% retrieves the parameter struct,
sPara = setStructField(getappdata(hFig,sParaStr),sType,sParaS);
setappdata(hFig,sParaStr,sPara)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    DATA/OBJECT RETRIEVAL FUNCTIONS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- retrieves the axes for the protocol type, pType
function [hAx,pType] = getProtoAxes(handles,pType)

% retrieves the plot axes based on the selected protocol tab
switch pType
    case 'Short-Term Stimuli Protocol'
        hAx = handles.axesProtoS;
        
    case 'Long-Term Stimuli Protocol'
        hAx = handles.axesProtoL;
        
    case 'Experiment Stimuli Protocol'
        hAx = handles.axesProtoEx;
        
    otherwise
        hAx = [];
end

% --- retrieves the currently selected signal parameter tab object
function hTab = getCurrentSignalParaTab(handles)

% retrieves the tab group for the current protocol type
dType = getProtoTypeStr(getappdata(handles.figExptSetup,'pType'));
hTabG = getappdata(handles.figExptSetup,sprintf('hTabGrp%s',dType));

% returns the selected tab object handle
hTab = get(hTabG,'SelectedTab');

% --- sets the hit-test properties for all non-selected signal blocks
function setSignalBlockHitTest(hFig,htState)

% global variables
global hSigSel 

% if there is no selected signal object, then exit
if isempty(hSigSel); return; end
    
% determines all the stimuli blocks that are not the selected block
sigBlkP = getAllProtocolSigBlocks(hFig);
if isempty(sigBlkP); return; end

ii = ~cellfun(@(x)(isequal(hSigSel,x)),sigBlkP);
if any(ii)
    % if there are any such blocks, then reset their hit-test state
    cellfun(@(x)(set(findobj(x),'hittest',htState)),sigBlkP(ii))
end

% --- updates the properties of a selected signal object
function setSelectedSignalProps(handles,sState,varargin)

% global variables
global mType hSigSel nProto

% initialisations
eStr = {'off','on'};
hFig = handles.figExptSetup;

% retrieves the protocol suffix letter
dType = getProtoTypeStr(getappdata(hFig,'pType'));

% updates the selection properties based on the selection state
switch sState
    case 'on' % case is turning on the selection properties
        
        % resets the currently selected signal block and retrieves the
        % userdata for the block
        hSigSelNw = getSelectedBlock(hFig);
        if isempty(hSigSelNw)
            return
        else
            hSigSel = hSigSelNw;
        end
        
        setSignalBlockHitTest(hFig,'off')
        uData = get(hSigSel,'UserData');
        
        % retrieves/resets the parameter tab corresponding to the object
        hTabG = getappdata(hFig,sprintf('hTabGrp%s',dType));
        hTab = findobj(hTabG,'Title',uData{indFcn('sType')});
        set(hTabG,'SelectedTab',hTab);
        setappdata(hFig,'sType',uData{indFcn('sType')})
        
        % sets the signal block highlights
        hP = findobj(hSigSel,'tag','patch');
        set(hP,'EdgeColor','r')
        
        % retrieves the signal parameter struct
        updateAllParaField(hFig,hSigSel,hTab);                      
        
        % makes the distance line markers visible
        iProto = getProtocolIndex(hFig);
        uData = get(hSigSel,'UserData');   
        hDL = uData{indFcn('hDL')};
        if iProto(nProto)
            % turns on the distance line markers
            cellfun(@(x)(setObjVisibility(x,'on')),hDL);
            
            % resets the stimuli train listboxes
            sName = uData{indFcn('sParaEx')}.sName;
            hList = getProtoObj(hFig,'listStimTrain');
            set(hList,'Value',find(strcmp(get(hList,'String'),sName)))
        else
            % turns off the distance line markers
            cellfun(@(x)(setObjVisibility(x,'on')),hDL);
        end
        
        % updates the mouse hover value
        mType = 1 + 2*(1 + iProto(nProto));
        
    case 'off' % case is turning off the selection properties
        
        % sets the signal block highlights
        hP = findobj(hSigSel,'tag','patch');
        set(hP,'EdgeColor','k')        
        
        % removes the ability to move the selected object
        setSignalBlockHightlight(hFig,'off')
        
        % turns on the hit-test fields for the other signal blocks
        setSignalBlockHitTest(hFig,'on')
        
        % removes the currently selected signal block
        [mType,hSigSel] = deal(0,[]);
end

% updates the signal block button enabled properties
setSignalBlockButtonProps(hFig,strcmp(sState,'on'),nargin==2)

% --- sets the enabled properties of the signal block buttons depending
%     on whether they are being enabled/disabled
function setSignalBlockButtonProps(hFig,isOn,updateDel)

% initialisations
eStr = {'off','on'};

% sets the add signal button properties (off if highlighting, on otherwise)
setObjEnableProps(hFig,'buttonAddSig',eStr{1+(~isOn)})
setObjEnableProps(hFig,'buttonDeselectSig',eStr{1+isOn})
setObjEnableProps(hFig,'buttonCopySig',eStr{1+isOn})
setObjEnableProps(hFig,'buttonClearChan',eStr{1+isOn})

% retrieves the clear object button handle and updates its properties
if updateDel
    setObjEnableProps(hFig,'buttonDelSig',eStr{1+isOn})
end

% --- updates all the parameter fields for a given signal block
function updateAllParaField(hFig,hSigBlk,hTab)

% global variables
global nProto

% retrieves the user data array
dType = getProtoTypeStr(getappdata(hFig,'pType'));
uData = get(hSigBlk,'UserData');

% retrieves/resets the parameter tab corresponding to the object
if nargin < 3
    hTabG = getappdata(hFig,sprintf('hTabGrp%s',dType));
    hTab = findobj(hTabG,'Title',uData{indFcn('sType')});
else
    hTabG = get(hTab,'Parent');
end

% updates the parameter field based on the object type
iProto = getProtocolIndex(hFig);
if iProto(nProto)
    % 
    sType = uData{indFcn('sType')};
    sParaEx = uData{indFcn('sParaEx')};   
    
    % 
    hTabNw = findobj(hTabG,'Title',sType);
    set(hTabG,'SelectedTab',hTabNw)
    tabSelectedExpt(hTabNw, '1', guidata(hFig))
    
    %     
    resetExptPara(hFig,hTab,sParaEx)
    updateParaExptField(hFig,dType,sType(1),sParaEx)

    % runs the experiment signal object callback function
    moveExptObj(hSigBlk.getPosition())
else
    sPara = uData{indFcn('sPara')};
    resetSignalPara(hTab,sPara)
    updateParaSignalField(hFig,dType,uData{indFcn('sType')},sPara)

    % runs the signal movement callback function
    moveSignalObj(hSigBlk.getPosition(),hFig)
end 

% --- resets the signal block time limits
function resetSignalBlockTimeLimits(hFig,sBlk,tMlt)

% global variables
global yGap hSigSel nProto

% retrieves the user data
if nargin < 3; tMlt = 1; end
if nargin >= 2
    uData = get(sBlk,'UserData');
    iCh = uData{indFcn('iCh')};
else
    iCh = NaN;
end

% retrieves signal block for the currently selected channel
[sBlkCh,sigBlk,iProto] = getSignalBlock(hFig,iCh);

% initialisations
if iProto(nProto) || iProto(1)
    iExpt = getappdata(hFig,'iExpt');
    tDur = iExpt.Timing.Texp;
else
    sPara = getProtocolParaInfo(hFig,getappdata(hFig,'pType'));
    tDur = sPara.tDur;
end

% updates the parameters for the signal blocks
for i = 1:length(sBlkCh)
    % sets the block y-axis limits
    uDataB = get(sBlkCh{i},'UserData');
    iChB = uDataB{indFcn('iCh')};
    yL = [((iChB(1)-1)+yGap),iChB(end)];
    
    % calculates the limits of the signal block (wrt to the other blocks
    % and the signal train limits)
    [sPos,uData] = deal(sBlkCh{i}.getPosition(),get(sBlkCh{i},'UserData'));
    uData{indFcn('tLim')} = ...
                    getValidStimBlockLimits(hFig,sBlkCh,sPos,tDur,i);
    fcnC = makeConstrainToRectFcn('imrect',uData{indFcn('tLim')},yL);
    
    % if the current signal block is the selected signal block, then update
    % the constraint function and run the movement callback function
    if isequal(sBlkCh{i},hSigSel)
        % updates the userdata/position constraint function for the block
        set(hSigSel,'UserData',uData)
        hSigSel.setPositionConstraintFcn(fcnC)
        
        % scales the time components of the vector
        sPos = hSigSel.getPosition();
        sPos([1,3]) = sPos([1,3])*tMlt;
        
        % runs the stimuli train movement callback function
        if iProto(nProto)
            moveExptObj(sPos,1)
        else
            moveSignalObj(sPos,hFig)
        end
    end
    
    % updates the user data within the signal block
    set(sBlkCh{i},'UserData',uData)
    sBlkCh{i}.setPositionConstraintFcn(fcnC)
end

% updates the signal blocks within the gui
if iProto(nProto) || iProto(1)
    sigBlk{nProto} = sBlkCh;
else
    sigBlk{iProto}{iCh} = sBlkCh;
end
    
setappdata(hFig,'sigBlk',sigBlk)

% --- retrieves the handle of the block that has been currently selected
function sBlk = getSelectedBlock(hFig)

% global variables
global iSigObj hSigSel

% determines the index of the selected channel
hAx = get(hFig,'CurrentAxes');
iCh = getappdata(hFig,'iCh');

% retrieves the blocks for the selected current channel
sBlkCh = getSignalBlock(hFig,iCh);

% matches the signal block with the signal block hover index
uData = cell2cell(cellfun(@(x)(get(x,'UserData')),sBlkCh(:),'un',0));
ii = cell2mat(uData(:,indFcn('iBlk')))==iSigObj;

if any(ii)
    sBlk = sBlkCh{ii};
else
    sBlk = [];
end

% --- retrieves the protocol suffix for a given protocol type
function dType = getProtoTypeStr(pType)

switch pType
    case 'Short-Term Stimuli Protocol'
        dType = 'S';
        
    case 'Long-Term Stimuli Protocol'
        dType = 'L';
        
    case 'Experiment Stimuli Protocol'
        dType = 'Ex';
        
    case 'Experiment Information'
        dType = 'Info';
        
end

% --- retrieves the parameter information for the protocol type, pType
function sPara = getProtocolParaInfo(hFig,pType)

% retrieves the parameter data struct/tab group handles
if length(pType) == 1
    sPara = getappdata(hFig,sprintf('sPara%s',pType));
else
    sPara = getappdata(hFig,sprintf('sPara%s',getProtoTypeStr(pType)));
end

% --- retrieves the parameter for the current signal
function sParaS = getSignalParaInfo(sPara,sType)

% calculates the duration of the signal (given the current para)
sParaS = eval(sprintf('sPara.%s',sType));

% --- returns the index of the currently selected protocol
function iProto = getProtocolIndex(hFig)

% retrieves the protocol string
pType = getappdata(hFig,'pType');

% returns the protocol index
iProto = strcmp({'Experiment Information',...
                 'Short-Term Stimuli Protocol',...
                 'Long-Term Stimuli Protocol',...
                 'Experiment Stimuli Protocol'},pType);             
             
% --- retrieves the signal block for a given channel/protocol
function [sBlk,sigBlk,iProto] = getSignalBlock(hFig,iCh)

% global parmaters
global nProto

% retrieves the signal block/protocol index
sigBlk = getappdata(hFig,'sigBlk');
if isempty(sigBlk)
    [sBlk,sigBlk,iProto] = deal([]);
    return
else
    iProto = getProtocolIndex(hFig);
end

% retrieves the signal block handle (based on protocol type)
if iProto(1)
    % case is the information tab
    sBlk = sigBlk{nProto};
elseif iProto(nProto)
    % case is the experiment protocol
    sBlk = sigBlk{iProto};
else
    % case is the short/long-term stimuli protocols
    if nargin == 1
        sBlk = cell2cell(sigBlk{iProto});
    else
        sBlk = sigBlk{iProto}{iCh};
    end
end
             
% --- determines if there is any overlap with any existing signal blocks
function isFeas = isFeasSigBlockPos(hFig,iCh)

%
global nProto chCol

% retrieves the stored signal block array
sBlk = getSignalBlock(hFig,iCh);

% determines if there are any signal blocks for the current channel
if isempty(sBlk)
    % if not, then flag there is no overlap
    isFeas = true;
else
    % otherwise, retrieves
    [hAx,pType] = deal(get(hFig,'CurrentAxes'),getappdata(hFig,'pType'));
    mPos = get(hAx,'CurrentPoint');
    iProto = getProtocolIndex(hFig);
    
    % retrieves the x-range of the existing blocks    
    sPos = getStimBlockPositions(sBlk);
    sPosRng = sPos(:,1)+[zeros(size(sPos,1),1),sPos(:,3)];
    
    % determines if the current mouse point is within an existing signal
    % block
    if any(prod(sign(sPosRng - mPos(1,1)),2) == -1)
        % if so, then return a true value
        isFeas = false;
    else
        % retrieves parameter information for the current protocol/signal
        sPara = getProtocolParaInfo(hFig,pType);  
        sType = getappdata(hFig,'sType');
        
        %   
        if iProto(nProto)
            sTrainS = getSelectedSignalTrainInfo(hFig);
            tDur = calcExptStimDuration(hFig,sTrainS,sPara);
            tDurEx = vec2time(sPara.tDur);
            
            sbLim = getValidExptBlockLimits(sBlk,mPos(1,1),tDurEx); 
            sbLim = sbLim(iCh,:);
        else           
            % determines the valid stimuli block range            
            sParaS = getSignalParaInfo(sPara,sType);
            tDur = sParaS.tDur;
            
            % determines the valid stimuli block range  
            sbLim = getValidStimBlockLimits(hFig,sBlk,mPos(1,1),sPara.tDur);             
        end              
        
        isFeas = tDur < diff(sbLim); 
    end
end

% --- retrieves the indices for each of the signal blocks
function iBlk = getSignalBlockIndices(sBlk)

% determines if there are any existing blocks
if isempty(sBlk)
    % case is there are existing blocks
    iBlk = 0;
else
    % case is there are existing blocks
    
    % retrieves the indices for each of the existing blocks
    iBlk = zeros(length(sBlk),1);
    for i = 1:length(sBlk)
        uData = get(sBlk{i},'UserData');
        iBlk(i) = uData{indFcn('iBlk')};
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    DATA CONVERSION FUNCTIONS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- converts the experiment data from the old-format .exp files 
function [iExpt,sTrainEx] = convertExptDataLocal(handles,sTrainS,iExpt0)

% converts the data from the old to new format
[iExpt,sTrainEx] = convertExptData(handles,sTrainS,iExpt0);

% updates the start time type (based on whether there is a fixed start)
hPanel = handles.panelExptStartTime;
set(handles.radioFreeExptStart,'Value',~iExpt.Timing.fixedT0)
set(handles.radioFixedStartTime,'Value',iExpt.Timing.fixedT0)
panelExptStartTime_SelectionChangedFcn(hPanel, '1', handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    WINDOW MOTION RELATED OBJECT UPDATE FUNCTIONS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- checks that the current channel highlight is correct
function checkCurrentChannelHighlight(hFig,hHover,isChP)

% global variables
global mType nProto

% if a stimuli/experiment block has been dropped then exit
if any(mType == [3,5]); return; end

% retrieves the stored and hovering channel indices
iCh = getappdata(hFig,'iCh');
iChNw = get(hHover(isChP),'UserData');   
iProto = getProtocolIndex(hFig);

% determines if the stored/hovering channel indices differ
if iChNw ~= iCh
    % if so, then update the channel index to the hovering value   
    setappdata(hFig,'iCh',iChNw)

    % disables/enables the stored/hovered channel outline respectively 
    hAx = get(hFig,'CurrentAxes');
    setObjVisibility(findobj(hAx,'tag','chFill','UserData',iCh),'off') 
    
    % turns on the channel highlight
    if ~iProto(nProto); setObjVisibility(hHover(isChP),'on'); end
end

% --- checks that the current stimuli block highlight is correct
function checkCurrentStimBlockHighlight(hFig,hHover)

% global variables
global mType hSigSel hSigTmp

% determines if a signal block is being hovered over
hSB = findobj(hHover,'tag','hSigBlk');
if isempty(hSigSel)
    if isempty(hSB)
        % if not, then turn off all highlights
        setSignalBlockHightlight(hFig,'off')
    else
        % otherwise, turn on the block highlight
        setSignalBlockHightlight(hSB,'on')

        % if currently a signal block that needs to be set,
        % then delete the current temporary block and reset the
        % mouse hover type to requiring a block to be created
        if any(mType == [2,4])
            % removes the stimuli block from the axes
            delete(hSigTmp)
            hSigTmp = [];

            % removes the distance markers
            hAx = get(hFig,'CurrentAxes');
            setObjVisibility(findobj(hAx,'tag','chDist'),'off');

            % resets the mouse movement type
            mType = 1;
        end
    end
end

% --- checks that the current temporary block is in the correct channel
function checkCurrentTempBlockChannel(hFig, hHover)

% global variables
global hSigTmp objOff mType

% retrieves the userdata of the currently created
% signal block placement object
uData = get(hSigTmp,'UserData');

if ~isempty(uData)
    % retrieves the stored and temporary block channel indices
    iCh = getappdata(hFig,'iCh');
    iChS = uData{indFcn('iCh')};
    
    % determines if the channel indices match
    if length(iChS) == 1
        % case is for a stimuli temporary block
        isMatch = iCh == iChS;
    else
        % case is for an experiment temporary block
        isMatch = (iCh >= iChS(1)) && (iCh <= iChS(2));
    end

    % if they channel indices do not match, then
    if ~isMatch
        % turns off all objects
        turnOffFillObj(hFig,true)

        % resets the objects to an on state
        objOff = false;
        if mType == 2; setObjVisibility(hHover,'on'); end
        createTempSignalObject(hFig,iCh)
    end
end

% --- checks that the current temporary block is within limits
function checkTempBlockLimits(hFig)

% global variables
global hSigTmp

% if a temporary block has been placed, then make
% sure that the position is within time limits
if ~isempty(hSigTmp)
    % retrieves current mouse position wrt the axes
    mPosAx = get(get(hFig,'CurrentAxes'),'CurrentPoint');

    % retrieves the limits of the stimuli block
    uData = get(hSigTmp,'UserData');
    tLim = uData{indFcn('tLim')};

    % updates the position of the imrect object so
    % that the block is within the limits                        
    sPos = hSigTmp.getPosition();
    sPos(1) = min(max(tLim(1),mPosAx(1,1)-sPos(3)/2),tLim(2)-sPos(3));
    hSigTmp.setPosition(sPos);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    MISCELLANEOUS FUNCTIONS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- calculates the scaled stimuli signals
function [xS,yS] = setupScaledStimuliSignal(hAx,sParaS,iCh,sType,useTOfs)

% global variables
global yGap

% calculates the actual stimuli signal values
yLim = get(hAx,'ylim');
[xS0,yS0] = setupStimuliSignal(sParaS,sType,1/100);

% determines the pixel-to-data scale factors
axPos = get(hAx,'Position');
[pX,pY] = deal(sParaS.tDur/axPos(3),diff(yLim)/axPos(4));

% calculates the time offset (if required)
if useTOfs
    tOfs = sParaS.tOfs*getTimeMultiplier(sParaS.tDurU,sParaS.tOfsU);
else
    tOfs = 0;
end

% scales the x/y coordinates to the axes/channel coordinates
dX = diff(xS0([1,end]));
xS = (roundP(tOfs,0.01)+pX) + (dX-2*pX)*(xS0-xS0(1))/dX;
yS = ((pY+yGap)+(iCh-1)) + (1-(yGap+3*pY))*yS0/100;

% --- calculates the axis limits (dependent on size and type)
function axLim = calcAxisLimits(x,axType)

% sets the proportional gap based on axis type
switch axType
    case 'x'
        % case is the x-axis limits
        pLim = 0.025;
        
    case 'y'
        % case is the y-axis limits
        pLim = 0.0;
        
end

% calculates the axis limits
axLim = [0,x] + [-1,1]*(pLim*x);

% --- calculates the coordinates of the axes with respect to the global
%     coordinate position system
function calcAxesGlobalCoords(handles)

% global variables
global axPosX axPosY

% retrieves the position vectors for each associated panel/axes
pPosO = get(handles.panelOuter,'Position');
pPosP = get(handles.panelProtoEx,'Position');
pPosAx = get(handles.panelAxesExpt,'Position');
axPos = get(handles.axesProtoEx,'Position');

% calculates the global x/y coordinates of the
axPosX = (pPosO(1)+pPosP(1)+pPosAx(1)+axPos(1)) + [0,axPos(3)];
axPosY = (pPosO(2)+pPosP(2)+pPosAx(2)+axPos(2)) + [0,axPos(4)];

% --- creates the custom mouse pointer based on the signal type
function mpCData = setupCustomMousePointer(sType)

% initialisations
N = 16;
[mpCD,sz] = deal(false(N),N*[1,1]);

% sets the binary mask (based on the signal type)
switch sType
    case 'Square' % case is the squarewave signal
        % sets the points
        del = N/4 - 1;
        pX = [2,2+del,2+del,3+3*del,3+3*del,N-1];
        pY = [N-1,N-1,2,2,N-1,N-1];
        
        % creates the squarewave array
        for i = 1:length(pX)-1
            if pY(i) > pY(i+1)
                mpCD(pY(i):-1:pY(i+1),pX(i):pX(i+1)) = true;
            else
                mpCD(pY(i):pY(i+1),pX(i):pX(i+1)) = true;
            end
        end
        
    case 'Ramp' % case is the ramp
        % sets the x/y data points
        x = roundP(linspace(N-1,2,2*N));
        
        % creates the binary mask
        mpCD(sub2ind(sz,(N+1)-x,x)) = true;
        
    case 'Triangle' % case is the signal waveform
        % sets the x/y data points
        x1 = linspace(1,N/2,2*N);
        x2 = linspace(N/2+1,N,2*N);
        y1 = N - roundP(2*(x1-1)+1);
        
        % creates the binary mask
        mpCD(sub2ind(sz,y1,roundP(x1))) = true;
        mpCD(sub2ind(sz,y1(end:-1:1),roundP(x2))) = true;
        
    case 'SineWave' % case is the sinewave
        % sets the x/y data points
        x = linspace(0,2*pi,200);
        y = 1 + roundP((N-1) * 0.5 * (sin(x) + 1));
        
        % creates the binary mask
        mpCD(sub2ind(sz,y,roundP(1+(N-1)*x/(2*pi)))) = true;
        
    otherwise
        %
        mpCData = [];
        return
end

% dilates the mask and sets all zero points to NaNs
mpCData = double(bwmorph(mpCD,'dilate'));
mpCData(mpCData == 0) = NaN;

% --- retrieves the signal userdata indices
function ind = indFcn(Type)

% retrieves the userdata index based on the type string
switch Type
    case 'tLim' % case is the signal block time limit
        ind = 1;
        
    case 'sPara' % case is the parameter struct
        ind = 2;
        
    case 'sType' % case is the signal type
        ind = 3;
        
    case 'iCh' % case is the channel index
        ind = 4;
        
    case 'hObjOfs' % case is the start location of the signal object
        ind = 5;
        
    case 'pDX' % case signal/block time difference
        ind = 6;
        
    case 'iBlk' % case is the signal block index
        ind = 7;
        
    case 'hDL' % case is the distance line handles
        ind = 8;
        
    case 'hSigObj' % case is the signal object handle
        ind = 9;
        
    case 'sParaEx' % case is the experiment parameter struct
        ind = 10;        
end

% --- sets the enabled properties of a given object
function setObjEnableProps(hFig,tStrB,eState)

% sets the enabled properties of the
setObjEnable(getProtoObj(hFig,tStrB),eState)

% --- retrieves the object handle for the current protocol type
function hObj = getProtoObj(hFig,tStrB,dType)

% retrieves the selected signal type from the parameter tab
if nargin < 3
    dType = getProtoTypeStr(getappdata(hFig,'pType'));
end

% sets the object tag string
tagStr = sprintf('%s%s',tStrB,dType);

% 
try
    hh = guidata(hFig); 
    hObj = eval(sprintf('hh.%s',tagStr));
catch
    hObj = findobj(hFig,'tag',tagStr);
end

% --- sets up the signal block userdata array
function uData = setupUserDataArray(hFig,tLim,sPara,sType,iCh)

% retrieves the time offset editbox handle
dType = getProtoTypeStr(getappdata(hFig,'pType'));
hTabG = getappdata(hFig,sprintf('hTabGrp%s',dType));
hTabS = get(hTabG,'SelectedTab');

hButOfs = {findobj(findobj(hTabG,'Title',sType),'USerData','tOfs'),...
           getProtoObj(hFig,'buttonResetPara'),...
           getProtoObj(hFig,'buttonUseMinSig')};

% sets the user-data array
uData = {tLim,sPara,sType,iCh,hButOfs};

% --- check that total stimuli duration is valid wrt existing stim blocks
function tMin = getMinTrainDuration(hFig,isRound)

% initialisations
tMin = 0.01;
if nargin < 2; isRound = true; end

% retrieves the signal blocks for the current protocol
sigBlk = getappdata(hFig,'sigBlk');
sBlkP = cell2cell(sigBlk{getProtocolIndex(hFig)});

% calculates the right-side of each signal block (the furtherest right
% block being the minimum duration of the stimuli train)
for i = 1:length(sBlkP)
    sPos = sBlkP{i}.getPosition();
    tMin = max(tMin,sum(sPos([1,3])));
end

% rounds the values to the nearest decimal
if isRound
    tMin = roundP(tMin,0.01);
end

% --- updates the experiment block object properties
function sBlk = updateExptObjPara(hFig,sParaS,sBlk)

% global variables
global hSigSel

% sets the default input arguments
if nargin < 3; sBlk = hSigSel; end

% initialisations
iProto = getProtocolIndex(hFig);
uData = get(sBlk,'UserData');
sigBlk = getappdata(hFig,'sigBlk');
sParaEx = getappdata(hFig,'sParaEx');
sTrainF = getappdata(hFig,'sTrain');
iExpt = getappdata(hFig,'iExpt');

% retrieves the important fields from the user data array
% iCh = uData{indFcn('iCh')};
iBlkF = uData{indFcn('iBlk')};
hSigObj = uData{indFcn('hSigObj')};
sTrainS = uData{indFcn('sPara')};
sType = uData{indFcn('sType')};

% calculates the offset time multiplier
tMltOfs = getTimeMultiplier(iExpt.Timing.TexpU,sParaS.tOfsU);

% updates the position of the signal block
rPos = sBlk.getPosition();
rPos(1) = sParaS.tOfs*tMltOfs;
rPos(3) = calcExptStimDuration(hFig,sTrainS,sParaEx);
sBlk.setPosition(rPos);

% retrieves the full experiment signal
xyData = setupFullExptSignal(hFig,sTrainS);
iChObj = ~cellfun('isempty',xyData);
cellfun(@(h,x,pdx)(set(h,'xData',(x(:,1)-x(1))+(rPos(1)+pdx),'yData',x(:,2))),...
       num2cell(hSigObj),xyData(iChObj),num2cell(uData{indFcn('pDX')}))

% updates the userdata for the selected object
uData{indFcn('sParaEx')} = sParaS;
set(sBlk,'UserData',uData);

% updates the experiment protocol stimuli train parameter field (for the
% current stimuli block)
sTrainF.Ex.sParaEx(iBlkF) = sParaS;
setappdata(hFig,'sTrain',sTrainF);

% updates the signal block within the storage array (only do this if the
% stimuli trains are not being updated as this is done outside function
iBlkS = cellfun(@(x)(isequal(sBlk,x)),sigBlk{iProto});
sigBlk{iProto}{iBlkS} = sBlk;
setappdata(hFig,'sigBlk',sigBlk)

% --- updates the parameter for the currently selected stimuli object
function updateStimObjPara(hFig,sParaS)

% global variables
global hSigSel

% initialisations
uData = get(hSigSel,'UserData');
sigBlk = getappdata(hFig,'sigBlk');
hAx = get(hFig,'CurrentAxes');
iProto = getProtocolIndex(hFig);
sParaP = getProtocolParaInfo(hFig,getappdata(hFig,'pType'));

% retrieves the userdata field values
iCh = uData{indFcn('iCh')};
sType = uData{indFcn('sType')};
hSigObj = uData{indFcn('hSigObj')};

% calculates the parameter time multiplier
tMltP = getTimeMultiplier(sParaP.tDurU,sParaS.tDurU);

% updates the position of the signal block
rPos = hSigSel.getPosition();
rPos(1) = sParaS.tOfs*getTimeMultiplier(sParaS.tDurU,sParaS.tOfsU)*tMltP;
rPos(3) = sParaS.tDur*tMltP;
hSigSel.setPosition(rPos);

% retrieves the scaled signal values
[xS,yS] = setupScaledStimuliSignal(hAx,sParaS,iCh,sType,1);
set(hSigObj,'xData',xS*tMltP,'yData',yS)

% updates the userdata for the selected object
uData{indFcn('pDX')} = xS(1)-rPos(1)/tMltP;
uData{indFcn('sPara')} = sParaS;
set(hSigSel,'UserData',uData);

% resets the signal block time limits for the current channel
resetSignalBlockTimeLimits(hFig,hSigSel);

% updates the signal block within the storage array
iBlk = cellfun(@(x)(isequal(hSigSel,x)),sigBlk{iProto}{iCh});
sigBlk{iProto}{iCh}{iBlk} = hSigSel;
setappdata(hFig,'sigBlk',sigBlk)

% --- retrieves the general motor channel names (for nCh channels)
function chName = getOptoChannelNames(varargin)

% sets the channel name array
chName = {'Red','Green','Blue','White'};

% reverses the order (if specified)
if nargin == 1
    chName = chName(end:-1:1);
end

% --- retrieves the time duration strings (up to a value of vMax)
function dStr = getTimeDurationString(vMax,v0)

% sets the default input arguments
if nargin == 1; v0 = 0; end

% creates the duration strings
if vMax >= 10
    dStr = [arrayfun(@(x)(sprintf('0%i',x)),(v0:9)','un',0);...
            arrayfun(@num2str,(10:vMax)','un',0)];
else
    dStr = arrayfun(@(x)(sprintf('0%i',x)),(v0:9)','un',0);
end

% --- sets the popup object values for the time vector, tVec
function setDurPopupValues(hPanel,tVec)

% updates the values for each of the popup menus
for i = 1:length(tVec)
    set(findobj(hPanel,'UserData',i),'Value',tVec(i)+1);
end

% --- sets the start experiment popup menu values
function setStartTimeValues(hPanel,tStart)

% retrieves the popupmenu objects from the panel
hPopup = findall(hPanel,'Style','popup');

% updates the popup menu items based on their type/value
for i = 1:length(hPopup)
    iType = get(hPopup(i),'UserData');
    switch iType
        case 1 % case is the AM/PM popup menu
            set(hPopup(i),'Value',1+(tStart(4)>=12))           
            
        case {2,3} % case is the month/day popup menus
            set(hPopup(i),'Value',tStart(iType));
            
        case 4 % case is the hour popup menu
            set(hPopup(i),'Value',mod(tStart(iType)-1,12)+1);            
            
        otherwise % case is the other menus
            set(hPopup(i),'Value',tStart(iType)+1);
    end
end

% --- resets the properties for the axes, hAx
function resetAxesProps(hAx,tDur)

% updates the axis limits and line markers
hLine = findall(hAx,'tag','hLine1');
set(hLine,'xdata',tDur*[1,1]);

% updates the x-axis tick labels/axis limits
set(hAx,'xlim',calcAxisLimits(tDur,'x'))
xTickLbl = arrayfun(@num2str,get(hAx,'xtick'),'un',0);
set(hAx,'xticklabels',xTickLbl)

% updates the location of the channel selection fill objects
hFill = findall(hAx,'tag','chFill');
arrayfun(@(x)(set(x,'XData',[0,0,tDur*ones(1,2)])),hFill)

% --- updates the zoom propeFrties based on zState
function setAxesZoomProperties(handles,zState,varargin)

% global variables
global nProto

% updates the axes zoom properties
isOff = strcmp(zState,'off');
hFig = handles.figExptSetup;
jTab = getappdata(hFig,'jTab');
hZoom = getappdata(hFig,'hZoom');

% sets the enabled properties of the protocol tabs
arrayfun(@(x)(jTab.setEnabledAt(x-1,isOff)),1:nProto)

try
    % updates the state of the zoom object
    setObjEnable(getappdata(hFig,'hZoom'),zState);
catch
    % if that fails, then delete the zoom object
    delete(hZoom)
    
    % creates a new zoom object and enables it
    hZoom = initZoomObject(hFig);
    setObjEnable(hZoom,zState);
    setappdata(hFig,'hZoom',hZoom)
end

% if turning off zoom, then reset the axes zoom to original
if isOff
    % if disabling zoom, then reset the axes zoom to original
    zoom out
    
    % resets the mouse motion callback function
    mFcn = {@figExptSetup_WindowButtonMotionFcn, handles};
    set(hFig,'WindowButtonMotionFcn',mFcn);
    
else
    % removes the motion callback function
    set(hFig,'WindowButtonMotionFcn',[]);
end

% --- sets the properties of the objects within the experiment proto tabs
function setExptProtoTabProps(hTab,eState)

% updates the tab/panel properties
setPanelProps(hTab,eState)
setPanelProps(findobj(hTab,'type','uipanel'),eState)

% --- deletes all the signal blocks for a given channel
function sigBlk = deleteChannelSignalBlocks(hFig,iProto,iCh)

% retrieves the signal block array
sigBlk = getappdata(hFig,'sigBlk');

% if any signal blocks within the channel, then delete them
if ~isempty(sigBlk{iProto}{iCh})
    cellfun(@(x)(deleteSignalBlock(x)),sigBlk{iProto}{iCh});
    sigBlk{iProto}{iCh} = [];
    
    % updates the signal blocks within the gui
    setappdata(hFig,'sigBlk',sigBlk)
end

% --- retrieves the signal train info for a protocol type
function sTrainS = getSelectedSignalTrainInfo(hFig)
    
% initialisations
sType = getappdata(hFig,'sType');
sTrain = getappdata(hFig,'sTrain');
hList = getappdata(hFig,'hListEx');
    
% retrieves the signal train info for the current protocol type
sTrainS = eval(sprintf('sTrain.%s',sType(1)));

% determines the index of the stimuli train that matches the currently
[lStr,iSel] = deal(get(hList,'String'),get(hList,'Value'));
iTrain = cellfun(@(x)(strcmp(x.sName,lStr{iSel})),sTrainS);

% returns the stimuli train corresponding to the selected list item
if ~any(iTrain)
    sTrainS = [];
else
    sTrainS = sTrainS{iTrain};  
end

% --- combines all signal blocks (for a given protocol) into a single array
function sigBlkP = getAllProtocolSigBlocks(hFig)

% global variables
global nProto

% retrieves all the signal blocks for the current protocol type
iProto = getProtocolIndex(hFig);
sigBlk = getappdata(hFig,'sigBlk');

% retrieves the signal blocks for the protocol
sigBlkP = sigBlk{getProtocolIndex(hFig)};
if ~iProto(nProto)
    % if not the experiment protocol, then combine the arrays further
    sigBlkP = cell2cell(sigBlkP);
end

% --- checks that the experiment block placement is feasible
function tLimF = checkExptBlockPlacement(hFig,tDurBlk)

% initialisations
sType = getappdata(hFig,'sType');
iExpt = getappdata(hFig,'iExpt');
sParaEx = getappdata(hFig,'sParaEx');

% retrieves the currently selected stimuli train protocol data field
sTrain = getappdata(hFig,'sTrain');
iSel = get(getappdata(hFig,'hListEx'),'Value');
sTrainP = eval(sprintf('sTrain.%s;',sType(1)));

% 
if isempty(sTrainP)
    % if no stimuli train have been created then output an error
    eStr = sprintf('No %s trains have been created',sType);
    waitfor(msgbox(eStr,'No Trains Set','modal'))    
    
    % exit the function with an empty array
    tLimF = [];
    return
else
    % otherwise, retrieve the selected stimuli train parameter struct
    sTrainS = sTrainP{iSel};
end

% calculates the duration of the experiment
tDurEx = vec2time(iExpt.Timing.Texp,iExpt.Timing.TexpU);
if nargin == 1
    userIA = true;    
    tDurBlk = calcExptStimDuration(hFig,sTrainS,sParaEx);
else
    userIA = false;
end

% retrieves the experiment stimuli train block handles 
sBlk0 = getSignalBlock(hFig);
if isempty(sBlk0)
    % sets the feasible duration
    [tLimF,userIA] = deal([0,tDurEx],false);
else
    %
    sBlk = reduceExptStimObj(sBlk0,sTrainS);        
    if isempty(sBlk)
        % sets the feasible duration
        [tLimF,userIA] = deal([0,tDurEx],false);        
    else
        % retrieves the stimuli block positions
        sPos = getStimBlockPositions(sBlk);

        % sets the 
        sbLim = [sPos(:,1),sum(sPos(:,[1,3]),2)];
        if sbLim(1,1) > 0; sbLim = [zeros(1,2);sbLim]; end
        if sbLim(end,2) < tDurEx; sbLim = [sbLim;tDurEx*ones(1,2)]; end

        % sets the feasible block time limits
        tLimF = [sbLim(1:end-1,2),sbLim(2:end,1)];    

        % combines the limits so that they are all contiguous
        [isKeep,iRow] = deal(true(size(tLimF,1),1),1);
        for i = 2:size(tLimF,1)
            % determines if the current block overlaps in time with the
            % candidate block
            if tLimF(i,1) < tLimF(iRow,2)
                % if so, then flag that the current row will not be kept
                isKeep(i) = false;
               if tLimF(i,2) > tLimF(iRow,2)
                    % if the current block is not completely covered by the
                    % candidate block, then udpate the limits
                    tLimF(iRow,2) = tLimF(i,2);
               end
            else
                % updates the new search block to the current
                iRow = i;
            end
        end

        % removes any combined rows
        tLimF = tLimF(isKeep,:);        
    end
end

% returns time blocks that can feasibly contain the new expt stimuli block
isOK = diff(tLimF,[],2) >= tDurBlk;
tLimF = tLimF(isOK,:);

% if there are no feasible blocks, then output a meesage to screen
if isempty(tLimF)
    % determines if there are any feasible locations to place the block
    if userIA
        % if there were no valid groups, and user interactivity is on, then
        % output an error message to screen
        eStr = sprintf(['There are no feasible locations to place the new ',...
                        'experiment block (%.2fh). Either remove ',...
                        'existing experiment blocks or alter the new ',...
                        'experiment block parameters.'],tDurBlk);
        waitfor(msgbox(eStr,'Infeasible Block Placement','modal'))
    end
elseif userIA            
    % retrieves the channel indices for the stimuli train blocks
    sTrainS = getSelectedSignalTrainInfo(hFig);
    iCh = getBlockChannelIndices(hFig,sTrainS);    
    
    % prompts the user    
    iChoice = promptExptBlockRegion(hFig,tLimF,iCh);
    if isempty(iChoice)
        tLimF = [];
    else
        tLimF = tLimF(iChoice,:);
    end
end

% --- calculates the experiment time offset
function tOfs = getExptTimeOffset(hFig,sPara)

% import field retrieval
if nargin < 2
    sPara = getappdata(hFig,'sParaEx');
end

% other field retrievals
sType = getappdata(hFig,'sType');
iExpt = getappdata(hFig,'iExpt');
sParaS = eval(sprintf('sPara.%s',sType(1)));

% retrieves the offset value (converted to experiment duration time units)
tOfs = sParaS.tOfs*getTimeMultiplier(iExpt.Timing.TexpU,sParaS.tOfsU);

% --- determines the channel indices for the expt block train parameters
function iCh = getBlockChannelIndices(hFig,sTrainS)

% retrieves the channel/device type names from the train block info
chNameBlk = field2cell(sTrainS.blkInfo,'chName');
devTypeBlk = field2cell(sTrainS.blkInfo,'devType');

% determines the channels with the matching channel/device type names
iCh0 = cellfun(@(x,y)(find(strcmp(sTrainS.chName,x) & ...
                           strcmp(sTrainS.devType,y))),...
                           chNameBlk,devTypeBlk,'un',0);
iCh0 = cell2mat(iCh0(~cellfun('isempty',iCh0)));

% returns the final channel indices
iCh = sort((length(sTrainS.chName)+1) - iCh0);

% --- 
function sPara = setExptParaValue(sPara,pStr,nwVal,dType)

% updates the parameter struct with the new value
eval(sprintf('sPara.%s.%s = nwVal;',dType,pStr));

% --- 
function sVal = getExptParaValue(sPara,pStr,dType)

% updates the parameter struct with the new value
eval(sprintf('sVal = sPara.%s.%s;',dType,pStr));

% --- 
function uDataH = toggleExptObjSelection(hFig,hSigBlk,updateSel)

% global variables
global isCreateBlk nProto
isCreateBlk = true;
if nargin < 3; updateSel = true; end

% creates a progressbar
h = ProgressLoadbar('Updating Block Selection...');
set(h.Control,'WindowStyle','modal')

handles = guidata(hFig);
uDataH = get(hSigBlk,'UserData');
iProto = getProtocolIndex(hFig);

% turns off the current block selection
turnOffFillObj(hFig)
setSelectedSignalProps(handles,'off')

% updates the signal block selection
updateExptBlockSelection(hFig,hSigBlk)

% updates the stimuli train listbox (if required)
hList = getProtoObj(hFig,'listStimTrain');
if iProto(nProto)
    iSel = strcmp(get(hList,'String'),uDataH{indFcn('sParaEx')}.sName);
    set(hList,'Value',find(iSel))
    
    % updates the stimuli train listbox (if required)
    sType = uDataH{indFcn('sType')};
    hListEx = getProtoObj(hFig,'listStimTrainEx',sType(1));
    iSelEx = strcmp(get(hListEx,'String'),uDataH{indFcn('sPara')}.sName);
    set(hListEx,'Value',find(iSelEx))
end

% updates the stimuli signal type
setappdata(hFig,'sType',uDataH{indFcn('sType')})

% updates the house-hover flag
% [mType,isCreateBlk] = deal(5,false);
isCreateBlk = false;
pause(0.02)

% deletes the progressbar
delete(h)

% --- 
function updateExptBlockSelection(hFig,hSigBlk)

% global parameters
global iSigObj hSigSel mType
mType = 5;

% retrieves the handle of the currently
% selected stimuli object block
uDataH = get(hSigBlk,'UserData');
iSigObj = uDataH{indFcn('iBlk')};
setappdata(hFig,'iCh',uDataH{indFcn('iCh')});
sBlk = getSelectedBlock(hFig);                            

% resets the selected block to the current
hSigSel = sBlk;

% resets the outline selection to red
hP = findobj(hSigBlk,'tag','patch');
set(hP,'EdgeColor','r')                            

% retrieves the signal parameter struct
updateAllParaField(hFig,hSigSel); 
moveExptObj(hSigSel.getPosition(),1)

% re-runs the motion function and makes the
% block highlights visible again
figExptSetup_WindowButtonMotionFcn(hFig, [], guidata(hFig))                            
setSignalBlockHightlight(hSigBlk,'on') 
setSignalBlockButtonProps(hFig,1,1)

% --- reduces the stimuli
function sBlk = reduceExptStimObj(sBlk,sTrainS)

% retrieves the full/stimuli train channel names
chNameR = sTrainS.chName(end:-1:1);
devTypeR = sTrainS.devType(end:-1:1);

chInfoS = [field2cell(sTrainS.blkInfo,'chName'),...;
           field2cell(sTrainS.blkInfo,'devType')];
      
indCh = cellfun(@(x)(find(strcmp(chNameR,x{1}) & ...
                          strcmp(devTypeR,x{2}))),num2cell(chInfoS,2));

% determines which channels are used for this experiment block    
uData = cell2cell(cellfun(@(x)(get(x,'UserData')),sBlk,'un',0));
hasCh = cellfun(@(x)(~isempty(intersect(x(1):x(end),indCh))),uData(:,4));

%
sBlk = sBlk(hasCh);

% --- resets the experiment time axes labels (from duration to actual time)
function resetExptTimeAxes(handles,Type,TexpU0)

% global variables
global nProto

% initialisations
hFig = handles.figExptSetup;
iExpt = getappdata(hFig,'iExpt');
sigBlk = getappdata(hFig,'sigBlk');
infoObj = getappdata(hFig,'infoObj');

%
switch Type
    case 'Ex'
        % object handles
        hAx = handles.axesProtoEx;
        
        % sets the time limits/units
        [iBlk,isFixedT0] = deal(nProto,iExpt.Timing.fixedT0);
        [tLim,tUnits] = vec2time(iExpt.Timing.Texp,iExpt.Timing.TexpU);
        
    case 'L'
        % object handles
        hAx = handles.axesProtoL;
        sPara = getappdata(hFig,'sParaL');
        
        % sets the time limits
        [iBlk,isFixedT0] = deal(nProto-1,false);
        [tLim,tUnits] = deal(sPara.tDur,sPara.tDurU);
end

% updates the axes object properties
resetAxesProps(hAx,tLim)
hXLabel = findall(hAx,'tag','xLabel');
xTicks = get(hAx,'xTick');

% updates the signal blocks (if the units have been provided)
if nargin == 3
    % determines if there was a change in the duration units
    if ~strcmp(TexpU0,tUnits)
        % if so, then determine if any experiment blocks have been set        
        if ~isempty(sigBlk)
            if ~isempty(sigBlk{iBlk})
                % if so, then update the parameters for each of the blocks
                sBlk = sigBlk{iBlk};
                tMlt = getTimeMultiplier(tUnits,TexpU0);
                
                % reduces down the cell array (long-term protocols only)
                if strcmp(Type,'L')
                    sBlk = cell2cell(sBlk);
                end
                
                for i = 1:length(sBlk) 
                    % updates the signal block offset values
                    uData = get(sBlk{i},'UserData');
                    hDX = uData{indFcn('pDX')};
                    uData{indFcn('pDX')} = hDX*tMlt;
                    set(sBlk{i},'UserData',uData)
                    
                    % updates the position of the data block
                    [rPos,rPos0] = deal(sBlk{i}.getPosition());
                    rPos([1,3]) = tMlt*rPos([1,3]);
                    sBlk{i}.setPosition(rPos);

                    % updates the signal block trace time-scale                       
                    hSigObj = uData{indFcn('hSigObj')};                        
                    xS = arrayfun(@(x,pdx)(tMlt*get(x,'xdata')-tMlt*...
                                (pdx+rPos0(1))),hSigObj,hDX,'un',0);
                    cellfun(@(x,xs,dx)(set(x,'xdata',xs+dx+rPos(1))),...
                                num2cell(hSigObj),xS,num2cell(hDX*tMlt))    
                end
            end
        end
    end
end

% sets the axes properties based on the experiment start type
if isFixedT0
    % case is a fixed start time
    set(hAx,'xticklabel',getFixedTimeLabels(...
                         iExpt.Timing.T0,xTicks,tUnits(1:end-1)))
    set(hXLabel,'string','Time')      
    
else    
    % case is a non-fixed start time 
    set(hAx,'xticklabel',arrayfun(@num2str,xTicks(:),'un',0))
    set(hXLabel,'string',sprintf('Time (%s)',tUnits))    
end

% if the experiment duration exceeds that of the video duration then reset
% the video duration popup
if strcmp(Type,'Ex') && ~strcmp(infoObj.exType,'StimOnly')
    if vec2sec([0,iExpt.Video.Dmax]) > vec2sec(iExpt.Timing.Texp)
        iExpt = resetVideoDurationPopup(handles,iExpt,false);
        setappdata(hFig,'iExpt',iExpt)
    end    

    % updates the minimum duration fields
    updateMinDurFields(handles)
    calcVideoTiming(handles);

else 
    % resets the signal block time limits (if required)
    if ~isempty(sigBlk)
        hSigBlk = cell2cell(sigBlk{iBlk});
        if ~isempty(hSigBlk)    
            if iscell(hSigBlk)
                cellfun(@(x)(resetSignalBlockTimeLimits(hFig,x)),hSigBlk);
            else
                arrayfun(@(x)(resetSignalBlockTimeLimits(hFig,x)),hSigBlk);
            end
        end
    end
end

% --- sets up the time labels for fixed start experiments
function xLbl = getFixedTimeLabels(tStart,xTicks,tUnits)

%
tStart0 = datenum(tStart);

% determines if the x-tick values are integers
if any(mod(xTicks,1) > 1e-6)
    % if not, then scale the locations until they are integers
    tMlt = [24,60,60];
    tUnitStr = {'Day','Hour','Minute','Second'};
    i0 = find(strcmp(tUnitStr,tUnits));
    
    % keep applying the multipliers until all locations are integers
    for i = i0:length(tMlt)
        % multiplies the x-tick locations by the multiplier
        xTicks = xTicks*tMlt(i);
        if ~any(mod(xTicks,1) > 1e-6) 
            % if all the values are integers, then exit the loop
            xTicks = roundP(xTicks);
            tUnits = tUnitStr{i+1};
            break
        end
    end
    
    xTicks = roundP(xTicks);
    tUnits = tUnitStr{i+1};
end

% sets the label strings based on the start time and the x-tick locations
xLbl = cell(length(xTicks),1);
for i = 1:length(xLbl)
    xLbl{i} = datestr(addtodate(tStart0,xTicks(i),tUnits),'HH:MM AM');
end

% --- sets the parameter editbox string
function eStr = getEditResetString(eVal,nMax)

% sets the default input argument
if nargin < 2; nMax = 3; end

pTol = 10^(-(nMax+1));
for i = 0:nMax
    modVal = mod(eVal,10^(-i));
    if (modVal < pTol) || (modVal > (1-pTol))
        break
    end
end

% sets the string format based on the precision
eStr = eval(sprintf('sprintf(''%s'',eVal)',sprintf('%s.%if',char(37),i)));

% --- updates the properties of the experiment tab depending on whether any
%     short/long-term experimental blocks have been set
function setExptTabProps(hFig)

% global variables
global nProto

% initalisations
jTab = getappdata(hFig,'jTab'); 
sTrain = getappdata(hFig,'sTrain');

% updates the enabled properties of the tab based on whether there are any
% short/long-term stimuli trains available
try
    jTab.setEnabledAt(nProto-1,~isempty(sTrain.S)||~isempty(sTrain.L)) 
end

% --- updates the minimum experiment duration --- %
function updateMinDurFields(handles,varargin)

% loads the required data structs
hFig = handles.figExptSetup;
iExpt = getappdata(hFig,'iExpt');

% retrieves the current tab index and stimulus timing type 
tMin = getMinExptDuration(hFig,false);

% updates the minimum duration text string based on the min duration
if tMin == 0    
    isFeas = true;
else
    % calculates the min duration values/strings
    tExp = vec2time(iExpt.Timing.Texp,iExpt.Timing.TexpU);
    isFeas = tExp >= tMin;        
end
    
% updates the feasible duration checkbox value
updateFeasFlag(handles,'checkDurFeas',isFeas)

% --- updates the time to go string
function timeToStart(obj, event, handles)

% global variables
global t2sStatus

% retrieves the gui handle
hFig = handles.figExptSetup;
if ishandle(hFig)
    % if the handle is valid, then retrieve the start time vector
    iExpt = getappdata(hFig,'iExpt');
    [nwTime,T0,enUpdate,isFeas] = deal(clock,iExpt.Timing.T0,false,true);
else
    % if not, then exit the function
    return
end

% determines if the start time is ok (and if there are any fixed time
% events)
if get(handles.checkFixStart,'value')    
    % calculates the time difference between the current time and the
    % experiment start time (T0)
    [dT,~,TS] = calcTimeDifference(T0,nwTime);
    if (dT < 0); TS{1} = TS{1}(2:end); end
    nwStr = sprintf('%s:%s:%s:%s',TS{1},TS{2},TS{3},TS{4});
    
    % sets the background colour based on whether the time is before the
    % start wait time period
    [isFeas,strCol] = deal(dT>=0,[]);
    if ~isFeas  
        % if the time difference is negative, then use a red font
        strCol = 'r';
        if (t2sStatus ~= 0)
            [enUpdate,t2sStatus] = deal(true,0);
        end
    else
        % if still okay, then use a green font
        if (isempty(strCol))        
            strCol = 'g';
            if (t2sStatus ~= 1)
                [enUpdate,t2sStatus] = deal(true,1);
            end
        end
    end

    % updates the time to go string
    set(handles.textTimeToGo,'string',nwStr,'backgroundcolor',strCol)
else
    % updates the time to go string
    set(handles.textTimeToGo,'string','N/A','backgroundcolor','g')       
    if (t2sStatus ~= 2)
        [enUpdate,t2sStatus] = deal(true,2);
    end    
end

% sets the save protocol/run experiment menu items
if enUpdate
    updateFeasFlag(handles,'checkStartFeas',isFeas); 
else
    set(handles.checkStartFeas,'value',isFeas)
end

% --- retrieves the minimum experiment duration
function tMin = getMinExptDuration(hFig,roundTime)

% parameters
pTol = 0.999;
if nargin < 2; roundTime = true; end

% retrieves the signal blocks for the 
sBlk = getSignalBlock(hFig);
if isempty(sBlk)
    % case is there are no experiment signal blocks
    tMin = 0;
else
    % case is there are experiment signal blocks
    sPos = cell2mat(cellfun(@(x)(x.getPosition()),sBlk(:),'un',0));    
    tMin = max(sPos(:,1)+sPos(:,3));
    
    if roundTime
        modVal = mod(tMin,1);
        if (modVal > pTol)
            tMin = ceil(tMin);
        elseif modVal < (1 - pTol)
            tMin = floor(tMin);
        end
    end
end

% --- initialises the time-to-go timer callback function
function initTimerObj(handles)

% deletes any old timer objects
hTimerOld = timerfindall('tag','StartTimer');
if ~isempty(hTimerOld) 
    deleteTimerObjects(hTimerOld)     
end

% creates the timer object
timerObj = timer('TimerFcn',{@timeToStart, handles}, 'Period', 1.0,...
                 'TasksToExecute', inf,'ExecutionMode', 'FixedRate',...
                 'tag','StartTimer');

% starts the timer object
setappdata(handles.figExptSetup,'timerObj',timerObj)

% --- stores the experiment training parameter struct
function sTrain = storeExptTrainPara(hFig)

% global parameters
global nProto

% sets the protocol type to the experiment protocol tab
setappdata(hFig,'pType','Experiment Stimuli Protocol')

% retrieves the stimuli train parameter struct
sTrain = getappdata(hFig,'sTrain');
if isempty(sTrain) || isempty(sTrain.Ex)
    % if recording only, then exit the function
    return 
end

% retrieves the stimuli train 
iExpt = getappdata(hFig,'iExpt');
sigBlk = getappdata(hFig,'sigBlk');
sParaEx = getappdata(hFig,'sParaEx');

% other initialisations
sTrainEx = sTrain.Ex;
sBlk = sigBlk{nProto};
TexpU = lower(iExpt.Timing.TexpU(1));

% resets the stimuli/train data structs
for i = 1:length(sBlk)
    % stimuli train/experiment protocol data structs for the current block
    uData = get(sBlk{i},'UserData');
    sTrainEx.sTrain(i) = uData{indFcn('sPara')};
    sTrainEx.sParaEx(i) = uData{indFcn('sParaEx')};
    
    % updates the signal block time offset
    rPos = sBlk{i}.getPosition();
    sTrainEx.sParaEx(i).tOfs = rPos(1);
    sTrainEx.sParaEx(i).tOfsU = TexpU;
    
    % updates the signal block units
    tMltDur = getTimeMultiplier(TexpU,sTrainEx.sParaEx(i).tDurU);
    sTrainEx.sParaEx(i).tDur = tMltDur*sTrainEx.sParaEx(i).tDur;
    sTrainEx.sParaEx(i).tDurU = TexpU; 
end

% resets the stimuli train data into the gui
sTrain.Ex = sTrainEx;
setappdata(hFig,'sTrain',sTrain);

% resets the protocol type to the current tab
hTabG = getappdata(hFig,'hTabGrp');
setappdata(hFig,'pType',get(get(hTabG,'SelectedTab'),'Title'));

% --- 
function sType = getStimuliTypeString(hFig,dType)

%
sType = getappdata(hFig,'sType');
if isempty(sType)
    % retrieves the 
    if nargin < 2
        dType = getProtoTypeStr(getappdata(hFig,'pType'));
    end

    %
    hTabG = getappdata(hFig,sprintf('hTabGrp%s',dType));
    sType = get(get(hTabG,'SelectedTab'),'Title');
    
    %
    setappdata(hFig,'sType',sType)
end

% --- converts the time (in units, tUnits) to a time vector string
function tVecStr = getTimeVectorString(t0,tUnits)

% initialisations
tVecStr = '';

% converts the time to seconds and then converts to a time vector
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

% --- updates the axes time tickmarks
function updateAxesTicks(hObj,eventdata,hFig)

% if the start time is not fixed, then exit the function
iExpt = getappdata(hFig,'iExpt');

%
hAx = eventdata.Axes;
xTicks = get(hAx,'xtick');

% retrieves the limits of the current axes
if iExpt.Timing.fixedT0
    [~,tUnits] = vec2time(iExpt.Timing.Texp,iExpt.Timing.TexpU);
    xLbl = getFixedTimeLabels(iExpt.Timing.T0,xTicks,tUnits(1:end-1));    
else
    xLbl = arrayfun(@num2str,xTicks,'un',0);
end

% updates the axis tickmarks
set(hAx,'xTickLabel',xLbl)

% --- determines if the experiment stimuli train contains at least one
%     channel from each of the attached devices
function hasAllStim = detStimTrainFeas(hFig)

% initialisations
chInfo = getappdata(hFig,'chInfo');
sTrain = getappdata(hFig,'sTrain');

if isempty(sTrain.Ex)
    hasAllStim = false;
    return
else
    chInfoBlk = [];
end

% determines the unique set of channel names
for i = 1:length(sTrain.Ex.sTrain)
    % appends the names for each of the channels in the block
    blkInfo = sTrain.Ex.sTrain(i).blkInfo;
    for j = 1:length(blkInfo)
        chInfoBlk = [chInfoBlk;{blkInfo(j).chName,blkInfo(j).devType}];
    end
end

% determines if there is a stimuli event including at least one channel
% from each of the attached devices
if isempty(chInfoBlk)
    hasAllStim = false;
else
    % determines the unique groupings, and from this determines if each
    % stimuli device is included in the analysis
    ii = cellfun(@(x)(find(strcmp(chInfo(:,2),x{1}) & ...
                 strcmp(chInfo(:,3),x{2}))),num2cell(chInfoBlk,2)); 
             
    nDev = length(unique(cell2mat(chInfo(:,1))));
    hasAllStim = length(unique(cell2mat(chInfo(ii,1)))) == nDev;
end

% --- updates the experimental protocol parameter fields
function ok = updateExptParaFields(hFig,sTrainC,dType,varargin)

% initialisations
[ok,eStr] = deal(true,[]);
iExpt = getappdata(hFig,'iExpt');
sParaEx = getappdata(hFig,'sParaEx');
hTabEx = getappdata(hFig,'hTabEx');
sPara = eval(sprintf('sParaEx.%s',dType));

%
% if strcmp(dType,'Ex') || (nargin == 4)
    tDur = iExpt.Timing.Texp;
    tDurEx = vec2time(tDur,iExpt.Timing.TexpU);
% else
%     sParaTmp = getappdata(hFig,sprintf('sPara%s',dType));
%     tDurEx = sParaTmp.tDur;
% end

% calculates the duration of all the stimuli blocks
[tDurS,tUnits,tOfsB,tDurB] = ...
            calcExptStimDuration(hFig,sTrainC,sPara,tDur);
tDurSI = max(tOfsB+tDurB);

% determines if the 
for i = 1:length(sPara)
    if ~all(strcmpi({sPara(i).tDurU,sPara(i).tOfsU},tUnits(1)))
        % resets the offset/duration parameters
        [sPara(i).tDurU,sPara(i).tOfsU] = deal(lower(tUnits(1)));

        % updates the parameter struct
        eval(sprintf('sParaEx.%s(i) = sPara(i);',dType));
        setappdata(hFig,'sParaEx',sParaEx);
    end
end

% determines if the total signal train exceeds the experiment duration
if tDurEx < tDurS
    % if so, then setup an error message string
    eStr = sprintf(['The duration of the stimuli train (%.2fh) exceeds ',...
                    'that of the experiment (%.2fh). Do either of ',...
                    'the following to remedy this issue:\n\n',...
                    ' * Reduce the Stimuli Train duration\n',...
                    ' * Increase the Experiment duration'],tDurEx,tDurS);
else
    % determines the duration of the stimuli interval
    tDurInt = vec2time(sPara.tStim,tUnits);
    if tDurSI > tDurInt
        % if the stimuli time exceeds that of the interval, then reset the
        % time interval so that equals the stimuli time
        tDurInt = tDurSI;
        sPara.tStim = time2vec(tDurS,tUnits);
%     else
%         % otherwise, set the stimuli time interval to be 1 hour
%         sPara.tStim = time2vec(1,'h');
    end
    
    % calculates the new signal duration
    tDurNw = (sPara.nCount-1)*tDurInt + tDurSI;
    if tDurNw > tDurEx
        % if the new signal duration exceeds the experiment duration, then
        % reduce the signal train repetition count
        sPara.nCount = floor((tDurNw - tDurSI)/tDurInt) + 1;
        tDurNw = (sPara.nCount-1)*tDurInt + tDurSI;
    end
    
    % updates the duration parameter field
    sPara.tDur = tDurNw;
    
    % updates the parameter struct
    eval(sprintf('sParaEx.%s = sPara;',dType));
    setappdata(hFig,'sParaEx',sParaEx)
    
    % updates the parameter fields on the experimental protocol tab
    iTabEx = cellfun(@(x)(startsWith(get(x,'Title'),dType)),hTabEx);    
    resetExptPara(hFig,hTabEx{iTabEx},sPara)
end

% if there was an error, then output the message to screen
if ~isempty(eStr)
    waitfor(msgbox(eStr,'Stimuli Train Error','modal'))
    ok = false;
end

% --- resets the stimuli train objects
function resetStimTrainObjects(hFig,p0,pNw,dType)

% global parameters
global nProto

% initialisations
sigBlk = getappdata(hFig,'sigBlk');
sBlk = sigBlk{nProto}; 

% retrieves all the field names
resetBlk = false;
pFld = fieldnames(p0);
isDiff = false(length(pFld),1);

% updates the parameters based on those which changed
for i = 1:length(pFld)
    % evaluates the current/new field values
    val0 = eval(sprintf('p0.%s',pFld{i}));
    valNw = eval(sprintf('pNw.%s',pFld{i}));
    
    % determines if there is a difference between the 2 values
    if ~isequal(val0,valNw)
        % updates the difference flags
        isDiff(i) = true;
        
        % updates the program objects depending on which parameter changed
        switch pFld{i}
            case 'sName'
                resetStimTrainNames(hFig,val0,valNw,dType);
                
            case 'blkInfo'
                resetBlk = ~isempty(sBlk);
                
        end
    end
end

% resets the block properties (if the block parameters changed)
if resetBlk    
    % sets the plot axes to be the experiment stimuli axes
    hAx0 = get(hFig,'CurrentAxes');
    set(hFig,'CurrentAxes',getProtoObj(hFig,'axesProto','Ex'));    
    
    % sets the protocol type to the experiment tab
    pType0 = getappdata(hFig,'pType');
    setappdata(hFig,'pType','Experiment Stimuli Protocol')    
    
    % updates the signal block parameters
    for i = 1:length(sBlk)
        % updates the stimuli train information
        uData = get(sBlk{i},'UserData');     
        sTrain = uData{indFcn('sPara')};
        
        %
        if strcmp(sTrain.sName,pNw.sName) 
            % deletes the current stimuli block  
            uData0 = get(sBlk{i},'UserData');
            iBlk0 = getBlockUserData(sBlk{i},'iBlk');
            sType0 = getBlockUserData(sBlk{i},'sType');
            sParaEx0 = getBlockUserData(sBlk{i},'sParaEx');   
            
            % deletes the current stimuli block
            rPos0 = sBlk{i}.getPosition();
            deleteSignalBlock(sBlk{i})   
            
            % sets up the data for the new experiment block
            [uData,rPos] = setupExptObjectInfo(hFig,[],pNw);            
            rPos(1) = rPos0(1);
            uData{indFcn('sType')} = sType0;
            
            % creates a new stimuli block
            sBlk{i} = createExptObject(hFig,uData,rPos,false,false,false);
            
            % resets the experiment block userdata
            updateBlockUserData(sBlk{i},'iBlk',iBlk0);
            updateBlockUserData(sBlk{i},'sParaEx',sParaEx0.sName,'sName');
        end 
    end    
    
    % retrieves the experiment signal blocks    
    sigBlk{nProto} = sBlk;  
    setappdata(hFig,'sigBlk',sigBlk);
    
    %
    resetSignalBlockTimeLimits(hFig,sBlk{1});        
    
    % resets the current axes back to the original
    set(hFig,'CurrentAxes',hAx0);
    setappdata(hFig,'pType',pType0);        
end

% --- case is updating all of the stimuli train names (on updating trains)
function resetStimTrainNames(hFig,val0,valNw,dType)

% retrieves the protocol/experiment stimuli train parameter fields
sTrain = getappdata(hFig,'sTrain');
sTrainP = eval(sprintf('sTrain.%s',dType));

% updates the stimuli trains for current stimuli protocol type
for i = 1:length(sTrainP)
    if strcmp(sTrainP{i}.sName,val0)
        sTrainP{i}.sName = valNw;
    end
end

% updates the stimuli train parameter struct into the gui
eval(sprintf('sTrain.%s = sTrainP;',dType));
setappdata(hFig,'sTrain',sTrain);

% updates the stimuli listbox strings
updateStimTrainLists(hFig,dType,val0,valNw);
updateStimTrainLists(hFig,dType,val0,valNw,'Ex');

% if there are any experimental stimuli trains
if ~isempty(sTrain.Ex)
    % retrieves the experimental signal blocks
    sBlk = getSignalBlock(hFig);
    
    % updates the experiment stimuli train names
    sTrain.Ex.sName(strcmp(sTrain.Ex.sName,val0)) = {valNw};
    
    % updates the stimuli train names 
    for i = 1:length(sTrain.Ex.sTrain)
        if strcmp(sTrain.Ex.sTrain(i).sName,val0)
            % updates the stimuli name within the parameter structs
            sTrain.Ex.sName{i} = valNw;
            sTrain.Ex.sTrain(i).sName = valNw;
            
            % updates the parameter struct within the signal block
            uData = get(sBlk{i},'UserData');
            sPara = uData{indFcn('sPara')};
            sPara.sName = valNw;
            uData{indFcn('sPara')} = sPara;
            set(sBlk{i},'UserData',uData)
        end
    end    
end   

% --- updates the stimuli train lists with the new train names
function updateStimTrainLists(hFig,dType,val0,valNw,pSuf)

% sets the default input arguments
if nargin < 5; pSuf = ''; end

% updates the list strings by swapping out the old string
hList = getProtoObj(hFig,sprintf('listStimTrain%s',pSuf),dType);
[lStr,iSel] = deal(get(hList,'string'),get(hList,'Value'));
lStr(strcmp(lStr,val0)) = {valNw};

% resets the list strings/value
set(hList,'String',lStr,'Value',iSel)

% --- sets up the information for the experiment signal block
function [uData,rPos] = setupExptObjectInfo(hFig,tLimF,sTrainS)

% global parameters
global yGap

% calculates the experiment block time-limits (if not provided)
if isempty(tLimF); tLimF = NaN(1,2); end
if nargin < 3; sTrainS = getSelectedSignalTrainInfo(hFig); end

% if a valid region was selected, then create the new expt object
iCh = getBlockChannelIndices(hFig,sTrainS);

% calculates the experiment duration        
sParaEx = getappdata(hFig,'sParaEx');
[tDurEx0,tDurExU] = calcExptStimDuration(hFig,sTrainS,sParaEx);

% calculates the block duration/time limits (in experiment time units)
iExpt = getappdata(hFig,'iExpt');
tMlt = getTimeMultiplier(iExpt.Timing.TexpU,tDurExU);        
[tDurEx,tLimF] = deal(tDurEx0*tMlt,tLimF*tMlt);

% calculates the block position vector and user data array
sType = getappdata(hFig,'sType');
rPos = [tLimF(1),((iCh(1)-1)+yGap),tDurEx,(range(iCh)+1)-yGap];
uData = setupUserDataArray(hFig,tLimF,sTrainS,sType,iCh([1,end]));

% --- 
function yVal = getBlockUserData(sBlk,uStr)

%
uData = get(sBlk,'UserData');
yVal = uData{indFcn(uStr)};

% --- 
function updateBlockUserData(sBlk,uStr,yVal,yFld)

% retrieves the field from the stimuli block userdata
uData = get(sBlk,'UserData');    

% updates the 
if nargin < 4
    uData{indFcn(uStr)} = yVal;
else
    fldVal = uData{indFcn(uStr)};
    eval(sprintf('fldVal.%s=yVal;',yFld));
    uData{indFcn(uStr)} = fldVal;
end

% updates the userdata field
set(sBlk,'UserData',uData)

% --- deletes all experiment stimuli train objects
function deleteStimTrainObjects(hFig,sTrainR)

% global parameters
global nProto

% initialisations
sigBlk = getappdata(hFig,'sigBlk');
sTrain = getappdata(hFig,'sTrain');
sBlk = sigBlk{nProto};
isKeep = true(length(sBlk),1);

% retrieves the experiment listbox strings/value
hListEx = getProtoObj(hFig,'listStimTrain','Ex');
lStr = get(hListEx,'String');

% goes through the list
for i = 1:length(sBlk)
    % retrieves the stimuli train data
    uData = get(sBlk{i},'UserData');
    sPara = uData{indFcn('sPara')};
    
    % if the current experiment stimuli train matches that being removed,
    % then delete the train objects
    if strcmp(sTrainR.sName,sPara.sName)
        % flag that the list item is to be removed
        isKeep(i) = false;
        
        % deletes the stimuli block
        deleteSignalBlock(sBlk{i}) 
    end
end

% resets the experiment listbox string/value 
if ~all(isKeep)    
    if ~any(isKeep)
        % if there are no stimuli trains left, then exit
        [sigBlk{nProto},sTrain.Ex] = deal([]);
        set(hListEx,'String',[],'Value',[],'Max',2);
    else
        % only keeps the fields that haven't been removed
        sTrain.Ex.sName = sTrain.Ex.sName(isKeep);
        sTrain.Ex.sType = sTrain.Ex.sType(isKeep);
        sTrain.Ex.sParaEx = sTrain.Ex.sParaEx(isKeep);
        sTrain.Ex.sTrain = sTrain.Ex.sTrain(isKeep);
        
        % resets the experiment listbox strings/value
        sigBlk{nProto} = sBlk(isKeep);
        set(hListEx,'String',lStr(isKeep),'Max',2,'Value',[]);
    end        
    
    % updates the stimuli train parameter struct
    setappdata(hFig,'sTrain',sTrain)  
    setappdata(hFig,'sigBlk',sigBlk)  
end

function hZoom = initZoomObject(hFig)

hZoom = zoom;
set(hZoom,'Enable','off','ActionPostCallback',{@setAxesZoomProperties,hFig});   

% --- resets the full experiment panel titles
function resetFullExptPanels(handles)

% retrieves the panel titles
hPanel = get(handles.panelFullExptInfo,'Children');
tStr = arrayfun(@(x)(get(x,'Title')),hPanel,'un',0);

% removes the titles and pauses for update
arrayfun(@(x)(set(x,'Title','')),hPanel)
pause(0.05);

% resets the original titles
cellfun(@(x,t)(set(x,'Title',t)),num2cell(hPanel),tStr);

% --- resets the device type names
function devType = resetDevType(devType)

% converts 'HT ControllerV1' to 'Motor'
devType(strcmp(devType,'HTControllerV1')) = {'Motor'};

% --- sets up the custom video resolution objects
function setupCustResObjects(handles)

% field retrieval
hFig = handles.figExptSetup;
hText = findall(handles.panelVideoRes,'Style','Text');
hEdit = findall(handles.panelVideoRes,'Style','Edit');
infoObj = getappdata(hFig,'infoObj');

% sets the video resolution data struct
vRes = getRecordingResolution(infoObj);
resInfo = struct('useCust',false,'W',vRes(1),'H',vRes(2));
setappdata(hFig,'resInfo',resInfo)

% sets up the editboxes
for i = 1:length(hEdit)
    % updates the editbox properties
    pStr = get(hEdit(i),'UserData');
    dimVal = num2str(getStructField(resInfo,pStr));
    
    % updates the object properties
    set(hEdit(i),'Callback',{@editResDim,handles},...
                 'Enable','off','String',dimVal);
    set(hText(i),'Enable','Off');
end

% --- retrieves the current recording device resolution
function vRes = getRecordingResolution(infoObj)

% retrieves the camera resolution
if infoObj.isWebCam
    vRes = infoObj.objIMAQ.pROI(3:4);
else
    vRes = infoObj.objIMAQ.VideoResolution;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    UNUSED FUNCTIONS?    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- retrieves the current values from the popup duration panel
function tDurV = getPopupDurValues(hPanel)

% memory allocation
tDurV = zeros(1,4);

% retrieves the 
for i = 1:length(tDurV)
    hPopup = findobj(hPanel,'Style','Popupmenu','UserData',i);
    tDurV(i) = get(hPopup,'Value')-1;
end

% --- calculates the scaled experiment time
function tVal = getExptScaledTime(sPara,pStr,dType)

% retrieves time value/units
tVal0 = getExptParaValue(sPara,pStr,dType);
tValU = getExptParaValue(sPara,[pStr,'U'],dType);

% scales the time value to experiment duration units
tVal = tVal0*getTimeMultiplier(sPara.tDurU,tValU);

% ---  disables the fixed duration panel
function setAllVideoProps(handles,eStr)

% sets the panel properties for the 
[isCheck,resetFields] = deal(false,true);

% otherwise, set the video panel properties to the enabled string
setPanelProps(handles.panelVideoPara,eStr)    

if (strcmp(eStr,'on'))
    % disables the frame rate popup menu (if only one selection)
    fStr = get(handles.popupFrmRate,'string');
    if length(fStr) == 1; setObjEnable(handles.popupFrmRate,'off'); end
    
    % determines if the video parameters have been set    
    iExpt = getappdata(hFig,'iExpt');
    if (iExpt.Video.FPS > 0) && (sum(iExpt.Video.Dmax) > 0)
        % if so enable the recording type parameters
        setPanelProps(handles.panelVideoRes,'on') 
        isCheck = all(field2cell(iExpt.Stim,'nCount',1) > 0);
        resetFields = false;
        
    else
        % disables the fixed duration objects panel
        setPanelProps(handles.panelVideoRes,'off')          
    end            
else
    % disables the fixed duration objects panel
    setPanelProps(handles.panelVideoRes,'off')
end
    
% sets the stimulus feasiblilty checkbox value
updateFeasFlag(handles,'checkStimFeas',isCheck)

% sets NaN values for all the info fields (if resetting fields)
if resetFields
    set(handles.textFrmCount,'string','NaN')
    set(handles.textVidCount,'string','NaN')
end

% --- determines if a patch is required to represent a signal block
function usePatch = detIfUsePatch(hAx,xS,yS)

% retrieves the axis limits/position
axPos = get(hAx,'Position');
dtLim = diff(get(hAx,'xlim'))/axPos(3);

% determines if any of the groups (where the signal is non-zeros) is 
% greater than the threshold time limit
iGrp = getGroupIndex(yS>yS(end));
if isempty(iGrp)
    usePatch = true;
else
    usePatch = any(cellfun(@(x)(any(diff(xS(x)) > dtLim)),iGrp));
end
