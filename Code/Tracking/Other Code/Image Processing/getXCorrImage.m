% --- retrieves the cross-correlation image
function [Inw,Ig] = getXCorrImage(I,Bw,varargin)

% global variables
global is2D

% sets the candidate image based on the apparatus type
if (is2D)
    % case is 2D apparatus    
    [Ig,Inw] = deal(I,NaN(size(I)));    
    if (~isempty(Bw))
        jGrp = getGroupIndex(Bw);
        for i = 1:length(jGrp)
            A = I(jGrp{i});
            Inw(jGrp{i}) = A - median(A(:));
        end        
    end    
else
    % case is 1D apparatus
    if (nargin == 2)
        [Inw,Ig] = deal(setEqualisedImage(I,1));
    else
        [Inw,Ig] = deal(I);
    end
end