function supportedRanges = BridgeRange(varargin)
%BridgeRange Return bridge range of an bridge channel
%   BridgeRange(model) Returns all supported ranges for a particular model
%   as daq.Range object arrays representing the effective range in 
%   VoltsPerVolt units

%    BridgeRange(model,bridgeConfig,excitationVoltage) Returns a supported 
%    range for a particular model, brideConfig and excitation voltage
%    as daq.Range object representing the effective range in VoltsPerVolt units

% Copyright 2011-2012 The MathWorks, Inc.

if( nargin > 1)
    % Return supported range based on bridgeConfig and excitation voltage
    model               = varargin{1};
    bridgeConfig        = varargin{2};
    excitationVoltage   = varargin{3};
    
    switch model
        case {'NI 4331','NI 4330'}
            if( excitationVoltage >= 2.75 )
                supportedRanges = daq.Range(-0.100,.100,'VoltsPerVolt');
            elseif ( excitationVoltage <= 2.5 )
                supportedRanges = daq.Range(-0.100,.100,'VoltsPerVolt');
            else
                supportedRanges = daq.Range(-0.025,.025,'VoltsPerVolt');
            end
        case {'NI 9235','NI 9236'}
            supportedRanges = daq.Range(-0.0294,0.0294,'VoltsPerVolt');
        case 'NI 9237'
            supportedRanges = daq.Range(-0.025,.025,'VoltsPerVolt');
        case 'NI 9219'
            switch bridgeConfig
                case 'Quarter'
                    supportedRanges = daq.Range(-0.025,0.025,'VoltsPerVolt');
                case 'Half'
                    supportedRanges = daq.Range(-0.500,0.500,'VoltsPerVolt');
                case 'Full'
                    supportedRanges = daq.Range(-0.0625,0.0625,'VoltsPerVolt');
            end
        otherwise
            supportedRanges = daq.Range(-0.025,.025,'VoltsPerVolt');
    end
    
else
    % Return all supported ranges for a specific device
    model  = varargin{1};
    
    switch model
        case {'NI 4331','NI 4330'}
            supportedRanges = [ daq.Range(-0.025,.025,'VoltsPerVolt'),...
                daq.Range(-0.100,.100,'VoltsPerVolt')];
        case {'NI 9235','NI 9236'}
            supportedRanges = daq.Range(-0.0294,0.0294,'VoltsPerVolt');
        case 'NI 9237'
            supportedRanges = daq.Range(-0.025,.025,'VoltsPerVolt');
        case 'NI 9219'
            supportedRanges = [ daq.Range(-0.0078,0.0078,'VoltsPerVolt'),...
                daq.Range(-0.500,0.500,'VoltsPerVolt'),...
                daq.Range(-0.0625,0.625,'VoltsPerVolt')];
        otherwise
            supportedRanges = daq.Range(-0.025,.025,'VoltsPerVolt');
    end
end
end