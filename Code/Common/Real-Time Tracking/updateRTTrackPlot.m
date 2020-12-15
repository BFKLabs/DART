% --- updates the real-time tracking plot
function updateRTTrackPlot(h,rtD,gType)

% global variables
global TlimRT

% limits for the plot domain
nGrp = size(rtD.rtP.combG.iGrp,1);
isC2A = getappdata(h,'isC2A');
isC2T = getappdata(h,'isC2T');

% updates the fly locations
[hh,iEnd] = deal(guidata(h),find(~isnan(rtD.T),1,'last'));
if (rtD.T(iEnd) > TlimRT)
    % determines the new plot vector
    tLim = (rtD.T(iEnd) - TlimRT);
    [iPlot,isLim] = deal(rtD.T >= tLim,true);
    xPlot = rtD.T(iPlot) - tLim;
    
    % determines the first negative time index
    iiNeg = find(iPlot,1,'first') - 1;
    if (iiNeg > 0)
        % if there is such a time index, then reset the plot vector
        [xPlot,jjNeg] = deal([0;xPlot],iiNeg+(0:1));
    end
else
    [iPlot,isLim] = deal(~isnan(rtD.T),false);
    xPlot = rtD.T(iPlot);
end

% determines if there are any previous stimulus markers
if (isC2A || isC2T)
    hStim = findobj(hh.axesProgress,'tag','hStimMark');
    if (~isempty(hStim) && isLim)
        % if so, then shift the marker to the left
        for i = 1:length(hStim)            
            xData = get(hStim(i),'xData');
            xDataNw = xData(1)-diff(xPlot(end-1:end));            
            if (xDataNw < 0)
                delete(hStim(i));
            else
                set(hStim(i),'xdata',xDataNw*[1 1]);
            end
        end
    end
end
   
% updates the plot values
for iApp = 1:nGrp
    % -------------------------------- %
    % --- METRIC PLOT TRACE UPDATE --- %
    % -------------------------------- %
    
    % retrieves the plot handle and the new plot data
    hPlot = findobj(hh.axesProgress,'UserData',iApp,'Type','Line');
    switch (gType)
        case ('menuAvgVel') % case is average velocity
            Y = rtD.VP(:,iApp);            
        case ('menuPropInact') % case is inactive proportion
            Y = 100*rtD.pInact(:,iApp);
        case ('menuMeanInact') % case is mean inactive duration
            Y = rtD.muInactT(:,iApp);
    end
    
    % updates the fly trace
    yPlot = Y(iPlot);
    if (isLim)
        if (iiNeg > 0)
            yPlotInt = interp1(rtD.T(jjNeg)-tLim,Y(jjNeg),0,'linear');
            yPlot = [yPlotInt;yPlot];
        end        
    end
    
    % updates the fly trace
    set(hPlot,'xdata',xPlot,'ydata',yPlot)    
    
    % -------------------------------------- %
    % --- STIMULI MARKER LOCATION UPDATE --- %
    % -------------------------------------- %        
        
%     % adds a stimuli marker to the plot (if a new one is required)
%     if (isShock(iApp))
%         % adds the stimulus time
%         if (isempty(xPlot))
%             tStim = 0;
%         else
%             tStim = xPlot(end);
%         end
%         
%         % adds the stimulus marker
%         hold(hh.axesProgress,'on')
%         plot(hh.axesProgress,tStim*[1 1],get(hh.axesProgress,'ylim'),...
%                 'tag','hStimMark','color',colSetTabColour(iApp),...
%                 'linestyle','--');        
%         hold(hh.axesProgress,'off')
%     end
end

% updates the figure
drawnow;