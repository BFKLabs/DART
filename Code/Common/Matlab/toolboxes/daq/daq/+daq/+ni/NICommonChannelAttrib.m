classdef (Hidden) NICommonChannelAttrib < handle
    %TemplateClass Example class structure
    %    TemplateClass Put your detailed info here
    
    % Copyright 2010-2012 The MathWorks, Inc.
    
    %% -- Constructor --
    methods
    end
    
    %% -- Public methods, properties, and events --
    % Read/write properties
    properties
    end
    
    % Read only properties
    properties (SetAccess = private)
    end
    
    % Read only properties that can be altered by a subclass
    properties (SetAccess = protected)
    end
    
    % Constants
    properties(Constant, GetAccess = private)
    end
    
    % Methods
    methods
    end
    
    % Sealed methods
    methods(Sealed)
    end
    
    % Events
    events
    end
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods(Hidden)
    end
    
    % Destructor
    methods
    end
    % Hidden properties
    properties (Hidden)
        PhysicalChannel
        
        % The group name associated with this channel.
        GroupName
        
        % Channel groups describe related channels that belong together
        % in a task.  They are self-organizing, with names generally of
        % the form <subsystem>/<deviceid>, but related devices may
        % choose another mechanism.  For instance, CompactDAQ uses
        % <subsystem>/<chassisID>.
        
    end
    
    % Property accessor methods
    methods      
        function value = get.GroupName(obj)           
            value = obj.getGroupNameHook();
        end
        
    end
    
    % Hidden read only properties
    properties(Hidden,SetAccess = private)
    end
    
    % Hidden methods, which are typically used as friend methods
    methods(Hidden)
    end
    
    % Hidden public sealed methods, which are typically used as friend methods
    methods (Sealed, Hidden)
    end
    
    % Hidden static methods, which are typically used as friend methods
    methods(Hidden,Static)
    end
    
    % Protected read only properties for use by a subclass
    properties(GetAccess=protected,SetAccess=private)
    end
    
    % Protected constants for use by a subclass
    properties(GetAccess=protected,Constant)
    end
    
    % Protected methods requiring implementation by a subclass
    methods (Abstract,Access = protected)
    end
    
    % Protected template methods with optional implementation by a subclass
    methods (Abstract,Access = protected)
        getGroupNameHook(obj);        
    end
    
    % Protected methods for use by a subclass
    methods (Sealed, Access = protected)
        function standardAIPropertyConfiguration(obj,taskHandle,propertyName,newValue)
            switch propertyName
                case 'CouplingInfo'
                    [status] = daq.ni.NIDAQmx.DAQmxSetAICoupling(...
                        taskHandle,...
                        obj.PhysicalChannel,...
                        daq.ni.utility.DAQToNI(newValue));
                    daq.ni.utility.throwOrWarnOnStatus(status);

                    % If the property is not supported we will get an
                    % error on read
                    [status,readValue] = daq.ni.NIDAQmx.DAQmxGetAICoupling(...
                        taskHandle,...
                        obj.PhysicalChannel,...
                        int32(0));
                    % Revert to the last good value
                    if(readValue ~= daq.ni.utility.DAQToNI(newValue))
                        [~] = daq.ni.NIDAQmx.DAQmxSetAICoupling(...
                            taskHandle,...
                            obj.PhysicalChannel,...
                            daq.ni.utility.DAQToNI(obj.CouplingInfo));
                    end
                    daq.ni.utility.throwOrWarnOnStatus(status);                        
                case 'TerminalConfigInfo'

                    [status] = daq.ni.NIDAQmx.DAQmxSetAITermCfg(...
                        taskHandle,...
                        obj.PhysicalChannel,...
                        daq.ni.utility.DAQToNI(newValue));
                    daq.ni.utility.throwOrWarnOnStatus(status);                
                case 'Range'
                    [status] = daq.ni.NIDAQmx.DAQmxSetAIMin(...
                        taskHandle,...          % taskHandle
                        obj.PhysicalChannel,...    % channel
                        newValue.Min);          % data
                    daq.ni.utility.throwOrWarnOnStatus(status);
                    
                    [status] = daq.ni.NIDAQmx.DAQmxSetAIMax(...
                        taskHandle,...          % taskHandle
                        obj.PhysicalChannel,...    % channel
                        newValue.Max);          % data
                    daq.ni.utility.throwOrWarnOnStatus(status);                   

            end
        end
        
        function standardAOPropertyConfiguration(obj,taskHandle,propertyName,newValue)
            switch propertyName
                case 'Range'
                    [status] = daq.ni.NIDAQmx.DAQmxSetAOMax(...
                        taskHandle,...          % taskHandle
                        obj.PhysicalChannel,...    % channel
                        newValue.Max);          % data
                    daq.ni.utility.throwOrWarnOnStatus(status);
                    
                    [status] = daq.ni.NIDAQmx.DAQmxSetAOMin(...
                        taskHandle,...          % taskHandle
                        obj.PhysicalChannel,...    % channel
                        newValue.Min);          % data
                    daq.ni.utility.throwOrWarnOnStatus(status);
                case 'TerminalConfigInfo'
                    [status] = daq.ni.NIDAQmx.DAQmxSetAOTermCfg(...
                        taskHandle,...
                        obj.PhysicalChannel,...
                        daq.ni.utility.DAQToNI(newValue));
                    daq.ni.utility.throwOrWarnOnStatus(status);
            end
        end
    end
    
    methods (Hidden)
        function onTaskRecreationHook(obj,taskHandle) %#ok<INUSD>
            % Do nothing by default. This method can be overridden by the channels if they need to react to task recreation.
        end
    end
    % Protected static methods for use by a subclass
    methods (Sealed,Static,Access=protected)
    end
    
    % Private properties
    properties (GetAccess = private,SetAccess = private)
    end
    
    % Internal constants
    properties(Constant, GetAccess = private)
    end
    
    % Superclass methods this class implements
    methods (Sealed, Access = protected)
    end
    
    % Private methods
    methods (Access = private)
    end    
end
