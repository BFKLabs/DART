classdef StimSchemaObj < handle & dynamicprops
    
    % class properties
    properties
        
        % object handles
        hRectS
        hPlotS
        
        % main class handles
        isEx
        sPara
        
        % train signal fields
        xOfs0
        xS
        yS
        xS0
        yS0
        nS
        tMlt
        yLim
        pX
        pY  
        
        % boolen class fields
        isUsePatch
        useTOfs = true;    
        isInit = true;
        
        % other class fields
        dT = 0.01;
        lWidOff = 0.5;
        nLenMax = 10000;
        tStrB = 'hSigBlk';        
        
    end    
    
    % observable class properties    
    properties (SetObservable)
    
        sLim
        rPos
        tOfs
        
    end    
    
    % private class properties
    properties (Access = protected)
        
        objB
        
    end    
        
    % class methods
    methods
        
        % --- class constructor
        function obj = StimSchemaObj(objB,sPara,xOfs0)
            
            % input arguments
            obj.objB = objB;
            obj.sPara = sPara;
            
            % sets the initial horizontal offset value
            if exist('xOfs0','var')
                [obj.isEx,obj.xOfs0] = deal(true,xOfs0);                
            else
                [obj.isEx,obj.xOfs0] = deal(false,0);
            end
            
            % initialises the class fields/objects
            obj.linkParentProps();
            obj.initClassFields();
            obj.initClassObjects();
            obj.setListenerFunc();             
            
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %        
        
        % --- initialises the class object fields with that parent object
        function linkParentProps(obj)
            
            % parent fields strings
            fldStr = {'hFig','hAx','sBlkT','objDL','objP','objR','yGap',...
                      'iCh','iChH','iSigH','sCol','lWid','tDurTotU',...
                      'iExpt','calcExptStimDurFcn','nCh','chCol'};
            
            % connects the base/child objects
            for propname = fldStr
                if isprop(obj.objB, propname{1})
                    metaprop = addprop(obj, propname{1});
                    metaprop.SetMethod = @(obj, varargin) ...
                        SetDispatch(obj, propname{1}, varargin{:});
                    metaprop.GetMethod = ...
                        @(obj)GetDispatch(obj, propname{1});
                end
            end
            
        end
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            
            
        end
        
        % --- initialises the class objects
        function initClassObjects(obj)
            
         
            
        end        
        
        % --- sets the listener function
        function setListenerFunc(obj)
            
            % retrieves observable parameter information
            mc = ?StimSchemaObj;
            isObs = arrayfun(@(x)(x.SetObservable),mc.PropertyList);
            pStr = arrayfun(@(x)(x.Name),mc.PropertyList(isObs),'un',0);
                                    
            % sets the parameter listener functions
            for i = 1:length(pStr)
                addlistener(obj,pStr{i},'PostSet',...
                    @(s,e)obj.alterStimObjProps(s,e,pStr{i}));
            end
            
        end 
        
        % ----------------------------- %
        % --- PLOT OBJECT FUNCTIONS --- %
        % ----------------------------- %          
        
        % --- creates the signal rectangle interactive object
        function createRectObject(obj)
            
            % creates the interactive object
            obj.hRectS = InteractObj('rect',obj.hAx,obj.rPos);
            uistack(obj.hRectS.hObj,'top');
            
            % sets the rectangle constraint function
            obj.yLim = obj.rPos(2) + [0,obj.rPos(4)];
            obj.hRectS.setConstraintRegion(obj.sLim,obj.yLim);
            
            % sets the other object properties
            obj.setStimObjProps('ContextMenu',[],...
                             'FaceColor',0.8*[1,1,1],'Tag',obj.tStrB,...
                             'LineWidth',1,'LineStyle','none',...
                             'FaceAlpha',0.01,'MarkerSize',1,...
                             'UserData',1,'EdgeAlpha',0);
            
        end        
        
        % --------------------------------------- %        
        % --- OBJECT/EVENT CALLBACK FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- train property update function
        function alterStimObjProps(obj,~,~,pStr)
            
            if obj.isInit
                return
            end
            
            switch pStr
                case 'sLim'
                    % case is the stimuli object limits
                    
                    % resets the rectangle constraint region
                    obj.hRectS.setConstraintRegion(obj.sLim,obj.yLim);
                    
                case 'rPos'
                    % case is the rectangle position vector
                    
                    % updates the rectangle object position
                    obj.hRectS.setPosition(obj.rPos)
                    
                    % updates the left-most distance line
                    xL0 = [obj.sLim(1),obj.rPos(1)];
                    obj.objDL.setDistLinePos(1,xL0);
                    
                    % updates the right-most distance line
                    xL1 = [sum(obj.rPos([1,3])),obj.sLim(2)];
                    obj.objDL.setDistLinePos(2,xL1);
                    
                case 'tOfs'
                    % case is the stimuli object time offset
                    
                    % resets the
                    if obj.isEx
                        % case is the experimental protocol
                        tOfsP = obj.tOfs*obj.tMltO;
                        cellfun(@(h,x)(set(h,'XData',...
                            x([(1:end),1])+tOfsP)),obj.hPlotS,obj.xS);
                    else
                        % case is the stimuli protocols
                        obj.calcScaledStimuliSignal(false);
                        set(obj.hPlotS,'XData',obj.xS,'YData',obj.yS);
                    end
            end
            
        end       
        
        % --- deletes the train plot objects
        function deleteStimObj(obj)

            % deletes the plot objects
            if obj.isEx
                % case is for experimental protocol 
                cellfun(@delete,obj.hPlotS);
                
            else
                % case is for experimental protocol
                delete(obj.hPlotS)
            end
                
            % deletes the rectangle object
            obj.hRectS.deleteObj();
            
        end   
        
        % --- updates the train object properties
        function setStimObjProps(obj,varargin)
            
            for i = 1:length(varargin)/2
                obj.hRectS.setFields(varargin{2*(i-1)+1},varargin{2*i});
            end
            
        end
        
        % ------------------------------- %        
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- recalculates the time offset
        function recalcTimeOffset(obj)
            
            tMltOfs = obj.calcTimeMultiplier('tOfs');
            obj.tOfs = obj.sPara.tOfs*obj.useTOfs*tMltOfs;
            
        end
        
        % --- calculates the pixel to axes scale factor
        function calcPixelScaleFactor(obj)
            
            % field retrieval
            axDim = obj.hAx.Position(3:4);
            
            % determines the pixel-to-data scale factors
            obj.pX = obj.sPara.tDur/axDim(1);
            obj.pY = diff(obj.hAx.YLim)/axDim(2);
            
        end
        
        % --- recalculates the time multiplier and signal offset
        function tMltD = calcTimeMultiplier(obj,pStrD)
        
            % field setup
            pUnitD = sprintf('%sU',pStrD);
            
            % sets the duration/base units for the calculations
            if obj.isEx
                tDurUnits = obj.iExpt.Timing.TexpU(1);
            else
                tDurUnits = obj.tDurTotU;
            end
            
            % calculates the time multiplier
            tMltD = getTimeMultiplier(tDurUnits,obj.sPara.(pUnitD));
            
        end
        
        % --- determines if a patch is required to represent a signal block
        function usePatch = detIfUsePatch(obj)
            
            % retrieves the axis limits/position
            axP = get(obj.hAx,'Position');
            dtLim = diff(obj.hAx.XLim)/(2*axP(3));
            
            % determines if any of the groups (where the signal is 
            % non-zeros) is greater than the threshold time limit
            iGrp = getGroupIndex(obj.yS > obj.yS(end));
            if isempty(iGrp)
                usePatch = true;
            else
                usePatch = any(cellfun(@(x)(...
                    any(diff(obj.xS(x)) > dtLim)),iGrp));
            end
            
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