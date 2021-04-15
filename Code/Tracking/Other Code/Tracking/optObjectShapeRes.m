function szObj = optObjectShapeRes(iMov,Img,fPos,sFlag)

% parameters
dimgSz = 5;
pTol0 = 0.01;
pEdgeTol = 0.05;
imgSz = 5;

% 
pOpt0 = [];
[Img,fPos] = deal(cell2cell(Img(:)),cell2cell(fPos,0));

%
while 1
    % retrieves the sub-image stack
    Isub0 = getAllSubImages(iMov,Img,fPos,sFlag,imgSz);
    
    % optimises the 2D gaussian image from the mean image
    pLim = cellfun(@(I)(nanmin(I(:))),Isub0);
    [Iopt0,pOptNw] = opt2DGaussian(Isub0,pLim,pOpt0);
    IoptNw = (1-normImg(Iopt0)).*(Iopt0<0);

    % determines if the optimal binary intersects the edge
    BoptNw = bwmorph(IoptNw > pTol0,'majority');
    Bedge = bwmorph(true(size(BoptNw)),'remove');
    if mean(BoptNw(Bedge)) > pEdgeTol
        % if so, then increment the image size
        pOpt0 = pOptNw;
        imgSz = imgSz + dimgSz;
    else
        % otherwise, exit the loop
        break
    end                    
end

% calculates the bounding box size
[~,objBB] = getGroupIndex(BoptNw,'BoundingBox');
szObj = objBB([3,4]);

%
function Isub = getAllSubImages(iMov,Img,fPos,sFlag,imgSz)

%
[iT,iApp] = find(sFlag==1);
Isub = cell(length(iApp),1);

%
for i = 1:length(iApp)
    %
    iR = iMov.iR{iApp(i)};
    iC = iMov.iC{iApp(i)};
    iRT = iR(iMov.iRT{iApp(i)}{iT(i)});
    
    %
    Bw = getExclusionBin(iMov,[length(iRT),length(iC)],iApp(i),iT(i));
    ImgL = cellfun(@(x)(Bw.*x(iRT,iC)),Img,'un',0);
    
    %
    fPosNw = cellfun(@(x)(x(iT(i),:)),fPos(iApp(i),:)','un',0);
    Isub{i} = getSubImages(ImgL,cell2mat(fPosNw),imgSz);
end

% converts the cell of cells into a single cell array
Isub = cell2cell(Isub);

% --- retrieves the sub-regions surrounding the points, pMax
function Isub = getSubImages(I,pMax,dN)

% initialisations
[sz,nPts] = deal(size(I{1}),size(pMax,1));

% memory allocation
Isub = repmat({NaN(2*dN+1)},nPts,1);

% retrieves the valid sub-image pixels surrounding the max points
for k = 1:nPts
    % sets the row/column indices
    iC = pMax(k,1) + (-dN:dN);
    iR = pMax(k,2) + (-dN:dN);

    % determines which indices are valid
    i1 = (iR >= 1) & (iR <= sz(1));
    i2 = (iC >= 1) & (iC <= sz(2));

    % sets the valid points for the sub-image
    Isub{k}(i1,i2) = I{k}(iR(i1),iC(i2));    
end

%
Isub = cellfun(@(x)(medianShiftImg(x)),Isub,'un',0);