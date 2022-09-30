% --- estimates the size of all videos (each with frame count, nFrmVid and
%     frame size, szFrm, using compression type, vComp
function fSizeTot = estTotalVideoSize(nFrmTot,szFrm,vComp)

% calculates the total frames
fSize0 = 3*nFrmTot*prod(szFrm);

% calculates the total estimated file size
switch vComp
    case 'Grayscale AVI'
        % case is grayscale avi
        fSizeTot = (1/2)*fSize0/3;
        
    case 'Uncompressed AVI'
        % case is uncompressed avi
        fSizeTot = fSize0;
        
    case 'Archival'
        % case is archival compression
        fSizeTot = (1/4)*fSize0;        
        
    case 'Motion JPEG 2000'
        % case is mj2 compressions
        fSizeTot = (4/20)*fSize0;
        
    case 'Motion JPEG AVI'
        % case is motion jpeg compression
        fSizeTot = (1/55)*fSize0;
        
    case 'MPEG-4'
        % case is mpeg-4 compression
        fSizeTot = (1/90)*fSize0;
end

