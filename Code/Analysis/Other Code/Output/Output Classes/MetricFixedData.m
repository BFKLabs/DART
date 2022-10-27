classdef MetricFixedData < DataOutputArray
    
    % class properties
    properties

        % string/index array fields
        xDep
        mIndG
        mStrT
        mStrH
        appName
        hasXDep
        
        % scalar fields
        nD1
        nGrp
        
        % data array fields
        YR
        YT
        YM

        % fixed fields
        pR = 0.001;
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = MetricFixedData(hFig,hProg)
            
            % creates the super-class object
            obj@DataOutputArray(hFig,hProg);
            
            % sets up the data array
            obj.initClassFields();
            obj.setupDataArray();
            
        end
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % reduces down the output data array
            obj.YR = cellfun(@(x)(cellfun(@(y)(roundP...
                    (y,obj.pR)),x,'un',0)),obj.Y(obj.iOrder),'un',0);
            
            % sets the global metric indices
            Type = field2cell(obj.iData.yVar,'Type',1); 
            mIndG0 = find(Type(:,2));
            obj.mIndG = mIndG0(obj.iOrder);            

            % sets the independent variable properties
            obj.xDep = field2cell(obj.iData.yVar(obj.mIndG),'xDep');
            obj.hasXDep = [~cellfun(@isempty,obj.xDep),...
                            cellfun(@(x)(length(x)>1),obj.xDep)];            
            
            % sets the other fields
            obj.nD1 = 1 + obj.sepGrp*(size(obj.YR{1}{1},1)-1);
            obj.nGrp = max(cellfun(@(x)(size(x{1},2)),obj.YR));
            obj.appName = obj.iData.appName(obj.appOut);
            
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
        
        % --- sets up the overall column header strings
        function setupGroupHeaders(obj)
                                   
            % sets the metric header strings
            mStrH0 = obj.iData.fName(obj.mIndG);
            obj.mStrH = [repmat({''},1,length(mStrH0));mStrH0(:)'];
            
        end
        
        % --- sets up the main table data strings
        function setupTableData(obj)
            
            % group header stacking convention
            %
            %  * Level #1 - Genotype Group Name
            %  * Level #2 - Bin/Grouping
            %  * Level #3 - Sub-Bin/Grouping
            
            % memory allocation
            b = '';            
            nLvl = 3;            
            mStr0 = cell(nLvl,1);             
            mStrTH0 = {'Group Name','Grouping','Sub-Grouping'};
            
            % ------------------------------ %
            % --- SUB-GROUP HEADER SETUP --- %
            % ------------------------------ %
            
            % sets the group heading boolean flags
            hasXD = any(obj.hasXDep,1);
            isKeep = logical([~obj.sepGrp,...
                               (obj.nGrp > 1) && hasXD(1),...
                               hasXD(2)]); 
            
            % sets the data for each level 
            for iLvl = find(isKeep)
                switch iLvl
                    case 1
                        % case is the day indices
                        if obj.numGrp
                            xiD = 1:max(obj.nApp);
                            mStr0{iLvl} = arrayfun(@num2str,xiD,'un',0);                            
                        else
                            mStr0{iLvl} = obj.appName(:)';
                        end
    
                    case {2,3}
                        % case is the group indices
                        YY = arr2vec(getStructField...
                                    (obj.plotD(1),obj.xDep{1}{iLvl-1}));                        
                        if obj.numGrp
                            xiG = 1:length(YY);
                            mStr0{iLvl} = arrayfun(@num2str,xiG,'un',0);
                        else
                            mStr0{iLvl} = YY(:)';
                        end

                end
            end                           
                  
            % reduces down the arrays to the feasible levels
            mStr0 = mStr0(isKeep);
            
            % combines the header strings into a single array
            if any(isKeep)
                mStrC = mStr0{1};
                for i = 2:length(mStr0)
                    A = num2cell(mStrC,1);
                    mStrC = cell2cell(cellfun(@(x)(...
                        combineCellArrays(x,mStr0{i},0,b)),A,'un',0),0);                
                end            
                           
                % sets the main grouping titles
                obj.mStrT = [mStrTH0(isKeep);string(mStrC)'];
            else
                %
                obj.mStrT = {'All Times'};
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
                    % sets the data for the current group
                    Ytmp{j} = obj.YR{j}{i}';
                end

                % combines the temporary data into a single array
                obj.YM{i} = num2cell(cell2cell...
                                    (cellfun(@arr2vec,Ytmp,'un',0),0));
            end
                        
        end
        
        % --- combines the header & metric data arrays into the final array
        function setupFinalDataArray(obj)
            
            % initialisations
            [a,b] = deal({''},'');
            
            if obj.sepGrp
                % sets the final data for each apparatus
                DataF = cell(obj.nApp,1);
                for i = 1:obj.nApp
                    % sets the title and combines it with the metric data
                    mData = [obj.mStrH;obj.YM{i}];
                    [mStrNw,mDataNw] = obj.matchRowCount(obj.mStrT,mData);
                    
                    % sets combines the header/                    
                    DataF{i} = combineCellArrays(a,[mStrNw,mDataNw],0,b);   
                    DataF{i}(1,1:2) = [{'Group Name'},obj.appName{i}];
                end

                % appends gaps to the top/left of the genotype groups data
                DataF = cellfun(@(x)...
                            (combineCellArrays(a,x,1,b)),DataF,'un',0);
                DataF = cellfun(@(x)...
                            (combineCellArrays(a,x,0,b)),DataF,'un',0);
                obj.Data = cell2cell(DataF,~obj.isHorz);

            else
                % combines all the cells into a single array
                DataM = string([obj.mStrH;cell2cell(obj.YM)]);                
                [obj.mStrT,DataM] = obj.matchRowCount(obj.mStrT,DataM);                
                
                % sets the final combined array
                obj.Data = combineCellArrays(a,[obj.mStrT,DataM],1,b);
            end
            
        end
        
    end
end