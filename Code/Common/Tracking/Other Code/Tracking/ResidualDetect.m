classdef ResidualDetect < handle
    % class properties
    properties
        % main class fields
        iMov
        hProg
        Img
        prData
        iPara
        iPhase
        
        % boolean/scalar flags
        wOfs = 0;      
        calcOK = true;        
        
        % permanent object fields
        fPosL
        fPos
        fPosG
        pMax
        pMaxG
        
        % temporary object fields
        IR      
        y0
        
        % dimensioning veriables
        nApp
        nTube
        nImg              
        
        % variable parameters
        
    end
    
    % methods
    methods
        % class constructor
        function obj = ResidualDetect(iMov,hProg)
            
            % sets the input arguments
            obj.iMov = iMov;
            obj.hProg = hProg;
            
            % array dimensioning
            obj.nApp = length(obj.iMov.iR);
            obj.nTube = getFlyCount(obj.iMov,1);
            
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
        function runDetectionAlgo(obj,prData)
           
            % default input arguments
            if ~exist('prData','var'); prData = []; end
            
            % field updates and other initialisations
            obj.prData = prData;
            obj.nImg = length(obj.Img); 
            
            % initialises the object fields
            obj.initObjectFields()
            
            % segments the object locations for each region
            for iApp = 1:obj.nApp
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
        
        % --- initialises the solver fields
        function initObjectFields(obj)   
            
            % flag initialisations
            obj.calcOK = true;            
            
            % permanent field memory allocation
            obj.fPosL = cell(obj.nApp,obj.nImg);
            obj.fPos = cell(obj.nApp,obj.nImg);
            obj.fPosG = cell(obj.nApp,obj.nImg); 
            
            % initialises the progressbar
            wStr = 'Residual Calculations (Initialising)';
            obj.hProg.Update(2+obj.wOfs,wStr,0);            
            
        end        
        
        % --- segments the all the objects for a given region
        function segmentRegions(obj,iApp)
            
            % initialisations
            imov = obj.iMov;
            iRT = imov.iRT{iApp};
            [iR,iC] = deal(imov.iR{iApp},imov.iC{iApp});
            pTol = num2cell(imov.pBG{obj.iPhase}{iApp});
            y0L = [zeros(obj.nTube(iApp),1),obj.y0{iApp}(:)];
            fok = num2cell(obj.iMov.flyok(:,iApp));
            
            % calculates the residual images for 
            ImgBG = imov.Ibg{obj.iPhase}{iApp};            
            ImgL = cellfun(@(I)(I(iR,iC)),obj.Img,'un',0);            
            
            % calculates the residual images 
            IRes = cellfun(@(x)(ImgBG-x),ImgL,'un',0);
            IResL = cell2cell(cellfun(@(x)(...
                       cellfun(@(ir)(x(ir,:)),iRT,'un',0)),IRes,'un',0),0);
                   
            % calculates the positions of the objects for each
            % frame/sub-region
            fPos0 = cellfun(@(x,p,fok)(obj.segSubRegions(x,p,fok)),...
                    num2cell(IResL,2),pTol,fok,'un',0);
                
            % sets the sub-region/region coorindates
            obj.fPosL(iApp,:) = cellfun(@(x)(...
                    cell2mat(x)),num2cell(cell2cell(fPos0),1),'un',0);
            obj.fPos(iApp,:) = cellfun(@(x)(...
                    x+y0L),obj.fPosL(iApp,:),'un',0);
           
        end                           
        
        % --------------------------------- %
        % --- CLASS FIELD I/O FUNCTIONS --- %
        % --------------------------------- %         
        
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
            for iApp = 1:obj.nApp
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
            iStatus = obj.iMov.StatusF{obj.iPhase};
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
                for iApp = 1:obj.nApp
                    h(iApp) = subplot(nR,nC,iApp);
                    plotGraph('image',ILp{iApp},h(iApp)); 
                    hold on
                end
            end

            % plots the most likely positions     
            for iApp = 1:obj.nApp
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
        
        % --- closes the progressbar (if created within internally)
        function performHouseKeepingOperations(obj)
           
            % clears the temporary image array fields
            obj.IR = [];
            obj.y0 = [];            
            
        end        
    end
    
    % static methods
    methods (Static)
        % --- calculates the locations of the objects for each sub-region
        function fPos = segSubRegions(IRL,pTol,fok)
            
            % determines if the region has been rejected            
            if ~fok
                % if so, then return NaN's
                fPos = num2cell(NaN(length(IRL),2),2)';
                return
            else
                % other, setup arrays for the position output
                nFrm = length(IRL);
                [sz,fPos] = deal(size(IRL{1}),cell(1,nFrm));                
            end
            
            % thresholds the image for the pixel tolerance, pTol
            iGrp = cellfun(@(x)(getGroupIndex(x>=pTol)),IRL,'un',0);            
                        
            % loops through each frame determining the most likely object
            for iFrm = 1:nFrm
                if isempty(iGrp{iFrm})
                    % case is there was no group was detected for pTol
                    [~,imx] = max(IRL{iFrm}(:));
                    iGrp{iFrm} = imx;
                    
                elseif length(iGrp{iFrm}) == 1
                    % case is there is only one binary group
                    iGrp{iFrm} = iGrp{iFrm}{1};

                elseif length(iGrp{iFrm}) > 1
                    % case is there is more than one group detected
                    iGrpMx = cellfun(@(x)(x(...
                                argMax(IRL{iFrm}(x)))),iGrp{iFrm});                

                    % determines the median value from each binary group
                    IRLmx = zeros(length(iGrpMx),1);
                    for i = 1:length(iGrpMx)
                        BGrpMx = bwmorph(setGroup(iGrpMx(i),sz),'dilate');
                        IRLmx(i) = nanmedian(IRL{iFrm}(BGrpMx));
                    end                

                    % determines the group with the highest residual
                    iGrp{iFrm} = iGrp{iFrm}{argMax(IRLmx)};
                end

                % calculates the positions
                [yP,xP] = ind2sub(sz,iGrp{iFrm});
                fPos{iFrm} = [nanmean(xP),nanmean(yP)];
            end
                    
        end        
    end
end