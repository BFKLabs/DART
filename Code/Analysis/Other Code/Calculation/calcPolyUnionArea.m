% --- calculates the intersecting area of the polygons given by the 
%     vertices, P1 and P2 respectively --- %
function A = calcPolyUnionArea(P1,P2,varargin)

% initialisations
Asz = 1000;

% if there are no values calculated, then exit
if (any(cellfun(@(x)(all(isnan(x))),[P1,P2])))
    A = NaN; return
end

% determines the convex hulls of both sets of points
ii = find((~isnan(P1{1})) & (~isnan(P2{1})));
[K1,K2] = deal(convhull(P1{1}(ii),P1{2}(ii)),convhull(P2{1}(ii),P2{2}(ii)));
xMin = min(min(P1{1}),min(P2{1}));
yMin = min(min(P1{2}),min(P2{2}));

% calculates the scale factor from the minimum areas of the convex hulls
[K1,K2] = deal(ii(K1),ii(K2));
Amin = min(polyarea(P1{1}(K1),P1{2}(K1)),polyarea(P2{1}(K1),P2{2}(K1)));
Rscl = sqrt(Asz/Amin);

% rescales the 
P1nw = roundP(Rscl*[(P1{1}(K1)-xMin),(P1{2}(K1)-yMin)])+1;
P2nw = roundP(Rscl*[(P2{1}(K2)-xMin),(P2{2}(K2)-yMin)])+1;
sz = [max([P1nw(:,2);P2nw(:,2)]),max([P1nw(:,1);P2nw(:,1)])];

% determines the union area vertices, and calculates the remaining area
[A1,A2] = deal(poly2bin(P1nw,sz),poly2bin(P2nw,sz));
A = sum(A1(:) & A2(:))/sum(A1(:));
