% --- updates the coordinate for an arrow head with the coordinates p0 and 
%     bearing angle, Bear
function updateArrowHeadCoords(hArr,p0,Phi,yDir,isF)

% sets the default input arguments
if (nargin == 3); yDir = 1; end

% retrieves the arrow user data
%  1 - arrow height
%  2 - arrow base width
uData = get(hArr,'UserData');

% converts the bearing angle to radians
pB = uData(1)*uData(2)*isF;

% memory allocation
[xArr,yArr] = deal(zeros(3,1));
[xDel,yDel] = deal(uData(1)*cos(Phi),uData(1)*sin(yDir*Phi));
[xDelB,yDelB] = deal(pB*cos(Phi+pi/2),pB*sin(yDir*(Phi+pi/2)));

% sets the coordinates of the arrow vertices
[xB,yB] = deal(p0(1)-xDel,p0(2)-yDel);
[xArr(1),yArr(1)] = deal(p0(1)+xDel,p0(2)+yDel);
[xArr(2:3),yArr(2:3)] = deal(xB+xDelB*[-1 1],yB+yDelB*[-1 1]);

% updates the arrow vertex coordinates
set(hArr,'xdata',xArr,'ydata',yArr);

