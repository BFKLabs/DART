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
global mainProgDir resetPData 
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
iMov = getappdata(varargin{1},'iMov');
iData = getappdata(varargin{1},'iData');

% resets the algorithm type (from svm-single to bgs-single)
if isempty(iMov.bgP)
    % if there is no background parameters, then load from file
    pFile = fullfile(mainProgDir,'Para Files','ProgPara.mat');  
    A = load(pFile);
    if strcmp(A.bgP.algoType,'svm-single')
        A.bgP.algoType = 'bgs-single';
        save(pFile,'-struct','A')
    end
    
    % sets the background parameters
    iMov.bgP = A.bgP;
else
    if strcmp(iMov.bgP.algoType,'svm-single')
        iMov.bgP.algoType = 'bgs-single';
        set(handles.buttonUpdate,'enable','on')
    end
end

% sets the data structs into the GUI
setappdata(hObject,'hGUI',varargin{1})
setappdata(hObject,'trkP',trkP)
setappdata(hObject,'iMov',iMov)

% initialises the GUI object fields
initParaEditBox(handles)
initAlgoType(handles)
initTablePara(handles)

if (~isfield(iData,'movStr'))
    set(handles.checkRot90,'value',false,'enable','off')
else
    set(handles.checkRot90,'value',iMov.rot90)
end

if (~iMov.isSet)
    set(handles.checkCalcAngle,'value',false,'enable','off')
elseif (~is2DCheck(iMov))
    set(handles.checkCalcAngle,'value',false,'enable','off')    
else
    set(handles.checkCalcAngle,'value',iMov.calcPhi)    
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
global resetPData 

% retrieves the segmentation parameters
trkP = getappdata(handles.figAnalyOpt,'trkP');
uD = get(hObject,'UserData');

% retrieves the parameter string and the new value/limits
pStr = sprintf('trkP.%s',uD{1});
[nwVal,nwLim] = deal(str2double(get(hObject,'string')),setParaLimits(uD{1}));

% checks to see if the new value is valid
if (chkEditValue(nwVal,nwLim,1))
    % if so, then update the parameter field and struct
    eval(sprintf('%s = nwVal;',pStr));    
    
    % enables the update button
    resetPData = true;
    set(handles.buttonUpdate,'enable','on')
    setappdata(handles.figAnalyOpt,'trkP',trkP)
else
    % otherwise, revert back to the previous valid value
    set(hObject,'string',num2str(eval(pStr)))
end

% --- Executes on button press in checkCalcAngle.
function checkCalcAngle_Callback(hObject, eventdata, handles)

% retrieves the relevant data structs
hGUI = getappdata(handles.figAnalyOpt,'hGUI');
iMov = getappdata(hGUI,'iMov');
pData = getappdata(hGUI,'pData');
hGUIH = guidata(hGUI);

%
if (get(hObject,'value'))
    % determines if there is any currently tracked data
    if ((~isempty(pData)) || initDetectCompleted(iMov))
        % if so, then prompt the user if they wish to clear the data
        uChoice = questdlg({'This action will clear the currently tracked data.';...
                            '';'Do you still wish to continue?'},'Clear Tracked Data?',...
                            'Yes','No','Yes');
        if (~strcmp(uChoice,'Yes'))
            % if not, then reset the checkbox and exit
            set(hObject,'value',~get(hObject,'value'))
            return
        else
            % otherwise, clear the tracked data and background estimate
            [iMov.Ibg,pData] = deal([]);
            
            % removes the markers (if they are visible)
            if (get(hGUIH.checkShowMark,'value'))
                set(hGUIH.checkShowMark,'value',0)  
                showMarkFcn = getappdata(hGUI,'checkShowMark_Callback');            
                showMarkFcn([],[],hGUIH)
            end
            
            % disables the relevant objects
            set(hGUIH.buttonDetectFly,'enable','off') 
            set(hGUIH.checkShowMark,'enable','off')              
        end
    end
else    
    % removes the orientation angle fields
    if (isfield(pData,'Phi'))
        % if so, then prompt the user if they wish to clear the data
        uChoice = questdlg({'This action will clear the currently tracked orientation data.';...
                            '';'Do you still wish to continue?'},'Clear Tracked Data?',...
                            'Yes','No','Yes');
        if (~strcmp(uChoice,'Yes'))        
            % if not, then reset the checkbox and exit
            set(hObject,'value',~get(hObject,'value'))
            return            
        else
            % removes the orientation data fields
            fStr = {'Phi','PhiF','axR','NszB'};
            for i = 1:length(fStr)
                if (isfield(pData,fStr{i}))
                    pData = rmfield(pData,fStr{i});
                end
            end
            
            % removes the fields from the data struct
            if (isfield(iMov,'NszP')); iMov = rmfield(iMov,'NszP'); end

            % removes the markers (if they are visible)
            if (get(hGUIH.checkShowAngle,'value'))
                set(hGUIH.checkShowAngle,'value',0)  
                showAngleFcn = getappdata(hGUI,'checkShowAngle_Callback');            
                showAngleFcn([],[],hGUIH)
            end            
            
            % disables the relevant checkboxes                   
            set(hGUIH.checkShowAngle,'enable','off')         
        end
    end
    
    % flag that the orientation calculations are not required
    pData.calcPhi = false;    
end
    
% updates the boolean field
trkP = getappdata(handles.figAnalyOpt,'trkP');
trkP.calcPhi = get(hObject,'value');
setappdata(handles.figAnalyOpt,'trkP',trkP);

% updates the orientation angle calculation flag
iMov.calcPhi = get(hObject,'value');
setappdata(hGUI,'iMov',iMov)
setappdata(hGUI,'pData',pData)

% enables the update button
set(handles.buttonUpdate,'enable','on')

% --- Executes on button press in checkRot90.
function checkRot90_Callback(hObject, eventdata, handles)

% global variables
global frmSz frmSz0

% retrieves the display function handle
hGUI = getappdata(handles.figAnalyOpt,'hGUI');
iMov = getappdata(hGUI,'iMov');
iData = getappdata(hGUI,'iData');
pData = getappdata(hGUI,'pData');

% retrieves the main GUI handles
hGUIH = guidata(hGUI);
sFunc = getappdata(hGUI,'setupDivisionFigure');
cFunc = getappdata(hGUI,'checkShowTube_Callback');

% parameters
[ii,is2D] = deal([2 1 4 3],is2DCheck(iMov));

% removes the division figure
feval(getappdata(hGUI,'removeDivisionFigure'),hGUIH.imgAxes)

% updates the frame size
iMov.rot90 = get(hObject,'value');
if (iMov.rot90)
    % case is the frame is rotated
    frmSz = frmSz0([2 1]);
else
    % case is the frame is not rotated
    frmSz = frmSz0;
end

% updates the rotation flag
if (iMov.isSet)
    % resets the sub-region parameters
    [pDir,H,W] = deal(1 - 2*iMov.rot90,frmSz(1),frmSz(2));            
    [iMov.nRow,iMov.nCol] = deal(iMov.nCol,iMov.nRow);    
    
    % resets the global outline position    
    iMov.posG = iMov.posG(ii);
    if (iMov.rot90)
        iMov.posG(1) = W - sum(iMov.posG([1 3]));        
    else
        iMov.posG(2) = H - sum(iMov.posG([2 4]));
    end    
           
    % permutes the sub-region positional vectors
    iMov.pos = cellfun(@(x)(x(ii)),iMov.pos,'un',0);
    iMov.posO = cellfun(@(x)(x(ii)),iMov.posO,'un',0);
    
    % offsets the positional vectors for the image rotation
    for i = 1:length(iMov.posO)        
        if (iMov.rot90)
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
        Img0 = get(findall(findall(hGUI,'type','axes'),'type','image'),'cdata');
        
        % sets the composite backgrounds for each phase
        Ibg0 = cell(length(iMov.vPhase),1);
        for i = 1:length(Ibg0)
            Ibg0{i} = double(rot90(createCompositeImage(Img0,iMov,iMov.Ibg{i}),pDir));
        end
        
        % sets the composite circular regions for each phase
        if (is2D)
            B0 = false(size(Img0));
            Bc0 = rot90(createCompositeImage(B0,iMov,iMov.autoP.B),pDir);
        end        
    end
    
    % updates the x/y-locations of the tube regions
    [yTube,xTube] = deal(iMov.xTube,iMov.yTube);
    [iC,iR,iCT,iRT] = deal(iMov.iR,iMov.iC,iMov.iRT,iMov.iCT);       
    
    % offsets the row/column indices and the x/y location of the turn 
    % regions for the rotation
    if (iMov.rot90)
        % case is using the rotated image
        xTube = cellfun(@(x,y)(y(3)-x(end:-1:1,[2 1])),xTube,iMov.pos,'un',0);
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
        yTube = cellfun(@(x,y)(y(4)-x(end:-1:1,[2 1])),yTube,iMov.pos,'un',0);
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
    
%     % sets the x/y locations of the tube regions
%     iMov.xTube = cellfun(@(x)(x(end:-1:1,:)),xTube,'un',0);
%     iMov.yTube = cellfun(@(x)(x(end:-1:1,:)),yTube,'un',0);
    
    % resets the row/column tube region indices    
    [iMov.xTube,iMov.yTube] = deal(xTube,yTube); 
    [iMov.iC,iMov.iR] = deal(iC,iR); 
    [iMov.iCT,iMov.iRT] = deal(iCT,iRT);
    
    % determines if the background estimate has been calculated
    if initDetectCompleted(iMov)
        % if so, rotates the background image estimate        
        for i = 1:length(iMov.vPhase)
            iMov.Ibg{i} = cellfun(@(x,y)(Ibg0{i}(x,y)),iMov.iR,iMov.iC,'un',0);
        end
    
        % reverses the status/acceptance flags
        N = getFlyCount(iMov);
        for i = 1:length(iMov.Status)            
            iMov.Status{i}(1:N) = iMov.Status{i}(N:-1:1);
            iMov.flyok(1:N,i) = iMov.flyok(N:-1:1,i);
        end
        
        % rotates the stationary coordinates (if any exist)
        for j = 1:size(iMov.pStats,2)
            for i = 1:size(iMov.pStats,1)             
                % retrieves the position segmentation statistics
                [pMu,pTol,fxPos,Nsz] = field2cell(...
                            iMov.pStats{i,j},{'pMu','pTol','fxPos','Nsz'});
                
                for k = 1:length(pMu)                                             
                    % sets the inverted index value
                    kk = (length(pMu) + 1) - k;
                    
                    % updates the position segmentation statistics array
                    iMov.pStats{i,j}(kk).pMu = pMu{k};
                    iMov.pStats{i,j}(kk).pTol = pTol{k};
                    iMov.pStats{i,j}(kk).Nsz = Nsz{k};
                    
                    % determines if there are any fixed coordinates
                    if (~all(isnan(fxPos{k}(:))))
                        % sets a copy of the permuted fixed coordinates
                        fxPos{k}(:,2:3) = fxPos{k}(:,[3 2]);
                                
                        % offsets the x/y coordinates for the rotation                        
                        if (iMov.rot90)
                            % case is using the rotated image
                            fxPos{k}(:,2) = (length(iMov.iCT{i}{k})+1) - fxPos{k}(:,2);                
                        else
                            % case is using the normal image
                            fxPos{k}(:,3) = (length(iMov.iRT{i}{k})+1) - fxPos{k}(:,3); 
                        end            
                    end
                    
                    % sets the final fixed positions
                    iMov.pStats{i,j}(kk).fxPos = fxPos{k};                    
                end
            end
        end
    end    
        
    % resets the x/y circle centre locations
    if (is2D)
        % rotates the search region binary masks
        iMov.autoP.B = cellfun(@(x,y)(Bc0(x,y)),iMov.iR,iMov.iC,'un',0);
        
        % rotates the circle coordinates
        [X,Y] = deal(iMov.autoP.Y',iMov.autoP.X');
        
        % offsets the x/y coordinates of the circle centers for rotation
        if (iMov.rot90)
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
if (~isempty(pData))
    % if so, then set the orientation calculation flag
    if (isfield(pData,'calcPhi'))
        % flag is present, so return the value
        calcPhi = pData.calcPhi;
    else
        % no flag is set, so return a false flag
        calcPhi = false;
    end    
    
    % resets the x/y locations of the 
    for i = 1:length(pData.fPos)
        % sets a temporary copy of the local/global coordinates
        fPos = cellfun(@(x)(x(:,[2 1])),pData.fPos{i},'un',0);
        fPosL = cellfun(@(x)(x(:,[2 1])),pData.fPosL{i},'un',0);
        
        % offsets the x/y coordinates for the rotation
        if (iMov.rot90)
            % case is using the rotated image
            fPosL = cellfun(@(x,y)([(length(y)+2)-x(:,1),x(:,2)]),...
                    fPosL(end:-1:1),iMov.iCT{i}','un',0);
            fPos = cellfun(@(x)([(length(iC{i})+2)-x(:,1),x(:,2)]),fPos(end:-1:1),'un',0);                
        else
            % case is using the normal image
            fPosL = cellfun(@(x,y)([x(:,1),(length(y)+2)-x(:,2)]),...
                    fPosL(end:-1:1),iMov.iRT{i}','un',0);
            fPos = cellfun(@(x)([x(:,1),(length(iR{i})+2)-x(:,2)]),fPos(end:-1:1),'un',0);                
        end
        
        % updates the local/global coordinates
        [pData.fPos{i},pData.fPosL{i}] = deal(fPos,fPosL);
        
        % updates the orientation angles (if calculated)
        if (calcPhi)            
            pData.Phi{i} = cellfun(@(x)(x-pDir*90),pData.Phi{i}(end:-1:1),'un',0);
            pData.PhiF{i} = cellfun(@(x)(x-pDir*90),pData.PhiF{i}(end:-1:1),'un',0);                        
        end
    end
    
    % updates the position data struct
    setappdata(hGUI,'pData',pData);
end

% updates the data struct
iData.sz = frmSz;
setappdata(hGUI,'iData',iData);
setappdata(hGUI,'iMov',iMov);

% updates the frame size string
[m,n] = deal(iData.sz(1),iData.sz(2));
set(hGUIH.textFrameSizeS,'string',sprintf('%i %s %i',m,char(215),n));

%
initFcn = getappdata(hGUI,'initMarkerPlots');
if (get(hGUIH.checkSubRegions,'value'))
    feval(initFcn,hGUIH)
else
    feval(initFcn,hGUIH,1)
end

% updates the main image
feval(getappdata(hGUI,'dispImage'),hGUIH)

% shows the sub-regions (if the checkbox is selected)
if (get(hGUIH.checkSubRegions,'value'))
    sFunc(iMov,hGUIH,true);
end

% shows the tube regions (if the checkbox is selected)
if (get(hGUIH.checkShowTube,'value'))
    cFunc(hGUIH.checkShowTube,[],hGUIH);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    ALGORITHM TYPE    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on selection change in popupAlgoType.
function popupAlgoType_Callback(hObject, eventdata, handles)

% retrieves the segmentation parameters
uList = get(hObject,'UserData');

% sets the algorithm type popup list index
iMov = getappdata(handles.figAnalyOpt,'iMov');
iMov.bgP.algoType = uList{get(hObject,'Value')};
setappdata(handles.figAnalyOpt,'iMov',iMov)

% enables the update button
set(handles.buttonUpdate,'enable','on')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    TABLE PARAMETERS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes when selected cell(s) is changed in tableRegionPara.
function tableRegionPara_CellSelectionCallback(hObject, eventdata, handles)

% if no indices are provided, then exit the function
if (isempty(eventdata.Indices))
    return; 
else
    [iRow,iCol] = deal(eventdata.Indices(1),eventdata.Indices(2));
    if (iCol ~= 2); return; end    
end

% retrieves the segmentation parameters
trkP = getappdata(handles.figAnalyOpt,'trkP');
cStr = {'pNC','pMov','pStat','pRej'};

% prompts the user for the new colour
nwCol = uisetcolor;
if (length(nwCol) > 1)
    % sets the classification parameters (based on the operating system type)
    if (ispc)
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
        set(handles.buttonUpdate,'enable','on')
        setappdata(handles.figAnalyOpt,'trkP',trkP)
    end
end

% --- Executes when entered data in editable cell(s) in tableRegionPara.
function tableRegionPara_CellEditCallback(hObject, eventdata, handles)

% if no indices are provided, then exit the function
if (isempty(eventdata.Indices))
    return; 
else
    [iRow,iCol] = deal(eventdata.Indices(1),eventdata.Indices(2));
    if (iCol == 2); return; end    
end

% retrieves the segmentation parameters
trkP = getappdata(handles.figAnalyOpt,'trkP');
[cStr,fStr] = deal({'pNC','pMov','pStat','pRej'},{'','','pMark','mSz'});

% sets the parameter string (based on the operating system)
if (ispc)
    % case is using PC
    pStr = sprintf('trkP.PC.%s.%s',cStr{iRow},fStr{iCol});
else
    % case is using Mac
    pStr = sprintf('trkP.Mac.%s.%s',cStr{iRow},fStr{iCol});
end

% sets the parameter based on the type
if (iCol == 4)
    % determines if the new value is valid
    nwVal = eventdata.NewData;    
    if (chkEditValue(nwVal,setParaLimits('mSz'),1))
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
set(handles.buttonUpdate,'enable','on')
setappdata(handles.figAnalyOpt,'trkP',trkP)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    OTHER CONTROL BUTTONS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in buttonUpdate.
function buttonUpdate_Callback(hObject, eventdata, handles)

% global variables
global mainProgDir resetPData

% retrieves the main GUI handle and closed loop parameter structs 
trkP = getappdata(handles.figAnalyOpt,'trkP');
iMov = getappdata(handles.figAnalyOpt,'iMov');
hGUI = getappdata(handles.figAnalyOpt,'hGUI');

% removes the video phase field (if resetting and is set)
if ~isempty(resetPData)
    if isfield(iMov,'vPhase')
        iMov = rmfield(iMov,'vPhase');
    end
end

% updates the sub-region data struct into the main GUI
setappdata(hGUI,'iMov',iMov)

% retrieves the function handles    
addFcn = getappdata(hGUI,'initMarkerPlots');
hGUIH = guidata(hGUI);

% if the positional data needs to be updated, then prompt the user one more
% time if they still want to update the parameters. if not, then exit
if (resetPData && ~isempty(getappdata(hGUI,'pData')))
    uChoice = questdlg(['The action will clear any stored position data. ',...
                        'Do you still want to continue updating?'],...
                        'Continue Parameter Update?','Yes','No','Yes');
    if (strcmp(uChoice,'Yes'))
        setappdata(hGUI,'pData',[])
        set(hGUIH.checkShowMark,'enable','off')             
    else
        return
    end
end

% loads the program parameter file
pFile = fullfile(mainProgDir,'Para Files','ProgPara.mat');
A = load(pFile);
A.bgP.algoType = iMov.bgP.algoType;
save(pFile,'-struct','A');

% disables the update button
set(hObject,'enable','off')

% deletes/re-adds the markers    
set(handles.figAnalyOpt,'WindowStyle','normal'); pause(0.25); 
addFcn(hGUIH,1); 

% resets the window style back to model
if (~isa(eventdata,'char'))
    pause(0.25);
    try; set(handles.figAnalyOpt,'WindowStyle','modal'); end
end

% --- Executes on button press in buttonClose.
function buttonClose_Callback(hObject, eventdata, handles)

% prompts the user if they want to update (if a change has been made)
if (strcmp(get(handles.buttonUpdate,'enable'),'on'))
    uChoice = questdlg('Do you want to update the tracking parameters?',...
                       'Update Tracking GUI Parameters?','Yes','No','Cancel','Yes');
    switch (uChoice)
        case ('Yes') % case is the user chose to update the parameters
            buttonUpdate_Callback(handles.buttonUpdate, '1', handles)   
        case ('Cancel') % case is the user cancelled
            return
    end
end

% closes the GUI
delete(handles.figAnalyOpt)

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    OBJECT INITIALISATION FUNCTIONS    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- initialises the parameter edit boxes properties --- %
function initParaEditBox(handles)

% retrieves the segmentation parameters
trkP = getappdata(handles.figAnalyOpt,'trkP');
      
% sets the properties for all the parameter edit boxes 
hEdit = findall(handles.figAnalyOpt,'style','edit');
for i = 1:length(hEdit) 
    % resets the parameter values and callback function
    uD = get(hEdit(i),'UserData');
    pVal = eval(sprintf('trkP.%s',uD{1}));
    
    % sets the editbox parameter value/callback function
    cFunc = @(hObj,e)AnalyOpt('editSegPara',hObj,[],handles); 
    set(hEdit(i),'String',num2str(pVal),'Callback',cFunc);    
end

% --- initialises the algorithm type dropdown-box
function initAlgoType(handles)

% retrieves the segmentation parameters
iMov = getappdata(handles.figAnalyOpt,'iMov');

% sets the algorithm type popup list index
uList = get(handles.popupAlgoType,'UserData');
iSel = find(strcmp(uList,iMov.bgP.algoType));
set(handles.popupAlgoType,'value',iSel)

% --- initialises the parameter table
function initTablePara(handles)

% retrieves the segmentation parameters
trkP = getappdata(handles.figAnalyOpt,'trkP');
[cStr,fStr] = deal({'pNC','pMov','pStat','pRej'},{'pCol','pMark','mSz'});

% sets the marker name/symbol
mSym = {'o','+','*','.','x','s','d'};
mName = {'Circle','Plus','Asterisk','Point','Cross','Square','Diamond'};

% sets the classification parameters (based on the operating system type)
if (ispc)
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
set(handles.tableRegionPara,'ColumnFormat',cForm,'Data',Data,'Position',tPos)
autoResizeTableColumns(handles.tableRegionPara);

% ------------------------------ %
% --- MISCELANEOUS FUNCTIONS --- %
% ------------------------------ %

% --- sets the parameter limits (based on the parameter string --- %
function nwLim = setParaLimits(pStr)

% sets the parameter limits
switch (pStr)
    % --------------------------------------- %
    % --- GENERAL SEGMENTATION PARAMETERS --- %
    % --------------------------------------- %
    
    case ('nFrmS')
        nwLim = [1,inf];
    
    %%%%%-----------------------------------  %%%%
    %%%%% ACTIVITY CLASSIFICATION PARAMETERS  %%%%
    %%%%%-----------------------------------  %%%%        
        
    case ('mSz')
        nwLim = [2 20*(1+ispc)];
end

% --- initialises the tracking parameter struct
function trkP = initTrackPara()

% initialises the tracking parameter struct
trkP = struct('nFrmS',50,'calcPhi',false,'rot90',false,'PC',[],'Mac',[]);

% sets the PC classification parameters
trkP.PC.pNC = struct('pCol',[1.0 1.0 0],'pMark','.','mSz',20);
trkP.PC.pMov = struct('pCol',[0.0 1.0 0.0],'pMark','.','mSz',20);
trkP.PC.pStat = struct('pCol',[1.0 0.4 0.0],'pMark','.','mSz',20);
trkP.PC.pRej = struct('pCol',[1.0 0.0 0.0],'pMark','.','mSz',20);

% sets the Mac classification parameters
trkP.Mac.pNC = struct('pCol',[1.0 1.0 0],'pMark','*','mSz',8);
trkP.Mac.pMov = struct('pCol',[0.0 1.0 0.0],'pMark','*','mSz',8);
trkP.Mac.pStat = struct('pCol',[1.0 0.4 0.0],'pMark','*','mSz',8);
trkP.Mac.pRej = struct('pCol',[1.0 0.0 0.0],'pMark','*','mSz',8);

% --- sets the cell colour string
function cellStr = setCellColourString(pHex)

% creates the colour string
cellStr = sprintf(['<html><font color="%s"><span style="background-',...
             'color:%s;">''aaaaaaaaaaa''</span></font></html>'],pHex,pHex);
