% --- retrieves the panel position (in tems of pixels)
function pPos = getPanelPosPix(hPanel,uStrNw,pType)

% sets the input arguments
if (nargin < 2); uStrNw = 'Pixels'; end
if (nargin < 3); pType = 'Position'; end

% sets the panel object (if there is more than one)
if (length(hPanel) > 1)
    if (iscell(hPanel))
        hPanel = hPanel{1};
    else
        hPanel = hPanel(1);
    end
end

% sets the panel units to pixels
uStr = get(hPanel,'Units');
set(hPanel,'Units',uStrNw)

% retrieves the panel position and resets the units back to original
pPos = get(hPanel,pType);
set(hPanel,'Units',uStr)