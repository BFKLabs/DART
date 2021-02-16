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
        sz
        szL
        del        
        nImg
        nTube
        fPosL
    end
   
    % class methods
    methods 
        % class constructor
        function obj = OrientationCalc(iMov,I,fPos,iApp)
            
            % sets the input arguments
            obj.I = I;
            obj.iMov = iMov;
            obj.fPos = fPos;
            obj.iApp = iApp;
            
            % memory allocation and other initialisations
            obj.sz = size(I{1}{1});
            
            % initialises the object fields
            obj.initObjectFields();
            
            % calculates the orientation angles for each sub-region
            for iTube = 1:obj.nTube
                if obj.iMov.flyok(iTube,obj.iApp)
                    obj.calcOrientationAngles(iTube);
                end
            end
            
        end       
        
        % --- calculates the fly orientation angles from their binary images
        function calcOrientationAngles(obj,iTube)            

            % sets the positional values
            fPosT = num2cell(roundP(cell2mat(obj.fPos{iTube}(:))),2);
                
            % sets the local images surrounding the position vectors
            IL = cellfun(@(x,y)...
                      (obj.getLocalImage(x,y)),obj.I{iTube}',fPosT,'un',0);

            % calculates the local image orientation angles
            phiD = cell2mat(cellfun(@(x)...
                      (obj.calcLocalImageAngle(x)),IL,'un',0));
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
            obj.Phi(iTube,:) = Phi0;
            obj.axR(iTube,:) = axR0;
            obj.NszB(iTube,:) = Nsz0;
            
        end
        
        % --- calculates the local image orientation angle
        function phi = calcLocalImageAngle(obj,IL)

            % sets the x/y meshgrid values                 
            [xx,yy] = meshgrid(1:obj.szL);

            % determines the most likely points from the image
            B0 = (IL > nanmedian(IL(:))) & (IL ~= 0);
            if sum(B0(:)) < obj.N/2
                % if the thresholded image is too small, then 
                % rethreshold with so that the binary has a decent size
                B0 = setGroup(detTopNPoints(IL(:),obj.N,0,0),obj.szL) & ...
                             (IL ~= 0);
            end

            % thresholds the sub-image and determines the overlapping
            [~,Bnw] = detGroupOverlap(B0,obj.fPosL);
            if ~any(Bnw(:))
                % if there is no overlapping group, then determine the groups from the
                % initial binary image
                [iGrp,pCent] = getGroupIndex(B0,'Centroid');
                if length(iGrp) > 1
                    % if there is more than one group, then determine the group that is
                    % closest to the centre of the sub-image
                    [~,imn] = min(sqrt(sum((pCent - ...
                                repmat(obj.fPosL,size(pCent,1),1)).^2,2)));
                    iGrp = iGrp(imn);
                end
                
            else
                % otherwise, fill any gaps within the image and continue
                iGrp = getGroupIndex(bwfill(Bnw,'holes'));
            end

            % ensures there are no non-zero values in the pca array setup
            ILmn = min(IL(iGrp{1}));
            if (ILmn < 1); IL = IL + (1 - ILmn); end

            % sets up and calculate the PCA 
            BB = num2cell(iGrp{1});
            z = cell2mat(cellfun(@(x)(repmat([xx(x),yy(x)],...
                                            ceil(IL(x)),1)),BB,'un',0)); 
            [coef,~,eVal] = pca(z); 

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
            
            % sets the row/column indices
            iR = (fPos(2)-obj.del):(fPos(2)+obj.del);
            iC = (fPos(1)-obj.del):(fPos(1)+obj.del);
            
            % determines the feasible row/column indices
            ii = (iR >= 1) & (iR <= obj.sz(1));
            jj = (iC >= 1) & (iC <= obj.sz(2));
            
            % sets the sub-image
            IL(ii,jj) = I(iR(ii),iC(jj));            
            
        end        
        
        % --- initialises the object fields
        function initObjectFields(obj)
            
            % array dimensioning
            obj.nImg = length(obj.I{1});
            obj.nTube = length(obj.fPos);            
            
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