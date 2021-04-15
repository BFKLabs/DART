% --- calculates the number of frames read/image stack
function nFrmRS = detStackFrmCount(pData)

if (hasPosData(pData))
    nFrmRS = NaN;
else
    Navg = size(pData.fPos{1}{1},1)/length(pData.frmOK);
    nFrmRS = 25*(1 + (Navg > 25));
end