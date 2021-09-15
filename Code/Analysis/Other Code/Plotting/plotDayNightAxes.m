% --- plots the day/night time bands --- %
function plotDayNightAxes(snTot,T,Y,ind,spInd,varargin)

% global variables
global tDay hDay

% parameters and other arrays
fAlpha = 0.9;
if (numel(T) == 1)
    % if value is a scalar, then it is a time scale multiplier. 
    isDay = cell2mat(snTot.isDay');
else
    % reshapes the time array
%     T = linspace(T(1),T(end),ceil(T(end)/nanmedian(diff(T))));        
    T = linspace(T(1),T(end),length(T));    
    if (nargin == 5)
        if (~isempty(snTot))
            Tofs = convertTime(vec2sec([0 snTot.iExpt(1).Timing.T0(4:end)]),'sec','hrs');
        else
            Tofs = tDay;
        end
    else
        Tofs = tDay;
    end
        
    % determines which points are within the day time
    Tm = mod(T+Tofs,24);
    isDay = (Tm >= tDay) & (Tm <= (tDay+hDay));    
end   

% the overall day time indices
kGrpD = cell2mat(getGroupIndex(isDay));

% memory allocation
IDN = 0.5*ones(Y,length(isDay),3);
IDN(:,kGrpD,1:2) = fAlpha;
IDN(:,kGrpD,3) = 0;

% retrieves the current axes handle
hAx = getCurrentAxesProp;
    
% loops through all the subplot indices setting the day/night bands
for j = 1:length(ind)
    % sets the subplot
    if (~isempty(spInd))
        if (ishandle(spInd))
            subplot(spInd); hold on           
        else
            subplot(spInd(1),spInd(2),j); hold on                           
        end
    else
        hold on
    end

    % plot the day-time bands
    colormap(hAx,'jet');
    imagesc(IDN);   
    set(hAx,'box','on')    
end