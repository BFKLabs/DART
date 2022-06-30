function varargout = StatTest(varargin)
% Last Modified by GUIDE v2.5 23-Dec-2017 07:53:26

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @StatTest_OpeningFcn, ...
                   'gui_OutputFcn',  @StatTest_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before StatTest is made visible.
function StatTest_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for StatTest
handles.output = hObject;

% sets the input arguments
hGUI = varargin{1};
lStr = varargin{2};
pType = varargin{3};
pStr = varargin{4};
tType = varargin{5};
fxVal0 = varargin{6};
iRow = varargin{7};

% sets the parameters into the GUI
setappdata(hObject,'hGUI',hGUI)
setappdata(hObject,'lStr',lStr)
setappdata(hObject,'pType',pType)
setappdata(hObject,'pStr',pStr)
setappdata(hObject,'tType',tType)
setappdata(hObject,'fxVal',fxVal0)
setappdata(hObject,'iRow',iRow)

% initials the GUI objects
handles = initGUIObjects(handles,lStr);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes StatTest wait for user response (see UIRESUME)
uiwait(handles.figStatTest);

% --- Outputs from this function are returned to the command line.
function varargout = StatTest_OutputFcn(hObject, eventdata, handles) 

% global variables
global stData cType dForm

% Get default command line output from handles structure
varargout{1} = stData;
varargout{2} = cType;
varargout{3} = dForm;

%-------------------------------------------------------------------------%
%                        FIGURE CALLBACK FUNCTIONS                        %
%-------------------------------------------------------------------------%

% --- Executes on updating editFixedValue
function editFixedValue_Callback(hObject, eventdata, handles)

% initialisations
nwVal = str2double(get(hObject,'string'));

% determines if the new value is valid
if (chkEditValue(nwVal,1e10*[-1 1],0))
    % if valid, then update the fixed value
    setappdata(handles.figStatTest,'fxVal',nwVal)
else
    % resets the editbox string to the last valid value
    set(hObject,'string',num2str(getappdata(handles.figStatTest,'fxVal')))
end
    
% --------------------------------- %
% --- PROGRAM CONTROL FUNCTIONS --- %
% --------------------------------- %

% --- Executes on button press in buttonStart.
function buttonStart_Callback(hObject, eventdata, handles)

% global variables
global stData cType dForm

% memory allocation
sInfo = NaN(1,2);

% retrieves the data structs
iRow = getappdata(handles.figStatTest,'iRow');
hGUI = getappdata(handles.figStatTest,'hGUI');
pStr = getappdata(handles.figStatTest,'pStr');
pType = getappdata(handles.figStatTest,'pType');

% retrieves the data struct
iData = getappdata(hGUI.figDataOutput,'iData');
pData = getappdata(hGUI.figDataOutput,'pData');
plotD = getappdata(hGUI.figDataOutput,'plotD');

% determines if the statistics panel has been removed
if (~isempty(getappdata(handles.figStatTest,'lStr')))
    % if not, return the selected index
    [sInfo(1),cType] = deal(get(handles.listStatTest,'value'));
else
    % only one test type
    cType = 1;
end

% retrieves the output data type
sInfo(2) = getappdata(handles.figStatTest,'fxVal');

% determines if the statistical test had been run
if (isempty(iData.Y{1}{iRow}{cType}))
    % if not, then run the statistical test data array setup
    stData = setupStatsArray(iData,plotD,pType,pStr,sInfo);
else
    % otherwise, retrieves the previously calculated statistical test data 
    stData = iData.Y{1}{iRow}{cType};
end

% sets the data output format
dForm = get(handles.listOutputData,'value');

% deletes the window
delete(handles.figStatTest)

% --- Executes on button press in buttonClose.
function buttonClose_Callback(hObject, eventdata, handles)

% global variables
global stData cType dForm
[stData,cType,dForm] = deal([]);

% deletes the window
delete(handles.figStatTest)

% ----------------------------------------------------------------------- %
% ---                      STATISTICAL FUNCTIONS                      --- %
% ----------------------------------------------------------------------- %

% --- sets up the stats array for the CSV output file --- %
function tData = setupStatsArray(iData,plotD,pType,pStr,sInfo)

% creates a loadbar
h = ProgressLoadbar('Calculating Statistical Significance Test...');

% loops through each of the metrics calculating the stats
switch (pType{1})
    case ('CompSumm') % case is ANOVA from summary data
        % retrieves the summary statistics
        Y_mn = cellfun(@(x)(x{1}),field2cell(plotD,[pStr,'_mn']));
        Y_sem = cellfun(@(x)(x{1}),field2cell(plotD,[pStr,'_sem']));
        N = cellfun(@(x)(x{1}),field2cell(plotD,'Hist'));
        
        % performs the test
        tData = compSummStatsTest(Y_mn,sqrt(N).*Y_sem,N);
    case ('Comp') % case is a between group type comparison
        tData = compStatsTest(field2cell(plotD,pStr),sInfo(1));
    case ('CompMulti')
        tData = compStatsTestMulti(field2cell(plotD,pStr),sInfo(1));
    case ('FixedComp')
        tData = fixedValStatsTest(field2cell(plotD,pStr),sInfo(1),sInfo(2));        
    case {'TTest','ZTest'}
        tData = calcTTestStats(iData,plotD,pStr,pType,false);                    
    case {'TTestGroup','ZTestGroup'}
        tData = calcTTestStats(iData,plotD,pStr,pType,true); 
    case {'Sim','SimNorm'}
        tData = setupSimArray(field2cell(plotD,pStr),pType,false);           
    case {'SimDN','SimNormDN'}
        tData = setupSimArray(field2cell(plotD,pStr),pType,true);     
    case {'GOF'}
        tData = setupGOFArray(plotD,pStr,pType);     
end

% closes the loadbar
try; delete(h); end

% --------------------------------- %
% --- GOF & SIMILIARITY MATRICS --- %
% --------------------------------- %

% --- sets up the GOF metric array
function tData = setupGOFArray(plotD,pStr,pType)

% memory allocation
tData = struct('mStr',[],'gofY',[],'Test','GOF Statistics',...
               'Type',pType{1},'pStr',[]);

% retrieves the data values
Data = cell2cell(field2cell(plotD,pStr)',0);
           
% sets the struct fields
tData.mStr = {'SoS Error','R2','Error DOF','R2 DOF Adjusted','RMS Error'}';
tData.gofY = cellfun(@(y)(num2cell(cell2mat(cellfun(@(x)(field2cell(y,x,1)),...
                        fieldnames(Data{1}),'un',0)))),Data,'un',0);
                    
% adds in the secondary header (if required)                    
if (length(pType) > 1)
    tStr = eval(sprintf('plotD(1).%s',pType{2}));
    tData.gofY = cellfun(@(x)([tStr(:)';x]),tData.gofY,'un',0);
    tData.mStr = [{''};tData.mStr];
end

% converts the numerical values to strings
for i = 1:numel(tData.gofY)
    % determines the numerical values
    iiN = find(cellfun(@isnumeric,tData.gofY{i}));
    
    % converts the numerical values to strings
    A = cell2mat(tData.gofY{i}(iiN));
    isI = mod(A,1) == 0;
    
    % converts the integer/float values
    tData.gofY{i}(iiN(isI)) = num2strC(A(isI),'%i');
    tData.gofY{i}(iiN(~isI)) = num2strC(A(~isI),'%.4f');
end

% --- sets up the similarity data array
function tData = setupSimArray(Data,pType,sepDN)

% sets the data array (normalised if specified)
[Data,isNorm] = deal(Data{1},strcmp(pType{1},'SimNormDN'));
if (isNorm); DataN = normImg(Data); end

% sets the data into a single array
[nApp,N] = deal(size(Data,1)/(1+sepDN),1+sepDN);
pStr = repmat({cell(nApp)},1,1+isNorm);
for i = 1:nApp
    for j = 1:nApp
        % sets the row/column indices
        [iR,iC] = deal((i-1)*N+(1:N),(j-1)*N+(1:N));
        
        % sets the values into the string array
        pStr{1}{i,j} = cellfun(@(x)(sprintf('%.4f',x)),...
                                num2cell(Data(iR,iC)),'un',0);        
        if (isNorm)
            pStr{2}{i,j} = cellfun(@(x)(sprintf('%.4f',x)),...
                                num2cell(DataN(iR,iC)),'un',0);        
        end
    end
end

% sets the arrays into the data struct
tData = struct('pStr',[],'Test','Similarity','Type',pType{1});
tData.pStr = pStr;

% ------------------------ %
% --- T-TEST FUNCTIONS --- %
% ------------------------ %

% --- calculates the day/night separation comparison stats for the metric
%     given by pStr. data is grouped, time-wise, by the parameter given in
%     pStr. test is dependent on the string given by sStr (T-Test/Z-Test)
function [p,ok] = calcTTestStats(iData,plotD,pStr,pType,sepDN)

% initialisations
[pTol,ok] = deal(0.05,true);
p = struct('p',[],'pStr',[],'isSig',[],'pTol',pTol,'Test',[],'Type',pType{1});

% %
% ind = strcmp(field2cell(iData.yVar,'Var'),pStr);
% Stats = iData.yVar(ind).Stats;
% Tgrp = eval(sprintf('plotD(1).%s;',Stats{2}));
% if (isnumeric(Tgrp)); Tgrp = num2cell(Tgrp); end

% sets the metric and parameter strings
switch (pType{1})
    case {'TTestGroup','TTest'}
        [pStrM,pStrS,p.Test] = deal([pStr,'_mn'],[pStr,'_sem'],'T-Test');
    case {'ZTestGroup','ZTest'}
        [pStrM,pStrS,p.Test] = deal([pStr,'_P'],[pStr,'_N'],'Z-Test');
end

%
[Mu0,SE0] = field2cell(plotD,{pStrM,pStrS});
if (iscell(Mu0{1}))
    Mu0 = cellfun(@(x)(cell2cell(x)),Mu0,'un',0);
    SE0 = cellfun(@(x)(cell2cell(x)),SE0,'un',0);
end

% sets the mean/standard error values
[Mu,SE] = deal(cell2mat(Mu0(:)'),cell2mat(SE0(:)'));         

% exits the function
if (length(Mu) < 2)
    ok = false; return
end

% calculates the P-scores and the significance strings
switch (pType{1})
    case {'TTestGroup','TTest'}
        [P,~,Pstr] = calcTTestPScore(Mu(:),SE(:));
    case {'ZTestGroup','ZTest'}
        [P,~,Pstr] = calcPropPScore(Mu(:),SE(:));
end

% memory allocation
nGrp = length(plotD);
nSub = size(P,1)/nGrp;
[p.p,p.pStr,p.isSig] = deal(cell(nGrp));

% sets the total stats array from the data
for i = 1:nGrp
    % sets the row/index offset
    iR0 = (i-1)*nSub+(1:nSub);    
    
    % sets the stats array for the sub-regions
    for j = 1:nGrp
        % sets the column indices
        iC0 = (j-1)*nSub+(1:nSub);
       
        % sets the values into the string array
        p.pStr{i,j} = cellfun(@(x)(sprintf('%.4f',x)),...
                                num2cell(P(iR0,iC0)),'un',0);        
        p.pStr{i,j}(isnan(P(iR0,iC0))) = {'N/A'};

        % sets the data for the other data structs
        p.p{i,j} = P(iR0,iC0);
        p.isSig{i,j} = P(iR0,iC0) <= pTol;
        p.pStr{i,j} = setPValueStrings(p.p{i,j});        
    end
end

% -------------------------------------- %
% --- PAIR-WISE COMPARISON FUNCTIONS --- %
% -------------------------------------- %

% --- 
function tData = compSummStatsTest(Y_mn, Y_sd, N)

% global variables
global pTolT
[pTol,pTolT] = deal(0.05);

% initialisations
[nTot, nGrp] = deal(sum(N), length(Y_mn));
[df1, df2, pStr] = deal(nGrp-1, nTot-nGrp, repmat({'N/A'},nGrp,nGrp));

% memory allocation
[p,isSig,isOK] = deal(NaN(nGrp),false(nGrp),true(nGrp,1));
tData = struct('Test',[],'p',[],'isSig',[],'pStr',[],'pTol',pTol,'Type',[]);
[tData.Type,tData.Test] = deal('CompSumm','ANOVA');

% calculates the total mean and mean differences
Y_mnTot = sum(N.*Y_mn)/nTot;
dY_mn = Y_mn-Y_mnTot;

% calculates the F-ratio
sB2 = (sum(N.*(dY_mn).^2)/df1);
sW2 = (sum((N-1).*Y_sd.^2)/df2);
p1 = 1 - fcdf(sB2/sW2, df1, df2);

% if the p-value is significant
if (p1 <= pTol)
    % creates the statistics struct
    gnames = strjust(num2str((1:length(Y_mn))'),'left');
    stats = struct('gnames',gnames,'n',N(:)','source','anova1',...
                   'means',Y_mn(:)','df',df2,'s',sqrt(sW2));
    
    % if significance is determined, then 
    c = multcompare(stats,'alpha',pTol,'display','off');

    % sets the p-values into the array
    indL = sub2ind(size(p),c(:,2),c(:,1));
    indU = sub2ind(size(p),c(:,1),c(:,2));
    [p(indL),p(indU)] = deal(c(:,6));

    % calculates the significance of the p-values
    isSig = p <= pTol;
end

% only determine significance levels if there are any valid p-values
if (any(~isnan(p(:))))
    for i = 1:(nGrp-1)
        for j = (i+1):nGrp
            % determines the level of significance
            if (all(isOK([i j])))
                hL = log10(p(i,j));
                if (hL < -3)
%                     [hL,pL] = deal(floor(hL),p(i,j)/(10^floor(hL)));
                    [pStr{i,j},pStr{j,i}] = deal(sprintf('%1.3E',p(i,j)));
                else
                    [pStr{i,j},pStr{j,i}] = deal(sprintf('%.4f',p(i,j)));
                end            
            end
        end
    end
end
    
% sets the final arrays into the statistical data struct
[tData.p,tData.isSig,tData.pStr] = deal(p,isSig,pStr);

% --- calculates the within/between group comparison test
function tData = compStatsTestMulti(DataF,sInfo)

% parameters
Nmin = 10;

% ensures the data is stored as row vectors
if (iscell(DataF{1}{1}))
    for i = 1:length(DataF)    
        DataF{i} = cellfun(@(x)(x(:)'),DataF{i},'un',0);
    end
end

% retrieves the number of genotype groups
nApp = length(DataF);
if (iscell(DataF{1}{1}))
    N = size(DataF{1}{1},2);
else
    N = length(DataF{1});
end

% sets the group indices
ind = cellfun(@(x)((x-1)*N + (1:N)),num2cell(1:nApp),'un',0);

% sets the data into a single cell array
Data = cell(1,length(DataF));
for i = 1:length(DataF)
%     Ytmp = cellfun(@(x)(cell2mat(cell2cell(x,1))),...
%                 num2cell(num2cell(DataF{i},1),3),'un',0);    
    
    if (iscell(DataF{1}{1}))
        Ytmp = DataF{i}(~cellfun(@isempty,DataF{i}));
        Data{i} = cell2mat(Ytmp(:));
    else
        Ytmp = DataF{i}; %(~cellfun(@isempty,DataF{i}));
        if length(Ytmp{1}) == 1
            Data{i} = combineNumericCells(Ytmp,0);                    
        else
            Data{i} = cell2mat(Ytmp);
        end        
%         Data{i} = cellfun(@(x)(combineNumericCells(x,0)),num2cell(Ytmp,2),'un',0);
    end
end

% combines the data into a single data array
Data = combineNumericCells(Data,0);

% removes any the columns where the data count is less than tolerance
Data(:,sum(~isnan(Data),1) < Nmin) = NaN;

% calculates the comparison test
tData = compStatsTest(Data,sInfo,1);

% seperates the data by the group types
[pNw,pStrNw] = deal(cell(nApp));
for i = 1:nApp
    for j = 1:nApp
        pNw{i,j} = tData.p(ind{i},ind{j});
        pStrNw{i,j} = tData.pStr(ind{i},ind{j});
    end    
end

% replaces the signficance arrays into the test data struct
[tData.p,tData.pStr] = deal(pNw,pStrNw);

% --- performs a pair-wise statistical comparison test on the data array,
%     Data. the tests performed are as follows:
%
%     => runs the Anderson-Darling test to check for normality of the data
%      -> if data is normal and within variance tolerance, then calculate
%         the one sided ANOVA with a post-hoc Tukey-Kramer test
%      -> otherwise, calculate the Kruskal-Wallis test with a post-hoc
%         Mann-Whitney U test
function tData = compStatsTest(Data,sInfo,varargin)

% global variables
global pTolT
[pTol,pTolT] = deal(0.05);

% determines the number of genotypes within the dataset
if (nargin == 2)
    [nApp,nGrp] = deal(length(Data));
    isOK = true(nApp,1);
else
    nGrp = size(Data,2);
    isOK = any(~isnan(Data),1);
end

% memory allocation and parameters
[vRatioMax,typeStr] = deal(4,{'Comp','CompMulti'});
[isNorm,vData] = deal(true(nGrp,1),zeros(nGrp,1));
[p,isSig] = deal(NaN(nGrp),false(nGrp));
tData = struct('Test',[],'p',[],'isSig',[],'pStr',[],'pTol',pTol,'Type',[]);

% sets the statistic test type
tData.Type = typeStr{1+(nargin>2)};
           
% combines the data into a single data array
pStr = repmat({'N/A'},nGrp,nGrp);
if (nargin == 2)
    if (iscell(Data{1}))
        DataN = combineNumericCells(Data);
    else
        Data = cellfun(@(x)(x(:)),Data,'un',0);
        DataN = combineNumericCells(Data(:)');
    end
else
    DataN = Data;
end

% ensures the data is stored in numerical arrays (within each cell)
if (iscell(Data))
    for i = 1:nGrp
        if (iscell(Data{i}))
            Data{i} = cell2mat(Data{i}(:));
        end
    end
end

% sets the normalisation/variance ratios depending on the test type
switch (sInfo)
    case (1) % case is determining from normality test
        % performs the Anderson-Darling test and calculates the variance
        for i = 1:nGrp
            if (iscell(Data))                
                isNorm(i) = AnDartest(Data{i}(:),pTol);    
                vData(i) = var(Data{i}(:),'omitnan');
            else
                isNorm(i) = AnDartest(Data(:,i),pTol);    
                vData(i) = var(Data(:,i),'omitnan');
            end
        end

        % calculates the variance ratio between the max/min data variances
        vRatio = max(vData)/min(vData);
    case (2) % case is using the ANOVA
        vRatio = 0;
    case (3) % case is using Kruskal-Wallis
        isNorm(:) = false;        
end
        
% determines if the dataset mets the normal distribution criteria
if (all(isNorm) && (vRatio <= vRatioMax))
    % if so, then perform the one-sided ANOVA test
    tData.Test = 'ANOVA';
    [p1,~,stats] = anova1(DataN,[],'off');
    if (p1 <= pTol)
        % if significance is determined, then perform the post-hoc test
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
    [p1,tData.Test] = deal(kruskalwallis(DataN,[],'off'),'K-W');
    if (p1 <= pTol)
        % calculates the Dunn-Sidak coeffiecient
        C = nGrp*(nGrp-1)*0.5;
        tData.pTol = 1 - (power((1-pTol),1/C)); 
        
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
                    [isSig(m,n),isSig(n,m)] = deal(p(m,n) <= tData.pTol);
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
%                     [hL,pL] = deal(floor(hL),p(i,j)/(10^floor(hL)));
                    [pStr{i,j},pStr{j,i}] = deal(sprintf('%1.3E',p(i,j)));
                else
                    [pStr{i,j},pStr{j,i}] = deal(sprintf('%.4f',p(i,j)));
                end            
            end
        end
    end
end
    
% sets the final arrays into the statistical data struct
[tData.p,tData.isSig,tData.pStr] = deal(p,isSig,pStr);

% --- performs a fixed value statistical comparison test on the data array,
%     Data. the tests performed are as follows:
%
%     => runs the Anderson-Darling test to check for normality of the data
%      -> if data is normal, then perform a one-sided t-test to determine
%         if the mean is significantly different from fxVal
%      -> otherwise, perform a Wilcoxon signed rank test to determine if
%         the median is signicantly different from fxVal
function tData = fixedValStatsTest(Data,sInfo,fxVal)

% determines the number of genotypes within the dataset
nApp = length(Data);

% memory allocation and parameters
[pTol,W] = deal(0.05,1.5);
tData = struct('Test',[],'p',[],'isSig',[],'pStr',[],...
               'pTol',pTol,'Type','FixedComp','fxVal',fxVal);
[isNorm,vData,p] = deal(true(nApp,1),zeros(nApp,1),NaN(1,nApp));
Test = cell(nApp,1);

% combines the data into a single data array
pStr = repmat({'N/A'},1,nApp);

% performs the Anderson-Darling test and calculates the variance
for i = 1:nApp
    [isNorm(i),vData(i)] = deal(AnDartest(Data{i},pTol),var(Data{i}));
end

% sets the normalisation/variance ratios depending on the test type
switch (sInfo)
    case (1) % case is determining from normality test
        % performs the Anderson-Darling test and calculates the variance
        for i = 1:nApp
            if (iscell(Data))
                isNorm(i) = AnDartest(Data{i},pTol);    
                vData(i) = var(Data{i});
            else
                isNorm(i) = AnDartest(Data(:,i),pTol);    
                vData(i) = var(Data(:,i));
            end
        end
    case (3) % case is using Kruskal-Wallis
        isNorm(:) = false;        
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
        ii = (Data{2} > (Y(1)-W*diff(Y))) & (Data{2} < (Y(2)+W*diff(Y)));
        
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
%             [hL,pL] = deal(floor(hL),p(i)/(10^floor(hL)));
            pStr{i} = sprintf('%1.3E',p(i));
        else
            pStr{i} = sprintf('%.4f',p(i));
        end
    end
end

% sets the final arrays into the statistical data struct
[tData.p,tData.isSig,tData.pStr,tData.Test] = deal(p,isSig,pStr,Test);

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
    for i = find(ii')
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
                  'P-Significance',sData.pTol;...
                  'Test Type',sData.Test};            
        case ('Fixed')
            BB = combineCellArrays([{'Metric Name'},sData.Metric],0);
            BB = combineCellArrays(BB,[{'P-Value Significance'},sData.pTol],0);                        
            BB = combineCellArrays(BB,[{'Fixed Value'},sData.fxVal],0);
            BB = combineCellArrays(BB,[{'Comparison Test Type'},sData.Test'],0);                        
        case ('CompMulti')
            CC = {'Metric Name',sData.Metric;...
                  'P-Significance',sData.pTol;...
                  'Test Type',sData.Test};  
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

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% ------------------------------ %
% --- GUI PROPERTY FUNCTIONS --- %
% ------------------------------ %

% --- initialises the GUI objects 
function handles = initGUIObjects(handles,lStr)

% parameters and initialisations
[Y0,resetObj] = deal(10,false);
fxVal = getappdata(handles.figStatTest,'fxVal');

% sets the output data listbox string
switch (getappdata(handles.figStatTest,'tType'))
    case (0) % case is no output data string
        outStr = [];
    case (1) % case is the significance strings
        outStr = {'Test P-Value Strings';...
                  'Test Significance Strings';...
                  'Both Data Output Formats'};
    case (2) % case is the raw/normalised data values
        outStr = {'Raw Data Values';...
                  'Normalised Data Values'};  
end

% sets the output data listbox properties
if isempty(outStr)
    % no output string, so set an empty array
    set(setObjEnable(handles.listOutputData,'off'),'string',[])
    setPanelProps(handles.panelOutputData,'off')
else
    % otherwise, set the output string
    set(handles.listOutputData,'string',outStr)
end

% determines, if the list strings were provided (remove listbox if not)
if isempty(lStr)    
    % retrieves the position of the test panel and figure    
    fPos = get(handles.figStatTest,'position');    
    pPosS = get(handles.panelStatTest,'position');      
    
    % deletes the panel
    delete(handles.panelStatTest)
    
    % resizes the GUI   
    resetObj = true;
    resetObjPos(handles.figStatTest,'height',fPos(4)-(Y0+pPosS(4)));
else
    % otherwise, set the listbox strings
    set(handles.listStatTest,'string',lStr)
    
    % determines if a valid fixed value was input
    if (isnan(fxVal))
        % if not, then remove the editbox
        ePos = get(handles.editFixedValue,'position');
        lPos = get(handles.listStatTest,'position');        
        
        % deletes the fixed value text/editbox objects
        delete(handles.textFixedValue)        
        delete(handles.editFixedValue)        
        
        % resets the object positions/dimensions
        resetObj = true;
        resetObjPos(handles.figStatTest,'height',-(ePos(4)+Y0/2),1)        
        resetObjPos(handles.panelStatTest,'height',-(ePos(4)+Y0/2),1)        
        resetObjPos(handles.listStatTest,'bottom',Y0)
        resetObjPos(handles.textStatTest,'bottom',lPos(4)+(3/2)*Y0)
    else
        % otherwise, set the fixed value editbox string
        set(handles.editFixedValue,'string',num2str(fxVal))
    end
end

% determines if the other objects need to be repositioned
if (resetObj)
    % retrieves the control button positions
    bPos = get(handles.buttonStart,'position');    
    
    % resets the button and data output panel positions
    resetObjPos(handles.buttonStart,'bottom',Y0);
    resetObjPos(handles.buttonClose,'bottom',Y0);
    resetObjPos(handles.panelOutputData,'bottom',2*Y0+bPos(4));       
end

% --- sets the p-value string
function pStr = setPValueStrings(p)

% memory allocation
pStr = cell(size(p));

% loops through each of the elements setting the p-value strings
for i = 1:numel(p)
    if (isnan(p(i)))
        % p-value is a NaN value
        pStr{i} = 'N/A';
    else
        % otherwise, determine the logarithmic index
        hL = log10(p(i));
        if (hL < -3)
            % if low, set a standard form string
            pStr{i} = sprintf('%1.3E',p(i));
        else
            % otherwise, set the original value
            pStr{i} = sprintf('%.4f',p(i));
        end
    end
end
