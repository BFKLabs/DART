classdef (Hidden) USB4431 < daq.ni.DeviceInfo
    %USB4431 Device info for National Instruments DSA family.
    %
    %    This class represents DSA devices by
    %    National Instruments.
    %
    %    This undocumented class may be removed in a future release.
   
    % Copyright 2011 The MathWorks, Inc.

    % Specializations of the daq.DeviceInfo class should call addSubsystem
    % repeatedly to add a SubsystemInfo record to their device. usage:
    % addSubsystem(SUBSYSTEM) adds an adaptor specific SubsystemInfo record
    % SUBSYSTEM to the device.

    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods (Hidden)
        function obj = USB4431(vendor,device)
            % Call the superclass constructor
            obj@daq.ni.DeviceInfo(vendor, device);
        end
        
        function supportedRates = getOutputUpdateRatesFromDataSheet(obj) %#ok<MANU>
            % These rates are hard-coded from data-sheet because NI does not
            % provide a way to query these discrete rates.
            supportedRates = [ 800    , 1.25e3  , 1.5e3 , ...
                               1.6e3  ,  2.5e3  ,   3e3 , ...
                               3.2e3  ,    5e3  ,   6e3 , ...
                               6.4e3  ,   10e3  ,  12e3 , ...
                               12.8e3 ,   20e3  ,  24e3 , ...
                               25.6e3 ,   40e3  ,  48e3 , ...                         
                               51.2e3 ,   80e3  ,  96e3  ];          
        end
    end
end
