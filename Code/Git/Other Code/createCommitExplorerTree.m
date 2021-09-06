% --- creates the commit explorer tree
function jRoot = createCommitExplorerTree(handles,sDiff)

% imports the checkbox tree
import com.mathworks.mwswing.checkboxtree.*

% parameters and initialisations
dX = 10;
hPanel = handles.panelFileChanges;
rStr = {'Current local version is up to date!','Code Changes...'};
hasFiles = any(cellfun(@length,getAllStructFields(sDiff)) > 0);

% sets up the directory trees structure
rootStr = setHTMLColourString('kb',rStr{1+hasFiles},1);
jRoot = DefaultCheckBoxNode(rootStr);

% creates the rest of the tree structure
fStr = fieldnames(sDiff);
for i = 1:length(fStr)
    % retrieves the file names for the current type
    sDiffF = eval(sprintf('sDiff.%s',fStr{i}));
    if ~isempty(sDiffF)
        % creates the root node for the current file type
        rootStr = setHTMLColourString('kb',sprintf('%s Files',fStr{i}),1);
        jRootF = DefaultCheckBoxNode(rootStr);
        
        % sets the children nodes for files for the current file type
        for j = 1:length(sDiffF)
            setupChildNode(jRootF,strsplit(sDiffF{j},'/'));
        end
        
        % adds the file type node to the root node
        jRoot.add(jRootF);
    end
end

% retrieves the object position
pPos = get(hPanel,'position');

% creates the final tree explorer object
jTree = com.mathworks.mwswing.MJTree(jRoot);
jCheckBoxTree = handle(CheckBoxTree(jTree.getModel),'CallbackProperties');
jScrollPane = com.mathworks.mwswing.MJScrollPane(jCheckBoxTree);
[~,~] = javacomponent(jScrollPane,[dX*[1 1],pPos(3:4)-[2*dX,35]],hPanel);

% only enabled the commit button if there are any commits available
setObjEnable(handles.buttonPushCommit,hasFiles)

% sets the callback function
hBut = handles.buttonPushCommit;
set(jCheckBoxTree,'MouseClickedCallback',{@selectCallback,jRoot,hBut})

% --- tree checkbox selection callback function
function selectCallback(~,~,jRoot,hBut)

% updates the commit buttons enabled properties
setObjEnable(hBut,~isempty(getSelectedTreeNodes(jRoot)))

% --- creates the child node for the root node for the fStrSp strings 
function jChild = setupChildNode(jRoot,fStrSp)

% imports the checkbox tree
import com.mathworks.mwswing.checkboxtree.*

% initialisation
jChild = [];

% determines if the current node already exists
for i = 1:jRoot.getChildCount
    jChildNw = jRoot.getChildAt(i-1);
    if strcmp(jChildNw,fStrSp{1})
        % if so, then set the child node to be the previous node
        jChild = jChildNw;
        break
    end
end

% if no previous node was found, then create a new one
if isempty(jChild)
    jChild = DefaultCheckBoxNode(fStrSp{1}); 
    set(jChild,'SelectionState',SelectionState.SELECTED)
    jRoot.add(jChild)
end

% add any further children nodes
if length(fStrSp) > 1
    jChild = setupChildNode(jChild,fStrSp(2:end));
end