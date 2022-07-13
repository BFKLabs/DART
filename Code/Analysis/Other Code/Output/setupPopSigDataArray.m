% --- sets up the individual signal data array
function [Data,DataN] = setupPopSigDataArray(handles,pData,iData,Y,iOrder)

% ------------------------------------------- %
% --- INITIALISATIONS & MEMORY ALLOCATION --- %
% ------------------------------------------- %

% initialisations 
appOut = iData.appOut(:,iData.cTab);
numGrp = getCheckValue(handles.checkNumGroups);
appName = iData.appName(appOut);
plotD = getappdata(handles.figDataOutput,'plotD');
nApp = sum(appOut);

% sets the output time values (if any)
[timeStr,tMlt,tRnd] = getOutputTimeValues(handles.popupUnits);

% sets the output type
% = 1 - all days/experiments combined
% = 2 - all day/individual experiment
% = 3 - individual day/all experiments
% = 4 - individual days/experiments 
YR = reduceDataArray(Y(iOrder),appOut);

% sets the global metric indices
mStrH = {'Genotype';'Metric';'Group';'Sub-Group';'';''};
Type = field2cell(iData.yVar,'Type',1); 
mIndG = find(Type(:,4));
mStrB = iData.fName(mIndG(iOrder));

%
[X1,X2,tStr,mStrT] = deal(cell(length(iOrder),1));
xVar = field2cell(pData.oP.xVar,'Var');

% --------------------------------- %
% --- TABLE HEADER STRING SETUP --- %
% --------------------------------- %

%
for j = 1:length(iOrder)
    %
    k = mIndG(iOrder(j));
    xDep = iData.yVar(k).xDep;
    indH = [true(1,2),(length(xDep)>1),(length(xDep)>2),true(1,2)];

    % retrieves the dimensions of the data array
    for i = 1:2
        if (indH(i+2))
            eval(sprintf('X%i{j} = plotD(1).%s;',i,xDep{1+i}));
        end
    end

    % retrieves the time unit string/multiplier
    if ~isnan(tMlt)
        tStr{j} = sprintf('Time %s',timeStr); 
    else        
        xDepS = cellfun(@(x)(x{1}),field2cell(pData.oP.yVar(mIndG),'xDep'),'un',0);
        tStr = cellfun(@(x)(pData.oP.xVar(strcmp(x,xVar)).Name),xDepS,'un',0);
    end
    
    %
    mStrS = setupSignalHeader(X1{j},X2{j},numGrp);
    mStrT{j} = combineCellArrays(mStrH(indH),mStrS);
end
    
% ------------------------------- %
% --- SIGNAL DATA ARRAY SETUP --- %
% ------------------------------- %

% memory allocation
[DataF,iiT] = deal(cell(1,length(YR)));

% sets the signal 
for i = 1:length(YR)
    % sets the metric header string
    mStrT{i}{2,2} = mStrB{i};
    mStrT{i}{end,1} = tStr{i};
    
    % sets the data for each of the genotype groups
    DataF{i} = repmat(mStrT(i),1,nApp);
    iiT{i} = repmat({false(size(mStrT{i}))},1,nApp);
    for j = 1:nApp
        % applies the time multiplier (if valid)
        YRnw = YR{i}{j};
        if (~isnan(tMlt))
            if (iscell(YRnw(:,1)))
                YRnw(:,1) = cellfun(@(x)(x*tMlt),YRnw(:,1),'un',0);
            else
                YRnw(:,1) = YRnw(:,1)*tMlt;
            end
        end
        
        % sets the data for the group
        DataF{i}{j}{1,2} = appName{j};
        if (iscell(YRnw))
            DataF{i}{j} = combineCellArrays(DataF{i}{j},YRnw,0);
        else
            DataF{i}{j} = combineCellArrays(DataF{i}{j},num2cell(YRnw),0);
        end
        
        % sets the time strings
        [m,n] = size(YR{i}{j});
        iiT{i}{j} = [iiT{i}{j};[true(m,1),false(m,n)]];
        
        %
        
    end

    %
    iiT{i}(1:(end-1)) = cellfun(@(x)(x(:,1:end-1)),iiT{i}(1:(end-1)),'un',0);
    iiT{i}(2:end) = cellfun(@(x)(x(:,2:end)),iiT{i}(2:end),'un',0);    
    
    %
    DataF{i}(1:(end-1)) = cellfun(@(x)(x(:,1:end-1)),DataF{i}(1:(end-1)),'un',0);
    DataF{i}(2:end) = cellfun(@(x)(x(:,2:end)),DataF{i}(2:end),'un',0);
    
    % combines the data over all genotype groups
    DataF{i} = cell2cell(DataF{i},0);
    iiT{i} = logical(cell2cell(iiT{i},0));
end

% ------------------------- %
% --- FINAL ARRAY SETUP --- %
% ------------------------- %

% sets the final data into a single array
[Data,DataN] = deal(cell2cell(DataF,0));
clear DataF; pause(0.05);

% converts the time signals to strings
if ~isnan(tRnd)
    iiT = logical(cell2cell(iiT,0));
    switch (tRnd)
        case (1)
            Data(iiT) = num2strC(Data(iiT),'%i');
        case (0.1)
            Data(iiT) = num2strC(Data(iiT),'%.1f');
        otherwise
            Data(iiT) = num2strC(Data(iiT),'%.4f');
    end
else
    iiT = false(size(Data));
end

% combines the full data array
isN = cellfun(@isnumeric,Data);
iiF = find(isN & (~iiT));
iiFN = iiF(cellfun(@isnan,Data(iiF)));
    
% converts the numerical values to strings
Data(iiF) = num2strC(cell2mat(Data(iiF)),'%.4f');
Data(iiFN) = {''};

% reshapes the data arrays
a = repmat({''},1,size(Data,2));
Data = combineCellArrays(a,Data,0);
Data = combineCellArrays(Data,a,0);

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- removes the apparatus groups that are not included
function YR = reduceDataArray(Y,indOut)

% memory allocation
YR = cell(1,length(Y));

% resets the arrays
for i = 1:length(Y)
    YR{i} = Y{i}(indOut);
end

% --- sets up the signal header
function mStrT = setupSignalHeader(X1,X2,numGrp)

% initialisations
[mStr1,mStr2] = deal([]);
[hasX1,hasX2] = deal(~isempty(X1),~isempty(X2));

%
if (hasX1)
    % sets the number of group parameters
    xi1 = 1:length(X1);    
    if (hasX2)
        xi1 = repmat(xi1(:),1,length(X2))';
    end
    
    % sets the group header based on whether numbers are used or not
    if (numGrp)
        % group numbering is used
        mStr1 = num2strC(xi1(:)','%i',1);
    else
        % group names is used
        mStr1 = cellfun(@(x)(X1{x}),num2cell(xi1(:)'),'un',0);
    end
end

%
if (hasX2)
    % sets the number of group parameters
    xi2 = 1:length(X2);    
    if (hasX1)
        xi2 = repmat(xi2(:)',length(X1),1)';
    end
    
    % sets the group header based on whether numbers are used or not
    if (numGrp)
        % group numbering is used
        mStr2 = num2strC(xi2(:)','%i',1);
    else
        % group names is used
        mStr2 = cellfun(@(x)(X2{x}),num2cell(xi2(:)'),'un',0);
    end
end

%
if (~((hasX2) || (hasX1)))
    mStrT = num2cell(NaN(1,2));
else
    A = repmat({''},hasX1+hasX2,1);
    mStrT = [[mStr1;mStr2],A];
end

%
mStrT = combineCellArrays(num2cell(NaN(2,1)),mStrT,0);