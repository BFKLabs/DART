% --- function that sets the total stimuli signal
function sPara = setTotalStimSignal(iPara,vxPara)

% determines the number of stimuli events
nStim = length(iPara);
if (nStim == 0)
    % if there are none, then return an empty array
    sPara = [];
    return
end

% parameters & memory allocation
[sPara,iDelay] = deal(cell(nStim,1),setStimArray(iPara(1).iDelay,1));
[tOfs,sRate,isOpto] = deal(iDelay,vxPara(1).sRate,false);

%
if isfield(vxPara(1),'vMin')
    [iC, nC] = deal(1, 1);
else
    if isfield(vxPara(1),'wNM')
        [iC, nC, isOpto] = deal(1:2, 2, true);
    end
end

% loops through all of the signal
for i = 1:nStim
    % sets the stimulus count
    if (iPara(i).sDelay.isRand)
        % sets the random count value
        [pMin,pMax] = deal(iPara(i).sDelay.pMin,iPara(i).sDelay.pMax);
        sDelay = roundP(pMin + (pMax - pMin)*rand,1/sRate);
    else
        % otherwise set the count to be the fixed value
        sDelay = iPara(i).sDelay.pVal;
    end
    
    if (isOpto)
        if (i > length(vxPara))
            sPara{i} = setSingleStimSignal(iPara(i),vxPara(1));
        else
            sPara{i} = setSingleStimSignal(iPara(i),vxPara(i));
        end
    else
        sPara{i} = setSingleStimSignal(iPara(i),vxPara);
    end
    
    % calculates the single stimulus train signal
    sPara{i}.Tsig = sPara{i}.Tsig + tOfs;
    [sPara{i}.sDelay,sPara{i}.iDelay] = deal(sDelay,iDelay);
    
    % appends the inter-stimulus delay to the current stimulus train signal
    % (if this is not the final stimulus train)
    if (i ~= nStim)
        TsigNw = (sPara{i}.Tsig(end)+((1/sRate):(1/sRate):sDelay)');
        sPara{i}.Tsig = [sPara{i}.Tsig;TsigNw(1:(end-1))];
        sPara{i}.Ysig = [sPara{i}.Ysig(:,iC);zeros(length(TsigNw)-1,nC)];
        
        % increments the time offset
        tOfs = (sPara{i}.Tsig(end) + (1/sRate));
    end
end

% sets the cell array as numerical arrays
sPara = cell2mat(sPara);