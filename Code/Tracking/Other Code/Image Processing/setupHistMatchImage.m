function Inw = setupHistMatchImage(I,iMov,cFrm)

% region count
nApp = length(iMov.iR);

% sets up the histogram matched image stack
IL = arrayfun(@(x)(getRegionImgStack(iMov,I,cFrm,x,0)'),1:nApp,'un',0);
ILhm = cellfun(@(x,y)(calcHistMatchStack(x,y)),IL,iMov.IbgR,'un',0);

% sets the histogram matched region images
Inw = I;
for i = 1:nApp
    Inw(iMov.iR{i},iMov.iC{i}) = ILhm{i}{1};
end