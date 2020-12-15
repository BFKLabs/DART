% --- sets up the stats array for the CSV output file --- %
function [Astat,pStat,ok] = setupStatsArray(pData,plotD,isMetGrp,isDN,rStr)

% sets the raw data string
if (nargin < 4); isDN = false; end
if (nargin < 5); rStr = 'Fly'; end

% memory allocation
[pStat,Astat,oP] = deal(struct(),[],pData.oP);

% retrieves the parameter indices and the suffix strings
[pInd,tStr,sStr,isRaw] = getOutputIndices(pData,'Stats');
[pStr,fxVal,isH] = deal(oP(pInd,2),isRaw,false);
isRaw(isnan(isRaw)) = 0;

% loops through each of the metrics calculating the stats
for i = 1:length(pStr)
    % calculates the t-test statistics arrays for the given metric
    switch (sStr{i})
        case ('Comp') % case is a between group type comparison
            
            % performs test depending if fixed values is being compared
            [isH,mStr] = deal(true,oP{pInd(i),1});
            if (isnan(fxVal(i)))
                % case is a pair-wise comparison
                pNw = compStatsTest(field2cell(plotD,pStr{i}),mStr);
            else
                % case is a comparison to a fixed value
                pNw = fixedValStatsTest(field2cell(plotD,pStr{i}),mStr,fxVal(i));
                isRaw(i) = 0;
            end

            % sets the output csv data array
            [Anw,ok] = setBoxPlotDataArray(pData,plotD,pStr{i},pNw);
            
        case ('CompMulti') % case is a between/within group type comparison
            
            % calculates the comparison statistics
            pNw = compStatsTestMulti(field2cell(plotD,pStr{i}),oP{pInd(i),1});
            
            % sets the output csv data array
            [Anw,ok] = setBoxPlotDataArray(pData,plotD,pStr{i},pNw,tStr{i});
            
        otherwise % case is either a T- or Z-tests
            
            % performs based on whether the test is for D/N or single group
            if (isDN)
                [Anw,pNw,ok] = calcTTestStatsDN(...
                                pData,plotD,tStr{i},pStr{i},sStr{i},isMetGrp);            
            else
                [Anw,pNw,ok] = calcTTestStats(...
                                pData,plotD,tStr{i},pStr{i},sStr{i},isMetGrp);    
            end
    end
                        
    if (ok == 0)
        return
    elseif (ok == 1)
        % appends the new data arrays to the global data arrays
        eval(sprintf('pStat.%s = pNw;',pStr{i}));
        Astat = combineCellArrays(Astat,Anw,isH);
    end
end

% sets the raw data for the csv file
if (any(isRaw))
    pInd = pInd(isRaw);
    Astat = combineCellArrays(Astat,...
                            setRawSheetDataArray(plotD,pData,rStr,pInd));
end

% ----------------------------------------------------------------------- %
% ---                      STATISTICAL FUNCTIONS                      --- %
% ----------------------------------------------------------------------- %

% ------------------------ %
% --- T-TEST FUNCTIONS --- %
% ------------------------ %

% --- calculates the comparison for the metric given by pStr. data is
%     grouped, time-wise, by the parameter given in pStr. test is dependent
%     on the string given by sStr (T-Test/Z-Test)
function [A,p,ok] = calcTTestStats(pData,plotD,tStr,pStr,sStr,isMetGrp)

% initialisations
[p,A] = deal(struct('tGrp',NaN,'P',NaN,'Pstr',NaN),{NaN}); 
[ok,hasGap] = deal(1);
appName = pData.appName;

% sets the time-grouping parameter (if one exists)
if (~isempty(tStr))
    switch (tStr)
        case ('Type')
            tGrp = pData.appName;
        otherwise
            tGrp = eval(sprintf('plotD.%s;',tStr));
            if (strcmp(tStr,'Tgrp'))
                if (length(tGrp) == 1) && (~isMetGrp)
                    isMetGrp = true;
                end
            end
    end
else
    tGrp = [];
end
    
% sets the statistical significance test string
ii = cellfun(@(x)(strcmp(pStr,x)),pData.oP(:,2));
if (~any(ii))
    % determines the parameter that closest matches the input string
    ii = ~cellfun(@isempty,strfind(pData.oP(:,2),sprintf('%s_',pStr)));
    j1 = find(ii,1,'first'); j2 = j1 + 1;
    
    % sets the metric and parameter strings
    mStr1 = pData.oP{j1,1}(1:(strfind(pData.oP{j1,1},'(')-1));           
    [pStrM,pStrS] = deal(pData.oP{j1,2},pData.oP{j2,2}); 
else
    % sets the metric and parameter strings
    mStr1 = pData.oP{ii,1};
    switch (sStr)
        case ('T-Test')
            [pStrM,pStrS] = deal([pStr,'_mn'],[pStr,'_sem']);
        case ('Z-Test')
            [pStrM,pStrS] = deal([pStr,'_P'],[pStr,'_N']);
    end
end

% sets the metric statistical significance header string
mStr = sprintf('Test Metric - %s',mStr1);

% ensures all numerical values are strings
if (~isempty(tGrp))
    if (isnumeric(tGrp))
        tGrp = cellfun(@num2str,num2cell(tGrp),'un',0);
    end
else
    tGrp = {NaN};
end
    
% sets the appartus names
aNm = cellfun(@(x)(sprintf('Type = %s',x)),appName,'un',0);

% sets the mean/sem values
if (length(plotD) == 1)
    % data values set into single array
    Mu = eval(sprintf('plotD.%s',pStrM));
    SE = eval(sprintf('plotD.%s',pStrS));
else   
    % sets the mean/standard error values
    Ynw = field2cell(plotD,pStrM);
    if (size(Ynw{1},1) == 1)        
        Mu = cell2mat(field2cell(plotD,pStrM))';
        SE = cell2mat(field2cell(plotD,pStrS))';    
    else
        Mu = cell2mat(field2cell(plotD,pStrM)');
        SE = cell2mat(field2cell(plotD,pStrS)');
    end
end

% exits the function
if (numel(Mu) < 2)
    ok = 0; return
elseif (all(isnan(Mu)))
    ok = -1; return
end

% sets the header group names based on the groupings
if (isMetGrp)
    % data is grouped by variable/metric
    [Mu,SE] = deal(Mu',SE');
    if (strcmp(tStr,'Type'))
        [hStr,hasGap] = deal(num2cell(tGrp),false);
    else
        hStr = setHeaderGroupNames(tGrp,aNm,[]);
    end
else
    % data is grouped by type
    if (strcmp(tStr,'Type'))
        [hStr,hasGap] = deal(num2cell(tGrp),false);
    else
        hStr = setHeaderGroupNames(aNm,tGrp,[]);
    end    
end

% calculates the P-scores and the significance strings
switch (sStr)
    case ('T-Test')
        [P,~,Pstr] = calcTTestPScore(Mu(:),SE(:));
    case ('Z-Test')
        [P,~,Pstr] = calcPropPScore(Mu(:),SE(:));
end

% memory allocation
[nGrp,nSub] = deal(length(hStr),size(hStr{1},2));
A = num2cell(NaN((nGrp*nSub+hasGap*nGrp)+2));

% data struct memory allocations
p.tGrp = tGrp; [p.P,p.Pstr] = deal(cell(nGrp));

% sets the total stats array from the data
for i = 1:nGrp
    % sets the row/index offset
    [iR0,iOfs] = deal((i-1)*nSub+(1:nSub),2+hasGap*i);    
    
    % sets the stats array for the sub-regions
    for j = 1:nGrp
        % sets the column indices
        [iC0,jOfs] = deal((j-1)*nSub+(1:nSub),2+hasGap*j);        
        A(iR0+iOfs,iC0+jOfs) = Pstr(iR0,iC0);
        
        % sets the data for the other data structs
        [p.P{i,j},p.Pstr{i,j}] = deal(P(iR0,iC0),Pstr(iR0,iC0));
        
        % sets the header arrays
        if (i == 1); A(1:size(hStr{j},1),iC0+jOfs) = hStr{j}; end
        if (j == 1); A(iR0+iOfs,1:size(hStr{i},1)) = hStr{i}'; end
    end
end

% adds a spacer to the top and right hand side
A = combineCellArrays({NaN},combineCellArrays([{NaN};mStr;{NaN}],A,0));

% --- calculates the day/night separation comparison stats for the metric
%     given by pStr. data is grouped, time-wise, by the parameter given in
%     pStr. test is dependent on the string given by sStr (T-Test/Z-Test)
function [A,p,ok] = calcTTestStatsDN(pData,plotD,tStr,pStr,sStr,isMetGrp)

% initialisations
[p,A,ok] = deal(struct('tGrp',NaN,'P',NaN,'Pstr',NaN),{NaN},true); 
[hasGap,tGrp] = deal(true,eval(sprintf('plotD.%s;',tStr)));

% sets the statistical significance test string
ii = cellfun(@(x)(strcmp(pStr,x)),pData.oP(:,2));
if (~any(ii))
    % determines the parameter that closest matches the input string
    ii = ~cellfun(@isempty,strfind(pData.oP(:,2),sprintf('%s_',pStr)));
    j1 = find(ii,1,'first'); j2 = j1 + 1;
    
    % sets the metric and parameter strings
    mStr1 = pData.oP{j1,1}(1:(strfind(pData.oP{j1,1},'(')-1));           
    [pStrM,pStrS] = deal(pData.oP{j1,2},pData.oP{j2,2});
else
    % sets the metric and parameter strings
    mStr1 = pData.oP{ii,1};
    switch (sStr)
        case ('T-Test')
            [pStrM,pStrS] = deal([pStr,'_mn'],[pStr,'_sem']);
        case ('Z-Test')
            [pStrM,pStrS] = deal([pStr,'_P'],[pStr,'_N']);
    end
end

% sets the metric statistical significance header string
mStr = sprintf('Test Metric - %s',mStr1);

% sets the total day/night group names
tGrp = cellfun(@(x,y)(sprintf('%s (%s)',x,y)),repmat(tGrp,1,2),...
                    repmat({'D','N'},length(tGrp),1),'un',0);

% ensures all numerical values are strings
if (isnumeric(tGrp))
    tGrp = cellfun(@num2str,num2cell(tGrp),'un',0);
end

% sets the header group names based on the groupings
if (isMetGrp)
    [A,B] = deal(field2cell(plotD,pStrM)',field2cell(plotD,pStrS)');
    Mu = [cell2mat(cellfun(@(x)(x(:,1)),A,'un',0))',...
          cell2mat(cellfun(@(x)(x(:,2)),A,'un',0))'];
    SE = [cell2mat(cellfun(@(x)(x(:,1)),B,'un',0))',...
          cell2mat(cellfun(@(x)(x(:,2)),B,'un',0))'];              
      
    % data is grouped by type
    hStr = setHeaderGroupNames(tGrp(:),pData.appName,[]);          
else
    % sets the mean/standard error values
    Mu = cell2mat(field2cell(plotD,pStrM)');
    SE = cell2mat(field2cell(plotD,pStrS)');    
      
    % data is grouped by variable/metric
    hStr = setHeaderGroupNames(pData.appName,tGrp(:),[]);          
end

% exits the function
if (length(Mu) < 2)
    ok = false; return
end

% calculates the P-scores and the significance strings
switch (sStr)
    case ('T-Test')
        [P,~,Pstr] = calcTTestPScore(Mu(:),SE(:));
    case ('Z-Test')
        [P,~,Pstr] = calcPropPScore(Mu(:),SE(:));
end

% memory allocation
[nGrp,nSub] = deal(length(hStr),size(hStr{1},2));
A = num2cell(NaN((nGrp*nSub+hasGap*nGrp)+2));

% data struct memory allocations
p.tGrp = tGrp(:); [p.P,p.Pstr] = deal(cell(nGrp));

% sets the total stats array from the data
for i = 1:nGrp
    % sets the row/index offset
    [iR0,iOfs] = deal((i-1)*nSub+(1:nSub),2+hasGap*i);    
    
    % sets the stats array for the sub-regions
    for j = 1:nGrp
        % sets the column indices
        [iC0,jOfs] = deal((j-1)*nSub+(1:nSub),2+hasGap*j);
        A(iR0+iOfs,iC0+jOfs) = Pstr(iR0,iC0);
        
        % sets the data for the other data structs
        [p.P{i,j},p.Pstr{i,j}] = deal(P(iR0,iC0),Pstr(iR0,iC0));
        
        % sets the header arrays
        if (i == 1); A(1:2,iC0+jOfs) = hStr{j}; end
        if (j == 1); A(iR0+iOfs,1:2) = hStr{i}'; end
    end
end

% adds a spacer to the top and right hand side
A = combineCellArrays({NaN},combineCellArrays([{NaN};mStr;{NaN}],A,0));

% -------------------------------------- %
% --- PAIR-WISE COMPARISON FUNCTIONS --- %
% -------------------------------------- %

% --- calculates the within/between group comparison test
function sData = compStatsTestMulti(Data,Metric)

% parametes
Nmin = 10;

% retrieves the number of genotype groups
[nApp,N] = deal(length(Data),length(Data{1}));
ind = cellfun(@(x)((x-1)*N + (1:N)),num2cell(1:nApp),'un',0);

% combines the data into a single data array
Data = reshape(Data,1,length(Data));
Data = cellfun(@(x)(combineNumericCells(x)),Data,'un',0);
Data = combineNumericCells(Data);

% removes any the columns where the data count is less than tolerance
Data(:,sum(~isnan(Data),1) < Nmin) = NaN;

% calculates the comparison test
sData = compStatsTest(Data,Metric,nApp);

% seperates the data by the group types
[pNw,isSigNw,pStrNw] = deal(cell(nApp));
for i = 1:nApp
    for j = 1:nApp
        pNw{i,j} = sData.p(ind{i},ind{j});
        isSigNw{i,j} = sData.isSig(ind{i},ind{j});
        pStrNw{i,j} = sData.pStr(ind{i},ind{j});
    end    
end

% --- performs a pair-wise statistical comparison test on the data array,
%     Data. the tests performed are as follows:
%
%     => runs the Anderson-Darling test to check for normality of the data
%      -> if data is normal and within variance tolerance, then calculate
%         the one sided ANOVA with a post-hoc Tukey-Kramer test
%      -> otherwise, calculate the Kruskal-Wallis test with a post-hoc
%         Mann-Whitney U test
function sData = compStatsTest(Data,Metric,nApp)

% determines the number of genotypes within the dataset
if (nargin == 2)
    [nApp,nGrp] = deal(length(Data));
    isOK = true(nApp,1);
else
    nGrp = size(Data,2);
    isOK = any(~isnan(Data),1);
end

% memory allocation and parameters
[vRatioMax,pTol,typeStr] = deal(4,0.05,{'Comp','CompMulti'});
[isNorm,vData] = deal(true(nGrp,1),zeros(nGrp,1));
[p,isSig] = deal(NaN(nGrp),false(nGrp));
sData = struct('Test',[],'p',[],'isSig',[],'pStr',[],'pTol',pTol,...
               'Type',[],'Metric',Metric);

% sets the statistic test type
sData.Type = typeStr{1+(nargin>2)};
           
% combines the data into a single data array
pStr = repmat({'N/A'},nGrp,nGrp);
if (nargin == 2)
    DataN = combineNumericCells(Data);
else
    DataN = Data;
end

% performs the Anderson-Darling test and calculates the variance
for i = 1:nGrp
    if (iscell(Data))
        [isNorm(i),vData(i)] = deal(AnDartest(Data{i},pTol),var(Data{i}));    
    else
        [isNorm(i),vData(i)] = deal(AnDartest(Data(:,i),pTol),var(Data(:,i)));    
    end
end

% calculates the variance ratio between the max/min data variances
vRatio = max(vData)/min(vData);

% determines if the dataset mets the normal distribution criteria
if (all(isNorm) && (vRatio <= vRatioMax))
    % if so, then perform the one-sided ANOVA test
    sData.Test = 'ANOVA';
    [p1,~,stats] = anova1(DataN,[],'off');
    if (p1 <= pTol)
        % if significance is determined, then 
        c = multcompare(stats,'alpha',pTol,'display','off');
        
        % sets the p-values into the array
        indL = sub2ind(size(p),c(:,2),c(:,1));
        indU = sub2ind(size(p),c(:,1),c(:,2));
        [p(indL),p(indU)] = deal(c(:,6));
        
        % calculates the significance of the p-values
        isSig = p <= pTol;
    end
else
    % otherwise, perform the Krukal-Wallis statistical test    
    [p1,sData.Test] = deal(kruskalwallis(DataN,[],'off'),'K-W');
    if(p1 <= pTol)
        % calculates the Dunn-Sidak coeffiecient
        C = nApp*(nApp-1)*0.5;
        sData.pTol = 1 - (power((1-pTol),1/C)); 
        
        % check pair-wise the significance between groups
        for m = 1:(nGrp-1)
            for n = (m+1):nGrp    
                if (all(isOK([m n])))
                    % calculates the rank-sum test and determines if the
                    % p-value is less than tolerance
                    if (iscell(Data))
                        [p(m,n),p(n,m)] = deal(ranksum(Data{m},Data{n}));
                    else
                        [p(m,n),p(n,m)] = deal(ranksum(Data(:,m),Data(:,n)));
                    end

                    % sets the significance strings
                    [isSig(m,n),isSig(n,m)] = deal(p(m,n) <= sData.pTol);
                end
            end            
        end                
    end
end

% only determine significance levels if there are any valid p-values
if (any(~isnan(p(:))))
    for i = 1:(nGrp-1)
        for j = (i+1):nGrp
            % determines the level of significance
            if (all(isOK([i j])))
                hL = log10(p(i,j));
                if (hL < -3)
                    [hL,pL] = deal(floor(hL),p(i,j)/(10^floor(hL)));
                    [pStr{i,j},pStr{j,i}] = deal(sprintf('%1.2f*10^{%i}',pL,hL));
                else
                    [pStr{i,j},pStr{j,i}] = deal(p(i,j));
                end            
            end
        end
    end
end
    
% sets the final arrays into the statistical data struct
[sData.p,sData.isSig,sData.pStr] = deal(p,isSig,pStr);

% --- performs a fixed value statistical comparison test on the data array,
%     Data. the tests performed are as follows:
%
%     => runs the Anderson-Darling test to check for normality of the data
%      -> if data is normal, then perform a one-sided t-test to determine
%         if the mean is significantly different from fxVal
%      -> otherwise, perform a Wilcoxon signed rank test to determine if
%         the median is signicantly different from fxVal
function sData = fixedValStatsTest(Data,Metric,fxVal)

% determines the number of genotypes within the dataset
nApp = length(Data);

% memory allocation and parameters
[pTol,W] = deal(0.05,1.5);
sData = struct('Test',[],'p',[],'isSig',[],'pStr',[],...
               'pTol',pTol,'Type','Fixed','fxVal',fxVal,'Metric',Metric);
[isNorm,vData,p] = deal(true(nApp,1),zeros(nApp,1),NaN(1,nApp));
Test = cell(nApp,1);

% combines the data into a single data array
pStr = repmat({'N/A'},1,nApp);

% performs the Anderson-Darling test and calculates the variance
for i = 1:nApp
    [isNorm(i),vData(i)] = deal(AnDartest(Data{i},pTol),var(Data{i}));
end

% determines if the dataset mets the normal distribution criteria
for i = 1:nApp
    if (isNorm(i))
        % if so, then perform the one-sided student t-test
        Test{i} = 'T-Test';
        [~,p(i)] = ttest(Data{i},fxVal);
    else
        % otherwise, perform the Wilcoxon signed rank test
        Test{i} = 'Signed Rank';
        
        % determines the outliers from the data set (and omits from test)
        Y = quantile(Data{i},[0.25 0.75]);
        ii = (Data{i} > (Y(1)-W*diff(Y))) & (Data{i} < (Y(2)+W*diff(Y)));
        
        % performs the signed ranked test
        p(i) = signtest(Data{i}(ii),fxVal);
    end
end

% determines the significance to the p-level
isSig = p <= pTol;

% only determine significance levels if there are any valid p-values
if (any(~isnan(p(:))))
    for i = 1:nApp
        % determines the level of significance
        hL = log10(p(i));
        if (hL < -3)
            [hL,pL] = deal(floor(hL),p(i)/(10^floor(hL)));
            pStr{i} = sprintf('%1.2f*10^{%i}',pL,hL);
        else
            pStr{i} = p(i);
        end
    end
end

% sets the final arrays into the statistical data struct
[sData.p,sData.isSig,sData.pStr,sData.Test] = deal(p,isSig,pStr,Test);

% ---------------------------------- %
% --- DATA ARRAY SETUP FUNCTIONS --- %
% ---------------------------------- %

% --- sets the data from a boxplot dataset into a data array
function [A,ok] = setBoxPlotDataArray(pData,plotD,vName,sData,tStrP)

% initialisations and other memory allocations
[sStr,tStr,A,ok] = deal({'NS','S'},pData.appName',[],true);

% reshapes the array
plotD = reshape(plotD,1,length(plotD));

% sets the indices of the current metric
indSM = ~cellfun(@isempty,strfind(pData.oP(:,2),sprintf('%s_',vName)));

% retrieves the metric values/stats title strings
[TSM,fStr] = deal(pData.oP(indSM,1),pData.oP(indSM,2));

% determines if any of the fields are missing (if so then output the error)
ii = cellfun(@(x)(~any(strcmp(x,fieldnames(plotD)))),fStr);
if (any(ii))
    % sets up the error variable string
    eStr = sprintf('The following variables are missing from the plot data struct:\n\n');
    for i = find(ii');
        eStr = sprintf('%s  => %s\n',eStr,TSM{i});
    end
    eStr = sprintf('%s\nUnable to setup the statistics array.',eStr);
    
    % outputs the error to string
    waitfor(errordlg(eStr,'Missing Data Fields','modal'));
    [A,ok] = deal([],false);
    return
end

% retrieves the metric values from the data struct
Y = field2cell(plotD,vName);
if (iscell(Y{1}))
    % sets the group title strings
    tStrG = eval(sprintf('plotD(1).%s;',tStrP));
    if (isnumeric(tStrG))
        tStrG = cellfun(@num2str,num2cell(tStrG),'un',0);
    end
            
    % retrieves the metric and statistical metric values
    AY = cellfun(@(x)(sort(combineNumericCells(x))),Y,'un',0);
    ASM = cellfun(@(y)(cell2mat(cellfun(@(x)(cell2mat(...
            field2cell(y,x))),fStr,'un',0))),...
            num2cell(plotD),'un',0);    
        
    % combines the data from each group type
    [AYnw,tStr,ASMnw] = deal([],[],TSM);
    for i = 1:length(AY)
        % combines the metric values
        a1 = num2cell(AY{i});
        AYnw = combineCellArrays(combineCellArrays(AYnw,a1),{NaN});
        tStr = combineCellArrays(combineCellArrays(tStr,tStrG),{NaN});

        % combines the statistical metrics
        if (~isempty(ASM))
            a2 = num2cell(ASM{i});
            ASMnw = combineCellArrays(combineCellArrays(ASMnw,a2),{NaN});
        end
    end
        
    % adds the title string to the top of the metric array
    AYnw = combineCellArrays(tStr,AYnw,0);
    
else
    % retrieves the metric and statistical metric values
    AY = sort(combineNumericCells(Y));    
    ASM = cell2mat(cellfun(@(x)(cell2mat(...
            field2cell(plotD,x))),fStr,'un',0));
        
    % combines the data values
    AYnw = combineCellArrays(tStr,num2cell(AY),0);        
    ASMnw = combineCellArrays(TSM,num2cell(ASM));
end  

% sets the metric values into the data array
AA = combineCellArrays(combineCellArrays({'Raw Values'},AYnw),{NaN},0);

% sets the metric stats values array (if there are any)
if (~isempty(ASM))
    AA = combineCellArrays(combineCellArrays(ASMnw,{NaN},0),AA,0);
end

% creates the comparison stats array (if there are any)
if (~isempty(sData))        
    % sets title array
    switch (sData.Type)
        case ('Comp')
            BB = {'Metric Name',sData.Metric;...
                  'P-Value Significance',sData.pTol;...
                  'Comparison Test Type',sData.Test};            
        case ('Fixed')
            BB = combineCellArrays([{'Metric Name'},sData.Metric],0);
            BB = combineCellArrays(BB,[{'P-Value Significance'},sData.pTol],0);                        
            BB = combineCellArrays(BB,[{'Fixed Value'},sData.fxVal],0);
            BB = combineCellArrays(BB,[{'Comparison Test Type'},sData.Test'],0);                        
        case ('CompMulti')
            CC = {'Metric Name',sData.Metric;...
                  'P-Value Significance',sData.pTol;...
                  'Comparison Test Type',sData.Test};  
            CC = cellfun(@(x)([{'Group Type',x};CC]),...
                                 pData.appName,'un',0);
            
            [BB,b] = deal({NaN,NaN},num2cell(NaN(1,length(Y{1})-1)));
            for i = 1:length(CC)
                BB = combineCellArrays(combineCellArrays(BB,CC{i}),b);
            end
    end                         
    
    % adds gap underneath the title strings 
    ASnwT = combineCellArrays(BB,{NaN},0);    
    
    % sets the p-value/significance arrays
    if (~exist('tStrP','var')); tStrP = []; end
    [pStrS,sStrS,Type] = deal(sData.pStr,sStr(sData.isSig+1),sData.Type);
    AP = setStatStringArray(pData,plotD,pStrS,tStr,tStrP,Type,'P-Values');                                 
    AS = setStatStringArray(pData,plotD,sStrS,tStr,tStrP,Type,'Significance');                                                            

    % combines the data into a single array
    ASnw = combineCellArrays(combineCellArrays(ASnwT,AP,0),AS,0);
    AA = combineCellArrays(ASnw,AA,0);
end

% combines the data into a single array
A = combineCellArrays(combineCellArrays(A,AA),{NaN});

% adds a space for the first row/column
A = combineCellArrays({NaN},combineCellArrays({NaN},A),false);

% --- 
function A = setStatStringArray(pData,plotD,pStr,tStr,tStrP,Type,lStr)        

% sets the p-value array    
switch (Type)
    case ('Comp')
        AT = combineCellArrays({lStr},tStr);
        AP = combineCellArrays(tStr',pStr);
    case ('Fixed')
        AT = combineCellArrays({lStr},tStr);
        AP = combineCellArrays({NaN},pStr);
    case ('CompMulti')
        % sets the title string array
        AT = combineCellArrays({lStr,NaN},tStr);
        
        % allocates memory for the data array
        nStr = length(tStr);
        [AP,nApp] = deal(num2cell(NaN(nStr,nStr+1)),length(plotD));
        nVar = length(eval(sprintf('plotD.%s',tStrP)));

        % sets the values into the cell array (for each sub-group)
        for j = 1:nApp
            % sets the column indices
            iC = (j-1)*nVar+(1:nVar);                
            for i = 1:nApp
                % sets the row indices
                iR = (i-1)*nVar+(1:nVar);

                % sets the new values
                AP(iR+(i-1),iC+(j+1)) = pStr(iR,iC);
                AP{iR(1)+(i-1),1} = pData.appName{i};
            end
        end
        
        % adds in a spare column at the start (to match the title
        AP(:,2) = tStr';
end            

% combines the P-values with the title string
A = combineCellArrays(combineCellArrays(AT,AP,0),{NaN},0);  
