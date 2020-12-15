function [obj, Fs] = privateDemoObj(subsystem, adaptor, id, chanID, sampleRate)
%PRIVATEDEMOOBJ Create requested data acquisition object.
%
%    [OBJ, FS, ERRFLAG] = PRIVATEDEMOOBJ(SUBSYSTEM,ADAPTOR,ID,CHANID,FS) 
%    creates a subsystem data acquisition object, OBJ, for adaptor, ADAPTOR 
%    and id, ID.  The channels, CHANID are added to OBJ.  The SampleRate of
%    OBJ is set to FS and returned.
%
%    PRIVATEDEMOOBJ is a helper function for DAQPLAY and DAQRECORD.
%

%    MP 01-12-98
%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.8.2.7 $  $Date: 2008/06/16 16:36:00 $

% Determine the channel id.
if isempty(chanID)
   switch lower(adaptor)
   case {'winsound'}
      chanID = 1;
   case {'nidaq','mcc'}
      chanID = 0;
   end
end

% Create and configure the object.
obj = feval(subsystem, adaptor, id);
try
    addchannel(obj, chanID);  

    if exist('sampleRate','var'),
      try
         setverify(obj, 'SampleRate', sampleRate);
      catch e %#ok<NASGU>
         warning('daq:demoobj:sampleratedefault', ['Unable to set SampleRate to ' num2str(sampleRate) '. Using default value.'])
      end
    end

    Fs=obj.SampleRate;
catch e
    delete(obj)
    rethrow(e)
end
