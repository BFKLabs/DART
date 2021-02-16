% --- retrieves the sleep-intensity data from the solution file, snTot -- %
function [Ycount,YcountR,Xbin,Ybin,ok] = getStimuliResponseData(snTot,cP,h,wOfs)

% sets the default parameters
ok = true;
if nargin < 4; wOfs = 0; end
if nargin < 3
    h = ProgBar({'Initialising'},'Retrieving Sleep Intensity Data');
end

% retrieves the group/bin number count
if isfield(cP,'nBin')
    % flag is set as "nBin"
    nBin = str2double(cP.nBin);
    
elseif isfield(cP,'nGrp')
    % flag is set as "nGrp"
    nBin = str2double(cP.nGrp);
    
else
    % bin parameter has not been set, so exit the function
    ok = false;
    eStr = 'Error! Must set nBin or nGrp as calculation parameters.';
    waitfor(errordlg(eStr,'Missing Parameter Error','modal')); 
    [Ycount,YcountR,Ybin] = deal([]);
    return    
end

% intialisations
nApp = length(snTot.appPara.flyok);
[nGrp,T0] = deal(60/nBin,[0 snTot.iExpt(1).Timing.T0(4:end)]);
xiG = num2cell(1:nGrp)';

% sets the stimuli times
Ts = cell2mat(snTot.Ts);
if isempty(Ts)
    % if there are no recorded stimuli events, then output an error    
    if wOfs == 0
        eStr = ['Error! This experiment contains no recorded ',...
                'stimuli events.'];
        waitfor(errordlg(eStr,'Invalid Experiment Type','modal'))    
    end
    
    % exits the function
    return
    
else
    % array dimensioning and memory allocation
    [Ttot,Ts] = deal(cell2mat(snTot.T),num2cell(sort(Ts)));
    flyok = snTot.appPara.flyok;    
end                             

% determines the indices, within the total time array, that the stimuli
% events took place and uses these to determine the effective time bands
h.Update(1+wOfs,'Determining Time Bin Indices...',1/(2+nApp));
iTs = cellfun(@(x)(find(Ttot<x,1,'last')),Ts,'un',0);

% resets the stimuli event/after times to account to remove any of the
% empty index cells
if nargout > 2  
    % if outputting the signals as well, then determine the end indices of
    % the after signal period
    if ~isfield(cP,'tBefore') && ~isfield(cP,'tAfter')
        % if the time before/after field is not set in parameter struct,
        % then exit with an error
        eStr = ['Error! For stimuli response, you must include the ',...
                'tBefore or tAfter variables.'];
        waitfor(errordlg(eStr,'Missing Parameter Error','modal'));        
        [Ycount,YcountR,Ybin] = deal([]);
        return
        
    elseif ~isfield(cP,'tBefore')
        [iTa1,nSig] = deal(iTs,cP.tAfter*60);
        iTa2 = cellfun(@(x)(find(Ttot<(x+cP.tAfter*60),1,'last')),Ts,'un',0);  
        
    elseif ~isfield(cP,'tAfter')
        [iTa2,nSig] = deal(iTs,cP.tBefore*60);
        iTa1 = cellfun(@(x)(find...
                (Ttot>(x-(cP.tBefore*60+cP.nAvg+1)),1,'first')),Ts,'un',0);
        
    else
        iTa1 = cellfun(@(x)(find...
                (Ttot>(x-(cP.tBefore*60+cP.nAvg+1)),1,'first')),Ts,'un',0);
        iTa2 = cellfun(@(x)(find...
                (Ttot<(x+cP.tAfter*60),1,'last')),Ts,'un',0);
        nSig = (cP.tBefore + cP.tAfter)*60 + (cP.nAvg + 1);
    end
    
    % sets the time before/time         
    ii = ~cellfun(@isempty,iTs) & ...
         ~cellfun(@isempty,iTa1) & ...
         ~cellfun(@isempty,iTa2);    
    
    % sets the indices of the after stimuli signal points and also set the
    % time signal values
    iTs = cell2mat(iTs(ii));
    [iTa1,iTa2] = deal(cell2mat(iTa1(ii)),cell2mat(iTa2(ii)));
    indS = num2cell([iTa1,iTa2],2);
    Tsig = cellfun(@(x)(max(0,...
                roundP(Ttot(x(1):x(2))-Ttot(x(1))))),indS,'un',0);
    
else
    % otherwise, determine if any of the groups are empty and remove them
    ii = ~cellfun(@isempty,iTs);
    iTs = cell2mat(iTs(ii));
end
    
% sets the index band array
indB = num2cell([[1;(iTs(1:end-1)+1)],iTs],2);
indG = detTimeGroupIndices(Ttot(iTs),[0 0 T0],1+cP.sepDN,cP.Tgrp0,true);
nDay = size(indG, 1);

% memory allocation
A = cellfun(@(x)(repmat...
                ({zeros(1+cP.sepDN,nGrp)},nDay,length(x))),flyok,'un',0);
[Ycount,YcountR] = deal(A);

% sets the x/y bin arrays
B = repmat({repmat({cell(nGrp,1)},nDay,1+cP.sepDN)},nApp,1);
if isempty(snTot.Px); Xbin = []; else; Xbin = B; end
if isempty(snTot.Py); Ybin = []; else; Ybin = B; end

% calculates the metrics for all apparatus
for i = 1:nApp
    % updates the waitbar figure
    wStrNw = sprintf('Setting Binned Signals (Region %i of %i)',i,nApp);
    if h.Update(1+wOfs,wStrNw,0.5*(1+wOfs)*(i+1)/(2+nApp))
        % if the user cancelled, then exit the function
        ok = false;
        [Ycount,YcountR,Ybin] = deal([]);
        return
    end         
        
    % initialisations
    [Px,Py] = deal([]);
    iFly = find(flyok{i});
    
    % only calculate if values exist...
    if ~isempty(snTot.Px); Px = snTot.Px{i}(:,flyok{i}); end
    if ~isempty(snTot.Py); Py = snTot.Py{i}(:,flyok{i}); end
    
    % calculates the pre-stimuli immobility times over all flies for each
    % of the stimuli events
    [tImmob,isReact] = calcFlyImmobilityTimes(Ttot,Px,Py,Ts,cP,indB);      

    % groups the immobile time/reaction flags
    if ~isempty(tImmob)
        tImmobG = cellfun(@(x)(tImmob(x,:)),indG,'un',0);
        isReactG = cellfun(@(x)(isReact(x,:)),indG,'un',0);

        %        
        iBinT = cellfun(@(x)(ceil(x/nBin)),tImmobG,'un',0);               
        iBinTC = cellfun(@(y)(cell2mat(cellfun(@(x)(...
                                sum(y==x,1)),xiG,'un',0))),iBinT,'un',0);

        % sets the bin indices
        iBinR = cellfun(@(x,y)(x.*y),iBinT,isReactG,'un',0);                            
        iBinTR = cellfun(@(y)(cell2mat(cellfun(@(x)(...
                                sum(y==x,1)),xiG,'un',0))),iBinR,'un',0);        

        % sorts the stimuli events into their time groups 
        for iDay = 1:nDay
            for k = 1:size(indG,2)                                       
                for j = 1:length(iFly)
                    Ycount{i}{iDay,iFly(j)}(k,:) = iBinTC{iDay,k}(:,j)';
                    YcountR{i}{iDay,iFly(j)}(k,:) = iBinTR{iDay,k}(:,j)';
                end                                 
            end            
        end    

        % retrieves the signals and bins them into the time groups
        if nargout > 2
            % determines the indices
            [Xnw,Ynw,iYnw,iRnw] = deal(cell(length(indB),1));
            for j = 1:length(indB)
                jj = tImmob(j,:) > 0;
                if (any(jj))
                    indSnw = indS{j}(1):indS{j}(2);
                    iYnw{j} = ceil(tImmob(j,jj)/nBin);
                    iRnw{j} = double(isReact(j,jj));                

                    % calculates the binned x-values (if they are present)
                    if ~isempty(Px)
                        Xnw{j} = setBinnedSignals(...
                                            Px(indSnw,jj),Tsig{j},nSig);
                    end

                    % calculates the binned y-values (if they are present)
                    if ~isempty(Py)
                        Ynw{j} = setBinnedSignals(...
                                            Py(indSnw,jj),Tsig{j},nSig);
                    end                
                end
            end

            % sets the x-values (if they present)
            if ~isempty(Px)
                XbinT = cellfun(@(x)(cell2mat(Xnw(x)')),indG,'un',0);
            end

            % sets the y-values (if they present)
            if (~isempty(Py))
                YbinT = cellfun(@(x)(cell2mat(Ynw(x)')),indG,'un',0);
            end        

            % sets the inactivity time bin and the reaction flags        
            iYnwT = cellfun(@(x)(cell2mat(iYnw(x)')),indG,'un',0);
            iRnwT = cellfun(@(x)(logical(cell2mat(iRnw(x)'))),indG,'un',0);

            % sets the x/y-values into each time bin over all days
            for j = 1:numel(iYnwT)
                % determines the traces that belong to each time bin
                if (~isempty(iYnwT{j}))
                    ii = cellfun(@(x)(find(iYnwT{j} == x)),xiG,'un',0);

                    % separates the x-values into each time bin (if present)
                    if ~isempty(Px)
                        if cP.moveOnly               
                            Xbin{i}{j} = cellfun(@(x)...
                                (XbinT{j}(:,x(iRnwT{j}(:,x)))),ii,'un',0); 
                        else
                            Xbin{i}{j} = cellfun(@(x)...
                                (XbinT{j}(:,x)),ii,'un',0);
                        end                
                    end            

                    % separates the y-values into each time bin (if present)
                    if (~isempty(Py))
                        if (cP.moveOnly)                
                            Ybin{i}{j} = cellfun(@(x)...
                                (YbinT{j}(:,x(iRnwT{j}(:,x)))),ii,'un',0); 
                        else
                            Ybin{i}{j} = cellfun(@(x)...
                                (YbinT{j}(:,x)),ii,'un',0);
                        end                
                    end
                end
            end

            % clears the extraneous variables
            clear Ynw XbinT YbinT iYnwT iRnwT;
        end                                    
    end
end

% closes the waitbar (if created in the function)
if nargin < 3
    h.closeProgBar()
else
    h.Update(1+wOfs,'Time Binning Signals Complete!',1);
end