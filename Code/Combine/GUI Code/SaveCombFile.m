function varargout = SaveCombFile(varargin)
% Last Modified by GUIDE v2.5 03-Jun-2021 16:23:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @SaveCombFile_OpeningFcn, ...
    'gui_OutputFcn',  @SaveCombFile_OutputFcn, ...
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

% --- Executes just before SaveCombFile is made visible.
function SaveCombFile_OpeningFcn(hObject, eventdata, handles, varargin)

% sets the input arguments
hMain = varargin{1};
hFigM = hMain.figFlyCombine;
sInfo = getappdata(hFigM,'sInfo');
hGUIInfo = getappdata(hFigM,'hGUIInfo');

% makes the information GUI invisible
setObjVisibility(hGUIInfo.hFig,'off')

% sets the data structs into the GUI
setappdata(hObject,'fExtn','.ssol')
setappdata(hObject,'fDir',getappdata(hFigM,'fDir'))
setappdata(hObject,'fName',getappdata(hFigM,'fName'))
setappdata(hObject,'iProg',getappdata(hFigM,'iProg'))

% updates the other fields in the gui
% setappdata(hObject,'iPara',iPara)
setappdata(hObject,'hGUIInfo',hGUIInfo)

% reshapes the solution file
for i = 1:length(sInfo)
    sInfo{i}.snTot = reshapeSolnStruct(sInfo{i}.snTot,sInfo{i}.iPara);
end

% % if only recording, then disable stimuli time-stamp checkbox
% if length(snTot.iExpt) == 1
%     if strcmp(snTot.iExpt.Info.Type,'RecordOnly')
%         setObjEnable(handles.checkOutputStim,'off')
%     end
% else
%     Type = field2cell(field2cell(snTot.iExpt,'Info',1),'Type');
%     if all(strcmp(Type,'RecordOnly'))
%         setObjEnable(handles.checkOutputStim,'off')
%     end
% end
    
% initialises the file information
initFileInfo(handles)

% updates the solution time object properties
set(handles.checkSolnTime,'value',0)
% if snTot.iMov.is2D 
%     set(setObjEnable(handles.checkOutputY,'off'),'value',1); 
% end
checkSolnTime_Callback(handles.checkSolnTime, [], handles)

% updates the object properties
updateObjectProps(handles)

% % initialises the panel file type to the DART file type
% set(handles.radioDART,'value',1)
% e = struct('NewValue',handles.radioDART);
% panelFileType_SelectionChangeFcn(hObject, e, handles)
% centreFigPosition(hObject);

% Choose default command line output for SaveCombFile
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
% set(hObject,'WindowStyle','modal')

% UIWAIT makes SaveCombFile wait for user response (see UIRESUME)
% uiwait(handles.figCombSave);

% --- Outputs from this function are returned to the command line.
function varargout = SaveCombFile_OutputFcn(hObject, eventdata, handles)

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% ----------------------------- %
% --- OUTPUT INFO CALLBACKS --- %
% ----------------------------- %
    
% --- Executes on button press in checkSolnTime.
function checkSolnTime_Callback(hObject, eventdata, handles)

% sets the time interval text/editbox properties
isSel = get(hObject,'value');
setObjEnable(handles.textSolnTime,isSel)
setObjEnable(handles.editSolnTime,isSel)

% --- Executes on editting editSolnTime
function editSolnTime_Callback(hObject, eventdata, handles)

% retrieves the parameters/data structs
Tmax = getappdata(handles.figCombSave,'Tmax');
iPara = getappdata(handles.figCombSave,'iPara');

% checks to see if the new value is valid
nwVal = str2double(get(hObject,'string'));
if chkEditValue(nwVal,[1 Tmax],1)
    % if so, updates the parameter field with the new value
    iPara.dT = nwVal;
    setappdata(handles.figCombSave,'iPara',iPara)
else
    % otherwise, revert to the previous valid value
    set(hObject,'string',num2str(iPara.dT))
end

% ------------------------------ %
% --- FILE CHOOSER CALLBACKS --- %
% ------------------------------ %

% --- callback function for the file chooser property change
function chooserPropChange(hObject, eventdata, handles)

% initialisations
hFig = handles.figCombSave;
iExp = getappdata(hFig,'iExp');
fExtn = getappdata(hFig,'fExtn');
objChng = eventdata.getNewValue;

switch class(objChng)
    case 'com.mathworks.mwswing.FileExtensionFilter'
        %        
        
        % case is the file extension filter change
        fExtn{iExp} = char(objChng.getSimpleFilterExtension);
        setappdata(hFig,'fExtn',fExtn)
        
        % retrieves the current file path
        jFileC = getappdata(hFig,'jFileC');
        currFile = getCurrentFilePath(hFig);
        jFileC.setSelectedFile(java.io.File(currFile));
        
        % updates the object properties
        updateObjectProps(handles)
        
    case 'sun.awt.shell.Win32ShellFolder2'
        % case is the folder change
        fDir = fileparts(char(objChng.getPath));
        [~,fName,~] = fileparts(char(objChng.getName));
        
        % updates the file name        
        setappdata(hFig,'fDir',fDir)
        setappdata(hFig,'fName',fName)
end

% --- updates when the file name is changed
function saveFileNameChng(hObject, eventdata, handles)

% enables the create button enabled properties (disable if no file name)
fName = char(get(hObject,'Text'));
setObjEnable(handles.buttonCreate,~isempty(fName))

% ---------------------------------------- %
% --- PROGRAM CONTROL BUTTON CALLBACKS --- %
% ---------------------------------------- %

% --- Executes on button press in buttonCreate.
function buttonCreate_Callback(hObject, eventdata, handles)

% % makes the GUI invisible
% setObjVisibility(handles.figCombSave,'off'); pause(0.05)

% retrieves the user's check values
Tmax = 12;
oPara = struct('useComma',get(handles.checkUseComma,'value'),...
               'outY',get(handles.checkOutputY,'value'),...
               'outExpt',get(handles.checkOutputExpt,'value'),...
               'outStim',get(handles.checkOutputStim,'value'));

% retrieves the other output parameter check values
% hRadio = findobj(handles.panelFileType,'value',1);
% fExtn = get(hRadio,'UserData');

% sets the full solution file name
hFig = handles.figCombSave;
snTot = getappdata(hFig,'snTot');
iPara = getappdata(hFig,'iPara');
jFileC = getappdata(hFig,'jFileC');

% retrieves the file directory, name and extension
fDir = char(jFileC.getCurrentDirectory);
fName = get(get(jFileC,'UI'),'FileName');
fExtn = char(jFileC.getFileFilter.getSimpleFilterExtension);

% updates the file directory/name into the gui
setappdata(hFig,'fDir',fDir)
setappdata(hFig,'fName',fName)

% removes the extension from the file name
if endsWith(fName,fExtn)
    fName = strrep(fName,fExtn,'');
end

% sets the full file name
if chkDirString(fName)
    fNameFull = fullfile(fDir,fName);
else
    return
end

% if not splitting a file (and not outputting a DART file) then determine
% if the files are too long
if ~get(handles.checkSolnTime,'value') && ~strcmp(fExtn,'.ssol')
    % sets the indices of the frames that are to be kept
    Ts = snTot.T{iPara.indS(1)}(iPara.indS(2));
    Tf = snTot.T{iPara.indF(1)}(iPara.indF(2));
    
    % if the solution file duration is excessive, then prompt the user if
    % they wish to split up the solution file
    if (Tf - Ts)/(60^2) > Tmax
        a = sprintf('Solution file duration is greater Than %i Hours',Tmax);
        b = 'Do you wish to reconsider splitting up the solution files?';
        uChoice = questdlg([{a};{b}],'Split Up Solution Files?',...
            'Yes','No','Yes');
        if strcmp(uChoice,'Yes')
            % if the user chose to exit, then leave the function
            return
        end
    end
end

% outputs the solution file (based on the users selection)
switch fExtn
    case {'.ssol','.mat'} % case is the DART Solution File
        if exist([fNameFull,fExtn],'file')
            % if the solution file already exists, then 
            qStr = ['Experimental solution file already exists. ',...
                    'Do you wish to overwrite file?'];
            uChoice = questdlg(qStr,'Overwrite File?','Yes','No','Yes');            
            if ~strcmp(uChoice,'Yes')
                return
            end
        end
        
        % outputs the DART solution file
        if strcmp(fExtn,'.ssol')
            outputDARTSoln(handles,oPara,fNameFull)
        else
            outputMATSoln(handles,oPara,fNameFull)
        end
        
    case ('.csv') % case is the Comma-Separated Value file
        outputASCIIFile(handles,oPara,true)
        
    case ('.txt') % case is the ASCII text file
        outputASCIIFile(handles,oPara,false)
end

% closes the GUI
buttonCancel_Callback(handles.buttonCancel, [], handles)

% --- Executes on button press in buttonCancel.
function buttonCancel_Callback(hObject, eventdata, handles)

% makes the information GUI invisible
hGUIInfo = getappdata(handles.figCombSave,'hGUIInfo');

% closes the GUI
delete(handles.figCombSave)
setObjVisibility(hGUIInfo.hFig,'on')

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% -------------------------------------- %
% --- SOLUTION FILE OUTPUT FUNCTIONS --- %
% -------------------------------------- %

% --- outputs the DART combined solution file --- %
function outputDARTSoln(handles,oPara,fNameFull)

% retrieves the apparatus data and solution file structs
hFig = handles.figCombSave;
iProg = getappdata(hFig,'iProg');
snTot = getappdata(hFig,'snTot');

% updates the region data struct
snTot = updateRegionInfo(snTot);
snTot = reshapeExptSolnFile(snTot);

% outputs the solution file
fFileFull = [fNameFull,'.ssol'];
saveExptSolnFile(iProg.TempFile,fFileFull,snTot,oPara);

% --- outputs a Matlab mat solution file --- %
function outputMATSoln(handles,oPara,fNameFull)

% retrieves the apparatus data and solution file struct
snTot = getappdata(handles.figCombSave,'snTot');

% converts the cell arrays to numerical arrays
snTot.T = cell2mat(snTot.T);
snTot.isDay = cell2mat(snTot.isDay');

% resets/add other important fields in the solution data struct
snTot.StimInfo = snTot.iExpt.Stim;
snTot.TimeInfo = snTot.iExpt.Timing;

% removes any extraneous fields
if ~snTot.iMov.is2D; snTot = rmfield(snTot,'Py'); end
snTot = rmfield(snTot,{'pMapPx','pMapPy','iExpt'});

% saves the file
h = ProgBar('Outputting Matlab Solution File...','Solution File Output');
save([fNameFull,'.mat'],'snTot')

% closes the waitbar
h.Update(1,'Matlab Solution File Output Complete',1); 
pause(0.05);
h.closeProgBar();

% --- outputs the CSV combined solution file --- %
function outputASCIIFile(handles,oPara,isCSV)

% retrieves the apparatus data and solution file struct
snTot = getappdata(handles.figCombSave,'snTot');
iPara = getappdata(handles.figCombSave,'iPara');
nApp = sum(snTot.iMov.ok);

% sets the output file name/directory
fDir = getappdata(handles.figCombSave,'fDir');
fName = getappdata(handles.figCombSave,'fName');

% sets the waitbar strings
wStr = {'Setting Positional Data',...
        'Outputting Data To File',...
        'Current File Progress'};

% creates the waitbar figure
h = ProgBar(wStr,'Positional Data Setup');

% -------------------------------- %
% --- SOLUTION FILE DATA SETUP --- %
% -------------------------------- %

% retrieves the positional data
[T,Pos,fNameSuf,Hstr,ok] = setupPosData(handles,'csv',oPara,h);
if ~ok
    return
else
    % sets the number of files to output (for each apparatus)
    nFile = length(T);
    
    % loops through each of the apparatus
    for i = 1:nApp
        % updates the waitbar figure
        wStrNw = sprintf('Overall Progress (Region %i of %i)',i,nApp);
        h.Update(1,wStrNw,i/nApp);
        
        % outputs the data for each split file
        for j = 1:nFile
            % updates the waitbar figure
            h.Update(2,sprintf('%s (%i of %i)',wStr{2},j,nFile),j/nFile);
            
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
            h.Update(3,sprintf('%s (Row 0 of %i)',wStr{3},nRow),0);
            
            % writes to the new data file
            for iRow = 1:nRow
                % updates the waitbar figure
                if mod(iRow,min(500,nRow)) == 0
                    if h.Update(3,sprintf('%s (Row %i of %i)',...
                                          wStr{3},iRow,nRow),iRow/nRow)
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
                        if (iRow == 1)
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
            h.Update(3,sprintf('%s (Row %i of %i)',...
                            wStr{3},size(DataNw,1),size(DataNw,1)),1);
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

% closes the waitbar figure
h.closeProgBar();

% ----------------------------------- %
% --- OUTPUT DATA SETUP FUNCTIONS --- %
% ----------------------------------- %

% --- sets up the positional data array for output to file --- %
function [T,Pos,fNameSuf,Hstr,ok] = setupPosData(handles,fType,oPara,h)

% retrieves the apparatus data and solution file struct
snTot = getappdata(handles.figCombSave,'snTot');
iPara = getappdata(handles.figCombSave,'iPara');

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
    if h.Update(1,sprintf('%s (Region %i of %i)',...
                h.wStr{1},i,nApp),i/nApp)
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
            if (oPara.outY)
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
            k = (i-1)*iMov.pInfo.nRow + j;
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

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% --- initialises the file information fields --- %
function initFileInfo(handles)

% sets the base file directory/output names
hFig = handles.figCombSave;
hPanel = handles.panelFileChoose;
objStr = 'javahandle_withcallbacks.com.sun.java.swing.plaf.windows.WindowsFileChooserUI$7';

% file chooser parameters
fSpec = {{'DART Experiment Solution File (*.ssol)',{'ssol'}};...
         {'Matlab Data File (*.mat)',{'mat'}};...
         {'Text File (*.txt)',{'txt'}};...
         {'Comma Separated Value File (*.csv)',{'csv'}}};
defDir = getappdata(hFig,'fDir');
defFile = getCurrentFilePath(hFig);

% creates the file chooser object
jFileC = setupJavaFileChooser(hPanel,'fSpec',fSpec,...
                                     'defDir',defDir,...
                                     'defFile',defFile);
jFileC.setName(getFileName(defFile,1))                                 
jFileC.PropertyChangeCallback = {@chooserPropChange,handles};
setappdata(hFig,'jFileC',jFileC)

% attempts to retrieve the correct object for the keyboard callback func
jPanel = jFileC.getComponent(2).getComponent(2);
hFn = handle(jPanel.getComponent(2).getComponent(1),'CallbackProperties');
if isa(hFn,objStr)
    % if the object is feasible, set the callback function
    hFn.KeyTypedCallback = {@saveFileNameChng,handles};
end

% calculates the experiment duration
iPara = getappdata(handles.figCombSave,'iPara');
[~,dT,~] = calcTimeDifference(iPara.Tf,iPara.Ts);
iPara.dT = min(dT(2),12);
setappdata(handles.figCombSave,'iPara',iPara)

% sets the maximum split time
setappdata(handles.figCombSave,'Tmax',24*dT(1)+dT(2))
set(handles.editSolnTime,'string',num2str(iPara.dT))

% --- Executes when selected object is changed in panelFileType.
function updateObjectProps(handles)

% initialisations
[isCSV,isOut,isTime] = deal(false,true,true);

% determines if there are any stimuli events
hFig = handles.figCombSave;
snTot = getappdata(hFig,'snTot');
fExtn = getappdata(hFig,'fExtn');
hasStim = ~isempty(snTot.stimP);

% updates the GUI properties based on the
switch fExtn
    case {'.ssol','.mat'} % case is the DART Solution File
        [isOut,isTime] = deal(false);
        set(handles.checkSolnTime,'value',0)
        checkSolnTime_Callback(handles.checkSolnTime, [], handles)
        
    case ('.txt') % case is the ASCII text file
        isCSV = true;
end

% updates the check-box properties
setObjEnable(handles.checkUseComma,isCSV)
setObjEnable(handles.checkSolnTime,isTime)

% sets the output checkbox enabled properties
setObjEnable(handles.checkOutputExpt,isOut)
setObjEnable(handles.checkOutputStim,isOut && hasStim)

% --- sets up the full file path string
function fFile = getCurrentFilePath(hFig)

% sets up the default file name
fDir = getappdata(hFig,'fDir');
fName = getappdata(hFig,'fName');
fExtn = getappdata(hFig,'fExtn');

% sets the full file name
fFile = fullfile(fDir,sprintf('%s%s',fName,fExtn));
