% --- adds in the errorbars to the data on the axis, hAx --- %
function hErr = addBarError(hAx,xi,Y,Ysem,col,lWid,pW)

% sets the default parameters (if not provided)
if ~exist('lWid','var'); lWid = 2.5; end
if ~exist('pW','var'); pW = 0.75; end

% initialisations and parameters
if isempty(xi); xi = 1:length(Y); end
    
% sets the upper/lower SEM limits
if iscell(Ysem)
    if iscell(Ysem{1})
        [YL,YU] = deal(Ysem{1}{1}-Y,max(Ysem{1}{2}-Y,0));
    else
        [YL,YU] = deal(Ysem{1}-Y,max(Ysem{2}-Y,0));
    end
else
    dYL = Ysem - reshape(Y,size(Ysem));
    [YU,YL] = deal(Ysem,Ysem - dYL.*(dYL > 0));
end

% sets any zero lower/upper values to NaNs
[YU(YU == 0),YL(YL == 0)] = deal(NaN);

% retrieves the axis object
if strcmp(hAx.Type,'bar')
    hPE = get(hAx,'Parent');
else
    hPE = hAx;
end

% creates the error bar
hErr = errorbar(hPE,xi,Y,YL,YU,'.','markersize',1,'linewidth',lWid,...
                                   'color',col,'tag','hErr');

% sets the cap-size (wrt to the bar widths)
axP = getPanelPosPix(hPE,'points'); 
hP = findall(hPE,'type','Bar');
hErr.CapSize = 0.75*pW*hP(1).BarWidth*axP(3)/length(xi);
