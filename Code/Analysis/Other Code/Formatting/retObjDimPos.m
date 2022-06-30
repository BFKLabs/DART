% retrieves the widths of all the objects in the cell array hObj --- %
function wObj = retObjDimPos(hObj,ind,varargin)

if isempty(hObj)
    wObj = {};
else
    % converts the object array to a cell array (if not already)
    if ~iscell(hObj); hObj = num2cell(hObj); end
    
    hasObj = ~cellfun(@isempty,hObj);    
    if ~any(hasObj)
        wObj = {};
    else
        wObj = num2cell(NaN(size(hObj)));        
        for i = 1:length(hObj)
            if ~hasObj(i)
                
            elseif ~isempty(hObj{i})
                try
                    wObj{i} = cellfun(@(y)(y(ind)),cellfun(@(x)(...
                            get(x,'Position')),hObj{i},'un',0));
                catch
                    wObj{i} = cellfun(@(y)(y(ind)),arrayfun(@(x)(...
                            get(x,'Position')),hObj{i},'un',0));                
                end
            end
        end
    end
    
    if (nargin == 3); wObj = cell2mat(wObj); end
end