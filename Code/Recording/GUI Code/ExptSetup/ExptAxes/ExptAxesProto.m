classdef ExptAxesProto < ExptAxes
    
    % class properties
    properties
        
        
        
    end
        
    % class methods
    methods
        
        % --- class constructor
        function obj = ExptAxesProto(objB)
            
            % creates the super-class object
            obj@ExptAxes(objB,'Proto');
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initClassObjects();
            
            
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %        
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % ------------------------------------------- %
            % --- CLASS OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------------- %
            

            
        end
        
        % --- initialises the class objects
        function initClassObjects(obj)
            
            
            
        end
        
        % --- resets the axis duration
        function resetTotalDuration(obj)
            
            % sets the x/y axis limits & x-axis tick marks
            Timing = obj.iExpt.Timing;
            tDurEx = vec2time(Timing.Texp,Timing.TexpU);            
            
            % resets the plot end-marker location
            set(obj.hPltF,'XData',tDurEx*[1,1]);            
            
            % resets the right draw-distance end-point
            dlPos = obj.objSM.objDL.hDL{2}.getPosition();
            dlPos(2,1) = tDurEx;
            obj.objSM.objDL.hDL{2}.setPosition(dlPos(:,1),dlPos(:,2))
            
            % calculates the x-axis limits
            set(obj.hAx,'XLim',obj.calcAxisLimits(tDurEx,'x'));             
                                    
            % updates the channel positions
            obj.resetAxesTimeProps();
            obj.objSM.updateChannelPosition();
            obj.objSM.resetEndBlockObjLimits()
            
            % resets the signal block time values
            sBlk = obj.objT{4}.objSM.sBlk;
            for i = 1:length(sBlk)
                if ~strcmpi(sBlk{i}.tDurTotU(1),Timing.TexpU(1))
                    sBlk{i}.resetBlockTimeUnits(Timing.TexpU);
                end
            end
            
            % resets the figure zoom
            zoom(obj.hFig,'reset');
            
        end 
        
        % --- resets the time axes properties
        function resetAxesTimeProps(obj)
            
            % field retrieval
            Timing = obj.iExpt.Timing;
            tUnits = Timing.TexpU;
            
            % other object retrieval
            xTicks = get(obj.hAx,'xTick');            
            hXLabel = findall(obj.hAx,'tag','xLabel');                        
            
            % sets the x-label/x-axis label strings
            if Timing.fixedT0
                % case is using fixed start time
                xLblStr = 'Time';
                xTickLbl = obj.getFixedTimeLabels(Timing.T0,xTicks,tUnits);
            else
                % case is using non-fixed start time
                xLblStr = sprintf('Time (%s)',tUnits);
                xTickLbl = arrayfun(@num2str,xTicks(:),'un',0);
            end                       
            
            % updates the plot axes properties
            set(obj.hAx,'XTickLabel',xTickLbl);
            set(hXLabel,'String',xLblStr);
            
        end
        
    end
    
    % static class methods
    methods (Static)
        
        % --- sets up the time labels for fixed start experiments
        function xLbl = getFixedTimeLabels(tStart,xTicks,tUnits)
            
            % initialisations
            tUnits = tUnits(1:end-1);
            tStart0 = datenum(tStart);
            
            % determines if the x-tick values are integers
            if any(mod(xTicks,1) > 1e-6)
                % if not, then scale the locations until they are integers
                tMlt = [24,60,60];
                tUnitStr = {'Day','Hour','Minute','Second'};
                i0 = find(strcmp(tUnitStr,tUnits));
                
                % keep using multipliers until all locations are integers
                for i = i0:length(tMlt)
                    % multiplies the x-tick locations by the multiplier
                    xTicks = xTicks*tMlt(i);
                    if ~any(mod(xTicks,1) > 1e-6)
                        % if all the values are integers, then exit loop
                        break
                    end
                end
                
                % sets the final tick/string values
                xTicks = roundP(xTicks);
                tUnits = tUnitStr{i+1};
            end
            
            % sets label strings based on start time and x-tick locations
            xLbl = cell(length(xTicks),1);
            for i = 1:length(xLbl)
                xLbl{i} = datestr(...
                    addtodate(tStart0,xTicks(i),tUnits),'HH:MM AM');
            end
            
        end
        
    end
    
end