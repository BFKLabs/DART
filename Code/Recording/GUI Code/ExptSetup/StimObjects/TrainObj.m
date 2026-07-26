classdef TrainObj < StimSchemaObj
    
    % class properties
    properties
        
        % main class handles
        sType
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = TrainObj(objB,sPara)
            
            % input arguments
            obj@StimSchemaObj(objB,sPara);
            
            % initialises the class fields/objects
            obj.initTrainClassFields();
            obj.initTrainClassObjects();
                        
            % resets the initialisation flag
            obj.isInit = false;            
            
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %                
        
        % --- initialises the class fields
        function initTrainClassFields(obj)
        
            % recalculates the time offset
            obj.recalcTimeOffset();            

            % sets up the position vector
            tMltDur = obj.calcTimeMultiplier('tDur'); 
            rPos0 = [obj.tOfs,(obj.iChH-1)+obj.yGap,...
                     obj.sPara.tDur*tMltDur,1-obj.yGap];                 
    
            % retrieves the temporary stimuli block properties
            obj.rPos = rPos0;            
            obj.sLim = obj.sBlkT.sLim;
            obj.sType = obj.sPara.dType;          
            
            % sets up the signal coordinates
            obj.calcPixelScaleFactor();
            obj.calcInitialStimuliSignal()                        
            
        end
        
        % --- initialises the class objects
        function initTrainClassObjects(obj)
            
            % turns axis hold on
            hold(obj.hAx,'on');
            
            % creates the plot/rectangle objects
            obj.updatePlotObject()            
            obj.createRectObject()
            
            % sets the callback function
            obj.hRectS.setObjMoveCallback(@obj.moveTrainObj);            
            
            % resets the train specific properties
            obj.setStimObjProps('EdgeColor',obj.sCol);
            
            % turns off the axes hold
            hold(obj.hAx,'off');                          
            
        end        
        
        % ----------------------------- %
        % --- PLOT OBJECT FUNCTIONS --- %
        % ----------------------------- %        
        
        % --- creates the signal plot object
        function updatePlotObject(obj)
            
            % creates the signal patch/plot object
            if obj.isUsePatch
                % creates the patch object
                [xP,yP] = obj.setupPatchCoords();
                xiP = [(1:length(xP)),1];
                
                if isempty(obj.hPlotS) || ~isvalid(obj.hPlotS)
                    % case is a new patch is required
                    obj.hPlotS = patch(obj.hAx,xP(xiP),yP(xiP),obj.sCol,...
                        'LineWidth',1,'FaceAlpha',0.2,...
                        'EdgeColor',obj.sCol);
                else
                    % otherwise, update the plot coordinates
                    set(obj.hPlotS,'XData',xP(xiP),'YData',yP(xiP));
                end
                
            else
                % otherwise, the signal using a line
                xiS = [(1:obj.nS),1];
                
                if isempty(obj.hPlotS) || ~isvalid(obj.hPlotS)
                    % case is a new plot is required
                    obj.hPlotS = plot(obj.hAx,obj.xS(xiS),obj.yS(xiS));
                    set(obj.hPlotS,'Color',obj.sCol)
                else
                    % otherwise, update the plot coordinates
                    set(obj.hPlotS,'XData',obj.xS(xiS),'YData',obj.yS(xiS))
                end
            end
            
        end

        % --------------------------------------- %
        % --- OBJECT EVENT/CALLBACK FUNCTIONS --- %
        % --------------------------------------- %        
        
        % --- updates the train parameters
        function alterTrainPara(obj,sParaS,pStrU)
            
            % default input arguments
            if ~exist('pStrU','var')
                pStrU = fieldnames(sParaS);
%                 pStrU = pStrU(~strcmp(pStrU,'tOfs'));
            end
            
            % updates the parameter fields
            for i = 1:length(pStrU)
                obj.sPara.(pStrU{i}) = sParaS.(pStrU{i});
                
                switch pStrU{i}
                    case 'dType'
                        obj.sType = sParaS.(pStrU{i});
                end
            end
            
            % recalculates the time offset
            if ~isempty(intersect(pStrU,{'tOfs','tOfsU'}))
                obj.recalcTimeOffset();
            end

            % recalculates the time multiplier/offset
            if ~isempty(intersect(pStrU,{'tDur'}))
                obj.calcPixelScaleFactor();
            end
            
            % recalculates the stimuli signal
            obj.calcInitialStimuliSignal();
            
            % resets the rectangle/signal plot coordinates
            tMltDur = obj.calcTimeMultiplier('tDur');
            obj.rPos([1,3]) = [obj.tOfs,obj.sPara.tDur*tMltDur];
            obj.updatePlotObject();
            
        end
        
        % --- train object rectangle object movement event function
        function moveTrainObj(obj,~,evnt)
            
            % resets the current object position
            obj.rPos = evnt.CurrentPosition;

            % updates the signal offset
            obj.tOfs = obj.rPos(1);
            obj.sPara.tOfs = obj.tOfs/obj.calcTimeMultiplier('tOfs');
            
            % updates the time offset parameter field
            obj.objP.updateParaField('tOfs',obj.sPara.tOfs);
                        
        end
        
        % ------------------------------- %        
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- sets up the feasible patch coordinates
        function [xP,yP] = setupPatchCoords(obj)
            
            if obj.nS > obj.nLenMax
                % if too many points, then downsample?
                yL = [floor(min(obj.yS))+obj.yGap,ceil(max(obj.yS))];
                xP = obj.xS([1,end,end,1]);
                yP = yL([1,1,end,end]);
                
            else
                % otherwise, use all points
                [xP,yP] = deal(obj.xS,obj.yS);
            end            
            
        end
        
        % --- sets the train object properties
        function setTrainObjHighlight(obj,eState)
            
            if strcmp(eState,'on')
                
            else
                % case is removing
                obj.setStimObjProps('EdgeAlpha',0,...
                                    'Color',obj.sCol,...
                                    'EdgeColor',obj.sCol,...
                                    'LineWidth',obj.lWidOff);
            end
            
        end
        
        % --- calculates the initial stimuli signal
        function calcInitialStimuliSignal(obj,calcScaled)
            
            % default input arguments
            if ~exist('calcScaled','var')
                calcScaled = true;
            end
            
            % calculates the actual stimuli signal values
            [obj.xS0,obj.yS0] = ...
                setupStimuliSignal(obj.sPara,obj.sType,obj.dT);
            
            % calculates the signal length
            obj.nS = length(obj.xS0);                
            obj.xS0 = obj.xS0*obj.calcTimeMultiplier('tDur');            
            
            % calculates the scale stimuli signal (if required)
            if calcScaled
                obj.calcScaledStimuliSignal();
            end
            
            % determines if a patch if to be used
            if isempty(obj.isUsePatch)
                obj.isUsePatch = obj.detIfUsePatch() || ...
                                (obj.nS > obj.nLenMax);
            end
            
        end
        
        % --- calculates the scaled stimuli signals
        function calcScaledStimuliSignal(obj,calcY)
            
            % default input arguments
            if ~exist('calcY','var')
                calcY = true;
            end            
                        
            % calculates the scaled x-data values
            dX = diff(obj.xS0([1,end]));            
            xOfs = roundP(obj.tOfs,0.001) + obj.pX;
            obj.xS = (xOfs + (dX-2*obj.pX)*(obj.xS0-obj.xS0(1))/dX);
            obj.rPos(1) = obj.xS(1);
            
            % calculates the scaled y-data values
            if calcY
                yOfs = (obj.pY+obj.yGap)+(obj.iChH-1);
                obj.yS = yOfs + (1-(obj.yGap+3*obj.pY))*obj.yS0/100;
            end
            
        end
        
    end
    
end