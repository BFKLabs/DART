function result = RTDRange( RTDType, units ) %#ok<INUSL>
%RTDRange Return temperature range of an RTD
%   RTDRange( RTDTYPE, UNITS) Returns a
%   daq.Range object representing the effective range in temperature units
%   of an RTD type daq.ni.RTDType in UNITS (physical units such as F or C) 
%

% Copyright 2010-2012 The MathWorks, Inc.

    minDegC = -200;
    maxDegC = 660;

    result = daq.Range(convertScale(minDegC,units),...
                       convertScale(maxDegC,units),...
                       char(units));
        
    function result = convertScale(degC,units)
        
        switch units
            case daq.TemperatureUnits.Celsius
                % No action required
                result = degC;
            case daq.TemperatureUnits.Kelvin
                % Convert Celsius to Kelvin
                result = degC + 273;
            case daq.TemperatureUnits.Fahrenheit
                % Convert Celsius to Fahrenheit
                result = degC * 1.8 + 32;
            case daq.TemperatureUnits.Rankine
                % Convert Celsius to Fahrenheit
                result = degC * 1.8 + 32;
                % Convert Fahrenheit to Rankine
                result = result + 459.67;
        end
    end
end

