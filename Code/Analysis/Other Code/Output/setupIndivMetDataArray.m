% --- sets up the population metric data array
function Data = setupIndivMetDataArray(handles,iData,pData,plotD,Y,iOrder)

% ------------------------------------------- %
% --- INITIALISATIONS & MEMORY ALLOCATION --- %
% ------------------------------------------- %

% initialisations 
appOut = iData.appOut(:,iData.cTab);
[nApp,nMetS,sepGrp] = deal(sum(appOut),length(iOrder),iData.sepGrp);
sepDay = getCheckValue(handles.checkSepByDay);
sepApp = getCheckValue(handles.checkSepByApp) || (nApp == 1);
sepExp = getCheckValue(handles.checkSepByExpt) && (iData.sepExp);
numGrp = getCheckValue(handles.checkNumGroups);
isHorz = get(handles.radioAlignHorz,'value');

% sets the global metric indices
Type = field2cell(iData.yVar,'Type',1); 
mIndG = find(Type(:,3));

% retrieves the fly acceptance/rejection flags
snTot = getappdata(handles.figDataOutput,'snTot');
flyok = arrayfun(@(x)(groupAcceptFlags(x)),snTot(:),'un',0)';
for i = 1:length(flyok); flyok{i} = flyok{i}(appOut); end

% sets the output type
% = 1 - all day combined
% = 2 - all day combined/individual experiments
% = 3 - individual combined/all experiments combined
% = 4 - individual days/expt
outType = 2*sepExp + sepDay + 1;
YR = reduceDataArray(Y(:,outType),appOut,iOrder,sepGrp);
szY = cellfun(@(x)([size(x,1),size(x,2),size(x,3)]),YR{1},'un',0);

% array indexing and other initialisations
[nGrp,ii,VarX] = detDataGroupSize(iData,plotD,mIndG(iOrder),1);
[nGrpG,nExp] = deal(1+sepGrp,size(YR{1}{1},2));
[nGrpU,iiU] = deal(unique(nGrp,'stable'),unique(ii,'stable'));
[appName,indG] = deal(iData.appName(appOut),cell(1,6));

% sets the output fly indices/counts
[isOKF,nOKF] = deal(cell(nApp,length(nGrpU)));
for i = 1:nApp
    for j = 1:length(nGrpU)
        isOKF{i,j} = repmat(cellfun(@(x)(...
                    repmat(find(x{i}),nGrpG,1)),flyok,'un',0),nGrpU(j),1);    
        nOKF{i,j} = cellfun(@(x)(length(x)/nGrpG),isOKF{i,j},'un',0);    
    end
end
                        
% --------------------------------- %
% --- TABLE HEADER STRING SETUP --- %
% --------------------------------- %

% sets the metric header strings
indGrpT = logical([~sepApp,true(1,2),(nExp>1),(any(nGrp>1)),sepGrp]);
mStrB = reshape(iData.fName(mIndG(iOrder)),1,length(iOrder));

% sets the main grouping titles
mStrT = {'Group Name','Fly Number','Local Index',...
         'Experiment','Bin Group','Sub-Group'};
mStrT = mStrT(indGrpT);

% sets the day separation header string
if (sepDay)
    % sets the complete header string for all the days
    if (sepGrp)
        xiD = num2cell(1:max(cellfun(@(x)(size(x{1},2)),YR{1}{1}(1,:))));
    else
        xiD = num2cell(1:max(cellfun(@(x)(size(x,2)),YR{1}{1}(1,:))));
    end
        
    nDay = max(detExptDayDuration(snTot));
    mStrD = cellfun(@(x)(sprintf('Day #%i',x)),xiD,'un',0);
    mStrD = repmat(combineCellArrays({NaN},mStrD,0),1,nMetS);
    
    % sets the final header array
    mStrD(1,1+(0:xiD{end}:(nMetS-1)*xiD{end})) = mStrB;
    if (~sepApp)
        mStrT = combineCellArrays({NaN},mStrT,0);
    end
else
    %
    if (sepApp)
        mStrD = combineCellArrays({NaN},mStrB,0);
    else
        mStrD = mStrB;
    end
end

% ------------------------------ %
% --- TABLE DATA ARRAY SETUP --- %
% ------------------------------ %

% sets the grouping indices (if not separating by genotype group)
if ((~sepApp) && (nApp > 1))
    xi0 = num2cell(1:nApp)';
    A0 = cell(size(nOKF));
    
    for i = 1:size(A0,2)
        A0(:,i) = cellfun(@(x,y)(cellfun(@(xx)(y*ones(xx*nGrpG,1)),...
                        x,'un',0)),nOKF(:,i),xi0,'un',0);
    end
                
    % sets the final group name array
    if (sepApp)
        % table data is separated by apparatus
        indG{1} = cellfun(@(x)(appName(cell2mat(x(:)))),A0,'un',0);
    else
        % table data is grouped together
        indG{1} = cellfun(@(x)(appName(cell2mat(x(:)))),A0,'un',0);
        indG{1} = cellfun(@(x)(cell2cell(x,1)),num2cell(indG{1},1),'un',0);
    end
end

% sets the overall fly number indexing 
A1 = cell(nApp,length(nGrpU));
for j = 1:length(nGrpU)
    iOfs0 = 0;
    for i = 1:nApp
        % sub-cell array memory allocation
        [A1{i,j},iOfs] = deal(cell(nGrpU(j)*nGrpG,nExp),0+iOfs0);

        % sets the indices for each of the groups
        for k = find(cellfun(@(x)(x>0),nOKF{i}(1,:)))
            A1{i,j}(:,k) = repmat({(1:nOKF{i}{1,k})'+iOfs},nGrpU(j)*nGrpG,1);
            iOfs = iOfs + nOKF{i}{1,k};
        end

        % increments the offset (depending if separating by apparatus)
        iOfs0 = (~sepApp)*iOfs;
    end
end

% sets the final fly number index array
if (sepApp)
    % sets the overall fly indices
    indG{2} = cellfun(@(x)(num2cell(cell2mat(x(:)))),A1,'un',0);        
    indG{2} = cellfun(@(x)(num2strC(x,'%i')),indG{2},'un',0);    
    
    % sets the individual experiment fly indices
    indG{3} = cellfun(@(x)(num2cell(cell2mat(x(:)))),isOKF,'un',0);        
    indG{3} = cellfun(@(x)(num2strC(x,'%i')),indG{3},'un',0);    
else
    % sets the overall fly indices
    indG{2} = cellfun(@(y)(num2cell(cell2mat(cellfun(@(x)(...
                    cell2mat(x(:))),y,'un',0)))),num2cell(A1,1),'un',0);        
    indG{2} = cellfun(@(x)(num2strC(x,'%i')),indG{2},'un',0);
    
    % sets the individual experiment fly indices
    indG{3} = cellfun(@(y)(num2cell(cell2mat(cellfun(@(x)(...
                    cell2mat(x(:))),y,'un',0)))),num2cell(isOKF,1),'un',0);                
    indG{3} = cellfun(@(x)(num2strC(x,'%i')),indG{3},'un',0);
end

% sets the experiment indices (if there are multiple experiments)
if (nExp > 1)
    A3 = cell(nApp,length(nGrpU));
    for i = 1:length(nGrpU)
        xi3 = num2cell(repmat((1:nExp),nGrpU(i),1));    
        A3(:,i) = cellfun(@(x)(cellfun(@(xx,yy)(xx*ones(yy*nGrpG,1)),...
                        xi3,x,'un',0)),nOKF(:,i),'un',0);
    end

    % sets the final experiment index array
    if (sepApp)
        % table data is separated by apparatus
        indG{4} = cellfun(@(x)(num2cell(cell2mat(x(:)))),A3,'un',0);        
        indG{4} = cellfun(@(x)(num2strC(x,'%i')),indG{4},'un',0);
    else
        % table data is grouped together
        indG{4} = cellfun(@(y)(num2cell(cell2mat(cellfun(@(x)(...
                    cell2mat(x(:))),y,'un',0)))),num2cell(A3,1),'un',0);                
        indG{4} = cellfun(@(x)(num2strC(x,'%i')),indG{4},'un',0);
    end
end

% sets the bin group indices (if there are multiple bin groups)
if (any(nGrpU > 1))
    A4 = cell(nApp,length(nGrpU));
    for i = 1:length(nGrpU)
        xi4 = num2cell(repmat((1:nGrpU(i))',1,nExp)); 
        A4(:,i) = cellfun(@(x)(cellfun(@(xx,yy)(xx*ones(yy*nGrpG,1)),...
                        xi4,x,'un',0)),nOKF(:,i),'un',0);    
    end

%     % retrieves the group names
%     iiG = strcmp(field2cell(iData.xVar,'Type'),'Group');
%     Xgrp = eval(sprintf('plotD.%s',iData.xVar(iiG).Var));                    
                    
    % sets the final experiment index array
    if (sepApp)
        % table data is separated by apparatus        
        indG{5} = cellfun(@(x)(num2cell(cell2mat(x(:)))),A4,'un',0);        
        if (~numGrp)
            indG{5} = cellfun(@(x,y)(cellfun(@(xx)(y{xx}),x,'un',0)),...
                        indG{5},repmat(VarX(:)',size(indG{5},1),1),'un',0);
        else
            indG{5} = cellfun(@(x)(num2strC(x,'%i')),indG{5},'un',0);
        end
    else
        % table data is grouped together
        indG{5} = cellfun(@(y)(num2cell(cell2mat(cellfun(@(x)(...
                    cell2mat(x(:))),y,'un',0)))),num2cell(A4,1),'un',0);                
        if (~numGrp)
            indG{5} = cellfun(@(x,y)(cellfun(@(yy)(x{yy}),y,'un',0)),...
                                    VarX(:)',indG{5},'un',0);
        else
            indG{5} = cellfun(@(x)(num2strC(x,'%i')),indG{5},'un',0);
        end
    end                    
end

% sets the secondary group indices (if they exist)
if (sepGrp)
    %
    xi4 = num2cell(repmat((1:nGrpG)',nGrp,nExp)); 
    nOKF2 = cellfun(@(x)(repmat(x,nGrpG,1)),nOKF,'un',0);
    
    %
    iiG2 = strcmp(field2cell(iData.xVar,'Type'),'Other');
    Xgrp2 = eval(sprintf('plotD.%s',iData.xVar(iiG2).Var));
    
    %
    A5 = cellfun(@(x)(cellfun(@(xx,yy)(xx*ones(yy,1)),...
                                xi4,x,'un',0)),nOKF2(:),'un',0);    
    
    % sets the final experiment index array
    if (sepApp)
        % table data is separated by apparatus        
        indG{6} = cellfun(@(x)(num2cell(cell2mat(x(:)))),A5,'un',0); 
        if (~numGrp)
            indG{6} = cellfun(@(x)(cellfun(@(y)(...
                                Xgrp2{y}),x,'un',0)),indG{6},'un',0);
        else
            indG{6} = cellfun(@(x)(num2strC(x,'%i')),indG{6},'un',0);
        end                     
    else
        % table data is grouped together
        indG{6} = cellfun(@(y)(num2cell(cell2mat(cellfun(@(x)(...
                    cell2mat(x(:))),y,'un',0)))),num2cell(A5,1),'un',0);                               
        if (~numGrp)
            indG{6} = cellfun(@(x)(cellfun(@(y)(...
                                Xgrp2{y}),x,'un',0)),indG{6},'un',0);
        else
            indG{6} = cellfun(@(x)(num2strC(x,'%i')),indG{6},'un',0);
        end        
    end
end

% combines the header and data into a single array
if (sepApp)
    % case is the table data is separated by apparatus
    [YT,indG] = deal(cell(nApp,length(nGrpU)),indG(~cellfun(@isempty,indG)));
    
    % combines the arrays into the final array
    for i = 1:numel(YT)
        YT{i} = [mStrT;cell2cell(cellfun(@(x)(x{i}),indG,'un',0),0)];
    end
else
    % case is the table data is grouped together
    xiU = num2cell(1:length(nGrpU));
    YT = cellfun(@(y)([mStrT;cell2cell(cellfun(@(x)(x{y}),...
                indG(~cellfun(@isempty,indG)),'un',0),0)]),xiU,'un',0);
end

% ------------------------------- %
% --- METRIC DATA ARRAY SETUP --- %
% ------------------------------- %

% case is separating the metric data by apparatus
YM = cell(nApp,1);        
for i = 1:nApp
    % sub-array memory allocation
    [YMtmp,YM{i}] = deal(cell(1,nMetS),cell(1,length(nGrpU)));

    % retrieves the data from the metric data arrays
    for j = 1:nMetS
        % retrieves and sets the data (for the current metric)
        Ytmp = cell(1+sepGrp,size(YR{j}{i},1),nExp);
        if (sepGrp)
            A = cellfun(@(x)(cell2cell(x)),num2cell(YR{j}{i},1),'un',0);
        else
            A = num2cell(YR{j}{i},1);
        end
        
        k = iiU == ii(j);
        for iExp = 1:nExp
            for iGrp = 1:(1+sepGrp)            
                Ytmp(iGrp,:,iExp) = cellfun(@(x,y,z)(x(y(1:z),:)),...
                            A{iExp}(:,iGrp),isOKF{i,k}(:,iExp),...
                            nOKF{i,k}(:,iExp),'un',0)';
            end
        end        
        
        YMtmp{j} = cell2cell(Ytmp(:));   
        
    end

    % combines the sub cell-arrays into a single array
    for j = 1:length(nGrpU)
        YM{i}{j} = cell2cell(YMtmp(ii == iiU(j)),0);
        if (sepDay) && (size(YM{i}{j},2) < xiD{end})
            % ensures the metric data array aligns with the correct number 
            % of days (for the header string)
            Ygap = num2cell(NaN(1,xiD{end}-size(YM{i}{j},2)));
            YM{i}{j} = combineCellArrays(YM{i}{j},Ygap);
        end        
    end
end

% ------------------------- %
% --- FINAL ARRAY SETUP --- %
% ------------------------- %

% sets the 
if (sepApp)
    % memory allocation
    [DataF,YM] = deal([],cell2cell(YM));
    
    % sets the final data for each apparatus
    for i = 1:nApp
        for j = 1:length(nGrpU)
            % sets the title and combines it with the new metric data
            k = (iiU(j) == ii);
            if (sepDay)
                k = cellfun(@(x)((x-1)*nDay+(1:nDay)),num2cell(k),'un',0);
                k = cell2cell(k,0);
            end
            
            DataNw = combineCellArrays({NaN},YT{i,j},0);                
            DataNw = combineCellArrays(DataNw,[mStrD(:,k(1:size(YM{i,j},2)));YM{i,j}],1);        
            DataNw(1,1) = appName(i);        

            % sets the new metric data into the full array
            if ((i == 1) && (j == 1))
                % if the first group, set the data as is
                DataF = DataNw;
            else
                % otherwise, add in a vertical gap between the groups
                DataF = combineCellArrays(DataF,{NaN},isHorz);
                DataF = combineCellArrays(DataF,DataNw,isHorz);
            end        
        end
    end
else    
    % memory allocation
    DataF = cell(1,length(nGrpU));
    
    % sets the data for each unique grouping type
    for i = 1:length(nGrpU)
        % sets the title and combines it with the new metric data
        k = find(iiU(j) == ii);
        if (sepDay)
            k = cellfun(@(x)((x-1)*nDay+(1:nDay)),num2cell(k),'un',0);
            k = cell2cell(k,0);
        end        
        
        % combines all the cells into a single array
        YMnw = cell2cell(cellfun(@(x)(x{i}),YM,'un',0));        
        DataF{i} = [YT{i},[mStrD(:,k(1:size(YMnw,2)));YMnw]]; 
        
        % adds in column spacer (if more than one group)
        if (i > 1)
            DataF{i} = combineCellArrays({NaN},DataF{i});
        end
    end
    
    % combines the final data array
    DataF = cell2cell(DataF,0);    
end

% sets the final array
Data = cell(size(DataF,1)+2,size(DataF,2));
Data((1:size(DataF,1))+1,:) = DataF;
Data(cellfun(@isempty,Data)) = {''};
Data(cellfun(@(x)(strcmp(x,'NaN')),Data)) = {''};

%
ii = find(cellfun(@(x)(~isnan(str2double(x))),Data));
DataN = cellfun(@(x)(str2double(x)),Data(ii));
jj = mod(DataN,1)==0;
Data(ii(jj)) = num2strC(DataN(jj),'%i');

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- removes the apparatus groups that are not included
function YR = reduceDataArray(Y,indOut,iOrder,sepGrp)

% memory allocation
YR = cell(1,size(iOrder,1));

% resets the arrays
for i = 1:size(iOrder,1)       
    % sets the reduced array
    YR{i} = Y{iOrder(i)}(indOut);
    
    % 
    if (sepGrp)        
        for iExp = 1:size(YR{i},2)
            % determines the separation indices
            n = size(YR{i}{1,iExp}{1},2)/2;
            [i1,i2] = deal(1:n,(n+1):(2*n));
            
            % separates the 
            for iApp = 1:size(YR{i},1)
                YR{i}{iApp,iExp} = cellfun(@(x)...
                            ({x(:,i1),x(:,i2)}),YR{i}{iApp,iExp},'un',0);
            end
        end
    end
end