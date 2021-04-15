% --- optimises parameters for the general 2D gaussian equation
function [Iopt,pOptF] = opt2DGaussian(Isub,pLim,pOpt0)

% optimisation solver option struct
opt = optimset('display','none','tolX',1e-6,'TolFun',1e-6);

% calculates the weighted mean image
pW = pLim/min(pLim);
X0 = cellfun(@(p,x)(p*x),num2cell(pW(:)),Isub(:),'un',0);
I0 = min(0,calcImageStackFcn(X0,'median'));

% determines the largest contour surrounding the frame centre-point
Pc = splitContourLevels(I0,20);
Bw = poly2bin(Pc{end},size(I0));
I = I0.*Bw;

% estimates the median/amplitude
if isempty(pOpt0)
    I(isnan(I)) = nanmedian(I(:));
    Ymd = nanmedian(I(:));
    Yamp = nanmax(I(:)) - nanmin(I(:));
    pOpt0 =  [   Ymd,  Yamp,  0.1, 0.1];
end

% sets up the x/y coordinate values
D = floor(size(I,1)/2);
[X,Y] = meshgrid(-D:D);

% parameters
pLB = [-255.0,-255.0,  0.0, 0.0];
pUB = [ 255.0, 255.0,  5.0, 5.0];

% runs the optimiation can returns the optimal template
pOptF = lsqnonlin(@optFunc,pOpt0,pLB,pUB,opt,I,X,Y,1-normImg(I));
[~,Iopt] = optFunc(pOptF,I,X,Y);  

% --- optimisation function for fitting the gabor function
function [F,ITg] = optFunc(p,IT,X,Y,Qw)

% calculates the new objective function
try
    [Y0,A,k1,k2] = deal(p(1),p(2),p(3),p(4));
    ITg = Y0 - A*exp(-k1*X.^2 + -k2*Y.^2);

    % calculates the objective function
    if exist('Qw','var')
        F = Qw.*(ITg - IT);
    else
        F = ITg - IT;
    end
    
catch
    %
    [F,ITg] = deal(1e10*ones(size(IT)),NaN(size(IT)));
end
