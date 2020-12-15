function output = privateGet(obj, varargin, nIn, nOut)
%PRIVATEGET Get image acquisition object properties..
%
%    OUTPUT = PRIVATEGET(OBJ, VARARGIN, NIN, NOUT) performs the
%    GET implementation for image acquisition toolbox objects. OBJ is the
%    image acquisition object, VARARGIN is the input to GET, and NIN and NOUT 
%    are the number of input and output arguments provided to GET. OUTPUT
%    is the GET result.
%

%    CP 9-01-01
%    Copyright 2001-2010 The MathWorks, Inc.

% Initialize return arguments.
output = [];

% Call builtin get if OBJ isn't an image acquisition object.
% Ex. get(gcf, obj);
if ~( isa(obj, 'imaqchild') || isa(obj, 'imaqdevice') )
    builtin('get', obj, varargin{:});
    return;
end

% Perform some error checking.
if nIn>2,
    error(message('imaq:get:tooManyInputs'));
elseif ~all(isvalid(obj)),
    error(message('imaq:get:invalidOBJ'));
end

% Extract UDD object.
uddobj = privateGetField(obj, 'uddobject');

if ((nOut == 0) && (nIn == 1))
    % Ex. get(obj)
    if (length(obj) > 1)
        error(message('imaq:get:vectorOBJ'));
    else
        localCreateGetDisplay(uddobj);
    end
elseif ((nOut == 1) && (nIn == 1))
    % Ex. out = get(obj);
    try
        % Call the UDD GET method and sort the list.
        oldfields = {};
        for nthStruct = 1:length(uddobj),
            getStruct = get(uddobj(nthStruct));
            fields = fieldnames(getStruct);
            
            % Make sure that all of the objects have the same properties.
            % This is currently always the case because it is not possible
            % to concatenate objects with different properties, but check
            % to be safe.
            if ~isempty(oldfields)
                if ~isempty(setxor(oldfields, fields))
                    error(message('imaq:get:sameprops'));
                end
            else
                oldfields = fields;
            end
                    
            % Use LOWER to ensure proeprties are alphabetized:
            % Logging, then LogToDiskMode, not the other way around.
            [sorted, ind] = sort(lower(fields));
            for i=1:length(sorted),
                output(nthStruct, 1).( fields{ind(i)} ) = getStruct.( fields{ind(i)} ); %#ok<AGROW>
            end
        end
    catch exception
        throw(privateFixUDDError(exception));
    end
else
    % Ex. get(obj, 'Name')
    try
        % Capture the output - call the UDD get method.
        output = get(uddobj, varargin{:});
    catch exception
        throw(privateFixUDDError(exception));
    end	
end

% ***************************************************************
% Create the GET display.
function localCreateGetDisplay(uddobj)

% TODO: Re-sort vendor specific properties.
% Create a sorted list of PV pairs.
getStruct = get(uddobj);
listValues = struct2cell(getStruct);
propertyNames = fieldnames(getStruct);

% Use LOWER to ensure proeprties are alphabetized:
% Logging, then LogToDiskMode, not the other way around.
[sortedNames index] = sort(lower(propertyNames));

% Capture UDD's GET structure display.
% This provides us with a formatted display of a property's value.
uddGetDisp = evalc('disp(getStruct)');
CRind = findstr(uddGetDisp, sprintf('\n'));

% Initialize different property grouping containers.
srcRelated = '';
callbackRelated = '';
triggerRelated = '';
colorspaceRelated = '';
genRelated = '';
deviceSpecific = '';

for i=1:length(sortedNames),
    % Using the sorted property list, extract the property 
    % name and its actual value.
    property = propertyNames{index(i)};
    value = listValues{index(i)};
    
    % For strings, display the value to avoid having extra quotes.
    % For all other types, use the formatted value display from 
    % the GET structure display. 
    cr = sprintf('\n');
    if ~ischar(value)
        % No CR for non-chars
        cr = '';
        
        % Locate the start and end of the property's value in 
        % the GET structure display.
        startind = findstr(uddGetDisp, [' ' property ':']) + length(property) + 3;
        CRlist = find((CRind > startind)==1);
        
        % Extract the property's value from the GET structure display.
        value = uddGetDisp(startind:CRind(CRlist(1)));
    end

    % Create the PV line.
    strToDisp = [sprintf('    %s = %s', property, value), cr];
    
    % Determine how to categorize the property.
    propertyInfo = findprop(uddobj, property);
    switch propertyInfo.Category,
        case 'acqSrc',
            srcRelated = [srcRelated strToDisp]; %#ok<AGROW>
        case 'callback',
            callbackRelated = [callbackRelated strToDisp]; %#ok<AGROW>
        case 'trigger',
            triggerRelated = [triggerRelated strToDisp]; %#ok<AGROW>
        case 'colorspace', 
            colorspaceRelated = [colorspaceRelated strToDisp]; %#ok<AGROW>
        otherwise,
            if propertyInfo.DeviceSpecific
                deviceSpecific = [deviceSpecific strToDisp]; %#ok<AGROW>
            else
                genRelated = [genRelated strToDisp]; %#ok<AGROW>
            end
    end    
end

% Display properties in groups.
%
% Note: CR is needed in order to get proper spaces
%       in codepad demos.
cr = sprintf('\n');
fprintf('  General Settings:%s%s%s', cr, genRelated, cr);

if ~isempty(colorspaceRelated)
    fprintf('  Color Space Settings:%s%s%s', cr, colorspaceRelated, cr);
end

if ~isempty(callbackRelated)
    fprintf('  Callback Function Settings:%s%s%s', cr, callbackRelated, cr);
end

if ~isempty(triggerRelated)
    fprintf('  Trigger Settings:%s%s%s', cr, triggerRelated, cr);
end

if ~isempty(srcRelated)
    fprintf('  Acquisition Sources:%s%s%s', cr, srcRelated, cr);
end

if ~isempty(deviceSpecific)
    fprintf('  Device Specific Properties:%s%s%s', cr, deviceSpecific, cr);
end
