% --- determines if 2 stimuli protocol structs are equal
function isEq = compareStimProto(stimP1,stimP2)

% initialisations and parameters
isEq = false;
dtTol = 60;

% if either protocol is empty, then exit
if isempty(stimP1) || isempty(stimP2)
    return
end

% retrieves the device types from each stimuli protocol
[dType1,dType2] = deal(fieldnames(stimP1),fieldnames(stimP2));
if ~isequal(dType1,dType2)
    % if the device types are not equal, then exit     
    return
else
    % otherwise, reset the device type variable
    dType = dType1;
end

% for each device type, 
for i = 1:length(dType)
    % retrieves the sub-struct for the current device
    stimD1 = getStructField(stimP1,dType{i});
    stimD2 = getStructField(stimP2,dType{i});
    
    % determines the channel types for each device
    [chType1,chType2] = deal(fieldnames(stimD1),fieldnames(stimD2));
    if ~isequal(chType1,chType2)
        % if the device channel types are not the same, then exit
        return
    else
        % otherwise, reset the channel type variable
        chType = chType1;
    end
    
    % for each channel type, ensure the number of stimuli 
    for j = 1:length(chType)
        % retrieves the sub-struct for the current channel
        stimC1 = getStructField(stimD1,chType{j});
        stimC2 = getStructField(stimD2,chType{j});
        
        % determines if 
        pFld = fieldnames(stimC1);
        for k = 1:length(pFld)
            % retrieves the stimuli timing values
            pVal1 = getStructField(stimC1,pFld{k});
            pVal2 = getStructField(stimC2,pFld{k});
            if length(pVal1) ~= length(pVal2)
                % exit if the length of the stimuli times are not the same
                return
            else
                % otherwise, 
                switch pFld{k}
                    case 'iStim'
                        % if the stimuli indices are not the same then exit
                        if ~isequal(pVal1,pVal2)
                            return                            
                        end
                        
                    otherwise
                        % if the stimuli times vary by too much, then exit
                        if any(abs(pVal1-pVal2)) > dtTol
                           return 
                        end
                end
            end
        end
    end
end

% flag that the stimuli protocols are similar
isEq = true;