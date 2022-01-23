% --- calculates the sleep metrics for an experiment --- %
function [nBoutAvg,tSleepAvg,Tgrp] = calcSleepMetrics(snTot,Ttot,indB,cP,ind,fok)

%
if isfield(cP,'nGrp')
    % case is the group count is used
    tExp = convertTime(Ttot(end),'sec','min');
    tMinGrp = min(0.25*tExp, 0.05*(24*60)/str2double(cP.nGrp));
    tMin = max(20,tMinGrp);
elseif isfield(cP,'tBin')
    % case is the time bin is used
    tMin = 1;    
else
    % finish me later...
    error('Set the correct time grouping parameter!')
end

% memory allocations & parameters
jj = ~cellfun(@isempty,indB);
i0 = find(jj,1,'first');

% calculates the binned activity metrics   
I = calcBinnedActivity(snTot,Ttot,indB,cP,ind,fok);

% sets the values into the temporary array
Y = true(length(indB),size(I{i0},2));
Y(jj,:) = logical(cell2mat(I(jj)));

% determines the groups of indices which correspond to the fly being
% inactive (false values in the temporary array)
Tmn = cellfun(@(x)(nanmean(Ttot(x))),indB);
iGrp = cellfun(@(x)(getGroupIndex(x)),num2cell(~Y,1),'un',0);

% for each fly, determine which periods of inactivation were longer than
% the sleep duration time (tSleep)
for i = 1:length(iGrp)
    nGrpNw = cellfun(@length,iGrp{i});
    Y(cell2mat(iGrp{i}(nGrpNw < cP.tSleep)),i) = true;
end

% calculates the new time groups
if isfield(cP,'nGrp')
    [nGrp,Tgrp0] = deal(str2double(cP.nGrp),cP.Tgrp0);   
else
    [nGrp,Tgrp0] = deal(1440/cP.tBin,cP.Tgrp0);    
end
    
% sets the group indices
iMap = find(~isnan(Tmn));
indGrp = detTimeGroupIndices(Tmn,snTot.iExpt(1).Timing.T0,nGrp,Tgrp0,true);
indGrp = cellfun(@(x)(iMap(x)),indGrp,'un',0);
Tgrp = cellfun(@(x)(nanmean(Tmn(x))),indGrp);

% calculates the sleep bouts/durations
YY = cellfun(@(x)(num2cell(~Y(x,:),1)),indGrp,'un',0);
nBout = cellfun(@(y)(cellfun(@(x)(...
                    length(getGroupIndex(x))),y)),YY,'un',0);
tSleep = cellfun(@(y)(cellfun(@(x)(sum(x)),y)),YY,'un',0);

% removes any rejected values from the analysis
if any(~fok) && (length(fok) == size(nBout{1},2))
    for i = 1:numel(nBout)
        [nBout{i}(:,~fok),tSleep{i}(:,~fok)] = deal(NaN);
    end
end

% determines the time difference over each time group 
[ii,dT] = deal(~cellfun(@isempty,indGrp),zeros(size(nBout)));
dT(ii) = cellfun(@length,indGrp(ii));

% removes any small time groups from the analysis)
jj = dT < tMin; 
nBout(jj) = cellfun(@(x)(NaN(size(x))),nBout(jj),'un',0);
tSleep(jj) = cellfun(@(x)(NaN(size(x))),nBout(jj),'un',0);
    
% converts the metrics to hourly rates
nBoutAvg = cellfun(@(x,y)(60*(x/y)),nBout,num2cell(dT),'un',0);
tSleepAvg = cellfun(@(x,y)(60*(x/y)),tSleep,num2cell(dT),'un',0);