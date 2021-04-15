% --- 
function oPos = calcOuterPos(m,n,i)

% calculates the height/width of each subplot
[W,H] = deal(1/n,1/m);
[iR,iC] = deal(floor((i-1)/n)+1,mod(i-1,n)+1);

% sets the outer position vector
oPos = [(iC-1)*W,(m-iR)*H,W,H];