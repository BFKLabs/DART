% --- 
function stimFrm = setStimFrameStats(iData)

% index for the movie
[T,stimP] = deal(iData.Tv,iData.stimP);
FPS = roundP(iData.exP.FPS,1);

% parameters
[tStimBefore,nT] = deal(60,length(T));                % duration before the stimuli 
stimFrm = zeros(nT,1);

% loops through each of the devices/channels determining the time points
% within the current movie that either 
for i = 1:length(stimP)    
    % loops through all of the stimuli events setting the 
    for j = 1:length(stimP(i).Tsig)
        % sets the stimuli signal trace
        [Tsig,Ysig] = deal(stimP(i).Tsig{j},stimP(i).Ysig{j});
        [Ts0,TsF] = deal(stimP(i).Ts0(j)-T(1),stimP(i).TsF(j)-T(1));
         
        % determines the indices 
        [inds0,indsF] = deal(roundP(Ts0*FPS,1),roundP(TsF*FPS,1));
        indsOn = roundP(roundP(Tsig(Ysig(:,1) > 0),1/FPS)*FPS,1) + (inds0-1);
        indsOn = indsOn((indsOn>=1)&(indsOn<nT));

        % updates the stimulus frame parameters      
        [i1,i2] = deal(inds0-(tStimBefore*FPS:-1:1),inds0:indsF);
        [i1,i2] = deal(i1((i1>=1)&(i1<nT)),i2((i2>=1)&(i2<nT)));
        stimFrm(i1+1) = max(1,stimFrm(i1+1));
        stimFrm(i2+1) = max(2,stimFrm(i2+1));
        stimFrm(indsOn) = 3;
    end
end
