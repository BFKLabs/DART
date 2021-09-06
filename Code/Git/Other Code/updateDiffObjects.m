% --- updates the difference list objects
function updateDiffObjects(handles,jTab,pDiff)

% initialisations
dType = fieldnames(pDiff);
hTabG = findall(handles.panelFileSelect,'tag','hTabDiff');

% updates the tab/listboxes for each file action type
for i = 1:length(dType)
    % retrieves the tab/listbox object
    hTab = findall(hTabG,'tag',dType{i});
    hList = findall(hTab,'style','listbox');
    hTxt = findall(hTabG,'tag',[dType{i},'T']);
    
    % retrieves the data struct for this action type
    pTab = eval(sprintf('pDiff.%s',dType{i}));
    if isempty(pTab)
        % if there are no such files, then disable the tab
        jTab.setEnabledAt(i-1,0)
        set(hList,'string',{''},'enable','off')

        txtStr = sprintf('0 Files %s Between Versions',dType{i});
        set(hTxt,'string',txtStr,'enable','off');
        
    else
        % otherwise, update the listbox with the file names
        jTab.setEnabledAt(i-1,1)

        fName = field2cell(pTab,'Name');
        [tStr,nFile] = deal({'','s'},length(fName));
        txtStr = sprintf('%i File%s %s Between Versions',...
                        nFile,tStr{1+(nFile>1)},dType{i});
        
        set(hList,'string',fName(:),'enable','on')        
        set(hTxt,'string',txtStr,'enable','on');
    end
    
    % de-selects the listbox
    set(hTxt,'BackgroundColor',0.94*ones(1,3))
    set(hList,'max',2,'value',[])
end