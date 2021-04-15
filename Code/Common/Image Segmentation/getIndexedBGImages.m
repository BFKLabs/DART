% --- retrieves the indexed background image stack
function Ibg = getIndexedBGImages(Ibg,indC,varargin)

% sets the background image stack based on the image type
if (iscell(Ibg{1}))
    % background images are stored in a multi-level cell array
    i0 = find(cellfun(@(x)(~isempty(x{1})),Ibg),1,'first');
    if (nargin >= 2)
        Ibg = Ibg{i0}(indC);
    else
        Ibg = Ibg{i0};
    end
else
    % background images are stored in a single-level cell array
    if (nargin >= 2)
        Ibg = Ibg(indC);
    end
end     

% returns the cell array as a numerical array (if the correct inputs)
if ((length(Ibg) == 1) && (nargin == 3))
    Ibg = Ibg{1};
end