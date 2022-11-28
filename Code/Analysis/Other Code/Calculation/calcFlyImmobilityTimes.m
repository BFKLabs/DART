% --- calculates the fly immobility times for the position array, Px, which
%     has rows that have time stamps, T. the immobility time bands are
%     given wrt
function [tImmob,isReact,tReact] = calcFlyImmobilityTimes(T,Px,Py,Ts,cP,indB,Tmlt)

% global variables
global nGrpMin
nGrpMin = 5;

%
if ((isempty(Px)) && (isempty(Py)))
    [tImmob,isReact,tReact] = deal([]);
    return
end

% converts the stimuli time array into a cell array (if not already)
if (~iscell(Ts))
    Ts = num2cell(Ts);
end

% sets the time-multiplier
if (nargin < 7); Tmlt = 60; end

% creates the time band index array (if not provided)
if (nargin < 6)
    % sets the time indices that correspond to the stimuli events
    iTs = cellfun(@(x)(find(T<x,1,'last')),Ts,'un',0);
    iTs = cell2mat(iTs(~cellfun('isempty',iTs)));
    
    % sets the index band array
    indB = num2cell([[1;(iTs(1:end-1)+1)],iTs],2);
end

% sets the index band to calculate the flies reaction to the stimuli
nFrm = size(Px,1);
indNR = cellfun(@(x)([x(2) min(x(2)+ceil(cP.tNonR),nFrm)]),indB,'un',0);
PxR = cellfun(@(z)(Px(z(1):z(2),:)),indNR,'un',0);

% calculates the immobility times and whether they reacted to the stimuli
if (isempty(Py))
    % case is 1D analysis
    tImmob = cell2mat(cellfun(@(x,y,zX,zY)(calcBandImmobilityTimes(...
                T(x(1):x(2)),Px(x(1):x(2),:),[],y,cP,zX,[],Tmlt)),...
                indB,Ts,PxR,'un',0));   
    isReact = cell2mat(cellfun(@(x)(calcBandReactivity(Px(x(1):x(2),:),...
                [],cP)),indNR,'un',0));    
else
    % case is 2D analysis
    PyR = cellfun(@(z)(Py(z(1):z(2),:)),indNR,'un',0);
    tImmob = cell2mat(cellfun(@(x,y,zX,zY)(calcBandImmobilityTimes(...
                T(x(1):x(2)),Px(x(1):x(2),:),Py(x(1):x(2),:),y,cP,zX,zY,Tmlt)),...
                indB,Ts,PxR,PyR,'un',0));   
    isReact = cell2mat(cellfun(@(x)(calcBandReactivity(Px(x(1):x(2),:),...
                Py(x(1):x(2),:),cP)),indNR,'un',0));
end
            
% calculates the reaction times (if required)
if (nargout == 3)
    indBN = [indB(2:end);[(indB{end}(2)+1) length(T)]];
    if (isempty(Py))
        % case is 1D analysis
        tReact = cellfun(@(x)(calcReactivityTime(T(x(1):x(2)),...
                    Px(x(1):x(2),:),[],cP)),indBN,'un',0);
    else
        % case is 2D analysis
        tReact = cellfun(@(x)(calcReactivityTime(T(x(1):x(2)),...
                    Px(x(1):x(2),:),Py(x(1):x(2),:),cP)),indBN,'un',0);        
    end
end

% --- calculates the reaction time of the stimuli wrt the stimuli start - %             
function tReact = calcReactivityTime(T,PxR,PyR,cP)            

% global variables
global nGrpMin

% calculates the change in x-location
[dT,dPx] = deal(T-T(1),calcDistanceRange(PxR,PyR) > cP.dMove);

% determines the indices of the time points where the x-location of the fly
% is greater than the
iGrp = cellfun(@(x)(getGroupIndex(x)),num2cell(dPx,1),'un',0);
iNw = cellfun(@(x)(find(cellfun('length',x)>= nGrpMin,1,'first')),iGrp,'un',0);

% sets the reaction times (for those that did react)
[tReact,ii] = deal(NaN(1,length(iNw)),~cellfun('isempty',iNw));
tReact(ii) = cellfun(@(x,y)(dT(x{y}(1))),iGrp(ii),iNw(ii));

% --- calculate the reactivity band           
function isReact = calcBandReactivity(PxR,PyR,cP)            

% global variables
global nGrpMin

% determines if the fly reacted for the correct number of frames
isReact = sum(calcDistanceRange(PxR,PyR) >= cP.dMove,1) >= nGrpMin;

% --- calculate            
function tImmob = calcBandImmobilityTimes(T,Px,Py,Ts,cP,PxR,PyR,Tmlt)            
      
% global variables
global nGrpMin

% sets the x/y location cell arrays
PxN = num2cell(Px,1);
if (isempty(Py))
    % case is 1D analysis
    PyN = cell(size(PxN));
else
    % case is 2D analysis
    PyN = num2cell(Py,1);    
end

% calculates the individual immobility times for each of the flies
iMove = cellfun(@(x,y)(calcIndivImmobilityIndex(x,y,cP.dMove)),PxN,PyN);
if (isfield(cP,'moveOnly'))
    if (cP.moveOnly)
        % removes any of the flies that have not reacted to the stimuli within
        % the time, tReact
        isReact = sum(calcDistanceRange(PxR,PyR) >= cP.dMove,1) >= nGrpMin;
        iMove(~isReact) = NaN;
    end
end

% calculates the immobility times (for all the feasible moved flies)
[tImmob,ii] = deal(NaN(1,length(iMove)),~isnan(iMove));
tImmob(ii) = floor((Ts - T(iMove(ii)))/Tmlt);

% --- determines the index within the x-location array, Px, where the fly
%     has moved more than a distance, dMove --- %
function iMove = calcIndivImmobilityIndex(Px,Py,dMove)

% global variables
global nGrpMin

% sets the minimum number of frames that the fly is outside the movement
% limit. if the number of frames is less than this value, then it is
% assumed that the flies movement is anomalous and will be ignored
if (isempty(Py))
    dRng = abs(Px - Px(end));
else
    dRng = sqrt((Px - Px(end)).^2 + (Py - Py(end)).^2);
end
    
% determines the last time point within the vector where the distance
% travelled from the final location is greater than dMove
ii = find(dRng > dMove,1,'last');
% iGrp = getGroupIndex(dPx > dMove);
if (isempty(ii))
    % if there was no movement, then set a NaN values for the index
    iMove = NaN;
else
    % searches to determine if the movement value is not anomalous
    while (1)
        if (isempty(ii)) || (ii <= nGrpMin)
            % if there is no more movement, then exit the loop with a nan
            iMove = NaN; return
        elseif (all(dRng(ii-(nGrpMin:-1:1)) > dMove))
            % if the movement index is less than the group count, then
            % return the index value in any case
            iMove = ii; return
        else
            % otherwise, search for the next movement index
            ii = find(dRng(1:(ii-1)) > dMove,1,'last');            
        end
    end  
end

% --- calculates the distance range of the fly from the initial location
function Drng = calcDistanceRange(PxR,PyR)

% initialisations
N = size(PxR,1);
dPxR = PxR - repmat(PxR(1,:),N,1);

% calculates the distance range of the fly
if (isempty(PyR))
    % case is 1D analysis
    Drng = abs(dPxR);
else
    % case is 2D analysis
    Drng = sqrt(dPxR.^2 + (PyR - repmat(PyR(1,:),N,1)).^2);
end