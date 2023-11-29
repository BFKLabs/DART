classdef MetricIndivData < DataOutputArray
    
    % class properties
    properties

        % string/index array fields
        xiD
        iiX
        iiU
        nGrp
        nGrpU
        nGrpG
        VarX                
        xDep
        mIndG
        mStrT
        mStrD
        iFly
        nFly
        iFlyH
        appName        
        
        % scalar fields
        iMet
        nDay
        outType
        
        % boolean fields
        sepGrp2
        
        % data array fields
        YR
        YT
        YM        
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = MetricIndivData(hFig,hProg)
            
            % creates the super-class object
            obj@DataOutputArray(hFig,hProg);
            
            % sets up the data array
            obj.initClassFields();
            obj.setupDataArray();
            
        end
        
        % --- sets up the data output array
        function setupDataArray(obj)
            
            % sets up the header/data values for the output array
            obj.setupGroupHeaders();
            obj.setupMetricData();
            
            % combines the final output data array
            obj.setupFinalDataArray();               
            
        end
            
        % --- initialises the class fields
        function initClassFields(obj)
            
            % sets the global metric indices
            Type = field2cell(obj.iData.yVar,'Type',1); 
            mIndG0 = find(Type(:,3));
            obj.mIndG = mIndG0(obj.iOrder);            

            % sets the data group properties
            obj.sepGrp2 = obj.iData.sepGrp;
            obj.outType = obj.sepDay + 1;
            obj.nGrpG = 1 + obj.sepGrp2;
            obj.nMet = length(obj.iOrder);            
            obj.nExp = sum(obj.expOut);
            [obj.nGrp,obj.iiX,obj.VarX] = ...
                        detDataGroupSize(obj.iData,obj.plotD,obj.mIndG,1);            
            obj.iiU = unique(obj.iiX,'stable');
            obj.nGrpU = unique(obj.nGrp,'stable');                                
            
            % sets the reduced acceptance flags
            snTot = getappdata(obj.hFig,'snTot');
            fok = arrayfun(@(x)(groupAcceptFlags(x)),snTot(:),'un',0)';
            for i = 1:length(fok)
                fok{i} = fok{i}(obj.appOut); 
            end                                
            
            % sets the output fly indices/counts
            A = cell(obj.nApp,length(obj.nGrpU));
            snTotF = arr2vec(obj.snTot(obj.expOut))';            
            [obj.iFly,obj.iFlyH,obj.nFly] = deal(A);
            for i = 1:obj.nApp
                for j = 1:length(obj.nGrpU)                                        
                    iOK0 = cellfun(@(x)(repmat...
                        (x{i},obj.nGrpG,1)),fok(obj.expOut),'un',0);                    
                    obj.iFly{i,j} = repmat(iOK0,obj.nGrpU(j),1);                    
    
                    iFly0 = arrayfun(@(x)(...
                        obj.setGroupFlyIndices(x,i)),snTotF,'un',0);
                    obj.iFlyH{i,j} = repmat(iFly0,obj.nGrpU(j),1);                    
                    
                    obj.nFly{i,j} = cellfun(@(x)...
                        (sum(x)/obj.nGrpG),obj.iFly{i,j},'un',0);
%                     obj.nFly{i,j} = cellfun(@(x)...
%                         (length(x)/obj.nGrpG),obj.iFly{i,j},'un',0);                    
                end
            end
            
            % determines the inclusion flags for each genotype group
            hGUI = getappdata(obj.hFig,'hGUI');
            [~,~,pInd] = getSelectedIndices(guidata(hGUI));
            if pInd == 3                        
                % reduces the genotype groups to those that appear >= once
                iOut = find(obj.appOut);
                hasF = cellfun(@(x)(any(cell2mat(x(1,:))>0)),obj.nFly);
                appOutF = obj.appOut & setGroup(iOut(hasF),size(obj.appOut));
                
                obj.iFly = obj.iFly(hasF,:);
                obj.nFly = obj.nFly(hasF,:);
            else
                % case is single experiment analysis
                appOutF = obj.appOut;
            end
            
            % reduces down the output data array            
            obj.reduceDataArray(appOutF);            
            
            % sets the other fields 
            obj.nApp = sum(appOutF);
            obj.appName = obj.iData.appName(appOutF);            
            obj.xDep = field2cell(obj.iData.yVar(obj.mIndG),'xDep');            
            
        end
        
        % ---------------------------------- %
        % --- DATA ARRAY SETUP FUNCTIONS --- %
        % ---------------------------------- % 
        
        % --- sets up the overall column header strings
        function setupGroupHeaders(obj)
            
            % initialisations
            [a,b,iOfs] = deal({''},'',1+(obj.nExp>1));
            isKeep = [(obj.nGrp>1),obj.sepGrp2];
            
            % retrieves the independent variables
            xDepT = strings(size(obj.xDep));
            hasX = ~cellfun('isempty',obj.xDep);
            xDepT(hasX) = cellfun(@strjoin,obj.xDep(hasX),'un',0);
            
            % determines the unique sub-grouping types
            [~,~,iC] = unique(xDepT,'stable');
            iGrpC = arrayfun(@(x)(find(iC==x)),1:max(iC),'un',0);
            nxDepU = length(iGrpC);
            
            % sets up column headers for all regions/expts
            obj.mStrT = cell(obj.nApp,nxDepU);            
            for k = 1:nxDepU
                % sets the metric index for the 
                obj.iMet = iGrpC{k}(1);
                for i = 1:obj.nApp
                    % sets the vertical string arrays (for all expts)
                    mStrT0 = cell(1,obj.nExp);
                    for j = 1:obj.nExp
                        % sets up the column header for a given region/expt
                        if obj.nFly{i}{1,j} > 0                              
                            mStrT0{j} = obj.setupSingleExptHeader(i,j);
                        end
                    end
                    
                    % combines the vertical headers and metric data
                    mStrT0 = cell2cell(mStrT0,0);
                    mStrC = combineCellArrays(a,string(mStrT0),1,b)';
                    
                    % sets the names of the sub-grouping types
                    for kk = find(isKeep)
                        xDepT = obj.xDep{obj.iMet}{kk};
                        ii = strcmp(field2cell(obj.iData.xVar,'Var'),xDepT);
                        mStrC{1,iOfs+kk} = obj.iData.xVar(ii).Name;
                    end
                    
                    % sets the other fields
                    if (obj.nExp > 1); mStrC{1,1} = 'Experiment'; end
                    mStrC{1,iOfs} = 'Fly Index';
                    
                    % sets the final data array
                    obj.mStrT{i,k} = mStrC;
                end
            end
                        
            % sets the metric header strings
            obj.mStrD = string(arr2vec(obj.iData.fName(obj.mIndG))');
            if obj.sepDay
                % if separating by day, then split the header strings
                szD = cellfun(@(x)(size(x,2)),obj.YR{1}{1}(1,:));
                
                % appends the day separation strings
                obj.xiD = 1:max(szD);
                mStrD0 = string(arrayfun(@(x)...
                                (sprintf('Day #%i',x)),obj.xiD,'un',0));
                            
                if iscell(obj.mStrD)
                    obj.mStrD = cell2cell(cellfun(@(x)(combineCellArrays...
                                    ({x},mStrD0,0,b)),obj.mStrD,'un',0),0);
                else
                    obj.mStrD = cell2cell(arrayfun(@(x)(combineCellArrays...
                                    ({x},mStrD0,0,b)),obj.mStrD,'un',0),0);                    
                end
            end
            
        end        
        
        % --- sets up the metric data strings
        function setupMetricData(obj)
            
            % memory allocation
%             nRow = 1+obj.sepGrp2;
            obj.YM = cell(obj.nApp,1);            
            
            % case is separating the metric data by apparatus
            for i = 1:obj.nApp
                % sub-array memory allocation
                YMtmp = cell(1,obj.nMet);
                obj.YM{i} = cell(1,length(obj.nGrpU));

                % retrieves the data from the metric data arrays
                for j = 1:obj.nMet
                    % retrieves and sets the data (for the current metric)
                    B = cell(1,size(obj.YR{j}{i},1));
                    Ytmp = repmat({B},[1,obj.nExp]);
%                     nGrpM = size(obj.YR{j}{i},1);
%                     Ytmp = cell(1,nGrpM,obj.nExp);
                    A = num2cell(obj.YR{j}{i},1);
                    
                    k = obj.iiU == obj.iiX(j);
                    for iExp = 1:obj.nExp
                        % retrieves the values to be stored
                        nFlyT = obj.nFly{i,k}(:,iExp);

                        % stores the final data values (if available)
                        if any(cell2mat(nFlyT) > 0)
                            % reduces down the data values to remove the
                            % rejected flies
                            iFlyT = obj.iFly{i,k}(:,iExp);
                            if obj.snTot(iExp).iMov.is2D
                                Ytmp0 = cellfun(@(x,y,z)(x(1:sum(y))),...
                                    A{iExp},iFlyT,'un',0)';
                            else
                                Ytmp0 = cellfun(@(x,y,z)(x...
                                    (y(1:z*obj.nGrpG),:)),A{iExp},iFlyT,...
                                    nFlyT,'un',0)';
                            end
                            
                            % re-orders the array so that the data is
                            % grouped by the individual flies
                            xiM = 1:size(Ytmp0{1},1);
                            Ytmp{iExp} = cell2cell(arr2vec(arrayfun(@(i)...
                                (cell2cell(cellfun(@(y)(y(i,:)),...
                                Ytmp0(:),'un',0))),xiM,'un',0)));
                        else
                            Ytmp{iExp} = [];
                        end
                    end
                    
                    % combines the data over all genotype groups
                    YMtmp{j} = cell2cell(Ytmp(:));                    

                end

                % combines the sub cell-arrays into a single array
                for j = 1:length(obj.nGrpU)
                    obj.YM{i}{j} = string(cell2cell...
                                        (YMtmp(obj.iiX==obj.iiU(j)),0));
                    if obj.sepDay && (size(obj.YM{i}{j},2) < obj.xiD(end))
                        % ensures the metric data array aligns with the 
                        % correct number of days (for the header string)
                        dYgap = obj.xiD(end)-size(obj.YM{i}{j},2);
                        Ygap = strings(1,dYgap);
                        obj.YM{i}{j} = combineCellArrays(obj.YM{i}{j},Ygap);
                    end        
                end
            end            
            
        end
        
        % --- combines the header & metric data arrays into the final array
        function setupFinalDataArray(obj)
            
            %
            [a,b] = deal({''},'');
            DataF0 = cell(max(obj.iiX),obj.nApp);
           
            % ------------------------------------------ %
            % --- ARRAY CONCATENATION PRE-PROCESSING --- %
            % ------------------------------------------ %            
            
            % concatenates the metric data for each genotype group type
            for i = 1:obj.nApp
                % combines the vertical string array
                mStrTF = obj.mStrT{i};
                
                % sets
                for j = 1:size(DataF0,1)
                    % sets the combined metric/header strings
                    mData0 = [obj.mStrD;obj.YM{i}{j}];
                    
                    % appends any rows (if there is a difference in height)
                    dnRow = size(mStrTF,1) - size(mData0,1);                    
                    if dnRow > 0
                        mData0 = combineCellArrays...
                                            (strings(dnRow),mData0,0,b);
                    elseif dnRow < 0
                        mStrTF = combineCellArrays...
                                            (strings(-dnRow),mStrTF,0,b);                        
                    end
                    
                    % sets the final array
                    aGap = repmat(a,~obj.sepDay+1,1);
                    DataF0{j,i} = [mStrTF,mData0];
                    DataF0{j,i} = combineCellArrays(aGap,DataF0{j,i},0,b);
                    
                    % appends the group name
                    DataF0{j,i}(1,1:2) = {'Group Name',obj.appName{i}};
                end
            end
            
            % combines the final array
            obj.combineFinalArray(DataF0,[1,1]);
                        
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- % 
        
        % --- removes the apparatus groups that are not included
        function reduceDataArray(obj,appOutF)

            % memory allocation
            obj.YR = cellfun(@(x)(x(appOutF)),...
                            obj.Y(obj.iOrder,obj.outType),'un',0)';
            if ~all(obj.expOut)
                obj.YR = cellfun(@(x)(cellfun(@(y)...
                        (y(:,:,obj.expOut)),x,'un',0)),obj.YR,'un',0);
            end
            
            % reduces the size of the data to the max number of days (if 
            % not using all expts, but separating by day)
            if ~all(obj.expOut) && obj.sepDay
                % sets up the day index array
                snTotE = obj.snTot(obj.expOut);
                nDayT = arrayfun(@(x)(detExptDayDuration(x)),snTotE);
                xiDT = 1:max(nDayT); 
            
                % reduces down the arrays
                for i = 1:length(obj.YR)
                    obj.YR{i} = cellfun(@(x)(cellfun(@(y)...
                                (y(:,xiDT)),x,'un',0)),obj.YR{i},'un',0);
                end
            end
                
%             % resets the arrays
%             for i = 1:obj.nMet
%                 %
%                 if obj.sepGrp2
%                     for iExp = 1:size(obj.YR{i},2)
%                         % determines the separation indices
%                         n = size(obj.YR{i}{1,iExp}{1},2)/2;
%                         [i1,i2] = deal(1:n,(n+1):(2*n));
% 
%                         % separates the data array
%                         for iApp = 1:size(obj.YR{i},1)
%                             YR0 = obj.YR{i}{iApp,iExp};
%                             obj.YR{i}{iApp,iExp} = cellfun(@(x)...
%                                         ({x(:,i1),x(:,i2)}),YR0,'un',0);
%                         end
%                     end
%                 end
%             end
            
        end       
        
        % --- sets up the column header string for a given expt/region
        function [mStrC,nP] = setupSingleExptHeader(obj,iApp,iExp)
            
            % group header stacking convention
            %
            %  * Level #1 - Expt
            %  * Level #2 - Fly
            %  * Level #3 - Bin/Grouping
            %  * Level #4 - Sub-Bin/Grouping
            
            % memory allocation            
            b = '';
            nLvl = 4;
            iOfs = 2;            
            mStr0 = cell(nLvl,1);
            
            % ------------------------------ %
            % --- SUB-GROUP HEADER SETUP --- %
            % ------------------------------ %            
                                
            % determines the feasible
            nP = [obj.nExp,obj.nFly{iApp}{1,iExp},obj.nGrp,obj.sepGrp2];
            isKeep = nP > [1,0,1,0];              
            
            % sets the header string based on the level
            for iLvl = find(isKeep)
                switch iLvl
                    case 1
                        % case is the day separation
                        iiExp = find(obj.expOut);
                        if obj.numGrp
                            mStr0{iLvl} = {num2str(iiExp(iExp))};
                        else                            
                            mStr0{iLvl} = {sprintf('Expt #%i',iiExp(iExp))};
                        end
                    
                    case 2
                        % case is the fly separation
                        if obj.useGlob
                            xiF = obj.iFlyH{iApp}{1,iExp}(:)';
                        else
                            xiF = 1:nP(2);                            
                        end
                            
                        if obj.numGrp
                            mStr0{iLvl} = arrayfun(@num2str,xiF,'un',0);
                        else
                            mStr0{iLvl} = arrayfun(@(x)...
                                    (sprintf('Fly #%i',x)),xiF,'un',0);
                        end
                            
                    case {3,4}
                        % case is the bin/grouping separation
                        mStr0{iLvl} = arr2vec(getStructField...
                               (obj.plotD,obj.xDep{obj.iMet}{iLvl-iOfs}))';
                        if obj.numGrp
                            xiM = 1:length(mStr0{iLvl});
                            mStr0{iLvl} = arrayfun(@num2str,xiM,'un',0);
                        end
                            
                end
            end      
            
            % reduces down the arrays to the feasible levels
            mStr0 = mStr0(isKeep);            
            
            % combines the header strings with the lower levels
            mStrC = mStr0{1};
            for i = 2:length(mStr0)
                A = num2cell(mStrC,1);
                mStrC = cell2cell(cellfun(@(x)(...
                        combineCellArrays(x,mStr0{i},0,b)),A,'un',0),0);                
            end            
            
        end
        
    end
    
    % static class methods
    methods (Static)
        
        function y = splitGroupData(y)

            y = num2cell(cell2mat(cellfun(@(x)(cell2mat(x(:))),y,'un',0)));
            
        end
        
        function indG = setupSubGroupIndices(iFly,xiG)
        
            [x,y] = meshgrid(xiG,iFly);
            indG = sub2ind(size(x),y,x);
            
        end
        
        % --- sets up the global group fly indices
        function iFlyG = setGroupFlyIndices(snTot,iApp)
            
            % field retrieval
            if snTot.iMov.ok(iApp)
                cID = snTot.cID{iApp};
            else
                iFlyG = [];
                return
            end
            
            % calculates the index offset
            fok = snTot.iMov.flyok{iApp};
            nFlyG = arr2vec(getSRCount(snTot.iMov)');
            iOfs = cumsum([0;nFlyG(1:end-1)]);
            
            % determines the unique row/column indices
            [iA,~,iC] = unique(cID(fok,1:2),'rows','stable');
            indC = arrayfun(@(x)(find(iC==x)),1:max(iC),'un',0)';
            
            % determines the flies overall index within the group
            if snTot.iMov.is2D
                % case is a 2D experiment
                iFlyG = iOfs(iA(:,2)) + iA(:,1);
            else
                % case is a 1D experiment
                indGT = (iA(:,1)-1)*snTot.iMov.nCol + iA(:,2);
                iFlyG = cell2mat(cellfun(@(x,y)(...
                    cID(x,3)+y),indC,num2cell(iOfs(indGT)),'un',0));
            end
            
        end        
            
    end
    
end