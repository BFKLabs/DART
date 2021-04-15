% --- converts a polynomial to a binary
function B = poly2bin(P,sz)

%
if (nargin == 1)
    [xMin,xMax] = deal(min(P(:,1)),max(P(:,1)));
    [yMin,yMax] = deal(min(P(:,2)),max(P(:,2)));
    
    sz = [(ceil(yMax)-floor(yMin)),(ceil(xMax)-floor(xMin))]+4;
    P = [(P(:,1)-xMin),(P(:,2)-yMin)]+2;
end

%
P(:,1) = max(1,min(P(:,1),sz(2)));
P(:,2) = max(1,min(P(:,2),sz(1)));

%
PP = cell(size(P,1)-1,1);
for i = 1:length(PP)
    j = (1:2)+(i-1);
    DD = sqrt(sum(diff(P(j,:),[],1).^2));
    xiI = linspace(0,1,ceil(DD))';
    PP{i} = roundP([interp1([0;1],P(j,1),xiI),...
                    interp1([0;1],P(j,2),xiI)]);
end

% sets up the X/Y coordinates
PPT = cell2mat(PP);
B = setGroup(sub2ind(sz,PPT(:,2),PPT(:,1)),sz);
B = bwmorph(bwfill(bwmorph(B,'dilate'),'holes'),'erode');
