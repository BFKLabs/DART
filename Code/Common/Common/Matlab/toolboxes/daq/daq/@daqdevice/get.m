function output = get(obj, varargin)
%GET Get data acquisition object properties.
%
%    V = GET(OBJ,'Property') returns the value, V, of the specified property
%    for data acquisition object OBJ.  If Property is replaced by a
%    1-by-N or N-by-1 cell array of strings containing property names,
%    then GET will return a 1-by-N cell array of values.  If OBJ is a
%    vector of data acquisition objects, then V will be a M-by-N cell array
%    of property values where M is equal to the length of OBJ and N is equal
%    to the number of properties specified.
%
%    GET(OBJ) displays all property names and their current values for
%    data acquisition object OBJ.
%
%    V = GET(OBJ) returns a structure, V, where each field name is the name
%    of a property of OBJ and each field contains the value of that property.
%
%    Example:
%       ai = analoginput('winsound');
%       addchannel(ai, [1 2]);
%       chan = get(ai,'Channel')
%       get(ai,{'SampleRate','TriggerDelayUnits'})
%       get(ai)
%       get(chan, 'Units')
%       get(chan(1), {'HwChannel';'ChannelName'})
%
%    See also DAQHELP, DAQDEVICE/SET, SETVERIFY, PROPINFO.
%

%    MP 2-25-98
%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.12.2.11 $  $Date: 2008/12/04 22:26:21 $

ArgChkMsg = nargchk(1,3,nargin);
if ~isempty(ArgChkMsg)
    error('daq:get:argcheck', ArgChkMsg);
end

if nargout > 1
    error('daq:get:argcheck', 'Too many output arguments.')
end

% Error appropriately if a user calls get(1,ai);
if ~isa(obj, 'daqdevice')
    try
        builtin('get', obj, varargin{:});
    catch e
        error('daq:get:unexpected', e.message);
    end
    return;
end

% Switch on the number of inputs
switch nargin
case 1   % get(obj);
        % Error if an object is invalid.
        if ~all(isvalid(obj))
            error('daq:get:invalidobject', 'Data acquisition object OBJ is an invalid object.');
        end
        
        if (~nargout) && (length(obj)>1)
            error('daq:get:invalidsize', 'Vector of objects not permitted for GET(OBJ) with no left hand side.');
        end
        
        % Build up the structure of property names and property values.
        % Each column of the structure corresponds to a different object.
        x = struct(obj);
        out = cell(length(obj),1);
        for i = 1:length(obj)
            try
                % Do the get, and convert any UDD Objects to OOPS objects in the
                % returned structure.
                out{i} = daqgate('privateUDDToMATLAB', get(x.uddobject(i)) );
            catch e
                error('daq:get:unexpected', e.message);
            end
        end
        
        % If there are no output arguments construct the GET display.
        if nargout == 0
            try
                daqgate('getdisplay', obj, out{:});
            catch e
                error('daq:get:unexpected', e.message);
            end
        else
            % Must sort fields of each structure
            firstfields = fieldnames(out{1});
            [sorted, ind] = sort(lower(firstfields));
            for i = 1:length(obj)
                % Test that fields are the same for each structure
                fields = fieldnames(out{i});
                if i > 1 && ~isempty(setxor(firstfields, fields))
                    error('daq:get:properties', 'All objects in OBJ must have the same properties.')
                end
                
                % Reorder the fields to the desired order.
                output(i) = orderfields( out{i}, ind ); %#ok<AGROW>
            end
        end
case 2   % get(obj, 'Property') | get(obj, {'Property'})
        prop = varargin{1};
        
        % Special cases when called from subsref or subsasgn. GET(OBJARRAY,INDEXARRAY)
        % Indexing into the array could not be handled by subsref or subsasgn
        % since '()' would call the default subsref which did not do the correct
        % thing.
        if ( isa(prop, 'logical') )
            newprop = [];
            for i = 1:length(prop)
                if ( prop(i) )
                    newprop = [newprop i]; %#ok<AGROW>
                end
            end
            prop = newprop;
            
            % Geck 142732:  Wrong error message Wrong error msg when index into DAQ
            % objects. Check to see that the result of this is an empty (i.e.
            % didn't find anything.
            if isempty(prop)
                % yes, prop is empty -- return it.
                output = prop;
                return;
            end
            
        end
        
        if ( isa(prop, 'double') )
            % Create the first object.
            try
                output = localCreateParent(obj,prop(1));
                
                % Append the device objects to the output array.
                for i = 2:length(prop)
                    output = [output localCreateParent(obj,prop(i))]; %#ok<AGROW>
                end
            catch e
                error('daq:get:invalidargument',...
                    'Second input argument of GET must contain a valid property\nname or a cell array containing valid property names.');
            end
            % Normal case when prop is a string or a cell array of strings.
        else
            % Error if an object is invalid.
            if ~all(isvalid(obj))
                error('daq:get:invalidobject', 'Data acquisition object OBJ is an invalid object.');
            end
            
            try
                uddobjs = daqgetfield(obj, 'uddobject');
                % Do the get, and convert any UDD Objects to OOPS objects in the
                % returned value.
                output = daqgate('privateUDDToMATLAB', get(uddobjs, prop) );
            catch e
                localHandleError(obj(1),e);
            end
        end
        
case 3
        % Error if an object is invalid.
        if ~all(isvalid(obj))
            error('daq:get:invalidobject', 'Data acquisition object OBJ is an invalid object.');
        end
        
        % Getting Channel/Line info:
        % get(ai, 'Channel', [1 3])  OR
        % get(ai, 'Channel', ':')
        prop = varargin{1};
        index = varargin{2};
        
        % Prepare empty output
        output = cell(length(obj),1);
        
        % For each parent object
        parentuddobjects = daqgetfield(obj,'uddobject');
        for i = 1:length(parentuddobjects)
            
            parentudd = parentuddobjects(i);
            
            % See if the given property is the channel friendly name
            channelName = getchannelfriendlyname(parentudd);
            if ~strcmpi(prop, channelName)
                error('daq:get:unexpected', 'Invalid property: ''%s''.', prop)
            end
            
            % Handle the colon operator.  If the colon operator is entered
            % as the index, the index contains all channels.
            if strcmp(index,':')
                try
                    index = 1:length(get(parentudd,channelName));
                catch e
                    localHandleError(obj(1),e);
                end
            end
            
            % Obtain the first channel object in the children list.
            try
                resultudd = getchannel(parentudd, index(1));
                result = daqgate('privateUDDToMATLAB', resultudd);
            catch e
                localHandleError(obj(index(1)),e);
            end
            
            % Concatenate the remaining channels to the output.
            for j = 2:length(index)
                try
                    resultudd = getchannel(parentudd, index(j));
                    result =  [result; daqgate('privateUDDToMATLAB', resultudd)]; %#ok<AGROW>
                catch e
                    localHandleError(obj(index(j)),e);
                end
            end
            output{i} = result;
        end
        
        if length(obj) == 1
            output = output{:};
        else
            % Create output that is a 1 x n struct with fields
            try
                output = [output{:}];
            catch e
                if (findstr(e.message, 'CAT arguments are not consistent in structure field number.'))
                    error('daq:get:properties', 'All objects in OBJ must have the same properties.');
                end
            end
        end
end
% *************************************************************************
% Create the parent object.
function parent = localCreateParent(Obj, index1)

% Recreate the device object.  Ex. obj(1)
structinfo = struct(Obj);
parent = daqgate('privateUDDToMATLAB', structinfo.uddobject(index1) );

% *******************************************************************
% Throw an error for ambiguous get.
function localHandleError(obj,e)

% Find the property that caused the error
quotes = strfind( e.message, '''' );
if ( length(quotes) < 2 )
    prop = 'Unknown';
else
    prop = e.message(quotes(1)+1:quotes(2)-1);
end

if strcmp('testmeas:getset:ambiguousProperty', e.identifier)
    all_names = get(daqgetfield(obj,'uddobject'));
    all_names = fieldnames(all_names);
    all_names = sort(all_names);
    i = strmatch(lower(prop), lower(all_names));
    list = all_names(i);
    str = repmat('''%s'', ',1, length(list));
    str = str(1:end-2);
    throwAsCaller(MException('daq:get:unexpected',...
        ['Ambiguous %s property: ''%s''.\nValid properties: ' str '.'],...
        class(obj), prop, list{:}))
end

% Find if it is a valid channel\line property or object property.
if strcmp(class(obj), 'analoginput') || strcmp(class(obj), 'analogoutput')
    childText = 'OBJ.CHANNEL';
else
    if strcmp(class(obj), 'digitalio')
    childText = 'OBJ.LINE';
    end
end

if (strcmp('aichanprop',daqgate('privateChildPropList', prop, class(obj)))  || ...
        strcmp('aochanprop', daqgate('privateChildPropList', prop, class(obj))) || ...
        strcmp('diolineprop', daqgate('privateChildPropList', prop, class(obj))))
    throwAsCaller(MException(e.identifier, 'Invalid object property: %s\nUse %s.%s\nUse PROPINFO(%s, ''PROPERTY'') for more information on this property.', ...
    prop, childText, prop, childText))
    
end

if strcmp('testmeas:getset:invalidProperty', e.identifier)
    throwAsCaller(MException('daq:get:unexpected',...
    'Invalid property: ''%s''.', prop))
end

% If all else fails, rethrow the original error.
throwAsCaller(MException('daq:get:unexpected',e.message))



