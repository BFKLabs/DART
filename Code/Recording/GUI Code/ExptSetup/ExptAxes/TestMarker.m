classdef TestMarker < handle & dynamicprops
    
    % class properties
    properties
        
        % main class fields
        hTimer
        hPlotM
        sTrain
        
        % fixed numerical class fields
        lWid = 2;
        tPer = 0.1;
        
        % fixed string fields
        tagStr = 'hTestTimer';
        plotTag = 'hTestMarker';
        
    end
    
    % private class properties
    properties (Access = protected)
        
        objB
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = TestMarker(objB)
            
            % input arguments
            obj.objB = objB;
            
            % initialises the class fields/objects
            obj.linkParentProps();
            obj.initClassFields();
            obj.initClassObjects();            
            
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class object fields with that parent object
        function linkParentProps(obj)
            
            % parent fields strings
            fldStr = {'hFig','hAx','tDurTot','hButTT'};
            
            % connects the base/child objects
            for propname = fldStr
                metaprop = addprop(obj, propname{1});
                metaprop.SetMethod = @(obj, varargin) ...
                    SetDispatch(obj, propname{1}, varargin{:});
                metaprop.GetMethod = @(obj)GetDispatch(obj, propname{1});
            end
            
        end            
        
        % --- initialises the class fields
        function initClassFields(obj)            
            
            % deletes any previous stimuli markers
            hTimerOld = timerfindall('tag',obj.tagStr);
            if ~isempty(hTimerOld) 
                deleteTimerObjects(hTimerOld)
            end            
            
        end
        
        % --- initialises the class objects
        function initClassObjects(obj)
            
            % creates the plot marker
            hold(obj.hAx,'on');
            obj.hPlotM = plot(obj.hAx,NaN(1,2),obj.hAx.YLim,'r',...
                'LineWidth',obj.lWid,'tag',obj.plotTag,'Visible','off');
            hold(obj.hAx,'off');            
            
            % creates the timer object
            obj.hTimer = timer('ExecutionMode','fixedRate',...
                'BusyMode','drop','Period',obj.tPer,...
                'TasksToExecute',obj.calcTaskCount(),...
                'StartFcn',@obj.startTest,'StartDelay',0.01,...
                'TimerFcn',@obj.timerTest,'Tag',obj.tagStr,...
                'StopFcn',@obj.stopTest);
            
        end        
        
        % ----------------------------- %
        % --- TIMER EVENT FUNCTIONS --- %
        % ----------------------------- %
        
        % --- start test callback function
        function startTest(obj,varargin)
            
            % sets the main window properties            
            setObjVisibility(obj.hPlotM,'on')
            
        end
        
        % --- task timer callback function
        function timerTest(obj,varargin)
            
            % determines if the toggle button has be clicked again
            if startsWith(obj.hButTT.String,'Test')
                % if so, stop the timer object
                stop(obj.hTimer)
                pause(0.05)
                
            else
                % otherwise, update the location of the signal test line
                xData = get(obj.hTimer,'TasksExecuted')*obj.tPer;
                set(obj.hPlotM,'xData',xData*[1,1])
            end
            
        end
        
        % --- stop timer callback function
        function stopTest(obj,varargin)
            
            % sets the main window properties
            setObjVisibility(obj.hPlotM,'off') 
            set(obj.hButTT,'Value',0,'String','Test Stimuli Train');
            set(obj.hPlotM,'xData',NaN(1,2))            
            
        end    
        
        % --- starts the stimuli test marker
        function startTimer(obj)
            
            start(obj.hTimer);
            
        end
        
        % --- resets the test stimuli marker properties
        function resetTimerProps(obj)
            
            % global variables
            global timerTest
            
            % resets the timer properties
            obj.hTimer.TasksToExecute = obj.calcTaskCount();
            
            % sets the global variable flag (remove me in future?)
            timerTest = obj.hTimer;
            
        end
        
        % --- calculates the timer task count
        function nCount = calcTaskCount(obj)
            
            nCount = (obj.tDurTot/obj.tPer);
            
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