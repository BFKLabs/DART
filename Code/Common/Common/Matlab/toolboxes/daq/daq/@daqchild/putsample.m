function putsample(varargin)
%PUTSAMPLE Immediately output single sample to channel group.
%
%    PUTSAMPLE(OBJ, DATA) immediately outputs a row vector, DATA, containing
%    one sample for each channel contained by analog output object, OBJ.
%    OBJ must be a 1-by-1 analog output object.
%
%    PUTSAMPLE is valid for analog output processes only and can be called 
%    when OBJ is not running.
%
%    PUTSAMPLE is not supported for sound cards.
% 
%    See also DAQHELP, PUTDATA.
%

%    CP 4-10-98
%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.10.2.5 $  $Date: 2008/08/08 12:50:45 $

error('daq:putsample:invalidtype', 'Wrong object type passed to PUTSAMPLE.  Use the object''s parent.');
