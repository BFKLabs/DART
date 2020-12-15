% --- determines the unique values from the array, y --- %
function [yUniq,iUniq] = detUniValues(y,varargin)

% %
% yID = zeros(size(y,1),1);
% 
% %
% for i = 1:size(y,2)
%     yy = y(:,i);
%     if (range
%     
% end

%
try
    yRng = range(y);
catch
    yRng = max(y) - min(y);
end

%
if (yRng == 0)
    % if the range is zero, then just set the first values as being unique
    if (nargin == 1)
        [yUniq,iUniq] = deal(y(1),{(1:length(y))'});
    else
        [yUniq,iUniq] = deal(y(1),[true;false(length(y)-1,1)]);
    end
else
%     % sorts the values in ascending order
%     [y,ii] = sort(y,'ascend');    
    
    % interpolates any nan-values
    ii = isnan(y);
    if (any(ii))
        jj = find(~ii); ii = find(ii);
        y(ii) = roundP(interp1(jj,y(jj),ii));
    end
        
    % otherwise, determine which elements
    if (nargin == 1)
        iUniq = (diff([(y(1)-1);y]) == 1);
    else
        iUniq = (diff([(y(1)-1);y]) ~= 0);
    end
    yUniq = y(iUniq);
end