classdef MetricPopData < DataOutputArray
    
    % class properties
    properties

        % string/index array fields
        szY
        fOK
        xDep        
        mIndG
        isOKF
        iOrderF
        appName
        
        % scalar fields
        outType     
        
        % data array fields
        YM
        YT
        YR
        indG
        iMet
        mStrT
        mStrH        
        
        % other fields
        nGrp 
        nDay
        nxDepU
        iGrpT

        % fixed class fields
        emptyStr = "N/A";
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = MetricPopData(hFig)
            
            % creates the super-class object
            obj@DataOutputArray(hFig);            
            
            % sets up the data array
            obj.initClassFields();
            obj.setupDataArray();
            
        end
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % global variables
            global nMet
            
            % reorders the array so the N values are at the top
            ii = obj.iOrder(:,2) ~= obj.nMetT;
            if obj.iData.metStats   
                obj.iOrderF = [[1 obj.nMetT];obj.iOrder(ii,:)];
            else
                obj.iOrderF = obj.iOrder(ii,:);
            end
            
            % field reduction
            obj.appName = obj.iData.appName(obj.appOut);
            obj.outType = (2*obj.sepDay + obj.sepExp) + 1;
            
            % sets the global metric indices
            Type = field2cell(obj.iData.yVar,'Type',1);
            mIndG0 = find(Type(:,1));   
            obj.mIndG = mIndG0(obj.iOrderF(:,1));
            
            % sets the independent variable strings
            yVar = obj.iData.yVar(obj.mIndG);
            obj.xDep = cell2cell(field2cell(yVar,'xDep'));                        
            
            % retrieves the reduced dataset
            obj.YR = obj.getReducedDataArray();            
            
            % sets the other data fields
            obj.nMet = nMet;
            obj.nExp = sum(obj.expOut);
            obj.nGrp = size(obj.YR{1}{1},1);
            obj.iGrpT = [obj.sepExp,obj.sepDay,(obj.nGrp>1)];
            obj.szY = cellfun(@(x)(obj.getArrayDim(x)),obj.YR{1},'un',0);     
                        
            % sets the day count
            if obj.sepDay
                snTotE = obj.snTot(obj.expOut);
                obj.nDay = arrayfun(@(x)(detExptDayDuration(x)),snTotE);
            else
                obj.nDay = ones(obj.nExp,1);
            end
            
            % determines the inclusion flags for each genotype group
            snTotE = obj.snTot(obj.expOut);
            obj.fOK = cell2mat(arrayfun(@(x)...
                        (cellfun(@any,x.iMov.flyok)),snTotE(:)','un',0));
            
            % determines the inclusion flags for each genotype group
            hGUI = getappdata(obj.hFig,'hGUI');
            [~,~,pInd] = getSelectedIndices(guidata(hGUI));
            if pInd == 3                             
                % reduces the genotype groups to those that appear >= once
                obj.appOut = obj.appOut & any(obj.fOK,2);
            end

            % reshapes the other data arrays
            obj.nApp = sum(obj.appOut);
            obj.appName = obj.iData.appName(obj.appOut);
            obj.YR = cellfun(@(x)(x(obj.appOut)),obj.YR,'un',0);

            % array indexing and other initialisations
            if obj.iData.metStats                
                % reduces the count array to only include groups which
                % intersect with the current data output configuration
                gName0 = obj.snTot(1).iMov.pInfo.gName;
                [~,iA] = intersect(gName0,obj.appName,'stable');                 
                
                % retrieves the group acceptance flags
                snTotE = obj.snTot(obj.expOut);
                iOK0 = cell2cell(arrayfun(@(x)...
                            (x.iMov.flyok),snTotE,'un',0),0);
                iOK0 = cellfun(@any,iOK0(iA,:));

                %
                nRowT = size(obj.YR{1}{1},1);
                switch obj.outType
                    case 1
                        % case is all day/expt data
                        obj.isOKF = arrayfun(@(x)(logical...
                                (x*ones(nRowT,1))),any(iOK0,2),'un',0);
                        
                    case 2
                        % case is all day/split expt data
                        obj.isOKF = cellfun(@(x)(repmat...
                                (x,nRowT,1)),num2cell(iOK0,2),'un',0);
                        
                    case 3
                        % case is split day/all expt data
                        nDayT = size(obj.YR{1}{1},2);
                        obj.isOKF = arrayfun(@(x)(logical...
                                (x*ones(nRowT,nDayT))),any(iOK0,2),'un',0);
                       
                    case 4
                        % case is split day/split data
                        [~,nDayT,nExpT] = size(obj.YR{1}{1});
                        [A,szL] = deal(ones(nRowT,nDayT),[1,1,nExpT]);
                        obj.isOKF = cellfun(@(y)(cell2mat(reshape...
                                (arrayfun(@(x)(logical(x*A)),y,'un',0),...
                                szL))),num2cell(iOK0,2),'un',0);
                end
            else
                % data is for other metric types
                obj.isOKF = cellfun(@(x)...
                            (true(size(x,1),1)),obj.YR{1},'un',0);
            end            
            
        end
        
        % --- sets up the data output array
        function setupDataArray(obj)
            
            % sets up the header/data values for the output array
            obj.setupGroupHeaders();
            obj.setupTableData();
            obj.setupMetricData();
            
            % combines the final output data array
            obj.setupFinalDataArray();
            
        end             

        % ---------------------------------- %
        % --- DATA ARRAY SETUP FUNCTIONS --- %
        % ---------------------------------- %        
        
        % --- sets up the main group header strings
        function setupGroupHeaders(obj)
            
            % sets the base variable names
            mStrB = obj.iData.fName(obj.mIndG);
            mStrB{1} = '';
                
            % sets the header string array
            if obj.iData.metStats
                % sets the final header string array 
                xiT = num2cell(obj.iOrderF(:,2));
                mStrH0 = cellfun(@(x)(ind2varStat(x,1)),xiT,'un',0);            
                mStrH0 = cellfun(@(x)(sprintf('(%s)',x)),mStrH0,'un',0);                
                obj.mStrH = [mStrB,mStrH0]';            
            else
                % case is no metrics are being calculated
                obj.mStrH = [repmat({''},1,length(mStrB));mStrB(:)'];
            end                        
            
        end        
        
        % --- sets up the main table data strings
        function setupTableData(obj)
                    
            % determines the unique sub-grouping types
            [~,~,iC] = unique(obj.xDep,'stable');
            if isempty(iC)
                obj.mStrT = cell(obj.nApp,1);
                [obj.nxDepU,iGrpC] = deal(1,{1});
            else
                iGrpC = arrayfun(@(x)(find(iC==x)),1:max(iC),'un',0);
                obj.nxDepU = length(iGrpC);            
            end
                    
            % sets up column headers for all regions/expts
            obj.mStrT = cell(obj.nApp,obj.nxDepU); 
            for k = 1:obj.nxDepU
                % sets the metric index for the 
                obj.iMet = iGrpC{k}(1);
                [mStrB,mStrBH] = obj.setupBaseTableHeader();
                
                % sets the table group headers for each type
                for i = 1:obj.nApp
                    obj.mStrT{i,k} = ...
                            obj.setGroupTableHeader(mStrB,mStrBH,i);
                end
            end
            
        end
        
        % --- sets up the metric data strings
        function setupMetricData(obj)
            
            % memory allocation
            obj.YM = cell(obj.nApp,1); 
            
            % sets the metric data for each apparatus
            for i = 1:obj.nApp
                % memory allocation of temporary array
                Ytmp = cell(1,length(obj.YR));    
                for j = 1:length(obj.YR)                
                    % set the data for the current group
                    Ytmp{j} = obj.YR{j}{i}(obj.isOKF{i});
                end

                % combines the temporary data into a single array
                YM0 = cell2cell(cellfun(@(x)(x(:)),Ytmp,'un',0),0);                
                if ~isempty(YM0); YM0(strcmp(YM0,'')) = {obj.emptyStr}; end
                obj.YM{i} = [obj.mStrH;YM0];
            end            
            
        end
        
        % --- combines the header & metric data arrays into the final array
        function setupFinalDataArray(obj)
            
            % initialisations
            [a,b] = deal({''},'');   
            isOK = any(obj.fOK(obj.appOut,:),2);
            [obj.YM,obj.mStrT] = deal(obj.YM(isOK),obj.mStrT(isOK));
            
            % appends the header and metric data
            for i = 1:length(obj.YM)
                % matches the array row counts
                [obj.mStrT{i},obj.YM{i}] = ...
                            obj.matchRowCount(obj.mStrT{i},obj.YM{i});                
                
                % adds in another vertical gap
                if ~isempty(obj.mStrT{i}{3,2})
                    obj.mStrT{i} = combineCellArrays(obj.mStrT{i},a,1,b);
                end
                
                % appends the header strings and metric data
                obj.YM{i} = [obj.mStrT{i},obj.YM{i}];
                obj.mStrT{i} = [];
            end

            % appends gaps to the top/left of the genotype groups data
            obj.YM = cellfun(@(x)(combineCellArrays(a,x,1,b)),obj.YM,'un',0);
            obj.YM = cellfun(@(x)(combineCellArrays(a,x,0,b)),obj.YM,'un',0);
            
            % sets the final data array
            obj.Data = cell2cell(obj.YM,1);           
            
        end                
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- reduces data values to for the required groups
        function YRF = getReducedDataArray(obj)

            % memory allocation
            YRF = cell(1,size(obj.iOrderF,1));

            % resets the arrays
            for i = 1:size(obj.iOrderF,1)
                % reduces the data to the required groups
                [iR,iC] = deal(obj.iOrderF(i,1),obj.iOrderF(i,2));
                YRF{i} = obj.Y{iR,iC,obj.outType};
                
                % converts to column vectors (if required)
                if ~obj.iData.metStats
                    YRF{i} = cellfun(@arr2vec,YRF{i},'un',0);                    
                end
            end
            
            % reshapes the data arrays
            YRF = cellfun(@(x)(obj.reshapeDataArray(x)),YRF,'un',0);            
            
        end

        % reshapes the data arrays for each group
        function YR = reshapeDataArray(obj,YR0)

            % Type Status Flags
            %  1 = Single-Day/Single-Expt
            %  2 = Single-Day/Multi-Expt
            %  3 = Multi-Day/Single-Expt
            %  4 = Multi-Day/Multi-Expt
            
            % reduces down the required expts (if separating)
            if obj.sepExp
                YR0 = cellfun(@(x)(x(:,obj.expOut)),YR0,'un',0);
            end
            
            % array dimensions
            [nDayT,nExp] = size(YR0{1});
            nGrpT = size(YR0{1}{1},2);
            Type = 2*(nDayT>1) + (nExp>1) + 1;

            % memory allocation
            if Type == 4
                % case is Multi-Day/Multi-Expt
                YR = repmat({strings(nGrpT,nDayT,nExp)},size(YR0));
            else
                % case is the other expt types
                YR = cell(size(YR0));
            end

            % reduces the data based on the expt/day type
            for i = 1:length(YR)
                switch Type
                    case 1
                        % case is Single-Day/Single-Expt
                        YR{i} = arr2vec(YR0{i}{1});

                    case 2
                        % case is Single-Day/Multi-Expt
                        A = cellfun(@(x)(x'),YR0{i},'un',0);
                        YR{i} = cell2cell(A,0);

                    case 3
                        % case is Multi-Day/Single-Expt
                        YR{i} = cell2cell(YR0{i})';
                        
                    case 4
                        % case is Multi-Day/Multi-Expt
                        
                        % sets the data for each 
                        for j = 1:nExp
                            % reshapes the data for the current expt
                            isOK = ~cellfun(@isempty,YR0{i}(:,j));
                            YRC = cell2cell(YR0{i}(isOK,j));

                            % stores the newe data
                            if size(YRC,1) == size(YR{i},1)
                                % case is row based data
                                YR{i}(isOK,:,j) = YRC;
                            else
                                % case is column based data
                                YR{i}(:,isOK,j) = YRC';
                            end
                        end
                end
            end        
            
        end        
        
        % --- sets up the table header for a given group
        function mStrTG = setGroupTableHeader(obj,mStrB,mStrBH,iApp)
             
            % initialisations
            [a,b] = deal({''},'');
            
            if obj.sepExp
                % case is separating by experiment
                iOut = find(obj.appOut);
                iExp0 = find(obj.expOut);
                iExp = iExp0(obj.fOK(iOut(iApp),:));
                if obj.numGrp
                    mStrE = arrayfun(@num2str,iExp,'un',0);                    
                else
                    mStrE = arrayfun(@(x)...
                                    (sprintf('Expt #%i',x)),iExp,'un',0);
                end
                
                % appends the experiment info
                mStrB = cell2cell(cellfun(@(x)...
                        (combineCellArrays({x},mStrB,1,'')),mStrE,'un',0));
                mStrBH = [{'Experiment'},mStrBH];
            end
            
            % combines the genotype group name
            gName0 = string([{'Group Name'},obj.appName(iApp)]);
            gName = combineCellArrays(gName0,a,0,b);
            
            % sets the final grouping
            mStrB = combineCellArrays(mStrBH,mStrB,0,'');
            mStrTG = combineCellArrays(gName,mStrB,0,'');
            
        end
        
        % --- sets up the column header string for a given expt/region
        function [mStrTF,mStrTH] = setupBaseTableHeader(obj)
            
            % group header stacking convention
            %
            %  * Level #1 - Experiment
            %  * Level #2 - Day
            %  * Level #3 - Bin/Grouping
            
            % memory allocation
            b = '';            
            nLvl = 2;            
            mStr0 = cell(nLvl,1);             
            mStrTH0 = {'Day','Group Bin'};
            
            % ------------------------------ %
            % --- SUB-GROUP HEADER SETUP --- %
            % ------------------------------ %
            
            % determines the feasible grouping types
            isKeep = [max(obj.nDay)>1,obj.nGrp>1];

            % sets the data for each level 
            for iLvl = find(isKeep)
                switch iLvl
                    case 1
                        % case is the day indices
                        xiD = 1:max(obj.nDay);
                        if obj.numGrp
                            mStr0{iLvl} = ...
                                    arrayfun(@num2str,xiD,'un',0);                            
                        else
                            mStr0{iLvl} = arrayfun(@(y)(sprintf...
                                            ('Day #%i',y)),xiD,'un',0);
                        end
    
                    case 2
                        % case is the group indices
                        if obj.numGrp
                            xiG = 1:obj.nGrp;
                            mStr0{iLvl} = ...
                                    arrayfun(@num2str,xiG,'un',0);
                        else
                            mStr0{iLvl} = arr2vec(getStructField...
                                    (obj.plotD(1),obj.xDep{obj.iMet}))';
                        end

                end
            end
            
            % reduces down the arrays to the feasible levels
            mStr0 = mStr0(isKeep);
            
            % combines the header strings into a single array
            if any(isKeep)
                % combines the header strings into a single array
                mStrC = mStr0{1};
                for i = 2:length(mStr0)
                    A = num2cell(mStrC,1);
                    mStrC = cell2cell(cellfun(@(x)(...
                            combineCellArrays(x,mStr0{i},0,b)),A,'un',0),0);
                end

                % sets the combined header
                mStrTF = string(mStrC)';
                mStrTH = string(mStrTH0(isKeep));
            else
                %
                mStrTF = {'All Times'};
                mStrTH = string({''});
            end

        end        
        
    end
    
    % static class method
    methods (Static)
                
        % --- retrieves the arrays 3D size
        function szY = getArrayDim(x)
            
            szY = [size(x,1),size(x,2),size(x,3)];
            
        end
        
        % --- sets up the binned group index array
        function indBG = setBinGroupInd(x)

            indBG = repmat(repmat((1:x(1))',1,x(2)),[1 1 x(3)]);

        end        

        % --- sets up the first order grouping index array
        function indG1 = setFirstOrderInd(x)

            indG1 = repmat(repmat((1:x(2)),x(1),1),[1 1 x(3)]);            
            
        end        
        
        % --- sets up the second order grouping index array
        function indG2 = setSecondOrderInd(x)

            ind0 = arrayfun(@(y)(y*ones(x(1),x(2))),(1:x(3))','un',0);
            indG2 = cell2mat(reshape(ind0,[1 1 x(3)]));

        end        
        
    end
    
end
