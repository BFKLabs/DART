% --- calculates the arousal threshold data
function indReact = calcArousalThresholdData(snTot,cP,h,wOfs)

% sets the default parameters
if nargin < 4; wOfs = 0; end
if nargin < 3
    h = ProgBar({'Initialising'},'Retrieving Sleep Intensity Data');
end

% retrieves the other calculation parameters (if they exist)
[devType,chType] = deal([]);
if isfield(cP,'devType'); devType = cP.devType; end
if isfield(cP,'chType'); chType = cP.chType; end   

% ------------------------------------------- %
% --- INITIALISATIONS & MEMORY ALLOCATION --- %
% ------------------------------------------- %

% retrieves the group/bin number count
if isfield(cP,'nGrp')
    % flag is set as "nGrp"
    nGrp = str2double(cP.nGrp);
    
else
    % bin parameter has not been set, so exit the function
    eStr = 'Error! Must set nGrp as calculation parameter';
    waitfor(errordlg(eStr,'Missing Parameter Error','modal'));
    indReact = [];
    return    
end

% memory allocation
Tgrp0 = cP.Tgrp0;
nApp = length(snTot.iMov.ok);
indReact = cell(1,nApp);

% sets the signal parameter struct (assumes that all signals are the same
% across all DAC devices for all stimuli events in the experiment)
pSig = snTot.iExpt.Stim(1).sigPara{1};

% calculates the signal duration and the time from the start of the signal
% stimuli train to the next train
Tsig = cellfun(@(x,y)(sum(x)+sum(y)),field2cell(pSig,'pDur'),...
                                     field2cell(pSig,'pDelay'));
TsigR = cumsum([0;(Tsig + field2cell(pSig,'sDelay',1));1e10]);
[cP.tNonR,tImmobTol] = deal(TsigR(end-1),TsigR(2));

% sets the stimuli times
Ts = getMotorFiringTimes(snTot.stimP,devType,chType);
if isempty(Ts)
    % if there are no recorded stimuli events, then output an error    
    if wOfs == 0
        eStr = 'Error! This experiment contains no recorded stimuli events.';
        waitfor(errordlg(eStr,'Invalid Experiment Type','modal'))    
    end
    
    % exits the function
    return
    
else
    % array dimensioning and memory allocation
    [Ttot,Ts] = deal(cell2mat(snTot.T),sort(Ts));
    flyok = snTot.iMov.flyok;    
end        

% determines the indices of the stimuli events within the total
% experiment, and determines what time groups that the stimuli
% events took place in
indGrp = detTimeGroupIndices(Ts,snTot.iExpt.Timing.T0,nGrp,Tgrp0,true);   

% determines the indices, within the total time array, that the stimuli
% events took place and uses these to determine the effective time bands
h.Update(1+wOfs,'Determining Time Bin Indices...',1/(2+nApp));
iTs = cellfun(@(x)(find(Ttot<x,1,'last')),num2cell(Ts),'un',0);

% otherwise, determine if any of the groups are empty and remove them
ii = ~cellfun(@isempty,iTs);
iTs = cell2mat(iTs(ii));

% sets the index band array
indB = num2cell([[1;(iTs(1:end-1)+1)],iTs],2);
                  
% calculates the metrics for all apparatus
for i = 1:nApp
    % updates the waitbar figure
    wStrNw = sprintf(['Calculating Reaction Levels (Region %i ',...
                      'of %i)'],i,nApp);
    if h.Update(1+wOfs,wStrNw,0.5*(1+wOfs)*(i+1)/(2+nApp))
        % if the user cancelled, then exit the function
        indReact = [];
        return
    end         
        
    % only calculate if data exists...
    if (~isempty(snTot.Px{i}))
        % sets the fly x-locations array
        [Px,Py] = deal(snTot.Px{i}(:,flyok{i}),[]);
        if (~isempty(snTot.Py)); Py = snTot.Py{i}(:,flyok{i}); end
                
        % calculates the pre-stimuli immobility times over all flies for each
        % of the stimuli events
        [tImmob,~,tReact] = calcFlyImmobilityTimes(Ttot,Px,Py,Ts,cP,indB,1);      

        % determines the flies which were immobile before the stimuli 
        tImmobGrp = cellfun(@(x)(tImmob(x,:)),indGrp,'un',0);
        tReactGrp = cellfun(@(x)(cell2mat(tReact(x))),indGrp,'un',0);

        % sets the stimuli train reaction indices for each time group
        indReact0 = cellfun(@(x,y)(detStimReactGroup(x,y,tImmobTol,TsigR)),...
                                    tImmobGrp,tReactGrp,'un',0);  
        indReact0(cellfun(@isempty,indReact0)) = {NaN(1,size(indReact0{1,1},2))};
        
        % rearranges the arrays so that they are ordered by day, rather
        % than by fly
        indReact{i} = cell(size(indGrp,1),length(flyok{i}));
        xiF = num2cell(1:sum(flyok{i}));
        indReact{i}(:,flyok{i}) = cell2cell(cellfun(@(z)(cellfun(@(x)(...
                combineNumericCells(cellfun(@(y)(y(:,x)),z,'un',0))),...
                xiF,'un',0)),num2cell(indReact0,2),'un',0));
            
        % fills any rejected regions with NaN values
        if any(~flyok{i})
            i0 = find(flyok{i},1,'first');
            indReact{i}(:,~flyok{i}) = {NaN(size(indReact{i}{i0}))};
        end
    end
end
                
% --- determines the stimuli train that the flies reacted to.
function indReact = detStimReactGroup(tImmob,tReact,tImmobTol,TsigR)

% memory allocation
indReact = zeros(size(tImmob));
if isempty(tImmob); return; end

% for the immobile flies, determine the time at which they reacted
isImmob = (tImmob > tImmobTol) & ~isnan(tReact);

% for the immobile flies, determine the stimuli that they reacted to
ii = cellfun(@(x)(find(x>=TsigR,1,'last')),num2cell(tReact(isImmob)));
indReact(isImmob) = ii;