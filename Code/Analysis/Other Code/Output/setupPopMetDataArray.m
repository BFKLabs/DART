% --- sets up the population metric data array
function Data = setupPopMetDataArray(handles,iData,plotD,Y,iOrder)

% global variables
global nMet

% ------------------------------------------- %
% --- INITIALISATIONS & MEMORY ALLOCATION --- %
% ------------------------------------------- %

% initialisations 
expOut = iData.expOut(:,iData.cTab);
appOut = iData.appOut(:,iData.cTab);
sepExp = getCheckValue(handles.checkSepByExpt);
sepDay = getCheckValue(handles.checkSepByDay);

% reorders the array so the N values are at the top
ii = iOrder(:,2) ~= nMet;
if (iData.metStats)    
    iOrderF = [[1 nMet];iOrder(ii,:)];
else
    iOrderF = iOrder(ii,:);
end

% sets the output type
% = 1 - all day/experiments combined
% = 2 - all day/individual experiment
% = 3 - individual day/all experiments
% = 4 - individual day/individual experiments
outType = (2*sepDay + sepExp) + 1;
isVert = ~iData.metStats;
YR = reduceDataArray(Y(:,:,outType),appOut,iOrderF,isVert);

% if separating by experiment, reduce the data output by the selection
if (sepExp)
    for i = 1:numel(YR)
        for j = 1:numel(YR{i})
            YR{i}{j} = YR{i}{j}(:,expOut);
        end
    end
end

% sets the final data arrays
Data = getPopDataArray(handles,plotD,iData,YR,iOrderF);

% --- sets up the population data array
function Data = getPopDataArray(handles,plotD,iData,YR,A)

% initialisations 
appOut = iData.appOut(:,iData.cTab);
nApp = sum(appOut);
sepExp = getCheckValue(handles.checkSepByExpt);
sepDay = getCheckValue(handles.checkSepByDay);
sepApp = getCheckValue(handles.checkSepByApp) || (nApp == 1);
numGrp = getCheckValue(handles.checkNumGroups);
isHorz = get(handles.radioAlignHorz,'value');

% reshapes the data arrays for each group
for i = 1:length(YR)
    YR{i} = reshapeDataArray(YR{i});
end

% sets the global metric indices
Type = field2cell(iData.yVar,'Type',1);
mIndG = find(Type(:,1));

% retrieves the dimensions of the data array
szY = cellfun(@(x)([size(x,1),size(x,2),size(x,3)]),YR{1},'un',0);
nGrp = size(YR{1}{1},1);

% array indexing and other initialisations
if (iData.metStats) 
%     if (strcmp(ind2varStat(A(2),1),'Conf. Interval'))
%         isOKF = cellfun(@(x)(cellfun(@(xx)(~isempty(xx)),x)),...
%                                     YR,'un',0);        
%     else
        isOKF = cellfun(@(x)(cellfun(@(xx)(str2double(xx)>0),x)),...
                                    YR{1},'un',0);
%     end
else
    % ??
    isOKF = cellfun(@(x)(true(size(x,1),1)),YR{1},'un',0);        
end

% memory allocation      
indGrpT = logical([~sepApp,(nGrp>1),sepExp,sepDay]);
[appName,indG] = deal(iData.appName(appOut),cell(1,4));

% --------------------------------- %
% --- TABLE HEADER STRING SETUP --- %
% --------------------------------- %

% sets the base variable names
mStrB = iData.fName(mIndG(A(:,1))); mStrB{1} = '';
xDep = cell2cell(field2cell(iData.yVar(mIndG(A(:,1))),'xDep'));

% sets the header string array
if (iData.metStats)
    % sets the metric header strings    
    mStrT = cellfun(@(x)(ind2varStat(x,1)),num2cell(A(:,2)),'un',0);
        
    % sets the final header string array         
    mStrH = [mStrB,mStrT]';
else
    % case is no metrics are being calculated
    mStrH = [repmat({''},1,length(mStrB));mStrB(:)'];
end

% sets the main grouping titles
mStrT = {'Group Name','Bin Group','Experiment','Day'};
mStrT = mStrT(indGrpT);

% ------------------------------ %
% --- TABLE DATA ARRAY SETUP --- %
% ------------------------------ %

% sets the grouping indices (if not separating by genotype group
if ((~sepApp) && (nApp > 1))
    xi0 = num2cell(1:nApp)';
    A0 = cellfun(@(x,y)(y*ones(size(x))),YR{1},xi0,'un',0);
    indG{1} = cellfun(@(x,y)(appName(x(y))),A0,isOKF,'un',0);        
    indG{1} = cell2cell(indG{1});
end

% sets the binned group indices (if more than one group)
if (nGrp > 1)
    % sets the group indices
    A3 = cellfun(@(x)(repmat(repmat((1:x(1))',1,x(2)),[1 1 x(3)])),szY,'un',0);
%     A3 = repmat({repmat(repmat((1:nGrp)',1,nD1),[1 1 nD2])},[nApp,1]);               
    
    % combines the grouped indices
    indG{2} = cellfun(@(x,y)(x(y)),A3,isOKF,'un',0);                        
    indG{2} = cellfun(@(x)(x(:)),indG{2},'un',0);     
    if (~sepApp); indG{2} = cell2mat(indG{2}); end
        
    % sets the bin group strings
    if (~numGrp)
        % bin group strings the original
        xType = field2cell(iData.xVar,'Var');
        mStrT{1+~sepApp} = iData.xVar(strcmp(xType,xDep{1})).Name;
        Xgrp = eval(sprintf('plotD.%s',xDep{1}));
        
        % ensures the independent variables are in a cell array
        if (isnumeric(Xgrp)); Xgrp = num2cell(Xgrp); end

        % sets the x-variable values for each genotype group
        if (sepApp)
            indG{2} = cellfun(@(x)(Xgrp(x)),indG{2},'un',0);
        else
            indG{2} = Xgrp(indG{2});
        end
    else
        if (sepApp)
            indG{2} = cellfun(@(x)(num2strC(x,'%i')),indG{2},'un',0);
        else        
            indG{2} = num2strC(indG{2},'%i');
        end
    end
end

% sets the 2nd-order dimension indices (if greater than one)
if (sepExp && sepDay)
    % sets the second order indices
    A2 = cellfun(@(x)(cell2mat(reshape(cellfun(@(y)(y*ones(x(1),x(2))),...
                num2cell(1:x(3))','un',0),[1 1 x(3)]))),szY,'un',0);   
    
    % combines the grouped indices
    indG{3} = cellfun(@(x,y)(x(y)),A2,isOKF,'un',0);                        
    indG{3} = cellfun(@(x)(x(:)),indG{3},'un',0);                   
           
    %    
    if (sepApp)
        indG{3} = cellfun(@(x)(num2strC(x,'%i')),indG{3},'un',0);
    else
        indG{3} = cell2mat(indG{3});
        indG{3} = num2strC(indG{3},'%i');
    end
end

% sets the 1st-order dimension indices (if greater than one)
if (sepExp || sepDay)
    % sets the first order indices
    A1 = cellfun(@(x)(repmat(repmat((1:x(2)),x(1),1),[1 1 x(3)])),szY,'un',0);
    
    indG{4} = cellfun(@(x,y)(x(y)),A1,isOKF,'un',0);
    indG{4} = cellfun(@(x)(x(:)),indG{4},'un',0);
    
    % combines the grouped indices
    if (sepApp)
        indG{4} = cellfun(@(x)(num2strC(x,'%i')),indG{4},'un',0);    
    else
        indG{4} = cell2mat(cellfun(@(x)(x(:)),indG{4},'un',0));
        indG{4} = num2strC(indG{4},'%i');
    end
end

% combines the headers into a single array
indG = indG(~cellfun(@isempty,indG));
if (isempty(indG))
    YT = [];
else
    if (sepApp) 
        YT = cellfun(@(x)([mStrT;cell2cell(x(:),0)]),num2cell(...
                        cell2cell(indG,0),2),'un',0);
    else
        YT = [mStrT;cell2cell(indG',0)];
    end
end

% ------------------------------- %
% --- METRIC DATA ARRAY SETUP --- %
% ------------------------------- %

% memory allocation
YM = cell(nApp,1);

% sets the metric data for each apparatus
for i = 1:nApp
    % memory allocation of temporary array
    Ytmp = cell(1,length(YR));    
    for j = 1:length(YR)                
        % allocates memory and set the data for the current group
        Ytmp{j} = YR{j}{i}(isOKF{i});
    end
    
    % combines the temporary data into a single array
    YM{i} = cell2cell(cellfun(@(x)(x(:)),Ytmp,'un',0),0);
end

% ------------------------- %
% --- FINAL ARRAY SETUP --- %
% ------------------------- %

% combines the header and metric data arrays into the final array
if (sepApp)      
    % memory allocation
    DataF = [];    
    
    % sets the final data for each apparatus
    for i = 1:nApp
        % sets the title and combines it with the new metric data
        if (~isempty(YT))
            DataNw = combineCellArrays({NaN},YT{i},0);                
        else
            DataNw = [];
        end
            
        DataNw = combineCellArrays(DataNw,[mStrH;YM{i}],1);   
        DataNw(1) = appName(i);
        
        % sets the new metric data into the full array
        if (i == 1)
            % if the first group, set the data as is
            DataF = DataNw;
        else
            % otherwise, add in a vertical gap between the groups
            DataF = combineCellArrays(DataF,{NaN},isHorz);
            DataF = combineCellArrays(DataF,DataNw,isHorz);
        end
    end
else
    % combines all the cells into a single array
    if (strcmp(mStrH{2},'N-Value')); mStrH{1} = []; end
    DataF = [combineCellArrays({NaN},YT,0),[mStrH;cell2cell(YM)]];    
end

% sets the final array
Data = cell(size(DataF,1)+2,size(DataF,2));
Data((1:size(DataF,1))+1,:) = DataF;
Data(cellfun(@isempty,Data)) = {''};
clear DataF; pause(0.05);

% removes any NaN values
ii = find(cellfun(@isnumeric,Data));
jj = ii(cellfun(@isnan,Data(ii)));

% converts the numbers to proper strings
Data(ii) = num2strC(Data(ii),'%.4f');
Data(jj) = {''};

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- removes the apparatus groups that are not included
function YR = reduceDataArray(Y,indOut,iOrderF,isVert)

% memory allocation
YR = cell(1,size(iOrderF,1));

% resets the arrays
for i = 1:size(iOrderF,1)       
    YR{i} = Y{iOrderF(i,1),iOrderF(i,2)}(indOut);
    if (isVert)
        for j = 1:length(YR{i})
            YR{i}{j} = YR{i}{j}(:);
        end
    end
end

% reshapes the data arrays for each group
function YR = reshapeDataArray(YR0)

% array dimensions
[nDay,nExp] = size(YR0{1});
nGrp = size(YR0{1}{1},2);
Type = (2*(nDay>1) + (nExp>1)) + 1;

% memory allocation
if (Type == 4)
    YR = repmat({cell(nGrp,nDay,nExp)},size(YR0));
else
    YR = cell(size(YR0));
end

%
for i = 1:length(YR)
    switch (Type)
        case (1)
            YR{i} = YR0{i}{1}';
        case (2)
            YR{i} = cell2cell(cellfun(@(x)(x'),YR0{i},'un',0),0);
        case (3)
            YR{i} = cell2cell(YR0{i})';
        case (4)
            for j = 1:nExp
                isOK = ~cellfun(@isempty,YR0{i}(:,j));
                YRC = cell2cell(YR0{i}(isOK,j));
                
                if (size(YRC,1) == size(YR{i},1))
                    YR{i}(isOK,:,j) = YRC;
                else
                    YR{i}(:,isOK,j) = YRC';
                end
            end
    end
end