classdef OrientationCalc < handle
    
    % class properties
    properties
        
        % main objects 
        I
        iMov
        fPos
        iApp
        
        % calculated fields 
        Phi
        axR
        NszB
        
        % other fields
        N
        fok
        szL
        del        
        nImg
        nTube
        fPosL
        
        % parameters
        pZ = 150;
        hZ = 2;
        
    end
   
    % class methods
    methods 
        
        % --- class constructor
        function obj = OrientationCalc(iMov,I,fPos,iApp)
            
            % sets the input arguments
            obj.I = I;
            obj.iMov = iMov;
            obj.fPos = fPos;
            obj.iApp = iApp;                
            
            % initialises the object fields
            obj.initObjectFields();
            
            % calculates the orientation angles for each sub-region
            for iImg = 1:obj.nImg
                obj.calcOrientationAngles(iImg);
            end
            
        end       
        
        % --- calculates the fly orientation angles from their local images
        function calcOrientationAngles(obj,iImg)            

            % sets the positional values
            fPosT = num2cell(roundP(obj.fPos{iImg}),2);
                
            % sets the local images surrounding the position vectors
            IL = cellfun(@(x,y)...
                      (obj.getLocalImage(x,y)),obj.I{iImg},fPosT,'un',0);

            % calculates the local image orientation angles
            phiD = cell2mat(cellfun(@(x)...
                      (obj.calcLocalImageAngle(x)),IL(obj.fok),'un',0));
            [Phi0,axR0,Nsz0] = deal(phiD(:,1)*(180/pi),phiD(:,2),phiD(:,3));

            % determines if any NaN-values are in the angle calculations
            ii = isnan(Phi0);
            if any(ii)
                % if so then fill in the NaN-gaps
                if ~all(ii)
                    % determines the non-NaN values in the group
                    isOk = find(~ii);

                    % loops through each of the groups removing the NaNs
                    iGrp = getGroupIndex(ii);
                    for i = 1:length(iGrp)
                        if iGrp{i}(1) == 1
                            % case is group contains NaN value at start
                            Phi0(iGrp{i}) = repmat(Phi0...
                                    (iGrp{i}(end)+1),length(iGrp{i}),1);
                            axR0(iGrp{i}) = repmat(axR0...
                                    (iGrp{i}(end)+1),length(iGrp{i}),1);                                
                        
                        elseif iGrp{i}(end) == size(Phi0,1)
                            % case is group contains NaN value at ends 
                            Phi0(iGrp{i}) = repmat(Phi0...
                                    (iGrp{i}(1)-1),length(iGrp{i}),1);
                            axR0(iGrp{i}) = repmat(axR0...
                                    (iGrp{i}(1)-1),length(iGrp{i}),1);                        
                                
                        else
                            % case is NaN values are surrounded by non-NaNs
                            Phi0(iGrp{i}) = ...
                                    interp1(isOk,Phi0(isOk),iGrp{i});
                            axR0(iGrp{i}) = ...
                                    interp1(isOk,Phi0(isOk),iGrp{i});                                
                        end
                    end
                end                
            end
            
            % sets orientation angles/axis 
            obj.Phi(obj.fok,iImg) = Phi0;
            obj.axR(obj.fok,iImg) = axR0;
            obj.NszB(obj.fok,iImg) = Nsz0;
            
        end
        
        % --- calculates the local image orientation angle
        function phi = calcLocalImageAngle(obj,IL)

            % sets the x/y meshgrid values  
            sz = size(IL);
            nPts = 2*ceil(obj.N);
            dsz = (1+floor(sz/2));
            [xx,yy] = meshgrid((1:sz(2))-dsz(2),(1:sz(1))-dsz(1));

            % determines the most likely points from the image
            BPos = IL > 0;
            iMx = detTopNPoints(IL(:),nPts,0,1);
            B0 = setGroup(iMx,sz) & BPos;
            
            % thresholds the sub-image and determines the overlapping
            [~,Bnw] = detGroupOverlap(B0,obj.fPosL);
            if ~any(Bnw(:))
                % if there is no overlapping group, then determine the 
                % groups from the initial binary image
                iGrp = getGroupIndex(B0);
                if length(iGrp) > 1
                    % if there is more than one group, then determine the 
                    % group that is closest to the centre of the sub-image
                    DB0 = bwdist(setGroup(obj.fPosL,sz));
                    IGrpUQ = normImg(cellfun(@(x)...
                        (prctile(IL(x),75)),iGrp),1);
                    DGrp = cellfun(@(x)...
                        (min(DB0(x))),iGrp)/obj.iMov.szObj(1);                    
                    imx = argMax(IGrpUQ./DGrp);
                    iGrp = iGrp(imx);
                end
                
            else
                % otherwise, fill any gaps within the image and continue
                iGrp = getGroupIndex(bwfill(Bnw,'holes'));
            end

            % determines if there are a feasible number of points
            if length(iGrp{1}) > 1
                % rescales the image
                ILmn = min(IL(iGrp{1}),[],'omitnan');
                ILmx = max(IL(iGrp{1}),[],'omitnan');
                ILZ = obj.pZ*((IL - ILmn)/(ILmx - ILmn)).^obj.hZ;                

                % sets up and calculate the PCA 
                z = cell2mat(arrayfun(@(x)(repmat([xx(x),yy(x)],...
                    max(1,floor(ILZ(x))),1)),iGrp{1},'un',0)); 
                [coef,~,eVal] = pca(z); 
            else
                % if there are insufficient points, then return NaN values
                eVal = [];
            end

            % determines if the pca calculations returned feasible values
            if (length(eVal) < 2)
                % calculation was not feasible, so return a NaN array
                phi = NaN(1,3);
                
            else
                % calculates the final orientation angle. align the 
                % orientation angle with the direction of the pixel 
                % weighted COM to the binary COM
                pF = mod(atan2(coef(2,1),coef(1,1))+pi/2,pi)-pi/2;
                BF = setGroup(size(obj.szL),iGrp{1});

                % sets the orientation angle and aspect ratio    
                phi = [pF,eVal(1)/eVal(2),sum(BF(:))];
            end

        end

        % --- retrieves the local image around the coordinate, fPos from I
        function IL = getLocalImage(obj,I,fPos)
            
            % memory allocation            
            IL = zeros(obj.szL*[1,1]);
            if any(isnan(fPos)); return; end
            
            % sets the row/column indices
            delF = round(1.5*obj.del);
            iR = (fPos(2)-delF):(fPos(2)+delF);
            iC = (fPos(1)-delF):(fPos(1)+delF);
            
            % determines the feasible row/column indices
            ii = (iR >= 1) & (iR <= size(I,1));
            jj = (iC >= 1) & (iC <= size(I,2));
            
            % sets the sub-image
            IL(ii,jj) = I(iR(ii),iC(jj));            
            
        end        
        
        % --- initialises the object fields
        function initObjectFields(obj)
            
            % array dimensioning
            obj.nImg = length(obj.fPos);
            obj.nTube = size(obj.fPos{1},1);   
            obj.fok = obj.iMov.flyok(1:obj.nTube,obj.iApp);
            
            % memory allocation
            obj.Phi = NaN(obj.nTube,obj.nImg);
            obj.axR = NaN(obj.nTube,obj.nImg);
            obj.NszB = NaN(obj.nTube,obj.nImg);
            
            % other initialisations
            obj.del = floor(max(obj.iMov.szObj));
            obj.szL = 2*obj.del+1;
            obj.N = 0.75*prod(obj.iMov.szObj);
            obj.fPosL = (obj.del+1)*[1,1];
            
        end
    end
end