% --- retrieves the signal data from each of the cell regions
function [sigD,ok] = getCellSignalData(iData,iParaG,segD,iLvl,h,isBatch)

% sets the default input arguments
hasWait = (nargin >= 5);
if (nargin < 6); isBatch = false; end

% sets the smoothing window half-span (if smoothing)
if (iParaG.useSm)
    % smoothing is being used
    nWid = iParaG.nWid;    
else
    % smoothing is not being used
    nWid = 0;
end

% parameters
[nFrm,nGrp,iData.fType] = deal(iData.nFrm,length(segD.Pc),'Dir');
[nAvg,kk,ok] = deal(2*nWid+1,(1+nWid):(nFrm-nWid),true);

% initialisations and memory allocation
[pGrp,iGrp] = deal(cell(nFrm,nGrp),segD.iGrp');
[R2mn,Ysig,muFrm] = deal(zeros(1,nGrp),NaN(nFrm,nGrp),zeros(nFrm,1));

% sets up the waitbar figure arrays
if (hasWait)
    wOfs = 2*isBatch;
    [iW,isW] = setupWaitbarArrays(nFrm);
end

% reads the data for each frame/cell region 
for iFrm = 1:nFrm
    % determines if the waitbar figure needs to be updated    
    if (hasWait)
        iFound = find(iFrm >= iW,1,'last');
        if (~isW(iFound))
            % updates the index array
            isW(iFound) = true;

            % updates the waitbar figure
            if (updateWaitbarPara('Reading Image Frames',0.8*iFrm/nFrm,h,wOfs))
                [sigD,ok] = deal([],false);
                return
            end
        end
    end
        
    % retrieves the current image
    ImgNw = double(getDispImage(iData,[],iFrm,iLvl,true));        

    % sets the pixels for each of the cell regions
    muFrm(iFrm) = mean(ImgNw(:));
    pGrp(iFrm,:) = cellfun(@(x)(ImgNw(x)'),iGrp,'UniformOutput',0);            
end

% combines the cell arrays into numerical arrays (for each cell group)
pGrp = cellfun(@(x)(cell2mat(x)),num2cell(pGrp,1),'UniformOutput',0);

% -------------------------------- %
% --- CELL SIGNAL CALCULATIONS --- %
% -------------------------------- %

% memory allocation and parameters
[Ixc,hF] = deal(zeros(size(ImgNw)),fspecial('disk',2));

% waitbar figure parameters 
if (hasWait); [iW,isW] = setupWaitbarArrays(nGrp); end

% calculates the mean mutual information and smoothed signal for each cell
for i = 1:nGrp
    % determines if the waitbar figure needs to be updated   
    if (hasWait)
        iFound = find(i >= iW,1,'last');
        if (~isW(iFound))
            % updates the index array
            isW(iFound) = true;

            % updates the waitbar figure
            pWnw = 0.8+(0.2*i/length(iW));
            if (updateWaitbarPara('Setting Final Cell Signals',pWnw,h,wOfs))
                [sigD,ok] = deal([],false);
                return
            end
        end    
    end
    
    % retrieves the neighbouring indices
    indN = getNeighbourIndices(iGrp{i},[],size(ImgNw));
    R2 = calcPixelXCorr(indN,pGrp{i});
    
    % sets the cross-correlation image
    Ixc(iGrp{i}) = max(R2,[],1);
        
    % sets the pixels into a numerical array and temporally smooths them    
    if (nAvg > 1)
        % smoothing is being used
        A = num2cell(pGrp{i},1);
        Asm = cell2mat(cellfun(@(x)(smooth(x,nAvg)),A,'UniformOutput',0));    
    else
        % smoothing is not being used
        Asm = pGrp{i};    
    end
        
    % calculates the mean mutual information and normalised signal
    [R2mn(i),Ysig(kk,i)] = deal(mean(max(R2,[],1)),mean(Asm(kk,:),2));
end

% sets the final data into the data struct
sigD = struct('pGrp',[],'Ysig',[],'muFrm',[],'R2mn',[],'Ixc',[],'IxcF',[]);
[sigD.pGrp,sigD.Ysig,sigD.muFrm] = deal(pGrp,Ysig,muFrm);
[sigD.R2mn,sigD.Ixc,sigD.Ixcf] = deal(R2mn,Ixc,imfilter(Ixc,hF));