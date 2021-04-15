% --- sets up the general population data array
function Data = setupPopGenDataArray(iData,Y,iOrder)

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
mStrH = [{'Genotype';'Metric';''},repmat({''},3,1)];
Type = field2cell(iData.yVar,'Type',1); 
mIndG = find(Type(:,6));
mStrB = iData.fName(mIndG(iOrder));

% sets up the final data output array
for i = 1:length(YR)
    % memory allocation
    Data{i} = cell(1,nApp);
    mStrH{1,2} = mStrB{i};
    
    % sets the data values for each group
    for j = 1:nApp        
        mStrH{2,2} = appName{j};
        Data{i}{j} = combineCellArrays(mStrH,YR{i}{j},0);
        Data{i}{j} = combineCellArrays(Data{i}{j},{NaN});
        Data{i}{j} = combineCellArrays(Data{i}{j},{NaN},0);
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