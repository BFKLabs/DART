% ---
function ImgEq = setRegionalEqualisedImage(iMov,Img,Bw,pos0)

del = 10;

% sets the default input arguments
if nargin < 4; pos0 = [0 0]; end

% initialisations
[is2D,sz] = deal(is2DCheck(iMov),size(Img));
ImgEq = NaN(sz);

%
if is2D
    % case is 2D setup
    
    % sets the number of fly count for each group
    nFly = getFlyCount(iMov);
    
    %
    for i = 1:length(iMov.iR)
        % sets the row/column indices
        [iR,iC] = deal(iMov.iR{i}-pos0(2),iMov.iC{i}-pos0(1));
        iRL = max(1,iR(1)):min(sz(1),iR(end));
        iCL = max(1,iC(1)):min(sz(2),iC(end));
        
        %
        for j = 1:nFly(i)
            %
            [iRLT,iCLT] = deal(iRL(iMov.iRT{i}{j}),iCL(iMov.iCT{i}));
            iRLT = max(1,iRLT(1)-del):min(sz(1),iRLT(end)+del);
            iCLT = max(1,iCLT(1)-del):min(sz(2),iCLT(end)+del);
            
            % sets the location acceptance mask/local image arrays
            [BwL,ImgL] = deal(Bw(iRLT,iCLT),Img(iRLT,iCLT));
            ImgL(~BwL) = NaN;

            %
            ImgLeq = ImgL;
            D = bwdist(bwmorph(BwL,'thin',inf));
            
            %
            Dw = 0;
            while 1
                %
                indNw = (D<=(Dw+1)) & (D>Dw);
                
                %
                if all(isnan(ImgLeq(indNw(:))))
                    break
                else
                    ImgLeq(indNw) = ImgLeq(indNw) - nanmedian(ImgLeq(indNw)); 
                    Dw = Dw + 1;
                end
            end
            
            
            %
            ImgEq(iRLT,iCLT) = setEqualisedImage(ImgLeq,1);
        end
    end
    
else
    % case is 1D setup

    %
    for i = 1:length(iMov.iR)
        % sets the row/column indices
        [iR,iC] = deal(iMov.iR{i}-pos0(2),iMov.iC{i}-pos0(1));
        iRL = max(1,iR(1)-del):min(sz(1),iR(end)+del);
        iCL = max(1,iC(1)-del):min(sz(2),iC(end)+del);
        
        %
        [ImgL,BwL] = deal(Img(iRL,iCL),Bw(iRL,iCL));
        ImgL(~BwL) = NaN;
        
        %
        ImgEq(iRL,iCL) = setEqualisedImage(ImgL,1);
    end    
end

%
ImgMd = nanmedian(ImgEq(Bw));
ImgEq(~Bw) = ImgMd;
ImgEq(isnan(ImgEq)) = ImgMd;