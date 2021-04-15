% --- resets the axes positions such that they are all equal in dimension
function resetAxesPos(hAx,m,n,dOfs)

% sets the default input arguments
if (nargin < 4); dOfs = [0 0.02*(m*n == 1)]; end

% converts the axes handles into a cell array
if (~iscell(hAx))
    if (length(hAx) == 1)
        hAx = {hAx}; 
    else
        hAx = num2cell(hAx);
    end
end

% retrieves the position of the axes
cellfun(@(x)(set(x,'Units','normalized')),hAx);
cellfun(@(x)(set(get(x(1),'Title'),'Units','Normalized')),hAx)

% sets the overall original height/width of the subplots
[xGap,yGap,dWmin] = deal(0.015,0.01,0.005);
axPosO = cell2mat(cellfun(@(x)(get(x(1),'OuterPosition')),hAx,'un',0));
[W,H,dX] = deal(n*axPosO(1,3),m*axPosO(1,4),min(axPosO(:,1)));
nAx = length(hAx{1});

% ensures the axis array is the correct size
if (numel(hAx) ~= m*n)
    hAx = [hAx(:);cell(m*n-numel(hAx),1)];
end

%
if (numel(hAx) == m*n)
    hAx = reshape(hAx,n,m)';
end

% ensures the axis handles are stored in a numerical array
hDim = cell(m,n);
for i = 1:m
    for j = 1:n       
        if (~isHG1); pause(0.05); end
        hDim{i,j} = getPlotObjTextHeight(hAx{i,j}); 
        
        if (length(hAx{i,j}) == 2)
            hTitle = findall(hAx{i,j}(2),'tag','Title');
            if (~isempty(hTitle)); delete(hTitle); end
        end
    end
end

% retrieves the axes object column widths/row heights
hDim = cell2mat(hDim);
WD = cellfun(@(x)(calcAxesObjDim(x,1)),num2cell(hDim,1),'un',0);
HD = cellfun(@(x)(calcAxesObjDim(x,2)),num2cell(hDim,2),'un',0);

% recalculates the new axes width/height
[WDmx,HDmx] = deal(sum(cellfun(@sum,WD)),sum(cellfun(@sum,HD)));
dW = (W - (WDmx + (n+2+(nAx==2))*xGap + dOfs(1)))/n;
dH = (H - (HDmx + (m+2)*yGap + dOfs(2)))/m;
         
% calculates the new widths/heights
[Lnw,Bnw] = deal(zeros(size(hAx)));

% sets the left position of the axes regions
L0 = dX + 2*xGap;
for i = 1:n
    Lnw(:,i) = L0 + sum(WD{i}([1 2]));
    L0 = (L0 + xGap) + sum(WD{i}) + dW;
end

% sets the bottom position of the axes regions
H0 = max(sum(axPosO(:,[2 4]),2)) - (yGap + dOfs(2));
for i = 1:m
    Bnw(i,:) = H0 - (HD{i}(3) + dH);
    H0 = H0 - (sum(HD{i}) + dH + yGap);
end

% resets the axes positions
for i = 1:m
    for j = 1:n        
        if (~isempty(hAx{i,j}))
            set(hAx{i,j},'position',[Lnw(i,j) Bnw(i,j) dW dH])
        end
    end
end

% optimises the title placements
hAxT = cellfun(@(x)(x(1)),hAx(~cellfun(@isempty,hAx)),'un',0);
optTitlePlacement(hAxT,'Title')

% %
% [pStr,pOfs] = deal({'yLabel','xLabel'},[3 1]);
% for i = 1:2
%     if (~isempty(hAxL{i}))
%         % retrieves the label object
%         lObjF = findall(hAxL{i},'type','text','tag',pStr{i});
%         lObj0 = get(hAx{iAxL(i)},pStr{i});
%                 
%         % retrieves the position and limits of the figure
%         axPos = getPanelPosPix(hAx{iAxL(i)},'pixels');
%         lExt0 = getPanelPosPix(lObj0,'pixels','extent');
%                 
%         % resets the location of the label               
%         set(lObjF,'Units','Pixels');                
%         hPosF = get(lObjF,'position');
%         hPosF(i) = axPos(i)+lExt0(i)+lExt0(i+2)/2 - pOfs(i);
%         set(lObjF,'position',hPosF,'Units','Normalized');
%     end
% end

% retrieves the x-tick mode
hAx0 = hAx{1}(1);

% initialisations    
axP = cell2mat(cellfun(@(x)(get(x(1),'position')),hAx(1,:)','un',0));
pX = cellfun(@(x)(get(x(1),'xtick')/max(get(x(1),'xlim'))),hAx(1,:),'un',0);
pX = cellfun(@(x)(x((x >= 0) & (x <= 1))),pX,'un',0);    
if (all(cellfun(@isempty,pX))); return; end

% determines the overall maximum x-axis label width
[txtX,fSz] = deal(get(hAx0,'xticklabel'),get(hAx0,'fontsize'));
if (isempty(txtX))
    return
elseif (~iscell(txtX))
    txtX = num2cell(txtX,2); 
end

% creates a dummy text object and retrieves the new width
hT0 = text(0,0,txtX{1},'FontUnits','Pixel','FontSize',fSz,...
          'FontWeight','bold','Parent',hAx0,'Units','Normalized');
hT1 = text(0,0,txtX{end},'FontUnits','Pixel','FontSize',fSz,...
          'FontWeight','bold','Parent',hAx0,'Units','Normalized');          
[hExt0,hExt1] = deal(get(hT0,'extent'),get(hT1,'extent'));
delete(hT0); delete(hT1);           

% sets the left/right extents of the x-axis label strings
[L,R] = deal(1e10*ones(1,n),zeros(1,n));
for j = 1:n
    L(j) = (pX{j}(1)-hExt0(3)/2)*axP(j,3)+axP(j,1);
    R(j) = (pX{j}(end)+hExt1(3)/2)*axP(j,3)+axP(j,1);        
end

% determines if there is any overlap (with other labels or with the
% right edge of the axes)
if (n == 1)
    % only one column, so check the right edge
    dLR = (1-R(end)) - dWmin;
else
    % more than one column, so check both
    dLR = min(L(2:end) - R(1:(end-1)),1-R(end)) - dWmin;
end

% determines if any of the axis labels overlap    
if (any(dLR < 0))
    % if they do, then shrink the axis so they no longer overlap
    cellfun(@(x)(resetObjPos(x,'width',min(dLR),1)),hAx)
end

% --- calculates the axes objects dimensions (depending on type)
function D = calcAxesObjDim(p,Type)

%
pStr = {{'yLH','yAxW','zLH','zAxH'},{'xLH','xAxH','TH'}};
Y = cellfun(@(x)(field2cell(p,x,1)),pStr{Type},'un',0);
D = max(cell2mat(cellfun(@(x)(x(:)),Y,'un',0)),[],1);
