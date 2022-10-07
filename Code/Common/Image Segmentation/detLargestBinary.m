% --- determines the largest feasible binary mask (i.e., binary
%     mask which doesn't touch the image edge)
function BGrp = detLargestBinary(I,p0,ILim,nDil)

% parameters
dILimTol = 1;

% other initialisations
szL = size(I);
BE = bwmorph(true(szL),'remove');

% default input arguments
if ~exist('nDil','var'); nDil = 2; end
if ~exist('ILim','var'); ILim = [min(I(:)),max(I(:))]; end

if exist('p0','var')
    [B0,BBest] = deal(setGroup(roundP(p0),szL));    
else
    [B0,BBest] = deal(setGroup(argMin(I(:)),szL));
end

% keep looping until limit difference is less than tolerance
while diff(ILim) > dILimTol
    % calculates the new limit/binary mask
    ILimNw = mean(ILim);
    [~,BNw] = detGroupOverlap(I <= ILimNw,B0);
    
    % updates the limits (based on the threshold result)
    iType = 1 + any(BNw(BE));
    ILim(iType) = ILimNw;
    
    % updates the best binary group
    if iType == 1; BBest = BNw; end
end

% sets the final binary mask blob
BGrp = ~BE & bwmorph(BBest,'dilate',nDil);
