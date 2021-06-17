% --- updates the tab group properties (based on that of the parameter
%     enabled properties within the tab)
function updateTabEnabledProps(hObj)

% if not objects, then return
if (isempty(hObj)); return; end

% sets the tab panel object handle based on the graphics type
if (isa(hObj,'uix.TabPanel') || isa(hObj,'matlab.ui.container.TabGroup') || ...
    strcmp(get(hObj,'type'),'uitabgroup'))
    % object handle is a tab panel
    hTabG = hObj;
else
    % object handle is not a tab panel
    hTabG = get(get(hObj,'Parent'),'Parent');
end

% initialisations
hTab = get(hTabG,'Children');
if ~iscell(hTab); hTab = num2cell(hTab); end

% retrieves the table java object
jTabG = getappdata(hTabG,'UserData');       
if isempty(jTabG)
    % if it doesn't exist, then retrieve it
    jH = findjobj(hTabG);
    jTabG = jH(cellfun(@(x)(isa(x,['javahandle_withcallbacks.',...
                'com.mathworks.mwswing.MJTabbedPane'])),num2cell(jH)));
    setappdata(hTabG,'UserData',jTabG)
end

% checks all of the tabs in the tab group
for i = 1:length(hTab)
    % disables a tab if all objects are disabled
    hChild = get(hTab{i},'Children');
    if (~isempty(hChild)) && (~isempty(jTabG))
        isEnable = any(strcmp(get(hChild,'enable'),'on'));              
        try
            jTabG.setEnabledAt(get(hTab{i},'UserData')-1,isEnable)        
        catch ME
            if (~strcmp(ME.identifier,'MATLAB:Java:GenericException'))
                rethrow(ME)
            end
        end
    end
end