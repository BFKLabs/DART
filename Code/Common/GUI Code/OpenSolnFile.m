function varargout = OpenSolnFile(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @OpenSolnFile_OpeningFcn, ...
                   'gui_OutputFcn',  @OpenSolnFile_OutputFcn, ...
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

% --- Executes just before OpenSolnFile is made visible.
function OpenSolnFile_OpeningFcn(hObject, eventdata, handles, varargin)

% global variables
global tableUpdate yGap
[tableUpdate,yGap] = deal(false,0);

% Choose default command line output for OpenSolnFile
handles.output = hObject;

% sets in the input arguments
hFigM = varargin{1};

% updates the field values within the gui
setappdata(hObject,'iTab',1);
setappdata(hObject,'nExpMax',4);
setappdata(hObject,'hFigM',hFigM);
setappdata(hObject,'isChange',false);
setappdata(hObject,'iProg',getappdata(hFigM,'iProg'));
setappdata(hObject,'menuExit_Callback',@menuExit_Callback);

% hide the main gui
setObjVisibility(hFigM,'off')

% sets up the other components of the gui (dependent on the parent gui)
switch get(hFigM,'tag')
    case 'figFlyCombine'
        % csae is the data combining gui
        delete(handles.panelOuterFunc)
        delete(handles.panelOuterMulti)
        
        % sets up the gui panels
        setappdata(hObject,'sObj',OpenSolnTab(hObject,1));
        
    case 'figFlyAnalysis'
        % csae is the analysis gui
        setappdata(hObject,'sObj',OpenSolnTab(hObject,3));
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes OpenSolnFile wait for user response (see UIRESUME)
% uiwait(handles.figOpenSoln);

% --- Outputs from this function are returned to the command line.
function varargout = OpenSolnFile_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes when user attempts to close figOpenSoln.
function figOpenSoln_CloseRequestFcn(hObject, eventdata, handles)

% Hint: delete(hObject) closes the figure
menuExit_Callback(handles.menuExit, [], handles)

%-------------------------------------------------------------------------%
%                         MENU CALLBACK FUNCTIONS                         %
%-------------------------------------------------------------------------%

% -------------------------------------------------------------------------
function menuExit_Callback(~, ~, handles)

% initialisations
hFig = handles.figOpenSoln;
sObj = getappdata(hFig,'sObj');
hFigM = getappdata(hFig,'hFigM');
postSolnLoadFunc = getappdata(hFigM,'postSolnLoadFunc');

% determines if there is a change
isChange = sObj.isChange;
if isChange && isempty(sObj.sInfo)
    % if the data is cleared, only update if there is stored data
    isChange = ~isempty(getappdata(sObj.hFigM,'sInfo'));
end

% determines if there were any changes made
if isChange
    % if so, prompts the user if they wish to update the changes
    qStr = 'Do wish to update the changes you have made?';
    uChoice = questdlg(qStr,'Update Changes?','Yes','No','Cancel','Yes');
    switch uChoice
        case 'Yes'
            % case is the user chose to update            
            
            % retrieves the solution file struct from the loading object
            if sObj.sType == 3
                % determines how many compatible experiment groups exist
                indG = sObj.cObj.detCompatibleExpts();
                if length(indG) > 1
                    % updates the selected tab to the expt grouping tab
                    tabStr = 'Experiment Compatibility & Groups';
                    hTab = findall(sObj.hTabGrpF,'title',tabStr);
                    set(sObj.hTabGrpF,'SelectedTab',hTab);
                    
                    % if more than one group, then prompt the user if they
                    % wish to continue
                    hTabS = get(sObj.mltObj.hTabGrpL,'SelectedTab');
                    mStr = sprintf(['More than one compatible experiment ',...
                                'grouping has been determined.\n',...
                                'The currently selected experiment ',...
                                'group is "%s". Are you sure you ',...
                                'want to continue loading this ',...
                                'experiment group?'],get(hTabS,'Title'));
                    uChoice = questdlg(mStr,'Continue Loading Data?',...
                                    'Yes','No','Yes');
                    if ~strcmp(uChoice,'Yes')
                        % uf the user cancelled, then exit quitting
                        return
                    end
                end
                
                % case is for loading data from the analysis gui
                sInfo = resetLoadedExptData(sObj);
            else
                % case is for loading files from the combining gui
                sInfo = sObj.sInfo;
            end            
            
            % retrieves the names of the loaded experiments
            if isempty(sInfo)
                expFile = {'Dummy'};
            else
                expFile = cellfun(@(x)(x.expFile),sInfo,'un',0);
            end
            
            % determines if there are repeated experiment names
            if length(expFile) > length(unique(expFile))
                % if so, then output an error message to screen
                mStr = sprintf(['There are repeated experiment names ',...
                                'within the loaded data list.\nRemove ',...
                                'all repeated file names before ',...
                                'attempting to continue.']);
                waitfor(msgbox(mStr,'Repeated File Names','modal'))
                
                % exits the function
                return
            end
            
            % updates the search directories in the main gui
            setappdata(hFigM,'sDirO',sObj.fObj.sDir);             
            
            % delete the figure and run the post solution loading function
            delete(hFig)
            postSolnLoadFunc(hFigM,sInfo);                           
            
        case 'No'
            % case is the user chose not to update
            
            % delete the figure and run the post solution loading function
            delete(hFig)
            postSolnLoadFunc(hFigM);    
    end
else
    % otherwise, delete the figure and run the post solution loading func
    delete(hFig)
    postSolnLoadFunc(hFigM); 
end

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- resets the loaded experiment data
function sInfo = resetLoadedExptData(sObj)

% if there is no loaded data, then exit with an empty array
if isempty(sObj.sInfo)
    sInfo = [];
    return
end

% determines the currently selected experiment
indG = sObj.cObj.detCompatibleExpts();
iTabG = sObj.getTabGroupIndex();

% reduces the stimuli inforation/group names for the current grouping
iS = indG{iTabG};
grpName = sObj.gNameU{iTabG};
[sInfo,gName] = deal(sObj.sInfo(iS),sObj.gName(iS));

% removes any group names that are not linked to any experiment
hasG = cellfun(@(x)(any(cellfun(@(y)(any(strcmp(y,x))),gName))),grpName);
grpName = grpName(hasG);

% loops through each of the loaded 
for i = 1:length(sInfo)
    % sets the group to overall group linking indices
    indL = cellfun(@(y)(find(strcmp(gName{i},y))),grpName,'un',0);        
    
    % removes any extraneous fields    
    sInfo{i}.snTot = reduceExptSolnFiles(sInfo{i}.snTot,indL,grpName);
end
