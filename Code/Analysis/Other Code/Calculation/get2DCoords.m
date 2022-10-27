% --- scales the position values back to pixel values for a given apparatus
function [dPx,dPy,Rad,ind,dp0] = get2DCoords(snTot,iApp,iR)

% sets the solution file type
if ~isfield(snTot,'Type')
    Type = 0;
else
    Type = snTot.Type;
end

% field retrieval
if isempty(iApp)    
    [Px,Py,iMov,sFac,iApp] = deal(snTot.Px,snTot.Py,snTot.iMov,1,1);
else    
    [Px,Py,iMov] = deal(snTot.Px(iApp),snTot.Py(iApp),snTot.iMov);
    sFac = deal(snTot.sgP.sFac);
end

% memory allocation and parameters
if isempty(iMov.autoP); iMov.autoP = detMissingCircleCoord(iMov); end
[tSec,pR,dR,nSecMin,Rmin,nApp] = deal(360/20,0.95,5,5,2,length(iApp));
[dPx,dPy,Rad,dp0] = deal(cell(nApp,1));

% optimisation parameters
opt = optimset('display','none');

% sets the row offset
R = iMov.autoP.R;
Rmax = max(R(:) + dR);

% determines the non-rejected fly tubes
fok = cellfun(@(x,y)(~isnan(x(1,:)) & ~isnan(y(1,:))),Px,Py,'un',0);

% converts the position values back to pixel values
if (nargin == 3)
    % row indices have been specified
    PxNw = cellfun(@(x,y)(x(iR,y)/sFac),Px,fok,'un',0);
    PyNw = cellfun(@(x,y)(x(iR,y)/sFac),Py,fok,'un',0);     
else
    % row indices have not been specified
    PxNw = cellfun(@(x,y)(x(:,y)/sFac),Px,fok,'un',0);
    PyNw = cellfun(@(x,y)(x(:,y)/sFac),Py,fok,'un',0);         
end
                                
% sets the extreme x/y-locations of the data points
nFrm = size(PxNw{1},1);
[xMean,yMean] = deal(cell(1,nApp));
for i = 1:length(PxNw)
    xMean{i} = num2cell(mean(PxNw{i},1,'omitnan')');
    yMean{i} = num2cell(mean(PyNw{i},1,'omitnan')');
end

% sets the x/y coordinates of the circle centres
[X0,Y0] = getCircCentreCoords(iMov);
if (Type == 0)
    % for the old solution file version, offset the y-position
    Y0 = Y0 - min(cellfun(@(x)(x(1)-1),iMov.iR)); 
end

% determines the indices of the circles wrt the regions
ind = cell(length(PxNw),1);
for i = 1:length(ind)
    ind{i} = cellfun(@(x,y)(argMin(sqrt((X0-x).^2+(Y0-y).^2),1)),xMean{i},yMean{i});
end

% memory allocation
for i = 1:nApp
    % calculates the x/y-location difference to the circle centre
    Rad{i} = R*ones(1,length(ind{i}));
    dPx{i} = PxNw{i} - repmat(X0(ind{i})',nFrm,1);
    dPy{i} = PyNw{i} - repmat(Y0(ind{i})',nFrm,1);  
    
    % determines the sub-regions where the flies have moved an appreciable
    % distance. those that have not will be excluded from the convex hull
    % calculations
    isOK = find(min(range(dPx{i},1),range(dPy{i},1)) > Rmin);
    
    % determines the convex hull coordinates for each valid circle    
    ii = cellfun(@(x)(find(~isnan(x))),num2cell(dPx{i}(:,isOK),1),'un',0);    
    kH = cellfun(@(x,y,z)(z(convhull(x(z),y(z)))),num2cell(dPx{i}(:,isOK),1),...
                        num2cell(dPy{i}(:,isOK),1),ii,'un',0);    
            
    % sets the convex hull points for each circle, and from this calculates
    % the radial distance and circumferential sector indices
    pC = cellfun(@(x,y,z)([x(z),y(z)]),num2cell(dPx{i}(:,isOK),1),...
                            num2cell(dPy{i}(:,isOK),1),kH,'un',0);
    RC = cellfun(@(x)(sqrt(x(:,1).^2+x(:,2).^2)),pC,'un',0);
    tC = cellfun(@(x)(floor(deg2bear(atan2(x(:,2),x(:,1)))/tSec)+1),...
                                pC,'un',0);
                            
    % determines which radial points are within range of the circle radius.
    % from this, determine which are 
    iRC = cellfun(@(x)((x >= pR*(R-dR)) & (x <= (R+dR))),RC,'un',0);
    jj = cellfun(@(x,y)(length(unique(x(y))) >= nSecMin),tC,iRC);
    
    % calculates the optimal offset
    dp0{i} = zeros(2,size(dPx{i},2));
    if (any(jj))
        kk = isOK(jj);
        dp0{i}(:,kk) = cell2mat(cellfun(@(p,x)(fminsearch(@optCircCentre,[0,0],opt,p(x,:))),...
                            pC(jj),iRC(jj),'un',0)')';        
        dPx{i}(:,kk) = dPx{i}(:,kk) - repmat(dp0{i}(1,kk),size(dPx{i},1),1);
        dPy{i}(:,kk) = dPy{i}(:,kk) - repmat(dp0{i}(2,kk),size(dPy{i},1),1);
    
        % calculates the mean radius of the convex hull points
        pC2 = cellfun(@(x,y,z)([x(z),y(z)]),num2cell(dPx{i}(:,kk),1),...
                            num2cell(dPy{i}(:,kk),1),kH(jj),'un',0);    
        Rad{i}(kk) = cellfun(@(x)(min(Rmax,mean(sqrt(x(:,1).^2 + x(:,2).^2)))),pC2);    
    end
end

% --- optimises the circle centre so that the range in radii is minimised
function F = optCircCentre(p0,pC)

% calculates the ranges of the radii
F = range(sqrt(sum((pC - repmat(p0,size(pC,1),1)).^2,2)));
