% function that creates the signals for the DAC/Serial devices
function xySigF = setupDACSignal(sTrainC,chInfo,dT)

% memory allocation
nDev = chInfo{end,1};
nTrain = length(sTrainC);
nCh = length(sTrainC(1).chName);
[xySig,xySigF] = deal(cell(nCh,2),cell(nDev,1));

for j = 1:nTrain
    %
    blkInfo = sTrainC(j).blkInfo;
    nBlk = length(blkInfo);

    % sets up the x/y locations of the signal objects
    for i = 1:nBlk
        % retrieves the channel index
        sP = blkInfo(i).sPara;
        iCh = find(strcmp(sTrainC(j).chName,blkInfo(i).chName) & ...
                   strcmp(sTrainC(j).devType,blkInfo(i).devType));
        tMlt = getTimeMultiplier('s',blkInfo(i).sPara.tDurU);               

        % calculates the actual stimuli signal values
        [xS0,yS0] = setupStimuliSignal(...
                    blkInfo(i).sPara,blkInfo(i).sType,dT);
        xS0 = (xS0 + sP.tOfs)*tMlt;

        % sets the time/amplitude values for each point in the signal where
        % there is a signficant change in the signal
        ii = find(diff([xS0;(xS0(end)+1)]) > 0);
        for k = 1:length(iCh)
            xySig{iCh(k),1} = [xySig{iCh(k),1};xS0(ii)];
            xySig{iCh(k),2} = [xySig{iCh(k),2};yS0(ii)];
        end
    end
end

% splits the signal values between the devices
for i = 1:nDev
    % sets the values for the current device
    ii = cell2mat(chInfo(:,1)) == i;
    xySigF{i} = xySig(ii,:);
end