% --- executes on selecting a node from the history explorer tree
function versionHistSelect(hTree, evnt, varargin) 

% initialisations
isOn = 1;
hFig = findall(0,'tag','figGitVersion');
GF = getappdata(hFig,'GitFunc');
gHist = getappdata(hFig,'gHist');

% removes the data from the table
handles = guidata(hFig);
set(handles.tableCodeLine,'data',[])

% sets the current node based on the eventdata class
if isa(evnt,'com.mathworks.hg.peer.event.NodeSelectedEvent')
    % function is being run as a callback
    hNodeNw = get(evnt,'CurrentNode');
else
    % function is being run manually
    hNodeNw = evnt;
end

if isempty(hTree)
    % case is the version history was updated
    [status,dStr,isOn] = deal(0,[],0); 
    
elseif hTree.getRoot == hNodeNw
    % case is the root node is selected
    [status,dStr,isOn] = deal(0,[],0); 
    
else
    % retrieves the currently highlighted/selected nodes
    hNodePr = getSelectedNode(hTree.getRoot);
    
    % if the selected/highlighted nodes are the same then exit
    if isequal(hNodePr,hNodeNw)
        % case is the current version is selected
        [status,dStr,isOn] = deal(0,[],0); 
         
    elseif strContains(get(hNodeNw,'Name'),'Merge pull request')
        % case is the merge version is selected
        [status,dStr,isOn] = deal(0,[],0); 
        
    else
        % creates a loadbar
        if nargin == 2
            h = ProgressLoadbar('Determining Version Differences...');
        end
        
        % retrieves the index of the selected node 
        iSelPr = getNodeUserData(hNodePr);  
        iSelNw = getNodeUserData(hNodeNw); 
        
        % sets the previous/current node git history structs
        if GF.uType == 0
            % case is for a developer 
            [gHistPr,gHistNw] = deal(gHist(iSelPr),gHist(iSelNw));
        else
            % case is for a user
            gHistPr = getUserGitHistory(hFig,iSelPr);
            gHistNw = getUserGitHistory(hFig,iSelNw);
        end
        
        % determines the code difference between the 2 nodes
%         if isempty(gHistPr) && isempty(gHistNw)
        if isempty(gHistNw)
            [dStr,status] = deal('',0);
        elseif isempty(gHistPr)
            [dStr,status] = GF.gitCmd('commit-diff-current',gHistNw.ID);
        else
            [dStr,status] = GF.gitCmd('commit-diff',gHistPr.ID,gHistNw.ID);    
        end        
        
        if status ~= 0
            % sets the origin url (non-developer only)
            if GF.uType > 0; GF.gitCmd('set-origin'); end            
            
            % fetches the origin
            GF.gitCmd('fetch-origin')
            if GF.uType > 0; GF.gitCmd('rmv-origin'); end
            
            % retrieves the new the code difference
            [dStr,status] = GF.gitCmd('commit-diff',gHistPr.ID,gHistNw.ID);            
        end
        
        % creates a loadbar
        if exist('h','var'); delete(h); end
    end
end
    
% updates the version difference objects (if any difference was found)
if status == 0
    % retrieves the code difference struct and updates the difference objs
    pDiff = splitCodeDiff(dStr);
    updateDiffObjects(handles,pDiff);
    
else
    % updates the difference objects
    [pDiff,isOn] = deal(splitCodeDiff(''),0);
    updateDiffObjects(handles,pDiff)
    
    % outputs an error to screen
    wStr = 'Error with accessing Git Version History.';
    waitfor(errordlg(wStr,'Git Request Error','modal'))   
end

% sets the update version 
set(handles.textFilePath,'string','')
setObjEnable(handles.buttonUpdateVer,isOn)

% updates the code difference struct
setappdata(hFig,'pDiff',pDiff);    

% --- retrieves the nodes user data
function uData = getNodeUserData(hNode)

% retrieves the node's userdata
uData = hNode.getUserObject;
if isempty(uData)
    % if there is no userdata, then set the user data as being the last
    % sibling node on the current branch
    uData = [hNode.getParent.getUserObject;hNode.getSiblingCount];
    hNode.setUserObject(uData);
end