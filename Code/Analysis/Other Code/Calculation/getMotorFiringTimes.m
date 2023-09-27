function [Ts,Tf] = getMotorFiringTimes(stimP,devType,chType)

% sets the default input arguments (if not provided)
if nargin == 1
    [devType,chType] = deal([]);
end

% determines if there is any motor firing information
if isempty(stimP)
    % if no stimuli information, then exit
    [Ts,Tf] = deal([]);
    return
else
    % determines which are the matching motor device fields
    sFld = fieldnames(stimP);
    if isempty(devType)    
        % if no device type is provided, then determines the motor fields        
        isMotor = strContains(sFld,'Motor');
    else
        % otherwise, determine the exact field
        isMotor = strcmp(sFld,devType);
    end
    
    % if no matches exist, then exit the function
    if ~any(isMotor)
        [Ts,Tf] = deal([]);
        return  
    end
end

% reduces down the data struct 
if sum(isMotor) > 1
    % case is there is more than one device type, so choose the first
    %   => look at if this needs to be addressed (what about the others?)
    sFldM = sFld(isMotor);
    pMotor = getStructField(stimP,sFldM{1});
else
    % case is there is a unique device type
    pMotor = getStructField(stimP,sFld{isMotor});
end

% retrieves the stimuli start/finish times based on the 
if isempty(chType)
    % determines what type of stimuli pattern was used for the motor device
    if isfield(pMotor,'Ch')
        % case is all motors are the same
        [Ts,Tf] = deal(pMotor.Ch.Ts,pMotor.Ch.Tf);
        
        % removes any duplicate entries
        [Ts,iA,~] = unique(Ts,'stable');
        Tf = Tf(iA);        
    elseif isfield(pMotor,'Ch1')
        % case is all motors are the same
        [Ts,Tf] = deal(pMotor.Ch1.Ts,pMotor.Ch1.Tf);
        
        % removes any duplicate entries
        [Ts,iA,~] = unique(Ts,'stable');
        Tf = Tf(iA);        
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
else
    % determines if the channel type exists for the current device
    if isfield(pMotor,chType)
        % if so, retrieve the start/finish stimuli times
        pMotorC = getStructField(pMotor,chType);
        [Ts,Tf] = deal(pMotorC.Ts,pMotorC.Tf);
        
        % removes any duplicate entries
        [Ts,iA,~] = unique(Ts,'stable');
        Tf = Tf(iA);        
    else
        % otherwise, return empty arrays
        [Ts,Tf] = deal([]);        
    end    
end