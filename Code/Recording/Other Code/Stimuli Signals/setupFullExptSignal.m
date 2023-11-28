% --- retrieves the full experiment signal
function [xyData,sPara] = setupFullExptSignal(sObj,sTrain,sPara)

% retrieves the properties from the gui
if isa(sObj,'OpenSolnFileTab')
    % object retrieval
    useTOfs = 1;        

    % retrieves the stimuli information for the current experiment
    hFig = sObj.hFig;
    iExpt = sObj.sInfo{sObj.iExp}.snTot.iExpt;    
else
    % retrieves the axes object/experiment data struct   
    useTOfs = 0;
    hFig = sObj;
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
end

% retrieves the current axes handle
hAx = get(hFig,'CurrentAxes');

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
nC = sPara.nCount;
[nCh,nBlk,xiC] = deal(length(sTrain.chName),length(blkInfo),(1:nC)');
[xyData,xyData0,sTypeT] = deal(cell(nCh,1));
tUnitsS = lower(tUnits(1));

% retrieves and separates the stimuli signal coordinates by channel
for i = 1:nBlk
    % calculates the signal time multiplier
    tMltDur = getTimeMultiplier(tUnitsS,blkInfo(i).sPara.tDurU);
    tMltOfs = getTimeMultiplier(tUnitsS,blkInfo(i).sPara.tOfsU);
    tOfs = tMltOfs*blkInfo(i).sPara.tOfs;    
    
    % retrieves the signal from the current stimuli block
    iCh = find(strcmp(sTrain.chName,blkInfo(i).chName) & ...
               strcmp(sTrain.devType,blkInfo(i).devType));
    
    % stores the signal values for the given channel
    if strcmp(blkInfo(i).sType,'Random')
        [xS,yS] = setupRandomStimuliSignal(...
                hAx,blkInfo(i).sPara,iCh,blkInfo(i).sType,useTOfs,nC);    
        xS = cellfun(@(x)(tMltDur*x+tOfs),xS,'un',0);                
        xyData0{iCh} = [xyData0{iCh};{[xS(:),yS(:)]}];
    else
        [xS,yS] = setupScaledStimuliSignal(...
                    hAx,blkInfo(i).sPara,iCh,blkInfo(i).sType,useTOfs);    
        xyData0{iCh} = [xyData0{iCh};{[tMltDur*xS(:)+tOfs,yS(:)]}];
    end
    
    % appends the signal protocol type to the channel
    sTypeT{iCh} = [sTypeT{iCh};{blkInfo(i).sType}];
end

% repeats the signals for the necessary counta
for i = find(~cellfun('isempty',xyData0(:)'))
    % memory allocation
    xyDataNw = cell(length(xyData0{i}),1);    
    for j = 1:length(xyDataNw)
        % adds on the inter-stimuli duration
        if strcmp(sTypeT{i}{j},'Random')
            % case is a random stimuli signale
            [xS,yS] = deal(xyData0{i}{j}(:,1),xyData0{i}{j}(:,2));
            xyDataNw{j} = cell2mat(cellfun(@(x,y,i)...
                ([x+(i-1)*tDurStim,y]),xS,yS,num2cell(xiC),'un',0));
        else
            % case is a non-random stimuli signale
            xyDataNw{j} = cell2mat(arrayfun(@(x)(colAdd(...
                xyData0{i}{j},1,(x-1)*tDurStim)),xiC,'un',0));
        end
    end
    
    % converts the cell array to a numerical array
    xyDataNw = cell2mat(xyDataNw);
            
    % scales the values in the
    j = (nCh+1) - i;
    yS = xyDataNw(:,2);
    xyDataNw(:,2) = yS + (j+mod(yS(1),1))-(1+yS(1));

    % sorts the time-shifted data in chronological order
    [~,iSort] = sort(xyDataNw(:,1));
    xyData{i} = xyDataNw(iSort,:);
end

% --- sets up the random stimuli experiment signal
function [xS,yS] = setupRandomStimuliSignal(hAx,sPara,iCh,sType,useTOfs,nC)

% memory allocation
[xS,yS] = deal(cell(nC,1));

% sets up the scale stimuli signals for each block
for i = 1:nC
    [xS{i},yS{i}] = setupScaledStimuliSignal(hAx,sPara,iCh,sType,useTOfs);        
end