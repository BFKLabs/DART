% --- determines the time group indices for the time array, T, given the 
%     experiment started at time, Texpt0, and the time of the first group
%     starts at Tgrp0
function [indGrp,indD] = detTimeGroupIndices(T,Texpt0,nGrp,Tgrp0,isDaySep)

% global variables
global tDay

% parameters
pTolMin = 0.01;

% sets the day seperation to false (if not provided)
if (nargin < 4); Tgrp0 = tDay; end
if (nargin < 5); isDaySep = false; end

% converts the time array/start time from seconds to hours
T = T(~isnan(T));
TT = convertTime(T,'sec','hrs');
T0 = convertTime(vec2sec([0 Texpt0(4:end)]),'sec','hrs');

% calculates the time groups that each time point belongs to
Tgrp = floor((TT - mod(Tgrp0-T0,24))/(24/nGrp));
[indG,indD] = deal(mod(Tgrp,nGrp)+1,floor(Tgrp/nGrp)+1);
if (indD(1) == 0); indD = indD+1; end

% sets the groupings depending if they are to be seperated by day
if isDaySep
    % memory allocation
    indGrp = cell(max(indD),nGrp);
    ii = sub2ind([max(indD) nGrp],indD,indG);
    
    % sets the index arrays for each day/time group
    indGrp(ii) = arrayfun(@(x)(find(ii==x)),ii,'un',0);
else
    % sets the index arrays for each time group
    indGrp = arrayfun(@(x)(find(indG==x)),1:nGrp,'un',0);
end

% removes any rows which don't have enough elements
nGrp = cellfun(@length,indGrp);
isOK = nGrp/max(nGrp(:)) > pTolMin;
indGrp(~isOK) = {[]};
indGrp = indGrp(any(isOK,2),:);
