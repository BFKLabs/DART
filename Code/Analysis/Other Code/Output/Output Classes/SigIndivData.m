classdef SigIndivData < DataOutputArray
    
    % class properties
    properties        
        
        % index/cell array fields        
        xDep        
        xDepT
        xDepTU
        iiXD
        indU
        indN
        isOK
        mIndG
        appName
        
        % column header strings
        tSp
        tStr
        
        % temporary data arrays
        DataT
        DataTN
        mData
        fData        
        
        % scalar/boolean fields
        iMet
        outType
        hasTime
        hasTSP = false;   
        
        % time vector related properties
        tMlt
        tRnd

        % data array fields
        YM
        YT
        YR
        indG
        iFly
        mStrT
        mStrH
        mStrF
        mStrMG
        
        % other fields
        nGrp
        nDay
        nFly
        nRow
        nCol
        
        % fixed class fields
        pR = 0.001;
        tSp0 = {'Day',''};
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = SigIndivData(hFig,hProg)
            
            % creates the super-class object
            obj@DataOutputArray(hFig,hProg);                                 
            
            % sets up the data array
            obj.initClassFields();
            obj.setupDataArray();
            
        end
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % fields retrieval
            [xVar,yVar] = deal(obj.iData.xVar,obj.iData.yVar);

            % sets the global output metric indices
            Type = field2cell(yVar,'Type',1);            
            mIndG0 = find(Type(:,5));
            obj.mIndG = mIndG0(obj.iOrder);
            
            % sets the other important class fields
            obj.outType = obj.sepDay + 1;            
            obj.xDep = field2cell(yVar(obj.mIndG),'xDep');
            obj.xDepT = cellfun(@(x)(x{1}),obj.xDep,'un',0);
            
            % aligns the independent variables to the plot values
            obj.nExp = obj.iData.sepExp*(sum(obj.expOut)-1)+1;
            [xVarV,xVarT] = field2cell(xVar,{'Var','Type'});
            [obj.xDepTU,~,obj.indU] = unique(obj.xDepT,'stable');
            obj.iiXD = cellfun(@(x)(find(strcmp(xVarV,x))),obj.xDepT);
            obj.hasTime = strcmp(xVarT(obj.iiXD),'Time');                                    
            
        end                        
        
        % --- sets up the full data array
        function setupDataArray(obj)
            
            % sets the horizontal alignment flag
            [a,b] = deal({''},'');
            isH = obj.isHorz;
                        
            % sets up the data arrays for each metric
            for i = 1:obj.nMet
                % sets up the single metric
                obj.iMet = i;
                obj.setupSingleMetric();
                
                % stores the data from the current metric
                if i == 1
                    % if the first metric, then set as is
                    obj.Data = obj.DataT;
                else
                    % otherwise, append the new data  
                    Data0 = combineCellArrays(obj.Data,a,isH,b);
                    obj.Data = combineCellArrays(Data0,obj.DataT,isH,b);
                end
                
                % clears the temporary data fields
                obj.DataT = [];
            end
            
        end
        
        % ---------------------------------- %
        % --- DATA ARRAY SETUP FUNCTIONS --- %
        % ---------------------------------- %
        
        % --- sets up the data output array
        function setupSingleMetric(obj)
                        
            % initialises the metric class fields
            obj.initMetricClassFields(); 
            
            % sets up the header/data values for the output array
            obj.setupAllGroupHeaders(); 
            obj.setupMetricData(); 
            
            % combines the final output data array
            obj.setupFinalDataArray(); 
            
        end
        
        % --- initialises the class fields for the current metric
        function initMetricClassFields(obj)            
            
            % sets the time vector properites
            if obj.hasTime(obj.iMet)
                % case is metric is time dependent
                hObj = obj.hFigH.popupUnits;
                [timeStr,obj.tMlt,obj.tRnd] = getOutputTimeValues(hObj);                
                
                % sets the column title string
                obj.tStr = sprintf('Time %s',timeStr); 
                
            else
                % case is the metric is not time-dependent
                [obj.tMlt,obj.tRnd] = deal(NaN);
                
                % sets the column title string
                xDepS = obj.xDepT{obj.iMet};
                xVarP = field2cell(obj.pData.oP.xVar,'Var');
                obj.tStr = obj.pData.oP.xVar(strcmp(xDepS,xVarP)).Name;
            end                                   
            
            % determines if the dependent variable is time
            xiY = 1:(1+obj.iData.sepDay);
            YY = cellfun(@(x)(cellfun(@(y)(y(obj.expOut)),...
                    x,'un',0)),obj.Y(obj.iOrder(obj.iMet),xiY),'un',0);            
            i0 = find(cellfun(@(x)(size(x,1)>1),YY{1}{1}),1,'first'); 
            if isempty(i0)
                % no match found, so set flag to false
                hasTSP0 = false;
            elseif isnumeric(YY{1}{1}{i0}(1))
                % case is for numerical time data
                YYT = YY{1}{1}{i0}(1:2,1);
                hasTSP0 = (diff(YYT) == 0) || ...
                          (all(mod(YYT,1) == 0) && (all(YYT > 0)));
            else
                % case is for non-numerical time data
                hasTSP0 = isnumeric(YY{1}{1}{i0}{1,1});
            end            

            % determines the number of days each experiment runs for            
            if ~obj.iData.sepDay || all(cellfun('isempty',YY{2}))
                obj.nDay = ones(obj.nExp,1);
            else
                [Y1,Y2] = deal(YY{1}{1},YY{2}{1});
                obj.nDay = arr2vec(cellfun(@(x,y)((size(x,2)-1)/...
                                    (size(y,2)-(1+hasTSP0))),Y2,Y1))';
            end
            
            % determines if the day index column needs inclusion
            if ~obj.sepDay; obj.hasTSP = hasTSP0; end
            obj.tSp = obj.tSp0((~obj.hasTSP+1):end);                                    
            
            % sets the reduces data array and non-empty data arrays
            obj.reduceDataArray();                        
            obj.isOK = cellfun(@(x)(~cellfun('isempty',x)),obj.YR,'un',0);                        
            
            % determines the number of flies for each genotype/experiment
            if length(obj.xDep{obj.iMet}) > 1
                % determines the number of genotype groups
                plotD = getappdata(obj.hFig,'plotD');
                gStr = getStructField(plotD,obj.xDep{obj.iMet}{2});
                obj.nGrp = length(gStr);

                % sets the title strings
                xVar = field2cell(obj.iData.xVar,'Var');
                jj = strcmp(xVar,obj.xDep{obj.iMet}{1});
                obj.tStr = {obj.iData.xVar(jj).Name};

                % sets the fly counts for each sub-region
                obj.nFly = num2cell(cellfun('length',obj.iFly));
                obj.nFly = num2cell(obj.nFly,2);                

%                 % sets the fly header column strings                        
%                 gStrF = cellfun(@(x)...
%                         (repmat(gStr(:)',1,x)),obj.nFly,'un',0);
%                 tStrF = cellfun(@(z)([{'','Fly #'},cell2cell(arrayfun...
%                         (@(y)([{num2str(y)},repmat({' '},1,obj.nGrp-1)]),...
%                         1:z,'un',0),0)]),obj.nFly,'un',0);
%                                     
%                 %
%                 appNameT = repmat(obj.appName(:),1,size(tStrF,2));
%                 obj.mStrF = cellfun(@(x,y,z)([z;[obj.tSp(1:end-1),...
%                         obj.tStr,y]]),appNameT,gStrF,...
%                         tStrF,'un',0);   
                
                %

                    
            else    
                % sets the fly count/genotype group counts
                if obj.useGlob
                    obj.nFly = num2cell(...
                        num2cell(cellfun('length',obj.iFly)),1);
                    [obj.iFly,obj.nGrp] = deal(num2cell(obj.iFly,1),1);    
                else                
%                     obj.nFly = num2cell(...
%                         num2cell(cellfun('length',obj.iFly)),2)';
                    obj.nFly = num2cell(...
                        num2cell(cellfun('length',obj.iFly)),2)';                    
                    [obj.iFly,obj.nGrp] = deal(num2cell(obj.iFly,2)',1);    
                end

%                 % sets the fly index title strings    
%                 obj.mStrF = cellfun(@(x)(arrayfun(@(xx)([obj.tSp,...
%                         arrayfun(@(yy)(sprintf('Fly #%i',yy)),xx{1},...
%                         'un',0)]),x,'un',0)),obj.iFly,'un',0);                                                  
            end             
            
            % sets the group string
            xVar = field2cell(obj.iData.xVar,'Var');
            jj = strcmp(xVar,obj.xDep{obj.iMet}{1});
            obj.tSp{end} = obj.iData.xVar(jj).Name;            
            
            % ------------------------------- %
            % --- MAIN GROUP HEADER SETUP --- %
            % ------------------------------- %
            
            % sets the main group header strings
            fName = obj.iData.fName{obj.mIndG(obj.iMet)};
            mStrMG0 = obj.setMainGroupHeader(fName);             
            
            % append the experiment title (if multi-expt)
            if obj.nExp > 1
                % appends the new strings onto the titles
                mStrMG0 = cellfun(@(x)...
                            (obj.setExptGroupHeader(x)),mStrMG0,'un',0);        
            else
                % otherwise, create a simple gap
                mStrMG0 = cellfun(@(x)...
                            (cellfun(@(y)(x),{1},'un',0)),mStrMG0,'un',0);
            end               
            
            % combines the header strings into a single array
            obj.mStrMG = cell2cell(mStrMG0(:));            
            
        end
        
        % --- sets up the column header string arrays
        function setupAllGroupHeaders(obj)                        
            
            % initialisations      
            obj.mStrT = cell(obj.nApp,obj.nExp);            
            
            % sets up column headers for all regions/expts
            for i = 1:obj.nApp
                for j = 1:obj.nExp
                    % sets up the column header for a given region/expt
                    if obj.nFly{i}{j} > 0                        
                        obj.mStrT{i,j} = obj.setupSingleExptHeader(i,j);
                    end
                end
            end
            
            % determines the row/column counts
            obj.nCol = cellfun(@(x)(size(x,2)),obj.mStrT,'un',0);
            obj.nRow = max(cellfun(@(x)(size(x,1)),obj.YR{1}));
            
        end
        
        % --- sets up the column header string for a given expt/region
        function [mStrC,nP] = setupSingleExptHeader(obj,iApp,iExp)
            
            % group header stacking convention
            %
            %  * Level #1 - Fly
            %  * Level #2 - Day
            %  * Level #3 - Bin/Grouping
            %  * Level #4 - Sub-Bin/Grouping
            
            % memory allocation
            nLvl = 4;
            [a,b] = deal({''},'');
            mStr0 = cell(nLvl,1);
            
            % ------------------------------ %
            % --- SUB-GROUP HEADER SETUP --- %
            % ------------------------------ %            
            
            % determines the feasible
            nDayT = obj.sepDay*(obj.nDay(iExp)-1) + 1;
            nP = [nDayT,obj.nGrp,false];
            isKeep = [true,nP>1];            
            
            % sets the header string based on the level
            for iLvl = find(isKeep)
                switch iLvl
                    case 1
                        % case is the fly separation
                        if obj.useGlob
                            xiE = obj.iFly{iApp}{iExp}(:)';
                        else
                            xiE = 1:obj.nFly{iApp}{iExp};
                        end
                            
                        if obj.numGrp
                            mStr0{iLvl} = arrayfun(@num2str,xiE,'un',0);
                        else
                            mStr0{iLvl} = arrayfun(@(x)...
                                (sprintf('Fly #%i',x)),xiE,'un',0);
                        end
                        
                    case 2
                        % case is the day separation
                        xiD = 1:nP(1);
                        if obj.numGrp
                            mStr0{iLvl} = arrayfun(@num2str,xiD,'un',0);
                        else
                            mStr0{iLvl} = arrayfun(@(x)...
                                (sprintf('Day #%i',x)),1:nP(1),'un',0);
                        end
                            
                    case {3,4}
                        % case is the bin/grouping separation
                        mStrNw = arr2vec(getStructField...
                                (obj.plotD,obj.xDep{obj.iMet}{iLvl-1}))';
                        if obj.numGrp
                            xiM = 1:length(mStrNw);
                            mStr0{iLvl} = arrayfun(@num2str,xiM,'un',0);                            
                        else
                            mStr0{iLvl} = mStrNw;
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
            
            % combines the main group header strings
            mStrC = combineCellArrays(obj.mStrMG{iApp,iExp},mStrC,0,b);
            
            % appends the independent variable fields                        
            tSpT = [a,obj.tSp(:)'];
            xStrC = [repmat(a,size(mStrC,1)-1,length(obj.tSp)+1);tSpT];
            mStrC = [xStrC,mStrC];            
                
        end                    
        
        % --- sets up the metric data strings
        function setupMetricData(obj)
        
            % updates the loadbar
            lStr0 = 'Metric Data Array Setup';
            lStr = sprintf('%s (Metric %i of %i)',lStr0,obj.iMet,obj.nMet);
            obj.hProg.StatusMessage = lStr;                        
            
            % other memory allocation
            a = {''};
            tData = obj.setupTimeVector();
            nDayTmp = obj.sepDay*(obj.nDay-1) + 1;
            obj.mData = cellfun(@(x)(strings(obj.nRow,x)),obj.nCol,'un',0);            
            
            % sets the signal data for each apparatus (split by day)
            for j = 1:obj.nApp
                % sets the column offset indices
                iFlyN = find(cell2mat(obj.nFly{j})>0);                    
                for i = 1:length(iFlyN) 
                    % sets the column indices
                    [i2,iOfs] = deal(iFlyN(i),(1 + obj.hasTSP));
                    nC = obj.nFly{j}{i2}*nDayTmp(i2)*obj.nGrp + iOfs;
                    xiC = 1:nC;

                    % sets the data into the arrays
                    if ~isempty(xiC)            
                        % field retrieval
                        YRnw = obj.YR{j}{i2}(:,xiC);
                        if iscell(YRnw)
                            % determines the NaN/numeric cells values
                            [isNN,isNum] = deal(cellfun(@isnumeric,YRnw));
                            iNum = find(isNum);
                            isNN(iNum(~cellfun(@isnan,YRnw(isNN)))) = false;                            

                            % rounds the numerical values
                            YRnw(isNum) = cellfun(@(x)...
                                    (roundP(x,obj.pR)),YRnw(isNum),'un',0);

                            % rounds the values and removes any NaN's
                            mDataNw = string(YRnw);
                            mDataNw(isNN) = a;
                        else
                            % case is the data is numeric
                            mDataNw = string(roundP(YRnw,obj.pR));
                            mDataNw(isnan(YRnw)) = a;
                        end
                        
                        % sets the data values
                        [iRnw,iC] = deal(1:size(mDataNw,1),xiC+1);
                        obj.mData{j,i2}(iRnw,iC) = string(mDataNw);
                        
                        % sets the time vector into the metric data
                        iCT = iC(1) + obj.hasTSP;
                        iRT = 1:length(tData{j}{i});
                        obj.mData{j,i2}(iRT,iCT) = tData{j}{i};
                    end
                end
            end  
            
        end        
        
        % --- sets up the time vector
        function tData = setupTimeVector(obj)
            
            % memory allocation and field retrieval
            tData = cell(obj.nApp,1);                       
            
            % sets the time vector for each group
            for i = 1:obj.nApp
                % retrieves the time vector from the raw data array
                iok = obj.isOK{i};
                tData{i}(iok) = cellfun(@(x)...
                            (x(:,1+obj.hasTSP)),obj.YR{i}(iok),'un',0);            
                for j = find(iok(:)')
                    % converts the time numerical values to strings
                    if obj.hasTime(obj.iMet)
                        % case is metric is time dependent     
                        if obj.nonZeroTime
                            dT = tData{i}{j} - diff(tData{i}{j}(1:2))/2;
                        else
                            dT = tData{i}{j} - tData{i}{j}(1);
                        end
                        
                        tData{i}{j} = string(roundP(dT*obj.tMlt,obj.tRnd));
                        
                    else
                        % case metric is not time dependent
                        if isnumeric(tData{i}{j})
                            tData{i}{j} = string(tData{i}{j});
                        end                        
                    end
                end
            end
            
        end        
        
        % --- combines the header & metric data arrays into the final array
        function setupFinalDataArray(obj)
            
            % updates the loadbar
            lStr0 = 'Combining Final Data Array';
            lStr = sprintf('%s (Metric %i of %i)',lStr0,obj.iMet,obj.nMet);
            obj.hProg.StatusMessage = lStr;                    
            
            % combines the data/number index arrays
            [cOfs,rOfs] = deal(0,1);
            [obj.mData,obj.mStrT] = deal(obj.mData',obj.mStrT');
            iOK = cell2mat(cell2cell(obj.nFly)') > 0; 
            i0 = find(iOK,1,'first');
            
            % memory allocation for the final data table
            nRowT = size(obj.mStrT{i0},1);
            szD = cell2mat(arr2vec(cellfun(@size,obj.mData(iOK),'un',0)));
            szT = [max(szD(:,1))+nRowT,sum(szD(:,2))];
            obj.DataT = strings(szT);
            
            % combines the header/data arrays for each feasible group
            iOK = arr2vec(find(iOK))';
            for j = 1:size(szD,1)
                % stores the data values
                i = iOK(j);
                mDataT = [obj.mStrT{i};obj.mData{i}];
                iR = (1:size(mDataT,1)) + rOfs;
                iC = (1:size(mDataT,2)) + cOfs;
                obj.DataT(iR,iC) = mDataT;
                
                % increments the column offset
                cOfs = cOfs + szD(j,2);                
            end
                
%             % combines the header
%             isN0 = cellfun(@(x,y)([zeros(size(x));y]),...
%                             obj.mStrT(iOK),obj.indN(iOK),'un',0);            
            
%             % removes the first column
%             obj.DataT = obj.DataT(:,2:end);
%             obj.DataTN = obj.DataTN(:,2:end);            
            
        end

        % ------------------------------------- %
        % --- COLUMN HEADER ARRAY FUNCTIONS --- %
        % ------------------------------------- %                
        
        % --- sets up the main group header string array
        function mStrGH = setMainGroupHeader(obj,x)
            
            mStrGH = cellfun(@(y)(string(cell2cell({{'Group Name',y};{...
                            'Metric',x};{'',''}}))),obj.appName,'un',0)';
            
        end   
        
        % --- sets up the experiment group header string array
        function mStrEH = setExptGroupHeader(obj,x)
            
            % initialisations
            xiE = 1:obj.nExp;
            [a,b] = deal({''},'');
            iiExp = find(obj.expOut);
            
            % appends the experiment index
            mStrEH0 = arrayfun(@(y)(combineCellArrays(x(1:end-1,:),...
                    {'Experiment #',num2str(iiExp(y))},0,b)),xiE,'un',0);
            
            % adds in the gap at the bottom    
            mStrEH = cellfun(@(x)...
                    (combineCellArrays(x,a,0,b)),mStrEH0,'un',0);
            
        end        
        
        % --- sets up the combined header strings
        function mStrC = combineGroupHeaders(obj,mStrF,x,varargin) 

            % --- sets the combined sub-title string
            function tStrC = setCombinedTitle(Y,tStr,useT)

                if useT
                    tStrC = [{'';tStr},Y];
                else
                    tStrC = Y;
                end

            end

            % sets up the final combined header string
            useT = nargin == 4;   
            mStrC = cell(size(mStrF));            
            hasD = ~cellfun('isempty',mStrF);
            
            mStrC(hasD) = cellfun(@(xx,yy)(combineCellArrays({NaN},...
                    combineCellArrays(xx,setCombinedTitle...
                    (yy,obj.tStr,useT),0))),x(hasD),mStrF(hasD),'un',0);

        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- sets the reduced metric data array
        function reduceDataArray(obj)
                        
            % sets the fly count for each group/experiment
            nFlyT = cell2mat(arrayfun(@(x)(cellfun...
                            (@sum,x.iMov.flyok)),obj.snTot,'un',0)');
            
            % reduces the count array to only include groups which
            % intersect with the current data output configuration
            gName0 = obj.snTot(1).iMov.pInfo.gName;
            [~,iA] = intersect(gName0,obj.iData.appName,'stable');                        
            nFlyT = nFlyT(iA,obj.expOut);                                                            
                        
            % reduces the genotype groups to those that appear in each expt
            [hasF,iOut] = deal(any(nFlyT>0,2),find(obj.appOut));
            appOutF = obj.appOut & setGroup(iOut,size(hasF));            
            obj.appName = obj.iData.appName(iOut);
            [obj.nApp,nFlyT] = deal(sum(appOutF),nFlyT(iOut,:));            
            
            % sets the global fly indices
            if obj.useGlob
                iFly0 = cell2cell(arrayfun(@(x)(...
                    obj.setGlobalFlyIndices(x)),...
                    obj.snTot(obj.expOut),'un',0));
                obj.iFly = iFly0(:,iOut);
            else
                obj.iFly = arrayfun(@(x)(1:x),nFlyT,'un',0);                
            end
            
            % resets the metrics to the specified genotype groups
            Ynw = obj.Y{obj.iOrder(obj.iMet),obj.outType}(obj.appOut);  
            Ynw = cellfun(@(x)(x(obj.expOut)),Ynw,'un',0);

            % sets the final data values
            obj.YR = Ynw;  
            
        end        
        
        % --- retrieves the number format string
        function frmStr = getFormatString(obj)
            
            % sets number format string (based on sig. figs)
            switch log10(obj.tRnd)
                case 0
                    % case is integers
                    frmStr = '%i';
                case -1
                    % case is 1 decimal place
                    frmStr = '%.1f';

                case -2
                    % case is 2 decimal place
                    frmStr = '%.2f';

                otherwise
                    % case is 4 or more
                    frmStr = '%.4f';
            end
            
        end        
        
        % --- sets the fly header indices
        function indF = setFlyIndices(obj,x)
           
            indF = [0,cumsum(obj.nDay.*cell2mat(x)*obj.nGrp)];
            
        end        
        
        % --- combines the header/metric data arrays
        function [DataC,isN] = combineHdrData(obj,mStrT,mData,isN0)

            % initialisations            
            isOKT = true(1,size(mData,2));            
            
            % determine which columns are numerical
            if obj.sepDay
                isNT = all(isN0==1,1);
                if any(isNT)
                    % if any columns are numerical, flag which are all NaN                
                    DataN = cell2mat(mData(:,isNT));
                    isOKT(isNT) = ~all(isnan(DataN),1);
                end
            end
            
            % combines the header/metric data values into a single array
            DataC = [mStrT(:,isOKT);mData(:,isOKT)];
            isN = [zeros(size(mStrT(:,isOKT)));isN0(:,isOKT)];
            
        end        
        
        % --- sets up the day grouped header strings
        function mStrDH = setupDayGroupHeader(obj,mStrF,mStrD)
           
            if obj.nGrp == 1
                % case is there is no secondary grouping data
                mStrDH = cell2cell(cellfun(@(X)(combineCellArrays...
                               ({X},mStrD,0)),mStrF(3:end),'un',0),0);
            else
                a = 1;
            end
                       
        end        
        
    end
    
    % static class methods
    methods (Static)
        
        % --- retrieves the nan status flag
        function sNaN = getNaNStatus(fStr)
        
            % initialisations
            sNaN = false;
            
            % sets the status flag based on the string type
            if ~isempty(fStr) && isnumeric(fStr)
                sNaN = isnan(fStr);
            end
            
        end                            
   
        % --- sets up the global fly indices
        function iFly = setGlobalFlyIndices(snTot)
            
            % field retrieval
            cID = snTot.cID;
            
            % calculates the index offset
            if snTot.iMov.is2D
                nFlyG = arr2vec(getSRCount(snTot.iMov)');
%                 nFlyG = snTot.iMov.pInfo.nRow*ones(snTot.iMov.pInfo.nCol,1);                
            else
                nFlyG = cellfun('length',snTot.iMov.iRT(:));
            end
                
            % calculates the region index offsets 
            iOfs = cumsum([0;nFlyG(1:end-1)]);
            
            % sets the global fly indices
            iFly = cell(1,length(cID));
            for i = 1:length(cID)
                % determines the unique row/column indices
                [iA,~,iC] = unique(cID{i}(:,1:2),'rows');
                indC = arrayfun(@(x)(find(iC==x)),1:max(iC),'un',0)';                
                
                % determines the global fly 
                indGT = (iA(:,1)-1)*snTot.iMov.nCol + iA(:,2);
                iFly{i} = cell2mat(cellfun(@(x,y)(...
                    cID{i}(x,3)+y),indC,num2cell(iOfs(indGT)),'un',0));
            end
            
        end        
        
    end
    
end