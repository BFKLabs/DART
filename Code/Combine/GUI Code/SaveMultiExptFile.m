function varargout = SaveMultiExptFile(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SaveMultiExptFile_OpeningFcn, ...
                   'gui_OutputFcn',  @SaveMultiExptFile_OutputFcn, ...
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

% --- Executes just before SaveMultiExptFile is made visible.
function SaveMultiExptFile_OpeningFcn(hObject, eventdata, handles, varargin)

% global variables
global tableUpdate
tableUpdate = false;

% Choose default command line output for SaveMultiExptFile
handles.output = hObject;

% sets the input arguments
hFigM = varargin{1};
hGUIInfo = getappdata(hFigM,'hGUIInfo');

% makes the information GUI invisible
setObjVisibility(hGUIInfo.hFig,'off')
setObjVisibility(hFigM,'off')

% sets the input arguments
setappdata(hObject,'hFigM',hFigM);
setappdata(hObject,'hGUIInfo',hGUIInfo);
setappdata(hObject,'iProg',getappdata(hFigM,'iProg'));

% sets the function handles into the gui
setappdata(hObject,'resetFcn',@resetChooserFile)

% initialises the object properties
initObjProps(handles)
setappdata(hObject,'sObj',OpenSolnTab(hObject,2));
initFileChooser(handles)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SaveMultiExptFile wait for user response (see UIRESUME)
% uiwait(handles.figMultiSave);

% --- Outputs from this function are returned to the command line.
function varargout = SaveMultiExptFile_OutputFcn(hObject, eventdata, handles)

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes when user attempts to close figMultiSave.
function figMultiSave_CloseRequestFcn(hObject, eventdata, handles)

% Hint: delete(hObject) closes the figure
buttonCancel_Callback(handles.buttonCancel, [], handles)

%-------------------------------------------------------------------------%
%                        OBJECT CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% ------------------------------ %
% --- FILE CHOOSER CALLBACKS --- %
% ------------------------------ %

% --- callback function for the file chooser property change
function chooserPropChange(hObject, eventdata, handles)

% global variables
global isUpdating

% if updating indirectly, then exit the function
if isUpdating; return; end

% initialisations
hFig = handles.figMultiSave;
objChng = eventdata.getNewValue;
sObj = getappdata(hFig,'sObj');
jFileC = getappdata(hFig,'jFileC');
expDir = getMultiObjData(hFig,'expDir');
expName = getMultiObjData(hFig,'expName');
iTabG = sObj.getTabGroupIndex();

switch get(eventdata,'PropertyName')
    case 'directoryChanged'
        % case is the folder change
        
        % retrieves the new file path
        expDir{iTabG} = char(objChng.getPath);
        setMultiObjData(hFig,'expDir',expDir);

    case 'SelectedFileChangedProperty'
        % case is the directory has been created
        newValue = char(removeFileExtn(char(get(eventdata,'NewValue'))));
        oldValue = char(removeFileExtn(char(get(eventdata,'OldValue'))));        
        
        % case is a file was selected
        if ~isempty(newValue)
            % determines if the new/old values differ
            if ~strcmp(oldValue,newValue)
                % updates the new file/directory names     
                [expDir{iTabG},expName{iTabG},~] = fileparts(newValue);
                setMultiObjData(hFig,'expDir',expDir);
                setMultiObjData(hFig,'expName',expName);

                % updates the explorer tree name and the table
                resetChooserFile(hFig,iTabG)

            else
                % updates the file name string
                hFn = getFileNameObject(jFileC);  
                [~,fName,~] = fileparts(char(newValue));

                isUpdating = true;
                hFn.setText(getFileName(fName));
                isUpdating = false;
            end
        end
end

% --- updates when the file name is changed
function saveFileNameChng(hObject, eventdata, handles)

% global variables
global isUpdating

% if updating elsewhere, then exit the function
if isUpdating; return; end 

% object retrieval
hFig = handles.figMultiSave;
sObj = getappdata(hFig,'sObj');
iTabG = sObj.getTabGroupIndex();
expName = getMultiObjData(hFig,'expName');

% updates the experiment file name
expName{iTabG} = char(get(hObject,'Text'));
setMultiObjData(hFig,'expName',expName);

% enables the create button enabled properties (disable if no file name)
setObjEnable(handles.buttonCreate,~isempty(expName{iTabG}))

% --- resets the chooser file
function resetChooserFile(hFig,iTabG,forceUpdate)

% global variables
global isUpdating

% if there is no file chooser, then exit
jFileC = getappdata(hFig,'jFileC');
if isempty(jFileC); return; end

% sets the default input arguments
if ~exist('forceUpdate','var'); forceUpdate = false; end

% initialisations
expDir = getMultiObjData(hFig,'expDir');
expName = getMultiObjData(hFig,'expName');

% retrieves the current file name and the new file name  
fFileS = char(jFileC.getSelectedFile());
fFileNw = fullfile(expDir{iTabG},expName{iTabG});

% if the new and selected files are not the same then update
if ~strcmp(fFileS,fFileNw) || forceUpdate
    % flag that the object is updating indirectly
    isUpdating = true;
    
    % resets the selected file
    jFileC.setSelectedFile(java.io.File(fFileNw));
    jFileC.repaint();
    
    % updates the file name string
    hFn = getFileNameObject(jFileC);    
    hFn.setText(getFileName(fFileNw));    
    pause(0.05);
    
    % resets the update flag
    isUpdating = false;
end

% -------------------------------- %
% --- CONTROL BUTTON CALLBACKS --- %
% -------------------------------- %

% --- Executes on button press in buttonRefresh.
function buttonRefresh_Callback(hObject, eventdata, handles)

% sets the full solution file name
hFig = handles.figMultiSave;
jFileC = getappdata(hFig,'jFileC');

% rescans the current file explorer directory
jFileC.rescanCurrentDirectory()

% --- Executes on button press in buttonCreate.
function buttonCreate_Callback(hObject, eventdata, handles)

% sets the full solution file name
hFig = handles.figMultiSave;
sObj = getappdata(hFig,'sObj');
iTabG = sObj.getTabGroupIndex();
[expDir,expName] = deal(sObj.expDir,sObj.expName);

% sets the full multi-experiment solution file path
expFile = fullfile(expDir{iTabG},[expName{iTabG},'.msol']);
if exist(expFile,'file')
    % if the file already exists, prompt the user if they wish to overwrite
    qStr = sprintf(['The multi-experiment file with this name already ',...
                    'exists.\nDo you want to overwrite the file?']);
    uChoice = questdlg(qStr,'Overwrite Solution Files?','Yes','No','Yes');
    if ~strcmp(uChoice,'Yes')
        % if the user cancelled, then quit the function
        return
    end
end

% % creates the progress bar
% wStr0 = {'File Batch Progress','Waiting For Process',...
%          'Current Experiment Progress','Output Data Field'};
% hProg = ProgBar(wStr0,'Solution File Loading');

% creates the waitbar figure
wStr = {'Overall Progress',...
        'Current Field Progress',...
        'Solution File Output'};
hProg = ProgBar(wStr,'Creating Multi-Experimental Solution File');

% --------------------------------------- %
% --- EXPERIMENT SOLUTION FILE OUTPUT --- %
% --------------------------------------- %

% field retrieval
iProg = getappdata(hFig,'iProg');
cObj = getMultiObjData(hFig,'cObj');
sInfo0 = getMultiObjData(hFig,'sInfo');
gName0 = getMultiObjData(hFig,'gName');
gNameU0 = getMultiObjData(hFig,'gNameU');

% other initialisations
tmpDir = iProg.TempFile;
tmpFile = fullfile(tmpDir,'Temp.tar');  

% determines the currently selected experiment
indG = cObj.detCompatibleExpts();
iTabG = sObj.getTabGroupIndex();

% reduces the stimuli inforation/group names for the current grouping
iS = indG{iTabG};
grpName = gNameU0{iTabG};
[sInfo,gName] = deal(sInfo0(iS),gName0(iS));
fName = cellfun(@(x)(x.expFile),sInfo,'un',0);

% memory allocation
nFile = length(fName);
tarFiles = cell(nFile,1);

% removes any group names that are not linked to any experiment
hasG = cellfun(@(x)(any(cellfun(@(y)(any(strcmp(y,x))),gName))),grpName);
grpName = grpName(hasG);
                    
% loops through all the variable strings loading the data from the
% individual experiment solution files, and adding it to the 
% multi-experiment solution file
for i = 1:nFile
    % updates the waitbar figure
    fNameNw = simpFileName(fName{i},15);
    wStr1 = sprintf('Appending "%s" (%i of %i)',fNameNw,i,nFile);    
    if hProg.Update(1,wStr1,i/nFile)
        % if the user cancelled, delete the solution files and exits 
        cellfun(@delete,tarFiles(1:(i-1)))
        return  
    elseif i > 1
        % otherwise, clear the lower waitbars (for files > 1)
        hProg.Update(2,wStr{2},0);
        hProg.Update(3,wStr{3},0);
    end    

    % ---------------------------------- %    
    % --- SOLUTION DATA STRUCT SETUP --- %
    % ---------------------------------- %
    
    % sets the experiment solution data struct
    snTot = sInfo{i}.snTot;
    ok = snTot.iMov.ok;              
    
    % sets the group to overall group linking indices
    gName{i}(~ok) = {''};
    indL = cellfun(@(y)(find(strcmp(gName{i},y))),grpName,'un',0);
    
    % reduces the arrays to remove any missing arrays
    snTot = reduceExptSolnFiles(snTot,indL,grpName);     
%     snTot.iMov.pInfo.gName = gName{i}(ok);    
    
%     if ~isempty(snTot.Px); snTot.Px = snTot.Px(ok); end
%     if ~isempty(snTot.Py); snTot.Py = snTot.Py(ok); end          
    
%     if isfield(snTot,'sName')        
%         snTot = rmfield(snTot,'sName');
%     end    
    
    % ---------------------------------- %    
    % --- TEMPORARY DATA FILE OUTPUT --- %
    % ---------------------------------- %    
    
    % outputs the single combined solution file    
    tarFiles{i} = fullfile(tmpDir,[fName{i},'.ssol']);
    if ~saveExptSolnFile(tmpDir,tarFiles{i},snTot,hProg)
        % otherwise, delete the solution files and exits 
        cellfun(@delete,tarFiles(1:(i-1)))
        return
    end
    
    % updates the waitbar figure
    hProg.Update(2,'Solution File Update Complete!',1);    
end

% creates and renames the tar file to a solution file extension
tar(tmpFile,tarFiles)
movefile(tmpFile,expFile,'f');
cellfun(@delete,tarFiles)

% deletes the progressbar
hProg.closeProgBar()

% resets the experiment table background colours
buttonRefresh_Callback(handles.buttonRefresh, [], handles)

% --- Executes on button press in buttonCancel.
function buttonCancel_Callback(hObject, eventdata, handles)

% initialisations
hFig = handles.figMultiSave;
sObj = getappdata(hFig,'sObj');
hFigM = getappdata(hFig,'hFigM');
hGUIInfo = getappdata(hFig,'hGUIInfo');

% determines if the user made a change 
if sObj.isChange
    % if there was a change, then prompt the user if they wish to update
    qStr = 'Do you want to update the changes you have made?';
    uChoice = questdlg(qStr,'Update Changes?','Yes','No','Cancel','Yes');    
    switch uChoice
        case 'Yes'
            % case is the user chose to update   
            sInfo = getMultiObjData(hFig,'sInfo');
            gName = getMultiObjData(hFig,'gName');
            postSaveFcn = getappdata(hFigM,'postSolnSaveFunc');
            
            % resets the group names into the solution data structs
            for i = 1:length(sInfo)
                sInfo{i}.gName = gName{i};
            end
            
            % updates the solution information into the main gui
            setappdata(hFigM,'sInfo',sInfo);
            postSaveFcn(hFigM,1);
            
        case 'Cancel'
            % case is the user cancelled
            return
    end
end

% closes the GUI
delete(hFig)
setObjVisibility(hGUIInfo.hFig,'on')
setObjVisibility(hFigM,'on')

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the GUI object properties
function initObjProps(handles)

% global variables
global H0T HWT

% parameters
dX = 5;
dYP = 25;
bHght = 25;
nExpMax = 7;
nExpMin = 7;

% object retrieval
hFig = handles.figMultiSave;
hPanelF = handles.panelFileInfo;
hPanelGrp = handles.panelGroupingInfo;

% memory allocation and other initialisations
sInfo = getappdata(hFig,'sInfo');
nExp = length(sInfo);

% ------------------------------------------- %
% --- EXPERIMENT INFORMATION OBJECT SETUP --- %
% ------------------------------------------- %

% object retrieval
hTableT = handles.tableExptComp;
hPanelInfo = handles.panelInfoTotal;
hPanelInfoN = handles.panelGroupNames;
hPanelInfoEx = handles.panelExptComp;

% calculates the new table height
pPosEx0 = get(hPanelInfoEx,'Position');
tblHght = calcTableHeight(max(nExpMin,min(nExpMax,nExp))) + H0T;
hghtNew = tblHght + dX;

% updates the height of the experiment comparison panel
resetObjPos(hPanelInfoEx,'height',hghtNew);
resetObjPos(hTableT,'height',tblHght);
resetObjPos(hTableT,'bottom',dX);

% resets the height of 
dHght = hghtNew-pPosEx0(4);
resetObjPos(hFig,'height',dHght,1)
resetObjPos(hPanelF,'height',dHght,1)
resetObjPos(hPanelInfo,'height',dHght,1)
resetObjPos(hPanelInfoN,'height',dHght,1)
resetObjPos(hPanelGrp,'bottom',dHght,1) 
resetObjPos(handles.panelFinalNames,'height',dHght,1)
resetObjPos(handles.panelLinkName,'height',dHght,1)
resetObjPos(handles.panelOuter,'height',dHght,1)

% calculates the number of rows within the new table
pPos = getpixelposition(handles.panelFinalNames);
nRow = floor((pPos(4)-(H0T+dYP))/HWT);
hghtTabN = nRow*HWT + H0T;

% resets the group name table heights
resetObjPos(handles.tableFinalNames,'Height',hghtTabN)
resetObjPos(handles.tableLinkName,'Height',hghtTabN)

% resets the movement button object positions
tPos = get(handles.tableFinalNames,'Position');
y0 = (sum(tPos([2,4]))-dX)/2 - bHght;
resetObjPos(handles.buttonMoveDown,'Bottom',y0);
resetObjPos(handles.buttonMoveUp,'Bottom',y0+(dX+bHght));

% sets the row count into the gui
setappdata(hFig,'nRow',nRow);

% --- initialises the file chooser object
function initFileChooser(handles)

% retrieves the default directories
hFig = handles.figMultiSave;
hPanelF = handles.panelFileInfo;
expDir = getMultiObjData(hFig,'expDir');
expName = getMultiObjData(hFig,'expName');

% sets the base file directory/output names
objStr = 'javahandle_withcallbacks.com.sun.java.swing.plaf.windows.WindowsFileChooserUI$7';

% file chooser parameters
defDir = expDir{1};
defFile = fullfile(defDir,expName{1});
fSpec = {{'DART Multi-Experiment Solution File (*.msol)',{'msol'}}};

% creates the file chooser object
jFileC = setupJavaFileChooser(hPanelF,'fSpec',fSpec,...
                                      'defDir',defDir,...
                                      'defFile',defFile,...
                                      'isSave',true);
jFileC.setName(expName{1});
jFileC.setFileSelectionMode(0)
jFileC.PropertyChangeCallback = {@chooserPropChange,handles};
setappdata(hFig,'jFileC',jFileC)

% attempts to retrieve the correct object for the keyboard callback func
jPanel = jFileC.getComponent(2).getComponent(2);
hFn = handle(jPanel.getComponent(2).getComponent(1),'CallbackProperties');
if isa(hFn,objStr)
    % if the object is feasible, set the callback function
    hFn.KeyTypedCallback = {@saveFileNameChng,handles};
end

% --------------------------------------------- %
% --- SAVE CLASS OBJECT FIELD I/O FUNCTIONS --- %
% --------------------------------------------- %

% --- retrieves the multi-experiment information object field
function fldVal = getMultiObjData(hFig,fldStr)

fldVal = getStructField(getappdata(hFig,'sObj'),fldStr);

% --- updates a multi-experiment information object field
function setMultiObjData(hFig,fldStr,fldVal)

sObj = getappdata(hFig,'sObj');
sObj = setStructField(sObj,fldStr,fldVal);
setappdata(hFig,'sObj',sObj);