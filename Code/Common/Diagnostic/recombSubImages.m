function I = recombSubImages(iMov,Isub)

%
[nFrm,nApp] = size(Isub);

% 
posG = iMov.posG;
[L,B,W,H] = deal(floor(posG(1)),floor(posG(2)),ceil(posG(3)),ceil(posG(4)));

% memory allocation
I = repmat({NaN([H,W])},nFrm,1);

% sets the sub-images into the overall arrays
for j = 1:nApp
    % sets the row/column indices
    [iR,iC] = deal(iMov.iR{j}-B,iMov.iC{j}-L);
    
    % sets the sub-images into the stack
    for i = 1:nFrm
        I{i}(iR,iC) = Isub{i,j};
    end
end

%
for i = 1:nFrm
    B = isnan(I{i});
    I{i}(B) = nanmean(I{i}(~B));
end