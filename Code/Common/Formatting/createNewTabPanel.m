% --- wrapper function for creating a new tab
function hTab = createNewTabPanel(hParent,varargin)

% initialisations
if (~ischar(varargin{1}))
    [varargin,useTabPanel] = deal(varargin(2:end),false);
else
    useTabPanel = ~isHG1;
end

% creates the tab object
if (useTabPanel)    
    hTab = uix.Panel('Parent',hParent,'Padding',0);          
else
    hTab = createNewTab(hParent);
end

% determines if the input arguments are correct
if (mod(length(varargin),2) ~= 0)
    eStr = 'Error! Tab creation function inputs must come in pairs';
    waitfor(errordlg(eStr,'Incorrect Function Inputs','modal'))
else
    for i = 1:2:length(varargin)
        switch (lower(varargin{i}))
            case ('title')
                if (useTabPanel)
                    tTitles = get(hParent,'TabTitles');
                    tTitles{end} = varargin{i+1};
                    set(hParent,'TabTitles',tTitles)
                else
                    set(hTab,varargin{i},varargin{i+1})                    
                end
            otherwise
                set(hTab,varargin{i},varargin{i+1})
        end
    end
end

% refreshes the figure
pause(0.05); drawnow;