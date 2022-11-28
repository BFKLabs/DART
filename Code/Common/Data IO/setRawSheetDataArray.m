% --- sets the csv sheet data array for the raw data values given by the 
%     parameter index, ind --- %
function A = setRawSheetDataArray(plotD,pData,rStr,ind)

% sets the default variables
if (nargin < 3); rStr = 'Fly'; end
if (nargin < 4); ind = getOutputIndices(pData,'RawData'); end

% array indexing and memory allocation
[nExp,b] = deal(length(pData.sName),num2cell(NaN(2,1)));

% sets the raw data for each of the experiments
for iExpt = 1:nExp
    % calculates and appends the new experiments to the overall array      
    Anw = setupExptRawData(plotD,pData,ind,iExpt,rStr);    
    if (iExpt == 1)
        % first experiment, so set new data as current
        A = Anw;               
    else
        % otherwise, add new data to current
        A = combineCellArrays(combineCellArrays(A,b,0),Anw,0);
    end
end

% --- sets up the raw data for a single experiment index, iExpt --- %
function A = setupExptRawData(plotD,pData,ind,iExpt,rStr)

% array indexing and memory allocation
[nMet,b] = deal(length(ind),num2cell(NaN(1,2)));

% sets the raw data for each of the metrics
for iMet = 1:nMet
    % sets up the head string
    hStr = num2cell(NaN(2)); 
    hStr{1,2} = sprintf('Experiment Name = %s',pData.sName{iExpt});  
    
    % calculates and appends the new experiments to the overall array    
    Anw = setupMetricRawData(plotD,pData,iExpt,ind(iMet),rStr);
    Anw = combineCellArrays(hStr,Anw,0);  
    if (iMet == 1)
        % first experiment, so set new data as current
        A = Anw;               
    else
        % otherwise, add new data to current
        A = combineCellArrays(combineCellArrays(A,b),Anw);
    end
end

% adds a spacer row
A = combineCellArrays({NaN},combineCellArrays({NaN},A,0));

% --- sets up the raw data array for a single metric index, iMet, for a
%     given experiment index, iExpt --- %
function A = setupMetricRawData(plotD,pData,iExpt,iMet,rStr)

% initialisations
[nApp,oP,b] = deal(length(plotD),pData.oP,{NaN});
Tgrp = plotD(1).Tgrp';

% determines maximum number of flies
YY = field2cell(plotD,oP{iMet,2});
N = max(cellfun(@(x)(size(x{iExpt},1)),YY));
nDay = max(cellfun(@(x)(size(x{iExpt},2)),YY));

% sets the data arrays for each index
for i = 1:nApp
    % retrieves the new Y-values
    Ynw = eval(sprintf('plotD(i).%s(:,iExpt)',oP{iMet,2}));    
        
    if (pData.isAvg)
        % if there is missing data, then use a NaN arrays to replace them
        ii = cellfun('isempty',Ynw);
        if all(ii)
            % all values are missing, so set an empty array
            Y = repmat({'-----'},N,1);
        else
            % case is daily averaging the data. average the data an place
            % it into a single array    
            Ynw(cellfun('isempty',Ynw)) = {NaN(N,1)};
            Y = num2cell(combineNumericCells(cellfun(@(x)(...
                                mean(x,2,'omitnan')),Ynw,'un',0)'));
        end
                            
        % sets the header string
        Bnw = [Tgrp;Y];   
        hStr = {sprintf('Metric = %s',oP{iMet,1});...
                sprintf('%s',pData.appName{i});''};
        Anw = combineCellArrays(hStr,Bnw,false);
        
        % sets the fly strings
        if (i == 1)
            % sets the fly index strings and initialises the final array
            fStr = [repmat(b,length(hStr)+1,1);...
                    cellfun(@(x)(sprintf('%s #%i',rStr,x)),...
                    num2cell(1:N)','un',0)];                            
            A = combineCellArrays(combineCellArrays(fStr,Anw),b);            
        else
            % appends the new data to the final array 
            A = combineCellArrays(A,combineCellArrays(fStr,Anw));
            A = combineCellArrays(A,b);            
        end                                                                
    else        
        % sets the day header strings   
        if (i == 1)
            dStr = cellfun(@(x)(sprintf('Day #%i',x)),num2cell(1:nDay),'un',0);
        end
                
        % case is outputting all the raw data
        for j = 1:length(Tgrp)
            % if no data, then set an empty array
            if (isempty(Ynw{j}))
                Anw = combineCellArrays(dStr,repmat({'-----'},N,nDay),0);            
            else
                % sets the new data values into an array
                Anw = combineCellArrays(dStr,num2cell(Ynw{j}),0);            
            end
            
            % sets the head string
            if (j == 1)
                % first time group
                hStr = {sprintf('Metric = %s',oP{iMet,1});...
                        sprintf('%s',pData.appName{i});...
                        sprintf('Time Group = %s',Tgrp{j});''};    
                fStr = [repmat(b,length(hStr)+1,1);...
                        cellfun(@(x)(sprintf('%s #%i',rStr,x)),...
                        num2cell(1:N)','un',0)];    
                    
                Anw = combineCellArrays(hStr,Anw,0);
                Anw = combineCellArrays(combineCellArrays(fStr,Anw),b); 
                
                if (i == 1)
                    A = Anw;
                else
                    A = combineCellArrays(A,Anw);
                end
            else
                % other time groups
                hStr = {'';'';sprintf('Time Group = %s',Tgrp{j});''};        
                
                Anw = combineCellArrays(hStr,Anw,0);
                A = combineCellArrays(A,combineCellArrays(fStr,Anw)); 
                A = combineCellArrays(A,b); 
            end
        end                   
    end
end
