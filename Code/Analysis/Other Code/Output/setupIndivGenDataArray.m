% --- sets up the general individual data array 
function Data = setupIndivGenDataArray(iData,Y,iOrder)

% ------------------------------------------- %
% --- INITIALISATIONS & MEMORY ALLOCATION --- %
% ------------------------------------------- %

% initialisations and memory allocation
appOut = iData.appOut(:,iData.cTab);
appName = iData.appName(appOut);
[nApp,Data] = deal(sum(appOut),cell(length(iOrder),1));

% sets the output type
YR = reduceDataArray(Y(iOrder),appOut);

% sets the global metric indices
mStrH = [{'Genotype';'Metric';'Fly #';''},repmat({''},4,1)];
Type = field2cell(iData.yVar,'Type',1); 
mIndG = find(Type(:,7));
mStrB = iData.fName(mIndG(iOrder));

% sets up the final data output array
for i = 1:length(YR)
    % memory allocation
    Data{i} = cell(1,nApp);
    mStrH{1,2} = mStrB{i};
    
    %
    for j = 1:nApp
        mStrH{2,2} = appName{j};
        Data{i}{j} = setIndivArrays(mStrH,YR{i}{j});
    end
    
    % combines the data array over each group
    Data{i} = cell2cell(Data{i},0);
end

% combines the individual arrays into a single array
Data = cell2cell(Data);

% removes any NaN values from the final data array
isN = find(cellfun(@isnumeric,Data));
iiFN = isN(cellfun(@isnan,Data(isN)));

% removes any NaN values and converted the integer/float values
kk = cellfun(@(x)(mod(x,1) == 0),Data(isN));
Data(isN(kk)) = num2strC(Data(isN(kk)),'%i');
Data(isN(~kk)) = num2strC(Data(isN(~kk)),'%.4f');
Data(iiFN) = {''};

% adds in a spacer row/column
Data = combineCellArrays(repmat({''},size(Data,1),1),Data);
Data = combineCellArrays(repmat({''},1,size(Data,2)),Data,0);

% --- 
function Data = setIndivArrays(mStrH,Y)

% memory allocation
Data = cell(length(Y),1);

%
for i = 1:length(Y)
    mStrH{3,2} = sprintf('%i',i);
    
    Data{i} = combineCellArrays(mStrH,Y{i},0);
    Data{i} = combineCellArrays(Data{i},{NaN});
    Data{i} = combineCellArrays(Data{i},{NaN},0);    
end

% combines the cell arrays into a single array
Data = cell2cell(Data,1);
%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- removes the apparatus groups that are not included
function YR = reduceDataArray(Y,appOut)

% memory allocation
YR = cell(1,length(Y));

% reduces the array for the selected groups
for i = 1:length(YR)
    YR{i} = Y{i}(appOut);
end