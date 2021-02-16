% --- function that sets up the 2D data arrays for the csv output
function Acsv = setSheet2DDataArray(plotD,pData)

% determines the metrics that are 
[ii,Acsv] = deal(cellfun(@isnan,pData.oP(:,3)),[]);
[pName,pStr] = deal(pData.oP(ii,1),pData.oP(ii,2));

% sets the csv data sheet array for the 2D arrays
for i = 1:length(pName)
    % retrieves the data from the plotting data struct
    Z = field2cell(plotD,pStr{1});
    if (iscell(Z{1}))
        [X,Y] = deal(1:size(Z{1}{1},2),(1:size(Z{1}{1},1))');
    else
        [X,Y] = deal(1:size(Z{1},2),(1:size(Z{1},1))');
    end
    
    % sets up the data array for the current metric
    for j = 1:length(Z)
        % initialisations
        [hStr,yStr] = deal(cell(2),[]);
        hStr(1,:) = {'Name',pData.appName{j}};
        
        % sets the data strings for each fly
        if (iscell(Z{j}))
            % case is an individual metric
            for k = 1:length(Z{j})            
                fIndex = {sprintf('Fly #%i',k)};
                yStrNw = [[fIndex,num2cell(X)];[num2cell(Y),num2cell(Z{j}{k})]];
                yStr = combineCellArrays(combineCellArrays(yStr,yStrNw,0),{NaN},0);
            end            
        else
            % case is a population metric
            yStr = [[{''},num2cell(X)];[num2cell(Y),num2cell(Z{j})]];
        end
        
        % appends the new data to the total output array 
        Anw = combineCellArrays(hStr,yStr,0);
        Acsv = combineCellArrays(combineCellArrays(Acsv,Anw),{NaN});
    end
end
