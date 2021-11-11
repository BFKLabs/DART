function varargout = ExptProgress(varargin)
% Last Modified by GUIDE v2.5 17-May-2019 16:16:17

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ExptProgress_OpeningFcn, ...
                   'gui_OutputFcn',  @ExptProgress_OutputFcn, ...
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

% --- Executes just before ExptProgress is made visible.
function ExptProgress_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for ExptProgress
handles.output = hObject;

% sets the input arguments
exObj = varargin{1};
setappdata(hObject,'exObj',exObj);

% initialises the progress bar/stimulus information panels
initProgBars(handles,exObj)
initStimInfo(handles)
centreFigPosition(hObject);

% sets the waitbar strings
wStr = {'Overall Progress','Current Video Progress'};

% sets the important fields into the GUI
setappdata(hObject,'pFunc',@updateBar);
setappdata(hObject,'tFunc',@updateTextInfo);
setappdata(hObject,'wStr',wStr);
setappdata(hObject,'isCancel',0);
setappdata(hObject,'mxProp',1);
setappdata(hObject,'cProp',0);
setappdata(hObject,'hBut',handles.buttonAbort);

% Update handles structure
guidata(hObject, handles);
setObjVisibility(hObject,'off')

% UIWAIT makes ExptProgress wait for user response (see UIRESUME)
% uiwait(handles.figExptProg);

% --- Outputs from this function are returned to the command line.
function varargout = ExptProgress_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- FIGURE PROPERTY INITIALISATION FUNCTIONS --- %
% ------------------------------------------------ %

% --- initialises the progress bar properties --- %
function initProgBars(handles,exObj)

% global variables
global wImg
wImg = ones(1,1000,3);

% loads the experimental data struct
nStr = 1 + exObj.hasIMAQ;
hP = handles.panelProgress;
hObj = repmat(struct('wStr',[],'wAxes',[],'wImg',[]),nStr,1);

% removes the video progress waitbar figure
if ~exObj.hasIMAQ
    % retrieves the locations 
    dHght = 50;
    posP = get(hP,'position');
    figP = get(handles.figExptProg,'position');
    
    % deletes the video progressbar
    delete(findobj(hP,'UserData',2))
    
    % resets the GUI object dimensions    
    resetObjPos(handles.figExptProg,'height',figP(4)-dHght);    
    resetObjPos(hP,'height',posP(4)-dHght);
    
    % repositions the experiment progress objects
    resetObjPos(handles.textExptProgress,'Bottom',-dHght,1)
    resetObjPos(handles.axesExptProgress,'Bottom',-dHght,1)
    
    % resets the bottom location of the panel/cancel button
    resetObjPos(handles.panelStimInfo,'bottom',45);
    resetObjPos(handles.buttonAbort,'bottom',10);
end
    
% sets the properties for each of the progress bar elements
for j = 1:nStr
    % sets the axes properties
    hObj(j).wStr = findobj(hP,'UserData',j,'style','text');
    hObj(j).wAxes = findobj(hP,'UserData',j,'type','axes');

    % clears the axis and adds the image
    cla(hObj(j).wAxes);
    hObj(j).wImg = image(wImg,'parent',hObj(j).wAxes);
    
    % updates the progress bar axes
    set(hObj(j).wAxes,'xtick',[],'ytick',[],'xticklabel',[],...
                      'yticklabel',[],'xcolor','k','ycolor','k','box','on')    
end

% sets the objects into the GUI
setappdata(handles.figExptProg,'hObj',hObj)

% --- initialises the progress bar properties --- %
function initStimInfo(handles)

% panel/textbox
hP = handles.panelStimInfo;
[txtL,txtW,txtH,dY] = deal([10 135 230 290],[125 80 60 140],20,10);

% retrieves the experimental data struct
hFig = handles.figExptProg;
exObj = getappdata(hFig,'exObj');
[nCount,chID] = deal([]);

% if the experiment type field is not set, then set its value
if isempty(exObj.iExpt.Info.Type) || ~ischar(exObj.iExpt.Info.Type)
    % sets the experiment type based on whether a RT expt is running
    if exObj.isRT
        exptType = 'RTTrack';
    else
        iType = double(exObj.hasIMAQ) + 2*double(exObj.hasDAQ);
        exptTypeS = {'RecordOnly','StimOnly','RecordStim'};
        exptType = exptTypeS{iType};
    end    
    
    % sets the experiment type into the experiment information struct
    exObj.iExpt.Info.Type = exptType;
end

% sets the number of text objects to add
switch (exObj.iExpt.Info.Type)
    case {'RecordStim','StimOnly'}
        % case is a stimuli-dependent experiment
        ID = field2cell(exObj.ExptSig,'ID');
        chInfo = getappdata(exObj.hExptF,'chInfo'); 
        iOfs = double(exObj.hasIMAQ);
        
        % sets the channel/device ID flags
        chID = cell2mat(cellfun(@(x)(unique(x,'rows')),ID,'un',0));
        chID = [chID,zeros(size(chID,1),1)];
        devID = cell2mat(chInfo(:,1));
        
        % sets the final mapping values
        nStim = size(chID,1) + iOfs;
        nCount = zeros(nStim-iOfs,1);
        for i = 1:nStim-iOfs
            ii = find(devID==chID(i,1),chID(i,2),'first');
            chID(i,3) = ii(end);            
            nCount(i) = sum(cellfun(@(x)(isequal(x,chID(i,1:2))),...
                                num2cell(exObj.ExptSig(chID(i,1)).ID,2)));
        end
        
    otherwise
        % case is RT tracking or recording only
        nStim = 1;
end
    
% resets the panel position
pPos = [10 45 440 ((nStim+1)*txtH+2*dY)];
set(hP,'position',pPos);

% updates the progress bar location
pPos2 = get(handles.panelProgress,'position');
pPos2(2) = (pPos(2)+pPos(4)) + dY;
set(handles.panelProgress,'position',pPos2);

% resets the figure height
fPos = get(handles.figExptProg,'position');
fPos(4) = (25 + 4*dY) + (pPos(4) + pPos2(4));
set(handles.figExptProg,'position',fPos)

% sets the header locations
YnwH = dY + nStim*txtH;
hEditH = findobj(handles.panelStimInfo,'UserData',1,'Style','text');

% resets the header positions
for i = 1:length(hEditH)
    % resets the header text-box location
    ePos = get(hEditH(i),'position');
    ePos(2) = YnwH;
    
    % updates the text-box position
    set(hEditH(i),'position',ePos);
end
    
% creates the text-boxes for all the rows
hText = cell(nStim,length(txtL));
for i = 1:nStim
    % sets the new Y location within the 
    Ynw = dY + (i-1)*txtH;
    j = nStim - (i-1);
    
    % creates all the text objects for the current row
    for k = 1:length(txtL)
        % sets the horizontal alignment flag
        hAlign = 'center';
        
        % sets the editbox string
        switch (k)
            case (1) % case is the stimuli number
                hAlign = 'right';                
                if (j == 1) && exObj.hasIMAQ
                    tStr = 'Video Recordings: ';                   
                else
                    iOfs = double(exObj.hasIMAQ);
                    tStr = sprintf('%s (%s): ',chInfo{chID(j-iOfs,3),3},...
                                               chInfo{chID(j-iOfs,3),2});                
                end
            case (2) % case is the current count (initially 0)
                tStr = '0';
                
            case (3) % case is the total stimuli count
                if (j == 1) && exObj.hasIMAQ
                    tStr = num2str(exObj.iExpt.Video.nCount);
                else
                    iOfs = double(exObj.hasIMAQ);
                    tStr = num2str(nCount(j-iOfs));
                end
                
            case (4) % case is the time to next stimuli field
                tStr = 'N/A';
        end
        
        % creates the new text-box and sets it properties
        nwPos = [txtL(k) Ynw txtW(k) txtH];
        hText{i,k} = uicontrol(hP,'style','text','position',nwPos,...
                     'FontSize',10,'UserData',k,'FontWeight','bold',...
                     'HorizontalAlignment',hAlign,'string',tStr,'tag',...
                     sprintf('text%i',j));
    end    
end

% sets the number of information fields to update
setappdata(hFig,'nInfo',nStim);
setappdata(hFig,'hText',hText);
setappdata(hFig,'nCount',nCount);
setappdata(hFig,'chID',chID);

% --- OBJECT CALLBACK FUNCTIONS --- %
% --------------------------------- %

% --- updates the stimulus info text labels --- %
function updateTextInfo(ind,tStr,h,tCol)

% sets the text colour (if not provided)
if (nargin == 3)
    tCol = 'k';
end

% updates the corresponding text object (to the index array, ind)
hh = guidata(h);
hText = findobj(hh.panelStimInfo,'Tag',...
                            sprintf('text%i',ind(1)),'UserData',ind(2));
set(hText,'string',tStr,'ForegroundColor',tCol);
                        
% --- updates the waitbar status string and proportion complete --- %
function isCancel = updateBar(ind,wStr,wProp,h)

% global variables
global wImg 

% initialisations
isCancel = 0;

% retrieves the waitbar handle (if not set)
if nargin == 3
    h = findobj('tag','waitbar');
end

% retrieves the current status of the waitbar cancel status
[hObj,hBut] = deal(getappdata(h,'hObj'),getappdata(h,'hBut'));    
if get(hBut,'value')   
    % if flagged to cancel, then delete the waitbar object
    isCancel = 1;
else
    % sets the new image
    wLen = roundP(wProp*1000,1);
    wImg(:,1:wLen,2:3) = 0;
    wImg(:,(wLen+1):end,2:3) = 1;

    % updates the status bar and the string
    set(hObj(ind).wImg,'cdata',wImg);
    set(hObj(ind).wStr,'string',wStr)
    drawnow;     
end
