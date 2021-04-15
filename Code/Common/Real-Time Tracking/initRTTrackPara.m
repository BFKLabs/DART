% --- initialises the tracking parameters struct --- %
function rtP = initRTTrackPara(iStim,iPara,exptType)

% RT-Closed Loop Parameters (trkP)

% General Tracking Parameters
%  => Vmove - the speed threshold for activity
%  => nSpan - average speed time point span
%  => pvFcn - population speed calculation type (mean or median)

% Combined Group Activity (combG)
%  => ind - the sub-grouping indices
%  => iGrp - the sub-grouping indices
%  => iGrpOrd - the sub-grouping indices

% Individual Stimulation Criteria (indSC)
%  => Tmove - maximum inactivity duration
%  => ExLoc - experiment location parameters
%    -> pX - position value (distance in mm or proportion)
%    -> pType - position type (mm or proporition)
%    -> pRef - position reference (1D - left/right edge, 2D - edge/centre)

% Population Stimulation Criteria (popSC)
%  => Ptol - the threhold proportion of the inactive population 
%  => Vtol - mean population speed threshold
%  => Mtol - maximum mean inactivity duration

% Stim - the indices of the corresponding apparatus/tube
%  => C2A - channel to apparatus connection indices
%  => C2G - channel to sub-region connection indices
%  => C2T - index of the channel to tube connection
%  => cType - connection type (channel to apparatus or tube)
%  => sType - stimulation type (continuous or single)
%  => bType - stimulation criteria boolean type (all or any)
%  => Tcd - stimuli cool-down time period
%  => Twarm - initial tracking warm-up phase (no stimuli within this period)

% sets the parameter struct fields
rtP = struct('trkP',[],'indSC',[],'popSC',[],'combG',[],'Stim',[]);

% sets the parameter sub-structs              
rtP.trkP = struct('Vmove',2,'nSpan',5,'pvFcn',@nanmean,'sFac',1);         
rtP.indSC = struct('Tmove',30,'ExLoc',[],'isTmove',1,'isExLoc',1);      
rtP.popSC = struct('Ptol',0.75,'Vtol',rtP.trkP.Vmove,'Mtol',120,...
                   'isPtol',1,'isVtol',1,'isMtol',1);   
rtP.combG = struct('ind',[],'iGrp',[],'iGrpOrd',[]);
         
% sets the individual stimulation criteria experiment location parameters
rtP.indSC.ExLoc = struct('pX',[5,0.1],'pType','mm','pRef','Left Edge');

% sets the USB details (if using stimuli)
if (strcmp(exptType,'RecordStim'))
    % memory allocation
    rtP.Stim = struct('C2A',[],'C2T',[],...
                      'cType','Ch2App','sType','Cont',...
                      'Tcd',30,'Twarm',30,'Tdur',5,'bType','All',...
                      'pFix',iPara,'YFix',[],'oPara',iStim.oPara(1));
    rtP.Stim.C2A = NaN(size(iStim.ID,1),1);                  
    rtP.Stim.C2T = NaN(size(iStim.ID,1),2);
    
    % initialises the parameter struct
    rtP.Stim.pFix.pDur.pVal = rtP.Stim.Tdur;    
    [rtP.Stim.pFix.pCount.pVal,rtP.Stim.pFix.pAmp.pVal] = deal(1);
    [rtP.Stim.pFix.pDelay.pVal,rtP.Stim.pFix.iDelay.pVal] = deal(0);
    
    % initialises the stimuli signal
    rtP.Stim.sFix = setSingleStimSignal(rtP.Stim.pFix,rtP.Stim.oPara);    
end
