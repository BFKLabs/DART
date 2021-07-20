function varargout = MultFlyCombInfo(varargin)
% Last Modified by GUIDE v2.5 06-Jul-2021 20:03:24

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @MultFlyCombInfo_OpeningFcn, ...
    'gui_OutputFcn',  @MultFlyCombInfo_OutputFcn, ...
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

% --- Executes just before MultFlyCombInfo is made visible.
function MultFlyCombInfo_OpeningFcn(hObject, eventdata, handles, varargin)

% global variables
global fColLo fColHi greyCol nAppMx
[fColLo,fColHi,greyCol,nAppMx] = deal(0.4,0.7,0.2*[1 1 1],9);

% Choose default command line output for MultFlyCombInfo
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% sets the input arguments
hGUI = varargin{1};
setappdata(hObject,'hGUI',hGUI)
setappdata(hObject,'hGUIInfo',[]);

% makes the info GUI invisible (if it exists)
hGUIInfoM = getappdata(hGUI.figFlyCombine,'hGUIInfo');
if ~isempty(hGUIInfoM)
    setObjVisibility(hGUIInfoM.hFig,'off')
end

% makes the main and current GUIs invisible
setObjVisibility(hGUI.figFlyCombine,'off')
setObjVisibility(hObject,'off'); 
pause(0.01);

% retrieves the program defaults data struct
iProg = getappdata(hGUI.figFlyCombine,'iProg');

% clears the image axis
set(handles.tableAppName,'Data',{''});
setObjEnable(handles.menuSave,'off')
cla(handles.axesSoln); axis(handles.axesSoln,'off')
cla(handles.axesDN); axis(handles.axesDN,'off')

% initialises the all/experimental data structs
initMoveButtons(handles)
initPopupObjects(handles.panelStartTime,'hMin')
initPopupObjects(handles.panelFinishTime,'hMax')
[iSolnAll,iSolnAdd] = initDataStruct(handles);
centreFigPosition(hObject);

% sets the data structs into the GUI
setappdata(hObject,'iProg',iProg);
setappdata(hObject,'iPara',initParaStruct);
setappdata(hObject,'iSolnAll',iSolnAll);
setappdata(hObject,'iSolnAdd',iSolnAdd);
setappdata(hObject,'appOut',[]);
setappdata(hObject,'snTot',[]);

% UIWAIT makes MultFlyCombInfo wait for user response (see UIRESUME)
% uiwait(handles.figMultCombInfo);

% --- Outputs from this function are returned to the command line.
function varargout = MultFlyCombInfo_OutputFcn(hObject, eventdata, handles)

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                         MENU CALLBACK FUNCTIONS                         %
%-------------------------------------------------------------------------%

% -------------------------------------------------------------------------
function menuLoadExpt_Callback(hObject, eventdata, handles)

% retrieves the program default files
iProg = getappdata(handles.figMultCombInfo,'iProg');

% sets the files types based on the solution file type being opened
if ~isa(eventdata,'struct')
    % case is the experiment solution file
    fFile = DirTree({'.ssol'},iProg.DirComb);
    if isempty(fFile)
        % if the user cancelled, then exit the function
        return
    else
        % creates a waitbar figure
        wStr = {'Reading Experimental Solution File'};
        h = ProgBar(wStr,'Experimental Solution File Loading');
        
        % if the file name is not a cell array, then convert to cell
        isMulti = false;
        if ~iscell(fFile)
            fFile = {fFile};
        else
            fFile = fFile(:);
        end
    end
else
    % case is a multi-experiment solution file
    [isMulti,fFile] = deal(true,eventdata.fFile);
end
    
% retrieves the program data struct
iSolnAll = getappdata(handles.figMultCombInfo,'iSolnAll');
i0 = length(iSolnAll.iExpt);

% determines the indices of the files to add
if isempty(iSolnAll.fDir)
    % sets the indices to add to be all the items
    iAdd = (1:length(fFile))';
else
    % sets the old file names and determines the unique items to add
    if isMulti
        % case is from opening a multi-experiment solution file
        fNameOld = iSolnAll.fName;
    else
        % case is from opening experiment solution files
        fNameOld = cellfun(@(x,y)(fullfile(x,[y,'.ssol'])),...
                        iSolnAll.fDir,iSolnAll.fName,'un',0);       
    end
                    
    % if there are no new unique filenames, then exit the function
    iAdd = find(cellfun(@(x)(~any(strcmp(x,fNameOld))),fFile));
    if isempty(iAdd)
        return
    end
end

% sets the file directories/names to be added
nAdd = length(iAdd);
if isMulti
    % case is a multi-experiment solution file
    fDir = repmat({eventdata.mFile},nAdd,1);
    fNameNw = reshape(eventdata.fFile(iAdd),nAdd,1);
    
    % sets the sotluion file array (ensures is a row cell array)    
    snTotNw = num2cell(reshape(eventdata.snTot(iAdd),nAdd,1));        
else
    % case is experiment solution files
    fDir = cellfun(@(x)(fileparts(x)),fFile(iAdd),'un',0);
    fName = cellfun(@(x)(getFinalDirString(x)),fFile(iAdd),'un',0);
    fNameNw = cellfun(@(x)(x(1:(end-5))),fName,'un',0);
    
    % sets an empty solution file array
    snTotNw = cell(nAdd,1);    
end

% resets the file names/directories and total file counts
iSolnAll.fDir = [iSolnAll.fDir;fDir];
iSolnAll.isAdded = [iSolnAll.isAdded;false(nAdd,1)];
iSolnAll.isMulti = [iSolnAll.isMulti;repmat(isMulti,nAdd,1)];
iSolnAll.fName = [iSolnAll.fName;fNameNw];

% updates the solution file data struct with the new data
snTot = [getappdata(handles.figMultCombInfo,'snTot');snTotNw];
setappdata(handles.figMultCombInfo,'snTot',snTot)

% loads the data from all the unique experimental files
[a,b] = deal(cell(nAdd,1),zeros(nAdd,1));
iSolnAll.nApp = [iSolnAll.nApp;b];
iSolnAll.appName = [iSolnAll.appName;a];
[iSolnAll.iExpt,iSolnAll.T] = deal([iSolnAll.iExpt;a],[iSolnAll.T;a]);

% loads each of the solution files
for i = 1:nAdd
    % updates the waitbar
    if ~isMulti
        if h.Update(1,sprintf('%s (%i of %i)',wStr{1},i,nAdd),i/nAdd)
            % if the user cancelled, then exit the function
            return
        end
    end
    
    % sets the new index
    j = i + i0;               
    if isMulti
        % sets the acceptance flag array
        okNw = snTotNw{i}.iMov.ok;
        
        % case is a multi-experiment solution file
        iSolnAll.T{j} = snTotNw{i}.T;
        iSolnAll.iExpt{j} = snTotNw{i}.iExpt; 
        iSolnAll.nApp(j) = sum(okNw);
        iSolnAll.appName{j} = snTotNw{i}.iMov.pInfo.gName(okNw);
        
    else
        % case is a the experiment solution files
        
        % untars the file and determines the Data file
        nwFile = fullfile(iSolnAll.fDir{j},[iSolnAll.fName{j},'.ssol']);
        A = untar(nwFile,iProg.TempFile);
        isData = cellfun(@(x)(strContains(x,'Data.mat')),A);

        % loads the information component of the experimental solution file
        aa = load(A{isData},'-mat');
        
        % sets the data struct fields        
        [iSolnAll.T{j},iSolnAll.iExpt{j}] = deal(aa.T,aa.iExpt);
        
        % sets the region name/counts based on the format type
        if isfield(aa,'cID')
            % case is the new format files
            iSolnAll.nApp(j) = length(aa.cID);     
            
            % sets the group name indices (dependent on expt type)
            if aa.iMov.is2D
                % case is a 2D expt
                indG = cellfun(@(x)(x(1,end)),aa.cID);
            else
                % case is a 1D expt
                nC = aa.iMov.pInfo.nCol;
                indG = cellfun(@(x)((x(1,1)-1)*nC+x(1,2)),aa.cID);
            end
            
            % sets the group names
            iSolnAll.appName{j} = aa.iMov.pInfo.gName(indG);
        else
            % case is the old format files
            iSolnAll.nApp(j) = sum(aa.appPara.ok);
            iSolnAll.appName{j} = aa.appPara.Name(aa.appPara.ok);            
        end
        
        % deletes the files and clears the file data
        cellfun(@delete,A)
        clear aa        
    end    
end

% updates the data struct
setappdata(handles.figMultCombInfo,'iSolnAll',iSolnAll);

% resets the GUI object properties (if initialising)
setObjEnable(handles.menuClearAll,'on')
if length(iSolnAll.iExpt) == nAdd
    resetSolnProps(handles,iSolnAll,~isa(eventdata,'struct'))
else
    % updates the information fields
    set(handles.listSolnAll,'string',iSolnAll.fName);
end

% post solution file selection operations
if isMulti
    % if opening a multi-experiment solution file, then add the new files
    set(handles.listSolnAll,'value',i0+(1:nAdd)')
    buttonSolnAdd_Callback(handles.buttonSolnAdd, '1', handles)     
    
    % sets the other GUI object properties
    set(handles.listSolnAll,'value',[])
    setObjEnable(handles.buttonSolnAdd,'off')
    
    % makes the GUI visible again
    pause(0.5);
    setObjVisibility(handles.figMultCombInfo,'on'); 
else
    % closes the waitbar
    h.closeProgBar(); 
end

% -------------------------------------------------------------------------
function menuLoadMultiExpt_Callback(hObject, eventdata, handles)

% loads the data structs from the GUI
iProg = getappdata(handles.figMultCombInfo,'iProg');
fType = {'*.msol','Multi-Experiment Solution Files (*.msol)'};

% prompts the user for the solution file directory
[fName,fDir,fIndex] = uigetfile(fType,'Select The Multi-Solution File',...
                                iProg.DirComb);
if fIndex == 0
    % if the user cancelled, then exit
    return
else
    % sets the solution file name
    mFile = fullfile(fDir,fName);   
end

% loads the multi-experiment solution file
[snTot,fFile,ok] = loadMultiExptSolnFiles(iProg.TempFile,mFile);
if ~ok
    % if the user cancelled, then exit the function
    return
else
    % sets the opened data into a struct
    eData = struct('snTot',[],'fFile',[],'mFile',mFile);
    [eData.fFile,eData.snTot] = deal(fFile,snTot);
    
    % runs the loading experimental solution file function
    menuLoadExpt_Callback(handles.menuLoadExpt, eData, handles)
end
    
% -------------------------------------------------------------------------
function menuSaveSoln_Callback(hObject, eventdata, handles)

% prompts the user for the movie filename
iProg = getappdata(handles.figMultCombInfo,'iProg');

% prompts the user for the movie filename
[mName, mDir, fIndex] = uiputfile(...
    {'*.msol','Multi-Experimental Solution Files (*.msol)'},...
    'Saving Multi-Experimental Solution File',iProg.DirComb);
if fIndex == 0
    % if the user cancelled, then exit the function
    return
else
    % retrieves the solution file data structs    
    snTotM = getappdata(handles.figMultCombInfo,'snTot');
    iSolnAdd = getappdata(handles.figMultCombInfo,'iSolnAdd');
    appOut = getappdata(handles.figMultCombInfo,'appOut');
    
    % memory allocation
    [mFile,tmpDir] = deal(fullfile(mDir,mName),iProg.TempFile);    
    tmpFile = fullfile(iProg.TempFile,'Temp.tar');    
    [nFile,fName] = deal(iSolnAdd.nCount,iSolnAdd.fName);
    tarFiles = cell(nFile,1);
    sFile = cellfun(@(x,y)(fullfile(x,[y,'.ssol'])),iSolnAdd.fDir,...
        iSolnAdd.fName,'un',0);
end

% creates the waitbar figure
wStr = {'Overall Progress','Current Field Progress','Solution File Output'};
h = ProgBar(wStr,'Creating Multi-Experimental Solution File');

% loops through all the variable strings loading the data from the
% individual experiment solution files, and adding it to the 
% multi-experiment solution file
for i = 1:nFile
    % clears the lower waitbars (for files > 1)
    if i > 1
        h.Update(2,wStr{2},0);
        h.Update(3,wStr{3},0);
    end
    
    % updates the waitbar figure
    fNameNw = simpFileName(fName{i},15);
    wStr1 = sprintf('Appending "%s" (%i of %i)',fNameNw,i,nFile);    
    if h.Update(1,wStr1,i/nFile)
        % if the user cancelled, delete the solution files and exits 
        cellfun(@delete,tarFiles(1:(i-1)))
        return        
    end    
    
    % determines if the solution data has already been loaded
    if iSolnAdd.isMulti(i)
        % if so, retrieve the solution data struct
        snTot = snTotM{iSolnAdd.Order(i)};
        ok = snTot.iMov.ok;
        
        % reduces the arrays to remove any missing arrays
        snTot.iMov.pInfo.gName = snTot.iMov.pInfo.gName(ok);
        if ~isempty(snTot.Px); snTot.Px = snTot.Px(ok); end
        if ~isempty(snTot.Py); snTot.Py = snTot.Py(ok); end        
    else
        % sets the output apparatus indices 
        ii = find(iSolnAdd.indOut{i} > 0);
        [~,jj] = sort(iSolnAdd.indOut{i}(ii),'ascend');
        indApp = ii(jj);        
        
        % creates the new cell array for the new variable
        [snTot,ok] = loadExptSolnFiles...
                                (tmpDir,sFile{i},0,handles,i,indApp,h);
        if ~ok
            % if the user cancelled, then exit the function
            cellfun(@delete,tarFiles(1:(i-1)))
            return
        end
    end

    % reduces down the data sets into combined solution files
    kk = find(~cellfun(@isempty,appOut));
    indNw = arrayfun(@(x)(find(x == iSolnAdd.indOut{i})),kk,'un',0);
    
    % sets the final apparatus names
    appName = appOut(1:length(indNw));
   
%     % updates the region data struct
%     snTot = updateRegionInfo(snTot);
%     snTot = reshapeExptSolnFile(snTot);
    
    % removes any extraneous fields    
    snTot = reduceExptSolnFiles(snTot,indNw,appName);
    if isfield(snTot,'sName')        
        snTot = rmfield(snTot,'sName');
    end        
        
    % outputs the single combined solution file
    tarFiles{i} = fullfile(iProg.TempFile,[fName{i},'.ssol']);
    if ~saveExptSolnFile(iProg.TempFile,tarFiles{i},snTot,[],h)
        % otherwise, delete the solution files and exits 
        cellfun(@delete,tarFiles(1:(i-1)))
        return
    end
    
    % updates the waitbar figure
    h.Update(2,'Solution File Update Complete!',1);
end

% creates and renames the tar file to a solution file extension
tar(tmpFile,tarFiles)
movefile(tmpFile,mFile,'f');

% deletes the temporary files and closes the waitbar figure
cellfun(@delete,tarFiles)
h.closeProgBar()

% -------------------------------------------------------------------------
function menuClearAll_Callback(hObject, eventdata, handles)

% prompt the user if they want to clear all the data
qStr = 'Are you sure you want to clear all the loaded data?';
uChoice = questdlg(qStr,'Clear All Data?','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    % if the user rejected clearing all, then exit the function
    return
end

% object retrieval
hFig = handles.figMultCombInfo;

% resets the all/added data structs
[iSolnAll,iSolnAdd] = initDataStruct(handles);
setappdata(hFig,'iSolnAll',iSolnAll)
setappdata(hFig,'iSolnAdd',iSolnAdd)
setappdata(hObject,'snTot',[]);

% runs the solution reset
buttonSolnReset_Callback(handles.buttonSolnReset, '1', handles)

% disables the add button
setObjEnable(hObject,'off')
setObjEnable(handles.buttonSolnAdd,'off')

% -------------------------------------------------------------------------
function menuExit_Callback(hObject, eventdata, handles)

% prompts the user if they wish to close the main gui
qStr = 'Are you sure you want to close the GUI?';
uChoice = questdlg(qStr,'Close GUI?','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    return
end

% retrieves the main GUI handles
hGUI = getappdata(handles.figMultCombInfo,'hGUI');

% deletes the GUI
delete(handles.figMultCombInfo); pause(0.05);
setObjVisibility(hGUI.figFlyCombine,'on');

% makes the info GUI visible (if it exists)
hGUIInfoM = getappdata(hGUI.figFlyCombine,'hGUIInfo');
if ~isempty(hGUIInfoM)
    setObjVisibility(hGUIInfoM.hFig,'on')
end

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --------------------------------------- %
% --- SOLUTION FILE LISTBOX CALLBACKS --- %
% --------------------------------------- %

% --- Executes on selection change in listSolnAll.
function listSolnAll_Callback(hObject, eventdata, handles)

% retrieves the maximum value of the other listbox
yMax = get(hObject,'max');
if yMax == 2
    % updates the listbox properties
    set(handles.listSolnAdded,'max',2,'value',[])
    
    % retrieves the indices of the selected item
    setObjEnable(handles.buttonSolnAdd,'on')
    setObjEnable(handles.buttonSolnRemove,'off')
end

% % resets the alpha patch on the graph
setMoveButtonProp(handles)
resetPatchAlpha(handles.axesSoln,0)
updateLinkTable(handles,[])

% updates the panel properties
setPanelProps(handles.panelSolnDetails,'off')
set(handles.textSolnCount,'string',' ')
set(handles.textSetupCorrect,'string',' ')

% --- Executes on selection change in listSolnAdded.
function listSolnAdded_Callback(hObject, eventdata, handles)

% retrieves the maximum value of the other listbox
yMax = get(hObject,'max');
if (yMax == 2)
    % updates the listbox properties
    set(hObject,'max',1);
    set(handles.listSolnAll,'value',[])
    
    % retrieves the indices of the selected item
    setObjEnable(handles.buttonSolnAdd,'off')
    setObjEnable(handles.buttonSolnRemove,'on')
end

% loads the solution data struct
iSolnAdd = getappdata(handles.figMultCombInfo,'iSolnAdd');

% resets the alpha patch on the graph
iSel = get(hObject,'Value');
setMoveButtonProp(handles,iSel)
resetPatchAlpha(handles.axesSoln,iSel)
updateLinkTable(handles,iSel)

% updates the solution file information
setPanelProps(handles.panelSolnDetails,'on')
setAddList(handles,iSolnAdd)
set(handles.textSolnCount,'string',sprintf('%i',iSolnAdd.nApp(iSel)))

% --- Executes on button press in buttonClearApp.
function buttonClearApp_Callback(hObject, eventdata, handles)

% resets the apparatus names
appOut = getappdata(handles.figMultCombInfo,'appOut');

% decrements the link indices
for i = sum(~cellfun(@isempty,appOut)):-1:1
    decrementLinkIndices(handles,i)
end

% clears the apparatus output names
appOut(:) = {''};
setappdata(handles.figMultCombInfo,'appOut',appOut);

% updates the apparatus link table data
tableAppLink_CellEditCallback([], '1', handles)
set(handles.tableAppName,'Data',appOut)
updateLinkTable(handles,get(handles.listSolnAdded,'value'))

% --- Executes on button press in buttonSyncInd.
function buttonSyncInd_Callback(hObject, eventdata, handles)

% prompt the user to make sure they really want to sychronise the indices
uChoice = questdlg(['Do you want to synchronise all the region link ',...
                  'indices?'],'Synchronise Link Indices','Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    % if the user cancelled, then exit the function
    return
else
    % loads the solution file data struct
    iSel = get(handles.listSolnAdded,'value');
    iSolnAdd = getappdata(handles.figMultCombInfo,'iSolnAdd');
end

% resets the ouput indices for all the
nSel = length(iSolnAdd.indOut{iSel});
for i = 1:iSolnAdd.nCount
    jj = 1:min(nSel,length(iSolnAdd.indOut{i}));
    iSolnAdd.indOut{i}(jj) = iSolnAdd.indOut{iSel}(jj);
end

% updates the solution struct and the table data
setappdata(handles.figMultCombInfo,'iSolnAdd',iSolnAdd);
tableAppLink_CellEditCallback(hObject, eventdata, handles)

% ----------------------------------------------- %
% --- SOLUTION FILE LIST PUSHBUTTON CALLBACKS --- %
% ----------------------------------------------- %

% --- Executes on button press in buttonSolnAdd.
function buttonSolnAdd_Callback(hObject, eventdata, handles)

% retrieves the program data struct
indNw = get(handles.listSolnAll,'Value');
indNw = reshape(indNw,length(indNw),1);

% retrieves the total/added solution data array structs
iSolnAll = getappdata(handles.figMultCombInfo,'iSolnAll');
iSolnAdd = getappdata(handles.figMultCombInfo,'iSolnAdd');

% resets the array to only include those not already added
indNw = indNw(~iSolnAll.isAdded(indNw));
if iSolnAll.isAdded(indNw)
    % if there are no unique solutions to add, then exit the function
    return
end

% updates the added flags
iSolnAll.isAdded(indNw) = true;
setappdata(handles.figMultCombInfo,'iSolnAll',iSolnAll);

% enables the remove/reset buttons
setObjEnable(handles.menuSave,'on')
setObjEnable(handles.buttonSolnReset,'on')

% makes the GUI invisible
setObjVisibility(handles.figMultCombInfo,'off'); pause(0.01);

% if there were no solutions added then enable the start/finish time panels
if iSolnAdd.nCount == 0
    % updates the panel properties
    setPanelProps(handles.panelStartTime,'on')
    setPanelProps(handles.panelFinishTime,'on')
    setObjEnable(handles.textOutName,'on')
    set(setObjEnable(handles.tableAppName,'on'),'visible','on')
    
    % resets the outer panel position
    pPos = get(handles.panelSolnOuter,'position');
    set(handles.panelSolnOuter,'position',[pPos(1:2) 1275 pPos(4)])
    
    % resets the figure position
    fPos = get(handles.figMultCombInfo,'position');
    set(handles.figMultCombInfo,'position',[fPos(1:2) 1295 fPos(4)])    
end

% updates the table dimensions
updateTableDim(handles);

% flags the new values to be added
[nAppNw,N0] = deal(iSolnAll.nApp(indNw),iSolnAdd.nCount);
iSolnAdd.nCount = sum(iSolnAll.isAdded);
iSolnAdd.fDir = [iSolnAdd.fDir;iSolnAll.fDir(indNw)];
iSolnAdd.fName = [iSolnAdd.fName;iSolnAll.fName(indNw)];
iSolnAdd.iExpt = [iSolnAdd.iExpt;iSolnAll.iExpt(indNw)];
iSolnAdd.T = [iSolnAdd.T;iSolnAll.T(indNw)];
iSolnAdd.nApp = [iSolnAdd.nApp;nAppNw];
iSolnAdd.appName = [iSolnAdd.appName;iSolnAll.appName(indNw)];
iSolnAdd.isMulti = [iSolnAdd.isMulti;iSolnAll.isMulti(indNw)];
iSolnAdd.Order = [iSolnAdd.Order;indNw];

% sets the output apparatus index arrays
Anw = arrayfun(@(x)(zeros(x,1)),nAppNw,'un',0);
iSolnAdd.indOut = [iSolnAdd.indOut;Anw];
setappdata(handles.figMultCombInfo,'iSolnAdd',iSolnAdd);

% sets the solution file names
reshapeAppNameTable(handles)
updateAddLists(handles)
updateSolnInfo(handles)

% makes the GUI visible again
centreFigPosition(handles.figMultCombInfo,1);
updateSolnPlot(handles)

% makes the GUI visible again
if ~isa(eventdata,'char')    
    setObjVisibility(handles.figMultCombInfo,'on'); 
end
    
% updates the cross-link information (if adding from multi-expt soln files)
isMulti = logical(iSolnAll.isMulti(indNw));
if (any(isMulti))    
    % sets the current apparatus count
    appOut = getappdata(handles.figMultCombInfo,'appOut');
    nOut = sum(~cellfun(@isempty,appOut));
    
    % sets the new apparatus names to be added
    appNameNw = unique(cell2cell(iSolnAll.appName(indNw(isMulti))));
    ii = find(cellfun(@(x)(~any(strcmp(x,appOut))),appNameNw));    
    
    % updates the apparatus name table
    if (~isempty(ii))
        % creates a loadbar
        if (sum(ii) > 2)
            h = ProgressLoadbar('Updating Cross-Link Name Tables...');
        end

        % updates the table with the new multi-experiment values
        for i = 1:length(ii)
            eData = struct('EditData',appNameNw{ii(i)},'Indices',nOut+i);
            tableAppName_CellEditCallback(handles.tableAppName, eData, handles)
        end

        % deletes the loadbar (if actually created)
        try; delete(h); end
    end
        
    % updates the cross-link names
    appOut = getappdata(handles.figMultCombInfo,'appOut');
    iSolnAdd = getappdata(handles.figMultCombInfo,'iSolnAdd');
        
    % sets the cross-link names for each of the new multi-expt files
    jj = indNw(logical(isMulti));
    for i = 1:length(jj)
        iSolnAdd.indOut{N0+i} = ...
            cellfun(@(x)(find(strcmp(x,appOut))),iSolnAll.appName{jj(i)});                        
    end
    
    % updates the solution struct
    setappdata(handles.figMultCombInfo,'iSolnAdd',iSolnAdd)
    setAddList(handles,iSolnAdd)
end

% --- Executes on button press in buttonSolnRemove.
function buttonSolnRemove_Callback(hObject, eventdata, handles)

% % global variables
% global nAppMx

% makes the GUI invisible 
setObjVisibility(handles.figMultCombInfo,'off'); 
pause(0.01);

% retrieves the program data struct
indNw = get(handles.listSolnAdded,'Value');
indNw = reshape(indNw,length(indNw),1);

% retrieves the total/added solution data array structs
% appOut = getappdata(handles.figMultCombInfo,'appOut');
iSolnAll = getappdata(handles.figMultCombInfo,'iSolnAll');
iSolnAdd = getappdata(handles.figMultCombInfo,'iSolnAdd');

% updates the added flags
jj = true(iSolnAdd.nCount,1); jj(indNw) = false;
iSolnAll.isAdded(iSolnAdd.Order(indNw)) = false;
setappdata(handles.figMultCombInfo,'iSolnAll',iSolnAll);

% resets the data arrays
ii = logical(iSolnAll.isAdded);
iSolnAdd.nCount = sum(ii);
iSolnAdd.fDir = iSolnAdd.fDir(jj);
iSolnAdd.fName = iSolnAdd.fName(jj);
iSolnAdd.iExpt = iSolnAdd.iExpt(jj);
iSolnAdd.T = iSolnAdd.T(jj);
iSolnAdd.nApp = iSolnAdd.nApp(jj);
iSolnAdd.appName = iSolnAdd.appName(jj);
iSolnAdd.indOut = iSolnAdd.indOut(jj);
iSolnAdd.isMulti = iSolnAdd.isMulti(jj);
iSolnAdd.Order = iSolnAdd.Order(jj);
setappdata(handles.figMultCombInfo,'iSolnAdd',iSolnAdd);

% enables the remove/reset buttons
if (iSolnAdd.nCount == 0)
    % resets the selection to the all loaded listbox
    indNw = [];
    set(handles.listSolnAll,'value',1)
    listSolnAll_Callback(handles.listSolnAll, [], handles)
    
    % disables the reset button
    setObjEnable(handles.buttonSolnReset,'off')
    setObjEnable(handles.menuSave,'off')
    
    % disable the start/finish time panels
    clearAllPanels(handles)
else
    % retrieves the selected index and reset the listbox
    indNw = min(iSolnAdd.nCount,indNw);
    set(handles.listSolnAdded,'Value',indNw)
    setMoveButtonProp(handles,indNw)
    set(handles.textSolnCount,'string',sprintf('%i',iSolnAdd.nApp(indNw)))
end

% % determines the new unique apparatus names
% appOutNw = unique(cell2cell(iSolnAdd.appName));
% if (length(appOutNw) ~= sum(~cellfun(@isempty,appOut)))            
%     % updates the apparatus names 
%     appOut(1:length(appOutNw)) = appOutNw;
%     appOut((length(appOutNw)+1):end) = {''};        
%     N = find(cellfun(@isempty,appOut),1,'first');
%     if (isempty(N)); N = length(appOut); end
%     
%     % reshapes the output apparatus name array
%     appOut = appOut(1:max(nAppMx,N));
%     setappdata(handles.figMultCombInfo,'appOut',appOut)
%             
%     % updates the apparatus indices
%     for i = 1:length(iSolnAdd.appName)
%         iSolnAdd.indOut{i} = ...
%             cellfun(@(x)(find(strcmp(x,appOut))),iSolnAdd.appName{i});        
%     end
%     
%     % updates the table to include
%     setappdata(handles.figMultCombInfo,'iSolnAdd',iSolnAdd)
% end

% sets the solution file names
updateLinkTable(handles,indNw)
updateAddLists(handles)
updateSolnInfo(handles)
updateSolnPlot(handles)
resetPatchAlpha(handles.axesSoln,indNw)

% makes the GUI visible again
setObjVisibility(handles.figMultCombInfo,'on'); 
pause(0.01);

% --- Executes on button press in buttonSolnReset.
function buttonSolnReset_Callback(hObject, eventdata, handles)

% resets the data structs and GUI object properties
iSolnAdd = getappdata(handles.figMultCombInfo,'iSolnAdd');
iSolnAll = getappdata(handles.figMultCombInfo,'iSolnAll');

% resets the data structs
if ischar(eventdata)
    % resets the added struct and flushes all the added regions
    [~,iSolnAdd] = initDataStruct(handles,1);
    iSolnAll.isAdded(:) = false;

    % resets the selection to the all loaded listbox
    set(handles.listSolnAll,'value',1)
    listSolnAll_Callback(handles.listSolnAll, [], handles)
end

% disables the up/down buttons
setObjEnable(hObject,'off')
setObjEnable(handles.menuSave,'off')
clearAllPanels(handles)

% updates the data struct into the GUI
setappdata(handles.figMultCombInfo,'iSolnAll',iSolnAll);
setappdata(handles.figMultCombInfo,'iSolnAdd',iSolnAdd);

% sets the solution file names
updateSolnInfo(handles)
updateSolnPlot(handles)

% makes the GUI visible again
setObjVisibility(handles.figMultCombInfo,'on'); 

% --- Executes on button press in buttonMoveUp.
function buttonMoveUp_Callback(hObject, eventdata, handles)

% resets the data structs and GUI object properties
iSolnAdd = getappdata(handles.figMultCombInfo,'iSolnAdd');
indNw = get(handles.listSolnAdded,'Value');

% sets the new index array
ii = (1:iSolnAdd.nCount)';
[ii(indNw),ii(indNw-1)] = deal(indNw-1,indNw);

% updates the arrays
iSolnAdd.fDir = iSolnAdd.fDir(ii);
iSolnAdd.fName = iSolnAdd.fName(ii);
iSolnAdd.iExpt = iSolnAdd.iExpt(ii);
iSolnAdd.T = iSolnAdd.T(ii);
iSolnAdd.nApp = iSolnAdd.nApp(ii);
iSolnAdd.appName = iSolnAdd.appName(ii);
iSolnAdd.indOut = iSolnAdd.indOut(ii);
iSolnAdd.Order = iSolnAdd.Order(ii);
setappdata(handles.figMultCombInfo,'iSolnAdd',iSolnAdd);

% updates the listbox selection and up/down button properties
set(handles.listSolnAdded,'value',indNw-1)
setMoveButtonProp(handles,indNw-1)

% sets the solution file names
updateAddLists(handles)
updateSolnInfo(handles)
updateSolnPlot(handles)
resetPatchAlpha(handles.axesSoln,indNw-1)

% --- Executes on button press in buttonMoveDown.
function buttonMoveDown_Callback(hObject, eventdata, handles)

% resets the data structs and GUI object properties
iSolnAdd = getappdata(handles.figMultCombInfo,'iSolnAdd');
indNw = get(handles.listSolnAdded,'Value');

% sets the new index array
ii = (1:iSolnAdd.nCount)';
[ii(indNw),ii(indNw+1)] = deal(indNw+1,indNw);

% updates the arrays
iSolnAdd.fDir = iSolnAdd.fDir(ii);
iSolnAdd.fName = iSolnAdd.fName(ii);
iSolnAdd.iExpt = iSolnAdd.iExpt(ii);
iSolnAdd.T = iSolnAdd.T(ii);
iSolnAdd.nApp = iSolnAdd.nApp(ii);
iSolnAdd.appName = iSolnAdd.appName(ii);
iSolnAdd.indOut = iSolnAdd.indOut(ii);
iSolnAdd.Order = iSolnAdd.Order(ii);
setappdata(handles.figMultCombInfo,'iSolnAdd',iSolnAdd);

% updates the listbox selection and up/down button properties
set(handles.listSolnAdded,'value',indNw+1)
setMoveButtonProp(handles,indNw+1)

% sets the solution file names
updateAddLists(handles)
updateSolnInfo(handles)
updateSolnPlot(handles)
resetPatchAlpha(handles.axesSoln,indNw+1)

% ------------------------------------- %
% --- APPARATUS NAME LINKING TABLES --- %
% ------------------------------------- %

% --- Executes when entered data in editable cell(s) in tableAppName.
function tableAppName_CellEditCallback(hObject, eventdata, handles)

% global variables
global nAppMx

% retrieves the output apparatus string
Data = get(hObject,'Data');
appOut = getappdata(handles.figMultCombInfo,'appOut');
indNw = min(sum(~cellfun(@isempty,appOut))+1,eventdata.Indices(1));

% updates the output parameters
nwStr = eventdata.EditData;
if (isempty(nwStr))
    % removes the apparatus string
    A = appOut((1:length(appOut)) ~= indNw);
    appOut(:) = {''}; appOut(1:length(A)) = A;
    decrementLinkIndices(handles,indNw)
    updateLinkTable(handles,get(handles.listSolnAdded,'Value'))    
else
    % checks to see if the new apparatus name is valid
    [eStr,tStr] = deal([]);
    if (any(cellfun(@(x)(strcmp(x,nwStr)),appOut(1:indNw))))
        % duplicates names within table
        eStr = 'Error! Duplicate names in list. Removing duplicate...';        
        tStr = 'Duplicate Name Input';
    elseif (strContains(nwStr,','))
        % new string contains a comma
        eStr = 'Region names strings can''t contain a comma';
        tStr = 'Region Naming Error';
    end

    % determines if there was an error
    if (~isempty(eStr))
        % outputs tht error
        waitfor(errordlg(eStr,tStr,'modal'))

        % resets the string to the previous and exits        
        Data{eventdata.Indices(1),1} = appOut{indNw};
        set(hObject,'Data',Data);
        return        
    else
        % updates the apparatus string
        appOut{indNw} = nwStr;
        if (indNw >= nAppMx)
            appOut = [appOut(:);{''}];            
        end        
    end
end

% determines if any of the output apparatus names have been set
if all(cellfun(@isempty,appOut))
    % if not, then disable the clear button
    setObjEnable(handles.buttonClearApp,'off')
else
    % otherwise, enable the clear button
    setObjEnable(handles.buttonClearApp,'on')
end

% removes any empty cells above nAppMx rows
ind = find(cellfun(@isempty,appOut),1,'first');
appOut = appOut(1:max(ind,nAppMx));

% updates the table data
setappdata(handles.figMultCombInfo,'appOut',appOut);
set(hObject,'Data',appOut)

% if the listbox is selected, then update the link table data
indSel = get(handles.listSolnAdded,'value');
if ~isempty(indSel)
    updateLinkTable(handles,indSel)
    setAddList(handles)
end

% --- Executes when entered data in editable cell(s) in tableAppLink.
function tableAppLink_CellEditCallback(hObject, eventdata, handles)

% retrieves the output apparatus string
iSolnAdd = getappdata(handles.figMultCombInfo,'iSolnAdd');
appOut = getappdata(handles.figMultCombInfo,'appOut');
indSoln = get(handles.listSolnAdded,'value');

% determines if the update is required
isUpdate = ~isa(eventdata,'char') && ...
            isa(eventdata,'matlab.ui.eventdata.CellEditData');

% retrieves the selected apparatus/solution indices
if isUpdate
    % determines the selected index
    indApp = eventdata.Indices(1);
    indNw = find(cellfun(@(x)(strcmp(x,eventdata.EditData)),appOut));
    if isempty(indNw)
        % no selection, so set as 0
        iSolnAdd.indOut{indSoln}(indApp) = 0;
    else
        % otherwise, update the index
        iSolnAdd.indOut{indSoln}(indApp) = indNw;
    end
end

% sets the sychronise indices button enabled properties
if ~isempty(indSoln)
    if all(iSolnAdd.indOut{indSoln} == 0)
        % no cross-link indices set, so disable button
        setObjEnable(handles.buttonSyncInd,'off')
    else
        % some cross-link indices have been set, so enable button
        anyXLink = any(find(iSolnAdd.indOut{indSoln}) > ...
                                min(cellfun(@length,iSolnAdd.indOut)));
        setObjEnable(handles.buttonSyncInd,anyXLink)
    end
end

% updates the solution struct
setappdata(handles.figMultCombInfo,'iSolnAdd',iSolnAdd)
setAddList(handles,iSolnAdd)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% ---------------------------------------------- %
% --- OBJECT INITIALISATION/UPDATE FUNCTIONS --- %
% ---------------------------------------------- %

% --- initialises the movement buttons --- %
function initMoveButtons(handles)

% global variables
global mainProgDir

% sets the button c-data values
cdFile = fullfile(mainProgDir,'Para Files','ButtonCData.mat');
if (~exist(cdFile,'file'))
    return
end

% sets the button colour data and updates the up/down buttons
[A,nDS] = deal(load(cdFile),3);
[Iup,Idown] = deal(A.cDataStr.Iup,A.cDataStr.Idown);
set(handles.buttonMoveUp,'Cdata',uint8(dsimage(Iup,nDS)));
set(handles.buttonMoveDown,'Cdata',uint8(dsimage(Idown,nDS)));

% --- resets the solution panel object properties --- %
function resetSolnProps(handles,iSolnAll,isShow)

% sets the GUI visibility flag
if (nargin == 2); isShow = true; end

% updates the panel properties and listbox values
setObjVisibility(handles.figMultCombInfo,'off')
setObjEnable(handles.listSolnAll,'on')
setObjEnable(handles.listSolnAdded,'on')

% initialises the solution file panel objects
setPanelProps(handles.panelSolnInfo,'on')
setObjEnable(handles.buttonSolnRemove,'off')
setObjEnable(handles.buttonSolnReset,'off')
setObjEnable(handles.buttonMoveUp,'off')
setObjEnable(handles.buttonMoveDown,'off')

% show the main GUI (if flag is set)
if isShow
    setObjVisibility(handles.figMultCombInfo,'on'); 
    pause(0.05);
end

% updates the information fields
set(handles.listSolnAll,'string',iSolnAll.fName,'value',1);

% --- updates the added experimental file listbox and table --- %
function updateAddLists(handles,varargin)

% determines the number of files that have been set
iSolnAdd = getappdata(handles.figMultCombInfo,'iSolnAdd');
nExp = iSolnAdd.nCount;

% updates the added experiment listbox
if nExp == 0
    % sets the listbox title/object properties
    set(handles.listSolnAdded,'String','','max',2,'Value',[],...
                              'enable','off')
else
    % sets the listbox title/object properties
    setAddList(handles,iSolnAdd)
end

% sets the up/down movement button properties
setMoveButtonProp(handles,get(handles.listSolnAdded,'value'))

% --- sets the up/down movement button properties --- %
function setMoveButtonProp(handles,indNw)

% retrieves the added solution data struct
iSolnAdd = getappdata(handles.figMultCombInfo,'iSolnAdd');

% only set the button enable properties if there is at least two items in
% the table and a valid selection has been made
if nargin == 1
    setObjEnable(handles.buttonMoveUp,'off');
    setObjEnable(handles.buttonMoveDown,'off');
    
elseif (iSolnAdd.nCount > 1) && ~isempty(indNw)
    if indNw(1) == 1
        % case is the first entry
        setObjEnable(handles.buttonMoveUp,'off');
        setObjEnable(handles.buttonMoveDown,'on');
        
    elseif indNw(1) == iSolnAdd.nCount
        % case is the last entry
        setObjEnable(handles.buttonMoveUp,'on');
        setObjEnable(handles.buttonMoveDown,'off');
        
    else
        % case is the other table entries
        setObjEnable(handles.buttonMoveUp,'on');
        setObjEnable(handles.buttonMoveDown,'on');
    end
    
else
    % disables the buttons
    setObjEnable(handles.buttonMoveUp,'off');
    setObjEnable(handles.buttonMoveDown,'off');
end

% --- updates the solution file duration string --- %
function updateDurString(handles)

% retrieves the parameter struct
iPara = getappdata(handles.figMultCombInfo,'iPara');

% updates the experiment durations
[~,~,tStr] = calcTimeDifference(60*(iPara.indF-iPara.indS));
% textDur = sprintf('%s D, %s H, %s M',tStr{1},tStr{2},tStr{3});
textDur = sprintf('%s:%s:%s',tStr{1},tStr{2},tStr{3});
set(handles.textSolnDur,'string',textDur)

% --- clears all the data from the panels --- %
function clearAllPanels(handles)

% makes the GUI invisible
setObjVisibility(handles.figMultCombInfo,'off'); 
pause(0.05);

% disable the start/finish time panels
setPanelProps(handles.panelStartTime,'off')
setPanelProps(handles.panelFinishTime,'off')
setPanelProps(handles.panelSolnDetails,'off')
setPanelProps(handles.panelAppName,'off')

% clears the strings of the
set(findobj(handles.panelStartTime,'style','popupmenu'),'string',' ','value',1)
set(findobj(handles.panelFinishTime,'style','popupmenu'),'string',' ','value',1)
set(findobj(handles.panelSolnDetails,'style','text','UserData',1),'string',' ')
        
% resets the outer panel position
pPos = get(handles.panelSolnOuter,'position');
set(handles.panelSolnOuter,'position',[pPos(1:2) 620 pPos(4)])

% resets the figure position
fPos = get(handles.figMultCombInfo,'position');
set(handles.figMultCombInfo,'position',[fPos(1:2) 640 fPos(4)])    

% resets the parameter struct
setappdata(handles.figMultCombInfo,'iPara',initParaStruct);

% --- reshapes the output apparatus name table data --- %
function reshapeAppNameTable(handles)

% global variables
global nAppMx

% loads the added solution file data struct
appOut = getappdata(handles.figMultCombInfo,'appOut');

% ensures the output apparatus name table is of the correct size
Data = get(handles.tableAppName,'Data');
if (length(Data) ~= nAppMx)
    % appends/resets the apparatus data labels
    if (length(Data) < nAppMx)
        % appends to the array
        A = repmat({''},nAppMx-length(Data),1);
        [DataNw,appOut] = deal([Data;A],[appOut;A]);                    
        
        % updates the table data
        setappdata(handles.figMultCombInfo,'appOut',appOut);
        set(handles.tableAppName,'Data',DataNw,'ColumnFormat',{'char'});
    end    
end

% --- sets the added solution file list box properties --- %
function setAddList(handles,iSolnAdd)

% global variables
global greyCol

% if only one input argument, then retrieve the added solution data
if (nargin == 1)
    iSolnAdd = getappdata(handles.figMultCombInfo,'iSolnAdd');
end

% sets the important variables
[nCount,col] = deal(iSolnAdd.nCount,'rk');
appOut = getappdata(handles.figMultCombInfo,'appOut');
fName = iSolnAdd.fName;

% sets the list colours and determines which solution files have been setup
% correctly
appSet = ~cellfun(@isempty,appOut);
if (~any(appSet))
    % if there are no apparatus names set, then set the colours to invalid
    [isSet,lCol] = deal(false(nCount,1),repmat({'gr'},nCount,1));
else
    % determines the which apparatus have been set correctly and from this
    % sets the list string colours
    isSet = allNameSet(handles);
    lCol = arrayfun(@(x)(col(x+1)),isSet,'un',0);
end

% sets the HTML colour string for the listbox
lStr = setHTMLColourString(lCol,fName);            

% adds the colours to the strings for each row
for i = 1:length(lStr)    
    % creates the new plot fill
    hFill = findobj(handles.axesSoln,'UserData',i,'tag','hFill');
    if (isSet(i))
        % if correct, then set the colour based on apparatus count
        iApp = unique(iSolnAdd.indOut{i}(iSolnAdd.indOut{i}>0));
        fCol = colSetTabColour(length(iApp));
    else
        % otherwise, set the colour to grey
        fCol = greyCol;
    end
    
    % sets the fill face colour
    set(hFill,'FaceColor',fCol)
end

% updates the list object
set(setObjEnable(handles.listSolnAdded,'on'),'String',lStr)
setObjEnable(handles.menuSave,all(isSet))

% updates the correct setup string
if isSet(get(handles.listSolnAdded,'Value'))
    % solution file not setup correctly
    set(handles.textSetupCorrect,'string','Yes','ForegroundColor','k');
    
else
    % solution file not setup correctly
    if strcmp(get(handles.textSetupCorrect,'enable'),'off')
        set(handles.textSetupCorrect,'string',' ');
    elseif (~any(appSet))
        set(handles.textSetupCorrect,'string','N/A','ForegroundColor','r');
    else
        set(handles.textSetupCorrect,'string','No','ForegroundColor','r');
    end
end

% --- updates the link table data for the solution file index, ind --- %
function updateLinkTable(handles,ind)

% otherwise, update the table
if isempty(ind)
    % no selection, so disable the table
    set(setObjEnable(handles.tableAppLink,'off'),'Data',[])
    setObjEnable(handles.textAppLink,'off')  
    setObjEnable(handles.buttonSyncInd,'off') 
    
else
    % otherwise, add all the required data elements to the table
    iSolnAdd = getappdata(handles.figMultCombInfo,'iSolnAdd');
    appOut = getappdata(handles.figMultCombInfo,'appOut');
    [appName,indOut] = deal(iSolnAdd.appName{ind},iSolnAdd.indOut{ind});
    
    % sets the cross-link field data
    fldName = [{' '};appOut(~cellfun(@isempty,appOut))]';
    fldData = arrayfun(@(x)(fldName{x+1}),indOut,'un',0);
    
    % updates the table
    setObjEnable(handles.textAppLink,'on')
    set(handles.tableAppLink,'ColumnFormat',{{'char'},fldName},...
                'Data',[appName fldData],'visible','on','enable','on')
    
    tableAppLink_CellEditCallback([], '1', handles)
    
    % loads the output apparatus string array
    appOut = getappdata(handles.figMultCombInfo,'appOut');
    if all(cellfun(@isempty,appOut))
        setObjEnable(handles.tableAppLink,'off')
    end
end

% --- updates the table dimensions
function updateTableDim(handles)

% global variables
global nAppMx

% initialisations
HT = calcTableHeight(nAppMx);
hTab = {handles.tableAppName,handles.tableAppLink};

% resizes the table and reset the resize flags
for i = 1:length(hTab)
    % resets the resize table flags
    autoResizeTableColumns(hTab{i});

    % resizes the table positions
    tPos = get(hTab{i},'position');
    set(hTab{i},'position',[tPos(1:3),HT])
end

% ----------------------------------------- %
% --- START/FINISH POPUP MENU FUNCTIONS --- %
% ----------------------------------------- %

% --- initialises the popup menu objects
function initPopupObjects(hPanel,Type)

% retrieves the object handles
hPopup = findobj(hPanel,'style','popupmenu');

% sets the callback function
for i = 1:length(hPopup)
    % sets the callback function
    hObj = hPopup(i);
    bFunc = @(hObj,e)MultFlyCombInfo('popupTimeVal',hObj,Type,guidata(hObj));
    set(hObj,'Callback',bFunc)
end

% --- resets the time popup box values --- %
function popupTimeVal(hObject,Type,handles)

% retrieves the parameter struct
iPara = getappdata(handles.figMultCombInfo,'iPara');
hParent = get(hObject,'parent');

% retrieves the time indices
iDay = get(findobj(hParent,'style','popupmenu','UserData',1),'value') - 1;
iHour = get(findobj(hParent,'style','popupmenu','UserData',2),'value') - 1;
iMin = get(findobj(hParent,'style','popupmenu','UserData',3),'value') - 1;
iTot = (60*(24*iDay + iHour) + iMin) + 1;

%
hAx = handles.axesSoln;
nDay = roundP(max(get(hAx,'xlim'))/(60*24),1);
xMax = convertTime(nDay,'days','mins');

% calculates the total index value
switch (Type)
    case ('hMin') % case is the lower limit is being moved
        if (iTot >= iPara.indF)
            % outputs an error string
            eStr = 'Error! Lower limit exceeds the upper limit!';
            waitfor(errordlg(eStr,'Lower Limit Error','modal'))
            
            % resets the popup menu values
            updateTimePopupBoxes(handles.panelStartTime,iPara.indS,nDay,1)
        else
            % resets the start index
            iPara.indS = iTot;
            resetLimitMarker(hAx,iPara.indS*[1 1],'hMin')
            resetLimitMarkerRegion(hAx,[iPara.indS xMax],'hMax')
        end
    case ('hMax') % case is the upper limit is being moved
        if (iTot <= iPara.indS)
            % outputs an error string
            eStr = 'Error! Upper limit is less than the lower limit!';
            waitfor(errordlg(eStr,'Upper Limit Error','modal'))                        
            
            % resets the popup menu values
            updateTimePopupBoxes(handles.panelFinishTime,iPara.indF,nDay,1)
        else
            % resets the start index
            iPara.indF = iTot;
            resetLimitMarker(hAx,iPara.indF*[1 1],'hMax')
            resetLimitMarkerRegion(hAx,[1 iPara.indF],'hMin')
        end
end

% updates the parameter struct
setappdata(handles.figMultCombInfo,'iPara',iPara)

% ---------------------------------------- %
% --- SOLUTION OUTPUT FIGURE FUNCTIONS --- %
% ---------------------------------------- %

% --- updates the combined experimental info fields
function updateSolnInfo(handles)

% global variables
global mainProgDir
a = load(fullfile(mainProgDir,'Para Files','ProgPara.mat'));

% parameters
tDay = a.gPara.Tgrp0;

% resets the data structs and GUI object properties
iSolnAdd = getappdata(handles.figMultCombInfo,'iSolnAdd');
if (iSolnAdd.nCount == 0)
    [T0nw,Tfnw] = deal([]);
else
    % sets the experiment start times and durations
    iExpt = iSolnAdd.iExpt; 
    T0 = cell2mat(cellfun(@(x)(x(1).Timing.T0),iExpt,'un',0));
    Texp = cellfun(@(x)(x{end}(end)),iSolnAdd.T);
    
    % calculates the new start time values (shifted to 8am of that day)
    [T0nw,ii] = deal(zeros(iSolnAdd.nCount,4),T0(:,4) >= tDay);
    a = ones(sum(ii),1);
    T0nw(ii,1:3) = T0(ii,3:end-1) - [T0(ii,3) tDay*a 0*a];
    T0nw(~ii,2) = (24-(tDay-T0(~ii,4))); T0nw(~ii,3) = T0(~ii,5);
    
    % calculates the duration of the experiments (relative to the start time)
    TfnwS = Texp + vec2sec(T0nw) + 60;
    Tfnw = sec2vec(TfnwS); Tfnw(:,end) = 0;
end

% updates the initial/final experiment times
setappdata(handles.figMultCombInfo,'T0nw',T0nw)
setappdata(handles.figMultCombInfo,'Tfnw',Tfnw)

% --- updates the solution plots
function updateSolnPlot(handles)

% global variables
global fColLo xLimTot yLimTot greyCol

% sets the font size (based on the OS type)
if ismac
    fSize = 11;
else
    fSize = 9;
end

% parameters and object handles
[xFill,yFill] = deal([0 0.5 0.5 0.0],[0 0 1 1]);
[xDN,yDN,xSoln,YDN] = deal(0.001,0.001,1,30);
[Ydel,HBase,HaxDN,H0,a] = deal(10,280,25,10,0.025*[-1 1]);
[hAxDN,hAxSoln] = deal(handles.axesDN,handles.axesSoln);

% retrieves the added solution data struct
iSolnAdd = getappdata(handles.figMultCombInfo,'iSolnAdd');
iPara = getappdata(handles.figMultCombInfo,'iPara');

% retrieves the figure positional vector
figPos = get(handles.figMultCombInfo,'Position');

% clears the two axes and makes the GUI invisible
% setObjVisibility(handles.figMultCombInfo,'off'); pause(0.01)
cla(hAxSoln)
cla(hAxDN)

% resets the figure position/dimensions based on the solution count
if iSolnAdd.nCount == 0
    % case is there are no files so collapse the figure to original
    pPos1 = get(handles.panelSolnOuter,'Position');
    pPos2 = get(handles.panelImgAxis,'Position');
    
    % removes the min/max markers
    delete(findobj(hAxSoln,'tag','hMax'))
    delete(findobj(hAxSoln,'tag','hMin'))
    
    % updates the figure/panel positions
    Bfig = figPos(2) + (figPos(4) - HBase);
    set(handles.figMultCombInfo,'Position',[figPos(1) Bfig figPos(3) HBase])
    set(handles.panelSolnOuter,'Position',[pPos1(1) 10 pPos1(3:4)])
    set(handles.panelImgAxis,'Position',[pPos2(1) -pPos2(4) pPos2(3:4)])    
else
    % retrieves the panel/axis position vectors
    pPos1 = get(handles.panelSolnOuter,'Position');
    pPos2 = get(handles.panelImgAxis,'Position');
    axPosS = get(hAxSoln,'Position');
    
    % calculates the change in the parameter sizes
    dSz = max(0,floor((iSolnAdd.nCount-H0)/10));
    [HSoln,fSize] = deal(max(2,8 - dSz),max(6,fSize - dSz));
    
    % height/bottom calculations
    HaxSoln = iSolnAdd.nCount*HSoln;
    Hp2 = YDN + 2.5*Ydel + (HaxDN + iSolnAdd.nCount*HSoln);
    Bp1 = Hp2 + 2*Ydel;
    Hfig = (HBase + Ydel) + Hp2;
    Bfig0 = figPos(2); Bfig = max(Bfig0 + (figPos(4) - Hfig),50);
    
    % resets the GUI object position vectors
    set(handles.figMultCombInfo,'Position',[figPos(1) Bfig figPos(3) Hfig])
    set(handles.panelSolnOuter,'Position',[pPos1(1) Bp1 pPos1(3:4)])
    set(handles.panelImgAxis,'Position',[pPos2(1) Ydel pPos2(3) Hp2])
    set(hAxSoln,'Position',[axPosS(1:3) HaxSoln])
    
    % ----------------------------- %
    % --- DAY/NIGHT MARKER PLOT --- %
    % ----------------------------- %
    
    % retrieves the experiment start/stop time vectors
    T0nw = getappdata(handles.figMultCombInfo,'T0nw');
    Tfnw = getappdata(handles.figMultCombInfo,'Tfnw');
    
    % determines the maximum number of days the experiments have run
    TfnwS = vec2sec(Tfnw);
    [~,imx] = max(TfnwS);
    nDay = ceil(ceil(convertTime(TfnwS(imx),'sec','days')));
    xtickLbl = arrayfun(@(x)(sprintf('Day %i',x-1)),1:nDay,'un',0);
    
    % sets the axis properties
    axis(hAxDN,'on'); hold(hAxDN,'on')
    
    % adds in the day/night fill markers
    for i = 1:nDay
        fill((i-1.0)+xFill,yFill,'y','FaceAlpha',fColLo,'Parent',hAxDN);
        fill((i-0.5)+xFill,yFill,'k','FaceAlpha',fColLo,'Parent',hAxDN);
    end
    
    % plots the outside line markers
    plot(hAxDN,[0 0],get(hAxDN,'ylim'),'k')
    plot(hAxDN,max(get(hAxDN,'xlim'))*[1 1],get(hAxDN,'ylim'),'k')
    plot(hAxDN,get(hAxDN,'xlim'),[0 0],'k')
    
    % sets the ticklabels and limits
    set(hAxDN,'xlim',[0 nDay]+xDN*[-1 1],'ylim',[0 1]+yDN*[-1 1],...
        'xtick',(1:nDay)-0.5,'xticklabel',xtickLbl,...
        'yticklabel',[],'ytick',[],'ticklength',[0 0],...
        'fontweight','bold','fontsize',fSize)
    
    % removes the hold from the axis
    hold(hAxDN,'off')
    
    % --------------------------------- %
    % --- SOLUTION FILE MARKER PLOT --- %
    % --------------------------------- %
    
    % determines the start/finish indices of each experiments
    ind0 = floor(convertTime(vec2sec(T0nw),'seconds','minutes'));
    indF = ceil(convertTime(vec2sec(Tfnw),'seconds','minutes'));
    
    % clears the and set the new x/y limits   
    set(hAxSoln,'xlim',xSoln*[-1 1]+[0 nDay*convertTime(1,'day','mins')],...
        'ylim',0.5 + a + [0 iSolnAdd.nCount],'xtick',[],...
        'ytick',[],'yticklabel',[],'xticklabel',[],'ticklength',[0 0],...
        'fontweight','bold','fontsize',fSize)
    axis(hAxSoln,'ij');
    
    % adds the horiztonal markers and fill objects
    hold(hAxSoln,'on')
    for i = 1:(length(ind0)+1)
        % only add the fill objects for a valid row
        if (i <= length(ind0))
            %
            xFillS = [ind0(i) indF(i)*[1 1] ind0(i)];
            yFillS = yFill + (i - 0.5);
            
            % sets the fill colour based on whether it is valid
            if (allNameSet(handles,i))
                % otherwise, set grey as the colour
                % if correct, then set the colour based on apparatus count
                iApp = unique(iSolnAdd.indOut{i}(iSolnAdd.indOut{i}>0));
                fCol = colSetTabColour(length(iApp));      
            else
                fCol = greyCol;
            end
            
            % sets the solution file fill colour
            fill(xFillS,yFillS,fCol,'linestyle','none','Parent',hAxSoln,...
                        'FaceAlpha',fColLo,'UserData',i,'tag','hFill');
        end
        
        % plots the horizontal markers
        plot(hAxSoln,get(hAxSoln,'xlim'),(i-0.5)*[1 1],'k');
    end
    
    % plots the vertical markers for the day/night markers
    yLim = get(hAxSoln,'ylim');
    for i = 1:nDay
        plot(hAxSoln,convertTime(((i-1)+0.5)*[1 1],'day','mins'),yLim,'k--')
        plot(hAxSoln,convertTime(i*[1 1],'day','mins'),yLim,'k')
    end
    
    % plots the start/end line markers
    plot(hAxSoln,xSoln*[1 1],yLim,'k')
    plot(hAxSoln,max(get(hAxSoln,'xlim'))-xSoln*[1 1],yLim,'k')
    
    % removes the hold from the axis
    hold(hAxSoln,'off')
    
    % --------------------------------- %
    % --- FILE START/FINISH MARKERS --- %
    % --------------------------------- %
            
    % resets the limit markers
    xLimTot = [(min(vec2sec(T0nw))/60) (max(vec2sec(Tfnw))/60)] + 1;
    yLimTot = get(hAxSoln,'yLim');
    
    % updates the start/finish indices
    [iPara.indS,iPara.indF] = deal(xLimTot(1),xLimTot(2));
    
    % updates the lower/upper indices (if the limits have changed)
    if (iPara.indF > xLimTot(2)); iPara.indF = xLimTot(2); end
    if (iPara.indS < xLimTot(1)); iPara.indS = xLimTot(1); end        
    setappdata(handles.figMultCombInfo,'iPara',iPara);    
        
    % initialises the popup boxes
    initLimitMarkers(handles,iPara)
    updateDurString(handles)
    updateTimePopupBoxes(handles.panelStartTime,iPara.indS,nDay)
    updateTimePopupBoxes(handles.panelFinishTime,iPara.indF,nDay)
end

% --- updates the popup box values
function updateTimePopupBoxes(hPanel,iX,nDay,varargin)

% sets the day/hours/minute strings and values
tVec = sec2vec(convertTime(iX-1,'mins','secs'))+1;
pStr{1} = num2cell((0:(nDay))');
pStr{2} = num2cell((0:23)');
pStr{3} = num2cell((0:59)');

% sets the popup strings/values
for i = 1:length(pStr)
    % retrieves the popup object handle
    hPopNw = findobj(hPanel,'UserData',i,'Style','popupmenu');
    if (nargin == 3)
        set(hPopNw,'String',pStr{i},'value',tVec(i))
    else
        set(hPopNw,'value',tVec(i))
    end
end

% -------------------------------------------- %
% --- SOLUTION FILE LIMIT MARKER FUNCTIONS --- %
% -------------------------------------------- %

% --- creates the line objects that will server as the limit markers -- %
function initLimitMarkers(handles,iPara)

% global variables
global yLimTot

% sets the axis limits
hAx = handles.axesSoln;

% creates the new markers
createNewMarker(hAx,iPara.indS*[1 1],yLimTot,'hMin')
createNewMarker(hAx,iPara.indF*[1 1],yLimTot,'hMax')

% --- creates the new marker of type, Type
function createNewMarker(hAx,xPos,yPos,Type)

% global variables
global xLimTot yLimTot

% creates a new line object
hLineS = imline(hAx,xPos,yPos);
setColor(hLineS,'k');
set(hLineS,'tag',Type)

% sets the properties of the object lines
set(findobj(hLineS,'tag','top line'),'linewidth',2)
set(findobj(hLineS,'tag','end point 1'),'hittest','off')
set(findobj(hLineS,'tag','end point 2'),'hittest','off')
setObjVisibility(findobj(hLineS,'tag','bottom line'),'off')

% sets the constraint/position callback functions
fcn = makeConstrainToRectFcn('imline',xLimTot,yLimTot);
setPositionConstraintFcn(hLineS,fcn);
hLineS.addNewPositionCallback(@(p)moveLimitMarker(p,guidata(hAx),Type));

% --- start/finish limit marker callback function --- %
function moveLimitMarker(pNew,handles,Type)

% global variables
global xLimTot

% initialisations
iPara = getappdata(handles.figMultCombInfo,'iPara');
[hAx,xNew] = deal(handles.axesSoln,roundP(pNew(1,1),1));
nDay = roundP(max(get(hAx,'xlim'))/(60*24),1);

%
T0nw = getappdata(handles.figMultCombInfo,'T0nw'); 
Tfnw = getappdata(handles.figMultCombInfo,'Tfnw');

% updates the
switch (Type)
    case ('hMin')
        % if the start marker exceeds the finish, then reset
        if (xNew >= iPara.indF)
            % sets the time vector to be below that of the finish
            xNew = iPara.indF - 1;
            resetLimitMarker(hAx,xNew*[1 1],'hMin')
        end
        
        % determines the
        iPara.indS = xNew;
        setappdata(handles.figMultCombInfo,'iPara',iPara)
        
        % resets the popup-values
        resetLimitMarkerRegion(hAx,[iPara.indS xLimTot(2)],'hMax')
        updateTimePopupBoxes(handles.panelStartTime,iPara.indS,nDay,1)
    case ('hMax')
        % if the start marker exceeds the finish, then reset
        if (xNew <= iPara.indS)
            % sets the time vector to be below that of the finish
            xNew = iPara.indS + 1;
            resetLimitMarker(hAx,xNew*[1 1],'hMax')
        end
        
        % determines the
        iPara.indF = xNew;
        setappdata(handles.figMultCombInfo,'iPara',iPara)
        
        % resets the popup-values
        resetLimitMarkerRegion(hAx,[xLimTot(1) iPara.indF],'hMin')
        updateTimePopupBoxes(handles.panelFinishTime,iPara.indF,nDay,1)
end

% updates the solution file duration string
updateDurString(handles)

% --- resets the limit marers
function resetLimitMarker(hAx,xNew,Type)

% global variables
global yLimTot

api = iptgetapi(findobj(hAx,'tag',Type));
api.setPosition([xNew',yLimTot']);

% --- resets the limit marker regions
function resetLimitMarkerRegion(hAx,xLimNew,Type)

% global variables
global yLimTot

% sets the constraint/position callback functions
fcn = makeConstrainToRectFcn('imline',xLimNew,yLimTot);
api = iptgetapi(findobj(hAx,'tag',Type));
api.setPositionConstraintFcn(fcn);

% --------------------------------------- %
% --- STRUCT INITIALISATION FUNCTIONS --- %
% --------------------------------------- %

% --- initialises the parameter struct
function iPara = initParaStruct()

% initialises the parameter struct
iPara = struct('indS',[],'indF',[]);

% --- initialises the program data struct
function [iSolnAll,iSolnAdd] = initDataStruct(handles,varargin)

% initialises the GUI objects (if only one input argument)
if (nargin == 1)
    % disables all the solution information panels
    setPanelProps(handles.panelSolnInfo,'off')
    clearAllPanels(handles)
    
    % removes the selections from the listboxes
    set(handles.listSolnAll,'max',2,'value',[],'string',[]);
end

% clears the data from the tables
set(handles.tableAppName,'Data',[])
set(handles.tableAppLink,'Data',[])

% initialises the data structs
set(handles.listSolnAdded,'max',2,'value',[],'string',[]);
[iSolnAll,iSolnAdd] = deal(struct('nCount',0,'fDir',[],'fName',[],...
    'iExpt',[],'T',[],'nApp',[],'appName',[],'isMulti',[]));
[iSolnAll.isAdded,iSolnAdd.Order,iSolnAdd.indOut] = deal([]);
setappdata(handles.figMultCombInfo,'appOut',[]);

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% --- decrements all link indices greater then indNw --- %
function decrementLinkIndices(handles,indNw)

% retrieves the data struct
iSolnAdd = getappdata(handles.figMultCombInfo,'iSolnAdd');

% for all indices greater than the index being removed (indNw), then
% decrement the link-indices by 1
for i = 1:length(iSolnAdd.indOut)
    indDec = iSolnAdd.indOut{i} > indNw;
    
    iSolnAdd.indOut{i}(iSolnAdd.indOut{i} == indNw) = 0;
    iSolnAdd.indOut{i}(indDec) = iSolnAdd.indOut{i}(indDec) - 1;
end

% updates the data struct
setappdata(handles.figMultCombInfo,'iSolnAdd',iSolnAdd);

% --- determines 
function isSet = allNameSet(handles,ind)

% retrieves the data struct
appSet = ~cellfun(@isempty,getappdata(handles.figMultCombInfo,'appOut'));

% sets the output indices
if (~any(appSet))
    % if none of the apparatus names are set, then return a false value
    isSet = false;
else
    % sets the search indices
    iSolnAdd = getappdata(handles.figMultCombInfo,'iSolnAdd');
    if (nargin == 1)
        ind = (1:iSolnAdd.nCount);
    end
    
    %  loops through all the indices (if there is more than one)
    if (length(ind) > 1)
        % loops through each of the indices determining if the apparatus
        % names have been set correctly
        isSet = false(iSolnAdd.nCount,1);
        for i = 1:length(isSet)
            isSet(i) = allNameSet(handles,i);
        end
        
        % exits the function
        return
    else
        % otherwise, determine if all the indices have been set
        indS = 1:sum(appSet);
        isSet = any(arrayfun(@(x)(any(x == iSolnAdd.indOut{ind})),indS));
    end
end
