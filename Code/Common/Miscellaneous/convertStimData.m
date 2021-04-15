% --- converts the stimuli data from the old-format .spl/.exp files 
function [sTrainS,devType,nCh] = convertStimData(fData,useSolnForm)

% default input arguments
if ~exist('useSolnForm','var'); useSolnForm = false; end

% initialisations
if useSolnForm
    % determines if this is a record-only experiment
    if isempty(fData.iExpt.Stim)
        % if so, then return an empty array 
        [sTrainS,devType,nCh] = deal({[]},{'RecordOnly'},0);
        return
    end    
    
    % case is loading data from the solution file    
    [nDev,nCh] = deal(1,length(fData.iExpt.Stim));   
    nCount = ones(nCh,1);
    nBlkInfo = sum(nCount);
    
    % retrieves the parameter structs (converts from cell to struct array)
    iPara0 = field2cell(fData.iExpt.Stim,'sigPara');
    iPara = cellfun(@(x)(cell2mat(x)),iPara0,'un',0);
    
else
    % determines if this is a record-only experiment
    if isempty(fData.iExpt.Stim)
        % if so, then return an empty array 
        [sTrainS,devType,nCh] = deal({[]},{'RecordOnly'},0);
        return
    end    
    
    % case is not loading data from the solution file
    iStim = fData.iStim;
    
    nCount = iStim.nCount;
    [nDev,nCh] = deal(length(iStim.nChannel),iStim.nChannel);
    [nBlkInfo,iPara] = deal(sum(iStim.nCount),iStim.iPara);
end

% other initialisations
[devType,sType] = deal(repmat({'Motor'},nDev,1),'Square');
iType = cell2cell(arrayfun(@(i,x)(i*ones(x,1)),(1:nDev),nCh,'un',0));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%    SHORT-TERM STIMULI PROTOCOL    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% memory allocation
sP0 = struct('sAmp',0,'nCount',0,'tDurOn',0,'tDurOnU','s','tDurOff',0,...
             'tDurOffU','s','tOfs',0,'tOfsU','s','tDur',0,'tDurU','s');
blkInfo = struct('chName',[],'devType',[],'sPara',[],'sType',[]);
sTrainS = struct('sName',[],'chName',[],'tDur',0,...
                 'tDurU','s','blkInfo',[],'devType',[]);

% sets the signal train header fields information
sTrainS.sName = 'Short-Term Train #1';
sTrainS.chName = getMotorChannelNames(nCh,1);
sTrainS.blkInfo = repmat(blkInfo,nBlkInfo,1);
sTrainS.devType = reshape(devType(iType),size(sTrainS.chName));

% loops through each channel/signal block setting up the 
iBlk = 1;
for iCh = 1:nCh
    % memory allocation
    nBlk = nCount(iCh);
    [tBlk0,tBlkDur] = getStimBlockTiming(iPara{iCh},nBlk);
    
    % sets the information for the signal block
    tOfs = 0;
    for iBlkCh = 1:nBlk
        % retrieves the parameter struct for the channel block
        iParaNw = iPara{iCh}(iBlkCh);
        
        % sets the time offset
        if iBlkCh == 1
            % case if for the first stimuli block
            if isstruct(iParaNw.iDelay)
                tOfs = iParaNw.iDelay.pVal;
            else
                tOfs = iParaNw.iDelay;
            end
        else
            % case is for the other stimuli blocks      
            iParaPr = iPara{iCh}(iBlkCh-1);
            if isstruct(iParaPr.iDelay)
                tOfs = tOfs + (sPara.tDur + iParaPr.sDelay.pVal);
            else
                tOfs = tOfs + (sPara.tDur + iParaPr.sDelay);
            end
        end

        % sets up the signal block userdata/position
        sPara = sP0;
        sPara.tOfs = tOfs;     
        sPara.tDur = tBlkDur(iBlkCh);
        
        if isstruct(iParaNw.pAmp)
            sPara.sAmp = 100*iParaNw.pAmp.pVal;
            sPara.tDurOn = iParaNw.pDur.pVal;
            sPara.tDurOff = iParaNw.pDelay.pVal;
            sPara.nCount = iParaNw.pCount.pVal;
            
        else
            sPara.sAmp = 100*iParaNw.pAmp(1);
            sPara.tDurOn = iParaNw.pDur(1);
            sPara.tDurOff = iParaNw.pDelay(1);
            sPara.nCount = iParaNw.nCount;            
        end

        % sets the information for the current block
        sTrainS.blkInfo(iBlk).chName = sTrainS.chName{iCh};
        sTrainS.blkInfo(iBlk).devType = 'Motor';
        sTrainS.blkInfo(iBlk).sPara = sPara;
        sTrainS.blkInfo(iBlk).sType = sType;

        % increments the block counter
        iBlk = iBlk + 1;
    end

    % determines the overall max train duration
    sTrainS.tDur = max(sTrainS.tDur,tBlk0(end)+tBlkDur(end));
end

% --- calculates the offset/duration of the timing blocks
function [t0,tDur] = getStimBlockTiming(iPara,nBlk)

% memory allocation
[t0,tDur] = deal(zeros(nBlk,1));

% calculates the offset/duration of the signal blocks
for iBlk = 1:nBlk
    %
    iParaNw = iPara(iBlk);   
    
    % retrieves the time offset for the current block
    if iBlk == 1
        % case is the first signal block
        t0Nw = 0;
    else
        % case are the subsequent blocks
        if isstruct(iParaNw.sDelay)
            t0Nw = t0(iBlk-1) + tDur(iBlk-1) + iParaNw.sDelay.pVal;
        else
            t0Nw = t0(iBlk-1) + tDur(iBlk-1) + iParaNw.sDelay;
        end
    end
    
    if isstruct(iParaNw.iDelay)
        % sets the time offset of the current block    
        t0(iBlk) = t0Nw + iParaNw.iDelay.pVal;

        % calculates the duration of the blocks
        tDurOn = iParaNw.pDur.pVal;
        tDurOff = iParaNw.pDelay.pVal;
        nCount = iParaNw.pCount.pVal;
        
    else
        % sets the time offset of the current block    
        t0(iBlk) = t0Nw + iParaNw.iDelay(1);
        
        % calculates the duration of the blocks
        tDurOn = iParaNw.pDur(1);
        tDurOff = iParaNw.pDelay(1);
        nCount = iParaNw.nCount;        
    end
    
    % sets the duration of the time block
    tDur(iBlk) = tDurOn*nCount + tDurOff*(nCount-1); 
end