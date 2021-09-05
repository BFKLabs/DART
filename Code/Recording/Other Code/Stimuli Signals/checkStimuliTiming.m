% --- ensures that all stimuli timing is correct
function [sTrain,isChange] = checkStimuliTiming(iExpt,sTrain)

% initialisations
isChange = false;
sFld = {'S','L'};
hasEx = ~isempty(sTrain.Ex);
tExpS = vec2sec(iExpt.Timing.Texp);

% loops through all the stimuli struct fields checking the timing
for i = 1:length(sFld)    
    sT = getStructField(sTrain,sFld{i});
    if ~isempty(sT)
        % checks each field of the sub-struct (if not empty)
        for j = 1:length(sT)
            % checks the duration of the stimuli block is feasible
            tMltD = getTimeMultiplier(sT{j}.tDurU,'s');
            if sT{j}.tDur*tMltD > tExpS
                % if not, then reset to the maximum
                isChange = true;
                sT{j}.tDur = tExpS/tMltD;
                
                % determines if the stimuli block matches any of the
                % experimental stimuli blocks
                if hasEx
                    ii = strcmp(sTrain.Ex.sName,sT{j}.sName);
                    if any(ii)
                        % if so, then replace it
                        sTrain.Ex.sTrain(ii) = sT{j};
                    end
                end
            end
            
            % retrieves the times of the stimuli blocks
            tBlk = arrayfun(@(x)(getMaxStimBlockTime(x)),sT{j}.blkInfo);
            if any(tBlk > tExpS)
                % FINISH ME!
            end
        end
        
        % updates the sub-struct within the main data struct
        sTrain = setStructField(sTrain,sFld{i},sT);
    end
end

% --- retrieves the maximum stimuli block time
function tMax = getMaxStimBlockTime(blkInfo)

% calculates the stimuli signal and returns the max value
sParaS = blkInfo.sPara;
[xS,~] = setupStimuliSignal(sParaS,blkInfo.sType,1/100);

% sets the duration/offset
tDur = max(xS)*getTimeMultiplier(sParaS.tDurU,'s');
tOfs = sParaS.tOfs*getTimeMultiplier(sParaS.tOfsU,'s');

% converts the time to seconds
tMax = tOfs + tDur;