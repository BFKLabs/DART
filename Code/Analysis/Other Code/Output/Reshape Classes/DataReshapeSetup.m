classdef DataReshapeSetup < handle
    
    % properties
    properties
        
        % main class fields
        hFig
        fName
        pStr
        pType
        pStats
        
        % x/y variable fields
        xVar
        yVar
        
        % data table fields
        Y
        Data0
        tData
        yData
        stData
        
        % array size fields
        nApp
        nExp
        nPara        
        
        % boolean array fields
        appOut        
        expOut
        appName
        
        % boolean flag fields
        sepDay
        sepExp
        sepGrp
        metStats
        grpComb
        
        % output class fields        
        Type
        hasTest
        
        % other class fields
        nOut
        incTab = 1;
        cInd = 1;
        cTab = 1;
        nTab = 1; 
        nMetG = 9;
        nMet = 11;
        nChk
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = DataReshapeSetup(hFig)
            
            % sets the input arguments
            obj.hFig = hFig;
        
            % initialises the class fields
            obj.initMainClassFields();            
            
        end
        
        % --- initialises the main class fields
        function initMainClassFields(obj)
            
            % initialisations
            pStrV = {'Stats','Type','Name'};
            
            % field retrieval
            pData = getappdata(obj.hFig,'pData'); 
            snTot = getappdata(obj.hFig,'snTot');             
            
            % determines number of other formatting checkbox objects
            hFigH = guidata(obj.hFig);
            hChk = findall(hFigH.panelManualData,'style','checkbox');
            obj.nChk = length(hChk);            
            
            % initialisations
            oP = pData.oP;
            [Stats,pType0,Name] = field2cell(oP.yVar,pStrV);                        
            
            % sets the output class fields
            obj.Type = logical(cell2mat(pType0));
            obj.hasTest = ~cellfun('isempty',Stats);
            
            % sets the object dimension fields
            obj.nApp = length(pData.appName);
            obj.nExp = length(snTot);
            obj.nPara = sum(obj.hasTest);            
            
            % sets the field names and strings
            obj.fName = Name;
            obj.pType = pType0;
            obj.pStats = Stats(obj.hasTest);
            obj.appName = pData.appName;            
            [obj.xVar,obj.yVar] = deal(oP.xVar,oP.yVar);
            
            % other memory allocations
            obj.Y = cell(1,obj.nMetG);
            obj.expOut = {true(obj.nExp,obj.nMetG)};
            obj.appOut = {true(obj.nApp,obj.nMetG)};
            obj.Data0 = cell(1,obj.nMetG-1);
            obj.stData = cell(obj.nPara,1); 
            
            % boolean flag fields
            obj.sepDay = oP.sepDay;
            obj.sepExp = oP.sepExp;
            obj.sepGrp = oP.sepGrp;
            obj.metStats = oP.metStats;
            obj.grpComb = oP.grpComb;
            
            % initialises the tab class fields
            obj.tData = DataOutputTable(obj);
            
        end                        
        
        % --- sets the output group index values
        function setAppOut(obj,nwVal,iRow)
            
            % sets the default input argument
            if ~exist('iRow','var')
                iRow = 1:length(nwVal);
            end
            
            % updates the group selected indices
            iSelT = obj.getSelectedMetricTab();
            obj.appOut{obj.cTab}(iRow,iSelT) = nwVal;
            
        end
        
        % --- retrieves the current tab's output group index values
        function appOutS = getAppOut(obj,iRow)
            
            % updates the group selected indices
            iSelT = obj.getSelectedMetricTab();
            appOutS = obj.appOut{obj.cTab}(:,iSelT);
            
            % reduces the index array (if provided)
            if exist('iRow','var'); appOutS = appOutS(iRow); end
            
        end
        
        % --- sets the output group index values
        function setExpOut(obj,nwVal,iRow)
            
            % sets the default input argument
            if ~exist('iRow','var')
                iRow = 1:length(nwVal);
            end
            
            % updates the group selected indices
            iSelT = obj.getSelectedMetricTab();
            obj.expOut{obj.cTab}(iRow,iSelT) = nwVal;
            
        end        
        
        % --- retrieves the current tab's output group index values
        function expOutS = getExpOut(obj,iRow)
            
            % updates the group selected indices
            iSelT = obj.getSelectedMetricTab();
            expOutS = obj.expOut{obj.cTab}(:,iSelT);
            
            % reduces the index array (if provided)
            if exist('iRow','var'); expOutS = expOutS(iRow); end
            
        end
        
        % --- retrieves the currently selected data type tab
        function iSelT = getSelectedMetricTab(obj)
            
            hTabS = findall(obj.hFig,'tag','metricTabGrp');
            iSelT = get(get(hTabS,'SelectedTab'),'UserData');
            
            if isempty(iSelT); iSelT = 1; end
            
        end             
        
    end
    
    % static class methods
    methods (Static)
        
        % --- retrieves the reshape function based on type
        function rFcn = getReshapeFunc(iType)
            
            switch iType
                case 1
                    % case is the population metrics
                    rFcn = @MetricPopReshape;

                case 2
                    % case is the fixed population metric
                    rFcn = @MetricFixedReshape;

                case 3
                    % case is the individual metrics
                    rFcn = @MetricIndivReshape;

                case 4
                    % case is the population signals
                    rFcn = @SigPopReshape;

                case 5
                    % case is the individual signals
                    rFcn = @SigIndivReshape;

                case 6
                    % case is the general 2D population array metrics
                    rFcn = @GenPopReshape;

                case 7
                    % case is the general 2D individual array metrics
                    rFcn = @GenIndivReshape;

            end            
            
        end            
        
    end
    
end