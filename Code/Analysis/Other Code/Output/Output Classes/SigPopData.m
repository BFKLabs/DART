classdef SigPopData < DataOutputArray
    
    % class properties
    properties

        % string/index array fields        
        xVar
        xDep
        mIndG
        mStrB
        mStrT
        tStr
        iGrpC
        appName
        
        % data array fields
        X
        YR
        iiT
        fOK
        
        % time related fields
        timeStr
        tMlt
        tRnd
        
        % other fixed fields
        pR = 0.001;
        iGap = true(1,2);        
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = SigPopData(hFig,hProg)
            
            % creates the super-class object
            obj@DataOutputArray(hFig,hProg);
            
            % sets up the data array
            obj.initClassFields();
            obj.setupDataArray();
            
        end
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % memory allocation
            obj.X = cell(obj.nMet,2);            
            
            % sets the global metric indices
            Type = field2cell(obj.iData.yVar,'Type',1); 
            mIndG0 = find(Type(:,4));
            obj.mIndG = mIndG0(obj.iOrder);            
            
            % determines the inclusion flags for each genotype group
            hGUI = getappdata(obj.hFig,'hGUI');
            [~,~,pInd] = getSelectedIndices(guidata(hGUI));
            if pInd == 3
                % retrieves the acceptance flags for each expt
                snTotE = obj.snTot(obj.expOut);
                obj.fOK = cell2mat(arrayfun(@(x)...
                    (cellfun(@any,x.iMov.flyok)),snTotE(:)','un',0));

                % reduces genotype groups to those that appear >= once
                obj.appOut = obj.appOut & any(obj.fOK,2);
            end            

            % sets the other important fields
            obj.nApp = sum(obj.appOut);
            obj.mStrB = obj.iData.fName(obj.mIndG);
            obj.xVar = field2cell(obj.pData.oP.xVar,'Var');
            obj.xDep = field2cell(obj.iData.yVar(obj.mIndG),'xDep');            
            obj.appName = obj.iData.appName(obj.appOut);
            
            % sets the output time values (if any)
            hPopup = obj.hFigH.popupUnits;
            [obj.timeStr,obj.tMlt,obj.tRnd] = getOutputTimeValues(hPopup);
            
            % reduces down the output data array
            obj.reduceDataArray();            
            
            % retrieves the time unit string/multiplier
            if ~isnan(obj.tMlt)
                tStr0 = sprintf('Time %s',obj.timeStr);
                obj.tStr = repmat({tStr0},obj.nMet,1);
            else        
                xDepS = cellfun(@(x)(x{1}),obj.xDep,'un',0);
                xName = field2cell(obj.pData.oP.xVar,'Name');
                iMatch = cellfun(@(x)(find(strcmp(x,obj.xVar))),xDepS);
                obj.tStr = xName(iMatch);
            end
            
        end
        
        % --- sets up the data output array
        function setupDataArray(obj)
            
            % sets up the header/data values for the output array
            obj.setupAllGroupHeaders();
            
            % combines the final output data array
            obj.setupFinalDataArray();            
            
        end        
        
        % ---------------------------------- %
        % --- DATA ARRAY SETUP FUNCTIONS --- %
        % ---------------------------------- %
        
        % --- sets up the overall column header strings
        function setupAllGroupHeaders(obj)
            
            % sets up the metric headers based on type
            if obj.sepGrp
                obj.setupGroupSepHeaders();                
            else
                obj.setupMetricSepHeaders();
            end
            
        end
        
        % --- set up the metric separated headers
        function setupMetricSepHeaders(obj)
            
            % initialisations
            b = '';                  
            iOfs = 1;
            mStrH = {'Metric';''};

            % memory allocation
            nC = length(obj.iGrpC);
            obj.mStrT = cell(nC,obj.nMet);

            for k = 1:nC
                for i = obj.iGrpC{k}(:)'
                    % sets the valid base column header strings
                    indY = [true,length(obj.xDep{i})>[1,2],obj.iGap];

                    % retrieves the dimensions of the data array
                    for j = 1:2
                        if indY(j+iOfs)
                            obj.X{i,j} = getStructField(...
                                            obj.plotD(1),obj.xDep{i}{1+j});
                        end
                    end

                    % sets up the signal header strings
                    if all(cellfun('isempty',obj.X(i,:)))
                        % case is there are no sub-group dependencies
                        mStrS = string([{''},obj.appName(:)']);
                    else
                        % case is there are sub-group dependencies
                        mStrS0 = obj.setupSignalHeader(obj.X(i,:),0);
                        mStrSG0 = cell2cell(cellfun(@(x)(combineCellArrays...
                                    ({x},mStrS0,0,'')),obj.appName,'un',0),0);
                        mStrS = combineCellArrays({''},string(mStrSG0),1,'');
                    end

                    % sets the signal/combined column header strings
                    obj.mStrT{k,i} = combineCellArrays(string(mStrH),mStrS,0,b);
                    obj.mStrT{k,i}{1,2} = obj.mStrB{i};
                    obj.mStrT{k,i}{end,1} = obj.tStr{i};
                end
            end
            
        end
        
        % --- sets up the genotype group separated headers
        function setupGroupSepHeaders(obj)
            
            % initialisations
            b = '';         
            nDep = cellfun('length',obj.xDep);
            mStrH = {'Group Name';'Metric';''};

            % memory allocation
            nC = length(obj.iGrpC);
            obj.mStrT = cell(nC,1);

            % determines the sub-grouping variable values
            for k = 1:nC
                for j = find(nDep(obj.iGrpC{k}(1))>[1,2])
                    obj.X{k,j} = ...
                            getStructField(obj.plotD(1),obj.xDep{k}{1+j});
                end            
            end

            % sets up the grouping header strings for each metric
            for k = 1:nC
                % sets the signal header strings
                mStrB0 = arr2vec(obj.mStrB(obj.iGrpC{k}))';
                mStrS0 = {obj.setupSignalHeader(obj.X(k,:),0)};
                mStrS0 = repmat(mStrS0,1,length(mStrB0));

                % combines all the metric header strings                
                mStrS = combineCellArrays({''},cell2cell(mStrS0,0),1,'');
                mStrM = cell2cell(cellfun(@(x,y)([x,strings(1,...
                            length(y)-1)]),mStrB0,mStrS0,'un',0),0);

                % combines the metric and column header strings
                obj.mStrT{k} = combineCellArrays...
                            (string(mStrH),string(mStrS),0,b);
                obj.mStrT{k}(2,1+(1:length(mStrM))) = mStrM;
                obj.mStrT{k}{end,1} = obj.tStr{1};
            end

            % expands the array
            obj.mStrT = repmat(obj.mStrT,1,obj.nApp);
            for i = 1:nC
                for j = 1:obj.nApp
                    obj.mStrT{i,j}{1,2} = obj.appName{j};
                end
            end
            
        end                       
        
        % --- combines the header & metric data arrays into the final array
        function setupFinalDataArray(obj)

            % combines the header/metric arrays
            mStrTF = obj.mStrT;
            iiD = ~cellfun('isempty',obj.YR);

            % appends the data            
            DataF0 = cellfun(@(x,y)([x;y]),mStrTF(iiD),obj.YR(iiD),'un',0);
            obj.combineFinalArray(DataF0,[1,1]);
            
        end        
            
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- sets up the signal column header strings
        function mStrTH = setupSignalHeader(obj,X,useGap)
            
            % sets the default input arguments
            if ~exist('useGap','var'); useGap = true; end
            
            % initialisations
            a = {''};
            hasX = ~cellfun('isempty',X);
            [xi1,xi2] = deal(1:length(X{1}),1:length(X{2}));
            
            if all(hasX)
                % case is the both x-variables have data
                if obj.numGrp
                    %
                    mStr1 = num2strC(xi1(:)','%i',1);
                    mStr2 = num2strC(xi2(:)','%i',1);
                else
                    % group names is not used                    
                    mStr1 = arrayfun(@(x)(X{1}{x}),xi1(:)','un',0);
                    mStr2 = arrayfun(@(x)(X{2}{x}),xi2(:)','un',0);
                end
                
                % combines the titles
                mStr12 = cell2cell(cellfun(@(x)(combineCellArrays...
                                    ({x},mStr2,0,'')),mStr1,'un',0),0);                
                mStrTH0 = [mStr12,repmat(a,2,useGap)];
                                
            elseif hasX(1)
                % case is the 1st x-variable only has data
                if obj.numGrp
                    % group numbering is used
                    mStr1 = num2strC(xi1(:)','%i',1);
                else
                    % group names is not used
                    mStr1 = arrayfun(@(x)(X{1}{x}),xi1(:)','un',0);
                end
                
                % appends a gap at the end
                mStrTH0 = [mStr1,repmat(a,1,useGap)];
                
            elseif hasX(2)
                % case is the 2nd x-variable only has data
                if obj.numGrp
                    % group numbering is used
                    mStr2 = num2strC(xi2(:)','%i',1);
                else
                    % group names is used
                    mStr2 = arrayfun(@(x)(X{2}{x}),xi2(:)','un',0);
                end
                
                % appends a gap at the end
                mStrTH0 = [mStr2,repmat(a,1,useGap)];
                
            else
                % case is no x-variables have data
                mStrTH0 = repmat(a,1,1+useGap);
            end

            % sets the final header string array
            if useGap
                mStrTH = string([repmat(a,size(mStrTH0,1),1),mStrTH0]);
            else
                mStrTH = string(mStrTH0);                
            end
            
        end        
        
        % --- reduces the metric data array
        function YRT = reduceMetricData(obj,YR0)
            
            % sets the metric data
            YT = cellfun(@(x)(x(:,2:end)),YR0(:)','un',0);

            % combines the metric data with the first order x-variable
            if isnan(obj.tMlt)
                YRT0 = [YR0{1}(:,1),combineNumericCells(YT)];
            else
                YRT0 = [obj.tMlt*YR0{1}(:,1),cell2mat(YT)];
            end     
            
            % converts the strings to            
            YRT = string(roundP(YRT0,obj.pR));
            YRT(isnan(YRT0)) = '';
            
        end        
        
        % --- sets the reduced metric data array
        function reduceDataArray(obj)
            
            % field retrieval
            hasX = ~cellfun('isempty',obj.xDep);
            xDepT0 = cell(size(hasX));
            xDepT0(hasX) = cellfun(@strjoin,obj.xDep,'un',0);
%             xDepT0 = cellfun(@(x)(x{1}),obj.xDep,'un',0);
            [xDepT,~,iC] = unique(xDepT0,'stable');
            
            % determines the independent variable groupings
            nC = length(xDepT);
            obj.iGrpC = arrayfun(@(x)(find(iC==x)),1:nC,'un',0);                      
            
            % reduces down the data to the set groups/metrics
            YT = cellfun(@(x)(x(obj.appOut)),obj.Y(obj.iOrder),'un',0);
            
            % reduces/separates the metrics based on the grouping type
            if obj.sepGrp
                % case is separating by genotype group  
                obj.YR = cell(nC,obj.nApp);                
                for i = 1:obj.nApp
                    % separates the data by each unique x-variable type
                    for j = 1:nC
                        % reduces the metric data
                        obj.YR{j,i} = obj.reduceMetricData...
                            (cellfun(@(y)(y{i}),YT(obj.iGrpC{j}),'un',0));
                    end
                end
                
            else
                % case is separating by metrics           
                obj.YR = cell(nC,obj.nMet);
                for j = 1:nC
                    for i = obj.iGrpC{j}(:)'
                        % separates the data by each unique x-variable type
                        obj.YR{j,i} = obj.reduceMetricData(YT{i});
                    end                    
                end                
                
            end         
            
        end              
        
    end
    
    % static class methods
    methods (Static)
        
        % --- combines the metric data into a single array
        function DataT = combineMetricDataArrays(Data)
        
            % initialisations
            cOfs = 0;
            szD = cell2mat(cellfun(@size,Data(:),'un',0));            
            DataT = strings(max(szD(:,1)),sum(szD(:,2)));
            
            % sets the data into the full array
            for i = 1:length(Data)
                % inserts the data into the array
                [iR,iC] = deal(1:szD(i,1),(1:szD(i,2)) + cOfs);
                DataT(iR,iC) = Data{i};
                
                % increments the column offset
                cOfs = cOfs + szD(i,2);
            end
            
        end                        
        
    end
    
end