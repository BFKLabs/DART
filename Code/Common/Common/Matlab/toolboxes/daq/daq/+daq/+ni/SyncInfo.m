classdef SyncInfo 
    %SyncInfo Clocking and Trigger information for channel groups
    
    %   This class contains all the properties required for clocking
    %   and trigger configuration required for a Channel Group
    %
    %   Copyright 2011 The MathWorks, Inc.

    properties ( SetAccess = public )
        % StartTrigger A string specifying the start trigger to be used by
        % the channel group.
        StartTrigger
        
        % StartTriggerCondition A string specifying the start trigger
        % condition to used by the channel group
        StartTriggerCondition
        
        % ExportedStartedTrigger A A string specifying the terminal to which
        % the start trigger being used by the channel group is exported .
        ExportedStartTrigger
        
        % ScanClock A string specifying the scan clock to be used by the
        % channel group
        ScanClock
        
        % ExportedScanClock A string specifying the terminal to which the
        % scan clock being used by the channel group is exported .
        ExportedScanClock
        
    end
    
    methods ( Access = public, Hidden )
        % Hidden Constructor
        function obj = SyncInfo
            
            %Set all properties to default value.
            obj.StartTrigger = daq.SyncManager.Default;
            obj.StartTriggerCondition = daq.TriggerCondition.RisingEdge;
            obj.ExportedStartTrigger = daq.SyncManager.Default;            
            obj.ScanClock = daq.SyncManager.Default;
            obj.ExportedScanClock = daq.SyncManager.Default;
        end
    end
    
     %% Superclass methods this class implements
    methods (Hidden,  Access = protected)
        function resetImpl(obj)
            %resetImpl Handle daq.reset (which is usually delete)
            if isvalid(obj)
                delete(obj)
            end
        end
    end
end

