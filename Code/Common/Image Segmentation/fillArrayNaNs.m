function I = fillArrayNaNs(I,fillVal)

B = isnan(I);
if exist('fillVal','var')
    I(B) = fillVal;
else
    I(B) = mean(I(~B));
end