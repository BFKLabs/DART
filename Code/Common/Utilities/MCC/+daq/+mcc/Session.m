 classdef (Hidden) Session < daq.sdk.Session
    %daq.mcc.Session Session object for DAQ MCCAdaptor
    %    Measurement computing devices are accessed using this session.
    
    % Copyright 2016 The MathWorks, Inc.
    
    
    %% Constructor / Destructor
    methods(Hidden)
        % Constructor
        function obj = Session(vendor)
            % TODO: Provide initial rate?
            initialRate = 1000;
            standardSampleRates = [];
            obj@daq.sdk.Session(vendor, initialRate, standardSampleRates);
        end
    end
end
