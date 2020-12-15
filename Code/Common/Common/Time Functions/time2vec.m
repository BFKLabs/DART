function tVec = time2vec(tMax,tUnits)

%
tMlt = [24,60,60,1];
tMaxS = tMax/getTimeMultiplier(tUnits,'s');

%
tVec = zeros(1,4);
for i = 1:length(tMlt)
    tMltNw = prod(tMlt(i:end));
    tVec(i) = floor(tMaxS/tMltNw);
    
    tMaxS = tMaxS - tVec(i)*tMltNw;
end