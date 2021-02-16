function varargout = DirTree(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DirTree_OpeningFcn, ...
                   'gui_OutputFcn',  @DirTree_OutputFcn, ...
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


% --- Executes just before DirTree is made visible.
function DirTree_OpeningFcn(hObject, eventdata, handles, varargin)

% global variables
global h movFile hMov
[movFile,hMov] = deal([]);

% Choose default command line output for DirTree
wState = warning('off','all');
handles.output = hObject;

% sets the input variables 
fType = varargin{1}{1};
defDir = varargin{2};

% sets the data arrays into the GUI
setappdata(hObject,'fType',fType)
setappdata(hObject,'defDir',defDir)
setappdata(hObject,'sDir',[]);

% sets the title based on the GUI it was called from
if (~isempty(findobj(0,'tag','figFlyTrack')))
    % case is the figure fly 
    set(hObject,'Name','Batch Process Movie Files')
    set(handles.panelMovieInfo,'Title','BATCH PROCESSING MOVIE INFORMATION')
elseif (~isempty(findobj(0,'tag','figMultCombInfo')))
    set(hObject,'Name','Experimental Solution File Selection')
    set(handles.panelMovieInfo,'Title','EXPERIMENTAL SOLUTION FILE INFORMATION')
elseif (~isempty(findobj(0,'tag','figFlyCombine')))
    set(hObject,'Name','Video Solution File Selection')
    set(handles.panelMovieInfo,'Title','VIDEO SOLUTION FILE INFORMATION')    
end

% initialises the GUI objects
createDirTreePanel(handles)

% sets the GUI object properties
setPanelPropsLocal(handles.panelMovieInfo,'off')
setObjEnable(handles.buttonContinue,'off')
set(handles.textFileType,'string',fType)
centreFigPosition(hObject);
warning(wState);

% Update handles structure
guidata(hObject, handles);
h = handles;

% UIWAIT makes DirTree wait for user response (see UIRESUME)
uiwait(handles.figDirTree);

% --- Outputs from this function are returned to the command line.
function varargout = DirTree_OutputFcn(hObject, eventdata, handles) 

% global variables
global fList sDir

% Get default command line output from handles structure
varargout{1} = fList;
varargout{2} = sDir;

%-------------------------------------------------------------------------%
%                       GUI OBJECT CALLBACK FUNCTIONS                     %
%-------------------------------------------------------------------------%

% --- Executes on button press in buttonSearchDir.
function buttonSearchDir_Callback(hObject, eventdata, handles)

% retrieves the program default struct
defDir = getappdata(handles.figDirTree,'defDir');

% prompts the user for the search directory
sDir = uigetdir(defDir,'Select the base batch processing movie directory');
if (sDir == 0)
    % if the user cancelled, then exit
    return
else
    % otherwise, set the search directory into the GUI
    setappdata(handles.figDirTree,'sDir',sDir);
end

% creates a new directory tree panel
setPanelPropsLocal(handles.panelMovieInfo,'on')
createDirTreePanel(handles,sDir)

% --- Executes on button press in buttonContinue.
function buttonContinue_Callback(hObject, eventdata, handles)

% global variables
global fList sDir movFile hMov

% retrieves the 
jMov = getappdata(handles.figDirTree,'jMov');
sDir = getappdata(handles.figDirTree,'sDir');

% sets the full names of the selected files
isSel = cellfun(@(x)(strcmp(get(x,'SelectionState'),'selected')),hMov);
fList = movFile(isSel);

% closes the GUI
delete(handles.figDirTree)

% --- Executes on button press in buttonClose.
function buttonClose_Callback(hObject, eventdata, handles)

% global variables
global fList sDir
[fList,sDir] = deal([]);

% closes the GUI
delete(handles.figDirTree)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- callback function for editing the apparatus inclusion checks --- %
function tableUpdate(hObject,eventdata)

% global variables
global h

% retrieves the tree handles
jMov = getappdata(h.figDirTree,'jMov');
if (isempty(jMov)); return; end

% sets the new selected movie count
isSel = cellfun(@(x)(strcmp(get(x,'SelectionState'),'selected')),jMov);
set(h.textSelCount,'string',int2str(sum(isSel)))    

% updates the batch process running menu item
setObjEnable(h.buttonContinue,sum(isSel) > 0)

% --- creates the directory tree panel --- %
function createDirTreePanel(handles,sDir)

% sets the panel dimensions
fType = getappdata(handles.figDirTree,'fType');
[L,B,W,H] = deal(10,45,680,500);

% removes any previous panel objects
hPanel = findobj(handles.figDirTree,'tag','hDirPanel');
if isempty(hPanel)
    % creates the panel object
    hPanel = uipanel('Units','Pixels','Position',[L B W H],...
                     'tag','hDirPanel','Parent',handles.figDirTree);
end
    
if nargin == 2
    % creates the file tree structure in the panel
    [jRoot,movFile,jMov] = setFileDirTree(hPanel,sDir,fType);    
    if (isempty(jRoot))
        return   
    end
        
    % sets the data arrays into the GUI
    setappdata(handles.figDirTree,'movFile',movFile)
    setappdata(handles.figDirTree,'jMov',jMov)
    setappdata(handles.figDirTree,'jRoot',jRoot)              
    
    % sets the file/selection count strings
    set(handles.textMovCount,'string',num2str(length(jMov)))    
    tableUpdate([],[])    
else
    % sets empty arrays for the data arrays
    setappdata(handles.figDirTree,'movFile',[])
    setappdata(handles.figDirTree,'jMov',[])    
    setappdata(handles.figDirTree,'jRoot',[])    
end

% --- sets up the file directory tree structure
function [jRoot,mFile,hM] = setFileDirTree(hObj,sDir,fType)

% global variables
global movFile hMov 
dX = 10;

% % sets the java-image
% iconPath = fullfile(mainProgDir,'Para Files','Images','Movie.png');
% jImage = java.awt.Toolkit.getDefaultToolkit.createImage(iconPath);

% imports the checkbox tree
import com.mathworks.mwswing.checkboxtree.*

% sets the 
if (nargin == 1)
    sDir = uigetdir('Select the base file search directory',pwd);
    if (sDir == 0)
        % if the user cancelled, then exit
        return
    end
end

% creates a loadbar
wStr = 'Initialising File Directory Tree Structure...';
try
    h = ProgressLoadbar(wStr);
catch
    h = waitbar(0,wStr);
end
    
% searches the batch processing movie directory for movies
movFile = findFileAllLocal(sDir,fType);
if (isempty(movFile))
    % if there are no movies detected, then exit with an error
    try
        % attempts to close the waitbar figure
        close(h); pause(0.05);   
    end
        
    % outputs an error to screen
    eStr = 'Error! No candidate files detected from base search directory.';
    waitfor(errordlg(eStr,'Invalid Directory Selection','modal'))
        
    % closes the loadbar and sets empty variables for the outputs
    [jRoot,mFile,hM] = deal([]);    
    return
else
    % otherwise, determine the directory struct from the movies
    hMov = cell(length(movFile),1);
    dirStr = detDirStructure(sDir,movFile);
end    

% creates the root checkbox node
sDirT = getFinalDirString(sDir);

% sets up the directory trees structure
jRoot = setSubDirTree(DefaultCheckBoxNode(sDirT),dirStr,sDirT);

% retrieves the object position
objP = get(hObj,'position');

% Now present the CheckBoxTree:
jTree = com.mathworks.mwswing.MJTree(jRoot);
jCheckBoxTree = handle(CheckBoxTree(jTree.getModel),'CallbackProperties');
jScrollPane = com.mathworks.mwswing.MJScrollPane(jCheckBoxTree);

%
wState = warning('off','all');
[~,~] = javacomponent(jScrollPane,[dX*[1 1],objP(3:4)-2*dX],hObj);
warning(wState);

% sets the callback function for the mouse clicking of the tree structure
cFunc = @(jCheckBoxTree,e)DirTree('tableUpdate',jCheckBoxTree,e); 
set(jCheckBoxTree,'MouseClickedCallback',cFunc)

% sets the output variables
if (nargout > 1)
    [mFile,hM] = deal(movFile,hMov);
end

% if there are no movies detected, then exit with an error
try
    [h.Indeterminate,h.FractionComplete] = deal(false,1);
    h.StatusMessage = 'Finished Creating Executable';     
catch
    try
        waitbar(1,h,'Tree Structure Initialisation Complete!'); 
    end    
end

% pauses and closes the window
pause(0.5); delete(h)

% -------------------------------------- %
% --- UITREE NODE CREATION FUNCTIONS --- %
% -------------------------------------- %

% --- sets up the sub-directory tree for the directories in dirStr --- %
function jTree = setSubDirTree(jTree,dirStr,dirC)
 
% global variables
global jImage movFile hMov

% imports the checkbox tree
import com.mathworks.mwswing.checkboxtree.*

% adds all the nodes for each of the sub-directories
for i = 1:length(dirStr.Names)    
    jTreeNw = DefaultCheckBoxNode(dirStr.Names{i});    
    jTreeNw = setSubDirTree(jTreeNw,dirStr.Dir(i),fullfile(dirC,dirStr.Names{i}));
    jTree.add(jTreeNw);                
end

% if there are any files detected, then add their names to the list
if (~isempty(dirStr.Files))
    for i = 1:length(dirStr.Files)                       
        % determines the matching movie file name
        fStr = fullfile(dirC,dirStr.Files{i});
        ii = find(cellfun(@(x)(strContains(x,fStr)),movFile));      
        
        % creates the new node
        [jTreeNw,hMov{ii}] = deal(DefaultCheckBoxNode(dirStr.Files{i}));
        jTree.add(jTreeNw)                    
    end        
end

% --- sets up the directory tree structure from the movie files --- %
function dirStr = detDirStructure(sDir,movFile)

% sets the directory name separation string
if (ispc); sStr = '\'; else sStr = '/'; end
if (~strcmp(sDir(end),sStr)); sDir = [sDir,sStr]; end

% memory allocation
[dirStr,a] = deal(struct('Files',[],'Dir',[],'Names',[]));

% sets up the director tree structure for the selected movies
for i = 1:length(movFile)
    % sets the new directory sub-strings
    A = splitStringRegExpLocal(movFile{i}((length(sDir)+1):end),sStr);
    bStr = 'dirStr';
    for j = 1:length(A)                
        % appends the data to the struct
        if (j == length(A))
            % appends the movie name to the list
            eval(sprintf('%s.Files = [%s.Files;A(end)];',bStr,bStr));
        else
            % if the sub-field does not exists, then create a new one
            if (~any(strcmp(eval(sprintf('%s.Names',bStr)),A{j})))            
                if (isempty(eval(sprintf('%s.Dir',bStr))))
                    eval(sprintf('%s.Dir = a;',bStr));
                    eval(sprintf('%s.Names = A(j);',bStr));                    
                else
                    eval(sprintf('%s.Dir = [%s.Dir;a];',bStr,bStr));
                    eval(sprintf('%s.Names = [%s.Names;A(j)];',bStr,bStr));
                end
            end            
            
            % appends the new field to the data struct
            ii = find(strcmp(eval(sprintf('%s.Names',bStr)),A{j}));
            bStr = sprintf('%s.Dir(%i)',bStr,ii);
        end
    end
end

% --- sets the enabled properties for all the objects within a panel --- %
function setPanelPropsLocal(hPanel,eType,varargin)

% retrieves the panel children objects
tCol = 0.71;
hChild = get(hPanel,'Children');

% loops through all the panel objects setting the enabled properties
for i = 1:length(hChild)
    switch (get(hChild(i),'type'))
        case {'axes','uitabgroup','uitab'}
            % no enabled properties for panel objects
        case ('uipanel')
            if (strcmp(eType,'on'))
                set(hChild(i),'foregroundcolor',[0 0 0])
            else
                set(hChild(i),'foregroundcolor',tCol*[1 1 1])
            end
        otherwise
            % sets the panel enabled type
            setObjEnable(hChild(i),eType);               
    end    
end

% sets the panel text colour based on the enabled properties
if nargin == 2
    if strcmp(eType,'on')
        set(hPanel,'foregroundcolor',[0 0 0])
    else
        set(hPanel,'foregroundcolor',tCol*[1 1 1])
    end
end

% --- finds all the finds
function fName = findFileAllLocal(snDir,fExtn)

% initialisations
[fFileAll,fName] = deal(dir(snDir),[]);

% determines the files that have the extension, fExtn
fFile = dir(fullfile(snDir,sprintf('*%s',fExtn)));
if (~isempty(fFile))
    fNameT = cellfun(@(x)(x.name),num2cell(fFile),'un',0);
    fName = cellfun(@(x)(fullfile(snDir,x)),fNameT,'un',0);    
end

%
isDir = find(cellfun(@(x)(x.isdir),num2cell(fFileAll)));
for j = 1:length(isDir)
    % if the sub-directory is valid, then search it for any files        
    i = isDir(j);
    if ~(strcmp(fFileAll(i).name,'.') || strcmp(fFileAll(i).name,'..'))        
        fDirNw = fullfile(snDir,fFileAll(i).name);        
        fNameNw = findFileAllLocal(fDirNw,fExtn);
        if ~isempty(fNameNw)
            % if there are any matches, then add them to the name array
            fName = [fName;fNameNw];
        end
    end
end

% --- splits up a string, Str, by its white spaces and returns the
%     constituent components in the cell array, sStr
function sStr = splitStringRegExpLocal(Str,sStr)

% ensures the string is not a cell array
if (iscell(Str))
    Str = Str{1};
end

% determines the indices of the non-white regions in the string
if (length(sStr) == 1)
    if (strcmp(sStr,'\') || strcmp(sStr,'/'))    
        ind = strfind(Str,sStr)';
    else
        ind = regexp(Str,sprintf('[%s]',sStr))';
    end
else
    ind = regexp(Str,sprintf('[%s]',sStr))';
end

% calculates the indices of the non-contigious non-white space indices and
% determines the index bands that the strings belong to
indGrp = num2cell([[1;(ind+1)],[(ind-1);length(Str)]],2);

% sets the sub-strings
sStr = cellfun(@(x)(Str(x(1):x(2))),indGrp,'un',false);
