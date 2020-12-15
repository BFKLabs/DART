% --- resets the position of the object, hObj, by resets the dimension
%     given by dim to the value, nwVal
function resetObjPos(hObj,dim,nwVal,varargin)

% denotes whether the object is being added to the GUI
isAdd = (nargin==4);
if (~iscell(hObj)); hObj = num2cell(hObj); end

% retrieves the position of the handle
for i = 1:length(hObj)
    hPos = get(hObj{i},'position');

    % resets the position location to the value, nwVal
    switch (lower(dim))
        case ('left') % case is resetting the left location
            if (isAdd)
                set(hObj{i},'position',[(hPos(1)+nwVal) hPos(2:end)]);        
            else
                set(hObj{i},'position',[nwVal hPos(2:end)]);                    
            end
        case ('bottom') % case is resetting the bottom location
            if (isAdd)
                set(hObj{i},'position',[hPos(1) (hPos(2)+nwVal) hPos(3:end)]);        
            else
                set(hObj{i},'position',[hPos(1) nwVal hPos(3:end)]);                    
            end            
        case ('width') % case is resetting the width dimension
            if (isAdd)
                set(hObj{i},'position',[hPos(1:2) (hPos(3)+nwVal) hPos(4)]);        
            else
                set(hObj{i},'position',[hPos(1:2) nwVal hPos(4)]);                    
            end            
        case ('height') % case is resetting the height dimension
            if (isAdd)
                set(hObj{i},'position',[hPos(1:3) (nwVal+hPos(4))]);                    
            else
                set(hObj{i},'position',[hPos(1:3) nwVal]);                    
            end            
    end
end