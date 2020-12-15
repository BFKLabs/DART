function result = thermocoupleRange( thermocoupleType, units )
%THERMOCOUPLERANGE Return temperature range of a thermocouple
%   thermocoupleRange( THERMOCOUPLETYPE, UNITS) Returns a
%   daq.Range object representing the effective range in temperature units
%   of a thermocouple THERMOCOUPLETYPE of type daq.ThermocoupleType in
%   UNITS (physical units such as F or C) 
%
%   Reference: Omega Revised Thermocouple Reference Tables,
%   http://www.omega.com/temperature/Z/zsection.asp

% Copyright 2010-2012 The MathWorks, Inc.

        switch(thermocoupleType)
            case {daq.ThermocoupleType.Unknown,...
                  daq.ThermocoupleType.J}
              % Unknown is defined as J for this purpose
                minDegC = 0;
                maxDegC = 750;
            case daq.ThermocoupleType.K
                minDegC = -199.5;
                maxDegC = 1250;
            case daq.ThermocoupleType.N
                minDegC = -199.5;
                maxDegC = 1300;
            case {daq.ThermocoupleType.R,...
                  daq.ThermocoupleType.S}
                minDegC = 0;
                maxDegC = 1450;
            case daq.ThermocoupleType.T
                minDegC = -199.5;
                maxDegC = 350;
            case daq.ThermocoupleType.B
                minDegC = 250.5;
                maxDegC = 1700;
            case daq.ThermocoupleType.E
                minDegC = -199.5;
                maxDegC = 900;
        end

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

