function result = privateSubsref(obj, Struct)
%PRIVATESUBSREF Subscripted reference into image acquisition objects.
%
%    PRIVATESUBSREF Subscripted reference into image acquisition objects.
%
%    OBJ(I) is an array formed from the elements of OBJ specified by the
%    subscript vector I.  
%
%    OBJ.PROPERTY returns the property value of PROPERTY for image 
%    acquisition object OBJ.
%

%    CP 1-24-03
%    Copyright 2001-2010 The MathWorks, Inc.

% Initialize variables.
prop1 = '';
index1 = {};
StructL = length(Struct);

% The first Struct can either be:
switch Struct(1).type
    case '.'
        % Ex. obj.FramesPerTrigger;
        prop1 = Struct(1).subs;
    case '()'
        % Ex. obj(1); 
        index1 = Struct(1).subs;
    case '{}'
        % obj{1}
        error(message('imaq:subsref:cellRef'));
    otherwise
        error(message('imaq:subsref:unknownType', Struct(1).type));
end

if StructL > 1
    % Ex. obj(1).FramesPerTrigger;
    switch Struct(2).type
        case '.'
            if isempty(index1)
                % Ex. obj.FramesPerTrigger.Prop2
                error(message('imaq:subsref:invalidDot'));
            else
                % Ex. obj(1).FramesPerTrigger;
                prop1 = Struct(2).subs;
            end
        case '()'
            error(message('imaq:subsref:invalidParens'));
        case '{}'
            error(message('imaq:subsref:cellRef'));
        otherwise
            error(message('imaq:subsref:unknownType', Struct(1).type));
    end  
end   

% Index1 will be entire object if not specified.
if isempty(index1)
    index1 = 1:length(obj);
end

% Convert index1 to a cell if necessary. Handle the case
% when a ':' is passed, which requires a column vector to
% be returned.
isColon = false;
if ~iscell(index1)
    index1 = {index1};
end

% If indexing with logicals, extract out the correct values.
if islogical(index1{1})
    % Determine which elements to extract from obj.
    indices = find(index1{1} == true);
    
    % If there are no true elements within the length of obj, return.
    if isempty(indices)
        result = [];
        return;
    end
    
    % Construct new array of doubles.
    index1 = {indices};
end

% Error if index is a non-number.
for i=1:length(index1)
    ind = index1{i};
    if ~isnumeric(ind) && (~(ischar(ind) && (strcmp(ind, ':'))))
        error(message('imaq:subsref:invalidIndex', class(ind)));
    end
end

if any(cellfun('isempty', index1))
    result = [];
    return;
elseif (length(index1{1}) ~= (numel(index1{1})))
    error(message('imaq:subsref:noMatrix'));
elseif length(index1) == 1 
    if strcmp(index1{:}, ':')
        isColon = true;
        index1 = {1:length(obj)};
    end
else
    for i=1:length(index1)
        if (strcmp(index1{i}, ':'))
            index1{i} = 1:size(obj,i); %#ok<AGROW>
        end
    end
end

% Return the specified value.
if ~isempty(prop1)
    % Ex. obj.BaudRate 
    % Ex. obj(2).BaudRate
    
    % Extract the object.
    try
        indexObj = localIndexOf(obj, index1, isColon);
    catch exception
        throw(exception)
    end
    
    % Get the property value.
    try
        result = get(indexObj, prop1);
    catch exception
        throw(exception);
    end
else
    % Ex. obj(2);
    
    % Extract the object.
    try
        result = localIndexOf(obj, index1, isColon);   
    catch exception
        throw(exception)
    end
end

% *********************************************************************
% Index into an image acquisition array.
function result = localIndexOf(obj, index1, isColon)

% Get the field information of the entire object.
uddobj = privateGetField(obj, 'uddobject');
type = privateGetField(obj, 'type');

% Redefine the object to contain the right UDD items.
result = obj;
result = isetfield(result, 'uddobject', uddobj(index1{:}));
result = isetfield(result, 'type', type(index1{:}));
if isColon
    result = result';
end