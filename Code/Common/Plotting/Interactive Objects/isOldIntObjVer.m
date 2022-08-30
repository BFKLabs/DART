% --- determines if the current version uses the old interactive 
%     object version (i.e., imline vs drawline)
function isOld = isOldIntObjVer()

isOld = verLessThan('matlab','9.4');
% isOld = true;
