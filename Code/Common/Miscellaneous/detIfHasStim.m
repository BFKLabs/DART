function hasStim = detIfHasStim(stimP)

% initialisations
hasStim = false;

% if there are potential stimuli info, then check if these are empty
if ~isempty(stimP)
    % checks each device to determine if there is any stimuli info
    fStrD = fieldnames(stimP);
    for i = 1:length(fStrD)
        % retrieves the device information
        stimPD = getStructField(stimP,fStrD{i});
        
        % retrieves the information for each channel
        fStrC = fieldnames(stimPD);
        stimPC = cellfun(@(x)(getStructField(stimPD,x)),fStrC,'un',0);
        
        % determines if any channels has a stimuli event
        hasStim = hasStim || any(cellfun(@(x)(~isempty(x.Ts)),stimPC));
    end
end