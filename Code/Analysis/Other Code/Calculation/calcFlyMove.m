% --- function that detects the frames that the flies have moved at a speed
%     greater than vAct
function [isMove,Vtot,Vmove,Dmove] = calcFlyMove(snTot,T,indRow,iApp,vAct)

% array indexing
nFrm = length(T);
fok = arr2vec(snTot.iMov.flyok(iApp));

% retrieves the x/y values of the flies for the current experiment and
% calculates the new time vector (wrt to the start time)
if ~isempty(snTot.Px)
    % X-values are present (2D tracking)
    X = cellfun(@(x,y)(x(indRow,y)),snTot.Px(iApp),fok,'un',0);
else
    % X-values are missing (1D tracking)
    X = cellfun(@(x)(zeros(nFrm,sum(x))),fok,'un',0);
end

if ~isempty(snTot.Py)
    % Y-values are present (2D tracking)
    Y = cellfun(@(x,y)(x(indRow,y)),snTot.Py(iApp),fok,'un',0);
else
    % Y-values are missing (1D tracking)
    Y = cellfun(@(x)(zeros(nFrm,sum(x))),fok,'un',0);
end

% calculates the inter-frame speed (distance/time) and from this
% determines the frames where the flies have moved (i.e., where the
% speed is greater than tolerance)
[dTnw,dTall] = deal(diff(T),diff(T([1 end])));
Dnw = cellfun(@(x,y)(sqrt(diff(x,1).^2+diff(y,1).^2)),X,Y,'un',0);
Vnw = cellfun(@(x)(x./repmat(dTnw,1,size(x,2))),Dnw,'un',0);
isMove = cellfun(@(x)(x >= vAct),Vnw,'un',0);

% calculates the overall average and active speed/displacements
dTnwT = cellfun(@(x)(repmat(dTnw,1,size(x,2))),Dnw,'un',0);
Vtot = cellfun(@(x)(sum(x,1,'omitnan')/dTall),Dnw,'un',0);
Dmove = cellfun(@(x,y)(sum(x.*y,1,'omitnan')),Dnw,isMove,'un',0);
Vmove = cellfun(@(x,y,z)(sum(x.*z,1,'omitnan')./sum(y.*z,1,'omitnan')),...
                                    Dnw,dTnwT,isMove,'un',0);
