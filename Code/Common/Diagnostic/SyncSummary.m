function varargout = SyncSummary(varargin)
% Last Modified by GUIDE v2.5 03-Aug-2016 11:14:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SyncSummary_OpeningFcn, ...
                   'gui_OutputFcn',  @SyncSummary_OutputFcn, ...
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


% --- Executes just before SyncSummary is made visible.
function SyncSummary_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for SyncSummary
handles.output = hObject;

% makes the main GUI visible
if ~isempty(varargin)
    hGUI = varargin{1};
    setObjVisibility(hGUI,'off')
    setappdata(hObject,'hGUI',hGUI)
else
    setappdata(hObject,'hGUI',[])
end

% initialises the file name data struct
setappdata(hObject,'iData',struct('PrimSumm',[],'SecSumm',[]));

% initialises the default directory buttons
initDefButton(handles)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SyncSummary wait for user response (see UIRESUME)
% uiwait(handles.figSyncSummary);

% --- Outputs from this function are returned to the command line.
function varargout = SyncSummary_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;


%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes on button press in buttonSync.
function buttonSync_Callback(hObject, eventdata, handles)

% loads the summary files
iData = getappdata(handles.figSyncSummary,'iData');
[AP,AS] = deal(load(iData.PrimSumm),load(iData.SecSumm));

%
if ((isempty(AP.tStampS)) && (~isempty(AS.tStampS)))
    % primary file does not have the stimuli time stamps, but the secondary
    % file does
    sFile = iData.PrimSumm;
    dT = calcTimeDifference(AS.iExpt.Timing.T0,AP.iExpt.Timing.T0);
    [tStampS,iStim] = deal(AS.tStampS,AS.iStim);
    
    % resets the stimuli experimental data struct
    iExpt = AP.iExpt;
    iExpt.Stim = AS.iExpt.Stim;
elseif ((isempty(AS.tStampS)) && (~isempty(AP.tStampS)))
    % secondary file does not have the stimuli time stamps, but the primary
    % file does
    sFile = iData.SecSumm;
    dT = calcTimeDifference(AP.iExpt.Timing.T0,AS.iExpt.Timing.T0);
    [tStampS,iStim] = deal(AP.tStampS,AP.iStim);
    
    % resets the stimuli experimental data struct
    iExpt = AS.iExpt;
    iExpt.Stim = AP.iExpt.Stim;    
else
    % no need for update, so exit
    return
end

% alters the stimuli event times by the difference in the experiment start
% times
tStampS = cellfun(@(x)(x+dT),tStampS,'un',0);

% makes a copy of the file (creates new directory)
[fDir,fName,~] = fileparts(sFile);
fDirNw = fullfile(fDir,'Original');

% creates a new directory and outputs the file
if (~exist(fDirNw,'dir')); mkdir(fDirNw); end
sFileNew = fullfile(fDirNw,[fName,'.mat']);
copyfile(sFile,sFileNew,'f')

% overwrites the fields in the summary file
save(sFile,'tStampS','-append')
save(sFile,'iStim','-append')
save(sFile,'iExpt','-append')

% --- Executes on button press in buttonClose.
function buttonClose_Callback(hObject, eventdata, handles)

% retrieves the main GUI handle
hGUI = getappdata(handles.figSyncSummary,'hGUI');

% closes the GUI
delete(handles.figSyncSummary)

% makes the main GUI visible again
if ~isempty(hGUI); setObjVisibility(hGUI,'on'); end

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the default directory/file pushbutton properties --- %
function initDefButton(handles)

% sets the variable tag strings
wStr = {'PrimSumm','SecSumm'};

% sets the call back function for all the GUI buttons
for i = 1:length(wStr)
    % sets up the object callback function
    hObj = eval(sprintf('handles.button%s;',wStr{i}));
    bFunc = @(hObj,e)SyncSummary('setDefDir',hObj,[],guidata(hObj));
    
    % sets the object callback function
    set(hObj,'UserData',wStr{i},'callback',bFunc);
end

% disables the sync button
setObjEnable(handles.buttonSync,'off')

% --- callback function for the default directory setting buttons --- %
function setDefDir(hObject, eventdata, handles)

% retrieves the default directory corresponding to the current object
wStr = get(hObject,'UserData');

% prompts the user for the new default directory
[fName,fDir,fIndex] = uigetfile({'*.mat','Matlab Files (*.mat)'},...
                                 'Select A Summary File');
if (fIndex)
    % sets the full file name and checks to see if it is valid
    fFile = fullfile(fDir,fName);
    if (checkSummaryFile(handles,fFile,wStr))
        % if valid, update the corresponding field 
        iData = getappdata(handles.figSyncSummary,'iData');
        eval(sprintf('iData.%s = fFile;',wStr));
        setappdata(handles.figSyncSummary,'iData',iData);           
    else
        % otherwise, reset to the last valid file name
        fFile = eval(sprintf('iData.%s',wStr));
    end
            
    % resets the enabled properties of the buttons
    hEdit = sprintf('handles.edit%s',wStr);
    set(eval(hEdit),'string',['  ',fFile])
    setOtherButton(handles)
end

% --- sets the properties of the sync button (depending if both the primary
%     and secondary summary files are set and are correct)
function setOtherButton(handles)

% initialisations
iData = getappdata(handles.figSyncSummary,'iData');

% if both fields have been set, then enable the sync button
isOK = ~isempty(iData.PrimSumm) && ~isempty(iData.SecSumm);
setObjEnable(handles.buttonSync,isOK)

% --- determines if the selected summary file is correct
function ok = checkSummaryFile(handles,fFile,wStr)

% retrieves the data struct and sets the summary file field names
iData = getappdata(handles.figSyncSummary,'iData');
fStr = {'iExpt','iStim','tStampV','tStampS','sData','iMov'};

% determines if the file has already been set
switch (wStr)
    case ('PrimSumm')
        ok = ~strcmp(fFile,iData.SecSumm);
    case ('SecSumm')
        ok = ~strcmp(fFile,iData.PrimSumm);
end

% if the file has already been selected, then exit with an error
if (~ok)
    eStr = sprintf('The following file has already been selected:\n\n  => %s',fFile);
    waitfor(errordlg(eStr,'Duplicate File Selection','modal'))
    return
end

% otherwise, load the file and determine if the fields are correct
A = load(fFile);
ok = all(cellfun(@(x)(any(strcmp(x,fStr))),fieldnames(A)));

% if not all the fields are present, then exit with an error
if (~ok)
    eStr = sprintf('The following file is not a correct summary file:\n\n  => %s',fFile);
    waitfor(errordlg(eStr,'Incorrect Summary File','modal'))    
end
