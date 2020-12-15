function obj = privateSubsasgn(obj, Struct, Value, classErrID, className)
%PRIVATESUBSASGN Subscripted assignment into image acquisition objects.
%
%    PRIVATESUBSASGN Subscripted assignment into image acquisition objects. 
%
%    OBJ(I) = B assigns the values of B into the elements of OBJ specified by
%    the subscript vector I. B must have the same number of elements as I
%    or be a scalar.
% 
%    OBJ(I).PROPERTY = B assigns the value B to the property, PROPERTY, of
%    image acquisition object OBJ.
%

%    CP 1-24-03
%    Copyright 2001-2010 The MathWorks, Inc.

% Initialize variables.
prop1 = '';
index1 = {};
StructL = length(Struct);

% Assuming obj is originally empty...
if isempty(obj)
    % Ex. obj(1) = videoinput('matrox', 1);
    if (isequal(Struct.type, '()') && isequal(Struct.subs{1}, 1:length(Value)))
        obj = Value;
        return;
    elseif length(Value) ~= length(Struct.subs{1})
        % Ex. obj(1:2) = videoinput('matrox', 1);
        error(message('imaq:subsasgn:elementMismatch'));
    elseif Struct.subs{1}(1) <= 0
        % Ex. obj(-3) = videoinput('matrox', 1);
        error(message('imaq:subsasgn:negativeIndex'));
    else
        % Ex. obj(2) = videoinput('matrox', 1); and av is []..
        error(message('imaq:subsasgn:noGaps'));
    end
end

% The first Struct can either be:
switch Struct(1).type
    case '.'
        % Ex. obj.FramesPerTrigger = 10;
        prop1 = Struct(1).subs;
    case '()'
        % Ex. obj(1) = obj(2); 
        index1 = Struct(1).subs;
        if strcmp(index1, ':')
            index1 = 1:length(obj);
        end
    case '{}'
        % Ex. obj{3} = obj(2);
        error(message('imaq:subsasgn:cellRef'));
    otherwise
        error(message('imaq:subsasgn:unknownType', Struct(1).type));
end

if StructL > 1
    % Ex. obj(1).TimerFcn = 'mycallback' creates:
    %    Struct(1) -> () and 1
    %    Struct(2) ->  . and 'TimerFcn'
    %    StrcutL   ->  3
    switch Struct(2).type
        case '.'
            if isempty(index1)
                % Ex. obj.FramesAvailable.Prop2 = 5
                error(message('imaq:subsasgn:invalidDot'));
            else
                % Ex. obj(1).TimerFcn = 'mycallback';
                % Ex. obj(2).FramesPerTrigger = 10
                prop1 = Struct(2).subs;
            end
        case '()'
            error(message('imaq:subsasgn:invalidParens'));
        case '{}'
            error(message('imaq:subsasgn:cellRef'));
        otherwise
            error(message('imaq:subsasgn:unknownType', Struct(2).type));
    end  
end   

% Index1 will be entire object if not specified.
if isempty(index1)
    index1 = 1:length(obj);
end

% Convert index1 to a cell if necessary.
if ~iscell(index1)
    index1 = {index1};
end

% Set the specified value.
if ~isempty(prop1)
    % Ex. obj.FramesPerTrigger = 10
    % Ex. obj(2).FramesPerTrigger = 10
    
    % Extract the object.
    try
        indexObj = localIndexOf(obj, index1);
    catch exception
        throw(exception)
    end
    
    % Set the property.
    try
        set(indexObj, prop1, Value);
    catch exception
        throw(exception);
    end
else
    % Ex. obj(2) = obj(1);
    if (~(isa(Value, className) || isempty(Value)))
        error(message(classErrID));
    end
    
    % Ex. obj(1) = [] and obj is 1-by-1.
    if ((length(obj) == 1) && isempty(Value))      
        error(message('imaq:subsasgn:useClear'));
    end
    
    % Error if a gap will be placed in array.
    % Ex. obj(4) = obj2 and obj is 1-by-1.
    if (max(index1{:}) > length(obj)+1)      
        error(message('imaq:subsasgn:dimensionExceeded'));
    end
    
    % If the objects are the same length replace.
    if ((length(index1{:}) == length(Value)) || isempty(Value) || (length(Value) == 1))
        try
            obj = localReplaceElement(obj, index1, Value);
        catch exception
            throw(exception)
        end
    else
        error(message('imaq:subsasgn:elementMismatch'));
    end	
end

% *********************************************************************
% Index into an image acquisition array.
function result = localIndexOf(obj, index)

% Initialize variables.
result = obj;

try
    % Get the field information of the entire object.
    uddobj = privateGetField(obj, 'uddobject');
    type = privateGetField(obj, 'type');
    
    % Create result with only the indexed elements.
    result = isetfield(result, 'uddobject', uddobj(index{:}));
    result = isetfield(result, 'type', type(index{:}));
catch %#ok<CTCH>
    message = 'Index exceeds matrix dimensions';
    id = 'imaq:subsasgn:dimensionExceeded';
    throw(MException(id, message))
end

% *********************************************************************
% Replace the specified element.
function obj = localReplaceElement(obj, index, Value)

% Get the current state of the object.
uddobject = privateGetField(obj, 'uddobject');
type = privateGetField(obj, 'type');

% Replace the specified index with Value.
if ~isempty(Value)
    uddobject(index{1}) = privateGetField(Value, 'uddobject');
    type(index{1}) = privateGetField(Value, 'type');
else
    uddobject(index{1}) = [];
    type(index{1}) = [];
end

% Assign the new state back to the original object.
obj = isetfield(obj, 'uddobject', uddobject);
obj = isetfield(obj, 'type', type);
