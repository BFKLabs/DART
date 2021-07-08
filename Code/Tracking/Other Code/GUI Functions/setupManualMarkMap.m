function [Imap,pMn] = setupManualMarkMap(obj)

% % sets the image size (based on whether the image is being rotated or not)
% if obj.iMov.useRot && ((obj.iMov.rotPhi) > 45)
%     % case is the image is being rotated
%     sz = flip(obj.iData.sz);
% else
%     % case is the image is not being rotated
%     sz = obj.iData.sz;
% end

% memory allocation
zTol = 0.5;
dTol = 10;
pMn = cell(max(obj.nTube),obj.nApp);
hG = fspecial('gaussian',5,2);

% retrieves the image from the main gui
hImg = findobj(obj.hGUI.imgAxes,'Type','image');
I = imfilter(double(get(hImg,'CData')),hG);

% other memory allocations
sz = size(I);
[Bw,Imap] = deal(false(sz),zeros(sz));

% sets up the full image binary mask
for i = 1:obj.nApp
    szR = [length(obj.iMov.iR{i}),length(obj.iMov.iC{i})];
    BwNw = getExclusionBin(obj.iMov,szR,i);
    Bw(obj.iMov.iR{i},obj.iMov.iC{i}) = BwNw;
end

% retrieves the indices
iMx = find(Bw.*imregionalmin(I));
[yMx,xMx] = ind2sub(sz,iMx);

%
for i = 1:obj.nApp
    % sets the column indices for the region
    iC = obj.iMov.iC{i};
    for j = 1:obj.nTube(i)
        % sets the row indices of the sub-region
        iR = obj.iMov.iR{i}(obj.iMov.iRT{i}{j});  
        pOfs = [iC(1),iR(1)]-1;
        
        % determines all the minima within the sub-region
        IL = I(iR,iC);
        isIn = find((yMx >= iR(1)) & (yMx <= iR(end)) & ...
                    (xMx >= iC(1)) & (xMx <= iC(end)));
        
        % removes any low-grade minima from the selection group
        szL = size(IL);
        iMxL = sub2ind(szL,yMx(isIn)-pOfs(2),xMx(isIn)-pOfs(1));
        ZL = (IL-mean(IL(:)))/std(IL(:));
        isIn = isIn(ZL(iMxL)/min(ZL(iMxL)) > zTol);
        
        % creates the sub-region map from the remaining points
        pMn{j,i} = [xMx(isIn),yMx(isIn)];
        Imap(iR,iC) = setSubRegionMap(pMn{j,i},pOfs,szL,dTol);
    end
end

% --- creates the sub-region map for all points within a sub-region
function ImapL = setSubRegionMap(pMn,pOfs,szL,dTol)

% memory allocation
D = zeros([szL,size(pMn,1)]);

% sets up the distance map for each point
for i = 1:size(pMn,1)
    dP = roundP(pMn(i,:)-pOfs);
    Dnw = bwdist(setGroup(dP,szL));
    D(:,:,i) = Dnw;
end

% sets the final map values (remove any large distance points
[Dmin,ImapL] = nanmin(D,[],3);
ImapL(Dmin>dTol) = 0;
