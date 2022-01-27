function stimP = reduceExptStimInfo(stimP,tLimV)

% initialisations
fStrD = fieldnames(stimP);

% reduces the stimuli information for the time limit, tLimV
for i = 1:length(fStrD)
    % retrieves the stimuli information for the current device
    stimPD = getStructField(stimP,fStrD{i});

    % retrieves the stimuli information for each channel
    fStrC = fieldnames(stimPD);
    stimPC = cellfun(@(x)(getStructField(stimPD,x)),fStrC,'un',0);

    % for each channel, determine which stimuli events intersect with
    % the current video
    for j = 1:length(stimPC)            
        if isempty(stimPC{j}.Ts)
            % if there are no stimuli event for the device, then remove it
            stimPD = rmfield(stimPD,fStrC{j});            
        else
            % determines which stimuli events occur within the video
            if exist('tLimV','var')
                % determines which stimuli events occur within the 
                % span of the time vector
                [Ts,Tf] = deal(stimPC{j}.Ts,stimPC{j}.Tf);
                isIn = (Ts<=tLimV(2)) & (Tf>=tLimV(1));                

                % removes the stimuli events not within the video
                stimPC{j}.Ts = stimPC{j}.Ts(isIn) - tLimV(1);
                stimPC{j}.Tf = stimPC{j}.Tf(isIn) - tLimV(1);
                stimPC{j}.iStim = stimPC{j}.iStim(isIn);
            end
            
            % resets the channel information into the device struct
            stimPD = setStructField(stimPD,fStrC{j},stimPC{j});             
        end               
    end

    % resets the device data into the entire data struct
    stimP = setStructField(stimP,fStrD{i},stimPD);
end
