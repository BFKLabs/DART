function varargout = CompareExptOld(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CompareExptOld_OpeningFcn, ...
                   'gui_OutputFcn',  @CompareExptOld_OutputFcn, ...
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


% --- Executes just before CompareExptOld is made visible.
function CompareExptOld_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for CompareExptOld
handles.output = hObject;

% sets the input arguments
setappdata(hObject,'sInfo',varargin{1});

% initialises the object properties
initObjProps(handles)

% centres the gui figure
centreFigPosition(hObject,1,0)
set(hObject,'CloseRequestFcn',{@figCompExpt_CloseRequestFcn,handles});

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes CompareExptOld wait for user response (see UIRESUME)
% uiwait(handles.figCompExpt);

% --- Outputs from this function are returned to the command line.
function varargout = CompareExptOld_OutputFcn(hObject, eventdata, handles)

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%


% --- Executes when user attempts to close figCompExpt.
function figCompExpt_CloseRequestFcn(hObject, eventdata, handles)

% Hint: delete(hObject) closes the figure
menuClose_Callback(handles.menuClose, [], handles)

%-------------------------------------------------------------------------%
%                         MENU CALLBACK FUNCTIONS                         %
%-------------------------------------------------------------------------%

% -------------------------------------------------------------------------
function menuClose_Callback(hObject, eventdata, handles)

% deletes the GUI
delete(handles.figCompExpt);

%-------------------------------------------------------------------------%
%                        OBJECT CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- callback function for selecting the experiment info tabs
function tabSelectedGrp(hObj,eventdata,handles,indG)

% object retrieval
hFig = handles.figCompExpt;
hTabGrpL = get(hObj,'Parent');
sInfo = getappdata(hFig,'sInfo');
iTab = get(hObj,'UserData');

% determines the compatible experiment info
if ~exist('indG','var')
    cObj = getappdata(hFig,'cmpObj');
    indG = cObj.detCompatibleExpts(); 
end

% resets the panel information
resetExptInfo(handles,indG{iTab}(1))

% resets the listbox parent object
hList = findall(hTabGrpL,'tag','hGrpList');
lStr = cellfun(@(x)(getExptName(x)),sInfo(indG{iTab}),'un',0);
set(hList,'Parent',hObj,'String',lStr(:));

% --- callback function for updating a criteria checkbox value
function checkUpdate(hObject, eventdata, handles)

% updates the criteria checkbox values
cObj = getappdata(handles.figCompExpt,'cmpObj');
cObj.setCritCheck(get(hObject,'UserData'),get(hObject,'Value'))

% object retrieval
updateGroupLists(handles);

% --- callback function for editing editMaxDiff
function editMaxDiff_Callback(hObject, eventdata, handles)

% object retrieval
hFig = handles.figCompExpt;
cObj = getappdata(hFig,'cmpObj');
nwVal = str2double(get(hObject,'String'));

% determines if the new value is valid
if chkEditValue(nwVal,[1,100],0)
    % if so, update the parameter struct
    cObj.setParaValue('pDur',nwVal);
    
    % updates compatibility flags
    cObj.calcCompatibilityFlags(5);
    updateGroupLists(handles)
else
    % otherwise, revert back to the last valid value
    set(hObject,'String',num2str(cObj.getParaValue('pDur')));
end

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the GUI object properties
function initObjProps(handles)

% parameters
dX = 5;
dZ = 4;
exHght0 = 45;
hghtObj = 20;
iHdr = [1,6,7];

% object retrieval
hFig = handles.figCompExpt;
hPanelEx = handles.panelExptComp;
hPanelGrp = handles.panelGroupingInfo;
hPanelGrpL = handles.panelGroupLists;
hPanelGrpC = handles.panelGroupingCrit;
hTxtH = findall(hPanelEx,'style','text');
uistack(hTxtH,'top')

% memory allocation and other initialisations
sInfo = getappdata(hFig,'sInfo');

% creates the experiment comparison object
cmpObj = ExptCompObj(hFig);
setappdata(hFig,'cmpObj',cmpObj);

% ------------------------------------------- %
% --- EXPERIMENT INFORMATION OBJECT SETUP --- %
% ------------------------------------------- %

% memory allocation
[nInfo,nHdr] = deal(length(sInfo),length(hTxtH));
[hTxt,hChk] = deal(cell(nInfo,nHdr-1),cell(nInfo,1));

% updates the height of the experiment comparison panel
pPosEx0 = get(hPanelEx,'Position');
hghtNew = exHght0 + nInfo*hghtObj;
resetObjPos(hPanelEx,'height',hghtNew);

% resets the height of 
dHght = hghtNew-pPosEx0(4);
resetObjPos(hFig,'height',dHght,1)
resetObjPos(hPanelGrp,'bottom',dHght,1)    

% creates the text label/checkbox objects for each loaded experiment
for i = 1:nHdr
    % retrieves the column header text object
    hTxtHnw = findall(hTxtH,'UserData',i);        
    pTxtH = get(hTxtHnw,'Position');
    [xTxt,wTxt] = deal(pTxtH(1),pTxtH(3));     
    
    % creates the objects for the current information column
    for j = 1:nInfo        
        % sets the object position vector
        yTxt = dX + (nInfo-j)*hghtObj;        
        pTxtNw = [xTxt,yTxt,wTxt,hghtObj - dZ*(i<nHdr)];
        
        % creates the object based on the column
        if i == nHdr
            % case is creating a checkbox
            pTxtNw(1) = xTxt+(pTxtNw(3)-hghtObj)/2;            
            hChk{j} = uicontrol(hPanelEx,'style','checkbox',...
                        'string',[],'Position',pTxtNw,'enable',...
                        'inactive','horizontalalignment','center');
        else
            % case is creating a text label
            hTxt{j,i} = uicontrol(hPanelEx,'style','text',...
                        'string','N/A','Position',pTxtNw,...
                        'horizontalalignment','center',...
                        'FontUnits','Pixels','FontWeight','bold',...
                        'FontSize',12);            
        end
    end
    
    % repositions the     
    resetObjPos(hTxtHnw,'Bottom',dHght,1);        
    if any(i == iHdr)
        jTxtHnw = findjobj(hTxtHnw);
        jTxtHnw.setVerticalAlignment(javax.swing.JLabel.CENTER);
    end           
end

% updates the object arrays within the GUi
setappdata(hFig,'hTxt',hTxt)
setappdata(hFig,'hChk',hChk)

% sets the comparison strings for each of the experiments
iC = 1:5;
cellfun(@(h,x)(set(h,'String',x)),hTxt(:,iC),cmpObj.expData(:,iC,1));

% --------------------------------------------- %
% --- EXPERIMENT GROUPING INFORMATION SETUP --- %
% --------------------------------------------- %

% determines the compatible experiment info
indG = cmpObj.detCompatibleExpts();

% sets the object positions
tabPosL = getTabPosVector(hPanelGrpL,[5,5,-10,-5]);
hTabGrpL = createTabPanelGroup(hPanelGrpL,1);
set(hTabGrpL,'position',tabPosL,'tag','hTabGrpL'); 
setappdata(hFig,'hTabGrpL',hTabGrpL)

% updates the grouping lists
updateGroupLists(handles,indG)

% sets the criteria checkbox callback functions
hChkL = findall(hPanelGrpC,'style','checkbox');
arrayfun(@(x)(set(hChkL,'Callback',{@checkUpdate,handles})),hChkL)

% sets the other parameters
set(handles.editMaxDiff,'string',num2str(cmpObj.getParaValue('pDur')));

% --- updates the group list tabs
function updateGroupLists(handles,indG)

% object retrieval
hFig = handles.figCompExpt;
hPanelGrpL = handles.panelGroupLists;
hTabGrpL = getappdata(hFig,'hTabGrpL');
hTab0 = get(hTabGrpL,'Children');

% sets the default input arguments
if ~exist('indG','var')
    cObj = getappdata(hFig,'cmpObj');
    indG = cObj.detCompatibleExpts();
end

% array dimensions
[nGrp,nTab] = deal(length(indG),length(hTab0));

% creates the new tab panel
for i = (nTab+1):nGrp
    tStr = sprintf('Group #%i',i);
    hTabNw = createNewTabPanel(hTabGrpL,1,'title',tStr,'UserData',i);
    set(hTabNw,'ButtonDownFcn',{@tabSelectedGrp,handles})
end

% retrieves the group list
hList = findall(hPanelGrpL,'tag','hGrpList');
if isempty(hList)
    % sets up the listbox positional vector
    tabPos = get(hTabGrpL,'Position');    
    lPos = [5,5,tabPos(3)-15,tabPos(4)-35];
    
    % creates the listbox object
    hTabNw = findall(hTabGrpL,'UserData',1);
    hList = uicontrol('Style','Listbox','Position',lPos,...
                             'tag','hGrpList','Max',2,'Value',[],...
                             'enable','Inactive');
    set(hList,'Parent',hTabNw)
end

% removes any extra tab panels
for i = (nGrp+1):nTab
    % determines the tab to be removed
    hTabRmv = findall(hTab0,'UserData',i);
    if isequal(hTabRmv,get(hTabGrpL,'SelectedTab'))
        % if the current tab is also selected, then change the tab to the
        % very first tab
        hTabNw = findall(hTab0,'UserData',1);
        set(hTabGrpL,'SelectedTab',hTabNw)
        set(hList,'Parent',hTabNw);
    end
    
    % deletes the tab
    delete(hTabRmv);
end

% updates the tab information
hTabS = get(hTabGrpL,'SelectedTab');
tabSelectedGrp(hTabS,[],handles,indG);

% --- resets the panel information for the experiment index, iExpt
function resetExptInfo(handles,iExp)

% initialisations
hFig = handles.figCompExpt;
hTxt = getappdata(hFig,'hTxt');
hChk = getappdata(hFig,'hChk');
cObj = getappdata(hFig,'cmpObj');

% other initialisations
isS = cObj.iSel;
nExp = cObj.getParaValue('nExp');
[~,isComp] = cObj.detCompatibleExpts();
iCT = 1+(1:size(cObj.cmpData,2));
[col,gCol] = deal({'r','b','g'},0.5*ones(1,3));

% sets up the object colours
objCol = repmat({'r'},nExp,1);
objCol(isComp{iExp}) = {'g'};
cellfun(@(h,c)(set(h,'ForegroundColor',c)),hTxt(:,1),objCol)

% updates the text object colours
for i = 1:nExp
    % updates the stimuli protocol comparison strings
    isC = isComp{iExp}(i);
    set(hTxt{i,end},'String',cObj.expData{i,6,iExp})
    set(hChk{i},'Value',isC);
    
    % resets the text object foreground colours
    cellfun(@(h,x)(set(h,'ForegroundColor',col{1+x*(1+isC)})),...
                    hTxt(i,iCT(isS)),num2cell(cObj.cmpData(i,isS,iExp)))
    cellfun(@(h,x)(set(h,'ForegroundColor',gCol)),...
                    hTxt(i,iCT(~isS)),num2cell(cObj.cmpData(i,~isS,iExp)))                        
end

% --- retrieves the experiment name (based on solution file type)
function expName = getExptName(sInfo)

switch sInfo.iTab
    case 1
        % case is a video solution file directory
        expName = getFinalDirString(sInfo.sFile);
    case 2
        % case is a single experimental solution file
        expName = getFileName(sInfo.sFile);
    case 3
        % case is an experimental file from a multi-solution file
        expName = sInfo.expFile;
end

% --- retrieves the currently selected tab handle
function hTab = getSelectedTab(hFig)

hTab = get(getappdata(hFig,'hTabGrpL'),'SelectedTab');
