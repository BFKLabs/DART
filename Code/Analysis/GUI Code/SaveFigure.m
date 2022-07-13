function varargout = SaveFigure(varargin)
% Last Modified by GUIDE v2.5 14-May-2014 00:44:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @SaveFigure_OpeningFcn, ...
    'gui_OutputFcn',  @SaveFigure_OutputFcn, ...
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

% --- Executes just before SaveFigure is made visible.
function SaveFigure_OpeningFcn(hObject, eventdata, handles, varargin)

% global variables
global isAllMet updateFlag figPos0
[updateFlag,isAllMet] = deal(2,false);

% sets the input arguments
hGUI = varargin{1};

% retrieves the undocked 
hFigU = hGUI.figUndockPlot;
figPos0 = get(hFigU,'position');
iProg = getappdata(hFigU,'iProg');
hPara = getappdata(hFigU,'hPara');
hGUIM = getappdata(hFigU,'hGUI');

% determines the number of apparatus  
hFigM = hGUIM.figFlyAnalysis;
sPara = getappdata(hFigM,'sPara');
pData = getappdata(hFigM,'pData');
plotD = getappdata(hFigM,'plotD');

% retrieves the plotting data struct
pDataH = getStructField(getappdata(hPara,'pObj'),'pData');

% determines which experiment/plot type has been selected, and determines
% if there is more than one figure type selected
[eInd,fInd,pInd] = getSelectedIndices(hGUIM);
isCalc = ~cellfun(@isempty,plotD{pInd}(:,eInd));
nReg = size(sPara.pos,1);

% updates the current plotting data struct parameters
pData{pInd}{fInd,eInd} = pDataH;
setappdata(hGUIM.figFlyAnalysis,'pData',pData);

% if so, then prompt the user if they want to output all the figures
if (sum(isCalc) > 1) && (nReg == 1)
    qStr = ['Multiple calculations exist. Do you wish to output ',...
            'current or all figures?'];
    uChoice = questdlg(qStr,'Figure Output Type','Current Figure',...
                            'All Figures','Cancel','Output Current');
    switch (uChoice)
        case ('All Figures')
            % if so, retrieve the plot data for all the figures
            pDataNw = cell2mat(pData{pInd}(isCalc,eInd));
            setappdata(hObject,'isCalc',find(isCalc))            
        case ('Current Figure')
            % otherwise, set the currently selected calculation
            pDataNw = pData{pInd}{fInd,eInd};                
        otherwise
            delete(hObject)
            return
    end
else
    % otherwise, set the currently selected calculation
    pDataNw = pData{pInd}{fInd,eInd};
end
    
% if there is more than one fly group (and there is more than one graph for
% the analysis function) then allow outputting of multiple images
if length(pDataNw) == 1
    % deletes the directory name panel
    delete(handles.panelDirName)
    handles = rmfield(handles,'panelDirName');    
    resetObjPos(hObject,'height',-100,1)    
    
    % enables the checkbox if there is more than one figure
    if nReg == 1
        if (pDataNw.nApp > 1) && pDataNw.hasSR
            setObjEnable(handles.checkOutputAll,'on');
            
        elseif any(strcmp(field2cell(pDataNw.pP,'Para'),'pMet') & ...
                   strcmp(field2cell(pDataNw.pP,'Type'),'List'))
            isAllMet = true;
            set(setObjEnable(handles.checkOutputAll,'on'),'string',...
                                'Output Images For All Metric Types');        
        end
    end
else
    % otherwise, set the directory string name    
    set(handles.editDirName,'string',['  ',iProg.OutFig]);
    set(handles.editSubDirName,'string','  ');
end
    
% sets the data structs into the GUI
setappdata(hObject,'hGUI',hGUI)
setappdata(hObject,'hGUIM',hGUIM)
setappdata(hObject,'iProg',iProg)
setappdata(hObject,'fDir',iProg.OutFig)
setappdata(hObject,'fName','Output Image')
setappdata(hObject,'sDir',[])
setappdata(hObject,'iPara',initParaStruct(handles,hGUI))
setappdata(hObject,'hPara',hPara)
setappdata(hObject,'pData',pDataNw)
setappdata(hObject,'fInd0',fInd)
setappdata(hObject,'sPara',sPara)

% Choose default command line output for SaveFigure
handles.output = hObject;
centreFigPosition(hObject);

% Update handles structure
setObjVisibility(hPara,'off')
setObjVisibility(hGUI.figUndockPlot,'off')
setObjVisibility(hGUIM.figFlyAnalysis,'off')
guidata(hObject, handles);

% UIWAIT makes SaveFigure wait for user response (see UIRESUME)
% uiwait(handles.figSaveFig);

% --- Outputs from this function are returned to the command line.
function varargout = SaveFigure_OutputFcn(hObject, eventdata, handles)

% Get default command line output from handles structure
varargout{1} = hObject;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% ----------------------------------------------- %
% --- BATCH FIGURE OUTPUT DIRECTORY CALLBACKS --- %
% ----------------------------------------------- %

% --- Executes on button press in buttonDirName.
function buttonDirName_Callback(hObject, eventdata, handles)

% prompts the user for the new default directory
dDir = getappdata(handles.figSaveFig,'fDir');
dirName = uigetdir(dDir,'Set The Base Figure Output Directory');
if (dirName == 0)
    % if the user cancelled, then escape
    return
else       
    % resets the base directory editbox string
    set(handles.editDirName,'string',['  ',dirName])
    setappdata(handles.figSaveFig,'fDir',dirName)
end

% --- Executes on button press in checkNewDir.
function checkNewDir_Callback(hObject, eventdata, handles)

% checks if the new string is not empty
[eStr,isNew] = deal({'off','on'},get(hObject,'value'));
sDir = getappdata(hObject,'sDir');

% sets the other object properties
setObjEnable(handles.buttonSaveImage,~isempty(sDir) || ~isNew)
setObjEnable(handles.editSubDirName,isNew)

% --- Executes on updating editSubDirName --- %
function editSubDirName_Callback(hObject, eventdata, handles)

% retrieves the file name
dirName = get(hObject,'string');
ii = regexp(dirName,'\S');

% resets the file name (with the first black spaces removed)
if (isempty(ii))
    dirName = '';
else
    dirName = dirName(ii(1):end);
end

% checks to see if the new string is valid
if chkDirString(dirName) || isempty(dirName)
    % checks if the new string is not empty
    setObjEnable(handles.buttonSaveImage,~isempty(dirName))
    
    % resets the enabled properties of the buttons
    setappdata(handles.figSaveFig,'sDir',dirName);
    set(hObject,'string',['  ',dirName])
else
    % otherwise, reset the solution file string
    set(hObject,'string',['  ',getappdata(handles.figSaveFig,'sDir')])    
end

% ---------------------------------- %
% --- IMAGE DIMENSIONS CALLBACKS --- %
% ---------------------------------- %

% --- Executes on button press in checkKeepAR.
function checkKeepAR_Callback(hObject, eventdata, handles)

% retrieves the parameter struct
iPara = getappdata(handles.figSaveFig,'iPara');
hEdit = findobj(handles.panelImageDim,'style','edit');

% sets the GUI properties based on the check value
if (get(hObject,'value'))
    % resets the width/height values
    [iPara.W,iPara.H] = deal(iPara.WmaxAR,iPara.HmaxAR);
    set(handles.editWidth,'string',num2str(iPara.W))
    set(handles.editHeight,'string',num2str(iPara.H))
    set(handles.textWidth,'string',num2str(iPara.W))
    set(handles.textHeight,'string',num2str(iPara.H))    
    
    % updates the parameter structs
    setappdata(handles.figSaveFig,'iPara',iPara)
    
    % disables the edit boxes
    set(handles.checkFullScreen,'value',0)
    setObjEnable(hEdit,'on')
end

% --- Executes on button press in checkFullScreen.
function checkFullScreen_Callback(hObject, eventdata, handles)

% retrieves the parameter struct
iPara = getappdata(handles.figSaveFig,'iPara');
hEdit = findobj(handles.panelImageDim,'style','edit');

% sets the GUI properties based on the check value
if (get(hObject,'value'))
    % resets the width/height values
    [iPara.W,iPara.H] = deal(iPara.Wmax,iPara.Hmax);
    set(handles.editWidth,'string',num2str(iPara.W))
    set(handles.editHeight,'string',num2str(iPara.H))
    set(handles.textWidth,'string',num2str(iPara.W))
    set(handles.textHeight,'string',num2str(iPara.H))
    
    % updates the parameter structs
    setappdata(handles.figSaveFig,'iPara',iPara)
    
    % disables the edit boxes
    set(handles.checkKeepAR,'value',0)
    setObjEnable(hEdit,'off')
else       
    % enables the edit boxes
    setObjEnable(hEdit,'on')    
end

% --- Executes on editting editWidth
function editWidth_Callback(hObject, eventdata, handles)

% retrieves the parameter struct and the new value
iPara = getappdata(handles.figSaveFig,'iPara');
nwVal = str2double(get(hObject,'string'));

% retrieves the maximum width
if (get(handles.checkKeepAR,'value'))
    Wmax = iPara.WmaxAR;
else
    Wmax = iPara.Wmax;
end

% check to see if the new value is valid
if (chkEditValue(nwVal,[1 Wmax],1))
    % if so, then update the parameter struct
    iPara.W = nwVal;
    
    % if keeping the aspect ratio, then rescale the height
    if (get(handles.checkKeepAR,'value'))
        iPara.H = roundP(iPara.W/iPara.rAR,1);
        set(handles.editHeight,'string',num2str(iPara.H))
    end
    
    % updates the parameter struct
    setappdata(handles.figSaveFig,'iPara',iPara);    
else
    % otherwise reset to the previous valid value
    set(hObject,'string',num2str(iPara.W))
end

% --- Executes on editting editHeight
function editHeight_Callback(hObject, eventdata, handles)

% retrieves the parameter struct and the new value
iPara = getappdata(handles.figSaveFig,'iPara');
nwVal = str2double(get(hObject,'string'));

% retrieves the maximum width
if (get(handles.checkKeepAR,'value'))
    Hmax = iPara.HmaxAR;
else
    Hmax = iPara.Hmax;
end

% check to see if the new value is valid
if (chkEditValue(nwVal,[1 Hmax],1))
    % if so, then update the parameter struct
    iPara.H = nwVal;
    
    % if keeping the aspect ratio, then rescale the height
    if (get(handles.checkKeepAR,'value'))
        iPara.W = roundP(iPara.H*iPara.rAR,1);
        set(handles.editWidth,'string',num2str(iPara.W))
    end
    
    % updates the parameter struct        
    setappdata(handles.figSaveFig,'iPara',iPara);    
else
    % otherwise reset to the previous valid value
    set(hObject,'string',num2str(iPara.H))
end

% ---------------------------------------- %
% --- PROGRAM CONTROL BUTTON CALLBACKS --- %
% ---------------------------------------- %

% --- Executes on button press in buttonSaveImage.
function buttonSaveImage_Callback(hObject, eventdata, handles)

% global variables
global isAllMet

% retrieves the data/parameter structs
hGUI = getappdata(handles.figSaveFig,'hGUI');
hGUIM = getappdata(handles.figSaveFig,'hGUIM');
iProg = getappdata(handles.figSaveFig,'iProg');
iPara = getappdata(handles.figSaveFig,'iPara');
pData = getappdata(handles.figSaveFig,'pData');

% retrieves the function class objects
fObj = getappdata(hGUIM.figFlyAnalysis,'fObj');
selectFcn = getappdata(hGUIM.figFlyAnalysis,'setSelectedNode');

% removes any previous plot figures
h = findall(0,'type','figure','tag','figOutputPlot');
if ~isempty(h); delete(h); end

% retrieves the original plot function list index/strings
[~,fInd0,pInd] = getSelectedIndices(hGUIM);

% determines the selected 
hSel = findobj(handles.panelImageType,'value',1);
fExtn = get(hSel,'userdata');
if strcmp(fExtn,'epsp')
    [fExtn,isPainters] = deal('eps',true);
else
    isPainters = false;
end

% prompts the user for the output file name/directory
if length(pData) == 1
    if strcmp(fExtn,'tiff')
        uiStr = {'*.tiff;*.tif','Tagged Image File Format (*.tiff, *.tif)'};
    else
        uiStr = {['*.',fExtn],get(hSel,'string')};    
    end
       
    % prompts the user for the output file name
    tStr = 'Save Analysis Figure';
    [fName,fDir,fIndex] = uiputfile(uiStr,tStr,iProg.OutFig);
    if fIndex == 0  
        % if the user cancelled, then exit the function
        return
    else        
        % otherwise set the image name
        imgName = {fullfile(fDir,fName)};        
    end
else
    % sets the full output figure directory string
    fDir = getappdata(handles.figSaveFig,'fDir');
    if get(handles.checkNewDir,'value')
        fDir = fullfile(fDir,getappdata(handles.figSaveFig,'sDir'));
    end
        
    % if the output directory does not exist, then create it
    if ~exist(fDir,'dir'); mkdir(fDir); end
    
    % sets the full image name strings and determines if any exist
    imgName = cellfun(@(x)(fullfile(fDir,[x,'.',fExtn])),...
                            field2cell(pData,'Name'),'un',0);    
    if any(cellfun(@(x)(exist(x,'file')),imgName))
        % if the solution file already exists, then 
        a = 'Image file(s) already exist. Do you wish to overwrite these files?';
        uChoice = questdlg(a,'Overwrite Solution File','Yes','No','Yes');            
        if ~strcmp(uChoice,'Yes')
            return
        end
    end    
end

% plots the analysis figure onto a temporary figure and updates the
% dimensions to that specified by the user
fig = hGUI.figUndockPlot; 
figPos = get(fig,'position');
resetObjPos(fig,'Width',iPara.W)
resetObjPos(fig,'Height',iPara.H)

% creates the load bar
wStr = 'Outputing Figures To File';
h = ProgressLoadbar(wStr);
N = length(pData); pause(0.01); 

% outputs the image(s) to file
for i = 1:N
    % updates the loadbar string
    try
        h.StatusMessage = sprintf('%s (Image %i of %i)',wStr,i,N);
    catch
        break
    end
    
    % updates the 
    if (N > 1)
        % enables the checkbox if there is more than one figure
        isOutAll = (pData(i).nApp > 1) && (pData(i).hasSR || isAllMet); 
        if isOutAll
            isOutAll = isOutAll && ...
                    (~isempty(pData(i).sP(3).Para) || isAllMet);
        end
        
        % sets the other object values
        set(handles.checkOutputAll,'value',isOutAll);          
        feval(selectFcn,hGUIM,fObj.getFuncIndex(pData(i).Name,pInd));
    end
    
    % saves the figure
    saveAnalysisFigure...
                (handles,imgName{i},fExtn,pData(i),isPainters,fig,h,N>1)
end

% closes the loadbar and deletes the temporary figure
feval(selectFcn,hGUIM,fInd0);
try; delete(h); end

% makes the figure visible again
set(fig,'position',figPos)

% resets the current figure to the 
set(0,'CurrentFigure',handles.figSaveFig)

% --- saves the analysis figure(s) to file
function saveAnalysisFigure...
                (handles,imgName,fExtn,pData,isPainters,fig,h,forceUpdate)

% global variables
global isAllMet

% sets the figure resolution (based on figure extension type)
if strcmp(fExtn,'.pdf')
    figRes = '-r0';
else
    figRes = '-r150';
end

% initialisations
sPara = getappdata(handles.figSaveFig,'sPara');
[isNewFig,ii] = deal(false,strfind(imgName,'.'));
lStr = 'Outputing Figures To File';
imgName0 = imgName(1:(ii(end)-1));

% if using subplots, then remove the sub-panel highlight colour
useSub = size(sPara.pos,1) > 1;
if useSub
    hPS = findall(fig,'tag','subPanel','HighlightColor',[1,0,0]);
    if ~isempty(hPS)
        set(hPS,'HighlightColor',[1,1,1])
    end
end

% determines if all the figures are to be output
try
    isOutAll = get(handles.checkOutputAll,'value');
catch
    isOutAll = false;
end

% sets the total number of figures to output
if isOutAll
    if isAllMet
        % determines the plot metric list item
        ii = find(strcmp(field2cell(pData.pP,'Para'),'pMet') & ...
                  strcmp(field2cell(pData.pP,'Type'),'List'));
                
        % retrieves the length of the list
        N = length(pData.pP(ii).Value{1,2});
    else
        % otherwise, set the length to be the region count
        N = pData.nApp;            
    end
else
    % only one output figure
    N = 1;
end

% creates all the required figures 
forceUpdate = forceUpdate || (N > 1);
for i = 1:N
    % updates the loadbar string
    if (N > 1)
        try
            h.StatusMessage = sprintf('%s (Sub-Image %i of %i)',lStr,i,N);
        catch
            break
        end
    end
    
    % if there is more than one graph, then reset the graph name
    if forceUpdate || strcmp(fExtn,'fig')
        % sets the new subplot indices        
        if isAllMet
            pData.pP(ii).Value{1,1} = i;
            if (N > 1)
                [x,y,~] = fileparts(imgName0);
                imgNameL = checkImageName(sprintf('%s (%s).%s',...
                                    y,pData.pP(ii).Value{1,2}{i},fExtn));                                        
                imgName = fullfile(x,imgNameL);
            end
        else
            if pData.hasSR
                pData.sP(3).Lim.appInd = i;
            end                        

            % updates the image name and replots the figure
            if (N > 1)
                [x,y,~] = fileparts(imgName0);
                imgNameL = checkImageName(sprintf('%s (%s).%s',...
                                            y,pData.appName{i},fExtn));                                        
                imgName = fullfile(x,imgNameL);
            end
        end
                
        % creates the new figure
        [figNw,isNewFig] = deal(updatePlotFigure(fig,pData,1,i),true);                        
        set(figNw,'units',get(fig,'units'),'position',...
                                get(fig,'position'),'visible','off')
    else
        % otherwise, use the undocked figure handle
        figNw = fig;
    end
    
    % outputs the figure based on the file extension        
    if ~isempty(findobj(figNw,'type','axes'))
        switch fExtn
            case ('eps') % case is an .eps image file
                if isPainters
                    set(figNw,'Renderer','painters','RendererMode','manual');
                    hgexport(figNw,sprintf('%s.eps',imgName(1:(end-4))));            
                else
                    % output the figure (dependent on OS type)    
                    if ispc
                        wState = warning('off','all');
                        export_fig(figNw,imgName,figRes);
                        warning(wState);
%                         print_eps(imgName, figNw)
                    else
                        print('-depsc2',figRes,imgName) 
                    end    
                end
                
            case ('fig') % case is a Matlab figure                       
                setObjVisibility(figNw,'on');
                saveas(figNw,imgName)
                
            otherwise % case is the other image types            
                try
                    % NOTE - increase resolution to desired amount here...                    
                    wState = warning('off','all');
                    export_fig(figNw,imgName,figRes);
                    warning(wState);
                    
                catch ME
                    eStr = {sprintf('Error outputting the image file:\n\n');...
                            sprintf(' => %s\n',imgName);...
                            ['Ensure that the image file is closed ',...
                             'and the filename is valid.']};
                    waitfor(errordlg(eStr,'Figure Output Error','modal'))
                    
                    % REMOVE ME
                    fprintf('Error = %s\n',ME.message);
                end
        end
    end
    
    % closes the temporary figure
    if isNewFig
        close(figNw);
    end
end

% resets the sub-panel highlight (if one exists)
if useSub && ~isempty(hPS)
    set(hPS,'HighlightColor',[1,0,0])
end

% --- Executes on button press in buttonClose.
function buttonClose_Callback(hObject, eventdata, handles)

% global variables
global updateFlag figPos0
updateFlag = 0;

% retrieves the parameter GUI struct handle
hPara = getappdata(handles.figSaveFig,'hPara');
hGUI = getappdata(handles.figSaveFig,'hGUI');

% deletes the GUI and makes the parameter GUI visible again
delete(handles.figSaveFig)

% runs the resize function
set(hGUI.figUndockPlot,'position',figPos0); pause(0.05);
setObjVisibility(hGUI.figUndockPlot,'on');
setObjVisibility(hPara,'on')

% feval(get(hGUI.figUndockPlot,'ResizeFcn'),hGUI.figUndockPlot,[])

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- initialises the parameter struct --- %
function iPara = initParaStruct(handles,hGUI)

% retrieves the plot panel
hPanel = hGUI.panelPlot;    

% allocates memory for the parameter struct
pUnits = get(hPanel,'Units'); set(hPanel,'Units','Pixels');
iPara = struct('W',[],'H',[],'Wmax',[],'Hmax',[],...
               'WmaxAR',[],'HmaxAR',[],'rAR',[]);

% retrieves the plot panel position and the maximum figure dimensions
pPos = get(hPanel,'position'); set(hPanel,'Units',pUnits);
[figPos,figPosMx] = getMaxScreenDim(pPos);

% sets the max width/height parameters and strings
iPara.rAR = pPos(3)/pPos(4);
[iPara.W,iPara.WmaxAR] = deal(figPos(3));
[iPara.H,iPara.HmaxAR] = deal(figPos(4));
[iPara.Wmax,iPara.Hmax] = deal(figPosMx(3),figPosMx(4));

% updates the editbox values
set(handles.editWidth,'string',num2str(iPara.W))
set(handles.editHeight,'string',num2str(iPara.H))
set(handles.textWidth,'string',num2str(iPara.WmaxAR))
set(handles.textHeight,'string',num2str(iPara.HmaxAR))
