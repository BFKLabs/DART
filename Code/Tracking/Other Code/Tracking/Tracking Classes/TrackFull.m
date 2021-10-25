classdef TrackFull < Track
    
    % class properties
    properties
        
        % main data fields
        pData
        sProg        
        prData = [];     
        sObj
        
        % initial values
        iPhase0       
        iStack0  
        
        % sorted phase array fields
        iPhaseS
        nCountS
        iFrmG
        
        % miscellaneous fields
        tDir
        wStr         
        
        % boolean/flag fields
        hasProg = false;
        isMultiBatch = false;
        solnChk = false;
        wOfs1 = 1;
        nLvl        
        
        % function handles
        dispImage
        
    end        
    
    % class methods
    methods
        
        % class constructor
        function obj = TrackFull(iData,isMulti)
            
            % creates the tracking object
            obj@Track(iData,isMulti);           
            
        end
        
        % ------------------------------------- %
        % --- FULL VIDEO TRACKING FUNCTIONS --- %
        % ------------------------------------- %
        
        % --- segments the locations for all flies within the entire video
        function segEntireVideoFull(obj)
        
            % initialises the tracking objects
            obj.initTrackingObjects('Detect');
            obj.initOtherClassFields();
            
            % starts the video tracking
            obj.startVideoTracking();                                       
            
        end
        
        % ---------------------------------- %
        % --- OBJECT DETECTION FUNCTIONS --- %
        % ---------------------------------- %
        
        % --- starts the video tracking 
        function startVideoTracking(obj)
           
            % initialises the position data struct
            obj.initPosDataStruct();
            if ~obj.calcOK
                % deletes the progress bar
                obj.hProg.closeProgBar();
                
                % exits the function
                return
            end            
            
            % determines the phase order (low-variance phases to be
            % segmented first)
            [~,obj.iPhaseS] = sort(obj.iMov.vPhase);            
            
            % ensures the progressbar is visible
            obj.hProg.setVisibility('on');
            
            % segments the objects from start phase to end
            for i = obj.iPhase0:obj.nPhase
                % updates the progessbar (if it exists)
                if ~isempty(obj.hProg)
                    % updates the progressbar phase field
                    wStrNw = sprintf('%s (Phase %i of %i)',...
                                        obj.wStr{obj.wOfs1},i,obj.nPhase);
                    if obj.hProg.Update(obj.wOfs1,wStrNw,i/obj.nPhase)
                        % if the user quit, then exit the function
                        obj.calcOK = false; 
                        break
                    else
                        % otherwise, reset the other progressbar fields
                        obj.resetProgBarFields(1);
                    end
                end
                
                % sets the phase to be segmented
                j = obj.iPhaseS(i);
                
                % resets the progress struct
                switch obj.iMov.vPhase(j)
                    case {1,2}
                        % case is a low/high-variance phase
                        
                        % resets the progress data struct
                        obj.resetProgressStruct(j);  
                        
                        % segments the current phase
                        obj.segVideoPhase(j);
                        
                    otherwise
                        % case is an untrackable phase
                        obj.pData.isSeg(j) = true;
                        
                end
                      
                % post-phase segmentation operations
                if ~obj.calcOK
                    % if user cancelled, then exit the loop
                    break
                else
                    % otherwise, update the segmentation flag
                    [obj.pData.isSeg(j),obj.iStack0] = deal(true,0);
                end                
            end
            
            % updates the data structs into the main GUI
            set(obj.hFig,'iMov',obj.iMov);
            set(obj.hFig,'pData',obj.pData);
            
        end  
        
        % --- segements all the frames for the video phase, iPhase
        function segVideoPhase(obj,iPhase)
            
            % ------------------------------------------- %
            % --- INITIALISATIONS & MEMORY ALLOCATION --- %
            % ------------------------------------------- %              
            
            % other flag initialisation
            nStack = length(obj.sProg.iFrmR);
            nCountNw = max(0,obj.pData.nCount(iPhase));
            vPh = obj.iMov.vPhase(iPhase);
            bOfs = obj.isBatch + obj.isMultiBatch;
            
            % updates the progressbar fields (single tracking only)
            if ~obj.isMulti
                % resets the waitbar figure based on phase/algorithm type
                switch vPh
                    case 1
                        % case is background estimation 
                        if obj.nLvl == (4 + bOfs)
                            obj.nLvl = 3 + bOfs;
                            obj.hProg.collapseProgBar(1)
                        end

                    case 2
                        % case is direct detect
                        if obj.nLvl == (3 + bOfs)
                            obj.nLvl = 4 + bOfs;
                            obj.hProg.expandProgBar(1)
                        end

                end        
                
                % sets the progress bar level offset
                wOfsNw = (bOfs + 1) + (vPh > 1);
                
            else
                % sets the progress bar level offset
                wOfsNw = bOfs + 2;
            end
            
            % retrieves the positional data from the previous phase
            if iPhase == 1
                % first phase, so no previous positional data
                fPosPr = [];
                
            elseif obj.iMov.vPhase(iPhase-1) == 3
                % if previous phase is hi-variance, then no positional data
                fPosPr = [];
                
            else
                % otherwise, retrieve the data from the tracking object
                fPosPr = obj.fObj{iPhase-1}.fPos;
            end
            
            % sets the previous data from the current tracking state
            if (iPhase == 1) && (nCountNw == 0)
                % case is the this is the first video stack
                prDataPh = obj.prData;  
                
            elseif ~isempty(fPosPr)
                % otherwise, if data from the previous phase object is
                % available then use these values
                iPhPr = iPhase-1;
                iFrmF = obj.iMov.iPhase(iPhPr,2);
                prDataPh = obj.sObj.getPrevPhaseData(obj.fObj{iPhPr},iFrmF); 
                
            else
                % if there is no positional data, then retrieve the
                % data values from the last valid frame
                if length(obj.sProg.iFrmR) == nCountNw
                    iFrmLast = obj.sProg.iFrmR{end}(1)-1;
                else
                    iFrmLast = obj.sProg.iFrmR{nCountNw+1}(1)-1;
                end
                
                % sets up the previous phases data struct
                prDataPh = obj.sObj.setupPrevPhaseData(iFrmLast,iPhase);
                
            end
            
            % sets the tracking object properties
            set(obj.fObj{iPhase},'iMov',obj.iMov,'wOfs',wOfsNw,...
                                 'hProg',obj.hProg,'iPh',iPhase,'vPh',vPh);

            % sets the phase dependent fields
            switch obj.iMov.vPhase(iPhase)
                case 2
                    % case is a low-variance phase
                    [vPh,dN,i2] = deal(obj.iMov.vPhase,10,[]);

                    % sets the pre phase frame indices
                    i0 = find(vPh(1:iPhase-1)==1,1,'last');
                    if ~isempty(i0)
                        xiF = max(1,length(obj.iFrmG{i0})-[(dN-1),0]);
                        i2 = [i2,obj.iFrmG{i0}(xiF(1):xiF(2))];
                    end

                    % sets the post phase frame indices
                    i1 = find(vPh(iPhase+1:end)==1,1,'first')+iPhase;
                    if ~isempty(i1)
                        N = length(obj.iFrmG{i1});
                        xiF = min(N,[1,dN]);
                        i2 = [i2,obj.iFrmG{i1}(xiF(1):xiF(2))];                            
                    end

                    % sets up the interpolation data
                    pInt = struct('fPos',[],'iFrm',i2);
                    pInt.fPos = cellfun(@(x)(cellfun(@(y)...
                           (y(i2,:)),x,'un',0)),obj.pData.fPosL,'un',0);
                    set(obj.fObj{iPhase},'pInt',pInt);
            end            
            
            % ------------------------------ %
            % --- FLY LOCATION DETECTION --- %
            % ------------------------------ %            
            
            % loops through each image stacks segmenting fly locations
            for i = max(1,(obj.pData.nCount(iPhase)+1)):nStack
                % updates the progressbar (if one is available)
                if ~isempty(obj.hProg)
                    wStrNw = sprintf('%s (Stack %i of %i)',...
                                        obj.wStr{obj.wOfs1+1},i,nStack);
                    if obj.hProg.Update(obj.wOfs1+1,wStrNw,i/nStack)
                        % if the user cancelled, then exit
                        obj.calcOK = false; 
                        return
                    else
                        % otherwise, reset the other progressbar fields
                        obj.resetProgBarFields(2);
                    end               
                end  
                
                % retrieves & sets the new image stack 
                Img = obj.getImageStack(obj.sProg.iFrmR{i});
                if ~isempty(obj.hS)
                    % applies the image filter (if set)
                    Img = cellfun(@(x)(imfilter(x,obj.hS)),Img,'un',0);
                end
                
                % updates the tracking object class fields                
                set(obj.fObj{iPhase},'Img',Img,'prData',prDataPh,...
                                     'iFrmR',obj.sProg.iFrmR{i});
                                    
                % runs the direct detection algorithm
                obj.fObj{iPhase}.runDetectionAlgo();   
                if ~obj.fObj{iPhase}.calcOK
                    % if the user cancelled, then exit the function
                    obj.calcOK = false;
                    return
                end
                
                % retrieves the data for the current stack
                prDataPh = obj.updateTrackingSoln(iPhase,i,nStack);
                
                % updates the solution tracking GUI  
                obj.updateTrackingGUI(i);                           
            end           
        end        
        
        % -------------------------------------------- %
        % ---- TRACKING SOLUTION UPDATE FUNCTIONS ---- %
        % -------------------------------------------- %
        
        % --- updates the tracking solution
        function prData = updateTrackingSoln(obj,iPhase,iStack,nStack)
            
            % determines the number of images that were segmented (all 
            % empty frames have been removed)
            nImg = length(obj.fObj{iPhase}.Img);
            iFrmR = obj.sProg.iFrmR{iStack}(1:nImg);
            
            % retrieves the global frame indices            
            fObjP = obj.fObj{iPhase};
            dX = cellfun(@(x)(x(1)-1),obj.iMov.iC);
            nFrm = length(iFrmR);
            
            % retrieves all values
            for iApp = find(obj.iMov.ok(:)')
                % calculates the offset
                pOfs = repmat([dX(iApp),0],nFrm,1);                                
                for iFly = 1:obj.sObj.getSubRegionCount(iApp)
                    % sets the local/global position values
                    obj.pData.fPos{iApp}{iFly}(iFrmR,:) = pOfs + ...
                        obj.getTrackFieldValues(fObjP.fPos,iApp,iFly);
                    if isprop(fObjP,'fPosL')
                        if ~isempty(fObjP.fPosL)
                            obj.pData.fPosL{iApp}{iFly}(iFrmR,:) = ...
                            obj.getTrackFieldValues(fObjP.fPosL,iApp,iFly);
                        end
                    end
                    
                    % sets the position metric values
                    obj.pData.IPos{iApp}{iFly}(iFrmR) = ...
                             obj.getTrackFieldValues(fObjP.IPos,iApp,iFly);   
                                        
                    % sets the orientation angle (if required)
                    if obj.iMov.calcPhi
                        obj.pData.Phi{iApp}{iFly}(iFrmR) = ...
                            obj.getTrackFieldValues(fObjP.Phi,iApp,iFly);
                        obj.pData.axR{iApp}{iFly}(iFrmR) = ...
                            obj.getTrackFieldValues(fObjP.axR,iApp,iFly); 
                        obj.pData.NszB{iApp}{iFly}(iFrmR) = ...
                            obj.getTrackFieldValues(fObjP.NszB,iApp,iFly);
                    end
                end
            end
            
            % updates the stack count and the positional data struct
            obj.pData.nCount(iPhase) = iStack;
            set(obj.hFig,'pData',obj.pData);
            
            % stores the data from the last frame (used for next stack)
            if iStack <= nStack
                prData = obj.getPrevPhaseData(obj.fObj{iPhase});
            end
            
        end
        
        % --- updates the display image (for the image stack, iStack)
        function updateTrackingGUI(obj,iStack)
            
            % retrieves the solution tracking GUI
            hSolnT = get(obj.hFig,'hSolnT');
            if ~isempty(hSolnT)
                % if it does exist, then update it
                try
                    % attempts to updates the solution view GUI
                    hSolnT.updateFunc(guidata(hSolnT));
                catch
                    % if there was an error, then reset the GUI handle
                    set(obj.hFig,'hSolnT',[])   
                end

                % sets the new frame
                if ~exist('iStack','var')
                    if isempty(obj.sProg)
                        nwFrm = obj.iData.nFrm;
                    else
                        nwFrm = obj.sProg.iFrmR{end}(end);
                    end
                elseif iStack == 0
                    nwFrm = 1;
                else
                    if isempty(obj.sProg)
                        nwFrm = obj.iData.nFrm;
                    else
                        nwFrm = obj.sProg.iFrmR{iStack}(end);
                    end
                end
                
                % updates the main axes with the new image                
                set(obj.hGUI.frmCountEdit,'string',nwFrm)
                obj.dispImage(obj.hGUI)
                pause(0.05);
                
            else
                % updates the frame selection properties
                setTrackGUIProps(obj.hGUI,'UpdateFrameSelection')
            end  
            
        end   
        
        % ---------------------------------------- %
        % ---- POSITION DATA STRUCT FUNCTIONS ---- %
        % ---------------------------------------- %
        
        % --- prompts the user to set their start point and resets the 
        %     positional data struct from there
        function resetData = resetPosDataStruct(obj)
            
            % initialisations
            resetData = false; 
            
            % prompts the user for the restart point
            indS = StartPoint(obj);
            if isempty(indS)
                % user cancelled, so exit 
                obj.calcOK = false; 
                
                % closes the progressbar (if it exists)
                if ~isempty(obj.hProg)
                    obj.hProg.closeProgBar()
                end

                % exits the function
                return        
                
            elseif isequal(indS,[1;1])
                % if set to the restart point, then exit
                [resetData,obj.iPhase0] = deal(true,1);
                return                
            end       
            
            % resets the segmentation flags/arrays 
            jPhase = obj.iPhaseS(indS(1));
            xiS = obj.iPhaseS((indS(1)+1):end);
            [obj.iPhase0,obj.iStack0] = deal(indS(1),indS(2)-1);                        
            obj.pData.isSeg(xiS) = false;
            obj.pData.nCount(xiS) = 0;
            obj.pData.nCount(jPhase) = max(0,indS(2));

            % loads the progress data file            
            pFile = fullfile(obj.tDir,'Progress.mat');
            A = load(pFile); obj.sProg = A.sProg;
            
            % sets the frames that are to be removed
            nFrmS = getFrameStackSize();
            Brmv = false(length(obj.pData.IPos{1}{1}),1);
            Brmv(cell2mat(obj.iFrmG(xiS)')) = true;
            Brmv(obj.iFrmG{jPhase}((indS(2)*nFrmS+1):end)) = true;
            
            % resets the positional arrays
            for i = 1:length(obj.pData.fPos)
                for j = 1:length(obj.pData.fPos{i})
                    % resets the local/global position arrays
                    obj.pData.fPos{i}{j}(Brmv,:) = NaN;
                    obj.pData.fPosL{i}{j}(Brmv,:) = NaN;

                    % if calculating the orientation angles, reset the
                    % associated fields
                    if obj.pData.calcPhi
                        obj.pData.Phi{i}{j}(Brmv,:) = NaN;
                        obj.pData.PhiF{i}{j}(Brmv,:) = NaN;
                        obj.pData.axR{i}{j}(Brmv,:) = NaN;
                        obj.pData.NszB{i}{j}(Brmv,:) = NaN; 
                    end
                end
            end                 
            
        end               
        
        % --- initialises the fly position data struct --- %
        function setupPosDataStructFull(obj)

            % loads the global analysis parameters 
            nFrmS = getFrameStackSize();

            % array length indexing
            nFrm = diff(obj.iMov.iPhase,[],2) + 1;
            nFrmS = obj.iMov.sRate.*floor(nFrmS./obj.iMov.sRate);
            nStack = ceil(nFrm/nFrmS);                 

            % memory allocation 
            [obj.pData,A,B] = obj.sObj.setupPosDataStruct(nFrm);
                           
            % sets the array dependent fields
            obj.pData.IPos = B;
            [obj.pData.fPos,obj.pData.fPosL] = deal(A);
            obj.pData.nCount = zeros(obj.nPhase,1);
            obj.pData.isSeg = false(obj.nPhase,1);
            
            % if calculating the orientation angle, then allocate memory
            if obj.pData.calcPhi
                [obj.pData.Phi,obj.pData.PhiF] = deal(B);
                [obj.pData.axR,obj.pData.NszB] = deal(B);
            end

            % other memory allocations
            obj.pData.frmOK = cell(obj.nPhase,1);
            for i = 1:obj.nPhase
                obj.pData.frmOK{i} = zeros(nStack(i),1);
            end
        
        end
        
        % --- resets the segmentation progress struct --- %
        function resetProgressStruct(obj,iPhase)
            
            % sets the phase indices  
            NN = getFrameStackSize();
            pInd = obj.iMov.iPhase(iPhase,:);

            % retrieves the frame stack size            
            nFrm = diff(pInd) + 1;
            nStack = ceil(nFrm/NN);

            % ------------------------------------------- %
            % --- PROGRESS DATA STRUCT INITIALISATION --- %
            % ------------------------------------------- %

            % initialises the data struct
            sProg0 = struct('movFile',[],'Status',[],'isComplete',0,...
                            'iFrmR',[],'nFrmS',NN);
            
            % sets the struct fields            
            sProg0.movFile = fullfile(obj.iData.fData.dir,...
                                      obj.iData.fData.name);
            sProg0.Status = NaN(nStack,1);  
            sProg0.iFrmR = cell(nStack,1);

            % sets the image stack/video stack indices
            for i = 1:nStack
                sProg0.iFrmR{i} = (((i-1)*NN+1):min(i*NN,nFrm)) + pInd(1)-1;
            end            

            % ------------------------------ %
            % --- PROGRESS STRUCT UPDATE --- %
            % ------------------------------ %                

            % determines if the progress file has been set
            pFile = fullfile(obj.tDir,'Progress.mat');
            if ~exist(pFile,'file') || ~obj.solnChk
                % if not, then initialise the sub-image progress struct
                obj.solnChk = false;
                [obj.sProg,sProg] = deal(sProg0); 
                save(pFile,'sProg');
                pause(0.5);                   
            else
                % otherwise, load the progress file
                A = load(pFile); 
                obj.sProg = A.sProg;
            end    

            % checks to see if the current movie matches the progress 
            % file stack (only if checking the solution)
            if obj.solnChk && ~strcmp(sProg0.movFile,obj.sProg.movFile)
                % if the current and stored movie file names do not match, 
                % then delete the image stack and reset the progress file
                [obj.sProg,sProg] = deal(sProg0);
                save(pFile,'sProg');
                pause(0.5);   
            end
                        
        end       
      
        % ---------------------------------------------------- %            
        % ---- CLASS/DATA STRUCT INITIALISATION FUNCTIONS ---- %
        % ---------------------------------------------------- %
        
        % --- initialises the other class fields
        function initOtherClassFields(obj)
            
            % array dimensioning
            obj.iStack0 = 0;               
            
            % other flag initialisations
            obj.calcOK = true;
            obj.is2D = is2DCheck(obj.iMov);
            obj.tDir = obj.iData.ProgDef.TempFile;     
            
            % function handles
            obj.dispImage = get(obj.hFig,'dispImage');
            
            % creates the progress bar (if not already set)
            if isempty(obj.hProg) || ~obj.hasProg
                % sets the progressbar strings
                obj.wStr = {'Video Tracking Progress',...
                            'Current Video Progress',...
                            'Sub-Image Stack Reading',...
                            'Image Stack Segmentation'};

                % case is the waitbar figure is being created here
                wtStr = 'Fly Location Detection Progress';
                obj.hProg = ProgBar(obj.wStr,wtStr,2);
                pause(0.05)    
                
            else
                % otherwise, retrieve the progressbar strings
                obj.wOfs1 = 2 + obj.isMultiBatch;
                obj.isBatch = true;
                obj.wStr = obj.hProg.wStr;                
            end
            
            % determines the number of progressbar field levels
            obj.nLvl = length(obj.wStr);
            
            % if the solution tracking GUI is open, then reset the 
            % update function       
            hSolnT = get(obj.hFig,'hSolnT');
            if ~isempty(hSolnT)
                try
                    % attempts to updates the solution view GUI
                    hSolnT.updateFunc(guidata(hSolnT));
                catch
                    % if there was an error, then reset the GUI handle
                    set(obj.hFig,'hSolnT',[])   
                end
            end                
            
        end
        
        % --- sets up the positional data struct
        function initPosDataStruct(obj)
            
            % --- prompts the user if they wish to continue or restart
            function uChoice = promptContChoice(obj)
                
                % loads the global analysis parameters 
                pPara = load(getParaFileName('ProgPara.mat'));
                nFrmS = getFrameStackSize();
                
                %
                jPhase = obj.iPhaseS(obj.iPhase0);
                nFrmPh = diff(obj.iMov.iPhase(jPhase,:));  
                nStackPh = ceil(nFrmPh/nFrmS);
                
                % determines if the video is partially/completely tracked
                if (obj.iPhase0 == obj.nPhase) && ...
                                (nStackPh == obj.nCountS(obj.iPhase0))
                    % case is video is fully tracked
                    sStr = 'Current video is fully segmented';
                else
                    % case is video is partially tracked
                    sStr = 'Current video is partially segmented';
                end                                
                
                % otherwise, prompt the user the restart status
                qStr = {sprintf('%s\n',sStr);...
                    sprintf('Current video segmentation phase = %i',...
                                obj.iPhase0);...
                    sprintf('Total number of video phases = %i\n',...
                                obj.nPhase);...
                    sprintf('Currently segmented image frame stacks = %i',...
                                obj.pData.nCount(jPhase));...
                    sprintf('Total image frame stacks to segment = %i',...
                                nStackPh);...
                    sprintf('\nDo you wish to continue or restart?')};   
                
                % otherwise, prompt the user if they want to 
                % overwrite the solution
                tStr = 'Tracking Restart Options';
                bStr = {'Continue','Restart','Restart From...','Cancel'};
                uChoice = QuestDlgMulti(bStr,qStr,tStr,400);
                
            end            
            
            % initialisations
            updateFrame = false;
            
            % sets the phase frame index groups
            xiPh = num2cell(obj.iMov.iPhase,2);
            [~,obj.iPhaseS] = sort(obj.iMov.vPhase);
            obj.iFrmG = cellfun(@(x)(x(1):x(2)),xiPh,'un',0);            
            
            % determines if the positional data struct exists
            if isempty(obj.pData)
                % if not, then initialise
                [resetData,obj.iPhase0] = deal(true,1); 
                
            elseif ~isfield(obj.pData,'isSeg')
                % if the position data struct is of the old format, then
                % completely remove the data struct and start again under 
                % the new format
                [resetData,obj.iPhase0] = deal(true,1); 
                
            else
                % determines the first feasible region/sub-region
                iApp0 = find(obj.iMov.ok,1,'first');
                iTube0 = find(obj.iMov.flyok(:,iApp0),1,'first');
                fPosT = obj.pData.fPos{iApp0}{iTube0};                

                % retrieves the index of the last segmented frame
                isTrk = ~isnan(fPosT(:,1));
                
                % determines the phase to be segmented
                if ~isTrk(1)
                    % no frames have been segmented, so start at 1st phase
                    obj.iPhase0 = 1;
                    
                elseif all(isTrk)
                    % all frames have been segmented
                    obj.iPhase0 = obj.nPhase;
                    
                else
                    % otherwise, determine which phase the tracking is
                    % currently up to from the segmented frames
                    iTrk = cellfun(@(x)(any...
                                    (~isTrk(x))),obj.iFrmG(obj.iPhaseS));
                    obj.iPhase0 = find(iTrk,1,'first');
                    if isempty(obj.iPhase0)
                        % case is the final phase is being segmented
                        obj.iPhase0 = obj.nPhase; 
                    end         
                end
                
                % determines if the first frame of the first video
                obj.nCountS = obj.pData.nCount(obj.iPhaseS);
                if (obj.nCountS(obj.iPhase0)==0) && (obj.iPhase0==1)
                    % if so, then no need to reset data
                    resetData = false;
                    
                else
                    if obj.isBatch
                        % if batch processing, flag continuing segmentation 
                        uChoice = 'Continue';
                        
                    else
                        % if the diagnostic window is open, close it
                        hDiag = findall(0,'tag','figDiagCheck');
                        if ~isempty(hDiag); delete(hDiag); end
                        
                        % sets the progressbar to be invisible 
                        obj.hProg.setVisibility('off')
                        
                        % prompts the user to restart/continue
                        uChoice = promptContChoice(obj);
                    end   
                    
                    %
                    switch uChoice
                        case ('Restart From...')
                            % prompts user for restart point
                            resetData = obj.resetPosDataStruct();
                            
                        case ('Restart')
                            % prompt the user to confirm they wish to
                            % restart their current progress
                            qStr2 = {['This action will permanently erase ',...
                                     'the current tracking progress.'];...
                                     'Are you sure you want to restart?'};
                            uChoice2 = questdlg(qStr2,'Confirm Restart?',...
                                                'Yes','No','Yes');
                            if strcmp(uChoice2,'Yes')
                                % flag that the user is restarting 
                                obj.iPhase0 = 1;
                                resetData = true;
                                
                            else
                                % flag the user quit. then exit
                                obj.calcOK = false;     
                                
                            end
                            
                        case ('Continue') % user clicked continue   
                            
                            % flag that data reset is not required
                            resetData = false;
                            
                        otherwise % user clicked cancel
                            
                            % flag the user quit. close the progressbar
                            obj.calcOK = false;
                                  
                    end
                    
                    % determines if the user cancelled
                    if obj.calcOK
                        % sets the progressbar to be visible again
                        obj.hProg.setVisibility('on')   
                        updateFrame = ~strcmp(uChoice,'Continue');  
                        
                    else
                        % if the user cancelled, then close the progressbar
                        if ~isempty(obj.hProg)
                            % closes the progressbar
                            obj.hProg.closeProgBar();
                        end
                        
                        % exits the function
                        return                      
                    end
                                        
                end
            end            
            
            % determines if the 
            if resetData
                % updates the angle orientation calculation flag
                A = load(getParaFileName('ProgPara.mat'));
                obj.iMov.calcPhi = A.trkP.calcPhi && is2DCheck(obj.iMov);

                % sets the fly location data struct
                obj.setupPosDataStructFull();

                % set the summary file name
                sumFile = fullfile(obj.iData.fData.dir,...
                            getSummFileName(obj.iData.fData.dir));
                
                % sets the video time vector
                if exist(sumFile,'file')
                    % retrieves the video file index
                    [~,fName,~] = fileparts(obj.iData.fData.name);
                    A = regexp(fName,'\D','split');
                    iVid = str2double(A{end});

                    % if the summary file exists, set the frame time-stamps
                    vidSum = load(sumFile);
                    obj.pData.T = ...
                            obj.checkTimeStampArray(vidSum.tStampV{iVid});
                        
                else
                    % loads the video object
                    try
                        % new version of the function
                        mObj = VideoReader(obj.iData.movStr);
                    catch
                        % old version of function this function is obsolete
                        % on newer Matlab versions)
                        mObj = mmreader(obj.iData.movStr);
                    end

                    % otherwise, set the time from the movie properties
                    tStep = 1/get(mObj,'FrameRate');
                    nFrmTot = get(mObj,'NumberOfFrames');
                    obj.pData.T = (0:tStep:(nFrmTot-1)*tStep)';
                end
                
            else
                % flag that initialisation is not necessary
                obj.iStack0 = obj.nCountS(obj.iPhase0);
                if ~isfield(obj.pData,'calcPhi')
                    obj.pData.calcPhi = false;
                end                
                
            end
            
            % updates the frame (if required)
            if updateFrame
                % updates the frame selection properties
                set(obj.hGUI.figFlyTrack,'pData',obj.pData);
                setTrackGUIProps(obj.hGUI,'UpdateFrameSelection'); 
                
                % updates the display image
                obj.dispImage(obj.hGUI)
            end            
        end                 
        
    end        
    
end
