classdef StimObj < handle
    % class properties
    properties
        % object handles
        hS
        hTimer
        hGUI        
        
        % device parameters/information fields
        xySig
        dT
        iDev
        iOfs
        sType
        stType
        isRT
        nDev
        hasStim
        hasIMAQ
        
        % channel timing arrays
        tEvent
        yEvent
        aEvent
        iEventCh
        iEventInd
        iChMap
        tStimSF
        tStampS
        tSigSF
        isRunning
        iCountD
        nCountD
        
        % channel properties
        yAmp
        nCh
        tStim
        cEvent
        iEvent
    end
    
    % class methods
    methods
        % class constructor
        function obj = StimObj(hS,xySig,dT,stType,sType,hasIMAQ)
            
            % sets the important fields
            obj.hS = hS;
            obj.dT = dT;
            obj.sType = sType;
            obj.stType = stType;
            obj.isRT = strcmp(obj.stType,'RTStim');
            obj.nDev = length(xySig);
            
            % sets the imaq existence flag
            if exist('hasIMAQ','var')
                obj.hasIMAQ = hasIMAQ;
            else
                obj.hasIMAQ = false;
            end

            % calculates the global channel ID's
            obj.hasStim = cellfun(@(x)...
                    (~cellfun(@isempty,x(:,1))),xySig,'un',0);
            obj.iChMap = cell2mat(cellfun(@(i,x)([i*ones(sum(x),1),...
                    find(x(:))]),num2cell((1:obj.nDev)'),...
                    obj.hasStim,'un',0));
            obj.xySig = cell2cell(...
                    cellfun(@(x,ok)(x(ok,:)),xySig,obj.hasStim,'un',0));

            % other field initialisations
            obj.nCh = size(obj.xySig,1);
            obj.tSigSF = NaN(2,obj.nCh);
            obj.isRunning = false(1,obj.nCh);        
            [obj.iCountD,obj.nCountD] = deal(zeros(1,obj.nCh));
            obj.yAmp = cellfun(@(x)(zeros(1,length(x))),obj.hasStim,'un',0);

            % sets the dac device properties based on the setup type
            switch (obj.stType)
                case ('RTStim')        

                case ('Test')
                    % determines the details of event changes
                    obj.detEventChange();
                    obj.setupTimerObj();             

                case ('Expt')
                    % determines the details of event changes
                    obj.detEventChange();                             
                    obj.setupTimerObj();

            end        
        
        end        
        
        % ---------------------------------------------- %        
        % ----    TIMER EVENT CALLBACK FUNCTIONS    ---- %
        % ---------------------------------------------- %
        
        % --- initialises the stimuli timer objects
        function setupTimerObj(obj)
        
            % creates the stimuli timer
            if obj.isRT
                % case is a real-time tracking experiment
                obj.hTimer = timer('StartFcn',@(h,e)obj.serialStart,...
                                   'TimerFcn',@(h,e)obj.serialTimer,...
                                   'StopFcn',@(h,e)obj.serialStopRT);
            else
                % case is another stimuli type
                obj.hTimer = timer('StartFcn',@(h,e)obj.serialStart,...
                                   'TimerFcn',@(h,e)obj.serialTimer);
            end

            % updates the other timer parameters
            set(obj.hTimer,'Period',max(obj.dT),'tag','hTimerExpt',...
                           'ExecutionMode','FixedRate')

            % memory allocation for stimuli time-stamps
            if strcmp(obj.stType,'Expt')
                obj.tStampS = arrayfun(@(x)(NaN(x,1)),obj.nCountD,'un',0);
            end
        
        end        
        
        % --- start callback function
        function serialStart(obj)
        
            % initialises the start time of the stimuli event 
            obj.tStim = tic;
            obj.cEvent = 1 + (obj.tEvent(1)==0);

            % updates the stimuli channels/progressbar if the stimuli train
            % starts immediately
            if obj.cEvent == 2
                obj.updateStimChannels(1)
                obj.updateProgressBar(1)
            end
        
        end             
        
        % --- timer callback function
        function serialTimer(obj)

            % determines if the time is greater than the next change event
            if toc(obj.tStim) >= obj.tEvent(obj.cEvent)
                % if so, update the stimuli channels 
                obj.updateStimChannels(obj.cEvent);
                obj.updateProgressBar(obj.cEvent);

                % increments the event counter
                obj.cEvent = obj.cEvent + 1;
                if obj.cEvent > length(obj.tEvent)
                    % if no more events then stop/delete the timer
                    try; stop(obj.hTimer); end
                    try; delete(obj.hTimer); end
                end
            end
        
        end       
        
        % --- timer real-time tracking function
        function serialStopRT(obj)
        
            % retrieves the real-time tracking data struct
            rtD = getappdata(obj.hGUI,'rtD');

            % sets the entries for the stimuli finish array
            obj.sFin(obj.iDev,:) = [1,rtD.T(rtD.ind)];            
            
        end     

        % --------------------------------------- %        
        % ----    OBJECT UPDATE FUNCTIONS    ---- %
        % --------------------------------------- %
        
        % --- updates the progress bar details for the current event
        function updateProgressBar(obj,ind)
         
            % if there is no progress bar handle, then exit the function
            if isempty(obj.hGUI); return; end                

            % loops through each of the channels which have action flag 
            % values updating the progress gui
            for i = find(obj.aEvent{ind} > 0)
                iCh = obj.iEventCh{ind}(i);
                switch obj.aEvent{ind}(i)
                    case 1
                        % case is a new stimuli train is running

                        % sets the object running flag to true
                        obj.isRunning(iCh) = true;

                        % sets the time stamp for the current channel
                        iCount = obj.iCountD(iCh)+1;
                        if ~isempty(obj.tStim)
                            obj.tStampS{iCh}(iCount) = toc(obj.tStim);
                        end

                        % updates the triggered device count within the 
                        % expertiment progress GUI
                        iOfsCh = double(obj.hasIMAQ);
                        tFunc = getappdata(obj.hGUI,'tFunc');
                        tFunc([(iCh+iOfsCh) 2],num2str(iCount),obj.hGUI);                     

                    case 3   
                        % case is a running stimuli train is finishing

                        % resets the object running flag to false
                        obj.isRunning(iCh) = false;

                        % increments the stimuli counter
                        obj.iCountD(iCh) = obj.iCountD(iCh) + 1;
                        if obj.iCountD(iCh) < obj.nCountD(iCh)
                            % if not the last stimuli event for the current
                            % channel, then reset the event time limits 
                            obj.tSigSF(:,iCh) = ...
                                    obj.tStimSF{iCh}(obj.iCountD(iCh)+1,:);
                        end                    

                end
            end
        
        end           
        
        % --- updates the serial controller output channels
        function updateStimChannels(obj,ind)
            
            % initialisations       
            [iGrp,yAmpNw] = deal(obj.iEventCh{ind},obj.yEvent{ind});
            [iDevNw,iChNw] = deal(obj.iChMap(iGrp,1),obj.iChMap(iGrp,2));

            % updates the amplitudes of the signals
            for j = 1:length(iChNw)
                obj.yAmp{iDevNw(j)}(iChNw(j)) = yAmpNw(j);            
            end                

            % loops through all of the changes updating the amplitudes
            iDevUniq = unique(iDevNw);
            for ii = 1:length(iDevUniq)
                iDevD = iDevUniq(ii);
                obj.setChannelStrings(iDevD,iChNw(iDevNw==iDevD));
            end
        
        end

        % --- sets the channel strings for the device index, iDevD
        function setChannelStrings(obj,iDevD,iChD)

            % --- creates the device input string for the 
            %     serial/DAC controllers
            function sStr = setupDeviceInputString(obj,sType,iDev,iCh)

                % sets up the device based on the channel dependence type
                if sType == 3
                    % case is the V3 (optogenetics) serial devices
                    Ys = convertSerialValues(roundP(obj.yAmp{iDev}));

                    % sets the rgb, white and IR channel strings
                    sStr = {sprintf('2,%s,%s,%s,000,000\n',...
                                                Ys{1},Ys{2},Ys{3}),...
                            sprintf('4,000,000,000,%s,000\n',Ys{4})};

                else
                    % case is the other channel dependent devices

                    % memory allocation
                    Y = obj.yAmp{iDev}(iCh);
                    sStr = cell(1,length(iCh));

                    % sets the string based on device type
                    switch sType
                        case 0
                            % case is the V1 device types
                            for i = 1:length(iCh)
                                sStr{i} = sprintf('%d,%f',iCh(i),Y(i)/100);
                            end

                        case 2
                            % case is the V2 devices types
                            Y = roundP(Y);
                            for i = 1:length(iCh)
                                sStr{i} = sprintf('1,%i,%f',iCh(i),Y(i));
                            end
                    end
                end

            end            
            
            % --- converts the integers in the array Y, to a 3-character
            %     number string (i.e., from 000 to 100)
            function yStr = convertSerialValues(Y)

                % memory allocation
                yStr = cell(length(Y),1);

                % creates the string based on the new value
                for i = 1:length(yStr)
                    if Y(i) == 0
                        % if the value is zero, then return a zero string
                        yStr{i} = '000';
                    else
                        % otherwise, create the 3 character number string
                        yStr{i} = sprintf('%s%i',...
                                repmat('0',1,2-floor(log10(Y(i)))),Y(i));
                    end
                end

            end              
            
            % parameters and other initialisations  
            hasDev = ~isempty(obj.hS);
            [tw0,tw1] = deal(5,0);            

            while 1
                try 
                    % sets the input string based on the device type 
                    if hasDev
                        sTypeD = get(obj.hS{iDevD},'UserData');
                    else
                        sTypeD = 3;
                    end

                    % sets up the new device string
                    sStr = setupDeviceInputString(obj,sTypeD,iDevD,iChD);
                    writeSerialString(obj.hS{iDevD},sStr);

                    % exits the loop
                    break                       
                catch 
                    % if there was an error, then pause for a short time
                    java.lang.Thread.sleep(roundP(tw0+rand*tw1));
                end
            end                
        
        end        
        
        % --- stops all the devices by writting zeros to all channels
        function stopAllDevices(obj)
            
            % for each device set the amplitude to zero and update the channels
            for iDevD = 1:obj.nDev
                obj.yAmp{iDevD}(:) = 0;
                obj.setChannelStrings(iDevD,find(obj.hasStim{iDevD}));            
            end
            
        end
        
        % ------------------------------- %        
        % ----    OTHER FUNCTIONS    ---- %
        % ------------------------------- %        
        
        % --- sets the progress gui handle
        function setProgressGUI(obj,hGUI)
           
            % sets the progressbar handle into the class object
            obj.hGUI = hGUI;
            setappdata(hGUI,'sObj',obj)                    
        
        end
        
        % --- determines the details of the event changes in a signal
        function detEventChange(obj)

            function tLim = getStimTimingLimits(xSig)

                if isempty(xSig)
                    tLim = [];
                else
                    tLim = cell2mat(cellfun...
                                    (@(x)(x([1,end])'),xSig(:),'un',0));
                end

            end

            function aSig = getStimActFlag(xSig)
                
                % --- function for setting up a single action flag array
                function aSig = getStimActFlagSingle(xSigS)

                    aSig = 2*ones(length(xSigS),1);
                    [aSig(1),aSig(end)] = deal(1,3);

                end

                % sets the action flag array for all stimuli in the channel
                if isempty(xSig)
                    aSig = [];
                else
                    aSig = cellfun(@(x)...
                                  (getStimActFlagSingle(x)),xSig,'un',0);
                end
            end

            function iChSig = getStimChIndices(ind,xSig)
                % sets the action flag array for all stimuli in the channel
                if isempty(xSig)
                    iChSig = [];
                else
                    iChSig = cellfun(@(x)(ind*ones(length(x),1)),xSig,'un',0);
                end                              
            end

            function iChInd = getStimEventIndices(xSig)

               if isempty(xSig)
                   iChInd = [];
               else
                   iChInd = arrayfun(@(x)(x*ones(length(xSig{x}),1)),...
                                                (1:length(xSig))','un',0);
               end

            end            
            
            % sets the amplitude multiplier
            yMlt = zeros(1,obj.nCh);
            for i = 1:obj.nCh
                switch obj.sType{obj.iChMap(i,1)}
                    case 'Opto'
                        yMlt(i) = 0.5;
                    otherwise
                        yMlt(i) = 1;
                end
            end

            % retrieves the time/amplitude of the signal points (the time
            % points are rounded to the nearest sampling time point)
            dt = obj.dT(1);
            xSig = cell2mat(cell2cell(cellfun(@(x)(cellfun(@(y)...
                    (roundP(y,dt)),x,'un',0)),obj.xySig(:,1),'un',0)));
            ySig = repmat(yMlt,size(xSig,1),1).*...
                               cell2mat(cell2cell(obj.xySig(:,2))); 

            % retrieves the action/channel indices
            aSig = cell2mat(cell2cell(cellfun(@(x)(...
                        getStimActFlag(x)),obj.xySig(:,1),'un',0)));
            iChSig = cell2mat(cell2cell(cellfun(@(i,x)(...
                        getStimChIndices(i,x)),num2cell(1:obj.nCh)',...
                        obj.xySig(:,1),'un',0)));  
            iIndSig = cell2mat(cell2cell(cellfun(@(x)(...
                        getStimEventIndices(x)),obj.xySig(:,1),'un',0))); 
            obj.tStimSF = cellfun(@(x)(...
                        getStimTimingLimits(x)),obj.xySig(:,1),'un',0);                            

            % initialises the stimuli timing array values
            for i = 1:obj.nCh
                obj.tSigSF(:,i) = obj.tStimSF{i}(1,:);
                obj.nCountD(i) = size(obj.tStimSF{i},1);
            end                      

            % sorts the time points temporally
            [xSig,ii] = sort(xSig); 
            [ySig,aSig] = deal(ySig(ii),aSig(ii));
            [iChSig,iIndSig] = deal(iChSig(ii),iIndSig(ii));

            % memory allocation
            [nRow,iRow] = deal(length(xSig),1);
            [tEvent0,diRow] = deal(zeros(nRow,1),0);
            [yEvent0,aEvent0,iEventInd0] = deal(zeros(nRow,obj.nCh));       

            % determines the time/amplitudes of any significant activity in 
            % any of the channels
            for i = 1:nRow
                % increments the row count it there is a change in  
                % amplitude of any signals between channels
                if i > 1
                    diRow = (diff(xSig((i-1):i)) >= obj.dT);
                    iRow = iRow + diRow;
                end

                % sets the new time/signal values
                tEvent0(iRow) = xSig(i);    
                yEvent0(iRow,iChSig(i)) = ySig(i); 
                aEvent0(iRow,iChSig(i)) = aSig(i);
                iEventInd0(iRow,iChSig(i)) = iIndSig(i);

                if diRow
                    iColOther = (1:obj.nCh) ~= iChSig(i);
                    yEvent0(iRow,iColOther) = yEvent0(iRow-1,iColOther);  
                end
            end

            % removes the points where there is no signal change
            isChange = [true;sum(abs(diff(yEvent0,[],1)),2) > 0];
            tEvent0 = tEvent0(isChange);
            yEvent0 = num2cell(yEvent0(isChange,:),2);
            aEvent0 = num2cell(aEvent0(isChange,:),2);
            iEventInd0 = num2cell(iEventInd0(isChange,:),2);

            % ensures the final point for all device channels is to zero
            if sum(yEvent0{end}) > 0
                yEvent0{end+1} = zeros(1,length(yEvent0{1}));
                aEvent0{end+1} = zeros(1,length(aEvent0{1}));
                iEventInd0{end+1} = zeros(1,length(iEventInd0{1}));
                tEvent0(end+1) = tEvent0(end+1) + dt;
            end

            % removes all channels where there is no change in the signal
            yEvent0 = cell2mat(yEvent0);
            yEvent0(abs(diff([-ones(1,...
                            size(yEvent0,2));yEvent0],[],1)) == 0) = NaN;
            yEvent0 = num2cell(yEvent0,2);

            % determine the channel indices/amplitudes for each event
            iEventCh0 = cellfun(@(x)(find(~isnan(x))),yEvent0,'un',0);
            yEvent0 = cellfun(@(i,y)(y(i)),iEventCh0,yEvent0,'un',0); 
            aEvent0 = cellfun(@(i,y)(y(i)),iEventCh0,aEvent0,'un',0); 
            iEventInd0 = cellfun(@(i,y)(y(i)),iEventCh0,iEventInd0,'un',0); 

            % sets the class object fields
            [obj.tEvent,obj.yEvent] = deal(tEvent0,yEvent0);
            [obj.aEvent,obj.iEventCh] = deal(aEvent0,iEventCh0);
            obj.iEventInd = iEventInd0;
        
        end    
        
        % --- force stops all devices
        function forceStopDevices(obj)

            % for each device, write all zeros
            for i = 1:obj.nDev
                % determine which channels belong to this device
                ii = obj.iChMap(:,1) == i;

                % sets all amplitudes to zero
                obj.yAmp{i}(:) = 0;                  
                obj.setChannelStrings(i,obj.iChMap(ii,1));
            end
            
        end
        
    end
end
