function [Imap,pMn] = setupManualMarkMap(obj)

% memory allocation
dTol = 10;
pMn = cell(max(obj.nTube),obj.nApp);
hG = fspecial('gaussian',5,2);

% retrieves the image from the main gui
hImg = findobj(obj.hGUI.imgAxes,'Type','image');
I = double(get(hImg,'CData'));

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
iMn = find(Bw.*imregionalmin(imfilter(I,hG)));
[yMx,xMx] = ind2sub(sz,iMn);

% sets up the full marker map
for i = find(obj.iMov.ok(:)')
    % sets the column indices for the region
    iC = obj.iMov.iC{i};
    for j = find(obj.iMov.flyok(:,i)')
        % sets the row indices of the sub-region
        iR = obj.iMov.iR{i}(obj.iMov.iRT{i}{j});  
        pOfs = [iC(1),iR(1)]-1;
        
        % determines all the minima within the sub-region
        isIn = find((yMx >= iR(1)) & (yMx <= iR(end)) & ...
                    (xMx >= iC(1)) & (xMx <= iC(end)));
        
        % removes the insignificant points
        ii = I(iMn(isIn))/max(I(iMn(isIn))) < 0.5;

        % creates the sub-region map from the remaining points
        szL = [length(iR),length(iC)];
        pMn{j,i} = [xMx(isIn(ii)),yMx(isIn(ii))];        
        Imap(iR,iC) = setSubRegionMap(pMn{j,i},pOfs,szL,dTol);
    end
end

% --- creates the sub-region map for all points within a sub-region
function ImapL = setSubRegionMap(pMn,pOfs,szL,dTol)

% memory allocation
ImapL = zeros(szL);
Dmin = dTol*ones([szL,2]);

% sets the 
DB = bwdist(setGroup((dTol+1)*[1,1],(2*dTol+1)*[1,1]));

% sets up the distance map for each point
for i = 1:size(pMn,1)
    % determines the valid row/column indices
    dP = roundP(pMn(i,:)-pOfs);
    iR = (dP(2)-dTol):(dP(2)+dTol);
    iC = (dP(1)-dTol):(dP(1)+dTol);
    [ii,jj] = deal((iR>0) & (iR<=szL(1)),(iC>0) & (iC<=szL(2)));

    % determines the closest overall points
    Dmin(iR(ii),iC(jj),2) = DB(ii,jj);
    [Dmin(iR(ii),iC(jj),1),iMnNw] = min(Dmin(iR(ii),iC(jj),:),[],3,'omitnan');

    % updates the sub-region map
    ImapL(iR(ii),iC(jj)) = i*(iMnNw == 2);
end
