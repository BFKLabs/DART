% --- creates the svm classifier from the classifier data files
function [svm,X,Grp] = createSVMClassifier()

% clears the screen
clc

% ------------------------------------------- %
% --- INITIALISATIONS & MEMORY ALLOCATION --- %
% ------------------------------------------- %

% initialisations
[iMet,svm,X,Grp] = deal(5:12,[],[],[]);

% prompts the user for the solution files
sFile = DirTree({'.xlsx'},pwd);
pause(0.05);

% if the user cancelled, then exit the function
if (isempty(sFile))    
    outputProgress('User Cancelled. Exiting Function...',1)
    return
end

% memory allocation
[xSVM,N,indM] = deal(cell(length(sFile),1));

% ----------------------------- %
% --- SOLUTION FILE READING --- %
% ----------------------------- %

% outputs the progress header
outputProgress('READING SOLUTION FILES',0)

% loads the data from each of the .xlsx files
for i = 1:length(sFile)
    % initialisations
    [iSheet,xlsD] = deal(1,[]);    
    
    % outputs the current file name to screen
    [~,sName] = fileparts(sFile{i});
    outputProgress(sprintf('Retrieving Expt #%i From "%s"',i,sName),1)
    
    % attempts to read all of the sheets within the spreadsheet
    while (1)        
        try
            % reads the data from the current sheet
            fprintf('   * Reading Sheet #%i',iSheet);
            [~,~,xlsD{end+1}] = xlsread(sFile{i},iSheet);  
            fprintf(' - Success!\n');
            
            % increments the sheet index counter
            iSheet = iSheet + 1;
        catch ME
            % if there are no more worksheets then exit the loop
            if strcmp(ME.identifier,'MATLAB:xlsread:WorksheetNotFound')
                fprintf(' - No More Worksheets...\n');
                break
            end
        end
    end
    
    % outputs the current file name to screen
    outputProgress('Separating Metric Data...',2)    
    if (i < length(sFile)); fprintf('\n'); end
    
    % memory allocation
    [xSVM{i},N{i},indM{i}] = deal(cell(length(xlsD),1));
    for j = 1:length(xlsD)    
        % retrieves the data from the data file
        [xSVM{i}{j},N{i}{j},indM{i}{j}] = getMetricData(xlsD{j},i,j);           
    end    
end

% de
[A,indM] = deal(cell2mat(cell2cell(xSVM)),cell2mat(cell2cell(indM)));

% determines if there are any events that haven't been classified
isN = A(:,2) == -1;
if (any(isN))
    % if so, then output the classifier results 
    fprintf('\n');
    outputProgress('Following Events Missing Classification...',1)                
    outputClassifierResults(indM(isN,:));

    % removes the fields that haven't been classified
    [A,indM] = deal(A(~isN,:),indM(~isN,:));
    
    % if there are no valid values, then exit the function
    if (isempty(A))
        fprintf('\n');
        outputProgress('No Valid Values For SVM Classification. Exiting Function...',1)
        return
    end
end

% ----------------------------------- %
% --- SVM CLASSIFIER CALCULATIONS --- %
% ----------------------------------- %

% outputs the progress header
outputProgress('SVM CLASSIFIER CALCULATION',0)

% sets the classification data and group index arrays
[Xa,GrpA] = deal(zeros(1,length(iMet)),0);
[X,Grp] = deal([A(:,iMet);Xa],[A(:,1);GrpA]);

% creates the svm classifier model
svm = fitcsvm(X,Grp,'KernelFunction','rbf','Standardize',false,...
                    'BoxConstraint',7.5,'KernelScale',0.5); 
                
% determines the performance of the classifier                
[P,S] = predict(svm,X); 
[Pmn,ix] = deal(mean(P==Grp),find(P~=Grp));

% outputs the classifier results                
outputProgress('Incorrectly Classified Events',1)                
outputClassifierResults(indM(ix,:),Grp,Pmn);

% --- outputs the classifier results to screen
function outputClassifierResults(indM,Grp,Pmn)

% sets the type strings
tStr = {'Expt','Video','Fly','Region','Event','Type','Start','Finish'};

% determines maximum string length
nStr = max(cellfun(@length,tStr)) + 2;

% converts the index values to string
aStr = cellfun(@(x)(cellfun(@num2str,...
                    num2cell(x),'un',0)),num2cell(indM,2),'un',0);
                
% sets the output strings for the table header 
[nn,b] = deal(length(tStr)*(nStr+1)+1,cell(4+length(aStr),1));
b([1 3 end]) = {repmat('*',1,nn)};
b{2} = setOutputString(tStr,nStr,0);

% sets the output strings for the anomalous frames
for i = 1:length(aStr)
    b{i+3} = setOutputString(aStr{i},nStr,1);
end

% outputs the anomalous frame information
fprintf('\n');
for i = 1:length(b)
    fprintf('  %s\n',b{i});
end

% outputs the other performance metrics
if (nargin > 1)
    fprintf('\n => Number of Likely Events = %i\n',length(Grp));
    fprintf(' => Number of True Seizure Events = %i\n',sum(Grp==1));
    fprintf(' => Number of Incorrectly Classified Events = %i\n',length(aStr));
    fprintf(' => Classifier Performance = %.2f%s\n\n',100*Pmn,char(37));
end

% --- 
function outStr = setOutputString(sStr,nStr,isRJ)

% initialisations
outStr = '*'; 

% combines all of the strings into a single string
for i = 1:length(sStr)
    % determines the pre/post string gap lengths
    nNw = length(sStr{i}); 
    if (isRJ)
        g2 = 1;
        g1 = nStr - (nNw+g2);
    else
        g1 = ceil((nStr-nNw)/2); 
        g2 = nStr - (nNw+g1); 
    end
    
    % combines the new string to the output string
    cNw = sprintf('%s%s%s*',repmat(' ',1,g1),sStr{i},repmat(' ',1,g2)); 
    outStr = strcat(outStr,cNw); 
end

% --- separates the metric data from the worksheet
function [A,NN,indM] = getMetricData(xlsD0,iFile,iSheet)

% reads the data values from file
xlsD = xlsD0(4:end,1:find(~all(cellfun(@(x)(isnan(x(1))),xlsD0),1),1,'last'));

% determines the data sheet spacing 
N = detDataSpacing(xlsD);

% retrieves the fly strings
fStr = xlsD0(2,1:N:size(xlsD0,2));
fStr = fStr(cellfun(@ischar,fStr));

% determines the number of rows/columns from the data sheet
[nRow,nFly] = deal(length(unique(fStr)),length(fStr));
nCol = nFly/nRow;

% memory allocation
NN = zeros(nRow,nCol);
[A,indM] = deal(cell(nFly,1));

% retrieves the data for each of the fly
for i = 1:nFly
    % sets the sub-array for the current fly
    [iApp,iFly] = deal(floor((i-1)/nRow)+1,mod(i-1,nRow)+1);
    Asub = xlsD(:,(i-1)*N + (1:(N-1)));
    
    
    % removes the NaN rows
    eRow = (find(cellfun(@(x)(isnan(x(1))),Asub(:,1)),1,'first')-1);
    if (isempty(eRow)); eRow = size(Asub,1); end
    A{i} = Asub(1:eRow,:);
    
    % reset the acceptance/rejection flags to 1/0 values
    ii = cellfun(@(x)(strcmp(x(1),'Y')),A{i}(:,2));
    jj = cellfun(@(x)(strcmp(x(1),'N')),A{i}(:,2));
    kk = ~(ii | jj);
    [A{i}(ii,2),A{i}(jj,2),A{i}(kk,2)] = deal({1},{0},{-1});
    
    % converts the cell array to a numerical one
    A{i} = cell2mat(A{i});
    NN(i) = size(A{i},1);
    
    % sets the index arrays
    if (NN(i) > 0)
        [a,b] = deal(ones(size(A{i},1),1),(1:size(A{i},1))');
        indM{i} = [iFile*a,iSheet*a,iFly*a,iApp*a,b,A{i}(:,2:4)];
    end
end

% converts the data for each of the flies into a single array
[A,indM] = deal(cell2mat(A),cell2mat(indM));

% --- determines the gap spacing
function N = detDataSpacing(xlsD)

%
isN = cellfun(@(x)(isnan(x(1))),xlsD(1,:));

%
N = 1;
while (1)
    ii = N:N:length(isN);
    if (all(isN(ii)))
        break
    else
        N = N + 1;
    end
end

% --- outputs the progress string
function outputProgress(outStr,Type)

% sets the display string based on the type
switch (Type)
    case (0) % case is a header string
        a = repmat('*',1,length(outStr)+4);
        dispStr = sprintf('\n%s\n* %s *\n%s\n',a,outStr,a);
    case (1) % case is a sub-header string
        dispStr = sprintf(' => %s',outStr);
    case (2) % case is a sub-sub-header string
        dispStr = sprintf('   * %s',outStr);        
end

% outputs the string
fprintf('%s\n',dispStr);