% --- plots the day/night time bands --- %
function hAx = plotDayNightGraph(hP,snTot,T,Y,ind,spInd,Tmlt)

% global variables
global tDay hDay    

% parameters and other arrays
TmltS2H = convertTime(1,'sec','hrs');
if (nargin < 7); Tmlt = TmltS2H; end
[ii,jj,fAlpha,del] = deal([1 1 2 2],[1 2 2 1],0.9,1e-5);
[yPlt,dT] = deal([del Y-del],diff(T([1 end])));

% sets the start/finish time of the expt
T0 = vec2sec([0 snTot.iExpt(1).Timing.T0(4:end)])*Tmlt;
TT = T0 + T;

% determines the times where the day/night transition occurs
TmltR = (Tmlt/TmltS2H);
indT = (tDay*TmltR):(hDay*TmltR):TT(end);
indT = indT(indT > TT(1));

% determines the proportional placement of the d/n transition markers
pT = [0+del,(indT-TT(1))/diff(TT([1 end])),1-del];
isD0 = (TT(1) >= tDay*TmltR) && (TT(1) < (tDay + hDay)*TmltR);   

% loops through all the subplot indices setting the day/night bands
hAx = cell(length(ind),1);
for j = 1:length(ind)
    % sets the subplot
    if (~isempty(spInd))
        if (length(spInd) == 2)
            hAx{j} = createSubPlotAxes(hP,[spInd(1),spInd(2)],j);
        else
            hAx{j} = subplot(spInd);       
        end
    else
        hAx{j} = getCurrentAxesProp;
    end

    % sets the axis properties
    hold(hAx{j},'on');
    set(hAx{j},'xlim',T([1 end]));
    
    % creates the day/night fill objects
    isD = ~isD0;
    for i = 1:(length(pT)-1)
        % sets the x-location of the transition points
        [xPlt,isD] = deal(T(1)+dT*pT(i+(0:1)),~isD);
        
        % creates the fill object depending on type
        if (isD)
            % case is a day phase
            fill(xPlt(ii),yPlt(jj),'y','facealpha',fAlpha,'tag','hDN');
        else
            % case is a night phase
            fill(xPlt(ii),yPlt(jj),'k','facealpha',0.5,'tag','hDN');
        end        
    end
end

% returns the object handle as a numerical value (rather than cell)
if ((nargout == 1) && (length(ind) == 1)); hAx = hAx{1}; end