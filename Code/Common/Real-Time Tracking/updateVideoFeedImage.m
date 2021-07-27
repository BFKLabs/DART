% --- the experiment timer callback function       
function varargout = updateVideoFeedImage(hGUI,objIMAQ,ImgNw,rtPos)

% global variables
global vFrm tLastFeed tFrmMn sFin sStart objDRT

% parameters
[pOKMin,okTestFrm] = deal(0.60,50);
[titleStr,tFrmMn] = deal('Real-Time Tracking Statistics',1);
[iStim,handles] = deal(getappdata(hGUI,'iStim'),guidata(hGUI));
[iMov,isTest] = deal(getappdata(hGUI,'iMov'),getappdata(hGUI,'isTest'));
dispImage = getappdata(hGUI,'dispImage');

% sets the new image frame (if not provided)
if nargin == 2
    % retrieves the frames from the image stack/camera
    if isTest
        % retrieves the video frame from the image stack 
        iData = getappdata(hGUI,'iData');
        ImgNw = getDispImage(iData,iMov,vFrm,false,handles);          
        if isempty(iMov); iMov.Ibg = []; end
    else
        % retrieves the video object and reads a single frame
        infoObj = getappdata(hGUI,'infoObj');
        objIMAQ = infoObj.objIMAQ;
        ImgNw = getsnapshot(objIMAQ);
    end
end

% sets the display image to be the frame that was read from file/camera
[ImgDisp,hGUIH] = deal(ImgNw,guidata(hGUI));
if strcmp(get(hGUI,'tag'),'figFlyTrack')
    % if calibrating through the fly track GUI, check to see if the local
    % image flag has been set. if so, then set the display image to be the
    % sub-image
    if get(hGUIH.checkLocalView,'value')
        ImgDisp = setSubImage(handles,ImgNw);
    end    
    
    % sets the new frame into the fly tracking GUI
    setappdata(hGUI,'ImgVid',ImgNw)    
end

% retrieves the position data struct and calculate the new fly
% locations from the current frame
hTrack = getappdata(hGUI,'hTrack');
if ~isempty(hTrack)
    % ------------------------------------------- %
    % --- INITIALISATIONS & MEMORY ALLOCATION --- %
    % ------------------------------------------- %        
    
    % retrieves the update function
    uFunc = getappdata(hTrack,'uFunc');
    isDAC = getappdata(hTrack,'isDAC');              
    
    % retrieves the parameter structs
    [rtD,rtP] = deal(getappdata(hGUI,'rtD'),getappdata(hGUI,'rtP'));           
    
    % appends the new fly positions to the data struct       
    nFlyR = getSRCountVec(iMov);
    [nMax,nApp] = deal(size(rtD.P{1,1},1),length(iMov.iR)); 
    [mFunc,jj] = deal(rtP.trkP.pvFcn,2:nMax);

    % updates the time counter
    tNewFeed = toc;
    dT = max(0,tNewFeed - tLastFeed); 
    tLastFeed = tNewFeed;        

    % ---------------------------------------- %
    % --- MOVEMENT STATISTICS CALCULATIONS --- %
    % ---------------------------------------- %    

    % sets the new time stamp for the current frame
    if all(isnan(rtD.T))
        % if the first time point, then set to the feed time
        [rtD.T(1),rtD.Tofs] = deal(tNewFeed);        
    else
        % otherwise, determined the last valid value
        iTime = find(~isnan(rtD.T),1,'last');
        if iTime == nMax
            % if buffer full, then add new point to the end
            rtD.T = [rtD.T(2:end);(rtD.T(end)+dT)];
        else
            % otherwise, set into the array
            rtD.T(iTime+1) = rtD.T(iTime) + dT;
        end
    end        
        
    % ------------------------------------- %
    % --- NEW FLY LOCATION CALCULATIONS --- %
    % ------------------------------------- %        

    % sets the previous fly locations
    p0 = cell(1,nApp);       
    for iApp = 1:nApp
        % determines the current valid index
        p0{iApp} = cell(getSRCount(iMov,iApp),1);
        if iMov.ok(iApp)
            % determines the regions where the flies have not moved
            ii = ~cellfun(@isempty,iMov.IbgE(1:nFlyR(iApp),iApp)) & ...
                  cellfun(@(x)(~isnan(x(1))),...
                  field2cell(iMov.pStats{iApp},'fxPos'));
            if any(ii)
                % sets the points where the fly has not moved
                p0{iApp}(ii) = cellfun(@(x)(x.fxPos(1,2:3)),...
                    num2cell(iMov.pStats{iApp}(ii)),'un',0);
            end

            %
            if (rtD.ind > 0) && any(~ii)
                % determines the last valid position index. retrieves
                % their values and set it into the positional array                       
                [xOfs,zOfs] = deal(iMov.iC{iApp}(1)-1,iMov.iR{iApp}(1)-1);                
                yOfs = cellfun(@(x)(x(1)-1),iMov.iRT{iApp}(~ii),'un',0);

                % offsets the previous coordinates to the local frame ref
                [iNw,Pnw] = deal(rtD.ind,rtD.P(~ii,iApp));
                p0{iApp}(~ii) = cellfun(@(x,y)(x(iNw,:) - ...
                            [xOfs,y+zOfs]),Pnw,yOfs,'un',0);

                % removes any rejected flies from the positional array
                p0{iApp}(~iMov.flyok(:,iApp)) = {[]};                    
            end
        end
    end

    % calculates the new fly positions
    [fPosNew,iMov,isChange] = calcSingleFramePos(iMov,ImgNw,p0);          

    % if there was a change in the background, then 
    if isChange; setappdata(hGUI,'iMov',iMov); end
        
    % --------------------------------------- %
    % --- MOVEMENT STATISTIC CALCULATIONS --- %
    % --------------------------------------- %

    % initialisations
    rtD.ind = min(rtD.ind+1,nMax);
    ii = max(1,rtD.ind-(rtP.trkP.nSpan+1)):rtD.ind;

    % updates the real-time tracking experiment struct (if available)
    if nargin == 4
        if ~isempty(rtPos)
            varargout{1} = updateRTExptStruct(rtPos,fPosNew,rtD.T(rtD.ind));
        end
    end    
    
    % for all the apparatus, calculate the new movement statistics          
    for iApp = find(iMov.ok(:)')
        % updates the index values and fly metric arrays  
        kApp = any(rtP.combG.iGrp == iApp,2);
        if (rtD.ind == nMax) && ~isnan(rtD.VP(nMax,kApp))
            % shifts the positional arrays
            for iFly = 1:nFlyR(iApp)
                rtD.P{iFly,iApp}(jj-1,:) = rtD.P{iFly,iApp}(jj,:);
            end                                  

            % updates the other numerical arrays                                              
            rtD.VI{iApp}(jj-1,:) = rtD.VI{iApp}(jj,:);
        end
        
        % sets the locations of the new fly positions
        for i = 1:nFlyR(iApp)
            rtD.P{i,iApp}(rtD.ind,:) = fPosNew{iApp}(i,:);
        end

        % calculates the individual avg speed (if sufficient points)
        if rtD.ind > tFrmMn                              
            % calculates the sequence mean speed for each object 
            Tnw = rtD.T(ii)-rtD.T(ii(1));
            rtD.VI{iApp}(rtD.ind,:) = ...
                    rtP.trkP.sFac*calcSeqSpeed(rtD.P(:,iApp),ii,diff(Tnw));    
        end                                        

        % updates the inactivity times/locations
        if rtD.ind > 1               
            % only calculate if the new frame is feasible              
            isInact = rtD.VI{iApp}(rtD.ind,:) < rtP.trkP.Vmove;

            % inactive flies have their inactive times incremented, and
            % the active flies have their times reset to zero. the
            % active flies also have their old location reset to their
            % current location
            rtD.Told(isInact,iApp) = rtD.Told(isInact,iApp) + dT;
            rtD.Told(~isInact,iApp) = 0;                   
        end
    end
       
    % calculates the population metrics (for the each grouping)
    for iGrp = 1:size(rtP.combG.iGrp,1)
        % updates the index values and fly metric arrays     
        if (rtD.ind == nMax) && ~isnan(rtD.VP(nMax,iGrp))
            rtD.VP(jj-1,iGrp) = rtD.VP(jj,iGrp);  
            rtD.pInact(jj-1,iGrp) = rtD.pInact(jj,iGrp);
            rtD.muInactT(jj-1,iGrp) = rtD.muInactT(jj,iGrp);                               
        end        
        
        % sets the acceptance/rejection flags for the current group
        jGrp = rtP.combG.iGrp(iGrp,1:rtP.combG.nGrp(iGrp));
        fok = iMov.flyok(:,jGrp);
        
        % calculates the average speed (if there are sufficient points)
        if rtD.ind > tFrmMn         
            % calculates the population speed
            VI = cell2mat(cellfun(@(x)(x(rtD.ind,:)),rtD.VI(jGrp),'un',0));
            rtD.VP(rtD.ind,iGrp) = mFunc(VI(fok(:)));                                                     
        end
            
        % calculates the mean/proportional inactivity 
        if rtD.ind > 1
            Told = rtD.Told(:,jGrp);
            rtD.muInactT(rtD.ind,iGrp) = mFunc(Told(fok));    
            rtD.pInact(rtD.ind,iGrp) = mean(Told(fok)>0);                    
        end
    end

    % ---------------------------------- %
    % --- GRAPH/TRACKING GUI UPDATES --- %
    % ---------------------------------- %

    % sets the fly locations into the GUI
    setappdata(hGUI,'fPosNew',fPosNew);      

    % updates the tracking property fields   
    try
        hTrackH = guidata(hTrack);    
        if isTest
            set(hTrack,'name',sprintf('%s (Frame %i)',titleStr,vFrm));
        end
    catch
        return
    end             
    
    % decrements the cool-down timer (only for channel to tube)
    if ~isempty(rtD.Tcool)
        % determines if any of the stimuli devices finished running. if
        % so then update their details within the real-time data struct
        if ~isempty(sFin)
            iDev = find(sFin(:,1) == 1);
            if ~isempty(iDev)
                for i = reshape(iDev,1,length(iDev))
                    % adds the new data to the stimuli data fields
                    rtD.sData{i}{end,2} = sFin(i,2);
                    rtD.sStatus(i,:) = [0,2];
                    rtD.Tcool(i) = rtP.Stim.Tcd;

                    % resets the array
                    sFin(i,:) = [0 0];
                end
            end
        end

        % ensures the cool-down period has a minimum value of 0
        isC2A = getappdata(hTrack,'isC2A');
        rtD.Tcool = max(0,rtD.Tcool-dT);

        % determines which channels are still "cooling down"
        ii = rtD.Tcool > 0;
        if any(ii)
            % update the status flags to being cooling down
            rtD.sStatus(ii,2) = 2;                    

            % updates the status colours (based on type)
            if isC2A
                % case is population activity
                popSC = rtP.popSC;
                mInd = find([popSC.isPtol,popSC.isMtol,popSC.isVtol]);
                
                % updates the status colours
                iC2A = num2cell(rtP.Stim.C2A(ii));
                cellfun(@(x)(uFunc(hTrack,'hTotE',{x,mInd},2)),iC2A)                                        
            else
                % case is individual activity
                iC2T = num2cell(rtP.Stim.C2T(ii,:),2);
                cellfun(@(x)(uFunc(hTrack,'hDataE',num2cell(x),2)),iC2T)                    
            end
        end

        % determines which channels were previously "cooling down"
        % but are now open 
        jj = (~ii == (rtD.sStatus(:,2) == 2));
        if any(jj)
            % resets the status flags to being open
            rtD.sStatus(jj,2) = 0;       

            % updates the status colours
            if isC2A
                [iC2A,popSC] = deal(num2cell(rtP.Stim.C2A(jj,:),2),rtP.popSC);
                mInd = find([popSC.isPtol,popSC.isMtol,popSC.isVtol]);
                cellfun(@(x)(uFunc(hTrack,'hTotE',{x,mInd},0)),iC2A)                                     
            else
                iC2T = num2cell(rtP.Stim.C2T(jj,:),2);
                cellfun(@(x)(uFunc(hTrack,'hDataE',num2cell(x),0)),iC2T)                     
            end
        end
    end        

    % -------------------------------------------- %
    % --- TRACKING GUI STATISTICS CALCULATIONS --- %
    % -------------------------------------------- %
    
    % updates the field properties (only for more than one time point)
    if rtD.ind > 1
        % updates the data properties (based on the selected metrics)
        hMenuD = getappdata(hTrack,'hMenuD');                                    
        hMenuDC = hMenuD{cellfun(@(x)(strcmp(get(x,'checked'),'on')),hMenuD)};

        % updates the graph properties (based on the selected metrics)            
        hMenuG = getappdata(hTrack,'hMenuG');
        hMenuGC = hMenuG{cellfun(@(x)(strcmp(get(x,'checked'),'on')),hMenuG)};

        % updates the tracking property fields    
        [rtD.rtP,rtD.iStim] = deal(rtP,iStim);
        [rtD,indS] = updateTrackingPropFields(iMov,rtD,...
                        hTrack,get(hMenuDC,'tag'),get(hMenuGC,'tag')); 
    else
        % returns an empy array
        indS = [];
    end            

    % ----------------------------- %
    % --- DAC TRIGGERING EVENTS --- %
    % ----------------------------- %            

    % determines if continuously stimulating
    if ~isempty(rtP.Stim)       
        isCont = strcmp(rtP.Stim.sType,'Cont');
        dInfo = getappdata(hGUI,'objDACInfo');
    else
        isCont = false;
    end

    % if running a running a full-test/experiment, then determine if a
    % DAC device needs to be triggered
    if ~isempty(indS)
        % parameters and other information    
        isC2A = getappdata(hTrack,'isC2A');
        ID = iStim.ID(indS,:);            
        yAmp = rtP.Stim.oPara.vMax;            
        
        % retrieves the object handles
        if ~isTest; hS = dInfo.Control; end
        
        % data retrieval and memory allocation            
        if isCont
            % applies a stimuli to the specified channels. update the
            % status flag to indicate that the channel is running                
            for i = 1:length(indS)         
                % flag that the channel output requires turning on
                rtD.sStatus(indS(i),2) = 1;  
                
                % stimulates the specified channel (not for testing)
                if ~isTest
                    if isDAC
                        % case is for a DAC device
                        iChG = find(iStim.ID(:,1) == ID(i,1));
                        updateStimChannels(hS{ID(i,1)},yAmp,1,rtD,iChG)                        
                    else
                        % case is for a serial controller
                        updateStimChannels(hS{ID(i,1)},yAmp,0,ID(i,2))
                    end
                end                  
            end

            % updates the tracking GUI fields (channel to app only)
            if isC2A; updateTrackingStimFields(hTrack,rtD,indS); end                
        else
            % if a single stimuli, then set up and run the devices                
            dT = diff(rtP.Stim.sFix.Tsig([1 2]));
            Ys = rtP.Stim.sFix.Ysig;            
            
            % sets up the run flags (DAC device only)
            if isDAC; isRun = false(length(objDRT),1); end
            
            % sets up the serial device for each stimuli event
            objS = cell(length(indS),1);
            for i = 1:length(objS)
                % updates the status of the device channel 
                rtD.sStatus(indS(i),2) = 1;                       
                if ~isTest
                    % sets up the channel properties for running
                    if isDAC
                        % case is for a DAC device                        
                        Ts = rtP.Stim.sFix.Tsig;
                        iChG = find(iStim.ID(:,1) == iStim.ID(indS(i),1));
                        chInd = [iStim.ID(indS(i),:),iChG(:)'];
                        objDRT{chInd(1)} = setupDACDeviceRT(hS,...
                                        objDRT{chInd(1)},hGUI,Ts,Ys,chInd); 
                        
                        % flag that this is the device to be run
                        isRun(chInd(1)) = true;
                    else
                        % case is for a serial controller
                        dInd = [indS(i),ID(i,:)];
                        objS{i} = setupSerialDevice(dInfo,'RTStim',hGUI,Ys,dT,dInd);
                    end
                else
                    % update the stimuli start time (test case only)
                    if sStart(indS(i)) == 0
                        sStart(indS(i)) = rtD.T(rtD.ind);
                    end
                end                                              
            end

            % runs each stimuli event (non-test only)
            if ~isTest
                if isDAC
                    % case is for a DAC device 
                    runTimedDevice(objDRT(isRun)); 
                else
                    % case is for a serial controller
                    runTimedDevice(objS); 
                end
            end

            % updates the tracking GUI fields (channel to app only)
            if isC2A; updateTrackingStimFields(hTrack,rtD,indS); end                
        end
    end

    % determines if any of the running channels need to be stopped
    if isCont
        % initialisations
        ID = iStim.ID;

        % determines if any of the running channels no longer need to
        % be stimulated. if this is the case, then stop the stimuli and
        % reset the status flag 
        if ~isTest; hS = dInfo.Control; end
        for i = 1:size(rtD.sStatus,1)
            if isequal(rtD.sStatus(i,:),[0 1])
                % resets the channels status
                rtD.sStatus(i,:) = [0,2];
                
                % turns off the channel
                if ~isTest
                    if isDAC
                        % case is a DAC device  
                        yAmp = rtP.Stim.oPara.vMax;
                        iChG = find(iStim.ID(:,1) == ID(i,1));
                        updateStimChannels(hS{ID(i,1)},yAmp,1,rtD,iChG)
                    else
                        % case is a serial device
                        updateStimChannels(hS{ID(i,1)},0,0,ID(i,2))
                    end
                end

                % updates the relevant fields                                    
                rtD.Tcool(i) = rtP.Stim.Tcd;
                rtD.sData{i}{end,2} = rtD.T(rtD.ind);
            end
        end
    else
        % determines if a device is "running" (for test conditions). if
        % the duration is sufficient, then "stop" the device
        ii = find(sStart > 0);
        if ~isempty(ii)
            for jj = reshape(ii,1,length(ii))
                if (rtD.T(rtD.ind) - sStart(jj)) > rtD.rtP.Stim.Tdur
                    sFin(jj,:) = [1,rtD.T(rtD.ind)];
                    [sStart(jj),rtD.Tcool(jj)] = deal(0,rtP.Stim.Tcd);
                end
            end
        end             
    end
    
    % updates the real-time tracking data struct
    setappdata(hGUI,'rtD',rtD);             
end

% rotates the image (if required)
if iMov.useRot && (iMov.rotPhi ~= 0)
    ImgDisp = imrotate(ImgDisp,iMov.rotPhi,'bilinear','crop');
end

% updates the image display
dispImage(handles,ImgDisp,1)  
    
% --- calculates the mean speed over a sequence
function V = calcSeqSpeed(P,ii,dT)

% retrieves the x/y-locations of the objects
X = cell2mat(cellfun(@(x)(x(ii,1)),P','un',0));
Y = cell2mat(cellfun(@(x)(x(ii,2)),P','un',0));

% calculates the mean speed of the sequence for each fly
V = nanmean(sqrt(diff(X,[],1).^2 + diff(Y,[],1).^2)./repmat(dT,1,size(X,2)),1);

% --- updates the stimuli data fields in the tracking GUI
function updateTrackingStimFields(hTrack,rtD,iCh)

% global variables
global tRTStart

% retrieves the current time
tNowStr = datestr(addtodate(tRTStart,roundP(rtD.T(rtD.ind)),'second'),14);
hStatT = getappdata(hTrack,'hStatT');

% updates the counter string                    
for i = 1:length(iCh)
    % updates the stimuli count
    j = rtD.rtP.Stim.C2A(iCh(i));
    set(hStatT{1,j},'string',tNowStr)
    set(hStatT{2,j},'string',num2str(size(rtD.sData{iCh(i)},1)));   
end

% % --- determines the feasibility of the new fly locations
% function [isOK,Dfly] = calcNewFlyFeasibility(P,indC,dXmax,d2Xmax)
% 
% % sets the max displacement/velocity change magnitudes (if not provided)
% if (nargin < 3)
%     [dXmax,d2Xmax] = deal(30,15);
% end
% 
% % calculate the relative x-displacement between the candidate frames
% dX = cell2mat(cellfun(@(x)(diff(x(indC,1))),P,'un',0)');
% if (size(dX,1) == 1)
%     [isOK,Dfly] = deal(false(size(P)),NaN);
%     return
% else
%     [d2X,Dfly] = deal(diff(dX(end-1:end,:)),abs(dX));
% end
% 
% % determines which of the fly regions are feasible (i.e., have both a
% % displacement/velocity change less than their respective tolerances)
% isOK = (abs(dX(end,:)) < dXmax) & (abs(d2X) < d2Xmax);
