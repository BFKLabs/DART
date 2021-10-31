function Inw = calcImgTranslate(I,dP)

if all(dP == 0)
    % return the original if no shift
    Inw = I;
elseif all(isnan(I(:)))
    % if all values are NaNs then return original image
    Inw = I;
else
    % otherwise, shift the image by the vector dP
    Inw = imtranslate(I,-dP,'linear','FillValues',NaN);
end