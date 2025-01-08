% --- resets the recalculation object properties --- %
function resetRecalcObjProps(handles,state,objP)

if isfield(handles,'figFlyAnalysis')
    hFig = handles.figFlyAnalysis;
else
    hFig = objP.hFig;
end

% initialisations
sPara = getappdata(hFig,'sPara');

% retrieves the analysis GUI handles
if (nargin == 2)
    objP = getappdata(hFig,'objP');
    if isempty(objP); return; end
end

% if there is more than one sub-plot, then update the required check flag
% for the current sub-plot
if size(sPara.pos,1) > 1
    sInd = getappdata(hFig,'sInd');
    sPara.calcReqd(sInd) = true;
    setappdata(hFig,'sPara',sPara);
end

% updates the object properties based on the update type
if strcmp(state,'Yes')
    set(objP.textCalcReqd,'string','Yes','ForegroundColor','r');
    set(handles.buttonUpdateFigure,'BackgroundColor','r');
else
    set(objP.textCalcReqd,'string','No','ForegroundColor','k');
    set(handles.buttonUpdateFigure,'BackgroundColor',(240/255)*[1 1 1]);    
end