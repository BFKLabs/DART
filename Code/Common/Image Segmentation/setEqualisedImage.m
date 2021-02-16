% --- equalises the image for the row/column medians
function Ieq = setEqualisedImage(I,varargin)

%
Ieq = I;

%
while 1
    %
    Ieq0 = Ieq;
    
    %
    Ieq = Ieq - repmat(nanmedian(Ieq,2),1,size(Ieq,2));
    Ieq = Ieq - repmat(nanmedian(Ieq,1),size(Ieq,1),1);

    %
    dIeq = nanmean(abs(Ieq0(:)-Ieq(:)));
    if dIeq < 0.01
        break
    end
    
%     % calculates the row/column median traces
%     IxMd = repmat(nanmedian(IeqPr,2),1,size(I,2));
%     IyMd = repmat(nanmedian(I,1),size(I,1),1);
% 
%     % calculates the equalised images
%     Ieq = I - (IxMd + IyMd);
end
    
%
if (nargin == 2); Ieq = Ieq - nanmedian(Ieq(:)); end
