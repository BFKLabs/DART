% --- retrieves the java object handle from a tab group
function jTab = getTabGroupJavaObj(hTabGrp)

% removes the warnings
wState = warning('off','all');

% attempts to retrieves the table group java object
cType = 'MJTabbedPane';
jTab = findjobj(hTabGrp,'class',cType);

% if no match was made, then return all the java objects for search
if isempty(jTab)
    % retrieves all the java objects
    [~,~,~,~,handlesAll] = findjobj(hTabGrp);
    
    % retrieves the tabbed pane object
    objClass = arrayfun(@(x)(class(x)),handlesAll,'un',0)';
    jTab = handlesAll(strContains(objClass,cType));
end

% resets the warning state
warning(wState)