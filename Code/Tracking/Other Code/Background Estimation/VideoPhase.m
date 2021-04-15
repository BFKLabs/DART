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
        histTol = 0.300;
        ccTol = 0.100;
        pTileHi = 75;
        pTolHi = 240;
        nFrmHiMax = 10;
        nImgR = 5;
        nFrmMin = 20;
        pTol = 15;
        
        % calculated object class fields
        NGrp
        iFrmGrp        
        Img
        iFrm0        
        xiH
        Zmn
        Zsd
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
            
            % parameters
            dtFrm = 30;
            
            % ---------------------------------- %
            % ---- FUNCTION INITIALISATIONS ---- %
            % ---------------------------------- %
            
            % initialisations
            nFrmTot = obj.iData.nFrm;  
            [obj.Zmn,obj.Zsd] = deal(NaN);
            obj.initPhaseDetectPara();                       
            
            % calculates the initial inter-frame metrics/groupings  
            nFrm = roundP(obj.iData.nFrmT/(dtFrm*obj.iData.exP.FPS));
            iFrm = roundP(linspace(1,obj.iData.nFrm,nFrm));      
            
            % --------------------------------- %
            % ---- INITIAL PHASE DETECTION ---- %
            % --------------------------------- %
            
            % determines the initial frame groupings
            iFrmG0 = obj.getFrameGroupings(iFrm);  
            
            % determines the phase boundaries
            if size(iFrmG0,1) == 1
                iPhaseF = [1,nFrmTot];                
            else
                iPhaseTmp = cell(size(iFrmG0,1)-1,1);
                for i = 1:length(iPhaseTmp)
                    % sets the frame range and histograms for each phase                   
                    iPhase0 = [iFrmG0(i,2),iFrmG0(i+1,1)];

                    % determines the frame boundaries of the phases
                    iPhaseTmp{i} = obj.detPhaseBoundaries(iPhase0);
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
            
            % for each of the medium phases, determine if these phases are
            % actually high fluctuation phases
            for i = find(vPhaseF == 2)'
                dFrm = diff(iPhaseF(i,:)) + 1;
                if dFrm <= obj.nFrmHiMax
                    % reads all the frames within the phase
                    iFrmT = iPhaseF(i,1):iPhaseF(i,2);
                    ImgL = obj.readImgStack(iFrmT,false);    
                    ImgLmd = cellfun(@(x)(prctile(x(:),obj.pTileHi)),ImgL);
                                
                    % if any frames are over the hi-variance phase
                    % tolerances within the group, then re-assign the video
                    % phase classification to hi-variance
                    if any(ImgLmd(:) > obj.pTolHi)                    
                        vPhaseF(i) = 3;
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
        function iPhaseNw = detPhaseBoundaries(obj,iPhase0)
            
            % initialisations
            iPhaseNw = iPhase0;
            ImgBnd = obj.calcCombinedStackAvg(iPhase0);
            
            % keep reducing the phase difference until the frame diff is 1
            while diff(iPhaseNw) > 1            
                % reads the new image
                iFrmNw = roundP(mean(iPhaseNw));
                ImgNw = obj.calcCombinedStackAvg(iFrmNw);

                % calculates the histogram metrics between the new frame and 
                % the limits of the surrounding groups
                dImgNw = [max(abs(ImgBnd{1}(:)-ImgNw{1}(:))),...
                          max(abs(ImgBnd{2}(:)-ImgNw{1}(:)))];
                iNw = find(dImgNw < obj.pTol);

                % determines if there is a match to the lower/upper phases
                if isempty(iNw)
                    % if not, then a new phase is found. split and solve
                    
                    % sets the lower/upper phase boundaries
                    iPhase1 = [iPhaseNw(1),iFrmNw];
                    iPhase2 = [iFrmNw,iPhaseNw(2)]; 
                    
                    % determines the phase boundaries for the sub-regions
                    iPhaseNw = [detPhaseBoundaries(obj,iPhase1);...
                                detPhaseBoundaries(obj,iPhase2)];
                    break
                else
                    % if both limits are within threshold, then assign the
                    % region to the side with the lower metric value
                    if length(iNw) == 2
                        iNw = iNw(argMin(dImgNw));
                    end
                    
                    % updates the phase frame/histogram
                    iPhaseNw(iNw) = iFrmNw;
                end
            end           
                        
        end
        
        % --- retrieves the initial video phase groupings
        function iFrmGrp = getFrameGroupings(obj,iFrm)
            
            % calculates the combined average image values (for each frame
            % given in the index vector, iFrm)
            nFrm = length(iFrm);
            ImgG = obj.calcCombinedStackAvg(iFrm);            
            
            % calculates the max difference between each frame       
            dImgG = NaN(nFrm); 
            for j = 1:nFrm
                for i = (j+1):nFrm
                    dImgG(i,j) = max(abs(ImgG{i}(:)-ImgG{j}(:))); 
                end
            end
            
            % determines if there is a major difference between the frames
            isDiff = dImgG > obj.pTol;
            
            % groups the difference into their separate phases
            iFrmGrpL = [1,NaN];
            while 1
                % determines the next phase edge
                iNw = find(isDiff(:,iFrmGrpL(end,1)),1,'first');
                if isempty(iNw)
                    % case is there are no more frames
                    iFrmGrpL(end,2) = nFrm;
                    break
                else
                    % otherwise add the group edge and append the new phase
                    iFrmGrpL(end,2) = iNw - 1;
                    iFrmGrpL = [iFrmGrpL;[iNw,NaN]];
                end
            end            
            
            % sets the 
            iFrmGrp = iFrm(iFrmGrpL);                        
        end                       
        
        % --- calculates the combined row/column averages for each of the
        %     images given by the frame index array, iFrm
        function ImgMn = calcCombinedStackAvg(obj,iFrm)

            % sets the default input arguments
            if ~exist('iFrm','var'); iFrm = obj.iFrm0; end
            
            % memory allocation
            ImgMn = cell(1,length(iFrm));

            % retrieves the frames for each frame in the stack
            for i = 1:length(iFrm)
                % reads the new frame from the stack
                ImgNw = double(getDispImage(obj.iData,obj.iMov,iFrm(i),0));
                
                % calculates the mean row/column pixel values, and removes
                % the median values from the result
                ImgMn{i} = obj.calcCombinedImgAvg(ImgNw);
            end
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
    
    methods (Static)
        
        % --- calculates the combined image average
        function ImgMn = calcCombinedImgAvg(Img)
            
            % calculates the mean row/column pixel values, and removes
            % the median values from the result
            Itmp = [nanmean(Img,2);nanmean(Img,1)'];
            ImgMn = roundP(Itmp-nanmedian(Itmp));            
            
        end        
        
    end
end
