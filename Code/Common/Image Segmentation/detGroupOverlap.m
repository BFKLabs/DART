% --- determines the blob groups within B that overlap that within Bx
function [kGrp,Bnw] = detGroupOverlap(B,Bx)

% initialisations
[kGrp,Bnw] = deal([],false(size(B)));
if size(B) ~= size(Bx)
    Bx = setGroup(Bx,size(B));
end

% determines the blob linear indices and from this determines which blobs
% overlap with the original
iGrp = getGroupIndex(B);
ii = cellfun(@(x)(any(Bx(x))),iGrp);

% returns the linear indices/binary of the overlapping blobs
if any(ii)
    kGrp = iGrp(ii);
    if nargout > 1
        Bnw = setGroup(kGrp,size(B));
    end
end
