% --- updates the analysis plot figure --- %
function varargout = updatePlotFigure(hGUISub,pDataNw,varargin)

% global variables
global isDocked
[varargout{1},isHG2] = deal([],~verLessThan('matlab','8.4'));
switch (length(varargin))
    case (0)
        [iPlot,isShowGUIs,isOutput] = deal([],true,false);
    otherwise
        [iPlot,isShowGUIs,isOutput] = deal(varargin{2},false,true);
end

% retrieves the Analysis GUI handles and the current plot
if (isfield(hGUISub,'figFlyAnalysis'))
    hGUI = hGUISub;
else
    hGUI = getappdata(hGUISub,'hGUI');    
end

% % creates the load bar (for HG2 graphics only)
% if ((isShowGUIs) && (isHG2))
%     hL = ProgressLoadbar('Initialising Analysis GUI...');
% end

% retrieves the subplot data struct
plotD = getappdata(hGUI.figFlyAnalysis,'plotD');
sPara = getappdata(hGUI.figFlyAnalysis,'sPara');
hPara = getappdata(hGUI.figFlyAnalysis,'hPara');  
nReg = size(sPara.pos,1);

% ensures the parameter GUI is invisible
setObjVisibility(hPara,'off'); pause(0.05);

% retrieves the data based on the 
if nReg == 1
    % retrieves the currently selected plot data
    [eInd,fInd,pInd] = getSelectedIndices(hGUI);
    plotDNw = plotD{pInd}{fInd,eInd};
else
    % if multiple subplots, determine which subplots are valid
    sInd = getappdata(hGUI.figFlyAnalysis,'sInd');    
    plotDNw = sPara.plotD{sInd};
    [eInd,pInd] = deal(sPara.ind(sInd,1),sPara.ind(sInd,3));    
end    

% if there is no plot data, then exit the function
if isempty(plotDNw)
    % makes the parameter GUI visible again (if showing)
    if isShowGUIs; setObjVisibility(hPara,'on'); end
%     try; delete(hL); end
    
    % exits the function
    return; 
end
    
% retrieves the axis update function and other struct/indices        
snTot = getappdata(hGUI.figFlyAnalysis,'snTot'); 
    
% sets the data for plotting
if (pInd == 3)
    snTotNw = snTot;
else
    snTotNw = reduceSolnAppPara(snTot(eInd));
end    

% retrieves the plot panel handle
if (isDocked)
    hPanel = hGUI.panelPlot;
else
    hUndock = guidata(getappdata(hGUI.figFlyAnalysis,'hUndock'));
    hPanel = hUndock.panelPlot;    
end

% sets the plot axes (based on the number of input arguments)
if (isOutput)
    % case is for figure output
    [fig,varargout{1}] = deal(figure('visible','off','units','pixels'));   

    % retrieves the 
    pPos = getPanelPosPix(hPanel);

    % expands the figure and deletes the axis
    expandFig(fig,pPos);
    delete(gca)    
    
    % resets the units of the panel
    if (nReg == 1)       
        % rescales the font sizes
        fPos = get(fig,'position');
        pDataNw.pF = rescaleFontSize(pDataNw.pF,fPos(3)/pPos(3));             
        
        % clears the main GUI axis and re-plots the figure    
        if (~isempty(iPlot))
            pDataNw = feval(pDataNw.pFcn,snTotNw,pDataNw,plotDNw,iPlot);            
        else
            pDataNw = feval(pDataNw.pFcn,snTotNw,pDataNw,plotDNw);            
        end            
    else
        % sets up the subplot panels
        setupSubplotPanels(hPanel,sPara)         
    end           
else
    % case is for creating an analysis figure  
    initAxesObject = getappdata(hGUI.figFlyAnalysis,'initAxesObject');
    initAxesObject(hGUI);            
    
    % clears the main GUI axis and re-plots the figure    
    if (~isempty(iPlot))
        pDataNw = feval(pDataNw.pFcn,snTotNw,pDataNw,plotDNw,iPlot);            
    else
        pDataNw = feval(pDataNw.pFcn,snTotNw,pDataNw,plotDNw);            
    end        
end

% redisplays the parameter GUI (is displaying the GUI output)
pause(0.05);
if isShowGUIs
    setObjVisibility(hPara,'on'); 
%     try; delete(hL); end
end

% if not outputting the figure, but a function output is required, then
% return the plot data struct
if (~isOutput) && (nargout == 1)
    varargout{1} = pDataNw;
end