% --- function that creates the subplot panels
function setupSubplotPanels(hPanel,sPara,fcnAxC,varargin)

% global variables
global newSz

% sets the default input arguments (if not provided)
if nargin == 2; fcnAxC = []; end

% retrieves the solution data struct
[hFig,uStr] = deal(get(hPanel,'parent'),get(hPanel,'Units'));
snTot = getappdata(hFig,'snTot');

% creates the axis objects
set(hPanel,'Units','Pixels');
hPos = get(hPanel,'position');
set(hPanel,'Units',uStr);

% other parameters
[R,pos] = deal(repmat([1 (1-2/hPos(4))],1,2),sPara.pos);

% creates the new subplot panels
setObjVisibility(hFig,'off'); pause(0.05)
for i = 1:size(pos,1)
    % creates the panel object
    pos(i,2) = 1 - sum(pos(i,[2 4]));
    if (nargin < 4)        
        hPnw = uipanel('parent',hPanel,'position',R.*pos(i,:),...
                       'tag','subPanel','UserData',i,'BackgroundColor',...
                       'w','BorderType','etchedin','ButtonDownFcn',fcnAxC);
    else
        %
        hPnw = findall(hPanel,'tag','subPanel','UserData',i);
    end
    
    % retrieves the panel dimensions (in pixels)
    set(hPnw,'Units','Pixels')        
    newSz = get(hPnw,'position');
    set(hPnw,'Units','Normalized')     
    
    % creates the axis object
    hAx = axes('outerposition',[0 0 1 1]);
    set(hAx,'parent',hPnw,'Units','Normalized','UserData',i,...
            'ButtonDownFcn',fcnAxC)            
    axis(hAx,'off');    
    
    % clears the axis and ensures it is off
    axes(hAx); cla(hAx); rotate3d(hAx,'off'); 
    setObjVisibility(hFig,'off'); pause(0.05)

    % determines if a valid subplot has been set 
    if (~isempty(sPara.plotD{i}))
        % if so, then retrieve the experiment/plot indices    
        [eInd,pInd] = deal(sPara.ind(i,1),sPara.ind(i,3));
        [pData,plotD] = deal(sPara.pData{i},sPara.plotD{i});

        % recreates the new plot
        if (pInd == 3)
            feval(pData.pFcn,snTot,pData,plotD);           
        else
            feval(pData.pFcn,reduceSolnAppPara(snTot(eInd)),pData,plotD);           
        end    
        
        % updates the text objects (from pixels to normalized)
        resetTextUnits(hPanel,i);        
    end
end
