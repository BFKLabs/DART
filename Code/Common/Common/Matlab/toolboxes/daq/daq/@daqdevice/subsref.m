function result = subsref(Obj, Struct)
%SUBSREF Reference into data acquisition objects.
%
%    Supported syntax for device objects:
%    a = ai.SampleRate;           calls    get(ai,'SampleRate');
%    a = ai.Channel;              calls    get(ai,'Channel');
%    a = ai.Channel(1:2);         calls    get(ai,'Channel',[1 2]);
%    a = ai.Channel(3).Units;     calls    get(get(ai,'Channel',3), 'Units');
%    a = ai.Channel.Units;        calls    get(get(ai,'Channel'), 'Units');
%    a = obj(1:3);                calls    get(obj,[1:3]);
%    a = obj(1:2).SampleRate;     calls    get(get(obj,[1:2]),'SampleRate');
%    a = obj(1:2).Channel;        calls    get(get(obj,[1:2]),'Channel');
%    a = obj(2).Channel(1:2);     calls    get(get(obj,2),'Channel',[1 2]);
%    a = obj(1).Channel(3).Units; calls    get(get(get(obj,1),'Channel',3), 'Units');
%    a = obj(2).Channel.Units;    calls    get(get(get(obj,1),'Channel'), 'Units');
%    a = obj([true false]);       calls    get(obj,[true false]);
%    a = obj([false false]);      returns  [];
%    a = obj([]);                 returns  [];
%
%    Supported syntax for channels or lines:
%    a = obj.Units;               calls    get(obj,'Units');
%    a = obj(1:2).SensorRange;    calls    get(obj(1:2),'SensorRange');
%
%    See also DAQDEVICE/GET, ANALOGINPUT, ANALOGOUTPUT, DIGITALIO, PROPINFO,
%    ADDCHANNEL, ADDLINE.
%

%    MP 2-25-98
%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.13.2.12 $  $Date: 2008/12/04 22:26:25 $

% Initialize variables
StructL = length(Struct);
isColon = 0;

% Parse the input.
% x = [ai1 ai2];
% x(2).Channel(1).ChannelName returns
% INDEX1 = 2, PROP1 = 'Channel',INDEX2 = 1, PROP2 = 'ChannelName'
try
    [prop1,index1,prop2,index2]=daqgate('privateparsedevice',Obj,Struct);
catch e
    error('daq:subsref:unexpected', e.message)
end

if ~isempty(index1)
    % Check for cell reference, which is invalid
    if(iscell(index1{1}))
        % They passed in a cell -- return the correct error message.
        error('daq:subsref:emptycell', 'Function ''subsref'' is not defined for values of class ''cell''.')
    end
    
    % Initialize index1 if it is a colon (e.g. ai(:) ),
    % or colon, colon e.g. ai(:,:) to the size of the device object array.
    if strcmp(index1{1}, ':')
        % Geck 170079: Check to see if it's the array expansion case.  If
        % so, set the flag to transpose the output at the end.
        if(numel(index1) == 1)
            isColon = 1;
        end
        index1 = {1:length(Obj)};
    end
    
    % Geck 170081 special case for array references that evaluate to empty.
    if isempty(index1{1})
        % They passed in [] -- Return [], like MATLAB and serial object does.
        % e.g. ai([]).
        result = [];
        return;
    end
end

% From the parsed input, obtain the information.
switch StructL
case 1
        % result is a property value of an analoginput\analogoutput\digitalio
        % object. Ex. ai.SampleRate.
        try
            if ~isempty(prop1)
                % Ex. x.SampleRate
                %     INDEX1 = [], PROP1 = 'SampleRate', INDEX2 = [], PROP2 = '';
                result = get(Obj, prop1);
            elseif ~isempty(index1)
                % Ex. x(1:2)
                %     INDEX1 = {1:2}, PROP1 = '', INDEX2 = [], PROP2 = '';
                
                % Check to see that object is a vector array
                if length(index1{1}) ~= numel(index1{1})
                    error('daq:subsref:size', 'Only a row or column vector of device objects can be created.')
                end
                
                % Geck 142732:  Wrong error message Wrong error msg when index into DAQ objects.
                % Check to see that index is positive.
                if ~islogical(index1{1}) && any(index1{1} <= 0)
                    error('daq:subsref:positive', 'Subscript indices must either be real positive integers or logicals.')
                end
                
                if(any(index1{1} > length(Obj)))
                    error('daq:subsref:invalidindex', 'Index exceeds array dimensions.');
                end
                
                result = get(Obj, index1{1});
                
                % Convert the output to the correct size.
                n = size(Obj,2);
                if isColon || n == 1
                    result = result';
                end
            end
        catch e
            localHandleError(e);
        end
        
case 2
        if ~isempty(index1)
            % Ex. obj(1).Channel;
            %     INDEX1 = '{1}', PROP1 = 'Channel', INDEX2 = [], PROP2 = '';
            try
                
                % Check to see that object is a vector array
                if length(index1{1}) ~= numel(index1{1})
                    error('daq:subsref:size', 'Only a row or column vector of device objects can be created.')
                end
                
                try
                    parent = get(Obj, index1{1});
                catch e
                    error('daq:subsref:invalidindex', 'Index exceeds array dimensions.');
                end
                result = get(parent, prop1);
            catch e
                localHandleError(e)
            end
        elseif isempty(prop2)
            % Ex. ai.Channel(1:2).
            %     INDEX1 = [], PROP1 = 'Channel', INDEX2 = {1:2}, PROP2 = '';
            try
                chan = localGetChild(Obj, prop1, index2{1});
                result = chan;
            catch e
                localHandleError(e)
            end
        else
            % Ex. ai.Channel.SensorRange
            %     INDEX1 = [], PROP1 = 'Channel', INDEX2 = [], PROP2 = 'SensorRange';
            
            try
                % Initialize variables.
                result = cell(length(Obj),1);
                
                chan = get(Obj, {prop1});
                for i = 1:length(Obj)
                    if ~isa(chan{i}, 'daqchild')
                        % This is needed for when the ChannelName is the same as a property.
                        % Ex. ai.Name.SensorRange
                        chan{i} = localCheckChild(Obj,i,prop1);
                    end
                    result{i} = get(chan{i}, prop2);
                end
            catch caughtException
                newException = MException(caughtException.identifier, caughtException.message);
                throwAsCaller(newException)
            end
            
            % Return a non-cell array if the object is 1-by-1.
            if length(Obj) == 1
                result = result{:};
            end
        end
case 3
        if ~isempty(index1)
            if ~isempty(index2)
                % Ex. x(1).Channel(1)
                %     INDEX1 = {1}, PROP1 = 'Channel', INDEX2 = {1}, PROP2 = '';
                try
                    % Check to see that object is a vector array
                    if length(index1{1}) ~= numel(index1{1})
                        error('daq:subsref:size','Only a row or column vector of device objects can be created.')
                    end
                    
                    try
                        parent = get(Obj, index1{1});
                    catch e
                        error('daq:subsref:invalidindex', 'Index exceeds array dimensions.');
                    end
                    result = get(parent, prop1, index2{1});
                catch e
                    localHandleError(e)
                end
            else
                % Ex. x(1).Channel.ChannelName
                %     INDEX1 = {1}, PROP1 = 'Channel', INDEX2 = [], PROP2 = 'ChannelName';
                try
                    % Initialize variables.
                    result = cell(length(index1{1}),1);
                    
                    % Get the channels.
                    try
                        parent = get(Obj, index1{1});
                    catch e
                        error('daq:subsref:invalidindex', 'Index exceeds array dimensions.');
                    end
                    chan = get(parent, {prop1});
                    
                    % Get the Channel's property value.
                    for i = 1:length(result)
                        if ~isa(chan{i}, 'daqchild')
                            % Needed for when the ChannelName is the same as a property.
                            % Ex. ai.Name.SensorRange
                            chan{i} = localCheckChild(Obj,i,prop1);
                        end
                        result{i} = get(chan{i}, prop2);
                    end
                catch e
                    localHandleError(e)
                end
                
                % Return a non-cell array if x(index1) is 1-by-1.
                if length(index1{1}) == 1
                    result = result{:};
                end
            end
        else
            % ai.Channel(1).ChannelName
            %     INDEX1 = [], PROP1 = 'Channel', INDEX2 = {1}, PROP2 = 'ChannelName';
            try
                chan = localGetChild(Obj, prop1, index2{1});
            catch e
                localHandleError(e)
            end
            
            try
                % Get the channel properties.
                if length(Obj) > 1
                    result = cell(length(Obj),1);
                    for i = 1:length(result)
                        result{i} = get(chan{i}, prop2);
                    end
                else
                    result = get(chan, prop2);
                end
            catch e
                localHandleError(e)
            end
        end
case 4
        % Ex. obj(1).Channel(1).ChannelName
        %     INDEX1 = {1}, PROP1 = 'Channel', INDEX2 = {1}, PROP2 = 'ChannelName';
        try
            % Get the channels.
            
            % Check to see that object is a vector array
            if length(index1{1}) ~= numel(index1{1})
                error('daq:subsref:size', 'Only a row or column vector of device objects can be created.')
            end
            
            try
                parent = get(Obj, index1{1});
            catch e
                error('daq:subsref:invalidindex', 'Index exceeds array dimensions.');
            end
            
            try
                chan = localGetChild(parent, prop1, index2{1});
            catch e
                localHandleError(e)
            end
            
            % Get the Channel property values.
            if length(parent) > 1
                result = cell(length(index1{1}),1);
                for i = 1:length(result)
                    result{i} = get(chan{i}, prop2);
                end
            else
                result = get(chan, prop2);
            end
        catch e
            localHandleError(e)
        end
otherwise
        error('daq:subsref:invalidsyntax', 'Invalid syntax: Too many subscripts.')
end

% *************************************************************************
% Get the requested channel array.
function chan = localGetChild(Obj, prop1, index2)

% Initialize variables.
chan = [];

% Error if a property other than Channel/Line is indexed into.
if isempty(find(strncmpi(prop1, {'channel', 'line'}, length(prop1)), 1))
    error('daq:subsref:unexpected','Inconsistently placed ''()'' in subscript expression.');
end

% Determine if the colon operator is used otherwise length test will fail.
% Code is in a try to handle ai.C(1) and C is ambiguous.
if ~strcmp(index2,':')
    lengthObj = length(get(Obj, prop1));
    if index2>lengthObj
        propname = lower(prop1);
        propname(1) = upper(propname(1));
        error('daq:subsref:unexpected',...
            'Index out of range for the ''%s'' property.\nThe %s array contains %d %s(s).',...
            propname, propname,lengthObj, prop1)
    end
end

% Get the specified channel array. (ai.Channel(1:2)).
try
    chan = get(Obj, prop1, index2);
catch e
    error('daq:subsref:unexpected',e.message)
end

% ******************************************************************************
% Get the correct channel - needed if the ChannelName is the same as a property.
function chan = localCheckChild(Obj,i,prop1)

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
        nonStructureException = MException('daq:subsref:fieldofnonstructurearray','Attempt to reference field of non-structure array.');
        throw(nonStructureException)
    end
catch caughtException
    newException = MException('daq:subsref:unexpected',caughtException.message);
    throwAsCaller(newException)
end

% *************************************************************************
% Remove any extra carriage returns.
function localHandleError(e)

% Initialize variables.
errmsg = e.message;

% Remove the trailing carriage returns from errmsg.
while errmsg(end) == sprintf('\n')
    errmsg = errmsg(1:end-1);
end

throwAsCaller(MException(e.identifier, errmsg))

