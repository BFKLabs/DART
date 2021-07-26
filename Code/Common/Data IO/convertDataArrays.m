% --- converts the data array fields so that they match the original
%     data array dimensioning
function snTot = convertDataArrays(snTot)

% initialisations
cID = snTot.cID;
iMov = snTot.iMov;
pInfo = iMov.pInfo;

% determines the number of frames
i0 = find(~cellfun(@isempty,snTot.Px),1,'first');
nFrm = size(snTot.Px{i0},1);

% sets the data array fields to 
pFld = {'Px'};
if iMov.is2D
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
        if iMov.is2D
            % case is the 2D experimental setup        
            Zf = repmat({NaN(nFrm,pInfo.nRow)},1,pInfo.nCol);        
            for j = 1:length(cID)            
                for k = 1:size(cID{j},1)
                    [iRow,iCol] = deal(cID{j}(k,1),cID{j}(k,2));
                    Zf{iCol}(:,iRow) = Z0{j}(:,k);
                end
            end                

        else
            % case is the 1D experimental setup

            % allocates memory for each region  
            nFly = arr2vec(pInfo.nFly');
            nFly(isnan(nFly)) = 0;
            Zf = arrayfun(@(n)(NaN(nFrm,n)),nFly,'un',0);

            % sets the data values for each grouping
            for j = 1:length(cID)
                if ~isempty(cID{j})
                    % strips out the data values as given in the 
                    iApp = (cID{j}(:,1)-1)*pInfo.nCol + cID{j}(:,2); 
                    
                    % calculates the total number of flies (over the unique
                    % regions within this grouping)
                    [iAppU,~,iC] = unique(iApp,'stable'); 
                    nFlyU = nFly(iAppU);
                    nFlyT = sum(nFlyU);
                    
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
            
        end   

        % resets the solution struct field   
        snTot = setStructField(snTot,pFld{i},Zf);
    end
end