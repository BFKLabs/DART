function varargout = BackgroundPara(varargin)
% Last Modified by GUIDE v2.5 20-Nov-2020 18:57:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @BackgroundPara_OpeningFcn, ...
                   'gui_OutputFcn',  @BackgroundPara_OutputFcn, ...
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

% --- Executes just before BackgroundPara is made visible.
function BackgroundPara_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for BackgroundPara
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% sets the input arguments
iMov = varargin{1};

% sets the parameter struct into the GUI
setappdata(hObject,'iMov',iMov)
setappdata(hObject,'iMov0',iMov)
setappdata(hObject,'isInit',false)
setappdata(hObject,'bgP',DetectPara.getDetectionPara(iMov))
setappdata(hObject,'bgP0',DetectPara.initDetectParaStruct('All'))

% initalises the object properties
initObjProps(handles)
centreFigPosition(hObject);
setappdata(hObject,'isInit',true)

% UIWAIT makes BackgroundPara wait for user response (see UIRESUME)
uiwait(handles.figBGPara);

% --- Outputs from this function are returned to the command line.
function varargout = BackgroundPara_OutputFcn(hObject, eventdata, handles)

% global parameters
global bgPNw 

% Get default command line output from handles structure
varargout{1} = bgPNw;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% ------------------------------------- %
% --- GUI OBJECT CALLBACK FUNCTIONS --- %
% ------------------------------------- %

% --- callback function for the edit box objects --- %
function editCallback(hObject, eventdata, handles)

% retrieves the global parameter struct
hFig = handles.figBGPara;
bgP = getappdata(hFig,'bgP');
pStr = get(hObject,'userdata');

% sets the parameter field string based on the algorithm type
if strContains(bgP.algoType,'single')
    % case is the single object detection
    pStrF = 'pSingle';
else
    % case is the multi object detection
    pStrF = 'pMulti';
end

% sets the parameter limits/integer flags
switch pStr
    % phase detection parameters
    case 'histTol' % histogram overlap tolerance
        [pStrF,nwLim,isInt] = deal('pPhase',[0.05,0.50],0);
    case 'rsmeTol' % RSME difference tolerance
        [pStrF,nwLim,isInt] = deal('pPhase',[0.01,0.10],0);
    case 'nImgR' % case is the phase detection initial frame count
        [pStrF,nwLim,isInt] = deal('pPhase',[5,20],1);
    case 'nFrmMin' % case is the minimum frame difference
        [pStrF,nwLim,isInt] = deal('pPhase',[10,100],1);        
    
    % tracking detection parameters
        
%     case ('P') % case is the glare range
%         [nwLim,isInt] = deal([0.01 0.40],0);
%     case ('Pmx') % case is the pixel threshold proportion
%         [nwLim,isInt] = deal([0.50 1.00],0);        
%     case ('PmxTol') % case is the column count threshold proportion
%         [nwLim,isInt] = deal([0.01 1.00],0);        
%     case ('pDel') % case is the median CDF pixel range
%         [nwLim,isInt] = deal([5 40],1);
%     case ('pTolLo') % case is the lower CDF threshold limit
%         [nwLim,isInt] = deal([0.01 0.49],0);
%     case ('pTolHi') % case is the upper CDF threshold limit
%         [nwLim,isInt] = deal([0.51 0.99],0);        
%     case ('AvgTol') % case is the average image pixel intensity tolerance
%         [nwLim,isInt] = deal([1.0 30.0],0);
%     case ('IqrTol') % case is the IQR range tolerance
%         [nwLim,isInt] = deal([1.0 20.0],0);        
%     case ('pOrder') % case is the SVM polynomial order
%         [nwLim,isInt] = deal([3 10],1);                                
%     case ('sFac') % case is the SVM scale factor
%         [nwLim,isInt] = deal([0.1 10.0],0);        
%     case ('pTolDD') % proportional tolerance
%         [nwLim,isInt] = deal([0.90 0.99],0);           
end

% determines if the new value is valid
nwVal = str2double(get(hObject,'string'));
if chkEditValue(nwVal,nwLim,isInt)
    % updates the parameter struct
    eval(sprintf('bgP.%s.%s = nwVal;',pStrF,pStr))
    setappdata(hFig,'bgP',bgP)
    
    % set the enabled update button   
    setObjEnable(handles.buttonUpdate,'on')
    setObjEnable(handles.buttonReset,'on')
else
    % resets the string to the previous value
    set(hObject,'string',eval(sprintf('bgP.%s.%s',pStrF,pStr)))
end

% ------------------------------ %
% --- CONTROL BUTTON UPDATES --- %
% ------------------------------ %

% --- Executes on button press in buttonUpdate.
function buttonUpdate_Callback(hObject, eventdata, handles)

% global parameters
global bgPNw

% retrieves the parameter struct
bgPNw = getappdata(handles.figBGPara,'bgP');

% prompts the user if they want to update the default parameter file
qStr = 'Do you want to also update the default parameter file?';
uChoice = questdlg(qStr,'Update Default Parameters?','Yes','No','Yes');
if strcmp(uChoice,'Yes')
    % if so, the update the parameter file
    pFile = getParaFileName('ProgPara.mat');  
    
    % updates the file
    A = load(pFile);
    A.bgP = bgPNw;
    save(pFile,'-struct','A')
end

% deletes the GUI
delete(handles.figBGPara)

% --- Executes on button press in buttonReset.
function buttonReset_Callback(hObject, eventdata, handles)

% prompts the user if they wish to update the struct
tStr = 'Reset Background Estimation Parameters?';
uChoice = questdlg(['Are sure you want to use the default detection ',...
                    'parameters?'],tStr,'Yes','No','Yes');
if ~strcmp(uChoice,'Yes')
    % if the user cancelled, then exit the function
    return
end

% retrieves the original detection parameters
hFig = handles.figBGPara;
bgP = getappdata(hFig,'bgP');
bgP0 = getappdata(hFig,'bgP0');

% updates the phase detection parameter
bgP = setParaEditValues(handles,bgP,bgP0,'pPhase');
if strContains(bgP.algoType,'single')
    % case is single object detection
    bgP = setParaEditValues(handles,bgP,bgP0,'pSingle');
else
    % case is multi object detection
    bgP = setParaEditValues(handles,bgP,bgP,'pMulti');
end

% sets the change flag to true and disables the reset/update buttons
setObjEnable(hObject,'off')
setObjEnable(handles.buttonUpdate,'on')

% updates the background parameters
setappdata(hFig,'bgP',bgP)

% --- Executes on button press in buttonClose.
function buttonClose_Callback(hObject, eventdata, handles)

% global parameters
global bgPNw

% if the update button is enabled, then prompt the user if they want to
% update the parameters
if (strcmp(get(handles.buttonUpdate,'enable'),'on'))
    uChoice = questdlg('Do you wish to update the parameters?',...
                       'Update Parameters?','Yes','No','Cancel','Yes');
    switch (uChoice)
        case ('Yes') % user has clicked yes
            buttonUpdate_Callback([], [], handles)
            return
            
        case ('No') % user has clicked no
            % sets an empty parameter struct
            bgPNw = deal([]);
            
            % resets the SVM images to original 
            iMov0 = getappdata(handles.figBGPara,'iMov0');
            setappdata(handles.figBGPara,'iMov',iMov0);            
                                    
        otherwise
            return
    end
end

% deletes the GUI
delete(handles.figBGPara)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initalises the GUI object properties
function initObjProps(handles)

% global variables
global algoType 

% initialisations
hFig = handles.figBGPara;
bgP = getappdata(hFig,'bgP');
bgP0 = getappdata(hFig,'bgP0');

% sets up the boolean flags
isDD = strContains(bgP.algoType,'dd-');

% initialises the algorithm type strings
switch bgP.algoType
    case 'bgs-single'
        algoStr = 'BG Subtraction (Single)';
    case 'bgs-multi'
        algoStr = 'BG Subtraction (Multi)';
    case 'dd-single'
        algoStr = 'Direct Detect (Single)';
    case 'dd-multi'
        algoStr = 'Direct Detect (Multiple)';
end

% sets the algorithm string
set(handles.textAlgoType,'string',algoStr)

% algorithm type
algoType = {'Direct Detect';'BG Subtraction'};
nAlgo = length(algoType);

% sets the initial tab position vector
hTabG = createTabPanelGroup(handles.panelAlgoPara,1);
tabPos = getTabPosVector(handles.panelAlgoPara,[5,5,-10,30]);
set(hTabG,'Position',tabPos,'tag','hTabG')       

% sets the editbox callback functions
hEditP = findall(handles.panelPhasePara,'style','edit');
for i = 1:length(hEditP)
    % retrieves the value of the parameter field
    pStr = get(hEditP(i),'UserData');
    strNw = num2str(eval(sprintf('bgP.pPhase.%s',pStr)));
    
    % updates the editbox properties
    set(hEditP(i),'Callback',{@editCallback,handles},'String',strNw);
end

% creates the new tab panels    
hTabP = cell(nAlgo,1);
for j = 1:nAlgo
    % creates the new tab panel
    hTabP{j} = createNewTabPanel(hTabG,1,'title',algoType{j},'UserData',j);
   
    % updates the panel properties
    hPanel = findall(hFig,'UserData',algoType{j});
    set(hPanel,'parent',hTabP{j})
end

% disables the background subtraction tab (if using DD algorithm)
if isDD
    % determines the index of the bg subtraction
    iSelBG = find(strcmp(algoType,'BG Subtraction'));        
    try
        % case is the generation 1 tab objects
        setObjEnable(hTabP{iSelBG},'off'); 
    catch        
        % case is the generation 2 tab objects
        jTab = findjobj(hTabG);
        jTab = jTab(arrayfun(@(x)(...
                        strContains(class(x),'MJTabbedPane')),jTab));                      
        jTab.setEnabledAt(iSelBG-1,0)
    end
end

% retrieves the tracking parameter sub-field
if strContains(bgP.algoType,'single')
    pFld = bgP.pSingle;
else
    pFld = bgP.pMulti;
end

% sets the parameter values for the tracking parameters
pFldStr = fieldnames(pFld);
for i = 1:length(pFldStr)
    hEditT = findall(hPanelT,'style','edit','userdata',pFldStr{i});
    set(hEditT,'String',num2str(eval(sprintf('pFld.%s',pFldStr{i}))),...
               'Callback',{@editCallback,handles})    
end

% disables the update button
setObjEnable(handles.buttonUpdate,'off')
setObjEnable(handles.buttonReset,~isequal(bgP,bgP0))

% --- sets the parameter values/fields for a particular sub-field, pStr
function bgP = setParaEditValues(handles,bgP,bgP0,pStr)

% initialisations
hFig = handles.figBGPara;

% retrieves the field strings
pFld = getFieldValue(bgP0,pStr);
pFldStr = fieldnames(pFld);

% updates the parameter editbox/fields
for i = 1:length(pFldStr)
    % retrieves the editbox handle corresponding to the parameter
    hEdit = findall(hFig,'UserData',pFldStr{i});
    if ~isempty(hEdit)
        % retrieves the field value from the sub-struct
        nwVal = getFieldValue(pFld,pFldStr{i});
        
        % updates the corresponding editbox and parameter field
        set(hEdit,'string',num2str(nwVal))
        bgP = setFieldValue(bgP,pFldStr{i},nwVal);
    end
end
