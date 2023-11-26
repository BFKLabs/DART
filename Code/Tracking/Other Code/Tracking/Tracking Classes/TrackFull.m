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
        
        % x/y coordinate extremum
        xLim
        yLim
        
        % miscellaneous fields
        tDir
        wStr         
        
        % boolean/flag fields
        nI = 0;
        dFrmMax = 10;
        hasProg = false;
        isMultiBatch = false;
        solnChk = false;
        wOfs1 = 1;
        nLvl        
        nFrmS
        
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
            validPh = obj.iMov.vPhase < obj.ivPhRej;
            
            % ensures the progressbar is visible
            obj.hProg.setVisibility('on');
            
            % segments the objects from start phase to end
            for i = obj.iPhase0:obj.nPhase
                % sets the phase to be segmented
                j = obj.iPhaseS(i);                
                
                % updates the progessbar (if it exists)
                if ~validPh(j)
                    % if the phase is rejected, then exit the loop 
                    break
                    
                elseif ~isempty(obj.hProg)
                    % updates the progressbar phase field
                    wStrNw = sprintf('%s #%i (Phase %i of %i)',...
                                    obj.wStr{obj.wOfs1},j,i,obj.nPhase);
                    if obj.hProg.Update(obj.wOfs1,wStrNw,i/obj.nPhase)
                        % if the user quit, then exit the function
                        obj.calcOK = false; 
                        break
                    else
                        % otherwise, reset the other progressbar fields
                        obj.resetProgBarFields(1);
                    end
                end                
                
                % resets the progress struct
                switch obj.iMov.vPhase(j)
                    case {1,4}
                        % case is a low-variance/special phase
                        
                        % resets progress data and segments phase
                        obj.resetProgressStruct(j);  
                        obj.segVideoPhase(j);
                        
                    case (2)
                        % case is a high-variance phase
                        
                        % only analyse if the phase is large
                        if diff(obj.iMov.iPhase(j,:)) > obj.dFrmMax
                            % resets progress data and segments phase
                            obj.resetProgressStruct(j);                          
                            obj.segVideoPhase(j);
                        end
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
        
        % --- segments all the frames for the video phase, iPhase
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
                % sets the progress bar level offset
                wOfsNw = (bOfs + 1);
                
            else
                % sets the progress bar level offset
                wOfsNw = bOfs + 2;
            end

            % determines the last phase that has been segmented            
            isSeg = false(size(obj.fObj));
            okPh = ~cellfun('isempty',obj.fObj);
            isSeg(okPh) = cellfun(@(x)(~isempty(x.fPos)),obj.fObj(okPh));            
            iPhPr = find(isSeg(1:(iPhase-1)),1,'last');
            
            % retrieves the positional data from the previous phase
            if isempty(iPhPr) || (obj.iMov.vPhase(iPhPr) > 1)
                % first phase or previous phase is not low-variance, so
                % don't use previous positional data
                fPosPr = [];
                
            else
                % otherwise, retrieve the data from the tracking object
                if isempty(iPhPr)
                    fPosPr = [];
                else
                    fPosPr = obj.fObj{iPhPr}.fPos;
                end
            end
            
            % sets the previous data from the current tracking state
            if (iPhase == 1) && (nCountNw == 0)
                % case is the this is the first video stack
                prDataPh = obj.prData;  
                
            elseif ~isempty(fPosPr)
                % otherwise, if data from the previous phase object is
                % available then use these values
                iFrmL = obj.iMov.iPhase(iPhPr,2);
                prDataPh = obj.getPrevPhaseData(obj.fObj{iPhPr},iFrmL);
                
            else
                % otherwise, determine the last tracked from the current 
                % phase. use this to determine the previous data
                iApp0 = find(obj.iMov.ok,1,'first');
                iFrmP = obj.iMov.iPhase(iPhase,1):obj.iMov.iPhase(iPhase,2);
                
                % determines the first valid tube index
                if iscell(obj.iMov.flyok)
                    iTube0 = find(obj.iMov.flyok{iApp0},1,'first');
                else
                    iTube0 = find(obj.iMov.flyok(:,iApp0),1,'first');  
                end
                
                % determines the last valid frame in the phase that was
                % analysed
                isTrk = ~isnan(obj.pData.fPos{iApp0}{iTube0}(iFrmP,1));                
                if ~any(isTrk)
                    % if there is none, then determine the last existing
                    % frame that has tracking data
                    if iPhase > 1
                        % case is not the first phase, so determine if any
                        % preceding phase frames are valid
                        ii = 1:(obj.iMov.iPhase(iPhase-1,2)-1);
                        X0 = obj.pData.fPos{iApp0}{iTube0}(ii,1);
                        iFrmLast = find(~isnan(X0),1,'last');
                    else
                        % case is the first phase, so no valid frame
                        iFrmLast = [];
                    end
                else
                    % otherwise, return the last tracked frame
                    iFrmLast = iFrmP(find(isTrk,1,'last'));
                end
                
                % sets the previous data struct if the last frame is valid
                if isempty(iFrmLast)
                    % case is the there are no viable frames
                    if iPhase == 1
                        % if the first phase, then use previous phase data
                        prDataPh = obj.prData;
                    else
                        % if not, then don't use previous location data
                        prDataPh = [];
                    end
                else
                    % determines if the gap between the current phase and
                    % the last tracked frame is too large
                    dFrm = obj.iMov.iPhase(iPhase,1) - iFrmLast;
                    if dFrm > obj.dFrmMax
                        % if so, then don't use the previous location data
                        prDataPh = [];
                    else                                        
                        % otherwise, set up the previous phases data struct
                        prDataPh = ...
                            obj.sObj.setupPrevPhaseData(iFrmLast,iPhase);
                    end
                end
                
            end
            
            % sets the tracking object properties
            set(obj.fObj{iPhase},'iMov',obj.iMov,'wOfs',wOfsNw,...
                                 'hProg',obj.hProg,'iPh',iPhase,'vPh',vPh);
            if obj.isMulti
                set(obj.fObj{iPhase},'calcInit',false);
            end
            
            % ------------------------------ %
            % --- FLY LOCATION DETECTION --- %
            % ------------------------------ %            
            
            % sets the first/last frames of the HT1 phase (if present)
            if obj.fObj{iPhase}.isHT1
                % retrieves the first/last frame of the phase
                iFrmS0 = [obj.sProg.iFrmR{1}(1),obj.sProg.iFrmR{end}(end)];
                I0 = obj.getImageStack(iFrmS0);
                
                % retrieves the sub-region image stacks
                xi = 1:obj.nApp;
                obj.fObj{iPhase}.ImgSL0 = cell(obj.nApp,1);
                obj.fObj{iPhase}.ImgS0 = arrayfun(@(x)...
                    (getRegionImgStack(obj.iMov,I0,iFrmS0,x,0)),xi,'un',0);
            end
            
            % loops through each image stacks segmenting fly locations
            for i = max(1,obj.pData.nCount(iPhase)):nStack                                
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
                iFrmR = obj.sProg.iFrmR{i};
                Img = obj.getImageStack(iFrmR);                
                
                % applies the image filter (if required)
                if ~obj.isMulti && ~isempty(obj.hS)
                    Img = cellfun(@(x)(imfiltersym(x,obj.hS)),Img,'un',0);
                end                
                
                % updates the tracking object class fields                
                set(obj.fObj{iPhase},'Img',Img,'prData',prDataPh,...
                                     'iFrmR',obj.sProg.iFrmR{i});
                if ~obj.isMulti
                    set(obj.fObj{iPhase},'xLim',obj.xLim,'yLim',obj.yLim);
                end
                                    
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
            nFrm = length(iFrmR);
            
            % retrieves the updated x/y limits
            if obj.isMulti
                % finds the valid region indices
                indReg = find(arr2vec(obj.iMov.flyok')');
                
            else
                % finds the valid region indices
                indReg = find(obj.iMov.ok(:)');
                
                % updates the x/y coordinate limits
                obj.xLim = get(fObjP,'xLim');
                obj.yLim = get(fObjP,'yLim');
            end
            
            % retrieves all values
            for iApp = indReg
                % calculates the positional offset
                if obj.isMulti
                    [iCol,iRow] = ind2sub(size(obj.iMov.flyok),iApp);
                    dX = obj.iMov.iC{iCol}(1) - 1;
                    dY = obj.iMov.iR{iCol}(obj.iMov.iRT{iCol}{iRow}(1))-1;
                    nFlyR = obj.iMov.pInfo.nFly(iRow,iCol);
                    iReg = (iCol-1)*obj.iMov.pInfo.nRow + iRow;
                    
                else
                    iReg = iApp;
                    dX = obj.iMov.iC{iApp}(1) - 1;
                    dY = obj.isMulti*(obj.iMov.iR{iApp}(1) - 1);
                    nFlyR = obj.sObj.getSubRegionCount(iApp);
                end
                
                % sets the positional offset array
                pOfs = repmat([dX,dY],nFrm,1);      
                
                %
                for iFly = 1:nFlyR
                    % sets the local/global position values
                    obj.pData.fPos{iReg}{iFly}(iFrmR,:) = pOfs + ...
                        obj.getTrackFieldValues(fObjP.fPos,iApp,iFly);
                    if isprop(fObjP,'fPosL')
                        if ~isempty(fObjP.fPosL)
                            obj.pData.fPosL{iReg}{iFly}(iFrmR,:) = ...
                                        obj.getTrackFieldValues...
                                        (fObjP.fPosL,iApp,iFly);
                        end
                    end
                    
                    % sets the position metric values
                    if isprop(fObjP,'IPos')
                        obj.pData.IPos{iReg}{iFly}(iFrmR) = ...
                             obj.getTrackFieldValues(fObjP.IPos,iApp,iFly);   
                    end
                                        
                    % sets the orientation angle (if required)
                    if obj.iMov.calcPhi
                        obj.pData.Phi{iReg}{iFly}(iFrmR) = ...
                            obj.getTrackFieldValues(fObjP.Phi,iApp,iFly);
                        obj.pData.axR{iReg}{iFly}(iFrmR) = ...
                            obj.getTrackFieldValues(fObjP.axR,iApp,iFly); 
                        obj.pData.NszB{iReg}{iFly}(iFrmR) = ...
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
            end
            
            % updates the frame selection properties
            if exist('nwFrm','var')
                setTrackGUIProps(obj.hGUI,'UpdateFrameSelection',nwFrm)
            else
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
            obj.iPhase0 = indS(1);                                    
            obj.pData.isSeg(xiS) = false;
            obj.pData.nCount(xiS) = 0;
            obj.pData.nCount(jPhase) = max(0,indS(2));
            [obj.iStack0,obj.nCountS] = deal(max(1,indS(2)));
            
            % loads the progress data file            
            pFile = fullfile(obj.tDir,'Progress.mat');
            A = load(pFile); obj.sProg = A.sProg;
            
            % sets the frames that are to be removed
            Brmv = false(size(obj.pData.fPos{1}{1},1),1);
            Brmv(cell2mat(obj.iFrmG(xiS)')) = true;
            Brmv(obj.iFrmG{jPhase}(((indS(2)-1)*obj.nFrmS+1):end)) = true;
            
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

            % array length indexing
            nFrm = diff(obj.iMov.iPhase,[],2) + 1;
            nFrmST = obj.iMov.sRate.*floor(obj.nFrmS./obj.iMov.sRate);
            nStack = ceil(nFrm/nFrmST);                 

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
            obj.nFrmS = getFrameStackSize();
            
            % sets the interpolation value
            iLV0 = find(obj.iMov.vPhase==1,1,'first');
%             if isempty(iLV0)
                obj.nI = 0;
%             else
%                 obj.nI = obj.fObj{iLV0}.nI;
%             end
            
            % function handles
            obj.dispImage = get(obj.hFig,'dispImage');
            
            % creates the progress bar (if not already set)
            if isempty(obj.hProg) || ~obj.hasProg
                % sets the progressbar strings
                obj.wStr = {'Tracking Video Phase',...
                            'Current Video Progress',...
                            'Sub-Image Stack Reading'};

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
                
                % determines the number of phases in the current stack
                jPhase = obj.iPhaseS(obj.iPhase0);
                nFrmPh = diff(obj.iMov.iPhase(jPhase,:))+1;  
                nStackPh = ceil(nFrmPh/obj.nFrmS);
                
                % determines if the video is partially/completely tracked
                if (obj.iPhase0 == obj.nPhase) && (nStackPh == obj.nCountS)
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
                                obj.nCountS);...
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
            dStr = {'ascend','descend'};
            
            % sets the phase frame index groups
            xiPh = num2cell(obj.iMov.iPhase,2);
            nFrmG = diff(obj.iMov.iPhase,[],2);
            [~,obj.iPhaseS] = sortrows([obj.iMov.vPhase,nFrmG],[1,2],dStr);
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
                if iscell(obj.iMov.flyok)
                    iTube0 = find(obj.iMov.flyok{iApp0},1,'first');
                else
                    iTube0 = find(obj.iMov.flyok(:,iApp0),1,'first');
                end
                fPosT = obj.pData.fPos{iApp0}{iTube0};                

                % retrieves the index of the last segmented frame
                indT = cell2mat(obj.iFrmG(obj.iPhaseS)');
                isTrk = ~isnan(fPosT(:,1));                
                
                % determines the phase to be segmented
                if ~isTrk(indT(1))
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
                
                % determines the number of tracked frames in the phase. 
                % from this, determine the number of analysed phase stacks       
                iFrmS = obj.iMov.iPhase(obj.iPhaseS(obj.iPhase0),:);
                nFrmTrkMax = ceil((diff(iFrmS)+1)/obj.nFrmS);                
                nFrmTrkPh = sum(isTrk(iFrmS(1):iFrmS(2)));                
                obj.nCountS = min(nFrmTrkMax,ceil(nFrmTrkPh/obj.nFrmS)+1);
                
                % determines/sets the tracking restart point
                if (obj.nCountS == 1) && (obj.iPhase0 == 1)
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
                    
                    % prompts the user where they want to start from
                    % (either continue, restart completely, or restart from
                    % a specified frame index)
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
                            iPhT = obj.iPhaseS(obj.iPhase0);
                            obj.pData.nCount(iPhT) = obj.nCountS;
                            
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
                    % loads the summary file data
                    vidSum = load(sumFile);                    
                    if vidSum.iExpt.Video.nCount == 1
                        % if only one video, then set the index to 1
                        iVid = 1;
                    else                    
                        % retrieves the video file index
                        [~,fName,~] = fileparts(obj.iData.fData.name);
                        A = regexp(fName,'\D','split');
                        iVid = str2double(A{end});
                    end

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
                obj.iStack0 = obj.nCountS;
                if ~isfield(obj.pData,'calcPhi')
                    obj.pData.calcPhi = false;
                end                
                
            end
            
            % determine the overall min/max coordinates for all sub-regions
            pMin = cellfun(@(y)(cell2mat(cellfun(@(x)...
                   (min(x,[],1,'omitnan')),y(:),'un',0))),...
                   obj.pData.fPosL,'un',0);
            pMax = cellfun(@(y)(cell2mat(cellfun(@(x)...
                   (max(x,[],1,'omitnan')),y(:),'un',0))),...
                   obj.pData.fPosL,'un',0);
               
            % set the overall x/y-coordinate limits for each sub-region
            isOK = ~cellfun('isempty',pMin);
            [obj.xLim,obj.yLim] = deal(cell(size(pMax)));
            obj.xLim(isOK) = cellfun(@(x,y)...
                        ([x(:,1),y(:,1)]),pMin(isOK),pMax(isOK),'un',0);
            obj.yLim(isOK) = cellfun(@(x,y)...
                        ([x(:,2),y(:,2)]),pMin(isOK),pMax(isOK),'un',0);            
            
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
