classdef SingleTrackBP < matlab.mixin.SetGet
    
    % class properties
    properties
        
        % main class properties
        hGUI
        hFig
        bData
        hProp0
        hProg
        iData
        pData
        iMov        
        
        % function handles
        dispImage
        checkShowTube
        checkShowMark
        menuOpenSoln
        menuViewProgress        
        initMarkerPlots
        
        % boolean flags and parameters        
        setupOK = true;
        calcOK = true;
        isOutput
        isRestart
        isRecord
        isMultiBatch 
        isSeg        
        forceCalcBG
        setSoln
        isCalcBG

        % other parameters/flags
        iFile0
        nFile
        TwaitEnd = 10;
        
        % initial data objects
        iMov0
        iData0
        pData0
        p0Pr
        
        % other important fields
        nDir     
        wStr
        outDir
        outSumm
        bFile   
        wErr
        fNameBase0
        sFileNw
        
    end
    
    % class methods
    methods
        
        % class constructor
        function obj = SingleTrackBP(hGUI,isRestart)
        
            % sets the input objects
            obj.hGUI = hGUI;
            obj.isRestart = isRestart;            
            
            % other object handles
            obj.hFig = hGUI.output;
            obj.iMov = get(obj.hFig,'iMov');
            obj.iData = get(obj.hFig,'iData');
            obj.pData = get(obj.hFig,'pData');            
            
            % function handle retrieval
            obj.initFuncObj();  
            obj.setupBatchData();
            
        end        

        % --- sets up the batch processing data
        function setupBatchData(obj)
            
            % runs the pre-batch processing  
            obj.hProp0 = getHandleSnapshot(obj.hGUI); 
            setTrackGUIProps(obj.hGUI,'PreBatchProcess');
            
            % removes the soln progress GUI (if it is on)
            if strcmp(get(obj.hGUI.menuViewProgress,'checked'),'on')    
                obj.menuViewProgress(obj.hGUI.menuViewProgress,[],obj.hGUI)                           
            end
                        
            % sets up the batch processing data struct
            if obj.isRestart
                % case is restarting the batch processing
                obj.bData = RestartBatchProcess(obj);
            else
                % case is setting up the batch processing
                obj.bData = SetupBatchProcess(obj.iData);
            end
            
            % ensures the comparison image has been set
            obj.setComparisonImages();            
            
            % if the user cancelled, then reset the objects
            if isempty(obj.bData)
                % flag that the setup was cancelled
                obj.setupOK = false;
                
                % if the user cancelled, then reset the object properties
                resetHandleSnapshot(obj.hProp0,obj.hFig); 
                obj.checkShowTube(obj.hGUI.checkShowTube,1,obj.hGUI)
                obj.checkShowMark(obj.hGUI.checkShowMark,1,obj.hGUI) 
            else
                % otherwise, check the record status of the video
                obj.checkVideoStatus();
            end
            
        end    
        
        % --- retrieves the batch processing comparsion image
        function setComparisonImages(obj)
            
            % retrieves the comparison image for each batch processing 
            % object (only for missing datasets)
            for i = 1:length(obj.bData)
                if isempty(obj.bData(i).Img0)            
                    % retrieves the candidate frame
                    fStr = obj.bData(i).mName{1};
                    Img0 = obj.getFeasComparisonImage(fStr); 
                    nFrm = length(obj.bData(i).mName);
                    
                    % sets the comparison image/offset values                    
                    obj.bData(i).Img0 = Img0;
                    obj.bData(i).dpImg = [zeros(1,2);NaN(nFrm-1,2)];
                end
            end
            
        end
        
        % --- retrieves the next feasible image
        function Img0 = getFeasComparisonImage(obj,fStr,iFrm0)

            % initialisation
            if ~exist('iFrm0','var'); iFrm0 = 1; end

            % reads in the first feasible frame                    
            while 1
                try
                    % reads the image frame
                    Img0 = obj.getComparisonImages(fStr,iFrm0);
                    if ~isempty(Img0)
                        % if feasible, then exit
                        break
                    end
                end

                % increments the frame counter
                iFrm0 = iFrm0 + 1;
            end

        end        
        
        % --- retrieves the comparison image
        function Img0 = getComparisonImages(obj,fStr,iFrm)
            
            % sets the frame index
            if ~exist('iFrm','var'); iFrm = 1; end
            cFrmT = obj.iMov.sRate*(iFrm-1) + obj.iData.Frm0;
            
            % retrieves the video object (dependent on video type) 
            fExtn = getFileExtn(fStr);
            switch fExtn
                case {'.mj2', '.mov','.mp4'}
                    % case is mj2, mov or mp4 videos
                    mObj = VideoReader(fStr);

                    % resets the image frame
                    Img0 = read(mObj,cFrmT); 
                    
                case '.mkv'
                    % case is .mkv videos
                    mObj = ffmsReader();
                    [~,~] = mObj.open(fStr,0); 
                    
                    % reads the image frame
                    Img0 = mObj.getFrame(cFrmT-1);                 

                otherwise
                    % case are the other video types
                    FPS = obj.iData.exP.FPS;
                    tFrm = cFrmT/FPS + (1/(2*FPS))*[-1 1];
                    [V,~] = mmread(fStr,[],tFrm,false,true,'');   
                    
                    % reads the image frame
                    if isempty(V.frames)
                        Img0 = [];
                    else
                        Img0 = V.frames(1).cdata;
                    end

            end         
            
            % converts truecolour images to grayscale
            if size(Img0,3) == 3
                Img0 = double(rgb2gray(Img0));
            else
                Img0 = double(Img0);
            end           
            
            % rotates the final image
            Img0 = getRotatedImage(obj.iMov,Img0);
            
        end
        
        % --- updates the video offset field (for the current video)
        function updateVideoOffset(obj,iDir,iFile)
            
            % if the first file, then exit
            if (iFile == 1) || ~isnan(obj.bData(iDir).dpImg(iFile,1))
                return
            end

            % calculates the new video offset
            dpImgNw = obj.calcVideoOffset(iDir,iFile);
            obj.bData(iDir).dpImg(iFile,:) = dpImgNw;
            szFrm = size(obj.bData(iDir).Img0);

            % calculates the relative change between the
            % previous/current videos 
            xiS = iFile+[-1;0];
            dpImgS = diff(obj.bData(iDir).dpImg(xiS,:),[],1);
            if any(dpImgS ~= 0)
                % update if there is a shift in position
                obj.iMov = resetRegionPos(obj.iMov,szFrm,dpImgS);
            end
            
        end        
        
        % --- starts running the batch processing 
        function startBatchProcessing(obj)
            
            % resets the global flag
            global isBatch
            isBatch = true;            
            
            % sets up the waitbar figure fields
            tStr = 'Segmentation Batch Processing';
            obj.wStr = {'Overall Progress',...
                       'Current Directory Progress',...
                       'Overall Video Progress',...
                       'Current Phase Progress',...
                       'Sub-Image Stack Reading',...
                       'Analysis Region'};
                   
            % removes the top line if not
            if ~obj.isMultiBatch
                obj.wStr = obj.wStr([1,3:end]);            
            end
                   
            % creates the waitbar figure                
            obj.hProg = ProgBar(obj.wStr,tStr,2);  
            obj.hProg.collapseProgBar(1);
            obj.hProg.setVisibility('on');            

            % ---------------------------- %            
            % --- MAIN PROCESSING LOOP --- %
            % ---------------------------- %
            
            % loops through all of the experiment directories ensuring that
            % they have been initialised correctly. if the directories are 
            % not empty, then the user will be asked if they want to 
            % restart or continue their progress
            for iDir = 1:obj.nDir
                if obj.isMultiBatch
                    % updates the waitbar figure
                    wStrNw = sprintf('%s (Directory %i of %i)',...
                                                obj.wStr{1},iDir,obj.nDir);
                    if obj.hProg.Update(1,wStrNw,iDir/(obj.nDir+1))
                        % if the user cancelled, then exit the function
                        obj.calcOK = false;
                        break
                    end     
                end
                
                % important files/directories            
                obj.outDir = fullfile(obj.bData(iDir).SolnDir,...
                                      obj.bData(iDir).SolnDirName);
                obj.bFile = fullfile(obj.outDir,'BP.mat');
                obj.outSumm = fullfile(obj.outDir,'Summary.mat');  
                
                % updates the movie status flags
                if ~exist(obj.bFile,'file')
                    obj.updateBPFile(obj.bData(iDir)); 
                end

                % batch processes the current directory                
                if ~obj.batchProcessDir(iDir)
                    % if there was an error or the user cancelled, then 
                    % exit the batch processing loop
                    obj.calcOK = false;
                    break
                end                         
            end
            
            % updates and closes the waitbar figure
            if ~obj.hProg.Update(1,'Batch Processing Complete!',1)
                obj.hProg.closeProgBar();
            end           
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %

            % turns off the viewing progress (if it is open)
            if strcmp(get(obj.hGUI.menuViewProgress,'checked'),'on')    
                obj.menuViewProgress(obj.hGUI.menuViewProgress,[],obj.hGUI)
            end            
            
            % if there was an error 
            if ~obj.calcOK
                % determines if there are any valid solution files in the
                % first batch processing directory
                fDir = obj.getSolnFileDir(1);
                sName = dir(fullfile(fDir,'*.soln'));
                if ~isempty(sName)
                    % if there are solution files in the directory, then 
                    % set the first solution file as that being loaded
                    e = struct('fDir',fDir,'fName',sName(1).name);

                    % opens and displays the solution file 
                    obj.menuOpenSoln(obj.hGUI.menuOpenSoln, e, obj.hGUI)        
                    obj.dispImage(obj.hGUI)  
                    
                else                    
                    % otherwise, reset to the original GUI properties
                    resetHandleSnapshot(obj.hProp0,obj.hFig); 
                end        
            end            
            
            % resets the plot markers back to their current status
            obj.initMarkerPlots(obj.hGUI,1)

            % updates the GUI properties
            setTrackGUIProps(obj.hGUI,'PostSolnLoadBP')
            setTrackGUIProps(obj.hGUI,'PostBatchProcess')
            setTrackGUIProps(obj.hGUI,'UpdateFrameSelection') 
            
            % if there was an error, then output it to the command window
            if ~isempty(obj.wErr)
                rethrow(obj.wErr); 
            end    
            
            % resets the global flag
            isBatch = false;
            
        end                    
        
        % ----------------------------------- %        
        % ---- MAIN PROCESSING FUNCTIONS ---- %
        % ----------------------------------- %        
        
        % --- batch processes a single directory
        function ok = batchProcessDir(obj,iDir)

            % memory allocation
            ok = true;     
            prData = [];
            
            % object field initialisations                        
            obj.setSoln = true;    
            obj.forceCalcBG = false;
            obj.nFile = length(obj.bData(iDir).mName);
            obj.isSeg = false(obj.nFile,1);                            
            
            % sets the initial data structs
            iwLvl = 1 + obj.isMultiBatch;
            [obj.iMov0,obj.iData0] = deal(obj.iMov,obj.iData);            
            obj.wStr{iwLvl} = 'Current Directory Progress';               
            
            % determines the processing start point
            obj.iFile0 = obj.detectStartPoint(obj.iData0.exP,iDir);
            if isnan(obj.iFile0)
                % if the user cancelled, then exit the function
                ok = false;
                return
                
            else
                % otherwise, set the video output file base name
                j0 = max(1,obj.iFile0-1);
                [~,obj.fNameBase0,~] = fileparts(obj.bData(iDir).mName{j0});                 
            end                        
            
            % waits for the current video to stop recording (if required)
            if obj.isRecord(iDir)
                % resets the waitbar string
                obj.wStr{iwLvl} = 'Waiting For Video To Finish Recording';
                if ~obj.videoRecordWait(obj.bData(iDir))
                    % if the user cancelled or there was an error, then
                    % exit the function (after flagging the error)
                    obj.calcOK = false;
                    return
                    
                else
                    % otherwise, reset the waitbar string
                    obj.wStr{iwLvl} = 'Current Directory Progress';                    
                end
            end
            
            % sets up the summary file
            obj.setupSummaryFile(obj.bData(iDir));
            
            % creates a new shell solution file (if one is required)
            if obj.setSoln
                obj.createShellSolnFile(iDir,obj.iFile0);
            end

            % resets the waitbar figure fields
            for j = iwLvl:length(obj.wStr)
                obj.hProg.Update(j,obj.wStr{j},0);
            end                      
            
            % --------------------------------------- %
            % --- VIDEO SEGMENTATION & PROCESSING --- %
            % --------------------------------------- %                                                   
            
            % intialisation
            isInit = true;            
            obj.isOutput = true;
            eStr = {'Error! There was an issue with ',...
                    'the tracking process.';'Read the error ',...
                    'message associated with this issue.'};            
            
            % loops through all the movies (starting at iFile0)
            i = obj.iFile0;
            while i <= obj.nFile
                % updates the waitbar figure
                wStrNw = sprintf('%s (Movie %i of %i)',...
                                         obj.wStr{iwLvl},i,obj.nFile);
                if obj.hProg.Update(iwLvl,wStrNw,i/obj.nFile)
                    % if the user cancelled, then exit the function
                    break
                    
                elseif ~isInit                    
                    % resets the other waitbar figure fields
                    for j = (iwLvl+1):length(obj.wStr)
                        obj.hProg.Update(j,obj.wStr{j},0);
                    end
                end                        
                
                % only segment if the video needs segmenting
                if ~obj.isSeg(i) || (obj.nFile == 1)                     
                    % if still recording, then wait for the next video to
                    % turn up for analysis
                    if obj.isRecord(iDir)
                        % determines the next video to be 
                        if ~obj.getNextRecordedVideo(iDir,i)
                            % updates the movie status flags
                            obj.updateBPFile(obj.bData(iDir));
                            
                            % exits the function
                            ok = false;
                            return
                        end
                    end

                    % reloads the current movie and resets the parameters 
                    obj.reloadImgData(iDir,i)
                    
                    % if the next video is valid, then segment the video
                    if obj.bData(iDir).movOK(i) == 1
                        % creates/opens a new solution file
                        obj.openNewSolnFile(iDir,i)
                        
                        % resets the sub-movie region data structs (only do
                        % this if restarting the batch processing and not
                        % the first file)
                        if (i > 1) && isInit
                            obj.resetSubRegionData()                            
                        end

                        % --------------------------------- %
                        % --- INITIAL SOLUTION ESTIMATE --- %
                        % --------------------------------- %                        
                        
                        % new background estimate calculations
                        if obj.bData(iDir).movOK(i) == 1  
                            % if initialising and not segmenting the first
                            % video, then retrieve the information from the
                            % last video frame to use for the new file
                            if isInit && (i > 1)
                                prData = obj.getPrevSolnData(iDir,i-1); 
                            end
                            
                            % runs the initial object calculations
                            switch obj.calcInitObjLocations(prData,iDir,i)
                                case 1
                                    % if the user cancelled then updates 
                                    % the bp file & exit the loop
                                    obj.updateBPFile(obj.bData(iDir));
                                    break
                                    
                                case 2
                                    % otherwise, just exit the loop
                                    break
                            end                             
                        end
                        
                        % ----------------------------- %
                        % --- ENTIRE VIDEO TRACKING --- %
                        % ----------------------------- %    
                        
                        % updates the batch processing data
                        obj.updateBPFile(obj.bData(iDir));
                        
                        % starts full video tracking (if video is valid)
                        if obj.bData(iDir).movOK(i) ~= 0
                            % tracks the video
                            trkOK = obj.segObjLocations(prData);
                            if ~isempty(obj.wErr)                                
                                % if there was an error with the 
                                % calculations then display and exit
                                tStr = 'Batch Processing Error';
                                waitfor(errordlg(eStr,tStr,'modal'))
                                
                                % flag the batch processing should stop
                                ok = false;
                            end                                   
                                                                                                                                        
                            if ~trkOK
                                % outputs the final data to file (if reqd)
                                if obj.isOutput
                                    obj.outputSolutionFile(iDir,i,0)
                                end    
                                
                                % if the user cancelled then updates 
                                % the bp file & exit the loop
                                obj.updateBPFile(obj.bData(iDir));
                                break                                
                            end  
                            
                            % if the tracking was successful, then store
                            % the data from current file to act as a
                            % starting point for the next video
                            if i < obj.nFile
                                prData = obj.storePrevData();  
                            end
                        
                        else
                            % initialises an empty position data struct
                            obj.initPosDataStruct(iDir); 
                            prData = [];
                        end                                                
                        
                        % ------------------------------- %
                        % --- HOUSE-KEEPING EXERCISES --- %
                        % ------------------------------- %                                                                         
                        
                        % outputs the final data to file (if reqd)
                        if obj.isOutput
                            obj.outputSolutionFile(iDir,i,0)
                        end                           
                        
                        % ensures the orientation angle flag has been set
                        if ~isfield(obj.pData,'calcPhi') 
                            obj.pData.calcPhi = false; 
                        end                                
                    end
                end                                               
                
                % detects the next video 
                obj.updateVideoInfo(iDir)

                % video counter incrememnt and output flag reset
                i = i + 1;           
                obj.isOutput = true;  
                obj.pData = [];
                                
                if i <= obj.nFile
                    try
                        % attempt to reset the minor progressbar fields
                        for j = (iwLvl+1):length(obj.wStr)
                            obj.hProg.Update(j,obj.wStr{j},0);
                        end
                    catch
                        % if there is an error, exit the analysis loop
                        break
                    end
                end
            end
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % clears the major class fields from the tracking objects
            fldStr = {'iMov','iMov0','iData0','pData0','p0Pr'};
            for i = 1:length(fldStr)
                set(obj,fldStr{i},[]);
            end            
            
%             % outputs to screen any videos that were invalid
%             obj.outputInvalidVideosMsg();
            
        end
        
        % --- stores the data from the solution data from the current file
        %     to be used in the analysis of the next file
        function prData = storePrevData(obj)

            % memory allocation
            prData = struct('fPos',[],'iStatus',[],'iStatusF',[]);            
            
            % stores the final location data
            prData.fPos = cellfun(@(x)(cell2mat(cellfun(@(y)...
                        (y(end,:)),x(:),'un',0))),obj.pData.fPos,'un',0);
                    
            % sets the other fields
            prData.iStatus = obj.iMov.Status;
            prData.iStatusF = obj.iMov.StatusF;            
            
        end
        
        % --- segements all object locations for a given video
        function ok = segObjLocations(obj,prData)
            
            % expands the waitbar figure by 1 level
            obj.hProg.expandProgBar(1);
            
            % initalises the tracking object
            if strContains(obj.iMov.bgP.algoType,'single')
                % case is single object tracking
                trkObjF = SingleTrackFull(obj.iData);                 
                set(trkObjF,'wOfs',1+obj.isMultiBatch);
                                
            else
                % case is single object tracking                
                trkObjF = feval('runExternPackage','MultiTrack',...
                                 obj.iData,'Full');
            end
            
            % sets the common tracking object fields
            set(trkObjF,'hProg',obj.hProg,'hasProg',true,...
                        'isBatch',true,'prData',prData,...
                        'isMultiBatch',obj.isMultiBatch); 
                        
            try
                % segments the entire video
                trkObjF.segEntireVideo(obj.hGUI,obj.iMov,obj.pData0);
                ok = trkObjF.calcOK;
                
            catch wErrNw
                % closes the progressbar (if open)
                obj.hProg.closeProgBar()

                % exits the function
                [obj.calcOK,ok] = deal(false);
                [obj.isOutput,obj.wErr] = deal(true,wErrNw);
            end
                
            % updates the tracking data
            [obj.iMov,obj.pData] = deal(trkObjF.iMov,trkObjF.pData);           
            
            % retrieves the status flag from the tracking object            
            if ok
                % expands the waitbar figure by 1 level
                obj.isOutput = true;
                if trkObjF.nLvl == (5 + obj.isMultiBatch)
                    obj.hProg.collapseProgBar(1); 
                end
                
            elseif any(obj.pData.nCount > 0) && isempty(obj.wErr)
                % prompt user if they wish to save current progress
                uChoice = questdlg(['Do you wish to save the current ',...
                           'tracking progress to to file?'],...
                           'Save Current Progress','Yes','No','Yes');    
                obj.isOutput = strcmp(uChoice,'Yes');                 
            end
            
        end
        
        % --- retrieves the previous solution data
        function prData = getPrevSolnData(obj,iDir,iFile)
            
            % initialisations
            nPr = 5;
            prData = struct('fPosPr',[],'iStatus',[],'iStatusF',[],...
                            'IPosPr',[],'fPos',[]);
            
            % retrieves the full file name of the solution file
            sFilePr = obj.getSolnFileName(iDir,iFile);

            % opens the previous solution file
            wState = warning('off','all');
            sData = load(sFilePr,'-mat');
            warning(wState)        
            
            % sets the location of the objects at the end of the video
            prData.fPosPr = cellfun(@(y)(cellfun(@(x)(x((end-(nPr-1))...
                            :end,:)),y,'un',0)),sData.pData.fPosL,'un',0);
            prData.IPosPr = cellfun(@(y)(cellfun(@(x)(x(end)),y)),...
                            sData.pData.IPos,'un',0);
            
            % retrieves the previous solution file data
            prData.iStatus = obj.iMov.Status;
            prData.iStatusF = obj.iMov.StatusF{end};
            
        end
        
        % --- calculates the new background image estimate
        function sFlag = calcInitObjLocations(obj,prData,iDir,iFile)
            
            % initialisations
            sFlag = 0;                
            
            % determines if the background estimate needs to be calculated
            if obj.isCalcBG
                % detects the new video phases
                obj.detectVideoPhases();  
                if ~obj.calcOK
                    % if the user cancelled, then exit
                    sFlag = 1;
                    return
                end
                
                % initialises the initial tracking object
                if strContains(obj.iMov.bgP.algoType,'single')
                    % case is tracking single objects
                    trkObjI = SingleTrackInit(obj.iData);    
                    set(trkObjI,'wOfsL',1+obj.isMultiBatch,'isBatch',true); 
                    
                else
                    % case is tracking multiple objects
                    trkObjI = feval('runExternPackage',...
                                    'MultiTrack',obj.iData,'Init'); 
                end                                                       
                
                % runs the initial tracking/background estimate
                set(trkObjI,'prData0',prData);
                trkObjI.calcInitEstimate(obj.iMov,obj.hProg);                

                % if the user cancelled, then exit                                
                if ~trkObjI.calcOK
                    sFlag = 1;
                    return
                end
                
                % retrieves the 
                obj.iMov = trkObjI.iMov;
                
                % if the solution tracking GUI is open then reset it
                hTrack = findall(0,'tag','figFlySolnView');
                if ~isempty(hTrack)
                    try
                        % pause to refresh
                        pause(0.05);       
                        
                        % updates the sub-region data struct
                        iMovOrig = get(obj.hFig,'iMov');
                        set(obj.hFig,'iMov',obj.iMov);
                        
                        % attempts to updates the solution view GUI
                        hTrack.initFunc(guidata(hTrack),1)
                        set(obj.hFig,'iMov',iMovOrig,'hSolnT',hTrack)                    

                        % pause to refresh
                        pause(0.05);

                    catch
                        % if there was an error, then reset the GUI handle
                        set(obj.hFig,'hSolnT',[])   
                    end      
                end
                
                % ensures the sub-region data struct reflects the previous 
                % solution file
                if iFile > 1
                    obj.bData(iDir).movOK(iFile) = ...
                                        1 - 2*any(obj.iMov.vPhase == 4);  
                    obj.realignSubRegionData();
                end
                
            else
                % otherwise, set the status flag for the video
                notOK = obj.iMov.vPhase == 4;
                obj.bData(iDir).movOK(iFile) = 1-all(notOK)-2*any(notOK);                                                
            end
            
            % initialises the plot markers to their current status
            if obj.bData(iDir).movOK(iFile) ~= 0
                set(obj.hFig,'iMov',obj.iMov);
                obj.initMarkerPlots(obj.hGUI,1)
            end         
            
            % makes the waitbar figure visible again
            try
                obj.hProg.setVisibility('on')
                uistack(obj.hProg.hFig,'top'); 
                pause(0.05);   
                
            catch
                sFlag = 2;
            end            
        end
        
        % --- detects the fly locations over all phases
        function detectVideoPhases(obj)
            
            % collapses the waitbar figure            
            dLvl = 1 + obj.isMultiBatch;
            obj.hProg.collapseProgBar(dLvl);

            % creates the video phase class object
            iLvl = dLvl + 1;
            phObj = VideoPhase(obj.iData,obj.iMov,obj.hProg,iLvl);

            % runs the phase detection solver            
            obj.hProg.Update(iLvl,'Determining Video Phases...',0);
            phObj.runPhaseDetect();
            
            % expands the waitbar figure again
            if obj.hProg.Update(iLvl,'Phase Detection Complete!',1)
                obj.calcOK = false;
            else
                % updates the sub-image data struct with the phase info
                obj.iMov.iPhase = phObj.iPhase;
                obj.iMov.vPhase = phObj.vPhase;          

                % expands the progressbar
                obj.hProg.expandProgBar(dLvl);
            end

        end        
        
        % --- resets the sub-region data struct
        function resetSubRegionData(obj)
            
            % initialisations
            i = 2 + obj.isMultiBatch;
            solnFile = fullfile(obj.outDir,[obj.fNameBase0,'.soln']);
            
            % updates the waitbar figure                    
            obj.hProg.Update(i,'Loading Initial Solution File...',0.5);
            solnData0 = load(solnFile,'-mat');             
            obj.hProg.Update(i,'Initial Solution File Load Complete',1);
            
            % sets the sub-movie/tube data structs                
            solnData0 = backFormatSoln(solnData0);    
            
            % sets the previous status/background image arrays
            obj.iMov0 = solnData0.iMov;     

            % resets the status flags any reject
            for iApp = 1:length(obj.iMov0.Status)
                obj.iMov0.Status{iApp}(~obj.iMov0.flyok(:,iApp)) = 3;
            end                   

            % sets locations of the flies at the end of the previous video
            obj.p0Pr = cellfun(@(x)(cellfun(@(y)(y(end,:)),x,...
                                'un',0)),solnData0.pData.fPosL,'un',0);            
        end
        
        % --- opens a new solution file
        function openNewSolnFile(obj,iDir,iFile)
            
            % makes the waitbar figure invisible 
            obj.hProg.setVisibility('off')                                                       
            
            % removes any temporary files already stored and resets the
            % progress data struct
            obj.iMov = resetProgressStruct(obj.iData,obj.iMov,true);
            obj.updateVideoOffset(iDir,iFile)            
            
            % sets the new solution file name     
            [obj.sFileNw,fNameBase] = obj.getSolnFileName(iDir,iFile);                        
            if ~exist(obj.sFileNw,'file')
                % is no solution file exists, then output a dummy file
                obj.outputSolutionFile(iDir,iFile,1);
                obj.isCalcBG = true;
                
            else                    
                % otherwise, determine if the background need calculating
                if iFile == 1
                    % first video, so background already calculated
                    obj.isCalcBG = obj.forceCalcBG;
                    
                else
                    % other videos, so load the solution file
                    BT = load(obj.sFileNw,'-mat');
                    if (isempty(BT.pData))
                        % no position data, so calculate background
                        obj.isCalcBG = true;
                        
                    else
                        % otherwise, if at least one frame stack had been
                        % calculated, then no need to calculated background
                        [iFly,iApp] = find(obj.iMov.flyok,1,'first');
                        obj.isCalcBG = ...
                                all(isnan(BT.pData.fPos{iApp}{iFly}(:,1)));
                    end
                end
            end                        
            
            % opens the solution file
            e = struct('fName',[fNameBase,'.soln'],'fDir',obj.outDir);
            obj.menuOpenSoln(obj.hGUI.menuOpenSoln,e,obj.hGUI)    
            obj.dispImage(obj.hGUI)                    
            
            % retrieves the important data struct from the tracking GUI
            obj.pData0 = get(obj.hFig,'pData');
            obj.iMov = get(obj.hFig,'iMov');                        
            
            % if the solution tracking GUI is open then reset it
            hTrack = findall(0,'tag','figFlySolnView');
            if ~isempty(hTrack)
                try
                    % pause to refresh
                    pause(0.05);         
                    
                    % removes the phase field
                    vPhase0 = obj.iMov.vPhase;
                    obj.iMov.vPhase = [];
                    set(obj.hFig,'iMov',obj.iMov)
                    
                    % attempts to updates the solution view GUI
                    set(obj.hGUI.checkShowMark,'value',0)
                    set(obj.hFig,'pData',[])
                    hTrack.initFunc(guidata(hTrack),1)
                    
                    % resets the phase field
                    obj.iMov.vPhase = vPhase0;
                    set(obj.hFig,'iMov',obj.iMov,'hSolnT',hTrack)                    
                    
                    % pause to refresh
                    pause(0.05);
                    
                catch
                    % if there was an error, then reset the GUI handle
                    set(obj.hFig,'hSolnT',[])   
                end        
            end                              
            
            % makes the waitbar figure visible again
            obj.hProg.setVisibility('on')              
            
        end
        
        % --- calculates the video offset between the current/first file
        function dpImg = calcVideoOffset(obj,iDir,iFile)
            
            % parameters
            pTolDiff = 10;
            
            % retrieves the 
            Img0 = obj.bData(iDir).Img0;
            fStr = obj.bData(iDir).mName{iFile};            
            
            % hisogram matches the images
            ImgNw = obj.getFeasComparisonImage(fStr); 
            if abs(mean2(Img0) - mean2(ImgNw)) > pTolDiff
                ImgNw = double(imhistmatch(uint8(ImgNw),uint8(Img0),256));
            end
            
            % calculates the video offset between the new/candidate frames
            dpImg = flip(roundP(fastreg(ImgNw,Img0)));
            
        end
            
        % --- waits for the next valid recorded video to turn up
        function ok = getNextRecordedVideo(obj,iDir,iFile)
            
            % initialisations
            ok = true;
            wOfs = 2 + obj.isMultiBatch;
            bdata = obj.bData(iDir);
            
            % waits for the summary file to become available
            if ~waitForRecordedFile(bdata.sName,[],obj.hProg,wOfs)
                % if the user cancelled, or there was a timeout, then exit
                ok = false;
                return
            end
            
            % loads the experimental data from the summary file
            A = load(bdata.sName,'-mat','iExpt');  
            
            % collapses down the waitbar figure
            hh0 = getHandleSnapshot(findall(obj.hProg.hFig));
            obj.hProg.collapseProgBar(2);               
            
            % waits for the file to finish recording
            if ~waitForRecordedFile(...
                            bdata.mName{iFile},A.iExpt,obj.hProg,wOfs)  
                % if the user cancelled, or there was a timeout, then exit
                ok = false;
                return    
            end
            
            % attempts to load the summary file. if there is an issue
            % (i.e., it is still saving) then wait until the summary
            % file is finished.
            wStrNw = 'Waiting For Summary File Output...';
            obj.hProg.Update(2+obj.isMultiBatch,wStrNw,0); 
            
            pause(1);            
            while (1)
                try 
                    load(bdata.sName);
                    break
                catch
                    pause(1);
                end
            end                

            % if everything was ok, then reset the waitbar figure
            resetHandleSnapshot(hh0)    
            
            % re-copies the summary file from the movie directory to
            % the solution file output directory
            obj.copySummaryFile(bdata)        
        end
            
        % --- determines if new videos have turned up (if still recording)
        function updateVideoInfo(obj,iDir)
            
            % clears java memory stack
            try; jheapcl; end

            % scans the movie directory to see if new videos have turned
            % up. if so then reset the movie file name array and file count        
            mName = detectMovieFiles(obj.bData(iDir).MovDir);
            if length(mName) > obj.nFile
                % resets the file count and movie names
                obj.nFile = length(mName);
                obj.bData(iDir).mName = cellfun(@(x)(fullfile(...
                                obj.bData(iDir).MovDir,x)),mName,'un',0);

                % expands the boolean arrays to accomodate the new videos
                nNew = nFileT-length(obj.isSeg);
                obj.isSeg = [obj.isSeg;false(nNew,1)];
                obj.bData(iDir).movOK = ...
                            [obj.bData(iDir).movOK;ones(nNew,1)];                        
            end  
            
        end
        
        % --- creates a new solution file (depending on type)
        function outputSolutionFile(obj,iDir,iFile,isDummy)
            
            % create a summy file
            a = 1;
            save(obj.sFileNw,'a')            
            
            % updates the solution file information            
            obj.iData.sfData = dir(obj.sFileNw);
            obj.iData.sfData.dir = obj.outDir;  
            summFile = fullfile(obj.outDir,'Summary.mat');
            
            % if the experiment data struct is not set, then retrieve 
            % from summary file
            summData = load(summFile);
            if ~isfield(obj.iData,'iExpt')                
                obj.iData.iExpt = summData.iExpt;
            end
            
            % updates the image offset array (if available)
            if isfield(obj.bData(iDir),'dpImg')
                summData.dpImg = obj.bData(iDir).dpImg;
                save(summFile,'-struct','summData')
            end                
            
            %
            if isDummy
                % outputs the solution file without the waitbar figure
                saveSolutionFile(obj.sFileNw,obj.iData,obj.iMov,[])                
            else
                % updates the waitbar figure and saves the .soln file
                obj.hProg.Update(5,'Saving Solution File...',1);    
                saveSolutionFile(obj.sFileNw,obj.iData,obj.iMov,obj.pData)
                
                % outputs the partial solution summary data file (if requested)
                if isfield(obj.bData(iDir),'sfData')
                    if obj.bData(iDir).sfData.isOut
                        % retrieves the experiment data struct
                        outputSolnSummaryCSV(...
                                obj.bData(iDir),obj.pData,obj.iMov,iFile)
                    end
                end    

                % updates the waitbar figure again
                obj.hProg.Update(5,'Solution File Save Complete!',1);                 
            end
        end        
        
        % ----------------------------------------- %
        % ---- OBJECT INITIALISATION FUNCTIONS ---- %
        % ----------------------------------------- %
        
        % --- initialises the function handle objects
        function initFuncObj(obj)
            
            % function handle strings
            fldStr = fieldnames(get(obj.hFig));
            fcnStr = {'initMarkerPlots','checkShowTube','checkShowMark',...
                      'menuViewProgress','menuOpenSoln','dispImage'};
                  
            % retrieves all functions in the fcnStr list
            for i = 1:length(fcnStr)
                % determines the matching function string
                indM = strContains(fldStr,fcnStr{i});
                
                % sets the function handle into the class object
                fcnHandle = get(obj.hFig,fldStr{indM});
                set(obj,fcnStr{i},fcnHandle);                
            end
            
        end
                     
        % ------------------------------- %        
        % ---- START VIDEO DETECTION ---- %
        % ------------------------------- %        
        
        % --- determines the batch processing starting point
        function iFile0 = detectStartPoint(obj,exP0,iDir)
            
            % initialisations
            iFile0 = 1;
            
            % determines if the output directory exists
            if ~exist(obj.outDir,'dir')
                % if not, the create it and set the experiment parameters
                mkdir(obj.outDir);
                obj.iData.exP = exP0;
                
            else
                % otherwise, determine the solution files that have 
                % already been analysed. 
                sName = dir(fullfile(obj.outDir,'*.soln'));
                if isempty(sName)
                    % if there are none then set the experiment data struct
                    obj.iData.exP = exP0;   
                    
                else
                    % initialisations
                    nFileNw = length(sName);
                    [cont,obj.setSoln] = deal(true,false);
                    
                    % --------------------------------------- %   
                    % --- TEMPORARY SOLUTION FILE REMOVAL --- %
                    % --------------------------------------- %                           

                    % determines if the temporary solution file exists 
                    % within the solution files that were detected
                    sFile = field2cell(sName,'name');
                    ii = cellfun(@(x)(strcmp(x,'Temp.soln')),sFile); 
                    if any(ii)
                        % if so, determine if it is the only one (in which 
                        % case read the data) or if there is more than one 
                        % (in which case it should be removed)
                        if length(ii) == 1
                            % loads the solution file data structs
                            A = load(fullfile(obj.outDir,...
                                                    sName(1).name),'-mat');             
                            [obj.iData.exP,obj.iMov] = deal(A.exP,A.iMov);    
                            [nFileNw,cont] = deal(0);
                            
                        else
                            % otherwise remove the temporary solution files
                            delete(fullfile(obj.outDir,sName(ii).name));   
                            [sName,nFileNw] = deal(sName(~ii),sum(~ii));                    
                        end
                    end     
                    
                    % ---------------------------------------- % 
                    % --- FINISHED SOLUTION FILE DETECTION --- %
                    % ---------------------------------------- %                       
                    
                    % keep searching 
                    while cont
                        % determines the first fully segmented video
                        B = load(fullfile(obj.outDir,...
                                            sName(nFileNw).name),'-mat'); 

                        % resets the sub-region struct to the loaded files
                        [obj.iMov,obj.iMov0] = deal(B.iMov);                                        
                                        
                        if ~isempty(B.pData)
                            % determines
                            i0 = find(obj.iMov.ok,1,'first');
                            j0 = find(obj.iMov.flyok(:,i0),1,'first');
                            
                            % determines the non-NaN frames (removes any
                            % high-variance/infeasible phases)
                            iPh = obj.iMov.iPhase;
                            isSegT = ~isnan(B.pData.fPos{i0}{j0}(:,1));
                            for i = find(obj.iMov.vPhase(:) == 3)
                                isSegT(iPh(i,1):iPh(i,2)) = true;
                            end
                            
                            if all(isSegT)
                                % if all phases are segmented, then use the
                                % next video for analysis
                                cont = false;
                                nFileNw = nFileNw + 1;   
                                
                            elseif any(isSegT)
                                % exit if all have been segmented correctly
                                cont = false;
                            end
                            
                            % 
                            if ~cont
                                obj.isSeg(1:(nFileNw-1)) = true;
                                obj.isSeg(nFileNw) = all(cellfun(@(x)...
                                                (all(x)),B.pData.frmOK));                                
                            end
                        end

                        % otherwise, decrement the movie index counter. if 
                        % the counter has reached zero, then exit the loop
                        if cont
                            nFileNw = nFileNw - 1;
                            if nFileNw == 0
                                cont = false;
                            end
                        end                                            
                    end
                    
                    % -------------------------------------------- % 
                    % --- BATCH PROCESSING CONTINUATION PROMPT --- %
                    % -------------------------------------------- % 
                    
                    % if there are valid files, then prompt the user for
                    % the start point (either continuing, restarting from a
                    % specific video, or cancelling)
                    if nFileNw > 0
                        % prompt the user for the start video
                        iFile0 = obj.promptUserCont(sName,iDir,nFileNw);                        
                        if isnan(iFile0)
                            % if the user cancelled, then reload the 
                            % original solution file
                            obj.resetObjProps();                             
                        end
                    end
                end                
            end            
            
        end            
        
        % --- prompts the user how they wish to continue
        function iFile0 = promptUserCont(obj,sName,iDir,nFileNw)
            
            % sets the continuation string based on the type/user input
            if obj.isMultiBatch            
                % continues if batch processing multiple directories
                uChoice = 'Continue';
                
            else
                % sets the progressbar to be invisible
                obj.hProg.setVisibility('off'); 
                
                % otherwise, prompt the user if they want to continue
                tStr = 'Overwrite Current Solution?';
                qhStr = sprintf('Full Directory = "%s"\n',obj.outDir);
                qStr = sprintf(['Number of segmented videos = %i\n',...
                                'Number of videos yet to track = %i\n',...
                                '\nDo you wish to continue or restart?'],...
                                nFileNw,obj.nFile);

                % otherwise, prompt the user if they want to overwrite 
                uChoice = questdlg([{qhStr};num2cell(qStr,2)],tStr,...
                        'Continue','Restart From...','Cancel','Continue');
            end
                               
            % sets initial file index based on the continuation type
            switch uChoice
                case 'Continue'
                    % case is continuing from the current point
                    iFile0 = nFileNw;

                case 'Restart From...'
                    % case is restarting from a specific point
                    iFile0 = obj.promptStartVideo(sName,iDir,nFileNw);
                                        
                otherwise
                    % case is the user cancelled
                    iFile0 = NaN;

            end
                        
            % determines if the user cancelled
            if ~isnan(iFile0)
                % otherwise, sets the progressbar to be visible again
                obj.hProg.setVisibility('on'); pause(0.05);
            end
            
        end
        
        % --- prompts the user for the start processing video
        function iFile0 = promptStartVideo(obj,sName,iDir,nFileNw)
            
            % initialisations
            bdata = obj.bData(iDir);
            inStr = {'Enter video to restart from:'};
            defVal = {num2str(nFileNw)};
            
            % keep prompting the user until a valid value has been entered
            % or the user cancelled
            while 1
                % prompts the user for the video file index
                nwVal = inputdlg(inStr,'Restart From...',1,defVal);
                if isempty(nwVal)
                    % if the user cancelled, then exit the function
                    iFile0 = NaN;
                    return
                    
                else
                    % checks to see if the new value is value
                    nwVal = str2double(nwVal);
                    if chkEditValue(nwVal,[0 nFileNw],1)
                        % if so, then reset the values
                        obj.isSeg((nwVal+1):end) = false;
                        obj.bData(iDir).movOK((nwVal+1):end) = 1;
                        obj.setSoln = nwVal == 0;                                                                                                  

                        % removes the data from the partial solution 
                        % data (if outputting to file)                                     
                        if bdata.sfData.isOut
                            if nwVal == 0
                                rmvPartialSolnData(bdata,0)                                            
                            else
                                rmvPartialSolnData(bdata,nwVal,...
                                            obj.iMov,sName(nwVal).name)
                            end
                        end         

                        % removes all solution files after the specified 
                        % start point (if any such files exist)
                        indFile = (nwVal+1):(nFileNw);
                        sNameD = field2cell(sName(indFile),'name');
                        if ~isempty(sNameD)
                            sNameF = cellfun(@(x)(fullfile(...
                                        obj.outDir,x)),sNameD,'un',0);
                            cellfun(@(x)(delete(x)),sNameF);
                        end                                    

                        % exits the loop
                        iFile0 = max(1,nwVal);   
                        break
                    end
                    
                end
            end
        end        
        
        % --------------------------------- %        
        % ---- DATA FILE I/O FUNCTIONS ---- %
        % --------------------------------- %
        
        % --- sets up the experiment summary file
        function setupSummaryFile(obj,bdata)
            
            % determines if the summary file exists
            if exist(obj.outSumm,'file')
                % if so compare the time stamps to see if they match
                [a0,a1] = deal(load(bdata.sName),load(obj.outSumm));
                
                % checks the video time stamps
                copySumm = ~all(cellfun(@(x,y)...
                                (isequal(x,y)),a0.tStampV,a1.tStampV));   
                if (strcmp(a0.iExpt.Info.Type,'RecordStim'))
                    % checks the stimuli time stamps (stimuli expt only)
                    copySumm = copySumm || ~all(cellfun(@(x,y)...
                                    (isequal(x,y)),a0.tStampS,a1.tStampS));
                end                            
            else
                % if not, then ensure the summary file is copied over
                copySumm = true;
            end
            
            % copies the summary file from the movie file directory to the
            % output solution file directory (if required)
            if copySumm
                obj.copySummaryFile(bdata)                
            end            
        end
        
        % --- copies the summary file from the batch processing video
        %     directory to the output solution file directory
        function copySummaryFile(obj,bdata)
           
            try        
                copyfile(bdata.sName,obj.outDir,'f');
            catch
                % if there was an error, then open the summary file and
                % save the file directly (error on OSX machines?)                    
                summData = load(bdata.sName);
                save(obj.outSumm,'-struct','summData');
            end                
            
        end
        
        % --- initialises an empty solution file
        function createShellSolnFile(obj,iDir,iFile)
            
            % initialisations
            bdata = obj.bData(iDir);
            [i0,movStr] = deal(1,obj.iData.movStr);            
            
            % keep looping until a feasible video is found
            while 1
                % reloads the current movie and sets the parameters   
                obj.reloadImgData(iDir,i0);                
                if obj.bData(iDir).movOK(i0)
                    % resets the progress data struct and BG flag
                    obj.iMov = resetProgressStruct(obj.iData,obj.iMov,1); 
                    obj.forceCalcBG = ~strcmp(movStr,bdata.mName{i0});
                    
                    % calculates the video offset
                    obj.updateVideoOffset(iDir,iFile);
                    
                    % sets the new solution file name            
                    [~,fNameBase,~] = fileparts(bdata.mName{i0});
                    obj.sFileNw = fullfile(obj.outDir,[fNameBase,'.soln']);
                    
                    % creates the shell solution file
                    obj.outputSolutionFile(iDir,i0,1);
                    
                    % exits the search loop
                    break
                    
                else
                    % if there was an error, then increment the counter
                    i0 = i0 + 1;
                end                
            end
            
        end
        
        % --- reloads the image data struct with the movie, mName --- %
        function reloadImgData(obj,varargin)
            
            % sets the input variables (based on input argument count)
            if nargin == 3
                % case is the file/directory indices were given
                [iDir,iFile] = deal(varargin{1},varargin{2});
                mFileNw = obj.bData(iDir).mName{iFile};
            else
                % case is the movie file name has been given
                mFileNw = varargin{1};
            end
            
            % loads the current movie parameters into the data struct
            [fDir,fName,fExtn] = fileparts(mFileNw);
            [a,obj.iData] = loadImgData(obj.hGUI,...
                            [fName,fExtn],fDir,0,1,obj.iData,obj.iMov); 
        
            % updates the acceptance flag values    
            if exist('iDir','var')
                obj.bData(iDir).movOK(iFile) = double(a);   
            end
        
        end        
        
        % --------------------------------- %        
        % ---- MISCELLANEOUS FUNCTIONS ---- %
        % --------------------------------- %        
        
        % --- retrieves for the solution file directory, iDir 
        function fDir = getSolnFileDir(obj,iDir)
           
            fDir = fullfile(obj.bData(iDir).SolnDir,...
                            obj.bData(iDir).SolnDirName);
            
        end        
        
        % --- retrieves the solution file name for the given directory/file
        function [sFileNw,fNameBase] = getSolnFileName(obj,iDir,iFile)
            
            [~,fNameBase,~] = fileparts(obj.bData(iDir).mName{iFile});
            sFileNw = fullfile(obj.outDir,[fNameBase,'.soln']);
            
        end
        
        % --- checks the recording status of the videos
        function checkVideoStatus(obj)
                        
            % memory allocation
            obj.nDir = length(obj.bData); 
            obj.isRecord = true(obj.nDir,1); 
            obj.isMultiBatch = obj.nDir > 1;
            
            % determines if any of the directories are still recording
            for i = 1:obj.nDir
                % determines if the summary file exists
                if exist(obj.bData(i).sName,'file')                
                    % if so, retrieves the experiment data struct
                    A = load(obj.bData(i).sName,'-mat','iExpt'); 
                    TT = A.iExpt.Timing;
                    VV = A.iExpt.Video;
                    II = A.iExpt.Info;
                    
                    % calculates the end time of the experiment            
                    TendV = addtodate(datenum(TT.T0),...
                                vec2sec(TT.Texp)+obj.TwaitEnd,'second');
                            
                    % determines if the video is still recording (i.e., if
                    % time between the experiment's end and now is > 0)
                    obj.isRecord(i) = ...
                            calcTimeDifference(datevec(TendV),clock) > 0;
                    if obj.isRecord(i)
                        % if still recording, then expand the movie names 
                        % array to account for all the nominated movies
                        obj.bData(i).mName = ...
                                setBPMovieNames(obj.bData(i).MovDir,VV,II);                
                    end                            
                    
                end
            end
                
        end      
        
        % --- waits until the relevant video has finished recording
        function ok = videoRecordWait(obj,bdata)
            
            % initialisations
            ok = true;
            
            % sets the waitbar figure to invisible
            wOfs = 2 + obj.isMultiBatch;
            hh0 = getHandleSnapshot(findall(obj.hProg.hFig));
            obj.hProg.collapseProgBar(2);

            % if the summary file has not yet turned up, then wait for it 
            if ~exist(bdata.sName,'file')
                if ~waitForRecordedFile(bdata.sName,[],obj.hProg,wOfs)
                    % if the user cancelled, or a timeout, then exit
                    ok = false;
                    return
                end
            end

            % loads the experiment information from the summary file
            A = load(bdata.sName,'-mat','iExpt');
            if ~waitForRecordedFile(...
                       bdata.mName{obj.iFile0},A.iExpt,obj.hProg,wOfs)
                % if the user cancelled, or there was a timeout, then exit
                ok = false;
                return 
                
            else
                % if everything was ok, then reset the waitbar figure
                resetHandleSnapshot(hh0)
            end                    
            
        end        
        
        % --- resets the object properties (in the user cancels when
        %     prompted for continuing tracking)
        function resetObjProps(obj)
            
            % if the user cancelled, then reset to the original state
            resetHandleSnapshot(obj.hProp0,obj.hFig); 
            obj.checkShowTube(obj.hGUI.checkShowTube,1,obj.hGUI)                                    
            
            % reloads the image data
            fName0 = fullfile(obj.iData0.fData.dir,...
                              obj.iData0.fData.name);
            obj.reloadImgData(fName0);              
            
            % closes the progressbar 
            obj.hProg.closeProgBar();
            
        end              
        
        % --- updates the batch processing file
        function updateBPFile(obj,bData)
            
            % if the output directory doesn't exist, create it
            if ~exist(obj.outDir,'dir')
                mkdir(obj.outDir)
            end
            
            % re-saves the batch processing data file
            eval(sprintf('save(''%s'',''bData'')',obj.bFile))
            
        end    
        
        % --- realigns the sub-region data structs
        function realignSubRegionData(obj)
            
            % only concerned with background subtraction algorithms
            if ~strContains(obj.iMov.bgP.algoType,'bgs-')
                return
            end
            
            % retrieves the new status fields
            StatusNw = obj.iMov.Status;
            StatusPr = obj.iMov0.Status;
            nPhase = length(obj.iMov.vPhase);
            
            % determines the index of the first 
            iPr = find(~cellfun(@isempty,obj.iMov0.Ibg),1,'first');

            % loops through all the apparatus checking if the tube statuses
            % have been set correctly. if not, then update the statuses to 
            % reflect the previous
            for j = 1:find(obj.iMov.ok(:)')
                % determines 
                [iCol,~,iRow] = getRegionIndices(obj.iMov,j);
                ii0 = (StatusNw{j} ~= 3) & (StatusPr{j} == 3);
                
                if obj.iMov.is2D
                    a = 1;
                else
                    nFly = obj.iMov.pInfo.nFly(iRow,iCol);
                    ii0((nFly+1):end) = false;
                end
                
                % determines the tubes which in the new video have been
                % classified as feasible, but have been classified as 
                % rejected in the previous                
                ii = find(ii0);
                for k = 1:length(ii)
                    % resets the tube status/rejection flags 
                    obj.iMov.Status{j}(ii(k)) = 3;
                    obj.iMov.flyok(ii(k),j) = false;

                    % resets the background image region 
                    for i = 1:nPhase
                        obj.iMov.Ibg{i}{j}(obj.iMov.iRT{j}{ii(k)},:) = ...
                           obj.iMov0.Ibg{iPr}{j}(obj.iMov.iRT{j}{ii(k)},:);
                    end
                end

%                 % determines the tubes which in the new video have been
%                 % classified as rejected, but were actually stationary in 
%                 % the previous video
%                 ii = find((StatusNw{j} == 3) & (StatusPr{j} == 2));
%                 for k = 1:length(ii)
%                     % resets the tube status/rejection flags 
%                     if (~all(isnan(obj.iMov.pStats{j}(ii(k)).fxPos(:))))
%                         [iMov.Status{j}(ii(k)),iMov.flyok(ii(k),j)] = deal(2,true);
% 
%                         % updates the background image region
%                         % belonging to previous solution
%                         for i = 1:nPhase
%                             iMov.Ib{i}{j}(iMov.iRT{j}{ii(k)},:) = ...
%                                                 IbgPr{iPr}{j}(iMov.iRT{j}{ii(k)},:);
%                             iMov.pStats{j,i}(ii(k)).fxPos = pStatsPr{j,i}(ii(k)).fxPos;
%                         end
%                     end
%                 end    

                % determines the tubes which in the new video have been
                % classified as rejected, but were actually moving in the 
                % previous video. in the new video, these objects are most 
                % likely stationary (instead of rejected)
                ii0 = (StatusNw{j} == 3) & (StatusPr{j} == 1);
                if obj.iMov.is2D
                    a = 1;
                else
                    ii0((nFly+1):end) = false;
                end
                
                ii = find(ii0);
                for k = 1:length(ii)
                    % resets the tube status/rejection flags 
                    obj.iMov.Status{j}(ii(k)) = 2;
                    obj.iMov.flyok(ii(k),j) = true;

                    % updates the background image region
                    % belonging to previous solution
                    for i = 1:nPhase
                        iRTnw = obj.iMov.iRT{j}{ii(k)};
                        obj.iMov.Ibg{i}{j}(iRTnw,:) = ...
                                        obj.iMov0.Ibg{iPr}{j}(iRTnw,:);
                    end
                end        
            end                        
        end
        
        % --- initialises the position data struct
        function initPosDataStruct(obj, iDir)

            % retrieves the index of the current file
            iVid = str2double(regexp(getFileName(...
                    obj.iData.fData.name),'\d+','match'));
            sFile = load(obj.bData(iDir).sName);

            % creates an empty position solution struct 
            % and outputs it to file               
            obj.pData = setupPosDataStruct(obj.iMov,sFile.tStampV{iVid});  

        end        
        
        % --- outputs a message listing the invalid videos (if any) 
        function outputInvalidVideosMsg(obj)
           
            % FINISH ME!
            a = 1;
            
        end        
        
    end
   
end
