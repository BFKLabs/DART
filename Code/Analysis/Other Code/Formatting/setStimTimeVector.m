% --- sets up the stimuli response time signal for tBefore/tAfter mins with
%     respect to the stimuli event
function T = setStimTimeVector(cP)

% scales the time to seconds and sets the time vector
[tBefore,tAfter] = deal(cP.tBefore*60,cP.tAfter*60);
T = (-tBefore:tAfter);