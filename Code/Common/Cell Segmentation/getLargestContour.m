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
    if (~isempty(cInd))
        cInd = indG(cInd); 
    end
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
    [xLvl,yLvl,cLvl,ALvl] = deal(xLvl(iA),yLvl(iA),cLvl(iA),ALvl(iA));
    
    % sorts the contours by area in descending order
    [~,iS] = sort(ALvl,'descend');
    [xLvl,yLvl,cLvl,ALvl] = deal(xLvl(iS),yLvl(iS),cLvl(iS),ALvl(iS));

    % sorts the largest feasible contour
    Pc = getFeasibleContour(p,xLvl,yLvl,cLvl,ALvl,pMx);        
    if (~isempty(Pc))
        cInd = find(inpolygon(pMx0(:,1),pMx0(:,2),Pc(:,1),Pc(:,2)));
    end
end
    
% --- retrieves the best feasible contour 
function cLvlF = getFeasibleContour(p,xLvl,yLvl,cLvl,ALvl,pMx)

% REMOVE ME LATER
p.pTol = 0.2;

% initialisations and parameters
[nLvl,cLvlMx] = deal(length(xLvl),max(cLvl));
[indP,i0,iP,cLvlF] = deal(NaN(nLvl,1),1,[],[]);

% % normalises the contour levels
% [cLvlMx,cLvlMn] = deal(max(cLvl),min(cLvl));
% cLvlN = (cLvl - cLvlMn)/(cLvlMx - cLvlMn);

% keep searching for the largest contour that contains the maxima
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

            % determines if the sub-contours meet the threshold criteria
            if ((cLvlMx-cLvl(cGrp(1))) < p.pTol)            
                % if so, then exit the loop
                cont = false;
            end
                
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