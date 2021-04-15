function varargout = RegionAnomaly(varargin)
% Last Modified by GUIDE v2.5 03-Oct-2016 23:54:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @RegionAnomaly_OpeningFcn, ...
                   'gui_OutputFcn',  @RegionAnomaly_OutputFcn, ...
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

% --- Executes just before RegionAnomaly is made visible.
function RegionAnomaly_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for RegionAnomaly
handles.output = hObject;

% sets the input arguments
setappdata(hObject,'iMov',varargin{1});
setappdata(hObject,'sGlare',varargin{2});
setappdata(hObject,'pGlare',varargin{3});
setappdata(hObject,'pRegion',varargin{4});

% initialises the GUI objects
initGUIObjects(handles)
updateRejectFlags(handles)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes RegionAnomaly wait for user response (see UIRESUME)
uiwait(handles.figAnomRegion);

% --- Outputs from this function are returned to the command line.
function varargout = RegionAnomaly_OutputFcn(hObject, eventdata, handles) 

% global variables
global iMov

% Get default command line output from handles structure
varargout{1} = iMov;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% -------------------------------- %
% --- TABLE CALLBACK FUNCTIONS --- %
% -------------------------------- %

% --- Executes when entered data in editable cell(s) in tableReflectGlare.
function tableReflectGlare_CellEditCallback(hObject, eventdata, handles)

% retrieves the glare/ok boolean arrays
iMov = getappdata(handles.figAnomRegion,'iMov');

% retrieves the table data and the selected row
[Data,iRow] = deal(get(hObject,'Data'),eventdata.Indices(1));
iApp = Data{iRow,1};

% updates the subregion data struct
[iMov.ok(iApp),iMov.flyok(:,iApp)] = deal(~eventdata.NewData);
setappdata(handles.figAnomRegion,'iMov',iMov);

% --- Executes when entered data in editable cell(s) in tablePartGlare.
function tablePartGlare_CellEditCallback(hObject, eventdata, handles)

% retrieves the glare/ok boolean arrays
iMov = getappdata(handles.figAnomRegion,'iMov');

% retrieves the table data and the selected row
[Data,iRow] = deal(get(hObject,'Data'),eventdata.Indices(1));
iApp = Data{iRow,1};

% updates the subregion data struct
[iMov.ok(iApp),iMov.flyok(:,iApp)] = deal(~eventdata.NewData);
setappdata(handles.figAnomRegion,'iMov',iMov);

% --- Executes when entered data in editable cell(s) in tableAnomRegion.
function tableAnomRegion_CellEditCallback(hObject, eventdata, handles)

% retrieves the glare/ok boolean arrays
iMov = getappdata(handles.figAnomRegion,'iMov');

% retrieves the table data and the selected row
[Data,iRow] = deal(get(hObject,'Data'),eventdata.Indices(1));
iApp = Data{iRow,1};

% updates the ok/flyok rejection/acceptance flags based on the selection
if (isnumeric(Data{iRow,2}))
    % single tube is represented by the cell
    iMov.flyok(Data{iRow,2},iApp) = ~eventdata.NewData;
    iMov.ok(iApp) = any(iMov.flyok(:,iApp));
else
    % all tubes are represented by the cell
    [iMov.ok(iApp),iMov.flyok(:,iApp)] = deal(~eventdata.NewData);    
end

% update the sub-region data struct
setappdata(handles.figAnomRegion,'iMov',iMov);

% -------------------------------- %
% --- CONTROL BUTTON FUNCTIONS --- %
% -------------------------------- %

% --- Executes on button press in buttonClose.
function buttonClose_Callback(hObject, eventdata, handles)

% global variables
global iMov

% retrieves the sub-region data struct
iMov = getappdata(handles.figAnomRegion,'iMov');

% deletes the GUI
delete(handles.figAnomRegion);

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- updates the rejection flags from the glare/anaomolous region flags
function updateRejectFlags(handles)

% retrieves the sub-region data struct
iMov = getappdata(handles.figAnomRegion,'iMov');
sGlare = getappdata(handles.figAnomRegion,'sGlare');
pRegion = getappdata(handles.figAnomRegion,'pRegion');

% sets the reflection glare rejection flags
[iMov.ok(sGlare),iMov.flyok(:,sGlare)] = deal(false);

% sets the anaomalous frame rejection flags
iMov.flyok(pRegion) = false;
iMov.ok(~any(iMov.flyok,1)) = false;

% resets the sub-region data struct
setappdata(handles.figAnomRegion,'iMov',iMov);

% ---- initialises the GUI objects
function initGUIObjects(handles)

% parameters
[dY,dYT0,dYT1,dYTH] = deal(10,5,10,25);

% memory allocation
pPos = zeros(3,4);

% retrieves the glare/ok boolean arrays
sGlare = getappdata(handles.figAnomRegion,'sGlare');
pGlare = getappdata(handles.figAnomRegion,'pGlare');
pRegion = getappdata(handles.figAnomRegion,'pRegion');

% updates the anomalous panel/table properties
if (any(pRegion(:)))
    % sets the table data array
    DataA = getAnomTableData(pRegion);
    
    % reset the table position vector 
    tabPos = get(handles.tableAnomRegion,'position');
    tabPos(4) = calcTableHeight(size(DataA,1)); 
    
    % resets the panel position vector
    pPos(3,:) = get(handles.panelAnomRegion,'position');
    pPos(3,4) = tabPos(4) + (dYT1 + dYTH);
        
    % updates the table/panel properties
    set(handles.tableAnomRegion,'Data',DataA,'Position',tabPos)
    set(handles.panelAnomRegion,'Position',pPos(3,:))   
    autoResizeTableColumns(handles.tableAnomRegion);
else
    % if anomalous regions, then delete the panel
    delete(handles.panelAnomRegion)
end

% updates the glare reflection panel/table properties
if (any(pGlare))
    % sets the table data array
    DataG = [num2cell(find(pGlare)),num2cell(false(sum(pGlare),1))];
    
    % reset the table position vector 
    tabPos = get(handles.tablePartGlare,'position');
    tabPos(4) = calcTableHeight(sum(pGlare));        
    
    % resets the panel position vector
    pPos(2,:) = get(handles.panelPartGlare,'position');
    pPos(2,4) = tabPos(4) + (dYT1 + dYTH);
    
    % sets the bottom location of the panel
    if (pPos(3,2) == 0)
        pPos(2,2) = dYT0;
    else
        pPos(2,2) = sum(pPos(3,[2 4])) + dY;
    end    
    
    % updates the table/panel properties
    set(handles.tablePartGlare,'Data',DataG,'Position',tabPos,...
                               'ColumnFormat',{'numeric','logical'})
    set(handles.panelPartGlare,'Position',pPos(2,:))
    autoResizeTableColumns(handles.tablePartGlare);
else
    % if no glare, then delete the panel
    delete(handles.panelPartGlare)
end

% updates the glare reflection panel/table properties
if (any(sGlare))
    % sets the table data array
    DataG = [num2cell(find(sGlare)),num2cell(true(sum(sGlare),1))];
    
    % reset the table position vector 
    tabPos = get(handles.tableReflectGlare,'position');
    tabPos(4) = calcTableHeight(sum(sGlare)); 
    
    % resets the panel position vector
    pPos(1,:) = get(handles.panelReflectGlare,'position');
    pPos(1,4) = tabPos(4) + (dYT1 + dYTH);
    
    % sets the bottom location of the panel
    if (pPos(2,2) == 0)
        pPos(1,2) = dYT0;
    else
        pPos(1,2) = sum(pPos(2,[2 4])) + dY;
    end    
    
    % updates the table/panel properties
    set(handles.tableReflectGlare,'Data',DataG,'Position',tabPos,...
                                  'ColumnFormat',{'numeric','logical'})
    set(handles.panelReflectGlare,'Position',pPos(1,:))
    autoResizeTableColumns(handles.tableReflectGlare);
else
    % if no glare, then delete the panel
    delete(handles.panelReflectGlare)
end

% determines the first non-zero row
iRow = find(pPos(:,1) > 0,1,'first');

% retrieves the position vector for the static text
tPos = get(handles.textAnom,'position');
tPos(2) = sum(pPos(iRow,[2 4])) + dY;
set(handles.textAnom,'position',tPos);

% retrieves the button position
bPos = get(handles.buttonClose,'position');

% updates the outer panel position vector
pPosO = get(handles.panelOuter,'Position');
pPosO(4) = sum(tPos([2 4])) + dY;

% updates the figure position vector
fPos = get(handles.figAnomRegion,'position');
fPos(4) = sum(pPosO([2 4])) + dY;

% updates the other object properties
set(handles.figAnomRegion,'position',fPos);
set(handles.panelOuter,'Position',pPosO)
set(handles.buttonClose,'position',bPos)

% --- retrieves the anomalous data array
function DataA = getAnomTableData(pRegion)

% initialisation
DataS = [];

% determines if there are any regions that are all anomalous
eApp = find(all(pRegion,1));
if (~isempty(eApp))
    % if so, then append the data to the table
    for i = eApp
        DataS = [DataS;{i,' All Tubes'}];
        pRegion(:,i) = true;
    end
end

% determines the remaining regions that anomalous
[eFly,eApp] = find(pRegion);
if (~isempty(eFly))
    % if so, then append the data to the table
    for i = 1:length(eApp)
        DataS = [DataS;{eApp(i),eFly(i)}];
    end
end

% sorts the data array 
[~,ii] = sort(cell2mat(DataS(:,1)));
DataS = DataS(ii,:);

% sets the final column to the data array
DataA = [DataS,num2cell(true(size(DataS,1),1))];
