% --- sets up the spreadsheet data array with the top index, xInd,
%     corresponding to the main table data type. the other variables, given
%     in yInd, are the parameters the are given for each group. it is
%     assumed that all the variables are grouped by type/apparatus. the
%     table header strings are given in array hStr - each column represents
%     the variable string names for each group
function Acsv = setSheetDataArray(plotD,pData,isMetGrp,isDN,xInd,yInd)

% sets the default parameters (if not provided)
if (nargin < 4); isDN = false; end

% determines the independent/dependent variable indices
if (nargin < 5)    
    [xInd,yInd] = getOutputIndices(pData,'Metric');
elseif (~iscell(yInd))
    yInd = {yInd};
end

% combines the data for each of the metrics
Acsv = [];
for i = 1:length(xInd)
    if (~isempty(yInd{i}))
        AcsvNw = setSheetDataArraySub(...
                        plotD,pData,xInd(i),yInd{i},isMetGrp,isDN);
        Acsv = combineCellArrays(Acsv,AcsvNw);
    end
end

% --- sets the data for a given independent variable
function Acsv = setSheetDataArraySub(plotD,pData,xInd,yInd,isMetGrp,isDN)

% global variables
global x hasNA

% array indices
[nApp,nMet,oP,nDN,nOfs] = deal(length(plotD),length(yInd),pData.oP,1+isDN,0);
if (nApp == 1); isMetGrp = true; end

% sets the apparatus type name strings
if (isDN)
    % has day/night separation
    appName = cellfun(@(x,y)(sprintf('%s (%s)',x,y)),...
            repmat(pData.appName,1,2),repmat({'Day','Night'},...
            length(pData.appName),1),'un',0)';    
    appName = appName(:);
else
    % no day/night separation
    appName = pData.appName; 
end

% retrieves the independent variable data
switch (oP{xInd,2})
    case ('Type')
        nApp = length(pData.appName);
        [isMetGrp,Xnw,nOfs] = deal(true,[],1);
    otherwise
        % initialises the new values into the cell array
        Xnw = eval(sprintf('plotD.%s;',oP{xInd,2}));
end

% sets up the spreadsheet data array with the given fields       
if (isMetGrp)
    hStr = setHeaderGroupNames(oP(yInd,1),appName);    
else
    hStr = setHeaderGroupNames(appName,oP(yInd,1));    
end

% sets the horizontal appending flag (only do vertically if there are not a
% large number of values to be output)
[Xnw,isH] = deal(reshape(Xnw,length(Xnw),1),size(hStr{1},2)/length(Xnw)<3);

% sets the independent variable data column
if (isnumeric(Xnw)); Xnw = num2cell(Xnw); end
if (size(hStr{1},1) == 1)    
    % header row only has one row
    if (isempty(Xnw))
        Acsv0 = [];
    else
        Acsv0 = [pData.oP(xInd,1);Xnw];
    end
        
    nStp = 1; Pnw = cell(nStp,nMet,nApp*nDN);
else
    % header row has more than one row
    if (isempty(Xnw))
        [Acsv0,nStp] = deal([],1);                
    else
        Acsv0 = [{NaN};pData.oP(xInd,1);Xnw];
        nStp = size(Acsv0,1)-(2-nOfs); 
    end
        
    Pnw = cell(nStp,nMet,nApp*nDN);
end
    
% adds in a space column/row
if (~isempty(Xnw))
    Acsv0 = combineCellArrays(Acsv0,{NaN});
end

% retrieves the data for each of the dependent variables
isOK = true(1,nMet);
for i = 1:length(plotD)
    for j = 1:nMet
        % evaluates the new values
        Ynw = eval(sprintf('plotD(i).%s;',oP{yInd(j),2}));
        if (all(isnan(Ynw(:))))
            isOK(j) = false;
        else
            if (isnumeric(Ynw))
                % removes the NaN values from the array
                ii = isnan(Ynw);
                if (any(ii)); [Ynw(ii),hasNA] = deal(2*x,true); end

                % converts the numeric array to a cell array
                Ynw = num2cell(Ynw);
            end

            % sets the final values into the overall dependent variable array
            if (nDN == 1)
                if (length(plotD) == 1)
                    for k = 1:size(Ynw,2)
                        Pnw(:,j,k) = Ynw(:,k);        
                    end
                else
                    Pnw(:,j,i) = Ynw;        
                end
            else
                Pnw(:,j,(i-1)*nDN+(1:nDN)) = Ynw;        
            end
        end
    end    
end

% readjusts
if ((length(plotD) == 1) && (~isDN)); 
    nApp = length(pData.appName); 
end

% combines the sub-index data arrays to the main data array column
if (isMetGrp)
    % combines the new cell arrays by group type
    if (size(hStr{1},1) == 1)
        % header row only has one row
        AA = combineCellArrays(hStr{1},...
                    reshape(Pnw(:,isOK,:),[sum(isOK),nApp*nDN])',false);
        Acsv = combineCellArrays(Acsv0,AA);        
    else
        % header row has more than one row
        if (isH)        
            % data is being combine horizontally
            Acsv = Acsv0;
            for i = find(isOK)
                Anw = combineCellArrays(...
                        hStr{i},reshape(Pnw(:,i,:),nStp,nApp*nDN),0);                                                               
                Acsv = combineCellArrays(...
                        combineCellArrays(Acsv,Anw,isH),{NaN},isH);                
            end
        else
            % data is being combine vertically
            for i = find(isOK)
                % creates the new sub-data array
                AA = combineCellArrays(...
                            hStr{i},reshape(Pnw(:,i,:),nStp,nApp*nDN),0);                                               
                BB = combineCellArrays(Acsv0,AA);

                % appends the sub-data array to the total data array
                if (i == find(isOK,1,'first'))
                    % case is the first metric
                    Acsv = BB;
                else
                    % case is the other metrics
                    Acsv = combineCellArrays(...
                            combineCellArrays(Acsv,{NaN},isH),BB,isH);
                end
            end
        end
    end
else
    % combines the new cell arrays by variable
    if (size(hStr{1},1) == 1)
        % header row only has one row
        AA = combineCellArrays(hStr{1},...
                            reshape(Pnw(:,isOK,:),[sum(isOK),nApp])',0);
        Acsv = combineCellArrays(Acsv0,AA);
    else
        % header row has more than one row
        if (isH)
            % data is being combine horizontally
            Acsv = Acsv0;
            for i = 1:nApp*nDN
                % creates the new sub-data array
                Anw = combineCellArrays(hStr{i}(:,isOK),Pnw(:,isOK,i),0);
                Acsv = combineCellArrays(...
                                combineCellArrays(Acsv,Anw,isH),{NaN},isH);
            end
        else
            % data is being combine vertically
            for i = 1:nApp*nDN
                % creates the new sub-data array
                AA = combineCellArrays(Acsv0,combineCellArrays(...
                                        hStr{i}(:,isOK),Pnw(:,isOK,i),0));

                % appends the sub-data array to the total data array
                if (i == 1)
                    % case is the first group type
                    Acsv = AA;
                else
                    % case is the other group types
                    Acsv = combineCellArrays(...
                                combineCellArrays(Acsv,{NaN},isH),AA,isH);
                end
            end            
        end
    end    
end

% adds in a gap for the first row/column
Acsv = combineCellArrays({NaN},combineCellArrays({NaN},Acsv,0));