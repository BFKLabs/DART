function varargout = AdaptorInfo(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @AdaptorInfo_OpeningFcn, ...
    'gui_OutputFcn',  @AdaptorInfo_OutputFcn, ...
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

% --- Executes just before AdaptorInfo is made visible.
function AdaptorInfo_OpeningFcn(hObject, eventdata, handles, varargin)

% turns off all warnings
wState = warning('off','all');

% global variables
global nChannelMax nDACMax
nDACMax = 7;                                % this is the max number of attached DAC devices (prob too high...)
nChannelMax = 2;                            % this is the max number of channels per DAC device (increase if device has more channels)
[IMAQonly,isSet] = deal(false);

% Choose default command line output for AdaptorInfo
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% sets the input variable
hMain = varargin{1};

% retrieves and sets the test flag
isTest = getappdata(hMain,'isTest');
setappdata(hObject,'isTest',isTest);
setappdata(hObject,'vSelDAC',[])
set(handles.popupVidResolution,'enable','off','string',{' '},'value',1)
setObjEnable(handles.textVidResolution,'off')

% sets the DAC only flag
if length(varargin) == 2
    [DAConly,isInit] = deal(isstruct(varargin{2}),false);
else
    [DAConly,isInit] = deal(false,true);
end

% if there is the 3rd flag, then readjust the GUI
if DAConly
    % initialisations and setting of the input arguments   
    [isSet,dY,Htext] = deal(true,5,18);
    Hpanel0 = cell2mat(retObjDimPos({handles.panelUSBRequire},4));
    HpO = cell2mat(retObjDimPos({handles.panelOuter},4));
    reqdCFig = varargin{2};

    % flag that only the DAC objects need to be set
    objDACInfo = getappdata(hMain,'objDACInfo');
    setappdata(hObject,'reqdCFig',reqdCFig)
    
    % sets the minimum number of USB devices/channels
    [nUSBMin,nChMin] = deal(reqdCFig.nDev,reqdCFig.nCh);

    % calculates the new panel height
    Hpanel = dY + (2+nUSBMin)*Htext;

    % sets the min USB strings
    setappdata(hObject,'nUSBMin',nUSBMin)
    setappdata(hObject,'nChMin',nChMin)
    if ~isempty(objDACInfo)
        setappdata(hObject,'vSelDAC',objDACInfo.vSelDAC)
    end
    
    % determines the criteria properties
	[crStr,crCol] = detCriteriaProps(reqdCFig,objDACInfo);    
    
    % sets up the min USB device channel strings
    hPanel = handles.panelUSBRequire;
    hTextL = findobj(handles.panelUSBRequire,'style','text');
    for k = 1:length(hTextL)
        % retrieves the dimensions of the header text object
        hTextC = findobj(hTextL,'UserData',k);
        tPosC = get(hTextC,'Position');
        
        % creates the text objects for each row
        for i = 1:nUSBMin
            % sets the new string colour (based on whether the correct
            % number of
            j = nUSBMin - (i-1); 
            
            % sets the text string based on the values
            switch k
                case 1 % case is the channel index
                    txtStr = num2str(i);
                    
                case 2 % case is the device type
                    txtStr = reqdCFig.dType{i};
                    
                case 3 % case is the min channel count
                    switch reqdCFig.dType{i}
                        case 'Opto' % case is the opto device
                            txtStr = 'N/A';
                            
                        otherwise % case is the other device types
                            txtStr = num2str(reqdCFig.nCh(i));
                            
                    end
                    
                case 4 % case is the criteria met flag
                    txtStr = crStr{i};
                    
            end
            
            % creates the min channel text string label
            tPos = [tPosC(1),dY+(j-1)*Htext,tPosC(3:4)];
            uicontrol('Parent',hPanel, 'Style', 'text','String',...
                      txtStr,'FontUnits','pixels','HorizontalAlignment',...
                      'center','UserData',[i,k],'Position',tPos,...
                      'FontSize',12,'FontWeight','bold',...
                      'ForegroundColor',crCol{i},'tag','hTextReqd');
        end
        
        % updates the position of the title header
        tPosC(2) = dY+(nUSBMin*Htext);
        set(hTextC,'Position',tPosC);
    end

    % determines if all the USB counts/channels are ok
    setObjEnable(handles.buttonConnect,all(strcmp(crStr,'All')))

    % deletes the IMAQ object
    delete(handles.panelIMAQObj)
    delete(handles.panelExptType)                

    % readjusts the location of the figure/GUI panels
    dH = Hpanel - Hpanel0;
    resetObjPos(handles.panelDACObj,'bottom',dH,1)
    resetObjPos(handles.panelUSBRequire,'height',dH,1)      

    % resets the outer/figure heights
    pPos = get(handles.panelDACObj,'position');
    dHO = HpO - (sum(pPos([2 4])) + dY);
    resetObjPos(handles.panelOuter,'height',-dHO,1)                
    resetObjPos(hObject,'height',-dHO,1)                

    % readjusts the control button locations and properties        
    set(handles.buttonExit,'String','Cancel')
end

% if not DAC only, then delete the USB requirements panel and 
% readjusts the GUI
if ~DAConly
    % deletes the panel
    Hpanel0 = cell2mat(retObjDimPos({handles.panelUSBRequire},4));
    delete(handles.panelUSBRequire)
    
    % readjusts the location of the figure/GUI panels
    dY = Hpanel0 + 10;
    resetObjPos(hObject,'height',-dY,1)
    resetObjPos(handles.panelOuter,'height',-dY,1)
    resetObjPos(handles.panelExptType,'bottom',-dY,1)
    resetObjPos(handles.panelIMAQObj,'bottom',-dY,1)
    resetObjPos(handles.panelDACObj,'bottom',-dY,1)    
end

% sets up the channel count array/button properties
nChannel = zeros(nDACMax,1);
if isSet
    if ~isempty(objDACInfo)
        nChannel(objDACInfo.vSelDAC) = ...
                        objDACInfo.nChannel(objDACInfo.vSelDAC);
    end
else
    % sets the stimulus struct
    if isInit
        % resets all the image/data acquisition objects
        if ~isTest
            try; imaqreset; pause(0.1); end
            try; daqreset; pause(0.1); end
        end
        
        % sets the exit button string
        set(handles.buttonExit,'String','Exit Program')
    else
        % case is the gui is not being initialised
        set(handles.buttonExit,'string','Cancel');        
    end
end

% updates the parameters into the sub-GUI
setappdata(hObject,'DAConly',DAConly)
setappdata(hObject,'nChannel',nChannel)

% initialises the imaq/daq selection indices
setappdata(hObject,'vSelIMAQ',[])

% --- IMAGE ACQUISITION OBJECT INITIALISATION --- %
% ----------------------------------------------- %

% creates a loadbar
if DAConly
    h = ProgressLoadbar('Initialising Data Acquisition Objects...');
else
    h = ProgressLoadbar('Initialising Image/Data Acquisition Objects...');
end

% deletes any previous imaq objects in memory
if ~DAConly
    % determines the attached image acquisition objects
    if isTest
        imaqInfo.InstalledAdaptors = [];
    else
        imaqInfo = imaqhwinfo;
    end
    
    % determins if there are any attached recording objects
    if isempty(imaqInfo.InstalledAdaptors) && ~isTest
        % if there are no attached recording objects, then return an
        % error and exit the function
        try
            % deletes the loadbar
            delete(h);
        catch
        end
        
        % outputs the error message
        eStr = [{'No video recording devices attached to computer!'};...
            {'Attach recording device and restart Matlab.'}];
        waitfor(warndlg(eStr,'Recording Device Not Detected','modal'))
        
        % cancels the GUI with an empty array (should exit program outside)
        buttonExit_Callback(handles.buttonExit, [], handles)
        return
    else
        % otherwise, initialise the imaq object listbox
        if isTest
            % case is a test, so set up an arbitrary number of cameras
            nVideo = 4;
            
            % sets imaq object strings/indices
            vStrIMAQ = cellfun(@(x)(sprintf('USB Camera %i',x)),...
                num2cell(1:nVideo)','un',0);
            vIndIMAQ = [(1:nVideo)' ones(nVideo,1)];
            set(handles.popupVidResolution,'enable','off','string',' ',...
                'value',1)
        else
            % determines the adaptor string names
            adaptStr = imaqInfo.InstalledAdaptors;
            [vStrIMAQ,vInd,sFormat] = deal([]);
            imaqInfoDev = cell(length(adaptStr),1);
            
            % loops through the adaptor strings retrieving the device names
            for i = 1:length(adaptStr)
                % retrieves the device information
                try
                    imaqInfoDev{i} = imaqhwinfo(adaptStr{i},'DeviceInfo');
                    
                    % if there are adaptors of the type attached, then set their
                    if (~isempty(imaqInfoDev{i}))
                        nInfo = length(imaqInfoDev{i});
                        vStrIMAQ = [vStrIMAQ,{imaqInfoDev{i}.DeviceName}];
                        vIndIMAQ = [vInd;[repmat(i,nInfo,1) (1:nInfo)']];
                        sFormat = [sFormat,detFeasCamFormat(imaqInfoDev{i})];
                    end
                end
            end
            
            % sets the
            sInd = ones(length(sFormat),1);
            
            % if there are not proper camera devices attached, then exit the
            % program displaying an error
            if (~any(~cellfun(@isempty,imaqInfoDev)))
                % if there are no attached recording objects, then return an
                % error and exit the function
                try
                    % deletes the loadbar
                    delete(h);
                catch
                end
                
                % outputs the error message
                eStr = {'No video recording devices attached to computer!';...
                        'Attach recording device and restart Matlab.'};
                waitfor(warndlg(eStr,'Recording Device Not Detected','modal'))
                
                % cancels the GUI with an empty array (should exit program outside)
                buttonExit_Callback(handles.buttonExit, [], handles)
                return
            end
            
            % updates the data structs into the GUI
            setappdata(hObject,'imaqInfo',imaqInfo)
            setappdata(hObject,'imaqInfoDev',imaqInfoDev)
            setappdata(hObject,'sFormat',sFormat)
            setappdata(hObject,'sInd',sInd)
        end
        
        % sets the name strings within the list box
        vStrIMAQ = reshape(vStrIMAQ,length(vStrIMAQ),1);
        vStrIMAQ = cellfun(@(x,y)(sprintf('%i - %s',x,y)),...
            num2cell(1:length(vStrIMAQ))',...
            vStrIMAQ,'un',false);
        set(handles.listIMAQObj,'String',vStrIMAQ,'value',[])
        
        % sets the other information into the GUI
        setappdata(hObject,'vIndIMAQ',vIndIMAQ)
        setappdata(hObject,'vStrIMAQ',vStrIMAQ)
    end
end

% --- DATA ACQUISTION OBJECT INITIALISATION --- %
% --------------------------------------------- %

% sets up the data acquisition device figure properties
if isTest
    % sets the number of DACs to the maximum amount
    nDAC = nDACMax-1;
    nChannelMax = 4*ones(nDAC,1);
    
    % determines the adaptor string names
    vStrDAC = cellfun(@(x,y)(sprintf('%i - DAC Device %i',x,x)),...
        num2cell(1:nDAC),'un',false)';
    
    % sets the name strings within the list box
    set(handles.listDACObj,'String',vStrDAC,'value',[])
    setappdata(hObject,'vStrDAC',vStrDAC)
else
    % determines the attached data acquisition objects
    [daqInfo,hasDevice] = detConnectedDevice();
    
    % determines if there are any attached DAC objects
    if ~hasDevice
        if DAConly
            eStr = {'Error! There are no devices attached to the computer',...
                    'You must attach a device before trying again.'};
            waitfor(errordlg(eStr,'No Devices Attached?','modal'))
        end
        
        % if there are no attached recording objects, then prompt the user 
        % if they want to still continue (i.e., recording mode only)
        setObjVisibility(h.Control,'off');
        
        % if there are no devices, then disables the other radio buttons 
        % (can't record with stimuli)
        setObjEnable(handles.radioRecordStim,'off')

        % otherwise, disable the panel
        setPanelProps(handles.panelDACObj,'off')
        set(handles.radioRecordOnly,'value',1)
        set(handles.listDACObj,'Value',[])
        setObjVisibility(h.Control,'on');
        [IMAQonly,vStrDAC] = deal(true,[]);
        
    else
        % otherwise, initialise the DAC/serial object listbox 
        isS = strcmp(daqInfo.dType,'Serial');
        [nChannelMax,vStrDAC] = deal(2*(1+isS),cell(length(isS),1));
        setappdata(hObject,'daqInfo',daqInfo)
        
        % determines the adaptor string names for the serial objects       
        pStr = cellfun(@(x)(get(x,'Port')),daqInfo.Control,'un',0);
        if (any(isS))
            vStrDAC(isS) = cellfun(@(x,y,z)(sprintf('%i - %s (%s)',x,y,z)),...
                num2cell(find(isS(:))),daqInfo.BoardNames(isS),...
                pStr(isS),'un',false);
        end
        
        % determines the adaptor string names for the dac objects
        if (any(~isS))
            indD = num2cell(find(~isS));
            bName = daqInfo.BoardNames(~isS);            
            vStrDAC(~isS) = cellfun(@(x,y,z)(sprintf('%i - %s (DAC %i)',x,y,z)),...
                indD(:),bName(:),num2cell(1:sum(~isS))','un',0);  
            
            % determines if the objects are the new format. if so, then set
            % the maximum number of channels
            if (~verLessThan('matlab','9.2'))
                ii = find(~isS);
                a = daqInfo.ObjectConstructorName(~isS,:);
                for i = 1:size(a,1)
                    nChannelMax(ii(i)) = length(a{i,3}.chName);
                end
            end
        end
            
        % sets the name strings within the list box
        set(handles.listDACObj,'String',vStrDAC,'value',[])
        setappdata(hObject,'vStrDAC',vStrDAC)
    end
end

% initialises the channel count edit boxes
if ~IMAQonly
    nDACMax = min(nDACMax,length(vStrDAC));
    initChannelEdit(handles,daqInfo);
end

% sets the list/channel values (if adaptors have been set)
if isSet && ~isempty(objDACInfo)
    set(handles.listDACObj,'value',objDACInfo.vSelDAC)
    for i = 1:length(objDACInfo.vSelDAC)
        j = objDACInfo.vSelDAC(i);
        hEdit = findobj(handles.panelDACObj,'style','edit','UserData',j);
        if isnan(nChannel(j))
            setEditProp(handles,j,'opto')
        else
            set(hEdit,'backgroundcolor','w','enable','on',...
                      'ForegroundColor','k','string',num2str(nChannel(j)))
        end
    end
end

% sets the imaq only flag
setappdata(hObject,'IMAQonly',IMAQonly)
if ~DAConly
    panelExptType_SelectionChangeFcn(handles.panelExptType, '1', handles)
end

% centres the figure
centreFigPosition(hObject);

% closes the loadbar
warning(wState);
try; delete(h); end

% UIWAIT makes AdaptorInfo wait for user response (see UIRESUME)
uiwait(handles.figAdaptInfo);

% --- Outputs from this function are returned to the command line.
function varargout = AdaptorInfo_OutputFcn(hObject, eventdata, handles)

% global variables
global objIMAQ objDACInfo exptType

% Get default command line output from handles structure
varargout{1} = objIMAQ;
varargout{2} = objDACInfo;
varargout{3} = exptType;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- VIDEO/DAC ADAPTOR LISTBOXES --- %
% ----------------------------------- %

% --- Executes on selection change in popupVidResolution.
function popupVidResolution_Callback(hObject, eventdata, handles)

% retrieves the selection
vSelIMAQ = get(handles.listIMAQObj,'Value');
sInd = getappdata(handles.figAdaptInfo,'sInd');

% updates the selection
sInd(vSelIMAQ) = get(hObject,'value');
setappdata(handles.figAdaptInfo,'sInd',sInd)

% --- Executes on selection change in listDACObj.
function listDACObj_Callback(hObject, eventdata, handles)

% global variables
global nDACMax

% retrieves the DAC only flag and parameter stimulus struct
hFig = handles.figAdaptInfo;
daqInfo = getappdata(hFig,'daqInfo');
DAConly = getappdata(hFig,'DAConly');
nChannel = getappdata(hFig,'nChannel');

% sets the current user selection
vSelDAC = get(hObject,'Value');
isOpto = strcmp(daqInfo.sType,'Opto');

% sets the flags of the edit boxes that need to be updated
[ii,jj] = deal(true(nDACMax,1),false(nDACMax,1));
[ii(vSelDAC),jj(isOpto)] = deal(false,true);

% resets the edit-box properties
setEditProp(handles,find(ii),'inactive')
setEditProp(handles,find(~ii & ~jj),'on')
setEditProp(handles,find(~ii & jj),'opto')
pause(0.01); drawnow

% updates the DAC selection indices
setappdata(hFig,'vSelDAC',vSelDAC)

% if the required info has been set, then enable the connection button
if DAConly
    updateReqdStrings(handles)
else
    if isempty(getappdata(hFig,'vSelIMAQ')) || isempty(vSelDAC)
        setObjEnable(handles.buttonConnect,'off')
    else
        canConnect = all((nChannel(vSelDAC)>0) | isnan(nChannel(vSelDAC)));
        setObjEnable(handles.buttonConnect,canConnect)
    end
end

% --- Executes on selection change in listIMAQObj.
function listIMAQObj_Callback(hObject, eventdata, handles)

% sets the current user selection
vSelIMAQ = get(hObject,'Value');
if (isempty(vSelIMAQ))
    return
else
    setappdata(handles.figAdaptInfo,'vSelIMAQ',vSelIMAQ)
end

%
nChannel = getappdata(handles.figAdaptInfo,'nChannel');
IMAQonly = getappdata(handles.figAdaptInfo,'IMAQonly');
sFormat = getappdata(handles.figAdaptInfo,'sFormat');
sInd = getappdata(handles.figAdaptInfo,'sInd');

% if the required info has been set, then enable the connection button
if IMAQonly || get(handles.radioRecordOnly,'value')
    setObjEnable(handles.buttonConnect,length(vSelIMAQ) == 1)
else
    vSelDAC = getappdata(handles.figAdaptInfo,'vSelDAC');
    canConnect = ~(isempty(vSelDAC) || any(nChannel(vSelDAC) == 0));
    setObjEnable(handles.buttonConnect,canConnect)
end

% updates the drop-down box
isTest = getappdata(handles.figAdaptInfo,'isTest');
if ~isa(eventdata,'char') && ~isTest
    setObjEnable(handles.textVidResolution,'on')
    set(handles.popupVidResolution,'string',...
                                sFormat{vSelIMAQ},'enable','on','max',1)
    if sInd(vSelIMAQ) > 0
        % updates the selection
        set(handles.popupVidResolution,'value',sInd(vSelIMAQ))
    else
        % otherwise, sets the value to be the non-selected value
        set(handles.popupVidResolution,'value',1)
    end
end

% --- EXPERIMENTAL TYPE RADIO BUTTONS --- %
% --------------------------------------- %

% --- Executes when selected object is changed in panelExptType.
function panelExptType_SelectionChangeFcn(hObject, eventdata, handles)

% global variables
global nDACMax

% retrieves the experiment type
if (isa(eventdata,'char'))
    exptType = get(get(hObject,'SelectedObject'),'UserData');
else
    exptType = get(eventdata.NewValue,'UserData');
end

% sets the DAC object panel enabled
switch exptType
    case ('RecordOnly') % case is recording only
        % otherwise, disable the panel
        setPanelProps(handles.panelDACObj,'off')
        set(handles.listDACObj,'value',[])
        
        % resets the selection fields for the DAC information
        objDACInfo = getappdata(handles.figAdaptInfo,'objDACInfo');
        objDACInfo.vSelDAC = [];
        
        % updates the data structs
        setappdata(handles.figAdaptInfo,'vSelDAC',[]);
        setappdata(handles.figAdaptInfo,'objDACInfo',objDACInfo);
        
        % updates the camera object list properties
        listIMAQObj_Callback(handles.listIMAQObj, '1', handles)
        
    otherwise % case is the other buttons
        % otherwise, disable the panel
        setPanelProps(handles.panelDACObj,'on')        
        
        % updates the camera/DAC object list properties
        listIMAQObj_Callback(handles.listIMAQObj, '1', handles)
        listDACObj_Callback(handles.listDACObj, [], handles)
        
        % disables the non-DAC editbox entries
        nCh = length(getappdata(handles.figAdaptInfo,'nChannel'));
        hCheck = cellfun(@(x)(findall(handles.panelDACObj,'UserData',x)),...
                        num2cell((nDACMax+1):nCh),'un',0);
        cellfun(@(x)(setObjEnable(x,'Inactive')),hCheck)
end

% updates the experiment type
setappdata(handles.figAdaptInfo,'exptType',exptType)

% --- CHANNEL COUNT EDITBOXES --- %
% ------------------------------- %

% --- callback function for updating the channel count edit boxes --- %
function editChannelUpdate(hObject, eventdata, handles)

% global variables
global nChannelMax

% retrieves the required data structs
nChannel = getappdata(handles.figAdaptInfo,'nChannel');
DAConly = getappdata(handles.figAdaptInfo,'DAConly');
vSelDAC = getappdata(handles.figAdaptInfo,'vSelDAC');
iEdit = get(hObject,'UserData');

% retrieves the new value and determines if it is valid
nwVal = str2double(get(hObject,'string'));
if chkEditValue(nwVal,[0 nChannelMax(iEdit)],1)
    % if the value is valid, set the new value and update the vector
    nChannel(iEdit) = nwVal;
    setappdata(handles.figAdaptInfo,'nChannel',nChannel)
    
    % check to see if only the DAC objects are being set
    if DAConly
        % retrieves the
        updateReqdStrings(handles)
    else
        % otherwise, check to see if the IMAQ object has been set AND at
        % least one channel has been provided for each DAC device
        if ((any(nChannel(vSelDAC) == 0)) || ...
                (isempty(getappdata(handles.figAdaptInfo,'vSelIMAQ'))))
            setObjEnable(handles.buttonConnect,'off')
        else
            setObjEnable(handles.buttonConnect,'on')
        end
    end
else
    % otherwise, revert back to the previous valid value
    set(hObject,'string',num2str(nChannel(iEdit)));
end

% --- PROGRAM CONTROL BUTTONS --- %
% ------------------------------- %

% --- Executes on button press in buttonConnect.
function buttonConnect_Callback(hObject, eventdata, handles)

% global variables
global objIMAQ objDACInfo exptType nChannelMax

% global variables
global mainProgDir

% retrieves the serial device strings from the parameter file
A = load(fullfile(mainProgDir,'Para Files','ProgPara.mat'));

% gets the DAC only flag
hFig = handles.figAdaptInfo;
isTest = getappdata(hFig,'isTest');
DAConly = getappdata(hFig,'DAConly');
vSel = getappdata(hFig,'vSelDAC');
objDACInfo = getappdata(hFig,'daqInfo');

% sets the image acquistion only flag
IMAQonly = getappdata(hObject,'IMAQonly');
if isempty(IMAQonly)
    IMAQonly = isempty(getappdata(hFig,'vSelDAC'));
end

% % determines if the correct device selection has been made
% if ~isempty(vSel) && ~isTest
%     objDACInfo.dType = objDACInfo.dType(vSel);
%     objDACInfo.sType = objDACInfo.sType(vSel);
% end

% ----------------------------------------------- %
% --- IMAGE ACQUISITION OBJECT INITIALISATION --- %
% ----------------------------------------------- %

% creates the image acquistion objects (if creating both)
if ~DAConly
    % sets the experiment type field
    exptType = getappdata(handles.figAdaptInfo,'exptType');
    if isTest
        % sets an empty imaq object
        objIMAQ = [];
    else
        % deletes any previous camera objects
        prImaqObj = imaqfind;
        if ~isempty(prImaqObj)
            delete(prImaqObj)
        end
        
        % retrieves the selected video input object index
        iSelV = get(handles.listIMAQObj,'Value');        
        
        % retrieves the required structs/objects
        vSelIMAQ = getappdata(hFig,'vSelIMAQ');
        vIndIMAQ = getappdata(hFig,'vIndIMAQ');
        imaqInfoDev0 = getappdata(hFig,'imaqInfoDev');
        sFormat = getappdata(hFig,'sFormat');
        sInd = getappdata(hFig,'sInd');
        
        % otherwise, set the video object to the user selection
        imaqInfoDev = imaqInfoDev0(~cellfun(@isempty,imaqInfoDev0));
        try
            vConStr = imaqInfoDev{vIndIMAQ(vSelIMAQ,1)}...
                           (vIndIMAQ(vSelIMAQ,2)).VideoInputConstructor;
        catch
            try
                vConStr = imaqInfoDev{iSelV}...
                            (vIndIMAQ(vSelIMAQ,2)).VideoInputConstructor;
            catch
                vConStr = imaqInfoDev{iSelV}...
                                (vIndIMAQ(vSelIMAQ,2)).ObjectConstructor;
            end
        end
        
        % creates the video object
        vStr = sprintf('%s, ''%s'')',vConStr(1:end-1),...
            sFormat{vSelIMAQ}{sInd(vSelIMAQ)});
        try
            objIMAQ = eval(vStr);
        catch ME
            if (strcmp(ME.identifier,'winvideo:internal:dxMsg'))
                eStr = {['Error! Selected recording device is already in ',...
                         'use. Please re-select.'];'';['If using multiple cameras ensure ',...
                         'they are attached to individual ports.']};
                waitfor(errordlg(eStr,'Recording Device Communication Error','modal'))
                return
            else
                eStr = 'Critical error with the selected recording device. Please re-select.';
                waitfor(errordlg(eStr,'Recording Device Error','modal'))
            end
            
            % exits the function
            return
        end
        
        % ensure that the video object writes avi objects to disk
        try
            set(objIMAQ,'LoggingMode','memory','ReturnedColorSpace','grayscale');
            set(objIMAQ,'Name',imaqInfoDev{vIndIMAQ(vSelIMAQ,1)}(vIndIMAQ(vSelIMAQ,2)).DeviceName);
        end
        triggerconfig(objIMAQ,'manual')
        
        % sets the camera automatic fields to manual
        try
            srcObj = getselectedsource(objIMAQ);
            set(srcObj,'FocusMode','manual','ExposureMode','auto');
        end
        
        % increases the amount of memory available to the camera
        try
            a = imaqmem;
            imaqmem(min(a.AvailVirtual,2*a.FrameMemoryLimit));
        end
    end
else
    % otherwise, set an empty data array
    [objIMAQ,exptType] = deal([]);
end

% --------------------------------------- %
% --- DATA ACQUISTION OBJECT CREATION --- %
% --------------------------------------- %

% deletes any previous DAC objects in memory
if ~isTest
    try
        prDaqObj = daqfind;
        if ~isempty(prDaqObj)
            delete(prDaqObj)
        end
    end
else
    objIMAQ = 1;
end

% sets the number of channels
vStr = getappdata(hFig,'vStrDAC');
nChannel = getappdata(hFig,'nChannel');
nChMx = num2cell(nChannelMax(vSel));

% sets the selected device fields
if IMAQonly
    % no device, so return empty field
    objDACInfo = [];
else
    % sets the DAC object information
    objDACInfo.iChannel = cellfun(@(x)((1:x)-1),nChMx,'un',0)'; 
    objDACInfo.vSelDAC = vSel;
    objDACInfo.nChannel = nChannel;    
    objDACInfo.vStrDAC = vStr;    
    objDACInfo.sRate = 50*ones(length(vStr),1);    
end
    
% deletes the GUI
delete(hFig)
pause(0.1);

% --- Executes on button press in buttonExit.
function buttonExit_Callback(hObject, eventdata, handles)

% global variables
global objIMAQ objDACInfo exptType

% sets empty arrays and deletes the GUI
[objIMAQ,objDACInfo,exptType] = deal([]);
delete(handles.figAdaptInfo)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- updates the channel edit box properties --- %
function setEditProp(handles,ind,state)

% if there are no indices, then exit the function
if (isempty(ind))
    return;
end

% retrieves the number of indices being updated
nChannel = getappdata(handles.figAdaptInfo,'nChannel');

% retrieves the edit boxes corresponding to the indices
hEdit = cellfun(@(x)(findobj('Style','Edit','UserData',x)),...
                     num2cell(ind),'un',0);
hEdit = reshape(hEdit,length(ind),1);

% sets the edit box enabled state
switch (state)
    case ('inactive')
        [bCol,fCol] = deal(0.5*[1 1 1],'w');    
    case ('on')
        [bCol,fCol] = deal('w','k');
    otherwise
        [bCol,fCol,state] = deal(0.8*[1 1 1],'k','inactive');
end

% sets the new edit strings
editStr = arrayfun(@num2str,nChannel(ind),'un',0);
editStr(isnan(nChannel(ind))) = {'N/A'};

% otherwise, reset the editbox background and string
cellfun(@(x)(setObjEnable(x,state)),hEdit)
cellfun(@(x,y)(set(x,'BackgroundColor',bCol,'String',y,...
                     'ForegroundColor',fCol)),hEdit,editStr);

% --- initialises the properties of the
function initChannelEdit(handles,daqInfo)

% global variables
global nDACMax
fcnStr = 'editChannelUpdate';

% initialises the editboxes
setEditProp(handles,1:nDACMax,'inactive')
nChannel = getappdata(handles.figAdaptInfo,'nChannel');

% loops through all of the edit boxes setting up their callback functions
for i = 1:nDACMax
    % retrieves the next edit box handle
    hObjNw = findobj('style','edit','userdata',i);
    
    % if the optogenetics serial device preset the value to 1 channel
    if i <= length(daqInfo.sType)
        if strcmp(daqInfo.sType{i},'Opto')
            set(hObjNw,'string','N/A')
            nChannel(i) = NaN;
        end
    end
    
    % sets the editbox callback function
    bFunc = @(hObjNw,e)AdaptorInfo(fcnStr,hObjNw,[],guidata(hObjNw));
    set(hObjNw,'Callback',bFunc)
end

% resets the channel vector into the GUI
setappdata(handles.figAdaptInfo,'nChannel',nChannel)

% --- determines if there are any external devices connected
function [daqInfo,hasDevice] = detConnectedDevice()

% global variables
global mainProgDir

% retrieves the serial device strings from the parameter file
A = load(fullfile(mainProgDir,'Para Files','ProgPara.mat'));

% initialisations
[hasDevice,sStr] = deal(false,A.sDev);

% determines the dac types
if (verLessThan('matlab','9.2'))
    dStr = {'mcc','nidaq'};
else
    % retrieves the installation information
    [dStr,dInfo] = getInstalledDeviceVendors(1);    
end

% memory allocation
daqInfo = initDACInfoStruct();

% attempts to detect/open the DAC devices
for i = 1:length(dStr)
    if (verLessThan('matlab','9.2'))
        try
            % attempts to find the measurement computing devices
            dInfo = daqhwinfo(dStr{i});
            isOK = ~cellfun(@isempty,dInfo.ObjectConstructorName(:,2));

            % determines if the devices can be constructed
            if (~isempty(isOK))
                if (any(isOK))
                    % if so, then append the instrument info into the struct
                    hasDevice = true;
                    daqInfo = appendDACInfo(daqInfo,dInfo,isOK);
                end
            end
        end
    else
        % sets the object constructor array
        hasDevice = true;
        [dVTemp,ssObj] = deal(get(dInfo(i),'Vendor'),get(dInfo(i),'Subsystems'));
        ssType = arrayfun(@(x)(get(x,'SubsystemType')),ssObj,'un',0);
        ssObj = ssObj(strcmp(ssType,'AnalogOutput'));        
                
        % sets the sub-system data struct
        ssStr = struct('ID',get(dInfo(i),'ID'),'chName',[],...
                       'mType',get(ssObj,'DefaultMeasurementType'));
        ssStr.chName = get(ssObj,'ChannelNames');                   
        objCon = {get(dInfo(i),'ID'),dStr{i},ssStr};
        
        % appends the data to the data struct        
        [daqInfo.dType,daqInfo.sType] = deal({'DAC'},{'Motor'});
        daqInfo.Control = [daqInfo.Control;cell(1)];
        daqInfo.BoardNames = [daqInfo.BoardNames;{get(dVTemp,'FullName')}];
        daqInfo.InstalledBoardIds = [daqInfo.InstalledBoardIds,{1}];
        daqInfo.ObjectConstructorName = [daqInfo.ObjectConstructorName;objCon];
    end
end

% closes and deletes any open serial ports
hh = instrfind();
if (~isempty(hh))
    fclose(hh);
    delete(hh);
end

% if there are any valid devices then retrieve their details
pStr = findSerialPort(sStr);
if (~isempty(pStr))
    % sets the object details    
    vStr = {'Motor','Opto'};
    daqInfo = appendSerialInfo(daqInfo,pStr,vStr);  
    hasDevice = ~isempty(daqInfo.Control);
end

% --- appends the new DAC information to the data struct
function A = appendDACInfo(A,Anw,isOK)

% sets the new boardname strings
bNameNw = cellfun(@(x)(sprintf('%s - %s',Anw.AdaptorName,x)),...
                        Anw.BoardNames(isOK),'un',0);

% appends the required fields
A.ObjectConstructorName = [A.ObjectConstructorName;...
                           Anw.ObjectConstructorName(isOK,:)];
A.InstalledBoardIds = [A.InstalledBoardIds,Anw.InstalledBoardIds(isOK)];
A.BoardNames = [A.BoardNames,bNameNw];

% creates spaces for the other fields
A.dType = [A.dType,repmat({'DAC'},1,sum(isOK))];
A.sType = [A.sType,repmat({'Motor'},1,sum(isOK))];
A.Control = [A.Control,cell(1,sum(isOK))];

% --- determines the feasible camera formats --- %
function sFormat = detFeasCamFormat(imaqInfoDev)

% sets the upper limit on the camera
scrSz = get(0,'Screensize');
[Wmax,Hmax] = deal(scrSz(3),scrSz(4));
sFormat = cell(length(imaqInfoDev),1);

% sets the camera formats (for each camera type)
for i = 1:length(sFormat)
    % determines the supported strings
    A = imaqInfoDev(i).SupportedFormats;
    if any(strContains(A,'_x'))
        sFormatS = cellfun(@(x)(splitStringRegExp(x,'_x')'),A,'un',0);

        % removes the non-feasible camera settings
        if length(sFormatS{1}) == 3
            isFeas = cellfun(@(x)((str2double(x{2}) <= Wmax)) && ...
                                  (str2double(x{3}) <= Hmax),sFormatS);
            sFormat{i} = A(isFeas);
        end
    else
        sFormat{i} = A(:);
    end
end

% --- updates the required device strings/colours
function updateReqdStrings(handles)

% initialisations
nCol = 4;
eStr = {'off','on'};
hFig = handles.figAdaptInfo;
daqInfo = getappdata(hFig,'daqInfo');
reqdCFig = getappdata(hFig,'reqdCFig');
nChannel = getappdata(hFig,'nChannel');
vSelDAC = getappdata(hFig,'vSelDAC');
hPanel = handles.panelUSBRequire;

% determines the criteria properties
[crStr,crCol] = detCriteriaProps(reqdCFig,daqInfo.sType(vSelDAC),...
                                          nChannel(vSelDAC));

% updates the criteria colours/strings for each required device
for i = 1:length(crStr)
    hTxt = arrayfun(@(x)(findobj(hPanel,'UserData',[i,x])),1:nCol,'un',0);
    cellfun(@(x)(set(x,'ForegroundColor',crCol{i})),hTxt);
    set(hTxt{nCol},'string',crStr{i})   
end

% sets the connect button enabled properties
allOK = all(strcmp(crStr,'All'));
setObjEnable(handles.buttonConnect,allOK)

% --- determines the required device criteria property strings/colours
function [crStr,crCol] = detCriteriaProps(reqdCFig,varargin)

% initialisations
nDev = reqdCFig.nDev;
crStr = repmat({'None'},nDev,1);
crCol = repmat({'r'},nDev,1);

% retrieves the device name/channel counts
switch length(varargin)
    case 1
        objDACInfo = varargin{1};
        nChD = objDACInfo.nChannel;
        sTypeD = objDACInfo.sType(objDACInfo.vSelDAC);
        
    case 2
        [sTypeD,nChD] = deal(varargin{1},varargin{2});
end

% retrieves the device name/channel counts
isFound = false(length(sTypeD),1);

% for each required device, determine if there is a matching device already
% attached. if so, update the criteria string/colours
for i = 1:nDev
    isMatch = strcmp(sTypeD(:),reqdCFig.dType{i}) & ~isFound(:);
    if any(isMatch)
        % sets the row flag and updates the criteria flag
        [iRow,crStr{i}] = deal(find(isMatch,1,'first'),'Device');
        isFound(iRow) = true;
        
        % determines if the channel count is correct
        switch sTypeD{iRow}
            case 'Opto'
                ok = true;
            otherwise
                ok = nChD(iRow) >= reqdCFig.nCh(i);
        end
        
        % updates the criteria strings/colours (if criteria met)
        if ok
            [crStr{i},crCol{i}] = deal('All','k');
        end
    end
end

% % --- registers the device with the name, dStr
% function ok = regDACDevice(dStr)
% 
% % initialisations
% ok = true;
% 
% % attempts to 
% try
%     % retrieves the data acquistion device information
%     dInfo = daqhwinfo;
% 
%     % attempts to register the device
%     if (~any(strcmp(dInfo.InstalledAdaptors,dStr)))
%         daqregister(dStr)
%     end
% catch
%     % if the registering failed, then output an error
%     eStr = 'Registering of device failed. Please re-run DART in Administrator Mode';
%     waitfor(errordlg(eStr,'Device Registering Error'))
%     ok = false;
% end
