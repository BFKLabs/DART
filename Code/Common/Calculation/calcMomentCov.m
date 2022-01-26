function Icov = calcMomentCov(I,x,y)

% initialisations
[XY,II] = deal([x(:),y(:)],I(:));
Isum = sum(II);

%
M10 = calcRawMoment(II,XY,[1,0]);
M01 = calcRawMoment(II,XY,[0,1]);
[Xc,Yc] = deal(M10/Isum,M01/Isum);

% calculates the other moments
u11 = (calcRawMoment(II,XY,[1,1]) - Xc * M01)/Isum;
u20 = (calcRawMoment(II,XY,[2,0]) - Xc * M10)/Isum;
u02 = (calcRawMoment(II,XY,[0,2]) - Yc * M01)/Isum;

% sets the final covariance array
Icov = [[u20, u11];[u11, u02]];

% --- calculate the raw moment of the image I for indices hX/hY
function M = calcRawMoment(I,XY,hXY)

% sets the x calculation values
for i = 1:length(hXY)
    switch hXY(i)
        case 0
            % case is zero indices
            XY(:,i) = 1;

        case 1
            % do nothing...

        otherwise
            % case is index > 1
            XY(:,i) = XY(:,i).^hXY(i);
    end
end

% calculates the final moment value
M = sum(I.*XY(:,1).*XY(:,2));