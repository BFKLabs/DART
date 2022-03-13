function Im = setGroup(Ig,dim,isInv)

% converts the 
if isempty(Ig)
    Im = false(dim);
    return
elseif ~iscell(Ig)
    Ig = {Ig};
end

% sets the inverted mask to false if not set
if (nargin== 2)
    isInv = 0;
end

% case is a normal mask
Im = false(dim(1),dim(2));
for i = 1:length(Ig)
    if size(Ig{i},2) == 2
        Im(sub2ind(dim,Ig{i}(:,2),Ig{i}(:,1))) = true;
    else
        Im(Ig{i}) = true;   
    end
end

% sets the indices 
if (isInv)
    Im = ~Im;
end