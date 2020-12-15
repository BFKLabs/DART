function varargout = AnalysisFunc(varargin)
% Last Modified by GUIDE v2.5 08-Apr-2016 16:18:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AnalysisFunc_OpeningFcn, ...
                   'gui_OutputFcn',  @AnalysisFunc_OutputFcn, ...
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


% --- Executes just before AnalysisFunc is made visible.
function AnalysisFunc_OpeningFcn(hObject, eventdata, handles, varargin)

% global variables
global fDir fName isDef

% Choose default command line output for AnalysisFunc
handles.output = hObject;

% sets the input arguments
ProgDef = varargin{1};
FuncDir = ProgDef.Analysis.DirFunc;

% determines the initial analysis functions
fName0 = field2cell(dir(fullfile(FuncDir,'*.m')),'name');
if (isempty(fName0))
    % if there are no analysis functions, then exit the GUI with an empty
    % array (this will prevent the executable from being made)
    [fDir,fName,isDef] = deal([]); delete(hObject)
    return
else
    % otherwise, set the directory names
    fDir0 = repmat({FuncDir},length(fName0),1);
end
    
% sets the arrays into the GUI
setappdata(hObject,'FuncDir',FuncDir)
setappdata(hObject,'fName0',fName0)
setappdata(hObject,'fDir0',fDir0)
setappdata(hObject,'isDef0',true(length(fDir0),1))

% initialises the GUI objects
initGUIObjects(handles)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes AnalysisFunc wait for user response (see UIRESUME)
uiwait(handles.figAnalyFunc);


% --- Outputs from this function are returned to the command line.
function varargout = AnalysisFunc_OutputFcn(hObject, eventdata, handles) 

% global variables
global fDir fName isDef

% Get default command line output from handles structure
varargout{1} = fDir;
varargout{2} = fName;
varargout{3} = isDef;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes on selection change in listAnalyFunc.
function listAnalyFunc_Callback(hObject, eventdata, handles)

% determines the indices of the files that have been selected
iSel = get(hObject,'value');
if (length(iSel) == 1)
    % if only one file selected, update the function path string
    fDir = getappdata(handles.figAnalyFunc,'fDir');    
    set(handles.textFuncPath,'string',fDir{iSel},'tooltipstring',fDir{iSel})
else
    % otherwise, give a generic statement for the string
    set(handles.textFuncPath,'string','Multiple Files Selected','tooltipstring','')
end

% ------------------------------- %
% --- PROGRAM CONTROL BUTTONS --- %
% ------------------------------- %

% --- Executes on button press in buttonAdd.
function buttonAdd_Callback(hObject, eventdata, handles)

% retrieves the default analysis function directory
FuncDir = getappdata(handles.figAnalyFunc,'FuncDir');

% user is manually selecting file to open
[fName,fDir,fIndex] = uigetfile(...
                {'*.m','Matlab M-Files (*.m)'},'Select A File',FuncDir,...
                'MultiSelect','on');
if (fIndex)       
    % sets the names of the new files
    if (~iscell(fName)); fName = {fName}; end
    fName = reshape(fName,length(fName),1);
           
    % determines if the new files are valid
    fName0 = getappdata(handles.figAnalyFunc,'fName');
    fNameNw = fName(checkFuncFileValidity(fDir,fName,fName0));
    if (~isempty(fNameNw))
        % set the new file directory names
        fDirNw = repmat({fDir},length(fNameNw),1);
        isDefNw = strcmp(fDirNw,FuncDir);
        
        % updates the GUI objects
        updateGUIObjects(handles,[fName0;fNameNw])

        % resets the function flags and directory/file names 
        setappdata(handles.figAnalyFunc,'isDef',...
                        [getappdata(handles.figAnalyFunc,'isDef');isDefNw])
        setappdata(handles.figAnalyFunc,'fDir',...
                        [getappdata(handles.figAnalyFunc,'fDir');fDirNw])
        setappdata(handles.figAnalyFunc,'fName',...
                        [getappdata(handles.figAnalyFunc,'fName');fNameNw])    
    end
end

% --- Executes on button press in buttonRemove.
function buttonRemove_Callback(hObject, eventdata, handles)

% prompts the user if they do want to remove the analysis functions
uChoice = questdlg('Are you sure you want to remove the selected functions?',...
                   'Remove Selected Functions','Yes','No','Yes');
if (strcmp(uChoice,'Yes'))    
    % retrieves the final analysis function names
    isDef = getappdata(handles.figAnalyFunc,'isDef');
    fDir = getappdata(handles.figAnalyFunc,'fDir');
    fName = getappdata(handles.figAnalyFunc,'fName');    
    
    % determines the indices of the selected functions
    isKeep = true(length(fName),1);
    isKeep(get(handles.listAnalyFunc,'value')) = false;    
    if (~any(isKeep))
        % must be at least one function added to the executable
        eStr = 'Error! At least one analysis function must be added to executable';
        waitfor(errordlg(eStr,'Function Removal Error','modal'))
        return
    end
    
    % removes from the data arrays the files that are not to be kept
    [isDef,fDir,fName] = deal(isDef(isKeep),fDir(isKeep),fName(isKeep));
    
    % updates the data arrays into the GUI
    setappdata(handles.figAnalyFunc,'isDef',isDef)
    setappdata(handles.figAnalyFunc,'fDir',fDir)
    setappdata(handles.figAnalyFunc,'fName',fName)    
    
    % updates the GUI objects
    updateGUIObjects(handles,fName)
end

% --- Executes on button press in buttonReset.
function buttonReset_Callback(hObject, eventdata, handles)

% re-initialises the GUI objects
initGUIObjects(handles)

% --- Executes on button press in buttonCont.
function buttonCont_Callback(hObject, eventdata, handles)

% global variables
global fDir fName isDef

% retrieves the final analysis function names
isDef = getappdata(handles.figAnalyFunc,'isDef');
fDir = getappdata(handles.figAnalyFunc,'fDir');
fName = getappdata(handles.figAnalyFunc,'fName');

% deletes the GUI
delete(handles.figAnalyFunc)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% ---------------------------- %
% --- GUI UPDATE FUNCTIONS --- %
% ---------------------------- %

% --- initialises the GUI objects
function initGUIObjects(handles)

% retrieves the final analysis function names
isDef = getappdata(handles.figAnalyFunc,'isDef0');
fDir = getappdata(handles.figAnalyFunc,'fDir0');
fName = getappdata(handles.figAnalyFunc,'fName0');

% updates the GUI objects
updateGUIObjects(handles,fName)

% resets the function flags and directory/file names 
setappdata(handles.figAnalyFunc,'isDef',isDef)
setappdata(handles.figAnalyFunc,'fDir',fDir)
setappdata(handles.figAnalyFunc,'fName',fName)

% --- updates the GUI objects
function updateGUIObjects(handles,fName)

% sorts the file names in alphabetical order
fName = sort(fName);

% sets the list/static text strings
set(handles.listAnalyFunc,'string',fName,'value',[])
set(handles.textFuncCount,'string',num2str(length(fName)))
set(handles.textFuncPath,'string','N/A')

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% --- checks to see if the function file are valid
function isOK = checkFuncFileValidity(fDir,fName,fName0)

% memory allocation and other initialisations
isOK = true(length(fName),1);
fStr = {'Name','fType','Type','Name'};

% determines if the directory is on the path
pathCell = regexp(path, pathsep, 'split');
onPath = any(strcmpi(fDir, pathCell));

% adds the directory to the known paths (if missing)
if (~onPath); addpath(fDir); end

% loops through each file determining their validity
for i = 1:length(fName)
    if (any(strcmp(fName0,fName{i})))
        % function name already included in list
        isOK(i) = false;
    else
        try
            % runs the function 
            fcn = eval(sprintf('@%s',getFileName(fName{i})));
            A = feval(fcn); 

            % checks if the correct fields are included in the data struct
            for j = 1:length(fStr)
                if (~isfield(A,fStr{j}))
                    % if not, then flag file as not a valid function
                    isOK(i) = false;
                    break
                end
            end
        catch
            % error occured, so not a valid function
            isOK(i) = false;
        end
    end
end

% remove directory from the known paths (if originally not on the path)
if (~onPath); rmpath(fDir); end
