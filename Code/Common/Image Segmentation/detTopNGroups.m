% --- 
function [iGrp,Pmx,pTol,I] = detTopNGroups(I,N,R,isMax,outAll)

% sets the default rejection radius (if not set)
if (nargin < 3); R = 3; end
if (nargin < 4); isMax = 1; end
if (nargin < 5); outAll = false; end

% if minimising, then take negative of image values
if (~isMax); I = -I; end

% array dimensioning
[sz,iGrp,i,j] = deal(size(I),getGroupIndex(imregionalmax(I)),1,1);
N = min(N,length(iGrp));
[Pmx,pTol] = deal(NaN(N,2),NaN(N,1));

% determines the regional maxima
Imx = cellfun(@(x)(I(x(1))),iGrp);

% sorts the regional maxima by their values
[~,ii] = sort(Imx,'descend');
[Imx,iGrp] = deal(Imx(ii),iGrp(ii));

%
while ((i <= N) && (j <= length(Imx)))
    % sets the sub-scripts for the new maxima
    Pnw = zeros(length(iGrp{j}),2);
    [Pnw(:,2),Pnw(:,1)] = ind2sub(sz,iGrp{j});
    
    if (length(iGrp{j}) > 1)
        Pnw = calcWeightedMean(Pnw);
    end
    
    % calculates the distances between the 
    if (i == 1)
        D = 1e10;
    else    
        D = sqrt((Pmx(1:(i-1),1)-Pnw(1)).^2 + (Pmx(1:(i-1),2)-Pnw(2)).^2);
    end
        
    % if the distance is greater than tolerance, then add to the list
    if (min(D) > 2*R)
        [pTol(i),Pmx(i,:)] = deal(Imx(j),Pnw);
        i = i + 1;
    end
    
    % increments the array counter
    j = j + 1;
end

%
[~,jj] = sort(Pmx(:,2));
[iGrp,Pmx,pTol] = deal(iGrp(jj),Pmx(jj,:),pTol(jj));

% sets the output data into a single array
if (outAll); iGrp = {iGrp,Pmx,pTol}; end