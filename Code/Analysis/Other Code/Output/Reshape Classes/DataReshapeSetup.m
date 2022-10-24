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
        appName
        expOut                
        
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
            
            % global parameters
            global nMetG nChk          
            
            % initialisations
            nMetG = 9;            
            pStrV = {'Stats','Type','Name'};
            
            % field retrieval
            pData = getappdata(obj.hFig,'pData'); 
            snTot = getappdata(obj.hFig,'snTot');             
            
            % determines number of other formatting checkbox objects
            hFigH = guidata(obj.hFig);
            hChk = findall(hFigH.panelManualData,'style','checkbox');
            nChk = length(hChk);            
            
            % initialisations
            oP = pData.oP;
            [Stats,pType0,Name] = field2cell(oP.yVar,pStrV);                        
            
            % sets the output class fields
            obj.Type = logical(cell2mat(pType0));
            obj.hasTest = ~cellfun(@isempty,Stats);                        
            
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
            obj.Y = cell(1,nMetG);
            obj.expOut = true(obj.nExp,1);            
            obj.appOut = true(obj.nApp,1);
            obj.Data0 = cell(1,nMetG-1);
            obj.stData = cell(obj.nPara,1); 
            
            % boolean flag fields
            obj.sepDay = oP.sepDay;
            obj.sepExp = oP.sepExp;
            obj.sepGrp = oP.sepGrp;
            obj.metStats = oP.metStats;
            obj.grpComb = oP.grpComb;
            
            % initialises the tab class fields
            obj.tData = obj.initTabClassFields();
            
        end                
        
        % --- initialises the tab class fields
        function tD = initTabClassFields(obj)
            
            % global parameters
            global nMetG nChk           
            
            % tab data struct initialisation
            tD = struct('Name',[],'Data',[],'DataN',[],'hTab',[],...
                    'iPara',[],'mInd',[],'stInd',[],'altChk',[],...
                    'alignV',[],'iSel',1,'mSel',1);
            
            % other memory allocation
            a = cell(1,nMetG);                
                
            % memory allocation and other field initialisations
            tD.Name = {'Sheet 1'};
            tD.iPara = {obj.addOrderArray(obj.Type)};            
            [tD.Data,tD.DataN,tD.mInd] = deal({a});
            [tD.stInd,tD.alignV] = deal({NaN(obj.nPara,2)},true(1,nMetG));
            tD.altChk = {repmat({false(1,nChk)},1,nMetG)};
                
        end                        
        
    end
    
    % static class methods
    methods (Static)
        
        % --- creates a new index order array
        function iPara = addOrderArray(metType)

            % iPara Convention
            %
            % Element 1 - Statistical Test
            % Element 2 - Population Metrics
            % Element 3 - Fixed Metrics
            % Element 4 - Individual Metrics
            % Element 5 - Population Signals
            % Element 6 - Individual Signals
            % Element 7 - 2D Array
            % Element 8 - Parameters

            % global variables
            global nMet nMetG

            % memory allocation
            [isMP,a] = deal(metType(:,1),[]);

            % set the individual cell components (population metrics)
            if any(isMP)
                a = false(sum(isMP),nMet); 
                [a(:,1),a(1,end)] = deal(true);
            end

            % sets the final array
            iPara = repmat({{[]}},1,nMetG);
            iPara{2} = {[],a};

        end
        
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