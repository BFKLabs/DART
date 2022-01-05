% --- sets up the median filtered residual estimate stack
function [dI,d2I] = setupResidualEstStack(Iapp,mdDim)

% calculates the median background estimate
B = cellfun(@(x)(medianBGImageEst(x,mdDim)),Iapp,'un',0);
Bmx = calcImageStackFcn(B,'max'); 
dI = cellfun(@(x)(max(0,Bmx-x).*...
                (1-normImg(x)).^0.5),Iapp,'un',0);

% calculates the twice residual image
if nargout == 2
    dBmin = calcImageStackFcn(dI,'min');
    d2I = cellfun(@(x)(x-dBmin),dI,'un',0);
end
