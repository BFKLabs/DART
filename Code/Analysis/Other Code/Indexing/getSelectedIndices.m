% --- retrieves the selected experiment, funtion type and plot indices
function [exptInd,funcInd,plotInd,funcIndT] = getSelectedIndices(handles)

% retrieves the plot index
plotInd = get(handles.popupPlotType,'value');
if (isempty(plotInd)); plotInd = 0; end

% retrieves the function index
fcnStr = get(handles.listPlotFunc,'string');
if (isempty(fcnStr))
    [funcIndT,funcInd] = deal([]);
else
    iSel = get(handles.listPlotFunc,'value');
    iMap = find(cellfun(@(x)(~strcmp(x(end),' ')),fcnStr));
    
    if (strContains(fcnStr{iSel},'#6E6E6E'))
        funcInd = [];
        funcIndT = -find(iMap == iSel); 
    else           
        [funcIndT,funcInd] = deal(find(iMap == iSel));
    end
end
    
if (isempty(funcInd)); funcInd = 0; end

% retrieves the experiment/function plot index
exptInd = get(handles.popupExptIndex,'value');
if (isempty(exptInd)); 
    exptInd = 0; 
elseif (plotInd == 3)
    exptInd = 1; 
end