function obj = dioline(varargin)
%DIOLINE Construct digital io line.
%
%    To create lines, ADDLINE must be used.  If OBJ is a digital io
%    object, then the following command will create two input lines 
%    assigned to port 0 and hardware line IDs [0 1]:
%
%       addline(obj, 0:1, 0, 'in')%    
%
%    See also DAQHELP, ADDLINE.
%

%    CP 3-26-98
%    Copyright 1998-2009 The MathWorks, Inc.
%    $Revision: 1.11.2.8 $  $Date: 2009/12/31 18:44:50 $

%   OBJ = DIOLINE returns an dioline partially initialized 
%   object OBJ. This constructor is intended to be used by DAQMEX only.
%
%   OBJ = DIOLINE(UDD) returns an dioline object OBJ that
%   wraps the given UDD handle. This constructor is intended to be used 
%   by SUBSREF, SUBSASGN, and others.

%   Object fields
%      .uddobject  - uddobject associated with the channel.
%      .version    - class version number.

if nargin > 1,
   error('daq:dioline:argcheck', 'To create additional channels, use ADDCHANNEL.\nFor help type ''daqhelp addchannel''.');
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
   error('daq:dioline:argcheck', 'To create additional channels, use ADDCHANNEL.\nFor help type ''daqhelp addchannel''.');
end

obj.version = tlbx_version;

daqc = daqchild;
obj = class(obj, 'dioline', daqc);