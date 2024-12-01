% --- reduces down the apparatus parameter solution struct (for single
%     experiment analysis)
function snTotL = reduceSolnAppPara(snTot)

% sets the initial solution struct
snTotL = snTot(1);

% if only one experiment, then reduce down the solution struct
if length(snTot) == 1
    % sets the acceptance/rejection flags
    ok = snTotL.iMov.ok;
    [flyok0,pInfo] = deal(snTot.iMov.flyok,snTot.iMov.pInfo);
    
    % reduces down the acceptance flag/group name arrays
    snTotL.cID = snTotL.cID(ok);
    snTotL.iMov.ok = snTotL.iMov.ok(ok);
    snTotL.iMov.flyok = snTotL.iMov.flyok(ok);
    [snTotL.iMov.Name,snTotL.iMov.pInfo.gName] = ...
                            deal(snTotL.iMov.pInfo.gName(ok));
    
    % reduces down the individual acceptance flags (dependent on expt type)
    if ~iscell(snTotL.iMov.flyok)
        if snTotL.iMov.is2D        
            % case is the 2D expt
            iGrpU = unique(pInfo.iGrp(:));
            snTotL.iMov.flyok = arrayfun(@(x)...
                            (flyok0(pInfo.iGrp==x)),iGrpU(iGrpU>0),'un',0);
                        
        elseif detIfCustomGrid(snTotL.iMov)
            % case is a 1D experiment (custom grid)
            gID = snTotL.iMov.pInfo.gID;
            nFly = arr2vec(snTotL.iMov.pInfo.nFly')';
            snTotL.iMov.flyok = arrayfun(@(n)(false(n,1)),nFly,'un',0);
                        
            % sets the acceptance flags for each grouping type
            for i = 1:length(gID)
                % determines the sub-grouping indices
                [gIDU,~,iC] = unique(gID{i});
                indC = arrayfun(@(x)(find(iC==x)),1:max(iC),'un',0);
                
                % sets the acceptance flags for each sub-grouping
                for j = 1:length(gIDU)
                    snTotL.iMov.flyok{gIDU(j)}(indC{j}) = true;
                end
            end
            
        else
            % case is a 1D experiment (fixed grid)
            nFly = pInfo.nFly;
            indG = arrayfun(@(x)(find(pInfo.iGrp==x)),1:pInfo.nGrp,'un',0);
            nFlyG = cellfun(@(x)(nFly(x)),indG,'un',0);

            % sets the final acceptance flags
            snTotL.iMov.flyok = cellfun(@(i,n)(cell2mat(arrayfun(@(ii,nn)...
                        (flyok0(1:nn,ii)),i,n,'un',0))),indG,nFlyG,'un',0);
        end
    end
end