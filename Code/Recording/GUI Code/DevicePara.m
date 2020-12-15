function varargout = DevicePara(varargin)
% Last Modified by GUIDE v2.5 27-Nov-2016 15:52:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DevicePara_OpeningFcn, ...
                   'gui_OutputFcn',  @DevicePara_OutputFcn, ...
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

% --- Executes just before DevicePara is made visible.
function DevicePara_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for DevicePara
handles.output = hObject;

% sets the inputs into the GUI
setappdata(hObject,'hGUI',varargin{1})

% initialises the GUI objects
initGUIObjects(handles)

% Update handles structure
guidata(hObject, handles);

% makes the GUI modal
set(hObject,'WindowStyle','modal')

% UIWAIT makes DevicePara wait for user response (see UIRESUME)
% uiwait(handles.figDevicePara);

% --- Outputs from this function are returned to the command line.
function varargout = DevicePara_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                         MENU CALLBACK FUNCTIONS                         %
%-------------------------------------------------------------------------%

% -------------------------------------------------------------------------
function menuExit_Callback(hObject, eventdata, handles)

% deletes the GUI
delete(handles.figDevicePara)

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes when entered data in editable cell(s) in tableDevicePara.
function tableDevicePara_CellEditCallback(hObject, eventdata, handles)

% check to see if a valid selection was made
if (isempty(eventdata.Indices))
    % if no indices selected, then exit the function
    return
else
    % sets the row/column indices that were altered
    hGUI = getappdata(handles.figDevicePara,'hGUI');
    [iStim,hGUIH] = deal(getappdata(hGUI,'iStim'),guidata(hGUI));
        
    % sets the limits
    [iRow,iCol] = deal(eventdata.Indices(1),eventdata.Indices(2));
    switch (iCol)
        case (1) % case is the actuator min voltage
            [nwLim,isInt,pStr] = deal([0 iStim.oPara(iRow).vMax],0,'vMin');
        case (2) % case is the actuator max voltage
            dInfo = getappdata(hGUI,'objDACInfo');
            if (strcmp(dInfo.BoardNames{iRow},'STMicroelectronics STLink Virtual COM Port'))
                vMax = 3.5;
            else
                vMax = 5;
            end
            
            [nwLim,isInt,pStr] = deal([iStim.oPara(iRow).vMin vMax],0,'vMax');
        case (3) % case is the actuator sample rate            
            [nwLim,isInt,pStr] = deal([0 100],1,'sRate');
    end
    
    % check to see if the new parameter value is valid
    nwVal = eventdata.NewData;    
    if (chkEditValue(nwVal,nwLim,isInt))
        % if so, update the parameter struct
        eval(sprintf('iStim.oPara(iRow).%s = nwVal;',pStr));                
        setappdata(hGUI,'iStim',iStim);
                
        % resets the window style to normal
        set(handles.figDevicePara,'WindowStyle','normal')
        
        % updates the stimulus plot                
        feval(getappdata(hGUI,'updateStimGraph'),hGUIH);        
        if (any(iCol == [1 2]))
            feval(getappdata(hGUI,'updateStimTrainPlot'),hGUIH,iStim)
        end
        
        % resets the window style to normal
        uistack(handles.figDevicePara,'top'); pause(0.05);
        set(handles.figDevicePara,'WindowStyle','modal')        
    else
        % otherwise, reset the table with the previous value
        Data = get(hObject,'Data');
        Data{iRow,iCol} = eventdata.PreviousData;
        set(hObject,'Data',Data);        
    end
end

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the GUI objects
function initGUIObjects(handles)

% global variables
global H0T HWT
X0 = 10;

% initialisations
hGUI = getappdata(handles.figDevicePara,'hGUI');
[iStim,dInfo] = deal(getappdata(hGUI,'iStim'),getappdata(hGUI,'objDACInfo'));
[nDACObj,oPara] = deal(length(iStim.oPara),iStim.oPara);
[isDAC,cWid] = deal(~strcmp(dInfo.dType,'Serial'),{106,106,126});
cName = {'Min Voltage (V)','Max Voltage (V)','Sample Rate (Hz)'};

% sets the data values for each 
Data = cell(nDACObj,2+isDAC);
for i = 1:nDACObj
    Data(i,1:2) = num2cell([oPara(i).vMin oPara(i).vMax]);
    if (isDAC); Data{i,3} = oPara(i).sRate; end
end

% sets the table row names
rowName = cellfun(@(x)(sprintf('Device #%i',x)),...
                            num2cell(1:nDACObj)','un',false);
tPos = [X0*[1 1],(100+sum(cell2mat(cWid(1:(2+isDAC))))),(H0T+nDACObj*HWT)];
pPos = [X0*[1 1],tPos(3:4)+2*X0];   

% sets the table data
resetObjPos(handles.figDevicePara,'width',pPos(3)+2*X0)
resetObjPos(handles.figDevicePara,'height',pPos(4)+2*X0)
set(handles.panelStimDevice,'position',pPos)
set(handles.tableDevicePara,'Data',Data,'RowName',rowName,...
                'ColumnWidth',cWid(1:(2+isDAC)),'Position',tPos,...
                'ColumnName',cName(1:(2+isDAC)))
                        
% resizes the table                        
autoResizeTableColumns(handles.tableDevicePara);                        
