function varargout = AnalyOpt(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AnalyOpt_OpeningFcn, ...
                   'gui_OutputFcn',  @AnalyOpt_OutputFcn, ...
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

% --- Executes just before AnalyOpt is made visible.
function AnalyOpt_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for AnalyOpt
handles.output = hObject;

% global variables
global mainProgDir resetPData isCalib
resetPData = false;

% determines if the tracking parameters have been set
A = load(fullfile(mainProgDir,'Para Files','ProgPara.mat'));
if ~isfield(A,'trkP')
    % track parameters have not been set, so initialise
    trkP = initTrackPara();
else
    % track parameters have been set
    trkP = A.trkP;
end

% retrieves the sub-image data struct
hGUI = varargin{1};
iMov = get(hGUI,'iMov');

% flags whether the background parameter struct needs to be reset
if ~isfield(iMov,'bgP')
    resetPara = true;
else
    resetPara = isempty(iMov.bgP);
end

% resets the algorithm type (from svm-single to bgs-single)
if resetPara
    % if there is no background parameters, then load from file
    pFile = fullfile(mainProgDir,'Para Files','ProgPara.mat');  
    A = load(pFile);
    
    % ensures that the algorithm type field has been set correctly
    if strcmp(A.bgP.algoType,'svm-single')
        A.bgP.algoType = 'bgs-single';
        save(pFile,'-struct','A')
    end
    
    % ensures that the path duration field is set
    if ~isfield(A.trkP,'nPath')
        A.trkP.nPath = 1;
        save(pFile,'-struct','A')        
    end
    
    % sets the background parameters
    iMov.bgP = A.bgP;
else
    % ensures that the algorithm type field has been set correctly
    if strcmp(iMov.bgP.algoType,'svm-single')
        iMov.bgP.algoType = 'bgs-single';
        setObjEnable(handles.buttonUpdate,'on')
    end
    
    % ensures that the path duration field is set
    if ~isfield(iMov,'nPath')
        iMov.nPath = 1;
        setObjEnable(handles.buttonUpdate,'on')        
    end
end

% adds the property fields to the figure
addObjProps(hObject,'hGUI',hGUI,'trkP',trkP,'trkP0',trkP,'iMov',iMov,...
                    'Img0',[]);

% initialises the GUI object fields
initParaEditBox(handles)
initAlgoType(handles)
initTablePara(handles)

% sets the image rotation checkbox
set(handles.checkUseRot,'value',iMov.useRot)
setPanelProps(handles.panelRotPara,iMov.useRot);

% sets the orientation angle calculation checkbox
if ~iMov.isSet
    set(setObjEnable(handles.checkCalcAngle,'off'),'value',false)
    
elseif ~is2DCheck(iMov)
    set(setObjEnable(handles.checkCalcAngle,'off'),'value',false)
    
else
    set(handles.checkCalcAngle,'value',iMov.calcPhi)    
end

% sets the separation colours checkbox (only applicable for multi-tracking)
if detMltTrkStatus(iMov)
    % sets the checkboxes value
    set(handles.checkSepColours,'value',iMov.sepCol)
else
    % otherwise, disable the checkbox
    set(setObjEnable(handles.checkSepColours,'off'),'value',false)
end

% sets the initial image (if calibrating)
if isCalib
    hGUIH = guidata(hGUI);
    Img0 = double(get(findobj(hGUIH.imgAxes,'type','Image'),'CData'));
    set(hObject,'Img0',getRotatedImage(iMov,Img0,1))
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes AnalyOpt wait for user response (see UIRESUME)
% uiwait(handles.figAnalyOpt);

% --- Outputs from this function are returned to the command line.
function varargout = AnalyOpt_OutputFcn(hObject, eventdata, handles)

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% -------------------------- %
% --- EDITBOX PARAMETERS --- %
% -------------------------- %

% --- the parameter editbox editting callback function --- %
function editSegPara(hObject, eventdata, handles)

% global parameters
global frmSz0 isCalib 

% retrieves the segmentation parameters
hFig = handles.output;
hGUI = get(hFig,'hGUI');
iMov = get(hFig,'iMov');
trkP = get(hFig,'trkP');

uD = get(hObject,'UserData');
isTrk = ~isfield(iMov,uD{1}) || strcmp(uD{1},'nPath');

% sets the parameter field (based on which struct it belongs to)
if isTrk
    [pStr,isTrk] = deal(sprintf('trkP.%s',uD{1}),true);
else
    [pStr,isTrk] = deal(sprintf('iMov.%s',uD{1}),false);    
end

% retrieves the parameter string and the new value/limits
nwVal = str2double(get(hObject,'string'));
[nwLim,isInt] = setParaLimits(uD{1});

% checks to see if the new value is valid
if chkEditValue(nwVal,nwLim,isInt)
    % if so, then update the parameter field and struct
    eval(sprintf('%s = nwVal;',pStr));
    
    % enables the update button
    setObjEnable(handles.buttonUpdate,'on')
    if isTrk
        set(hFig,'trkP',trkP)
    else
        set(hFig,'iMov',iMov)
        if strcmp(uD{1},'rotPhi')
            % retains a copy of the original sub-region data struct from
            % the main Fly Tracking GUI
            iMov0 = get(hGUI,'iMov');
            set(hGUI,'iMov',iMov)

            % updates the frame size
            if detIfRotImage(iMov)
                % case is the frame is rotated
                frmSz = frmSz0([2 1]);
            else
                % case is the frame is not rotated
                frmSz = frmSz0;
            end            
            
            % if the guide markers are present, then remove them
            hAngle = handles.buttonAngleGuide;
            if get(hAngle,'value')
                set(hAngle,'value',0)
                buttonAngleGuide_Callback(hAngle, '1', handles)
            end            
            
            % runs the image update function and reset the sub-region data
            % struct
            if isCalib
                Img0 = getRotatedImage(iMov,get(hFig,'Img0'));
                feval(hGUI.dispImage,guidata(hGUI),Img0,1) 
            else
                feval(hGUI.dispImage,guidata(hGUI)) 
            end
                
            resizeFlyTrackGUI(hGUI,frmSz)
            set(hGUI,'iMov',iMov0);
        end
    end
else
    % otherwise, revert back to the previous valid value
    set(hObject,'string',num2str(eval(pStr)))
end

% --- Executes on button press in checkCalcAngle.
function checkCalcAngle_Callback(hObject, eventdata, handles)

% retrieves the relevant data structs
hGUI = get(handles.output,'hGUI');
iMov = get(hGUI,'iMov');
pData = get(hGUI,'pData');
hGUIH = guidata(hGUI);

%
if get(hObject,'value')
    % determines if there is any currently tracked data
    if ~isempty(pData) || initDetectCompleted(iMov)
        % if so, then prompt the user if they wish to clear the data
        qStr = {'This action will clear the currently tracked data.';...
                '';'Do you still wish to continue?'};
        uChoice = questdlg(qStr,'Clear Tracked Data?','Yes','No','Yes');
        if ~strcmp(uChoice,'Yes')
            % if not, then reset the checkbox and exit
            set(hObject,'value',~get(hObject,'value'))
            return
        else
            % otherwise, clear the tracked data and background estimate
            [iMov.Ibg,pData] = deal([]);
            
            % removes the markers (if they are visible)
            if get(hGUIH.checkShowMark,'value')
                set(hGUIH.checkShowMark,'value',0)  
                showMarkFcn = get(hGUI,'checkShowMark_Callback');            
                showMarkFcn([],[],hGUIH)
            end
            
            % disables the relevant objects
            setObjEnable(hGUIH.buttonDetectFly,'off') 
            setObjEnable(hGUIH.checkShowMark,'off')              
        end
    end
else    
    % removes the orientation angle fields
    if isfield(pData,'Phi')
        % if so, then prompt the user if they wish to clear the data
        qStr = {['This action will clear the currently tracked ',...
                 'orientation data.'];'';'Do you still wish to continue?'};
        uChoice = questdlg(qStr,'Clear Tracked Data?',...
                            'Yes','No','Yes');
        if ~strcmp(uChoice,'Yes')      
            % if not, then reset the checkbox and exit
            set(hObject,'value',~get(hObject,'value'))
            return            
        else
            % removes the orientation data fields
            fStr = {'Phi','PhiF','axR','NszB'};
            for i = 1:length(fStr)
                if isfield(pData,fStr{i})
                    pData = rmfield(pData,fStr{i});
                end
            end
            
            % removes the fields from the data struct
            if (isfield(iMov,'NszP')); iMov = rmfield(iMov,'NszP'); end

            % removes the markers (if they are visible)
            if (get(hGUIH.checkShowAngle,'value'))
                set(hGUIH.checkShowAngle,'value',0)  
                showAngleFcn = get(hGUI,'checkShowAngle_Callback');            
                showAngleFcn([],[],hGUIH)
            end            
            
            % disables the relevant checkboxes                   
            setObjEnable(hGUIH.checkShowAngle,'off')         
        end
    end
    
    % flag that the orientation calculations are not required
    pData.calcPhi = false;    
end
    
% updates the boolean field
handles.output.trkP.calcPhi = get(hObject,'value');

% updates the orientation angle calculation flag
iMov.calcPhi = get(hObject,'value');
set(hGUI,'iMov',iMov,'pData',pData)

% enables the update button
setObjEnable(handles.buttonUpdate,'on')

% --- Executes on button press in checkUseRot.
function checkUseRot_Callback(hObject, eventdata, handles)

% global variables
global frmSz0 isCalib

% retrieves the display function handle
hFig = handles.output;
hGUI = get(hFig,'hGUI');
iMov = get(hFig,'iMov');
iMovH = get(hGUI,'iMov');
iData = get(hGUI,'iData');
pData = get(hGUI,'pData');

% retrieves the main GUI handles
hGUIH = guidata(hGUI);
sFunc = hGUI.setupDivisionFigure;
cFunc = hGUI.checkShowTube_Callback;

% parameters
[ii,is2D] = deal([2 1 4 3],is2DCheck(iMov));

% removes the division figure
feval(get(hGUI,'removeDivisionFigure'),hGUIH.imgAxes)

% sets the rotation flag value
iMov.useRot = get(hObject,'value');
set(hFig,'iMov',iMov);
setPanelProps(handles.panelRotPara,iMov.useRot);

% if the guide markers are present, then remove them
if get(handles.buttonAngleGuide,'value')
    set(handles.buttonAngleGuide,'value',0)
    buttonAngleGuide_Callback(handles.buttonAngleGuide, '1', handles)
end

% determines if the image needs to berotated by 90 degrees
isRot90 = detIfRotImage(iMov);

% updates the frame size
if isRot90
    % case is the frame is rotated
    frmSz = frmSz0([2 1]);
else
    % case is the frame is not rotated
    frmSz = frmSz0;
end

% updates the rotation flag
if iMov.isSet
    % resets the sub-region parameters
    [H,W,pDir] = deal(frmSz(1),frmSz(2),1-2*isRot90);            
    [iMov.nRow,iMov.nCol] = deal(iMov.nCol,iMov.nRow);    
    
    % resets the global outline position    
    iMov.posG = iMov.posG(ii);
    if isRot90        
        iMov.posG(1) = W - sum(iMov.posG([1 3]));        
    else
        iMov.posG(2) = H - sum(iMov.posG([2 4]));
    end    
           
    % permutes the sub-region positional vectors
    iMov.pos = cellfun(@(x)(x(ii)),iMov.pos,'un',0);
    iMov.posO = cellfun(@(x)(x(ii)),iMov.posO,'un',0);
    
    % offsets the positional vectors for the image rotation
    for i = 1:length(iMov.posO)
        if isRot90
            % case is using the rotated image
            iMov.pos{i}(1) = W - sum(iMov.pos{i}([1 3]));
            iMov.posO{i}(1) = W - sum(iMov.posO{i}([1 3]));
        else
            % case is using the normal image
            iMov.pos{i}(2) = H - sum(iMov.pos{i}([2 4]));
            iMov.posO{i}(2) = H - sum(iMov.posO{i}([2 4]));
        end       
    end    
    
    % determines if the background estimate has been calculated
    if initDetectCompleted(iMov)
        % retrieves the current image
        Img0 = getDispImage(iData,iMov,1,false,hGUIH);
        
        % sets the composite backgrounds for each phase
        Ibg0 = cell(length(iMov.vPhase),1);
        for i = 1:length(Ibg0)
            if ~isempty(iMov.Ibg{i})
                Icomp = createCompositeImage(Img0,iMov,iMov.Ibg{i});
                Ibg0{i} = double(rot90(Icomp,pDir));
            end
        end
        
        % sets the composite circular regions for each phase
        if is2D
            B0 = false(size(Img0));
            Bc0 = rot90(createCompositeImage(B0,iMov,iMov.autoP.B),pDir);
        end        
    end
    
    % updates the x/y-locations of the tube regions
    [yTube,xTube] = deal(iMov.xTube,iMov.yTube);
    [iC,iR,iCT,iRT] = deal(iMov.iR,iMov.iC,iMov.iRT,iMov.iCT);       
    
    % offsets the row/column indices and the x/y location of the turn 
    % regions for the rotation
    if isRot90
        % case is using the rotated image
        xTube = cellfun(@(x,y)...
                        (y(3)-x(end:-1:1,[2 1])),xTube,iMov.pos,'un',0);
        iC = cellfun(@(x)(W-x(end:-1:1)),iC,'un',0);
        
        if iscell(iCT{1})
            iCT = cellfun(@(x,y)(cellfun(@(yy)((length(x)+1)-...
                            yy(end:-1:1)),y,'un',0)),iC,iCT,'un',0);
        else
            iCT = cellfun(@(x,y)((length(x)+1)-y(end:-1:1)),iC,iCT,'un',0);                    
        end
           
        % reverses the column indices
        iCT = cellfun(@(x)(x(end:-1:1)),iCT,'un',0);
        
    else
        % case is using the normal image
        yTube = cellfun(@(x,y)...
                        (y(4)-x(end:-1:1,[2 1])),yTube,iMov.pos,'un',0);
        iR = cellfun(@(x)(H-x(end:-1:1)),iR,'un',0);
        
        if iscell(iRT{1})
            iRT = cellfun(@(x,y)(cellfun(@(yy)((length(x)+1)-...
                            yy(end:-1:1)),y,'un',0)),iR,iRT,'un',0); 
        else
            iRT = cellfun(@(x,y)((length(x)+1)-y(end:-1:1)),iR,iRT,'un',0);                     
        end
        
        % reverses the row indices
        iRT = cellfun(@(x)(x(end:-1:1)),iRT,'un',0);
    end    
    
    % resets the row/column tube region indices    
    [iMov.xTube,iMov.yTube] = deal(xTube,yTube); 
    [iMov.iC,iMov.iR] = deal(iC,iR); 
    [iMov.iCT,iMov.iRT] = deal(iCT,iRT);
    
    % determines if the background estimate has been calculated
    if initDetectCompleted(iMov)
        % if so, rotates the background image estimate        
        for i = 1:length(iMov.vPhase)
            if ~isempty(Ibg0{i})
                iMov.Ibg{i} = cellfun(@(x,y)(Ibg0{i}(x,y)),iR,iC,'un',0);
            end
        end
    
        % reverses the status/acceptance flags
        N = getSRCount(iMov);
        for i = 1:length(iMov.Status)
            iMov.Status{i}(1:N) = iMov.Status{i}(N:-1:1);
            iMov.flyok(1:N,i) = iMov.flyok(N:-1:1,i);
        end        
    end    
        
    % resets the x/y circle centre locations
    if is2D
        % rotates the search region binary masks
        iMov.autoP.B = cellfun(@(x,y)(Bc0(x,y)),iMov.iR,iMov.iC,'un',0);
        
        % rotates the circle coordinates
        [X,Y] = deal(iMov.autoP.Y',iMov.autoP.X');
        
        % offsets the x/y coordinates of the circle centers for rotation
        if isRot90
            % case is using the rotated image
            X = W - X(:,end:-1:1);
        else
            % case is using the normal image
            Y = H - Y(:,end:-1:1);
        end
        
        % updates the x/y coordinates of the circle centres
        [iMov.autoP.X,iMov.autoP.Y] = deal(X,Y);
    end
end

% determines if any positional data has been calculated
if ~isempty(pData)
    % if so, then set the orientation calculation flag
    if isfield(pData,'calcPhi')
        % flag is present, so return the value
        calcPhi = pData.calcPhi;
    else
        % no flag is set, so return a false flag
        calcPhi = false;
    end    
    
    % resets the x/y local/global coordinates
    for i = 1:length(pData.fPos)
        % sets a temporary copy of the local/global coordinates
        fPosL = cellfun(@(x)(x(:,[2 1])),pData.fPosL{i},'un',0);
        [x0,y0] = deal(iC{i}(1)-1,iR{i}(1)-1);
        
        % offsets the x/y coordinates for the rotation
        if isRot90
            % case is using the rotated image
            xL = length(iC{i});
            fPosL = cellfun(@(x)([xL-x(:,1),x(:,2)]),fPosL,'un',0);
            fPos = cellfun(@(x,y)...
                    ([x(:,1)+x0,x(:,2)+(y(1)-1)]),fPosL,iRT{i}','un',0);
            
        else
            % case is using the normal image
            yL = length(iR{i});
            fPosL = cellfun(@(x)([x(:,1),yL-x(:,2)]),fPosL,'un',0);   
            fPos = cellfun(@(x,y)...
                    ([x(:,1)+(y(1)-1),x(:,2)+y0]),fPosL,iCT{i}','un',0);            
        end
        
        % updates the local/global coordinates        
        [pData.fPos{i},pData.fPosL{i}] = deal(fPos,fPosL);
        
        % updates the orientation angles (if calculated)
        if (calcPhi)         
            % REMOVE ME LATER
            waitfor(msgbox('Check Angle Rotation Calculations!'))
            
            pData.Phi{i} = cellfun(@(x)(x-pDir*90),...
                                        pData.Phi{i}(end:-1:1),'un',0);
            pData.PhiF{i} = cellfun(@(x)(x-pDir*90),...
                                        pData.PhiF{i}(end:-1:1),'un',0);                        
        end
    end
    
    % updates the position data struct
    set(hGUI,'pData',pData);
end

% updates the data struct
iData.sz = frmSz;
set(hGUI,'iData',iData,'iMov',iMov);

% updates the frame size string
[m,n] = deal(iData.sz(1),iData.sz(2));
set(hGUIH.textFrameSizeS,'string',sprintf('%i %s %i',m,char(215),n));

%
initFcn = get(hGUI,'initMarkerPlots');
if get(hGUIH.checkSubRegions,'value')
    feval(initFcn,hGUIH)
else
    feval(initFcn,hGUIH,1)
end

% updates the main image
if isCalib
    Img0 = getRotatedImage(iMov,get(hFig,'Img0'));
    feval(hGUI.dispImage,hGUIH,Img0,1)
else
    feval(hGUI.dispImage,hGUIH)
end

% shows the sub-regions (if the checkbox is selected)
if get(hGUIH.checkSubRegions,'value')
    sFunc(iMov,hGUIH,true);
end

% shows the tube regions (if the checkbox is selected)
if get(hGUIH.checkShowTube,'value')
    cFunc(hGUIH.checkShowTube,[],hGUIH);
end

% enables the update button
setObjEnable(handles.buttonUpdate,'on')

% resizes the tracking GUI objects
resizeFlyTrackGUI(hGUI,frmSz)
set(hGUI,'iMov',iMovH);

% --- Executes on button press in buttonAngleGuide.
function buttonAngleGuide_Callback(hObject, eventdata, handles)

% retrieves the main axes handle
hFig = handles.output;
hGUI = get(hFig,'hGUI');
hAx = findall(hGUI,'type','axes');

% adds/removes the guide markers based on the toggle button value
if get(hObject,'Value')
    % sets up the gui markers for the main GUI
    setupGuideMarkers(handles,hAx)
else
    % removes all guide markers from the main GUI
    removeGuideMarkers(hAx)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    ALGORITHM TYPE    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on selection change in popupAlgoType.
function popupAlgoType_Callback(hObject, eventdata, handles)

% retrieves the segmentation parameters
uList = get(hObject,'UserData');
algoType = uList{get(hObject,'Value')};

% sets the algorithm type popup list index
handles.output.iMov.bgP.algoType = algoType;

% sets the enabled properties of the separation checkbox (only valid if the
% user is using multi-tracking)
setObjEnable(handles.checkSepColours,strContains(algoType,'multi'))

% enables the update button
setObjEnable(handles.buttonUpdate,'on')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    TABLE PARAMETERS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes when selected cell(s) is changed in tableRegionPara.
function tableRegionPara_CellSelectionCallback(hObject, eventdata, handles)

% if no indices are provided, then exit the function
if isempty(eventdata.Indices)
    return; 
else
    [iRow,iCol] = deal(eventdata.Indices(1),eventdata.Indices(2));
    if iCol ~= 2; return; end    
end

% retrieves the segmentation parameters
trkP = get(handles.output,'trkP');
cStr = {'pNC','pMov','pStat','pRej'};

% prompts the user for the new colour
nwCol = uisetcolor;
if (length(nwCol) > 1)
    % sets the classification parameters (based on the operating system type)
    if ispc
        % case is using PC
        [mMark,osStr] = deal(trkP.PC,'PC');                
    else
        % case is using Mac
        [mMark,osStr] = deal(trkP.Mac,'Mac');
    end    
    
    % determines if the colour has already been set for another marker
    pC0 = {mMark.pNC.pCol;mMark.pMov.pCol;mMark.pStat.pCol;mMark.pRej.pCol};
    if any(cellfun(@(x)(isequal(x,nwCol)),pC0((1:length(pC0)~=iRow))))
        % if so, then output an error
        eStr = 'Error! Classification colour is already in use';
        waitfor(errordlg(eStr,'Duplicate Classification Colours','modal'))
    else           
        % otherwise, update the parameter value
        eval(sprintf('trkP.%s.%s.pCol = nwCol;',osStr,cStr{iRow}))

        % updates the table
        Data = get(hObject,'Data');
        Data{iRow,iCol} = setCellColourString(rgb2hex(nwCol));
        set(hObject,'Data',Data)

        % updates the parameter struct
        setObjEnable(handles.buttonUpdate,'on')
        set(handles.output,'trkP',trkP)
    end
end

% --- Executes when entered data in editable cell(s) in tableRegionPara.
function tableRegionPara_CellEditCallback(hObject, eventdata, handles)

% if no indices are provided, then exit the function
if isempty(eventdata.Indices)
    return; 
else
    [iRow,iCol] = deal(eventdata.Indices(1),eventdata.Indices(2));
    if (iCol == 2); return; end    
end

% retrieves the segmentation parameters
trkP = get(handles.output,'trkP');
[cStr,fStr] = deal({'pNC','pMov','pStat','pRej'},{'','','pMark','mSz'});

% sets the parameter string (based on the operating system)
if ispc
    % case is using PC
    pStr = sprintf('trkP.PC.%s.%s',cStr{iRow},fStr{iCol});
else
    % case is using Mac
    pStr = sprintf('trkP.Mac.%s.%s',cStr{iRow},fStr{iCol});
end

% sets the parameter based on the type
if iCol == 4
    % determines if the new value is valid
    nwVal = eventdata.NewData;    
    if chkEditValue(nwVal,setParaLimits('mSz'),1)
        % updates the parameter values
        eval(sprintf('%s = nwVal;',pStr));
    else
        % resets the data within the table to the previous valid value
        Data = get(hObject,'Data');
        Data{iRow,iCol} = eval(pStr);
        set(hObject,'Data',Data)
        
        % exits the function
        return
    end
else
    % sets the marker name/symbol
    mSym = {'o','+','*','.','x','s','d'};
    mName = {'Circle','Plus','Asterisk','Point','Cross','Square','Diamond'};   
    
    % sets the field value (based on the operating system type)
    eval(sprintf('%s = mSym{strcmp(mName,eventdata.NewData)};',pStr))
end

% updates the parameter struct
setObjEnable(handles.buttonUpdate,'on')
set(handles.output,'trkP',trkP)

% --- Executes on button press in checkSepColours.
function checkSepColours_Callback(hObject, eventdata, handles)

% updates the separation colour flag
handles.output.iMov.sepCol = get(hObject,'value');

% enables the update button
setObjEnable(handles.buttonUpdate,'on')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    OTHER CONTROL BUTTONS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in buttonUpdate.
function buttonUpdate_Callback(hObject, eventdata, handles)

% global variables
global mainProgDir resetPData

% retrieves the main GUI handle and closed loop parameter structs 
hFig = handles.output;
trkP = get(hFig,'trkP');
iMov = get(hFig,'iMov');
hGUI = get(hFig,'hGUI');

% retrieves the plot marker update function handle
deleteAllMarkers = get(hGUI,'deleteAllMarkers');
initMarkerPlots = get(hGUI,'initMarkerPlots');
updateAllPlotMarkers = get(hGUI,'updateAllPlotMarkers');

% removes the video phase field (if resetting and is set)
if resetPData
    if isfield(iMov,'vPhase')
        iMov = rmfield(iMov,'vPhase');
    end
end

% updates the sub-region data struct into the main GUI
iMov.nPath = trkP.nPath;
set(hGUI,'iMov',iMov)

% retrieves the function handles    
hGUIH = guidata(hGUI);

% if the positional data needs to be updated, then prompt the user one more
% time if they still want to update the parameters. if not, then exit
if resetPData && ~isempty(get(hGUI,'pData'))
    uChoice = questdlg(['The action will clear any stored position data. ',...
                        'Do you still want to continue updating?'],...
                        'Continue Parameter Update?','Yes','No','Yes');
    if strcmp(uChoice,'Yes')
        set(hGUI,'pData',[])
        setObjEnable(hGUIH.checkShowMark,'off')             
    else
        return
    end
end

% loads the program parameter file
pFile = fullfile(mainProgDir,'Para Files','ProgPara.mat');
A = load(pFile);
A.bgP.algoType = iMov.bgP.algoType;
A.trkP = trkP;
save(pFile,'-struct','A');

% disables the update button
setObjEnable(hObject,'off')

% updates the checkbox values
hChk = {hGUIH.checkShowMark};
for i = 1:length(hChk)
    set(hChk{i},'value',strcmp(get(hChk{i},'enable'),'on'))
end

% deletes/re-adds the markers    
% dispImage(hGUIH);
deleteAllMarkers(hGUIH)
initMarkerPlots(hGUIH)
updateAllPlotMarkers(hGUIH,iMov,true);

% % resets the window style back to modal
% if ~isa(eventdata,'char')
%     pause(0.25);
%     try; set(handles.figAnalyOpt,'WindowStyle','modal'); end
% end

% --- Executes on button press in buttonClose.
function buttonClose_Callback(hObject, eventdata, handles)

% prompts the user if they want to update (if a change has been made)
if strcmp(get(handles.buttonUpdate,'enable'),'on')
    uChoice = questdlg('Do you want to update the tracking parameters?',...
                       'Update Tracking GUI Parameters?','Yes','No',...
                       'Cancel','Yes');
    switch uChoice
        case ('Yes') % case is the user chose to update the parameters
            buttonUpdate_Callback(handles.buttonUpdate, '1', handles) 
            
        case ('No') % case is the user to not update the parameters
            hFig = handles.output;
            hGUI = get(hFig,'hGUI');
            iMov = get(hGUI,'iMov');
            set(hFig,'iMov',iMov)
                        
            % resets the main GUI image
            set(handles.checkUseRot,'Value',iMov.useRot);
            checkUseRot_Callback(handles.checkUseRot, '1', handles)
            
        case ('Cancel') % case is the user cancelled
            return
    end
end

% removes any guide markers
hGUI = get(handles.output,'hGUI');
removeGuideMarkers(findall(hGUI,'type','axes'))

% closes the GUI
delete(handles.figAnalyOpt)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --------------------------------------- %
% --- OBJECT INITIALISATION FUNCTIONS --- %
% --------------------------------------- %

% --- initialises the parameter edit boxes properties --- %
function initParaEditBox(handles)

% retrieves the segmentation parameters
iMov = get(handles.output,'iMov');
trkP = get(handles.output,'trkP');
      
% sets the properties for all the parameter edit boxes 
hEdit = findall(handles.output,'style','edit');
for i = 1:length(hEdit)
    % resets the parameter values and callback function
    uD = get(hEdit(i),'UserData');
    if isfield(iMov,uD{1})
        pVal = getStructField(iMov,uD{1});
    else
        pVal = getStructField(trkP,uD{1});
    end
    
    % sets the editbox parameter value/callback function
    cFunc = @(hObj,e)AnalyOpt('editSegPara',hObj,[],handles); 
    set(hEdit(i),'String',num2str(pVal),'Callback',cFunc);    
end

% --- initialises the algorithm type dropdown-box
function initAlgoType(handles)

% retrieves the segmentation parameters
iMov = get(handles.output,'iMov');

% sets the algorithm type popup list index
uList = get(handles.popupAlgoType,'UserData');
iSel = find(strcmp(uList,iMov.bgP.algoType));
set(handles.popupAlgoType,'value',iSel)

% --- initialises the parameter table
function initTablePara(handles)

% retrieves the segmentation parameters
trkP = get(handles.output,'trkP');
[cStr,fStr] = deal({'pNC','pMov','pStat','pRej'},{'pCol','pMark','mSz'});

% sets the marker name/symbol
mSym = {'o','+','*','.','x','s','d'};
mName = {'Circle','Plus','Asterisk','Point','Cross','Square','Diamond'};

% sets the classification parameters (based on the operating system type)
if ispc
    % case is using PC
    cPara = trkP.PC;
else
    % case is using Mac
    cPara = trkP.Mac;
end

% sets the table data
Data = cell(4);
Data(:,1) = {'Non-Classified','Moving','Stationary','Rejected'}';

% sets the data fields for the table
for i = 1:length(cStr)
    for j = 1:length(fStr)
        % sets the parameter string
        pStr = sprintf('cPara.%s.%s',cStr{i},fStr{j});
        
        % sets the data field based on the parameter type
        switch (fStr{j})
            case ('pCol') % case is the classification colour
                Data{i,j+1} = setCellColourString(rgb2hex(eval(pStr)));
            case ('pMark') % case is the fly marker type
                Data{i,j+1} = mName{strcmp(mSym,eval(pStr))};
            case ('mSz') % case is the fly marker size
                Data{i,j+1} = eval(pStr);
        end
        
    end
end

% recalculates the table height
tPos = get(handles.tableRegionPara,'Position');
tPos(4) = calcTableHeight(4);

% sets the table parameters
cForm = {'char','char',mName,'numeric'};
set(handles.tableRegionPara,'ColumnFormat',cForm,'Data',Data,...
                'Position',tPos)
autoResizeTableColumns(handles.tableRegionPara);

% --------------------------------------- %
% --- ROTATION GUIDE MARKER FUNCTIONS --- %
% --------------------------------------- %

% --- sets up the rotation guide markers on the main GUI axes
function setupGuideMarkers(handles, hAx)

% parameters
yOfs = 15;
mStr = 'Draw an initial line along the landmark feature.';

% prompts the user to place the initial line on the main image
axes(hAx)
waitfor(msgbox(mStr,'','modal'))
hLine = imline(hAx);

% retrieves the dimensions of the set line and deletes it
hAPI = iptgetapi(hLine);
lPos0 = hAPI.getPosition();
delete(hLine);

% sets the start/end points of the set line (sorts the points from L-to-R)
[xP,iS] = sort(lPos0(:,1));
yP = lPos0(iS,2);

% creates the horizontal marker
hGuideH = imline(hAx,xP,yP(1)*[1,1]);
set(hGuideH,'tag','hGuideH')
hAPIH = iptgetapi(hGuideH);
setupGuideProps(hGuideH,hAPIH,1)

% creates the movable marker marker
hGuideV = imline(hAx,xP,yP);
set(hGuideV,'tag','hGuideV')
hAPIV = iptgetapi(hGuideV);
setupGuideProps(hGuideV,hAPIV,0)

% sets up the angle text object
hAngle = text(xP(1),yP(1)+yOfs,'0');
set(hAngle,'fontweight','bold','color','r','BackgroundColor','w',...
           'tag','hAngle','fontsize',16,'horizontalalignment','center')

% sets the position callback function
hGuideV.addNewPositionCallback(@(p)moveGuide(p,hAPIH,hAngle));

% initialises the 
moveGuide(lPos0,hAPIH,hAngle);

% --- removes the rotation guide markers on the main GUI axes
function removeGuideMarkers(hAx)

% retrives the object handles of the guide markers
hGuide = [findall(hAx,'tag','hAngle');...
          findall(hAx,'tag','hGuideH');...
          findall(hAx,'tag','hGuideV')];
if ~isempty(hGuide)
    % if they exist, then delete them
    delete(hGuide)
end

% --- sets up the properties for the guide markers
function setupGuideProps(hGuide,hAPI,isHoriz)

% sets the constraint function for the rectangle object
frmSz = getCurrentImageDim();
fcn = makeConstrainToRectFcn('imline',[0 frmSz(2)],[0 frmSz(1)]);
hAPI.setPositionConstraintFcn(fcn);
hAPI.setColor('r');

% updates the visibility of the given markers
set(findall(hGuide,'tag','top line'),'hittest','off')
setObjVisibility(findall(hGuide,'tag','bottom line'),'off')

% removes the hit-test for the first point
set(findall(hGuide,'tag','end point 1'),'hittest','off')
if isHoriz
    % if horizontal, then remove the hit-test for the second point 
    set(findall(hGuide,'tag','end point 2'),'hittest','off')
end

% --- updates on moving the guidance marker
function moveGuide(p,hAPIH,hAngle)

% resets the horizontal line marker
pH = hAPIH.getPosition();
pH(2,1) = p(2,1);
hAPIH.setPosition(pH(:,1),pH(:,2))

% updates the angle text label
phiNw = (180/pi)*atan(-diff(p(:,2))/diff(p(:,1)));
set(hAngle,'string',sprintf('%.2f',phiNw));

% ------------------------------ %
% --- MISCELANEOUS FUNCTIONS --- %
% ------------------------------ %

% --- sets the parameter limits (based on the parameter string --- %
function [nwLim,isInt] = setParaLimits(pStr)

% initialisations
isInt = true;

% sets the parameter limits
switch pStr
    % --------------------------------------- %
    % --- GENERAL SEGMENTATION PARAMETERS --- %
    % --------------------------------------- %
    
    case ('nFrmS')
        nwLim = [1,inf];
        
    case ('nPath')
        nwLim = [1,10000];    
        
    case ('rotPhi')
        [nwLim,isInt] = deal([-90,90],false);         
    
    % ------------------------------------------ %
    % --- ACTIVITY CLASSIFICATION PARAMETERS --- %
    % ------------------------------------------ %       
        
    case ('mSz')
        nwLim = [2 20*(1+ispc)];
end

% --- sets the cell colour string
function cellStr = setCellColourString(pHex)

% creates the colour string
cellStr = sprintf(['<html><font color="%s"><span style="background-',...
             'color:%s;">''aaaaaaaaaaa''</span></font></html>'],pHex,pHex);
