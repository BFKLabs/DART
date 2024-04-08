classdef DataCombPlotObj < handle
    
    % class properties
    properties
        
        % main class fields
        hGUI        
        
        % class objects fields
        hAx
        hFig
        hMenuP     
        hPanelI
        hPanelD
        hPanelS
        hPanelF
        hPopupAP
        hTabGrp
        
        % limit marker object fields
        hStart
        hFinish
        
        % experimental data struct fields
        sInfo
        sInfoT
        
        % plot data fields
        T
        V
        Px
        Py
        Phi
        
        % plot object fields
        hPos
        hPos2
        hGrpF       
        
        % plotting array fields
        Tmlt
        xLim
        yLim
        nApp
        nFrmT
        xLimT
        yLimT
        pStep
        iStep
        sFac
        regSz
        scrSz
        axSize
        lblSize
        
        % boolean fields
        fOK
        isOK        
        use2D
        calcPhi
        isMltTrk
        
        % fixed class fields
        pW = 1.05;        
        tBin = 5;
        mSzM = 5;        
        lWidL = 2;
        pDel = 1e-4;
        fAlpha = 0.1;
        ix = [1,2,2,1,1];
        iy = [1,1,2,2,1];  
        isUpdating = false;
        tStr = {'hPos','hPos2','hGrpFill','hSep'};
        
        % function handles
        updateViewMenu
        resetPopupFields
        getCurrentExptDur
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = DataCombPlotObj(hGUI)
            
            % sets the input variables
            obj.hGUI = hGUI;
            
            % initialises the class fields and object properties
            obj.initClassFields();
            obj.resetExptPlotObjects();
            
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
                        
            % figure handle retrieval
            obj.hAx = obj.hGUI.axesImg;
            obj.hFig = obj.hGUI.figFlyCombine;
            obj.hMenuP = obj.hGUI.menuPlotData;
            obj.hPanelI = obj.hGUI.panelImg;
            obj.hPanelD = obj.hGUI.panelExptDur;
            obj.hPanelS = obj.hGUI.panelStartTime;
            obj.hPanelF = obj.hGUI.panelFinishTime;
            obj.hPopupAP = obj.hGUI.popupAppPlot;
            
            % retrieves the regular/screen sizes
            obj.scrSz = get(0,'ScreenPixelsPerInch');
            obj.regSz = get(obj.hPanelI,'Position');
            
            % other field retrieval            
            obj.hTabGrp = getappdata(obj.hFig,'hTabGrp');            
            obj.updateViewMenu = getappdata(obj.hFig,'updateViewMenu');
            obj.resetPopupFields = getappdata(obj.hFig,'resetPopupFields');
            obj.getCurrentExptDur = getappdata(obj.hFig,'getCurrentExptDur');                        
            
        end

        % ------------------------------------------ %
        % --- PLOT OBJECT SETUP/UPDATE FUNCTIONS --- %
        % ------------------------------------------ %        
        
        % --- resets the plot objects (for a given experiment)
        function resetExptPlotObjects(obj)
            
            % resets the experimental data field
            obj.sInfoT = getappdata(obj.hFig,'sInfo');
            
            % determines the font sizes and sets the expt info
            obj.detCombineFontSizes();
            obj.setCurrentExptInfo();
            
            % calculates the max overall sub-region count
            nRowMxT = max(cellfun(@(x)...
                (obj.getMaxPlotObjCount(x.snTot.iMov)),obj.sInfoT));
            
            % ------------------------------------ %
            % --- PLOTTING AXES INITIALISATION --- %
            % ------------------------------------ %
            
            % creates the grouping colour fill objects
            xLim0 = [0,1];
            has2D = any(cellfun(@(x)(x.is2D),obj.sInfoT));
            hasMT = any(cellfun(@(x)...
                (detMltTrkStatus(x.snTot.iMov)),obj.sInfoT));
            
            % removes/adds any excess/missing group objects
            if length(obj.hPos) > nRowMxT
                                
                % deletes the excess plot objects
                iRmv = (nRowMxT+1):length(obj.hPos);                
                arrayfun(@(x)(obj.deletePlotObj(x)),obj.hPos(iRmv));
                arrayfun(@(x)(obj.deletePlotObj(x)),obj.hPos2(iRmv));
                arrayfun(@(x)(obj.deletePlotObj(x)),obj.hGrpF(iRmv));
                
                % determines the
                iRem = 1:nRowMxT;
                obj.hPos = obj.hPos(iRem);
                obj.hPos2 = obj.hPos2(iRem);
                obj.hGrpF = obj.hGrpF(iRem);
                
                % case is there are excess plot markers
                for i = iRmv(1:end-1)
                    hSep = findall(obj.hAx,'tag','hSep','UserData',i);
                    delete(hSep);                              
                end           

            elseif length(obj.hPos) < nRowMxT
                % case is plot objects need to be created
                
                % turns the axes hold on
                hold(obj.hAx,'on');
                
                % determines how many objects will be added
                iNew = (length(obj.hPos)+1):nRowMxT;
                hNew = NaN(length(iNew),1);
                
                % memory allocation
                obj.hPos = [obj.hPos;hNew];
                obj.hPos2 = [obj.hPos2;hNew];
                obj.hGrpF = [obj.hGrpF;hNew];                
                
                % adds in the missing plot objects
                for i = iNew
                    % initialises the plot traces
                    obj.hPos(i) = plot(obj.hAx,NaN,NaN,'Color','b',...
                        'Tag','hPos','UserData',i,'LineWidth',0.5,...
                        'Visible','off');
                    
                    % initialises plot trace for 2nd plot lines (2D only)
                    if has2D || hasMT
                        % plots the trace
                        obj.hPos2(i) = plot(obj.hAx,NaN,NaN,'Color','r',...
                            'Tag','hPos2','UserData',i,'LineWidth',0.5,...
                            'Visible','off');
                    end
                    
                    % creates the fill objects
                    yy = (i-0.5)+[0,1];
                    obj.hGrpF(i) = patch(xLim0(obj.ix),yy(obj.iy),...
                        'k','FaceAlpha',obj.fAlpha,'Tag','hGrpFill',...
                        'UserData',i,'Parent',obj.hAx,'Visible','off');
                    
                    % sets seperation line (if not the last sub-region)
                    if i ~= nRowMxT
                        plot(obj.hAx,[0,0],(i+0.5)*[1 1],'k',...
                            'linewidth',1,'tag','hSep','UserData',i);
                    end
                end
                
                % releases the hold on the axes
                hold(obj.hAx,'off')
            end
                
            % sets the other axis properties
            set(obj.hAx,'fontweight','bold','fontsize',obj.axSize,...
                'Box','on','TickLength',[0 0],'linewidth',1.5)
            
        end
        
        % --- updates the plot objects (for a given experiment)
        function updatePlotObjects(obj)
            
            % updates the current experiment information
            obj.setCurrentExptInfo();
            
            % sets the time multiplier
            iPara = obj.sInfo.iPara;
            snTot = obj.sInfo.snTot;
            obj.nApp = length(snTot.Px);
            obj.calcPhi = isfield(snTot,'Phi');
            obj.Tmlt = getTimeScale(snTot.T{end}(end));
            obj.isMltTrk = detMltTrkStatus(snTot.iMov);
            obj.use2D = snTot.iMov.is2D || obj.isMltTrk;
            obj.nFrmT = sum(cellfun('length',snTot.T));
             
            % sets the scale factor (newer versions will have this value)
            if isfield(snTot.sgP,'sFac')
                % scale factor is present, so use it
                obj.sFac = snTot.sgP.sFac;
            else
                % otherwise, use a value of unity
                obj.sFac = 1;
            end
            
            % sets the acceptance flags (dependent on expt setup type)
            if obj.isMltTrk
                % case is multi-tracking
                if iscell(snTot.iMov.flyok)
                    obj.fOK = combineNumericCells(snTot.iMov.flyok);
                else
                    obj.fOK = snTot.iMov.flyok;                    
                end
            else
                % case is single tracking
                obj.fOK = snTot.iMov.flyok;
            end
            
            % determines which regions are feasible
            if obj.isMltTrk
                % case is multi-trackin
                obj.isOK = obj.fOK';
                
            elseif obj.use2D
                % case is a 2D setup
                obj.isOK = any(obj.fOK,1);
                
            else
                % case is a 1D setup
                obj.isOK = ~strcmp(obj.sInfo.gName,'* REJECTED *');
            end
            
            % ---------------------------------------- %
            % --- REGION SELECTION POPUPMENU SETUP --- %
            % ---------------------------------------- %
            
            % sets up the popup menu strings
            if obj.isMltTrk
                % case is multi-tracking
                
                % sets the fly indices for each region
                hGUIInfo = getappdata(obj.hFig,'hGUIInfo');
                iFlyF = hGUIInfo.setupMultiTrackIndices(snTot.iMov);
                
                % sets the popup strings (for the region selection popup)
                lblStr = 'Fly Index';
                popStr = cellfun(@(x)(sprintf(...
                    'Region %i (Fly %i-%i)',x(1),x(2),x(3))),iFlyF,'un',0);
                
            elseif snTot.iMov.is2D
                % case is the 2D experimental setup
                lblStr = 'Grid Row Number';
                popStr = arrayfun(@(x)(sprintf...
                    ('Column #%i',x)),1:snTot.iMov.pInfo.nCol,'un',0)';
                
            else
                % case is the 1D experimental setup
                lblStr = 'Sub-Region Index';
                popStr = setup1DRegionNames(snTot.iMov.pInfo,1);
            end
            
            % initialises the popup menu properties
            set(obj.hPopupAP,'String',popStr,'Value',1,'Enable','on')            
            
            % ---------------------------------------- %
            % --- AXES LIMIT CALCULATIONS & UPDATE --- %
            % ---------------------------------------- %
            
            % recalculates the global variables
            nFly = obj.getMaxPlotObjCount(snTot.iMov);
            obj.xLimT = [snTot.T{1}(1),snTot.T{end}(end)]*obj.Tmlt;
            obj.yLimT = [1 nFly]+0.5*[-1 1];
            obj.pStep = 10^max(floor(log10(obj.nFrmT))-3,0);   
            obj.iStep = 1:obj.pStep:obj.nFrmT;
            
            % sets the time array
            T0 = cell2mat(snTot.T);
            obj.T = T0(obj.iStep);
            Tfin = obj.T(end);
            
            % sets the plot x-axis limits
            xLim0 = obj.Tmlt*[0 Tfin];
            obj.xLim = xLim0 + 0.001*diff(xLim0)*[-1 1];
            
            % resets the x/y data of the plot objects
            set(obj.hAx,'xLim',obj.xLim);
            arrayfun(@(x)(obj.resetObjData(x,NaN,NaN)),obj.hPos);
            arrayfun(@(x)(obj.resetObjData(x,NaN,NaN)),obj.hPos2);
            arrayfun(@(x)(obj.resetObjData(x,obj.xLim(obj.ix))),obj.hGrpF);
            
            % resets the separator line x-data
            hSep = findall(obj.hAx,'tag','hSep');
            if ~isempty(hSep)
                arrayfun(@(x)(obj.resetObjData(obj.xLim)),hSep);
            end
            
            % --------------------------------- %
            % --- METRIC VALUE CALCULATIONS --- %
            % --------------------------------- %
   
            % memory allocation
            [obj.Px,obj.Py,obj.V] = deal(cell(1,obj.nApp));
            if obj.calcPhi; obj.Phi = obj.Px; end            
            
            % sets the fly time/x-coordinate arrays
            for i = find(obj.isOK(:)')
                obj.Px{i} = snTot.Px{i}(obj.iStep,:)/obj.sFac;
                if obj.use2D
                    % if 2D analysis, then set the y-locations as well
                    obj.Py{i} = snTot.Py{i}(obj.iStep,:)/obj.sFac;
                    if i == 1; obj.T = obj.T(1:(end-1)); end
                end

                % calculates the population speed
                obj.calcPopVel(i);

                % sets the orientation angles (if calculated)
                if obj.calcPhi
                    obj.Phi{i} = snTot.Phi{i}(obj.iStep,:); 
                end
            end                       
            
            % -------------------------- %
            % --- PLOT OBJECT UPDATE --- %
            % -------------------------- %
            
            % sets the absolute time values on the time scale
            setAbsTimeAxis(obj.hAx,obj.T,snTot)   
            
            % resets the axis properties
            set(obj.hAx,'ytick',(1:nFly)','linewidth',1.5)
            obj.resetXTickMarkers();
            
            % updates the y-axis label properties
            hLbl = ylabel(obj.hAx,lblStr,...
                'FontUnits','pixels','tag','hYLbl');
            set(hLbl,'fontweight','bold',...
                'fontsize',obj.lblSize,'UserData',lblStr)
            
            % updates the axis properties
            axis(obj.hAx,'ij')
            axis(obj.hAx,'on')            
            set(obj.hAx,'Units','Normalized')
            
            % updates the menu properties
            setObjEnable(obj.hGUI.menuPlotData,'on')
            obj.updateViewMenu(obj.hGUI,obj.hGUI.menuViewXData,1)
            setObjEnable(obj.hGUI.menuViewYData,obj.use2D)
            setObjEnable(obj.hGUI.menuViewXYData,obj.use2D)            
            
            % updates the plot traces and start/finish markers
            obj.updatePosPlot(1);            
            
            % adds in the stimuli axes panels (if stimuli are present)
            tLim = obj.T([1 end]);
            addStimAxesPanels(obj.hGUI,snTot.stimP,snTot.sTrainEx,tLim);
            
        end
        
        % --- updates the plot traces
        function updatePosPlot(obj,varargin)
            
            % data struct/object handle retrieval
            hGUIInfo = getappdata(obj.hFig,'hGUIInfo');
            
            % other initialisations
            snTot = obj.sInfo.snTot;
            iMov = snTot.iMov;
            nFly = obj.getMaxPlotObjCount(iMov);
            
            % updates the region popup indices
            if obj.isMltTrk
                % retrieves the currently selected region
                iApp = obj.getMultiTrackRegion();                            
                [iRow,iCol] = hGUIInfo.getMultiTrackIndices(iApp);
                
            else
                % retrieves the currently selected region
                iApp = get(obj.hPopupAP,'value');
                if isempty(obj.Px{iApp}) && ~isempty(varargin)
                    iApp = find(~cellfun('isempty',obj.Px),1,'first');
                    set(obj.hPopupAP,'Value',iApp)
                end
                
                % sets the visibility flags
                ok = hGUIInfo.ok;
            end
            
            % other initialisations/parameters
            avgPlot = false;
            nMeanRatioMax = 10;
            eStr = {'off','on'};
            
            % ---------------------------------- %
            % --- PLOTTING DATA CALCULATIONS --- %
            % ---------------------------------- %
            
            % sets the plot data based on the selected menu type
            hMenu = findobj(obj.hMenuP,'checked','on');
            switch get(hMenu,'tag')
                case 'menuViewXData'
                    % case is the x-locations only
                    [xPlt,yPlt] = deal(obj.setupPlotValues('Px',iApp),[]);
                    
                case 'menuViewYData'
                    % case is the y-locations only
                    [xPlt,yPlt] = deal([],obj.setupPlotValues('Py',iApp));
                    
                case 'menuViewXYData'
                    % case is both the x/y-locations
                    xPlt = obj.setupPlotValues('Px',iApp);
                    yPlt = obj.setupPlotValues('Py',iApp);
                    
                case 'menuOrientAngle'
                    % case is the orientation angles
                    [xPlt,yPlt] = deal(obj.setupPlotValues('Phi',iApp),[]);
                    
                case ('menuAvgSpeedIndiv')
                    % case is the avg. speed (individual fly)
                    [xPlt,yPlt] = deal(obj.setupPlotValues('V',iApp),[]);
                    
                case ('menuAvgSpeedGroup')
                    % case is the avg. speed (group average)
                    avgPlot = true;                    
                    [iA,~,iC] = unique(obj.sInfo.gName,'Stable');
                    [xPlt,yPlt] = deal(obj.setupPlotValues('Vavg',iApp),[]);
                    
                    nFly = length(iA);                    
                    ok = any(~isnan(xPlt),1);
                    
            end
            
            % includes a gap in graph if there is a major gap in the data
            dT = diff(obj.T); 
            jj = find(dT > nMeanRatioMax*mean(dT));
            if isempty(jj)
                % case is there are no major gaps
                tPlt = obj.T;
                
            else
                % case is there is one or more major gaps
                for i = length(jj):-1:1
                    % removes the gaps from the time signal
                    tPlt = [obj.T(1:jj(i));...
                            obj.T(jj(i)+(0:1)');...
                            obj.T((jj(i)+1):end)];
                    
                    % removes the gaps from the x-plot values
                    if ~isempty(xPlt)
                        xGap = NaN(2,size(xPlt,2));
                        xPlt = [xPlt(1:jj(i),:);xGap;xPlt((jj(i)+1):end,:)];
                    end
                    % removes the gaps from the y-plot values
                    if ~isempty(yPlt)
                        yGap = NaN(2,size(yPlt,2));
                        yPlt = [yPlt(1:jj(i),:);yGap;yPlt((jj(i)+1):end,:)];
                    end
                end
            end
            
            % ensures all plot arrays are of the correct length
            kk = 1:min(max(size(xPlt,1),size(yPlt,1)),length(tPlt));             
            if ~isempty(xPlt); xPlt = xPlt(kk,:); end
            if ~isempty(yPlt); yPlt = yPlt(kk,:); end
            tPlt = tPlt(kk);
            
            % ------------------------------- %
            % --- PATCH BACKGROUND UPDATE --- %
            % ------------------------------- %
            
            % retrieves the group background fill objects
            if ~isempty(obj.hGrpF)
                % if they exist, then update their colours
                if avgPlot
                    % case is the average plot
                    iGrp = (1:nFly)';
                    if obj.isMltTrk
                        indG = arrayfun(@(x)(find(iC==x)),1:max(iC),'un',0);
                        isVis = cellfun(@(x)(any(iMov.ok(x))),indG);
                    else
                        isVis = iMov.ok;
                    end
                    
                else
                    % case is the other plot types
                    
                    if obj.isMltTrk
                        % case is for multi-tracking
                        iSelP = get(obj.hPopupAP,'value');
                        iPlt = hGUIInfo.getMultiTrackPlotIndices(iMov,iSelP);
                        iGrp = iMov.pInfo.iGrp(iRow,iCol);
                        
                        nFlyV = iMov.pInfo.nFly(iRow,iCol);
                        isVis = hGUIInfo.ok(iRow,iCol)*ones(nFlyV,1);
                        
                    else
                        % case is for single fly tracking
                        isVis = ok(:,iApp);
                        iGrp = getRegionGroupIndices(...
                            iMov,obj.sInfo.gName,iApp);
                    end
                end

                % sets up the patch colours
                tCol = getAllGroupColours(length(unique(obj.sInfo.gName)));
                
                % sets the grouping indices
                if obj.isMltTrk && ~avgPlot
                    iiG = (1:length(iPlt))';
                    iGrp = iGrp*ones(size(iiG));
                else
                    iiG = (1:length(iGrp))';
                end
                
                % sorts the fields in descending order
                [~,iS] = sort(arrayfun(@(x)(get(x,'UserData')),obj.hGrpF));
                hGrpP = obj.hGrpF(iS);
                
                % updates the face colours of the fill objects
                isVisF = arr2vec(isVis(iiG));
                if avgPlot
                    indV = find(isVisF);
                    xiH = 1:length(indV);

                    arrayfun(@(h,i)(set(setObjVisibility(h,1),...
                        'FaceColor',tCol(i+1,:))),hGrpP(xiH),iGrp(indV));
                else
                    arrayfun(@(h,i,isV)(set(setObjVisibility(h,isV),...
                        'FaceColor',tCol(i+1,:))),hGrpP(iiG),iGrp,isVisF);
                end
            end
            
            % resets region acceptance flags so they match up correctly
            if avgPlot
                % case is the average trace plot
                aok = ok;
            elseif iscell(obj.Px)
                if length(obj.Px) ~= length(iMov.ok)
                    aok = iMov.ok(iMov.ok);
                else
                    aok = iMov.ok;
                end
            else
                aok = iMov.ok;
            end
            
            % -------------------------------------- %
            % --- PLOTTING TRACE PROPERTY UPDATE --- %
            % -------------------------------------- %
            
            
            % retrieves the handles from the image panel
            hObjImg = findall(obj.hAx);
            
            % determines if the is any feasible data to plot
            if avgPlot
                % case is the average plot (always plot)
                canPlot = true;
            elseif obj.isMltTrk
                % case is the multi-tracking
                [iRow,iCol] = hGUIInfo.getMultiTrackIndices(iApp);
                canPlot = hGUIInfo.ok(iRow,iCol);
            elseif iMov.is2D
                % case is 2D single tracking
                canPlot = any(hGUIInfo.ok(:,iApp));
            else
                % case is 1D single tracking
                canPlot = aok(iApp);
            end
            
            % otherwise, plot the data by apparatus
            if canPlot
                % if apparatus is accepted, then turn on the image axis
                obj.setAxisObjVisibility(hObjImg,'on')
                
                % sets the trace plots for each fly within the apparatus
                nFlyF = min([nFly,max([size(xPlt,2),size(yPlt,2)])]);
                for i = 1:nFlyF
                    % sets the acceptance flags
                    if avgPlot
                        % case is the average plot
                        okNw = ok(i);                        
                        setObjVisibility(obj.hGrpF(i),okNw);
                        
                    elseif obj.isMltTrk
                        % case is the multi-tracking
                        okNw = true;

                    else
                        % case is the single tracking
                        okNw = ok(i,iApp);
                    end
                    
                    % updates the plot properties for the first trace type
                    if ~isempty(xPlt)
                        % updates the plot data
                        yNw = (i + 0.5) - xPlt(:,i)';
                        set(obj.hPos(i),'LineWidth',0.5,'Color','b',...
                            'XData',tPlt*obj.Tmlt,'YData',yNw,...
                            'Visible',eStr{1+okNw});
                        
                    elseif (obj.hPos(i) ~= 0)
                        % otherwise, make the line invisible
                        setObjVisibility(obj.hPos(i),'off');
                    end
                    
                    % updates the plot properties for the second trace type
                    if ~isempty(yPlt)
                        % updates the plot data
                        yNw = (i + 0.5) - yPlt(:,i)';
                        set(obj.hPos2(i),'LineWidth',0.5,'Color','r',...
                            'XData',tPlt*obj.Tmlt,'YData',yNw,...
                            'Visible',eStr{1+okNw});
                    
                    elseif (obj.hPos2(i) ~= 0)
                        % otherwise, make the line invisible
                        setObjVisibility(obj.hPos2(i),'off');
                    end
                end
                
                % sets the y-tick label indices
                if obj.isMltTrk && ~avgPlot
                    iSelP = get(obj.hPopupAP,'value');
                    iFlyF = hGUIInfo.setupMultiTrackIndices();
                    yTickInd = iFlyF{iSelP}(2):iFlyF{iSelP}(3);
                else
                    yTickInd = 1:nFlyF;
                end
                
                % updates the axis limits
                obj.yLim = [1 nFlyF] + 0.5*[-1.002 1];
                yTickLbl = arrayfun(@num2str,yTickInd(:),'un',0);
                set(obj.hAx,'yLim',obj.yLim,'yTickLabel',yTickLbl);
                
                % updates the line height
                obj.resetMarkerHeight(obj.yLim);
                
            else
                % if apparatus is rejected, turn off the image axis
                obj.setAxisObjVisibility(hObjImg,'off')                
                setObjVisibility(obj.hPos,'off')
                setObjVisibility(obj.hPos2,'off')
            end
            
            % resets all the marker regions
            obj.updateLimitMarkers();
            
            % sets the limit marker visibility
            setObjVisibility(obj.hStart.hObj,canPlot)
            setObjVisibility(obj.hFinish.hObj,canPlot)

        end
        
        % ------------------------------------ %
        % --- PLOT MARKER UPDATE FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- resets the tick markers so they match the y-axis limit
        function resetXTickMarkers(obj)
            
            % retrieves the xtick marker labels and the y-axis limits
            nFlyMx = obj.getMaxPlotObjCount(obj.sInfo.snTot.iMov);
            yLimC = [0,nFlyMx] + 0.5;
            hTick0 = findall(obj.hAx,'tag','hXTick');
            
            % removes any previous tick markers
            if ~isempty(hTick0); delete(hTick0); end
            
            % sets the marker coordinates
            xTick = get(obj.hAx,'xtick');
            xPlt = repmat(xTick,2,1);
            yPlt = repmat(yLimC',1,length(xTick));
            
            % creates the marker lines
            hold(obj.hAx,'on')
            plot(obj.hAx,xPlt,yPlt,'k--','tag','hXTick')
            hold(obj.hAx,'on')
            
        end
        
        % --- creates the line objects that will server as limit markers 
        function updateLimitMarkers(obj)
            
            % turns the axis hold on
            hold(obj.hAx,'on');
            Ttot = obj.sInfo.snTot.T;
            indS = obj.sInfo.iPara.indS;
            indF = obj.sInfo.iPara.indF;
            
            % creates/resets the start marker
            hStartPr = findall(obj.hAx,'tag','hMark','UserData','Start');
            if ~isempty(hStartPr); delete(hStartPr); end             
            obj.hStart = obj.createNewMarker...
                (Ttot{indS(1)}(indS(2))*[1 1]*obj.Tmlt,obj.yLim,'Start');
            
            % creates/resets the finish marker
            hFinishPr = findall(obj.hAx,'tag','hMark','UserData','Finish');
            if ~isempty(hFinishPr); delete(hFinishPr); end
            obj.hFinish = obj.createNewMarker...
                (Ttot{indF(1)}(indF(2))*[1 1]*obj.Tmlt,obj.yLim,'Finish');
            
            % turns the axis hold on
            hold(obj.hAx,'off');
            
        end
        
        % --- creates the new experiment start/finish limit markers --- %
        function hM = createNewMarker(obj,xPos,yPos,Type)
            
            % creates a new line object
            hM = InteractObj('line',obj.hAx,{xPos,yPos});

            % sets the object properties
            hM.setColour('r')                        
            hM.setFields('Userdata',Type,'Tag','hMark')
            hM.setLineProps('LineWidth',obj.lWidL,'MarkerSize',obj.mSzM)
            hM.setConstraintRegion(obj.xLim,obj.yLim);
            hM.setObjMoveCallback(@obj.moveLimitMarker);
            
        end
        
        % --- start/finish limit marker callback function --- %
        function moveLimitMarker(obj,varargin)
            
            % if updating the marker elsewhere, then exit
            if obj.isUpdating
                return
            end            
            
            % retrieves the object handle and the index of the line
            switch length(varargin)
                case 1
                    % case is the older version interactive objects
                    pNew = varargin{1};
                    Type = get(get(gco,'parent'),'UserData');
                    
                case 2
                    % case is the newer version interactive objects
                    pNew = varargin{2}.CurrentPosition;
                    Type = varargin{1}.UserData;
            end
            
            % field retrieval
            xNew = pNew(1,1);
            T0 = obj.sInfo.snTot.iExpt(1).Timing.T0;
            Tv0 = cellfun(@(x)(x(1)),obj.sInfo.snTot.T)*obj.Tmlt;
            
            % updates the
            switch Type
                case ('Start')
                    % retrieves the finish marker x-location
                    pF0 = obj.hFinish.getPosition();
                    pF = pF0(:,1);
                    
                    % if the start marker exceeds the finish, then reset
                    xNew = min(xNew,pF(1)-obj.pDel); 
                    
                    % determines the new marker index value
                    if xNew <= Tv0(1)
                        obj.sInfo.iPara.indS = ones(1,2);
                    else
                        [obj.sInfo.iPara.indS(1),indS0] = ...
                            deal(find([Tv0;1e10] <= xNew,1,'last'));
                        obj.sInfo.iPara.indS(2) = find(...
                            [obj.sInfo.snTot.T{indS0}*obj.Tmlt;...
                            1e10] <= xNew,1,'last');
                    end
                    
                    indS = obj.sInfo.iPara.indS;                    
                    if prod(indS) == 1
                        % if first point, set the original marker point
                        obj.sInfo.iPara.Ts = obj.sInfo.iPara.Ts0;
                    else
                        % otherwise, calculate the new time string
                        TT = obj.sInfo.snTot.T{indS(1)}(indS(2));
                        obj.sInfo.iPara.Ts = calcTimeString(T0,TT);
                    end
                    
                    % updates the solution file info
                    obj.updateCurrentExptInfo();
                    
                    % re-calculates the finish marker lower limit
                    iPara = obj.sInfo.iPara;
                    TvecNw = iPara.Ts;
                    TvecNw(5) = TvecNw(5) + 1;
                    Ts0 = obj.sInfo.snTot.iExpt.Timing.T0;
                    xLimNew = (calcTimeDifference(TvecNw,iPara.Ts0) + ...
                        calcTimeDifference(iPara.Ts0,Ts0))*obj.Tmlt;
                    
                    % resets the popup-values
                    xLimF = [xLimNew obj.xLimT(2)];
                    obj.hFinish.setConstraintRegion(xLimF,obj.yLim);
                    obj.resetPopupFields(obj.hPanelS,iPara.Ts)
                    
                case ('Finish')
                    % retrieves the start marker x-location
                    pS0 = obj.hStart.getPosition();
                    pS = pS0(:,1);
                    
                    % if the start marker exceeds the finish, then reset
                    xNew = max(xNew,pS(1) + obj.pDel);
                    
                    % sets the final marker index and the final time string
                    [obj.sInfo.iPara.indF(1),indF0] = ...
                        deal(find([Tv0;1e10] <= xNew,1,'last'));
                    obj.sInfo.iPara.indF(2) = find...
                        ([obj.sInfo.snTot.T{indF0}*obj.Tmlt;1e10] ...
                        <= xNew,1,'last');
                    
                    % updates the finish time stamp
                    indF = obj.sInfo.iPara.indF;
                    obj.sInfo.iPara.Tf = calcTimeString...
                        (T0,obj.sInfo.snTot.T{indF(1)}(indF(2)));
                    
                    % updates the solution file info                    
                    obj.updateCurrentExptInfo()
                    
                    % re-calculates the finish marker lower limit
                    iPara = obj.sInfo.iPara;
                    TvecNw = iPara.Tf;
                    TvecNw(5) = TvecNw(5) - 1;
                    Ts0 = obj.sInfo.snTot.iExpt.Timing.T0;
                    xLim0 = calcTimeDifference(iPara.Ts0,Ts0)*obj.Tmlt;
                    xLimNew = calcTimeDifference...
                            (TvecNw,iPara.Ts0)*obj.Tmlt + xLim0;
                    
                    % resets the popup-values
                    xLimS = [xLim0 xLimNew];
                    obj.hStart.setConstraintRegion(xLimS,obj.yLim);
                    obj.resetPopupFields(obj.hPanelF,iPara.Tf)
            end
            
            % updates the experiment duration            
            obj.resetExptDurFields();
            
        end
        
        % --- resets the limit marers
        function resetLimitMarker(obj,xNew,Type)
            
            % updates the update flag
            obj.isUpdating = true;
            pause(0.01)
            
            % retrieves the object handle
            hObj = findobj(obj.hAx,'UserData',Type);            
            
            % DOES THIS NEED TO BE REMOVED?
            if length(hObj) > 1
                delete(hObj(2:end))
                hObj = hObj(1);
            end
            
            % resets the marker position
            setIntObjPos(hObj,[xNew(:),obj.yLim(:)]);
            
            % resets the update flag
            obj.isUpdating = false;
            
        end
                
        % --- resets the limit marker regions
        function resetLimitMarkerRegion(obj,hM,xLimNew)
            
            % sets the constraint/position callback functions
            hM.setConstraintRegion(obj.xLim,obj.yLim);
            hM.setConstraintRegion(obj.xLim,obj.yLim);
            
            hObj = findobj(obj.hAx,'UserData',Type,'Tag','hMark');
            setConstraintRegion(hObj,xLimNew,obj.yLim,isOld,'line');
            
        end                
        
        % ------------------------------------ %
        % --- METRIC CALCULATION FUNCTIONS --- %
        % ------------------------------------ %        
        
        % --- calculates the population velocities
        function calcPopVel(obj,iApp)
            
            % memory allocation    
            nFrm = length(obj.T);
            iVel = (1+obj.tBin):(nFrm-obj.tBin);
            Vplt = NaN(nFrm,size(obj.Px{iApp},2));
            
            % sets the time-step vectors
            dT = arrayfun(@(x)(diff(obj.T(x+obj.tBin*[-1,1]))),iVel);
            
            % calculates the inter-frame displacement
            a = zeros(1,size(obj.Px{iApp},2));
            if isempty(obj.Py{iApp})
                % 1D inter-frame distance calculations
                D = [a;abs(diff(obj.Px{iApp},[],1))];
            else    
                % 2D inter-frame distance calculations
                D = [a;sqrt(diff(obj.Px{iApp},[],1).^2 + ...
                            diff(obj.Py{iApp},[],1).^2)];    
            end 
            
            % sets the calculation indices
            if obj.isMltTrk
                % case is for multi-tracking
                vInd = 1:size(D,2);
            else
                % case is the other setups
                vInd = find(obj.fOK(:,iApp))';
            end
            
            % calculates the distance travelled and the time steps
            for i = vInd
                Vplt(iVel,i) = arrayfun(@(x)(sum...
                    (D((x-obj.tBin):(x+obj.tBin),i))),iVel)./dT;
            end
            
            % sets the final plot values
            obj.V{iApp} = Vplt;
            
        end
        
        % --- calculates the x/y location data for the plots
        function Z = setupPlotValues(obj,Type,iApp)
            
            % parameters
            snTot = obj.sInfo.snTot;
            iMov = snTot.iMov;
            
            % retrieves the base metric array
            switch Type
                case 'Vavg'
                    % case is the average speed
                    Pz = obj.V;
                    
                otherwise
                    % case is the other metrics
                    Pz = getStructField(obj,Type);
            end
            
            % if the region is rejected, then exit with a NaN value
            if isempty(Pz{iApp})
                Z = [];
                return
            end
            
            % sets the column/plot indices
            if obj.isMltTrk
                % case is the multi-tracking setup
                iSelP = get(obj.hPopupAP,'value');
                hGUIInfo = getappdata(obj.hFig,'hGUIInfo');
                iPlt = hGUIInfo.getMultiTrackPlotIndices(iMov,iSelP);
                [iRow,iCol] = hGUIInfo.getMultiTrackIndices(iApp);
                
            else
                % case is the other setup types
                iCol = iApp;
                iPlt = 1:size(Pz{iApp},2);
            end
            
            % sets the extremum values (used for normalising the signals
            switch Type
                case 'Px'
                    % case is the x-location data
                    if iscell(iMov.iC{iCol})
                        % determines the min/max range of the tube regions
                        zMin = cellfun(@(x)(x(1)-1),iMov.iC{iCol});
                        zMax = cellfun(@(x)(x(end)-1),iMov.iC{iCol});
                        zH = 0.5*(zMin + zMax);
                        
                        % determines the min/max range of actual points, 
                        % and determines which group these values belong to
                        Zmn = min(Pz{iApp},[],1);
                        Zmx = max(Pz{iApp},[],1);
                        iX = arrayfun(@(x)(argMin(abs(x-zH))),(Zmn+Zmx)/2);
                        
                        % calculates the normalized position values
                        Z = zeros(size(Pz{iApp}));
                        for i = 1:length(zMin)
                            ii = iX == i;
                            zDen = zMax(i) - zMin(i);
                            Z(:,ii) = (Pz{iApp}(:,ii)-zMin(i))/zDen;
                        end
                    else                            
                        % sets the horizontal offset
                        zMin = iMov.iC{iCol}(1) - 1;
                        zMax = iMov.iC{iCol}(end) - 1;
                        
                        % calculates the normalised location
                        Z = (Pz{iApp}(:,iPlt) - zMin)/(zMax - zMin);
                    end
                    
                case 'Py'
                    % case is the y-location data
                    if iscell(iMov.iC{iCol})
                        % determines the min/max range of the tube regions
                        zMin = cellfun(@(x)(x(1)-1),iMov.iR{iCol});
                        zMax = cellfun(@(x)(x(end)-1),iMov.iR{iCol});
                        zH = 0.5*(zMin + zMax);
                        
                        % determines the min/max range of actual points, 
                        % and determines which group these values belong to
                        Zmn = min(Pz{iApp},[],1);
                        Zmx = max(Pz{iApp},[],1);
                        iX = arrayfun(@(x)(argMin(abs(x-zH))),(Zmn+Zmx)/2);
                        
                        % calculates the normalized position values
                        Z = zeros(size(Pz{iApp}));
                        for i = 1:length(zMin)
                            ii = iX == i;
                            zDen = zMax(i) - zMin(i);
                            Z(:,ii) = (Pz{iApp}(:,ii)-zMin(i))/zDen;
                        end
                    else
                        if obj.isMltTrk
                            % sets the min/max scaling values
                            zMin = iMov.yTube{iCol}(iRow,1);
                            zMax = iMov.yTube{iCol}(iRow,2);
                        else
                            % sets the min/max scaling values
                            nRow = size(Pz{iApp},1);
                            zMin = repmat(iMov.yTube{iCol}(:,1)',nRow,1);
                            zMax = repmat(iMov.yTube{iCol}(:,2)',nRow,1);                            
                        end                                                
                        
                        % calculates the normalised location
                        yOfs = iMov.iR{iCol}(1)-1;                        
                        Z = (Pz{iApp}(:,iPlt) - (zMin+yOfs))./(zMax-zMin);
                    end
                    
                case ('V')
                    % case is average speed
                    pV = 1/(obj.pW*max(Pz{iApp}(:),[],'omitnan'));
                    Z = pV*Pz{iApp}(:,iPlt);
                    
                case ('Phi')
                    % case is orientation angle
                    Z = (Pz{iApp}(:,iPlt) + 180)/360;
                    
                case ('Vavg')
                    % case is the grouped average speed
                    hGUIInfo = getappdata(obj.hFig,'hGUIInfo');
                    
                    % retrieves the region acceptance flag and grouping indices
                    flyok = hGUIInfo.ok;
                    
                    % determnes the unique groupings comprising the expt
                    iGrp = getRegionGroupIndices(iMov,obj.sInfo.gName);
                    iGrpU = unique(iGrp(iGrp>0),'stable');
                    
                    % memory allocation
                    if obj.isMltTrk
                        % case is multi-tracking
                        jGrp = num2cell(arr2vec(iGrp')');
                        okG = num2cell(arr2vec(flyok')');
                        
                    else
                        % case is the other setups
                        jGrp = num2cell(iGrp,1);
                        okG = num2cell(flyok,1);
                    end
                    
                    % calculates the avg. velocity based on grouping type
                    Zgrp = cell(1,length(iGrpU));
                    for i = 1:length(Zgrp)
                        Zgrp{i} = cell2mat(cellfun(@(x,j,ok)...
                            (x(:,(j==iGrpU(i)) & ok)),Pz,jGrp,okG,'un',0));                        
                        if isempty(Zgrp{i})
                            Zgrp{i} = NaN(size(Pz{1},1),1);
                        else
                            Zgrp{i} = mean(Zgrp{i},2,'omitnan');
                        end
                    end
                    
                    % normalises the signals to the maximum
                    Z = cell2mat(Zgrp);
                    Z = Z/(obj.pW*max(Z(:),[],'omitnan'));
            end
            
        end

        % --------------------------------------- %
        % --- EXPERIMENTAL DATA I/O FUNCTIONS --- %
        % --------------------------------------- %        
        
        % --- sets the currently selected experiment information struct
        function setCurrentExptInfo(obj)
            
            % retrieves the currently selected expt index 
            iTab = get(get(obj.hTabGrp,'SelectedTab'),'UserData');

            % sets the current expt solution file information
            obj.sInfo = obj.sInfoT{iTab};
            
        end
        
        % --- updates the currently selected experiment information struct
        function updateCurrentExptInfo(obj)
            
            % retrieves the currently selected expt index
            iTab = get(get(obj.hTabGrp,'SelectedTab'),'UserData');
            
            % overall field retrieval
            sInfo0 = getappdata(obj.hFig,'sInfo');
            [sInfo0{iTab},obj.sInfoT{iTab}] = deal(obj.sInfo);
            setappdata(obj.hFig,'sInfo',sInfo0)
            
        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- resets the experiment duration fields
        function resetExptDurFields(obj)
            
            % calculates the experiment duration
            tExpt = obj.getCurrentExptDur(obj.sInfo.iPara);
            
            % sets the properties for each of the editboxes
            for i = 1:length(tExpt)
                % sets the callback function
                hEdit = findall(obj.hPanelD,'UserData',i,'Style','Edit');
                set(hEdit,'String',num2str(tExpt(i)))
            end
            
        end        
        
        % --- resets the marker heights
        function resetMarkerHeight(obj,yLimM)
            
            % retrieves the marker line objects
            hMark = findall(obj.hAx,'tag','hMark');
            
            if isOldIntObjVer()
                % updates the marker line y-location
                x = findall(hMark,'tag','top line');
                set(x,'ydata',yLimM);
                
                % updates the end marker y-location
                y = findall(hMark,'tag','end point 2');
                set(y,'ydata',yLimM(2));
            else
                % updates the end marker y-location
                for i = 1:length(hMark)
                    fPos = getIntObjPos(hMark(i),false);
                    fPos(:,2) = yLimM;
                    setIntObjPos(hMark(i),fPos,false);
                end
            end
            
        end
        
        % --- retrieves the combine GUI font sizes
        function detCombineFontSizes(obj)
            
            % determines the font ratio
            newSz = get(obj.hPanelI,'position');
            fR = min(newSz(3:4)./obj.regSz(3:4))*obj.scrSz/72;
            
            % sets the font size based on the OS type
            if ismac
                % case is using a Mac
                [obj.axSize,obj.lblSize] = deal(20*fR,26*fR);
            else
                % case is using a PC
                [obj.axSize,obj.lblSize] = deal(11*fR,16*fR);
            end
            
        end                
        
        % --- retrieves the region from the popup menu selection
        function iReg = getMultiTrackRegion(obj,iSelP)

            % sets the default input arguments
            if ~exist('iSelP','var')
                iSelP = get(obj.hPopupAP,'value');
            end

            % retrieves the region index
            pStrS = getArrayVal(obj.hPopupAP.String,iSelP);
            iReg = str2double(getArrayVal(regexp(pStrS,'\d+','match'),1));

        end        
        
    end
    
    % static class methods
    methods (Static)
        
        % --- deletes the plot object (if it is valid)
        function deletePlotObj(hObj)
            
            if ~isnumeric(hObj)
                delete(hObj)
            end
                
        end        
        
        % --- calculates the maximum plot object count (for a given expt)
        function nRowMx = getMaxPlotObjCount(iMov)
            
            if detMltTrkStatus(iMov)
                % case is the multi-tracking
                nFly = iMov.pInfo.nFly;
                nRowMx = max(max(nFly(:)),max(iMov.pInfo.iGrp(:)));
                
            elseif iMov.is2D
                % case is a 2D experiment
                szGrp = size(iMov.pInfo.iGrp);
                nRowMx = max(max(szGrp),max(iMov.pInfo.iGrp(:)));

            else
                % case is a 1D experiment
                nRowMx = max(numel(iMov.pInfo.iGrp),size(iMov.flyok,1));
            end
            
        end        
        
        % --- resets the x/y data of the plot object, hObj
        function resetObjData(hObj,xData,yData)
            
            if isgraphics(hObj)
                if exist('yData','var')
                    set(hObj,'xData',xData,'yData',yData);
                else
                    set(hObj,'xData',xData);
                end
            end
            
        end
        
        % --- sets the axis visibility flags
        function setAxisObjVisibility(hObjImg,state)
            
            if strcmp(state,'on')
                hGrpFill = findall(hObjImg,'tag','hGrpFill');
                setObjVisibility(setxor(hObjImg,hGrpFill),'on');
            else
                setObjVisibility(hObjImg,'off')
            end
            
        end
        
    end
    
end
