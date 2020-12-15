function outflag = privateChildPropList(prop, objtype)
% PRIVATECHILDPROPLIST(PROP, OBJTYPE) returns the class of object as a 
% string. 
%
%   PRIVATECHILDPROPLIST(PROP, OBJTYPE) returns a string that is the class
%   of the object to which the property belongs. It can be analoginput, 
%   analogoutput or digitalio. If the property does not belong to any 
%   class of objects it returns a invalid property.

%   PRIVATECHILDPROPLIST(PROP, OBJTYPE) is a helper function for GET and
%   SET functions.
%
%   Copyright 2008 The MathWorks, Inc.

outflag = 'invalidproperty';

% List of all the analoginput channel properties.
aiChanProp = {'ChannelName', 'Coupling', 'HwChannel', 'Index', ...
    'InputRange', 'NativeOffset', ...
    'NativeScaling', 'Parent', 'SensorRange', ...
    'Type', 'Units', 'UnitsRange'};

% List of all the analogoutput channel properties.
aoChanProp = {'ChannelName', 'DefaultChannelValue', ...
    'HwChannel', 'Index', 'NativeOffset', ...
    'NativeScaling', 'OutputRange', 'Parent', ...
    'Type', 'Units', 'UnitsRange'};

% List of all the digitalio line properties.
dioLineProp = {'Direction', 'HwLine', 'Index', 'LineName', ...
    'Parent', 'Port', 'Type'};

if strcmp(objtype, 'analoginput')
    if max(strcmpi(prop, aiChanProp))
        outflag = 'aichanprop';
    end
end

if strcmp(objtype, 'analogoutput')
    if max(strcmpi(prop, aoChanProp))
        outflag = 'aochanprop';
    end
end

if(strcmp(objtype, 'digitalio'))
    if max(strcmpi(prop, dioLineProp))
        outflag = 'diolineprop';
    end
end




