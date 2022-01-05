% --- creates the split region index map mask
function iMov = createRegionIndexMap(iMov)

% global variables
global frmSz0

% memory allocation
[aP,sD] = deal(iMov.autoP,iMov.srData);
[nFly,nApp] = size(aP.X0);
[Imap,iGrp] = deal(zeros(frmSz0),cell(nFly,nApp));

% sets the sub-region maps for each sub-region
for j = 1:nApp
    for i = 1:nFly
        switch iMov.mShape
            case 'Rect'
                % case is the rectangular regions

                % sets the rectangle parameters
                p0 = [aP.X0(i,j),aP.Y0(i,j)];
                [W,H] = deal(aP.W(i,j),aP.H(i,j));
                [pW,pH] = deal(sD.pWid{i,j},sD.pHght{i,j});

                % calculates the proportional location
                [X,Y] = meshgrid(1:frmSz0(2),1:frmSz0(1));
                [pX,pY] = deal((X-p0(1))/W,(Y-p0(2))/H);
                iGrp{i,j} = cell(length(pH)*length(pW),1);

                % sets the binary regions for each grid rectangle
                y0 = 0;
                for k1 = 1:length(pH)
                    % sets the column limits
                    [yL,x0] = deal([y0,sum(pH(1:k1))],0);
                    for k2 = 1:length(pW)
                        % sets the row limits
                        xL = [x0,sum(pW(1:k2))];

                        % sets the 
                        Bnw = (pX >= xL(1)) & (pX <= xL(2)) & ...
                              (pY >= yL(1)) & (pY <= yL(2)); 
                        
                        iNw = (k1-1)*length(pH) + k2;
                        iGrp{i,j}{iNw} = find(Bnw);
                        Imap(Bnw) = iNw;

                        % increments the width offset
                        x0 = x0 + pW(k2);
                    end

                    % increments the height offset
                    y0 = y0 + pH(k1);
                end           
                
            case 'Circ'
                % case is the circular regions

                % calculates the circle properties
                phiP = sD.pPhi{i,j};  
                [p0,R] = deal([aP.X0(i,j),aP.Y0(i,j)],aP.R(i,j));
                iGrp{i,j} = cell(length(phiP),1);
                
                % determines the points within the circle
                D = bwdist(setGroup(roundP(p0),frmSz0));
                Bnw = D <= R;   
                
                % calculates the angles (relative to the centre point)
                [X,Y] = meshgrid(1:frmSz0(2),1:frmSz0(1));
                phiC = atan2(Y-p0(2),X-p0(1));

                % sets up the mapping index array
                phiPL = phiP([1:end,1]);
                for k = 1:length(phiP)
                    %    
                    if phiPL(k+1) < phiPL(k)
                        Bseg = (phiC >= phiPL(k)) | ...
                               (phiC < phiPL(k+1));
                    else
                        % case is the other segments
                        Bseg = (phiC >= phiPL(k)) & ...
                               (phiC <= phiPL(k+1));
                    end

                    % sets the group mapping index mask
                    iGrp{i,j}{k} = find(Bnw & Bseg);
                    Imap(iGrp{i,j}{k}) = k;
                end                
                
        end            
    end
end

% sets the global mapping indices
nGrp = cellfun(@length,iGrp);
iMov.srData.indG = cell2mat(arrayfun(@(i,n)...
            ([i*ones(n,1),(1:n)']),(1:length(nGrp))',nGrp,'un',0));

% resets the map/group fields
[iMov.srData.Imap,iMov.srData.iGrp] = deal(Imap,iGrp);