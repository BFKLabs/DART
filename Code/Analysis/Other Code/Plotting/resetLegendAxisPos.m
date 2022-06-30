% --- resets the position of the legend/subplot axes
function resetLegendAxisPos(hAxB,hLg,dim,dW,wLg)

% ensures the axis handles are stored in a cell array
if ~iscell(hAxB); hAxB = {hAxB}; end
if (nargin < 3); dim = [1 1]; end
if (nargin < 4); dW = 0; end

%
pause(0.05);
drawnow;

% resets the width of the vertical legend
lgP = resetVertLegendWidth(hLg);
axP = cell2mat(cellfun(@(x)(get(x,'position')),hAxB(:),'un',0));
W0 = axP(1,3);

% retrieves the legend width (if not provided)
if (nargin < 5); wLg = lgP(3); end

% updates the legend width
dWT = wLg+dW;
lgP(1:2) = [(1-dWT),(0.5-lgP(4)/2)];
set(hLg,'position',lgP);

%
Wmx = max(sum(axP(:,[1 3]),2));
dWAx = (Wmx - (lgP(1)+dW));

% repositions each of the subplot axis
for j = 1:dim(1)
    for k = 1:dim(2)
        kk = (j-1)*dim(2)+k;
        if (kk <= numel(hAxB))
            axP(kk,1) = axP(kk,1) - (k-1)*dWAx/dim(2);
            axP(kk,3) = axP(kk,3) - dWAx/dim(2);
            set(hAxB{kk},'position',axP(kk,:));
            
            hErr = findall(hAxB{kk},'tag','hErr');
            if (~isempty(hErr))
                cSzNw = hErr(1).CapSize*axP(kk,3)/W0;
                set(hErr,'CapSize',cSzNw)
            end
        end
    end
end