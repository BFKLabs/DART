function varargout = TrackingPara(varargin)
% Last Modified by GUIDE v2.5 11-May-2017 07:25:23

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TrackingPara_OpeningFcn, ...
                   'gui_OutputFcn',  @TrackingPara_OutputFcn, ...
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

% --- Executes just before TrackingPara is made visible.
function TrackingPara_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for TrackingPara
handles.output = hObject;

% retrieves the real-time parameter data struct
hGUI = varargin{1};
rtP = getappdata(hGUI,'rtP');
iExpt = getappdata(hGUI,'iExpt');

% sets the segmentation parameter struct into the GUI
setappdata(hObject,'hGUI',hGUI)
setappdata(hObject,'rtP',rtP)
setappdata(hObject,'iExpt',iExpt)
setappdata(hObject,'iMov',getappdata(hGUI,'iMov'))
setappdata(hObject,'iStim',getappdata(hGUI,'iStim'))

% initialises the parameter editbox properties
initLocationPopupMenus(handles)
initSpeedPopupMenus(handles)
initParaEditBox(handles)
initParaCheckBox(handles)
initCombActivity(handles)
initUSBChannelTable(handles)

% disables the update button
setObjEnable(handles.buttonUpdate,'off')

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes TrackingPara wait for user response (see UIRESUME)
if (strcmp(get(hGUI,'tag'),'figMultExpt'))
    uiwait(handles.figTrackPara);    
end

% --- Outputs from this function are returned to the command line.
function varargout = TrackingPara_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = hObject;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% ------------------------- %
% --- USB CHANNEL TABLE --- %
% ------------------------- %

% --- Executes when entered data in editable cell(s) in tableUSBChannel.
function tableUSBChannel_CellEditCallback(hObject, eventdata, handles)

% retrieves the parameter struct
rtP = getappdata(handles.figTrackPara,'rtP');
iMov = getappdata(handles.figTrackPara,'iMov');
[iCh,iCol] = deal(eventdata.Indices(1),eventdata.Indices(2));
Data = get(hObject,'Data');

% if "None" is selected, reset the NaN value to the correct value
if (isnan(eventdata.NewData))    
    Data{iCh,iCol} = 'None';
    set(hObject,'Data',Data)
end

% determines the selection
cForm = get(hObject,'columnformat');
nwVal = find(strcmp(cForm{iCol},eventdata.EditData)) - 1;

% updates the parameters based on the connection type
switch (rtP.Stim.cType)
    case ('Ch2App') % case is connecting a channel to an apparatus                
        % sets the channel to apparatus index
        if (nwVal == 0)
            % case is no connection
            rtP.Stim.C2A(iCh) = NaN;
        else                      
            % otherwise, determine if the channel index has been set for
            % another apparatus
            if (any(rtP.Stim.C2A == nwVal))
                % if there is a match, then output an error to screen
                eStr = 'Error! Device channel has already been set.';
                waitfor(errordlg(eStr,'Duplicate Device Channel','modal'))
                
                % resets the table to the original value
                Data{iCh,iCol} = eventdata.PreviousData;
                set(hObject,'Data',Data)
                return
            else
                % otherwise, update the channel connection index
                rtP.Stim.C2A(iCh) = nwVal;
            end
        end
        
    case ('Ch2Tube') % case is connecting a channel to a fly
        
        % sets the channel to apparatus index
        if (nwVal == 0)
            % case is no connection
            rtP.Stim.C2T(iCh,iCol-2) = NaN;
        else
            % otherwise, determine if the configuration has been set for
            % another apparatus/channel
            nwP = rtP.Stim.C2T(iCh,:); nwP(iCol-2) = nwVal;            
            isMatch = cellfun(@(x)(isequal(x,nwP)),num2cell(rtP.Stim.C2T,2));            
            if (any(isMatch))
                % if there is a match, then output an error to screen
                eStr = 'Error! Device configuration has already been set.';
                waitfor(errordlg(eStr,'Duplicate Device Configuration','modal'))
                
                % resets the table to the original value
                Data{iCh,iCol} = eventdata.PreviousData;
                set(hObject,'Data',Data)
                return
            else          
                % determines 
                C2T = rtP.Stim.C2T;
                nFlyR = getSRCountVec(iMov);
                C2T(iCh,iCol-2) = nwVal;
                
                % determines if both the channel and fly count is correct
                if (~all(isnan(C2T(iCh,:))))
                    % if so, determine if selection is correct
                    if (C2T(iCh,2) > nFlyR(C2T(iCh,1)))
                        % if there is a match, then output an error to screen
                        eStr = sprintf(['Error! Sub-Region #%i has a maximum ',...
                                        'count of %i flies.'],C2T(iCh,1),nFlyR(C2T(iCh,1)));
                        waitfor(errordlg(eStr,'Incorrect Configuration','modal'))

                        % resets the table to the original value
                        Data{iCh,iCol} = eventdata.PreviousData;
                        set(hObject,'Data',Data)
                        return                        
                    else
                        % updates the connection 
                        rtP.Stim.C2T = C2T;                        
                    end
                else
                    % updates the connection 
                    rtP.Stim.C2T = C2T;
                end
            end
        end        
end

% sets the new USB index
setObjEnable(handles.buttonUpdate,'on')
setappdata(handles.figTrackPara,'rtP',rtP);

% ------------------------------- %
% --- COMBINED ACTIVITY PANEL --- %
% ------------------------------- %

% --- Executes when entered data in editable cell(s) in tableCombActivity.
function tableCombActivity_CellEditCallback(hObject, eventdata, handles)

% initialisations
chkMatch = false;

% retrieves the important data structs
rtP = getappdata(handles.figTrackPara,'rtP');
iMov = getappdata(handles.figTrackPara,'iMov');

% determines the select group index
iRow = eventdata.Indices(1);
Data = get(hObject,'Data');
cForm = get(hObject,'Columnformat');
DataT = get(handles.tableUSBChannel,'Data');
cFormT = get(handles.tableUSBChannel,'columnformat');

% retrieves the new/previous values
nwVal = find(strcmp(cForm{2},eventdata.EditData))-1;
prVal = find(strcmp(cForm{2},eventdata.PreviousData))-1;

% updates the combined group indices
if (nwVal == 0)
    % case is the "none" field has been selected    
    rtP.combG.ind(iRow) = NaN;    
    if (sum(rtP.combG.ind == prVal) < 2)
        [valueChk,chkMatch] = deal(eventdata.PreviousData,true);
    end
else
    % case another group index was selected
    rtP.combG.ind(eventdata.Indices(1)) = nwVal;        
    [valueChk,chkMatch] = deal(Data{iRow,1},true);    
end

% if the current sub-region is selected as a channel connection, then
% remove it from the channel connection table
if (chkMatch)
    isMatch = strcmp(DataT(:,3),valueChk);
    if (any(isMatch))
        % removes the match and updates the table data 
        [rtP.Stim.C2A(isMatch),DataT{isMatch,3}] = deal(NaN,'None');
        if (nwVal > 0)
            cFormT{3} = cFormT{3}(~strcmp(cFormT{3},Data{iRow,1}));
            set(handles.tableUSBChannel,'Data',DataT,'Columnformat',cFormT)
        end
    end    
end
    
% determines the combined sub-group indices
[iGrp,cMax] = deal(getCombSubRegionIndices(iMov,rtP,1),max(rtP.combG.ind));

% if there are sufficient groups selected, and the group selected is
% the current maximum, then expand the group indices
if ((cMax == nwVal) && (sum(~isnan(iGrp(cMax,:))) > 1) && (length(cForm{2}) == (nwVal+1)))
    % updates the column format for the combined sub-region table
    cForm{2}{end+1} = sprintf('Group #%i',length(cForm{2}));
    set(hObject,'Columnformat',cForm)     
end

if ((prVal > 0) && (~all(isnan(rtP.combG.ind))))
    % determines if a group has no selections in the table. if so, then
    % remove that group and resets the other affected groups
    iGrp = getCombSubRegionIndices(iMov,rtP,1);   
    if (prVal > size(iGrp,1))
        reduceCForm = true;
    else
        reduceCForm = all(isnan(iGrp(prVal,:)));
    end
    
    if (reduceCForm)
        % if a group has no selection, then remove that group       
        [ii,cGrpMx] = deal((rtP.combG.ind > prVal),max(rtP.combG.ind));
        rtP.combG.ind(ii) = rtP.combG.ind(ii) - 1;
        
        % resets the affect group strings in each table
        for i = (prVal+1):cGrpMx
            cStr0 = sprintf('Group #%i',i);
            cStr1 = sprintf('Group #%i',i-1);
            DataT(strcmp(DataT(:,3),cStr0),3) = {cStr1};
            Data(strcmp(Data(:,2),cStr0),2) = {cStr1};
        end
        
        % resets the table's column format and data
        cForm{2} = cForm{2}(1:end-1);
        set(hObject,'Columnformat',cForm,'Data',Data) 
    end
end

% updates the column format for the channel connection table
cFormT{3} = setupTableColumnFormat(iMov,rtP);    
C2A = cellfun(@(x)(find(strcmp(x,cFormT{3}))-1),DataT(:,3),'un',0);
ii = cellfun(@isempty,C2A);
[C2A(ii),DataT(ii,3)] = deal({0},{'None'});

% updates the channel to sub-region connection indices
rtP.Stim.C2A = cell2mat(C2A);
rtP.Stim.C2A(rtP.Stim.C2A == 0) = NaN;    
set(handles.tableUSBChannel,'Columnformat',cFormT,'Data',DataT)    
    
% updates the real-time tracking parameter struct
setObjEnable(handles.buttonUpdate,'on')
setappdata(handles.figTrackPara,'rtP',rtP)
    
% ----------------------------------- %
% --- CHECKBOX/EDITBOX PARAMETERS --- %
% ----------------------------------- %

% --- the parameter editbox editting callback function --- %
function editSegPara(hObject, eventdata, handles)

% retrieves the segmentation parameters
rtP = getappdata(handles.figTrackPara,'rtP');

% resets the parameter values and callback function
[uD,pInd] = deal(get(hObject,'UserData'),NaN);
if (length(uD) == 2)
    % parameter has 2 sub-fields
    paraStr = sprintf('rtP.%s.%s',uD{1},uD{2});    
else    
    % sets the parameter string
    pInd = get(handles.popupLocType,'Value');
    paraStr = sprintf('rtP.%s.%s.%s(pInd)',uD{1},uD{2},uD{3});    
end

% retrieves the parameter string and the new value/limits
nwVal = str2double(get(hObject,'string'));
nwLim = setParaLimits(uD{end},pInd);

% checks to see if the new value is valid
if (chkEditValue(nwVal,nwLim,strcmp(uD{end},'nSpan')))
    % if so, then update the parameter field and struct
    if (pInd == 2)
        eval(sprintf('%s = nwVal/100;',paraStr));
    else
        eval(sprintf('%s = nwVal;',paraStr));
    end
        
    % if altering the single-stimuli duration, then update the signal
    if (strcmp(uD{end},'Tdur'))
        rtP.Stim.pFix.pDur.pVal = nwVal;
        rtP.Stim.sFix = setSingleStimSignal(rtP.Stim.pFix,rtP.Stim.oPara);
    end
    
    % enables the update button
    setObjEnable(handles.buttonUpdate,'on')
    setappdata(handles.figTrackPara,'rtP',rtP)
else
    % otherwise, revert back to the previous valid value
    if (pInd == 2)
        set(hObject,'string',num2str(eval(paraStr)*100))
    else
        set(hObject,'string',num2str(eval(paraStr)))
    end
end

% --- the parameter checkbox editting callback function --- %
function checkSegPara(hObject, eventdata, handles)

% retrieves the segmentation parameters
rtP = getappdata(handles.figTrackPara,'rtP');
[pVal,uD] = deal(get(hObject,'value'),get(hObject,'UserData'));

% sets the GUI properties based on the selection value
hTag = get(hObject,'tag');
switch (hTag)
    case ('checkExptLoc')
        % case is the experiment region location checkbox
        hObj = {handles.textExptLoc;handles.editLocValue;...
                handles.popupLocType;handles.textFrom;handles.popupLocRef};    
    otherwise
        % case is the other checkboxes
        hObj = {eval(sprintf('handles.text%s',hTag(6:end)));...
                eval(sprintf('handles.edit%s',hTag(6:end)))};
end

% only update if not initialising
if (~isa(eventdata,'char'))
    % sets the new parameter string
    paraStr = sprintf('rtP.%s.%s',uD{1},uD{2});  
    eval(sprintf('%s = pVal;',paraStr))

    % determines if at least one boolean value has been set
    if (strcmp(rtP.Stim.cType,'Ch2App'))
        % case is connecting a channel to a sub-region
        bVal = [rtP.popSC.isPtol,rtP.popSC.isVtol,rtP.popSC.isMtol];
    else
        % case is connecting a channel to a tube region
        bVal = [rtP.indSC.isTmove,rtP.indSC.isExLoc];
    end
    
    % updates the parameter struct
    if (~any(bVal))
        % if none of the boolean values set, then output an error message
        % and turn the check value back on
        eStr = 'At least one criteria checkbox must be set.';
        waitfor(errordlg(eStr,'Incorrect Criteria Configuration','modal'))
        set(hObject,'value',1)
        
        % exits the function 
        return
    else
        % if at least one set, then update the data struct
        setObjEnable(handles.buttonUpdate,'on')
        setappdata(handles.figTrackPara,'rtP',rtP)
    end
end

% updates the object enabled properties
if ~isempty(hObj)
    cellfun(@(x)(setObjEnable(x,pVal)),hObj);
end
    
% ----------------------------- %
% --- POPUP MENU PARAMETERS --- %
% ----------------------------- %

% --- Executes on selection change in popupSpeedType.
function popupSpeedType_Callback(hObject, eventdata, handles)

% retrieves the selected item and the popup strings
rtP = getappdata(handles.figTrackPara,'rtP');
[iSel,lStr] = deal(get(hObject,'value'),get(hObject,'string'));

% sets the population speed calculation type
switch (lStr{iSel})
    case ('Mean') % case is the mean population speed
        rtP.pvFcn = @nanmean;
    case ('Median') % case is the median population speed
        rtP.pvFcn = @nanmedian;
end
        
% resets the parameter struct into the GUI
setObjEnable(handles.buttonUpdate,'on')
setappdata(handles.figTrackPara,'rtP',rtP)       

% --- Executes on selection change in popupLocType.
function popupLocType_Callback(hObject, eventdata, handles)

% retrieves the selected item and the popup strings
rtP = getappdata(handles.figTrackPara,'rtP');
[iSel,lStr] = deal(get(hObject,'value'),get(hObject,'string'));

% updates the location value editbox
if (iSel == 1)
    set(handles.editLocValue,'string',num2str(rtP.indSC.ExLoc.pX(iSel)))
else
    set(handles.editLocValue,'string',num2str(100*rtP.indSC.ExLoc.pX(iSel)))
end

% updates the parameter struct
rtP.indSC.ExLoc.pType = lStr{iSel};
setObjEnable(handles.buttonUpdate,'on')
setappdata(handles.figTrackPara,'rtP',rtP)

% --- Executes on selection change in popupLocRef.
function popupLocRef_Callback(hObject, eventdata, handles)

% retrieves the selected item and the popup strings
rtP = getappdata(handles.figTrackPara,'rtP');
[iSel,lStr] = deal(get(hObject,'value'),get(hObject,'string'));

% sets the popupmenu value
rtP.indSC.ExLoc.pRef = lStr{iSel};

% updates the parameter struct
setObjEnable(handles.buttonUpdate,'on')
setappdata(handles.figTrackPara,'rtP',rtP)

% ------------------------------- %
% --- CHANNEL CONNECTION TYPE --- %
% ------------------------------- %

% --- Executes when selected object is changed in panelConnectType.
function panelConnectType_SelectionChangeFcn(hObject, eventdata, handles)

% retrieves the current table properties
rtP = getappdata(handles.figTrackPara,'rtP');
iMov = getappdata(handles.figTrackPara,'iMov');
iStim = getappdata(handles.figTrackPara,'iStim');

% sets the number of USB channels
nTube = getSRCountMax(iMov);
[nCh,nChMx,nApp] = deal(size(rtP.Stim.C2A,1),9,length(iMov.iR));
[isCh,nDev0,nCh0] = deal(nCh <= nChMx,max(iStim.ID(:,1)),max(iStim.ID(:,2)));

% sets the apparatus/fly index string selection arrays
dStr = cellfun(@(x)(sprintf('Device #%i',x)),num2cell(1:nDev0)','un',0);
cStr = cellfun(@(x)(sprintf('Channel #%i',x)),num2cell(1:nCh0)','un',0);
aStr = [{'None'};cellfun(@(x)(sprintf('Sub-Region #%i',x)),num2cell(1:nApp)','un',0)];
fStr = [{'None'};cellfun(@(x)(sprintf('Fly #%i',x)),num2cell(1:nTube)','un',0)];

% sets the initial data array
Data = [dStr(iStim.ID(:,1)),cStr(iStim.ID(:,2))];

% sets the table based on the selection
switch (get(get(handles.panelConnectType,'SelectedObject'),'tag'))
    case ('radioCh2App') % case is connecting channel to apparatus
        
        % sets the table properties
        cName = {'Device','Channel','Sub-Region'}';        
        cWid = {50+4*isCh,50+4*isCh,145+11*isCh};
        cForm = {'numeric', 'numeric', setupTableColumnFormat(iMov,rtP)};
        cEdit = [false,false,true];
                        
        % sets the table values
        jj = double(~isnan(rtP.Stim.C2A));
        jj(jj > 0) = rtP.Stim.C2A(jj > 0);        
        Data = [Data,cForm{3}(jj+1)'];
        
        % sets the connection type
        rtP.Stim.cType = 'Ch2App';      
        
        % disables/enables the relevant panels
        setPanelProps(handles.panelIndivStim,'off')        
        if (~isa(eventdata,'char'))                     
            hCheck = findall(handles.panelPopStim,'style','checkbox');
            for i = 1:length(hCheck)
                setObjEnable(hCheck(i),'on')
                checkSegPara(hCheck(i), [], handles)
            end
            
            set(handles.panelPopStim,'foregroundcolor',[0 0 0])
            
            % sets the combined activity panel
            if (iMov.isSet)
                % sub-regions have been set, so re-enable
                setPanelProps(handles.panelRegionActivity,'on')
            end
        end
                        
    case ('radioCh2Tube') % case is connecting channel to tube
        
        % sets the table properties
        cName = {'Device','Channel','Sub-Region','Fly'}';
        cWid = {50+4*isCh,50+4*isCh,88+6*isCh,50+5*isCh}; 
        cForm = {'numeric', 'numeric', aStr', fStr'};
        cEdit = [false,false,true,true];        
        
        % sets the table values
        ii = double(~isnan(rtP.Stim.C2T(:,1)));
        ii(ii > 0) = rtP.Stim.C2T(ii>0,1);        
        jj = double(~isnan(rtP.Stim.C2T(:,2)));
        jj(jj > 0) = rtP.Stim.C2T(jj>0,2);        
        Data = [Data,aStr(ii+1),fStr(jj+1)];
        
        % sets the connection type
        rtP.Stim.cType = 'Ch2Tube';
        
        % disables/enables the relevant panels
        setPanelProps(handles.panelPopStim,'off')        
        setPanelProps(handles.panelRegionActivity,'off')    
        if (~isa(eventdata,'char'))
            hCheck = findall(handles.panelIndivStim,'style','checkbox');
            for i = 1:length(hCheck)
                setObjEnable(hCheck(i),'on')
                checkSegPara(hCheck(i), [], handles)
            end
            
            set(handles.panelIndivStim,'foregroundcolor',[0 0 0])
        end                           
end

% enables the update button (if selecting the radio button manually)
if ~isa(eventdata,'char')
    setappdata(handles.figTrackPara,'rtP',rtP);
    setObjEnable(handles.buttonUpdate,'on')
end
    
% sets the table properties   
set(handles.tableUSBChannel,'ColumnFormat',cForm,'ColumnName',cName,...
                            'ColumnWidth',cWid,'ColumnEditable',cEdit,...
                            'Data',Data)                                      
                        
% --- Executes when selected object is changed in panelStimType.
function panelStimType_SelectionChangeFcn(hObject, eventdata, handles)
                        
% retrieves the current table properties
rtP = getappdata(handles.figTrackPara,'rtP');             

% sets the table based on the selection
switch (get(get(handles.panelStimType,'SelectedObject'),'tag'))
    case ('radioContStim') % case is connecting channel to apparatus                
        setObjEnable(handles.textFixedDur,'off') 
        setObjEnable(handles.editFixedDur,'off') 
        rtP.Stim.sType = 'Cont';    
        
    case ('radioSingleStim') % case is connecting channel to tube        
        setObjEnable(handles.editFixedDur,'on') 
        setObjEnable(handles.textFixedDur,'on') 
        rtP.Stim.sType = 'Single';        
end

% enables the update button (if selecting the radio button manually)
if ~isa(eventdata,'char')
    setappdata(handles.figTrackPara,'rtP',rtP);
    setObjEnable(handles.buttonUpdate,'on')
end

% --- Executes when selected object is changed in panelStimGen.
function panelStimGen_SelectionChangeFcn(hObject, eventdata, handles)

% retrieves the current table properties
rtP = getappdata(handles.figTrackPara,'rtP');             

% sets the table based on the selection
switch (get(get(handles.panelStimGen,'SelectedObject'),'tag'))
    case ('radioStimAll') % case is connecting channel to apparatus                   
        rtP.Stim.bType = 'All';        
        
    case ('radioStimAny') % case is connecting channel to tube        
        rtP.Stim.bType = 'Any';
        
end

% enables the update button (if selecting the radio button manually)
if ~isa(eventdata,'char')
    setappdata(handles.figTrackPara,'rtP',rtP);
    setObjEnable(handles.buttonUpdate,'on')
end

% ----------------------------- %
% --- OTHER CONTROL BUTTONS --- %
% ----------------------------- %

% --- Executes on button press in buttonUpdate.
function buttonUpdate_Callback(hObject, eventdata, handles)

% global variables
global isRTPChange

% retrieves the main GUI handle and closed loop parameter structs 
hGUI = getappdata(handles.figTrackPara,'hGUI');
rtP = getappdata(handles.figTrackPara,'rtP'); 
iMov = getappdata(handles.figTrackPara,'iMov'); 

% determines if the combined groups have been set correctly (if stimulation
% criteria is based on population activity)
if ((strcmp(rtP.Stim.cType,'Ch2App')) && (~all(isnan(rtP.combG.ind))))
    % determines the number of sub-regions within each connected group
    iGrp = num2cell(1:max(rtP.combG.ind));
    nGrp = cellfun(@(x)(length(find(rtP.combG.ind==x))),iGrp);
    ii = find(nGrp < 2);
    if (~isempty(ii))
        % if there any groups have less than two sub-regions then output an
        % error message to screen and exit
        mStr = sprintf(['The following groups have less than 2 ',...
                        'sub-regions selected:\n\n']);
        for i = 1:length(ii)
            mStr = sprintf('%s   => Group #%i\n',mStr,ii(i));
        end
                        
        % outputs the message to screen
        mStr = sprintf(['%s\nEither add in another sub-region for these ',...
                        'groups or set to "None".'],mStr);
        waitfor(msgbox(mStr,'Invalid Combined Groupings','modal'))
        
        % exits the function
        return
    end
end

% sets the combined group indices/order 
rtP.combG = getCombSubRegionIndices(iMov,rtP);

% updates the closed loop parameter struct in the main GUI
setObjEnable(hObject,'off')
setappdata(hGUI,'rtP',rtP);

% updates the experiment protocol menu item enabled properties
hGUIMain = guidata(hGUI);
switch (get(hGUI,'tag'))
    case ('figFlyRecord')
        % determines if the user is still tracking
        isTracking = ~get(hGUIMain.toggleStartTracking,'value');

        % updates the menu enabled properties
        isEnable = ~isempty(rtP.Stim) && isTracking;
        setObjEnable(hGUIMain.menuExptProto,isEnable)
        
    case ('figFlyTrack')
        isRTPChange = true;
end

% --- Executes on button press in buttonClose.
function buttonClose_Callback(hObject, eventdata, handles)

% prompts the user if they want to update (if a change has been made)
if strcmp(get(handles.buttonUpdate,'enable'),'on')
    uChoice = questdlg('Do you want to update the tracking parameters?',...
                       'Update Tracking Parameters?','Yes','No',...
                       'Cancel','Yes');
    switch (uChoice)
        case ('Yes') % case is the user chose to update the parameters
            buttonUpdate_Callback(handles.buttonUpdate, [], handles)   
        case ('Cancel') % case is the user cancelled
            return
    end
end

% if running the Recording GUI, then determine if the connection parameters
% are set. if so then enable the experimental menu item
hGUI = getappdata(handles.figTrackPara,'hGUI');
if strcmp(get(hGUI,'tag'),'figFlyRecord')
    uFunc = getappdata(hGUI,'updateExptMenuProps');
    uFunc(guidata(hGUI))
end

% closes the GUI
delete(handles.figTrackPara)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --------------------------------------- %
% --- OBJECT INITIALISATION FUNCTIONS --- %
% --------------------------------------- %

% --- initialises the parameter edit boxes properties --- %
function initParaEditBox(handles)

% retrieves the segmentation parameters
rtP = getappdata(handles.figTrackPara,'rtP');
      
% sets the properties for all the parameter edit boxes 
hEdit = findall(handles.figTrackPara,'style','edit');
for i = 1:length(hEdit)           
    % resets the parameter values and callback function
    uD = get(hEdit(i),'UserData');
    if (length(uD) == 2)
        % parameter has 2 sub-fields
        pVal = eval(sprintf('rtP.%s.%s',uD{1},uD{2}));    
    else
        % parameter has 3 sub-fields
        pInd = get(handles.popupLocType,'value');
        if (pInd == 1)
            pVal = eval(sprintf('rtP.%s.%s.%s(pInd)',uD{1},uD{2},uD{3}));    
        else
            pVal = eval(sprintf('rtP.%s.%s.%s(pInd)',uD{1},uD{2},uD{3}))*100;    
        end
    end
    
    % sets the editbox parameter value/callback function
    cFunc = @(hObj,e)TrackingPara('editSegPara',hObj,[],handles); 
    set(hEdit(i),'String',num2str(pVal),'Callback',cFunc);
end

% --- initialises the parameter check boxes properties --- %
function initParaCheckBox(handles)

% retrieves the segmentation parameters
rtP = getappdata(handles.figTrackPara,'rtP');

% sets the properties for all the parameter check boxes
hCheck = findall(handles.panelStimCriteria,'style','checkbox');
for i = 1:length(hCheck)              
    % resets the parameter values and callback function
    uD = get(hCheck(i),'UserData');
    pVal = eval(sprintf('rtP.%s.%s',uD{1},uD{2}));       
    
    % sets the editbox parameter value/callback function
    cFunc = @(hObj,e)TrackingPara('checkSegPara',hObj,[],handles); 
    set(hCheck(i),'Value',pVal,'Callback',cFunc);   
    checkSegPara(hCheck(i),'1',handles)
end

% --- initialises the USB Channel table properties --- %
function initUSBChannelTable(handles)

% retrieves the closed-loop parameter struct
rtP = getappdata(handles.figTrackPara,'rtP');

% determines if there are any apparatus set (from the CL para struct)
if (isempty(rtP.Stim))
    % if not, then clear the USB channel table 
    set(handles.tableUSBChannel,'Data',[])
    
    % disable the relevant panels
    setPanelProps(handles.panelStimGen,'off')
    setPanelProps(handles.panelUSBChannel,'off')
    setPanelProps(handles.panelConnectType,'off')
    setPanelProps(handles.panelStimType,'off')
    setPanelProps(handles.panelStimCriteria,'off')
    setPanelProps(handles.panelIndivStim,'off')
    setPanelProps(handles.panelPopStim,'off')
else
    % sets the connection type radio button values
    if (strcmp(rtP.Stim.cType,'Ch2App'))
        set(handles.radioCh2App,'value',1)
    else
        set(handles.radioCh2Tube,'value',1)
    end
    
    % sets the stimuli type radio button values
    if (strcmp(rtP.Stim.sType,'Cont'))
        set(handles.radioContStim,'value',1)
    else
        set(handles.radioSingleStim,'value',1)
    end    
    
    % sets the stimuli boolean generation type
    if (strcmp(rtP.Stim.bType,'All'))
        set(handles.radioStimAll,'value',1)
    else
        set(handles.radioStimAny,'value',1)
    end      
    
    % updates the panel properties
    panelConnectType_SelectionChangeFcn(handles.panelConnectType,'1',handles)  
    panelStimType_SelectionChangeFcn(handles.panelStimType,'1',handles)
end

% auto-resizes the table
autoResizeTableColumns(handles.tableUSBChannel);

% --- initialises the combined activity panel object properties --- %
function initCombActivity(handles)

% retrieves the current table properties
iMov = getappdata(handles.figTrackPara,'iMov');
rtP = getappdata(handles.figTrackPara,'rtP');

% if the sub-regions have not set, then disable the activity panel and exit
if ~iMov.isSet
    % resets the table background colour
    setObjVisibility(handles.tableCombActivity,'off') 
    setPanelProps(handles.panelRegionActivity,'off')       
    return
end

% case is channel to individual sub-regions
ii = double(~isnan(rtP.combG.ind));
ii(ii > 0) = rtP.combG.ind(ii > 0);        

% sets the number of USB channels
[iApp,jApp] = deal(num2cell(1:(max(ii)+1)),num2cell(find(iMov.ok)));

% sets the column form, sub-region and data string arrays
cForm = [{'None'},cellfun(@(x)(sprintf('Group #%i',x)),iApp,'un',0)];
srStr = cellfun(@(x)(sprintf('Sub-Region #%i',x)),jApp,'un',0);
Data = [srStr,cForm(ii+1)'];

% sets the object properties
set(handles.tableCombActivity,'ColumnFormat',['char',{cForm}],'Data',Data)    

% auto-resizes the table
autoResizeTableColumns(handles.tableCombActivity);

% --- initialises the USB Channel table properties --- %
function initSpeedPopupMenus(handles)

% retrieves the necessary data structs
rtP = getappdata(handles.figTrackPara,'rtP');

% sets the population speed popupmean value
switch (func2str(rtP.trkP.pvFcn))
    case ('nanmean') % case is the mean population speed
        set(handles.popupSpeedType,'value',1)
    case ('nanmedian') % case is the median population speed
        set(handles.popupSpeedType,'value',2)
end

% --- initialises the USB Channel table properties --- %
function initLocationPopupMenus(handles)

% retrieves the segmentation parameters
rtP = getappdata(handles.figTrackPara,'rtP');
iMov = getappdata(handles.figTrackPara,'iMov');

% sets the sub-struct index
pStrT = get(handles.popupLocType,'string');
if (is2DCheck(iMov))
    pStrR = {'Centre','Edge'};
else
    pStrR = {'Left Edge';'Right Edge'};
end

% retrieves the location/reference string values
[pType,pRef] = deal(rtP.indSC.ExLoc.pType,rtP.indSC.ExLoc.pRef);

% sets the popup menu values/list strings
set(handles.popupLocType,'value',find(strcmp(pStrT,pType)))
set(handles.popupLocRef,'String',pStrR,'value',find(strcmp(pStrR,pRef)))

% ------------------------------ %
% --- MISCELANEOUS FUNCTIONS --- %
% ------------------------------ %

% --- sets the parameter limits (based on the parameter string --- %
function nwLim = setParaLimits(paraStr,pInd)

% sets the parameter limits
switch (paraStr)
    % ----------------------------------- %
    % --- GENERAL TRACKING PARAMETERS --- %
    % ----------------------------------- %
    
    case ('Vmove') % case is threshold inactivity speed
        nwLim = [0.5,inf];
    case ('nSpan') % case is the speed smooth range
        nwLim = [1,60];     
        
    % ----------------------------------------------- %
    % --- GENERAL STIMULATION CRITERIA PARAMETERS --- %
    % ----------------------------------------------- %
        
    case ('Twarm') % case is the initial warm-up phase
        nwLim = [0,300];          
        
    % -------------------------------------------------- %
    % --- POPULATION STIMULATION CRITERIA PARAMETERS --- %
    % -------------------------------------------------- %        
        
    case ('Ptol') % case is proportion inactivity threshold
        nwLim = [0.01,0.99];
    case ('Vtol') % case is mean velocity threshold
        nwLim = [0,inf];
    case ('Mtol') % case is mean population inactivity time
        nwLim = [1,inf];
        
    % -------------------------------------------------- %
    % --- INDIVIDUAL STIMULATION CRITERIA PARAMETERS --- %
    % -------------------------------------------------- %        
        
    case ('Tmove') % case is movement threshold time        
        nwLim = [0,inf];    
    case ('pX') % case is the position value
        if (pInd == 1)
            % case is distance in mm
            nwLim = [0,inf];         
        else
            % case is distance as a proportional length
            nwLim = [0,100];          
        end         
        
    % --------------------------------------------------- %
    % --- STIMULI CHANNEL CROSS-CONNECTION PARAMETERS --- %
    % --------------------------------------------------- %            

    case ('Tdur') % fixed stimuli duration
        nwLim = [1,inf];                                  
    case ('Tcd') % case is cooldown period
        nwLim = [0,inf];             
end

% --- sets up the channel connection table column format
function cForm = setupTableColumnFormat(iMov,rtP)

% sets up the group/sub-region data strings
nApp = length(iMov.iR);
gStr = cellfun(@(x)(sprintf('Group #%i',x)),num2cell(1:nApp),'un',0);
aStr = cellfun(@(x)(sprintf('Sub-Region #%i',x)),num2cell(1:nApp)','un',0);

% determines which sub-regions are grouped
iGrp = getCombSubRegionIndices(iMov,rtP,1);      
ii = sum(~isnan(iGrp),2) > 1;
jj = ~ii & ~all(isnan(iGrp),2);
jj(unique(rtP.combG.ind(~isnan(rtP.combG.ind)))) = false;

% sets the final column format strings
cForm = [{'None'},gStr(ii),aStr(iGrp(jj,1))'];
