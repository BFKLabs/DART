% --- calculates the neighbouring pixel cross-correlations
function [R2,P] = calcPixelXCorr(indN,pB,h,pW)

% global variables
global wOfs hasWait

% memory allocation for the sparse matric elements
[nEle,nB] = deal(cellfun(@length,indN),size(pB,2));
nEleC = [0;cumsum(nEle)];
[iR,iC,R2v,Pv] = deal(zeros(nEleC(end),1));
pBsm = cell(1,nB);

% other memory allocations
if ((nargin > 2) && (hasWait))
    [iW,isW] = setupWaitbarArrays(nB); 
end

% loops through each of the significant pixels calculating the mutual
% information with each of the pixels neighbours
for j = 1:nB
    % determines if the waitbar figure needs to be updated    
    if ((nargin > 2) && (hasWait))
        iFound = find(j >= iW,1,'last');
        if (~isW(iFound))
            % updates the index array
            isW(iFound) = true;                        
            
            % updates the waitbar figure
            pWnw = pW(1) + pW(2)*((iFound-1)/(length(iW)-1));
            if (updateWaitbarPara('Pixel Cross-Correlation Calculations',pWnw,h,wOfs))
                [R2,P] = deal([]);
                return
            end            
        end    
    end
    
    %
    if (isempty(pBsm{j}))
        pBsm{j} = smooth(pB(:,j));
    end
        
    % loops through each of the pixels local neighbours
    for k = 1:length(indN{j})
        % sets the local index
        [i,iCC] = deal(indN{j}(k),nEleC(j) + k);
        if (isempty(pBsm{i}))
            pBsm{i} = smooth(pB(:,i));
        end
                
        % calculates the normalised signal mutual information             
        [Rtmp,Ptmp] = corrcoef(pBsm{j},pBsm{i});
        [iR(iCC),iC(iCC),R2v(iCC),Pv(iCC)] = deal(i,j,Rtmp(2,1),Ptmp(2,1));
    end
end

% sets the final R2 sparse array
R2 = sparse(iR,iC,R2v,nB,nB) + sparse(iC,iR,R2v,nB,nB);
P = sparse(iR,iC,Pv,nB,nB) + sparse(iC,iR,Pv,nB,nB);
