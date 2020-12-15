function output=propinfo(varargin)
%PROPINFO Return property information for data acquisition objects.
%
%    OUT = PROPINFO(OBJ) returns a structure array, OUT, for all properties
%    of data acquisition object, OBJ.  OUT contains a field for each 
%    property of OBJ.  Each property field contains the following fields:
%
%         Type            - the property data type: 
%                           { 'any', 'callback', 'double', 'string', 'struct',
%                            'channel', 'line' }
%         Constraint      - constraints on property values:
%                           {'bounded', 'callback', 'enum', 'none'}
%         ConstraintValue - a list of valid string values or a range of
%                           valid values.
%         DefaultValue    - the default value for the property.
%         ReadOnly        - the condition under which a property is read-only:
%                          'always'         - property cannot be configured.
%                          'whileRunning'   - property cannot be configured 
%                                             while Running is set to on.
%                          'never'          - property can always be configured.
%         DeviceSpecific  - 1 if the property is device specific, 
%                           0 if the property is not device specific.
%
%    OBJ must be a 1-by-1 data acquisition object.
%
%    OUT = PROPINFO(OBJ, 'PROPERTY') returns a structure, OUT, for the 
%    property specified by PROPERTY. If PROPERTY is a cell array of strings,
%    a cell array of structures is returned.
%
%    Example:
%      ai = analoginput('winsound');
%      out = propinfo(ai);
%      out1 = propinfo(ai, 'SampleRate');
%
%    See also DAQHELP.
%

%   DTL 9-1-2004
%   Copyright 1998-2008 The MathWorks, Inc.
%   $Revision: 1.9.2.7 $  $Date: 2008/06/16 16:35:04 $

% Verify correct number of output arguments
if nargout > 1,
   error('daq:propinfo:argcheck', 'Too many output arguments.')
end

% Verify correct number of input arguments
if ( nargin == 0 )
   error('daq:propinfo:invalidobject', 'A valid data acquisition object must be passed to PROPINFO.')
end

if ( nargin > 2 )
   error('daq:propinfo:argcheck', 'Too many inputs passed to PROPINFO.')
end
   
% Determine if an invalid object was passed.
obj = varargin{1};
if ~all(isvalid(obj))
   error('daq:propinfo:invalidobject', 'Data acquisition object OBJ is an invalid object.');
end

% Verify it is a daq object
if ~( isa(obj,'daqdevice') || isa(obj,'daqchild') )
   error('daq:propinfo:argcheck', 'The first input argument OBJ must be a data acquisition object.')
end

% Get underlying uddobject.
% NOTE: Old DAQ code allowed more than one object but returned the
% propinfo of the last object. Duplicate this behavior.
x = struct( obj );
uddobj = x.uddobject;
if ( length(uddobj) > 1 )
   uddobj = uddobj(length(uddobj));
end
      
if ( nargin == 1 )
   try
      % Call UDD propinfo
      output = daqgate('privateUDDToMATLAB', propinfo( uddobj ) );
   catch e
      error('daq:propinfo:unexpected', e.message)
   end   
elseif ( nargin == 2 )
   try
      if iscellstr(varargin{2}),
         for i=1:length(varargin{2})
            % Call UDD propinfo 
            output{i} = daqgate('privateUDDToMATLAB', propinfo( uddobj, varargin{2}{i} ) ); %#ok<AGROW>
         end
      elseif ischar(varargin{2}),
          % Call UDD propinfo 
         output = daqgate('privateUDDToMATLAB', propinfo( uddobj, varargin{2} ) );
      else
         error('daq:propinfo:invalidproperty','PROPERTY must be a single string or a cell array of strings.')
      end
   catch e
      error('daq:propinfo:unexpected', e.message)
   end  
end   

   
   