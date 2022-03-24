% --- determines if the object is large relative to the experimental region
function isLarge = detIfLarge(iMov,Nsz)

switch getDetectionType(iMov)
    case ('None')
        isLarge = Nsz > max(cellfun(@length,iMov.iC))/4;
    case {'Circle','Rectangle'}
        if isempty(iMov.autoP)
            [szC,szR] = deal(cellfun(@length,iMov.iC),cellfun(@length,iMov.iR));
            isLarge = Nsz > max(max(szC),max(szR))/4;
        else
            isLarge = any(Nsz > iMov.autoP.R(:)/2);
        end        
    case ('General')
        isLarge = Nsz > max(cellfun(@length,iMov.iC))/4;
end
