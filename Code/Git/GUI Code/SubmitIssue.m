function varargout = SubmitIssue(varargin)

% Last Modified by GUIDE v2.5 26-Jul-2020 15:50:04

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SubmitIssue_OpeningFcn, ...
                   'gui_OutputFcn',  @SubmitIssue_OutputFcn, ...
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


% --- Executes just before SubmitIssue is made visible.
function SubmitIssue_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for SubmitIssue
handles.output = hObject;

% sets the input arguments
if isempty(varargin)
    hFig = [];
else
    hFig = varargin{1};
end

% sets up the data structs
[sData,vData] = setupDataStruct();

% sets the fields into the GUI
setappdata(hObject,'hFig',hFig)
setappdata(hObject,'sData',sData)
setappdata(hObject,'vData',vData)

% initialises the object properties
if ~initObjProps(handles,hFig)
    % if there was an error, then exit the GUI
    menuExit_Callback(handles.menuExit, [], handles)
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SubmitIssue wait for user response (see UIRESUME)
% uiwait(handles.figSubmitIssue);

% --- Outputs from this function are returned to the command line.
function varargout = SubmitIssue_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                     FIGURE CALLBACK FUNCTIONS                     %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes when user attempts to close figSubmitIssue.
function figSubmitIssue_CloseRequestFcn(hObject, eventdata, handles)

% runs the exit menu item
menuExit_Callback(handles.menuExit,[],handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                      MENU CALLBACK FUNCTIONS                      %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -------------------------------------------------------------------------
function menuExit_Callback(hObject, eventdata, handles)

% retrieves the main GUI handle
hFig = getappdata(handles.figSubmitIssue,'hFig');

% deletes the GUI and makes the main GUI visible again
delete(handles.figSubmitIssue)

% removes the remote git URL
[~,~] = system('git remote remove origin');

% makes the main GUI visible again
if ~isempty(hFig); set(hFig,'visible','on'); end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                     OBJECT CALLBACK FUNCTIONS                     %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    SUBMIT ISSUES TAB OBJECTS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on key press with focus on editIssueTitle and none of its controls.
function Title_KeyReleaseFcn(hObject, eventdata, handles, jEdit)

% updates the data struct with the new text
sData = getappdata(handles.figSubmitIssue,'sData');
sData.Title = char(jEdit.getText());
setappdata(handles.figSubmitIssue,'sData',sData)

% updates the submit button props
updateSubmitButtonProps(handles)

% --- Executes on selection change in checkComboCallback.
function submitComboCallback(hChk,~,handles)

% retrieves the data struct
sData = getappdata(handles.figSubmitIssue,'sData');

% updates the label
lblChk = num2cell(char(hChk.getSelectedItem()),2);
sData.Label = cellfun(@(x)(strrep(x,' ','')),lblChk,'un',0);

% updates the data struct
setappdata(handles.figSubmitIssue,'sData',sData)

% updates the submit button props
updateSubmitButtonProps(handles)

% --- Executes on key press with focus on editIssueDesc and none of its controls.
function Desc_KeyReleaseFcn(hObject, eventdata, handles, jEdit)

% updates the data struct with the new text
sData = getappdata(handles.figSubmitIssue,'sData');
sData.Body = char(jEdit.getComponent(0).getComponent(0).getText);
setappdata(handles.figSubmitIssue,'sData',sData)

% updates the submit button props
updateSubmitButtonProps(handles)

% --- Executes on button press in buttonSubmitIssue.
function buttonSubmitIssue_Callback(hObject, eventdata, handles)

% prompts the user if they want to continue
qStr = 'Are you sure you want to continue with submitting this issue?';
uChoice = questdlg(qStr,'Issue Submission Confirmation','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    % if the user cancelled, then exit the function
    return
end

% creates a loadbar
h = ProgressLoadbar('Creating New Issue...');

% updates the data struct with the new text
sData = getappdata(handles.figSubmitIssue,'sData');

% creates and runs the command string
ghCmd = sprintf('gh issue create -t "%s" -b "%s" -l "%s"',...
        sData.Title,sData.Body,cell2mat(join(sData.Label,',')));
[~,~] = system(ghCmd);

% enables the update list button
set(handles.buttonUpdateList,'enable','on')

% closes the loadbar
delete(h)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    VIEW ISSUES TAB OBJECTS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- executes on updating editIssueCount
function editIssueCount_Callback(hObject, eventdata, handles)

% retrieves the view status data struct
vData = getappdata(handles.figSubmitIssue,'vData');

% determines if the new value is valid
nwVal = str2double(get(hObject,'string'));
if chkEditValue(nwVal,[1,100],1)
    % updates the value in the data struct
    vData.Count = nwVal;
    setappdata(handles.figSubmitIssue,'vData',vData);
    
    % resets the update button enabled properties
    resetUpdateButtonProps(handles,vData)
else
    % otherwise, reset the value 
    set(hObject,'string',num2str(vData.Count))
end

% --- Executes on button press in checkNoLabelFilt.
function checkNoLabelFilt_Callback(hObject, eventdata, handles)

% retrieves the view status data struct
vData = getappdata(handles.figSubmitIssue,'vData');
vData.NoFilt = get(hObject,'value');
setappdata(handles.figSubmitIssue,'vData',vData)

% updates the label filter object properties
setObjEnable(handles.textLabelFilter,~vData.NoFilt)
setObjEnable(get(hObject,'UserData'),~vData.NoFilt)

% resets the update button enabled properties
resetUpdateButtonProps(handles,vData)

% --- Executes on selection change in checkComboCallback.
function viewComboCallback(hChk,~,handles)

% retrieves the data struct
vData = getappdata(handles.figSubmitIssue,'vData');

% updates the label
lblChk = num2cell(char(hChk.getSelectedItem()),2);
vData.Label = cellfun(@(x)(strrep(x,' ','')),lblChk,'un',0);

% updates the data struct
setappdata(handles.figSubmitIssue,'vData',vData)

% resets the update button enabled properties
resetUpdateButtonProps(handles,vData)

% --- Executes when selected object is changed in panelIssueStatus.
function panelIssueStatus_SelectionChangedFcn(hObject, eventdata, handles)

% retrieves the data struct
vData = getappdata(handles.figSubmitIssue,'vData');

% updates the status field and resets the data struct
vData.Status = get(eventdata.NewValue,'UserData');
setappdata(handles.figSubmitIssue,'vData',vData)

% resets the update button enabled properties
resetUpdateButtonProps(handles,vData)

% --- Executes on button press in buttonUpdateList.
function buttonUpdateList_Callback(hObject, eventdata, handles)

% retrieves the data struct
vData = getappdata(handles.figSubmitIssue,'vData');

% creates a loadbar
h = ProgressLoadbar('Updating Issue Filter...');

% sets the issue list string
ghCmd = sprintf('gh issue list -s "%s" -L %i',vData.Status,vData.Count);
if ~vData.NoFilt
    % adds the label filter (if required)
    ghCmd = sprintf('%s -l "%s"',ghCmd,cell2mat(join(vData.Label,',')));
end

% runs the command and retrieves the output
[~,ghStr] = system(ghCmd);
if isempty(ghStr)
    % if there is no matches, then reset the listbox
    ghData = [];
    set(handles.listIssueList,'string',[],'max',2,'value',[])
else
    % otherwise, split up the command output into its components
    ghData0 = strsplit(ghStr(1:end-1),'\n');
    ghDataS = cellfun(@(x)(strsplit(x,'\t')),ghData0(:),'un',0);
    
    % resets any labels that are missing
    nC = cellfun(@length,ghDataS);
    for i = find(nC' == 4)
        ghDataS{i} = [ghDataS{i}(1:3),{''},ghDataS{i}(4)];
    end

    % updates the list strings/selection
    ghData = cell2cell(ghDataS);
    set(handles.listIssueList,'string',ghData(:,3),'max',1,'value',1)
end

% updates the data within the GUI
setappdata(handles.figSubmitIssue,'ghData',ghData)
setappdata(handles.figSubmitIssue,'lblStr',cell(size(ghData,1),1))
setappdata(handles.figSubmitIssue,'nComment',cell(size(ghData,1),1))

% calls the list update function
listIssueList_Callback(handles.listIssueList, [], handles)

% deletes the loadbar and disables the button
delete(h)
set(hObject,'enable','off')

% --- Executes on button press in pushWebView.
function pushWebView_Callback(hObject, eventdata, handles)

% initialisations
iSel = get(handles.listIssueList,'value');
ghData = getappdata(handles.figSubmitIssue,'ghData');

% creates a loadbar
h = ProgressLoadbar('Loading Web Browser...');

% opens the browser for the selected issue
[~,~] = system(sprintf('gh issue view %s -w',ghData{iSel,1}));

% closes the loadbar
delete(h)

% --- Executes on selection change in listIssueList.
function listIssueList_Callback(hObject, eventdata, handles)

% initialisations
[eStr,h] = deal({'off','on'},[]);
ghData = getappdata(handles.figSubmitIssue,'ghData');
lblStr = getappdata(handles.figSubmitIssue,'lblStr');
nComment = getappdata(handles.figSubmitIssue,'nComment');

% retrieves all the label button object handles
hLblBut = findall(handles.panelLabels,'style','pushbutton');

% retrieves the issue data fields
if isempty(ghData)
    % if empty, then reset the strings to N/A
    set(handles.textCommentCount,'string','N/A')
    set(handles.textIssueStatus,'string','N/A') 
    set(hLblBut,'visible','off')
    
    % makes all the label buttons invisible
    set(hLblBut,'visible','off')
else
    % otherwise, retrieve the current selection
    iSel = get(hObject,'value');
    set(hLblBut,'visible','off')    
    
    % views the actual issue 
    if isempty(nComment{iSel})
        % creates a progress bar
        if ~isempty(eventdata) && ~isempty(ghData)
            h = ProgressLoadbar('Retrieve Issue Data...');
        end
        
        [~,ghView0] = system(sprintf('gh issue view %s',ghData{iSel,1}));
        ghView = strsplit(ghView0(1:end-1),'\n');

        % retrieves the comment count line
        cLine = strsplit(ghView{cellfun(@(x)(...
                                startsWith(x,'comments:')),ghView)},'\t');
        lLine = strsplit(ghView{cellfun(@(x)(...
                                startsWith(x,'labels:')),ghView)},'\t');                       
                            
        % updates label strings
        [lblStr{iSel},nComment{iSel}] = deal(lLine{2},cLine{2});
        setappdata(handles.figSubmitIssue,'lblStr',lblStr)
        setappdata(handles.figSubmitIssue,'nComment',nComment)
    end
    
    % updates the label button values
    lStr = strsplit(lblStr{iSel},', ');    
    for i = 1:min(length(lStr),length(hLblBut))
        if ~isempty(lStr{i})
            hBut = findall(hLblBut,'UserData',i);
            set(hBut,'visible','on','string',lStr{i},...
                     'backgroundcolor',hex2rgb(getLabelColour(lStr{i})),...
                     'tooltipstring',getLabelTTString(lStr{i}))
        end
    end
    
    % updates the comment count/issue status strings
    set(handles.textCommentCount,'string',nComment{iSel})
    set(handles.textIssueStatus,'string',ghData{iSel,2})    
end

% disables the objects from the label panel properties
isOK = ~isempty(ghData);
setObjEnable(handles.pushWebView,isOK)
setObjEnable(handles.panelLabels,isOK)
setObjEnable(handles.panelIssueDetails,isOK)

% deletes the loadbar (if it exists)
if ~isempty(h); delete(h); end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                          OTHER FUNCTIONS                          %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- initialises the object properties
function ok = initObjProps(handles,hFig)

% global variables
global mainProgDir
cd(mainProgDir)

% java import
import javax.swing.*

% memory allocation
ok = true;
tStr = {'Submit','View'};
hTab = cell(length(tStr),1);
sLblStr = {'bug','help','question','request'};
vLblStr = {'bug','documentation','feature','help','question','request'};

% makes the main GUI invisible
if ~isempty(hFig); set(hFig,'visible','off'); end

% resets the remote git URL to the DARTIssues repository
gitURL = 'https://github.com/BFKLabs/DARTIssues';
[~,~] = system('git remote remove origin');
[~,~] = system(sprintf('git remote add -f origin %s',gitURL));

% determines if the config file exists
cfigDir = fullfile(getenv('USERPROFILE'),'.config','gh');
if ~exist(cfigDir,'dir')
    % if the config file doesn't exist, then re-initialise
    initGHConfig(0);
else
    % runs a test of the github cli
    [~,ghTest] = system('gh issue list -L 1');
    if strContains(ghTest,'HTTP 401')
        % if there was an issue, then delete the folder and reset
        rmdir(cfigDir,'s')
        initGHConfig(1);
    end
end

% creates the tab groups
hTabGrp = createTabPanelGroup(handles.panelOuter,1);
for i = 1:length(tStr)
    % creates the new tab
    hTab{i} = uitab('Parent',hTabGrp,'Title',sprintf('%s Issue',tStr{i}));

    % sets the corresponding panel parent's the the new tab
    hPanel = eval(sprintf('handles.panel%sIssue',tStr{i}));
    set(hPanel,'Parent',hTab{i});
end

% sets up the checkbox popup lists
setupCheckboxList(handles.panelSubmitIssue,sLblStr,...
       [540,337,130,23],{@submitComboCallback,handles},'submitCheckBox');
hView = setupCheckboxList(handles.panelViewFilter,vLblStr,...
       [90,6,140,23],{@viewComboCallback,handles},'viewCheckBox'); 
set(hView,'Enabled',0)   

% sets the checkbox view object into the No Label Filter checkbox
set(handles.radioOpen,'Value',1)
set(handles.checkNoLabelFilt,'UserData',hView);

% disables the objects from the label panel properties
setPanelProps(handles.panelLabels,'off')
setPanelProps(handles.panelIssueDetails,'off')
set(findall(handles.panelLabels,'style','pushbutton'),'visible','off')

% sets the callback function for the issue title
tCbFcn = {@Title_KeyReleaseFcn,handles,findjobj(handles.editIssueTitle)};
set(handles.editIssueTitle,'KeyReleaseFcn',tCbFcn)

% sets the callback function for the issue description
dCbFcn = {@Desc_KeyReleaseFcn,handles,findjobj(handles.editIssueDesc)};
set(handles.editIssueDesc,'KeyReleaseFcn',dCbFcn)

% --- updates the submit button properties
function updateSubmitButtonProps(handles)

% initialisations
sData = getappdata(handles.figSubmitIssue,'sData');

% updates the button properties
subData = {sData.Title,sData.Label,sData.Body};
isOK = all(cellfun(@(x)(~isempty(x)),subData));
setObjEnable(handles.buttonSubmitIssue,isOK)

% --- resets the update button enabled properties
function resetUpdateButtonProps(handles,vData)

% sets the update button enabled properties
if vData.NoFilt
    % if no label filter, then enable the update list button
    setObjEnable(handles.buttonUpdateList,'on')
else
    % otherwise, set the enabled properties based on the label list
    setObjEnable(handles.buttonUpdateList,'enable',~isempty(vData.Label))
end

% --- initialises the issue submission data struct
function [sData,vData] = setupDataStruct()

% submit issue data struct
sData = struct('Title',[],'Label',{'bug'},'Body',[]);

% view issue data struct
vData = struct('Count',30,'NoFilt',1,'Label',{'bug'},'Status','open');

% --- sets up the checkbox popup-list object
function hCB = setupCheckboxList(hPanel,cLblStr,cPos,cbFcn,tStr)

% create CheckBoxListComboBox
jCB = com.jidesoft.combobox.CheckBoxListComboBox(cLblStr);
[hCB, hJavaCBWrapper] = javacomponent(jCB, [], hPanel); 
set(hJavaCBWrapper,'Units','pixels','Position',cPos);

% direct access
hCB.setSelectedIndices(0);
hCB.putClientProperty('TabCycleParticipant', true);  
set(hCB,'PropertyChangeCallback',cbFcn,'Name',tStr);

% --- retrieves the label colour (based on the type)
function lCol = getLabelColour(lStr)

switch lStr
    case 'bug' % case is a bug
        lCol = '#d73a4a';
    case 'documentation' % case is documentation
        lCol = '#0075ca';
    case 'feature' % case is a feature
        lCol = '#a2eeef';
    case 'help' % case is a help issue
        lCol = '#008672';
    case 'question' % case is a question
        lCol = '#d876e3';
    case 'request' % case is a request
        lCol = '#fbca04';
end

% --- retrieves the label tooltip string (based on the type)
function ttStr = getLabelTTString(lStr)

switch lStr
    case 'bug' % case is a bug
        ttStr = 'An error within the program';
    case 'documentation' % case is documentation
        ttStr = 'Improvements or additions to documentation';
    case 'feature' % case is a feature
        ttStr = 'New feature added to the program';
    case 'help' % case is a help issue
        ttStr = 'Assistance about using the program';
    case 'question' % case ia a question
        ttStr = 'Further information is requested';
    case 'request' % case is a request
        ttStr = 'A user request for a new feature';
end

% --- re-initialises the GitHub CLI config files
function initGHConfig(type)

%
switch (type)
    case 0
        eStr = sprintf(['The Github CLI configuration files are ',...
                        'missing.\nFollow the prompts to initialise ',...
                        'the configuration files.']);
    case 1
        eStr = sprintf(['There is an error with the GitHub CLI ',...
                        'authentication.\nFollow the prompts to ',...
                        'initialise the configuration files.']);               
end

% outputs the error to screen
waitfor(errordlg(eStr,'Configuration Error!','modal'))

% runs a simple command to force reconfiguration
cmdExe = fullfile(getenv('windir'),'system32','cmd.exe');
proc = System.Diagnostics.Process.Start(cmdExe,'/C gh issue list');
proc.WaitForExit();