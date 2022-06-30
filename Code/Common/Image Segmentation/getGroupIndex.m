% --- retrieves the linear indices + other properties for the blob objects
%     from the binary mask, Im
function [iGrp,varargout] = getGroupIndex(Im,varargin)

% sets the region properties array
pStr = {'PixelIdxList'};
if ~isempty(varargin)
    % ensures the input arguments have the correct format
    if iscell(varargin{1})
        varargin = varargin{1};
    end
    
    % sets the final property string array
    pStr = [pStr;varargin(:)];
end

% calculates the object region properties
s = regionprops(bwlabel(logical(Im)),pStr);

% retrieves the pixel index list
iGrp = arrayfun(@(x)(x.PixelIdxList),s,'un',0);

% sets the other output property values
if nargout > 1
    varargout = cell(nargout-1,1);
    for i = 1:(nargout-1)
        Pout = arrayfun(@(x)(x.(varargin{i})),s,'un',0);
        varargout{i} = cell2mat(Pout);
    end
end