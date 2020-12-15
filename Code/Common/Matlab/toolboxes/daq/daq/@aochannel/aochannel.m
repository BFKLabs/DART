function obj = aochannel(varargin)
%AOCHANNEL Construct analog output channel.
%
%    To create channels, ADDCHANNEL must be used.  If OBJ is an analog
%    output object, then the following command will create two channels
%    assigned to hardware channel IDs [1 2]:
%
%       addchannel(OBJ, [1 2])
%
%    See also DAQHELP, ADDCHANNEL.
%

%    DTL 9-1-2004
%    Copyright 1998-2009 The MathWorks, Inc.
%    $Revision: 1.10.2.7 $  $Date: 2009/12/31 18:44:42 $

%   OBJ = AOCHANNEL returns an aochannel partially initialized 
%   object OBJ. This constructor is intended to be used by DAQMEX only.
%
%   OBJ = AOCHANNEL(UDD) returns an aochannel object OBJ that
%   wraps the given UDD handle. This constructor is intended to be used 
%   by SUBSREF, SUBSASGN, and others.

%   Object fields
%      .uddobject  - uddobject associated with the channel.
%      .version    - class version number.

if nargin > 1,
   error('daq:aochannel:argcheck', 'To create additional channels, use ADDCHANNEL.\nFor help type ''daqhelp addchannel''.');
end

tlbx_version=2.0;


% DAQMEX is calling the constructor.
if ( nargin==0 ) 
   obj.uddobject = handle(0);
% MATLAB code is calling the constructor
elseif ( nargin==1 && ...
         (strcmp(class(varargin{1}),'handle') || ...
          ~isempty(strfind( class(varargin{1}), 'daq.'))) )
   obj.uddobject = varargin{1};
else   
   error('daq:aochannel:argcheck', 'To create additional channels, use ADDCHANNEL.\nFor help type ''daqhelp addchannel''.');
end

obj.version = tlbx_version;

daqc = daqchild;
obj = class(obj, 'aochannel', daqc);