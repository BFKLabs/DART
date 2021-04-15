% --- resets the recalculation object properties --- %
function resetRecalcObjProps(handles,state,hParaH)

% retrieves the analysis GUI handles
if (nargin == 2)
    hPara = getappdata(handles.figFlyAnalysis,'hPara');
    if (isempty(hPara)); return; end
    hParaH = guidata(hPara);
end

% updates the object properties based on the update type
if (strcmp(state,'Yes'))
    set(hParaH.textCalcReqd,'string','Yes','ForegroundColor','r');
    set(handles.buttonUpdateFigure,'BackgroundColor','r');
else
    set(hParaH.textCalcReqd,'string','No','ForegroundColor','k');
    set(handles.buttonUpdateFigure,'BackgroundColor',(240/255)*[1 1 1]);    
end