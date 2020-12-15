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
set(hObject,'visible','off'); pause(0.01)

% sets the input arguments
hMain = varargin{1};

% retrieves the imaq object and the program default struct
objIMAQ = getappdata(hMain.figFlyRecord,'objIMAQ');
iProg = getappdata(hMain.figFlyRecord,'iProg');

% sets the input arguments into the sub-GUI
setappdata(hObject,'objIMAQ',objIMAQ)
setappdata(hObject,'iProg',iProg)
setappdata(hObject,'hMain',hMain)

% disables the real-time tracking menu item (if available)
if (isfield(hMain,'menuRTTrack'))
    setappdata(hObject,'eStr0',get(hMain.menuRTTrack,'enable'));
    set(hMain.menuRTTrack,'enable','off')
    
    % sets the rotation checkbox flag
    isRot = getappdata(hMain.figFlyRecord,'isRot');
    set(handles.checkRotateVideo,'value',isRot)
end

% intialises the GUI panels and objects
initGUIObjects(handles,objIMAQ); pause(0.1)
centreFigPosition(hObject);

% Update handles structure
guidata(hObject, handles);
set(hObject,'visible','on'); pause(0.01)

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
objIMAQ = getappdata(handles.figVideoPara,'objIMAQ');
srcObj = getappdata(handles.figVideoPara,'srcObj');
srcInfo = get(hObject,'UserData');

% % stops the video object
% if (isrunning(objIMAQ))
%     stop(objIMAQ); pause(0.2);
% end

% retrieves the new input value
nwVal = str2double(get(hObject,'string'));

% check to see if the new value is valid
if (chkEditValue(nwVal,srcInfo.ConstraintValue,1))
    % if so, then update the camera parameters
    set(srcObj,srcInfo.Name,nwVal)
    setappdata(handles.figVideoPara,'srcObj',srcObj);
    
    % enables the reset button
    set(handles.buttonReset,'enable','on')
else
    % otherwise, reset to the previous value
    set(hObject,'string',num2str(get(srcObj,srcInfo.Name)))
end

% --- runs on editing one of the enumeration parameters
function popupCallback(hObject, eventdata, handles)

% retrieves the source object and related information
objIMAQ = getappdata(handles.figVideoPara,'objIMAQ');
srcObj = getappdata(handles.figVideoPara,'srcObj');
srcInfo = get(hObject,'UserData');

% % stops the video object
% if (isrunning(objIMAQ))
%     stop(objIMAQ); pause(0.2);
% end

% updates the relevant field in the source object
lStr = get(hObject,'String');
set(srcObj,srcInfo.Name,lStr{get(hObject,'value')})
setappdata(handles.figVideoPara,'srcObj',srcObj);

% enables the reset button
set(handles.buttonReset,'enable','on')

% --- runs on updating editPauseTime
function editPauseTime_Callback(hObject, eventdata, handles)

% sets the new value and the parameter limits
nwVal = str2double(get(hObject,'string'));
nwLim = [5 600];

% retrieves the main gui handles and the experimental data struct
hMain = getappdata(handles.figVideoPara,'hMain');
iExpt = getappdata(hMain.figFlyRecord,'iExpt');

% check to see if the new value is valid
if (chkEditValue(nwVal,nwLim,1))
    % if so, then update the video pause time (in the main GUI as well)
    iExpt.Timing.Tp = nwVal;
    setappdata(hMain.figFlyRecord,'iExpt',iExpt)
    setappdata(handles.figVideoPara,'hMain',hMain)
else
    % if not, the reset to the previous valid value
    set(hObject,'string',num2str(iExpt.Timing.Tp));
end

% --- Executes on button press in checkRotateVideo.
function checkRotateVideo_Callback(hObject, eventdata, handles)

% retrieves the main gui handles and the experimental data struct
hMain = getappdata(handles.figVideoPara,'hMain');

% updates the flag/properties based on the main GUI type
if (isfield(hMain,'figFlyRecord'))
    % case is running from the recording GUI
        
    % updates the rotation flag
    setappdata(hMain.figFlyRecord,'isRot',get(hObject,'value'))
    if (get(hMain.toggleVideoPreview,'value'))
        % if the preview is running, stop/restart the video preview        
        togglePrev = getappdata(hMain.figFlyRecord,'toggleVideoPreview');
        
        set(hMain.toggleVideoPreview,'value',false)
        togglePrev(hMain.toggleVideoPreview, 1, hMain); pause(0.05);
        
        set(hMain.toggleVideoPreview,'value',true)
        togglePrev(hMain.toggleVideoPreview, 1, hMain); 
    end
    
    % returns focus to the video parameter GUI
    figure(handles.figVideoPara);    
else
    % case is running from the tracking GUI
    
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
    if (~all(cellfun(@(x)(any(strcmp(vprData.fldNames,x))),fldNames(ii))))
        % if not, then exit with an error
        eStr = 'Camera presets do not match video properties.';
        waitfor(errordlg(eStr,'Invalid Camera Presets','modal'))
        return
    else
        % resets the parameter struct and updates the parameters
        setappdata(handles.figVideoPara,'pVal0',[vprData.fldNames,vprData.pVal]);
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
pVal0 = getappdata(handles.figVideoPara,'pVal0');
srcObj = getappdata(handles.figVideoPara,'srcObj');
[srcInfo,fldName] = combineDataStruct(propinfo(srcObj));

% retrieves the field names and edit box/popup menu handles
hEdit = findobj(handles.figVideoPara,'Style','Edit');
hPopup = findobj(handles.figVideoPara,'Style','PopupMenu');

% retrieves the parameter struct fieldnames
for i = 1:length(hEdit)
    % retrieves the editbox user data
    uData = get(hEdit(i),'UserData');
    if (isstruct(uData))
        indNw = find(strcmp(pVal0(:,1),uData.Name));

        % resets the camera properties and the editbox string
        try
        set(srcObj,uData.Name,pVal0{indNw,2});
        set(hEdit(i),'string',num2str(pVal0{indNw,2}))
        catch
            a = 1;
        end
    end
end

% retrieves the parameter struct fieldnames
for i = 1:length(hPopup)
    % retrieves the editbox user data
    uData = get(hPopup(i),'UserData');
    indNw = find(strcmp(pVal0(:,1),uData.Name));
    
    % resets the camera properties and the editbox string
    set(srcObj,uData.Name,pVal0{indNw,2});
    set(hPopup(i),'Value',find(strcmp(pVal0{indNw,2},uData.ConstraintValue)))
end

% disables the update/reset buttons
set(hObject,'enable','off')

% --- Executes on button press in buttonClose.
function buttonClose_Callback(hObject, eventdata, handles)

% resets the real-time tracking menu item enabled properties (if available)
hMain = getappdata(handles.figVideoPara,'hMain');
if (isfield(hMain,'menuRTTrack'))
    set(hMain.menuRTTrack,'enable',getappdata(handles.figVideoPara,'eStr0'))
end

% deletes the sub-GUI
delete(handles.figVideoPara)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the GUI panels and their constituent objects --- %
function initGUIObjects(handles,objIMAQ)

% sets the horizontal/vertical gap sizes
[vGap,hGap] = deal(2,10);
[vGapP,hGapP] = deal(10,10);
pGap = [hGap vGap hGapP vGapP];

% retrieves the source object handle and the property information
srcObj = getselectedsource(objIMAQ);
srcInfo = combineDataStruct(propinfo(srcObj));

% retrieves the field names and the original property values
fType = field2cell(srcInfo,'Type');
fConstraint = field2cell(srcInfo,'Constraint');
fReadOnly = field2cell(srcInfo,'ReadOnly');
                                                                                
% determines which of parameters are manual/auto or numeric parameters
isEnum = strcmp(fType,'string') & ...
            strcmp(fConstraint,'enum') & ~strcmp(fReadOnly,'always'); 
isNumeric = (strcmp(fType,'double') | strcmp(fType,'integer')) & ~strcmp(fReadOnly,'always');

% if there are no valid parameters, then exit the function
if (~any(isEnum) && ~any(isNumeric))
    wStr = 'Camera does not have any feasible parameters!';
    waitfor(warndlg(wStr,'No Feasible Camera Parameters','modal'))    
    return
end

% sets up the numeric edit-box panel
if (any(isNumeric))
    initNumericPanel(handles,srcInfo(isNumeric),srcObj,pGap);
end

% sets up the enumeration popup-menu panel
if (any(isEnum))
    try
        initENumPanel(handles,srcInfo(isEnum),srcObj,pGap,isNumeric);
    catch
        a = 1;
    end
end

% retrieves the current figure position
figPos = get(handles.figVideoPara,'Position');

% updates the figure position for the numerical parameters
hPanelN = findobj(handles.figVideoPara,'tag','panelNumPara');
if (~isempty(hPanelN))
    pPosN = get(hPanelN,'position');
    figPos(4) = figPos(4) + (pPosN(4) + vGapP);
    set(hPanelN,'Position',pPosN)
end

% updates the figure position for the enumeration parameters
hPanelE = findobj(handles.figVideoPara,'tag','panelENumPara');
if (~isempty(hPanelE))
    pPosE = get(hPanelE,'position');
    figPos(4) = figPos(4) + (pPosE(4) + vGapP);
    set(hPanelE,'Position',pPosE)
end

% updates the figure position
set(handles.figVideoPara,'Position',figPos)

% sets the source object handle and original parameter values into the GUI
pStr = fieldnames(srcObj);
setappdata(handles.figVideoPara,'srcObj',srcObj);
setappdata(handles.figVideoPara,'pVal0',[pStr(:),get(srcObj,pStr(:))'])

% updates the pause time string
hMain = getappdata(handles.figVideoPara,'hMain');
iExpt = getappdata(hMain.figFlyRecord,'iExpt');
set(handles.editPauseTime,'string',num2str(iExpt.Timing.Tp))

% -- sets the numerical parameter panel --- %
function initNumericPanel(handles,srcInfoNum,srcObj,pGap)

% determines the number of parameters to setup
[hGap,vGap,vGapP] = deal(pGap(1),pGap(2),pGap(4));
nPara = length(srcInfoNum);
[nRow,nCol,pOfs] = deal(ceil(nPara/2),2,15);

% sets the edit box/text box size 
[He,We] = deal(20,70);
[Ht,Wt] = deal(18,160);

% calculates the edit/text box left location and panel dimensions
[Le,Lt] = deal([(2*hGap+Wt) (4*hGap+2*Wt+We)],[hGap (3*hGap+Wt+We)]);
[Lpn,Bpn,Wpn] = deal(vGapP,100,5*hGap+2*(We+Wt));
Hpn = 20+(nRow*He + (nRow-1)*vGap + pOfs);

% initialises the panel
hP = uipanel('Title','NUMERICAL PARAMETERS','Units','pixels',...
             'FontWeight','bold','Parent',handles.figVideoPara,...
             'Position',[Lpn Bpn Wpn Hpn],'tag','panelNumPara',...
             'BorderType','etchedin','FontUnits','pixels','FontSize',13);

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
        pVal = get(srcObj,srcInfoNum(k).Name);             
        
        % creates the new textbox
        Bt = (vGapP - 1) + (nRow-i)*(He + vGap);
        uicontrol('Style','text','Parent',hP,'Position',[Lt(j) Bt Wt Ht],...
                  'Parent',hP,'HorizontalAlignment','Right',...
                  'String',tStr{k},'Fontweight','bold')           
        
        % creates the new editbox
        Be = vGapP + (nRow-i)*(He + vGap);
        h = uicontrol('Style','edit','Parent',hP,'Position',[Le(j) Be We He],...
                  'HorizontalAlignment','Center','UserData',srcInfoNum(k),...
                  'String',pVal,'BackgroundColor','w');        
              
        % updates the editbox callback function
        bFunc = @(h,e)VideoPara('editCallback',h,[],handles);                  
        set(h,'Callback',bFunc);
    end
end         
         
% -- sets the enumeration parameter panel --- %
function initENumPanel(handles,srcInfoENum,srcObj,pGap,isNum)

% determines the number of parameters to setup
[hGap,vGap,vGapP] = deal(pGap(1),6,pGap(4));
nPara = length(srcInfoENum);
[nRow,nCol,pOfs] = deal(ceil(nPara/2),2,15);

% sets the edit box/text box height/width dimensions
[Hp,Wp] = deal(18,70);
[Ht,Wt] = deal(18,160);

% calculates the popup menu/text box left location and panel dimensions
[Lp,Lt] = deal([(2*hGap+Wt) (4*hGap+2*Wt+Wp)],[hGap (3*hGap+Wt+Wp)]);
[Lpe,Wpe,Hpe] = deal(vGapP,50+2*(Wp+Wt),20+(nRow*Hp+(nRow-1)*vGap+pOfs));

% calculates the panel bottom (depending on whether there are any numerical
% parameters for the camera or not)
if (any(isNum))
    % if no numerical parameters, then set the default size
    pPos = get(findobj(handles.figVideoPara,'tag','panelNumPara'),'position');
    Bpe = (pPos(2)+pPos(4)) + vGapP;
else
    % if no numerical parameters, then set the default size
    Bpe = 100;
end

% initialises the panel
hP = uipanel('Title','ENUMERATION PARAMETERS','Units','pixels',...
             'FontWeight','bold','Parent',handles.figVideoPara,...
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
        pVal = get(srcObj,srcInfoENum(k).Name);
        
        % creates the new textbox
        Bt = (vGapP - 4) + (nRow-i)*(Hp + vGap);
        uicontrol('Style','text','Parent',hP,'Position',[Lt(j) Bt Wt Ht],...
                  'HorizontalAlignment','Right',...
                  'String',tStr{k},'Fontweight','bold')
              
        % creates the new textbox
        Bp = vGapP + (nRow-i)*(Hp + vGap);           
        h = uicontrol('Style','popupmenu','Parent',hP,'BackgroundColor','w',...
                  'Position',[Lp(j) Bp Wp Hp],'String',lStr,'Value',...
                  find(strcmp(lStr,pVal)),'HorizontalAlignment','Center',...
                  'UserData',srcInfoENum(k)); 
              
        % updates the editbox callback function
        bFunc = @(h,e)VideoPara('popupCallback',h,[],handles);                  
        set(h,'Callback',bFunc);              
    end
end
