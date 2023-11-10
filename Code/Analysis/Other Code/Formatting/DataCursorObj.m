classdef DataCursorObj < handle
    
    % class properties
    properties
        
        % object handle fields
        hFig
        hCur
        pObj
        evnt
        
        % plot info fields
        pType
        pData
        plotD
        grpName
        
        % x-axis properties
        xName
        xUnits
        xGrp
        
        % x-axis properties
        xName2
        xUnits2
        xGrp2
        
        % y-axis properties
        yName
        yUnits
        yGrp
        
        % time properties
        tUnits
        tDay0
        
        % other scalar fields
        hAx        
        tmpStr        
        mIndex
        iBoxOfs = 7;
        useXGrp = false;
        combFig = false;
        useGrpHdr = true;
        
        % object types
        eBar = 'matlab.graphics.chart.primitive.ErrorBar';
        boxStr = {'Upper Adjacent Value','Upper Whisker',...
            'Median','Lower Whisker','Lower Adjacent Value'};
        boxStrF = {'Upper Value','Upper Quartile',...
            'Median','Lower Quartile','Lower Value'};
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = DataCursorObj(hFig)
            
            % sets the input arguments
            obj.hFig = hFig;
            
            % initialises the class fields
            obj.initClassFields();
            
        end
        
        % ------------------------------------ %
        % --- OBJECT INITIALISATION FIELDS --- %
        % ------------------------------------ %
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % retrieves the parameter object handle
            obj.pObj = getappdata(getappdata(obj.hFig,'hPara'),'pObj');
            
            % creates the data cursor mode object
            obj.hCur = datacursormode(obj.hFig);
            set(obj.hCur,'DisplayStyle','window')
            
            % retrieves the current plot data
            obj.getCurrentPlotData();
            
            % sets up the callback function (if it exists)
            if ~isempty(obj.pData.dcFunc)
                % sets up the full callback function
                set(obj.hCur,'UpdateFcn',{obj.pData.dcFunc,obj});
            else
                set(obj.hCur,'UpdateFcn',[]);
            end
            
        end
        
        % ------------------------------------ %
        % --- DATA CURSOR STRING FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- sets up the data cursor string
        function dTxt = setupCursorString(obj)
            
            % initialisations
            obj.tmpStr = [];
            isMulti = strContains(obj.pType,'Multi');
            
            % sets up the text based on the type
            switch obj.pType
                case {'Bar Graph','Polar','Multi-Bar Graph'}
                    % case is a bar graph is selected
                    obj.setupBarGraphString(isMulti);
                                        
                case 'Stacked Bar Graph'
                    % case is a stacked bar graph
                    obj.setupStackedBarGraphString();
                    
                case {'Boxplot','Multi-Boxplot'}
                    % case is a boxplot is selected
                    obj.setupBoxplotString(isMulti);                    
                    
                case 'FilledBoxplot'
                    % case is a boxplot is selected
                    obj.setupFilledBoxplotString();
                    
                case 'Scatterplot'
                    % case is a scatterplot is selected
                    obj.setupScatterplotString();
                    
                case 'Trace'
                    % case is a trace/line plot is selected
                    obj.setupTraceString();
                    
                case {'Individual Trace','Multi-Individual Trace'}
                    % case is a trace/line plot is selected
                    obj.setupIndivTraceString(isMulti);                    
                    
                case {'Fitted Trace','Multi-Fitted Trace'}
                    % case is a fitted trace/line plot is selected
                    obj.setupFittedTraceString(isMulti);
                                        
                case 'Marker'
                    % case is a plot marker is selected
                    obj.setupMarkerString();
                    
                case 'Heatmap'
                    % case is the heatmap
                    obj.setupHeatmapString();
                    
                otherwise
                    % FINISH ME!
                    a = 1;
            end
            
            % initialisations
            dTxt = obj.tmpStr;
            
        end
        
        % --- sets up the bar-graph data-cursor string
        function setupBarGraphString(obj,isMulti)
            
            % sets up the text block header string
            if isMulti
                % case is a multi-dimensional plot
                valLbl = {'Y-Value','Primary X-Value','Secondary X-Value'};
                valTxt = {obj.setupYValString(),obj.setupXValString(),...
                          obj.setupX2ValString()};
                hdrStr = obj.setupMultiTextBlockHeader();
                
            else
                % case is a single dimensional plot
                valLbl = {'Y-Value','X-Value'};
                valTxt = {obj.setupYValString(),obj.setupXValString()};
                hdrStr = obj.setupTextBlockHeader();
            end
            
            % appends the errorbar values (if required)
            [valLbl,valTxt] = obj.appendErrorValues(valLbl,valTxt);
            
            % sets the final string
            valStr = obj.combineTextArrays(valLbl,valTxt);
            obj.tmpStr = sprintf('%s\n\n%s',hdrStr,valStr);
            
        end
        
        % --- sets up the stacked bar-graph data-cursor string
        function setupStackedBarGraphString(obj)
            
            % case is a multi-dimensional plot
            valLbl = {'Y-Value','X-Value','Sub-Group'};
            valTxt = {obj.setupYValString(),obj.setupXValString(),...
                      obj.setupX2ValString()};
            hdrStr = obj.setupMultiTextBlockHeader();
            
            % sets the final string
            valStr = obj.combineTextArrays(valLbl,valTxt);
            obj.tmpStr = sprintf('%s\n\n%s',hdrStr,valStr);            
            
        end
        
        % --- sets up the boxplot data-cursor string
        function setupBoxplotString(obj,isMulti)
            
            % sets up the boxplot string (based on the selected object)
            if strcmp(get(obj.evnt.Target,'tag'),'Outliers')
                % determines the index of the selected outlier
                iSel = obj.evnt.Position(2) - obj.iBoxOfs;
                yOutL = obj.evnt.Target.YData;
                
                % case is an outlier value
                valLbl = {'Outlier Value'};
                valTxt = {num2str(yOutL(iSel))};
                
            else
                % determines objects that belong to the selected boxplot
                hBoxP = get(obj.evnt.Target,'Parent');
                xDataC = arrayfun(@(x)(mean(x.XData)),hBoxP.Children);
                iiC = xDataC == obj.evnt.Position(1);
                hBoxC = hBoxP.Children(iiC);
                tagStr = arrayfun(@(x)(x.Tag),hBoxC,'un',0);
                
                % retrieves the corresponding object values
                valLbl = obj.boxStrF;
                valTxt = cell(size(valLbl));
                for i = 1:length(valTxt)
                    % determines the matching object index
                    ii = strcmp(tagStr,obj.boxStr{i});
                    
                    % sets the text value
                    switch obj.boxStr{i}
                        case 'Lower Whisker'
                            % case is the lower quartile
                            valTxt{i} = num2str(max(hBoxC(ii).YData));

                        case 'Upper Whisker'
                            % case is the lower quartile
                            valTxt{i} = num2str(min(hBoxC(ii).YData));

                        otherwise
                            % case is the other markers
                            valTxt{i} = num2str(hBoxC(ii).YData(1));
                    end
                end
                
            end
            
            % sets up the header block string
            if isMulti
                % sets up the
                xLbl = {'Primary X-Value','Secondary X-Value'};
                xTxt = {obj.setupXValString(),obj.setupX2ValString()};
                hdrStr = obj.setupMultiTextBlockHeader();
                
            else
                % case is a single-dimensional plot
                xLbl = {'X-Value'};
                xTxt = {obj.setupXValString()};
                hdrStr = obj.setupTextBlockHeader();
            end
            
            % sets up the text block header string
            xStr = obj.combineTextArrays(xLbl,xTxt);
            valStr = obj.combineTextArrays(valLbl,valTxt);
            obj.tmpStr = sprintf('%s\n\n%s\n\n%s',hdrStr,xStr,valStr);
            
        end
        
        % --- sets up the filled boxplot data-cursor string
        function setupFilledBoxplotString(obj)
            
            % determines objects that belong to the selected boxplot
            hBoxP = get(obj.evnt.Target,'Parent');
            xDataC = arrayfun(@(x)(mean(x.XData)),hBoxP.Children);
            iiC = xDataC == obj.evnt.Position(1);
            hBoxC = hBoxP.Children(iiC);
            tagStr = arrayfun(@(x)(x.Tag),hBoxC,'un',0);            
            
            % retrieves the corresponding object values
            valLbl = obj.boxStrF;
            valTxt = cell(size(valLbl));
            for i = 1:length(obj.boxStr)
                % determines the matching object index
                ii = strcmp(tagStr,obj.boxStr{i});

                % sets the text value
                yD = hBoxC(ii).YData;
                switch obj.boxStr{i}
                    case 'Box'
                        % case is the lower quartile
                        valTxt([2,4]) = arrayfun(@num2str,yD,'un',0);

                    case 'Whisker'
                        % case is the lower quartile
                        valTxt([1,5]) = arrayfun(@num2str,yD,'un',0);

                    otherwise
                        % case is the other markers
                        valTxt{3} = num2str(yD(1));
                end
            end            
            
            % sets up the header block string
            xLbl = {'X-Value'};
            xTxt = {obj.setupXValString()};
            hdrStr = obj.setupTextBlockHeader();
            
            % sets up the text block header string
            xStr = obj.combineTextArrays(xLbl,xTxt);
            valStr = obj.combineTextArrays(valLbl,valTxt);
            obj.tmpStr = sprintf('%s\n\n%s\n\n%s',hdrStr,xStr,valStr);            
            
        end
        
        % --- sets up the scatterplot string
        function setupScatterplotString(obj)
            
            % initialisations
            pPos = obj.evnt.Position;
            sgType = obj.xGrp{get(obj.evnt.Target,'UserData')};
            
            % sets up the metric string array
            xLbl = {'X-Value','Y-Value','Sub-Group Type'};
            xTxt = {num2str(pPos(1)),num2str(pPos(2)),sgType};
            xStr = obj.combineTextArrays(xLbl,xTxt);
            
            % combines the header and metric strings
            hdrStr = obj.setupScatterTextBlockHeader();
            obj.tmpStr = sprintf('%s\n\n%s',hdrStr,xStr);
            
        end
        
        % --- sets up the trace/line plot string
        function setupTraceString(obj)
            
            % initialisations
            pp = obj.plotD{1}(1);
            pPos = obj.evnt.Position;
            
            if obj.pData.hasTime
                % sets up the duration string (from the expt start)
                Ts = convertTime(pPos(1),obj.tUnits,'s');
                [~,~,tStr] = calcTimeDifference(Ts);
                dStr = strjoin(tStr,':');
                
                % case is a time-based signal
                xLbl = {'Y-Value','Time From Start'};
                xTxt = {num2str(pPos(2)),dStr};
                
                % appends the absolute time (if long expt)
                if strcmp(obj.tUnits,'Hours') && isfield(pp,'TInfo')
                    % determines the time at the selected point
                    TInfo = pp.TInfo;
                    tSel = addtodate(datenum(TInfo.T0),Ts,'s');
                    
                    % sets the label/value strings
                    xLbl{end+1} = 'Absolute Time';
                    xTxt{end+1} = datestr(tSel,14);
                end
                
            elseif ~isempty(obj.tDay0)
                % case is a long signal type
                
                % sets up the duration string (from the expt start)
                Ts = roundP(convertTime(pPos(1),obj.tUnits,'s'));
                tSel = addtodate([datenum(obj.tDay0)],Ts,'s');                
                
                % case is a time-based signal
                xLbl = {'Y-Value','Absolute Time'};
                xTxt = {num2str(pPos(2)),datestr(tSel,14)}; 
                
            elseif obj.useXGrp
                % case is usings the specified x-values                
                if iscell(obj.xGrp)
                    xStr = obj.xGrp{obj.evnt.Position(1)};
                else
                    xStr = obj.xGrp(obj.evnt.Position(1));
                end
                
                % sets the x-label/text values
                xLbl = {'Y-Value','X-Value'};                                
                xTxt = {num2str(pPos(2)),num2str(xStr)};
                
            else
                % case is a short signal type
                xLbl = {'Y-Value','X-Value'};
                xTxt = {num2str(pPos(2)),num2str(pPos(1))};
            end
            
            % combines the header and metric strings
            xStr = obj.combineTextArrays(xLbl,xTxt);            
            hdrStr = obj.setupTraceTextBlockHeader();
            obj.tmpStr = sprintf('%s\n\n%s',hdrStr,xStr);
            
        end
        
        % --- sets up the individual trace/line plot string
        function setupIndivTraceString(obj,isMulti)

            % initialisations
            iSelI = get(obj.evnt.Target,'UserData');
            pPos = arrayfun(@num2str,obj.evnt.Position,'un',0);    
            
            % case is a short signal type
            if isMulti
                % case are signals are combined
                xLbl = {'Y-Value','X-Value','Group Name','Fly Index'};
                xTxt = [pPos,obj.grpName(iSelI(1)),num2str(iSelI(2))];                
            else
                % case are group separated
                xLbl = {'Y-Value','X-Value','Fly Index'};
                xTxt = [pPos,num2str(iSelI)];
            end
            
            % combines the header and metric strings
            xStr = obj.combineTextArrays(xLbl,xTxt);            
            hdrStr = obj.setupTraceTextBlockHeader();
            obj.tmpStr = sprintf('%s\n\n%s',hdrStr,xStr);            
            
        end
        
        % --- sets up the fitted trace/line plot string
        function setupFittedTraceString(obj,isMulti)
            
            % initialisations
            pPos = obj.evnt.Position;
            tType = {'Raw Trace','Fitted Trace'};
            iType = 1 + strContains(get(obj.evnt.Target,'tag'),'hFit');
            
            % sets up the metric values
            if isMulti
                % case is a multi-fitted signal
                xLbl = {'Y-Value','Primary X-Value','Secondary X-Value',...
                        'Time Group','Trace Type'};
                xTxt = {num2str(pPos(2)),num2str(pPos(1)),...
                        obj.setupXValString(),obj.setupX2ValString(),...
                        tType{iType}};
                hdrStr = obj.setupMultiTextBlockHeader();
                
            else
                % case is a single fitted signal
                xLbl = {'Y-Value','X-Value','Time Group','Trace Type'};
                xTxt = {num2str(pPos(2)),num2str(pPos(1)),...
                        obj.setupXValString(),tType{iType}};
                hdrStr = obj.setupTraceTextBlockHeader();
            end
            
            % combines the header and metric strings
            xStr = obj.combineTextArrays(xLbl,xTxt);            
            obj.tmpStr = sprintf('%s\n\n%s',hdrStr,xStr);            
            
        end
                
        % --- sets up the plot marker string
        function setupMarkerString(obj)
            
            % initialisations
            pPos = obj.evnt.Position;
            uD = obj.evnt.Target.UserData;                       
            
            % case is a short signal type
            xLbl = {'Y-Value','X-Value','Fly Index','Marker Index'};
            xTxt = arrayfun(@num2str,[flip(pPos),uD,obj.mIndex],'un',0);            
            
            % combines the header and metric strings
            xStr = obj.combineTextArrays(xLbl,xTxt);            
            hdrStr = obj.setupTraceTextBlockHeader();
            obj.tmpStr = sprintf('%s\n\n%s',hdrStr,xStr);            
            
        end
        
        % --- sets up the heatmap string
        function setupHeatmapString(obj)
            
            % field retrieval
            pP = obj.evnt.Position;
            
            % sets up the header block string
            valLbl = {'X-Value','Y-Value','Heatmap Value'};
            valTxt = {obj.setupXValString(),obj.yGrp{pP(2)},...
                      obj.setupYValString()};
            hdrStr = obj.setupTextBlockHeader();            
            
            % case is a short signal type
            valStr = obj.combineTextArrays(valLbl,valTxt);
            obj.tmpStr = sprintf('%s\n\n%s',hdrStr,valStr);                        
            
        end
        
        % ----------------------------------------- %
        % --- HEADER TEXT BLOCK SETUP FUNCTIONS --- %
        % ----------------------------------------- %
        
        % --- sets up the bar/boxplot header text block
        function hdrTxt = setupTextBlockHeader(obj)
            
            % sets up the label/value string arrays
            hdrLbl = {'Y-Metric','X-Metric'};
            hdrVal = {obj.yName,obj.xName};
            
            % adds the group header (if required)
            if obj.useGrpHdr
                hdrLbl = [{'Group Name'},hdrLbl];
                hdrVal = [{obj.getSelectedGroup()},hdrVal];
            end
            
            % combines the text arrays into a single string
            hdrTxt = obj.combineTextArrays(hdrLbl,hdrVal);
            
        end
        
        % --- sets up the multi-dimensional header text block
        function hdrTxt = setupMultiTextBlockHeader(obj)
            
            % sets up the label/value string arrays
            hdrLbl = {'Y-Metric','Primary X-Metric','Secondary X-Metric'};
            hdrVal = {obj.yName,obj.xName,obj.xName2};
            
            % adds the group header (if required)
            if obj.useGrpHdr
                hdrLbl = [{'Group Name'},hdrLbl];
                hdrVal = [{obj.getSelectedGroup()},hdrVal];                
            end                  
                  
            % combines the text arrays into a single string
            hdrTxt = obj.combineTextArrays(hdrLbl,hdrVal);
            
        end
        
        % --- sets up the scatterplot header text block
        function hdrTxt = setupScatterTextBlockHeader(obj)
            
            % sets up the label/value string arrays
            hdrLbl = {'Y-Metric','X-Metric','Sub-Grouping'};
            hdrVal = {obj.yName,obj.xName,obj.xName2};
                  
            % adds the group header (if required)
            if obj.useGrpHdr
                hdrLbl = [{'Group Name'},hdrLbl];
                hdrVal = [{obj.getSelectedGroup()},hdrVal];                
            end
            
            % combines the text arrays into a single string
            hdrTxt = obj.combineTextArrays(hdrLbl,hdrVal);
            
        end
        
        % --- sets up the trace/line plot header text block
        function hdrTxt = setupTraceTextBlockHeader(obj)
            
            % sets up the label/value string arrays
            hdrLbl = {'Y-Metric','X-Metric'};
            hdrVal = {obj.yName,obj.xName};

            % adds the group header (if required)
            if obj.useGrpHdr
                hdrLbl = [{'Group Name'},hdrLbl];
                hdrVal = [{obj.getSelectedGroup()},hdrVal];                
            end            
            
            % combines the text arrays into a single string
            hdrTxt = obj.combineTextArrays(hdrLbl,hdrVal);            
            
        end        
        
        % ------------------------------------ %
        % --- OTHER STRING SETUP FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- sets up the x-axis value string
        function xStr = setupXValString(obj)
            
            % retrieves the x-position of the target
            x0 = obj.evnt.Position(1);
            
            if obj.combFig
                % case is a combined figure
                switch obj.pType
                    case {'Stacked Bar Graph'}
                        % case is the stacked bar graph
                        xStr = obj.xGrp{x0(1)};
                        
                    otherwise
                        % case is the other metrics
                        xStr = obj.xGrp{1};
                end
            else
                % case is the other plot types
                switch obj.pType
                    case {'Bar Graph','Multi-Bar Graph',...
                          'Boxplot','Stacked Bar Graph',...
                          'FilledBoxplot','Heatmap'}
                        % case are bar-graphs
                        if iscell(obj.xGrp)
                            xStr = obj.xGrp{roundP(x0)};
                        else
                            xStr = obj.xGrp(roundP(x0));
                        end
                        
                    case {'Multi-Boxplot'}
                        % case are boxplots
                        iSelB = obj.getMultiBoxplotSelectedIndices();
                        xStr = obj.xGrp{iSelB(1)};
                        
                    case {'Scatterplot','Polar'}
                        % case are scatter/polar plots
                        iSelB = get(obj.evnt.Target,'UserData');
                        if iscell(obj.xGrp)
                            xStr = obj.xGrp{iSelB};
                        else
                            xStr = num2str(obj.xGrp(iSelB));                            
                        end
                        
                    case {'Fitted Trace','Multi-Fitted Trace'}
                        % case are fitted traces
                        
                        % field retrieval
                        sP = retParaStruct(obj.pData.sP);
                        tagStr = get(obj.evnt.Target,'tag');
                        iSelB0 = get(obj.evnt.Target,'UserData');
                        
                        % retrieves the global plot indices
                        if strContains(tagStr,'hRaw')
                            % case is a raw trace
                            if obj.pData.hasSR
                                iPlot = find(sP.pT);
                                xStr = obj.xGrp{iPlot(iSelB0)};
                            else
                                xStr = obj.xGrp{iSelB0};
                            end
                                
                        elseif strContains(tagStr,'hFit')
                            % case is a fitted trace
                            if obj.pData.hasSR
                                iPlot = find(sP.pF);
                                xStr = obj.xGrp{iPlot(iSelB0)};
                            else
                                xStr = obj.xGrp{iSelB0};
                            end
                        end
                end
            end
            
            % ensures the final string is not numeric
            if isnumeric(xStr); xStr = num2str(xStr); end
            
        end
        
        % --- sets up the secondary x-axis value string
        function xStr2 = setupX2ValString(obj)
            
            % field retrieval
            nGrp2 = length(obj.xGrp2);
            pP = retParaStruct(obj.pData.pP);
            x0 = obj.evnt.Position(1);
            
            % determines the index of the selected sub-group
            switch obj.pType
                case {'Multi-Bar Graph'}
                    % case is a multi-bar graph
                    x = x0 - roundP(x0);
                    xOfs = -0.5 + (1-pP.pW)/2;
                    iSelB = roundP(0.5 + (nGrp2/pP.pW)*(x - xOfs));
                    
                case {'Multi-Boxplot'}
                    % case is a multi-boxplot
                    iSelB0 = obj.getMultiBoxplotSelectedIndices();
                    iSelB = iSelB0(2);
                    
                case {'Multi-Fitted Trace'}
                    % case is a multi-fitted trace
                    tagStr = get(obj.evnt.Target,'tag');
                    iSelB = str2double(tagStr(5:end));
                    
                case {'Stacked Bar Graph'}
                    % case is a stacked bar graph
                    iSelB = get(obj.evnt.Target,'SeriesIndex');
                    
            end
            
            % returns the string
            xStr2 = obj.xGrp2{iSelB};
            
        end
        
        % --- sets up the y-axis value string
        function yStr = setupYValString(obj)

            % field retrieval
            pP = obj.evnt.Position;
            
            switch obj.pType
                case 'Polar'
                    % case is the polar plot
                    iSelB = get(obj.evnt.Target,'UserData');
                    if iscell(obj.yGrp)
                        yStr = obj.yGrp{iSelB};
                    else
                        yStr = num2str(obj.yGrp(iSelB));
                    end
                    
                case 'Stacked Bar Graph'
                    % case is a stacked bar graph
                    yD = get(obj.evnt.Target,'YData');
                    yStr = num2str(yD(pP(1)));
                    
                case 'Heatmap'
                    % case is a heatmap
                    yD = get(obj.evnt.Target,'CData');
                    yStr = num2str(yD(pP(2),pP(1)));
                    
                otherwise                
                    % case is the other metrics
                    yStr = num2str(obj.evnt.Position(2));
            end
            
        end
        
        % --------------------------------- %
        % --- FIELD RETRIEVAL FUNCTIONS --- %
        % --------------------------------- %
        
        % --- retrieves the current plot data
        function getCurrentPlotData(obj,evnt)
            
            % sets the input arguments
            if exist('evnt','var'); obj.evnt = evnt; end
            
            % field retrieval
            plotD0 = getappdata(obj.hFig,'plotD');
            [eInd,fInd,pInd] = getSelectedIndices(guidata(obj.hFig));
            
            % sets the plot data fields
            obj.plotD = plotD0{pInd}{fInd,eInd};
            obj.pData = obj.pObj.pData;
            
        end
        
        % --- retrieves the name of the currently selected group
        function gName = getSelectedGroup(obj)
            
            % case is the bar/boxplot graphs
            sP = retParaStruct(obj.pData.sP);
            
            % retrieves the group type based on the plot type
            if obj.combFig
                % case is graph is combined into a single figure
                if strContains(obj.pType,'Trace')
                    iSelT = get(obj.evnt.Target,'UserData');
                    gName = obj.grpName{iSelT};
                else
                    gName = obj.grpName{obj.evnt.Position(1)};
                end
                
            elseif obj.pData.hasSR
                % case is stimuli-response type selection
                gName = obj.grpName{sP.pInd};
                
            else
                % case is graph is separated by group
                gName = obj.grpName{obj.getSelectAxesIndex()};
            end
            
        end
        
        % --- retrieves the currently selected axes index
        function iAx = getSelectAxesIndex(obj)
            
            % keep looping until the axes object is found
            obj.hAx = get(obj.evnt.Target,'Parent');
            while ~isa(obj.hAx,'matlab.graphics.axis.Axes')
                obj.hAx = get(obj.hAx,'Parent');
            end
            
            % retrieves the current axes index
            iAx = get(obj.hAx,'UserData');
            
        end
        
        % ---------------------------- %
        % --- OBJECT I/O FUNCTIONS --- %
        % ---------------------------- %
        
        % --- opens the data cursor object
        function openObject(obj)
            
            % turns on the data cursor mode
            set(obj.hCur,'Enable','on')
            datacursormode on
            
        end
        
        % --- closes the data cursor object
        function closeObject(obj)
            
            % otherwise, turn off the data cursor mode
            set(obj.hCur,'Enable','off','UpdateFcn',[])
            datacursormode off
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- appends the error bar information (if required)
        function [valLbl,valTxt] = appendErrorValues(obj,valLbl,valTxt)
            
            % appends the errorbar information (if selected)
            if isa(obj.evnt.Target,obj.eBar)
                % determines the errorbar value
                iSel = roundP(obj.evnt.Position(1));
                yErr = obj.evnt.Target.YPositiveDelta(iSel);
                
                % appends the error strings
                valLbl{end+1} = 'Error';
                valTxt{end+1} = num2str(yErr);
            end
            
        end
        
        % --- gets the multi-dimensional boxplot selected indices
        function iSelB = getMultiBoxplotSelectedIndices(obj)
            
            % memory allocation
            iSelB = zeros(1,2);
            
            % retrieves the
            hP = get(obj.evnt.Target,'Parent');
            hM = findall(hP.Children,'tag','Median');
            mVal = arrayfun(@(x)(mean(x.YData)),hM);
            
            % retrieves the primary/secondary boxplot indices
            x0 = obj.evnt.Position(1);
            iGrp = getGroupIndex(~isnan(mVal));
            iSelB(1) = find(cellfun(@(x)(any(x==x0)),iGrp));
            iSelB(2) = find(iGrp{iSelB(1)} == x0);
            
        end
        
    end
    
    % static class methods
    methods (Static)
        
        function tStr = combineTextArrays(tLbl,tVal)
            
            % combines the label/values into a single string
            tStr = strjoin(cellfun(@(x,y)...
                (sprintf('%s: %s',x,y)),tLbl,tVal,'un',0),'\n');
            
        end
        
    end
    
end