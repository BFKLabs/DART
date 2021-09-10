function varargout = SaveExptFile(varargin)
% Last Modified by GUIDE v2.5 18-Jul-2021 18:00:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @SaveExptFile_OpeningFcn, ...
    'gui_OutputFcn',  @SaveExptFile_OutputFcn, ...
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

% --- Executes just before SaveExptFile is made visible.
function SaveExptFile_OpeningFcn(hObject, eventdata, handles, varargin)

% global variables
global isUpdating
isUpdating = false;

% sets the input arguments
hFigM = varargin{1};
sInfo = getappdata(hFigM,'sInfo');
hGUIInfo = getappdata(hFigM,'hGUIInfo');

% makes the information GUI invisible
setObjVisibility(hGUIInfo.hFig,'off')
setObjVisibility(hFigM,'off')

% reshapes the solution file information
for i = 1:length(sInfo)
    sInfo{i}.snTot = reshapeSolnStruct(sInfo{i}.snTot,sInfo{i}.iPara);
end

% sets the data structs into the GUI
setappdata(hObject,'hFigM',hFigM);
setappdata(hObject,'sInfo',sInfo);
setappdata(hObject,'isChange',false)
setappdata(hObject,'hGUIInfo',hGUIInfo)
setappdata(hObject,'fExtn',repmat({'.ssol'},length(sInfo),1));
setappdata(hObject,'iProg',getappdata(hFigM,'iProg'))
    
% initialises the file information
setupFileInfoData(handles);
setupOutputFlags(handles);
initExplorerTree(handles);
initFileInfo(handles);
initExptInfo(handles);

% updates the solution time object properties
set(handles.checkSolnTime,'value',0)
checkSolnTime_Callback(handles.checkSolnTime, [], handles)

% updates the object properties
updateObjectProps(handles)

% Choose default command line output for SaveExptFile
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SaveExptFile wait for user response (see UIRESUME)
% uiwait(handles.figExptSave);

% --- Outputs from this function are returned to the command line.
function varargout = SaveExptFile_OutputFcn(hObject, eventdata, handles)

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes when user attempts to close figExptSave.
function figExptSave_CloseRequestFcn(hObject, eventdata, handles)

% runs the close windown button
buttonCancel_Callback(handles.buttonCancel, [], handles)

%-------------------------------------------------------------------------%
%                        OBJECT CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes when selected object is changed in panelExptOutput.
function panelExptOutput_SelectionChangedFcn(hObject, eventdata, handles)

% initialisations
hFig = handles.figExptSave;
hPanel = handles.panelExptOutput;
isCust = get(handles.radioCustomOutput,'Value');

% updates the object enabled properties
arrayfun(@(x)(setObjEnable(x,~isCust)),findall(hPanel,'UserData',1))
arrayfun(@(x)(setObjEnable(x,isCust)),findall(hPanel,'UserData',2))

% updates the tree visibility
hTree = getappdata(hFig,'hTree');
set(hTree,'Visible',isCust)

% resets the experiment table background
resetExptTableBG(hFig)
setappdata(hFig,'isChange',true)

% --- Executes on button press in buttonFixedDir.
function buttonFixedDir_Callback(hObject, eventdata, handles)

% retrieves the fixed directory path
hFig = handles.figExptSave;
fDirFix = getappdata(hFig,'fDirFix');

% prompts the user for the search directory
sDirNw = uigetdir(fDirFix,'Select the root search directory');
if sDirNw == 0
    % if the user cancelled, then exit
    return
end

% otherwise, update the directory string names
set(handles.editFixedDir,'String',sDirNw);    
set(handles.radioFixedOutput,'TooltipString',sDirNw);
setappdata(hFig,'fDirFix',sDirNw);

% updates the object properties    
resetChooserFile(hFig,getappdata(hFig,'iExp'))   
resetExptTableBG(hFig)
setappdata(hFig,'isChange',true)

% --- tree selection change callback function
function treeSelectChng(hObject, eventdata, hFig)

% global variables
global isUpdating

% if updating elsewhere, then exit
if isUpdating; return; end

% retrieves the current node. if it is not a leaf node then exit
hNodeS = get(eventdata,'CurrentNode');
if ~hNodeS.isLeafNode; return; end

% updates the experiment name table selection
handles = guidata(hFig);
iExp = hNodeS.getUserObject;
hTableEx = handles.tableExptName;

% updates the table selection
setTableSelection(hTableEx,iExp-1,0)

% ----------------------------- %
% --- OUTPUT INFO CALLBACKS --- %
% ----------------------------- %

% --- Executes on button press for the other parameter checkboxes
function otherParaCheck(hCheck, ~, handles)
    
% field retrieval
hFig = handles.figExptSave;
iExp = getappdata(hFig,'iExp');
oPara = getappdata(hFig,'oPara');
pFld = get(hCheck,'UserData');

% updates the other parameter struct (for the current experiment)
oPara(iExp) = setStructField(oPara(iExp),pFld,get(hCheck,'Value'));
setappdata(hFig,'oPara',oPara)
setappdata(hFig,'isChange',true)

% --- Executes on button press in checkSolnTime.
function checkSolnTime_Callback(hObject, eventdata, handles)

% sets the time interval text/editbox properties
isSel = get(hObject,'value');
setObjEnable(handles.textSolnTime,isSel)
setObjEnable(handles.editSolnTime,isSel)

% --- Executes on editting editSolnTime
function editSolnTime_Callback(hObject, eventdata, handles)

% retrieves the parameters/data structs
hFig = handles.figExptSave;
iExp = getappdata(hFig,'iExp');
Tmax = getappdata(hFig,'Tmax');
sInfo = getappdata(hFig,'sInfo');

% checks to see if the new value is valid
nwVal = str2double(get(hObject,'string'));
if chkEditValue(nwVal,[1 Tmax(iExp)],1)
    % if so, updates the parameter field with the new value
    sInfo{iExp}.iPara.dT = nwVal;
    setappdata(hFig,'sInfo',sInfo)
    setappdata(hFig,'isChange',true)
else
    % otherwise, revert to the previous valid value
    set(hObject,'string',num2str(sInfo{iExp}.iPara.dT))
end

% ------------------------------ %
% --- FILE CHOOSER CALLBACKS --- %
% ------------------------------ %

% --- callback function for the file chooser property change
function chooserPropChange(hObject, eventdata, handles)

% global variables
global addedDir isUpdating

% if updating indirectly, then exit the function
if isUpdating; return; end

% initialisations
hFig = handles.figExptSave;
iExp = getappdata(hFig,'iExp');
fName = getappdata(hFig,'fName');
jFileC = getappdata(hFig,'jFileC');
[fExtn,fExtn0] = deal(getappdata(hFig,'fExtn'));
isFixed = get(handles.radioFixedOutput,'Value');
objChng = eventdata.getNewValue;

switch get(eventdata,'PropertyName')
    case 'directoryChanged'
        % case is the folder change
        
        % retrieves the new file path
        nwDir = char(objChng.getPath);
         
        % retrieves the root directory and chooser object handle 
        if isFixed
            isOK = true;
        else
            fDirRoot = getappdata(hFig,'fDirRoot');
            isOK = startsWith(objChng.getPath,fDirRoot);
        end
        
        % determines if the new directory is on the root path        
        if isOK
            % if so, then update the directory
            if isFixed
                % if fixed, the update
                setappdata(hFig,'fDirFix',nwDir);
                
                % updates the fixed output strings
                set(handles.editFixedDir,'string',nwDir)
                set(handles.radioFixedOutput,'tooltipstring',nwDir)
            else
                % updates the file
                fDir = getappdata(hFig,'fDir');
                fDir{iExp} = nwDir;
                setappdata(hFig,'fDir',fDir)

                % updates the tree node
                treeNodeUpdate(hFig,'move',iExp)                 
            end
            
            % resets the figure background
            resetExptTableBG(hFig)
            setappdata(hFig,'isChange',true)
            
        else
            % if the folder is invalid then output a message to screen
            mStr = sprintf(['The selected directory is not on the ',...
                           'root directory path.\nEither reset the ',...
                           'root directory or choose another directory.']);
            waitfor(msgbox(mStr,'Invalid File Directory','modal'))
                        
            % reverts back to the original path
            currFile = getCurrentFilePath(hFig,iExp);
            jFileC.setSelectedFile(java.io.File(currFile));            
        end
    
    case 'fileFilterChanged'        
        % case is the file extension filter change   
        fExtn{iExp} = char(objChng.getSimpleFilterExtension);
        setappdata(hFig,'fExtn',fExtn)               
        
        % determines if the new name is feasible
        if checkExptName(hFig,fName{iExp})
            % updates the chooser file and experiment table background
            resetChooserFile(hFig,iExp)   
            resetExptTableBG(hFig)

            % updates the object properties
            hTable = handles.tableExptName;
            updateObjectProps(handles,iExp)
            setTableValue(hTable,iExp,3,java.lang.String(fExtn{iExp}))
            setappdata(hFig,'isChange',true)
        else
            % otherwise, revert the file extensions back to original
            setappdata(hFig,'fExtn',fExtn0)              
            resetChooserFileExtn(jFileC,fExtn0{iExp})            
        end
        
    case 'SelectedFileChangedProperty'
        % case is the directory has been created
        newValue = removeFileExtn(char(get(eventdata,'NewValue')));
        oldValue = removeFileExtn(char(get(eventdata,'OldValue')));
       
        if isempty(newValue)
        	% case is a new directory is being created
            if ~isempty(oldValue)
                % appends the added directory to the array
                addedDir = [addedDir;{char(oldValue)}];
            end
        else
%             % case is a file was selected
%             if ~isempty(oldValue)
                % determines if the new/old values differ
                if ~strcmp(char(oldValue),char(newValue))
                    % if so, update with the new values
                    iExp = getappdata(hFig,'iExp');
                    fDir = getappdata(hFig,'fDir');
                    
                    % updates the new file/directory names     
                    [fDir{iExp},fNameNw,~] = fileparts(char(newValue));
                    setappdata(hFig,'fDir',fDir);
                    
                    % updates the explorer tree name and the table
                    resetChooserFile(hFig,iExp,fNameNw)
                    saveFileNameChng([], fNameNw, handles)
                else
                    % updates the file name string
                    hFn = getFileNameObject(jFileC);  
                    [~,fName,~] = fileparts(char(newValue));
                    
                    isUpdating = true;
                    hFn.setText(getFileName(fName));
                    isUpdating = false;
                end
%             end
        end
end

% --- updates when the file name is changed
function saveFileNameChng(hObject, eventdata, handles)

% global variables
global isUpdating

% if updating elsewhere, then exit the function
if isUpdating; return; end 

% initialisations
hFig = handles.figExptSave;
iExp = getappdata(hFig,'iExp');
fName = getappdata(hFig,'fName');

% retrieves the 
if ischar(eventdata)
    fNameNw = eventdata;
else
    fNameNw = char(get(hObject,'Text'));
end

% enables the create button enabled properties (disable if no file name)
if checkExptName(hFig,fNameNw)
    % if the new name is valid, then update the experiment name struct
    fName{iExp} = fNameNw;
    setappdata(hFig,'fName',fName);  
    setappdata(hFig,'isChange',true);
    
    % updates the other gui objects
    updateTreeExplorerName(handles,iExp)    
    setObjEnable(handles.buttonCreate,~isempty(fNameNw))
    resetExptTableBG(hFig)
    
    % resets the table value    
    setTableValue(handles.tableExptName,iExp,1,java.lang.String(fNameNw))
        
else
    % otherwise, reset the chooser file
    resetChooserFile(hFig,iExp,[],true);
end

% --- determines if the new experiment name is feasible and unique
function [ok,mStr] = checkExptName(hFig,exptName,iExp)

% object retrieval
handles = guidata(hFig);
fName = getappdata(hFig,'fName');
fExtn = getappdata(hFig,'fExtn');

% default input arguments
if ~exist('iExp','var'); iExp = getappdata(hFig,'iExp'); end
if get(handles.radioFixedOutput,'Value')
    % case is fixed, so repeat the fixed directory strings
    fDirFix = getappdata(hFig,'fDirFix');
    fDir = repmat({fDirFix},length(fName),1);
else
    % otherwise, retrieve the custom directory strings
    fDir = getappdata(hFig,'fDir');
end

% check to see if the current directory string is valid/unique
[ok,mStr] = chkDirString(exptName);
if ok
    % sets the current file output file/directory names
    fFile = cell(length(fName),1);
    for i = 1:length(fFile)
        % sets the experiment file name
        if i == iExp
            fNameNw = exptName;
        else
            fNameNw = fName{i};
        end
        
        % sets the full experiment file/directory path (extn dependent)
        switch fExtn{i}
            case {'.mat','.ssol'}
                % case is .mat/.ssol format output
                fFile{i} = fullfile(fDir{i},[fNameNw,fExtn{i}]);
                
            otherwise
                % case is .txt/.csv format output
                fFile{i} = fullfile(fDir{i},fNameNw);
        end
    end
    
    % if the new experiment file already exists in the solution file list
    % then flag an error
    B = ~setGroup(iExp,size(fDir));
    if any(strcmp(fFile(B),fFile{iExp}))
        ok = false;        
        mStr = sprintf(['The output file name "%s" already exists in ',...
                        'the solution file list. Please retry using ',...
                        'a unique file name.'],exptName);
    end
end

% if there was an error, and it isn't being output, then output to screen
if (nargout == 1) && ~isempty(mStr)
    waitfor(msgbox(mStr,'Infeasible Experiment Name','modal'))
end

% --------------------------------------------- %
% --- EXPERIMENT/GROUP NAME TABLE CALLBACKS --- %
% --------------------------------------------- %

% --- Executes when entered data in editable cell(s) in tableExptName.
function tableExptName_CellEditCallback(hObject, eventdata, handles)

% global variables
global isUpdating

% if updating elsewhere, then exit the function
if isUpdating; return; end
isUpdating = true;

% object handle retrieval
hFig = handles.figExptSave;
hTable = handles.tableExptName;
fName = getappdata(hFig,'fName');

% retrieves the input values
tabData = get(hObject,'Data');
[iRow,iCol] = deal(eventdata.Indices(1),eventdata.Indices(2));

% performs the update check based on the column that was altered
switch iCol
    case 1
        % case is the experiment name
        nwStr = eventdata.NewData;
        if checkExptName(hFig,nwStr,iRow)
            % if the new name is valid, then update the arrays
            fName{iRow} = nwStr;
            setappdata(hFig,'fName',fName)   
            setappdata(hFig,'isChange',true)
            
            % updates the explorer tree
            updateTreeExplorerName(handles,iRow)            
            resetChooserFile(hFig,iRow);
        else
            % otherwise, revert back to the original name
            tabData{iRow,1} = eventdata.PreviousData;
            set(hObject,'Data',tabData)
        end
        
    case 2        
        % updates the experiment inclusion flag
        updateExptInclusionFlag(hFig,iRow,tabData{iRow,iCol});      
        
        % updates the tree node based on the table selection
        if tabData{iRow,iCol}
            % case is adding a node            
            treeNodeUpdate(hFig,'add',iRow)
        else
            % case is removing a node 
            treeNodeUpdate(hFig,'remove',iRow)
        end
        
        %        
        if tabData{iRow,iCol}
            setTableSelection(hObject,iRow-1,0)
        end
            
        % pause to allow refresh of gui        
        isUpdating = false;
        pause(0.05);        
end

% resets the experiment tables background colour
resetExptTableBG(hFig)

% --- Executes when selected cell(s) is changed in tableExptName.
function tableExptName_CellSelectionCallback(hObject, eventdata, handles)

% global variables
global isUpdating

% slight pause (this alows the cell edit function to run before the cell
% selection function - important for checkbox value changes)
pause(0.1)

% if updating then exit
if isUpdating; return; end

% object handle retrieval
hFig = handles.figExptSave;
iExp = getappdata(hFig,'iExp');
fExtn = getappdata(hFig,'fExtn');
gName = getappdata(hFig,'gName');
sInfo = getappdata(hFig,'sInfo');
jFileC = getappdata(hFig,'jFileC');
hTable = handles.tableGroupName;

% sets the currently selected row
if isempty(eventdata)
    isUpdating = true;
    iRow = max(1,getTableCellSelection(hObject));
    isUpdating = false;
elseif isempty(eventdata.Indices)
    return
else
    iRow = eventdata.Indices(1);
end

% updates the selected index
tabData = get(hObject,'Data');
setappdata(hFig,'iExp',iRow)

% sets the table 
setObjEnable(hTable,tabData{iRow,2})
setObjVisibility(handles.panelFileInfo,tabData{iRow,2})

% if the region is rejected, then exit the function
if tabData{iRow,2}
    % retrieves the group name table colour array
    ok = sInfo{iRow}.snTot.iMov.ok;
    bgCol = getGroupNameTableColour(hFig,iRow);

    % resets the group name table properties
    Data = [gName{iRow}(:),num2cell(ok)];
    set(hTable,'Data',Data,'BackgroundColor',bgCol);

    % updates the object properties    
    resetChooserFile(hFig,iRow)    
else
    % if the region is rejected    
    nRow = length(sInfo{iExp}.snTot.iMov.ok);
    set(hTable,'Data',[],'BackgroundColor',ones(nRow,3));    
end

% updates the other output parameters
resetSelectedNode(hFig,iRow)
updateObjectProps(handles,iRow);
resetChooserFileExtn(jFileC,fExtn{iRow})

% --- Executes when entered data in editable cell(s) in tableGroupName.
function tableGroupName_CellEditCallback(hObject, eventdata, handles)

% initialisations
hFig = handles.figExptSave;
iExp = getappdata(hFig,'iExp');
gName = getappdata(hFig,'gName');
sInfo = getappdata(hFig,'sInfo');

% input data
[iRow,iCol] = deal(eventdata.Indices(1),eventdata.Indices(2));
[prStr,nwStr] = deal(eventdata.PreviousData,eventdata.NewData);
tabData = get(hObject,'Data');

switch iCol        
    case 1
        % determines if the group region was rejected
        if ~strcmp(prStr,'* REJECTED *')
            % otherwise, update the group name array
            gName{iExp}{iRow} = nwStr;
            setappdata(hFig,'gName',gName)
            setappdata(hFig,'isChange',true)
            
            % resets the table background colour scheme
            bgCol = getGroupNameTableColour(hFig,iExp);
            set(hObject,'BackgroundColor',bgCol)              
            return
        end
        
    case 2
        % determines if the group region was rejected
        if ~strcmp(tabData{iRow,1},'* REJECTED *')
            % updates the group acceptance flags
            sInfo{iExp}.snTot.iMov.ok(iRow) = nwStr;
            setappdata(hFig,'sInfo',sInfo);
            setappdata(hFig,'isChange',true)

            % resets the table background colour scheme
            bgCol = getGroupNameTableColour(hFig,iExp);
            set(hObject,'BackgroundColor',bgCol)  
            return
        end
end

% if so, then output an error message to screen
mStr = ['This group region has been rejected and can''t be ',...
        'include in the output.'];
waitfor(msgbox(mStr,'Rejected Region Error','modal'))

% resets the table data to the previous string
tabData{iRow,iCol} = prStr;
bgCol = getGroupNameTableColour(hFig,iExp);
set(hObject,'Data',tabData,'BackgroundColor',bgCol);
    
% ---------------------------------------- %
% --- PROGRAM CONTROL BUTTON CALLBACKS --- %
% ---------------------------------------- %


% --- Executes on button press in buttonRefresh.
function buttonRefresh_Callback(hObject, eventdata, handles)

% sets the full solution file name
hFig = handles.figExptSave;
jFileC = getappdata(hFig,'jFileC');

% resets the experiment table background colours
resetExptTableBG(hFig)
jFileC.rescanCurrentDirectory()

% --- Executes on button press in buttonCreate.
function buttonCreate_Callback(hObject, eventdata, handles)

% sets the full solution file name
hFig = handles.figExptSave;
useExp = getappdata(hFig,'useExp');
fName = getappdata(hFig,'fName');
fExtn = getappdata(hFig,'fExtn');

% determines if the files already exist
fExist = detExistingExpt(hFig);
if any(fExist(useExp))
    % if there are files/directories that already exist, the output a
    % message to screen promptint the user if they wish to overwrite
    mStr = sprintf(['The following files from the output list ',...
                    'already exist:\n\n']);
    for i = find(fExist(useExp)')
        if any(strcmp({'.mat','.ssol'},fExtn{i}))
            fExtnNw = fExtn{i};
        else
            fExtnNw = '';
        end        
        mStr = sprintf('%s %s %s%s\n',mStr,char(8594),fName{i},fExtnNw);
    end
    mStr = sprintf(['%s\nAre you sure you want to overwrite ',...
                    'these files?'],mStr);
                
    % promts the user if the wish to overwrite the files
    uChoice = questdlg(mStr,'Overwrite Existing Files?','Yes','No','Yes');
    if ~strcmp(uChoice,'Yes')
        % if the user cancelled, then exit the function
        return
    end
end

% creates the progress bar
wStr0 = {'File Batch Progress','Waiting For Process',...
         'Current Experiment Progress'};
hProg = ProgBar(wStr0,'Solution File Loading');

% --------------------------------------- %
% --- EXPERIMENT SOLUTION FILE OUTPUT --- %
% --------------------------------------- %

% important field retrieval
sInfo = getappdata(hFig,'sInfo');
oPara = getappdata(hFig,'oPara');
gName = getappdata(hFig,'gName');
iProg = getappdata(hFig,'iProg');
jFileC = getappdata(hFig,'jFileC');

% sets the output directory files
if get(handles.radioFixedOutput,'Value')
    % case is using a fixed output directory
    fDir = repmat({getappdata(hFig,'fDirFix')},sum(useExp),1);
else
    % case is using a custom output directory structure
    fDir0 = getappdata(hFig,'fDir');
    fDir = fDir0(useExp);
end

% reshapes the arrays to only include those that were accepted for output
nExp = sum(useExp);
tmpDir = iProg.TempFile;
[fName,fExtn] = deal(fName(useExp),fExtn(useExp));
[sInfo,oPara,gName] = deal(sInfo(useExp),oPara(useExp),gName(useExp));

% if the first file output is .mat, then collase the progress bar
if strcmp(fExtn{1},'.mat')
    hProg.collapseProgBar(2)
end

% loops through each of the valid experiments outputting data to file
for i = 1:nExp
    % updates the progress bar
    wStrNw = sprintf('%s (Expt %i of %i)',wStr0{1},i,nExp);
    if hProg.Update(1,wStrNw,i/(1+nExp))
        % if the user cancelled, then exit
        return
    elseif i > 1
        % resets the progress waitbar
        for j = 2:length(wStr0)
            hProg.Update(j,wStr0{j},0);
        end
    end
    
    % updates the experiment with the new groups names/fields 
    snTot = sInfo{i}.snTot;
    snTot.iMov.pInfo.gName = gName{i};
    
    % sets the full output file/directory name
    fNameFull = fullfile(fDir{i},fName{i});
    
    % outputs the solution file (based on the users selection)    
    switch fExtn{i}
        case '.ssol' 
            % case is the DART Solution File
            outputDARTSoln(snTot,oPara(i),fNameFull,hProg,tmpDir)

        case '.mat'
            % case is the Matlab Mat File
            outputMATSoln(snTot,oPara(i),fNameFull,hProg)            

        case {'.csv','.txt'}
            % case is an ascii type file (csv or txt)
            a = 1;
            
            % outputs the csv/text file to disk
            isCSV = strcmp(fExtn{i},'.csv');
            outputASCIIFile(handles,snTot,oPara(i),isCSV,hProg)
    end
    
    if i < nExp
        % determines which of the current/next files are .mat files
        isMat = cellfun(@(x)(strcmp(x,'.mat')),fExtn(i+[0,1]));
        if isMat(1)
            % if the current file is a mat file, but the next is not, then
            % expand the progressbar
            if ~isMat(2)
                hProg.expandProgBar(2);
            end
            
        elseif isMat(2)
            % if the next file is a .mat then collapse the progressbar
            hProg.collapseProgBar(2);
        end
    end

end

% resets the experiment table background colours
buttonRefresh_Callback(handles.buttonRefresh, [], handles)

% % retrieves the user's check values
% Tmax = 12;

% % if not splitting a file (and not outputting a DART file) then determine
% % if the files are too long
% if ~get(handles.checkSolnTime,'value') && ~strcmp(fExtn,'.ssol')
%     % sets the indices of the frames that are to be kept
%     Ts = snTot.T{iPara.indS(1)}(iPara.indS(2));
%     Tf = snTot.T{iPara.indF(1)}(iPara.indF(2));
%     
%     % if the solution file duration is excessive, then prompt the user if
%     % they wish to split up the solution file
%     if (Tf - Ts)/(60^2) > Tmax
%         a = sprintf('Solution file duration is greater Than %i Hours',Tmax);
%         b = 'Do you wish to reconsider splitting up the solution files?';
%         uChoice = questdlg([{a};{b}],'Split Up Solution Files?',...
%             'Yes','No','Yes');
%         if strcmp(uChoice,'Yes')
%             % if the user chose to exit, then leave the function
%             return
%         end
%     end
% end

% closes the progress bar
hProg.closeProgBar()

% --- Executes on button press in buttonCancel.
function buttonCancel_Callback(hObject, eventdata, handles)

% makes the information GUI invisible
hFig = handles.figExptSave;
hFigM = getappdata(hFig,'hFigM');
hGUIInfo = getappdata(hFig,'hGUIInfo');

% determines if the user made a change 
if getappdata(hFig,'isChange')
    % if there was a change, then prompt the user if they wish to update
    qStr = 'Do you want to update the changes you have made?';
    uChoice = questdlg(qStr,'Update Changes?','Yes','No','Cancel','Yes');    
    switch uChoice
        case 'Yes'
            % retrieves the solution file information
            sInfo = getappdata(hFig,'sInfo');
            gName = getappdata(hFig,'gName');
            fName = getappdata(hFig,'fName');
            postSaveFcn = getappdata(hFigM,'postSolnSaveFunc');
            
            % resets the fields
            for i = 1:length(sInfo)
                sInfo{i}.expFile = fName{i};
                sInfo{i}.gName = gName{i};
            end                       
            
            % case is the user chose to update            
            setappdata(hFigM,'sInfo',sInfo);            
            postSaveFcn(hFigM,0);
            
        case 'Cancel'
            % case is the user cancelled
            return
    end
end

% removes the added folders
removeAddedFolders()

% closes the GUI
delete(hFig)
setObjVisibility(hGUIInfo.hFig,'on')
setObjVisibility(hFigM,'on')

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% -------------------------------------- %
% --- SOLUTION FILE OUTPUT FUNCTIONS --- %
% -------------------------------------- %

% --- outputs the DART combined solution file --- %
function outputDARTSoln(snTot,oPara,fNameFull,hProg,tmpDir)

% resets the progress bar strings
hProg.wStr(2:end) = {'Overall Progress',...
                     'Output Data Field'};

% resets the progreebar
for i = 2:length(hProg.wStr)
    hProg.Update(i,hProg.wStr{i},0);
end

% updates the region data struct
snTot = updateRegionInfo(snTot);
snTot = reshapeExptSolnFile(snTot);

% outputs the solution file
fFileFull = [fNameFull,'.ssol'];
saveExptSolnFile(tmpDir,fFileFull,snTot,hProg,1);

% --- outputs a Matlab mat solution file --- %
function outputMATSoln(snTot,oPara,fNameFull,hProg)

% converts the cell arrays to numerical arrays
snTot.T = cell2mat(snTot.T);
snTot.isDay = cell2mat(snTot.isDay');

% removes the y-coordinate data (if not required)
if ~snTot.iMov.is2D && ~oPara.outY
    snTot = rmfield(snTot,'Py'); 
end

% removes any other extraneous fields
snTot = rmfield(snTot,{'pMapPx','pMapPy','iExpt'});

% saves the file
hProg.Update(2,'Outputting Matlab Solution File...',0.5); 
save([fNameFull,'.mat'],'snTot')

% closes the waitbar
hProg.Update(2,'Matlab Solution File Output Complete',1); 
pause(0.05);

% --- outputs the CSV combined solution file --- %
function outputASCIIFile(handles,snTot,oPara,isCSV,hProg)

% retrieves the apparatus data and solution file struct
iPara = getappdata(handles.figExptSave,'iPara');
nApp = sum(snTot.iMov.ok);

% sets the output file name/directory
fDir = getappdata(handles.figExptSave,'fDir');
fName = getappdata(handles.figExptSave,'fName');

% sets the waitbar strings
hProg.wStr(2:end) = {'Setting Positional Data',...
                     'Outputting Data To File',...
                     'Current File Progress'};
                 
% resets the fields
for i = 2:length(hProg.wStr)
    hProg.Update(2,hProg.wStr{i},0);
end

% -------------------------------- %
% --- SOLUTION FILE DATA SETUP --- %
% -------------------------------- %

% retrieves the positional data
[T,Pos,fNameSuf,Hstr,ok] = setupPosData(handles,'csv',oPara,hProg);
if ~ok
    return
else
    % sets the number of files to output (for each apparatus)
    nFile = length(T);
    
    % loops through each of the apparatus
    for i = 1:nApp
        % updates the waitbar figure
        wStrNw = sprintf('Overall Progress (Region %i of %i)',i,nApp);
        hProg.Update(2,wStrNw,i/nApp);
        
        % outputs the data for each split file
        for j = 1:nFile
            % updates the waitbar figure
            hProg.Update(3,sprintf('%s (%i of %i)',...
                                        hProg.wStr{3},j,nFile),j/nFile);
            
            % opens a new data file
            DataNw = [Hstr{i};num2cell([T{j} Pos{i}{j}])];
            if isCSV
                fNameEnd = sprintf('%s (%s).csv',fName,fNameSuf{i}{j});
            else
                fNameEnd = sprintf('%s (%s).txt',fName,fNameSuf{i}{j});
            end
            
            % opens the file
            fNameNw = fullfile(fDir,fNameEnd);
            fid = fopen(fNameNw,'w');
            
            % updates the waitbar figure
            [nRow,nCol] = size(DataNw);
            wStrNw = sprintf('%s (Row 0 of %i)',hProg.wStr{4},nRow);
            hProg.Update(4,wStrNw,0);
            
            % writes to the new data file
            for iRow = 1:nRow
                % updates the waitbar figure
                if mod(iRow,min(500,nRow)) == 0
                    if hProg.Update(4,sprintf('%s (Row %i of %i)',...
                                    hProg.wStr{4},iRow,nRow),iRow/nRow)
                        % if the user cancelled, then exit the function
                        try; fclose(fid); end
                        return
                    end
                end
                
                % prints the first column of data
                if iRow == 1
                    fprintf(fid,'%s',DataNw{iRow,1});
                else
                    fprintf(fid,'%.2f',DataNw{iRow,1});
                end
                
                % prints the other columns of data
                for iCol = 2:nCol
                    if isCSV || oPara.useComma
                        if iRow == 1
                            fprintf(fid,',%s',DataNw{iRow,iCol});
                        else
                            fprintf(fid,',%.2f',DataNw{iRow,iCol});
                        end
                    else
                        if iCol == 2
                            if iRow == 1
                                fprintf(fid,'\t\t%s',DataNw{iRow,iCol});
                            else
                                fprintf(fid,'\t\t%.2f',DataNw{iRow,iCol});
                            end
                        else
                            if iRow == 1
                                fprintf(fid,'\t%s',DataNw{iRow,iCol});
                            else
                                fprintf(fid,'\t%.2f',DataNw{iRow,iCol});
                            end
                        end
                    end
                end
                
                % prints the end of line-statement
                if isCSV
                    fprintf(fid,'\n');
                else
                    fprintf(fid,'\r\n');
                end
            end
            
            % updates the waitbar figure and closes the file
            wStrNw = sprintf('%s (Row %i of %i)',...
                            hProg.wStr{4},size(DataNw,1),size(DataNw,1));
            hProg.Update(4,wStrNw,1);
            fclose(fid);
        end
    end
end

% retrieves the experimental data (if selected)
if oPara.outStim
    % sets the stimuli data
    stimData = setupStimData(snTot);
    if isCSV
        fNameStim = fullfile(fDir,sprintf('%s (Stim Data).csv',fName));
    else
        fNameStim = fullfile(fDir,sprintf('%s (Stim Data).txt',fName));
    end
    
    % writes the stimuli data to file
    writeCSVFile(fNameStim,stimData);
end

% retrieves the experimental data (if selected)
if oPara.outExpt
    % retrieves the experiment info and the file name
    exptData = setupExptData(snTot,iPara);
    if isCSV
        fNameExpt = fullfile(fDir,sprintf('%s (Expt Data).csv',fName));
    else
        fNameExpt = fullfile(fDir,sprintf('%s (Expt Data).txt',fName));
    end
    
    % writes the stimuli data to file
    writeCSVFile(fNameExpt,exptData);
end

% ----------------------------------- %
% --- OUTPUT DATA SETUP FUNCTIONS --- %
% ----------------------------------- %

% --- sets up the positional data array for output to file --- %
function [T,Pos,fNameSuf,Hstr,ok] = setupPosData(handles,fType,oPara,h)

% retrieves the apparatus data and solution file struct
snTot = getappdata(handles.figExptSave,'snTot');
iPara = getappdata(handles.figExptSave,'iPara');

% determines the split time/if splitting flag
isSplit = get(handles.checkSolnTime,'value');

% initialisations
flyok = snTot.iMov.flyok;
indOut = find(snTot.iMov.ok);
gName = snTot.iMov.pInfo.gName;
[nApp,ok] = deal(length(indOut),true);

% memory allocation
[Pos,fNameSuf,Hstr] = deal(cell(1,nApp));

% ------------------------- %
% --- TIME VECTOR SETUP --- %
% ------------------------- %

% sets the time vector based on the file type/
switch fType
    case {'txt','csv'} % case is text/csv file output
        % sets the time vector
        T = cell2mat(snTot.T);
end

% ------------------------------ %
% --- POSITIONAL ARRAY SETUP --- %
% ------------------------------ %

% sets the indices of the frames that are to be kept
sOfs = [0;cumsum(cellfun(@length,snTot.T))];
i0 = sOfs(iPara.indS(1)) + iPara.indS(2);
i1 = sOfs(iPara.indF(1)) + iPara.indF(2);
indNw = i0:i1;

% resets the time
T = T(indNw);
if ~iscell(T); T = T - T(1); end

% sets the solution file group indices
if isSplit
    % if splitting up the movies, then set the split time
    tSplitH = str2double(get(handles.editSolnTime,'string'));
    tSplit = tSplitH*3600;
    
    % determines the point in the movie where the split occurs
    Tmod = mod(T-T(1),tSplit);
    ii = find(Tmod(2:end)<Tmod(1:end-1)) + 1;
    
    % sets the group indices based on the number of file splits
    if isempty(ii)
        % only one group, so set from start to end
        indGrp = [];
    else
        % sets the indices of each solution file group
        jj = [[1;ii],[(ii-1);length(T)]];
        indGrp = cellfun(@(x)(x(1):x(2)),num2cell(jj,2),'un',0);
    end
    
else
    % only one group, so set from start to end
    indGrp = [];
end

% loops through all the
for i = 1:nApp
    if h.Update(2,sprintf('%s (Region %i of %i)',...
                h.wStr{2},i,nApp),i/nApp)
        % if the user cancelled, then exit the function
        [T,Pos,Hstr,ok] = deal([],[],[],false);
        return
    end
    
    % sets the apparatus index and ok flags
    [iApp,okNw] = deal(indOut(i),find(flyok(:,indOut(i))));
    Hstr{i} = cell(1,1+(1+double(oPara.outY))*length(okNw));
    
    % retrieves the fly x-coordinates
    Px = snTot.Px{i}(indNw,okNw);
    
    % sets the position array based on whether outputting the y-coords
    if oPara.outY
        % output y-location as well
        Py = snTot.Py{i}(indNw,okNw);
        [PxC,PyC] = deal(num2cell(Px,1),num2cell(Py,1));
        Pos{i} = cell2mat(cellfun(@(x,y)([x y]),PxC,PyC,'un',0));
        
        % clears extraneous variables
        clear Py; pause(0.01);
    else
        % only outputting x-locations
        Pos{i} = Px;
    end
    
    % clears extraneous variables
    clear Px; pause(0.01);
    
    % sets the file name suffix strings
    if ~isempty(indGrp)
        % if more than one file, then set the file-names based on the
        % file period
        Pos{i} = cellfun(@(x)(Pos{i}(x,:)),indGrp,'un',0);
        fNameSuf{i} = cellfun(@(x)(sprintf('%s - H%i-%i',gName{iApp},...
            (x-1)*tSplitH,x*tSplitH)),...
            num2cell(1:size(indGrp,1))','un',0);
        
        % splits up the time strings into groups
        if (i == 1)
            T = cellfun(@(x)(T(x,:)),indGrp,'un',0);
        end
    else
        % otherwise, set the suffix name to be the apparatus name
        [Pos{i},fNameSuf{i}] = deal(Pos(i),gName(iApp));
        if (i == 1)
            T = {T};
        end
    end
    
    % sets the header string for each apparatus
    switch fType
        case {'csv','txt'}
            % sets the header string based on whether outputting y-data
            Hstr{i}{1} = 'Time';
            H1 = arrayfun(@(x)(sprintf('X%i',x)),okNw,'un',0);
            if oPara.outY
                % case is outputting both x and y data
                H2 = [H1 arrayfun(@(x)(sprintf('Y%i',x)),okNw,'un',0)];
                Hstr{i}(2:end) = reshape(H2',[1 numel(H2)]);
            else
                % case is outputting both x data
                Hstr{i}(2:end) = H1;
            end
    end
end

% --- sets up the experimental data array for output to file --- %
function exptData = setupExptData(snTot,iPara)

% memory allocation
nField = 5;
exptData = cell(nField,2);

% sets the experiment data fields based on the field type
for i = 1:nField
    switch (i)
        case (1) % case is the start time
            exptData{i,1} = 'Solution Start Time';
            T0 = snTot.iExpt.Timing.T0;
            dT = roundP(snTot.T{iPara.indS(1)}(iPara.indS(2))/(24*3600));            
            exptData{i,2} = datestr(datenum(T0) + datenum(dT));
            
        case (2) % case is the duration
            Tst = snTot.T{iPara.indS(1)}(iPara.indS(2),:);
            Tfn = snTot.T{iPara.indF(1)}(iPara.indF(2),:);
            [~,~,Ts] = calcTimeDifference(Tfn-Tst);
            
            exptData{i,1} = 'Solution File(s) Duration';
            exptData{i,2} = sprintf('%s:%s:%s:%s',Ts{1},Ts{2},Ts{3},Ts{4});
            
        case (3) % case is the experiment type
            exptData{i,1} = 'Experiment Type';
            switch (snTot.iExpt.Info.Type)
                case ('RecordOnly')
                    exptData{i,2} = 'Recording Only';
                otherwise
                    exptData{i,2} = 'Recording + Stimuli';
            end
            
        case (4) % case is the video count
            exptData{i,1} = 'Video Count';
            exptData{i,2} = num2str(length(snTot.T));
            
        case (5) % case is the recording frame rate
            exptData{i,1} = 'Recording Rate (fps)';
            exptData{i,2} = num2str(snTot.iExpt.Video.FPS);
    end
end

% --- sets up the stimulus data array for output to file --- %
function stimData = setupStimData(snTot)

% initialisations
[stimP,sTrainEx] = deal(snTot.stimP,snTot.sTrainEx);

% % REMOVE ME LATER
% fName = 'MM (4Ch).expp';
% [stimP,sTrainEx] = getExptStimInfo(fName);

[nTrain,sTrain] = deal(length(sTrainEx.sName),sTrainEx.sTrain);

% loops through each block within the train retrieving the info
for i = 1:nTrain
    stimDataNw = setStimTrainInfo(sTrain(i).blkInfo,stimP,i);
    if i == 1
        stimData = stimDataNw;
    else
        stimData = combineCellArrays(stimData,stimDataNw,1,'');
    end
end

% removes the last column from the final data array
stimData = stimData(:,1:end-1);

% --- retrieves the stimuli block information
function sBlk = setStimTrainInfo(bInfo,stimP,iTrain)

% retrieves the block channel names
chNameBlk = cellfun(@(x)...
        (regexprep(x,'[ #]','')),field2cell(bInfo,'chName'),'un',0);
devTypeBlk = cellfun(@(x)...
        (regexprep(x,'[ #]','')),field2cell(bInfo,'devType'),'un',0); 

% retrieves the unique device names from the list. from this determine if
% any motor devices where used (with matching protocols). if so, then
% remove them from the list of output
isOK = false(length(devTypeBlk),1);
devTypeU = unique(devTypeBlk);
for i = 1:length(devTypeU)
    % determines all the devices that belong to the current type
    ii = find(strcmp(devTypeBlk,devTypeU{i}));
    if strContains(devTypeU{i},'Motor')
        % if the device is a motor, and the fields have already been
        % reduced, then ignore the other channels (as they are identical)
        if isfield(getStructField(stimP,devTypeU{i}),'Ch')
            [ii,chNameBlk{ii(1)}] = deal(ii(1),'Ch');            
        end
    end
    
    % updates the acceptance flags
    isOK(ii) = isOK(ii) || true;
end

% removes any of the 
bInfo = bInfo(isOK);
[chNameBlk,devTypeBlk] = deal(chNameBlk(isOK),devTypeBlk(isOK));

% determines the number of blocks
nBlk = length(bInfo);
sBlkT = cell(1,nBlk);

% sets the column header string arrays
cStr1 = repmat({'Time','Units'},1,nBlk);
cStr2 = [{'Stim #'},repmat({'tStart','tFinish'},1,nBlk)];

% sets the row header string arrays
rStr1 = {'Train #','Device Type','Channel','Signal Type',''}';
rStr2 = {'Cycle Count','Amplitude',''}';
rStr3 = {'','Initial Offset','Cycle Duration','Total Duration',''}';

% combines the bottom row header with the stimuli info header row
rStr4 = combineCellArrays(combineCellArrays(rStr3,cStr1,1),cStr2,0);

% combines all the data into the header array
sBlkH = combineCellArrays(rStr1,combineCellArrays(rStr2,rStr4,0),0);
sBlkH(cellfun(@isnumeric,sBlkH)) = {''};
sBlkH{1,2} = num2str(iTrain);

% sets the stimuli information for each block within the entire train
for i = 1:nBlk
    % iteration initialisations
    [iC,sP] = deal(2*i,bInfo(i).sPara);
    
    % sets the output channel name (based on type)
    if strcmp(chNameBlk{i},'Ch')
        chNameNw = 'All Channels';
    else
        chNameNw = chNameBlk{i};
    end
    
    % sets the main stimuli info fields
    sBlkH{2,iC} = bInfo(i).devType;
    sBlkH{3,iC} = chNameNw;
    sBlkH{4,iC} = bInfo(i).sType;
    
    % sets the train count field
    iR = length(rStr1);
    sBlkH{iR+1,iC} = num2str(sP.nCount);
    
    % sets the duration info fields
    iR2 = iR + length(rStr2);
    [sBlkH{iR2+2,iC},sBlkH{iR2+2,iC+1}] = deal(num2str(sP.tOfs),sP.tOfsU);
    [sBlkH{iR2+4,iC},sBlkH{iR2+4,iC+1}] = deal(num2str(sP.tDur),sP.tDurU);
    
    % sets the signal type specific fields
    switch bInfo(i).sType
        case 'Square' % case is the square wave stimuli
            
            % sets the amplitude field
            sBlkH{iR+2,iC} = sprintf('0/%s',num2str(sP.sAmp));
            
            % sets the cycle duration fields
            sBlkH{iR2+3,iC} = sprintf('%s/%s',...
                                num2str(sP.tDurOn),num2str(sP.tDurOff));
            sBlkH{iR2+3,iC+1} = sprintf('%s/%s',...
                                num2str(sP.tDurOnU),num2str(sP.tDurOffU));                            
            
        otherwise % case is the other stimuli types
            
            % sets the amplitude field
            sBlkH{iR+2,iC} = sprintf('%s/%s',...
                                num2str(sP.sAmp1),num2str(sP.sAmp1));
                            
            % sets the cycle duration fields
            sBlkH{iR2+3,iC} = num2str(sP.tCycle);
            sBlkH{iR2+3,iC+1} = sP.tCycleU;                             
    end    
    
    % sets the stimuli block start times    
    stP = eval(sprintf('stimP.%s.%s',devTypeBlk{i},chNameBlk{i}));
    ii = stP.iStim(:) == iTrain;
    sBlkT{i} = num2cell(roundP([stP.Ts(ii),stP.Tf(ii)],0.001));
end

% sets the full stimuli start/finish time arrays
sBlkT = [num2cell(1:size(sBlkT{1},1))',cell2cell(sBlkT,0)];

% combines the header/time stamp informations into a single array (converts
% all numerical values to strings)
sBlk = combineCellArrays(combineCellArrays(sBlkH,sBlkT,0),{''},1,'');
isNum = cellfun(@isnumeric,sBlk);
sBlk(isNum) = cellfun(@num2str,sBlk(isNum),'un',0);

% --- updates the region information data struct
function snTot = updateRegionInfo(snTot)

% retrieves the region data struct fields
iMov = snTot.iMov;

% updates the setup dependent fields
if iMov.is2D
    % resets the group index array/count
    iGrp0 = iMov.pInfo.iGrp;    
    iMov.pInfo.iGrp(:) = 0;    
    
    % sets the grouping indices
    indG = 1;
    for i = 1:max(iGrp0(:))
        ii = (iGrp0 == i) & iMov.flyok;
        if iMov.ok(i) && any(ii(:))
            iMov.pInfo.iGrp(ii) = indG;
            indG = indG + 1;
        else
            iMov.pInfo.iGrp(ii) = 0;
        end
    end    
    
    % resets the group counter
    iMov.pInfo.nGrp = indG - 1;   
    
else  
    % sets the group numbers and group indices
    [NameU,~,iC] = unique(iMov.pInfo.gName,'Stable');
    iMov.pInfo.nGrp = length(NameU);
    
    % sets the grouping numbers for each region
    for i = 1:iMov.pInfo.nRow
        for j = 1:iMov.pInfo.nCol
            k = (i-1)*iMov.pInfo.nCol + j;
            if iMov.ok(k)
                % region is accepted, so set the grouping index number                
                iMov.pInfo.iGrp(i,j) = iC(k);
                iMov.pInfo.nFly(i,j) = sum(iMov.flyok(:,k));
            else
                % region is rejected, so set the index number to zero                
                iMov.pInfo.iGrp(i,j) = 0;
                iMov.pInfo.nFly(i,j) = NaN; 
                [iMov.flyok(:,k),iMov.ok(k)] = deal(false);
            end
        end
    end
end

% retrieves the region data struct fields
snTot.iMov = iMov;

% ---------------------------------------- %
% --- PROGRAM INITIALISATION FUNCTIONS --- %
% ---------------------------------------- %

% --- sets up the file information data structs
function setupFileInfoData(handles)

% retrieves the solution file data
hFig = handles.figExptSave;
iProg = getappdata(hFig,'iProg');
sInfo = getappdata(hFig,'sInfo');

% sets the output file/group names
fDir = cell(length(sInfo),1);
for i = 1:length(sInfo)
    switch sInfo{i}.iTab
        case 1
            fDir{i} = strrep(sInfo{i}.sFile,iProg.DirSoln,iProg.DirComb);
        otherwise
            fDir{i} = fileparts(sInfo{i}.sFile);
    end
end

% sets the data into the gui
setappdata(hFig,'isFix',false)
setappdata(hFig,'fDir',fDir);
setappdata(hFig,'fDirFix',iProg.DirComb);
setappdata(hFig,'fDirRoot',iProg.DirComb);
setappdata(hFig,'fName',cellfun(@(x)(x.expFile),sInfo,'un',0))
setappdata(hFig,'gName',cellfun(@(x)(x.gName),sInfo,'un',0))

% sets the fixed/custom directories
set(handles.editFixedDir,'String',iProg.DirComb)
set(handles.radioFixedOutput,'ToolTipString',iProg.DirComb);
set(handles.radioCustomOutput,'ToolTipString',iProg.DirComb);

% --- sets up the output flag array
function setupOutputFlags(handles)

% field retrieval
hFig = handles.figExptSave;
sInfo = getappdata(hFig,'sInfo');

% memory allocation
pStr0 = struct('useComma',0,'outY',0,'outExpt',0,'outStim',0,'solnTime',0);
oPara = repmat(pStr0,length(sInfo),1);

% sets the fields for each for the 
for i = 1:length(sInfo)
    % ensures the data is always output for a 2D experiment
    if sInfo{i}.snTot.iMov.is2D
        oPara(i).outY = true;
    end
end

% updates the array into the gui
setappdata(hFig,'oPara',oPara);

% --- initialises the file information fields --- %
function initFileInfo(handles)

% global variable
global mainProgDir

% sets the base file directory/output names
hFig = handles.figExptSave;
hPanel = handles.panelFileInfo;
sInfo = getappdata(hFig,'sInfo');
objStr = 'javahandle_withcallbacks.com.sun.java.swing.plaf.windows.WindowsFileChooserUI$7';

% file chooser parameters
fSpec = {{'DART Experiment Solution File (*.ssol)',{'ssol'}};...
         {'Matlab Data File (*.mat)',{'mat'}};...
         {'Text File (*.txt)',{'txt'}};...
         {'Comma Separated Value File (*.csv)',{'csv'}}};
     
% retrieves the current file path
iFile = 1;
[defFile,defDir] = getCurrentFilePath(hFig,iFile);
[dDir0,dFile0,~] = fileparts(defFile);

% %
% lf0 = javax.swing.UIManager.getLookAndFeel();
% lfStr = 'javax.swing.plaf.metal.MetalLookAndFeel';
% lfStr = 'com.sun.java.swing.plaf.windows.WindowsLookAndFeel';

javax.swing.UIManager.put('DocumentPane.boldActiveTab',false);

% creates the file chooser object
jFileC = setupJavaFileChooser(hPanel,'fSpec',fSpec,...
                                     'defDir',defDir,...
                                     'defFile',fullfile(dDir0,dFile0),...
                                     'isSave',true);
jFileC.setName(getFileName(defFile))
jFileC.setFileSelectionMode(0)
jFileC.PropertyChangeCallback = {@chooserPropChange,handles};
setappdata(hFig,'jFileC',jFileC)

% sets the checkbox callback functions
hChk = findall(handles.panelOtherPara,'Style','Checkbox');
arrayfun(@(x)(set(x,'Callback',{@otherParaCheck,handles})),hChk);

% attempts to retrieve the correct object for the keyboard callback func
hFn = getFileNameObject(jFileC);
if isa(hFn,objStr)
    % if the object is feasible, set the callback function
    hFn.KeyTypedCallback = {@saveFileNameChng,handles};
end

% calculates the experiment duration
Tmax = zeros(length(sInfo),1);
for i = 1:length(sInfo)
    iPara = sInfo{i}.iPara;
    [~,dT,~] = calcTimeDifference(iPara.Tf,iPara.Ts);
    sInfo{i}.iPara.dT = min(dT(2),12);
    Tmax(i) = 24*dT(1)+dT(2);
end
    
% sets the solution time
set(handles.editSolnTime,'string',num2str(sInfo{iFile}.iPara.dT))

% sets the maximum split time
setappdata(hFig,'Tmax',Tmax)
setappdata(hFig,'sInfo',sInfo)

% sets the tree explorer icons
A = load('ButtonCData.mat');
[Im,mMap] = rgb2ind(A.cDataStr.Im,256);
[Ifolder,fMap] = rgb2ind(A.cDataStr.Ifolder,256);
imwrite(Im,mMap,getIconImagePath(hFig,'File'),'gif')
imwrite(Ifolder,fMap,getIconImagePath(hFig,'Folder'),'gif')

% --- initialises the explorer tree objects
function initExplorerTree(handles)

% parameters
dX = 10;

% object handle retrieval
hFig = handles.figExptSave;
hPanel = handles.panelExplorerTree;

% retrieves the file path information
fDir = getappdata(hFig,'fDir');
fName = getappdata(hFig,'fName');
fDirRoot = getappdata(hFig,'fDirRoot');

% tree explorer properties
rStr = getFinalDirString(fDirRoot);
pPos = getObjGlobalCoord(hPanel);
tPos = [dX*[1,1]+pPos(1:2),pPos(3:4)-1.5*dX];

% remove any added folders
removeAddedFolders()

% Root node
wState = warning('off');
hRoot = uitreenode('v0', rStr, rStr, [], false);
hRoot.setUserObject(fDirRoot);
set(0,'CurrentFigure',hFig);
warning(wState);

% sets the file/folder icons
Ifile = getIconImagePath(hFig,'File');
Ifolder = getIconImagePath(hFig,'Folder');

% adds the tree sub-nodes
for i = 1:length(fDir)
    % creates/determines the parent node of the current file name
    hNodeP = hRoot;
    fDirSp = strsplit(fDir{i}((length(fDirRoot)+2):end),filesep);         
    for j = 1:length(fDirSp)
        hNodeP = addFolderTreeNode(hNodeP,fDirSp{j},Ifolder);        
    end
    
    % adds in the experiment name leaf node
    hNodeL = uitreenode('v0',fName{i},fName{i},Ifile,true);
    hNodeL.setUserObject(i);
    hNodeP.add(hNodeL);
end

% creates the tree object
hTree = uitree('v0','parent',hPanel,'Root',hRoot,'position',tPos,...
               'SelectionChangeFcn',{@treeSelectChng,hFig});
hTree.expand(hRoot)
setappdata(hFig,'hTree',hTree)
expandExplorerTreeNodes(hFig);

% --- initialises the experiment/group name fields
function initExptInfo(handles)

% object handle retrieval
hFig = handles.figExptSave;
hTableEx = handles.tableExptName;
hTableGrp = handles.tableGroupName;
fName = getappdata(hFig,'fName');
fExtn = getappdata(hFig,'fExtn');

% initialises the experiment inclusion flag array
useExp = true(length(fName),1);
setappdata(hFig,'useExp',useExp);

% sets the experiment name table
Data = [fName(:),num2cell(true(length(fName),1)),fExtn(:)];
Data(:,end) = centreTableData(Data(:,end));

set(hTableEx,'Data',Data)
resetExptTableBG(hFig)
setTableSelection(hTableEx,0,0)

% auto-resizes the table
autoResizeTableColumns(hTableEx)
autoResizeTableColumns(hTableGrp)

% runs the table experiment name selection callback
tableExptName_CellSelectionCallback(hTableEx, [], handles)

% ------------------------------------ %
% --- FILE EXPLORER TREE FUNCTIONS --- %
% ------------------------------------ %

% --- sets up the full file path string
function [fFile,fDir] = getCurrentFilePath(hFig,iExp)

% sets the input arguments
if ~exist('iExp','var'); iExp = 1; end

% retrieves the file data arrays
handles = guidata(hFig);
fName0 = getappdata(hFig,'fName');

% retrieves the directory name based on the output directory type
if get(handles.radioFixedOutput,'Value')
    % case is using a fixed output directory
    fDir = getappdata(hFig,'fDirFix');
else
    % case is using a customised structure
    fDir0 = getappdata(hFig,'fDir');
    fDir = fDir0{iExp};
end

% sets the full file name
fFile = fullfile(fDir,fName0{iExp});

% --- retrieves the explorer tree node for the iExp
function hNodeP = getExplorerTreeNode(hFig,iExp)

hTree = getappdata(hFig,'hTree');

for i = 1:hTree.getRoot.getLeafCount
    % sets the next node to search for
    if i == 1
        % case is from the root node
        hNodeP = hTree.getRoot.getFirstLeaf;
    else
        % case is for the other nodes
        hNodeP = hNodeP.getNextLeaf;
    end
       
    % if the correct node was found, then exit the loop
    if hNodeP.getUserObject == iExp
        break
    end
end

% --- retrieves the explorer tree node for the iExp
function expandExplorerTreeNodes(hFig)

% initialisations
hTree = getappdata(hFig,'hTree');

for i = 1:hTree.getRoot.getLeafCount
    % sets the next node to search for
    if i == 1
        % case is from the root node
        hNodeP = hTree.getRoot.getFirstLeaf;
    else
        % case is for the other nodes
        hNodeP = hNodeP.getNextLeaf;
    end
    
    % retrieves the selected node
    hTree.expand(hNodeP.getParent);
end

% --- tree node update function
function treeNodeUpdate(hFig,Type,iExp,varargin)

% initialisations
hTree = getappdata(hFig,'hTree');
Ifile = getIconImagePath(hFig,'File');

% retrieves the root node
hRoot = hTree.getRoot;

%
switch Type
    case 'move'
        % removes the existing node and replaces with the new
        treeNodeUpdate(hFig,'remove',iExp,1)
        treeNodeUpdate(hFig,'add',iExp,1)  
        
    case 'add'
        % case is adding a new node
        fDir = getappdata(hFig,'fDir');
        fName = getappdata(hFig,'fName');
        Ifolder = getIconImagePath(hFig,'Folder');
        
        % determines the folder to add
        hP = {hRoot};
        fDirRoot = getappdata(hFig,'fDirRoot');
        fDirAdd = fDir{iExp}((length(fDirRoot)+2):end);
        
        % retrieves/add in the parent folder node
        fDirSp = strsplit(fDirAdd,filesep);
        for j = 1:length(fDirSp)
            hP{end+1} = addFolderTreeNode(hP{end},fDirSp{j},Ifolder);
        end        

        % adds in the leaf node
        hNodeL = uitreenode('v0',fName{iExp},fName{iExp},Ifile,true);
        hNodeL.setUserObject(iExp);
        hP{end}.add(hNodeL);

        % reloads all the nodes
        cellfun(@(x)(hTree.reloadNode(x)),hP)
        
    case 'remove'
        % case is removing an existing node
        hNodeL = getExplorerTreeNode(hFig,iExp);
        
        % delete the leaf node and any empty folder nodes
        while 1
            % retrieves the parent node and deletes the current
            hNodeP = hNodeL.getParent();
            hNodeP.remove(hNodeL);
            hTree.reloadNode(hNodeP);
            
            %
            if (hNodeP.getChildCount > 0) || isequal(hRoot,hNodeP)
                % if the parent node has children, or is the root, then
                % exit the loop
                break
            else
                % otherwise, reset the leaf node for removal
                hNodeL = hNodeP;
            end
        end
end

% repaints the tree
if nargin == 3
    expandExplorerTreeNodes(hFig)
    hTree.repaint();    
    pause(0.05);
end

% --- creates a tree node from the parent node hNodeP
function hNodeP = addFolderTreeNode(hNodeP,nName,Iicon)

% global variables
global addedDir

% sets the default input aruments
if ~exist('Iicon','var'); Iicon = []; end

if hNodeP.getChildCount > 0
    % if the current node has children nodes, then 
    indC = 1:hNodeP.getChildCount;
    hNodeC = arrayfun(@(x)(hNodeP.getChildAt(x-1)),indC(:),'un',0);
    chNode = cellfun(@(x)(char(x.getName)),hNodeC,'un',0);
    isLeaf = cellfun(@(x)(logical(x.isLeaf)),hNodeC);
    
    %
    isEx = strcmp(chNode,nName) & ~isLeaf;
    if any(isEx)
        % if the node exists, then retrieve it
        hNodeP = hNodeP.getChildAt(find(isEx)-1);
        isAdd = false;
    else
        % otherwise, add a new node
        isAdd = true;
    end

else
    % if the node count is zero, then add the node
    isAdd = true;
end

% adds the new node (if required)
if isAdd && ~isempty(nName)
    % adds a new node to the tree
    hNodeP.setAllowsChildren(true);
    hNodeNw = uitreenode('v0',nName,nName,Iicon,false);
    hNodeP.add(hNodeNw);   

    % retrieves the full path of the new node
    fDirNw = getFullNodePath(hNodeNw);
    if ~exist(fDirNw,'dir')
        % if the directory does not exist, then create it
        mkdir(fDirNw)
        addedDir = [addedDir;{fDirNw}];
    end
    
    % updates the parent node to the new node
    hNodeP = hNodeP.getChildAt(hNodeP.getChildCount-1);
end

% --- updates the selected tree node
function resetSelectedNode(hFig,iRow)

% global variables
global isUpdating

% retrieves the tree object handle
hTree = getappdata(hFig,'hTree');
useExp = getappdata(hFig,'useExp');
                       
% retrieves the currently selected and candidate tree nodes
hNodeS = hTree.getSelectedNodes; 
if ~useExp(iRow)
    hNodeNw = [];
else
    hNodeNw = getExplorerTreeNode(hFig,iRow);
end
    
% determines if the tree node needs updating
if isempty(hNodeS)
    % if no selected node, then update 
    updateNode = true;
else
    % otherwise, determine if there is a difference between the 2
    updateNode = ~isequal(hNodeS(1),hNodeNw);
end
                       
% updates the tree selected node (if required)
if updateNode
    isUpdating = true;
    hTree.setSelectedNode(hNodeNw);
    pause(0.05);
    isUpdating = false;   
end

% --- updates the explorer tree
function updateTreeExplorerName(handles,iExp)

% global variables
global isUpdating

% initialisations
hFig = handles.figExptSave;
hTree = getappdata(hFig,'hTree');
fName = getappdata(hFig,'fName');

% retrieves the explorer tree node
hNodeP = getExplorerTreeNode(hFig,iExp);

% updates the experiment name
isUpdating = true;
hNodeP.setName(fName{iExp});
hTree.reloadNode(hNodeP);
hTree.repaint()
isUpdating = false;

% --- retrieves the full directory path of the node, hNodeNw
function fPath = getFullNodePath(hNodeNw)

hNodePath = hNodeNw.getPath;
fPathN = arrayfun(@(x)(char(x.getName())),hNodePath(2:end),'un',0);
fPath = strjoin([{hNodePath(1).getUserObject};fPathN]',filesep);

% ------------------------------------- %
% --- OTHER OBJECT UPDATE FUNCTIONS --- %
% ------------------------------------- %

% --- resets the chooser file
function resetChooserFile(hFig,iExp,fFileNw,forceUpdate)

% global variables
global isUpdating

% sets the default input arguments
if ~exist('forceUpdate','var'); forceUpdate = false; end

% initialisations
jFileC = getappdata(hFig,'jFileC');
if ~exist('fFileNw','var'); fFileNw = []; end
fFileS = char(jFileC.getSelectedFile());

% retrieves the current file name and the new file name
if isempty(fFileNw) || forceUpdate   
    fFileNw = getCurrentFilePath(hFig,iExp);
end

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

% --- resets the experiment name tables background colours
function resetExptTableBG(hFig)

% global variables
global isUpdating

% determines which experiments currently exist
handles = guidata(hFig);
fileExist = detExistingExpt(hFig);

% updates the table background colours 
isUpdating = true;
bgCol = getExptNameTableColour(getappdata(hFig,'useExp'),fileExist);
set(handles.tableExptName,'BackgroundColor',bgCol)  
pause(0.05);
isUpdating = false;

% --- Executes when selected object is changed in panelFileType.
function updateObjectProps(handles,iExp)

% sets the default argument values
if ~exist('iExp','var'); iExp = 1; end

% initialisations
igChk = {'checkOutputY'};
[isCSV,isOut,isTime] = deal(false,true,true);

% determines if there are any stimuli events
hFig = handles.figExptSave;
sInfo = getappdata(hFig,'sInfo');
fExtn = getappdata(hFig,'fExtn');
oPara = getappdata(hFig,'oPara');
hasStim = sInfo{iExp}.hasStim;

% retrieves the table data data
tabDataEx = get(handles.tableExptName,'Data');

% updates the panel properties
setPanelProps(handles.panelOtherPara,tabDataEx{iExp,2})

% updates the GUI properties based on the
switch fExtn{iExp}
    case {'.ssol','.mat'} % case is the DART Solution File
        [isOut,isTime] = deal(false);
        set(handles.checkSolnTime,'value',0)
        checkSolnTime_Callback(handles.checkSolnTime, [], handles)
        
    case ('.txt') % case is the ASCII text file
        isCSV = true;
end

% updates the check properties (if required)
if tabDataEx{iExp,2}
    % updates the check-box properties
    setObjEnable(handles.checkUseComma,isCSV)
    setObjEnable(handles.checkSolnTime,isTime)
    setObjEnable(handles.checkOutputY,~sInfo{iExp}.snTot.iMov.is2D)

    % sets the output checkbox enabled properties
    setObjEnable(handles.checkOutputExpt,isOut)
    setObjEnable(handles.checkOutputStim,isOut && hasStim)
end

% updates the checkbox values
pFld = fieldnames(oPara(iExp));
for i = 1:length(pFld)
    % retrieves the checkbox item
    hChk = findall(handles.panelOtherPara,'UserData',pFld{i},...
                                          'Style','CheckBox');       
    tagStr = get(hChk,'tag');
                                      
    if strcmp(get(hChk,'Enable'),'off') && ~any(strcmp(igChk,tagStr))
        % if the checkbox is disabled, then reset the flag value to false
        oPara(iExp) = setStructField(oPara(iExp),pFld{i},false);
    end
    
    % updates the checkbox value
	set(hChk,'Value',getStructField(oPara(iExp),pFld{i}));    
end

% updates the solution time values
setappdata(hFig,'oPara',oPara)
set(handles.editSolnTime,'string',num2str(sInfo{iExp}.iPara.dT));

% --- removes all of the added folders
function removeAddedFolders()

% global variables
global addedDir

% if there are no added directories then exit the function
if isempty(addedDir); return; end

% splits the added directory paths and orders by descending size
fDirSp = cellfun(@(x)(strsplit(x,filesep)),addedDir,'un',0);
[~,iS] = sort(cellfun(@length,fDirSp),'descend');
dirRemove = addedDir(iS);

% removes any of the added folders which are empty
for i = 1:length(dirRemove)
    dirData = dir(dirRemove{i});
    if ~any(arrayfun(@(x)(x.bytes),dirData) > 0)
        % if the directory is empty, then remove it
        try; rmdir(dirRemove{i}); end
    end
end

% global variables
addedDir = [];

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% --- retrieves the icon image data for type, Type
function iconImg = getIconImagePath(hFig,Type)

% retrieves temporary directory path
iProg = getappdata(hFig,'iProg');
tDir = iProg.TempFile;

% sets the full icon path
iconImg = fullfile(tDir,sprintf('%s.gif',Type));

% --- determines which output files/directories already exist
function [fileExist,fFile] = detExistingExpt(hFig,ind)

% object retrieval
handles = guidata(hFig);
fName = getappdata(hFig,'fName');
fExtn = getappdata(hFig,'fExtn');

% retrieves the base directory names
if get(handles.radioFixedOutput,'Value')
    % case is a output to a fixed directory
    fDirFix = getappdata(hFig,'fDirFix');
    fDir = repmat({fDirFix},length(fName),1);
else
    % case is output to the custom tree structure
    fDir = getappdata(hFig,'fDir');
end

% memory allocation
if ~exist('ind','var'); ind = 1:length(fName); end
[fileExist,fFile] = deal(false(length(ind),1),cell(length(ind),1));

% determines if the file/directory exists (depending on extension type)
for i = 1:length(ind)
    j = ind(i);
    switch fExtn{j}
        case {'.ssol','.mat'}
            % case is a file output
            fFile{i} = fullfile(fDir{j},[fName{j},fExtn{j}]);
            fileExist(i) = exist(fFile{i},'file') > 0;
        otherwise
            % case is a directory output
            fFile{i} = fullfile(fDir{j},fName{j});
            fileExist(i) = exist(fFile{i},'dir') > 0;
    end    
end

% --- updates the inclusion flag for the experiment index, iExp
function useExp = updateExptInclusionFlag(hFig,iExp,nwValue)

useExp = getappdata(hFig,'useExp');
useExp(iExp) = nwValue;
setappdata(hFig,'useExp',useExp)

% --- sets the experiment name table background colour array
function bgCol = getExptNameTableColour(ok,fileExist)

% sets the default input arguments
if ~exist('fileExist','var'); fileExist = []; end

% sets the background colour array
bgCol = ones(length(ok),3);
bgCol(~ok,:) = 0.81;

% if the existing file information is given then add this info to the array
if ~isempty(fileExist)
    bgCol(fileExist,1) = 1;
    bgCol(fileExist,2:3) = 0.5;
    bgCol(~ok & fileExist,2:3) = 0.81;
end

% --- sets the group name table background colour array
function bgCol = getGroupNameTableColour(hFig,iExp)

% field retrieval
sInfo0 = getappdata(hFig,'sInfo');
gName0 = getappdata(hFig,'gName');
[sInfo,gName] = deal(sInfo0{iExp},gName0{iExp});

% retrieves the unique group names from the list
grayCol = 0.81;
[gNameU,~,iGrpNw] = unique(gName,'stable');
isOK = sInfo.snTot.iMov.ok & ~strcmp(gName,'* REJECTED *');

% sets the background colour based on the matches within the unique list
tCol = getAllGroupColours(length(gNameU),1);
bgCol = tCol(iGrpNw,:);
bgCol(~isOK,:) = grayCol;

% --- resets the chooser file extension to fExtn
function resetChooserFileExtn(jFileC,fExtn)

% global variables
global isUpdating

% retrieves the list of choosable file filters
jExtn = jFileC.getChoosableFileFilters;
txtExtn = arrayfun(@(x)(get(x,'SimpleFilterExtension')),jExtn,'un',0);

% resets the file filter
isUpdating = true;
jFileC.setFileFilter(jExtn(strcmp(txtExtn,fExtn)))
pause(0.05);
isUpdating = false;

% --- sets the value, cValue, at the (iRow,iCol) cell in the table, hTable
function setTableValue(hTable,iRow,iCol,cValue)

% global variables
global isUpdating

% flag that an updating is occuring
isUpdating = true;

% retrieves the java table object
jTable = getJavaTable(hTable);
jTable.setValueAt(cValue,iRow-1,iCol-1)
pause(0.05);

% resets the update flag
isUpdating = false;
