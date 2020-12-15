function NIvalue = DAQToNI(DAQvalue)
%DAQTONI Converts from DAQ enumerations to NI constants

%   Copyright 2010-2012 The MathWorks, Inc.

    switch DAQvalue
        
        % Shunt Resistor Location
        case  daq.ShuntLocation.Default
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_Default;
            
        case daq.ShuntLocation.Internal
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_Internal;
            
        case daq.ShuntLocation.External
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_External;
            
        % Trigger Conditions
        case daq.TriggerCondition.RisingEdge
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_Rising;
        case daq.TriggerCondition.FallingEdge
             NIvalue = daq.ni.NIDAQmx.DAQmx_Val_Falling;
                   
        
        % Input types
        case daq.InputType.Differential
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_Diff;

        case daq.InputType.SingleEnded
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_RSE;
        
        case daq.InputType.SingleEndedNonReferenced
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_NRSE;
        
        case daq.InputType.PseudoDifferential
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_PseudoDiff;  
        
        % TerminalConfig types
        case daq.TerminalConfig.Differential
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_Diff;

        case daq.TerminalConfig.SingleEnded
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_RSE;
        
        case daq.TerminalConfig.SingleEndedNonReferenced
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_NRSE;
        
        case daq.TerminalConfig.PseudoDifferential
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_PseudoDiff;

            
        % Coupling
        case daq.Coupling.AC
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_AC;
            
        case daq.Coupling.DC
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_DC;

        % Bridge Modes
        % Unknown is used to force user to set a value for the bridge mode.
        % It is mapped to half because we need to map to a legal value.
        case daq.BridgeMode.Unknown
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_QuarterBridge;
            
        case daq.BridgeMode.Full
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_FullBridge;
            
        case daq.BridgeMode.Half
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_HalfBridge;
            
        case daq.BridgeMode.Quarter
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_QuarterBridge;
            
        % Excitation sources
        % Unknown is used to force user to set a value for the excitation source.
        % It is mapped to Internal because we need to map to a legal value.
        case  daq.ExcitationSource.Unknown
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_Internal;
            
        case daq.ExcitationSource.Internal
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_Internal;
            
        case daq.ExcitationSource.External
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_External;
            
        case daq.ExcitationSource.None
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_None;
            

        % Temperature units
        case daq.TemperatureUnits.Celsius
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_DegC;

        case daq.TemperatureUnits.Fahrenheit
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_DegF;

        case daq.TemperatureUnits.Kelvin
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_Kelvins;

        case daq.TemperatureUnits.Rankine
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_DegR;

        % Thermocouple types
        % Unknown is used to force user to set a value for the thermocouple
        % type. It is mapped to J because we need to map to a legal value.
        case daq.ThermocoupleType.Unknown
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_J_Type_TC;

        case daq.ThermocoupleType.J
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_J_Type_TC;

        case daq.ThermocoupleType.K
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_K_Type_TC;

        case daq.ThermocoupleType.N
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_N_Type_TC;

        case daq.ThermocoupleType.R
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_R_Type_TC;

        case daq.ThermocoupleType.S
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_S_Type_TC;

        case daq.ThermocoupleType.T
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_T_Type_TC;

        case daq.ThermocoupleType.B
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_B_Type_TC;

        case daq.ThermocoupleType.E
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_E_Type_TC;

            
        % Digitizer Timing modes
        case daq.ni.ADCTimingMode.HighResolution
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_HighResolution;
            
        case daq.ni.ADCTimingMode.HighSpeed
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_HighSpeed;
            
        case daq.ni.ADCTimingMode.Best50HzRejection
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_Best50HzRejection;

        case daq.ni.ADCTimingMode.Best60HzRejection
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_Best60HzRejection;
            
        
        % ActiveEdge
        case daq.SignalEdge.Rising
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_Rising;
        case daq.SignalEdge.Falling
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_Falling;
        
        % CountDirection
        case daq.CountDirection.Increment
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_CountUp;
        case daq.CountDirection.Decrement
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_CountDown;
            
        % ActivePulse
        case daq.ActivePulse.High
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_Rising;
        case daq.ActivePulse.Low
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_Falling;
            
        % EncoderType
        case daq.EncoderType.X1
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_X1;
        case daq.EncoderType.X2
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_X2;
        case daq.EncoderType.X4
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_X4;
        case daq.EncoderType.TwoPulse
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_TwoPulseCounting;
            
        % ZResetCondition
        case daq.ZResetCondition.BothLow
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_ALowBLow;
        case daq.ZResetCondition.AHigh
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_AHighBLow;
        case daq.ZResetCondition.BHigh
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_ALowBHigh;
        case daq.ZResetCondition.BothHigh
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_AHighBHigh;
            
        % IdleState
        case daq.IdleState.High
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_High;
        case daq.IdleState.Low
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_Low;
            
        % RTDType
        case daq.RTDType.Pt3750
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_Pt3750;
        case daq.RTDType.Pt3851
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_Pt3851;
        case daq.RTDType.Pt3911
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_Pt3911;
        case daq.RTDType.Pt3916
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_Pt3916;
        case daq.RTDType.Pt3920
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_Pt3920;
        case daq.RTDType.Pt3928
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_Pt3928;
            
        % RTDConfiguration
        % Unknown is used to force user to set a value for the RTD Configuration.
        % It is mapped to 3Wire because we need to map to a legal value.
        case daq.RTDConfiguration.Unknown
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_3Wire;
        case daq.RTDConfiguration.TwoWire
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_2Wire;
        case daq.RTDConfiguration.ThreeWire
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_3Wire;
        case daq.RTDConfiguration.FourWire
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_4Wire;
            
        % ExcitationSource
        case daq.ExcitationSource.Internal
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_Internal;
        case daq.ExcitationSource.External
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_External;
        case daq.ExcitationSource.None
            NIvalue = daq.ni.NIDAQmx.DAQmx_Val_None;
        
        otherwise
            error(message('nidaq:ni:unknownConversion'));
    end
end

