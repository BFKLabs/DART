% --- calculates the sleep metrics for an experiment --- %
function [dTot,dWake,tWake,V] = calcWakingMetrics(snTot,Ttot,indB,cP,ind,flyok)

% sets the minimum time grouping values
tExp = convertTime(Ttot(end),'sec','min');
tMinGrp = min(0.25*tExp, 0.05*(24*60)/str2double(cP.nGrp));
tMin = max(20,tMinGrp);

% memory allocations
[nGrp0,Tgrp0] = deal(str2double(cP.nGrp),cP.Tgrp0); 
jj = cellfun(@length,indB) > 1;
i0 = find(jj,1,'first');
I = cell(length(indB),1);

% calculates the range/midline crossings for all the time bins
V = calcBinnedFlyMovement(snTot,Ttot,indB(jj),cP,ind,flyok);

% sets the distance metric for calculating the average 
if (strcmp(cP.movType,'Absolute Range'))
    cP.movType = 'Absolute Distance';
    VD = cell2mat(calcBinnedFlyMovement(snTot,Ttot,indB(jj),cP,ind,flyok));
else
    VD = cell2mat(V);
end
    
% calculates the mean proportional movement (based on the movement
% type)
switch (cP.movType)
    case ('Midline Crossing') % case is calculating midline crossing
        I(jj) = cellfun(@(x)(x > 0),V,'un',0);
    otherwise % case is calculating absolute distance
        % calculates the mean proportional movement
        I(jj) = cellfun(@(x)(x > cP.dMove),V,'un',0);        
end

% sets the values into the temporary array
Y = true(length(indB),size(I{i0},2));
Y(jj,:) = logical(cell2mat(I(jj)));

% determines the groups of indices which correspond to the fly being
% inactive (false values in the temporary array)
iGrp = cellfun(@(x)(getGroupIndex(x)),num2cell(~Y,1),'un',0);

% sets all the time bins where there is inactivity, but no sleep, to being 
% active time bins
for i = 1:length(iGrp)
    nGrp = cellfun(@length,iGrp{i});
    Y(cell2mat(iGrp{i}(nGrp < cP.tSleep)),i) = true;
end

% sets the group indices
Tmn = cellfun(@(x)(mean(Ttot(x))),indB);
indGrp = detTimeGroupIndices(Tmn,snTot.iExpt(1).Timing.T0,nGrp0,Tgrp0,true);

% sets the number of the time points for each time group (remove small
% time bins that are short)
N = cellfun(@length,indGrp);
N(N < tMin) = 0;
indGrp(cellfun(@(x)(x==0),num2cell(N))) = {[]};

% converts the movement cell array to a numeric array
YY = cellfun(@(x)(num2cell(Y(x,:),1)),indGrp,'un',0);
VV = cellfun(@(x)(num2cell(VD(x,:),1)),indGrp,'un',0);

% calculates the 
dTot0 = cellfun(@(xx,yy)(cellfun(@(x,y)(nanmean(x(y))),...
                        xx,yy)),VV,YY,'un',0);
dWake0 = cellfun(@(xx,yy)(cellfun(@(x,y)(nanmean(x(y))*...
                        length(y)/sum(y)),xx,yy)),VV,YY,'un',0);
tWake0 = cellfun(@(x,y)(60*cellfun(@sum,x)/y),YY,num2cell(N),'un',0);

% removes any NaN values from the waking distance array
for i = 1:size(N,1)
    for j = 1:size(N,2)
        if (N(i,j) > 0)
            dTot0{i,j}(isnan(dTot0{i,j})) = 0;
            dWake0{i,j}(isnan(dWake0{i,j})) = 0;
        else
            tWake0{i,j}(isinf(tWake0{i,j})) = NaN;
        end
    end
end

% memory allocation
A = {NaN(size(dTot0{1},1),length(flyok))};
[dTot,dWake,tWake] = deal(repmat(A,size(dTot0)));

% sets the full arrays
for i = 1:numel(dTot)
    dTot{i}(:,flyok) = dTot0{i};
    dWake{i}(:,flyok) = dWake0{i};
    tWake{i}(:,flyok) = tWake0{i};
end