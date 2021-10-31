% --- applies the offset the the frame Img (if translation applies)
function Img = applyImgOffset(Img,iMov,iFrmR)

% determines if translation is feasible
if ~isfield(iMov,'iPhase') || ~isfield(iMov,'dpInfo')
    % if no information is provided, then exit
    return
elseif isempty(iMov.dpInfo)
    % if the field has not been initialised, then exit
    return
end

% calculates and applied the image offset
dpOfs = calcFrameOffset(iMov.dpInfo,iFrmR);
Img = calcImgTranslate(Img,dpOfs);