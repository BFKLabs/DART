classdef ResidualDetect < handle
   
    % class properties
    properties
        
        % main class fields
        iMov
        hProg
        Img
        prData
        iPara
        
        % boolean/other scalar flags
        is2D
        calcInit
        wOfs = 0;      
        calcOK = true;   
        iPh
        vPh
        
        % dimensioning veriables
        nApp
        nTube
        nImg
        
        % permanent object fields
        fPosL
        fPos
        fPosG
        pMax
        pMaxG
        Phi
        axR
        NszB
        
        % temporary object fields
        IR      
        y0        
    end
    
    % class methods
    methods
        
        % class constructor
        function obj = ResidualDetect(iMov,hProg)
            
            % sets the input arguments
            obj.iMov = iMov;
            obj.hProg = hProg;
            
            % array dimensioning
            obj.nApp = length(obj.iMov.iR);
            obj.nTube = getSRCountVec(obj.iMov);
            obj.is2D = is2DCheck(obj.iMov);
            
            % sets the tube-region offsets
            obj.y0 = cell(obj.nApp,1);
            for iApp = 1:obj.nApp
                obj.y0{iApp} = cellfun(@(x)(x(1)-1),obj.iMov.iRT{iApp});
            end     
            
        end        
        
        % ---------------------------- %
        % --- MAIN SOLVER FUNCTION --- %
        % ---------------------------- %         
        
        % --- runs the main detection algorithm 
        function runDetectionAlgo(obj)
            
            % field updates and other initialisations
            obj.Img = obj.Img(~cellfun(@isempty,obj.Img));
            obj.nImg = length(obj.Img); 
            
            % initialises the object fields
            obj.initObjectFields()
            
            % segments the object locations for each region
            for iApp = find(obj.iMov.ok(:)')
                % updates the progress bar
                wStr = sprintf(['Residual Calculations ',...
                                '(Region %i of %i)'],iApp,obj.nApp);
                if obj.hProg.Update(2+obj.wOfs,wStr,iApp/(1+obj.nApp))
                    % if the user cancelled, then exit
                    obj.calcOK = false;
                    return
                end
                
                % segments the region
                obj.segmentRegions(iApp);                       
            end
            
            % updates the progressbar
            wStr = 'Residual Calculations (Complete!)';
            obj.hProg.Update(2+obj.wOfs,wStr,1);

            % converts the local coordinates to the global frame reference
            obj.calcGlobalCoords();      
            
        end           
        
        % --- segments the all the objects for a given region
        function segmentRegions(obj,iApp)
                        
            % initialisations
            imov = obj.iMov;
            iRT = imov.iRT{iApp};
            hG = fspecial('gaussian',3,1);
            [iR,iC] = deal(imov.iR{iApp},imov.iC{iApp});            
            y0L = [zeros(obj.nTube(iApp),1),obj.y0{iApp}(:)];
            
            % retrieves the global row/column indices
            nTubeR = getSRCount(obj.iMov,iApp);
            fok = obj.iMov.flyok(1:nTubeR,iApp);
            dTol = max(obj.iMov.szObj);
            
            % sets the residual tolerances
            if ~isfield(imov,'pBG')
                pTol = 10*ones(length(iRT),1);
            elseif size(imov.pBG,2) == obj.nApp
                pTol0 = imov.pBG{iApp};
                pTol = min(pTol0,nanmedian(pTol0));
            else
                pTolAll = cell2mat(cellfun(@(x)(x{iApp}),...
                                    imov.pBG(imov.vPhase==1)','un',0));
                pTol = nanmedian(pTolAll(:))*ones(length(iRT),1);               
            end
            
            % converts the residual tolerances to a cell array
            pTol(~fok) = NaN;
            pTol = num2cell(pTol);            
            
            % retrieves the exclusion binary mask
            Bw = getExclusionBin(obj.iMov,[length(iR),length(iC)],iApp);
            
            % calculates the residual images for            
            ImgBG = imov.Ibg{obj.iPh}{iApp}.*Bw;            
            ImgL = cellfun(@(I)(I(iR,iC).*Bw),obj.Img,'un',0);
            
            % calculates the residual images 
            IRes = cellfun(@(x)(imfilter(ImgBG-x,hG)),ImgL,'un',0);
            IResL = cell2cell(cellfun(@(x)(...
                       cellfun(@(ir)(x(ir,:)),iRT,'un',0)),IRes,'un',0),0);                                 
                   
            % sets the previous stack location data
            if isempty(obj.prData)
                % no previous data, so use empty values
                fPr = cell(obj.nTube(iApp),1);
            elseif ~isfield(obj.prData,'fPosPr')
                % no previous data, so use empty values
                fPr = cell(obj.nTube(iApp),1);                
            else
                % otherwise, use the previous values
                fPr = obj.prData.fPosPr{iApp}(:);
            end
                   
            % calculates the positions of the objects for each
            % frame/sub-region   
            fPos0 = cellfun(@(x,p,f0,fok)...
                    (obj.segSubRegions(x,p,f0,fok,dTol)),...
                    num2cell(IResL,2),pTol,fPr,num2cell(fok),'un',0);               
            
            % checks the stationary flies have not moved appreciable
            indF = 1:getSRCount(obj.iMov,iApp);
            for i = find(obj.iMov.Status{iApp}(indF)' == 2)
                % calculates the distance travelled over the frame stack
                % (relative to the original coordinates)
                if ~isempty(obj.prData)
                    fP0 = obj.prData.fPos{iApp}(i,:) - [0,obj.y0{iApp}(i)];
                    D = abs(repmat(fP0,obj.nImg,1)-cell2mat(fPos0{i}(:)));
                else
                    fP0 = cell2mat(fPos0{i}(:));
                    D = abs(repmat(median(fP0,1),obj.nImg,1)-fP0);
                end
                
                % determines if any objects have moved appreciably. if so,
                % then replace the coordinates with the initial position
                isMove = any(D > repmat(obj.iMov.szObj,obj.nImg,1)/2,2);
                for j = find(isMove(:)')
                    if ~isempty(obj.prData)
                        fPos0{i}{j} = fP0;
                    else
                        fPos0{i}{j} = fP0(j,:);
                    end
                end
            end            
                
            % performs the orientation angle calculations (if required)
            if imov.calcPhi
                % creates the orientation angle object
                phiObj = OrientationCalc(imov,num2cell(IResL,2),fPos0,iApp);
                                
                % sets the orientation angles/eigan-value ratio
                obj.Phi(iApp,:) = num2cell(phiObj.Phi,1);
                obj.axR(iApp,:) = num2cell(phiObj.axR,1);
                obj.NszB(iApp,:) = num2cell(phiObj.NszB,1);
            end            
            
            % sets the sub-region/region coorindates
            try
            obj.fPosL(iApp,:) = cellfun(@(x)(...
                    cell2mat(x)),num2cell(cell2cell(fPos0),1),'un',0);
            obj.fPos(iApp,:) = cellfun(@(x)(...
                    x+y0L),obj.fPosL(iApp,:),'un',0);
            catch
                a = 1;
            end
           
        end                           
        
        % --------------------------------- %
        % --- CLASS FIELD I/O FUNCTIONS --- %
        % --------------------------------- %
        
        % --- sets class field for the field string(s) given in pStr
        function setClassField(obj,pStr,pVal)
            
            % ensures the field strings are in a cell array
            if ~iscell(pStr); pStr = {pStr}; end
            
            % combines the field string
            fStr = 'obj';
            for i = 1:length(pStr)
                fStr = sprintf('%s.%s',fStr,pStr{i});
            end
            
            % updates the field value
            eval(sprintf('%s = pVal;',fStr));
            
        end
        
        % --- sets class field for the field string(s) given in pStr
        function pVal = getClassField(obj,pStr)
            
            % ensures the field strings are in a cell array
            if ~iscell(pStr); pStr = {pStr}; end
            
            % combines the field string
            fStr = 'obj';
            for i = 1:length(pStr)
                fStr = sprintf('%s.%s',fStr,pStr{i});
            end
            
            % retrieves the field value
            pVal = eval(fStr);
            
        end       
        
        % -------------------------- %
        % --- PLOTTING FUNCTIONS --- %
        % -------------------------- %
        
        function plotFramePos(obj,iImg,isFull)
            
            % sets the default input arguments
            if ~exist('isFull','var'); isFull = false; end
            
            % determine if the plot frame index is valid
            if iImg > obj.nImg
                % outputs an error message to screen
                eStr = sprintf(['The plot index (%i) exceeds the total',...
                    'number of frames (%i)'],iImg,obj.nImg);
                waitfor(errordlg(eStr,'Invalid Frame Reference','modal'))
                
                % exits the function
                return
            end
            
            % initialisations
            iStatus = obj.iMov.StatusF{obj.iPh};
            [I,iM] = deal(obj.Img{iImg},obj.iMov);
            [nR,nC] = deal(iM.nRow,iM.nCol);
            ILp = cellfun(@(ir,ic)(I(ir,ic)),iM.iR,iM.iC,'un',0);            
            
            % creates the image/location plots for each sub-region  
            figure;
            if isFull
                % memory allocation
                h = subplot(1,1,1);
                
                % creates the full image figure
                plotGraph('image',I,h)
                hold on
                
            else           
                % memory allocation
                h = zeros(obj.nApp,1);
                
                % creates the figure displaying each region separately
                for iApp = find(obj.iMov.ok(:)')
                    h(iApp) = subplot(nR,nC,iApp);
                    plotGraph('image',ILp{iApp},h(iApp)); 
                    hold on
                end
            end

            % plots the most likely positions     
            for iApp = find(obj.iMov.ok(:)')
                % retrieves the marker points
                if isFull
                    j = 1;
                    fPosP = obj.fPosG{iApp,iImg};
                else
                    j = iApp;
                    fPosP = obj.fPos{iApp,iImg};
                end
                
                % plots the markers
                isMove = iStatus(:,iApp) == 1;
                plot(h(j),fPosP(isMove,1),fPosP(isMove,2),'go');
                plot(h(j),fPosP(~isMove,1),fPosP(~isMove,2),'ro');
            end  
        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- initialises the solver fields
        function initObjectFields(obj)
            
            % flag initialisations
            obj.calcOK = true;            
            
            % permanent field memory allocation
            obj.fPosL = cell(obj.nApp,obj.nImg);
            obj.fPos = cell(obj.nApp,obj.nImg);
            obj.fPosG = cell(obj.nApp,obj.nImg); 
            
            % orientation angle memory allocation
            if obj.iMov.calcPhi
                obj.Phi = cell(obj.nApp,obj.nImg);
                obj.axR = cell(obj.nApp,obj.nImg);
                obj.NszB = cell(obj.nApp,obj.nImg);
            end
            
            % initialises the progressbar
            wStr = 'Residual Calculations (Initialising)';
            obj.hProg.Update(2+obj.wOfs,wStr,0);            
            
        end     
        
        % --- calculates the global coords from the sub-region reference
        function calcGlobalCoords(obj)
            
            % exit if not calculating the background
            if ~obj.calcOK; return; end            
            
            % memory allocation
            [~,nFrm] = size(obj.fPos);
            obj.fPosG = repmat(arrayfun(@(x)(NaN(x,2)),...
                                                obj.nTube,'un',0),1,nFrm);
            obj.pMaxG = repmat(arrayfun(@(x)(cell(x,1)),...
                                                obj.nTube,'un',0),1,nFrm);                                            
            
            % converts the coordinates from the sub-region to global coords
            for iApp = find(obj.iMov.ok(:)')
                % calculates the x/y offset of the sub-region
                xOfs = obj.iMov.iC{iApp}(1)-1;
                yOfs = obj.iMov.iR{iApp}(1)-1;
                
                % calculates the global offset and appends it to each frame
                pOfs = repmat([xOfs,yOfs],obj.nTube(iApp),1);
                for iFrm = 1:nFrm
                    obj.fPosG{iApp,iFrm} = obj.fPos{iApp,iFrm} + pOfs;
                    obj.pMaxG{iApp,iFrm} = num2cell(obj.fPosG{iApp,iFrm},2);
                end
            end            
            
        end           
        
        % --- closes the progressbar (if created within internally)
        function performHouseKeepingOperations(obj)
           
            % clears the temporary image array fields
            obj.IR = [];
            obj.y0 = [];            
            
        end       
        
    end
    
    methods(Static)
        
        % --- calculates the locations of the objects for each sub-region
        function fPos = segSubRegions(IRL,pTol,fPr,fok,dTol)
            
            % initialisations
            nFrm = length(IRL);
            
            % determines if the region has been rejected            
            if ~fok
                % if so, then return NaN's
                fPos = num2cell(NaN(nFrm,2),2)';
                return
            end
            
            % calculates the new positions from the sub-image stack
            IRL = cellfun(@(x)(x-nanmedian(x(:))),IRL,'un',0);
            [fPosNw,IRmx] = segSingleSubRegion(IRL,fPr,dTol);
            
            % determines which frames have a residual value above tolerance
            isOK = IRmx >= pTol;
            if ~any(isOK)
                % if not any, then determine if there is any previous data  
                % from which to set the missing frames
                if isempty(fPr)
                    % if not, then return NaN's
                    fPos = num2cell(NaN(nFrm,2),2)';
                else
                    % otherwise, repeat these values
                    fPos = num2cell(repmat(fPr(end,:),nFrm,1),2)';
                end

                % exits the function
                return
            else
                % otherwise, convert the position array to a cell array
                fPos = num2cell(fPosNw,2)';
            end
            
            % if there are any missing frames, then set the position 
            % coordinates from the surrounding frames
            if any(~isOK)
                jGrp = getGroupIndex(~isOK);
                for i = 1:length(jGrp)
                    if jGrp{i}(1) == 1
                        % case is the first frame in the group is the first
                        % frame (use the first non-empty frame)
                        fPos(jGrp{i}) = fPos(jGrp{i}(end)+1);
                    else
                        % case is the last frame is the last overall (use
                        % the previous non-empty frame)
                        fPos(jGrp{i}) = fPos(jGrp{i}(1)-1);
                    end
                end
            end                    
        end        
        
    end
end
