function Obj = subsasgn(Obj, Struct, Value)
%SUBSASGN Assign into data acquisition object.
%
%    Supported syntax for device objects:
%    ai.samplerate=1000;
%       calls set(ai,'samplerate',1000);
%    ai.channel = ch;
%       calls set(ai,'channel',ch);
%    ai.channel.units = 'Temp';
%       calls set(get(ai, 'Channel'), 'Units', 'Temp');
%    ai.channel(1:3) = ch;
%       calls set(get(ai, Channel, 1:3), 'Channel', ch);
%    ai.channel(3).Units='Temp';
%       calls set(get(ai, 'Channel', 3), 'Units', 'Temp');
%
%    obj(1).samplerate=1000;
%       calls set(get(obj,1),'samplerate',1000);
%    obj(1).channel = ch;
%       calls set(get(obj,1),'channel',ch);
%    obj(1).channel.units = 'Temp';
%       calls set(get(get(obj,1), 'Channel'), 'Units', 'Temp');
%    obj(1).channel(1:3) = ch;
%       calls set(get(get(obj,1), Channel, 1:3), 'Channel', ch);
%    obj(1).channel(3).Units='Temp';
%       calls set(get(get(obj,1), 'Channel', 3), 'Units', 'Temp');
%
%    Supported syntax for channels or lines:
%    aic.Units = 'Degrees';
%       calls  set(aic, 'Units', 'Degrees');
%    aic(1:2).Units = Degrees;
%       calls  set(aic(1:2), 'Units', 'Degrees');
%    aic(1:2) = ch;
%       calls  set(get(aic, 'Parent'), 'Channel', ch);
%
%    See also DAQDEVICE/SET, ANALOGINPUT, ANALOGOUTPUT, DIGITALIO, PROPINFO,
%    ADDCHANNEL, ADDLINE.
%

%    MP 2-25-98
%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.12.2.13 $  $Date: 2008/12/04 22:26:24 $

if isempty(Obj)
    % Ex. ai(1) = analoginput('winsound');
    if isequal(Struct.type, '()') && isequal(Struct.subs{1}, 1:length(Value))
        Obj = Value;
        return;
    elseif ~isa(Obj,'daqdevice') && ~isa(Struct.subs,'cell'),
        Obj=builtin('subsasgn',Obj,Struct,Value);
        return
    elseif length(Value) ~= length(Struct.subs{1})
        % Ex. ai(1:2) = analoginput('winsound');
        error('daq:subsasgn:invalidassignment', 'In an assignment A(I)=B, the number of elements in B and I must be the same.');
    elseif Struct.subs{1}(1) <= 0
        error('daq:subsasgn:invalidindex', 'Index into matrix is negative or zero.');
    else
        % Ex. ai(2) = analoginput('winsound'); where ai is originally empty.
        error('daq:subsasgn:invalidindex', 'Gaps are not allowed in device array indexing.');
    end
elseif ~isa(Obj,'daqdevice'),
    Obj=builtin('subsasgn',Obj,Struct,Value);
    return
end

% Initialize variables
StructL = length(Struct);

% Define possible error messages
error1 = 'Invalid syntax.  For help type ''daqhelp set''.';

% Parse the input.
% obj(2).Channel(1).ChannelName returns
% INDEX1 = 2; PROP1 = 'Channel'; INDEX2 = 1, PROP2 = 'ChannelName'
try
    [prop1,index1,prop2,index2] = daqgate('privateparsedevice',Obj,Struct);
catch e
    error('daq:subsasgn:unexpected', e.message)
end

% From the parsed input, the Value can be assigned to the correct property.
switch StructL
case 1
        % Ex. obj.SampleRate = 8000;
        % Ex. obj(1:2) = obj(2:-1:1);
        if ~isempty(prop1)
            % Ex. obj.SampleRate = 8000;
            %     INDEX1 = [], PROP1 = 'SampleRate', INDEX2 = [], PROP2 = '';
            try
                % Check the size of Value if prop1 is Channel.
                if ~isempty(find(strncmpi(prop1, {'channel', 'line'}, length(prop1)), 1))
                    try
                        localChildSize(Obj, prop1, Value);
                    catch e
                        error('daq:subsasgn:unexpected', e.message);
                    end
                end
                
                set(Obj, prop1, Value);
            catch e
                localHandleError(e);
            end
        elseif ~isempty(index1)
            % Ex. x(1) = ao;
            % Ex. x(1) = [];
            %     INDEX1 = {1}, PROP1 = '', INDEX2 = [], PROP2 = '';
            %
            % Ex. s(1) = [] and s is 1-by-1.
            if ((length(Obj) == 1) && isempty(Value))
                error('daq:subsasgn:useclear', 'Use CLEAR to remove the object from the workspace.');
            elseif ~(isa(Value, 'daqdevice') || isempty(Value))
                error('daq:subsasgn:onlydaqobjcat', 'Only data acquisition objects may be concatenated.');
            else
                try
                    Obj = localReplaceElement(Obj, index1, Value);
                catch e
                    localHandleError(e);
                end
            end
        end
case 2
        % Ex. x(1).Channel = channel;
        % Ex. x(1).SampleRate = 10000;
        % Ex. x.Channel(1:2) = chan2;
        if ~isempty(index1)
            % Ex. x(1).Channel = channel;
            % Ex. x(1).SampleRate = 10000;
            %     INDEX1 = {1}, PROP1 = 'Channel', INDEX2 = [], PROP2 = '';
            try
                % Error if trying to set a property to a cell array.
                % Ex. obj(1:2).SampleRate = {8000; 10000};
                if iscell(Value) && ~(strncmpi(prop1, 'userdata', length(prop1)) || ...
                        localIsCallback(Obj, prop1))
                    error('daq:subsasgn:invalidsyntax', error1);
                end
                
                % Get the indexed array of objects.
                try
                    parent = get(Obj, index1{1});
                catch e
                    error('daq:subsasgn:invalidindex', 'Index exceeds array dimensions.');
                end
                
                % Check the size of Value if prop1 is Channel.
                if ~isempty(find(strncmpi(prop1, {'channel', 'line'}, length(prop1)), 1));
                    try
                        localChildSize(parent, prop1, Value);
                    catch e
                        error('daq:subsasgn:unexpected', e.message);
                    end
                end
                
                set(parent, prop1, Value);
            catch e
                localHandleError(e);
            end
            
        elseif isempty(prop2)
            % Ex. ai.Channel(1:2) = chan2;
            %     INDEX1 = [], PROP1 = 'Channel', INDEX2 = {1:2}, PROP2 = '';
            try
                % To modify an objects channel property, the entire array must be
                % modified at once. Check for this by making sure that the indexing
                % into Channel returns the entire array.
                try
                    localChildSize(Obj, prop1, Value, index2{1});
                catch e
                    error('daq:subsasgn:unexpected', e.message);
                end
                
                set(Obj, prop1, Value);
            catch e
                localHandleError(e);
            end
        else
            % Multiple values cannot be assigned to objects with the dot notation.
            % ai.Channel.ChannelName = {'Temp1';'Temp2'}; - should fail.
            % ai.Channel.SensorRange = [-4 4]; - should work.
            %     INDEX1 = [], PROP1 = 'Channel', INDEX2 = [], PROP2 = 'SensorRange';
            if iscell(Value)
                error('daq:subsasgn:invalidsyntax', error1);
            end
            
            try
                % Get the channels/lines.
                chan = get(Obj, {prop1});
                
                for i = 1:length(Obj)
                    
                    % When setting Channel and Line properties provide an error
                    % message instructing the user to first add a channel/line if
                    % none exist.
                    if (strcmpi('Channel', prop1) || strcmpi('Line', prop1)) ...
                            && isempty(chan{i})
                        channelPropName = prop1;
                        error('daq:subsasgn:invalidsyntax', 'Property ''%s'' is empty. Call ADD%s before setting ''%s'' properties.',...
                            channelPropName, upper(channelPropName), channelPropName );
                    end
                    
                    if ~isa(chan{i}, 'daqchild')
                        % Needed for when the ChannelName is the same as a property.
                        % Ex. ai.Name.SensorRange
                        chan{i} = localCheckChild(Obj,i,prop1);
                    end
                    
                    set(chan{i}, prop2, Value);
                end
            catch e
                newException = MException(e.identifier,e.message);
                throwAsCaller(newException)
            end
        end
case 3
        if isempty(index1)
            % Multiple values cannot be assigned to objects with the dot notation.
            % ai.Channel(1:2).ChannelName = {'Temp1';'Temp2'}; - should fail.
            % ai.Channel(1).SensorRange = [-4 4]; - should work.
            %     INDEX1 = [], PROP1 = 'Channel', INDEX2 = {1}, PROP2 = 'SensorRange';
            if iscell(Value)
                error('daq:subsasgn:invalidsyntax', error1);
            end
            
            try
                % Get the channel objects
                try
                    chan = localGetChild(Obj, prop1, index2{1});
                catch e
                    localHandleError(e);
                end
                
                % Set the channel objects property (prop2) to Value.
                if length(Obj) > 1
                    for i = 1:length(chan)
                        set(chan{i}, prop2, Value);
                    end
                else
                    set(chan, prop2, Value);
                end
            catch e
                localHandleError(e);
            end
        elseif isempty(index2)
            % Ex. x(1).Channel.Units = 'one';
            %     INDEX1 = {1}, PROP1 = 'Channel', INDEX2 = [], PROP2 = 'Units';
            if iscell(Value)
                error('daq:subsasgn:invalidsyntax', error1);
            end
            
            try
                try
                    parent = get(Obj, index1{1});
                catch e
                    error('daq:subsasgn:invalidindex', 'Index exceeds array dimensions.');
                end
                chan = get(parent, {prop1});
                for i = 1:length(index1{1})
                    if ~isa(chan{i}, 'daqchild')
                        % This is needed for when the ChannelName is the same as a property.
                        % Ex. ai.Name.SensorRange
                        chan{i} = localCheckChild(Obj,i,prop1);
                    end
                    set(chan{i}, prop2, Value);
                end
            catch e
                localHandleError(e);
            end
        else
            % Ex. x(1).Channel(1) = ChannelArray;
            %     INDEX1 = {1}, PROP1 = 'Channel', INDEX2 = {1}, PROP2 = '';
            try
                try
                    parent = get(Obj, index1{1});
                catch e
                    error('daq:subsasgn:invalidindex', 'Index exceeds array dimensions.');
                end
                
                % To modify an objects channel property, the entire array must be
                % modified at once. Check for this by making sure that the indexing
                % into Channel returns the entire array.
                try
                    localChildSize(parent, prop1, Value, index2{1});
                catch e
                    error('daq:subsasgn:unexpected', e.message);
                end
                set(parent, prop1, Value);
            catch e
                localHandleError(e);
            end
        end
case 4
        % Ex. x(1).Channel(1).ChannelName = 'Sydney';
        %     INDEX1 = {1}, PROP1 = 'Channel', INDEX2 = {1}, PROP2 = 'ChannelName';
        try
            try
                parent = get(Obj, index1{1});
            catch e
                error('daq:subsasgn:invalidindex', 'Index exceeds array dimensions.');
            end
            
            try
                chan = localGetChild(parent, prop1, index2{1});
            catch e
                localHandleError(e);
            end
            
            if length(parent) == 1
                for i = 1:length(chan)
                    set(chan(i), prop2, Value);
                end
            else
                for i = 1:length(parent)
                    for j = 1:length(chan{i})
                        set(chan{i}(j), prop2, Value);
                    end
                end
            end
        catch e
            localHandleError(e);
        end
otherwise
        error('daq:subsasgn:invalidsyntax', 'Invalid syntax: Too many subscripts.')
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

% *************************************************************************
% Error if the given Value does not have the correct size and value for the
% channel array.
function localChildSize(Obj, prop1, Value, index)

% Determine the child type - channel or line.
daqinfo = daqgetfield(Obj, 'info');
childtype = lower(daqinfo.child);

if isempty(Value)
    error('daq:subsasgn:unexpected','To delete all %ss, use the DELETE command.',childtype);
elseif iscell(Value)
    error('daq:subsasgn:unexpected','Invalid syntax.  For help type ''daqhelp set''.');
else
    % Determine if each object's Channel array has the same length
    % as what it is being set to.
    chan = get(Obj, {prop1});
    for i = 1:length(chan)
        if nargin == 4
            if ~isequal(index, 1:max(index)) || ~isequal(length(chan{i}), length(index))
                error('daq:subsasgn:unexpected',...
                    'Individual %ss cannot be set.  An object''s entire %s\narray must be set to a %s array of the same size.',...
                    childtype, childtype,childtype)
            end
        end
    end
end

% ******************************************************************************
% Get the correct channel - needed if the ChannelName is the same as a property.
function chan = localCheckChild(Obj,i,prop1)

% Initialize variables.
chan = [];

% Handles the case where the ChannelName/LineName is the same as a property.
% Get all the channels/lines and find the one that matches the given
% ChannelName/LineName.
try
    parent = get(Obj, i);
    
    % Determine if the child is a channel or line.
    daqinfo = daqgetfield(Obj, 'info');
    childtype = daqinfo.child;
    
    % Get the child and find the correct one by comparing channelnames or
    % linenames.
    tempchan = get(parent, childtype);
    tempindex = strmatch(prop1, get(tempchan, {[childtype 'Name']}));
    if ~isempty(tempindex)
        chanudd = getchannel(daqgetfield(Obj,'uddobject'), tempindex(1));
        chan = daqgate('privateUDDToMATLAB', chanudd);
    else
        % This Property is not a structure array. Emit the same error
        % message you get when doing: >> x = 1, x.someField
        nonStructureException = MException('daq:subsasgn:fieldofnonstructurearray','Attempt to reference field of non-structure array.');
        throw(nonStructureException)
    end
catch e
    error('daq:subsasgn:unexpected', e.message);
end

% *************************************************************************
% Get the requested channel array.
function chan = localGetChild(Obj, prop1, index2)

% Initialize variables.
chan = [];

% Error if a property other than Channel/Line is indexed into.
if isempty(find(strncmpi(prop1, {'channel', 'line'}, length(prop1)), 1))
    error('daq:subsasgn:unexpected',...
        'Inconsistently placed ''()'' in subscript expression.');
end

% Determine if the colon operator is used otherwise length test will fail.
% Code is in a try to handle ai.C(1) and C is ambiguous.
try
    if ~strcmp(index2,':')
        lengthObj = length(get(Obj, prop1));
        if index2>lengthObj
            propname = lower(prop1);
            propname(1) = upper(propname(1));
            error('daq:subsasgn:unexpected',...
                'Index out of range for the ''%s'' property.\n', ...
                'The %s array contains %d %s(s).',...
                propname, propname,lengthObj, prop1)
        end
    end
catch e %#ok<NASGU>
end

% Get the specified channel array. (ai.Channel(1:2)).
try
    chan = get(Obj, prop1, index2);
catch e
    error('daq:subsasgn:unexpected',e.message)
end

% *************************************************************************
% Replace element of device array.
function obj = localReplaceElement(obj, index, Value)

% Initialize variables.
index = index{1};

% The following is illegal: x(1) = x(2:4)
if (length(index) ~= length(Value)) && ~(isempty(Value) || length(Value) == 1)
    error('daq:subsasgn:unexpected',...
        'In an assignment A(I)=B, the number of elements in B and I must be the same.');
end

% Get the current state of the object.
uddobjs = daqgetfield(obj, 'uddobject');
info = daqgetfield(obj, 'info');
version = daqgetfield(obj, 'version');

% Replace the specified index with Value.
if ~isempty(Value)
    uddobjs(index) = daqgetfield(Value, 'uddobject');
    info(index) = daqgetfield(Value, 'info');
    version(index) = daqgetfield(Value, 'version');
else
    uddobjs(index) = [];
    info(index) = [];
    version(index) = [];
end

% Assign the new state back to the original object.
obj = daqsetfield(obj, 'uddobject', uddobjs);
obj = daqsetfield(obj, 'info', info);
obj = daqsetfield(obj, 'version', version);

% Need to recast the object into the correct type.
% Ex. x = [ai ao]; x(1) = [].  Need to recast x so that is an
% analogoutput object rather than an analoginput object.
if length(uddobjs) == 1
    classname = lower(get(uddobjs, 'Type'));
    classname(find(classname == ' ')) = []; %#ok<FNDSB>
    obj = feval(classname, uddobjs );
end

% *************************************************************************
% Remove any extra carriage returns.
function localHandleError(e)

% Initialize variables.
errmsg = e.message;

% Remove the trailing carriage returns.
while errmsg(end) == sprintf('\n')
    errmsg = errmsg(1:end-1);
end

throwAsCaller(MException(e.identifier,errmsg))
