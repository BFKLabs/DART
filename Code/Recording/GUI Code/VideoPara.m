function varargout = VideoPara(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @VideoPara_OpeningFcn, ...
                   'gui_OutputFcn',  @VideoPara_OutputFcn, ...
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

% --- Executes just before VideoPara is made visible.
function VideoPara_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for VideoPara
handles.output = hObject;
setObjVisibility(hObject,'off'); pause(0.01)

% sets the input arguments
hMain = varargin{1};

% retrieves the imaq object and the program default struct
hFigM = hMain.figFlyRecord;
iProg = getappdata(hFigM,'iProg');
infoObj = getappdata(hFigM,'infoObj');

% sets the input arguments into the sub-GUI
setappdata(hObject,'infoObj',infoObj)
setappdata(hObject,'iProg',iProg)
setappdata(hObject,'hMain',hMain)

% disables the real-time tracking menu item (if available)
if isfield(hMain,'menuRTTrack')
    setappdata(hObject,'eStr0',get(hMain.menuRTTrack,'enable'));
    setObjEnable(hMain.menuRTTrack,'off')
    
    % sets the rotation checkbox flag
    isRot = getappdata(hMain.figFlyRecord,'isRot');
    set(handles.checkRotateVideo,'value',isRot)
end

% intialises the GUI panels and objects
initGUIObjects(handles,infoObj.objIMAQ); 
pause(0.1)
centreFigPosition(hObject);

% Update handles structure
guidata(hObject, handles);
setObjVisibility(hObject,'on'); 
pause(0.01)

% UIWAIT makes VideoPara wait for user response (see UIRESUME)
% uiwait(handles.figVideoPara);

% --- Outputs from this function are returned to the command line.
function varargout = VideoPara_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% ---------------------------------- %
% --- PARAMETER OBJECT CALLBACKS --- %
% ---------------------------------- %

% --- runs on editing one of the numerical parameters
function editCallback(hObject, eventdata, handles)

% retrieves the source object and related information
hFig = handles.figVideoPara;
srcInfo = get(hObject,'UserData');
srcObj = getappdata(hFig,'srcObj');
infoObj = getappdata(hFig,'infoObj');

% retrieves the previous/new values
prVal = get(srcObj,srcInfo.Name);
nwVal = str2double(get(hObject,'string'));

% retrieves the current parameters constraints values
srcInfoNw = propinfo(srcObj,srcInfo.Name);
nwLim = srcInfoNw.ConstraintValue;
isInt = all(mod(nwLim,1) == 0);

% check to see if the new value is valid
if chkEditValue(nwVal,nwLim,isInt)
    try
        % if so, then update the camera parameters
        set(srcObj,srcInfo.Name,nwVal)
        setappdata(handles.figVideoPara,'srcObj',srcObj);
        specialParaUpdate(handles,srcInfo.Name,nwVal)
        
        % enables the reset button
        setObjEnable(handles.buttonReset,'on')
    catch
        % outputs the error message and resets the to its previous values
        outputUpdateErrorMsg(infoObj.objIMAQ,srcInfo)               
        set(hObject,'string',num2str(prVal))
    end    
else
    % otherwise, reset to the previous value
    set(hObject,'string',num2str(prVal))
end

% --- runs on editing one of the enumeration parameters
function popupCallback(hObject, eventdata, handles)

% retrieves the source object and related information
hFig = handles.figVideoPara;
srcInfo = get(hObject,'UserData');
srcObj = getappdata(hFig,'srcObj');
infoObj = getappdata(hFig,'infoObj');

% retrieves the current property value
lStr = get(hObject,'String');
prVal = get(srcObj,srcInfo.Name);
nwVal = lStr{get(hObject,'value')};

try
    % updates the relevant field in the source object
    set(srcObj,srcInfo.Name,nwVal)
    setappdata(handles.figVideoPara,'srcObj',srcObj);
    specialParaUpdate(handles,srcInfo.Name,nwVal)

    % enables the reset button
    setObjEnable(handles.buttonReset,'on')
catch 
    % outputs the error message and resets the to its original values
    outputUpdateErrorMsg(infoObj.objIMAQ,srcInfo)       
    set(hObject,'Value',find(strcmp(lStr,prVal)))
end

% --- runs on updating editPauseTime
function editPauseTime_Callback(hObject, eventdata, handles)

% sets the new value and the parameter limits
nwVal = str2double(get(hObject,'string'));
nwLim = [5 600];

% retrieves the main gui handles and the experimental data struct
hMain = getappdata(handles.figVideoPara,'hMain');
iExpt = getappdata(hMain.figFlyRecord,'iExpt');

% check to see if the new value is valid
if chkEditValue(nwVal,nwLim,1)
    % if so, then update the video pause time (in the main GUI as well)
    iExpt.Timing.Tp = nwVal;
    setappdata(hMain.figFlyRecord,'iExpt',iExpt)
    setappdata(handles.figVideoPara,'hMain',hMain)
else
    % if not, the reset to the previous valid value
    set(hObject,'string',num2str(iExpt.Timing.Tp));
end

% ------------------------------- %
% --- PROGRAM CONTROL BUTTONS --- %
% ------------------------------- %

% --- Executes on button press in buttonLoad.
function buttonLoad_Callback(hObject, eventdata, handles)

% loads the required data structs/objects
srcObj = getappdata(handles.figVideoPara,'srcObj');
iProg = getappdata(handles.figVideoPara,'iProg');

% prompts the user for the camera preset file
[fName,fDir,fIndex] = uigetfile(...
    {'*.vpr','Video Preset Files (*.vpr)'},...
    'Load Stimulus Playlist File',iProg.CamPara);
if (fIndex ~= 0)    
    % loads the video preset data file
    vprData = importdata(fullfile(fDir,fName));
    
    % retrieves the source object information
    [srcInfo,fldNames] = combineDataStruct(propinfo(srcObj));   
    ii = ~cellfun(@(x)(strcmp(x,'Parent')),fldNames);
    
    % determines if the camera properties match that of the loaded file 
    if ~all(cellfun(@(x)(any(strcmp(vprData.fldNames,x))),fldNames(ii)))
        % if not, then exit with an error
        eStr = 'Camera presets do not match video properties.';
        waitfor(errordlg(eStr,'Invalid Camera Presets','modal'))
        return
    else
        % resets the parameter struct and updates the parameters
        pVal0 = [vprData.fldNames,vprData.pVal];
        setappdata(handles.figVideoPara,'pVal0',pVal0);
        buttonReset_Callback(handles.buttonReset, eventdata, handles)
    end
end

% --- Executes on button press in buttonSave.
function buttonSave_Callback(hObject, eventdata, handles)

% loads the required data structs/objects
srcObj = getappdata(handles.figVideoPara,'srcObj');
iProg = getappdata(handles.figVideoPara,'iProg');

% prompts the user for the camera preset file
[fName,fDir,fIndex] = uiputfile(...
    {'*.vpr','Video Preset Files (*.vpr)'},...
    'Save Stimulus Playlist File',iProg.CamPara);
if (fIndex ~= 0)
    % retrieves the current parameter values and field names
    fldNames = fieldnames(srcObj);
    pVal = get(srcObj,fldNames)';
    
    % removes the parent object from the struct
    ii = ~cellfun(@(x)(strcmp(x,'Parent')),fldNames);
    [fldNames,pVal] = deal(fldNames(ii),pVal(ii));
    
    % saves the field names/parameter values to file
    save(fullfile(fDir,fName),'pVal','fldNames')
end

% --- Executes on button press in buttonReset.
function buttonReset_Callback(hObject, eventdata, handles)

% retrieves the original parameters and the camera source object
hFig = handles.figVideoPara;
pVal0 = getappdata(hFig,'pVal0');
hMain = getappdata(hFig,'hMain');
srcObj = getappdata(hFig,'srcObj');
infoObj = getappdata(hFig,'infoObj');
vcObj = getappdata(hMain.figFlyRecord,'vcObj');
[srcInfo,fldName] = combineDataStruct(propinfo(srcObj));

% other initialisations
srcFld = field2cell(srcInfo,'Name');
[ignoreFld,ignoreName] = getIgnoredFieldInfo(infoObj);
wState = warning('off','all');

% determines if the video preview is running
vidOn = get(hMain.toggleVideoPreview,'Value');
if vidOn
    % if so, then turn it off
    toggleFcn = getappdata(hMain.figFlyRecord,'toggleVideoPreview');    
    set(hMain.toggleVideoPreview,'Value',false)
    toggleFcn(hMain.toggleVideoPreview,[],hMain);
end

% retrieves the field names and edit box/popup menu handles
hEdit = findobj(handles.figVideoPara,'Style','Edit');
hPopup = findobj(handles.figVideoPara,'Style','PopupMenu');

% resets the camera ROI (if necessary)
resetCameraROIPara(infoObj.objIMAQ);

% retrieves the parameter struct fieldnames
for i = 1:length(hEdit)
    % retrieves the editbox user data
    uData = get(hEdit(i),'UserData');
    if isstruct(uData) 
        isIgnore = strcmp(ignoreName,uData.Name);
        if any(isIgnore)
            % if the field is to be ignored, then use the fixed value
            pValEdit = ignoreFld{isIgnore}{2};
        else
            % otherwise, use the stored value
            indNw = strcmp(pVal0(:,1),uData.Name);
            pValEdit = pVal0{indNw,2};
        end

        % resets the camera properties and the editbox string
        try
            set(srcObj,uData.Name,pValEdit);
            set(hEdit(i),'string',num2str(pValEdit))
        catch
            pValNw = get(srcObj,uData.Name);
            set(hEdit(i),'string',num2str(pValNw))
        end
    end
end

% retrieves the parameter struct fieldnames
for i = 1:length(hPopup)
    % retrieves the editbox user data
    uData = get(hPopup(i),'UserData');    
    isIgnore = strcmp(ignoreName,uData.Name);
    if any(isIgnore)
        % if the field is to be ignored, then use the fixed value
        pValPopup = ignoreFld{isIgnore}{2};
    else
        % otherwise, use the stored value
        indNw = strcmp(pVal0(:,1),uData.Name);
        pValPopup = pVal0{indNw,2};
    end
    
    % resets the camera properties and the editbox string
    iSel = find(strcmp(pValPopup,uData.ConstraintValue));
    if ~isempty(iSel)
        set(srcObj,uData.Name,pValPopup);
        set(hPopup(i),'Value',iSel)
    end
end

% disables the update/reset buttons
setObjEnable(hObject,'off')

% resets the video properties (if calibrating)
if ~isempty(vcObj)
    vcObj.resetVideoProp()
end

% turns the video preview back on (if already on)
if vidOn
    set(hMain.toggleVideoPreview,'Value',true)    
    toggleFcn(hMain.toggleVideoPreview,[],hMain);
end

% reverts the warning back to their original state
warning(wState)

% --- Executes on button press in buttonClose.
function buttonClose_Callback(hObject, eventdata, handles)

% resets the real-time tracking menu item enabled properties (if available)
hMain = getappdata(handles.figVideoPara,'hMain');
if isfield(hMain,'menuRTTrack')
    hMainFig = hMain.menuRTTrack;
    setObjEnable(hMainFig,getappdata(handles.figVideoPara,'eStr0'))
end

% deletes the sub-GUI
delete(handles.figVideoPara)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the GUI panels and their constituent objects --- %
function initGUIObjects(handles,objIMAQ)

% creates a loadbar
h = ProgressLoadbar('Retrieving Camera Properties...');

% sets the horizontal/vertical gap sizes
[vGap,hGap] = deal(2,10);
[tWidN,tWidE,pWidN,pWidE] = deal(0);
[vGapP,hGapP,Wt,Wp] = deal(10,10,150,50);
pGap = [hGap vGap hGapP vGapP];
hFig = handles.figVideoPara;
hMain = getappdata(hFig,'hMain');

% determines if the video preview is running
vidOn = get(hMain.toggleVideoPreview,'Value');
if vidOn
    % if so, then turn it off
    toggleFcn = getappdata(hMain.figFlyRecord,'toggleVideoPreview');
    
    set(hMain.toggleVideoPreview,'Value',false)
    toggleFcn(hMain.toggleVideoPreview,[],hMain);
end

% retrieves the source object handle and the property information
sObj = getselectedsource(objIMAQ);
srcInfo = combineDataStruct(propinfo(sObj));

% retrieves the field names and the original property values
fType = field2cell(srcInfo,'Type');
fConstraint = field2cell(srcInfo,'Constraint');
fReadOnly = field2cell(srcInfo,'ReadOnly');                      

% determines which of parameters are manual/auto or numeric parameters
isEnum = strcmp(fType,'string') & strcmp(fConstraint,'enum') & ...
            ~strcmp(fReadOnly,'always'); 
isNum = (strcmp(fType,'double') | strcmp(fType,'integer')) & ...
            ~strcmp(fReadOnly,'always');

% if there are no valid parameters, then exit the function
if ~any(isEnum) && ~any(isNum)
    wStr = 'Camera does not have any feasible parameters!';
    waitfor(warndlg(wStr,'No Feasible Camera Parameters','modal'))    
    return
end

% sets up the numeric edit-box panel
if any(isNum)
    [tWidN,pWidN] = initNumericPanel(handles,srcInfo(isNum),sObj,pGap);
end

% sets up the enumeration popup-menu panel
if any(isEnum)
    [tWidE,pWidE] = initENumPanel(handles,srcInfo(isEnum),sObj,pGap,isNum);
end

% retrieves the current figure position
figPos = get(hFig,'Position');

% updates the figure position for the numerical parameters
hPanelN = findobj(hFig,'tag','panelNumPara');
if ~isempty(hPanelN)
    pPosN = get(hPanelN,'position');
    figPos(4) = figPos(4) + (pPosN(4) + vGapP);
    set(hPanelN,'Position',pPosN)
end

% updates the figure position for the enumeration parameters
hPanelE = findobj(hFig,'tag','panelENumPara');
if ~isempty(hPanelE)
    pPosE = get(hPanelE,'position');
    figPos(4) = figPos(4) + (pPosE(4) + vGapP);
    set(hPanelE,'Position',pPosE)
end

% updates the figure position
set(hFig,'Position',figPos)

% calculates the change in text/other parameter object widths
dWidT = max(0,max([tWidN,tWidE]) - Wt);  
dWidP = max(0,max([pWidN,pWidE]) - Wp);

% if there is a change, then update the gui object dimensions
if (dWidT > 0) || (dWidP > 0)
    % resets the object dimensions
    dWid = dWidT + dWidP;
    
    % resets the sizes of the panels/text objects
    hPanel = {hPanelN,hPanelE};
    for i = 1:length(hPanel)
        if ~isempty(hPanel{i})
            % retrieves the text, edit and popupmenu object handles
            resetPanelObjPos(hPanel{i},'text',dWidT,dWidP)
            resetPanelObjPos(hPanel{i},'edit',dWidT,dWidP)
            resetPanelObjPos(hPanel{i},'popupmenu',dWidT,dWidP)
        
            % resets the panel width
            resetObjPos(hPanel{i},'Width',2*dWid,1)
        end
    end
    
    % retrieves the control button information
    hBut = findall(hFig,'style','pushbutton');
    nBut = length(hBut);
    dWidBut = 2*dWid/nBut;
    posBut = cell2mat(get(hBut(:),'Position'));
    
    % resets the button dimensions
    hBut = hBut(argSort(posBut(:,1)));
    for i = 1:length(hBut)
        resetObjPos(hBut(i),'Width',dWidBut,1);
        resetObjPos(hBut(i),'Left',(i-1)*dWidBut,1);
    end
    
    % resets the other object dimensions
    resetObjPos(hFig,'Width',2*dWid,1)
    resetObjPos(handles.panelOtherPara,'Width',2*dWid,1); 
    resetObjPos(handles.editPauseTime,'Width',dWid,1); 
end

% sets the source object handle and original parameter values into the GUI
pStr = fieldnames(sObj);
setappdata(hFig,'srcObj',sObj);
setappdata(hFig,'pVal0',[pStr(:),get(sObj,pStr(:))'])

% updates the pause time string
hMain = getappdata(hFig,'hMain');
iExpt = getappdata(hMain.figFlyRecord,'iExpt');
set(handles.editPauseTime,'string',num2str(iExpt.Timing.Tp))

% turns the video preview back on (if already on)
if vidOn
    set(hMain.toggleVideoPreview,'Value',true)    
    toggleFcn(hMain.toggleVideoPreview,[],hMain);
end

% deletes the loadbar
try; delete(h); end

% --- resets the panel object positions
function resetPanelObjPos(hPanel,pStyle,dWidT,dWidP)

% retrieves the handles of the objects within the panel
hObj = findall(hPanel,'Style',pStyle);
if isempty(hObj)
    % if there are none, then exit the function
    return
end

% otherwise, retrieves the locations of the objects
pPos = get(hPanel,'Position');
pObj = cell2mat(get(hObj,'Position'));
isL = pObj(:,1) < 0.4*pPos(3);

% determines which objects are on the left side of the panel
if strcmpi(pStyle,'text')
    % case is the text objects
    arrayfun(@(x)(resetObjPos(x,'width',dWidT,1)),hObj)
    arrayfun(@(x)(resetObjPos(x,'left',dWidT+dWidP,1)),hObj(~isL))
    
else
    % case is the edit/popup objects
    arrayfun(@(x)(resetObjPos(x,'width',dWidP,1)),hObj)    
    arrayfun(@(x)(resetObjPos(x,'left',dWidT,1)),hObj(isL))
    arrayfun(@(x)(resetObjPos(x,'left',2*dWidT+dWidP,1)),hObj(~isL))
end

% -- sets the numerical parameter panel --- %
function [tWidMx,pWidMx] = initNumericPanel(handles,srcInfoNum,srcObj,pGap)

% removes the parameters which have no limit range
pLim = arrayfun(@(x)(double(x.ConstraintValue)),srcInfoNum(:),'un',0);
isFeas = diff(cell2mat(pLim),[],2) > 0;
srcInfoNum = srcInfoNum(isFeas);

% other initialisations
hFig = handles.figVideoPara;
srcFld = field2cell(srcInfoNum,'Name');
ignoreFld = getIgnoredFieldInfo(getappdata(hFig,'infoObj'));

% removes any of the fields which have been flagged for being ignored
isKeep = true(length(srcFld),1);
for i = 1:length(ignoreFld)
    % determines if the ignored field exists in the camera properties
    isKeepNw = ~strcmp(srcFld,ignoreFld{i}{1});
    isKeep = isKeep & isKeepNw;
    
    % if the field exists, then set the fixed field value
    if any(~isKeepNw)
        set(srcObj,ignoreFld{i}{1},ignoreFld{i}{2});
    end
end
                    
% determines the number of parameters to setup
srcInfoNum = srcInfoNum(isKeep);
nPara = length(srcInfoNum);
hFig = handles.figVideoPara;
[hGap,vGap,vGapP] = deal(pGap(1),pGap(2),pGap(4));
[nRow,nCol,pOfs,tWidMx,pWidMx,dpWid] = deal(ceil(nPara/2),2,15,0,0,5);

% sets the edit box/text box size 
[He,We] = deal(20,70);
[Ht,Wt] = deal(18,160);
lArr = char(8594);

% calculates the edit/text box left location and panel dimensions
[Le,Lt] = deal([(2*hGap+Wt) (4*hGap+2*Wt+We)],[hGap (3*hGap+Wt+We)]);
[Lpn,Bpn,Wpn] = deal(vGapP,100,5*hGap+2*(We+Wt));
Hpn = 20+(nRow*He + (nRow-1)*vGap + pOfs);

% initialises the panel
hP = uipanel('Title','NUMERICAL PARAMETERS','Units','pixels',...
             'FontWeight','bold','Parent',hFig,'tag','panelNumPara',...
             'BorderType','etchedin','FontUnits','pixels','FontSize',13,...
             'Position',[Lpn,Bpn,Wpn,Hpn]);      
         
% retrieves the field strings strings
tStr = splitUpperCase(field2cell(srcInfoNum,'Name'));
         
% for each of the rows/columns, add in the text/edit boxes
for i = 1:nRow
    for j = 1:nCol
        % sets the new linear index
        k = (i-1)*2 + j;
        if (k > nPara)
            % if the index is greater than the parameter count, then exit
            break
        end
        
        % sets the list strings and current parameter value           
        pLim = srcInfoNum(k).ConstraintValue;                
        
        % sets the tooltip string        
        if diff(pLim) > 0
            % increments the object counter and sets the current row/column
            % indices
            pVal = get(srcObj,srcInfoNum(k).Name); 
            ttStr = sprintf(['%s\n %s Lower Limit = %s',...
                             '\n %s Upper Limit = %s',...
                             '\n %s Initial Value = %s'],...
                            srcInfoNum(k).Name,lArr,num2str(pLim(1)),...
                            lArr,num2str(pLim(2)),lArr,num2str(pVal));

            % creates the new textbox
            Bt = (vGapP - 1) + (nRow-i)*(He + vGap);
            txtPosF = [Lt(j) Bt Wt Ht];
            hTxt = uicontrol('Style','text','Parent',hP,...
                             'Parent',hP,'HorizontalAlignment','Right',...
                             'String',tStr{k},'Fontweight','bold',...
                             'TooltipString',ttStr);
              
            % determines the size of the new text object
            editEx = get(hTxt,'Extent');
            tWidMx = max(tWidMx,editEx(3));
            set(hTxt,'Position',txtPosF);              

            % creates the new editbox
            Be = vGapP + (nRow-i)*(He + vGap);
            editPosF = [Le(j) Be We He];
            h = uicontrol('Style','edit','Parent',hP,...
                      'UserData',srcInfoNum(k),'BackgroundColor','w',...
                      'String',pVal,'HorizontalAlignment','Center',...
                      'TooltipString',ttStr);        

            % determines the size of the new text object
            editEx = get(h,'Extent');
            pWidMx = max(pWidMx,editEx(3));
            set(h,'Position',editPosF);                  

            % updates the editbox callback function
            bFunc = {@editCallback,handles};
            set(h,'Callback',bFunc);            
        end
    end
end         
        
% increases the popup max width
pWidMx = pWidMx + dpWid;

% -- sets the enumeration parameter panel --- %
function [tWidMx,pWidMx] = ...
                    initENumPanel(handles,srcInfoENum,srcObj,pGap,isNum)
                
% removes any enumeration parameters which only have 1 choice
cVal = field2cell(srcInfoENum,'ConstraintValue'); 
isMulti = cellfun(@length,cVal) > 1;
srcInfoENum = srcInfoENum(isMulti);

% other initialisations
hFig = handles.figVideoPara;
srcFld = field2cell(srcInfoENum,'Name');
ignoreFld = getIgnoredFieldInfo(getappdata(hFig,'infoObj'));

% removes any of the fields which have been flagged for being ignored
isKeep = true(length(srcFld),1);
for i = 1:length(ignoreFld)
    % determines if the ignored field exists in the camera properties
    isKeepNw = ~strcmp(srcFld,ignoreFld{i}{1});
    isKeep = isKeep & isKeepNw;
    
    % if the field exists, then set the fixed field value
    if any(~isKeepNw)
        set(srcObj,ignoreFld{i}{1},ignoreFld{i}{2});
    end
end
                
% determines the number of parameters to setup
srcInfoENum = srcInfoENum(isKeep);
nPara = length(srcInfoENum);
[hGap,vGap,vGapP] = deal(pGap(1),6,pGap(4));
[nRow,nCol,pOfs,tWidMx,pWidMx,dpWid] = deal(ceil(nPara/2),2,15,0,0,5);

% sets the edit box/text box height/width dimensions
[Hp,Wp] = deal(18,70);
[Ht,Wt] = deal(18,160);

% calculates the popup menu/text box left location and panel dimensions
[Lp,Lt] = deal([(2*hGap+Wt) (4*hGap+2*Wt+Wp)],[hGap (3*hGap+Wt+Wp)]);
[Lpe,Wpe,Hpe] = deal(vGapP,50+2*(Wp+Wt),20+(nRow*Hp+(nRow-1)*vGap+pOfs));

% calculates the panel bottom (depending on whether there are any numerical
% parameters for the camera or not)
if any(isNum)
    % if no numerical parameters, then set the default size
    pPos = get(findobj(hFig,'tag','panelNumPara'),'position');
    Bpe = (pPos(2)+pPos(4)) + vGapP;
else
    % if no numerical parameters, then set the default size
    Bpe = 100;
end

% initialises the panel
hP = uipanel('Title','ENUMERATION PARAMETERS','Units','pixels',...
             'FontWeight','bold','Parent',hFig,...
             'Position',[Lpe Bpe Wpe Hpe],'tag','panelENumPara',...
             'BorderType','etchedin','FontUnits','pixels','FontSize',13);

% retrieves the field strings strings
tStr = splitUpperCase(field2cell(srcInfoENum,'Name'));                         
         
% for each of the rows/columns, add in the text/edit boxes
for i = 1:nRow
    for j = 1:nCol
        % sets the new linear index
        k = (i-1)*2 + j;
        if (k > nPara)
            % if the index is greater than the parameter count, then exit
            break
        end
        
        % sets the list strings and current parameter value
        lStr = srcInfoENum(k).ConstraintValue; 
        
        try
            pVal = get(srcObj,srcInfoENum(k).Name);
        catch
            pVal = {'Not Applicable'};
        end
        
        % creates the new textbox
        Bt = (vGapP - 4) + (nRow-i)*(Hp + vGap);
        txtPosF = [Lt(j) Bt Wt Ht];
        hTxt = uicontrol('Style','text','Parent',hP,...
                         'HorizontalAlignment','Right',...
                         'String',tStr{k},'Fontweight','bold',...
                         'TooltipString',srcInfoENum(k).Name);
              
        % determines the size of the new text object
        txtEx = get(hTxt,'Extent');
        tWidMx = max(tWidMx,txtEx(3));
        set(hTxt,'Position',txtPosF);
              
        %
        iSel = find(strcmp(lStr,pVal));
        if isempty(iSel); iSel = 1; end
        
        % creates the new textbox
        Bp = vGapP + (nRow-i)*(Hp + vGap); 
        popPosF = [Lp(j) Bp Wp Hp];
        h = uicontrol('Style','popupmenu','BackgroundColor','w',...
                  'String',lStr,'Value',iSel,...
                  'HorizontalAlignment','Center','Parent',hP,...
                  'TooltipString',srcInfoENum(k).Name,...
                  'UserData',srcInfoENum(k)); 
              
        % determines the size of the new popup object
        popupEx = get(h,'Extent');
        pWidMx = max(pWidMx,popupEx(3));
        set(h,'Position',popPosF)
              
        % updates the editbox callback function
        bFunc = {@popupCallback,handles};                  
        set(h,'Callback',bFunc);              
    end
end

% increases the popup max width
pWidMx = pWidMx + dpWid;

% --- outputs the update error message
function outputUpdateErrorMsg(objIMAQ,srcInfo)

% if the update failed, then determine if the camera is previewing
if strcmp(get(objIMAQ,'Previewing'),'on')
    % if so, then prompt the user to turn off the camera
    eStr = sprintf(['The "%s" property can only be altered ',...
                    'when not previewing. Turn off ',...
                    'the video preview and try again.'],srcInfo.Name);
    waitfor(msgbox(eStr,'Video Property Update Error','modal'))
else
    % otherwise, a critical error has occured with the camera
    eStr = sprintf(['The "%s" property could not be ',...
                    'correctly. Please ensure the camera is ',...
                    'operating correctly and try again.'],srcInfo.Name);
    waitfor(errordlg(eStr,'Video Property Update Error','modal'))        
end

% --- post parameter update function (for a specific set of parameters)
function specialParaUpdate(handles,pName,pVal)

% memory allocation
hFig = handles.figVideoPara;
hMain = getappdata(hFig,'hMain');
infoObj = getappdata(hFig,'infoObj');
vcObj = getappdata(hMain.figFlyRecord,'vcObj');

% updates the video ROI (depending on camera type)
switch get(infoObj.objIMAQ,'Name')
    case 'Allied Vision 1800 U-501m NIR'
        switch pName
            case {'AutoModeRegionOffsetX','AutoModeRegionOffsetY',...
                  'AutoModeRegionWidth','AutoModeRegionHeight'}
                resetCameraROI(hMain,infoObj.objIMAQ)
        end
end

% if video calibrating is on, then update the calibration info
if ~isempty(vcObj)
    vcObj.appendVideoProp(pName,pVal);
end

% --- retrieves the ignored field information
function [ignoreFld,ignoreName] = getIgnoredFieldInfo(infoObj)

% initialisations
pROI = get(infoObj.objIMAQ,'ROIPosition');

% sets the ignored field information/names
ignoreFld = {{'AcquisitionFrameRateEnable','True'},...
             {'AutoModeRegionOffsetX',pROI(1)},...
             {'AutoModeRegionOffsetY',pROI(2)},...
             {'AutoModeRegionWidth',pROI(3)},...
             {'AutoModeRegionHeight',pROI(4)}};
ignoreName = cellfun(@(x)(x{1}),ignoreFld,'un',0);
