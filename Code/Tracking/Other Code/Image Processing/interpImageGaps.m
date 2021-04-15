% --- interpolates the gaps in an image (along a given dimension)
function Iint = interpImageGaps(I,iDim)

% sets the interpolation dimension (if not provided)
if nargin == 1; iDim = 2; end

% interpolates the image along the selected dimension
Iint = cell2mat(cellfun(@(x)(interpImageDim(x)),num2cell(I,iDim),'un',0));

% --- interpolates along a single image dimension
function yI = interpImageDim(yI)

% determines the gaps in the signal (if none then exit)
isN = isnan(yI);
if all(isN)
    return
else
    iGrp = getGroupIndex(isN);
    if isempty(iGrp); return; end
end

% sets the 1st group to the 1st valid value (if touching the first edge)
if iGrp{1}(1) == 1
    yI(iGrp{1}) = yI(iGrp{1}(end)+1);
    isN(iGrp{1}) = false;
    
    % reduces the array. exits if there are no more gaps
    iGrp = iGrp(2:end);
    if isempty(iGrp); return; end    
end

% sets the last group to the last valid value (if touching the other edge)
if iGrp{end}(end) == length(yI)
    yI(iGrp{end}) = yI(iGrp{end}(1)-1);
    isN(iGrp{end}) = false;
    
    % reduces the array. exits if there are no more gaps
    iGrp = iGrp(1:(end-1));
    if isempty(iGrp); return; end       
end

% interpolates the remaining gaps 
if ~isempty(iGrp)
    xGrp = find(~setGroup(cell2mat(iGrp),size(yI)));
    yI(isN) = interp1(xGrp,yI(xGrp),find(isN),'pchip');
end