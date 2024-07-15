% --- calculates the binned fly movement. the movement is calculated
%     using the binned indices array, indB, for the feasible flies
%     given by the boolean array, flyok and the apparatus index, ind --- %
function V = calcBinnedFlyMovement(snTot,T,indB,cP,ind,flyok,varargin)

% determines the non-empty time bins
jj = cellfun('length',indB) > 1;
V = cell(length(indB),1);

% sets the new x/y fly location arrays
Px = snTot.Px{ind};
if ~isempty(snTot.Py)
    % y-values present, so use them
    Py = snTot.Py{ind}; 
else
    % otherwise, set an empty array
    Py = []; 
end

% sets the fly feasibility boolean array (if not provided)
if (nargin == 5)
    flyok = true(size(Px,2),1);
end

% sets the binned x/y locations   
switch cP.movType
    case 'Absolute Speed'
        % case is calculating absolute distance
        V(jj) = calcBinnedAbsSpeed(Px,Py,T,flyok,indB(jj));

    case 'Absolute Range' 
        % case is calculating absolute distance
        V(jj) = calcBinnedRange(Px,Py,flyok,indB(jj));        

    case 'Absolute Distance' 
        % case is calculating absolute distance
        V(jj) = calcBinnedAbsDist(Px,Py,flyok,indB(jj));                

    case 'Midline Crossing'
        % case is calculating midline crossing
        V(jj) = calcMidlineCross(Px,flyok,indB(jj),cP.pWid,cP.tBin);
end

% converts the binned activity array to the full sized array
if (nargin == 7)    
    Vtmp = NaN(length(V),length(flyok));
    Vtmp(:,flyok) = cell2mat(V);
    V = num2cell(Vtmp,2);
end

% ----------------------------------------------- %
% --- ABSOLUTE LOCATION CALCULATION FUNCTIONS --- %
% ----------------------------------------------- %

% --- calculates the movement using the absolute distance
function V = calcBinnedAbsSpeed(Px,Py,Ttot,flyok,indB)

% calculates the movement based on whether the y-distances are included
if isempty(Py)
    % calculates the binned distances from the summed absolute
    % difference in the x-locations
%     if (sum(flyok) == size(Px,2))
        V = cellfun(@(x)(sum(abs(diff(Px(x,:),1)),1,'omitnan')/...
                        diff(Ttot(x([1 end])))),indB,'un',0);        
%     else
%         V = cellfun(@(x)(sum(abs(diff(Px(x,flyok),1,'omitnan')),1)/...
%                         diff(Ttot(x([1 end])))),indB,'un',0);
%     end
else
    % sets the binned x/y locations 
%     if (sum(flyok) == size(Px,2))
        PxB = cellfun(@(x)(Px(x,:)),indB,'un',0);
        PyB = cellfun(@(x)(Py(x,:)),indB,'un',0);        
%     else
%         PxB = cellfun(@(x)(Px(x,flyok)),indB,'un',0);
%         PyB = cellfun(@(x)(Py(x,flyok)),indB,'un',0);
%     end            

    % calculates the total distance travelled using Phythagoras
    dT = cellfun(@(x)(diff(Ttot(x([1 end])))),indB,'un',0);
    V = cellfun(@(x,y,z)(sum(sqrt(diff(x,[],1).^2 + ...
                diff(y,[],1).^2),1,'omitnan'))/z,PxB,PyB,dT,'un',0);        
end

% --- calculates the movement using the absolute distance
function V = calcBinnedRange(Px,Py,flyok,indB)

% calculates the binned distances from the summed absolute
% difference in the x-locations
if (isempty(Py))
    % case is for 1-dimension. calculate the range of the distance
    % travelled over the time bin
    if (sum(flyok) == size(Px,2))
        V = cellfun(@(x)(range(Px(x,:))),indB,'un',0);
    else
        V = cellfun(@(x)(range(Px(x,flyok))),indB,'un',0);
    end
else
    % case is for 2-dimensions. calculate the largest distance travelled
    % from the initial time point in the time bin
    if (sum(flyok) == size(Px,2))
        dX = cellfun(@(x)(Px(x,:)-repmat(Px(x(1),:),...
                                    length(x),1)),indB,'un',0);
        dY = cellfun(@(x)(Py(x,:)-repmat(Py(x(1),:),...
                                    length(x),1)),indB,'un',0);        
    else
        dX = cellfun(@(x)(Px(x,flyok)-repmat(Px(x(1),flyok),...
                                    length(x),1)),indB,'un',0);
        dY = cellfun(@(x)(Py(x,flyok)-repmat(Py(x(1),flyok),...
                                    length(x),1)),indB,'un',0);
    end
                                
    % calculates the maximum distance travelled 
    V = cellfun(@(x,y)(max(sqrt(x.^2 + y.^2))),dX,dY,'un',0);
end

% --- calculates the summed absolute displacement from the x-location
%     array, Px, for the time bin indices, indB. if the y-locations are
%     provided, then calculate the summed distance travelled in 2D
function D = calcBinnedAbsDist(Px,Py,flyok,indB)

% calculates the absolute binned distance
if isempty(Py)
    if sum(flyok) == size(Px,2)
        D = cellfun(@(x)(sum...
                (abs(diff(Px(x,:),1)),1,'omitnan')),indB,'un',0);
    else
        D = cellfun(@(x)(sum...
                (abs(diff(Px(x,flyok),1)),1,'omitnan')),indB,'un',0);
    end
else
    % sets the binned x/y locations 
    if sum(flyok) == size(Px,2)
        PxB = cellfun(@(x)(Px(x,:)),indB,'un',0);
        PyB = cellfun(@(x)(Py(x,:)),indB,'un',0);            
    else
        PxB = cellfun(@(x)(Px(x,flyok)),indB,'un',0);
        PyB = cellfun(@(x)(Py(x,flyok)),indB,'un',0);    
    end
        
    % calculates the summed distances travelled over each time bin
    D = cellfun(@(x,y)(sum(sqrt(diff(x,[],1).^2 + ...
                    diff(y,[],1).^2),1,'omitnan')),PxB,PyB,'un',0);
end

% ----------------------------------------------- %
% --- MID-LINE CROSSING CALCULATION FUNCTIONS --- %
% ----------------------------------------------- %

% --- calculates the movement using the absolute distance
function N = calcMidlineCross(Px,flyok,indB,pWid,tBin)

% the exclusion zone (in pixels) around the mid-line crossing
xDel = 1;
tScale = 60/tBin;
nRow = size(Px,1);

% sets the lower/uppder midline location   
[PxMn,PxMx] = deal(min(Px(:)),max(Px(:)));     
P0 = PxMn + pWid*(PxMx - PxMn); 
xLo = floor(P0)-xDel; 
xHi = xLo + 2*xDel;

% determines the indices where the flies move from 
if (sum(flyok) == size(Px,2))
    indCross = cellfun(@(x)(calcMidlineCrossoverIndiv(x,xLo,xHi)),...
                            num2cell(Px,1),'un',0);    
else
    indCross = cellfun(@(x)(calcMidlineCrossoverIndiv(x,xLo,xHi)),...
                            num2cell(Px(:,flyok),1),'un',0);
end
                    
% sets the binned cross-over points, and calculates the number of
% cross-over points/minute for each of the time bins (scales the values
% such that the metric is given in crosses/min)
ACross = cell2mat(cellfun(@(x)(setGroup(x,[nRow 1])),indCross,'un',0));
N = cellfun(@(x)(sum(ACross(x,:),1)*tScale),indB,'un',0);
                    
% --- determines the indices (within the x-location array, PxNw) where the
%     fly crosses the tube mid-line (given by the lower/upper limits
%     xLo/xHi) --- %
function indCross = calcMidlineCrossoverIndiv(PxNw,xLo,xHi)

% determines the locations where the flies travel from right to left, and
% from right to left (crossing the low/high points)
iR2L = diff(sign([PxNw(1);PxNw] - xLo)) < 0; 
iL2R = diff(sign([PxNw(1);PxNw] - xHi)) > 0;
if (~any(iR2L) || ~any(iL2R))
    indCross = [];
    return
end

% sets the indices of the crossover points into a dummy array
A = zeros(length(PxNw),1);
[A(iR2L),A(iL2R)] = deal(1,2);

% from the non-zeros indices, determine the indices where there is a
% cross-over (i.e., a change in index from 1 to 2, or vice versa). store
% these points as the crossover indices
ii = find(A>0); 
indCross = [0;ii(abs(diff([A(ii(1));A(ii)])) > 0)];

% sets the initial side index (based on the first x-location)
if (PxNw(1) < xLo)
    % fly is initially on the left side
    indCross(1) = find(iL2R,1,'first');
else
    % fly is initially on the right side
    indCross(1) = find(iR2L,1,'first');
end    