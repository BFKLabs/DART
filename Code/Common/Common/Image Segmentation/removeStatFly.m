% --- removes the static fly locations
function ILnw = removeStatFly(IL,fxP,xcP)

% array indexing
[sz,dX] = deal(size(IL),floor(size(xcP.ITx)/2));
[pTol,fxP] = deal(1e-2,roundP(fxP));
[BBxT,BByT] = deal(true(sz));

% calculates the x-gradient of the image
[Gx,Gy] = imgradientxy(IL,'IntermediateDifference');

% sets the row/column indices of the template image
[iR,iC] = deal((fxP(2)-dX):(fxP(2)+dX),(fxP(1)-dX):(fxP(1)+dX));
[ii,jj] = deal((iR>=1)&(iR<=sz(1)),(iC>=1)&(iC<=sz(2)));

% sets the new binary images
[BBx,BBy] = deal(abs(xcP.ITx(ii,jj))>pTol,abs(xcP.ITy(ii,jj))>pTol);
[GxB,GyB] = deal(Gx(iR(ii),iC(jj)),Gy(iR(ii),iC(jj)));
[Nx,Ny] = deal(sum(BBx(:)),sum(BBy(:)));

% determines the 
GxB(BBx) = roundP(normrnd(0,std(Gx(~BBx)/2),[Nx,1]));
GyB(BBy) = roundP(normrnd(0,std(Gy(~BBy)/2),[Ny,1]));
[Gx(iR(ii),iC(jj)),Gy(iR(ii),iC(jj))] = deal(GxB,GyB);
[BBxT(iR(ii),iC(jj)),BByT(iR(ii),iC(jj))] = deal(~BBx,~BBy);

% calculates the reconstruction image
ILnw = 0.5*(reconstructImage(IL,Gx,BBxT,1)+reconstructImage(IL,Gy,BByT,2));

% --- reconstructs the missing region from the image gradient image
function IL = reconstructImage(IL,G,BB,dim)

% memory allocation
j = find(dim ~= (1:2));
[ii,ind] = deal(cell(1,2));

% determines the indices of the binary image
[ind{1},ind{2}] = ind2sub(size(IL),find(~BB));

% sets the row/column indices
[ii{dim},~,B] = unique(ind{dim});
ii{j} = cellfun(@(x)(ind{j}(B==x)),num2cell(1:length(ii{dim})),'un',0);

% reconstructs the missing parts of the image using the gradient
for i = 1:length(ii{dim})
    % determines the indices of the points to be added
    [indNw,mlt,k1] = deal(min(ii{j}{i}):max(ii{j}{i}),1,ii{dim}(i)); 
    if (indNw(1) == 1)
        [indNw,mlt] = deal(indNw(end:-1:1),-1); 
        if (indNw(1) == size(IL,j)); indNw = indNw(2:end); end
    end
    
    
    % reconstructs the new images   
    for k2 = indNw
        if (dim == 1)
            % reconstructs in the x-derivative
            IL(k1,k2) = IL(k1,k2-mlt) + mlt*G(k1,k2-mlt);
        else
            % reconstructs in the y-derivative
            IL(k2,k1) = IL(k2-mlt,k1) + mlt*G(k2-mlt,k1);
        end
    end            
end