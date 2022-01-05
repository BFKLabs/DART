function varargout = StartPoint(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @StartPoint_OpeningFcn, ...
                   'gui_OutputFcn',  @StartPoint_OutputFcn, ...
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


% --- Executes just before StartPoint is made visible.
function StartPoint_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for StartPoint
handles.output = hObject;

% sets the input arguments
trkObj = varargin{1};

% loads the progress data file
A = load(getParaFileName('ProgPara.mat'));

% sets the data structs into the GUI
setappdata(hObject,'trkObj',trkObj)
setappdata(hObject,'nFrmS',getFrameStackSize)
setappdata(hObject,'iDataS',initDataStruct(handles,trkObj))

% initialises the object properties
initObjProps(handles)

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes StartPoint wait for user response (see UIRESUME)
uiwait(handles.figStartPoint);


% --- Outputs from this function are returned to the command line.
function varargout = StartPoint_OutputFcn(hObject, eventdata, handles) 

% global variables
global indStart

% Get default command line output from handles structure
varargout{1} = indStart;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes when user attempts to close figStartPoint.
function figStartPoint_CloseRequestFcn(hObject, eventdata, handles)

% closes the figure via the cancel function
buttonCancel_Callback(handles.buttonCancel,[],handles)

%-------------------------------------------------------------------------%
%                        OBJECT CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes when selected object is changed in panelStartPoint.
function panelStartPoint_SelectionChangedFcn(hObject, eventdata, handles)

% retrieves the handle of the selected radio button
if ischar(eventdata)
    hRadio = get(hObject,'SelectedObject');
else
    hRadio = eventdata.NewValue;
end   

% updates the object properties based on the selection
isFrameSel = strcmp(get(hRadio,'tag'),'radioStartFrame');
setObjEnable(handles.editFrame,isFrameSel)
setPanelProps(handles.panelStartPhase,~isFrameSel)

% sets the table background colour based on the selection
if isFrameSel
    % case is the global frame is selected
    bgCol = 0.81*[1,1,1];
else
    % case is the phase/stack is selected
    nStackTrk = getappdata(handles.output,'nStackTrk');
    nStackTot = getappdata(handles.output,'nStackTot');
    
    % sets the table background colours
    prTrk = nStackTrk./nStackTot;
    bgCol0 = {[1,0,0],[1,1,0],[0,1,0]};
    trkType = 1 + (prTrk > 0) + (prTrk == 1);
    bgCol = cell2mat(arrayfun(@(x)(bgCol0{x}),trkType(:),'un',0));
    
    % highlights the selected row
    iData = getappdata(handles.output,'iDataS');
    bgCol(iData.Phase,:) = 0.75*bgCol(iData.Phase,:);
end

% updates the table background colour
set(handles.tablePhaseInfo,'BackgroundColor',bgCol)

% --- Executes on updating parameter editboxes
function editParaUpdate(hEdit, eventdata, h)

% retrieves the important data structs
hFig = h.figStartPoint;
isTrk = getappdata(hFig,'isTrk');
nStackTot = getappdata(hFig,'nStackTot');
nStackTrk = getappdata(hFig,'nStackTrk');
[iDataS,iData0] = deal(getappdata(hFig,'iDataS'));
hPanelS = h.panelStartPoint;

% retrieves the parameter limits (based on type)
pStr = get(hEdit,'UserData');
switch pStr
    case 'Phase' % case is the start frame
        
        % determines the feasible max phase count
        nPhMax = find(nStackTrk > 0,1,'last');
        if nStackTrk(nPhMax)/nStackTot(nPhMax) == 1
            % if the phase is fully tracked, then start on the next phase
            nPhMax = min(length(nStackTot),nPhMax+1);
        end
        
        % sets the phase limits
        nwLim = [1,nPhMax];        
        
    case 'Stack' % case is the start stack
        nwLim = [1,max(1,nStackTrk(iDataS.Phase))];
        
    case 'Frame' % case is the start frame
        nwLim = [1,length(isTrk)];
        
end

% resets the lower limit if the upper limit is zero
if nwLim(2) == 0; nwLim(1) = 0; end

% determines if the new value is 
nwVal = str2double(get(hEdit,'string'));
if chkEditValue(nwVal,nwLim,true)
    % if so, then update the parameter struct
    eval(sprintf('iDataS.%s = nwVal;',pStr));   
    
    % updates the other fields based on the parameter being altered
    switch pStr
        case 'Frame' % case is the frame index
            % determines if the selected frame has been tracked
            if ~isTrk(nwVal)
                % if not, output an error to screen
                eStr = sprintf(['Error! The selected frame has not ',...
                                'yet been tracked.\nTry again with ',...
                                'an untracked frame index.']);
                waitfor(msgbox(eStr,'Invalid Frame Index','modal'))
                
                % resets to the last valid value and exits
                set(hEdit,'string',num2str(iData0.Frame)) 
                return
            else            
                % otherwise, update the phase/stack fields
                [iDataS.Phase,iDataS.Stack] = calcPhaseIndex(h,nwVal);
                set(h.editPhase,'string',num2str(iDataS.Phase))
                set(h.editStack,'string',num2str(iDataS.Stack))
            end
            
        case 'Phase' % case is the phase index
            % resets the stack index
            if iDataS.Stack > nStackTot(iDataS.Phase)
                iDataS.Stack = nStackTot(iDataS.Phase);
                set(h.editStack,'string',num2str(iDataS.Stack))                
            end
            
            % resets the frame index
            iDataS.Frame = calcFrameIndex(h,iDataS.Phase,iDataS.Stack);                
            set(h.editFrame,'string',num2str(iDataS.Frame))                    
            
        otherwise % case is the stack index
            iDataS.Frame = calcFrameIndex(h,iDataS.Phase,iDataS.Stack);
            set(h.editFrame,'string',num2str(iDataS.Frame))
            
    end
    
    % updates the data struct
    setappdata(hFig,'iDataS',iDataS)
    if strcmp(pStr,'Phase')
        panelStartPoint_SelectionChangedFcn(hPanelS,'1',h)
    end
    
else
    % otherwise, reset the parameter to the last valid value
    set(hEdit,'string',num2str(eval(sprintf('iDataS.%s',pStr))))
end

% --- Executes on button press in buttonCont.
function buttonCont_Callback(hObject, eventdata, handles)

% global variables
global indStart

% returns an empty data struct
iDataS = getappdata(handles.figStartPoint,'iDataS');
indStart = [iDataS.Phase,iDataS.Stack];

% deletes the GUI
delete(handles.figStartPoint)

% --- Executes on button press in buttonCancel.
function buttonCancel_Callback(hObject, eventdata, handles)

% global variables
global indStart

% returns an empty data struct
indStart = [];

% deletes the GUI
delete(handles.figStartPoint)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the object properties
function initObjProps(handles)

% global variables
global H0T HWT

% retrieves the data structs
dX = 10;
hFig = handles.figStartPoint;
iDataS = getappdata(hFig,'iDataS');
trkObj = getappdata(hFig,'trkObj');
iMov = trkObj.iMov;

% object handles
hEditF = handles.editFrame;
hTable = handles.tablePhaseInfo;
hPanelS = handles.panelStartPoint;
hPanelP = handles.panelStartPhase;

% initialises the editbox object properties
fStr = fieldnames(iDataS);
for i = 1:length(fStr)
    % retrieves the editbox handle
    hEdit = eval(sprintf('handles.edit%s',fStr{i}));
    
    % sets the callback function and values
    cbFcn = {@editParaUpdate,handles};
    pVal = eval(sprintf('iDataS.%s;',fStr{i}));
    set(hEdit,'Callback',cbFcn,'String',num2str(pVal))
end

% determines the frames that have been tracked
nPh = length(iMov.vPhase);
iPh = iMov.iPhase(trkObj.iPhaseS,:);
iApp0 = find(trkObj.iMov.ok,1,'first');
iTube0 = find(trkObj.iMov.flyok(:,iApp0),1,'first');
isTrk = ~isnan(trkObj.pData.fPos{iApp0}{iTube0}(:,1));

% determines the total number of stacks per phase
nFrmS = diff(iPh,[],2) + 1;
nStackTot = ceil(nFrmS/trkObj.nFrmS);

% determines the number of tracked stacks per phase
nStackTrk = ceil(cellfun(@(x)(sum(isTrk(x(1):x(2)))),...
                        num2cell(iPh,2))/trkObj.nFrmS);    

setappdata(hFig,'isTrk',isTrk);
setappdata(hFig,'nStackTrk',nStackTrk);
setappdata(hFig,'nStackTot',nStackTot);

% determines if the video is multi-phase. reduce the GUI if not
if nPh == 1
    % calculates the change in height for the remaining objects
    pPos = get(handles.radioStartFrame,'Position');
    dHght = dX - pPos(2);    
    
    % makes the phase objects invisible
    setObjVisibility(handles.radioStartFrame,0)
    setObjVisibility(handles.radioStartPhase,0)  
    setObjVisibility(handles.textStartPhase,0)
    setObjVisibility(handles.panelStartPhase,0)
    
    % retrieves the non-panel object handles
    hObj = findall(hPanelS);
    hObj = hObj(hObj ~= hPanelS);
    
    % resets the height of the objects
    resetObjPos(hObj,'Bottom',dHght,1)
    resetObjPos(hPanelS,'Height',dHght,1)    
    resetObjPos(hFig,'Height',dHght,1)
    set(handles.radioStartFrame,'Value',1)
    
else
    % case is there are multiple phases
    
    % initialisations
    hObj = [findall(handles.panelStartPoint,'UserData',1);hEditF];
    
    % determines the change in the GUI object heights/locations 
    tPos0 = get(hTable,'Position');
    dtHght = H0T + nPh*HWT - tPos0(4);
    
    % resets the object positions
    resetObjPos(hFig,'Height',dtHght,1)
    resetObjPos(hTable,'Height',dtHght,1)
    resetObjPos(hPanelS,'Height',dtHght,1)
    resetObjPos(hPanelP,'Height',dtHght,1)
    resetObjPos(hObj,'Bottom',dtHght,1)                            
                        
    % sets the table data/properties
    tData = num2cell([(1:nPh)',iPh,nStackTrk,nStackTot]);
    set(hTable,'Data',tData);            
    
    % runs the start point selection callback function
    panelStartPoint_SelectionChangedFcn(hPanelS, '1', handles)    
end

% --- initialises the data struct
function iDataS = initDataStruct(handles,trkObj)

% calculates the frame index
[iPhase0,iStack0] = deal(trkObj.iPhase0,max(1,trkObj.nCountS));
iFrm0 = calcFrameIndex(handles,iPhase0,iStack0);

% sets up the data struct
iDataS = struct('Phase',iPhase0,'Stack',iStack0,'Frame',iFrm0);
setappdata(handles.figStartPoint,'iFrm0',iFrm0)

% --- calculates the frame index (from the phase/stack indices)
function iFrm0 = calcFrameIndex(handles,iPhase0,iStack0)

% retrieves the important values from the GUI
nFrmS = getappdata(handles.figStartPoint,'nFrmS');
trkObj = getappdata(handles.figStartPoint,'trkObj');
nFrmMx = size(trkObj.pData.fPos{1}{1},1);

% calculates the start frame index
jPhase = trkObj.iPhaseS(iPhase0);
iFrm0 = min(nFrmMx,trkObj.iMov.iPhase(jPhase,1)+nFrmS*(iStack0-1));

% --- calculates the phase/stack indices (from the frame index)
function [iPhase0,iStack0] = calcPhaseIndex(handles,iFrm0)

% retrieves the important values from the GUI
nFrmS = getappdata(handles.figStartPoint,'nFrmS');
trkObj = getappdata(handles.figStartPoint,'trkObj');

% calculates the phase/stack indices
iPhase0 = find(cellfun(@(x)(any(x==iFrm0)),trkObj.iFrmG(trkObj.iPhaseS)));
iPhaseS0 = trkObj.iPhaseS(iPhase0);
iStack0 = max(1,ceil((iFrm0-trkObj.iMov.iPhase(iPhaseS0,1))/nFrmS));
