function varargout = AnalysisFunc(varargin)
% Last Modified by GUIDE v2.5 04-Sep-2021 00:23:31

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
setappdata(hObject,'fName',fName0)
setappdata(hObject,'fDir',fDir0)
setappdata(hObject,'isDef',true(length(fDir0),1))

% initialises the GUI objects
initGUIObjects(handles)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes AnalysisFunc wait for user response (see UIRESUME)
uiwait(handles.figAnalyFunc);


% --- Outputs from this function are returned to the command line.
function varargout = AnalysisFunc_OutputFcn(hObject, eventdata, handles) 

% global variables
global fDir fName isDef pkgName

% Get default command line output from handles structure
varargout{1} = fDir;
varargout{2} = fName;
varargout{3} = isDef;
varargout{4} = pkgName;

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

% --- Executes when entered data in editable cell(s) in tableAnalyFunc.
function tableAnalyFunc_CellEditCallback(hObject, eventdata, handles)

% determines the number of selected files
Data = get(hObject,'Data');
nFunc = sum(cell2mat(Data(:,2)));

% updates the function count label
set(handles.textFuncCount,'string',num2str(nFunc))
setObjEnable(handles.buttonCont,nFunc>0)

% --- Executes when entered data in editable cell(s) in tableExternPkg.
function tableExternPkg_CellEditCallback(hObject, eventdata, handles)

% determines the number of selected files
Data = get(hObject,'Data');
nPkg = sum(cell2mat(Data(:,2)));

% updates the function count label
set(handles.textPkgCount,'string',num2str(nPkg))

% --- Executes on button press in buttonCont.
function buttonCont_Callback(hObject, eventdata, handles)

% global variables
global fDir fName isDef pkgName

% retrieves the final analysis function names
hFig = handles.figAnalyFunc;
fDir0 = getappdata(hFig,'fDir');
isDef0 = getappdata(hFig,'isDef');
pkgDir = getappdata(hFig,'pkgDir');

% retrieves the table data
fcnData = get(handles.tableAnalyFunc,'Data');
pkgData = get(handles.tableExternPkg,'Data');

% sets the function name/directories
isSel = cell2mat(fcnData(:,2));
[fName,isDef,fDir] = deal(fcnData(isSel,1),isDef0(isSel),fDir0(isSel));

% retrieves the package name data
if isempty(pkgData)
    % case is no packages were detected
    pkgName = [];
else
    % otherwise, determine the selected packages
    pkgName0 = pkgData(cell2mat(pkgData(:,2)),1);
    if isempty(pkgName0)
        pkgName = [];
    else
        pkgName = cellfun(@(x)(fullfile(pkgDir,x)),pkgName0,'un',0);
    end
end

% deletes the GUI
delete(hFig)

% --- Executes on button press in buttonCancel.
function buttonCancel_Callback(hObject, eventdata, handles)

% global variables
global fDir fName isDef pkgName

% retrieves the final analysis function names
hFig = handles.figAnalyFunc;
[isDef,fDir,fName,pkgName] = deal([]);

% deletes the GUI
delete(hFig)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% ---------------------------- %
% --- GUI UPDATE FUNCTIONS --- %
% ---------------------------- %

% --- initialises the GUI objects
function initGUIObjects(handles)

% retrieves the final analysis function names
hFig = handles.figAnalyFunc;

% sets the function table data
fcnName = sort(getappdata(hFig,'fName'));
fcnData = [fcnName,num2cell(true(length(fcnName),1))];

% sets the external app field string
pkgDir = getProgFileName('Code','External Apps');
if exist(pkgDir,'dir')
    % if it exists, then determine the valid packages
    fDir = dir(pkgDir);
    fDirS = field2cell(fDir,'name');
    setappdata(hFig,'pkgDir',pkgDir)
    
    % determines the valid package directories
    isValid = ~(strContains(fDirS,'.') | startsWith(fDirS,'Z - '));
    if any(isValid)
        % if there are valid packages, then set the table data
        pkgData = [fDirS(isValid),num2cell(false(sum(isValid),1))];
    else
        % otherwise, set an empty table data array
        pkgData = [];
    end
else
    % otherwise, set an empty array
    pkgData = [];
end

% sets the list/static text strings
set(handles.tableAnalyFunc,'Data',fcnData)
set(handles.tableExternPkg,'Data',pkgData)
set(handles.textFuncCount,'string',num2str(length(fcnName)))
set(handles.textPkgCount,'string','0')

% auto-resizes the table columns
autoResizeTableColumns(handles.tableAnalyFunc)
autoResizeTableColumns(handles.tableExternPkg)

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
if ~onPath; rmpath(fDir); end

