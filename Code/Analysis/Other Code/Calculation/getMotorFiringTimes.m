function [Ts,Tf] = getMotorFiringTimes(stimP)

% determines if there is any motor firing information
if isempty(stimP)
    % if no stimuli information, then exit
    [Ts,Tf] = deal([]);
    return
elseif ~isfield(stimP,'Motor')
    % if no motor field, then exit
    [Ts,Tf] = deal([]);
    return    
end

% initiasiations
pMotor = stimP.Motor;

% determines what type of stimuli pattern was used for the motor device
if isfield(pMotor,'Ch')
    % case is all motors are the same
    [Ts,Tf] = deal(pMotor.Ch.Ts,pMotor.Ch.Tf);
else
    % determines the names of the channels that were used
    pFld = fieldnames(pMotor);
    [Ts,Tf] = deal(cell(length(pFld),1));
    
    % sets the start/finish times for each motor channel
    for i = 1:length(pFld)
        pFldS = getStructField(pMotor,pFld{i});
        [Ts{i},Tf{i}] = deal(pFldS.Ts,pFldS.Tf);
    end
end