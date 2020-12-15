% --- calculates the median filtered background image estimate
function ImdBG0 = medianBGImageEst(I,h,N)

% sets the default input variables
if nargin < 3; N = 1; end

% updates the median background image
for i = 1:N
    % calculates the new median smoothed background mask
    ImdBG0 = 0.5*(medfilt2(I,[h(1),1]) + medfilt2(I,[1,h(2)]));

    % updates the image (by removing the median image)
    if i < N; I = I - ImdBG0; end
end