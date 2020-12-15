% --- sets up the individual signal data array
function [Data,DataN] = setupIndivSigDataArray(handles,pData,iData,Y,iOrder)

% ------------------------------------------- %
% --- INITIALISATIONS & MEMORY ALLOCATION --- %
% ------------------------------------------- %

% initialisations 
appOut = iData.appOut(:,iData.cTab);
expOut = iData.expOut(:,iData.cTab);
[nApp,nExp] = deal(sum(appOut),iData.sepExp*(sum(expOut)-1)+1);
sepDay = getCheckValue(handles.checkSepByDay);

% sets the global metric indices
Type = field2cell(iData.yVar,'Type',1);
mIndG = find(Type(:,5));

% retrieves the independent variable string
xDep = field2cell(iData.yVar(mIndG(iOrder)),'xDep');
[outType,tSp] = deal(sepDay + 1,{'Day',''});

%
xDepT = cellfun(@(x)(x{1}),xDep,'un',0);
ii = find(cellfun(@(x)(any(strcmp(xDepT,x))),field2cell(iData.xVar,'Var')));
iiT = ii(strcmp(field2cell(iData.xVar(ii),'Type'),'Time'));
hasTime = ~isempty(iiT);

% not separating by day, so determine if column exists
i0 = find(cellfun(@(x)(size(x,1)>1),Y{1,1}{1}),1,'first');
if (isnumeric(Y{1}{1}{i0}(1)))
    % case is for numerical time data
    hasTSP0 = diff(Y{1,1}{1}{i0}(1:2,1)) == 0;
else
    % case is for non-numerical time data
    hasTSP0 = isnumeric(Y{1,1}{1}{i0}{1,1});
end

% determines if the day index column has been included
if (sepDay)
    % separating by day, so no day index column
    hasTSP = false;
else
    hasTSP = hasTSP0;
end

% determines the number of days each experiment runs for
if (all(cellfun(@isempty,Y{1,2})))
    nDay = ones(length(Y{1,1}{1}),1);
else
    nDay = cellfun(@(x,y)((size(x,2)-1)/(size(y,2)-(1+hasTSP0))),Y{1,2}{1},Y{1,1}{1});
    nDay = nDay(:)';
end

% sets the output type
% = 1 - all day combined
% = 2 - individual days
nDayY = sepDay*(nDay-1)+1;
[YR,iFly] = reduceDataArray(Y(:,outType),appOut,expOut,iOrder,nDayY,hasTSP);

% array indexing and other initialisations
tSp = tSp((1+(~hasTSP)):2);
[appName,pR] = deal(iData.appName(appOut)',0.001);

% determines the number of flies for each genotype/experiment
ii = cellfun(@length,xDep) > 1;
if (any(ii))
    plotD = getappdata(handles.figDataOutput,'plotD');
    gStr = eval(sprintf('plotD.%s',xDep{find(ii,1,'first')}{2}));
    nGrp = length(gStr);
    
    jj = strcmp(field2cell(iData.xVar,'Var'),xDep{find(ii,1,'first')}{1});
    tStr = {iData.xVar(jj).Name};
    
    nFly = num2cell(cellfun(@(x)(size(x,2)/nGrp),iFly,'un',0),2);
    gStrF = cellfun(@(x)(repmat(gStr,1,x{1})),nFly,'un',0);
    tStrF = cellfun(@(z)([{'Fly #'},cell2cell(cellfun(@(y)([{num2str(y)},...
            repmat({' '},1,nGrp-1)]),num2cell(1:z{1}),'un',0),0)]),nFly,'un',0);
    
    mStrF = cellfun(@(x,y,z)({[z;[tSp(1:end-1),tStr,y]]}),...
                                appName,gStrF(:)',tStrF(:)','un',0);    
else    
    nFly = num2cell(num2cell(cellfun(@length,iFly)),2)'; 
    [iFly,nGrp] = deal(num2cell(iFly,2)',1);    
      
    % sets the group string
    jj = strcmp(field2cell(iData.xVar,'Var'),xDep{1});
    tSp{end} = iData.xVar(jj).Name;
                
    % sets the fly index title strings    
    mStrF = cellfun(@(x)(cellfun(@(xx)([tSp,cellfun(@(yy)(...
            sprintf('Fly #%i',yy)),num2cell(xx),'un',0)]),...
            x,'un',0)),iFly,'un',0);                                                  
end
                
% retrieves the time unit string/multiplier
[timeStr,tMlt,tRnd] = getOutputTimeValues(handles.popupUnits);
if (~isnan(tMlt))
    tStr = sprintf('Time %s',timeStr); 
else
    xVar = field2cell(pData.oP.xVar,'Var');
    xDepS = cellfun(@(x)(x{1}),field2cell(pData.oP.yVar(mIndG),'xDep'),'un',0);
    tStr = pData.oP.xVar(strcmp(xDepS{1},xVar)).Name;
end

% --------------------------------- %
% --- TABLE HEADER STRING SETUP --- %
% --------------------------------- %

% sets the metric header strings
mStrB = reshape(iData.fName(mIndG(iOrder)),1,length(iOrder));

% sets the metric/genotype combination strings
mStrMG = cellfun(@(x)(cellfun(@(y)(cell2cell({{'Genotype',y};{...
        'Metric',x}})),appName,'un',0)),mStrB,'un',0);          
    
% if there is more than one experiment, then append the title for each    
if (nExp > 1)
    % experiment index array
    xiE = num2cell(1:nExp);
    
    % appends the new strings onto the titles
    for i = 1:length(mStrMG)
        mStrMG{i} = cellfun(@(x)(cellfun(@(y)(combineCellArrays(...
                x,{'Experiment #',num2str(y)},0)),xiE,...
                'un',0)),mStrMG{i},'un',0);        
    end    
else
    for i = 1:length(mStrMG)
        mStrMG{i} = cellfun(@(x)(cellfun(@(y)(x),{1},...
                'un',0)),mStrMG{i},'un',0);            
    end
end    
        
% sets the main title string (depending on whether data is split by day)
if (sepDay)
    % sets the day index title strings
    mStrD = cellfun(@(x)(cellfun(@(xx)(sprintf('Day #%i',xx)),num2cell(1:x),...
                    'un',0)),num2cell(nDay),'un',0);        
    
    % sets the combined fly/day title strings
    mStrFD = cellfun(@(x)(cellfun(@(xx,yy)(cell2cell(cellfun(@(X)(...
             combineCellArrays({X},yy,0)),xx(2:end),'un',0),0)),...
             x,mStrD,'un',0)),mStrF,'un',0);
         
    % sets the time string
    for i = 1:length(mStrFD)
        isOK = true(length(mStrFD{i}),1);

        for j = 1:length(mStrFD{i})
            if (nFly{i}{j} > 0)
                if (~isnan(tMlt))
                    mStrFD{i}{j}{1+(nGrp>1),1+hasTSP} = tStr;
                end
            else
                isOK(j) = false;
                mStrFD{i}{j} = [];
                for k = 1:length(mStrMG)
                    mStrMG{k}{i}{j} = [];
                end
            end
        end

        mStrFD{i} = mStrFD{i}(isOK);
        for k = 1:length(mStrMG)
            mStrMG{k}{i} = mStrMG{k}{i}(isOK);
        end
    end      
        
    % sets the main title combination strings
    mStr = cellfun(@(x)(cell2cell(cellfun(@(xx,yy)(cell2cell(cellfun(...
           @(X,Y)(combineCellArrays({NaN},combineCellArrays(X,[{'';tStr},Y],...
           0))),xx,yy,'un',0),0)),x,mStrFD,'un',0),0)),...
           mStrMG,'un',0);                   
else    
% sets the time string    
    for i = 1:length(mStrF)
        isOK = true(length(mStrF{i}),1);

        for j = 1:length(mStrF{i})
            if (nFly{i}{j} > 0)
                if (~isnan(tMlt))
                    mStrF{i}{j}{1+(nGrp>1),1+hasTSP} = tStr;
                end
            else
                isOK(j) = false;
                mStrF{i}{j} = [];
                for k = 1:length(mStrMG)
                    mStrMG{k}{i}{j} = [];
                end
            end
        end

        mStrF{i} = mStrF{i}(isOK);
        for k = 1:length(mStrMG)
            mStrMG{k}{i} = mStrMG{k}{i}(isOK);
        end
    end
    
    % sets the main title combination strings  
    mStr = cellfun(@(x)(cell2cell(cellfun(@(xx,yy)(cell2cell(cellfun(@(X,Y)...
           (combineCellArrays({NaN},combineCellArrays(X,Y,0))),xx,yy,...
            'un',0),0)),x,mStrF,'un',0),0)),mStrMG,'un',0);    
end

% combines all of the title strings and set the time header string
mStrT = cell2cell(mStr,0);

% removes the NaN values from the array
ii = find(cellfun(@isnumeric,mStrT));
jj = cellfun(@isnan,mStrT(ii));
mStrT(ii(jj)) = {''};

% ------------------------------- %
% --- SIGNAL DATA ARRAY SETUP --- %
% ------------------------------- %

% memory allocation
nRow = max(cellfun(@(x)(size(x,1)),YR{1}{1}));
nCol = cellfun(@(x)(size(x,2)),mStr,'un',0);
mData = cellfun(@(x)(cell(nRow,x)),nCol,'un',0);
indN = cellfun(@(x)(zeros(nRow,x)),nCol,'un',0);

% determines the feasible data arrays
isOK = cellfun(@(x)(~cellfun(@isempty,x)),YR{1},'un',0);

% sets the time vector
tData = cell(nApp,1);
for i = 1:nApp
    % retrieves the time vector from the raw data array
    tData{i}(isOK{i}) = cellfun(@(x)(x(:,1+hasTSP)),YR{1}{i}(isOK{i}),'un',0);
    
    %
    for j = reshape(find(isOK{i}),1,sum(isOK{i}))
        if (isnan(tRnd))
            if (isnumeric(tData{i}{j}))
                tData{i}{j} = num2cell(tData{i}{j});
            end
        else        
            % converts the time signals to strings
            tData{i}{j} = roundP((tData{i}{j}-tData{i}{j}(1))*tMlt,tRnd);
            switch (tRnd)
                case (1)
                    tData{i}{j} = num2strC(tData{i}{j},'%i');
                case (0.1)
                    tData{i}{j} = num2strC(tData{i}{j},'%.1f');
                case (0.01)
                    tData{i}{j} = num2strC(tData{i}{j},'%.2f');                
                otherwise
                    tData{i}{j} = num2strC(tData{i}{j},'%.4f');
            end    
        end        
    end
end
    
% sets the signal data arrays depending on whether data is split by day
if (sepDay)
    % sets the fly count sum array
    nFlyC = cellfun(@(x)([0,cumsum(nDay.*cell2mat(x)*nGrp)]),nFly,'un',0);
    nFlyS = cellfun(@(x)(x(end)),nFlyC);
    nExpF = cellfun(@length,mStrFD);
    
    % sets the signal data for each apparatus (split by day)
    for j = 1:nApp
        % sets the column index offset
        iC0 = sum(nFlyS(1:(j-1))) + 2*sum(nExpF(1:(j-1))) + 1;  
        iFlyN = find(cell2mat(nFly{j})>0);
                            
        % sets the column offset indices
        for i = 1:length(iFlyN) 
            % sets the column indices
            i2 = iFlyN(i);
            iC = (iC0+1) + (1:(nFly{j}{i2}*nDay(i2)*nGrp)) + (nFlyC{j}(i)+2*(i-1));  
            
            % sets the data into the arrays
            if (~isempty(iC))            
                for k = 1:length(YR)  
                    %
                    YRnw = YR{k}{j}{i2}(:,2:end);                
                    iRnw = 1:size(YRnw,1);

                    % sets the data values
                    mData{k}(iRnw,iC(1)-1) = tData{j}{i};
                    if (iscell(YRnw))
                        mData{k}(iRnw,iC) = cellfun(@(x)(roundP(x,pR)),YRnw,'un',0);
                    else
                        mData{k}(iRnw,iC) = num2cell(roundP(YRnw,pR));
                    end

                    % sets the number indices
                    [indN{k}(iRnw,iC(1)-1),indN{k}(iRnw,iC)] = deal(2,1);
                end
            end
        end
    end         
else         
    % sets the fly count sum array
    nFlyC = cellfun(@(x)([0,cumsum(cell2mat(x)*nGrp)]),nFly,'un',0);
    nFlyS = cellfun(@(x)(x(end)),nFlyC) + hasTSP;    
    nExpF = cellfun(@length,mStrF);
    
    % sets the data into the metric array (for each genotype)
    for j = 1:nApp    
        % sets the column index offset
        iC0 = sum(nFlyS(1:(j-1))) + 2*sum(nExpF(1:(j-1))) + (1+hasTSP);        
        iFlyN = find(cell2mat(nFly{j})>0);
        
        for i = 1:length(iFlyN)        
            % sets the column indices  
            i2 = iFlyN(i);
            iC = (iC0+1) + (1:nFly{j}{i2}*nGrp) + (nFlyC{j}(i2)+2*(i-1)) + hasTSP*(i-1);

            % sets the data for each metric
            if (~isempty(iC))
                for k = 1:length(YR)    
                    YRnw = YR{k}{j}{i2}(:,(2+hasTSP):end);
                    iRnw = 1:size(YRnw,1);

                    % sets the data values
                    if (hasTSP)
                        if (isnumeric(YR{k}{j}{i2}(1,1)))
                            mData{k}(iRnw,iC(1)-2) = num2cell(YR{k}{j}{i2}(:,1)); 
                        else
                            mData{k}(iRnw,iC(1)-2) = YR{k}{j}{i2}(:,1); 
                        end                
                    end         
                    
                    % sets the time vector
                    mData{k}(iRnw,iC(1)-1) = tData{j}{i};                                                    
                    if (iscell(YRnw))
                        mData{k}(iRnw,iC) = cellfun(@(x)(roundP(x,pR)),YRnw,'un',0);
                    else
                        mData{k}(iRnw,iC) = num2cell(roundP(YRnw,pR));
                    end

                    % sets the number indices
                    indN{k}(iRnw,iC(1)-((1+hasTSP):1)) = 1+~isnan(tMlt);                
                    indN{k}(iRnw,iC) = 1;  
                    if (hasTSP); indN{k}(iRnw,iC(1)-2) = 1; end
                    if (~hasTime); indN{k}(iRnw,iC(1)-1) = 0; end
                end
            end
        end        
    end   
end

% clears extraneous variables
clear Y YR tData iRnw YRnw

% ------------------------- %
% --- FINAL ARRAY SETUP --- %
% ------------------------- %

% sets the final data into a single array
[Data,DataN] = deal([mStrT;cell2cell(mData,0)]);
clear mData YRnw; pause(0.05);

% sets the time/numeric elements
indN = cell2cell(indN,0);
isN = [zeros(size(mStrT));indN];
iiF = find(isN == 1);

% clears the extraneous variables
clear indN mStrT; pause(0.05);

% combines the full data array
iiFN = iiF(cellfun(@isnan,Data(iiF)));
    
% converts the numerical values to strings
jj = roundP(linspace(0,length(iiF),50));
for i = 1:(length(jj)-1)
    kk = iiF((jj(i)+1):jj(i+1));
    A = cell2mat(Data(kk));
    isI = mod(A,1) == 0;

    Data(kk(isI)) = num2strC(A(isI),'%i');
    Data(kk(~isI)) = num2strC(A(~isI),'%.4f');
    clear A isI kk
end
    
% reduces the array
Data(iiFN) = {''};

%
clear iiF isN 
pause(0.05);

%
Data = Data(:,2:end);
DataN = DataN(:,2:end);

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- removes the apparatus groups that are not included
function [YR,iFly] = reduceDataArray(Y,appOut,expOut,iOrder,nDay,hasTSP)

% memory allocation
YR = cell(1,size(iOrder,1));
[iFly,kk] = deal(cell(sum(appOut),sum(expOut)),cell(sum(appOut),1));

% resets the arrays
for i = 1:size(iOrder,1)  
    % resets the metrics to the specified genotype groups
    Ynw = Y{iOrder(i)}(appOut);    
    for iApp = 1:length(Ynw)
        % resets the metrics to the specified experiments
        Ynw{iApp} = Ynw{iApp}(expOut);        
        for iExp = 1:length(Ynw{iApp})
            % removes any columns without any valid values
            YnwT = Ynw{iApp}{iExp}(:,((2+hasTSP):end));
            if (i == 1); kk{iApp} = 1:size(YnwT,2); end                     
            
            if (iscell(YnwT))
                isOK = ~all(cellfun(@isnan,YnwT(:)));
            else
                isOK = ~all(isnan(YnwT(:)));
            end
            
            if ((i == 1) && (isOK))
                iFly{iApp,iExp} = kk{iApp}(1:length(kk{iApp})/nDay(iExp));
            end
        end        
    end
    
    % sets the final data values
    YR{i} = Ynw;
end