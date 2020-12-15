function output = privateSet(obj, vararginFromSet, nIn, nOut)
%PRIVATESET Configure or display image acquisition object properties.
%
%    OUT = PRIVATESET(OBJ, VARARGINFROMSET, NIN, NOUT)
%    performs the SET implementation for image acquisition toolbox objects.
%    OBJ is the image acquisition object, VARARGINFROMSET is the input to
%    SET, and NIN and NOUT are the number of input and output arguments
%    provided to SET. OUTPUT is the SET result.
%

%    CP 9-01-01
%    Copyright 2001-2012 The MathWorks, Inc.

% Initialize return arguments.
output = [];

% Call builtin set if OBJ isn't an image acquisition object.
% Ex. set(gcf, obj);
% Ex. set(obj, 'FramesPerTrigger', obj);
if ~( isa(obj, 'imaqchild') || isa(obj, 'imaqdevice') ),
    builtin('set', obj, vararginFromSet{:});
    return;
end

% Error if invalid.
if ~all(isvalid(obj))
    error(message('imaq:set:invalidOBJ'));
end

% Extract UDD object.
uddobj = privateGetField(obj, 'uddobject');

% Need to get the original values in case set errors and they need to be
% restored.
for ii = 1:length(uddobj)
    settableProps(ii) = builtin('set', uddobj(ii)); %#ok<AGROW>
    allSettablePropNames(ii) = {fieldnames(settableProps(ii))}; %#ok<AGROW>
    originalValues(ii) = {get(obj, allSettablePropNames{ii})}; %#ok<AGROW>
end

% Construct appropriate displays and calls.
if nOut == 0,
    if nIn == 1,
        % Ex. set(obj)
        if (length(obj) > 1)
            error(message('imaq:set:vectorOBJ'));
        else
            localSetListDisp(uddobj);
        end
    else
        % Ex. set(obj, 'FramesPerTrigger');
        % Ex. set(obj, 'FramesPerTrigger', 48);
        try
            % Call the UDD set method.
            if (nIn == 2)
                if ischar(vararginFromSet{1}) 
                    % Ex. set(obj, 'LoggingMode')
                    % Obtain the property's enums (this also
                    % ensures we have a valid property).
                    enums = set(uddobj, vararginFromSet{1});
                    
                    % Correct the case of the property name - i.e case
                    % insensitivity.
                    handle = uddobj.classhandle;
                    propinfo = findprop(handle, vararginFromSet{1});
                    
                    % Create the property's enum display.
                    fprintf('%s\n', privateCreatePropEnumDisp(propinfo.Name, enums, propinfo.DefaultValue));
                else
                    % Ex. set(obj, struct);
                    if isa(obj,'imaqchild') && ~isempty(strfind(uddobj.parent.Name,'gige'))
                        if isstruct(vararginFromSet{1}) && isfield(vararginFromSet{1}, 'PacketSize')
                            % If using old enumerated PacketSize, convert
                            % to numeric and issue warning.
                            vararginFromSet{1}.PacketSize = str2double(vararginFromSet{1}.PacketSize);
                            warning(message('imaq:set:gigePacketSize'));
                        end
                    end
                    builtin('set', uddobj, vararginFromSet{:});
                end
            else
                % Ex. set(obj, 'FramesPerTrigger', 48, ...); 
                % Ex. set(obj, {'FramesPerTrigger', 'Timeout', 'LoggingMode'}, {48, 5, 'disk'}); 
                if isa(obj,'imaqchild') && ~isempty(strfind(uddobj.parent.Name,'gige'))
                    for ii = 1:length(vararginFromSet)
                        if strcmp(vararginFromSet{ii}, 'PacketSize')
                            % If using old enumerated PacketSize, convert
                            % to numeric and issue warning.
                            if ischar(vararginFromSet{ii+1})
                                vararginFromSet{ii+1} = str2double(vararginFromSet{ii+1});
                                warning(message('imaq:set:gigePacketSize'));
                            end
                        end
                    end
                end
                builtin('set', uddobj, vararginFromSet{:});
            end
        catch exception
            for ii = 1:length(obj)
                set(obj, allSettablePropNames{ii}, originalValues{ii});
            end
            throw(privateFixUDDError(exception));
        end	
    end
elseif ((nOut == 1) && (nIn == 1))
    % Ex. out = set(obj);
    
    % Call the UDD SET method and sort the list.
    outputStruct = set(uddobj);
    fields = fieldnames(outputStruct);
    % Use LOWER to ensure properties are alphabetized:
    % Logging, then LogToDiskMode, not the other way around.
    [sorted, ind] = sort(lower(fields));
    for i=1:length(sorted),
        output.( fields{ind(i)} ) = outputStruct.( fields{ind(i)} );
    end
else
    % Ex. out = set(obj);
    % Ex. out = set(obj, 'FramesPerTrigger')
    % Ex. out = set(obj, 'FramesPerTrigger', 48)
    try
        % Call the UDD set method.
        output = builtin('set', uddobj, vararginFromSet{:});
        if nIn>2,
            % Handles the case where we have:
            %   >> out = set(ch(1), {'Selected'}, {'foobar'})
            %
            % This syntax executes the set correctly, but "out" remains
            % unassigned. I.e. it'll perform the set and return:
            %    ??? Error using ==> set
            %    One or more output arguments not assigned during call to 'imaqchild/set'.
            %
            % In order for FEVAL to work properly, we *need* to return
            % something for "output".
            output = [];
        end
    catch exception
        for ii = 1:length(obj)
            set(obj, allSettablePropNames{end}, originalValues{end});
        end
        throw(privateFixUDDError(exception));
    end	
end	

% *******************************************************************
function localSetListDisp(uddobj)
% Create the SET display for SET(OBJ).

% TODO: Re-sort vendor specific properties.
% Create a sorted list of PV pairs.
list = set(uddobj);
handle = uddobj.classhandle;
listValues = struct2cell(list);
propertyNames = fieldnames(list);

% Use LOWER to ensure proeprties are alphabetized:
% Logging, then LogToDiskMode, not the other way around.
[sortedNames index] = sort(lower(propertyNames));

% Initialize different property grouping containers.
srcRelated = '';
callbackRelated = '';
triggerRelated = '';
colorspaceRelated = '';
genRelated = '';
deviceSpecific = '';

% Display each property as follows:
%   ...
%   LoggingMode: [ append | index | {overwrite} ]
%   Name
%   ...
indent = blanks(4);
for i=1:length(sortedNames),
    property = propertyNames{index(i)};
    enumStr = '';
    propName = sprintf([indent property]);
    propertyinfo = findprop(handle, property);
    
    % Create the enum value line
    if ~isempty(listValues{index(i)}) || ~isempty(findstr('Fcn ', [propName ' '])),
        enumDisp = privateCreatePropEnumDisp(property, listValues{index(i)}, propertyinfo.DefaultValue);
        enumStr = sprintf(': %s', enumDisp);
    end
    strToDisp = sprintf('%s%s\n', propName, enumStr);
    
    % Determine how to categorize the property.
    switch propertyinfo.Category,
        case 'acqSrc',
            srcRelated = [srcRelated strToDisp]; %#ok<AGROW>
        case 'callback',
            callbackRelated = [callbackRelated strToDisp]; %#ok<AGROW>
        case 'trigger',
            triggerRelated = [triggerRelated strToDisp]; %#ok<AGROW>
        case 'colorspace',
            colorspaceRelated = [colorspaceRelated strToDisp]; %#ok<AGROW>
        otherwise,
            if propertyinfo.DeviceSpecific
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
    fprintf('  Color Space Settings%s%s%s', cr, colorspaceRelated, cr);
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
