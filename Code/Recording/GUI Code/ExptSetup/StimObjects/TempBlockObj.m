classdef TempBlockObj < TempStimObj
    
    % class properties
    properties
       
        % main class object handles
        iChB
        sParaB
        sTrainB
        
        % plot property class fields
        nPlotB
        hPlotB
        chColB
        
        % channel coordinates
        xChS
        yChS
        
        % boolean class fields
        isUsePatch
        
        % parameter class fields
        lWid = 1;
        fAlpha = 0.2;     
        lWidOff = 0.5;
        nLenMax = 10000;        
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = TempBlockObj(objB)
            
            % creates the super-class object
            obj@TempStimObj(objB,true);
                        
            % sets the movement region/callback function
            obj.setObjMoveCallback(@obj.moveBlockObj,1);            
            
        end
        
        % --- stimuli object movement callback function
        function moveBlockObj(obj,varargin)
            
            if obj.isUpdating
                return
            end                        
            
            % runs the common movement updates
            obj.moveStimObj();            
            
            % updates the 
            xOfs = obj.rPos(1);
            cellfun(@(h,x)(set(h,'XData',x+xOfs)),obj.hPlotB,obj.xChS);
            
        end
        
        % --- resets the object properties
        function updateObjProps(obj,rPosNw,sLim,sTrainB,sParaB,iChB)
            
            % updates the common stimuli object properties
            obj.updateStimObjProps(rPosNw,sLim);  
            
            % updates the class fields
            obj.sTrainB = sTrainB;
            obj.sParaB = sParaB;
            obj.iChB = iChB;
            
            % sets the block colours
            chColF = flip(obj.objB.chCol);
            obj.chColB = chColF(obj.iChB);            
            
            % stimuli train coordinate calculations
            xyData = setupFullExptSignal(obj,sTrainB,sParaB);
            obj.xChS = cellfun(@(x)(x(:,1)),xyData(iChB),'un',0);
            obj.yChS = cellfun(@(x)(x(:,2)),xyData(iChB),'un',0);
            obj.isUsePatch = all(cellfun('length',obj.xChS) < obj.nLenMax);
            
            % memory allocation
            obj.nPlotB = length(iChB);
            obj.hPlotB = cell(obj.nPlotB,1);            

            % creates the plot objects
            xOfs = obj.rPos(1);            
            hold(obj.hAx,'on');            
            for i = 1:obj.nPlotB
                if obj.isUsePatch
                    % case is creating a patch
                    obj.hPlotB{i} = patch(obj.hAx,obj.xChS{i}+xOfs,...
                        obj.yChS{i},obj.chColB{i},'FaceAlpha',obj.fAlpha,...
                        'EdgeColor',obj.chColB{i},'LineWidth',obj.lWid);                    
                    
                else
                    % case is creating a plot
                    xiS = [(1:length(obj.xChS{i})),1];
                    obj.hPlotB{i} = plot(obj.hAx,obj.xChS{i}(xiS)+xOfs,...
                        obj.yChS{i}(xiS),'Color',obj.chColB{i});
                end
            end
            
            % turns the axis hold off
            hold(obj.hAx,'off');
            
        end
        
        % --- sets the object visibility
        function setObjVisibility(obj,vState)
            
            obj.setStimObjVisibility(vState)
            
            if ~isempty(obj.hPlotB)
                cellfun(@(x)(set(x,'Visible',vState)),obj.hPlotB);
            end
            
        end        
        
    end
    
end