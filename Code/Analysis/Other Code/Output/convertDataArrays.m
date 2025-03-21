% --- converts the data array fields so that they match the original
%     data array dimensioning
function snTot = convertDataArrays(snTot)

% initialisations
cID = snTot.cID;
iMov = snTot.iMov;
pInfo = iMov.pInfo;
isMT = detMltTrkStatus(iMov);

% sets any missing flags
if ~isfield(iMov,'calcPhi')
    [snTot.iMov.calcPhi,iMov.calcPhi] = deal(false);
end

% determines the number of frames
i0 = find(~cellfun('isempty',snTot.Px),1,'first');
if isempty(i0)
    return
else
    nFrm = size(snTot.Px{i0},1);
end

% sets the data array fields to 
pFld = {'Px'};
if iMov.is2D || isMT || ~isempty(snTot.Py)
    pFld = [pFld,{'Py'}]; 
    if iMov.calcPhi
        pFld = [pFld,{'Phi','AxR'}]; 
    end
end

% converts data arrays (for all the specified fields
for i = 1:length(pFld)
    % retrieves the struct field
    if isfield(snTot,pFld{i})
        Z0 = getStructField(snTot,pFld{i});

        % converts the data arrays based on the type
        if isMT
            % case is a multi-tracking experiment setup
            Zf = arrayfun(@(x)(NaN(nFrm,x)),pInfo.nFly,'un',0);
            for j = 1:length(cID)
                for k = 1:size(cID{j},1)
                    [iReg,iFly] = deal(cID{j}(k,1),cID{j}(k,2));
                    [iC,iR] = ind2sub(size(Zf),iReg);
                    Zf{iR,iC}(:,iFly) = Z0{j}(:,k);
                end
            end
        
        elseif iMov.is2D
            % case is the 2D experimental setup        
            Zf = repmat({NaN(nFrm,pInfo.nRow)},1,pInfo.nCol);        
            for j = 1:length(cID)            
                for k = 1:size(cID{j},1)
                    [iRow,iCol] = deal(cID{j}(k,1),cID{j}(k,2));
                    Zf{iCol}(:,iRow) = Z0{j}(:,k);
                end
            end
            
        elseif detIfCustomGrid(iMov)
            % case is the 1D custom grid experimental setup
            nFly = arr2vec(iMov.pInfo.nFly')';
            Zf = arrayfun(@(x)(NaN(nFrm,x)),nFly,'un',0);
            
            % splits the metric between regions
            for j = 1:length(cID)
                % if the ID array is empty, then continue
                if isempty(cID{j})                
                    continue
                end
                
                % determines the unique region indices for the group
                iApp = (cID{j}(:,1)-1)*pInfo.nCol + cID{j}(:,2);
                [iAppU,~,iC] = unique(iApp,'stable');
                indC = arrayfun(@(x)(find(iC == x)),1:max(iC),'un',0);
                
                % sets the indices for each grouping
                for k = 1:length(iAppU)
                    iColZ = cID{j}(indC{k},3);
                    Zf{iAppU(k)}(:,iColZ) = Z0{j}(:,indC{k});
                end
            end
            
            % resets the solution struct field   
            snTot = setStructField(snTot,pFld{i},Zf);            
            
        else
            % case is the 1D fixed grid experimental setup

            % allocates memory for each region 
            Zf = cell(1,iMov.nRow*iMov.nCol);
%             nFly = arr2vec(pInfo.nFly');
%             nFly(isnan(nFly)) = 0;
%             Zf = arrayfun(@(n)(NaN(nFrm,n)),nFly,'un',0);

            % sets the data values for each grouping
            for j = 1:length(cID)
                % if the ID array is empty, then continue                
                if isempty(cID{j})
                    continue
                end
                    
                % strips out the data values as given in the
                iApp = (cID{j}(:,1)-1)*pInfo.nCol + cID{j}(:,2);
                
                % calculates the total number of flies (over the unique
                % regions within this grouping)
                [iAppU,~,iC] = unique(iApp,'stable');
                nFlyU = arrayfun(@(x)(max(cID{j}(iApp==x,3))),iAppU);
                if length(pInfo.nFly) == 1
                    nFlyU = max(nFlyU(:),arr2vec(pInfo.nFly));
                else
                    nFlyU = max(nFlyU(:),arr2vec(pInfo.nFly(iAppU)));
                end
                
                % memory allocation
                nFlyT = sum(nFlyU);
                for k = 1:length(iAppU)
                    Zf{iAppU(k)} = NaN(nFrm,nFlyU(k));
                end
                
                for k = 1:size(cID{j},1)
                    % sets the new configuration index
                    kk = cID{j}(k,3);
                    if size(Z0{j},2) == nFlyT
                        % if the final and original data arrays are the
                        % same then retrieve the corresponding values
                        kkG = sum(nFlyU(1:(iC(k)-1)))+kk;
                        Zf{iApp(k)}(:,kk) = Z0{j}(:,kkG);
                    else
                        % otherwise, work through each column of the
                        % original index setting the linked final value
                        Zf{iApp(k)}(:,kk) = Z0{j}(:,k);
                    end
                end
            end
            
        end   

        % resets the solution struct field   
        snTot = setStructField(snTot,pFld{i},Zf);
    end
end