% --- initialises the position data struct --- %
function rtD = initRTDataStruct(iMov,rtP)

% ------------------------------ %
% --- rtD FIELD DESCRIPTIONS --- %
% ------------------------------ %

% T = tracking frame time stamp 
% P = fly positions 
% VP = average population speed
% VI = individual speed
% muInactT = mean population inactivity times
% pInact = population inactivity proportion
% Told = the time at which the fly last moved
% 
% Tcool = channel stimuli cool-down time (single stimuli only)
% isRun = boolean flags to indicate device is running (single stimuli only)
% sStatus = stimuli status flags for the channel
%   = 0 - currently free to apply stimulus
%   = 1 - currently stimuli is being applied
%   = 2 - channel is going through cool-down period (single stimuli only)
% sData = stimuli event information struct
% 
% ind = current tracking index
% fok = acceptance/rejection flags
% sFac = pixel-to-mm scale factor

% global variables
global nFrmRT

% struct memory allocation
rtD = struct('T',[],'P',[],'VI',[],'VP',[],'pInact',[],'muInactT',[],...
             'Told',[],'Tcool',[],'sStatus',[],'sData',[],...
             'ind',0,'fok',[],'Tofs',0);

% array dimensioning
nGrp = size(rtP.combG.iGrp,1);
[nApp,nFly] = deal(length(iMov.iR),getSRCountMax(iMov));

% memory allocation for the kinematic quantities
rtD.P = repmat({NaN(nFrmRT,2)},nFly,nApp);
rtD.VI = repmat({NaN(nFrmRT,nFly)},1,nApp);
[rtD.T,rtD.Told] = deal(NaN(nFrmRT,1),zeros(nFly,nApp));
[rtD.VP,rtD.pInact,rtD.muInactT] = deal(NaN(nFrmRT,nGrp));

% memory allocation for the stimuli events (if applicable)
if (~isempty(rtP.Stim))
    % determines the number of channels that are to be used
    switch (rtP.Stim.cType)
        case ('Ch2App') % case is connecting a channel to an apparatus
            nCh = size(rtP.Stim.C2A,1);
        case ('Ch2Tube') % case is connecting a channel to a tube
            nCh = size(rtP.Stim.C2T,1);
    end

    % allocates memory based on the connection type 
    rtD.Tcool = zeros(nCh,1);      
    [rtD.sStatus,rtD.sData] = deal(zeros(nCh,2),cell(nCh,1));      
end

% sets the acceptance/region flags
rtD.fok = iMov.flyok;