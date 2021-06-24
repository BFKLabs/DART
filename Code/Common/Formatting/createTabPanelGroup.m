function hTabG = createTabPanelGroup(hParent,varargin)

if nargin == 2
    hTabG = createTabGroup();
    set(hTabG,'Parent',hParent,'Units','pixels');     
else
    hTabG = uix.TabPanel('Parent',hParent,'Padding',5,'Units','pixels',...
                         'BackgroundColor',0.8*[1 1 1]);
end