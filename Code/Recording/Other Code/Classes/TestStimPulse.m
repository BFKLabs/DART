classdef TestStimPulse < handle

    % class properties
    properties

        % main class fields
        sType
        infoObj

        % frame acquistion fields
        T        
        Img  
        ImgHM
        iRI
        iCI
        iRL
        iCL

        % other object class fields
        tObj
        hTimer
        hProg

        % stimuli parameter fields
        devType
        chInfo
        sTrain
        sRate
        xySig

        % boolean class fields
        isWebCam
        isRecord
        isRunning = false;

        % fixed class fields
        dX = 10;
        iDev = 1;
        nFrm = 50;
        pTolOfs = 10;
        timerStr = 'timerRec';

    end

    % class methods
    methods

        % --- class constructor
        function obj = TestStimPulse(infoObj,sType)

            % sets the default input arguments
            if ~exist('sType','var'); sType = 'StimRecord'; end

            % sets the input arguments
            obj.sType = sType;
            obj.infoObj = infoObj;

            % initialises the class fields
            obj.setupStimTrainPara();
            obj.initClassFields();

        end

        % -------------------------------------------- %
        % --- CLASS FIELD INITIALISATION FUNCTIONS --- %
        % -------------------------------------------- %

        % --- initialises the class fields
        function initClassFields(obj)

            % sets up the camera device fields
            obj.T = NaN(obj.nFrm,1);
            obj.Img = cell(obj.nFrm,1);
            obj.isWebCam = isa(obj.infoObj.objIMAQ,'webcam');
            

            % sets up the device type strings/fields
            obj.chInfo = obj.setupChannelInfo();
            obj.sRate = field2cell(obj.infoObj.iStim.oPara,'sRate',1);
            obj.xySig = setupDACSignal(obj.sTrain,obj.chInfo,1./obj.sRate);

            % removes any previous timer objects
            hTimerPr = timerfindall('tag',obj.timerStr);
            if ~isempty(hTimerPr)
                stop(hTimerPr);
                delete(hTimerPr)
            end

            % sets up the frame acquistion timer object
            tPer = obj.sTrain.tDur/obj.nFrm;
            obj.hTimer = timer('TimerFcn',@obj.frameGetFunc,...
                'ExecutionMode','FixedRate','Period',tPer,...
                'StartDelay',0,'TasksToExecute',obj.nFrm,...
                'Tag','StartTimer');

        end

        % --- sets up the stimuli train parameters
        function setupStimTrainPara(obj)

            % parameters
            obj.isRecord = strcmp(obj.sType,'StimRecord');
            tEnd = 2.5*obj.isRecord;

            % sets the stimuli block parameters
            sPara = struct('sAmp',100,'tDurOn',NaN,'tDurOff',NaN,...
                'tOfs',NaN,'nCount',NaN,'tDur',NaN,'tDurU','s',...
                'tOfsU','s','tDurOnU','s','tDurOffU','s');
            sPara.nCount = 2*(1 + ~obj.isRecord*0.5);
            sPara.tOfs = 2.5*obj.isRecord;
            sPara.tDurOn = 2 + 3*obj.isRecord;
            sPara.tDurOff = 2 + 3*obj.isRecord;            
            sPara.tDur = (sPara.nCount*sPara.tDurOn) + ...
                         ((sPara.nCount-1)*sPara.tDurOff);

            % sets up the block information struct
            blkInfo = struct('chName','Ch #1','devType',...
                'Motor','sPara',sPara,'sType','Square');

            % sets the final stimuli train struct
            obj.sTrain = struct('sName','Short-Term Signal #1',...
                'tDur',NaN,'tDurU','s','blkInfo',blkInfo,...
                'chName',[],'devType',[]);
            obj.sTrain.chName = {'Ch #1'};
            obj.sTrain.devType = {'Motor'};
            obj.sTrain.tDur = sPara.tDur + sPara.tOfs + tEnd;

        end

        % --- sets up the channel information
        function chInfo = setupChannelInfo(obj)

            % retrieves the initial device types
            dType = obj.resetDevType(obj.infoObj.objDAQ.sType);

            % memory allocation
            nDev = length(dType);
            [dTypeT,isFound] = deal(dType,false(nDev,1));

            % otherwise, setup the device type strings
            for i = 1:nDev
                if ~isFound(i)
                    % determines if multiple devices of the same type
                    ii = find(strcmp(dType,dTypeT{i}));
                    if length(ii) > 1
                        % if so, replace their names with numbered names
                        dTypeT(ii) = arrayfun(@(x)(sprintf('%s %i',...
                            dTypeT{i},x)),1:length(ii),'un',0);
                    end

                    % flag all devices of the current type
                    isFound(ii) = true;
                end
            end

            % sets the device channel information array
            chName = obj.setupChannelNames(dType);
            chID = cellfun(@(i,x)(i*ones(length(x),1)),...
                num2cell(1:nDev),chName,'un',0);
            chInfo = cell2cell(cellfun(@(i,x)([num2cell(i),x(:),...
                dTypeT(i)]),chID,chName,'un',0));

        end

        % --- sets up the channel names
        function chName = setupChannelNames(obj,dType)

            % sets up the axis properties based on the connected device
            nDev = length(dType);
            chName = cell(1,nDev);
            nCh = obj.infoObj.objDAQ.nChannel;

            % sets up the channel names depending on device type
            for i = 1:nDev
                switch dType{i}
                    case 'Opto'
                        % case is the optogenetic device
                        chName{i} = obj.getOptoChannelNames();

                    case 'Motor'
                        % case is a motor device
                        chName{i} = obj.getMotorChannelNames(nCh(i));
                end
            end

        end

        % ------------------------------------------ %
        % --- STIMULI/FRAME ACQUSITION FUNCTIONS --- %
        % ------------------------------------------ %

        % --- runs the stimuli device
        function runDevice(obj)

            % if already running then exit
            if obj.isRunning
                return
            end

            % sets up the device object
            objDev = {setupSerialDevice(obj.infoObj.objDAQ,...
                'Test',obj.xySig(obj.iDev),obj.sRate,obj.iDev)};

            % stops the frame acquistion timer (if running)            
            if obj.isRecord
                % stops the timer (if currently running)
                if strcmp(obj.hTimer.Running,'on')
                    obj.hTimer.stop;
                end
                
                % retrieves the current/full video resolution
                if obj.isWebCam
                    rPos = obj.infoObj.objIMAQ.pROI;                
                else
                    rPos = get(obj.infoObj.objIMAQ,'ROIPosition');
                end
    
                % sets the ROI row/column indices
                obj.iCI = rPos(1) + (1:rPos(3));
                obj.iRI = rPos(2) + (1:rPos(4));  

                % creates the progressbar
                wStr = {'Reading Image Frames'};
                obj.hProg = ProgBar(wStr,'HT1 Controller Reading');
                pause(0.01)
            end

            % flag the device is running
            obj.isRunning = true;

            % runs the output device and starts the recording timer
            runOutputDevices(objDev,1:length(objDev));
            if obj.isRecord
                obj.tObj = tic; 
                obj.hTimer.start;
            end

            % resets the device running flag
            obj.isRunning = false;            

        end

        % --- frame acquistion timer callback function
        function frameGetFunc(obj,hTimer,~)

            % clears the image stack array (first frame only)
            iFrm = hTimer.TasksExecuted;
            if iFrm == 1
                % resets the arrays
                [obj.Img(:),obj.T(:)] = deal({[]},NaN);
            end

            % updates the progressbar
            if ~isempty(obj.hProg)
                wStr = sprintf('Reading Frame %i of %i',iFrm,obj.nFrm);
                obj.hProg.Update(1,wStr,iFrm/obj.nFrm);
            end

            % sets the time stamp
            obj.T(iFrm) = toc(obj.tObj);            

            % retrieves the frame snapshot (depending on type)
            if obj.isWebCam
                ImgTmp = snapshot(obj.infoObj.objIMAQ);
            else
                ImgTmp = getsnapshot(obj.infoObj.objIMAQ);
            end

            % sets the final image (converts to gray)
            obj.Img{iFrm} = double(rgb2gray(ImgTmp(obj.iRI,obj.iCI,:)));

        end

        % -------------------------------- %
        % --- STACK ANALYSIS FUNCTIONS --- %
        % -------------------------------- %

        % --- processes the image stack
        function processImgStack(obj)

            %
            ImgMu = cellfun(@(x)(mean(x(:))),obj.Img);
            stFrm = ImgMu < mean(ImgMu);

            %
            Iref0 = uint8(calcImageStackFcn(obj.Img(~stFrm)));
            obj.setupRegionIndices(double(Iref0));
            Iref = cellfun(@(x,y)(Iref0(x,y)),obj.iRL,obj.iCL,'un',0);

            % 
            ImgL = obj.getLocalImageStack(obj.Img);
            ImgHML = cellfun(@(x,y)...
                (calcHistMatchStack(x,y)),ImgL,Iref,'un',0);

            % sets the 
            obj.ImgHM = obj.Img;
            for iFrm = 1:length(obj.Img)
                for i = 1:numel(obj.iRL)
                    obj.ImgHM{iFrm}...
                        (obj.iRL{i},obj.iCL{i}) = ImgHML{i}{iFrm};
                end
            end

        end

        % --- auto-detects the region row/column indices
        function setupRegionIndices(obj,Iref)

            % parameters
            nSm = 25;
            dpTol = 0.1;
            sz = size(Iref);
            [nR,nC] = deal(3,2);

            % determines the max row/column pixel intensities
            ImaxC = smooth(max(Iref,[],1),nSm);
            ImaxR = smooth(max(Iref,[],2),nSm);

            % determines the lower/upper peak indices
            [ImaxT,IminT] = deal(max(Iref(:)),min(Iref(:)));
            pLo = IminT + dpTol*(ImaxT - IminT);

            % determines the global row/column indices
            iPkC = obj.detFeasPeaks(ImaxC,pLo,nC);
            iPkR = obj.detFeasPeaks(ImaxR,pLo,nR);
            iRG = obj.setupGlobalRegionIndices(iPkR,sz(1));
            iCG = obj.setupGlobalRegionIndices(iPkC,sz(2));

            %
            BD = zeros(sz);
            for i = 1:nR
                for j = 1:nC
                    BD(iRG{i},iCG{j}) = (i-1)*nC + j;
                end
            end

            % threholds the reference image and determines which thrsholded
            % blobs belong to which global group
            pTol = max([ImaxC(iPkC);ImaxR(iPkR)]) + obj.pTolOfs;
            iGrp = getGroupIndex(Iref > pTol);
            indG = cellfun(@(x)(BD(x(1))),iGrp);

            %
            [obj.iRL,obj.iCL,BB] = deal(cell(nR,nC));
            for i = 1:nR
                for j = 1:nC
                    k = (i-1)*nC + j;
                    jGrp = cell2mat(iGrp(indG == k));
                    [yG,xG] = ind2sub(sz,jGrp);

                    % calculates the binary group bounding boxes
                    [yGmn,xGmn] = deal(min(yG)-obj.dX,min(xG)-obj.dX);
                    [yGmx,xGmx] = deal(max(yG)+obj.dX,max(xG)+obj.dX);
                    BB{i,j} = [xGmn,yGmn,xGmx-xGmn,yGmx-yGmn];

                    % sets up the local row/column indices
                    obj.iCL{i,j} = ...
                        obj.setupLocalIndices(xGmn,BB{i,j}(3),sz(2));
                    obj.iRL{i,j} = ...
                        obj.setupLocalIndices(yGmn,BB{i,j}(4),sz(1));
                end
            end

        end

        % --- calculates the histogram matched image statistics
        function pStats = calcImageStats(obj)

            % memory allocation
            pStats = struct();  
            ImgL = obj.getLocalImageStack(obj.Img);

            % sets up the raw/HM image stacks          
            IhmL = obj.getLocalImageStack(obj.ImgHM);            
            IhmMx = cellfun(@(x)(calcImageStackFcn(x,'max')),IhmL,'un',0);
            IhmR = cellfun(@(x,y)(...
                cellfun(@(z)(y-z),x,'un',0)),IhmL,IhmMx,'un',0);
            
            % calculates the mean histogram matched/residual image stacks
            ImgMu = cellfun(@(x)(cellfun(@(y)(mean(y(:))),x)),ImgL,'un',0);
            IhmMu = cellfun(@(x)(cellfun(@(y)(mean(y(:))),x)),IhmL,'un',0);            
            Ravg = cellfun(@(x)(cellfun(@(y)(mean(y(:))),x)),IhmR,'un',0);

            % calculates the total mean/std dev residual values
            pStats.Rsd = sqrt(sum(arr2vec(cellfun(@var,Ravg))));
            pStats.Rmu = mean(arr2vec(cellfun(@mean,Ravg)));
            pStats.Dsd = sqrt(sum(...
                arr2vec(cellfun(@(x,y)(var(x-y)),IhmMu,ImgMu))));

        end

        % --------------------------- %
        % --- PLOT TEST FUNCTIONS --- %
        % --------------------------- %

        %
        function plotAllTraces(obj,hAx)

            if ~exist('hAx','var')
                figure;
            else
                axes(hAx)
            end

            ImgL = obj.getLocalImageStack(obj.Img);
            IhmL = obj.getLocalImageStack(obj.ImgHM);

            ImgMu = cellfun(@(x)(cellfun(@(y)(mean(y(:))),x)),ImgL,'un',0);
            IhmMu = cellfun(@(x)(cellfun(@(y)(mean(y(:))),x)),IhmL,'un',0);

            for i = 1:length(hAx)
                hold(hAx(i),'on');
                plot(hAx(i),ImgMu{i},'--')
                plot(hAx(i),IhmMu{i},'linewidth',2)
            end 

        end

        % --- plot the region traces
        function plotRegionTraces(obj,hAx)


            IhmL = obj.getLocalImageStack(obj.ImgHM);

            IhmMx = cellfun(@(x)(calcImageStackFcn(x,'max')),IhmL,'un',0);
            IhmR = cellfun(@(x,y)(cellfun(@(z)(y-z),x,'un',0)),IhmL,IhmMx,'un',0);
            Ravg = cellfun(@(x)(cellfun(@(y)(mean(y(:))),x)),IhmR,'un',0);

            for i = 1:length(hAx)
                hold(hAx(i),'on')
                plot(hAx(i),Ravg{i})
            end 

        end   

        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %

        % --- get local images from the stack, I
        function IL = getLocalImageStack(obj,I)

            IL = cellfun(@(x,y)(cellfun...
                (@(z)(z(x,y)),I,'un',0)),obj.iRL,obj.iCL,'un',0);

        end

    end

    % static class methods
    methods (Static)

        % --- resets the device type names
        function devType = resetDevType(devType)

            % converts 'HT ControllerV1' to 'Motor'
            devType(strcmp(devType,'HTControllerV1')) = {'Motor'};
            devType(strcmp(devType,'HTControllerV2')) = {'Motor'};

        end

        % --- retrieves the general motor channel names (for nCh channels)
        function chName = getMotorChannelNames(nCh)

            chName = arrayfun(@(x)(sprintf('Ch #%i',x)),(1:nCh)','un',0);

        end

        % --- retrieves the general motor channel names (for nCh channels)
        function chName = getOptoChannelNames(varargin)

            % sets the channel name array
            chName = flip({'Red','Green','Blue','White'});

        end

        % --- determines the feasible peaks (minima) between pLo/pHi
        function iPk = detFeasPeaks(Imax,pLo,N)

            % determines the approx location of the separation lines
            i0 = find(Imax > pLo,1,'first') - 1;
            i1 = find(Imax > pLo,1,'last') + 1;
            indP = roundP(linspace(i0,i1,N+1));

            % determines the overall local minima from the signal
            [~,iPk0] = findpeaks(-Imax);
            iPk0 = iPk0((iPk0 > i0) & (iPk0 < i1));
            dScl = diff(indP([1,end]))/N;
            yPk0 = normImg(Imax(iPk0),1);

            % determines the likely candidate minima 
            iPk = zeros(N-1,1);
            for i = 1:length(iPk)
                diPk = abs(iPk0 - indP(i+1))/dScl;
                iPk(i) = iPk0(argMin(diPk.*yPk0));
            end

        end

        % --- sets the regions global indices
        function ind = setupGlobalRegionIndices(iPk,sz)

            A = [[1;iPk(:)],[iPk(:);sz]];
            ind = cellfun(@(x)(x(1):x(2)),num2cell(A,2),'un',0);

        end

        % --- sets the regions local indices
        function indL = setupLocalIndices(p0,pW,sz)

            indL = p0 + (1:pW);
            indL = indL((indL >= 1) & (indL <= sz));

        end

    end

end