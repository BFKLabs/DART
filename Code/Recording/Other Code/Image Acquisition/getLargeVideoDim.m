% --- retrieves the maximum height/width dimension coordinates
function [Hmax,Wmax] = getLargeVideoDim()

% sets the height/width dimensions
pW = 10;
Wmax = pW*[1600:100:2500,2590];
Hmax = pW*[1600,1560,1520,1460,1400,1340,1285,1235,1190,1145,1100];