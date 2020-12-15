function DAQvalue = NIToDAQ(NIvalue)
%NIToDAQ Converts from NI constants to DAQ enumerations

%   Copyright 2010-2012 The MathWorks, Inc.


switch NIvalue
    % TerminalConfig types
    case daq.ni.NIDAQmx.DAQmx_Val_Diff
        DAQvalue = daq.TerminalConfig.Differential;
        
    case daq.ni.NIDAQmx.DAQmx_Val_RSE
        DAQvalue = daq.TerminalConfig.SingleEnded;
        
    case daq.ni.NIDAQmx.DAQmx_Val_NRSE
        DAQvalue = daq.TerminalConfig.SingleEndedNonReferenced;
        
    case daq.ni.NIDAQmx.DAQmx_Val_PseudoDiff
        DAQvalue = daq.TerminalConfig.PseudoDifferential;
        
        
        % Coupling
    case daq.ni.NIDAQmx.DAQmx_Val_AC
        DAQvalue = daq.Coupling.AC;
        
    case daq.ni.NIDAQmx.DAQmx_Val_DC
        DAQvalue = daq.Coupling.DC;
        
        % Bridge Modes
    case daq.ni.NIDAQmx.DAQmx_Val_FullBridge
        DAQvalue = daq.BridgeMode.Full;
        
    case daq.ni.NIDAQmx.DAQmx_Val_HalfBridge
        DAQvalue = daq.BridgeMode.Half;
        
    case daq.ni.NIDAQmx.DAQmx_Val_QuarterBridge
        DAQvalue = daq.BridgeMode.Quarter;
        
        % Excitation sources
    case daq.ni.NIDAQmx.DAQmx_Val_Internal
        DAQvalue = daq.ExcitationSource.Internal;
        
    case daq.ni.NIDAQmx.DAQmx_Val_External
        DAQvalue = daq.ExcitationSource.External;
        
    case daq.ni.NIDAQmx.DAQmx_Val_None
        DAQvalue = daq.ExcitationSource.None;
        
        % Temperature units
    case daq.ni.NIDAQmx.DAQmx_Val_DegC
        DAQvalue = daq.TemperatureUnits.Celsius;
        
    case daq.ni.NIDAQmx.DAQmx_Val_DegF
        DAQvalue = daq.TemperatureUnits.Fahrenheit;
        
    case daq.ni.NIDAQmx.DAQmx_Val_Kelvins
        DAQvalue = daq.TemperatureUnits.Kelvin;
        
    case daq.ni.NIDAQmx.DAQmx_Val_DegR
        DAQvalue = daq.TemperatureUnits.Rankine;
        
        % Thermocouple types
    case daq.ni.NIDAQmx.DAQmx_Val_J_Type_TC
        DAQvalue = daq.ThermocoupleType.J;
        
    case daq.ni.NIDAQmx.DAQmx_Val_K_Type_TC
        DAQvalue = daq.ThermocoupleType.K;
        
    case daq.ni.NIDAQmx.DAQmx_Val_N_Type_TC
        DAQvalue = daq.ThermocoupleType.N;
        
    case daq.ni.NIDAQmx.DAQmx_Val_R_Type_TC
        DAQvalue = daq.ThermocoupleType.R;
        
    case daq.ni.NIDAQmx.DAQmx_Val_S_Type_TC
        DAQvalue = daq.ThermocoupleType.S;
        
    case daq.ni.NIDAQmx.DAQmx_Val_T_Type_TC
        DAQvalue = daq.ThermocoupleType.T;
        
    case daq.ni.NIDAQmx.DAQmx_Val_B_Type_TC
        DAQvalue = daq.ThermocoupleType.B;
        
    case daq.ni.NIDAQmx.DAQmx_Val_E_Type_TC
        DAQvalue = daq.ThermocoupleType.E;
        
        % Digitizer Timing modes
    case daq.ni.NIDAQmx.DAQmx_Val_HighResolution
        DAQvalue = daq.ni.ADCTimingMode.HighResolution;
        
    case daq.ni.NIDAQmx.DAQmx_Val_HighSpeed
        DAQvalue = daq.ni.ADCTimingMode.HighSpeed;
        
    case daq.ni.NIDAQmx.DAQmx_Val_Best50HzRejection
        DAQvalue = daq.ni.ADCTimingMode.Best50HzRejection;
        
    case daq.ni.NIDAQmx.DAQmx_Val_Best60HzRejection
        DAQvalue = daq.ni.ADCTimingMode.Best60HzRejection;
        
        % ActiveEdge
    case daq.ni.NIDAQmx.DAQmx_Val_Rising
        DAQvalue = daq.SignalEdge.Rising;
    case daq.ni.NIDAQmx.DAQmx_Val_Falling
        DAQvalue = daq.SignalEdge.Falling;
        
        % CountDirection
    case daq.ni.NIDAQmx.DAQmx_Val_CountUp
        DAQvalue = daq.CountDirection.Increment;
    case daq.ni.NIDAQmx.DAQmx_Val_CountDown
        DAQvalue = daq.CountDirection.Decrement;
        
        % EncoderType
    case daq.ni.NIDAQmx.DAQmx_Val_X1
        DAQvalue = daq.EncoderType.X1;
    case daq.ni.NIDAQmx.DAQmx_Val_X2
        DAQvalue = daq.EncoderType.X2;
    case daq.ni.NIDAQmx.DAQmx_Val_X4
        DAQvalue = daq.EncoderType.X4;
    case daq.ni.NIDAQmx.DAQmx_Val_TwoPulseCounting
        DAQvalue = daq.EncoderType.TwoPulse;
        
        % ZResetCondition
    case daq.ni.NIDAQmx.DAQmx_Val_ALowBLow
        DAQvalue = daq.ZResetCondition.BothLow;
    case daq.ni.NIDAQmx.DAQmx_Val_AHighBLow
        DAQvalue = daq.ZResetCondition.AHigh;
    case daq.ni.NIDAQmx.DAQmx_Val_ALowBHigh
        DAQvalue = daq.ZResetCondition.BHigh;
    case daq.ni.NIDAQmx.DAQmx_Val_AHighBHigh
        DAQvalue = daq.ZResetCondition.BothHigh;
        
        % IdleState
    case daq.ni.NIDAQmx.DAQmx_Val_High
        DAQvalue = daq.IdleState.High;
    case daq.ni.NIDAQmx.DAQmx_Val_Low
        DAQvalue = daq.IdleState.Low;
        
        % RTDType
    case daq.ni.NIDAQmx.DAQmx_Val_Pt3750
        DAQvalue = daq.RTDType.Pt3750;
    case daq.ni.NIDAQmx.DAQmx_Val_Pt3851
        DAQvalue = daq.RTDType.Pt3851;
    case daq.ni.NIDAQmx.DAQmx_Val_Pt3911
        DAQvalue = daq.RTDType.Pt3911;
    case daq.ni.NIDAQmx.DAQmx_Val_Pt3916
        DAQvalue = daq.RTDType.Pt3916;
    case daq.ni.NIDAQmx.DAQmx_Val_Pt3920
        DAQvalue = daq.RTDType.Pt3920;
    case daq.ni.NIDAQmx.DAQmx_Val_Pt3928
        DAQvalue = daq.RTDType.Pt3928;
        
        % RTDConfiguration
    case daq.ni.NIDAQmx.DAQmx_Val_2Wire
        DAQvalue = daq.RTDConfiguration.TwoWire;
    case daq.ni.NIDAQmx.DAQmx_Val_3Wire
        DAQvalue = daq.RTDConfiguration.ThreeWire;
    case daq.ni.NIDAQmx.DAQmx_Val_4Wire
        DAQvalue = daq.RTDConfiguration.FourWire;
        
        % ExcitationSource
    case daq.ni.NIDAQmx.DAQmx_Val_Internal
        DAQvalue = daq.ExcitationSource.Internal;
    case daq.ni.NIDAQmx.DAQmx_Val_External
        DAQvalue = daq.ExcitationSource.External;
    case daq.ni.NIDAQmx.DAQmx_Val_None
        DAQvalue = daq.ExcitationSource.None;
        
    otherwise
        error(message('nidaq:ni:unknownConversion'));
end
end

