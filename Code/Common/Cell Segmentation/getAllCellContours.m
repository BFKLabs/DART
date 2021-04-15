% --- retrieves all the cell contours from the thresholded maxima points
function [Pc,iGrp,ok] = getAllCellContours(I,p,xMx,yMx,pW,h)

% global variable
global wOfs

% memory allocation and parameters
[isFound,sz,ok] = deal(false(length(xMx),1),size(I),true);
[Pc,iGrp] = deal(cell(length(xMx),1));

% retrieves the local maxima index array
[~,kk] = sort(I(sub2ind(sz,yMx,xMx)),'descend');
[ind,pMx] = deal(getLocalIndexArray(xMx,yMx,sz,32),[xMx,yMx]);

% sets up the waitbar figure arrays
[iW,isW] = setupWaitbarArrays(length(xMx));

% while there are still maxima points to be searched, then keep calculating 
% the cell contour search
while (any(~isFound))
    % retrieves the sub-image and pixel offset
    i0 = find(~isFound,1,'first');
    [i,isFound(i0)] = deal(kk(i0),true);
    pMxNw = [xMx(i),yMx(i)];  
    
    % determines if the waitbar figure needs to be updated    
    iFound = find(sum(isFound) >= iW,1,'last');
    if (~isW(iFound))
        % updates the index array and waitbar figure proportion
        isW(iFound) = true;        
        
        % updates the waitbar figure
        pWnw = pW(1) + pW(2)*((iFound-1)/(length(iW)-1));
        if (updateWaitbarPara('Cell Contour Calculations',pWnw,h,wOfs))   
            ok = false;
            return
        end
    end    
    
    % sets the global row/column indices
    ii = floor(pMxNw/(sz(1)/size(ind,1)))+1;
    iCG = getGlobalIndices(ii(1),size(ind,2));
    iRG = getGlobalIndices(ii(2),size(ind,1));
    indG = ind(iRG,iCG);

    % sets the row/column indices and the x/y offsets
    [Isub,pOfs] = getSubImage(I,pMxNw,20);
     
    % determines the largest feasible contour from the sub-image
    [Pc{i},cInd] = getLargestContour(p,Isub,pMxNw,pMx,cell2mat(indG(:)),pOfs);                            
    if (~isempty(Pc{i}))
        % if a feasible contour was found, then remove the cell
        iGrp{i} = getCellGroupIndices(Pc{i},sz);        
        I = removeContourImg(I,Isub,Pc{i},pOfs);
        
        % if there are any overlapping maxima, then set them as being found
        if (~isempty(cInd))
            for j = 1:length(cInd)
                isFound(kk == cInd(j)) = true;
            end
        end
    end    
end    

% removes any empty contour arrays
jj = cellfun(@length,iGrp) > p.Amin;
[Pc,iGrp] = deal(Pc(jj),iGrp(jj));

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% ----------------------------------- %
% --- IMAGE CALCULATION FUNCTIONS --- %
% ----------------------------------- %

% --- removes the contour image from the average image
function I = removeContourImg(I,Isub,Pc,pOfs,hQ)

% parameters
if (nargin < 5); hQ = 2; end
szL = size(Isub);

% determines the 
[X,Y] = meshgrid(1:szL(2),1:szL(1)); 
BB = inpolygon(X,Y,Pc(:,1)-pOfs(1),Pc(:,2)-pOfs(2)); 

% sets the local image into the overall image
[iR,iC] = deal(pOfs(2)+(1:szL(1)),pOfs(1)+(1:szL(2)));
I(iR,iC) = (1-exp(-bwdist(BB).^2/hQ)).*I(iR,iC);

% --- retrieves the sub-image surrounding the maxima point
function [Isub,pOfs] = getSubImage(I,pMx,N)

% initialisations and parameters
if (nargin < 3); N = 10; end

% sets the row/column indices and the x/y offsets
iCS = max(1,pMx(1)-N):min(size(I,2),pMx(1)+N);
iRS = max(1,pMx(2)-N):min(size(I,1),pMx(2)+N);
[pOfs,Isub] = deal([(iCS(1)-1),(iRS(1)-1)],I(iRS,iCS));

% normalises the image to the maximal value
IMx = Isub(pMx(2)-pOfs(2),pMx(1)-pOfs(1)); IMn = 0.25*IMx;
[Isub(Isub > IMx),Isub(Isub < IMn)] = deal(IMx,IMn);

% ------------------------------------- %
% --- CONTOUR CALCULATION FUNCTIONS --- %
% ------------------------------------- %

% --- retrieves the largest 
function [Pc,cInd] = getLargestContour(p,Isub,pMx,pMx0,indG,pOfs)

% initialisations and parameters
[pMx0,pMx,szL] = deal(pMx0(indG,:),pMx-pOfs,size(Isub));
if (size(pMx0,1) > 1)
    % 
    pMx0 = pMx0 - repmat(pOfs,size(pMx0,1),1);
    ii = cellfun(@(x)(~isequal(pMx,x)),num2cell(pMx0,2));
    [pMx0,indG] = deal(pMx0(ii,:),indG(ii));
    
    %
    jj = (pMx0(:,1)>=1)&(pMx0(:,2)>=1)&(pMx0(:,1)<=szL(1))&(pMx0(:,1)<=szL(2));
    [indG,pMx0] = deal(indG(jj),pMx0(jj,:));
else
    % no other surrounding points
    pMx0 = zeros(1,2);
end

% determines the initial feasible contour
[Pc,cInd] = splitContour(p,Isub,pMx,pMx0);
if (~isempty(Pc))
    Pc = Pc + repmat(pOfs,size(Pc,1),1);
    if (~isempty(cInd)); cInd = indG(cInd); end
end

% --- determines the most likely contours to contain the cell region
function [Pc,cInd] = splitContour(p,Isub,pMx,pMx0)

% initialisations
[cOfs,nLvl,Pc,cInd,iLvl,cLvl] = deal(1,40,[],[],[],[]);

% determines the indices/lengths of the feasible contours (contours that
% have start/end points that are the same)
hh = contourc(Isub,nLvl);
if (isempty(hh)); return; end

% determines if the 
while (1)
    % sets the number of indices for the current contour level
    Nnw = hh(2,cOfs);
    iCnw = cOfs + [1 Nnw];
    
    % determines if the contour start/end are coincident
    if ((diff(hh(1,iCnw)) == 0) && (diff(hh(2,iCnw)) == 0))
        % if so, then set the contour indices/level values
        [iLvl,cLvl] = deal([iLvl;iCnw],[cLvl;hh(1,cOfs)]);
    end
    
    % increments the column offset counter
    cOfs = cOfs + (Nnw+1);
    if (cOfs > size(hh,2)); break; end
end

% if there are any 
if (~isempty(iLvl))
    % sets the x/y coordinates of the contour levels
    iC = cellfun(@(x)(x(1):x(2)),num2cell(iLvl,2),'UniformOutput',0);
    xLvl = cellfun(@(x)(hh(1,x)),iC,'UniformOutput',0);
    yLvl = cellfun(@(x)(hh(2,x)),iC,'UniformOutput',0);
    ALvl = cellfun(@(x,y)(polyarea(x,y)),xLvl,yLvl);

    % removes the groups that are below the area threshold
    iA = ALvl >= p.Amin;
    [xLvl,yLvl,ALvl] = deal(xLvl(iA),yLvl(iA),ALvl(iA));
    
    % sorts the contours by area in descending order
    [~,iS] = sort(ALvl,'descend');
    [xLvl,yLvl] = deal(xLvl(iS),yLvl(iS));

    % sorts the largest feasible contour
    Pc = getFeasibleContour(xLvl,yLvl,pMx);
        
    if (~isempty(Pc))
        cInd = find(inpolygon(pMx0(:,1),pMx0(:,2),Pc(:,1),Pc(:,2)));
    end
end
    
% --- retrieves the best feasible contour 
function cLvlF = getFeasibleContour(xLvl,yLvl,pMx)

% initialisations and parameters
nLvl = length(xLvl);
[indP,i0,iP,cLvlF] = deal(NaN(nLvl,1),1,[],[]);

%
for i = nLvl:-1:2
    iPnw = (i-1);
    while (1)        
        if (inpolygon(xLvl{i}(1),yLvl{i}(1),xLvl{iPnw},yLvl{iPnw}))
            indP(i) = iPnw;
            break;
        else
            iPnw = iPnw - 1;
            if (iPnw == 0)
                break
            end
        end
    end
end

% determines the children indices
indC = cellfun(@(x)(find(indP==x)),num2cell(1:nLvl)','UniformOutput',0);

% determines the contour groups
indG = find(isnan(indP));
ii = cellfun(@(x)(inpolygon(pMx(1),pMx(2),xLvl{x},yLvl{x})),num2cell(indG));

% sets the parent contours
if (any(ii))
    [pGrp,iP] = deal(find(cellfun(@(x)(length(x)>1),indC)),indG(ii));
    if (~isempty(pGrp))
        %
        xP = cellfun(@(x)(xLvl{x}(1)),num2cell(pGrp));
        yP = cellfun(@(x)(yLvl{x}(1)),num2cell(pGrp));
        jj = inpolygon(xP,yP,xLvl{iP},yLvl{iP});
        [pGrp,xP,yP] = deal(pGrp(jj),xP(jj),yP(jj));

        % if there are sub-contours within the largest contour, then
        % determine if they meet tolerance. if not, then reduce the 
        % sub-contours down until they meet 
        cont = ~isempty(pGrp);
        while (cont)
            % sets the children contour groups
            cGrp = indC{pGrp(i0)};                
            if (cont)            
                % increments the counter. if no more sub-contours then exit
                iP = cGrp(cellfun(@(x)(inpolygon(pMx(1),pMx(2),...
                                        xLvl{x},yLvl{x})),num2cell(cGrp)));                
                if (isempty(iP))                                    
                    cont = false;
                else
                    % determines the next sub-contour from the parent group
                    i0 = find(inpolygon(xP,yP,xLvl{iP},yLvl{iP}),1,'first');                                                            
                    if (isempty(i0))
                        % if there are none, then exit the loop
                        cont = false;
                    end
                end
            end
        end
    end  
end
    
% set the final feasible contour
if (~isempty(iP))
    cLvlF = [xLvl{iP}',yLvl{iP}'];
end

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% --- converts the local coordinates to global frame coordinates
function iGrp = getCellGroupIndices(Pc,sz)

% calculates the pixel offset
[pOfsMn,pOfsMx] = deal(floor(min(Pc,[],1))-1,ceil(max(Pc,[],1))+1);
pRng = pOfsMx-pOfsMn;

% sets the pixel range
[xP,yP] = meshgrid(1:pRng(1),1:pRng(2));
B = inpolygon(xP,yP,Pc(:,1)-pOfsMn(1),Pc(:,2)-pOfsMn(2));

% 
[yB,xB] = ind2sub(size(B),find(B));
iGrp = sub2ind(sz,yB+pOfsMn(2),xB+pOfsMn(1));