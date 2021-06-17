% --- formats the x/y labels for a multi-plot figure
function hAx = formatMultiXYLabels(hAx,pF,dim)

% converts the axis cell array to a numerical array
if (~iscell(hAx))
    if (length(hAx) == 1)
        hAx = {hAx}; 
    else
        hAx = num2cell(hAx);
    end
else
    hAx = hAx(:);    
end

% sets the row/column sizes
[m,n,dx,dy,dz] = deal(dim(1),dim(2),0,0,0);
[ix,iy,iz] = deal((m-1)*n + [1 n],[(m-1)*n+1 1],[m*n n]);

% sets the axis handles into a single cell array
nAx = sum(~cellfun(@isempty,hAx));
if (any(cellfun(@length,hAx) > 1))
    hAx = num2cell(cell2cell(hAx));
end

% sets the plot label indices
hP = get(hAx{1},'parent');
[pF(1).xLabel.ind,pF(1).yLabel.ind,pF(2).zLabel.ind] = deal(ix(1),iy(2),iz(2));  

%
if (any(ix > nAx))   
    % 
    n0 = size(hAx,1);
    hAx = [hAx;cell(m*n-size(hAx,1),size(hAx,2))];
    
    for i = (n0+1):(m*n)
        for j = 1:size(hAx,2)
            hAx{i,j} = axes('OuterPosition',calcOuterPos(m,n,i),'Parent',hP);        
            set(hAx{i,j},'UserData',i);
            axis(hAx{i,j},'off')
        end
    end

    % formats the plot axis
    [pF(1).Title(1).String,ipF] = deal('',1);
else
    % formats the plot axis
    ipF = ix(1);
end

% converts the postion arrays (based on the axis units)
pPos = getPanelPosPix(hP);
if (strcmpi(get(hAx{1,1},'units'),'pixels'))
    % case is units are in pixels
    cellfun(@(x)(set(x,'Units','Pixels')),hAx)
    p0 = 1;    
else
    % case is units are normalized
    cellfun(@(x)(set(x,'Units','Normalized')),hAx)
    [p0,pPos] = deal(max(1./pPos(3:4)),[1 1 1 1]);
end
  
% retrieves the axis postion vectors
axPos = cellfun(@(x)(get(x,'position')),hAx,'un',0);
axPos = reshape(axPos(:,1),size(hAx,1),1);

% retrieves the x/y-axis labels
pF(1).yLabel.Font.Color = get(hAx{1,1},'ycolor');
pF(1).xLabel.Font.Color = get(hAx{1,1},'xcolor');

% removes the title/legend fields
pF = rmfield(pF,{'Title','Legend'});   

% creates the x-axis label (if string is not empty)
if (~isempty(pF(1).xLabel.String))    
    % creates the actual x-axis label
    pX = [axPos{ix(1)}(1),sum(axPos{ix(2)}([1 3]))];
    hDimX = createLabelAxes(hP,pF,[pX(1),p0,diff(pX),p0]/pPos(3),'xLabel');    
    dy = hDimX(2);
    delete(get(hAx{ix(1),1},'xlabel'));
end

% creates the y-axis label (if string is not empty)
if (~isempty(pF(1).yLabel.String))
    % creates the actual y-axis label
    pY = [axPos{iy(1)}(2),sum(axPos{iy(2)}([2 4]))];
    hDimY = createLabelAxes(hP,pF,[p0,pY(1),p0,diff(pY)]/pPos(4),'yLabel');
    dx = hDimY(1);
    delete(get(hAx{iy(2),1},'ylabel'));
end

% creates the z-axis label (if string is not empty)
if ((~isempty(pF(1).zLabel.String)) && (size(hAx,2) == 2))
    % updates the axis colour    
    pF(1).zLabel.Font.Color = get(hAx{1,2},'ycolor');
    
    % creates the actual y-axis label
    pZ = [axPos{iz(1)}(2),sum(axPos{iz(2)}([2 4]))];
    hDimZ = createLabelAxes(hP,pF,[1-p0,pZ(1),p0,diff(pZ)]/pPos(4),'zLabel');    
    dz = hDimZ(1);
    delete(get(hAx{iz(1),2},'ylabel'));
end

% ensures the axes cell array is the correct size
if (numel(hAx) < prod(dim))
    hAx = [hAx(:);cell(prod(dim)-numel(hAx),1)];
end

% resets the outer positions of the sub-plots to incorporate the new axis
% labels strings
for k = 1:size(hAx,2)
    hAxT = reshape(hAx(:,k),dim(2),dim(1))';
    [Wnw,Hnw] = deal((1-(dx+dz))/dim(2),(1-dy)/dim(1));            
    for i = 1:dim(1)
        for j = 1:dim(2)
            if (~isempty(hAxT{i,j}))
                axUnits = get(hAxT{i,j},'Units');
                set(hAxT{i,j},'Units','Normalized');
                
                Pnw = [dx+(j-1)*Wnw,dy+(dim(1)-i)*Hnw,Wnw,Hnw];
                set(hAxT{i,j},'OuterPosition',Pnw,'Units',axUnits)
            end
        end
    end
end
    
% --- creates the label axes
function hTextD = createLabelAxes(hP,pF,axPos,lStr)

% initialisations
pFF = eval(sprintf('pF.%s',lStr));
switch (lower(lStr))
    case ('xlabel') % case is the x-label
        [X,Y,angle,dim,mlt] = deal(0.5,0.0,0,2,1.40);
    case ('ylabel') % case is the y-label
        [X,Y,angle,dim,mlt] = deal(0.0,0.5,90,1,1.00);
    case ('zlabel') % case is the y-label        
        [X,Y,angle,dim,mlt] = deal(0.0,0.5,90,1,-1.1);        
end

% creates the label axis object
hAx = axes('position',axPos,'parent',hP,'xticklabel',[],'xtick',[],...
           'yticklabel',[],'ytick',[],'xlim',[0 1],'ylim',[0 1],...
           'tag',lStr,'xcolor','w','ycolor','w','color','none',...
           'TickLength',[0.001 0.001]);
       
% creates the text label       
hText = text(X,Y,pFF.String,'Parent',hAx,'rotation',angle,...
                            'horizontalalignment','center');       
       
% updates the font properties       
updateFontProps(hText,pFF.Font,1,lStr);

% retrieves t
[tPos,tExt] = deal(get(hText,'position'),get(hText,'extent'));
tPos(dim) = tExt(dim) + mlt*tExt(dim+2);
set(hText,'position',tPos)

% updates the text object so that it is now in terms of pixels
set(hText,'Units','Normalized')

%
hExt = get(hText,'Extent');
hTextD = hExt(3:4).*axPos(3:4);