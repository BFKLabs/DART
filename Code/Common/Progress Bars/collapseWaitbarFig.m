% --- collapses nRow rows from a waitbar figure --- %
function h = collapseWaitbarFig(h,nRow,varargin)

% retrieves the objects from the waitbar figure
try
    hObj = getappdata(h,'hObj');
catch
    % if there was an error, then exit
    h = []; return
end

% makes the gui visible again
setObjVisibility(h,'on')
pause(0.05);

% retrieves all the objects from the 
[dY,fNames] = deal(50,{'wStr','wAxes','wImg'});

% sets the indices
[nObj,mlt] = deal(length(hObj),1-2*(nargin==2));

% resets the figure/panel heights
% set(h,'visible','off');
resetObjPos(findobj(h,'type','uipanel'),'height',mlt*dY*nRow,1)
resetObjPos(h,'height',mlt*dY*nRow,1)    

% determines the number of rows in the new waitbar figure
hPos = get(findobj(h,'type','uipanel'),'Position');
hRow = roundP((hPos(4) - 10)/dY);

% resets the locations of all the sub-units
for i = 1:nObj        
    % retrieves the new object handles for the current row
    A = cellfun(@(x)(sprintf('hObj(i).%s',x)),fNames,'un',0);
    hObjNw = cellfun(@eval,A,'un',0);    
    
    % sets the properties based on the new values
    resetObjPos(hObjNw(1:2),'bottom',mlt*dY*nRow,1)
    if (i <= hRow)     
        cellfun(@(x)(set(x,'visible','on')),hObjNw)        
    else
        cellfun(@(x)(set(x,'visible','off')),hObjNw)
    end
end

% makes the waitbar figure visible again
setObjVisibility(h,'on')
pause(0.05);