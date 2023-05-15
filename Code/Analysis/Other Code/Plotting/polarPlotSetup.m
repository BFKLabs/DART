% --- creates the polar plot (either half or full polar plot)
function polarPlotSetup(hAx,pF,isFull,dr,fullAngle)

% sets the angle offset
if (nargin < 4); dr = 0.05; end

% initialisations
fSz = pF.Axis.Font.FontSize;
[nC,nL,rTX,rTY] = deal(1000,6*(isFull+1)+1,1+2*dr,1+dr);
[phiC,phiL] = deal(linspace(0,(1+isFull)*pi,nC),linspace(0,(1+isFull)*pi,nL));
[xL,yL,xC,yC] = deal(cos(phiL),sin(phiL),cos(phiC),sin(phiC));

% retrieves the background colour
hP = get(hAx,'Parent');
if (strcmp(get(hP,'Type'),'uipanel'))
    bgCol = get(hP,'backgroundcolor');
else
    bgCol = get(hP,'color');    
end

% sets up the parent object and axis colors
set(hAx,'box','off','color','none','xcolor',bgCol,'ycolor',bgCol,...
        'tag','hPolar','HitTest','off');
    
% turns the hold on and sets the axis to equal aspect ratio    
hold(hAx,'on');

% creates the circle patch 
patch(xC,yC,'w','HitTest','off');

% plots the radial markers and text labels
rCol = 0.5*ones(1,3);
hText = zeros((length(xL)-isFull),1);
for i = 1:(length(xL)-isFull)
    % creates the radial marker
    plot(hAx,[0,xL(i)],[0,yL(i)],':','linewidth',0.5,...
                                 'color',rCol,'HitTest','off')
    
    % sets the text label string based on the type    
    phiNw = roundP(deg2bear(phiL(i)));
    if isFull
        % 
        if (nargin < 5); fullAngle = true; end
        
        % sets the full polar plot angle string
        if ~fullAngle && (phiNw > 180)
            % case is not using full angle (and 
            tStr = num2str(phiNw-360);
        else
            % 
            tStr = num2str(phiNw);            
        end
    else
        % case is the half polar plot
        if phiNw > 180
            % case is for negative angles
            tStr = num2str(phiNw-360);
        else
            % case is for positive angles
            tStr = num2str(phiNw);
        end
    end
        
    % creates the text label
    hText(i) = text(rTX*xL(i),rTY*yL(i),tStr);
    set(hText(i),'fontsize',fSz,'fontweight','bold','HorizontalAlignment', 'center');        
end

% determines the x-axis limits from the text object positions
tPos = cell2mat(get(hText,'extent'));
xLim = max(abs(min(tPos(:,1))),max(sum(tPos(:,[1 3]),2)))*[-1 1];

% sets the y-axis limits
if isFull
    % case is for a full circle
    yLim = max(abs(min(tPos(:,2))),max(sum(tPos(:,[2 4]),2)))*[-1 1];
else
    % case is for a half-circle
    yLim = [0 max(sum(tPos(:,[2 4]),2))];
end

% sets the axis limits
set(hAx,'xlim',xLim,'yLim',yLim)