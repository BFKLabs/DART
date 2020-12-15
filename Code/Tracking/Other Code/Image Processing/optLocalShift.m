% --- calculates the shifts local in the images in the image array, I
%     wrt the candidate frame, I0
function [Ishift,dXL,dYL] = optLocalShift(iMov,I,Iavg,iApp,varargin)

% global variables
global isDetecting is2D

% ensures the image array is a cell array
if (~iscell(I)); I = {I}; end

% initialisations and memory allocation
[nTubeR,isCG] = deal(getAppFlyCount(iMov,iApp),isColGroup(iMov));
[nTube,nFrm] = deal(1+(nTubeR-1)*is2D,length(I));
[dXL,dYL] = deal(zeros(nTube,nFrm));
[I0L,I1L] = deal(cell(1,nTube));
Ishift = cell(nFrm,nTubeR);

if (nargin == 5)    
    if (isCG)
        indRC = iMov.iCT{iApp};
    else
        indRC = iMov.iRT{iApp};
    end
else
    indRC = getDownSampledRowIndices(iMov,iApp);
end

% sets the row/column offsets
if (isempty(Iavg))
    Iavg = nanmean(cell2mat(reshape(I,[1 1 nFrm])),3);
end

% sets the first row images
for i = 1:nTube
    if (isCG)
        I0L{i} = Iavg(:,indRC{i});                     
    else
        I0L{i} = Iavg(indRC{i},:);                     
    end
end
        
% loops through each of the frames optimising the x/y local image shifts
for k = 1:nFrm
    if (is2D)    
        % case is a 2D experiment analysis
        for j = 1:nTube
            % resets the optimisation flag
            if (k == 1); optShift = true; end                  
            
            % sets the local the local image of the current frame      
            if (isCG)
                I1L{j} = I{k}(:,indRC{j});
            else
                I1L{j} = I{k}(indRC{j},:);
            end

            % optimises the shift in the image (if required) and is either
            % detecting background (not detecting), or is detecting and the
            % sub-region has not been rejected
            if ((optShift) && ((~isDetecting) || (isDetecting && iMov.flyok(j,iApp))))
                [dZ,Ishift{k,j}] = calcOptOffset(I0L{j},I1L{j});    
                if ((j == 1) && (k == 1) && (all(abs(dZ) < 0.01)))
                    % if there was no discernable shift, then flag that the
                    % other frames probably don't need optimisation
                    optShift = false;
                else
                    % sets the x/y shift values (if required)
                    [dXL(j,k),dYL(j,k)] = deal(dZ(1),dZ(2));
                end                
            else
                % no optimisation required, so set local image
                Ishift{k,j} = I1L{j};
            end            
        end
    else
        % resets the optimisation flag
        if (k == 1); optShift = true; end              
        
        % case is a 1D experiment analysis
        if ((optShift) && ((~isDetecting) || (isDetecting && iMov.ok(iApp))))
            [dZ,IshiftNw] = calcOptOffset(Iavg,I{k});                            
            if (any(abs(dZ) >= 0.01))               
                % sets the x/y shift values (if required)
                [dXL(k),dYL(k)] = deal(dZ(1),dZ(2));
            end                
        else
            % no optimisation required, so set local image
            IshiftNw = I{k};
        end           
        
        % sets the shifted images for each tube region
        for j = 1:nTubeR
            if (isCG)
                Ishift{k,j} = IshiftNw(:,indRC{j});
            else
                Ishift{k,j} = IshiftNw(indRC{j},:);
            end
        end
    end    
end

% --- calculates the optimal offset
function [dz,Ishift] = calcOptOffset(I0,I1)

% global variables
global opt is2D

% parameters
[dzTol,sz,delMx] = deal(0.01,size(I1),10);

% calculates the normalised 2D gradients for each image
if (is2D)
    [I0eq,I1eq] = deal(I0,I1);
else
    [I0eq,I1eq] = deal(setEqualisedImage(I0),setEqualisedImage(I1));
end

% sets the optimisation option struct
opt = optimset('display','none','tolX',dzTol);

% -------------------------------- %
% --- COARSE SHIFT OPTIMSATION --- %
% -------------------------------- %

%
[B0nan,B1nan] = deal(isnan(I0eq),isnan(I1eq));
if (any(B0nan(:))); I0eq(B0nan) = mean(I0eq(~B0nan(:))); end
if (any(B1nan(:))); I1eq(B1nan) = mean(I1eq(~B1nan(:))); end

%
if (is2D)
    %
    Imx = max(max(I1eq(:)),max(I0eq(:)));
    Imn = min(min(I1eq(:)),min(I0eq(:)));    
    [I1eqN,I0eqN] = deal((I1eq-Imn)/(Imx-Imn),(I0eq-Imn)/(Imx-Imn));
    
    a = stretchlim(uint8(255*I1eqN),[0.05,0.95]);
    I1eqA = imadjust(uint8(255*I1eqN),a,[]);
    
    I0eqA = imadjust(uint8(255*I0eqN),a,[]);
    if (range(I0eqA(:)) == 0); I0eqA = I0eqN; end    
else
    [I0eqA,I1eqA] = deal(I0eq,I1eq);
end

% calculates the image cross-correlation
A = normxcorr2(double(I0eqA),double(I1eqA)); 

% sets the exclusion region
[iR,iC] = deal((sz(1)-delMx):(sz(1)+delMx),(sz(2)-delMx):(sz(2)+delMx));
B = false(size(A)); 
B(iR,iC) = true;

% calculates the optimal shift
[~,imx] = max(A(:).*B(:));  
[ymx,xmx] = ind2sub(size(A),imx); 

% calculates the coarse shift
dz = [(xmx-sz(2)),(ymx-sz(1))];

% ------------------------------ %
% --- FINE SHIFT OPTIMSATION --- %
% ------------------------------ %

% shifts the image by the initial amount
Ibest = getShiftedImage(I1,dz(1),dz(2)); 

% runs the optimisation function        
dzF = fminsearch(@optFunc,[0 0],opt,I0,Ibest);
if (~is2D); dzF(1) = 0; end

% calculates the offset
if (abs(dzF) > dzTol)
    dz = dz + dzF;
end

if (nargout == 2)
    % sets the shifted image
    Ishift = getShiftedImage(I1,dz(1),dz(2)); 

    % removes any NaN values (if there any)
    BBnan = isnan(Ishift);
    if (any(BBnan(:)))
        % sets the NaN areas to the mean image value
        Ishift(BBnan) = mean(Ishift(~BBnan(:)));
        
        % performs an opening operation
        A = imopen(Ishift,ones(5));
        Ishift(BBnan) = A(BBnan);
    end
end

% --- 
function F = optFunc(z,I0,I1)

% global variables
global is2D

% no shift in x-direction is 1D analysis
if (~is2D); z(1) = 0; end

% calculates the shifted image and calculates the mean shift
IX = conv2(I1,[z(2); 1-z(2)]*[z(1), 1-z(1)],'same');
F = nanmean(abs(I0(:)-IX(:)));
