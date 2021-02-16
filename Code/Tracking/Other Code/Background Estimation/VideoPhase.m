classdef VideoPhase < handle
    % class properties
    properties
        % main class fields
        iData
        iMov
        iPhase
        vPhase
        
        % parameters        
        nBin = 256;
        histTol = 0.150;
        rsmeTol = 0.040;
        nImgR = 5;
        nFrmMin = 20;
        
        % calculated object class fields
        NGrp
        iFrmGrp        
        Img
        iFrm0        
        xiH
    end
    
    % class methods
    methods 
        % class constructor
        function obj = VideoPhase(iData,iMov)
            
            % main input fields
            obj.iData = iData;   
            obj.iMov = iMov;  
            
        end

        % --- runs the phase detection algorithm
        function runPhaseDetect(obj)
            
            % ---------------------------------- %
            % ---- FUNCTION INITIALISATIONS ---- %
            % ---------------------------------- %
            
            % initialisations
            nFrmTot = obj.iData.nFrm;
            iFrm = roundP(linspace(1,obj.iData.nFrm,obj.nImgR));  
            obj.initPhaseDetectPara();            
            
            % reads the image stack and sets up the histogram vector
            obj.Img = obj.readImgStack(iFrm);
            
            % calculates the initial inter-frame metrics/groupings            
            obj.getInitGroupings(iFrm);            
            
            % --------------------------------- %
            % ---- INITIAL PHASE DETECTION ---- %
            % --------------------------------- %
            
            % determines the phase boundaries
            if length(obj.iFrmGrp) == 1
                iPhaseF = [1,nFrmTot];                
            else
                iPhaseTmp = cell(length(obj.iFrmGrp)-1,1);
                for i = 1:(length(obj.iFrmGrp)-1)
                    % sets the frame range and histograms for each phase
                    iPhase0 = [obj.iFrmGrp{i}(end),obj.iFrmGrp{i+1}(1)];
                    NHist0 = [obj.NGrp{i}(end,:,:);obj.NGrp{i+1}(1,:,:)];

                    % determines the frame boundaries of the phases
                    iPhaseTmp{i} = obj.detPhaseBoundaries(NHist0,iPhase0);
                end

                iPhaseTot = cell2mat(iPhaseTmp);
                iPhaseF = [[1;iPhaseTot(:,2)],[iPhaseTot(:,1);nFrmTot]];
            end
            
            % ------------------------------- %
            % ---- VIDEO PHASE REDUCTION ---- %
            % ------------------------------- %
            
            % determines the frame count of each phase and determine the
            % classification of the phases based on this
            dFrm = diff(iPhaseF,[],2) + 1;
            vPhaseF = 1 + (dFrm < obj.nFrmMin);
            
            % for each of the medium phases, determine if these phases are
            % actually high fluctuation phases
            for i = find(vPhaseF == 2)'
                a = 1;
            end
            
            % reduces the concident phases with medium/high fluctuations
            for vP = 2:3
                if any(vPhaseF == vP)
                    % if there are any medium/high phases, then reduces the
                    % phases if they are adjoining
                    jGrp = getGroupIndex(vPhaseF == vP);
                    for i = length(jGrp):-1:1
                        if length(jGrp{i}) > 1
                            % sets the reduced frame range
                            iPhaseC = [iPhaseF(jGrp{i}(1),1),...
                                       iPhaseF(jGrp{i}(end),2)];
                            
                            % sets the indices of the phases to be kept
                            ii = true(length(vPhaseF),1);
                            ii(jGrp{i}(2:end)) = false;
                            
                            % reduces/updates the phase frame 
                            % index/classifcation arrays
                            vPhaseF = vPhaseF(ii);
                            iPhaseF = iPhaseF(ii,:);
                            iPhaseF(jGrp{i}(1),:) = iPhaseC;
                        end
                    end
                end
            end
            
            % --------------------------------- %
            % ---- HOUSE-KEEPING EXERCISES ---- %
            % --------------------------------- %            
            
            % sets the final arrays
            [obj.iPhase,obj.vPhase] = deal(iPhaseF,vPhaseF);
            
        end
        
        % --- determines the frame boundaries between phases
        function iPhaseNw = detPhaseBoundaries(obj,NHist,iPhase0)
            
            % initialisations
            iPhaseNw = iPhase0;
            
            % keep reducing the phase difference until the frame diff is 1
            while diff(iPhaseNw) > 1            
                % reads the new image
                iFrmNw = roundP(mean(iPhaseNw));
                ImgNw = obj.readImgStack(iFrmNw,false);                   
                NHistNw = calcImageHistograms(obj,ImgNw);

                % calculates the histogram metrics between the new frame and 
                % the limits of the surrounding groups
                mHistNw = [
                    calcImageHistMetrics(obj,[NHist(1,:,:);NHistNw],1);...
                    calcImageHistMetrics(obj,[NHist(2,:,:);NHistNw],1)];

                % determines which phases meet the tolerance
                Btol = [mHistNw(:,1)<obj.histTol,mHistNw(:,2)<obj.rsmeTol];
                iNw = find(all(Btol,2));

                % determines if there is a match to the lower/upper phases
                if isempty(iNw)
                    % if not, then a new phase is found. split and solve
                    
                    % sets the lower phase boundaries/histogram arrays
                    iPhase1 = [iPhaseNw(1),iFrmNw];
                    NHist1 = [NHist(1,:,:);NHistNw];
                    
                    % sets the upper phase boundaries/histogram arrays
                    iPhase2 = [iFrmNw,iPhaseNw(2)];                    
                    NHist2 = [NHistNw;NHist(2,:,:)];
                    
                    % determines the phase boundaries for the sub-regions
                    iPhaseNw = [detPhaseBoundaries(obj,NHist1,iPhase1);...
                                detPhaseBoundaries(obj,NHist2,iPhase2)];
                    break
                else
                    % if both limits are within threshold, then assign the
                    % region to the side with the lower metric value
                    if length(iNw) == 2
                        iNw = iNw(argMin(prod(mHistNw,2)));
                    end
                    
                    % updates the phase frame/histogram
                    iPhaseNw(iNw) = iFrmNw;
                    NHist(iNw,:,:) = NHistNw;
                end
            end           
                        
        end

        % --- retrieves the initial video phase groupings
        function getInitGroupings(obj,iFrm)
            
            %
            ImgL = cell2cell(cellfun(@(x)(cellfun(@(ir,ic)(x(ir,ic)),...
                    obj.iMov.iR,obj.iMov.iC,'un',0))',obj.Img,'un',0),0);
            
            % initialisations
            [isF,iGrp] = deal(false(obj.nImgR,1),[]);   
            NHist = obj.calcImageHistograms(ImgL);
            mHist = obj.calcImageHistMetrics(NHist);          
            
            % keep looping until all frames have been grouped
            while any(~isF)
                % determines the frames that are similar to each other
                iNw = find(~isF,1,'first');
                jGrp = getGroupIndex(obj.threshHistMet(mHist(:,iNw,:))&~isF);
                jGrp = jGrp{argMin(cellfun(@(x)(x(1)),jGrp))};                                                

                % appends these indices to a new grouping
                iGrp{end+1} = jGrp;
                isF(jGrp) = true;
            end         
            
            % sets the group frame indices/histogram signals
            obj.iFrmGrp = cellfun(@(x)(iFrm(x)),iGrp,'un',0);
            obj.NGrp = cellfun(@(x)(NHist(x,:,:)),iGrp,'un',0);
        end        
        
        % --- thresholds the histogram metrics
        function B = threshHistMet(obj,mHist)

            mHist = squeeze(mHist);
            B = (mHist(:,1)<=obj.histTol) & (mHist(:,2)<=obj.rsmeTol);

        end        
        
        % --- reads the image stack for the frames, iFrm
        function Img = readImgStack(obj,iFrm,isFull)

            % sets the default input arguments
            if ~exist('iFrm','var'); iFrm = obj.iFrm0; end
            if ~exist('isFull','var'); isFull = true; end
            
            % memory allocation
            Img = cell(length(iFrm),1);

            % retrieves the frames for each frame in the stack
            for j = 1:length(iFrm)
                Img{j} = double(...
                            getDispImage(obj.iData,obj.iMov,iFrm(j),0));
                if ~isFull
                    Img{j} = cellfun(@(ir,ic)(Img{j}(ir,ic)),...
                                    obj.iMov.iR,obj.iMov.iC,'un',0)';
                end
            end

            % converts the cell of cell arrays to a cell array
            if ~isFull
                Img = cell2cell(Img,0);
            end
        end                  
        
        % --- calculates the image histograms
        function NHist = calcImageHistograms(obj,Img)

            % memory allocation            
            [nApp,nImg] = size(Img);
            NHist = zeros(nImg,obj.nBin,nApp);      
            
            % calculates the image pixel intensity histograms
            for i = 1:nImg
                for j = 1:nApp
                    NN = imhist(uint8(Img{j,i}));
                    NHist(i,:,j) = NN/sum(NN);
                end
            end            
            
        end
        
        % --- calcualates the inter-frame histogram metrics
        function mHistF = calcImageHistMetrics(obj,NHist,reduceArr)

            % --- calculates the inter-frame histogram metrics, pN1 and pN2
            function [pOver,dMax] = calcHistMetrics(pN1,pN2)

                % calculates the overlap of the histograms
                A = [pN1(:),pN2(:)];
                [Amin,Amax] = deal(min(A,[],2),max(A,[],2));

                % determines the histogram overlap/max distance
                pOver = sum(Amin)/sum(Amax);
                dMax = max(Amax-Amin);

            end                  
            
            % default input arguments
            if ~exist('reduceArr','var'); reduceArr = false; end
            
            % memory allocation
            [nMet,nImg] = deal(2,size(NHist,1));
            mHist = repmat({zeros(nImg*[1,1])},nMet,1);
            
            % calculates the histogram metrics (between all frames)            
            for i = 1:nImg
                for j = (i+1):nImg
                    [pOver,dpOver] = calcHistMetrics(...
                           mean(NHist(i,:,:),3),mean(NHist(j,:,:),3));
                    [mHist{1}(i,j),mHist{1}(j,i)] = deal(1-pOver);
                    [mHist{2}(i,j),mHist{2}(j,i)] = deal(dpOver);
                end
            end
            
            % calculates the median metric values over all regions
            mHistF = cell2mat(reshape(cellfun(@(x)...
                            (nanmedian(x,3)),mHist,'un',0),[1,1,nMet]));
            
            % reduces the array (if required)
            if reduceArr
                mHistF = squeeze(mHistF(2,1,:))';
            end            
        
        end    
        
        % --- sets the solver parameter
        function setSolverPara(obj,pStr,pVal)
            
            eval(sprintf('obj.%s = %s;',pStr,num2str(pVal)));
            
        end
        
        % ---  reads the image frames for all phases
        function [Img,sImg] = readPhaseFrames(obj)
            
            % initialisations and memory allocation         
            nPhase = length(obj.vPhase);
            [Img,sImg] = deal(cell(nPhase,1));            
            
            % sets the frame indices
            iFrm = getPhaseFrameIndices(obj.iMov,obj.nImgR,obj.iPhase);                
            
            % reads the frames for each 
            for i = 1:nPhase                           
                % reads the video frames
                Img{i} = obj.readImgStack(iFrm{i});
                
                % reads the sub-image stack
                sImg{i} = setSubImageStruct(obj.iMov,Img{i});
                sImg{i}.iFrm = iFrm{i};                
            end
            
            % converts the cell array to a struct array
            sImg = cell2mat(sImg);
        end   
        
        % --- sets the phase detection parameters
        function initPhaseDetectPara(obj)
            
            % initialisations
            pPhase = obj.iMov.bgP.pPhase;
            pFld = fieldnames(pPhase);            
            
            % sets the parameter values
            for i = 1:length(pFld)
                if isfield(obj,pFld{i})
                    nwVal = getFieldValue(pPhase,pFld{i});
                    obj = setFieldValue(obj,pFld{i},nwVal);
                end
            end   
            
        end        
    end
end