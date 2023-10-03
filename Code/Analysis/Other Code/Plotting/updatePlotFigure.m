% --- updates the analysis plot figure --- %
function varargout = updatePlotFigure(objH,pDataNw,varargin)

% initialisations
varargout{1} = [];
switch length(varargin)
    case (0)
        [iPlot,isShowGUIs,isOutput] = deal([],true,false);
    otherwise
        [iPlot,isShowGUIs,isOutput] = deal(varargin{1},false,true);
end

% field retrieval
hFigM = findall(0,'tag','figFlyAnalysis');
pImg = getappdata(hFigM,'pImg'); 
sPara = getappdata(hFigM,'sPara');
snTot = getappdata(hFigM,'snTot');
hPara = getappdata(hFigM,'hPara'); 
hGUI = guidata(hFigM);

% retrieves the subplot data struct
if isOutput
    % retrieves the 
    plotDNw = objH.plotD;
    
else
    % retrieves the main gui handles
    plotD0 = getappdata(hFigM,'plotD');            
end

% ensures the parameter GUI is invisible
setObjVisibility(hPara,'off'); pause(0.05);

% retrieves the data based on the 
nReg = size(sPara.pos,1);
if nReg == 1
    % retrieves the currently selected plot data
    [eInd,fInd,pInd] = getSelectedIndices(hGUI);
    if ~isOutput
        plotDNw = plotD0{pInd}{fInd,eInd};
    end
else
    % if multiple subplots, determine which subplots are valid
    sInd = getappdata(hFigM,'sInd');    
    [eInd,pInd] = deal(sPara.ind(sInd,1),sPara.ind(sInd,3));    
    
    % sets the plot data struct (if not outputting)
    if ~isOutput; plotDNw = sPara.plotD{sInd}; end
end        

% if there is no plot data, then exit the function
if isempty(plotDNw)
    % makes the parameter GUI visible again (if showing)
    if isShowGUIs; setObjVisibility(hPara,'on'); end
    
    % exits the function
    return; 
end
        
% sets the data for plotting
if (pInd == 3)
    snTotNw = snTot;
else
    snTotNw = reduceSolnAppPara(snTot(eInd));
end    

% sets the plot axes (based on the number of input arguments)
if isOutput
    % case is for figure output
    hFigAx = objH.hFig;
    hPanelAx = objH.hPanelAx;    
        
    % expands the figure and deletes the axis
    set(0,'CurrentFigure',hFigAx)
    set(hFigAx,'CurrentAxes',objH.setupPlotAxes());
    
    % resets the units of the panel
    if nReg == 1     
        % rescales the font sizes
        fPos = get(hFigAx,'position');
        pPos = getPanelPosPix(hPanelAx);
        pDataNw.pF = rescaleFontSize(pDataNw.pF,fPos(3)/pPos(3));             
        
        % clears the main GUI axis and re-plots the figure    
        if ~isempty(iPlot)
            pDataNw = feval(pDataNw.pFcn,snTotNw,pDataNw,plotDNw,iPlot);            
        else
            pDataNw = feval(pDataNw.pFcn,snTotNw,pDataNw,plotDNw);            
        end            
    else
        % sets up the subplot panels        
        setupSubplotPanels(hPanelAx,sPara)         
    end           
else
    % case is for creating an analysis figure  
    initAxesObject = getappdata(hFigM,'initAxesObject');
    initAxesObject(hGUI);            
    
    % clears the main GUI axis and re-plots the figure    
    if ~isempty(iPlot)
        pDataNw = feval(pDataNw.pFcn,snTotNw,pDataNw,plotDNw,iPlot);            
    else
        pDataNw = feval(pDataNw.pFcn,snTotNw,pDataNw,plotDNw);            
    end     
    
    % updates the plot image
    pause(0.05);
    hPanel = findall(hFigM,'tag','panelPlot');
    pImg{pInd}{fInd,eInd} = screencapture(hPanel);
    setappdata(hFigM,'pImg',pImg);
end

% redisplays the parameter GUI (is displaying the GUI output)
pause(0.05);
if isShowGUIs
    setObjVisibility(hPara,'on'); 
end

% if not outputting the figure, but a function output is required, then
% return the plot data struct
if ~isOutput && (nargout == 1)
    varargout{1} = pDataNw;
end