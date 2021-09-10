function varargout = DataOutput(varargin)
% Last Modified by GUIDE v2.5 16-Nov-2018 03:04:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DataOutput_OpeningFcn, ...
                   'gui_OutputFcn',  @DataOutput_OutputFcn, ...
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

% --- Executes just before DataOutput is made visible.
function DataOutput_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for DataOutput
handles.output = hObject;

% imports the java classes
import javax.swing.*

% global variables
global Tmlt T0 TStr updateFlag nMet canEditCell nSheetMax tCount
global rngRow rngCol iRowD iColD
[Tmlt,TStr,updateFlag,canEditCell,nMet] = deal(1,' (sec)',2,true,11);
[nSheetMax,tCount,rngRow,rngCol,iRowD,iColD] = deal(20,0,40,15,[],[]);

% creates the load bar
set(0,'CurrentFigure',hObject);
h = ProgressLoadbar('Initialising Data Output GUI...');
setObjVisibility(hObject,'off'); pause(0.05);

% sets the input arguments
hGUI = varargin{1};
hGUIH = guidata(hGUI);

% retrieves the data structs from the main GUI
iProg = getappdata(hGUI,'iProg');
hPara = getappdata(hGUI,'hPara');
plotD = getappdata(hGUI,'plotD');
snTot = getappdata(hGUI,'snTot');
sName = getappdata(hGUI,'sName');
pData = getappdata(hPara,'pData');

% Choose default command line output for DataOutput
setObjVisibility(hPara,'off')
setObjVisibility(hGUI,'off') 
pause(0.05);

% retrieves the listbox selection indices from the main GUI
T0 = snTot(1).iExpt.Timing.T0;
[eInd,fInd,pInd] = getSelectedIndices(hGUIH);

% sets the plot parameter/data structs
plotD = plotD{pInd}{fInd,eInd};
if (pInd ~= 3)
    [sName,snTot] = deal(sName(eInd),snTot(eInd));
end

% runs the post-output function
[pData,plotD] = feval(pData.oFcn,pData,plotD{1},snTot);   

% removes special characters from the group names
for i = 1:length(pData.appName)
    pData.appName{i} = pData.appName{i}(regexp(pData.appName{i},'[^{\^}]'));
end

% initialises the data struct
[iData,metType,hasTest] = initDataStruct(handles,snTot,pData,plotD);

% sets the data structs into the GUI
setappdata(hObject,'hGUI',hGUI);
setappdata(hObject,'iProg',iProg)
setappdata(hObject,'hPara',hPara)
setappdata(hObject,'pData',pData)  
setappdata(hObject,'plotD',plotD)  
setappdata(hObject,'sName',sName)  
setappdata(hObject,'iData',iData)  
setappdata(hObject,'snTot',snTot)  
setappdata(hObject,'metType',metType)
setappdata(hObject,'hasTest',find(hasTest))

% % removes the solution/plot data structs from the analysis GUI
% setappdata(hGUI,'snTot',[])

% sets the function handles into the GUI
setappdata(hObject,'updateSheetData',@updateSheetData)
setappdata(hObject,'setFinalSheetData',@setFinalSheetData);
setappdata(hObject,'getTableHeaderStrings',@getTableHeaderStrings);

% updates the panel selection
handles = initGUIObjects(handles,metType,hasTest);
centreFigPosition(hObject);

% updates the sheet data
setObjVisibility(hObject,'on')
pause(0.05); drawnow();

% initialises the GUI java objects
initGUIJavaObjects(handles)
   
% updates the sheet data
updateSheetData(handles,true,1)

% closes the loadbar
try; delete(h); end

% ensures that the appropriate check boxes/buttons have been inactivated
updateFlag = 0; pause(0.1); 

% Update handles structure and sets the main/parameter GUIs to be invisible
guidata(hObject, handles);

% UIWAIT makes DataOutput wait for user response (see UIRESUME)
% uiwait(handles.figDataOutput);

% --- Outputs from this function are returned to the command line.
function varargout = DataOutput_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                         MENU CALLBACK FUNCTIONS                         %
%-------------------------------------------------------------------------%

% ----------------------- %
% --- FILE MENU ITEMS --- %
% ----------------------- %

% -------------------------------------------------------------------------
function menuSave_Callback(hObject, eventdata, handles)

% turns off annoying warnings...
warning off all

% retrieves the data structs
iData = getappdata(handles.figDataOutput,'iData');
iProg = getappdata(getappdata(handles.figDataOutput,'hGUI'),'iProg');

% determines if any of the data sheet tabs are empty
ii = find(cellfun(@isempty,iData.tData.Data));
if (~isempty(ii))
    % if so, then create a warning message for the user
    wStr = sprintf('The following data tab sheets are empty:\n\n');
    for i = reshape(ii,1,length(ii))
        wStr = sprintf('%s => %s\n',wStr,iData.tData.Name{i});
    end
    wStr = sprintf(['%s\nThese data tab sheets will not be included in ',...
                    'the final output data file. Do you still want to ',...
                    'continue anyway?'],wStr);
                
    % prompts the user if they still want to continue
    uChoice = questdlg(wStr,'Empty Data Sheet Tabs','Yes','No','Yes');
    if (~strcmp(uChoice,'Yes'))
        % if not, then exit the function
        return
    end
end

% sets the output file type
[fStr,sType] = deal({'XLSX','CSV'},{'Sheet Tab','File'});
fType = {'*.xlsx','Excel Spreadsheet (*.xlsx)';...
         '*.csv','Comma Separated Value File (*.csv)'};

% prompts the user for the movie filename
[fName,fDir,fIndex] = uiputfile(fType,'Save Data File',iProg.OutData);
if (fIndex == 0)
    % if the user cancelled, then exit the function
    return
else
    % if outputting to xlsx file, then 
    if (fIndex == 1)
        [N,Nmax] = deal(cellfun(@(x)(numel(x)),iData.tData.Data),0.5e6);
        if (sum(N) > Nmax)
            % if the data is too large, then output a warning
            wStr = {'Warning! Data is too large to output to .xlsx file.';
                    'Data will be output to a .csv file instead.'};
            waitfor(warndlg(wStr,'Output Data Too Large','modal'))
            
            % resets the file index
            fIndex = 2;
        end
    end        
end

% creates a loadbar figure
wStr = sprintf('Outputting %s Data File',fStr{fIndex});
h = ProgressLoadbar(wStr); pause(0.05);

% sets the file name based on the output file type
if (fIndex == 1)
    % case is an .xlsx file
    fFile = fullfile(fDir,fName);
    
    % deletes the file if it exists
    if (exist(fFile,'file')); delete(fFile); end
else
    % case is a .csv file
    fNameP = getFileName(fName); 
end

% outputs the data for each worksheet tab
for i = 1:iData.nTab    
    % updates the loadbar string
    wStrNw = sprintf(['%s (Sheet Tab %i of %i - String Data ',...
                           'Conversion)'],wStr,i,iData.nTab);
    if (~updateLoadbar(h,wStrNw))    
        break
    end       
    
    % only output if the data sheet is not empty
    iSel = iData.tData.iSel(i);
    if (~isempty(iData.tData.Data{i}{iSel}))        
        % resets all numeric strings to numerical values
        if (~isempty(iData.tData.DataN{i}{iSel}))
            DataNw = iData.tData.DataN{i}{iSel};        
        else                        
            DataNw = iData.tData.Data{i}{iSel};        
            ii = cellfun(@(x)(~isnan(str2double(x))),DataNw);
            DataNw(ii) = num2cell(cellfun(@str2double,DataNw(ii)));            
        end
                        
        % updates the loadbar
        wStrNw = sprintf('%s (%s %i of %i)',wStr,sType{fIndex},i,iData.nTab);
        updateLoadbar(h,wStrNw);        
        
        % outputs the data to file
        sName = iData.tData.Name{i};
        switch (fIndex)
            case (1) % output file is .xlsx                  
                % outputs the file
                writeXLSFile(fFile,DataNw,sName,h)              
            case (2) % output file is .csv                
                % outputs the file
                fName = fullfile(fDir,sprintf('%s (%s).csv',fNameP,sName));
                writeCSVFile(fName,DataNw,h)
        end
                
        % clear the data array
        clear DataNw;
        pause(0.05);
    end
end    

% turns on warnings again
warning on all

% --- writes the data to an excel spreadsheet file
function writeXLSFile(fFile,DataNw,sName,h)

% initialisations
[blkSz,i0] = deal(100000,25);
[nRow,nCol] = size(DataNw);

% outputs the data to file
nRC = nRow*nCol;
if nRC < blkSz 
    % if so, then write the file as one block
    writeXLSData(fFile,DataNw,sName,0);

else
    % otherwise, write the data to file in blocks
    nBlk = ceil(nRC/blkSz);
    rwSz = 1 + ceil((nRow-i0)/nBlk);
    wStr = h.StatusMessage(1:end-1);
    
    % loops through each block outputting the data to file
    for i = 1:nBlk
        % updates the loadbar message
        updateLoadbar(h,sprintf('%s, Block %i of %i)',wStr,i,nBlk));        

        % sets the indices of the new block
        if i == 1
            indBlk = 1:i0;
        else
            indBlk = (i0 + (i-2)*rwSz+1):min(nRow, i0 + (i-1)*rwSz);
        end

        % sets the new data block for output. resets any columns that
        % have non-cell columns
        nwBlk = DataNw(indBlk,:);
        ii = cellfun(@(x)(all(cellfun(@ischar,x))),num2cell(nwBlk,1));            
        if any(ii)
            nwBlk(:,ii) = cellfun(@(x)({str2double(x)}),nwBlk(:,ii));
        end
            
        % outputs the data to file
        if ~writeXLSData(fFile,nwBlk,sName,i > 1)
		return
	end
    end
    
    % kills any external excel processes (if any are running)
    if ispc; closeExcelProcesses(); end
    
    % if a CSV file has been created as well, then delete it
    [fDir,fName,~] = fileparts(fFile);
    fFileCSV = fullfile(fDir,sprintf('%s.csv',fName));
    if exist(fFileCSV,'file')
        delete(fFileCSV)
    end
end

% -------------------------------------------------------------------------
function menuExit_Callback(hObject, eventdata, handles)

% prompts the user if they wish to close the tracking gui
uChoice = questdlg('Are you sure want to close the Data Output GUI?',...
                     'Close Data Output GUI?','Yes','No','Yes');
if (~strcmp(uChoice,'Yes'))
    return
end

% retrieves the parameter GUI handle
hGUI = getappdata(handles.figDataOutput,'hGUI');
hPara = getappdata(handles.figDataOutput,'hPara');

% % resets the solution/plot data structs from the analysis GUI
% setappdata(hGUI,'snTot',getappdata(handles.figDataOutput,'snTot'))

% deletes the output stats GUI (if open)
hStats = findall(0,'tag','figStatTest');
if ~isempty(hStats); delete(hStats); end

% deletes the sub-GUI and makes the parameter GUI visible again
delete(handles.figDataOutput)
setObjVisibility(hGUI,'on')
setObjVisibility(hPara,'on')

% sets the parameter GUI to the top
uistack(hPara,'top');

% ---------------------------------- %
% --- TAB INFORMATION MENU ITEMS --- %
% ---------------------------------- %

% -------------------------------------------------------------------------
function menuDeleteTab_Callback(hObject, eventdata, handles)

% global variables
global iRowD iColD

% retrieves the data struct
iData = getappdata(handles.figDataOutput,'iData');
hTabGrpD = findall(handles.panelDataOuter,'tag','sheetTabGrp');
hTabGrpM = findall(handles.panelMetricInfo,'tag','metricTabGrp');

% if there is only one tab, then output an error then exit
if (iData.nTab == 1)
    eStr = 'Error! Data output must include at least one worksheet';
    waitfor(errordlg(eStr,'Tab Deletion Error','modal'))
    return 
else
    mSel0 = iData.tData.mSel(iData.cTab);
end

% prompts the user if they want to delete the selected tab
uChoice = questdlg('Are you sure you want to delete the selected tab?',...
                   'Delete Sheet Tab','Yes','No','Yes');
if (~strcmp(uChoice,'Yes'))
    % if the user cancelled, then exit the function
    return
end

% deletes the currently selected tab
delete(getSheetTableHandle(handles))
delete(iData.tData.hTab{iData.cTab})

% decrements the tab counters
for i = (iData.cTab+1):(iData.nTab+1)
    iTab0 = get(iData.tData.hTab{i},'UserData');
    set(iData.tData.hTab{i},'UserData',iTab0-1);
    
    hTable = findall(iData.tData.hTab{i},'type','uitable');
    set(hTable,'UserData',iTab0-1);            
end

% removes the data associated with the selected tab
ii = (1:iData.nTab) ~= iData.cTab;
iData.tData.Name = iData.tData.Name(ii);
iData.tData.Data = iData.tData.Data(ii);
iData.tData.DataN = iData.tData.DataN(ii);
iData.tData.iPara = iData.tData.iPara(ii);
iData.tData.iSel = iData.tData.iSel(ii);
iData.tData.mSel = iData.tData.mSel(ii);
iData.tData.mInd = iData.tData.mInd(ii);
iData.tData.stInd = iData.tData.stInd(ii);
iData.tData.altChk = iData.tData.altChk(ii);
iData.tData.alignV = iData.tData.alignV(ii,:);
iData.tData.hTab = iData.tData.hTab([ii,true]);
[iData.appOut,iData.expOut] = deal(iData.appOut(:,ii),iData.expOut(:,ii));
[iRowD,iColD] = deal(iRowD(ii),iColD(ii));

% decrements the tab count
iData.nTab = iData.nTab - 1;
if iData.cTab > iData.nTab
    % if the selected tab is greater than tab count, then re-select    
    iData.cTab = iData.nTab;
    updateTabSelection(hTabGrpD,iData.cTab,iData.nTab)        
end

% updates the data struct
setappdata(handles.figDataOutput,'iData',iData)

% disables the delete/move tab menu items (if only one tab)
if iData.nTab == 1
    setObjEnable(handles.menuDeleteTab,'off')
    setObjEnable(handles.menuMoveTab,'off')
end

% updates the metric 
updateTabSelection(hTabGrpM,iData.tData.mSel(iData.cTab),1)

% sets the worksheet information and data 
updateSheetInfo(handles)

% -------------------------------------------------------------------------
function menuRenameTab_Callback(hObject, eventdata, handles)

% retrieves the data struct
iData = getappdata(handles.figDataOutput,'iData');
[iTab,eStr] = deal(iData.cTab,[]);
prStr = iData.tData.Name(iTab);

% prompts the user for the new name
nwStr = inputdlg('Enter new tab name:','Selected Tab Rename',[1 40],prStr);
if (~isempty(nwStr))
    % checks to see if the input string is valid
    if (strcmp(nwStr{1},'+')) 
        % can't have a "+" as a tab name (used for adding sheets)
        eStr = 'This is not a valid tab name. Please try again.';        
    elseif (any(strcmp(nwStr{1},iData.tData.Name((1:iData.nTab) ~= iTab))))
        % tab name already exists
        eStr = 'Tab name already exists. Please try again.';                        
    end
       
    % determines if the new tab name is valid
    if (~isempty(eStr))
        % if not, output an error to screen and re-run the function
        waitfor(errordlg(eStr,'Invalid Tab Name','modal'))
        menuRenameTab_Callback(handles.menuRenameTab, [], handles)
        return
    else
        % otherwise, update the tab name and tab title
        iData.tData.Name{iTab} = nwStr{1};
        set(iData.tData.hTab{iTab},'Title',iData.tData.Name{iTab})

        % resets the data struct
        setappdata(handles.figDataOutput,'iData',iData)
    end
end

% -------------------------------------------------------------------------
function menuMoveTab_Callback(hObject, eventdata, handles)

% global variables
global iRowD iColD

% initialisations
iData = getappdata(handles.figDataOutput,'iData');
[lStr,lSize,iTab0] = deal(iData.tData.Name',[250 300],iData.cTab);
lStr = [lStr((1:length(lStr))~=iData.cTab);{'(Move To End)'}];

% prompts the user for the tab to move the selected tab before
[iTab,ok] = listdlg('PromptString','Move selected tab to before:',...
                      'SelectionMode','single','ListString',lStr,...
                      'Name','Move Selected Tab','ListSize',lSize);
if ((~ok) || (iTab == iTab0)) 
    return
end
              
% sets the permutation array
ii = find((1:iData.nTab) ~= iTab0);
jj = [ii(1:(iTab-1)),iTab0,ii(iTab:end)];
jTab = find(jj == iTab0);

% reorders the arrays
iData.tData.Name = iData.tData.Name(jj);
iData.tData.Data = iData.tData.Data(jj);
iData.tData.DataN = iData.tData.DataN(jj);
iData.tData.iPara = iData.tData.iPara(jj);
iData.tData.iSel = iData.tData.iSel(jj);
iData.tData.mSel = iData.tData.mSel(jj);
iData.tData.mInd = iData.tData.mInd(jj);
iData.tData.stInd = iData.tData.stInd(jj);
iData.tData.altChk = iData.tData.altChk(jj);
iData.tData.alignV = iData.tData.alignV(jj,:);
[iData.appOut,iData.expOut] = deal(iData.appOut(:,jj),iData.expOut(:,jj));
[iRowD,iColD] = deal(iRowD(jj),iColD(jj));

% updates the tab properties
cellfun(@(x,y)(set(x,'Title',y)),iData.tData.hTab(1:end-1),iData.tData.Name');

% updates the data struct
iData.cTab = jTab;
setappdata(handles.figDataOutput,'iData',iData)

% resets the selected tab
hTabGrp = findall(handles.panelDataOuter,'tag','sheetTabGrp');
updateTabSelection(hTabGrp,jTab,iTab0)
setObjVisibility(findall(iData.tData.hTab{jTab},'type','uitable'),'on')

% updates the data struct
iData.cTab = jTab;
setappdata(handles.figDataOutput,'iData',iData)

% sets the worksheet information and data 
updateSheetInfo(handles,1)

% updates the sheet data for all tabs
[h,iDataT] = deal(ProgressLoadbar('Updating All Data Tables...'),iData);
for i = 1:iData.nTab
    % sets the 
    iDataT.cTab = i;
    setappdata(handles.figDataOutput,'iData',iDataT)
    
    % updates the data sheet
    updateSheetData(handles,true,1)
end

% resets the original data struct into the GUI
try; close(h); end
setappdata(handles.figDataOutput,'iData',iData)

% -------------------------------------------------------------------------
function menuClearTab_Callback(hObject, eventdata, handles)

% prompts the user if they want to delete the selected tab
uChoice = questdlg('Are you sure you want to clear the data from the selected tab?',...
                   'Clear Sheet Tab','Yes','No','Yes');
if (~strcmp(uChoice,'Yes'))
    % if the user cancelled, then exit the function
    return
end

% updates the parameter struct
iData = getappdata(handles.figDataOutput,'iData');
% metType = getappdata(handles.figDataOutput,'metType');

% removes all the flag for each of the alternative option values
iSel = iData.tData.iSel(iData.cTab);

% resets the data struct fields
iData.tData.altChk{iData.cTab}{iSel}(:) = false;
iData.tData.Data{iData.cTab}{iSel} = [];
iData.tData.DataN{iData.cTab}{iSel} = [];
iData.tData.iPara{iData.cTab}{iSel}(1) = {[]};
iData.tData.mInd{iData.cTab}{iSel} = [];

% clears the stats selection (if selected)
if (iSel == 1); iData.tData.stInd{iData.cTab}(:) = NaN; end
    
% updates the data struct
setappdata(handles.figDataOutput,'iData',iData);

% resets the button properties
set(handles.listMetricOrder,'value',[])
updateButtonProps(handles)

% sets the worksheet information 
updateSheetInfo(handles)
updateTableProperties(handles)
% updateSheetData(handles,true); 

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% ------------------------------------- %
% --- GUI FIGURE SPECIFIC FUNCTIONS --- %
% ------------------------------------- %

% --- Executes when figDataOutput is resized.
function figDataOutput_ResizeFcn(hObject, eventdata, handles)

% global variables
global updateFlag 

% dont allow any update (if flag is set to 2)
if (updateFlag == 2)
    return; 
else
    updateFlag = 2;
end

% parameters
[pPos,Y0] = deal(get(handles.panelInfoOuter,'position'),10);
[Wmin,Hmin] = deal(1000,pPos(4)+2*Y0);

% retrieves the final position of the resized GUI
fPos = getFinalResizePos(hObject,Wmin,Hmin);

% update the figure position
resetFigSize(handles,fPos)

% makes the figure visible again
setObjVisibility(hObject,'on');

% ensures the figure doesn't resize again (when maximised)
% pause(1);
updateFlag = 0;

% --- resizes the analysis GUI objects
function resetFigSize(h,fPos)

% sets the overall width/height of the figure
[W0,H0,dY,dX] = deal(fPos(3),fPos(4),10,10);
pPosIO = get(h.panelInfoOuter,'position');

% updates the image panel dimensions
pPosDO = [sum(pPosIO([1 3]))+dX,dY,(W0-(3*dX+pPosIO(3))),(H0-2*dY)];
set(h.panelDataOuter,'units','pixels','position',pPosDO)

% updates the outer position bottom location
pPosIO(2) = H0 - (pPosIO(4)+dY);
set(h.panelInfoOuter,'position',pPosIO);

% resets the edit position
ePos = [[dX dY]/2-dX,pPosDO(3)-(dX+2),pPosDO(4)-(7*dY/2)];

% resets the data sheet table position
tPos = [10,10,pPosDO(3:4)-[22 42]];
hTab = findall(h.panelDataOuter,'type','uitable');
hSP = findall(h.panelDataOuter,'tag','hSP');
cellfun(@(x)(set(x,'position',tPos)),num2cell(hTab))
cellfun(@(x)(set(x,'position',tPos)),num2cell(hSP))

% updates the position of the tab group
hTabGrp = findall(h.panelDataOuter,'tag','sheetTabGrp');
htPos = getTabPosVector(h.panelDataOuter);
% htPos = [3,dY/2,pPosDO(3)-dX,pPosDO(4)-(dY-2)];
set(hTabGrp,'Position',htPos)

% resets the outer panel
set(h.panelOuter,'position',[0 0 fPos(3:4)])

% ---------------------------------- %
% --- OUTER INFO PANEL CALLBACKS --- %
% ---------------------------------- %

% --- Executes when selected object is changed in panelInfoOuter.
function panelInfoOuter_SelectionChangeFcn(hObject, eventdata, handles)

% global variables
global nMetG

% creates a loadbar figure
if (~isa(eventdata,'char'))
    h = ProgressLoadbar('Updating Data Table...');
end

% updates the data struct
iData = getappdata(handles.figDataOutput,'iData');
[iSel,iSelT] = getSelectedIndexType(handles);
iData.tData.iSel(iData.cTab) = iSelT;
setappdata(handles.figDataOutput,'iData',iData)

% sets the index of the radio button that was 
[eStr,eInd] = deal({'off','on'},num2cell(zeros(1,3)));
if (iSel == 1)
    % case is the statistical tests
    eInd{1} = 1;
    
    % updates the data alignment panel properties
    iPara = iData.tData.iPara{iData.cTab}{1};
    setPanelProps(handles.panelDataAlign,eStr{1+(length(iPara{1})>1)})    
else
    % case is the data metrics
    eInd(2:3) = {1};
end    

%
updateCheckboxProps(handles,iSelT)

% updates the current sheet tab
hP = {handles.panelStatTest,handles.panelMetricData,handles.panelMetricInfo};
try; cellfun(@(x,y)(setPanelProps(x,eStr{1+y})),hP,eInd); end
setTimeUnitObjProps(handles,iSelT-1)
updateOrderList(handles);

% updates the data alignment radio buttons
set(handles.radioAlignVert,'value',iData.tData.alignV(iData.cTab,iSelT))
set(handles.radioAlignHorz,'value',~iData.tData.alignV(iData.cTab,iSelT))

% updates the table column properties
if (iSelT > 1)
    hTab = findall(handles.panelMetricInfo,'type','uitable','UserData',iSelT-1);
    updateTableColumnProp(hTab)
end

% updates the other formating checkbox values
updateOtherFormatCheck(handles,iData,1)
if (~isa(eventdata,'char'))
    updateSheetData(handles,false); 
    try; delete(h); end
end

% ---------------------------------------- %
% --- STATISTICAL TEST PANEL CALLBACKS --- %
% ---------------------------------------- %

% --- Executes when selected cell(s) is changed in tableStatTest.
function tableStatTest_CellSelectionCallback(hObject, eventdata, handles)

% if the indices are empty, then exit
if (isempty(eventdata.Indices)); return; end

% retrieves the row/column indices
hasTest = getappdata(handles.figDataOutput,'hasTest');
[jRow,iCol,eStr] = deal(eventdata.Indices(1),eventdata.Indices(2),{'off','on'});
iRow = hasTest(jRow);

% sets the table java object (if not set)
if isempty(getappdata(hObject,'jTable'))
    setappdata(hObject,'jTable',getJavaTable(hObject))
end

% only open set up the statistic test type if the correct column is
% selected
jTable = getappdata(hObject,'jTable');
if iCol == 3
    % retrieves the data struct
    [Data,updateSheet] = deal(get(hObject,'Data'),false);
    iData = getappdata(handles.figDataOutput,'iData');                         
    
    % retrieves the parameter string and data types    
    [pStr,pType] = deal(iData.yVar(iRow).Var,iData.pStats{jRow});
        
    % determined if a valid test type was selected
    [stData,cType,dForm] = runStatsTest(handles,pType,pStr,jRow);   
    if ~isempty(stData)
        % updates the data struct with the new statistical test info
        iData.Y{1}{jRow}{cType} = stData;
        iData.tData.stInd{iData.cTab}(jRow,:) = [cType,dForm];
                
        % if this the test is included, then update the order list
        iPara = iData.tData.iPara{iData.cTab}{1};
        if (Data{jRow,2})
            % resets the sheet update flag            
            updateSheet = true;
            if (~any(iPara{1} == jRow))
                % if the index is not included within the order array, then
                % add it to the order array
                iPara{1} = [iPara{1};jRow];
                iData.tData.iPara{iData.cTab}{1} = iPara;
            end
        end
        
        % updates the data alignment panel properties
        setPanelProps(handles.panelDataAlign,eStr{1+(length(iPara{1})>1)})
                
        % updates the data struct
        setappdata(handles.figDataOutput,'iData',iData);
        updateOrderList(handles);
        
        % sets the statistics string
        mStr = setStatTestString(iData,pType,jRow);
        if (iscell(mStr))
            Data{jRow,iCol} = mStr{1};
        else
            Data{jRow,iCol} = mStr;    
        end
        
        % updates the table string
        set(hObject,'Data',Data)
    end
    
    % removes the selection from the table and updates the current sheet tab
    jTable.changeSelection(-1,-1,false,false);  
    if (updateSheet); updateSheetData(handles,true); end    
else
    % removes the selection from the table
    jTable.changeSelection(-1,-1,false,false);
end

% ------------------------------------ %
% --- METRIC DATA OBJECT FUNCTIONS --- %
% ------------------------------------ %

% --- callback function for altering the sheet tabs
function changeMetricTab(hObject, eventdata, varargin)

% global variables
global canEditCell
canEditCell = false;

% imports the required java classes
import javax.swing.table.*

% retrieves the GUI handles
handles = guidata(hObject);
iData = getappdata(handles.figDataOutput,'iData');

% retrieves the original metric selection
iSel0 = iData.tData.iSel(iData.cTab);

% retrieves the required data arrays
if (nargin == 1)
    % retrieves the metric selection tab index
    [mSel,iSelNw] = deal(iData.tData.mSel(iData.cTab),1);
    hTab1 = findall(handles.panelMetricInfo,'type','uitable','UserData',mSel);
else     
    % sets the visibility of the genotype inclusion table
    mSel = get(eventdata.NewValue,'UserData');
    iData.tData.mSel(iData.cTab) = mSel;
    [iData.tData.iSel(iData.cTab),iSelNw] = deal(mSel + 1);
    setappdata(handles.figDataOutput,'iData',iData)    
    
    % hides the currently visible table
    hTab1 = findall(handles.panelMetricInfo,'type','uitable','UserData',mSel);    
    
    % retrieves the table object
    [jTab,Data] = deal(getappdata(hTab1,'jTable'),get(hTab1,'Data'));
    iPara = iData.tData.iPara{iData.cTab}{mSel+1};
    
    % sets the table inclusion flags
    isInc = false(size(Data,1),1);    
    if (~isempty(iPara{1}))
        isInc(iPara{1}(:,1)) = true;                 
    end
    Data(:,2) = num2cell(isInc);        
    
    % sets the secondary column strings
    if (mSel == 1)
        for i = reshape(find(isInc),1,sum(isInc))
            metInd = iData.tData.iPara{iData.cTab}{2}{2}(i,:);
            Data{i,3} = setMetricStatString(metInd);
        end
    end
    
    % updates the table values
    for i = 1:size(Data,1)
        for j = 2:(2+any(mSel == 1))
            jTab.setValueAt(Data{i,j},i-1,j-1);                                    
        end
    end
end

% determines if the spreadsheet has/requires data output
hasData = detIfHasData(iData,iSel0) || detIfHasData(iData,iSelNw);
updateCheckboxProps(handles)

% creates a loadbar figure
if ((nargin == 2) && (~isa(eventdata,'double')) && (hasData))
    h = ProgressLoadbar('Updating Data Table...');
end
    
% updates the data alignment radio buttons
set(handles.radioAlignVert,'value',iData.tData.alignV(iData.cTab,mSel+1))
set(handles.radioAlignHorz,'value',~iData.tData.alignV(iData.cTab,mSel+1))

% updates the table column properties
updateTableColumnProp(hTab1)
updateOrderList(handles);

% updates the sheet data
setTimeUnitObjProps(handles,mSel)

% updates the sheet data (if there is data)
if ((nargin == 2) && (~isa(eventdata,'double')) && (hasData))
    updateSheetData(handles,false); 
    try; close(h); end
else
    updateSheetInfo(handles,1)
end

% enables editing again
pause(0.2); 
canEditCell = true;

% --- Executes when entered data in the table objects
function tableCellEdit(hObject, eventdata)

% global variables
global canEditCell

% if the indices are empty, then exit
if ((isempty(eventdata.Indices)) || (~canEditCell))
    return; 
end

% retrieves the row index
[handles,eStr] = deal(guidata(hObject),{'off','on'});
[iRow,iCol] = deal(eventdata.Indices(1),eventdata.Indices(2));
iData = getappdata(handles.figDataOutput,'iData');
[nwVal,nwData,updateSheet] = deal(eventdata.NewData,[],false);

% sets the parameter index (based on the table that was editted)
if (get(hObject,'UserData') == 0)    
    % case is the statistical test table
    pInd = 1;
    if (~isnan(iData.tData.stInd{iData.cTab}(iRow,1)))
        nwData = iRow;
    end
else
    % case is the metric data table
    pInd = 1 + iData.tData.mSel(iData.cTab);
    switch (pInd)
        case (2) % case is the population metrics
            mInd = find(iData.tData.iPara{iData.cTab}{pInd}{2}(iRow,:))';
            nwData = [iRow*ones(length(mInd),1),mInd];
        case (4)
            if (iCol == 2)
                nwData = iRow;
            end
        otherwise % case is the other metrics
            nwData = iRow;
    end    
end 

% updates the order array
iPara = iData.tData.iPara{iData.cTab}{pInd};
if (iCol == 2)
    if (nwVal)
        % adds the indices associated with the metric
        if (~isempty(nwData))
            updateSheet = true;
            iPara{1} = [iPara{1};nwData];
        end
    else
        % ensures the statistical test type cell is empty
        if (pInd == 1)
            Data = get(handles.tableStatTest,'Data');
            Data{iRow,3} = '';
            set(handles.tableStatTest,'Data',Data);
        end
        
        % removes the indices associated with the metric
        if (~isempty(iPara{1}))
            updateSheet = any(iPara{1}(:,1) == iRow);
            iPara{1} = iPara{1}(iPara{1}(:,1) ~= iRow,:);
        end
    end
    
    % updates the data alignment panel properties
    if (get(handles.radioStatTest,'value'))        
        setPanelProps(handles.panelDataAlign,eStr{1+(length(iPara{1})>1)})        
    end
else
    % case is updating the SEM inclusion checkbox
    iPara{2}(iRow) = nwVal;    
    updateSheet = ~isempty(iPara{1});
end
    
% % updates the data alignment panel properties
% setPanelProps(handles.panelDataAlign,eStr{1+(length(iPara{1})>1)})

% updates the data struct
iData.tData.iPara{iData.cTab}{pInd} = iPara;
setappdata(handles.figDataOutput,'iData',iData);

% updates the current tab
updateOrderList(handles)
if (updateSheet); updateSheetData(handles,true); end

% --- Executes when selected cell(s) is changed in the metric table objects
function metTableCellSelect(hObject, eventdata)

% global variables
global canEditCell

% if the indices are empty, then exit
if ((isempty(eventdata.Indices)) || (~canEditCell))
    return; 
end

% initialisations
handles = guidata(hObject);
jTable = getappdata(hObject,'jTable');  
iData = getappdata(handles.figDataOutput,'iData');
snTot = getappdata(handles.figDataOutput,'snTot');
plotD = getappdata(handles.figDataOutput,'plotD');
metType = getappdata(handles.figDataOutput,'metType');

% retrieves the row/column indices
[iRow,iCol] = deal(eventdata.Indices(1),eventdata.Indices(2));
pInd = iData.tData.iSel(iData.cTab);

% sets the table java object (if not set)
if (isempty(getappdata(hObject,'jTable')))
    setappdata(hObject,'jTable',getJavaTable(hObject))
end

% only open set up the statistic test type if the correct column is
% selected
if ((iCol == 3) && (pInd == 2))
    % retrieves the data struct
    Data = get(hObject,'Data');                     

    % determined if a valid test type was selected
    [metInd,isChange] = MetricStats(iData,iRow,pInd);      
    if (isChange)
        % retrieves the order and metric index arrays        
        [iOrder,mIndF] = deal(iData.tData.iPara{iData.cTab}{pInd}{1},find(metInd)');        
                
        % determines which of the indices (which were previously set) have
        % been included in the new selection. remove those that are missing
        if (Data{iRow,2})
            [ok1,ok2] = deal(iOrder(:,1) ~= iRow,find(iOrder(:,1) == iRow));                
            ok1(ok2) = cellfun(@(x)(any(x==mIndF)),num2cell(iOrder(ok2,2)));

            % resets the metric index array (removes any which have already
            % been set previously)
            ok3 = cellfun(@(x)(~any(x==iOrder(ok2,2))),num2cell(mIndF));
            mIndF = mIndF(ok3);

            % sets the final permutation array
            iOrder = [iOrder(ok1,:);[iRow*ones(length(mIndF),1),mIndF]];
            iData.tData.iPara{iData.cTab}{pInd}{1} = iOrder;
        end        
        
        % resets the metric indices
        iData.tData.iPara{iData.cTab}{pInd}{2}(iRow,:) = metInd;
        iData = calcStatMetricsPop(snTot,iData,plotD,metType(:,1),iRow);                       
        setappdata(handles.figDataOutput,'iData',iData);
        
        % updates the table string
        mStr = setMetricStatString(metInd);
        if (iscell(mStr))
            Data{iRow,iCol} = mStr{1};
        else
            Data{iRow,iCol} = mStr;
        end
        set(hObject,'Data',Data)
        
        % updates the order list
        updateOrderList(handles)
    end    
    
    % updates the current sheet tab    
    updateSheetData(handles,true);   
end    

% removes the selection
jTable.changeSelection(-1,-1,false,false);

% --- Executes on selection change in popupUnits.
function popupUnits_Callback(hObject, eventdata, handles)

% retrieves the data struct
iData = getappdata(handles.figDataOutput,'iData');

% updates the worksheet tab (if there is any data)
if (detIfHasData(iData))
    updateSheetData(handles,true)
end

% ----------------------------------- %
% --- DATA TAB CALLBACK FUNCTIONS --- %
% ----------------------------------- %

% --- callback function for altering the sheet tabs
function changeInfoTab(hObject, eventdata)

% retrieves the GUI handles
[handles,showTable] = deal(guidata(hObject),false(2,1));
iData = getappdata(handles.figDataOutput,'iData');

% sets the visibility of the genotype inclusion table
switch get(eventdata.NewValue,'Title')
    case ('Genotype Groups') % case is the genotyp groups        
        [iData.incTab,showTable(1)] = deal(1,true);
    case ('Experiment Output') % case is the experiment output        
        [iData.incTab,showTable(2)] = deal(3,true);
    otherwise
        iData.incTab = 2;
end

% updates the table data
setappdata(handles.figDataOutput,'iData',iData)

% --- Executes when entered data in editable cell(s) in tableGroupInc.
function tableGroupInc_CellEditCallback(hObject, eventdata, handles)

% global variables
global nMetG

% if the indices are empty, then exit
if (isempty(eventdata.Indices)); return; end
iData = getappdata(handles.figDataOutput,'iData');

% retrieves the row/column indices
iData.appOut(eventdata.Indices(1),iData.cTab) = eventdata.NewData;
[Y,xStr] = deal(iData.appOut(:,iData.cTab),'genotype group');
hChk = handles.checkSepByApp;

% determins if any of the inclusion indices have been set
if (~any(Y))
    % if not, then output an error
    eStr = sprintf('Error! Data output must include at least one %s.',xStr);
    waitfor(errordlg(eStr,'Output Selection Error','modal'))    
    
    % resets the table
    Data = get(hObject,'Data');
    Data{eventdata.Indices(1),2} = true;
    set(hObject,'Data',Data)
else    
    % updates the enabled properties of the checkbox
    [iSel,iSelT] = getSelectedIndexType(handles);
    [uData,eStr] = deal(isempty(get(hChk,'UserData')),{'off','on'});   
    
    % resets the checkbox enabled properties
    isOK = (iSel==2) && all(iSelT ~= [5 6 nMetG]) && uData && (sum(Y) > 1);        
    setObjEnable(hChk,isOK)        
    
    % updates the checkbox flag and array value (if not ok)
    if (~isOK)
        % removes the check label for the separation                 
        mSel = iData.tData.mSel(iData.cTab);
        iData.tData.altChk{iData.cTab}{mSel}(get(hChk,'Max')) = false;
        set(hChk,'value',0)
    end
    
    % otherwise, update the data struct
    setappdata(handles.figDataOutput,'iData',iData)     
    
    % sets the alignment button enabled properties
    checkOtherFormat(handles.checkSepByApp,'1')          
    
    % updates the sheet data
    if (detIfHasData(iData)); updateSheetData(handles,true); end
end

% --- Executes when entered data in editable cell(s) in tableExptInc.
function tableExptInc_CellEditCallback(hObject, eventdata, handles)

% if the indices are empty, then exit
if (isempty(eventdata.Indices)); return; end
iData = getappdata(handles.figDataOutput,'iData');

% retrieves the row/column indices
iData.expOut(eventdata.Indices(1),iData.cTab) = eventdata.NewData;
[Y,xStr] = deal(iData.expOut(:,iData.cTab),'experiment');
hChk = handles.checkSepByExpt;

% determins if any of the inclusion indices have been set
if (~any(Y))
    % if not, then output an error
    eStr = sprintf('Error! Data output must include at least one %s.',xStr);
    waitfor(errordlg(eStr,'Output Selection Error','modal'))    
    
    % resets the table
    Data = get(hObject,'Data');
    Data{eventdata.Indices(1),2} = true;
    set(hObject,'Data',Data)
else    
    % updates the enabled properties of the checkbox
    [uData,eStr] = deal(isempty(get(hChk,'UserData')),{'off','on'});

    % resets the checkbox enabled properties
    isOK = uData && (sum(iData.expOut(:,iData.cTab)) > 1);
    setObjEnable(hChk,isOK)        
    
    % updates the checkbox flag and array value (if not ok)
    if ~isOK
        % removes the check label for the separation                 
        mSel = iData.tData.mSel(iData.cTab);
        iData.tData.altChk{iData.cTab}{mSel}(get(hChk,'Max')) = false;
        set(hChk,'value',0)
    end
            
    % otherwise, update the data struct
    setappdata(handles.figDataOutput,'iData',iData)    
    
    % updates the sheet data
    if (detIfHasData(iData)); updateSheetData(handles,true); end
end

% --------------------------------------- %
% --- OTHER DATA FORMATTING FUNCTIONS --- %
% --------------------------------------- %

% --- Executes when selected object is changed in panelDataAlign.
function panelDataAlign_SelectionChangeFcn(hObject, eventdata, handles)

% determines which button is currently selected
hR = findall(handles.panelDataAlign,'style','radiobutton','value',1);
alignV = strcmp(get(hR,'tag'),'radioAlignVert');

% updates the numeral grouping flags
iData = getappdata(handles.figDataOutput,'iData');
iData.tData.alignV(iData.cTab,iData.tData.iSel(iData.cTab)) = alignV;
setappdata(handles.figDataOutput,'iData',iData)

% updates the worksheet data
if (detIfHasData(iData)); updateSheetData(handles,true); end

% --- Other format checkbox callback function
function checkOtherFormat(hObject,eventdata)

% retrieves the selection type
[handles,iType] = deal(guidata(hObject),get(hObject,'Max'));
iData = getappdata(handles.figDataOutput,'iData');

% sets the metric parameter index
iSel = iData.tData.iSel(iData.cTab);

% updates the numeral grouping flags
iData.tData.altChk{iData.cTab}{iSel}(iType) = get(hObject,'value');
setappdata(handles.figDataOutput,'iData',iData)

% updates the alignment radio buttons
hR = findall(handles.panelDataAlign,'style','radiobutton');
switch (get(hObject,'tag'))
    case ('checkSepByApp')
        if iSel ~= 1
            isOK = (get(hObject,'Value')>0) && ...
                    strcmp(get(hObject,'enable'),'on');    
            setObjEnable(hR,isOK);
        end
        
    case ('checkSepByExpt')
        resetExptTabProps(handles,iData,get(hObject,'Value')>0)
end

% updates the sheet data
if ((~isa(eventdata,'char')) && (detIfHasData(iData,iSel)))
    updateSheetData(handles,true)
end

% ----------------------------------- %
% --- LIST ORDER OBJECT FUNCTIONS --- %
% ----------------------------------- %

% --- Executes on selection change in listMetricOrder.
function listMetricOrder_Callback(hObject, eventdata, handles)

% updates the button properties
updateButtonProps(handles)

% --- Executes on button press in buttonMoveDown.
function buttonMoveDown_Callback(hObject, eventdata, handles)

% global variables
global nMet

% initialisations
iData = getappdata(handles.figDataOutput,'iData');
iSel = get(handles.listMetricOrder,'value');
iOrder = iData.tData.iPara{iData.cTab}{iData.tData.iSel(iData.cTab)}{1};

if (size(iOrder,2) == 2)
    ii = iOrder(:,2) ~= nMet;
    [iOrder,iOrderN] = deal(iOrder(ii,:),iOrder(~ii,:));
else
    iOrderN = [];
end

% reorders the array
[jj,ii] = deal(setGroup(iSel,[size(iOrder,1),1]),(1:size(iOrder,1))');
iGrp = getGroupIndex(jj);
ii(cell2mat(iGrp)) = cell2mat(iGrp) + 1;
ii(cellfun(@(x)(x(end)+1),iGrp)) = cellfun(@(x)(x(1)),iGrp);
[~,kk] = sort(ii);

% updates the list strings
lStr = get(handles.listMetricOrder,'string');
[lStr,iOrder] = deal(lStr(kk),[iOrder(kk,:);iOrderN]);

% updates the listbox and button properties
set(handles.listMetricOrder,'string',lStr,'value',iSel+1)
updateButtonProps(handles)

% updates the permutation order array
iData.tData.iPara{iData.cTab}{iData.tData.iSel(iData.cTab)}{1} = iOrder;
setappdata(handles.figDataOutput,'iData',iData);

% updates the worksheet data
updateSheetData(handles,true)

% --- Executes on button press in buttonMoveUp.
function buttonMoveUp_Callback(hObject, eventdata, handles)

% global variables
global nMet

% initialisations
iData = getappdata(handles.figDataOutput,'iData');
iSel = get(handles.listMetricOrder,'value');
iOrder = iData.tData.iPara{iData.cTab}{iData.tData.iSel(iData.cTab)}{1};

if (size(iOrder,2) == 2)
    ii = iOrder(:,2) ~= nMet;
    [iOrder,iOrderN] = deal(iOrder(ii,:),iOrder(~ii,:));
else
    iOrderN = [];
end

% reorders the array
[jj,ii] = deal(setGroup(iSel,[size(iOrder,1),1]),(1:size(iOrder,1))');
iGrp = getGroupIndex(jj);
ii(cell2mat(iGrp)) = cell2mat(iGrp) - 1;
ii(cellfun(@(x)(x(1)-1),iGrp)) = cellfun(@(x)(x(end)),iGrp);
[~,kk] = sort(ii);

% updates the list strings
lStr = get(handles.listMetricOrder,'string');
[lStr,iOrder] = deal(lStr(kk),[iOrder(kk,:);iOrderN]);

% updates the listbox and button properties
set(handles.listMetricOrder,'string',lStr,'value',iSel-1)
updateButtonProps(handles)

% updates the permutation order array
iData.tData.iPara{iData.cTab}{iData.tData.iSel(iData.cTab)}{1} = iOrder;
setappdata(handles.figDataOutput,'iData',iData);

% updates the worksheet data
updateSheetData(handles,true)

% ------------------------------------- %
% --- DATA TABLE CALLBACK FUNCTIONS --- %
% ------------------------------------- %

% --- callback function for altering the sheet tabs
function changeDataTab(hObject, eventdata)

% retrieves the GUI handles
handles = guidata(hObject);
hTabGrp = findall(handles.panelDataOuter,'tag','sheetTabGrp');
iData = getappdata(handles.figDataOutput,'iData');

% determines if a new tab has to be added 
addTab = strcmp(get(eventdata.NewValue,'Title'),'+');

% determines which tab was selected
if (addTab)
    % selected tab was the addition tab
    addDataTab(handles,hTabGrp)      
else
    % retrieves the new and set tab user data values
    uDataS = cellfun(@(x)(get(x,'UserData')),iData.tData.hTab(1:end-1),'un',0);
    uDataN = get(eventdata.NewValue,'UserData');
    
    % determines the new the tab index
    [mSel0,cTab0] = deal(iData.tData.mSel(iData.cTab),iData.cTab);
    [iData.cTab,cTab1] = deal(find(cell2mat(uDataS) == uDataN));
    setappdata(handles.figDataOutput,'iData',iData);    
    
    % stops the cell editor (if editting)
    hTab0 = getSheetTableHandle(handles,cTab0);
    hSP0 = findall(handles.panelDataOuter,'tag','hSP','UserData',cTab0);
    hTab1 = getSheetTableHandle(handles,cTab1);
    hSP1 = findall(handles.panelDataOuter,'tag','hSP','UserData',cTab1);
    
    % updates the table properties
    updateTableProperties(handles)
    
    % stops the cell editor (if editting)
    jTab0 = getappdata(hTab0,'jTable');
    if (~isempty(jTab0))
        if (jTab0.isEditing)
            jTab0.getCellEditor().stopCellEditing();
            pause(0.05);
        end    
    end
    
    % changes the visibility of the tables
    setObjVisibility(hTab0,'off'); 
    setObjVisibility(hSP0,'off'); 
    setObjVisibility(hTab1,'on');                   
    setObjVisibility(hSP1,'on');                   
    drawnow; pause(0.05);
        
    % updates the metric tab selection
    hTabGrpM = findall(handles.panelMetricInfo,'tag','metricTabGrp');
    hTabM = get(hTabGrpM,'Children');
    
    % updates the metric selection tab
    uDataM = get(hTabM,'UserData');
    if iscell(uDataM); uDataM = cell2mat(uDataM); end

    % updates the selected tab
    i1 = find(uDataM==iData.tData.mSel(iData.cTab));
    updateTabSelection(hTabGrpM,i1);
    
    % sets the worksheet information
    if iData.tData.iSel(iData.cTab) == 1
        changeMetricTab(hTabGrpM)
    else
        changeMetricTab(hTabGrpM, struct('NewValue',hTabM(i1)), 1)
    end
end

% resets the button properties
set(handles.listMetricOrder,'value',[])
updateButtonProps(handles)

% --- updates the table properties for the currently selected worksheet tab
function updateTableProperties(handles)

% global variables
global nMet nMetG

% initialisations
iData = getappdata(handles.figDataOutput,'iData');

% initialisations
cTab = iData.cTab;
iPara = iData.tData.iPara{cTab};
mInd = [find(any(getappdata(handles.figDataOutput,'metType'),1)),(nMetG-1)];

% updates the statistical test table (if required)
if (iData.metStats)
    % resets the table data
    Data = get(handles.tableStatTest,'Data');
    [Data(:,2),Data(:,3)] = deal({false},{''});
    Data(iPara{1}{1},2) = {true};

    % resets the valid statistical test strings
    stInd = iData.tData.stInd{cTab};
    for i = 1:size(stInd,1)
        if (~isnan(stInd(i,1)))
            Data{i,3} = setStatTestString(iData,iData.pStats{i},i);
        end
    end
    
    % updates the table data with the new values
    set(handles.tableStatTest,'Data',Data);           
end

% updates the metric data tables (for each valid metric + parameters)
for i = mInd
    % retrieves the table handle and the table data
    hTable = findall(handles.panelMetricInfo,'Type','uitable','UserData',i);
    Data = get(hTable,'Data');
    
    % resets the table data entries
    Data(:,2) = {false};    
    switch (i)
        case (1)
            % updates the selected metric checkboxes
            if (~isempty(iPara{i+1}{1}))
                sInd = iPara{i+1}{1}(iPara{i+1}{1}(:,2) < nMet,1);                       
                Data(sInd,2) = {true};            
            end
            
            % updates the metric strings
            metInd = num2cell(iPara{2}{2},2);
            Data(:,3) = cellfun(@(x)(setMetricStatString(x)),metInd,'un',0);
        case (4)
            Data(iPara{i+1}{1},2) = {true};
        otherwise
            Data(iPara{i+1}{1},2) = {true};
    end
    
    % resets the table data
    set(hTable,'Data',Data);
end

% updates the group inclusion flags table
DataG = get(handles.tableGroupInc,'Data');
DataG(:,2) = num2cell(iData.appOut(:,iData.cTab));
set(handles.tableGroupInc,'Data',DataG)

% updates the experiment inclusion flags table (if required)
try
    DataE = get(handles.tableExptInc,'Data');
    DataE(:,2) = num2cell(iData.expOut(:,iData.cTab));
    set(handles.tableExptInc,'Data',DataE)
end

% --- callback function for adding a sheet tab
function addDataTab(handles,hTabGrp)

% global variables
global nChk nMetG
 
% updates the parameter struct
iData = getappdata(handles.figDataOutput,'iData');
metType = getappdata(handles.figDataOutput,'metType');
a = cell(1,nMetG);

% makes the currently visible sheet invisible
setObjVisibility(getSheetTableHandle(handles),'off');

% determines the selected radio button
hRS = findall(handles.panelInfoOuter,'style','radiobutton','value',1);
hRS = hRS(~cellfun(@isempty,get(hRS,'UserData')));

% enables the delete/move tab menu items
if iData.nTab == 1
    setObjEnable(handles.menuDeleteTab,'on')
    setObjEnable(handles.menuMoveTab,'on')
end

% resets the data struct fields
iData.tData.Name{end+1} = getUniqueTabName(iData.tData.Name);
iData.tData.Data = [iData.tData.Data;{a}];
iData.tData.DataN = [iData.tData.DataN;{a}];
iData.tData.iPara{end+1} = addOrderArray(metType);
iData.tData.iSel(end+1) = get(hRS,'UserData');
iData.tData.mSel(end+1) = iData.tData.mSel(iData.cTab);
iData.tData.mInd{end+1} = cell(1,nMetG);
iData.tData.stInd{end+1} = NaN(size(iData.tData.stInd{1}));
iData.tData.altChk{end+1} = repmat({false(1,nChk)},1,nMetG);
iData.tData.alignV = [iData.tData.alignV;true(1,nMetG)];
iData.appOut = [iData.appOut,true(size(iData.appOut,1),1)];
iData.expOut = [iData.expOut,true(size(iData.expOut,1),1)];
% iData.stData = [iData.stData,cell(size(iData.stData,1),1)];
[iData.nTab,iData.cTab] = deal(iData.nTab + 1);

% updates the tab fields
hTable = createTabTable(handles.panelDataOuter,iData.nTab,iData.tData.hTab{end});

% creates the new tab
iData.tData.hTab{end+1} = createNewTabPanel(hTabGrp,1,'Title','+');
set(hTable,'Parent',iData.tData.hTab{end-1});
setappdata(handles.figDataOutput,'iData',iData);

% resets the user data/title fields
set(iData.tData.hTab{end},'UserData',iData.nTab+1);
set(iData.tData.hTab{end-1},'Title',iData.tData.Name{end});

% sets the worksheet information
changeDataTab(hTabGrp, struct('NewValue',iData.tData.hTab{end-1}))
updateSheetInfo(handles)  

% --- Executes on key press with focus on the table sheet
function tableDataSheetCallback(hObject, eventdata, handles)

% retrieves the data struct
handles = guidata(hObject);
iData = getappdata(handles.figDataOutput,'iData');
iSel = iData.tData.iSel(iData.cTab);
Data = iData.tData.Data{iData.cTab};

% sets the table java object (if not set)
jTab = getappdata(hObject,'jTable');
[iRow,iCol] = deal(jTab.getSelectedRows,jTab.getSelectedColumns);                        
mType = detKeyModifierType(eventdata.Modifier);

% sets the row/column indices
switch (eventdata.Key)
    case {'delete','backspace'} % case is deleting a cell        
        % retrieves the manual alteration index and tab sheet data arrays
        mInd = iData.tData.mInd{iData.cTab}{iSel};          
        ii = true(size(mInd,1),1);
        
        % updates the data table
        for i = reshape(iRow,1,length(iRow))
            for j = reshape(iCol,1,length(iCol))            
                % updates the sheet and data sheet arrays
                jTab.setValueAt('',i,j);                                    
                Data{i+1,j+1} = '';
                
                % determines if there is a matching manual index value
                if (~isempty(mInd))
                    ii = ii & ~((mInd(:,1)==i) & (mInd(:,2)==j));
                end
            end
        end        
        
        % updates the tab sheet fields
        iData.tData.mInd{iData.cTab}{iSel} = mInd(ii,:);
        iData.tData.Data{iData.cTab} = Data;
    case ('uparrow') % case is the up arrow       
        % performs the action based on the modifier
        switch (mType)                
            case (12) % case is the control + shift modifier 
                jTab.setRowSelectionInterval(0, iRow(end));
        end
    case ('downarrow') % case is the down arrow
        % performs the action based on the modifier
        switch (mType)
            case (12) % case is the control + shift modifier 
                jTab.setRowSelectionInterval(iRow(1), size(Data,1)-1);
        end        
    case ('leftarrow') % case is the left arrow
        % performs the action based on the modifier
        switch (mType)
            case (12) % case is the control + shift modifier 
                jTab.setColumnSelectionInterval(0, iCol(end));
        end                
    case ('rightarrow') % case is the right arrow
        % performs the action based on the modifier
        switch (mType)
            case (12) % case is the control + shift modifier 
                jTab.setColumnSelectionInterval(iCol(1), size(Data,2)-1);
        end        
end

% updates the data struct in the GUI
setappdata(handles.figDataOutput,'iData',iData)

% --- Executes when entered data in editable cell(s) in the table DataSheet.
function dataSheetEdit(hObject, eventdata, handles)

% retrieves the GUI object handles
handles = guidata(findall(0,'tag','figDataOutput'));

% retrieves the data struct fields
iData = getappdata(handles.figDataOutput,'iData');
iSel = iData.tData.iSel(iData.cTab);
mInd = iData.tData.mInd{iData.cTab}{iSel};

% retrieves the row/column indices
jTab = getappdata(getSheetTableHandle(handles),'jTable');
[iRow,iCol] = deal(eventdata.getFirstRow,eventdata.getColumn);

% retrieves the new values from the cell
[nwVal,mIndNw] = deal(jTab.getValueAt(iRow,iCol),[iRow,iCol]);
      
% determines if the manual editting indices need to be updated
if (isempty(nwVal))
    % cell is being cleared, so determines if a matching index needs to
    % be removed from the index array
    if (~isempty(mInd))
        ii = cellfun(@(x)(~isempty(jTab.getValueAt(x(1),x(2)))),num2cell(mInd,2));
        mInd = mInd(ii,:);
    end
else
    % cell is being added, so determined if a new index needs to be
    % added to the index array        
    if (isempty(mInd))
        % manual index array is empty, so add the new value
        mInd = mIndNw;
    elseif (~any(cellfun(@(x)(isequal(mIndNw,x)),num2cell(mInd,2))))
        % otherwise, if the new indices is not included in the index
        % array then append the new values to the array
        mInd = [mInd;mIndNw];
    end
    
    % updates the string within the sheet data array
    iData.tData.Data{iData.cTab}{iSel}{mIndNw(1)+1,mIndNw(2)+1} = nwVal;
end

% updates the data struct
iData.tData.mInd{iData.cTab}{iSel} = mInd;
setappdata(handles.figDataOutput,'iData',iData)
   
% --- determines the unique data tab name
function tNameNw = getUniqueTabName(tName0)

% determines the current number of tabs
nTab = length(tName0) + 1;

% keep incrementing the tab counter until a feasible name has been found
while (1)
    tNameNw = sprintf('Sheet %i',nTab);
    if (~any(strcmp(tName0,tNameNw)))
        % unique name has been found so exit
        break
    else
        % name is not unique, so increment the counter
        nTab = nTab + 1;
    end
end

% --- 
function viewAdjuctFunc(hObject,eventdata,Data,jView,jTM,rSz,cTab,Type)

% global variables
global iRowD iColD

% retrieves the table handle. if not available exit the function
try
    jTab = jView.getComponent(0); 
catch
    return
end

% retrieves the current position of the 
[vP,vSz] = deal(jView.getViewPosition,jView.getSize);

% sets the rows/columns of the table that are currently visible
iCol = setDataTableIndices(vP.x,rSz.width,vSz.width,size(Data,2),5);
iRow = setDataTableIndices(vP.y,rSz.height,vSz.height,size(Data,1),50);

% compares the previous row/column indices to the new ones
if isequal(iRowD{cTab},iRow) && isequal(iColD{cTab},iCol)
    % if there is no change in the row/column indices, then exit
    return
else
    % otherwise, determine the row/column indices that need to
    % be added/removed
    [iCellC,iCellR] = deal(jTab.getSelectedColumn,jTab.getSelectedRow);
    if Type == 1
        [iColA,iColR] = deal(iCol);
        iRowA = setdiff(iRow,iRowD{cTab});
        iRowR = setdiff(iRowD{cTab},iRow);
        
        [rowLo,rowHi] = calcIndLim(vP.y,rSz.height,vSz.height);
        if iCellR <= rowLo
            resetSelectedCell(jTab, rowLo, iCellC);
        elseif iCellR >= (rowHi-1)
            resetSelectedCell(jTab, rowHi-2, iCellC);
        end        
    else
        [iRowA,iRowR] = deal(iRow);
        iColA = setdiff(iCol,iColD{cTab});
        iColR = setdiff(iColD{cTab},iCol);
        
        [colLo,colHi] = calcIndLim(vP.x,rSz.width,vSz.width);
        if iCellC <= colLo
            resetSelectedCell(jTab, iCellR, colLo);
        elseif iCellC >= (colHi-1)
            resetSelectedCell(jTab, iCellR, colHi-2);
        end
    end
end
    
% removes the table update callback function
addJavaObjCallback(jTM,'TableChangedCallback',[])

% sets the new values into the sheet
for i = 1:length(iRowA)
    for j = 1:length(iColA)
        jTab.setValueAt(Data{iRowA(i)+1,iColA(j)+1},iRowA(i),iColA(j)); 
    end
end

% removes the extraneous values from the sheet
for i = 1:length(iRowR)
    for j = 1:length(iColR)
        jTab.setValueAt([],iRowR(i),iColR(j)); 
    end
end

% updates the current row/column indices
[iRowD{cTab},iColD{cTab}] = deal(iRow,iCol);

% resets the table update callback function
addJavaObjCallback(jTM,'TableChangedCallback',@dataSheetEdit)

% --- 
function resetSelectedCell(jTab,iRow,iCol)

% if editting, then stop editting
if (jTab.isEditing()) 
    jTab.getCellEditor().stopCellEditing();
end

% toggles the cell selection
jTab.changeSelection(iRow, iCol, false, false);

% --- sets the row/column indice array
function ind = setDataTableIndices(x0,rSz,vSz,mxSz,del)

[dimLo,dimHi] = calcIndLim(x0,rSz,vSz);
ind = max(0,dimLo-del):min(mxSz-1,dimHi+del);

function [dimLo,dimHi] = calcIndLim(x0,rSz,vSz)

dimLo = floor(x0/rSz);
dimHi = ceil((x0+vSz)/rSz);

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% ---------------------------------- %
% --- STATISTICAL TEST FUNCTIONS --- %
% ---------------------------------- %

% --- sets up the statistical test result data array
function AT = setupStatsDataArray(handles,iData,pData,plotD,stData,dForm,iRow)

% global variables
global pTolT

% other initialisations
hasTest = getappdata(handles.figDataOutput,'hasTest');
[sStr,tStr] = deal({'NS','S'},pData.appName');
[jRow,aOut] = deal(hasTest(iRow),find(iData.appOut(:,iData.cTab)));           
[pStrS,Type] = deal(stData.pStr,stData.Type);
[mStr,Stats] = deal(iData.fName{jRow},pData.oP.yVar(jRow).Stats);

% sets the x variable strings
if ((length(Stats) > 1) && (~strcmp(Stats{1},'FixedComp')))
    X1 = eval(sprintf('plotD(1).%s',Stats{2}));
else
    X1 = [];
end

% if there is no statistical test data, then exit the function
if (iData.sepGrp)
    % sets the 2nd x-variable strings
    X2 = eval(sprintf('plotD(1).%s',Stats{3}));
    nGrp1 = length(X1);
    
    % sets the header strings
    tStr0 = cell2cell(cellfun(@(y)(cellfun(@(x)(sprintf('%i (%s)',y,x)),...
                    X2,'un',0)),num2cell(1:nGrp1),'un',0),0)';
elseif (isempty(pStrS))
    % no header strings available
    tStr0 = [];
else
    % sets the header strings
    tStr0 = cellfun(@(x)(sprintf('%i',x)),...
                    num2cell(1:size(pStrS{1},1)),'un',0)';
end

% sets the number of Y-groups        
if (isfield(stData,'isSig'))
    nGrpY = size(stData.isSig,1)/length(pData.appName);            
else
    nGrpY = [];
end
            
% sets the dependency parameter string
if (length(iData.pType{iRow}) < 2)
    % none set, so use empty dependency string
    tStr = [];
else
    % otherwise, retrieve the dependency string
    
end
    
% sets the corrected signficance p-level
if (strcmp(stData.Type,'FixedComp'))
    pTol = stData.pTol;
else
    switch (stData.Test)
        case ('K-W') % case is Dunn-Sidak coefficient (for K-W test)
            if (iscell(stData.p(aOut,1)))
                nGrp = sum(cellfun(@(x)(size(x,1)),stData.p(aOut,1)));
            else
                nGrp = length(stData.p(aOut,1));
            end
                
            pTol = 1 - (power((1-pTolT),1/(nGrp*(nGrp-1)*0.5)));        
        case {'ANOVA'} % case is ANOVA test significance level
            pTol = pTolT;
        case {'T-Test','Z-Test'}
            pTol = stData.pTol;
    end
end
    
% sets the data based on the test type
switch (stData.Type)
    case {'Comp','CompSumm'} % case is a group comparison
        % sets the header strings
        hStr = {'Metric Name',mStr;...
                'P-Significance',getSignificanceString(pTol);...
                'Test Name',stData.Test};                                   
            
        % sets the significance strings
        pStrS = stData.pStr(aOut,aOut);
        sStrS = sStr((stData.p(aOut,aOut) <= pTol) + 1);
        
        % sets the title string        
        if (iData.tData.altChk{iData.cTab}{1}(4))
            % using numeral strings
            tStr = tStr0;
        else        
            % using the binned group strings
            tStr = iData.appName(iData.appOut(:,iData.cTab))';
        end
        
    case ('CompMulti') % case is a multi-group comparison             
        % sets the header strings
        hStr0 = {'Metric Name',mStr;...
                 'P-Significance',getSignificanceString(pTol);...
                 'Test Name',stData.Test};  
        if (nGrpY == 1)
            hStr1 = [{'Group Name'},pData.appName(aOut)'];            
            hStr2 = combineCellArrays(hStr0,hStr1,0);
            hStr = combineCellArrays({NaN},hStr2);
        else
            hStr0 = cellfun(@(x)([{'Group Type',x};hStr0]),...
                                 pData.appName(aOut),'un',0);
                             
            % creates the header strings for each of the genotype groups
            [hStr,b] = deal({NaN,NaN},num2cell(NaN(1,size(stData.p{1,1},1)-1)));
            for i = 1:length(hStr0)
                hStr = combineCellArrays(combineCellArrays(hStr,hStr0{i}),b);
            end                                  
        end             
        
        % sets the significance strings
        sStrS = sStr((cell2mat(stData.p(aOut,aOut)) <= pTol) + 1);
        pStrS = cell2cell(cellfun(@(x)(cell2cell(x)'),...
                    num2cell(stData.pStr(aOut,aOut),1),'un',0));                                                        
               
        % sets the title string
        if (iData.tData.altChk{iData.cTab}{1}(4))
            % using numeral strings
            tStr = tStr0;
        else
            % using the binned group strings
            tStr = eval(sprintf('plotD.%s',iData.pStats{iRow}{2}));
        end
    
    case {'TTest','ZTest','TTestGroup','ZTestGroup'} % case is a day/night T-/Z-test
        % sets the header strings
        hStr = {'Metric Name',mStr;...
                'P-Significance',getSignificanceString(pTol);...
                'Test Name',stData.Test};

        % sets the significance strings
        [A,B] = deal(stData.pStr(aOut,aOut),stData.p(aOut,aOut));
        pStrS = cell2cell(cellfun(@(x)(cell2cell(x)),num2cell(A,1),'un',0),0);
        pValS = cell2cell(cellfun(@(x)(cell2cell(x)),num2cell(B,1),'un',0),0);        
        sStrS = sStr((pValS <= pTol) + 1);

        % sets the title string
        if (iData.tData.altChk{iData.cTab}{1}(4))
            % using numeral strings
            tStr = tStr0;
        else
            % using the binned group strings
            if (length(iData.pStats{iRow}) > 1)
                tGrp = eval(sprintf('plotD.%s',iData.pStats{iRow}{2}))';                
                if (iData.sepGrp)
                    tStr = cell2cell(cellfun(@(y)(cellfun(@(x)(...
                            sprintf('%s (%s)',y,x)),X2,...
                            'un',0)),tGrp,'un',0),0)';
                else
                    if (isnumeric(tGrp)); tGrp = num2cell(tGrp); end
                    tStr = tGrp;
                end                
            else
                tStr = [];
            end            
        end

    case ('FixedComp') % case is a fixed value comparison  
        % sets the header strings
        [hStr,dForm] = deal([{'Metric Name'},mStr],-dForm);
        hStr = combineCellArrays(hStr,[{'P-Significance'},getSignificanceString(pTol)],0);                        
        hStr = combineCellArrays(hStr,[{'Fixed Value'},stData.fxVal],0);
        hStr = combineCellArrays(hStr,[{'Test Name'},stData.Test'],0);                                
        
        % sets the significance strings
        [pStrS,sStrS] = deal(stData.pStr,sStr(stData.isSig+1));
        
    case {'Sim','SimDN'} % case is the raw only similarity matrics
        % sets the header strings
        hStr = {'','';'Metric Name',mStr;'Values Type','Raw'};  
        
        % sets the group strings
        tStr = eval(sprintf('plotD(1).%s',iData.pStats{iRow}{2}));
        tStr = cell2cell(tStr(aOut));
             
        % ensures only the values are being output
        pStrS = cell2cell(pStrS{dForm}(aOut,aOut));
        [pStrS,dForm] = deal(combineCellArrays(pStrS,{NaN}),1);        
        
    case {'SimNorm','SimNormDN'} % case is the raw/normalized similarity matrics
        % sets the value type strings
        vtStr = {'Raw','Normalised'};
        
        % sets the header strings
        hStr = {'','';'Metric Name',mStr;...
                'Values Type',vtStr{dForm}};  
        
        % sets the group strings
        tStr = eval(sprintf('plotD(1).%s',iData.pStats{iRow}{2}));
        tStr = cell2cell(tStr(aOut));
             
        % ensures only the values are being output
        pStrS = cell2cell(pStrS{dForm}(aOut,aOut));
        [pStrS,dForm] = deal(combineCellArrays(pStrS,{NaN}),1);
        
    case ('GOF') % case is the goodness-of-fit metrics
        % sets the header string
        [hStr,dForm] = deal({'','';'Metric Name',mStr},0);
                
        % retrieves the data strings       
        pStrS = cellfun(@(x)([stData.mStr,x]),stData.gofY,'un',0);
        
        % sets the 2nd dependecy string (if is exists)
        if (length(Stats) > 2)
            tStr2 = eval(sprintf('plotD(1).%s',Stats{3}));
            for i = 1:size(pStrS,1)
                for j = 1:size(pStrS,2)
                    pStrS{i,j}{1,1} = tStr2{i};
                end
            end
        end
end

% adds gap underneath the title strings 
AT = combineCellArrays(hStr,{NaN},0);    

% if using P-value output, set up the array strings
if (any(abs(dForm) == [0 1 3]))
    if (dForm > 0)
        pStrS(logical(eye(size(pStrS)))) = {'N/A'};
    end
        
    AP = setStatStringArray(iData,pData,pStrS,tStr,Type,nGrpY);                                 
    AT = combineCellArrays(AT,AP,0);
end

% if using significance string output, set up the array strings
if (any(abs(dForm) == [2 3]))    
    if (dForm > 0)
        sStrS(logical(eye(size(sStrS)))) = {'N/A'};
    end
        
    AS = setStatStringArray(iData,pData,sStrS,tStr,Type,nGrpY);                                                            
    AT = combineCellArrays(AT,AS,0);
end

% sets empty strings into the empty cells
AT(cellfun(@isempty,AT)) = {''};

% --- sets the final statistic test string arrays
function A = setStatStringArray(iData,pData,pStr,tStr,Type,nGrpY)        

% sets the p-value array    
switch (Type)
    case {'Comp','CompSumm'}
        AT = combineCellArrays({NaN},tStr);
        AP = combineCellArrays(tStr',pStr);
    case ('FixedComp')
        AT = combineCellArrays({NaN},tStr);
        AP = combineCellArrays({NaN},pStr);
    case ('CompMulti')
        % allocates memory for the data array
        aOut = find(iData.appOut(:,iData.cTab));
        [AP,nApp,nVar] = deal({[]},length(aOut),length(tStr));
        
        % repeats the 
        if (nGrpY == 1)
            tStr = repmat(tStr(:),nApp,1);
        else
            [tStr0,tStr] = deal(tStr(:));
            for j = 1:(nApp-1)
                tStr = combineCellArrays(combineCellArrays(tStr,{NaN},0),tStr0,0);            
            end
        end
                
        % sets the title string array        
        AT = combineCellArrays(num2cell(NaN(1,2)),tStr');
        
        % sets the values into the cell array (for each sub-group)
        for j = 1:nApp
            % sets the column indices
            iC = (j-1)*nVar+(1:nVar);                
            for i = 1:nApp
                % sets the row indices
                iR = (i-1)*nVar+(1:nVar);

                % sets the new values
                cOfs = (nGrpY==1) + (nGrpY~=1)*j;
                AP(iR+(nGrpY~=1)*(i-1),(iC+1)+cOfs) = pStr(iR,iC);
                AP{iR(1)+(nGrpY~=1)*(i-1),1} = pData.appName{aOut(i)};                
            end
        end
        
        % sets the group titles (vertically)
        AP(:,2) = tStr;
    case {'TTest','ZTest','TTestGroup','ZTestGroup'}
        % initialisations
        appStr = iData.appName(iData.appOut(:,iData.cTab));
        nApp = length(find(iData.appOut(:,iData.cTab)));
        N = size(pStr,1)/nApp;
        
        if (N == 1)
            [AP,AT] = deal(num2cell(NaN(size(pStr)+2)),[]);
            [AP(3:end,1),AP(1,3:end)] = deal(appStr(:),appStr(:)');
            AP(3:end,3:end) = pStr;
        else
            pStrNw = cell(nApp*(N+1)-1);
            AA = num2cell(NaN(1,1+(N==length(tStr))));

            if (N == length(tStr))
                tStr = repmat([tStr(:);{''}],nApp,1);
                
                % combines the group names with the title strings
                A0 = cell2cell(cellfun(@(x)([x;num2cell(NaN(N,1))]),appStr,'un',0));
                tStr = combineCellArrays(A0(1:end-1),tStr(1:end-1));
            else
                tStr = [tStr(:),repmat({''},length(tStr),1)]';
                tStr = tStr(1:end-1)';
            end

            % adds in a gap into the data values
            for i = 1:nApp
                iR = (i-1)*N + (1:N);
                for j = 1:nApp
                    iC = (j-1)*N + (1:N);
                    pStrNw(iR+(i-1),iC+(j-1)) = pStr(iR,iC);
                end
            end
            
            % sets the overall title/data value arrays
            AT = combineCellArrays(AA,tStr');
            AP = combineCellArrays(tStr,pStrNw);            
        end
    case {'Sim','SimDN','SimNorm','SimNormDN'} % case is the similarity matrics
        AT = combineCellArrays({NaN},tStr');
        AP = combineCellArrays(tStr,pStr);
        
    case {'GOF'} % case is the goodness-of-fit statistics
        % initialisations
        [AP,AT] = deal([]);
        
        %
        for i = 1:size(pStr,1)
            AP2 = [];
            for j = 1:size(pStr,2)
                tStrG = {'Group',tStr{j};'',''};                
                APnw = combineCellArrays(tStrG,pStr{i,j},0);
                AP2 = combineCellArrays(combineCellArrays(AP2,APnw),{NaN});
            end
            
            % appends the new arrays            
            AP = combineCellArrays(AP,AP2,0);
            if (i < size(pStr,1))
                AP = combineCellArrays(AP,{NaN},0);
            end
        end
end            

% combines the P-values with the title string
A = combineCellArrays(combineCellArrays(AT,AP,0),{NaN},0);  
A = combineCellArrays(A,{NaN});

% --- retrieves the statistics test type
function [stData,cType,dForm] = runStatsTest(handles,pType,pStr,iRow)

% initialisations
[lStr,fxVal0,tType] = deal([],NaN,1);

% sets the parameters based on the test type
switch (pType{1})
    case ('CompSumm')
        lStr = {'One-Sided ANOVA from Summary Statistics'};
    case {'Comp','CompMulti'} % case is using a comparison test
        lStr = {'Automatic selection based on normality test of data';...
                'One-Sided ANOVA (Normally Distributed Data)';...
                'Kruskal-Wallis (Non-Normally Distributed Data)'};                      
    case ('FixedComp') % case is comparison against a fixed value
        lStr = {'Automatic selection based on normality test of data';...
                'One-Sided Student T-Test (Normally Distributed Data)';...
                'Wilcoxon Signed Rank Test (Non-Normally Distributed Data)'}; 
            
        pData = getappdata(handles.figDataOutput,'pData');
        cP = retParaStruct(pData.cP);
        fxVal0 = cP.tPer;  
    case {'ZTest','ZTestGroup'}
        lStr = {'One-Sided Proportion Z-Test'};
    case {'TTest','TTestGroup'}
        lStr = {'One-Sided Student T-Test'};        
    case {'Sim','SimDN'} % case is the similarity array
        [lStr,tType] = deal({'Inter-Group Similarity Matrix'},0);
    case {'SimNorm','SimNormDN'} % case is the (normalised) similarity array 
        [lStr,tType] = deal({'Inter-Group Similarity Matrix'},2);
    case {'GOF'} % case is the goodness-of-fit statistics
        [lStr,tType] = deal({'Goodness-of-fit Statistics'},0);
end

% runs the statistical test setup GUI
[stData,cType,dForm] = StatTest(handles,lStr,pType,pStr,tType,fxVal0,iRow);

% ----------------------------------- %
% --- SHEET DATA OUTPUT FUNCTIONS --- %
% ----------------------------------- %

% --- updates the data tab information
function updateSheetInfo(handles,varargin)

% retrieves the data struct
iData = getappdata(handles.figDataOutput,'iData');

% retrieves the parameter indices
cTab = iData.cTab;

% updates the radio button value
hRadio = findall(handles.panelInfoOuter,'style','radiobutton');    
set(findall(hRadio,'UserData',1+(iData.tData.iSel(cTab)>1)),'Value',1)

% updates the selection index
[~,iData.tData.iSel(cTab)] = getSelectedIndexType(handles);
setappdata(handles.figDataOutput,'iData',iData)

% updates the other formating checkbox values
updateOtherFormatCheck(handles,iData)

% updates the panel selection
if (nargin == 1)
    panelInfoOuter_SelectionChangeFcn(handles.panelInfoOuter, 1, handles)
else
    panelInfoOuter_SelectionChangeFcn(handles.panelInfoOuter, '1', handles)
end

% --- updates the data tab sheet
function updateSheetData(handles,isRecalc,varargin)

% global variables
global allowSelect
allowSelect = true;

% retrieves the data struct
iData = getappdata(handles.figDataOutput,'iData');
pData = getappdata(handles.figDataOutput,'pData');
plotD = getappdata(handles.figDataOutput,'plotD');
snTot = getappdata(handles.figDataOutput,'snTot');
jTab = getappdata(getSheetTableHandle(handles),'jTable');

% other initialisations
iSel = iData.tData.iSel(iData.cTab);
iPara = iData.tData.iPara{iData.cTab}{iSel};
[Y,A,Data,eStr,h] = deal(iData.Y{iSel},iPara{1},[],{'off','on'},[]);

% sets the tab worksheet data cell array
if (~isRecalc)
    % if not recalculating, then retrieve the stored values 
    Data = iData.tData.Data{iData.cTab}{iSel};
elseif (~isempty(iPara{1}))
    % creates the load bar    
    if (nargin == 2)
        h = ProgressLoadbar('Initialising Data Table Array...');
    end
    
    % updates the GUI
    pause(0.05);    
    
    % data array needs to be recreated
    DataN = [];
    try
        switch (iSel)
            case (1) % case is the statistical test
                % determines the output variables indices 
                [stInd,A] = deal(iData.tData.stInd{iData.cTab},iPara{1});
                isHorz = get(handles.radioAlignHorz,'value');
                DataT = get(handles.tableStatTest,'Data');

                % for each of the 
                for j = 1:length(A)
                    % retrieves the new statistical output data
                    i = A(j);
                    ATnw = setupStatsDataArray(handles,iData,pData,...
                                      plotD,Y{i}{stInd(i,1)},stInd(i,2),i);    

                    % appends the new data to the table
                    if (j == 1)
                        Data = ATnw;
                    else
                        Data = combineCellArrays(Data,ATnw,isHorz);
                    end   
                    
                    %
                    if (isempty(DataT{i,3}))
                        DataT{i,3} = setStatTestString(iData,iData.pStats{i},i);
                        set(handles.tableStatTest,'Data',DataT)
                    end
                end                                    
            case (2) % case is the population metric output                                  
                Data = setupPopMetDataArray(handles,iData,plotD,Y,A);                
            case (3) % case is the population metric (fixed) output                                  
                Data = setupFixedMetDataArray(handles,iData,pData,plotD,Y,A);                
            case (4) % case is the individual metric output
                Data = setupIndivMetDataArray(handles,iData,pData,plotD,Y,A);
            case (5) % case is the population signal output 
                [Data,DataN] = setupPopSigDataArray(handles,pData,iData,Y,A);
            case (6) % case is the individual signal output 
                [Data,DataN] = setupIndivSigDataArray(handles,pData,iData,Y,A);
            case (7) % case is the general population data array
                Data = setupPopGenDataArray(iData,Y,A);
            case (8) % case is the general individual data array
                Data = setupIndivGenDataArray(iData,Y,A);
            otherwise % case is the parameters
                Data = setupParaDataArray(handles,iData);
        end                          

        %
        if (~any(iSel == [5 6]))
            isN = find(cellfun(@isnumeric,Data));
            Data(isN(cellfun(@isnan,Data(isN)))) = {''}; 
        end
        
        %
        mInd = iData.tData.mInd{iData.cTab}{iSel};
        if (~isempty(mInd))
            % removes any manual indices not within the sheet frame
            [m,n] = size(Data);
            mInd = mInd((mInd(:,1) < m) & (mInd(:,2) < n),:);

            % if any indices remain, remove any of the manual indices for the
            % cells which are not empty
            if (~isempty(mInd))
                ii = cellfun(@(x)(isempty(Data{x(1),x(2)})),num2cell(mInd+1,2));
                mInd = mInd(ii,:);

                % if there are still manual indices, then set the cell entries
                % from the previous data array into the new one
                if (~isempty(mInd))
                    jj = sub2ind(size(Data),mInd(:,1)+1,mInd(:,2)+1);
                    Data(jj) = Data0(jj);
                end
            end
        end

        % updates the sheet data array
        iData.tData.mInd{iData.cTab}{iSel} = mInd;
        iData.tData.Data{iData.cTab}{iSel} = Data;    
        iData.tData.DataN{iData.cTab}{iSel} = DataN;
    catch ME
%         enableDisableFig(handles.figDataOutput,'on');
        rethrow(ME)
    end
else
    % sets an empty array for the sheet data array
    iData.tData.mInd{iData.cTab}{iSel} = [];
    iData.tData.Data{iData.cTab}{iSel} = [];            
    iData.tData.DataN{iData.cTab}{iSel} = [];     
end    

% updates the data into the overall data array
setappdata(handles.figDataOutput,'iData',iData)        

% disables the save menu item
setObjEnable(handles.menuSave,any(~cellfun(@isempty,iData.tData.Data)))
enableDisableFig(handles.figDataOutput,'off');

% creates the load bar
if isempty(h) && (nargin == 2) && isRecalc
    h = ProgressLoadbar('Updating Data Table...');
    pause(0.05); 
    
elseif ~isempty(h)
    h.StatusMessage = 'Updating Data Table...';
end

% determine if there is sufficient memory to display the data
try; jheapcl; end

% otherwise, update the table to include the new values
Data = expandWorksheetTable(Data);
[rowN,colN] = getTableHeaderStrings(Data);    

% sets the table java object (if not set)    
hTab = getSheetTableHandle(handles);
if (isempty(jTab))        
    setappdata(hTab,'jTable',getJavaTable(hTab))
end    

% updates the table and makes it visible    
cEdit = true(1,size(Data,2));
cForm = repmat({'char'},1,size(Data,2));          
set(hTab,'ColumnFormat',cForm,'ColumnName',colN,...
         'ColumnEditable',cEdit,'RowName',rowN);                         

% sets the table data and adds the table popup menu
setFinalSheetData(handles,jTab,Data,colN,get(hTab,'UserData'))                        
addDataTablePopupMenu(jTab,handles)

% makes the tab visible again
if nargin == 2; setObjVisibility(hTab,'on'); end

% deletes the loadbar
enableDisableFig(handles.figDataOutput,'on');
try; delete(h); end; pause(0.1);        

% --- sets the final data array for output to the worksheet
function setFinalSheetData(handles,jTab,Data,colN,cTab)

% global variables
global rngRow rngCol iRowD iColD

% java class imports
import javax.swing.BorderFactory

% initialisations
pPos = get(handles.panelDataOuter,'position');
[iRowD{cTab},iColD{cTab}] = deal([],[]);
[cCol,tPos] = deal(125/255,[10,10,pPos(3:4)-[22 42]]);
jTabLB = BorderFactory.createLineBorder(java.awt.Color(1,1,1),1);
jTab = javaObjectEDT(jTab);

% sets the row/column counts
[nRow,nCol] = size(Data);
[iRow,iCol] = deal(1:min(nRow,rngRow),1:min(nCol,rngCol));

% deletes any existing scrollpane objects
hSP0 = findall(handles.panelDataOuter,'tag','hSP','UserData',cTab);
if ~isempty(hSP0); delete(hSP0); end

% Draw table in scroll pane
jSP = javaObjectEDT('javax.swing.JScrollPane', jTab);
[jSP, hC] = javacomponent(jSP, [], handles.panelDataOuter);
set(hC,'Position',tPos,'tag','hSP','UserData',cTab)
jSP.setViewportView(jTab);

% updates the table data
jTM = javax.swing.table.DefaultTableModel(Data(iRow,iCol),colN);
addJavaObjCallback(jTM,'TableChangedCallback',@dataSheetEdit)
jTM.setRowCount(max(nRow,50))
jTM.setColumnCount(max(nCol,20))
jTab.setModel(jTM);

% sets the horizonal/vertical scrollbar callback functions
hSP = handle(jSP,'CallbackProperties'); 
[jView,cellSz] = deal(jTab.getParent,jTab.getCellRect(0,0,1));
[jSBH, jSBV] = deal(hSP.getHorizontalScrollBar, hSP.getVerticalScrollBar);
cbFcnH = setupAdjustCBFcn(Data,jView,jTM,cellSz,cTab,0);
cbFcnV = setupAdjustCBFcn(Data,jView,jTM,cellSz,cTab,1);

%
addJavaObjCallback(jSBH,'AdjustmentValueChangedCallback',cbFcnH)
addJavaObjCallback(jSBV,'AdjustmentValueChangedCallback',cbFcnV)

% retrieves the statistical test table java object handle
jTabH = getappdata(handles.tableGroupInc,'jTable');        
if (isempty(jTabH)) 
    % sets the table java object (if not set)
    jTabH = getJavaTable(handles.tableGroupInc);
    setappdata(handles.tableGroupInc,'jTable',jTabH)
end   

% sets the tables cell selection to non-contiguous
LSM = jTab.getSelectionModel();
jTab.setNonContiguousCellSelection(true);

% jTab.setSelectionMode(LSM.SINGLE_SELECTION)
jTab.setSelectionMode(LSM.MULTIPLE_INTERVAL_SELECTION)
jTab.setColumnSelectionAllowed(true);
jTab.setRowSelectionAllowed(true);

% sets the table colours
jTab.setBackground(java.awt.Color(1,1,1))
jTab.setGridColor(java.awt.Color(cCol,cCol,cCol));
jTab.setBorder(jTabLB)
jTab.revalidate;

% determines if the header renderer has been set
if (~isempty(Data))
    % updates the default renderer
    jTabHR = jTabH.getColumnModel.getColumn(0).getHeaderRenderer;
    jTab.getTableHeader.setDefaultRenderer(jTabHR)
    jTab.getTableHeader.revalidate
end

% clears any potential java errors
pause(0.5)
clc
    
% --- creates the scrollbar adjustment callback function
function cbFcn = setupAdjustCBFcn(Data,jView,jTM,cellSz,cTab,Type)

cbFcn = {@viewAdjuctFunc,Data,jView,jTM,cellSz,cTab,Type};

% --- retrieves the table header strings (based on the data array)
function [rowN,colN] = getTableHeaderStrings(Data)

% retrieves the data array dimensions
[nRow,nCol] = size(Data);

% sets the row/column header strings
rowN = cellfun(@num2str,num2cell(1:nRow)','un',0);
colN = getSheetColumnStrings(1:nCol);

% --- sets the metric statistics string from the index array, metInd
function mStr = setMetricStatString(metInd)

% global variables
global nMet

% determines the selected indices (remove the N-values)
iMet = find(metInd);
iMet = iMet(iMet ~= nMet);

% sets the metric string based on the selection type
if (length(iMet) > 1)
    % case is multiple metrics have been selected
    mStr = 'Multiple Metrics';
else
    % case is only one has been selected
    [~,mStr] = ind2varStat(iMet);                        
end

% --- sets the statistical test string 
function stStr = setStatTestString(iData,pType,iRow)

% initisalisations
switch (pType{1})
    case {'Sim','SimDN','GOF'} % case is the similarity matrics
        outStr = [];
    case {'SimNorm','SimNormDN'} % case is the normalised similarity matrices
        outStr = {'Raw','Normalised'};
    otherwise % case is the significance tests
        outStr = {'P-Values','Significance','Both'};
end

% determines if a valid test type has been set/calculated
stInd = iData.tData.stInd{iData.cTab}(iRow,:);
if (isnan(stInd(1)))
    % if no test is set, then set an empty string
    stStr = '';
else
    % otherwise, set the test string based on the type
    stData = iData.Y{1}{iRow}{stInd(1)};
    if (isempty(outStr))
        stStr = stData.Test;
    else
        if (iscell(stData.Test))
            stStr = cellfun(@(x)(sprintf('%s (%s)',x,outStr{stInd(2)})),stData.Test,'un',0);
        else
            stStr = sprintf('%s (%s)',stData.Test,outStr{stInd(2)});
        end
    end
end

% --------------------------------- %
% --- OBJECT PROPERTY FUNCTIONS --- %
% --------------------------------- %

% --- initialises the GUI objects 
function handles = initGUIObjects(handles,metType,hasTest)

% global variables
global mainProgDir

% retrieves the data structs
hGUI = getappdata(handles.figDataOutput,'hGUI');
iData = getappdata(handles.figDataOutput,'iData');
snTot = getappdata(handles.figDataOutput,'snTot');
plotD = getappdata(handles.figDataOutput,'plotD');
pData = getappdata(handles.figDataOutput,'pData');

% turns off all the warnings (for the tab group creation)
warning off all

% updates the data struct with the 
mInd = find(any(metType,1));
iData.tData.mSel = mInd(1);
setappdata(handles.figDataOutput,'iData',iData)          

% --------------------------------------- %
% --- USER INFO GROUP INITIALISATIONS --- %
% --------------------------------------- %

% initialisations
tabPosU = getTabPosVector(handles.panelUserInfo);
tStr = {'Genotype Groups','Metric Order','Experiment Output'};
tStr = tStr(1:(end-(length(snTot)==1)));

% creates a tab panel group
hTabGrpU = createTabPanelGroup(handles.panelUserInfo,1);
set(hTabGrpU,'position',tabPosU,'tag','userTabGrp')           

% creates the tabs         
hTabU = cell(length(tStr),1);
for i = 1:length(tStr)
    hTabU{i} = createNewTabPanel(hTabGrpU,1,'title',tStr{i},'UserData',i);    
end     
         
% sets the tab selection change callback function
setTabGroupCallbackFunc(hTabGrpU,{@changeInfoTab});

% sets the table data and resizes
set(handles.tableGroupInc,'Data',[iData.appName,num2cell(iData.appOut)],...
                          'RowName',[]);                                          
                      
% ----------------------------------- %
% --- METRIC TABLE INITIALSATIONS --- %
% ----------------------------------- %

% initialisations
[sDN,dD] = deal(iData.fName(hasTest),cell(length(mInd)+1,1));
[nStrS,eStr] = deal(length(sDN),{'off','on'});

% initialises the table data cell arrays
for i = 1:length(dD)
    if (i == length(dD))
        ind = 1:(1+(~isempty(pData.cP)));
        dDN = {'Global Parameters';'Calculation Parameters'};
        [nStrD,dDN] = deal(length(ind),dDN(ind));
    else
        dDN = iData.fName(logical(metType(:,mInd(i))));
        nStrD = sum(metType(:,mInd(i)));        
    end
    
    % sets the data strings  
    if (i < length(dD))
        isMP = mInd(i) == 1;
    else
        isMP = false;
    end
    
    if (isMP)
        dD{i} = [dDN,num2cell(false(nStrD,1)),repmat({''},nStrD,1)];    
    else
        dD{i} = [dDN,num2cell(false(nStrD,1))];    
    end
end

% sets the table properties
[eFcn,sFcn] = deal({@tableCellEdit},{@metTableCellSelect});
                
% if not any statistical tests, then disable the radio button               
if (any(hasTest))
    % sets the stats sheet data
    sD = [sDN,num2cell(false(nStrS,1)),repmat({''},nStrS,1)];
    set(handles.tableStatTest,'Data',sD,'ColumnFormat',...
                {'char','logical',[]},'CellEditCallback',eFcn);    
            
    % sets the table column resize flags
    autoResizeTableColumns(handles.tableStatTest);
else
    % otherwise, remove the table and resets the object properties    
    delete(handles.tableStatTest)
    set(handles.radioMetricData,'value',1)
    setObjEnable(handles.radioStatTest,'off')
end

% sets the enabled properties of the metric data radio button
setObjEnable(handles.radioMetricData,any(metType(:)))    

% sets the time unit popup strings (if any are required)
if any(any(metType(:,4:5)))
    % sets up the units popup menu based on the dependent variable(s)
    if any(strcmp(field2cell(iData.xVar,'Type'),'Time'))
        % sets the list strings and the experiment durations
        lStr = {'Seconds','Minutes','Hours','Days'};
        Texp = cell2mat(cellfun(@(x)(sec2vec(x{end}(end))),...
                            field2cell(snTot,'T'),'un',0));        
                        
        % sets the final list string and userdata tag
        [lStr,uData] = deal(lStr(1:(5-find(any(Texp>=1,1),1,'first'))),'Time');
        set(handles.textUnits,'String','Time Vector Units:');
    elseif any(strcmp(field2cell(iData.xVar,'Type'),'Time'))
        % sets the final list string and userdata tag
        [lStr,uData] = deal({'Millimetres','Centimetres','Metres'},'Dist');    
        set(handles.textUnits,'String','Distance Vector Units:');
    else
        lStr = [];
    end
            
    % sets the list strings based on the experiment durations    
    if isempty(lStr)
        set(handles.popupUnits,'String',{''},'Value',1,'visible','off');
        set(setObjEnable(handles.textUnits,'off'),'String',' ');
    else
        set(handles.popupUnits,'String',lStr,'Value',1,'UserData',uData);
    end
end

% ----------------------------------------- %
% --- METRIC DATA GROUP INITIALISATIONS --- %
% ----------------------------------------- %

% initialisations
tStr = {'Metrics (Pop)','Metrics (Fixed)','Metrics (Indiv)',...
        'Signals (Pop)','Signals (Indiv)','General Array (Pop)',...
        'General Array (Indiv)','Other'};
tabPosM = getTabPosVector(handles.panelMetricInfo);

% sets the table properties
cWid{1} = {140,45,107};
cWid{2} = {225,45};
mInd(end+1) = length(tStr);

% creates a tab panel group
hTabGrpM = createTabPanelGroup(handles.panelMetricInfo,1);
set(hTabGrpM,'tag','metricTabGrp','Units','Pixels','position',tabPosM)

% otherwise, resets the tab group dimensions
resetObjPos(hTabGrpM,'height',2,1)
resetObjPos(hTabGrpM,'bottom',-2,1)

% creates the tabs         
[hTabM,hTable] = deal(cell(length(mInd),1));
for i = 1:length(mInd)
    % creates the tab object
    hTabM{i} = createNewTabPanel(hTabGrpM,1,'title',tStr{mInd(i)},'UserData',mInd(i)); 
    
    % retrieves the table position vector (HG2 graphics only)
    tPos = getTabTablePos(hTabGrpM,false);
    
    % creates the table object
    cEdit = [false,true];
    [cName,cForm] = deal({'Metric','Include'},{'char','logical'});    
    if ((mInd(i) == 1) && (iData.metStats))
        [cName{3},cEdit(3)] = deal('Metric Stats',false);
        dD{i}(:,3) = {'Mean'};            
    end    
    
    % creates the table object
    hTable{i} = uitable(handles.panelMetricInfo,'position',tPos,...
                'ColumnFormat',cForm,'CellEditCallback',eFcn,...
                'CellSelectionCallback',sFcn,'ColumnName',cName,...
                'UserData',mInd(i),'visible','on','Data',dD{i},...
                'ColumnWidth',cWid{1+(mInd(i)>1)},'RowName',[],...
                'ColumnEditable',cEdit);                                 
    
    % makes the table invisible (if the tab is not selected)
    set(hTable{i},'parent',hTabM{i}); 
end           

% automatically resizes the table columns
cellfun(@(x)(setappdata(x,'jTable',getJavaTable(x))),hTable)
cellfun(@(x)(updateTableColumnProp(x)),hTable)      
cellfun(@(x)(autoResizeTableColumns(x)),hTable)

% sets the tab selection change callback function
setTabGroupCallbackFunc(hTabGrpM,{@changeMetricTab});

% --------------------------------------- %
% --- SHEET TAB GROUP INITIALISATIONS --- %
% --------------------------------------- %

% initialisations
tabPosD = getTabPosVector(handles.panelDataOuter);
tStr = {'Sheet 1','+'};
    
% creates a tab panel group
hTabGrpD = createTabPanelGroup(handles.panelDataOuter,1);
set(hTabGrpD,'tag','sheetTabGrp','Units','Pixels','position',tabPosD)         
        
% sets up the tab objects (over all stimuli objects)
iData.tData.hTab = cell(length(tStr),1);
for i = 1:length(tStr)    
    iData.tData.hTab{i} = ...
        createNewTabPanel(hTabGrpD,1,'title',tStr{i},'UserData',i);
end    

% creates the tab table
createTabTable(handles.panelDataOuter,1,iData.tData.hTab{1});

% sets the tab selection change callback function
setTabGroupCallbackFunc(hTabGrpD,{@changeDataTab});

% initialises the information panel properties
set(handles.radioAlignVert,'value',1)

% updates the data struct into the main GUI
setappdata(handles.figDataOutput,'iData',iData);

% -------------------------------- %
% --- OTHER GUI INITIALSATIONS --- %
% -------------------------------- %
    
% initialisations
uD = {1,[]};
cdFile = 'ButtonCData.mat';
nDay = detExptDayDuration(snTot,hGUI);

% retrieves the experiment duration 
mltExp = (length(snTot) > 1) && (iData.sepExp);
mltDay = (any(nDay > 1)) && (iData.sepDay);
mltApp = length(iData.appName) > 1;
mltGrp = any(detDataGroupSize(iData,plotD,[])) > 1;

% sets the button c-data values
if exist(cdFile,'file')
    [A,nDS] = deal(load(cdFile),3); 
    [Iup,Idown] = deal(A.cDataStr.Iup,A.cDataStr.Idown);        
    set(handles.buttonMoveUp,'Cdata',uint8(dsimage(Iup,nDS)));        
    set(handles.buttonMoveDown,'Cdata',uint8(dsimage(Idown,nDS)));                   
end

% updates the metric order listbox
listMetricOrder_Callback(handles.listMetricOrder, [], handles)

% disables the delete/move tab menu items
setObjEnable(handles.menuDeleteTab,'off')
setObjEnable(handles.menuMoveTab,'off')

% sets the enabled properties of the checkboxes
set(setObjEnable(handles.checkSepByExpt,mltExp),'UserData',uD{1+mltExp})
set(setObjEnable(handles.checkSepByDay,mltDay),'UserData',uD{1+mltDay})    
set(setObjEnable(handles.checkSepByApp,mltApp),'UserData',uD{1+mltApp})
setObjEnable(handles.checkNumGroups,mltGrp)    
checkOtherFormat(handles.checkSepByApp,'1')

% sets the callback functions for the other formatting checkboxes
hCheck = findall(handles.panelManualData,'style','checkbox');
for i = 1:length(hCheck)
    set(hCheck(i),'Callback',{@checkOtherFormat});
end

% removes the background edit boxes
delete(handles.editTabBack)
delete(handles.editDataBack)
delete(handles.editTabPanel)

% resets the tab group height
resetObjPos(hTabGrpU,'height',2,1)
resetObjPos(hTabGrpU,'bottom',-2,1)

% resets the position of the table
set(handles.tableGroupInc,'parent',hTabU{1},...
                          'position',getTabTablePos(hTabGrpU,0))

% resets the metric order listbox dimensions
set(handles.listMetricOrder,'parent',hTabU{2})
resetObjPos(handles.listMetricOrder,'width',-15,1)
resetObjPos(handles.listMetricOrder,'height',-10,1)
resetObjPos(handles.listMetricOrder,'left',5)
resetObjPos(handles.listMetricOrder,'bottom',5)        

% resets the position of the up/down arrow buttons
hObj = {handles.buttonMoveUp,handles.buttonMoveDown};
for i = 1:length(hObj)
    set(hObj{i},'parent',hTabU{2})
    resetObjPos(hObj{i},'left',-20,1)
    resetObjPos(hObj{i},'bottom',-10,1)        
end

% resets the experiment inclusion table (if required)
if length(hTabU) == 3
    % sets the experiment inclusion data
    sName = getappdata(handles.figDataOutput,'sName');
    DataExp = [sName(:),num2cell(iData.expOut)];

    % sets the table properties
    set(handles.tableExptInc,'parent',hTabU{3},'Data',DataExp,...
                             'position',getTabTablePos(hTabGrpU,0))             
    autoResizeTableColumns(handles.tableExptInc); 
else
    % if not required, then delete the table
    delete(handles.tableExptInc); 
end   

% resizes the table columns
autoResizeTableColumns(handles.tableGroupInc); 
panelInfoOuter_SelectionChangeFcn(handles.panelInfoOuter, '1', handles)

% sets the metric tab data
changeMetricTab(hTabGrpM); 

% disables the save menu item
setObjEnable(handles.menuSave,'off')

% --- initialises the GUI's java objects
function initGUIJavaObjects(handles)

% initialisations
hFig = handles.figDataOutput;

% retrieves all the tab groups from the 
hTabG = findall(hFig,'type','uitabgroup');
for i = 1:length(hTabG)
    % retrieves the tabbed pane object from the tab group
    jH = findjobj(hTabG(i));
    jHT = jH(cellfun(@(x)(isa(x,['javahandle_withcallbacks.',...
                'com.mathworks.mwswing.MJTabbedPane'])),num2cell(jH)));

    % sets the java object into the tab group
    setappdata(hTabG(i),'UserData',jHT)        
end

% --- updates the metric order selection buttons
function updateButtonProps(handles)

% initialisations
[eStr,hList] = deal({'off','on'},handles.listMetricOrder);
[iSel,nList] = deal(get(hList,'value'),length(get(hList,'string')));

% updates the button enabled properties
if isempty(iSel) || (nList == 0)
    % no selection made
    setObjEnable(handles.buttonMoveUp,'off')
    setObjEnable(handles.buttonMoveDown,'off')    
else
    % update based on the current selection
    setObjEnable(handles.buttonMoveUp,~any(iSel==1))
    setObjEnable(handles.buttonMoveDown,~any(iSel==nList))
end

% --- updates the list order
function updateOrderList(handles)

% global variables
global nMet nMetG

% initialisations
iData = getappdata(handles.figDataOutput,'iData');
metType = getappdata(handles.figDataOutput,'metType');
[iSel,lStr] = deal(iData.tData.iSel(iData.cTab),[]);
iPara = iData.tData.iPara{iData.cTab};

% retrieves the list strings (in the specified order)
iOrder = iPara{iSel}{1};
if (iSel == 2)
    % case is the population statistic values
    iOrder = iPara{iSel}{1};        
    if (~isempty(iOrder))
        % memory allocation
        iOrder = iOrder(iOrder(:,2)~=nMet,:);
        lStr = cell(size(iOrder,1),1);
        
        % sets the local metric type indices        
        mType = find(metType == (iSel-1));
        
        % sets the metric statistical strings for each type
        for i = 1:length(lStr)
            % sets the final list string    
            if (iData.metStats)
                [~,mStr] = ind2varStat(iOrder(i,2));                        
                fName = iData.fName{mType(iOrder(i,1))};
                lStr{i} = sprintf('%s (%s)',fName,mStr);
            else
                lStr{i} = iData.fName{mType(iOrder(i,1))};
            end
        end
    end
else
    if (~isempty(iOrder))
        switch (iSel)
            case (1) % case is the statistical test     
                hasTest = getappdata(handles.figDataOutput,'hasTest');
                lStr = iData.fName(hasTest(iOrder));
            case (nMetG)
                hTabG = findall(0,'tag','metricTabGrp');
                hTab = findall(hTabG,'UserData',nMetG-1,'Parent',hTabG);
                hTable = findall(hTab,'type','uitable');
                
                Data = get(hTable,'Data');
                lStr = Data(iOrder);
            otherwise % case is the other metrics
                %
                mType = find(metType(:,iSel-1));
                lStr = iData.fName(mType(iOrder));
        end
    end     
end
    
% resets the list value (if it is greater than the list length)
if (isempty(lStr))
    set(handles.listMetricOrder,'value',[])    
elseif (max(get(handles.listMetricOrder,'value')) > length(lStr))
    set(handles.listMetricOrder,'value',length(lStr))    
end

% sets the list strings
set(handles.listMetricOrder,'string',lStr)
updateButtonProps(handles)

% --- updates the other formatting checkbox values
function updateOtherFormatCheck(handles,iData,varargin)

% global variables
global nMetG

% retrieves the checkbox handles
hCheck = findall(handles.panelManualData,'style','checkbox');

% sets the metric parameter index
[iSelT,eStr] = deal(iData.tData.iSel(iData.cTab),{'off','on'});

% updates the checkbox values
for i = 1:length(hCheck)
    hCheckNw = findall(hCheck,'Max',i);    
    set(hCheckNw,'value',i*iData.tData.altChk{iData.cTab}{iSelT}(i))
    
    switch (get(hCheckNw,'tag'))
        case ('checkSepByExpt')
            % sets the check box enabled properties
            isOK = (any(iSelT == 2)) && iData.sepExp;
            enableChk = isOK && (sum(iData.expOut(:,iData.cTab))>1);
            setObjEnable(hCheckNw,enableChk)            
            
            isChk = iData.tData.altChk{iData.cTab}{iSelT}(2);
            if (nargin < 3)
                resetExptTabProps(handles,iData,isChk);            
            end
            
        case ('checkSepByApp')
            isOK = all(iSelT ~= [5:8 nMetG]) && ...
                            (getSelectedIndexType(handles) ==2 );
            setObjEnable(hCheckNw,isOK&&(sum(iData.appOut(:,iData.cTab))>1)) 
            
        case ('checkNumGroups')
            % determines
            switch iSelT
                case (1) % case is the statistical tests            
                    iiV = getappdata(handles.figDataOutput,'hasTest');
                    
                case (nMetG) % case is the other properties
                    iiV = [];    
                    
                otherwise % case is the other metrics
                    metType = getappdata(handles.figDataOutput,'metType');
                    iiV = metType(:,iSelT-1);    
            end            
            
            % determines if there are any grouped variables
            if ~isempty(iiV)
                % values could be grouped
                [Var,Type] = field2cell(iData.xVar,{'Var','Type'});
                xDepY = field2cell(iData.yVar(iiV),'xDep');
                isE = cellfun(@isempty,xDepY);
                if (all(isE))
                    % no grouping independent variables
                    hasGrp = false;
                else
                    % determines if any of the metrics could be grouped
                    hasGrp = any(cellfun(@(x)(any(strcmp(cellfun(@(y)(...
                            Type(strcmp(y,Var))),x),'Group'))),xDepY(~isE)));
                end
            else
                % values are not grouped
                hasGrp = false;
            end
                            
            % updates the checkbox enabled properties
            setObjEnable(hCheckNw,hasGrp)                                        
    end
end

% updates the separation by apparatus checkbox callback
checkOtherFormat(handles.checkSepByApp,'1')

% --- sets the time unit object properties
function setTimeUnitObjProps(handles,mSel)

% initialisations
eStr = {'off','on'};

% determines if the values are the population/individual signals
if (any(mSel == [4 5]))
    % if so, then retrieve the important data structs
    pData = getappdata(handles.figDataOutput,'pData');    
    
    % determines if there are any time dependencies
    Type = field2cell(pData.oP.xVar,'Type');
    iTT = any(strcmp(Type,'Time'));
    if (any(iTT))
        % if so, then retrieve the x-dependencies of the signal variables
        metType = getappdata(handles.figDataOutput,'metType');
        yVar = pData.oP.yVar(metType(:,mSel));  
        tVar = field2cell(pData.oP.xVar(iTT),'Var');
        
        xDep = field2cell(yVar,'xDep');
        tOK = any(cellfun(@(x)(any(cellfun(@(y)(any(strcmp(y,tVar))),x))),xDep));
    else
        % no time dependencies
        tOK = false;
    end
else
    % otherwise, there are no time dependencies
    tOK = false;
end

% sets the enabled properties of the time unit objects
setObjEnable(handles.textUnits,tOK)
setObjEnable(handles.popupUnits,tOK)

% --- updates the column enabled properties
function updateTableColumnProp(hTab)

% retrieves the java table object
jTab = getappdata(hTab,'jTable');
if (isempty(jTab))
    jTab = getJavaTable(hTab);
    setappdata(hTab,'jTable',jTab)    
end

% --- resets the experiment tab properties
function resetExptTabProps(handles,iData,isOK)

% retrieves the solution data struct
snTot = getappdata(handles.figDataOutput,'snTot');

% retrieves the tab group java object handle (based on graphics type)
hTabG = findall(handles.panelUserInfo,'tag','userTabGrp');
jTabG = getappdata(hTabG,'UserData'); 
if isempty(jTabG)
    return       
end

% updates the experiment output tab properties
if length(snTot) > 1
    if ~isempty(jTabG)
        jTabG.setEnabledAt(length(get(hTabG,'children'))-1,isOK)        
    end
end

% if disabling the tab (and it is selected), then shift the
% selected tab to the first tab instead
if ~isOK && (iData.incTab == 3)
    % shifts the tab
    updateTabSelection(hTabG,1,3)

    % runs the tab change callback function
    hTabNw = findall(hTabG,'UserData',1);
    changeInfoTab(hTabG, struct('NewValue',hTabNw))
end            

% --- creates a new tabe table object
function hTable = createTabTable(hPanel,iTab,hTab)

% initialisations
[tPos,cFcn] = deal(getTabTablePos(hPanel),{@tableDataSheetCallback});

% creates the new table 
hTable = uitable(hPanel,'position',tPos,'UserData',iTab,'Data',[],...
                    'CellEditCallback',cFcn,'Visible','on','Parent',hTab);       
                          
% retrieves the java table object             
setappdata(hTable,'jTable',getJavaTable(hTable))
        
% --- retrieves the worksheet table handle
function hTab = getSheetTableHandle(handles,iTab)

% sets the default tab index to the currently selected
if (nargin == 1)
    iData = getappdata(handles.figDataOutput,'iData');
    iTab = iData.cTab;
end

% retrieves the worksheet table handle
hTab = findall(handles.panelDataOuter,'type','uitable','UserData',iTab);        
        
% --- sets the hit-test of all the objects
function setAllHitTest(handles,Type)

set(findall(handles.figDataOutput),'hittest',Type)

% --------------------------------------- %
% --- DATA TABLE POPUP MENU FUNCTIONS --- %
% --------------------------------------- %

% --- sets the datasheet table pop-up menus
function addDataTablePopupMenu(jTab,h)

% Prepare the context menu (note the use of HTML labels)
menuCopy = javax.swing.JMenuItem('Copy Selection');
menuSelect = javax.swing.JMenuItem('Select All');
menuInsert = javax.swing.JMenuItem('Insert Sheet Row(s)/Column(s)');
menuDelete = javax.swing.JMenuItem('Delete Sheet Row(s)/Column(s)');
menuShift = javax.swing.JMenuItem('Shift Sheet Row(s)/Column(s)');

% Set the menu items' callbacks
addJavaObjCallback(menuCopy,'ActionPerformedCallback',{@menuCopyFcn,h})
addJavaObjCallback(menuSelect,'ActionPerformedCallback',{@menuSelectFcn,h})
addJavaObjCallback(menuInsert,'ActionPerformedCallback',{@menuInsertFcn,h})
addJavaObjCallback(menuDelete,'ActionPerformedCallback',{@menuDeleteFcn,h})
addJavaObjCallback(menuShift,'ActionPerformedCallback',{@menuShiftFcn,h})

% Add all menu items to the context menu (with internal separator)
jmenu = javax.swing.JPopupMenu;
jmenu.add(menuCopy);
jmenu.add(menuSelect);
jmenu.addSeparator;
jmenu.add(menuInsert);
jmenu.add(menuDelete);
jmenu.add(menuShift);

% sets the tree mouse-click callback
addJavaObjCallback(jTab,'MousePressedCallback', {@mousePressed,jmenu})

% ------------------------------------- %
% --- POPUP-MENU CALLBACK FUNCTIONS --- %
% ------------------------------------- %

% Set the mouse-press callback
function mousePressed(hTab, eventData, jmenu)
    
% right-click is like a Meta-button
if eventData.isMetaDown  
    % retrieves the table object
    jTab = eventData.getSource;
    if (jTab.isEditing)
        % if the user is editing the cell, then force stop editing
        jTab.getCellEditor().stopCellEditing();
        pause(0.05);
    end
        
	% Display the (possibly-modified) context menu
    jmenu.show(jTab, eventData.getX, eventData.getY);
    jmenu.repaint;
end

% --- copy menu item
function menuCopyFcn(hObject, eventData, handles)

% global variables
global allowSelect

% initialisations
iData = getappdata(handles.figDataOutput,'iData');
Data = iData.tData.Data{iData.cTab}{iData.tData.iSel(iData.cTab)};
[m,n] = size(Data);

% determines if the user can select the data
if (allowSelect)
    % determines the selected rows/columns
    jTab = getappdata(getSheetTableHandle(handles),'jTable');
    [iRow0,iCol0] = deal(jTab.getSelectedRows,jTab.getSelectedColumns);
    
    % sets the reduces data array
    iRow = (iRow0(1)+1):min(m,iRow0(end)+1);
    iCol = (iCol0(1)+1):min(n,iCol0(end)+1);
    Data = Data(iRow,iCol);
    mStr = 'Selected sheet data has been copied to the clipboard.';
else
    % outputs a message to screen
    mStr = 'All sheet data has been copied to the clipboard.';    
end

% copies the data to the clipboard
waitfor(msgbox(mStr,'Data Copying','modal'))   
mat2clip(Data)

% --- select all menu item
function menuSelectFcn(hObject, eventData, handles)

% retrieves the table java object
jTab = getappdata(getSheetTableHandle(handles),'jTable');

% selects the entire table
jTab.selectAll

% --- insert row/column menu item
function menuInsertFcn(hObject, eventData, handles)

% runs the data alteration sub-gui
AlterData(handles,1)

% --- insert row/column menu item
function menuDeleteFcn(hObject, eventData, handles)

% runs the data alteration sub-gui
AlterData(handles,2)

% --- shift row/column menu item
function menuShiftFcn(hObject, eventData, handles)

% runs the data alteration sub-gui
AlterData(handles,3)

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% --- initialises the data struct
function [iData,Type,hasTest] = initDataStruct(handles,snTot,pData,plotD)

% global variables
global nMet nChk nMetG
nMetG = 9;

% initialisations
oP = pData.oP;
[Stats,pType,Name] = field2cell(oP.yVar,{'Stats','Type','Name','Var'});

% retrieves the parameter types
[hasTest,Type] = deal(~cellfun(@isempty,Stats),logical(cell2mat(pType)));

% memory allocation
[nApp,nExp,nPara] = deal(length(pData.appName),length(snTot),sum(hasTest));

% determines number of other formatting checkbox objects
nChk = length(findall(handles.panelManualData,'style','checkbox'));
a = cell(1,nMetG);

% initialises the output data struct
iData = struct('fName',[],'pStr',[],'pType',[],'pStats',[],'xVar',[],'yVar',[],...
               'appOut',[],'appName',[],'expOut',[],'stData',[],'tData',[],...
               'nOut',[],'cInd',1,'cTab',1,'nTab',1,'incTab',1,'Data0',[],...
               'sepDay',oP.sepDay,'sepExp',oP.sepExp,'sepGrp',oP.sepGrp,...
               'metStats',oP.metStats,'grpComb',oP.grpComb);
           
% sets the tab data struct           
iData.tData = struct('Name',[],'Data',[],'DataN',[],'hTab',[],'iPara',[],...
                     'mInd',[],'stInd',[],'altChk',[],'alignV',[],...
                     'iSel',1,'mSel',1);
[iData.tData.Name,iData.tData.Data,iData.tData.DataN] = deal({'Sheet 1'},{a},{a}); 
[iData.tData.stInd{1},iData.tData.mInd{1}] = deal(NaN(nPara,2),a);
iData.tData.iPara{1} = addOrderArray(Type);
iData.tData.altChk = {repmat({false(1,nChk)},1,nMetG)};
[iData.tData.alignV,iData.Data0] = deal(true(1,nMetG),cell(1,nMetG-1));

% sets the field names and strings
[iData.fName,iData.pStats,iData.pType] = deal(Name,Stats(hasTest),pType);
[iData.appOut,iData.appName] = deal(true(nApp,1),pData.appName);
[iData.stData,iData.Y] = deal(cell(nPara,1),cell(nMetG,1));
[iData.expOut,iData.xVar,iData.yVar] = deal(true(nExp,1),oP.xVar,oP.yVar);

% sets the statistical test cell array (if any are to be output)
if (any(hasTest) && iData.metStats)
    nTest = num2cell(cellfun(@(x)(getStatCount(x{1})),Stats(hasTest)));
    iData.Y{1} = cellfun(@(x)(cell(1,x+1)),nTest,'un',0);
else
    iData.metStats = false;
end

% calculates the individual metrics (if any are to be output)
if (any(Type(:,1)))          
    % calculates all of the population metrics
    iData.Y{2} = cell(sum(Type(:,1)),nMet,4);
    iData = calcStatMetricsPop(snTot,iData,plotD,Type(:,1)); 
end

% set the signal traces (if any are to be output)
if (any(Type(:,2)))
    iData.Y{3} = cell(sum(Type(:,2)),1);
    iData = setFixedMetricsPop(iData,plotD,Type(:,2));
end
    
% calculates the individual metrics (if any are to be output)
if (any(Type(:,3)))          
    % calculates all of the grouped individual metrics
    iData.Y{4} = cell(sum(Type(:,3)),2);
    iData = calcStatMetricsIndiv(snTot,iData,plotD,Type(:,3));    
end
    
% set the signal traces (if any are to be output)
if (any(Type(:,4)))
    iData.Y{5} = cell(sum(Type(:,4)),1);
    iData = setMetricSignalsPop(iData,plotD,Type(:,4));
end

% set the signal traces (if any are to be output)
if (any(Type(:,5)))
    iData.Y{6} = cell(sum(Type(:,5)),2);
    iData = setMetricSignalsIndiv(snTot,iData,plotD,Type(:,5));
end

% set the signal traces (if any are to be output)
if (any(Type(:,6)))
    iData.Y{7} = cell(sum(Type(:,6)),1);
    iData = set2DArrayDataPop(iData,plotD,Type(:,6));
end

% set the signal traces (if any are to be output)
if (any(Type(:,7)))
    iData.Y{8} = cell(sum(Type(:,7)),1);
    iData = set2DArrayDataIndiv(iData,plotD,Type(:,7));
end

% --- creates a new index order array
function iPara = addOrderArray(metType)

% iPara Convention
%
% Element 1 - Statistical Test
% Element 2 - Population Metrics
% Element 3 - Fixed Metrics
% Element 4 - Individual Metrics
% Element 5 - Population Signals
% Element 6 - Individual Signals
% Element 7 - 2D Array
% Element 8 - Parameters

% global variables
global nMet nMetG

% memory allocation
[isMP,a] = deal(metType(:,1),[]);

% set the individual cell components (population metrics)
if (any(isMP))
    a = false(sum(isMP),nMet); 
    [a(:,1),a(1,end)] = deal(true);
end

% sets the final array
iPara = repmat({{[]}},1,nMetG);
iPara{2} = {[],a};
        
% --- retrieves the test count for each statistical test type
function nTest = getStatCount(sType)

% retrieves the test count based on the test type
switch (sType)
    case {'Comp','CompMulti','FixedComp'}
        nTest = 2;
    case {'ZTest','ZTestGroup','TTest','TTestGroup','SimNorm','SimNormDN'}
        nTest = 0;
    case {'Sim','SimDN','GOF','CompSumm'}
        nTest = 0;
end     

% --- retrieves the significance level string
function pTolStr = getSignificanceString(pTol)

% sets the significance string
hL = log10(pTol);
if (hL < -3)
    % p-value significance is small, so use scientific form
    [hL,pL] = deal(floor(hL),pTol/(10^floor(hL)));
    pTolStr = sprintf('%1.2E%i',pL,hL);
else
    % otherwise, use rounded value
    pTolStr = sprintf('%.4f',pTol);
end

% --- gets the currently selected radio button index and the overall index
function [iSel,iSelT] = getSelectedIndexType(handles)

% initialisations
iData = getappdata(handles.figDataOutput,'iData');

% determines the 
hRS = findall(handles.panelInfoOuter,'style','radiobutton','value',1);
if (length(hRS) > 1)
    hRS = hRS(~cellfun(@isempty,get(hRS,'UserData')));
end

% retrieves the selected radio button index
[iSel,mSel] = deal(get(hRS,'UserData'),iData.tData.mSel(iData.cTab));
if (iSel == 1)
    iSelT = 1;
else
    iSelT = mSel + 1;
end


% --- function that updates the tab selection
function updateTabSelection(hTabG,iNw,iPr)

% updates the selected tab based on the graphics type
if nargin == 2
    % new index is the order within tab group
    hTabG.SelectedTab = hTabG.Children(iNw);
else
    % new index is based on the user data flag
    hTabG.SelectedTab = findall(hTabG,'UserData',iNw,'Parent',hTabG);
end

% --- gets the tab table position vector
function tPos = getTabTablePos(hPanel,isShift)

% global variables
global tCount

% determines if the table needs to be shifted
if nargin < 2
    tCount = tCount + 1;
    isShift = tCount < 1;
end

% sets the table position vector
hTabG = findall(hPanel,'type','uitabgroup');
tgPos = get(hTabG,'position');    
if isShift
    tPos = [1 31 tgPos(3:4)-[6 30]];        
else
    tPos = [1 1 tgPos(3:4)-[6 30]];        
end

% --- determines if the metric (iSel) has data
function hasData = detIfHasData(iData,iSel)

% sets the default input arguments
if (nargin == 1); iSel = iData.tData.iSel(iData.cTab); end

% determines if the data array is empty (if not, then has data)
hasData = ~isempty(iData.tData.Data{iData.cTab}{iSel});

% --- updates the checkbox properties
function updateCheckboxProps(handles,iSelT)

% global variables
global nMetG

% retrieves the group count
iData = getappdata(handles.figDataOutput,'iData');
nApp = sum(iData.appOut(:,iData.cTab));

% retrieves the current metric selection
if (nargin == 1)
    [~,iSelT] = getSelectedIndexType(handles);
end

% initialisations
uDataD = isempty(get(handles.checkSepByDay,'UserData'));
uDataE = isempty(get(handles.checkSepByExpt,'UserData'));
uDataA = isempty(get(handles.checkSepByApp,'UserData'));

% sets the checkbox enabled properties
[isOKE,isOKD] = deal(iSelT == 2,any(iSelT == [2 4 6]));
setObjEnable(handles.checkSepByDay,(isOKD && uDataD && iData.sepDay))
setObjEnable(handles.checkSepByExpt,(isOKE && uDataE && iData.sepExp))
setObjEnable(handles.checkSepByApp,uDataA && (nApp > 1))
setObjEnable(handles.checkNumGroups,~any(iSelT == nMetG))
