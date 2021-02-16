% --- calculates the x/y derivative cross-correlation
function [Z,Inw] = calcDerivXCorr(xcP,Bw,Inw,Ig,Gx,Gy)

% global variables
global is2D

% if cell arrays are provided, then run the function for each cell
if (iscell(Inw))
    % memory allocation
    Z = cell(size(Inw));
    if (isempty(Bw)); Bw = Z; end
    
    % calculates the derivative x-corr masks
    for i = 1:length(Z)
        [Z{i},Inw{i}] = calcDerivXCorr(xcP,Bw{i},Inw{i},Ig{i},Gx{i},Gy{i});
    end
    
    % exits the function
    return
end

% parameters
D = floor(size(xcP.ITx,1)/2);

% retrieves the cross-correlation image (if not provided)
if (nargin == 3)
    [Inw,Ig] = getXCorrImage(Inw,Bw);
end

% calculates the x/y image derivative (if not provided)
if (nargin < 5)
    [Gx,Gy] = imgradientxy(Ig,'Sobel'); 
end

% calculates the x/y gradients of the candidate image, and the
% cross correlation sum image
Z = 0.5*(calcXCorr(xcP.ITx,Gx,D) + calcXCorr(xcP.ITy,Gy,D)); 

% removes the rejected regions from the Z-score image
if (is2D)
    if (~isempty(Bw))
        [Z(~Bw),Inw(~Bw)] = deal(-1,max(Inw(Bw))); 
    end
end

