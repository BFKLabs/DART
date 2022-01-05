% --- calculates the median filtered background image estimate
function ImdBG0 = medianBGImageEst(I,h,N)

% sets the default input variables
if nargin < 3; N = 1; end

% fills in any gaps
B = isnan(I);
I(B) = nanmedian(I(~B));

% updates the median background image
for i = 1:N
    % calculates the new median smoothed background mask
    if length(h) == 1
        ImdBG0 = medfilt2(I,h*[1,1],'symmetric');
    else
        ImdBG0 = 0.5*(medfilt2(I,[h(1),1],'symmetric') + ...
                      medfilt2(I,[1,h(2)],'symmetric'));
    end

    % updates the image (by removing the median image)
    if i < N; I = I - ImdBG0; end
end