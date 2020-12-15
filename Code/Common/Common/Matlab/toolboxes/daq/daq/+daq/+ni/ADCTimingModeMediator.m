classdef (Hidden) ADCTimingModeMediator < daq.internal.ChannelMediator
    %ADCTimingModeMediator Coordinates ADCTimingMode across a device
    % A channel can register and use a mediator object to define complex
    % interactions between channels, without knowing how many channels are
    % involved.
    %
    % In this case, we synchronize the ADCTimingMode property across a
    % device, as all channels on the device are required to operate
    % together.
    
    % Copyright 2010 The MathWorks, Inc.
    % $Revision: 1.1.12.1 $  $Date: 2014/02/11 04:16:44 $
    
    %% -- Constructor --
    methods
        function obj = ADCTimingModeMediator(ADCTimingModeDefault)
            % The default is HighSpeed
            obj.ADCTimingModeInfo = ADCTimingModeDefault;
        end
    end
    
    %% -- Public methods, properties, and events --
    % Read/write properties
    properties(SetObservable)
        ADCTimingModeInfo
    end
end