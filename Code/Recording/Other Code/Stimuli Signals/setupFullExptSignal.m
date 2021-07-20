% --- retrieves the full experiment signal
function [xyData,sPara] = setupFullExptSignal(hFig,sTrain,sPara)

% retrieves the current axes handle
hAx = get(hFig,'CurrentAxes');

% retrieves the properties from the gui
switch get(hFig,'tag')
    case 'figExptSetup'
        % retrieves the axes object/experiment data struct   
        useTOfs = 0;
        iExpt = getappdata(hFig,'iExpt');

        % sets the default input arguments (if not provided)
        if ~exist('sPara','var')
            % retrieves the experiment parameter struct (if not provided)
            sType = getappdata(hFig,'sType');    
            sParaEx = getappdata(hFig,'sParaEx');
            sPara = getStructField(sParaEx,sType(1));         

            % retrieves the selected signal train info (if not provided)
            if ~exist('sTrain','var')
                sTrain = getSelectedSignalTrainInfo(hFig);
            end
        end

    case 'figOpenSoln'
        % object retrieval
        useTOfs = 1;
        iExp = getappdata(hFig,'iExp');
        sInfo = getappdata(hFig,'sInfo');        
        
        % retrieves the stimuli information for the current experiment
        iExpt = sInfo{iExp}.snTot.iExpt;
        
end

%
if isfield(iExpt.Timing,'TexpU')
    TexpU = iExpt.Timing.TexpU;
else
    tLim = [2,6,1e10];
    tStr0 = {'m','h','d'};
    tUnits0 = {'Minutes','Hours','Days'};    
    Texp = vec2sec(iExpt.Timing.Texp);
    
    TexpC = cellfun(@(x)(convertTime(Texp,'s',x)),tStr0);
    TexpU = tUnits0{find(TexpC < tLim,1,'first')};    
end

% retrieves the experiment-dependent parameter struct (for the current
% device type and protocol type)
[~,tUnits] = vec2time(iExpt.Timing.Texp,TexpU);
tDurStim = vec2time(sPara.tStim,tUnits);

% retrieves the currently selected stimuli train
blkInfo = sTrain.blkInfo;

% memory allocation
[nCh,nBlk] = deal(length(sTrain.chName),length(blkInfo));
[xyData,xyData0] = deal(cell(nCh,1));
tUnitsS = lower(tUnits(1));

% retrieves and separates the stimuli signal coordinates by channel
for i = 1:nBlk
    % calculates the signal time multiplier
    tMltDur = getTimeMultiplier(tUnitsS,blkInfo(i).sPara.tDurU);
    tMltOfs = getTimeMultiplier(tUnitsS,blkInfo(i).sPara.tOfsU);
    
    % retrieves the signal from the current stimuli block
    iCh = find(strcmp(sTrain.chName,blkInfo(i).chName) & ...
               strcmp(sTrain.devType,blkInfo(i).devType));
    [xS,yS] = setupScaledStimuliSignal(...
                hAx,blkInfo(i).sPara,iCh,blkInfo(i).sType,useTOfs);
    
    % stores the signal values for the given channel
    tOfs = tMltOfs*blkInfo(i).sPara.tOfs;
    xyData0{iCh} = [xyData0{iCh};[tMltDur*xS(:)+tOfs,yS(:)]];
end

% repeats the signals for the necessary counta
for i = 1:nCh
    if ~isempty(xyData0{i})
        % adds on the inter-stimuli duration
        xyDataNw = cell2mat(arrayfun(@(x)(colAdd(...
                xyData0{i},1,(x-1)*tDurStim)),(1:sPara.nCount)','un',0));        
            
        % scales the values in the
        j = (nCh+1) - i;
        yS = xyDataNw(:,2);
        xyDataNw(:,2) = yS + (j+mod(yS(1),1))-(1+yS(1));                                
        
        % sorts the time-shifted data in chronological order
        [~,iSort] = sort(xyDataNw(:,1));
        xyData{i} = xyDataNw(iSort,:);
    end
end