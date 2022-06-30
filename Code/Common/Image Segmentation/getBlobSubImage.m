% --- retrieves the sub-region image surrounding the blob, iGrpB
function [Isub0,Bw0,pOfs] = getBlobSubImage(iGrpB,IRB,BwB,sz,dN0)

% sets the default input arguments
if ~exist('dN0','var'); dN0 = 5*[1,1]; end

if iscell(iGrpB)
    % memory allocation
    [Isub0,Bw0,pOfs] = deal(cell(length(iGrpB),1));
    
    % retrieves the sub-image for each blob in the cell array
    for i = 1:length(iGrpB)
        [Isub0{i},Bw0{i},pOfs{i}] = ...
                                getBlobSubImage(iGrpB{i},IRB,BwB,sz,dN0);
    end
    
    % exits the function
    return
end

% converts the linear indices to coordinates
[yP,xP] = ind2sub(sz,iGrpB);

% sets the feasible column indices
iR = (min(yP)-dN0(1)):(max(yP)+dN0(1));
ii = (iR >= 1) & (iR <= sz(1));

% sets the feasible column indices
iC = (min(xP)-dN0(1)):(max(xP)+dN0(1));   
jj = (iC >= 1) & (iC <= sz(2));

% sets the sub-image (given the feasible rows/columns)
Isub0 = NaN(length(iR),length(iC));
Isub0(ii,jj) = IRB(iR(ii),iC(jj));

% set the rejection binary mask (removes any other 
% blobs within the sub-image frame)
if isempty(BwB)
    Bw0 = [];
else
    if isa(BwB,'logical')
        Bw0 = false(length(iR),length(iC));
    else
        Bw0 = zeros(length(iR),length(iC));        
    end
        
    Bw0(ii,jj) = BwB(iR(ii),iC(jj));
end

% sets the sub-image offset
if nargout == 3
    pOfs = [iC(1),iR(1)] - 1;
end