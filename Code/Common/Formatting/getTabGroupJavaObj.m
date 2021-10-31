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
    
    %
    if length(jTab) > 1
        % calculates the tab object aspect ratio
        jTabAR = zeros(length(jTab),1);
        for i = 1:length(jTab)
            jTabAR(i) = get(jTab(i),'Width')/get(jTab(i),'Height');
        end
        
        % retrieves the object which is most like the tab group object 
        hPos = get(hTabGrp,'Position');
        jTab = jTab(argMin(abs(jTabAR - hPos(3)/hPos(4))));      
    end
end

% resets the warning state
warning(wState)