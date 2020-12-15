classdef (Hidden) DataAvailableInfo < event.EventData & daq.internal.BaseClass
    %DataAvailableInfo Information associated with a DataAvailable event
    % Listeners on the DataAvailable event of the daq.Session object will
    % receive a call to their listener function with a
    % daq.DataAvailableInfo object as the second/EVENTINFO parameter.
    %
    % Example:
    %
    % See also: daq.Session.DataAvailable, handle.addlistener
    
    % Copyright 2010 The MathWorks, Inc.
    % $Revision: 1.1.6.3 $  $Date: 2010/08/07 07:25:33 $
    
    %% -- Public methods, properties, and events --
    % Read only properties
    properties(SetAccess=private)
        % A MATLAB serial date time stamp of the absolute time of TimeStamp==0
        TriggerTime

        % An mxn array of observations where m is the number of scans, and n is the
        % number of channels
        Data

        % An mx1 array of time stamps where 0 is defined as TriggerTime
        TimeStamps
    end
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = DataAvailableInfo(triggerTime,data,timeStamps)
            %DataAvailableInfo Information associated with a DataAvailable event
            % daq.DataAvailableInfo(TRIGGERTIME,DATA,TIMESTAMP).
            % TRIGGERTIME is a MATLAB serial date time stamp representing
            % timestamp of 0. DATA is the data acquired (if any) in an mxn
            % array of doubles, where m is the number of scans acquired,
            % and n is the number of input channels in the session.
            % TIMESTAMPS is a mx1 array of timestamps relative to the time
            % the operation was triggered.  

            obj.TriggerTime = triggerTime;
            obj.Data = data;
            obj.TimeStamps = timeStamps;
        end
    end
    
    % Superclass methods this class implements
    methods (Sealed, Access = protected)
        function resetImpl(obj)
            %resetImpl Handle daq.reset (which is usually delete)
            if isvalid(obj)
                delete(obj)
            end
        end
    end
end

