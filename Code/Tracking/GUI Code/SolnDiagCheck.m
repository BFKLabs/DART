function varargout = SolnDiagCheck(varargin)
% Last Modified by GUIDE v2.5 24-Dec-2015 20:05:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SolnDiagCheck_OpeningFcn, ...
                   'gui_OutputFcn',  @SolnDiagCheck_OutputFcn, ...
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

% --- Executes just before SolnDiagCheck is made visible.
function SolnDiagCheck_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for SolnDiagCheck
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% sets the input arguments
hGUI = varargin{1};

% parameters
Dtol0 = 10;

% initialises the object properties
pFldStr = {'jTabD','jTabN','jObjD','jObjN','cjTab','chTab',...
           'nNaN','Dfrm','Dtol','hGUI'};
initObjPropFields(hObject,pFldStr);

% sets the diagnostic metrics from the solution view GUI
hFigM = hGUI.output;
set(hObject,'nNaN',hFigM.nNaN,'Dfrm',hFigM.Dfrm,'Dtol',Dtol0,'hGUI',hGUI);

% sets the GUI object properties
setObjEnable(handles.buttonGoto,'off')
set(handles.editFrmDist,'string',num2str(Dtol0))

% sets the figure to be visible
setObjVisibility(hGUI.figFlySolnView,'off')
setObjVisibility(hObject,'on'); 
pause(0.05);

% initialises the table positions
hasNaN = updateNaNTable(handles);
hasD = updateDistTable(handles);
centreFigPosition(hObject);

% retrieves the distance table java objects (if created)
if hasD
    set(hObject,'jObjD',findjobj(handles.tableFrmDist)); 
    set(hObject,'jTabD',getJavaTable(handles.tableFrmDist)); 
end         

% retrieves the NaN frame table java objects (if created)
if hasNaN
    set(hObject,'jObjN',findjobj(handles.tableNaNCount)); 
    set(hObject,'jTabN',getJavaTable(handles.tableNaNCount)); 
end

% UIWAIT makes SolnDiagCheck wait for user response (see UIRESUME)
% uiwait(handles.figDiagCheck);

% --- Outputs from this function are returned to the command line.
function varargout = SolnDiagCheck_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- TABLE SELECTION CALLBACK FUNCTIONS --- %
% ------------------------------------------ %

% --- executes on editting editFrmDist
function editFrmDist_Callback(hObject, eventdata, handles)

% check to see if the new value is valid
nwVal = str2double(get(hObject,'string'));
if chkEditValue(nwVal,[10 inf],0)
    % if so, then update the value into the GUI
    set(handles.output,'Dtol',nwVal)
    updateDistTable(handles);
else
    % otherwise, reset the editbox to the original value
    set(hObject,'string',num2str(get(handles.output,'Dtol')))
end

% --- TABLE SELECTION CALLBACK FUNCTIONS --- %
% ------------------------------------------ %

% --- Executes when selected cell(s) is changed in tableNaNCount.
function tableNaNCount_CellSelectionCallback(hObject, eventdata, handles)

% if the indices are empty, then exit
if isempty(eventdata.Indices); return; end

% retrieves the java object handles
jTabD = get(handles.output,'jTabD');
jTabN = get(handles.output,'jTabN');

% removes the table selection for the other table
if ~isempty(jTabD)
    jTabD.changeSelection(-1,-1, false, false);
end

% updates the goto button enabled properties (frame index selection only)
setObjEnable(handles.buttonGoto',any(eventdata.Indices(2) == [4,5]))

% sets the current table handle
set(handles.output,'cjTab',jTabN,'chTab',hObject);

% --- Executes when selected cell(s) is changed in tableFrmDist.
function tableFrmDist_CellSelectionCallback(hObject, eventdata, handles)

% if the indices are empty, then exit
if isempty(eventdata.Indices); return; end

% retrieves the java object handles
jTabD = get(handles.output,'jTabD');
jTabN = get(handles.output,'jTabN');

% removes the table selection for the other table
if ~isempty(jTabN)
    jTabN.changeSelection(-1,-1, false, false);
end

% updates the goto button enabled properties (frame index selection only)
setObjEnable(handles.buttonGoto,eventdata.Indices(2) == 4)

% sets the current table handle
set(handles.output,'cjTab',jTabD,'chTab',hObject);

% --- PROGRAM CONTROL BUTTONS --- %
% ------------------------------- %

% --- Executes on button press in buttonGoto.
function buttonGoto_Callback(hObject, eventdata, handles)

% retrieves the main GUI object handles
hGUI = get(handles.output,'hGUI');
hGUIM = get(hGUI.figFlySolnView,'hGUI');

% retrieves the selected row/column indices
jTab = get(handles.output,'cjTab');
hTab = get(handles.output,'chTab');
[row,col] = deal(jTab.getSelectedRows+1,jTab.getSelectedColumns+1);

% retrieves the table data and updates the frame counter
Data = get(hTab,'Data');
set(hGUIM.frmCountEdit,'string',num2str(Data{row,col}));

% updates the main figure
feval(get(hGUIM.figFlyTrack,'dispImage'),hGUIM);
setObjEnable(hObject,'off')

% --- Executes on button press in buttonClose.
function buttonClose_Callback(hObject, eventdata, handles)

% retrieves the solution viewing GUI handles
hGUI = get(handles.output,'hGUI');

% deletes the GUI and makes the GUI visible again
delete(handles.output)
setObjVisibility(hGUI.figFlySolnView,'on');

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- OBJECT UPDATE FUNCTIONS --- %
% ------------------------------- %

% --- updates the distance tolerance table
function hasD = updateDistTable(handles)

% retrieves the relevant data arrays/values
Dfrm = get(handles.output,'Dfrm');
Dtol = get(handles.output,'Dtol');

% retrievesw the NaN panel/table and figure position vectors
pPos = get(handles.panelFrmDist,'position');
pPos2 = get(handles.panelNaNCount,'position');
tPos = get(handles.tableFrmDist,'position');
fPos = get(handles.figDiagCheck,'position');
txPos = get(handles.textFrmDist,'position');
edPos = get(handles.editFrmDist,'position');

% parameters
[yDel,fPosH,hasD] = deal(10,fPos(4),true);
setObjVisibility(handles.figDiagCheck,'off')

% determines the frames where distance is greater than tolerance
DfrmT = cellfun(@(x)(find(x > Dtol)),Dfrm,'un',0);

% determines the array entries where the NaN count is greater than zero
nDCount = cellfun('length',DfrmT);
if all(nDCount == 0)
    % resets the panel dimensions
    [hasD,pPos(4)] = deal(false,85);
    txPos2 = get(handles.textDispLbl,'position');
    
    % makes the table invisible 
    setObjVisibility(handles.tableFrmDist,'off')      
    txPos = [txPos(1) (2*yDel+txPos2(4)) txPos(3:4)];
    edPos = [edPos(1) (2*yDel+txPos2(4)+3) edPos(3:4)];
    set(handles.textDispLbl,'position',[txPos2(1) yDel txPos2(3:4)],...
                            'visible','on')
                        
else
    % determines the regions which have NaN values     
    nGrp = sum(nDCount(:));
    [iNaN,jNaN] = find(nDCount > 0);        
    
    % resets the table/panel dimensions
    tPos(4) = calcTableHeight(min(10,nGrp));
    pPos(4) = 65 + tPos(4);    
    txPos(2) = 2*yDel + tPos(4) + 3;
    edPos(2) = 2*yDel + tPos(4);
        
    % sets the data into the table
    [Data,tOfs] = deal(cell(length(jNaN),5),0);
    for i = 1:length(jNaN)        
        for j = 1:length(DfrmT{iNaN(i),jNaN(i)})
            % sets the apparatus and tube indices
            iFrmNw = DfrmT{iNaN(i),jNaN(i)}(j);
            Data{j+tOfs,2} = jNaN(i);                        
            [Data{j+tOfs,3},Data{j+tOfs,4}] = deal(iNaN(i),iFrmNw);            
            Data{j+tOfs,5} = Dfrm{iNaN(i),jNaN(i)}(iFrmNw);
        end
        
        % increments the table offset counter
        tOfs = tOfs + length(DfrmT{iNaN(i),jNaN(i)});
    end
    
    % sort arrays by distance (in descending order)
    [~,ii] = sort(cell2mat(Data(:,5)),'descend');
    Data = Data(ii,:); Data(:,1) = num2cell(1:size(Data,1));
    
    % resets the table properties
    set(handles.tableFrmDist,'visible','on','Data',Data,...
                'position',tPos,'columnwidth',getCWid(tPos(3),nGrp))
    setObjVisibility(handles.textDispLbl,'off')
    autoResizeTableColumns(handles.tableFrmDist);
end

% resets the panel/figure dimensions
pPos(2) = 25 + 2*yDel;
pPos2(2) = sum(pPos([2 4])) + yDel;
fPos(4) = pPos(4) + pPos2(4) + (25 + 4*yDel);
fPos(2) = fPos(2) + (fPosH - fPos(4));

% resets the panel/figure positions
set(handles.figDiagCheck,'position',fPos)
set(handles.panelFrmDist,'position',pPos) 
set(handles.panelNaNCount,'position',pPos2) 
set(handles.textFrmDist,'position',txPos)
set(handles.editFrmDist,'position',edPos)
setObjVisibility(handles.figDiagCheck,'on')

% --- updates the NaN count table
function hasNaN = updateNaNTable(handles)

% retrieves the relevant data arrays/values
nNaN = get(handles.output,'nNaN');
jObj = get(handles.output,'jObjN');

% retrievesw the NaN panel/table and figure position vectors
pPos = get(handles.panelNaNCount,'position');
tPos = get(handles.tableNaNCount,'position');

% parameters
hasNaN = true;

% determines the array entries where the NaN count is greater than zero
nNaNCount = cellfun('length',nNaN);
if (all(nNaNCount == 0))
    % resets the panel dimensions
    [hasNaN,pPos(4)] = deal(false,55);
    
    % makes the table invisible 
    setObjVisibility(handles.tableNaNCount,'off')   
else
    % determines the regions which have NaN values     
    nGrp = sum(nNaNCount(:));
    [iNaN,jNaN] = find(nNaNCount > 0);        
    
    % resets the table/panel dimensions
    tPos(4) = calcTableHeight(min(10,nGrp));
    pPos(4) = 35 + tPos(4);    
        
    % sets the data into the table
    [Data,tOfs] = deal(cell(length(jNaN),4),0);
    for i = 1:length(jNaN)        
        for j = 1:length(nNaN{iNaN(i),jNaN(i)})
            % sets the apparatus and tube indices
            Data{j+tOfs,1} = j+tOfs;
            [Data{j+tOfs,2},Data{j+tOfs,3}] = deal(jNaN(i),iNaN(i));
            Data{j+tOfs,4} = nNaN{iNaN(i),jNaN(i)}{j}(1);
            Data{j+tOfs,5} = nNaN{iNaN(i),jNaN(i)}{j}(end);
        end
        
        % increments the table offset counter
        tOfs = tOfs + length(nNaN{iNaN(i),jNaN(i)});
    end
    
    % resets the table properties
    set(handles.tableNaNCount,'visible','on','Data',Data,...
                'position',tPos,'columnwidth',getCWid(tPos(3),nGrp))
    autoResizeTableColumns(handles.tableNaNCount);            
end

% resets the table position
set(handles.panelNaNCount,'position',pPos) 

% --- retrieves the column widths for the tables
function cWid = getCWid(Wtot,nGrp)

% global variables
global W0T

% resets the column widths
if (nGrp <= 10)
    cWid = [40,84,64,84];
else
    cWid = [40,80,60,79];
end

% calculates the final column width and converts array to a cell array
cWid(end+1) = Wtot - (sum(cWid)+W0T);
cWid = num2cell(cWid);
