% --- applies the offset the the frame Img (if translation applies)
function Img = applyImgOffset(Img,iMov,iFrmR)

% determines if translation is feasible
if ~isfield(iMov,'iPhase') || ~isfield(iMov,'phInfo')
    % if no information is provided, then exit
    return
elseif isempty(iMov.phInfo)
    % if the field has not been initialised, then exit
    return
end

% calculates and applied the image offset
iMov.phInfo.hasT = iMov.phInfo.hasT & iMov.ok;
dpOfs = mean(calcFrameOffset(iMov.phInfo,iFrmR),1,'omitnan');
Img = calcImgTranslate(Img,dpOfs);
