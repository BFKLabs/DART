classdef BlobCNNTrain < dynamicprops & handle
    
    % class properties
    properties
        
        % other class objects
        objC
        
        % tracking object fields
        Img0
        ImapR
        ImapS        
        
        % region indices
        iR
        iC
        iRT
        okF
        indG
        
        % training data fields
        iIDT
        ImgT        
        fPosTG
        fPosTL
        sFlagT
        useT        
        nCountT        
        
        % main training object fields
        optT
        layersT        
        pNet        
        fPG
        iCountT
        initT
        pTrain
        trainSuccess
        
        % progressbar object fields
        hProgT
        iPhaseT
        wStrT
        
        % array fields
        szG
        szG0
        szL        
        nCh
        nFrm
                        
        % fixed training option parameters
        learnRate = 1e-4;  
        pAccMin = 0.85;        
        
        % temporary option parameters
        isVerbose = false;                
        plotType = 'none';        
        
        % fixed scalar fields
        nI = 1;
        Ng = 2;        
        Nh = 5;
        pMlt = 1;
        pSF = 1;
        szI = [480,600];
        
    end
    
    % private class properties
    properties (Access = private)
        
        objB
        
    end    
    
    % class methods
    methods
        
        % --- class constructor
        function obj = BlobCNNTrain(objB)
            
            % sets the input arguments
            obj.objB = objB;
            
            % initialises the class fields
            obj.linkParentProps();
            obj.initClassFields();
            
        end        
            
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class object fields with that parent object
        function linkParentProps(obj)
            
            % parent fields strings
            fldStr = {'nApp','nTube','calcOK','iMov','mFlag'};
            
            % connects the base/child objects
            for propname = fldStr
                metaprop = addprop(obj, propname{1});
                metaprop.SetMethod = @(obj, varargin) ...
                    SetDispatch(obj, propname{1}, varargin{:});
                metaprop.GetMethod = @(obj)GetDispatch(obj, propname{1});
            end
            
        end               
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % field retrieval
            obj.szG0 = size(obj.objB.Img{1}{1});            
                       
            % training network/parameters
            obj.hProgT = obj.objB.hProg;            
            obj.pNet = obj.hProgT.pCNN.pNet;
            obj.pTrain = obj.hProgT.pCNN.pTrain;
            obj.pSF = max(round(obj.szG0./obj.szI));            
            
            % sets up the network classifier object
            obj.hProgT.pCNN.pSF = obj.pSF;
            obj.objC = BlobCNNClassify(obj.iMov,obj.hProgT.pCNN);            
            
            % general field retrieval        
            obj.nCh = length(obj.pTrain.iCh);
            obj.nFrm = length(obj.objB.Img{1});
            obj.szL = (2*obj.Nh + 1)*[1,1];                                    
            
            % rescales the images
            obj.Img0 = cellfun(@(x)(...
                obj.rescaleImage(x)),obj.objB.Img{1},'un',0);            
            obj.szG = size(obj.Img0{1});            
            
            % memory allocation
            obj.nCountT = NaN(1,obj.Ng);
            obj.sFlagT = obj.objB.sFlagT(1,:);
            obj.useT = cellfun(@(x)(x == 1),obj.sFlagT,'un',0);            
            obj.okF = obj.iMov.ok & cellfun(@(x)(any(x)),obj.useT);
            
            % retrieves the candidate blob region global indices
            xiOK = num2cell(find(obj.okF));
            obj.indG = cell2mat(cellfun(@(x,y)([x*ones(sum(y),1),...
                find(y(:))]),xiOK,obj.useT(obj.okF),'un',0)');            
            
            % sets and updates the progressbar (if valid)
            if isvalid(obj.hProgT)
                obj.hProgT.updateTrainPhase(1);             
            end                                               
            
            % sets up the training images
            obj.rescaleCoords(1);
            obj.rescaleAllIndices();
            obj.setupRegionMaps();
            obj.setupTrainingImages();                   
            obj.setupTrainingLayers();
            
            % --------------------------- %            
            % --- TRAIN OPTIONS SETUP --- %
            % --------------------------- %
            
            % sets up the training options
            obj.optT = trainingOptions(obj.pTrain.algoType,...
                'MaxEpochs',obj.pTrain.maxEpochs,...
                'InitialLearnRate',obj.learnRate,...
                'MiniBatchSize',obj.pTrain.batchSize,...
                'LearnRateSchedule','piecewise',...
                'LearnRateDropPeriod',1,...
                'LearnRateDropFactor',0.5,...
                'Verbose',obj.isVerbose,...
                'Plots',obj.plotType,...
                'OutputFcn',@obj.trainOutputFcn);            
            
            % sets solver specific parameters
            switch obj.pTrain.algoType
                case 'sgdm'
                    obj.optT.Momentum = obj.pTrain.Momentum;
                    obj.optT.InitialLearnRate = 1e-3;                    
            end                        
                        
        end
        
        % --- sets up the training image array
        function setupTrainingImages(obj)
            
            % determines which regions have candidate blobs
            if ~any(obj.okF); return; end                        

            % --------------------------- %
            % --- SUB-IMAGE RETRIEVAL --- %
            % --------------------------- %            
            
            % memory allocation
            obj.fPG = cell(obj.nFrm,obj.Ng);            
            ImgS = deal(cell(obj.nFrm,obj.nCh,obj.Ng));
            BG = bwmorph(true(obj.szG),'erode',obj.Nh);            
            
            % sets up the training images for each frame/region            
            for i = 1:obj.nFrm
                % calculates the image x/y gradient
                ICh = obj.objC.setupClassifyImageStack(obj.Img0{i},0);
                
                % retrieves the coordinates of the feasible regions
                fPC = num2cell(cell2mat(cellfun(@(x,y)(x(y,:)),...
                    obj.fPosTG(obj.okF,i),obj.useT(obj.okF)','un',0)),2);
                
                % sets the sub-image points (false/true group types)
                obj.fPG{i,2} = num2cell(cell2mat(cellfun(@(x)(...
                    obj.expandPointCoords(x)),fPC,'un',0)),2);
                if i == 1
                    obj.fPG{i,1} = obj.setupOtherPointCoords(...
                        obj.Img0{i},BG,obj.indG,fPC);                
                end
                
                % sets up the image stack (for each group/channel)
                for k = 1:obj.nCh                
                    for j = 1:obj.Ng
                        % only retrieve sub-image points if they exist
                        if ~isempty(obj.fPG{i,j})
                            ImgS{i,k,j} = cellfun(@(x)(...
                                obj.objC.getPointSubImage(...
                                ICh{k},x,k,obj.Nh)),obj.fPG{i,j},'un',0);
                        end
                    end
                end              
            end            
            
            % determines the overall sub-image counts (over all frames)
            nImgS = reshape(cellfun('length',ImgS(:,1,:)),obj.nFrm,2);
            obj.nCountT = sum(nImgS,1);                                    

            % ------------------------------- %
            % --- FINAL IMAGE ARRAY SETUP --- %
            % ------------------------------- %
            
            % memory allocation
            iOfs = 0;
            szT = [obj.szL,1,sum(obj.nCountT)];
            obj.ImgT = repmat({zeros(szT)},1,obj.nCh);
            obj.iIDT = zeros(szT(end),1);
            
            % sets the images into the full array
            for i = 1:length(obj.nCountT)
                % sets the ID flags
                obj.iIDT(iOfs+(1:obj.nCountT(i))) = i;
                
                % resets the array
                iOfsF = 0;
                for j = 1:obj.nFrm
                    % continue if no candidates
                    if nImgS(j,i) == 0
                        continue
                    end
                    
                    % sets the parameters for the current frame
                    szR = [1,1,1,nImgS(j,i)];                    
                    xiT = (iOfs + iOfsF) + (1:nImgS(j,i));
                    
                    % sets the image stacks for each channel
                    for k = 1:obj.nCh
                        obj.ImgT{k}(:,:,1,xiT) = ...
                            cell2mat(reshape(ImgS{j,k,i},szR));
                        ImgS{j,k,i} = [];
                    end
                    
                    % increments the frame counter
                    iOfsF = iOfsF + nImgS(j,i);
                end
                
                % clears the array
                iOfs = iOfs + obj.nCountT(i);
            end
            
            % converts the ID flags to categorical flags
            obj.iIDT = categorical(obj.iIDT);
            
        end
            
        % --- sets up the region maps
        function setupRegionMaps(obj)
            
            % memory allocation
            [obj.ImapR,obj.ImapS] = deal(zeros(obj.szG));
            
            % sets up the region/sub-region index masks
            for i = 1:obj.nApp
                % sets the region index mask
                iRnw = obj.iR{i};
                obj.ImapR(iRnw,obj.iC{i}) = i;
                
                % sets the sub-region index masks
                for j = 1:length(obj.iRT{i})
                    obj.ImapS(iRnw(obj.iRT{i}{j}),obj.iC{i}) = j;
                end
            end
            
        end        
        
        % --- sets up the model training layers architecture
        function setupTrainingLayers(obj)
            
            % field retrieval
            szImg = size(obj.ImgT{1});                        
            
            % sets up the entire training network layer architecture
            for i = 1:obj.nCh                
                % sets up the layer network for the current channel
                layersCh = obj.setupChannelLayer(szImg,i,obj.Nh);
                
                % initialises/appends to the layer graph
                if i == 1
                    % if more than one channel, then append addition layer
                    if obj.nCh > 1
                        layersCh(end+1) = ...
                            concatenationLayer(3,obj.nCh,'Name','concat');
                    end
                    
                    % appends the 
                    layersCh = [layersCh;...
                        fullyConnectedLayer(obj.Ng,'Name','fcF')
                        softmaxLayer('Name','softmax')
                        classificationLayer('Name','output')];
                    
                    % initialises the layer graph
                    obj.layersT = layerGraph(layersCh);
                else
                    % if subsequent channels, then add on the layers to the
                    % addition node
                    
                    % sets the naming strings
                    fcStr = sprintf('fc%i',i);
%                     addStr = sprintf('add/in%i',i);
                    addStr = sprintf('concat/in%i',i);

                    % adds and connects the new layers
                    obj.layersT = addLayers(obj.layersT,layersCh);
                    obj.layersT = connectLayers(obj.layersT,fcStr,addStr);                    
                end
            end
                                    
        end                        
        
        % ----------------------------------------------- %
        % --- MODEL TRAINING/CLASSIFICATION FUNCTIONS --- %
        % ----------------------------------------------- %        
        
        % --- runs the network training/classification routine 
        function trainCNN(obj,hProg)

            % initialises the the calculation flag
            obj.calcOK = true;            

            % creates the training progressbar
            if exist('hProg','var')
                % sets the progressbar (if provided)
                obj.hProgT = hProg;
            
            elseif isempty(obj.hProgT) || ~isvalid(obj.hProgT)                
                % if the progressbar is not set (or invalid) then create
                obj.hProgT = BlobCNNProgBar(true);
            end
            
            % runs the network training (if required)
            if obj.hProgT.isTrain
                obj.trainFullNetwork(false);
                if ~obj.calcOK
                    % exit if the user cancelled
                    return
                end
            end
            
            % tracks the stationary blobs
            obj.trackStationaryBlobs();

            % closes the progressbar
            if obj.calcOK 
                % upsamples the final coordinates
                obj.rescaleCoords(0);                
                
                % closes the progressbar
                if ~exist('hProg','var')
                    pause(0.5);
                    obj.hProgT.closeProgBar();
                end
            end            
            
        end        
        
        % --- runs the full network training
        function trainFullNetwork(obj,createPB)
            
            % sets the default input arguments
            if ~exist('createPB','var'); createPB = true; end
           
            % if there are no valid regions, then exit
            if ~any(obj.okF)
                obj.calcOK = false;
                return
            end            
                        
            % other initialisations
            iFrm0 = 1;
            obj.initT = true;
            
            % creates the progressbar
            if createPB
                obj.hProgT = BlobCNNProgBar(true);
            end
            
            % -------------------------------- %
            % --- INITIAL NETWORK TRAINING --- %
            % -------------------------------- %
            
            % field resetting/update            
            obj.pMlt = 1;
            nSample = size(obj.ImgT{1},4);            
            mBatchSz = obj.pTrain.batchSize;
            [obj.optT.MaxEpochs,maxEpochs] = deal(obj.pTrain.maxEpochs); 
            isRunning = strcmp(obj.hProgT.hTimer.Running,'on');
            
            % sets up the training data store object
            tData0 = obj.setupTrainingDataStore(true);
            obj.hProgT.recalcIterCount(nSample,maxEpochs,mBatchSz);
            obj.hProgT.updateTrainPhase(2,~isRunning);
            obj.hProgT.Update(3,0);
            
            % trains the CNN network
            obj.pNet = trainNetwork(tData0,obj.layersT,obj.optT);
            if obj.calcOK
                % if successful, clear the extraneous variables
                clear tData0
               
                % runs the accuracy check. if too low, then exit
                obj.runAccuracyCheck()
                if ~obj.calcOK
                    return
                end
            else
                % otherwise, exit the function
                return
            end
            
            % calculates the training accuracy of the initial model
            obj.runAccuracyCheck();            

            % --------------------------- %
            % --- TRAINING DATA RESET --- %
            % --------------------------- %            
                        
            % field resetting/update
            obj.hProgT.updateTrainPhase(3);
            
            % determines the locations of the misclassified points
            fPC0 = obj.getInitMisclassifiedPoints(iFrm0);            
            if isempty(fPC0)
                % if the user didn't cancel, then update the progressbar
                if obj.calcOK
                    obj.hProgT.closeProgBar();
                end
                
                % exits the function
                return
                
            else
                % otherwise, update the progressbar
                obj.hProgT.Update(4,3);
            end
            
            % other field retrieval
            ImgF = obj.ImgT;               
            ICh = obj.objC.setupClassifyImageStack(obj.Img0{iFrm0},0);
            
            % appends the images for eahc channel
            for i = 1:obj.nCh
                % sets the new sub-images for the channel
                A = cellfun(@(x)(obj.objC.getPointSubImage(...
                    ICh{i},x,i,obj.Nh)),fPC0,'un',0);
                IsubNw = cell2mat(reshape(A,[1,1,1,length(A)]));
                clear A
                
                % concatenates the 
                ImgF{i} = cat(4,ImgF{i},IsubNw);
                clear IsubNw
            end            
            
            % otherwise, update the progressbar
            if obj.hProgT.Update(4,4)
                % if the user cancelled, then exit the function
                obj.calcOK = false;
                return
                
            else
                % sets the expanded label array
                iIDF = [obj.iIDT;categorical(ones(size(fPC0,1),1))];
            end
            
            % ------------------------------ %
            % --- FINAL NETWORK TRAINING --- %
            % ------------------------------ %  
            
            % field resetting/update
            obj.hProgT.updateTrainPhase(4);            
            obj.hProgT.Update(5,0);
            
            % field resetting/update
            obj.pMlt = 2;            
            obj.iPhaseT = 3;
            obj.initT = false;            
            nSamples = size(ImgF{1},4);
            [obj.optT.MaxEpochs,maxEpochs] = deal(2*obj.pTrain.maxEpochs);
                        
            % sets up the training datastore object
            tDataF = obj.setupTrainingDataStore(true,ImgF,iIDF);
            obj.hProgT.recalcIterCount(nSamples,maxEpochs,mBatchSz);
            clear ImgF iIDF            
            
            % trains the network with the appended data
            obj.pNet = trainNetwork(tDataF,layerGraph(obj.pNet),obj.optT);
            clear tDataF
            
            % performs the post-training calculations
            if obj.calcOK 
                % runs the accuracy check
                obj.runAccuracyCheck()                                
                if obj.calcOK
                    % if successful, then rescale the coordinates
                    obj.rescaleCoords(0);
                end
                
                % closes the progressbar (if created within the function)
                if createPB
                    pause(0.1);
                    obj.hProgT.closeProgBar();
                end                
            end
            
        end        
        
        % --- network training output function
        function isStop = trainOutputFcn(obj, evnt)
            
            % initialisations
            isStop = false;
            
            % updates based on the training state flag
            switch evnt.State
                case 'start'
                    % case is starting the training
                    obj.iCountT = 0;                                
                    obj.trainSuccess = false;
                    
                case 'iteration'
                    % case is a training iteration
                                        
                    % pre-calculations
                    iLvl = 5 - 2*obj.initT;
                    nCountStopT = obj.pMlt*obj.pTrain.nCountStop;
                    
                    % determines if accuracy is above the limits
                    if evnt.TrainingAccuracy >= 99
                        % if so, then increment the counter
                        obj.iCountT = obj.iCountT + 1;
                        if obj.iCountT == nCountStopT
                            % if above limits, then stop the solver
                            isStop = true;
                            obj.trainSuccess = true;
                            obj.hProgT.Update(iLvl);
                            
                            % exits the function
                            return
                        end
                        
                    else
                        % other, reset the training counter
                        obj.iCountT = 0;
                    end
                    
                    % updates the progressbar            
                    pCountT = obj.iCountT/nCountStopT;
                    if obj.hProgT.Update(iLvl,evnt,pCountT)
                        % if the user cancelled, then exit the solver
                        isStop = true;
                        obj.calcOK = false;
                    end
            end
            
        end        

        % --- retrieves the locations of the misclassified points (from the
        %     initial training classfication
        function fPC0 = getInitMisclassifiedPoints(obj,iFrm0)
            
            % parameters
            fPC0 = [];
            nGridS = floor(obj.Nh/2);            
            
            % updates the progressbar
            if obj.hProgT.Update(4,1)
                % exit if the user cancelled
                obj.calcOK = false;
                return
            end                        
                        
            % retrieves the coordinates of the feasible regions
            fPT = num2cell(cell2mat(cellfun(@(x,y)(x(y,:)),...
                obj.fPosTG(obj.okF,iFrm0),obj.useT(obj.okF)','un',0)),2);
            BP = obj.setupPointDiskMask(fPT);             
            BC0 = ~setGroup(cell2mat(obj.fPG{1}),obj.szG);            
            
            % determines the mis-classified points overall regions
            iPC0 = cell(size(obj.indG,1),2);
            for i = 1:size(obj.indG,1)
                % retrieves the region/sub-region index
                [iApp,iAppS] = deal(obj.indG(i,1),obj.indG(i,2));
                
                % sets the sub-region row/column indices
                iCS = obj.iC{iApp};
                iRS = obj.iR{iApp}(obj.iRT{iApp}{iAppS});                
                                
                % sets up the search grid coordinates/linear indices
                szS = [length(iRS),length(iCS)];
                [X0,Y0] = obj.objC.setupSearchGrid(szS,nGridS,iCS,iRS);
                iXY = sub2ind(obj.szG,Y0,X0);
                
                % removes the known region grid points 
                iXYB = BP(iXY) & BC0(iXY);
                iPC0(i,:) = {iXY(iXYB),[X0(iXYB),Y0(iXYB)]};
            end
            
            % sets up the data store for the classification
            fPC = cell2mat(iPC0(:,2));
            ICh = obj.objC.setupClassifyImageStack(obj.Img0{iFrm0},0);
            tDataC = obj.objC.setupClassificationDataStore(ICh,fPC,obj.Nh);
            
            % --------------------------------- %            
            % --- GRID POINT CLASSIFICATION --- %
            % --------------------------------- %
        
            % updates the progressbar
            if obj.hProgT.Update(4,2)
                % exit if the user cancelled
                obj.calcOK = false;
                return
            end            
            
            % runs the classifier on the test datastore
            iPredC = classify(obj.pNet,tDataC); 
            isMC = double(iPredC) == 2;
            
            % returns the expanded points array
            if any(isMC)
                fPC0 = cell2mat(cellfun(@(x)(obj.expandPointCoords(x)),...
                    num2cell(fPC(isMC,:),2),'un',0));
                fPC0 = num2cell(fPC0,2);
            end
            
        end        

        % --- sets up the CNN network layer for the channel, iCh
        function layersCh = setupChannelLayer(obj,szImg,iChL,sz2D)
            
            % field names            
            fclName = sprintf('fc%i',iChL);
            inputName = sprintf('input%i',iChL);            
            maxStr = sprintf('maxpool%i',iChL);
            reluStr = sprintf('relu%i',iChL);
            cStr = sprintf('conv2D_%i',iChL);
            
            % layer images
            layersCh = imageInputLayer(szImg(1:3),'Name',inputName);
            
            % sets the network for each convolution level
            for i = 1:obj.pTrain.nLvl
                % sub-level names
                nF = obj.pTrain.filtSize*i;
                cStrNw = sprintf('%s%i',cStr,i);
                maxStrNw = sprintf('%s%i',maxStr,i);                
                reluStrNw = sprintf('%s%i',reluStr,i);
                
                % sets up the level layers array
                layersChNw = [
                    % 1st convolution layer
                    convolution2dLayer(...
                        sz2D,nF,'Padding','same','Name',cStrNw)
                    % 1st RELU layer
                    reluLayer('Name',reluStrNw);     
                    % 1st max pooling layer
                    maxPooling2dLayer(2,'Stride',2,'Name',maxStrNw)                    
                ];
            
                % appends the array
                layersCh = [layersCh;layersChNw];
                clear layersChNw
            end
            
            % layer images
            layersCh = [layersCh;fullyConnectedLayer(10,'Name',fclName)];            
        
        end                
        
        % --------------------------- %
        % --- DATASTORE FUNCTIONS --- %
        % --------------------------- %        
        
        % --- sets up the training data store object
        function tData = setupTrainingDataStore(obj,addLbl,Img,iID)
            
            % sets the default input arguments
            if ~exist('Img','var'); Img = obj.ImgT; end
            if ~exist('iID','var'); iID = obj.iIDT; end
            
            % combines the images into the data store
            tData = obj.objC.createDataStore(Img{1});
            for i = 2:obj.nCh
                tData = combine(tData,obj.objC.createDataStore(Img{i}));
            end
            
            % appends the response data
            if addLbl
                tData = combine(tData,arrayDatastore(iID));
            end
            
        end        
        
        % ------------------------------------------ %        
        % --- STATIONARY BLOB TRACKING FUNCTIONS --- %
        % ------------------------------------------ %
        
        % --- tracks the stationary blobs using the network classifier
        function trackStationaryBlobs(obj)
           
            % parameters
            nFrmMin = ceil(0.5*obj.nFrm);
            
            % memory allocation
            BS = false(obj.szG);
            BC = cell(obj.nFrm,1);            
            obj.objC.pNet = obj.pNet;            
            isS = cellfun(@(x)(x == 2),obj.sFlagT,'un',0);

            % field resetting/update
            iPhaseTot = 2 + 3*obj.hProgT.isTrain;
            obj.hProgT.updateTrainPhase(iPhaseTot);
            
            % determines if there are any stationary sub-regions
            if ~any(cellfun(@any,isS))
                % if not, then update the progressbar and exit
                obj.hProgT.Update(6,1);
                return
                
            else
                % otherwise, allocate memory for the classification
                iGrpS = arrayfun(@(x)(cell(x,1)),obj.nTube,'un',0);
                BCL = arrayfun(@(x)(cell(x,1)),obj.nTube,'un',0);
            end
            
            % runs the model classification for all images in the stack
            for iFrm = 1:obj.nFrm
                
                % updates the progressbar
                if obj.hProgT.Update(6,iFrm,obj.nFrm)
                    % if the user cancelled, then exit
                    obj.calcOK = false;
                    return
                end
                
                % ---------------------------------- %
                % --- INITIAL SEARCH POINT SETUP --- %
                % ---------------------------------- %                

                % memory allocation
                fP0 = cell(obj.nApp,1);
                ICh = obj.objC.setupClassifyImageStack(obj.Img0{iFrm},0);
                
                % loops through each of the regions/sub-regions retrieving
                % the initial search points
                for i = 1:obj.nApp
                    % memory allocation
                    fPT = cell(obj.nTube(i),1);
                    
                    % sets the search points for each stationary sub-region
                    for j = find(isS{i}(:)')
                        % retrieves the sub-region row/column indices
                        [iRS,iCS] = obj.getRegionIndices(i,j);
                        szT = [length(iRS),length(iCS)];             
                        pOfs = [iCS(1),iRS(1)] - 1;
                        
                        % updates the movement flag 
                        obj.mFlag{1,i}(j) = 1;

                        % sets the search points based on frame index
                        if iFrm == 1
                            % case is first frame (use general search)

                            % sets up the sub-region grid-points
                            [X,Y] = obj.objC.setupSearchGrid(szT,2);
                            fPT{j} = [arr2vec(iCS(X)),arr2vec(iRS(Y))];

                        else
                            % case is other frame (use previous frame)

                            % sets the points from the previous frame
                            [Y,X] = ind2sub(szT,iGrpS{i}{j});
                            fPT{j} = [X(:)+pOfs(1),Y(:)+pOfs(2)];
                        end
                    end
                    
                    % stores all points for the current region
                    fP0{i} = cell2mat(fPT);
                    clear fPT;
                end
                
                % converts the cell array to the correct format
                fP = cell2mat(fP0);                
               
                % ---------------------------- %
                % --- IMAGE CLASSIFICATION --- %
                % ---------------------------- %                

                % sets up and runs the classification neighbourhood search
                BC{iFrm} = obj.objC.runNeighbourhoodSearch(ICh,fP);                
                
                % sets the classified image mask for the stationary regions
                for i = 1:obj.nApp
                    for j = find(isS{i}(:)')
                        % memory allocation
                        if iFrm == 1
                            BCL{i}{j} = cell(obj.nFrm,1);
                        end
                        
                        % updates the binary mask
                        [iRS,iCS] = obj.getRegionIndices(i,j);
                        BCL{i}{j}{iFrm} = BC{iFrm}(iRS,iCS);
                        BS(iRS,iCS) = BS(iRS,iCS) | BC{iFrm}(iRS,iCS);

                        % sets the stationary binary blobs
                        iGrpS{i}{j} = cell2mat(getGroupIndex(BS(iRS,iCS)));
                    end
                end                            
                
            end

            % -------------------------------------- %            
            % --- POST CLASSIFICATION OPERATIONS --- %
            % -------------------------------------- %
            
            % updates the progressbar
            obj.hProgT.Update(6,0);            
            
            % sets the classified image mask for the stationary regions
            for i = 1:obj.nApp
                for j = find(isS{i}(:)')                    
                    % updates the binary mask
                    [iRS,iCS] = obj.getRegionIndices(i,j);            
                    pOfs = [iCS(1),iRS(1)] - 1;       
                    
                    % retrieves the region binary mask
                    Isum = calcImageStackFcn(BCL{i}{j},'sum');                    
                    [iGrpT,pCT] = getGroupIndex(Isum >= nFrmMin,'Centroid');
                    switch length(iGrpT)
                        case 0
                            % case is there are no blobs
                            indT = NaN;
                            
                        case 1
                            % case is there is only one blob
                            indT = 1;
                            
                        otherwise
                            % case is there are multiple blobs
                            
                            % determines the most likely stationary blob
                            grpSz = cellfun('length',iGrpT);                            
                            ImeanG = cellfun(@(x)(max(Isum(x))),iGrpT);
                            indT = argMax(grpSz.*ImeanG);
                    end
                    
                    % sets the positional coordinates
                    if isnan(indT)
                        % case is there is no match
                        fPosL = NaN(1,2);
                        
                    else
                        % otherwise, reset the most likely group index
                        fPosL = round(pCT(indT,:));
                    end
                    
                    % resets the local/global coordinates of the point
                    for iFrm = 1:obj.nFrm
                        obj.fPosTL{i,iFrm}(j,:) = fPosL;
                        obj.fPosTG{i,iFrm}(j,:) = fPosL + pOfs;
                    end
                end
            end
            
            % updates the progressbar
            obj.hProgT.Update(6,1);              
            
        end
        
        % ------------------------------------------- %
        % --- FAST IMAGE CLASSIFICATION FUNCTIONS --- %
        % ------------------------------------------- %        
        
        % --- classifies all of the images in the stack
        function BC = classifyAllImagesFast(obj,useMove)
            
            % sets the default input arguments
            if ~exist('useMove','var'); useMove = true; end

            % memory allocation
            xiN = -2:2;
            idX = obj.pTrain.iCh == 2;
            BS = false(obj.szG);
            
            % memory allocation & field retrieval
            BC = cell(obj.nFrm,1);
            isM = cellfun(@(x)(x == 1),obj.sFlagT,'un',0);
            isS = cellfun(@(x)(x == 2),obj.sFlagT,'un',0);
            iGrpS = arrayfun(@(x)(cell(x,1)),obj.nTube,'un',0);
            
            % runs the model classification for all images in the stack
            for iFrm = 1:obj.nFrm
                
                % updates the progressbar
                obj.hProgT.Update(6,iFrm,obj.nFrm)
                
                % ---------------------------------- %
                % --- INITIAL SEARCH POINT SETUP --- %
                % ---------------------------------- %
                
                % memory allocation
                fP0 = cell(obj.nApp,1);
                ICh = obj.objC.setupClassifyImageStack(obj.Img0{iFrm},0);
                
                % loops through each of the regions/sub-regions retrieving
                % the initial search points
                for i = 1:obj.nApp
                    % memory allocation
                    fPT = cell(obj.nTube(i),1);
                    
                    %
                    for j = 1:obj.nTube(i)
                        if isM{i}(j) && useMove
                            % case is a moving blob
                            
                            % use the points surrounding the moving point
                            fPM = obj.fPosTG{i,iFrm}(j,:);
                            [X,Y] = meshgrid(fPM(1)+xiN,fPM(2)+xiN);
                            fPT{j} = [X(:),Y(:)];
                            
                        elseif isS{i}(j)
                            % case is a potentially stationary blob
                            
                            % retrieves the sub-region row/column indices
                            [iRS,iCS] = obj.getRegionIndices(i,j);
                            szT = [length(iRS),length(iCS)];             
                            pOfs = [iCS(1),iRS(1)] - 1;                            
                            
                            % sets the search points based on frame index
                            if iFrm == 1
                                % case is first frame (use general search)
                                
                                % sets up the sub-region grid-points
                                IChS = ICh{idX}(iRS,iCS);
                                [X,Y] = obj.setupInitPointSearch(IChS);
                                fPT{j} = [arr2vec(iCS(X)),arr2vec(iRS(Y))];
                                
                            else
                                % case is other frame (use previous frame)
                                
                                % sets the points from the previous frame
                                [Y,X] = ind2sub(szT,iGrpS{i}{j});
                                fPT{j} = [X(:)+pOfs(1),Y(:)+pOfs(2)];
                            end
                        end
                    end
                    
                    % stores all points for the current region
                    fP0{i} = cell2mat(fPT);
                    clear fPT;
                end
                
                % converts the cell array to the correct format
                fP = cell2mat(fP0);
                
                % ---------------------------- %
                % --- IMAGE CLASSIFICATION --- %
                % ---------------------------- %                

                % sets up and runs the classification neighbourhood search
                BC{iFrm} = obj.objC.runNeighbourhoodSearch(ICh,fP);
                
                % sets the classified image mask for the stationary regions
                for i = 1:obj.nApp
                    for j = find(isS{i}(:)')
                        % updates the binary mask
                        [iRS,iCS] = obj.getRegionIndices(i,j);
                        BS(iRS,iCS) = BS(iRS,iCS) | BC{iFrm}(iRS,iCS);
                        
                        % sets the stationary binary blobs
                        iGrpS{i}{j} = cell2mat(getGroupIndex(BS(iRS,iCS)));
                    end
                end
                    
            end
                
        end         
        
        % --- sets up the stationary point initial search grid
        function [X,Y] = setupInitPointSearch(obj,IChS)
            
            % distance tolerances
            szS = size(IChS);
            [dXmin,dXmax] = deal(obj.Nh-2,obj.Nh+2);
            iPmn = find(imregionalmin(IChS));
            iPmx = find(imregionalmax(IChS));
            
            % removes any infeasible minima/maxima
            iPmn = iPmn(IChS(iPmn) < 0);
            iPmx = iPmx(IChS(iPmx) > 0);            
            
            % determines the sub-image regional minima/maxima 
            [yPmn,xPmn] = ind2sub(szS,iPmn);
            [yPmx,xPmx] = ind2sub(szS,iPmx);            
            
            % determines the minima/maxima within distance range
            [dY,dX] = deal(pdist2(yPmn,yPmx),xPmx' - xPmn);
            BXY = (dY <= 1) & (dX >= dXmin) & (dX <= dXmax);
            [iMn,iMx] = find(BXY);            
            
            % sets the expanded points surrounding the feasible extrema
            fP0 = round([xPmn(iMn)+xPmx(iMx),yPmn(iMn)+yPmx(iMx)]/2);
            fPex = cell2mat(cellfun(@(x)(...
                obj.expandPointCoords(x,1)),num2cell(fP0,2),'un',0));
           
            % sets the final unique/feasible points
            fPex = unique(fPex,'stable','rows');
            ii = all(fPex <= flip(size(IChS)),2) & all(fPex > 0,2);
            [X,Y] = deal(fPex(ii,1),fPex(ii,2));
            
        end                                
        
        % --------------------------------- %
        % --- FIELD RETRIEVAL FUNCTIONS --- %
        % --------------------------------- %                
        
        % --- sets up the coordinates of the non-blob points
        function fPR = setupOtherPointCoords(obj,I,BG,indG,fPG)
            
            % memory allocation
            iOfs = 0;            
            iPR = cell(size(indG,1),1);
            
            % determines the local regional minima
            BD = obj.setupPointDiskMask(fPG);            
            B0 = (I > 0) & BG & BD;
            
            % determines the unique region groupings
            [~,~,iB] = unique(indG(:,1),'stable');
            indC = arrayfun(@(x)(find(iB==x)),1:max(iB),'un',0);
            
            %
            for i = 1:length(indC)
                % retrieves the region index
                iApp = indG(indC{i}(1),1);
                iAppS = indG(indC{i},2);
                
                % sets the candidate grid points for the sub-regions
                for j = 1:length(indC{i})
                    % retrieves the sub-region coordinates
                    [iRnw,iCnw] = obj.getRegionIndices(iApp,iAppS(j));
                    szT = [length(iRnw),length(iCnw)];
                    
                    % sets up the sub-region grid-points
                    [X,Y] = obj.objC.setupSearchGrid(szT,obj.Nh,iCnw,iRnw);
                    
                    % stores the grid points (not overlapping the known
                    % candidate point neighbouring binary mask)
                    indP = sub2ind(obj.szG,Y,X);
                    iPR{j+iOfs} = indP(B0(indP));                    
                end
                    
                % increments the row counter
                iOfs = iOfs + length(indC{i});
            end
            
            % converts the indices to global coordinates
            [yPR,xPR] = ind2sub(obj.szG,cell2mat(iPR));                        
            fPR = num2cell([xPR,yPR],2);
            
        end                                
        
        % --- retrieves the classification indices for the region, iApp
        function fPR = getClassifyRegionIndices(obj,iApp,iReg)
            
            % sets the region row indices (based on input type)
            if exist('iReg','var')
                % case is the sub-region indices are provided                                
                iRF = obj.iR{iApp}(cell2mat(obj.iRT{iApp}(iReg)'));
            else
                % case is region index only is provided
                iRF = obj.iR{iApp};
            end
            
            % converts the row/column indices to a coordinate array
            [X,Y] = meshgrid(obj.iC{iApp},iRF);
            fPR = [X(:),Y(:)];
            
        end                                
                
        % ---------------------------- %
        % --- DIAGNOSTIC FUNCTIONS --- %
        % ---------------------------- %        
        
        % --- calculates the training accuracy metrics
        function [yAcc,iPred] = calcTrainingAccuracy(obj)
            
            tData = obj.setupTrainingDataStore(false);
            iPred = classify(obj.pNet,tData); 
            yAcc = sum(iPred == obj.iIDT)/sum(obj.nCountT);
            
        end                

        % ------------------------- %
        % --- SCALING FUNCTIONS --- %
        % ------------------------- %
        
        % --- down-scales the coordinates
        function P = downScaleCoords(obj,P0)
            
            P = max(1,round(P0/obj.pSF));
            
        end
        
        % --- up-scales the coordinates
        function P = upScaleCoords(obj,P0)
            
            P = P0*obj.pSF;
            
        end        
        
        % --- rescales the coordinates
        function rescaleCoords(obj,isDownSample)
            
            % exit is there is no scaling
            if obj.pSF == 1
                % sets the 
                if isDownSample
                    % case is retrieving initial values
                    obj.fPosTG = obj.objB.fPosG{1};
                    obj.fPosTL = obj.objB.fPosL{1};
                else
                    % case is setting final values
                    obj.objB.fPosL{1} = obj.fPosTL;
                    obj.objB.fPosG{1} = obj.fPosTG;
                end
                
                % exits the function
                return
            end
            
            if isDownSample            
                % case is downsampling the coordinates (initial)
                obj.fPosTG = cellfun(@(x)(...
                    obj.downScaleCoords(x)),obj.objB.fPosG{1},'un',0);
                obj.fPosTL = cellfun(@(x)(...
                    obj.downScaleCoords(x)),obj.objB.fPosL{1},'un',0);                
                
            else
                % case is upsampling the coordinates (final)
                obj.objB.fPosL{1} = cellfun(@(x)(...
                    obj.upScaleCoords(x)),obj.fPosTL,'un',0);
                obj.objB.fPosG{1} = cellfun(@(x)(...
                    obj.upScaleCoords(x)),obj.fPosTG,'un',0);                
            end
                        
        end
        
        % --- rescales the image row/column indices
        function rescaleAllIndices(obj)
            
            function ind = rescaleIndices(ind0,pS)
                
                ind = unique(floor((ind0-1)/pS)+1);
                
            end
            
            % field retrieval
            obj.iR = obj.iMov.iR;
            obj.iC = obj.iMov.iC;
            obj.iRT = obj.iMov.iRT;             
            
            % exit is there is no scaling
            if obj.pSF == 1; return; end                       
            
            % rescales the region/sub-region row/column indices
            for i = 1:obj.nApp
                % rescales the row/column indices
                obj.iR{i} = rescaleIndices(obj.iR{i},obj.pSF);
                obj.iC{i} = rescaleIndices(obj.iC{i},obj.pSF);
                
                % rescales the sub-region indices
                for j = 1:obj.nTube(i)
                    obj.iRT{i}{j} = rescaleIndices(obj.iRT{i}{j},obj.pSF);
                end
            end            
            
        end        
        
        % --- rescales the image, I, but the scale factor, pSF
        function I = rescaleImage(obj,I)
            
            if obj.pSF > 1
                I = imresize(I,1/obj.pSF);
            end
            
        end        
        
        % ------------------------------- %        
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- runs the model training accuracy check
        function runAccuracyCheck(obj)
            
            % if the training was successful, then exit
            if obj.trainSuccess
                return
            end
            
            % calculates the model accuracy
            pAcc0 = obj.calcTrainingAccuracy();
            if pAcc0 < obj.pAccMin
                % if too low, then output the training error message
                obj.outputTrainErrorMsg();
                
                % flag an error occurred then exit.
                obj.calcOK = false;
                return
            end
            
        end
        
        % --- sets up the point distance mask
        function BD = setupPointDiskMask(obj,fPG)
           
            BD = bwdist(setGroup(fPG,obj.szG),'chessboard') > obj.Nh;            
            
        end                                
        
        % --- retrieves row/column indices for a given region/subregion
        function [iRS,iCS] = getRegionIndices(obj,iApp,iAppS)
            
            % retrieves the column indices
            iCS = obj.iC{iApp};
            
            % retrieves the region indices
            if exist('iAppS','var')
                % case is for a sub-region
                iRS = obj.iR{iApp}(obj.iRT{iApp}{iAppS});
            else
                % case is for an entire region
                iRS = obj.iR{iApp};
            end
            
        end             
        
    end
    
    % private class methods
    methods (Access = private)
        
        % --- sets a class object field
        function SetDispatch(obj, propname, varargin)
            obj.objB.(propname) = varargin{:};
        end
        
        % --- gets a class object field
        function varargout = GetDispatch(obj, propname)
            varargout{:} = obj.objB.(propname);
        end
        
    end     
    
    % static class methods
    methods (Static)
        
        % --- expands the coordinates around the point, fP0
        function fP = expandPointCoords(fP0,use8C)
            
            % sets the default input arguments
            if ~exist('use8C','var'); use8C = false; end
            
            % sets the neighbourhood size
            if use8C
                % case is 8-element connected neighbourhood
                [dX,dY] = meshgrid(-1:1);
                
            else
                % case is 4-element connected neighbourhood
                dX = [-1;zeros(3,1);1];
                dY = [0;(-1:1)';0];                
            end
            
            % initialisations
            fP = [fP0(1)+dX(:),fP0(2)+dY(:)];
                        
        end        
        
        % --- outputs an model training error message 
        function outputTrainErrorMsg()
            
            % character strings
            arrChr = char(8594);
            dotChr = char(8226);
            
            % sets the main header strings
            mStrH = {'Increase the following parameters:',...
                     'Decrease the following parameters:',...
                     'Remove Y-Gradient from classification types.'};
            mStrS = {{'Convolution Filter Size',...
                      'Network Level Count'};...
                     {'Training Batch Size',...
                      'Maximum Epoch Count',...
                      'Solver Stopping Count'};[]};
                 
            % sets up the messagebox fields
            tStr = 'Poor Model Performance';
            eStr = sprintf(['The accuracy of the trained network is ',...
                'too low. To improve model accuracy, make the ',...
                'following changes to the training parameters:\n']);
            
            % sets up the hint strings
            for i = 1:length(mStrH)
                % sets the strings for each sub-section
                eStrH = sprintf('  %s %s',dotChr,mStrH{i});                
                for j = 1:length(mStrS{i})
                    eStrH = sprintf(...
                        '%s\n    %s %s',eStrH,arrChr,mStrS{i}{j});
                end
                
                % appends the 
                eStr = sprintf('%s\n%s',eStr,eStrH);
            end
            
            % outputs the message to screen
            waitfor(msgbox(eStr,tStr,'modal'))
            
        end
        
    end
    
end