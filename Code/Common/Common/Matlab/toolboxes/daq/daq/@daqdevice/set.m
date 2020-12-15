function outputStruct = set(obj, varargin)
%SET Set data acquisition object properties.
%
%    SET(OBJ, 'PropertyName', PropertyValue) sets the value, PropertyValue,
%    of the specified property, PropertyName, for data acquisition object OBJ.
%
%    OBJ can be a vector of data acquisition objects, in which case SET sets the
%    property values for all the data acquisition objects specified.
%
%    SET(OBJ,S) where S is a structure whose field names are object property
%    names, sets the properties named in each field name with the values contained
%    in the structure.
%
%    SET(OBJ,PN,PV) sets the properties specified in the cell array of strings,
%    PN, to the corresponding values in the cell array PV for all objects
%    specified in OBJ.  The cell array PN must be a vector, but the cell array
%    PV can be M-by-N where M is equal to length(OBJ) and N is equal to length(PN)
%    so that each object will be updated with a different set of values for the
%    list of property names contained in PN.
%
%    SET(OBJ,'PropertyName1',PropertyValue1,'PropertyName2',PropertyValue2,...)
%    sets multiple property values with a single statement.  Note that it
%    is permissible to use property/value string pairs, structures, and
%    property/value cell array pairs in the same call to SET.
%
%    SET(OBJ, 'PropertyName')
%    PROP = SET(OBJ,'PropertyName') displays or returns the possible values for
%    the specified property, PropertyName, of data acquisition object OBJ.  The
%    returned array, PROP, is a cell array of possible value strings or an empty
%    cell array if the property does not have a finite set of possible string
%    values.
%
%    SET(OBJ)
%    PROP = SET(OBJ) displays or returns all property names and their possible
%    values for data acquisition object OBJ.  The return value, PROP, is a structure
%    whose field names are the property names of OBJ, and whose values are cell
%    arrays of possible property values or empty cell arrays.
%
%    Example:
%       ai = analoginput('winsound');
%       chan = addchannel(ai, [1 2]);
%       set(chan, {'ChannelName'}, {'One';'Two'});
%       set(chan, {'Units', 'UnitsRange'}, {'Degrees', [0 100]; 'Volts', [0 10]});
%       set(ai, 'SamplesPerTrigger', 2048)
%
%    See also DAQHELP, DAQDEVICE/GET, SETVERIFY, PROPINFO.
%

%    MP 3-26-98
%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.13.2.11 $  $Date: 2008/12/29 01:47:28 $

nout = nargout;
nin = nargin;
if nout > 1,
    error('daq:set:argcheck', 'Too many output arguments.')
end

% If obj is not a Data Acquisition object, call the builtin set.
% This is needed for:  set(gcf, 'UserData', chan);
if ~isa(obj, 'daqdevice')
    try
        builtin('set', obj, varargin{:});
    catch e
        error('daq:set:invalidobject', e.message)
    end
    return;
end

% Error if one of the objects is a copy of a deleted object.
if ~all(isvalid(obj))
    error('daq:set:invalidobject', 'Data acquisition object OBJ is an invalid object.');
end

% Try for the trivial case set(obj,p,v) where all inputs are scalars
if (nin==3 && ischar(varargin{1}) && nout==0)
    try
        set( daqgetfield(obj,'uddobject'), varargin{:} );
        return;
    catch e %#ok<NASGU>
        % Just keep going
    end
end

% Initialize variables.
try
    all_prop = get(obj);
catch e
    error('daq:set:properties', 'Unable to set values. Objects in the object array do not have identical properties.');
end
if ~iscell(all_prop)
    all_prop = {all_prop};
end
store_prop = {};


% Create the display
switch nin
case 0
        error('daq:set:argcheck', 'Not enough input parameters.');
case 1   % SET(OBJ)
        switch nout
            case 0
                % return the set display: set(obj)
                try
                    daqgate('privateSetList', obj);
                catch e
                    error('daq:set:unexpected', e.message)
                end
            case 1
                % return the set structure: h = set(obj)
                try
                    outputStruct = daqgate('privateSetList', obj);
                catch e
                    error('daq:set:unexpected', e.message)
                end
        end
        return
case 2   % SET(OBJ, PROP)
        % Check that prop is a valid property.
        try
            daqgate('privateCheckSetInput', varargin{1});
        catch e
            error('daq:set:unexpected', e.message);
        end
        
        % Error if PROP is a cell.
        if iscell(varargin{1})
            error('daq:set:invalidpvpair', 'Invalid parameter/value pair arguments.');
        end
        
        % If prop is a structure break the structure into property names
        % and property values with the call to localStructSet and loop through
        % the PV pairs.
        if isa(varargin{1}, 'struct')
            if nout ~= 0
                error('daq:set:lhs', 'A LHS argument cannot be used when assigning values.');
            end
            localStructSet(obj,varargin{1},all_prop,store_prop);
            return
        end
        
        switch nout
            case 0
                % return the possible property values display: set(obj, 'Name')
                try
                    daqgate('privateSetList', obj, varargin{1});
                catch e
                    localHandleError(obj, varargin{1}, e);
                end
            case 1
                % return the possible property values cell array: h = set(obj, 'Name')
                try
                    outputStruct = daqgate('privateSetList', obj, varargin{1});
                catch e
                    localHandleError(obj, varargin{1}, e);
                end
        end
        return;
end

% When assigning values an output argument cannot be supplied.
if nout ~= 0
    error('daq:set:lhs', 'A LHS argument cannot be used when assigning values.');
end

% Set the property values.  Initialize the index and loop through
% varargin and set the properties.
index = 1;

while index < nin
    prop = varargin{index};
    
    % Check that prop is a valid property.
    try
        daqgate('privateCheckSetInput', varargin{1});
    catch e
        error('daq:set:unexpected', e.message);
    end
    
    % If prop is a structure break the structure into property names
    % and property values with the call to localStructset and set the
    % PV pairs.  The index should be incremented by 1.
    if isstruct(prop)
        store_prop = localStructSet(obj,prop,all_prop,store_prop);
        index = index+1;
        % If prop is a string, the property value, val, should be the next
        % element in the list.  The index is incremented by 2.
    elseif ischar(prop)
        try
            val = varargin{index+1};
        catch e
            localRestore(obj,all_prop,store_prop);
            error('daq:set:invalidpvpair', 'Incomplete parameter/value pair arguments.');
        end
        index = index + 2;
        % It is not valid to do: set(obj, 'Name', {'sydney'})
        % UserData and callback properties can be set to a cell array.
        % Reset the old property values before erroring.
        if iscell(val) && ~(strncmpi(prop, 'userdata', length(prop)) || ...
                localIsCallback(obj, prop))
            localRestore(obj,all_prop,store_prop);
            if isempty(val)
                val = {''};
            end
            localHandleError(obj, prop,...
                MException('daq:set:unexpected','Type mismatch'))
        end
        
        if iscell(val)
            try
                localCheckSize(obj, {prop}, {val});
            catch e
                error('daq:set:unexpected', e.message);
            end
        end
        
        % Set the property value, val for all objects in obj
        x = struct(obj);
        for i = 1:length(obj)
            try
                store_prop = {store_prop{:} prop};
                
                % If a channel or line property, convert value to UDD object.
                if localIsChannel( x.uddobject(i), prop )
                    val = daqgate('privateMATLABToUDD', val );
                end
                set(x.uddobject(i), prop, val);
            catch e
                % Reset the old property values before erroring.
                localRestore(obj,all_prop,store_prop);
                localHandleError(obj, prop, e);
            end
        end
        % If prop is a cell, the property value, val should be the next
        % element in the list.  The index is incremented by 2 and nprop
        % is decremented by 2.
    elseif iscell(prop)
        try
            val = varargin{index+1};
        catch e
            localRestore(obj,all_prop,store_prop);
            error('daq:set:invalidpvpair', 'Incomplete parameter/value pair arguments.');
        end
        index = index+2;
        % If val is not a cell, an error occurs.
        % It is not valid to do: set(obj, {'Name'}, 'sydney')
        if ~iscell(val)
            % Reset the old property values before erroring.
            localRestore(obj,all_prop,store_prop);
            error('daq:set:invalidpvpair', 'Invalid parameter/value pair arguments.');
        else
            % Check the size of the PV pair to determine if a row vector
            % of property values was passed and if the number of property
            % names specified equals the number of property values specified.
            try
                localCheckSize(obj,prop,val);
            catch e
                % Reset the old property values before erroring.
                localRestore(obj,all_prop,store_prop);
                error('daq:set:unexpected', e.message);
            end
            % Reshape the val matrix.
            % set(obj, {'TimeOut'}, {3}) where obj is 1-by-10.
            val = localGetValue(obj,prop,val);
            
            % Set the properties.  Need to loop through prop in case multiple
            % properties were given.  Need to loop through obj in case an array
            % of device objects were passed.
            x = struct(obj);
            for j = 1:length(obj)
                for i = 1:length(prop)
                    if isempty(prop{i})
                        error('daq:set:invaliddata', 'Empty cells not allowed in cell array of parameter names.');
                    end
                    try
                        store_prop = {store_prop{:} prop{i}};
                        
                        % If a channel or line property, convert value to UDD
                        % object.
                        if localIsChannel( x.uddobject(j), prop{i} )
                            val{j,i} = daqgate('privateMATLABToUDD', val{j,i} );
                        end
                        
                        % Set the remaining properties.
                        if localIsCallback( x.uddobject(j), prop{i}) && length(prop)==1 && ischar(val)
                            set(x.uddobject(j), prop{i}, val);
                        else
                            set(x.uddobject(j), prop{i}, val{j,i});
                        end
                    catch e
                        % Reset the old property values before erroring.
                        localRestore(obj,all_prop,store_prop);
                        localHandleError(obj, prop{i},e);
                    end
                end
            end
        end
    end
end

% ***********************************************************
% Break sructure input argument into P-V pairs and set values.
function store_prop = localStructSet(obj,structure,all_prop,store_prop)

% Obtain the property names.
Pcell=fieldnames(structure);
store_prop = {store_prop{:} Pcell{:}};

% Obtain the property values.
Vcell=struct2cell(structure);

% Loop through the PV pairs and set them.
x = struct(obj);
for j = 1:length(obj)
    for i = 1:length(Pcell)
        
        % If a channel or line property, convert value to UDD object.
        if localIsChannel( x.uddobject(j), Pcell{i} )
            Vcell{i} = daqgate('privateMATLABToUDD', Vcell{i} );
        end
        
        % Check the size of the property value - for callback properties only.
        if localIsCallback( x.uddobject(j), Pcell{i})
            localCheckSize(obj, Pcell(i), Vcell(i));
        end
        
        % Try setting the property.
        try
            set(x.uddobject(j), Pcell{i}, Vcell{i});
        catch e
            % Get the bad property name.
            bad_prop = Pcell{i};
            % Restore the property values before erroring.
            localRestore(obj, all_prop,store_prop);
            localHandleError(obj,bad_prop,e);
        end
    end
end

% ************************************************************
% Determine the Callback properties.
function out = localIsCallback(obj,prop)

try
    pInfo = propinfo(obj, prop);
    out = strcmp(pInfo.Type, 'callback');
catch e %#ok<NASGU>
    out = 0;
end

% Determine the Callback properties.
function out = localIsChannel(obj,prop)

try
    pInfo = propinfo(obj, prop);
    out = strcmpi(pInfo.Type, 'channel') ||  strcmpi(pInfo.Type, 'line');
catch e %#ok<NASGU>
    out = 0;
end


% *****************************************************
% Throw error if the incorrect size arguments were passed to set.
function localCheckSize(obj, prop, val)

expand = 1;  % set(x, {'StartFcn'}, {'hello'}) where x is not 1-by-1.

numObjs = length(obj);
[r1,c1]=size(prop);
[r2,c2]=size(val);

% Check that the properties specified is either a row vector or a column
% vector.  A user cannot pass a matrix of property names to set.
if ~((r1 == 1) || (c1 == 1))
    error('daq:set:unexpected',...
        'A matrix of property names cannot be passed to SET.')
end

% The size of val must be numObjs-by-max(r1,c1) if scalar expansion
% is not done.
if (any(size(prop) ~= size(val)) || any(size(prop') ~= size(val)))
    expand = 0;
    if r2 ~= numObjs
        error('daq:set:unexpected','Size mismatch in Param Cell / Value Cell pair.')
    elseif c2 ~= max(r1,c1)
        error('daq:set:unexpected','Size mismatch in Param Cell / Value Cell pair.');
    end
end

% Determine if the Callbackl properties are set to valid values.
% Valid   : set(ai, {'StartFcn'}, {{'test', 5,6}});
% Invalid : set(ai, {'StartFcn'}, {{'test',5,5;'mytest',5,5}})
switch expand
    case 0
        for i = 1:length(prop)
            if localIsCallback(obj, prop{i})
                % Callback property.
                for j = 1:numObjs
                    if iscell(val{j,i})
                        [r3] = size(val{j,i});
                        if (r3~=1)
                            error('daq:set:unexpected',...
                                'Invalid value for ''%s''.\n ''%s'' may only be set to a string or a row cell array.',...
                                prop{i},prop{i})
                        end
                    end
                end
            end
        end
end

% ****************************************************
% Determine how to reshape the val matrix.
function val = localGetValue(obj, prop, val)

nval = numel(val);
nprop = length(prop);

% Determine how to reshape the Val matrix.  Dependent upon whether a
% specific value is passed for each device object or if the same value
% is passed to each device object.
if isequal(size(prop), size(val)) || isequal(size(val), size(prop'))
    tranflag = 1;
else
    tranflag = 0;
end

% If a there are multiple objects and a single value, repeat the value.
if (nval/nprop ~= length(obj))
    val = repmat(val, [1 length(obj)]);
end

%Reshape the Val matrix.
if tranflag
    val = reshape(val,nprop,length(obj))';
else
    val = reshape(val,length(obj),nprop);
end

%**********************************************************
% Reset the original property values since an error occurred
% while setting some PV pair.
function localRestore(obj, all_prop,store_prop)

% Obtain a unique list of properties that have been set.
store_prop = unique(store_prop);

x = struct(obj);

% Only restore if more than one property is set.  If the first property
% is being set to an invalid value it does not get set by the engine and
% therefore does not need to be restored.
if length(store_prop) > 1
    for j = 1:length(obj)
        
        % Obtain the property names.
        Pcell=fieldnames(all_prop{j});
        
        % Find the properties that have been set in the Pcell cell array.
        index =[];
        for i = 1:length(store_prop)
            index = [index find(strcmpi(store_prop{i}, Pcell))]; %#ok<AGROW>
        end
        
        % Index out only the properties that have been set.
        Pcell = Pcell(index);
        
        % Set the PV pairs.
        Vcell=struct2cell(all_prop{j});
        Vcell = Vcell(index);
        
        % Loop through the PV pairs and set them.
        for i = 1:length(Pcell)
            try
                % If a channel or line property, convert value to UDD object.
                if localIsChannel( x.uddobject(j), Pcell{i} )
                    Vcell{i} = daqgate('privateMATLABToUDD', Vcell{i} );
                end
                % Note: Do not need to fix "PsuedoDifferential" here because we
                % are simply resetting to the previously stored value which will
                % never be incorrect.
                set(x.uddobject(j), Pcell{i}, Vcell{i});
            catch e
                return;
            end
        end
    end
end

% *******************************************************************
% Throw an error for bad set.
function localHandleError(obj, prop, baseException)

x = struct(obj);

errmsg = lower(baseException.message);
if strcmp('testmeas:getset:ambiguousProperty', baseException.identifier)
    all_names = get(x.uddobject);
    all_names = fieldnames(all_names);
    all_names = sort(all_names);
    i = strmatch(lower(prop), lower(all_names));
    list = all_names(i);
    str = repmat('''%s'', ',1, length(list));
    str = str(1:end-2);
    throwAsCaller(MException('daq:set:unexpected',...
        ['Ambiguous %s property: ''%s''.\nValid properties: ' str '.'],...
        class(obj), prop, list{:}))
end

% If prop is a channel property, propinfo(obj, prop) will error out with invalid
% property message. To avoid generating this error and to catch the actual 
% error the following check is necessary.

% Handle the case of analoginput, analogoutput or a digitalio object.
if ((strcmp(class(obj), 'analoginput') || strcmp(class(obj), 'analogoutput') || strcmp(class(obj), 'digitalio')))
    % Go ahead only if it is an object property.
    if (max(strcmp(fieldnames(obj), prop)))
        
        % Get the property information and error if the property does not exist.
        try
            propstruct = propinfo(obj, prop);
            
        catch e
            errmsg = lower(e.message);
            if findstr('ambiguous', errmsg)
                all_names = get(x.uddobject);
                all_names = fieldnames(all_names);
                all_names = sort(all_names);
                i = strmatch(lower(prop), lower(all_names));
                list = all_names(i);
                str = repmat('''%s'', ',1, length(list));
                str = str(1:end-2);
                throwAsCaller(MException('daq:set:unexpected',...
                    ['Ambiguous %s property: ''%s''.\n',...
                    'Valid properties: ' str '.'],...
                    class(obj), prop, list{:}))
            else
                throwAsCaller(MException('daq:set:unexpected',...
                    'Invalid property: ''%s''.',prop))
            end
        end
        
        % Find complete property name.
        prop = findCompleteName(obj, prop);
        
        if (strcmp('testmeas:set:setDenied', baseException.identifier) ||...
                strcmp('testmeas:property:readOnly', baseException.identifier) || ...
                any(findstr('type mismatch', errmsg)) || ...
                strcmp('testmeas:set:invalidEnum', baseException.identifier))
            % Error appropriately depending on if the property is read-only, read-only
            % while running and if the property has an enumerated list or constraint values.
            if strcmp(propstruct.ReadOnly,'always')
                throwAsCaller(MException('daq:set:unexpected',...
                    'Attempt to modify read-only property: ''%s''.', prop))
            elseif strcmpi(propstruct.ReadOnly,'whileRunning') &&...
                    strcmpi(get(x.uddobject, 'Running'), 'on')
                throwAsCaller(MException('daq:set:unexpected',...
                    '%s: Property can not be set while Running is set to ''On''.', prop))
            else
                switch propstruct.Constraint
                    case 'enum'
                        throwAsCaller(MException('daq:set:unexpected',...
                            'Bad value for %s property: ''%s''.',class(obj), prop))
                    otherwise
                        throwAsCaller(MException('daq:set:unexpected',...
                            'Property value for ''%s'' must be a %s.', prop, propstruct.Type))
                end
            end
        end
    end
end

% Find if it is a valid object property
if strcmp(class(obj), 'aichannel') || strcmp(class(obj), 'aochannel')
    childString = 'Invalid channel property: ';
else
    if strcmp(class(obj), 'dioline')
        childString = 'Invalid line property: ';
    end
end

% Find if it is a valid channel\line property or object property.
if strcmp(class(obj), 'analoginput') || strcmp(class(obj), 'analogoutput')
    childText = 'OBJ.CHANNEL';
else
    if strcmp(class(obj), 'digitalio')
        childText = 'OBJ.LINE';
    end
end

if (strcmp(class(obj), 'aichannel') || strcmp(class(obj), 'aochannel') || strcmp(class(obj), 'dioline'))
    if max(strcmp(fieldnames(x.uddobject(1).Parent), prop))
        throwAsCaller(MException(baseException.identifier, '%s%s\nUse OBJ.%s\nUse PROPINFO(OBJ,''PROPERTY'') for more information on property.', childString, prop, prop ))
    end
end

if (strcmp('aichanprop',daqgate('privateChildPropList', prop, class(obj)))  || ...
        strcmp('aochanprop', daqgate('privateChildPropList', prop, class(obj))) || ...
        strcmp('diolineprop', daqgate('privateChildPropList', prop, class(obj))))
    throwAsCaller(MException(baseException.identifier, 'Invalid object property: %s\nUse %s.%s\nUse PROPINFO(%s, ''PROPERTY'') for more information on this property.', ...
    prop, childText, prop, childText))
    
end

% Convert UDD message to old dat message when the property is not valid.
if strcmp('testmeas:getset:invalidProperty', baseException.identifier)
    throwAsCaller(MException('daq:set:unexpected',...
        'Invalid property: ''%s''.',prop))
end

% Convert UDD message to old daq message when trying to set handle property
% Currently only valid for 'TriggerChannel'.
if strcmp('testmeas:set:scalarHandle', baseException.identifier)
    throwAsCaller(MException('daq:set:unexpected',...
        'Object must be a single object for property: ''%s''.',prop))
end

% If all else fails, rethrow the original error.
rethrow(baseException);

% ***********************************************************
% Find the complete property name.
function prop = findCompleteName(obj, prop)

 % Find complete property name.
 newprop = [];
 for i = 1:length(obj)
    allnames = fieldnames(get(get(obj,i)));
    propIndex = find(strncmpi(prop, allnames, length(prop)));
    if ~isempty(propIndex)
        newprop = allnames{propIndex(1)};
    end
    if ~isempty(newprop)
        break;
    end
 end

 % If a property was found - use it otherwise use the old value.
 if ~isempty(newprop)
    prop = newprop;
 end
