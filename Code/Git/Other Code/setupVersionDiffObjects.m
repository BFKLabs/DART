% --- sets up the version difference objects
function [jTab,hTabDiff] = setupVersionDiffObjects(hFig,hPanel,tStr,eState)

% sets the object positions
tabPos = getTabPosVector(hPanel,[5,5,-10,10]);
lPos = [5,20,tabPos(3)-10,tabPos(4)-54];
txtPos = [5,0,tabPos(3)-10,15];

% creates a tab panel group
hTabDiff = createTabPanelGroup(hPanel,1);
set(hTabDiff,'position',tabPos,'tag','hTabDiff')           

% creates the tabs for each code difference type
for i = 1:length(tStr)
    % creates a new tab panel
    hTabU = createNewTabPanel(hTabDiff,1,'title',tStr{i},'UserData',i);

    % creates the new text labels
    txtStr = sprintf('0 Files %s Between Versions',tStr{i});
    uicontrol('style','text','parent',hTabU,'HorizontalAlignment','left',...
              'position',txtPos,'string',txtStr,'FontWeight','bold',...
              'tag',[tStr{i},'T']);    
    
    % creates a new listbox
    hObj = uicontrol('style','listbox','parent',hTabU,...
                      'position',lPos,'tag',tStr{i});                  
    set(hObj,'Callback',{@selDiffItem,hFig})                         
end     

% retrieves the table group java object
jTab = findjobj(hTabDiff);
jTab = jTab(arrayfun(@(x)(strContains(class(x),'MJTabbedPane')),jTab));

% disables all the tabs for each group type
if nargin < 4
    arrayfun(@(x)(jTab.setEnabledAt(x-1,0)),1:length(tStr))
else
    arrayfun(@(x)(jTab.setEnabledAt(x-1,eState)),1:length(tStr))
end

% --- callback function for selecting the code difference listbox items
function selDiffItem(hObject, eventdata, hFig)

% retrieves the 
try    
    handles = guidata(hObject.Source);
catch
    handles = guidata(hObject);
end
    
% initialisations
iSel = get(hObject,'value');
pDiff = getappdata(hFig,'pDiff');
pCol = {[1.0,1.0,1.0],[0.9,0.7,0.7],[0.7,0.9,0.7]};
pTab = eval(sprintf('pDiff.%s(iSel)',get(hObject,'tag')));

% case is a text file is selected
hStr = {'Line #','Line #','Code'};
set(handles.tableCodeLine,'data',[],'enable','on','columnname',hStr)                         

% sets the file path string
if isempty(pTab.Path)
    pStr = fullfile('.',pTab.Name);    
else
    pStr = fullfile('.',pTab.Path,pTab.Name);
end
set(handles.textFilePath,'string',pStr)

%
if isempty(pTab.CBlk)
    % case is a binary file is selected
    set(handles.tableCodeLine,'data',{'','','Binary File Selected...'},...
                              'enable','off')                       
else    
    % initialisations
    [tData,bCol] = deal([]);
    
    %
    for i = 1:length(pTab.CBlk)
        % sets the code block header and block data
        hStr = {setHTMLColourString('b','####',1),...
                setHTMLColourString('b','####',1),...
                setHTMLColourString('b',sprintf('CODE BLOCK #%i',i),1)};                      
                                       
        tDataNw = [hStr;[pTab.CBlk(i).iLine,pTab.CBlk(i).Code]];
        bColNw = num2cell([0;pTab.CBlk(i).Type]);
        
        % inserts a gap for multiple code blocks
        if i > 1 
            [tDataNw,bColNw] = deal([{'','',''};tDataNw],[{0};bColNw]); 
        end        
        
        [tData,bCol] = deal([tData;tDataNw],[bCol;bColNw]);
    end
    
    % case is a text file is selected
    bColFin = cell2mat(cellfun(@(x)(pCol{x+1}),bCol,'un',0));
    set(handles.tableCodeLine,'data',tData,'visible','on');       
    autoResizeTableColumns(handles.tableCodeLine)
    set(handles.tableCodeLine,'backgroundcolor',bColFin)
end