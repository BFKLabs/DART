% --- function that updates the stimulus trace graph axes
function sPara = setSingleStimSignal(iPara,vxPara)

% sets the parameters from the struct
[sRate,isAlt] = deal(vxPara.sRate,false);
if (isfield(vxPara,'vMin'))
    [vMin,vMax,pAmpP] = deal(vxPara.vMin,vxPara.vMax,iPara.pAmp); 
else
    [vMin,vMax,pAmpP,isAlt] = deal(0,1,vxPara,true); 
end

% sets the stimulus count
if (iPara.pCount.isRand)
    % sets the random count value
    [pMin,pMax] = deal(iPara.pCount.pMin,iPara.pCount.pMax);
    nCount = roundP(pMin + (pMax - pMin)*rand,1);
else
    % otherwise set the count to be the fixed value
    nCount = iPara.pCount.pVal;
end

% sets the pulse duration, amplitude and delay vectors
pDur = setStimArray(iPara.pDur,nCount);
pAmp = setStimArray(pAmpP,nCount);
pDelay = setStimArray(iPara.pDelay,nCount-1);

% sets the stimulus time/signal array
[tStimTot,tOfs] = deal(sum(pDur) + sum(pDelay),0);
Tsig = (0:(1/sRate):tStimTot)';
Ysig = NaN(length(Tsig),1+isAlt);

% loops through all the stimuli pulses setting the signal
for i = 1:nCount
    % updates the signal with the new pulse
    Tnw = tOfs + [0 (pDur(i)+eps)];
    ii = roundP(roundP(Tnw,(1/sRate))*sRate,1);    
    Ysig(max(1,ii(1)):min(ii(2),length(Ysig)),1) = pAmp(i)*(vMax-vMin)+vMin;
    
    % increments the time offset (except for the last stimulus)
    if (i ~= nCount)
        tOfs = tOfs + (pDur(i) + pDelay(i));
    end
end

% adds the alternative values (if required)
if isAlt
    % determines the alternative device type
    if isfield(vxPara,'wNM')
        % case is the optogenetics device
        Ysig(:,2) = vxPara.wNM;
    end
end
    
% sets all the nan values to zero
Ysig(isnan(Ysig)) = 0;

% sets the final stimulus parameter struct
sPara = struct('nCount',nCount,'pDur',pDur,'pAmp',pAmp,'pDelay',pDelay,...
               'sDelay',0,'iDelay',0,'Tsig',Tsig,'Ysig',Ysig);
           
         