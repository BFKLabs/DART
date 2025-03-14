classdef Track < matlab.mixin.SetGet
    
    % class properties
    properties
        
        % the tracking class objects
        fObj    

        % main objects
        mObj
        iData
        iMov       
        hProg
        hGUI
        hFig 
        wStr

        % initialised class fields
        dX = 5;        
        wOfs = 0;            
        wOfsL = 0;
        nFrmR = 10;
        calcOK = true;
        isBatch = false; 
        isCalib = false;
        stopUpdate = false;
        ivPhRej = 5;
        ivPhFeas = [1,2,4];
        fStepMax = 10;
        nFrmMax = 100000;
        
        % boolean flags and other count variables
        is2D
        isDD
        isBGCalc 
        isManual    
        isMulti
        nApp
        nTube
        nPhase  
        nFly
        
    end
    
    % class methods
    methods
        
        % class constructor
        function obj = Track(iData,isMulti)
            
            % major field initialisation 
            obj.iData = iData;   
            obj.isMulti = isMulti;
            
            % retrieves the video object handle
            obj.mObj = get(findall(0,'tag','figFlyTrack'),'mObj');
            
        end       
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %       
        
        % --- resets the minor progress bar fields
        function resetProgBarFields(obj,i0)
            
            % resets the other progressbar fields
            for j = i0:(length(obj.wStr)-obj.wOfs1)
                obj.hProg.Update(j+obj.wOfs1,obj.wStr{j+obj.wOfs1},0);
            end                       
            
        end           
        
        % --- reads the images for the frame indices given in iFrm
        function [Img,iFrm] = getImageStack(obj,iFrm,varargin)
            
            % initialisations
            nFrm = length(iFrm);                        
            
            % determines if the slow frame methods is to be used
            if obj.isBGCalc
                useSlow = true;
            else
                useSlow = (obj.iData.nFrm < obj.nFrmMax) && ...
                    ((mean(diff(iFrm)) > obj.fStepMax) || (nFrm == 1));
            end
            
            % retrieves the image stack
            if useSlow
                % if only one frame is being read, or the step size is
                % large, then read the frames using the slower method
                Img = arrayfun(@(x)(obj.slowImageRead...
                    (x,iFrm(x),nFrm,nargin<3)),1:nFrm,'un',0);
                
            else
                % otherwise, read the image using the faster methods
                Img = obj.fastImageRead(iFrm,nargin<3);                
            end
            
            % determines which frames are feasible (only if required)
            if nargout == 2
                isOK = ~cellfun(@(x)(all(isnan(x(:)))),Img);
                for i = find(~isOK(:)')
                    % calculates the frame increment
                    diFrm = 1 - 2*(i>1);
                    
                    % keep looping until the new frame is feasible
                    while 1
                        % retrieves the new image
                        iFrm(i) = iFrm(i) + diFrm;
                        Img{i} = ...
                            obj.slowImageRead(i,iFrm(i),nFrm,nargin<3);
                        
                        % if the image is feasible, then exit the loop
                        if ~all(isnan(Img{i}(:)))
                            break
                        end
                    end
                end
            end
                              
            % if requested, return the first cell array element
            if nargin >= 3; Img = Img{1}; end
            
        end   
        
        % --- retrieves the new image using the slower read method
        function Img = slowImageRead(obj,iFrm,iFrmG,nFrm,updateProg)
            
            % sets the progress bar update flag
            if ~exist('updateProg','var'); updateProg = true; end
            
            % updates the progressbar
            if updateProg
                pW = obj.calcProgMult();                                
                wStrP = sprintf(['Sub-Image Stack Reading ',...
                                '(Frame %i of %i)'],iFrm,nFrm);
                obj.UpdatePB([3,2],wStrP,pW*iFrm/nFrm);
            end
                        
            % retrieves the images for all frames in the array, iFrm
            while true
                try
                    Img = double(getDispImage(obj.iData,obj.iMov,iFrmG,0));
                    break
                catch
                    iFrmG = iFrmG - 1;
                end
            end
            
        end
        
        % --- retrieves the new image using the faster read method
        function Img = fastImageRead(obj,iFrm,updateProg)
            
            % memory allocation
            indF = 1;            
            nFrm = length(iFrm);
            Img = cell(nFrm,1);    
            sRate = obj.iMov.sRate;
            
            % calculates the total 
%             iFrmT = sRate*(iFrm-1) + (obj.iData.Frm0*sRate);
            iFrmT = sRate*(iFrm-1) + obj.iData.Frm0;
            
            % resets the video object current time (if not matching)
            t0 = iFrmT(1)/obj.mObj.FrameRate;
            if obj.mObj.CurrentTime ~= t0
                obj.mObj.CurrentTime = t0;
            end            
            
            % reads all the frames from the image stack
            for iFrmR = iFrmT(1):iFrmT(end)
                try
                    if iFrmR/obj.mObj.FrameRate == obj.mObj.CurrentTime
                        Inw = readFrame(obj.mObj,'native');
                    else
                        Inw = read(obj.mObj,iFrmR);
                    end                        
                        
                catch ME
                    if strcmp(ME.identifier,'MATLAB:audiovideo:VideoReader:EndOfFile')
                        % if end of file, then reshape arrays and exit
                        Img = Img(1:(indF-1));
                        obj.iData.nFrm = iFrm(indF-1);
                        return
                    end
                end                
                
                % determines if the next frame is to be stored
                if iFrmR == iFrmT(indF)
                    % if so, store the new frame
                    Inw = double(rgb2gray(Inw));
                    Img{indF} = getRotatedImage(obj.iMov,Inw);
               
                    % updates the progressbar
                    if updateProg
                        pW = obj.calcProgMult();
                        wStrP = sprintf(['Sub-Image Stack Reading ',...
                                        '(Frame %i of %i)'],indF,nFrm);
                        obj.UpdatePB([3,2],wStrP,pW*indF/nFrm);
                    end
                    
                    % increments the frame counter
                    indF = indF + 1;                    
                end
            end
                        
        end
        
        % --- initialises the class fields
        function initClassFields(obj)
        
            % initialisations              
            obj.calcOK = true;
            obj.nPhase = length(obj.iMov.vPhase);
            obj.nApp = length(obj.iMov.iR);
            obj.nTube = getSRCountVec(obj.iMov);
            obj.nPhase = length(obj.iMov.vPhase);            
            
            % determines the algorithm type (direct detect or BG subtract)
            obj.isDD = isDirectDetect(obj.iMov);
            obj.is2D = is2DCheck(obj.iMov);
        
        end
        
        % --- determines which phases are feasible (from feasInd)
        function okPh = getFeasPhase(obj,indF)

            if ~exist('indF','var'); indF = obj.ivPhFeas; end
            okPh = arrayfun(@(x)(any(indF==x)),obj.iMov.vPhase);

        end
        
        % --- case is updating the progressbar
        function isCancel = UpdatePB(obj,iType,wStrU,pNum,pDen)
            
            % initialisations
            
            
            % sets the default input arguments
            if ~exist('pDen','var'); pDen = 1; end
            
            if isa(obj.hProg,'BlobCNNProgBar')
                % if updates are stopped, then exit
                if obj.stopUpdate
                    isCancel = false; 
                    return
                end
                
%                 % sets the selection type
%                 if length(iType) == 1
%                     iTypeS = -1;
%                 else
%                     iTypeS = iType(2);
%                 end
                
                % case is the cnn tracking progressbar
                switch iType(2)
                    case 1
                        % case is initial frame stack read
                        obj.hProg.updateTrainPhase(1,1);
                        
                    case 2
                        % case is image stack reading
                        isCancel = obj.hProg.Update(2,1,pNum);
                        
                    case 3
                        % case is moving object detection
                        isCancel = obj.hProg.Update(2,2,0.5*(1+pNum));
                        
                    case 4 
                        % case is the post-training calculations
                        pMlt = 1/2;
                        wStrL = 'Final Background Estimate Calculations';
                        isCancel = obj.hProg.Update(6,pMlt*pNum,pDen,wStrL);
                        
                    case 5
                        % case is the quality metrics
                        wPr = (pDen + pNum)/2;
                        wStrL = 'Quality Metric Calculations';                        
                        isCancel = obj.hProg.Update(6,wPr,pDen,wStrL);
                       
                    case 6
                        % case is initial tracking completion
                        isCancel = obj.hProg.Update(6);
                        
                    otherwise
                        % case is the other update types
                        isCancel = false;
                end
                
            else
                % case is the normal progressbar object
                iLvlP = iType(1) + obj.wOfsL;
                isCancel = obj.hProg.Update(iLvlP,wStrU,pNum/pDen);                
            end
            
        end

        % --- calculates the progressbar multiplier
        function pW = calcProgMult(obj)
            
            pW = 0.5*(1+(obj.isMulti && obj.isBGCalc));
            
        end
            
    end
    
    % class static methods
    methods (Static)
    
        % --- retrieves a particular field from the tracking solution
        function Y = getTrackFieldValues(Yf,iApp,iTube)
            
            % retrieves the solution values for the tube region
            Y = cell2mat(cellfun(@(x)(x(iTube,:)),Yf(iApp,:)','un',0));
            
        end
        
        % --- checks the time array to fill any NaN entries
        function T = checkTimeStampArray(T)

            % determines if there are any missing time-stamps
            ii = find(T == 0);
            if isempty(ii); return; end

            % fill in the missing time stamp frames
            dT = median(diff(T),'omitnan');
            for i = 1:length(ii)
                if ii(i) > 1
                    % case is 
                    T(ii(i)) = T(ii(i)-1) + dT;
                else
                    T(ii(i)) = T(ii(i)+1) - dT;
                end
            end     
            
        end              
            
    end
        
end
