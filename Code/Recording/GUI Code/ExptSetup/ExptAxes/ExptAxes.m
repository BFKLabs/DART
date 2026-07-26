classdef ExptAxes < handle & dynamicprops
    
    % class properties
    properties
        
        % sub-class object fields
        objS
        
        % plot handle class fields
        hPltF
        hPltTest
        hDL        
        hLblX 
        
        % other class fields
        tType
        nChTot
        
        % fixed numerical class fields
        tHght = 24;
        fSzAx = 14;        
        fSzLbl = 14;
        fSzAxLbl = 16;        
        axLimMax = 1800;        
        pyLim = 0.04;        
        
        % other numerical class fields
        yGap
        
    end
    
    % private class properties
    properties (Access = private)
        
        objB
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = ExptAxes(objB,tType)
            
            % input arguments
            obj.objB = objB;
            obj.tType = tType;
            
            % initialises the class fields/objects
            obj.linkParentProps();
            obj.initAxesClassFields();
            obj.initAxesClassObjects();            
            
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %        
        
        % --- initialises the class object fields with that parent object
        function linkParentProps(obj)
            
            % parent fields strings
            fldStr = {'hFig','hPanelAx','hAx','iExpt',...
                      'pAx','axPosX','axPosY','mType','mpStrDef',...
                      'nCh','chName','chID','chInfo','chCol','sName',...
                      'tDurTot','tDurTotU','nDev','clearTimerFcn',...
                      'isInit','isShort','isHLOn','isOverAxesFcn',...
                      'isMouseDown','defMouseCursor','setPanelPropFcn',...
                      'sTrainP','calcExptStimDurFcn',...
                      'objR','objP','objSM','objT'};
            
            % connects the base/child objects
            for propname = fldStr
                metaprop = addprop(obj, propname{1});
                metaprop.SetMethod = @(obj, varargin) ...
                    SetDispatch(obj, propname{1}, varargin{:});
                metaprop.GetMethod = @(obj)GetDispatch(obj, propname{1});
            end
            
        end
        
        % --- initialises the class fields
        function initAxesClassFields(obj)
            
            % array dimension sizes
            obj.nChTot = sum(obj.nCh);
            
        end
        
        % --- initialises the class objects
        function initAxesClassObjects(obj)
            
            % creates the axes object
            obj.hAx = createUIObj('axes',obj.hPanelAx,'Units',...
                'Pixels','FontUnits','Pixels','Position',obj.pAx,...
                'Box','On');            

            % -------------------------------- %
            % --- PLOT AXES INITIALISATION --- %
            % -------------------------------- %                                    
            
            % x-axis label
            if strcmp(obj.tType,'Proto')
                % case is the experiment protocol tab
                if obj.iExpt.Timing.fixedT0
                    % case is a fixed start time
                    xLbl = 'Time';
                else
                    % case is a free start time
                    xLbl = sprintf('Time (%s)',obj.tDurTotU);                    
                end
            else
                % case is the other tabs
                xLbl = sprintf('Time (%s)',obj.tDurTotU);
            end
            
            % sets the x/y axis limits & x-axis tick marks
            xLim = obj.calcAxisLimits(obj.tDurTot,'x');
            yLim = obj.calcAxisLimits(obj.nChTot,'y');
            obj.yGap = obj.pyLim*yLim(2); 
            
            % sets the axis properties
            yTick = (1:obj.nChTot) - (0.5 - obj.yGap/2);
            set(obj.hAx,'box','on','xlim',xLim,'ylim',yLim,...
                    'ytick',yTick,'yticklabel',obj.chInfo(end:-1:1,2),...
                    'TickLength',[0,0],'FontSize',obj.fSzAx,...
                    'FontWeight','bold')                      
            ytickangle(obj.hAx,0);
            
            % sets the x-axis label
            obj.hLblX = xlabel(obj.hAx,xLbl,'FontSize',obj.fSzLbl,...
                'FontWeight','bold','tag','xLabel');             
            
            % if not initialising, then clear the plot axes
            if ~obj.isInit; cla(obj.hAx); end

            % ---------------------------------- %
            % --- PLOT MARKER INITIALISATION --- %
            % ---------------------------------- %
            
            % initialisations
            xPlt = obj.axLimMax*[-1,1];
            sID = cell2mat(obj.chInfo(end:-1:1,1));
            
            % turns on the axis hold
            hold(obj.hAx,'on')            
            
            % plots the
            for i = 0:obj.nChTot
                % plots the edge markers
                plot(obj.hAx,xPlt,(i+obj.yGap)*[1,1],'k:')
                
                % creates the device/channel marker lines
                if i < obj.nChTot
                    if i > 0
                        if sID(i+1) ~= sID(i)
                            % case is a device separation line
                            hPltDev = plot(obj.hAx,...
                                xPlt,i*[1,1],'k','linewidth',2);
                            uistack(hPltDev,'bottom')
                        else
                            % case is a channel separation line
                            plot(obj.hAx,obj.axLimMax*[-1,1],i*[1,1],'k:')
                        end
                    end
                end
            end
            
            % plots the start/end time markers
            plot(obj.hAx,[0,0],yLim,'k')
            obj.hPltF = plot(obj.hAx,obj.tDurTot*[1,1],yLim,'k');            
            
            % creates the y-axis labels
            obj.createYAxisLabels(sID,yTick);            

            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % creates the stimuli object manager
            if strcmp(obj.tType,'Stim')
                obj.objSM = TrainObjManager(obj);
            else
                obj.objSM = BlockObjManager(obj);
            end
                        
            % turns off the axis hold
            hold(obj.hAx,'off')            
            
        end        
        
        % --- creates the y-axis labels
        function createYAxisLabels(obj,sID,yTick)
            
            % memory allocation
            xLim = obj.hAx.XLim;
            hText = zeros(obj.nDev,1); 
            sIDU = unique(cell2mat(obj.chInfo(:,1)));
            
            % calculates the x-coordinates of the text label
            pIns = obj.hAx.TightInset;
            xTxt = xLim(1) - diff(xLim)*(pIns(1)+3*obj.tHght/4)/obj.pAx(3);
            
            % inserts the text label for each device
            for i = 1:obj.nDev
                % determines the matching serial device index
                iMatch = find(sID==sIDU(i));
                
                % retrieves the device type string
                dType = obj.chInfo{end-(iMatch(1)-1),3};
                switch dType
                    case 'HTControllerV3'
                        % case is the HTControllerV3 device
                        dType = 'HT Controller (V3)';
                end
                
                % creates the text object
                hText(i) = text(obj.hAx,xTxt,mean(yTick(iMatch)),dType,...
                            'FontSize',obj.fSzAxLbl,'FontWeight','bold',...
                            'Rotation',90,'HorizontalAlignment','Center');
            end
            
            % resets axis position to accomodate the device titles
            set(hText,'Units','Pixels')
            tPos = get(hText(1),'Extent');
            dPos = ceil(5 - (obj.pAx(1)+tPos(1)));
            resetObjPos(obj.hAx,'left',dPos,1)
            resetObjPos(obj.hAx,'width',-dPos,1)            
            
        end        
        
    end
    
    % static class methods
    methods (Static)
        
        % --- calculates the axis limits (dependent on size and type)
        function axLim = calcAxisLimits(x,axType)
            
            % sets the proportional gap based on axis type
            switch axType
                case 'x'
                    % case is the x-axis limits
                    pLim = 0.025;
                    
                case 'y'
                    % case is the y-axis limits
                    pLim = 0.0;
                    
            end
            
            % calculates the axis limits
            axLim = [0,x] + [-1,1]*(pLim*x);
            
        end
        
    end
    
    % private class methods
    methods (Access = private)
        
        % --- sets a class object field
        function SetDispatch(obj, propname, varargin)
            obj.objB.(propname) = varargin{:};
        end
        
        % --- gets a class object field
        function varargout = GetDispatch(obj, propname)
            varargout{:} = obj.objB.(propname);
        end
        
    end
    
end