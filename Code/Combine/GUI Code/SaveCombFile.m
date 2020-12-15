function varargout = SaveCombFile(varargin)
% Last Modified by GUIDE v2.5 26-Jan-2014 12:29:29

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

% global variables
global is2D

% sets the input arguments
hMain = varargin{1};
iPara = getappdata(hMain.figFlyCombine,'iPara');
snTot = getappdata(hMain.figFlyCombine,'snTot');
hGUIInfo = getappdata(hMain.figFlyCombine,'hGUIInfo');
iMov = getappdata(hMain.figFlyCombine,'iMov');

% makes the information GUI invisible
set(hGUIInfo,'visible','off')

% sets the data structs into the GUI
setappdata(hObject,'fDir',getappdata(hMain.figFlyCombine,'fDir'))
setappdata(hObject,'fName',getappdata(hMain.figFlyCombine,'fName'))
setappdata(hObject,'iPara',iPara)
setappdata(hObject,'appPara',getappdata(hMain.figFlyCombine,'appPara'))
setappdata(hObject,'iProg',getappdata(hMain.figFlyCombine,'iProg'))
setappdata(hObject,'flyok',getappdata(hGUIInfo,'ok'))
setappdata(hObject,'hGUIInfo',hGUIInfo)
setappdata(hObject,'iMov',iMov)

% reshapes the solution file
snTot = reshapeSolnStruct(snTot,iPara);
setappdata(hObject,'snTot',snTot)

% if only recording, then disable stimuli time-stamp checkbox
if (length(snTot.iExpt) == 1)
    if (strcmp(snTot.iExpt.Info.Type,'RecordOnly'))
        set(handles.checkOutputStim,'enable','off')
    end
else
    Type = field2cell(field2cell(snTot.iExpt,'Info',1),'Type');
    if (all(strcmp(Type,'RecordOnly')))
        set(handles.checkOutputStim,'enable','off')
    end
end
    
% initialises the file information
initFileInfo(handles)

% updates the solution time object properties
set(handles.checkSolnTime,'value',0)
if (is2D); set(handles.checkOutputY,'value',1,'enable','off'); end
checkSolnTime_Callback(handles.checkSolnTime, [], handles)

% initialises the panel file type to the DART file type
set(handles.radioDART,'value',1)
e = struct('NewValue',handles.radioDART);
panelFileType_SelectionChangeFcn(hObject, e, handles)
centreFigPosition(hObject);

% Choose default command line output for SaveCombFile
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
set(hObject,'WindowStyle','modal')

% UIWAIT makes SaveCombFile wait for user response (see UIRESUME)
% uiwait(handles.figCombSave);

% --- Outputs from this function are returned to the command line.
function varargout = SaveCombFile_OutputFcn(hObject, eventdata, handles)

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% ------------------------------------ %
% --- SOLUTION FILE INFO CALLBACKS --- %
% ------------------------------------ %

% --- Executes on button press in buttonSolnDir.
function buttonSolnDir_Callback(hObject, eventdata, handles)

% retrieves the experimental protocol data struct
dDir = getappdata(handles.figCombSave,'fDir');

% prompts the user for the new default directory
dirName = uigetdir(dDir,'Set The Default Path');
if (dirName == 0)
    % if the user cancelled, then escape
    return
else
    % otherwise, update the directory string names
    setappdata(handles.figCombSave,'fDir',dirName);
    
    % resets the enabled properties of the buttons
    updateSolnDirStr(handles)
    set(handles.buttonSolnDir,'tooltipstring',dirName)
end

% --- Executes on editing editSolnName
function editSolnName_Callback(hObject, eventdata, handles)

% retrieves the file name
fileName = get(hObject,'string');
ii = regexp(fileName,'\S');
fileName = fileName(ii(1):end);

% checks to see if the new string is valid
if (chkDirString(fileName))
    % resets the enabled properties of the buttons
    setappdata(handles.figCombSave,'fName',fileName);
    set(handles.editSolnName,'string',['  ',fileName])
else
    % otherwise, reset the solution file string
    set(hObject,'string',['  ',getappdata(handles.figCombSave,'fName')])    
end
    
% --- Executes on button press in checkSolnTime.
function checkSolnTime_Callback(hObject, eventdata, handles)

% sets the time interval text/editbox properties
if (get(hObject,'value'))
    set(handles.textSolnTime,'enable','on')
    set(handles.editSolnTime,'enable','on')
else
    set(handles.textSolnTime,'enable','off')
    set(handles.editSolnTime,'enable','off')
end

% --- Executes on editting editSolnTime
function editSolnTime_Callback(hObject, eventdata, handles)

% retrieves the parameters/data structs
Tmax = getappdata(handles.figCombSave,'Tmax');
iPara = getappdata(handles.figCombSave,'iPara');

% checks to see if the new value is valid
nwVal = str2double(get(hObject,'string'));
if (chkEditValue(nwVal,[1 Tmax],1))
    % if so, updates the parameter field with the new value
    iPara.dT = nwVal;
    setappdata(handles.figCombSave,'iPara',iPara)
else
    % otherwise, revert to the previous valid value
    set(hObject,'string',num2str(iPara.dT))
end

% ------------------------------------- %
% --- FILE TYPE SELECTION CALLBACKS --- %
% ------------------------------------- %

% --- Executes when selected object is changed in panelFileType.
function panelFileType_SelectionChangeFcn(hObject, eventdata, handles)

% initialisations
[eStr,isCSV,isOut,isTime] = deal({'off','on'},false,true,true);

% determines if there are any stimuli events
snTot = getappdata(handles.figCombSave,'snTot');
hasStim = any(~(cellfun(@isempty,snTot.Ts)));

% updates the GUI properties based on the
switch (get(eventdata.NewValue,'UserData'))
    case {'ssol','mat'} % case is the DART Solution File
        [isOut,isTime] = deal(false);
        set(handles.checkSolnTime,'value',0)
        checkSolnTime_Callback(handles.checkSolnTime, [], handles)
    case ('txt') % case is the ASCII text file
        isCSV = true;
end

% updates the check-box properties
set(handles.checkUseComma,'enable',eStr{1+isCSV})
set(handles.checkSolnTime,'enable',eStr{1+isTime})

% sets the output checkbox enabled properties
set(handles.checkOutputExpt,'enable',eStr{1+isOut})
set(handles.checkOutputStim,'enable',eStr{1+(isOut&&hasStim)})

% ---------------------------------------- %
% --- PROGRAM CONTROL BUTTON CALLBACKS --- %
% ---------------------------------------- %

% --- Executes on button press in buttonCreate.
function buttonCreate_Callback(hObject, eventdata, handles)

% % makes the GUI invisible
% set(handles.figCombSave,'visible','off'); pause(0.05)

% retrieves the user's check values
Tmax = 12;
oPara = struct('useComma',get(handles.checkUseComma,'value'),...
               'outY',get(handles.checkOutputY,'value'),...
               'outExpt',get(handles.checkOutputExpt,'value'),...
               'outStim',get(handles.checkOutputStim,'value'));

% retrieves the other output parameter check values
hRadio = findobj(handles.panelFileType,'value',1);
fExtn = get(hRadio,'UserData');

% sets the full solution file name
snTot = getappdata(handles.figCombSave,'snTot');
iPara = getappdata(handles.figCombSave,'iPara');
fDir = getappdata(handles.figCombSave,'fDir');
fName = getappdata(handles.figCombSave,'fName');
fNameFull = fullfile(fDir,fName);

% if not splitting a file (and not outputting a DART file) then determine
% if the files are too long
if (~get(handles.checkSolnTime,'value') && ~strcmp(fExtn,'ssol'))
    % sets the indices of the frames that are to be kept
    Ts = snTot.T{iPara.indS(1)}(iPara.indS(2));
    Tf = snTot.T{iPara.indF(1)}(iPara.indF(2));
    
    % if the solution file duration is excessive, then prompt the user if
    % they wish to split up the solution file
    if ((Tf - Ts)/(60^2) > Tmax)
        a = sprintf('Solution file duration is greater Than %i Hours',Tmax);
        b = 'Do you wish to reconsider splitting up the solution files?';
        uChoice = questdlg([{a};{b}],'Split Up Solution Files?',...
            'Yes','No','Yes');
        if (strcmp(uChoice,'Yes'))
            % if the user chose to exit, then leave the function
            return
        end
    end
end

% outputs the solution file (based on the users selection)
switch (fExtn)
    case {'ssol','mat'} % case is the DART Solution File
        if (exist([fNameFull,'.',fExtn],'file'))
            % if the solution file already exists, then 
            a = 'Experimental solution file already exists. Do you wish to overwrite file?';
            uChoice = questdlg(a,'Overwrite Solution File','Yes','No','Yes');            
            if (~strcmp(uChoice,'Yes'))
                return
            end
        end
        
        % outputs the DART solution file
        if (strcmp(fExtn,'ssol'))
            outputDARTSoln(handles,oPara,fNameFull)
        else
            outputMATSoln(handles,oPara,fNameFull)
        end
    case ('csv') % case is the Comma-Separated Value file
        outputASCIIFile(handles,oPara,true)
    case ('txt') % case is the ASCII text file
        outputASCIIFile(handles,oPara,false)
end

% --- Executes on button press in buttonCancel.
function buttonCancel_Callback(hObject, eventdata, handles)

% makes the information GUI invisible
hGUIInfo = getappdata(handles.figCombSave,'hGUIInfo');

% closes the GUI
delete(handles.figCombSave)
set(hGUIInfo,'visible','on')

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% -------------------------------------- %
% --- SOLUTION FILE OUTPUT FUNCTIONS --- %
% -------------------------------------- %

% --- outputs the DART combined solution file --- %
function outputDARTSoln(handles,oPara,fNameFull)

% retrieves the apparatus data and solution file struct
hFig = handles.figCombSave;
iProg = getappdata(hFig,'iProg');
snTot = getappdata(hFig,'snTot');
appPara = getappdata(hFig,'appPara');
iMov = getappdata(hFig,'iMov');
[iMov.flyok,snTot.appPara.flyok] = deal(getappdata(hFig,'flyok'));

% reduce the combined solution files
[aok,snTot.iMov] = deal(appPara.ok,iMov);
snTot = reduceCombSolnFiles(snTot,num2cell(find(aok)),appPara.Name(aok),1);

% reduces the sub-region by the unique names
snTot = resetUniqueSubRegions(snTot);

% outputs the solution file
saveCombSolnFile(iProg.TempFile,[fNameFull,'.ssol'],snTot,oPara);

% --- outputs a Matlab mat solution file --- %
function outputMATSoln(handles,oPara,fNameFull)

% global variables
global is2D

% retrieves the apparatus data and solution file struct
snTot = getappdata(handles.figCombSave,'snTot');
appPara = getappdata(handles.figCombSave,'appPara');
appPara.flyok = getappdata(handles.figCombSave,'flyok');

% converts the cell arrays to numerical arrays
snTot.T = cell2mat(snTot.T);
snTot.Ts = cell2mat(snTot.Ts);
snTot.Tf = cell2mat(snTot.Tf);
snTot.isDay = cell2mat(snTot.isDay');

% resets/add other important fields in the solution data struct
snTot.StimInfo = snTot.iExpt.Stim;
snTot.TimeInfo = snTot.iExpt.Timing;
snTot.appPara = appPara;

% removes any extraneous fields
if (~is2D); snTot = rmfield(snTot,'Py'); end
snTot = rmfield(snTot,{'pMapPx','pMapPy','iExpt'});

% saves the file
h = waitbar(0,'Outputting Matlab Solution File');
save([fNameFull,'.mat'],'snTot')

% closes the waitbar
waitbar(1,h,'Matlab Solution File Output Complete'); pause(0.05);
close(h)

% --- outputs the CSV combined solution file --- %
function outputASCIIFile(handles,oPara,isCSV)

% retrieves the apparatus data and solution file struct
snTot = getappdata(handles.figCombSave,'snTot');
appPara = getappdata(handles.figCombSave,'appPara');
iPara = getappdata(handles.figCombSave,'iPara');
nApp = sum(appPara.ok);

% sets the output file name/directory
fDir = getappdata(handles.figCombSave,'fDir');
fName = getappdata(handles.figCombSave,'fName');

% sets the waitbar strings
wStr = {'Setting Positional Data','Outputting Data To File','Current File Progress'};

% creates the waitbar figure
h = waitbarFig(wStr,'Positional Data Setup');

% -------------------------------- %
% --- SOLUTION FILE DATA SETUP --- %
% -------------------------------- %

% retrieves the positional data
[T,Pos,fNameSuf,Hstr,ok] = setupPosData(handles,'csv',oPara,h);
if (~ok)
    return
else
    % sets the number of files to output (for each apparatus)
    nFile = length(T);
    
    % loops through each of the apparatus
    for i = 1:nApp
        % updates the waitbar figure
        waitbarFig(1,sprintf('Overall Progress (Apparatus %i of %i)',...
            i,nApp),i/nApp,h);
        
        % outputs the data for each split file
        for j = 1:nFile
            % updates the waitbar figure
            waitbarFig(2,sprintf('%s (%i of %i)',wStr{2},j,nFile),j/nFile,h);
            
            % opens a new data file
            DataNw = [Hstr{i};num2cell([T{j} Pos{i}{j}])];
            if (isCSV)
                fNameEnd = sprintf('%s (%s).csv',fName,fNameSuf{i}{j});
            else
                fNameEnd = sprintf('%s (%s).txt',fName,fNameSuf{i}{j});
            end
            
            % opens the file
            fNameNw = fullfile(fDir,fNameEnd);
            fid = fopen(fNameNw,'w');
            
            % updates the waitbar figure
            waitbarFig(3,sprintf('%s (Row 0 of %i)',wStr{3},size(DataNw,1)),0,h);
            
            % writes to the new data file
            for iRow = 1:size(DataNw,1)
                % updates the waitbar figure
                if (mod(iRow,min(500,size(DataNw,1))) == 0)
                    if (waitbarFig(3,sprintf('%s (Row %i of %i)',...
                            wStr{3},iRow,size(DataNw,1)),iRow/size(DataNw,1),h))
                        try; fclose(fid); end
                        return
                    end
                end
                
                % prints the first column of data
                if (iRow == 1)
                    fprintf(fid,'%s',DataNw{iRow,1});
                else
                    fprintf(fid,'%.2f',DataNw{iRow,1});
                end
                
                % prints the other columns of data
                for iCol = 2:size(DataNw,2)
                    if (isCSV || oPara.useComma)
                        if (iRow == 1)
                            fprintf(fid,',%s',DataNw{iRow,iCol});
                        else
                            fprintf(fid,',%.2f',DataNw{iRow,iCol});
                        end
                    else
                        if (iCol == 2)
                            if (iRow == 1)
                                fprintf(fid,'\t\t%s',DataNw{iRow,iCol});
                            else
                                fprintf(fid,'\t\t%.2f',DataNw{iRow,iCol});
                            end
                        else
                            if (iRow == 1)
                                fprintf(fid,'\t%s',DataNw{iRow,iCol});
                            else
                                fprintf(fid,'\t%.2f',DataNw{iRow,iCol});
                            end
                        end
                    end
                end
                
                % prints the end of line-statement
                if (isCSV)
                    fprintf(fid,'\n');
                else
                    fprintf(fid,'\r\n');
                end
            end
            
            % updates the waitbar figure and closes the file
            waitbarFig(3,sprintf('%s (Row %i of %i)',...
                wStr{3},size(DataNw,1),size(DataNw,1)),1,h);
            fclose(fid);
        end
    end
end

% retrieves the experimental data (if selected)
if (oPara.outStim)
    % sets the stimuli data
    stimData = setupStimData(snTot);
    if (isCSV)
        fNameStim = fullfile(fDir,sprintf('%s (Stim Data).csv',fName));
    else
        fNameStim = fullfile(fDir,sprintf('%s (Stim Data).txt',fName));
    end
    
    % opens a new files and sets the header row
    fid = fopen(fNameStim,'w');
    if (isCSV || oPara.useComma)
        fprintf(fid,'%s,%s,%s\n','Stim Event','Start Time','Finish Time');
    else
        fprintf(fid,'%s\t%s\t%s\n','Stim Event','Start Time','Finish Time');
    end
    
    % outputs the time values to file
    for iRow = 1:size(stimData,1)
        % prints the stimuli event index
        fprintf(fid,'%i',stimData(iRow,1));
        
        % prints the other columns
        for iCol = 2:size(stimData,2)
            fprintf(fid,'\t,%.2f',stimData(iRow,iCol));
        end
        
        % prints the end of line-statement
        fprintf(fid,'\n');
    end
    
    % closes the file
    fclose(fid);
end

% retrieves the experimental data (if selected)
if (oPara.outExpt)
    % retrieves the experiment info and the file name
    exptData = setupExptData(snTot,iPara);
    if (isCSV)
        fNameExpt = fullfile(fDir,sprintf('%s (Expt Data).csv',fName));
    else
        fNameExpt = fullfile(fDir,sprintf('%s (Expt Data).txt',fName));
    end
    
    % opens a new files and sets the header row
    fid = fopen(fNameExpt,'w');
    
    % outputs the time values to file
    for iRow = 1:size(exptData,1)
        % prints the stimuli event index
        if (isCSV || oPara.useComma)
            fprintf(fid,'%s,%s\n',exptData{iRow,1},exptData{iRow,2});
        else
            fprintf(fid,'%s\t%s\n',exptData{iRow,1},exptData{iRow,2});
        end
    end
    
    % closes the file
    fclose(fid);
end

% closes the waitbar figure
close(h)

% ----------------------------------- %
% --- OUTPUT DATA SETUP FUNCTIONS --- %
% ----------------------------------- %

% --- sets up the positional data array for output to file --- %
function [T,Pos,fNameSuf,Hstr,ok] = setupPosData(handles,fType,oPara,h)

% retrieves the apparatus data and solution file struct
snTot = getappdata(handles.figCombSave,'snTot');
iPara = getappdata(handles.figCombSave,'iPara');
appPara = getappdata(handles.figCombSave,'appPara');
flyok = getappdata(handles.figCombSave,'flyok');

% determines the split time/if splitting flag
isSplit = get(handles.checkSolnTime,'value');

% initialisations
[nApp,ok] = deal(sum(appPara.ok),true);
indOut = find(appPara.ok);

% memory allocation
[Pos,fNameSuf,Hstr] = deal(cell(1,nApp));
wStr = getappdata(h,'wStr');

% ------------------------- %
% --- TIME VECTOR SETUP --- %
% ------------------------- %

% sets the time vector based on the file type/
switch (fType)
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
if (~iscell(T)); T = T - T(1); end

% sets the solution file group indices
if (isSplit)
    % if splitting up the movies, then set the split time
    tSplitH = str2double(get(handles.editSolnTime,'string'));
    tSplit = tSplitH*3600;
    
    % determines the point in the movie where the split occurs
    Tmod = mod(T-T(1),tSplit);
    ii = find(Tmod(2:end)<Tmod(1:end-1)) + 1;
    
    % sets the group indices based on the number of file splits
    if (isempty(ii))
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
    if (waitbarFig(1,sprintf('%s (Apparatus %i of %i)',...
            wStr{1},i,nApp),i/nApp,h))
        % if the user cancelled, then exit the function
        [T,Pos,Hstr,ok] = deal([],[],[],false);
        return
    end
    
    % sets the apparatus index and ok flags
    [iApp,okNw] = deal(indOut(i),find(flyok(:,indOut(i))));
    Hstr{i} = cell(1,1+(1+double(oPara.outY))*length(okNw));
    
    % retrieves the fly x-coordinates
    Px = snTot.Px{i}(indNw,okNw);
    
    % sets the position array based on whether the user is outputting the y-coords
    if (oPara.outY)
        % output y-location as well
        Py = snTot.Py{i}(indNw,okNw);
        Pos{i} = cell2mat(cellfun(@(x,y)([x y]),num2cell(Px,1),num2cell(Py,1),'un',0));
        
        % clears extraneous variables
        clear Py; pause(0.01);
    else
        % only outputting x-locations
        Pos{i} = Px;
    end
    
    % clears extraneous variables
    clear Px; pause(0.01);
    
    % sets the file name suffix strings
    if (~isempty(indGrp))
        % if more than one file, then set the file-names based on the
        % file period
        Pos{i} = cellfun(@(x)(Pos{i}(x,:)),indGrp,'un',0);
        fNameSuf{i} = cellfun(@(x)(sprintf('%s - H%i-%i',appPara.Name{iApp},...
            (x-1)*tSplitH,x*tSplitH)),...
            num2cell(1:size(indGrp,1))','un',0);
        
        % splits up the time strings into groups
        if (i == 1)
            T = cellfun(@(x)(T(x,:)),indGrp,'un',0);
        end
    else
        % otherwise, set the suffix name to be the apparatus name
        [Pos{i},fNameSuf{i}] = deal(Pos(i),appPara.Name(iApp));
        if (i == 1)
            T = {T};
        end
    end
    
    % sets the header string for each apparatus
    switch (fType)
        case {'csv','txt'}
            % sets the header string based on whether outputting y-data
            Hstr{i}{1} = 'Time';
            H1 = cellfun(@(x)(sprintf('X%i',x)),num2cell(okNw),'un',0);
            if (oPara.outY)
                % case is outputting both x and y data
                H2 = [H1 cellfun(@(x)(sprintf('Y%i',x)),num2cell(okNw),'un',0)];
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
nField = 6;
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
        case (6) % case is the stimuli count
            exptData{i,1} = 'Stimuli Count';
            switch (snTot.iExpt.Info.Type)
                case ('RecordOnly')
                    exptData{i,2} = 'N/A';
                otherwise
                    exptData{i,2} = num2str(length(cell2mat(snTot.Ts)));
            end
    end
end

% --- sets up the stimulus data array for output to file --- %
function stimData = setupStimData(snTot)

% sets the start/finish times and appends the stimuli index
tStim = [cell2mat(snTot.Ts) cell2mat(snTot.Tf)];
stimData = [(1:size(tStim,1))' tStim];

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% --- initialises the file information fields --- %
function initFileInfo(handles)

% sets the base file directory/output names
fName = getappdata(handles.figCombSave,'fName');

% sets file information string fields
updateSolnDirStr(handles)
set(handles.editSolnName,'string',['  ',fName],'tooltipstring',fName)

% calculates the experiment duration
iPara = getappdata(handles.figCombSave,'iPara');
[~,dT,~] = calcTimeDifference(iPara.Tf,iPara.Ts);
iPara.dT = min(dT(2),12);
setappdata(handles.figCombSave,'iPara',iPara)

% sets the maximum split time
setappdata(handles.figCombSave,'Tmax',24*dT(1)+dT(2))
set(handles.editSolnTime,'string',num2str(iPara.dT))

% --- updates the base output directory string objects --- %
function updateSolnDirStr(handles)

% retrieves the program default struct
fDir = getappdata(handles.figCombSave,'fDir');
iProg = getappdata(handles.figCombSave,'iProg');

% if the last letter is a back/forward slash then remove it
cDir = iProg.DirComb; 
if (strcmp(cDir(end),'/') || strcmp(cDir(end),'\'))
    cDir = cDir(1:end-1); 
end

% sets the new base directory name string
ii = strfind(fDir,cDir);
if (isempty(ii))
    % if not in the default directory, then set the whole name
    nwDir = fDir;
else
    % otherwise, use the shortened version of the name
    iOfs = (ii-1) + length(cDir);
    if (iOfs == length(fDir))
        nwDir = fullfile('~',' ');
    else
        nwDir = fullfile('~',fDir((iOfs+1):end),' ');
    end
end

% sets file information string fields
set(handles.editSolnDir,'string',['  ',nwDir])
set(handles.buttonSolnDir,'tooltipstring',fDir)
