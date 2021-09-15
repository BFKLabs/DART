% --- retrieves the selected experiment, funtion type and plot indices
function [exptInd,funcInd,plotInd] = getSelectedIndices(handles)

% retrieves the plot index
plotInd = get(handles.popupPlotType,'value');
if isempty(plotInd); plotInd = 0; end

% retrieves the tree object handle
hFig = handles.figFlyAnalysis;
hTreeF = getappdata(hFig,'hTreeF');

% retrieves the function index
if isempty(hTreeF)
    % if the tree is empty, then set empty index arrays
    funcInd = [];
else
    % determines the currently selected nodes
    hNodeS = hTreeF.getSelectedNodes;
    if isempty(hNodeS)
        % if the tree is not selected, then set empty index arrays
        funcInd = [];       
    elseif ~hNodeS(1).isLeafNode
        % if the leaf node isn't selected, then set empty index arrays
        funcInd = [];
    else
        % otherwise, return the function index
        funcInd = hNodeS(1).getUserObject;
    end
end
    
% if no function index is provided, then set a zero index
if isempty(funcInd); funcInd = 0; end

% retrieves the experiment/function plot index
exptInd = get(handles.popupExptIndex,'value');
if isempty(exptInd)
    % if no index is selected, then set a zero index
    exptInd = 0;
    
elseif (plotInd == 3)
    % case is multi-experiment functions
    exptInd = 1; 
end