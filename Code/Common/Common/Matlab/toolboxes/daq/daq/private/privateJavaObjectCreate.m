function [objJava] = privateJavaObjectCreate(type,adaptor,ID)
%PRIVATEJAVAOBJECTCREATE Returns DAQ UDD object wrapped in javabean class.
%
%    [OBJJAVA] = PRIVATEJAVAOBJECTCREATE(TYPE,ADAPTOR,ID) returns a java
%    object that wraps the internal UDD object used by the Data Acquisition
%    Toolbox.
%    TYPE must be a valid object type, e.g. analoginput, analogoutput, etc.
%    ADAPTOR must be the name of a valid installed DAQ adaptor
%    ID must be the device/board ID of a valid installed device for that
%    adaptor.
%
%    PRIVATEJAVAOBJECTCREATE is a helper function for the java model layer.
%

%    Copyright 2004-2008 The MathWorks, Inc.
%    $Revision: 1.1.6.5 $  $Date: 2008/06/16 16:36:02 $

% Adaptor names used by special case code
nidaqAdaptorName = 'nidaq';
nidaqmxAdaptorName = 'nidaqmx';

%Ensure that the daq toolbox is loaded.
daqmex;

% create the UDD DAQ object, and wrap it in a javabean
try
    objJava = java(daq.engine.createobject(type,adaptor,ID));
catch savedException
    % Geck 281433:  In order to make NIDAQmx and NIDAQ adaptors look like a
    % single adaptor, we handle nidaq specially
    if strcmp(adaptor,nidaqAdaptorName)
        try
            objJava = java(daq.engine.createobject(type,nidaqmxAdaptorName,ID));
        catch e
            % Since the Java layer can't generate requests for hardware
            % that doesn't exist, we don't need to be quite so careful
            % about returning the correct error in that case.  The
            % initial response is probably the correct one.
            rethrow(savedException);
        end
    else
        rethrow(savedException);
    end
end
