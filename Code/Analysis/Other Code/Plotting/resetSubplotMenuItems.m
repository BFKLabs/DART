% --- resets the Analysis GUI subplot menu items
function resetSubplotMenuItems(hFigM,hMenuSP,nReg,varargin)

% initialisations
nMenu = length(get(hMenuSP,'Children'));                
cbFcn = getappdata(hFigM,'menuSubPlot');                    
set(findall(hMenuSP,'Checked','on'),'Checked','off')

% determines if the correct number of menu items are set
if nMenu > nReg
    % if there are too many items, then remove them
    for i = nReg:-1:(nMenu+1)
        hMenuCR = findall(hMenuSP,'UserData',i);
        delete(hMenuCR);
    end

elseif nMenu < nReg
    % if there are too few menu items, then add them
    for i = (nMenu+1):nReg
        lStr = sprintf('Subplot #%i',i);
        uimenu(hMenuSP,'Label',lStr,'UserData',i,...
                       'Callback',cbFcn);                               
    end
end

% initialises the menu item details
if nargin == 4
    setappdata(hFigM,'sInd',1);
    set(findall(hMenuSP,'UserData',1),'Checked','on');
end