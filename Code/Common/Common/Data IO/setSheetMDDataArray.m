% --- sets the csv multi-dimensional data array with the top index, xInd
%     corresponding to the main table data type. the other variables, given
%     in yInd, are the parameters the are given for each group. it is
%     assumed that all the variables are grouped by type/apparatus. the
%     table header strings are given in array hStr - each column represents
%     the variable string names for each group
function Acsv = setSheetMDDataArray(plotD,pData,isMetGrp,isDN,xInd,yInd)

% sets the default parameters (if not provided)
if (nargin < 4); isDN = false; end

% determines the independent/dependent variable indices
if (nargin < 5)    
    [xInd,yInd] = getOutputIndices(pData,'MetricMD');
else
    if (~iscell(yInd)); yInd = {yInd}; end
    if (~iscell(xInd)); xInd = {xInd}; end
end

% combines the data for each of the metrics
Acsv = [];
for i = 1:length(xInd)
    if (~isempty(yInd{i}))
        AcsvNw = setSheetMDDataArraySub(...
                            plotD,pData,xInd{i},yInd{i},isDN,isMetGrp);
        Acsv = combineCellArrays(Acsv,AcsvNw);
    end
end

% --- sets the data for a given independent variable
function Acsv = setSheetMDDataArraySub(plotD,pData,xInd,yInd,isDN,isMetGrp)

% global variables
global x hasNA

% array indices and initialisations
[pName,Acsv] = deal(pData.appName,[]);
[nApp,nMet,oP,nDN] = deal(length(plotD),length(yInd),pData.oP,1+isDN);

% retrieves the vertical independent variable values
xV = eval(sprintf('plotD.%s',oP{xInd(1),2}));
if (isnumeric(xV)); xV = num2cell(xV); end

% retrieves the horizontal independent variable values
xH = field2cell(plotD,oP{xInd(2),2});
nxH = cellfun(@length,xH);
for i = 1:length(xH)
    % ensures the numeric values are in a cell array
    if (isnumeric(xH{i}) || islogical(xH{i})); xH{i} = num2cell(xH{i}); end

    % if the day seperation is being used, then reset the horiztonal strings
    if (isDN)
        xH{i} = cellfun(@(x,y)(sprintf('%s (%s)',x,y)),...
                            repmat(xH{i}',2,1),repmat({'D';'N'},...
                            1,length(xH{i})),'un',0)';  
        xH{i} = reshape(xH{i}(:),1,2*nxH(i));
    end
end
    
% ensures the horizontal/vertical arrays are in the correct direction
[nH,imx] = max(nxH);
[xV,isH] = deal(reshape(xV,length(xV),1),nH/length(xV) < 3);
% isH = false;

% sets up the spreadsheet data array with the given fields   
if (isMetGrp)
    hStr = setHeaderGroupNames(pData.appName,xH{imx},'Sub-Group = ');     
else
    hStr = setHeaderGroupNames(oP(yInd,1),xH{imx},'Metric = ');    
end

% % reduces the header strings to only incorporate the flies that are present
% % for each of the groups
% hStr = cellfun(@(x,y)(x(:,1:y)),hStr,num2cell(nxH)','un',0);
    
% sets the header strings
Acsv0 = [num2cell(NaN(2,1));pData.oP(xInd(1),1);xV];
nStp = size(Acsv0,1)-3; Pnw = cell(nStp,nH,nMet,nApp);

% adds in a space column/row
Acsv0 = combineCellArrays(Acsv0,{NaN});

% retrieves the data for each of the dependent variables
for i = 1:nApp
    for j = 1:nMet
        % evaluates the new values
        Ynw = eval(sprintf('plotD(i).%s;',oP{yInd(j),2}));
        if (iscell(Ynw))
            for k = 1:nDN
                if (isnumeric(Ynw{k}))               
                    % removes the NaN values from the array
                    ii = isnan(Ynw{k});
                    if (any(ii)); [Ynw{k}(ii),hasNA] = deal(2*x,true); end

                    % converts the numeric array to a cell array
                    Ynw{k} = num2cell(Ynw{k});                    
                end
            end
        elseif (isnumeric(Ynw) || islogical(Ynw))
            % removes the NaN values from the array
            ii = isnan(Ynw);
            if (any(ii)); [Ynw(ii),hasNA] = deal(2*x,true); end

            % converts the numeric array to a cell array
            Ynw = {num2cell(double(Ynw))};
        end
        
        % sets the final values into the overall dependent variable array
        for k = 1:nDN
            Pnw(:,(k-1)*nxH(i)+(1:nxH(i)),j,i) = Ynw{k};        
        end
    end    
end

% combines the sub-index data arrays to the main data array column
if (isMetGrp)
    % sets the metrics for each of the apparatus
    % data is grouped by metric    
    for i = 1:nMet  
        for j = 1:nApp    
            % sets the indices for the current sub-group
            [jj,kk] = deal(1:nxH(j),1:(nDN*nxH(j)));                        

            % sets the new header  
            if (isH)                
                % appends the dependent variable
                if (j == 1)
                    AcsvNw = Acsv0;                     
                    pStrNw = {sprintf('Metric = %s',oP{yInd(i),1})};
                    hStrNw = combineCellArrays(pStrNw,hStr{j}(:,jj),0);                         
                else
                    hStrNw = combineCellArrays({NaN},hStr{j}(:,jj),0); 
                end                               
                
                % appends the new data to the overall data array
                Anw = combineCellArrays(...
                            hStrNw,reshape(Pnw(:,kk,i,j),nStp,nDN*nxH(j)),0);                                                               
                AcsvNw = combineCellArrays(combineCellArrays(AcsvNw,Anw),{NaN});                
            else
                % sets the new header                
                if (j == 1)
                    AcsvNw = [];
                    hStrNw = combineCellArrays(oP(yInd(i),1),hStr{j}(:,jj),0); 
                else
                    hStrNw = hStr{j}(:,jj);
                end

                % appends the new data to the overall data array
                Bnw = combineCellArrays(...
                            hStrNw,reshape(Pnw(:,kk,i,j),nStp,nxH(j)),0);                                                               
                Anw = combineCellArrays(Acsv0,Bnw);
                Anw = combineCellArrays(Anw,{NaN},0);
                
                % combines the the new data to the global array
                AcsvNw = combineCellArrays(AcsvNw,Anw,0);                                            
            end                        
        end
        
        % adds an additional column spacer
        Acsv = combineCellArrays(combineCellArrays(Acsv,AcsvNw,1),{NaN},1);                
    end
else
    for i = 1:nApp
        % sets the vertical data array
        [jj,kk] = deal(1:nxH(i),1:(nDN*nxH(i)));            
        % data is grouped by type
        for j = 1:nMet      
            if (isH)                  
                % sets the new header                    
                if (j == 1)
                    AcsvNw = Acsv0;  
                    pStrNw = {sprintf('Sub-Group = %s',pName{i})};
                    hStrNw = combineCellArrays(pStrNw,hStr{j}(:,jj),0);                    
                else
                    hStrNw = combineCellArrays({NaN},hStr{j}(:,jj),0);                
                end
                
                % appends the new data to the overall data array
                Anw = combineCellArrays(hStrNw,Pnw(:,kk,j,i),0);
                AcsvNw = combineCellArrays(combineCellArrays(AcsvNw,Anw),{NaN});
            else            
                % sets the new header
                if (j == 1)
                    AcsvNw = [];
                    hStrNw = combineCellArrays(pName(i),hStr{j}(:,jj),0);
                else
                    hStrNw = hStr{j}(:,jj);
                end              

                % appends the new data to the overall data array
                Bnw = combineCellArrays(hStrNw,Pnw(:,kk,j,i),0);
                Anw = combineCellArrays(Acsv0,Bnw);
                Anw = combineCellArrays(Anw,{NaN},0);
                
                % combines the the new data to the global array
                AcsvNw = combineCellArrays(AcsvNw,Anw,isH);                     
            end                                
        end
        
        % adds an additional column spacer
        Acsv = combineCellArrays(combineCellArrays(Acsv,AcsvNw,1),{NaN},1);         
        
%         % adds an additional column spacer
%         Acsv = combineCellArrays(Acsv,{NaN},isH);        
    end    
end
    
% adds in a gap for the first row/column
Acsv = combineCellArrays({NaN},combineCellArrays({NaN},Acsv,0));

