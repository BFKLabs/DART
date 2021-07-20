% --- groups the acceptance flags for a given experiment
function fok = groupAcceptFlags(snTot,varargin)

% field retrieval
[iMov,cID] = deal(snTot.iMov,snTot.cID);
[fok0,pInfo] = deal(iMov.flyok,iMov.pInfo);
sz = size(fok0);

% memory allocation
if iscell(fok0)
    fok = fok0;
    return
else
    nGrp = length(cID);
    fok = cell(1,nGrp);
end

% loops through each group type setting the acceptance flags
for i = 1:nGrp
    if ~isempty(cID{i})
        if iMov.is2D
            % case is a 2D expt setup
            fok{i} = fok0(sub2ind(sz,cID{i}(:,1),cID{i}(:,2)));
        else
            % case is a 1D expt setup            
            iReg = (cID{i}(:,1)-1)*pInfo.nCol + cID{i}(:,2);
            if nargin == 1
                % case is neglecting any rejected sub-regions
                fok{i} = fok0(sub2ind(sz,cID{i}(:,3),iReg));
            else
                % case is keeping all sub-regions
                iRegU = unique(iReg,'stable');
                [iCol,~,iRow] = getRegionIndices(iMov,iRegU);
                
                % appends the acceptance flags for the given region
                for j = 1:length(iCol)
                    nFlyNw = pInfo.nFly(iRow(j),iCol(j));
                    fok{i} = [fok{i};fok0(1:nFlyNw,iRegU(j))];
                end
            end
        end
    end
end

% ensures the arrays are logical arrays
fok = cellfun(@(x)(logical(x)),fok,'un',0);