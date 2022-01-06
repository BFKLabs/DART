% --- retrieves the 1D/2D experiment data structs
function [D1,D2] = getRegionDataStructs(iMov,appPara)

% initialisations
[D1,D2] = deal([]);
is2D = is2DCheck(iMov);
isNewFormat = isfield(iMov,'pInfo');

if isfield(iMov,'is2D')
    is2D = iMov.is2D;
else
    is2D = is2DCheck(iMov);
end
    
% determines if the variable sub-region count has been set
if isfield(iMov,'nTubeR')
    hasNTube = ~isempty(iMov.nTubeR);
else
    hasNTube = false;
end

% update the grouping fields (based on the format of iMov)
if isNewFormat
    % case is the new format
    A = iMov.pInfo; 
else
    % case is the old format
    A = struct('nRow',NaN,'nCol',NaN,'nGrp',NaN,'gName',[],'iGrp',[]);    
    
    % sets the grouping indices
    if exist('appPara','var')
        % case is the region information is provided
        ii = ~cellfun(@isempty,appPara.Name);
        [gNameU,~,iC] = unique(appPara.Name(ii),'Stable');
        
        % sets the group indices
        if is2D
            % case is a 2D experimental setup
            A.iGrp = zeros(size(appPara.flyok));
            for i = 1:iMov.nRow
                for j = 1:iMov.nCol
                    % sets the global index and row indices
                    k = (i-1)*iMov.nCol + j;
                    iR = (i-1)*iMov.nTube + (1:iMov.nTube);
                    
                    % sets the group values
                    A.iGrp(iR,j) = iC(k);
                end
            end
        else           
            % case is a 1D experimental setup
            A.iGrp = reshapeIndexArray(iC,[iMov.nRow,iMov.nCol]);
        end
        
        % retrieves the group names and 
        [A.gName,A.nGrp] = deal(appPara.Name,length(gNameU));
    
    elseif hasNTube
        % initialisations
        szG = [iMov.nRow,iMov.nCol];
        
        % sets the grouping indices
        if is2D
            % case is a 2D setup
            nTubeR = reshapeIndexArray(iMov.nTubeR,szG);
            A.iGrp = zeros(iMov.nTube*iMov.nRow,iMov.nCol);
            
            % sets up the grouping based on the sub-region counts
            for i = 1:size(nTubeR,1)            
                for j = 1:size(nTubeR,2)                
                    iOfs = sum(max(nTubeR(1:(i-1),:),[],2));
                    A.iGrp(iOfs + (1:nTubeR(i,j)),j) = j;
                end
            end            
        else
            % case is a 1D setup            
            A.iGrp = reshapeIndexArray(1:prod(szG),szG);
        end        
        
    else
        % otherwise, setup the grouping indices based on other fields
        if is2D
            A.iGrp = double(iMov.flyok);
        else
            A.iGrp = double(reshape(any(iMov.flyok,1),iMov.nRow,iMov.nCol));
        end
    end   
    
    % sets the group names (if not already set)
    if isempty(A.gName)
        % sets the unique grouping numbers
        if is2D
            % case is the 2D setup
            iGrpN = unique(A.iGrp(:));
        else
            % case is the 1D setup
            iGrpN = arr2vec(A.iGrp');
        end
        
        % sets the group names and counts
        A.gName = arrayfun(@(x)(sprintf('Region #%i',x)),iGrpN,'un',0);
        A.nGrp = length(unique(iGrpN));        
    end
end

% updates up the data struct (based on the setup type)
if is2D
    % case is a 2D setup
    D2 = A;
    
    % updates the remaining fields (old format only) 
    if ~isNewFormat
        % sets the grouping type to grid based grouping
        D2.gType = 1;
        
        % sets the grid/grouping row/column counts
%         if hasNTube
%             % case is the sub-region counts have been set
%             D2.nCol = size(iMov.nCol,2);
%             D2.nRow = max(sum(iMov.nTubeR,1));
%             [D2.nRowG,D2.nColG] = size(iMov.nTubeR);
%             
%         else
            % otherwise, use the other dimensions to estimate
            D2.nRowG = iMov.nRow;
            D2.nRow = D2.nRowG*iMov.nTube;
            [D2.nCol,D2.nColG] = deal(iMov.nCol);            
%         end
    end   
    
    % if only one output, swap the variables
    if nargout == 1, D1 = D2; end
    
else
    % case is a 1D setup
    D1 = A;
    
    % sets the other fields    
    D1.nFly = getSRCount(iMov);
    D1.nFlyMx = max(D1.nFly(:));       
    [D1.nRow,D1.nCol] = deal(iMov.nRow,iMov.nCol);
    
    % for all rejected regions, then remove these values
    for i = find(~iMov.ok)'        
        [iCol,~,iRow] = getRegionIndices(iMov,i);
        [D1.iGrp(iRow,iCol),D1.nFly(iRow,iCol)] = deal(0,NaN);
    end
end
