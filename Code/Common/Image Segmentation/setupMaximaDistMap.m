% --- sets up the maxima distance map
function Dmap = setupMaximaDistMap(iMx,sz)

% memory allocation
D = zeros([sz,length(iMx)]);                 

% sets up the distance matrix for each maxima point
for j = 1:length(iMx)
    D(:,:,j) = bwdist(setGroup(iMx(j),sz)); 
end

% determines the regions closest to each of the maxims
[~,Dmap] = min(D,[],3);