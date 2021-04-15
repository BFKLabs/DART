% --- updates the tracking statistics GUI object properties and returns the
%     indices of the USB devices/channels that need to be stimulated --- %
function [rtD,indStim] = updateTrackingPropFields(iMov,rtD,h,dType,gType)

% ----------------------------------------------- %
% --- TRACKING METRIC CALCULATIONS & STATUSES --- %
% ----------------------------------------------- %

% array dimensioning
indStim = [];

% -------------------------------------- %
% --- TRACKING METRIC STATUS STRINGS --- %
% -------------------------------------- %

% check to see if any of the devices are connected to apparatus/tubes
if (~isempty(rtD.rtP.Stim))
    % determines the stimuli criteria
    [rtD,checkStim] = detStimCriteria(iMov,rtD,h);
    
    % if there are any valid connect channels, then determine if any of
    % them are flagged to have a stimuli applied
    if (checkStim)
        % determines if any of the channels require stimulation
        indStim = false(size(rtD.sStatus,1),1);
        for i = 1:size(rtD.sStatus,1)
            indStim(i) = isequal(rtD.sStatus(i,:),[1 0]);
        end

        % converts the boolean array to a numeric array
        indStim = find(indStim);
    end
end

% retrieves the new tracking property fields strings/status colours
[datStr,totStr,rtD] = getTrackingProps(iMov,rtD,h,dType);
datStr = datStr(:,rtD.rtP.combG.iGrpOrd);
        
% ------------------------------------ %
% --- TRACKING GUI PROPERTY UPDATE --- %
% ------------------------------------ %

% retrieves the connection flags
isC2A = getappdata(h,'isC2A');

% sets the individual fly/population data strings
cellfun(@(x,y)(set(x,'string',y)),getappdata(h,'hDataT'),datStr); 
cellfun(@(x,y)(set(x,'string',y)),getappdata(h,'hTotT'),totStr); 
            
% sets the population status colours            
if (isC2A)            
    % sets the channel to apparatus index connections (based on type)
    iChC = rtD.rtP.Stim.C2A;
    
    % updates the stimlation statistic fields
    iCh = find(~isnan(iChC))';
    hStatT = getappdata(h,'hStatT');
    [statStr,statCol] = getTrackingStatus(rtD,iCh);            
    cellfun(@(x,y,z)(set(x,'string',y,'foregroundcolor',z)),...
                hStatT(3:4,iChC(iCh)),statStr,statCol);             
end
    
% updates the tracking duration string (if required)
if (getappdata(h,'isTrack'))
    [~,~,tS] = calcTimeDifference(roundP(rtD.T(rtD.ind)));
    tStrNw = sprintf('%s:%s:%s:%s',tS{1},tS{2},tS{3},tS{4});
    set(getappdata(h,'hTime'),'string',tStrNw)
end

% ------------------------------------------- %
% --- TRACKING GUI TRACKING FIGURE UPDATE --- %
% ------------------------------------------- %
            
% updates the real-time tracking plot
updateRTTrackPlot(h,rtD,gType)
            
% --- retrieves the status of the stimuli channel
function [statStr,statCol] = getTrackingStatus(rtD,iCh)

% memory allocation
nCh = length(iCh);
[statStr,statCol] = deal(cell(2,nCh));

% loops through all of the channels determining the channel statuses
for i = 1:nCh
    dT = (rtD.T(rtD.ind)-rtD.Tofs);
    if (dT <= rtD.rtP.Stim.Twarm)
        % the apparatus is stimulating
        nwTime = sprintf('%i s',roundP(rtD.rtP.Stim.Twarm-dT));
        statStr(:,i) = {nwTime;'Warm-Up Phase'};
        statCol(:,i) = repmat({[1 0 1]},2,1); 
    elseif (any(rtD.sStatus(iCh(i),2) == 1))
        % the apparatus is stimulating
        statStr(:,i) = {'***';'Stimulating'};
        statCol(:,i) = repmat({'r'},2,1);
    elseif (rtD.Tcool(iCh(i)) > 0)
        % the apparatus is cooling down
        nwTime = sprintf('%i s',roundP(rtD.Tcool(iCh(i)),1));
        statStr(:,i) = {nwTime;'Cooling Down'};
        statCol(:,i) = repmat({'b'},2,1);        
    else
        % otherwise, the apparatus is in normal state
        statStr(:,i) = {'***';'Device Ready'};
        statCol(:,i) = repmat({'k'},2,1);                   
    end
end

% ----------------------------------------------------------------------- %
%                               OTHER CODE                                %
% ----------------------------------------------------------------------- %
             
% --- determines if any of the stimulation criteria has been met
function [rtD,checkStim] = detStimCriteria(iMov,rtD,h)

% --------------------------------------------- %
% --- INITIALISATIONS AND MEMORY ALLOCATION --- %
% --------------------------------------------- %

% sets the stimulus parameter sub-struct
[uFunc,checkStim] = deal(getappdata(h,'uFunc'),false);
[Stim,ind] = deal(rtD.rtP.Stim,rtD.ind);

% determines which type of connection is being used
if (rtD.T(ind) < Stim.Twarm)
    % if still in the warm-up phase, then exit the function
    return
else
    % otherwise, check the channels have been set
    switch (Stim.cType)
        case ('Ch2App') % case is connecting channel to apparatus
            % check which channels have been set
            iCh = find(~isnan(Stim.C2A));
            if (isempty(iCh))        
                % if no channels are set, then exit the function
                return
            else
                % otherwise, set the channel parameters/indices
                [isC2A,popSC] = deal(true,rtD.rtP.popSC);
                iApp = Stim.C2A(iCh);
            end
        case ('Ch2Tube') % case is connecting channel to individual tube 
            % check which channels have been set
            iCh = find(all(~isnan(Stim.C2T),2));
            if (isempty(iCh))      
                % if no channels are set, then exit the function
                return
            else
                % otherwise, set the channel parameters/indices
                [isC2A,indSC] = deal(false,rtD.rtP.indSC);      
                [iApp,iFly] = deal(Stim.C2T(iCh,1),Stim.C2T(iCh,2));
            end            
    end
end
    
% ----------------------------------------------- %
% --- STIMULI CRITERIA CONDITION CALCULATIONS --- %
% ----------------------------------------------- %

% array indexing and other initialisations
checkStim = true;
[isCont,isAll] = deal(strcmp(Stim.sType,'Cont'),strcmp(Stim.bType,'All'));

% determines if the stimuli criteria conditions have been met
if (isC2A)
    % --------------------------------------------- %
    % --- CHANNEL-TO-APPARATUS STIMULI CRITERIA --- %
    % --------------------------------------------- %
    
    % determines the indices of the metrics to be found 
    mInd = find([popSC.isPtol,popSC.isMtol,popSC.isVtol]);
    
    % loops through each apparatus determining if the conditions are met
    for i = 1:length(iCh)
        % only check the criteria if either running continuous stimulation
        % or (if running single stimulation) if the device is open
        if ((isCont) || all(rtD.sStatus(iCh(i),:) == 0)) && (rtD.Tcool(i) == 0)
            cMet = false(length(mInd),1);
            for j = 1:length(mInd)
                switch (mInd(j))
                    case (1) % case is population inactivity                           
                        cMet(j) = rtD.pInact(ind,iApp(i)) > popSC.Ptol;                                                
                    case (2) % case is mean inactivity duration
                        cMet(j) = rtD.muInactT(ind,iApp(i)) > popSC.Mtol;
                    case (3) % case is mean/median population speed
                        cMet(j) = rtD.VP(ind,iApp(i)) < popSC.Vtol;                        
                end
            end
            
            % checks to see if the stimulation criteria is met
            hInd = {iApp(i),mInd};
            if (isAll)
                % all criteria must be met for stimulation
                rtD.sStatus(iCh(i),1) = double(all(cMet));
                                
                % if a new stimuli event has occured, then store the info
                if (isequal(rtD.sStatus(iCh(i),:),[1 0]))
                    sNw = {rtD.T(rtD.ind),NaN,{mInd}};
                    rtD.sData{iCh(i)} = [rtD.sData{iCh(i)};sNw];                     
                end 
                
                % updates the status colours                
%                 uFunc(h,'hTotE',hInd,rtD.sStatus(iCh(i),1)); 
                uFunc(h,'hTotE',hInd,double(cMet));
            else
                % any criteria must be met for stimulation
                rtD.sStatus(iCh(i),1) = double(any(cMet));
                
                % if a new stimuli event has occured, then store the info
                if (isequal(rtD.sStatus(iCh(i),:),[1 0]))
                    sNw = {rtD.T(rtD.ind),NaN,{mInd(cMet)}};
                    rtD.sData{iCh(i)} = [rtD.sData{iCh(i)};sNw];
                end                 
                
                % updates the status colours
                uFunc(h,'hTotE',hInd,double(cMet));                 
            end                       
        end
    end
else
    % ---------------------------------------- %
    % --- CHANNEL-TO-TUBE STIMULI CRITERIA --- %
    % ---------------------------------------- %
    
    % determines the indices of the metrics to be found 
    mInd = find([indSC.isTmove,indSC.isExLoc]);  
    
    % loops through each apparatus determining if the conditions are met
    for i = 1:length(iCh)
        % only check the criteria if either running continuous stimulation
        % or (if running single stimulation) if the device is open
        if ((isCont) || all(rtD.sStatus(iCh(i),:) == 0)) && (rtD.Tcool(i) == 0)
            cMet = false(length(mInd),1);
            for j = 1:length(mInd)
                switch (mInd(j))
                    case (1) % case is maximum inactivity duration
                        cMet(j) = rtD.Told(iFly(i),iApp(i)) > indSC.Tmove;
                    case (2) % case is experiment region location
                        sInd = [iApp(i),iFly(i)];
                        Pnw = rtD.P{iFly(i),iApp(i)}(ind,:);
                        cMet(j) = exptLocCond(rtD,iMov,indSC.ExLoc,Pnw,sInd);
                end
            end
            
            % checks to see if the stimulation criteria is met
            if (isAll)
                % all criteria must be met for stimulation
                rtD.sStatus(iCh(i),1) = double(all(cMet));
                                
                % if a new stimuli event has occured, then store the info
                if (isequal(rtD.sStatus(iCh(i),:),[1 0]))
                    sNw = {rtD.T(rtD.ind),{mInd}};
                    rtD.sData{iCh(i)} = [rtD.sData{iCh(i)};sNw]; 
                end 
            else
                % any criteria must be met for stimulation
                rtD.sStatus(iCh(i),1) = double(any(cMet));
                
                % if a new stimuli event has occured, then store the info
                if (isequal(rtD.sStatus(iCh(i),:),[1 0]))
                    sNw = {rtD.T(rtD.ind),{mInd(cMet)}};
                    rtD.sData{iCh(i)} = [rtD.sData{iCh(i)};sNw];
                end                 
            end    
            
            % updates the status colours
            uFunc(h,'hDataE',{iApp(i),iFly(i)},rtD.sStatus(iCh(i),1));                        
        end
    end  
end

% --- determines if the experimental location condition has been met
function cMet = exptLocCond(rtD,iMov,ExLoc,Pnw,sInd)

% global variables
global is2D

% determines if the position type is in mm
[isMM,pRef] = deal(strcmp(ExLoc.pType,'mm'),{'Right Edge','Edge'});
 
% case is a 2D experimental arena
[X,L] = retRelFlyPosition(Pnw,iMov,sInd,rtD.rtP.trkP.sFac,is2D);  
if (strcmp(ExLoc.pRef,pRef{1+is2D}))
    % case is checking if the fly is on the edge
    if (isMM)
        % case is distance tolerance is in mm
        cMet = (L-X) < ExLoc.pX(1);
    else
        % case is distance tolerance is proportional
        cMet = (L-X)/L < ExLoc.pX(2);
    end
else
    % case is checking if the fly is in the centre
    if (isMM)
        % case is distance tolerance is in mm
        cMet = X < ExLoc.pX(1);
    else
        % case is distance tolerance is proportional
        cMet = X/L < ExLoc.pX(2);
    end        
end

% --- retrieves the individual/total metrics and status colours for the
%     current frame
function [datStr,totStr,rtD] = getTrackingProps(iMov,rtD,h,dType)

% global variables
global tFrmMn is2D

% parameters and array indexing
[nFly,nApp] = size(rtD.P);
nGrp = size(rtD.rtP.combG.iGrp,1);
[rtP,mFunc] = deal(rtD.rtP,rtD.rtP.trkP.pvFcn);
nTot = max(cellfun(@(x)(x(1)),get(findobj(h,'tag','hTotT'),'UserData')));

% memory allocation
[datStr,totStr] = deal(cell(nFly,nApp),cell(nTot,nGrp));

% ------------------------------------- %
% --- INDIVIDUAL DATA FIELD STRINGS --- %
% ------------------------------------- %

% loops through all of the apparatus calculating the new tracking metrics
for i = 1:nApp
    % sets the data fields based on the number of viable fields
    if (rtD.ind <= tFrmMn)
        % number of data points less than minimum, so return empty fields
        datStr(:,i) = repmat({'***'},nFly,1);
    else
        % retrieves the instantaneous inactivity flags
        [isInact,fok] = deal((rtD.Told(:,i) > 0),rtD.fok(:,i));
                    
        % depending on the data type being shown in the table fields, set
        % the data strings and colours
        switch (dType)
            case ('menuTotalDisp') % case the total displacement 
                datStr(:,i) = getStatusProps(rtD,i);    
            case ('menuInstantInact') % case is instantaneous inactivity 
                datStr(~isInact,i) = {'Active'};
                datStr(isInact,i) = {'Inactive'};
            case ('menuInactiveTime') % case is the overall inactivity time
                datStr(:,i) = cellfun(@(x)(sprintf('%i',x)),num2cell(...
                            roundP(rtD.Told(:,i),1)),'un',0);
            case ('menuFlyPos1') % case is the position from left/centre                 
                P = cellfun(@(x,y)(retRelFlyPosition(x(rtD.ind,:),...
                        iMov,[i,y],rtP.trkP.sFac,is2D)),rtD.P(:,i),...
                        num2cell(1:nFly)','un',0);
                datStr(:,i) = cellfun(@(x)(sprintf('%.2f',...
                            roundP(x(1),0.01))),P,'un',0);
            case ('menuFlyPos2') % case is the position from right/edge
                P = cellfun(@(x,y)(retRelFlyPosition(x(rtD.ind,:),...
                        iMov,[i,y],rtP.trkP.sFac,is2D)),rtD.P(:,i),...
                        num2cell(1:nFly)','un',0);
                datStr(:,i) = cellfun(@(x)(sprintf('%.2f',...
                            roundP(x(2)-x(1),0.01))),P,'un',0);
            case ('menuStimCount') % case is stimulation count
                % determines the number of stimulations for each channel
                % that is connected to the current sub-region
                iC2T = find(rtP.Stim.C2T(:,1) == i);                
                nStim = cellfun(@(x)(size(x,1)),rtD.sData(iC2T),'un',0);
                
                % sets the string values
                datStr(:,i) = {'***'};
                datStr(rtP.Stim.C2T(iC2T,2),i) = nStim;
        end

        % removes any groups that are not feasible
        datStr(~fok,i) = {'***'};                                
    end
end

% ------------------------------------- %
% --- POPULATION DATA FIELD STRINGS --- %
% ------------------------------------- %

% loops through all of the apparatus calculating the new tracking metrics
for i = 1:nGrp
    % sets the data fields based on the number of viable fields
    if (rtD.ind <= tFrmMn)
        % number of data points less than minimum, so return empty fields
        totStr(:,i) = repmat({'***'},nTot,1);          
    else
        % calculates the overall metrics for the apparatus
        for j = 1:nTot                          
            % updates the total fields based on the metric type
            switch (j)
                case (1) % case is proportion of inactive flies
                    Y = rtD.pInact(rtD.ind,i)*100;
                    totStr(j,i) = cellfun(@(x)(sprintf('%i %s',x,char(37))),...
                                    num2cell(roundP(Y)),'un',0);
                case (2) % case is inactivity duration
                    Y = rtD.muInactT(rtD.ind,i);
                    totStr(j,i) = cellfun(@(x)(sprintf('%i s',x)),...
                                    num2cell(roundP(Y)),'un',0);                                
                case (3)
                    Y = rtD.VP(rtD.ind,i);
                    totStr(j,i) = cellfun(@(x)(sprintf('%.2f mm/s',x)),...
                                    num2cell(Y),'un',0);                
            end
        end        
    end
end
    
% --- calculates the flies displacement over the last nFrameMin frames
function datStr = getStatusProps(rtD,iApp)

% calculates the average velocity over the time gap
V = rtD.VI{iApp}(rtD.ind,:); 
datStr = cellfun(@(x)(sprintf('%.2f',x)),num2cell(V),'un',0);   

% --- retrieves the position of the flies
function [X,L] = retRelFlyPosition(Pnw,iMov,sInd,sFac,is2D)

% calculates the relative fly position 
if (is2D)
    % case is a 2D experimental arena        
    x0 = iMov.autoP.X(sInd(2),sInd(1));
    y0 = iMov.autoP.Y(sInd(2),sInd(1));

    % calculates the distance from the circle centre        
    X = sqrt((Pnw(1)-x0)^2 + (Pnw(2)-y0)^2)*sFac;   
    L = iMov.autoP.R*sFac;
else
    % case is a 1D experimental arena
    X = (Pnw(1)-(iMov.iCT{sInd(1)}(1)-1))*sFac;
    L = length(iMov.iCT{sInd(1)})*sFac;
end

% if only one output, then combine the data into one array
if (nargout == 1); X = [X,L]; end