classdef ExptAxesStim < ExptAxes
    
    % class properties
    properties
        
        
        
    end    
    
    % class methods
    methods
        
        % --- class constructor
        function obj = ExptAxesStim(objB)
            
            % creates the super-class object
            obj@ExptAxes(objB,'Stim');
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initClassObjects();            
            
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
                
        % --- initialises the class fields
        function initClassFields(obj)
            
            
            
        end
        
        % --- initialises the class objects
        function initClassObjects(obj)
            
            
            
        end 
        
        % --- resets the axis duration
        function resetTotalDuration(obj)
            
            % resets the plot end-marker location
            set(obj.hPltF,'XData',obj.tDurTot*[1,1]);
            set(obj.hLblX,'String',sprintf('Time (%s)',obj.tDurTotU));
            
            % calculates the x-axis limits
            set(obj.hAx,'XLim',obj.calcAxisLimits(obj.tDurTot,'x'));
            xTickLbl = arrayfun(@num2str,get(obj.hAx,'xtick'),'un',0);
            set(obj.hAx,'xticklabels',xTickLbl)
            
            % resets the right draw-distance end-point
            dlPos = obj.objSM.objDL.hDL{2}.getPosition();
            dlPos(2,1) = obj.tDurTot;
            obj.objSM.objDL.hDL{2}.setPosition(dlPos(:,1),dlPos(:,2))
            
            % updates the channel positions
            obj.objSM.updateChannelPosition();
            obj.objSM.resetEndTrainObjLimits()
            
            % resets the figure zoom
            zoom(obj.hFig,'reset');
            
        end        
        
    end
    
end