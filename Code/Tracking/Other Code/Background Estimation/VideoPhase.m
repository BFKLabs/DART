classdef VideoPhase < handle
    % class properties
    properties
        % main class fields
        iData
        iMov
        hProg
        iPhase
        vPhase
        iLvl
        ImnF
        
        % parameters
        nImgR = 10;
        p0 = 0.00;
        pW = 0.70;        
        pTolPhase = 5;
        pTolHi = 236;  
        pTolLo = 20;  
        
        % calculated object class fields
        NGrp
        iFrmGrp        
        Img
        iFrm0        
        xiH
        Zmn
        Zsd
        
        % other arrays
        isCheck
        Zrng
        Zmu
        pZHi
        pZLo
        
    end
    
    % class methods
    methods 
        % class constructor
        function obj = VideoPhase(iData,iMov,hProg,iLvl)
            
            % main input fields
            obj.iData = iData;   
            obj.iMov = iMov; 
            obj.hProg = hProg; 
            obj.iLvl = iLvl;
            
        end

        % ------------------------------------ %
        % --- PHASE DETECTION CALCULATIONS --- %
        % ------------------------------------ %        
        
        % --- runs the phase detection algorithm
        function runPhaseDetect(obj)
            
            % parameters
            dtFrm = 150;
            dnFrm = dtFrm*(obj.iData.exP.FPS/obj.iMov.sRate);                
            
            % ---------------------------------- %
            % ---- FUNCTION INITIALISATIONS ---- %
            % ---------------------------------- %
            
            % initialisations
            nFrmTot = obj.iData.nFrm;  
            obj.initPhaseDetectPara();                       
            
            % calculates the initial inter-frame metrics/groupings  
            nFrm = 1+ceil(nFrmTot/dnFrm);
            iFrm = roundP(linspace(1,nFrmTot,nFrm)');                        
            
            % --------------------------------- %
            % ---- INITIAL PHASE DETECTION ---- %
            % --------------------------------- %

            % initialisations
            iGrp = [1,1];
            
            % calculates the metrics for the first frame
            obj.calcFrameMetrics(iFrm(1));

            % loops through each of the frames determining if there are any 
            % major changes in the background intensity
            for i = 1:nFrm-1
                % calculates the metrics for the new frame
                iFrmG = iFrm(i + [0,1]);
                obj.calcFrameMetrics(iFrm(i+1));
                dImnG = obj.groupMetricComp(iGrp(end,:),iFrm(i+1));    

                % determines if the difference in mean pixel intensity 
                % (between regions) is less than tolerance
                if dImnG < obj.pTolPhase
                    % if so, then append the solution to the previous        
                    iGrp(end,2) = iFrm(i+1);           
                    
                else        
                    % otherwise, determine the new phase limits
                    iGrpNw = detPhaseLimits(obj,iFrmG); 

                    % appends the new limits to the overall grouping array
                    iGrp(end,2) = iGrpNw(1);
                    iGrpAdd = [iGrpNw(1:end-1,2),iGrpNw(2:end,1)];
                    iGrp = [iGrp;iGrpAdd;[iGrpNw(end,2),iFrmG(2)]];
                end

                % updates the progressbar    
                obj.isCheck(iFrmG(1):iFrmG(2)) = true;
                obj.updatePhaseDetectionProgress();
            end

            % --------------------------------- %
            % ---- HOUSE-KEEPING EXERCISES ---- %
            % --------------------------------- %                 
            
            % determines the initial phase status flags
            %  =1 - low-variance phase (use background subtraction)
            %  =2 - medium-variance phase (use direct detection)
            %  =3 - untrackable phase (use interpolation/reject)
            obj.reducePhaseTypes(iGrp);
            
        end
        
        % --- determines the phase limits
        function iGrpF = detPhaseLimits(obj,iFrm)

            % updates the check flags for the new frame indices
            obj.isCheck(iFrm) = true;

            %
            while 1
                % reads in the new frame (the mid-point between the limits)
                iFrmNw = roundP(mean(iFrm));
                ImnNw = obj.calcFrameMetrics(iFrmNw);
                ImnPr = full(obj.Zmu(:,iFrm));

                % calculates the sub-image stack mean and calculates the
                % difference with the current frame limit values    
                dImn = mean(abs(ImnPr-repmat(ImnNw,1,2)),1);

                % determines if any differences are less than tolerance
                isTol = dImn < obj.pTolPhase;
                if ~any(isTol)
                    % if not then analyse the new groupings separately 
                    iGrpF = [obj.detPhaseLimits([iFrm(1),iFrmNw]);...
                             obj.detPhaseLimits([iFrmNw,iFrm(2)])];
                    break
                else
                    % otherwise, replace the frame/mean values of the limit 
                    % that has the lower residual value
                    imn = argMin(dImn);
                    if imn == 1
                        obj.isCheck(iFrm(1):iFrmNw) = true;
                    else
                        obj.isCheck(iFrmNw:iFrm(2)) = true;
                    end

                    % updates the progressbar
                    obj.updatePhaseDetectionProgress();

                    % updates the frame/mean values
                    iFrm(imn) = iFrmNw;                
                    if diff(iFrm) == 1
                        % if the frame difference is equal to 1 then 
                        % exit the analysis loop
                        iGrpF = iFrm(:)';
                        break
                    end
                end
            end

        end        
        
        % --- reduces the phase types for each detected phase
        function reducePhaseTypes(obj,iGrp)

            % parameters
            dnFrmMin = 25;              % minimum frame        
            pTolPerc = 0.25;
            pTolRng = 0.25*256;         % pixel range tolerange

            % converts the cell arrays to a numerical array
            nGrp = size(iGrp,1);
            vPhaseF = zeros(nGrp,1);

            %
            for i = 1:nGrp
                % retrieves the non-sparse frames for the current group
                iGrpNw = iGrp(i,1):iGrp(i,2);
                iFrmG = find(obj.Zmu(1,iGrpNw)) + (iGrp(i,1)-1);

                % determines if the frame range is too low for tracking                
                ZrngNw = full(obj.Zrng(:,iFrmG));
                if any(ZrngNw(:) < pTolRng)
                    % pixel range is too low, so set as untrackable
                    vPhaseF(i) = 3;
                else
                    % otherwise, determine if the mean pixel intensity is 
                    % either too high or too low for tracking
                    pHiNw = full(obj.pZHi(:,iFrmG));
                    pLoNw = full(obj.pZLo(:,iFrmG));
                    if all(pHiNw(:)>pTolPerc) || all(pLoNw(:)>pTolPerc)
                        % the mean pixel intensity is either too high/low.
                        % therefore, flag that the phase is untrackable
                        vPhaseF(i) = 3;
                    else
                        % otherwise, determine if the frame range is either
                        % a low or medium variance phase
                        vPhaseF(i) = 1 + (diff(iGrp(i,:)) < dnFrmMin);
                    end
                end
            end

            % determines which adjacent phases are either
            % medium/untrackable phases AND have a small number of frames
            loVarPh = vPhaseF == 1;
            phID = 10*vPhaseF + (diff(iGrp,[],2) < dnFrmMin);
            phID(loVarPh) = phID(loVarPh) + rand(sum(loVarPh),1);
            [~,~,iC] = unique(phID,'stable');

            % groups each of the similar phases together
            indG = cell(max(iC),1);
            for i = 1:length(indG)
                indG{i} = getGroupIndex(iC==i); 
            end

            % sorts the index groups in chronological order
            indG = cell2cell(indG,1);
            indG0 = cellfun(@(x)(x(1)),indG);
            [~,iS] = sort(indG0);
            indG = indG(iS);

            % sets the final frame limits for each phase            
            [vPhaseF,nGrp] = deal(vPhaseF(indG0(iS)),length(indG));
            [iPhaseF,obj.ImnF] = deal(zeros(nGrp,2),cell(nGrp,1));
            for i = 1:length(indG)
                % sets the phase frame limits 
                iPhaseF(i,:) = [iGrp(indG{i}(1),1),iGrp(indG{i}(end),2)];                
                if vPhaseF(i) == 1
                    % if a low-variance phase, then calculate the average
                    % mean pixel intensity over all frames
                    iGrpNw = iPhaseF(i,1):iPhaseF(i,2);
                    iFrmG = find(obj.Zmu(1,iGrpNw)) + (iPhaseF(i,1)-1);
                    obj.ImnF{i} = nanmean(full(obj.Zmu(:,iFrmG)),2);
                end
            end

            % final field updates
            [obj.iPhase,obj.vPhase] = deal(iPhaseF,vPhaseF);

        end
        
        % --------------------------------- %
        % --- FRAME METRIC CALCULATIONS --- %
        % --------------------------------- %
        
        % --- calculates the inter-region metric differences
        function dImnG = groupMetricComp(obj,iGrp,iFrmNw)

            % retrieves the new/group metric values
            ImnNw = full(obj.Zmu(:,iFrmNw));
            ImnG = cellfun(@(x)...
                            (full(obj.Zmu(:,x))),num2cell(iGrp,2),'un',0);

            % calculates the maximum of the mean difference between the new
            % frame metric values and those already stored in the grouping 
            % index arrays
            dImnG = cellfun(@(x)(max(mean...
                            (abs(x-repmat(ImnNw,1,size(x,2))),1))),ImnG);

        end        
        
        % --- calculates the frame metrics for the frame(s) in iFrm
        function Imn = calcFrameMetrics(obj,iFrm)            

            % reads the image stacks and calculates the mean/range 
            I = num2cell(obj.readImgStack(iFrm,false),1);
            
            % calculates the metrics
            Imn = obj.calcSubImageStackMetrics(I,'mean');
            Irng = obj.calcSubImageStackMetrics(I,'range');
            pHi = obj.calcSubImageStackMetrics(I,'hi-perc',obj.pTolHi);
            pLo = obj.calcSubImageStackMetrics(I,'lo-perc',obj.pTolLo);            

            % sets the values into the overall metric arrays
            [obj.Zmu(:,iFrm),obj.Zrng(:,iFrm)] = deal(Imn,Irng);
            [obj.pZHi(:,iFrm),obj.pZLo(:,iFrm)] = deal(pHi,pLo);

        end                                
        
        % ----------------------------- %
        % --- IMAGE FRAME FUNCTIONS --- %
        % ----------------------------- %                    
        
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
            [obj.iMov.vPhase,obj.iMov.iPhase] = deal(obj.vPhase,obj.iPhase);
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
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %         
        
        % --- updates the phase detection progress
        function updatePhaseDetectionProgress(obj)

            % progress bar parameters
            pChk = mean(obj.isCheck);
            wStr = sprintf('Detecting Video Phases (%.2f%s Complete)',...
                            100*pChk,'%');

            % updates the progress bar
            obj.hProg.Update(obj.iLvl,wStr,obj.p0+obj.pW*pChk);

        end        
        
        % --- sets the phase detection parameters
        function initPhaseDetectPara(obj)
            
            % memory allocation
            nApp = length(obj.iMov.iR);            
            obj.isCheck = false(obj.iData.nFrm,1);
            [obj.Zrng,obj.Zmu] = deal(sparse(nApp,obj.iData.nFrm));     
            [obj.pZHi,obj.pZLo] = deal(sparse(nApp,obj.iData.nFrm));  
            
            % other initialisations
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

        % --- calculates the metrics from the image stack, I
        function Imet = calcSubImageStackMetrics(I,mType,varargin)

            switch mType
                case 'mean' % case is the mean pixel intensity
                    Imet0 = cellfun(@(x)(...
                            cellfun(@(y)(nanmean(y(:))),x)),I,'un',0);
                        
                case 'range' % case is the pixel intensity range
                    Imet0 = cellfun(@(x)(...
                            cellfun(@(y)(range(y(:))),x)),I,'un',0);
                        
                case 'hi-perc' % case is percentage of high pixels
                    pTol = varargin{1};
                    Imet0 = cellfun(@(x)(...
                            cellfun(@(y)(mean(y(:)>pTol)),x)),I,'un',0); 
                        
                case 'lo-perc' % case is percentage of low pixels
                    pTol = varargin{1};
                    Imet0 = cellfun(@(x)(...
                            cellfun(@(y)(mean(y(:)<pTol)),x)),I,'un',0);
                    
            end

            % converts the cell array to a numerical array
            Imet = cell2mat(Imet0);

        end
        
    end
end
