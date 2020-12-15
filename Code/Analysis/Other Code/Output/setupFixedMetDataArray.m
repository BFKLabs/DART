% --- sets up the fixed metrics data array
function Data = setupFixedMetDataArray(handles,iData,pData,plotD,Y,iOrder)

% ------------------------------------------- %
% --- INITIALISATIONS & MEMORY ALLOCATION --- %
% ------------------------------------------- %

% sets the reduced data array
isVert = ~iData.metStats;
YR = reduceDataArray(Y(iOrder),isVert);

% sets the final data arrays
Data = getPopDataArray(handles,plotD,iData,YR,iOrder);

% --- sets up the population data array
function Data = getPopDataArray(handles,plotD,iData,YR,A)

% initialisations 
appOut = iData.appOut(:,iData.cTab);
[nApp,sepGrp] = deal(sum(appOut),iData.sepGrp);
numGrp = getCheckValue(handles.checkNumGroups);
isHorz = get(handles.radioAlignHorz,'value');
sepApp = getCheckValue(handles.checkSepByApp) || (nApp == 1);

% sets the global metric indices
Type = field2cell(iData.yVar,'Type',1);
mIndG = find(Type(:,2));

% retrieves the dimensions of the data array
nD1 = 1 + sepGrp*(size(YR{1}{1},1)-1);
nGrp = max(cellfun(@(x)(size(x{1},2)),YR));

%
xDep = field2cell(iData.yVar(mIndG(A(:,1))),'xDep');
hasXDep1 = ~cellfun(@isempty,xDep);
hasXDep2 = cellfun(@(x)(length(x)>1),xDep);

% memory allocation      
indGrpT = logical([~sepApp,(nGrp>1)&&(any(hasXDep1)),(nD1>1)&&(any(hasXDep2))]);
[appName,indG] = deal(iData.appName(appOut),cell(1,3));

% --------------------------------- %
% --- TABLE HEADER STRING SETUP --- %
% --------------------------------- %

% sets the base variable names
mStrB = iData.fName(mIndG(A(:,1)));

% case is no metrics are being calculated
mStrH = [repmat({''},1,length(mStrB));mStrB(:)'];

% sets the main grouping titles
mStrT = {'Group Name','Bin Group','Sub Group'};
mStrT = mStrT(indGrpT);

% ------------------------------ %
% --- TABLE DATA ARRAY SETUP --- %
% ------------------------------ %

% sets the grouping indices (if not separating by genotype group
if ((~sepApp) && (nApp > 1))
    xi0 = num2cell(1:nApp)';
    N = max(cellfun(@(x)(numel(x{1})),YR));
    A0 = cellfun(@(x)(x*ones(1,N)),xi0,'un',0);
    indG{1} = cell2cell(cellfun(@(x)(appName(x)),A0,'un',0));    
end

% sets the binned group indices (if more than one group)
if (nGrp > 1)
    % combines the grouped indices
    indG{2} = repmat({repmat((1:nGrp)',1,nD1)},[nApp,1]); 
    indG{2} = cellfun(@(x)(x(:)),indG{2},'un',0);     
    if (~sepApp); indG{2} = cell2mat(indG{2}); end    
    
    %
    xDep1 = repmat({''},size(xDep));    
    xDep1(hasXDep1) = cellfun(@(x)(x{1}),xDep(hasXDep1),'un',0);
%     xDep1 = cellfun(@(x)(x{1}),xDep(hasXDep1),'un',0);
    
    % sets the bin group strings
    if (~numGrp)
        % bin group strings the original
        xType = field2cell(iData.xVar,'Var');                
        mStrT{1+~sepApp} = iData.xVar(find(strcmp(xType,xDep1{1}),1,'first')).Name;
        
        %
        if (length(unique(xDep1)) > 1)
            A = cell(length(xDep1),1);
            for i = 1:length(xDep1)
                A{i} = eval(sprintf('plotD(1).%s',xDep1{i}));
            end
            
            Xgrp = A{argMax(cellfun(@length,A))};
        else
            Xgrp = eval(sprintf('plotD(1).%s',xDep1{1}));            
        end
        
        %        
        Xgrp = Xgrp(:);
        
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

%
if (sepGrp)
    %
    xDep2 = cellfun(@(x)(x{2}),xDep,'un',0);
    X2 = eval(sprintf('plotD.%s',xDep2{1}));
    
    % combines the grouped indices 
    indG{3} = repmat({repmat((1:nD1)',1,nGrp)'},[nApp,1]);
    indG{3} = cellfun(@(x)(x(:)),indG{3},'un',0); 
    
    %    
    if (sepApp)
        if (numGrp)
            indG{3} = cellfun(@(x)(num2strC(x,'%i')),indG{3},'un',0);            
        else
            indG{3} = cellfun(@(x)(cellfun(@(xx)(X2{xx}),...
                            num2cell(x),'un',0)),indG{3},'un',0);
        end
    else
        indG{3} = cell2mat(indG{3});
        if (numGrp)
            indG{3} = num2strC(indG{3},'%i');
        else
            indG{3} = cellfun(@(x)(X2{x}),num2cell(indG{3}),'un',0);
        end
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
        Ytmp{j} = YR{j}{i}';
    end
    
    % combines the temporary data into a single array
    YM{i} = num2cell(cell2cell(cellfun(@(x)(x(:)),Ytmp,'un',0),0));
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
    DataF = [combineCellArrays({NaN},YT,0),[mStrH;cell2cell(YM)]];    
end

% sets the final array
Data = cell(size(DataF,1)+1,size(DataF,2));
Data((1:size(DataF,1)),:) = DataF;
Data(cellfun(@isempty,Data)) = {''};
clear DataF; pause(0.05);

% removes any NaN values
ii = find(cellfun(@isnumeric,Data));
jj = ii(cellfun(@isnan,Data(ii)));

% converts the numbers to proper strings
kk = cellfun(@(x)(mod(x,1) == 0),Data(ii));
Data(ii(kk)) = num2strC(Data(ii(kk)),'%i');
Data(ii(~kk)) = num2strC(Data(ii(~kk)),'%.4f');
Data(jj) = {''};

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- removes the apparatus groups that are not included
function YR = reduceDataArray(Y,isVert)

% memory allocation
YR = cell(1,length(Y));

% resets the arrays
for i = 1:length(Y)
    YR{i} = cellfun(@(x)(x),Y{i},'un',0);
end
