function output = privateFindObj(obj, varargin)
%PRIVATEFINDOBJ Find image acquisition objects.
%
%    OUT = IMAQFIND(OBJ, 'P1', V1, 'P2', V2,...) returns a cell array, OUT, of
%    image acquisition objects whose property names and property values match
%    those passed as parameter/value pairs, P1, V1, P2, V2. The parameter/value
%    pairs can be specified as a cell array. The search is restricted to the
%    image acquisition objects listed in OBJ. OBJ can be an array of objects.
%
%    See also IMAQDEVICE/IMAQFIND.

%    CP 7-13-02
%    Copyright 2001-2013 The MathWorks, Inc.

% Error checking.
isParentObjects = isa(obj, 'imaqdevice');

% Adding a check for the videosource object seperately as videosource is no
% longer a imaqchild object after converting it to an mcos object.
if ~isParentObjects && ~isa(obj, 'imaqchild') ...
        && ~isa(obj,'videosource')
    error(message('imaq:imaqfind:invalidType'));
else
    validIndices = isvalid(obj);
    if ~all(validIndices),
        % There are invalid objects.
        % Find all invalid indexes.
        inval_OBJ_indexes = find(isvalid(obj) == false);
        
        % Generate an error message specifying the index for the first invalid
        % object found.
        error(message('imaq:imaqfind:invalidOBJ', inval_OBJ_indexes(1)));
    else
        % Extract the valid objects.
        obj = obj(isvalid(obj));
    end
end

% If the object is a videosource, we do not need to get its uddobject and
% convert them into MATLAB objects.
if isa(obj,'videosource')
    parent = findobj(obj,varargin{:});
else
    % Extract the UDD objects.
    uddobjects = privateGetField(obj, 'uddobject');
    nObjects = length(uddobjects);
    
    % Search for the specified parameters.
    parent = find(uddobjects, varargin{:});
    
    % Convert UDD objects to MATLAB objects.
    if ~isempty(parent),
        parent = privateUDDToMATLAB(parent);
    else
        % FIND returns 0x1 handle array.
        parent = [];
    end
end

children = {};
% Find all children objects matching criteria.
if isParentObjects,
    for i=1:nObjects
        src = get(uddobjects(i), 'Source');
        result = findobj(src, varargin{:});
        if ~isempty(result),
            for r = 1:length(result),
                % Children need to be returned as 1x1's.
                children = [ children {result} ]; %#ok<AGROW>
            end
        end
    end
end

% Return all results as a column.
output = cell(size(parent));
for i=1:length(parent)
    output{i} = parent(i);
end
output = {output{:} children{:}}'; %#ok<CCAT>
