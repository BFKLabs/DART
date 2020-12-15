function out = propinfo(obj, prop)
%PROPINFO Return image acquisition object property information.
%
%    OUT = PROPINFO(OBJ) returns a structure array, OUT, with field 
%    names given by the property names for OBJ. Each property name 
%    in OUT contains a structure with the fields:
%
%      Type              - the property data type: 
%                          {'any', 'callback', 'double', 'string', 'struct'}
%      Constraint        - constraints on property values:
%                          {'bounded', 'callback', 'enum', 'none'}
%      ConstraintValue   - a list of valid string values or a range of
%                          valid values.
%      DefaultValue      - the default value for the property.
%      ReadOnly          - the condition under which a property is read-only:
%                          'always'         - property cannot be configured.
%                          'whileRunning'   - property cannot be configured 
%                                             while Running is set to on.
%                          'never'          - property can always be configured.
%      DeviceSpecific    - 1 if the property is device specific, 
%                          0 if the property is not device specific.
%
%    OBJ must be a 1-by-1 image acquisition object.
%
%    OUT = PROPINFO(OBJ, 'PROPERTY') returns a structure, OUT, for the 
%    property specified by PROPERTY. If PROPERTY is a cell array of strings,
%    a cell array of structures is returned.
%
%    Example:
%      obj = videoinput('matrox', 1);
%      out = propinfo(obj);
%      out1 = propinfo(obj, 'LoggingMode');
%
%    See also IMAQHELP.
%

%    CP 9-01-01
%    Copyright 2001-2010 The MathWorks, Inc.

% Error checking.
if ~isa(obj, 'imaqdevice')
    error(message('imaq:propinfo:invalidType'));
elseif (length(obj) > 1)
    error(message('imaq:propinfo:OBJ1x1'));
elseif ~isvalid(obj),
    error(message('imaq:propinfo:invalidOBJ'));
end

% Extract the UDD object and get the property information.
uddobj = imaqgate('privateGetField', obj, 'uddobject');
try
    switch nargin,
        case 1,
            out = propinfo(uddobj);
        case 2,
            out = propinfo(uddobj, prop);
    end
catch exception
    throw(exception)
end
