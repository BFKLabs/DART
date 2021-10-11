% --- determines the 
function [kGrp,Bnw] = detGroupOverlap(B,Bx)

%
if isequal(size(B),size(Bx))
    iGrp = find(Bx);
else
    iGrp = sub2ind(size(B),Bx(:,2),Bx(:,1));
end

%
[B,jGrp] = deal(double(B>0),getGroupIndex(B>0));
B(iGrp) = B(iGrp) + 1;

%
ii = cellfun(@(x)(mean(B(x))>1),jGrp);
if (any(ii))
    [kGrp,Bnw] = deal(jGrp(ii),setGroup(jGrp(ii),size(B)));
else
    [kGrp,Bnw] = deal([],false(size(B)));
end
