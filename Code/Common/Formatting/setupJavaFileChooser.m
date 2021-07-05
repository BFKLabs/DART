function hjFileC = setupJavaFileChooser(hParent,varargin)

% initialisations
ip = inputParser;
pPos = get(hParent,'Position');
javaObjType = 'com.mathworks.hg.util.dFileChooser';
bgcolor = get(hParent,'backgroundcolor');

% sets up the input parser
addParameter(ip,'fSpec',{'All files','*.*'});
addParameter(ip,'defDir',pwd);
addParameter(ip,'defFile','');
addParameter(ip,'multiSelect',false);
addParameter(ip,'propCbFcn','');
addParameter(ip,'isSave',false);

% parses the input arguments
parse(ip,varargin{:})
p = ip.Results;

% creates the java object
fcPos = [0,0,pPos(3:4)-10];
wState = warning('off','all');
[hjFileC, ~] = javacomponent(javaObjType, fcPos, hParent);
warning(wState)

% sets the file chooser properties
hjFileC.setCurrentDirectory(java.io.File(p.defDir));
hjFileC.setMultiSelectionEnabled(p.multiSelect);
hjFileC.setDialogType(p.isSave);
hjFileC.setControlButtonsAreShown(false);
hjFileC.Background = java.awt.Color(bgcolor(1),bgcolor(2),bgcolor(3));

% sets the default file (if one is provided)
if ~isempty(p.defFile)
    hjFileC.setSelectedFile(java.io.File(p.defFile));
end

% creates the object
drawnow;

% Prepare the allowable file types filter (similar to the uigetfile function)
if ~isempty(p.fSpec)
    %
    hjFileC.setAcceptAllFileFilterUsed(false);
    
    % creates the file filter objects
    nSpec = length(p.fSpec);
    fFilter = cell(nSpec,1);
    for fIdx = 1:nSpec
        fFilter{fIdx} = AddFileFilter(hjFileC, p.fSpec{fIdx});
    end
    
    try
        hjFileC.setFileFilter(fFilter{1});
    catch
    end
end

% --- Add a file filter type
function fFilter = AddFileFilter(hjFileC, fSpec)

%
[fDesc,fExt] = deal(fSpec{1}, fSpec{2});
jObjEDT = 'javax.swing.plaf.basic.BasicFileChooserUI$AcceptAllFileFilter';

% ensures the extension array is stored as a cell array
if ~iscell(fExt); fExt = {fExt}; end

try    
    % creates the new file filter
    if strcmp(fExt{1},'*.*')
        % case is all files
        jChUI = javax.swing.plaf.basic.BasicFileChooserUI(hjFileC.java);
        fFilter = javaObjectEDT(jObjEDT,jChUI);
    else
        % case is specific extension
        fExt = regexprep(fExt,'^.*\*?\.','');
        fFilter = com.mathworks.mwswing.FileExtensionFilter(fDesc,fExt,0,1);
    end
    
    % adds the chooseable file filter
    javaMethodEDT('addChoosableFileFilter',hjFileC,fFilter);
catch
    % ignore...
    fFilter = [];
end

% --- Figure actions (Cancel & Open)
function ActionPerformedCallback(hjFileC, eventData, hParent)

%
hFig = hParent;
while ~isa(hFig,'matlab.ui.Figure')
    hFig = get(hFig,'Parent');
end

switch char(eventData.getActionCommand)
  case 'CancelSelection'
      % closes the figure
      close(hFig);
      
  case 'ApproveSelection'
      % 
      selFiles = cellfun(@char,cell(hjFileC.getSelectedFiles),'un',0);    
      if isempty(selFiles)
          selFiles = char(hjFileC.getSelectedFile);
      end
      
      %
      setappdata(hFig,'selFiles', selFiles);
      uiresume(hFig);
end