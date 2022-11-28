% --- set up the region data struct (for expt solution files packaged
%     within a multi-expt solution file - old file format)
%     this is required because the data for each group has been combined
%     and needs to be separated into its components
function A = getMultiRegionDataStructs(snTot)

% initialisations
[iMov,appPara] = deal(snTot.iMov,snTot.appPara);
A = struct('nRow',NaN,'nCol',NaN,'nGrp',NaN,'gName',[],'iGrp',[]); 

% sets the group names/counts
A.gName = appPara.Name;
A.nGrp = length(appPara.Name);

if iMov.is2D
    % sets the grid dimensions
    if iscell(iMov.iC{1})
        % calculates the number of columns (from the region dimensions)
        wPos = median(cellfun(@(x)(x(3)),iMov.pos));
        x0 = cellfun(@(x)(x(1)),cell2cell(iMov.iC));
        A.nCol = length(unique(cumsum([1;roundP(diff(sort(x0))/wPos)])));
        
        % case is the columns have been grouped
        hPos = median(cellfun(@(x)(x(4)),iMov.pos));
        y0 = sort(cellfun(@(x)(x(1)),cell2cell(iMov.iRT)));
        A.nRow = roundP(hPos/max(diff(y0)));
    else
        % case is columns are separated
        [A.nRow,A.nCol] = size(iMov.flyok);
    end
    
    % other initialisations
    sFac = snTot.sgP.sFac;    
    A.iGrp = zeros(A.nRow,A.nCol);  
    
    % loops through each of the groups 
    for i = 1:A.nGrp
        [Px,Py] = deal(snTot.Px{i}/sFac,snTot.Py{i}/sFac);
        for j = 1:size(Px,2)
            % determines which column the fly belongs to (if valid)
            if ~all(isnan(Px(:,j)))
                % calculates the mean x/y coordinates of the region
                xMx = roundP(0.5*(max(Px(:,j))+min(Px(:,j))));
                yMx0 = roundP(0.5*(max(Py(:,j))+min(Py(:,j))));
                
                % determines the grid column index
                if iscell(iMov.iC{1})
                    % case is the columns are combined (very old format)
                    iOfs = cumsum([0,cellfun('length',iMov.iC(2:end))]);
                    iColF = cellfun(@(x)(find(cellfun(@(y)...
                                (any(y==xMx)),x))),iMov.iC,'un',0);
                    
                    % sets the final column index
                    ii = ~cellfun('isempty',iColF);  
                    iCol = iColF{ii}+iOfs(ii);
                    
                else
                    % case is the columns are separated
                    iCol = find(cellfun(@(x)(any(x==xMx)),iMov.iC));
                end
                
                %
                if ~isempty(iCol)
                    % sets the grid row index
                    if iscell(iMov.iC{1})
                        % case is row groups are combined
                        yMx = yMx0 - iMov.iR{ii}{iColF{ii}}(1);
                        iRow = find(cellfun(@(x)...
                                    (any(x==yMx)),iMov.iRT{ii}),1,'first');
                    else
                        % case is row groups are separated
                        yMx = yMx0 - iMov.iR{iCol}(1);
                        iRow = cellfun(@(x)(any(x==yMx)),iMov.iRT{iCol});
                    end
                       
                    % sets the grouping index
                    A.iGrp(iRow,iCol) = i;
                end
            end
        end
    end
else      
    % case is a 1D experimental setup
    A.nFly = getSRCount(iMov);
    A.nFlyMx = max(A.nFly(:));       
    [A.nRow,A.nCol] = deal(iMov.nRow,iMov.nCol);
    
    % case is the region information is provided
    [~,~,iC] = unique(appPara.Name,'Stable');     
    A.iGrp = reshapeIndexArray(iC,[iMov.nRow,iMov.nCol]);
end