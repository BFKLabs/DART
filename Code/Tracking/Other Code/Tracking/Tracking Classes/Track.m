classdef Track < matlab.mixin.SetGet
    
    % class properties
    properties
        
        % the tracking class objects
        fObj    

        % main objects
        iData
        iMov       
        hProg
        hGUI
        hFig      

        % initialised class fields
        dX = 5;        
        wOfs = 0;            
        wOfsL = 0;
        nFrmR = 10;
        calcOK = true;
        isBatch = false; 
        isCalib = false;
        ivPhRej = 5;
        ivPhFeas = [1,2,4];

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
            
            % retrieves the image stack
            nFrm = length(iFrm);            
            Img = arrayfun(@(x)(obj.getNewImage...
                                    (x,iFrm(x),nFrm)),1:nFrm,'un',0);                             
            
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
                        Img{i} = obj.getNewImage(i,iFrm(i),nFrm);
                        
                        % if the image is feasible, then exit the loop
                        if ~all(isnan(Img{i}(:)))
                            break
                        end
                    end
                end
            end
                              
            % if requested, return the first cell array element
            if nargin == 3; Img = Img{1}; end
            
        end   
        
        % --- retrieves the new image
        function Img = getNewImage(obj,iFrm,iFrmG,nFrm)
            
            % updates the progressbar
            pW = 0.5*(1+(obj.isMulti && obj.isBGCalc));
            wStr = sprintf('Sub-Image Stack Reading (Frame %i of %i)',...
                           iFrm,nFrm);
            obj.hProg.Update(3+obj.wOfsL,wStr,pW*iFrm/nFrm);
                        
            % retrieves the images for all frames in the array, iFrm
            Img = double(getDispImage(obj.iData,obj.iMov,iFrmG,0));             
            
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
