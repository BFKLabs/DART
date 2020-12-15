function out = horzcat(varargin)
%HORZCAT Horizontal concatenation of data acquisition objects.

%    MP 5-12-98
%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.10.2.6 $  $Date: 2008/06/16 16:34:29 $

% Determine if the objects are valid and have the same parent.
valid_parent = daqgate('privatecheckparent', varargin);
if valid_parent == 1
   error('daq:horzcat:badparent', 'Only objects with the same parent are permitted to be concatenated.');
elseif valid_parent == 2
   error('daq:horzcat:invalidobject', 'Invalid object.');
end

%Concatenate the handles of each input into one object.
c=[];
for i = 1:nargin
   if ~isempty(varargin{i}),
      if isempty(c),
         c=varargin{i};
      else
         try
            c.uddobject = [c.uddobject varargin{i}.uddobject];
         catch e
            error('daq:horzcat:unexpected', e.message);
         end
      end      
   end
end

% Determine if a matrix of channels was constructed if so error
% since only vectors are allowed.
if length(c.uddobject) ~= numel(c.uddobject) 
   error('daq:horzcat:size', 'Only a row or column vector of channels can be created.')
end

% Assign the new channel vector to the output.  
out = c;
