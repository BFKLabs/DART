% --- calculates the extremum of a signal, Ysig 
function [imx,indTmp] = calcSignalExtremum(Ysig,kTol)

% initialisations
Ysig = reshape(Ysig,length(Ysig),1);
[nP,sYsig] = deal(length(Ysig),sign(Ysig));

% thresholds the image such that the signal values less that kTol are zero
if (nargin > 1)
    ii = abs(Ysig) < kTol;
    [Ysig(ii),sYsig(ii)] = deal(0);
end

% determines the positions in the signal where there is a change in sign
ii = find(sYsig);
jj = find(diff(ii) > 1);

% from this, calculate the index bands of the signal components that are
% greater than zero
indTmp = [([ii(1);ii(jj+1)]-1) ([ii(jj);ii(end)]+1)];
[indTmp(1,1),indTmp(end,2)] = deal(max(1,indTmp(1,1)),min(nP,indTmp(end,2)));

%
ind = [];
for i = 1:size(indTmp,1)
    %
    B = Ysig(indTmp(i,1):indTmp(i,2));
    kk = find(abs(diff(sign(B))) > 1);
    
    %
    if (isempty(kk))
        %
        ind = [ind;indTmp(i,:)];
    else
        for j = 1:(length(kk)+1)
            switch (j)
                case (1)
                    indNw = [1 kk(j)];
                case (length(kk)+1)
                    indNw = [(kk(j-1)+1) length(B)];                    
                otherwise
                    indNw = [(kk(j-1)+1) kk(j)];
            end             
            
            %
            ind = [ind;(indTmp(i,1)-1)+indNw];                        
        end
    end
end

%
imx = zeros(size(ind,1),1);
for i = 1:size(ind,1)
    %
    if (i > length(imx))
        break
    else
        %
        if (indTmp(1,1) == 1) && (indTmp(end,2) == nP) && (i == 1)
            %
            indMx = [(ind(i,1):ind(i,2)) (ind(end,1):(ind(end,2)-1))];
            imx = imx(1:(end-1));
        else
            %
            indMx = ind(i,1):ind(i,2);
        end
        
        %
        [~,imxNw] = max(abs(Ysig(indMx)));            
        imx(i) = indMx(imxNw);        
    end       
end

%
if (any(imx == 1)) && (any(imx == nP))
    imx = imx(1:(end-1));
end

% resorts the time points into chronological order
imx = sort(imx,'ascend');

%
if (size(indTmp,1) > 1)
    while (1)
        % determines the upper bounds that are coincident with the next
        % band lower bound
        ii = (indTmp(1:end-1,2) == indTmp(2:end,1)); 
        if (~any(ii))
            % if none exist, then exit the loop
            break
        else
            % otherwise, join the last coincident bands and remove the last
            % element from the band index array
            jj = find(ii,1,'last');
            indTmp(jj,2) = indTmp(jj+1,2);
            indTmp = indTmp((1:size(indTmp,1))' ~= (jj+1),:);
            
            % if there is only one band left, then exit the loop
            if (size(indTmp,1) == 1)
               break 
            end
        end
    end
end