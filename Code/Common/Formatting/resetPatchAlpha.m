% --- resets the patch colour
function resetPatchAlpha(hAx,indSel)

% global variables
global fColLo fColHi
[lWidLo,lWidHi] = deal(0.5,0.5);

% updates the old fill face-alpha to the low value (if not the currently
% selected fill region)
hFillOld = findobj(hAx,'tag','hFill','FaceAlpha',fColHi);
if (~isempty(hFillOld))
    if (get(hFillOld(1),'UserData') ~= indSel)
        % resets the old fill region to the low colour
        set(hFillOld,'FaceAlpha',fColLo,'LineWidth',lWidLo)    
    end
end
    
% sets the new region to the high face-alpha 
if (~isnan(indSel))
    hFillNew = findobj(hAx,'tag','hFill','UserData',indSel);
    set(hFillNew,'FaceAlpha',fColHi,'LineWidth',lWidHi)
end