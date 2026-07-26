classdef BlockObj < StimSchemaObj
    
    % class properties
    properties
        
        % main class handles
        iChB
        idBlk
        sTrain        
        
        % plot object class fields
        tMltO
        chColB
        chColF
        
        % function handle fields
        updateMinDurFcn
        
        % static string class fields
        blkTagStr = 'hSigBlk';
        
    end
            
    % class methods
    methods
        
        % --- class constructor
        function obj = BlockObj(objB,sPara,sTrain,iChB,xOfs)
            
            % creates the super-class object
            obj@StimSchemaObj(objB,sPara,xOfs);             
            
            % input arguments
            obj.iChB = iChB;
            obj.sTrain = sTrain;
            
            % other property updates
            obj.idBlk = objB.idBlk;
            obj.updateMinDurFcn = objB.updateMinDurFcn;
            
            % initialises the class fields/objects
            obj.initBlockClassFields();
            obj.initBlockClassObjects();
            
            % resets the initialisation flag
            obj.isInit = false;                     
                        
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %                
        
        % --- initialises the class fields
        function initBlockClassFields(obj)
            
            % recalculates the time offset            
            obj.recalcTimeOffset();   
            obj.tMltO = obj.calcTimeMultiplier('tOfs');
            [obj.sPara.tOfs,obj.tOfs] = deal(obj.xOfs0/obj.tMltO);
            
            % sets up the position vector
            y0 = obj.nCh - obj.iChB(end);
            h0 = rangewr(obj.iChB) + (1-obj.yGap);
            tDurBlk = obj.calcExptStimDurFcn(obj.sTrain,obj.sPara);
            rPos0 = [obj.xOfs0,y0+obj.yGap,tDurBlk,h0];
            
            % sets the channel colour
            obj.chColF = flip(obj.chCol);
            obj.chColB = obj.chColF(obj.iChB);
            
            % retrieves the temporary stimuli block properties
            obj.rPos = rPos0;
            obj.sLim = obj.objB.getFeasRegionLimits(rPos0(1)+rPos0(3)/2);
            
            % sets up the signal coordinates
            obj.calcPixelScaleFactor();
            obj.calcStimBlockSignals();            
            
        end
        
        % --- initialises the class objects
        function initBlockClassObjects(obj)
            
            % turns axis hold on
            hold(obj.hAx,'on');
            
            % creates the plot/rectangle objects
            obj.updatePlotObject()            
            obj.createRectObject()
            
            % sets the block-specific properties
            obj.setStimObjProps('LineWidth',2,...
                                'EdgeColor','k',...
                                'FaceAlpha',0.01,...
                                'EdgeAlpha',1,...
                                'Tag',obj.blkTagStr,...
                                'UserData',obj.idBlk);
                            
            % sets the callback function
            obj.hRectS.setObjMoveCallback(@obj.moveBlockObj);
                            
            % turns off the axes hold
            hold(obj.hAx,'off');                      
            
        end
        
        % ----------------------------- %
        % --- PLOT OBJECT FUNCTIONS --- %
        % ----------------------------- %
               
        % --- creates the signal plot object
        function updatePlotObject(obj)
            
            % determines if the plots need to be recreated
            resetPlot = isempty(obj.hPlotS) || ~isvalid(obj.hPlotS{1});
            if resetPlot
                obj.hPlotS = cell(length(obj.iChB),1);
            end            
            
            % creates the signal patch/plot object
            tOfsP = obj.tOfs*obj.tMltO;            
            for i = 1:length(obj.iChB)
                % otherwise, the signal using a line
                xiS = [(1:length(obj.xS{i})),1];
                [xP,yP] = deal(obj.xS{i}(xiS)+tOfsP,obj.yS{i}(xiS));                
                
                if obj.isUsePatch
                    % case is using a patch object
                    if isempty(obj.hPlotS) || ...
                      ~isvalid(obj.hPlotS) || ...
                      (i > length(obj.hPlotS))
                        % case is a new patch is required
                        hold(obj.hAx,'on');
                        hPatchNw = patch(obj.hAx,xP,yP,...
                            obj.chColB{i},'EdgeColor',obj.chColB{i},...
                            'LineWidth',1,'FaceAlpha',0.2);
                        hold(obj.hAx,'off');
                        
                        % stores the plot item
                        if i > length(obj.hPlotS)
                            obj.hPlotS{end+1} = hPatchNw;
                        else
                            obj.hPlotS{i} = hPatchNw;
                        end  
                        
                    else
                        % otherwise, update the plot coordinates
                        set(obj.hPlotS{i},'XData',xP(xiP),'YData',yP(xiP));
                    end

                else
                    % case is using a plot object
                    if resetPlot || (i > length(obj.hPlotS))
                        % case is a new plot is required
                        hold(obj.hAx,'on');
                        hPlotNw = plot(obj.hAx,xP,yP);                        
                        set(hPlotNw,'Color',obj.chColB{i});
                        hold(obj.hAx,'off');
                        
                        % stores the plot item
                        if i > length(obj.hPlotS)
                            obj.hPlotS{end+1} = hPlotNw;
                        else
                            obj.hPlotS{i} = hPlotNw;
                        end
                        
                    else
                        % otherwise, update the plot coordinates
                        set(obj.hPlotS{i},'XData',xP,'YData',yP)
                    end
                end
            end
            
            % resets the data arrays
            if length(obj.hPlotS) > length(obj.iChB)
                cellfun(@delete,obj.hPlotS((length(obj.iChB)+1):end));
                obj.hPlotS = obj.hPlotS(1:length(obj.iChB));
            end            
            
        end        
        
        % --------------------------------------- %        
        % --- OBJECT/EVENT CALLBACK FUNCTIONS --- %
        % --------------------------------------- %        
        
        % --- block parameter alteration callback function
        function alterBlockPara(obj,sParaS,pStrU)
            
            % default input arguments
            if ~exist('pStrU','var')
                pStrU = fieldnames(obj.sPara);
                pStrU = pStrU(~strcmp(pStrU,'tOfs'));
            end
            
            % updates the parameter fields
            for i = 1:length(pStrU)
                obj.sPara.(pStrU{i}) = sParaS.(pStrU{i});                
            end   
            
            % recalculates the time offset
            if ~isempty(intersect(pStrU,{'tOfs','tOfsU'}))
                obj.tOfs = obj.sPara.tOfs;
                obj.tMltO = obj.calcTimeMultiplier('tOfs');
            end            
            
            % recalculates the time multiplier/offset
            if ~isempty(intersect(pStrU,{'tDur'}))
                obj.calcPixelScaleFactor();
            end                        
            
            % recalculates the stimuli block signals
            obj.calcStimBlockSignals();            
            
            % updates the plot signal/objects
            tDurBlk = obj.calcExptStimDurFcn(obj.sTrain,obj.sPara);   
            obj.rPos([1,3]) = [obj.tOfs*obj.tMltO,tDurBlk];
            obj.updatePlotObject();
            
        end
        
        % --- block object rectangle object movement event function
        function moveBlockObj(obj,varargin)
            
            % resets the current object position
            obj.rPos = obj.hRectS.getPosition();
            
            % updates the signal offset
            obj.tOfs = obj.rPos(1)/obj.tMltO;
            obj.sPara.tOfs = obj.tOfs;
            
            % updates the minimum duration button property function
            if ~isempty(obj.objB.updateMinDurFcn)
                obj.updateMinDurFcn();
            end
            
            % updates the time offset parameter field
            obj.objR.updateParaField('tOfs',obj.sPara.tOfs);            
            
        end        
        
        % ------------------------------ %
        % --- CLASS SETTER FUNCTIONS --- %
        % ------------------------------ %        
        
        % --- sets the train object properties
        function setBlockObjHighlight(obj,eState)
            
            if strcmp(eState,'on')
                obj.setStimObjProps('EdgeAlpha',1,...
                                    'LineWidth',obj.lWid);                
            else
                % case is removing
                obj.setStimObjProps('EdgeAlpha',0,...
                                    'LineWidth',obj.lWidOff,...
                                    'EdgeColor','k');
            end
            
        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- resets the block time units
        function resetBlockTimeUnits(obj,tUnitsNw)
            
            % field retrieval
            tUnits0 = obj.tDurTotU;
            obj.tDurTotU = tUnitsNw;
            obj.tMltO = obj.calcTimeMultiplier('tOfs');
            
            % converts the block time offset/duration
            obj.rPos([1,3]) = ...
                convertTime(obj.rPos([1,3]),tUnits0,tUnitsNw);
            obj.xS = cellfun(@(x)(...
                convertTime(x,tUnits0,tUnitsNw)),obj.xS,'un',0);
            
            % resets the block coordinates
            obj.updatePlotObject();
            
        end
        
        % --- resets the block properties
        function resetBlockProps(obj)
            
            % recalculates and replots the stimuli block object
            obj.calcStimBlockSignals();
            obj.updatePlotObject();            
            
            % sets up the position vector
            y0 = obj.nCh - obj.iChB(end);
            h0 = rangewr(obj.iChB) + (1-obj.yGap);
            tDurBlk = obj.calcExptStimDurFcn(obj.sTrain,obj.sPara);
            obj.rPos(2:4) = [y0+obj.yGap,tDurBlk,h0];            
                        
        end
        
        % --- sets up the stimuli block signal coordinates
        function calcStimBlockSignals(obj)
            
            % sets up the block object coordinates
            xyData = setupFullExptSignal(obj.objB,obj.sTrain,obj.sPara);
            obj.xS = cellfun(@(x)(x(:,1)),xyData(obj.iChB),'un',0);
            obj.yS = cellfun(@(x)(x(:,2)),xyData(obj.iChB),'un',0);            
            
            % determines the overall maximum length stimuli trace
            nS0 = cellfun('length',obj.xS);
            obj.nS = length(max(nS0));
            
            % resets the use patch field
            if isempty(obj.isUsePatch)
                obj.isUsePatch = (obj.nS > obj.nLenMax);
            end
            
        end        
        
        % --- calculates the time multiplier
        function tMlt = calcExptTimeMultiplier(obj,tUnit0)
        
             tMlt = getTimeMultiplier(tUnit0,obj.iExpt.Timing.TexpU);
            
        end        
        
        % --- updates the block object channel indices
        function updateChannelIndices(obj,iChBNw)
            
            % resets the index/colour fields
            obj.iChB = iChBNw;
            obj.chColB = obj.chColF(obj.iChB);
            
            % resets the patch/plot line colours
            for i = 1:min(length(obj.chColB),length(obj.hPlotS))
                if obj.isUsePatch
                    % resets the plot colour
                    set(obj.hPlotS{i},...
                        'Color',obj.chColB{i},'EdgeColor',obj.chColB{i})                    
                else
                    % resets the plot colour
                    set(obj.hPlotS{i},'Color',obj.chColB{i})
                end
            end
            
        end
        
    end
    
end