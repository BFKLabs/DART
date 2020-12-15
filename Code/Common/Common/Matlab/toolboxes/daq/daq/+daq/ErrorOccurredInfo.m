classdef (Hidden) ErrorOccurredInfo < event.EventData & daq.internal.BaseClass
    %ErrorOccurredInfo Information associated with a ErrorOccurred event
    % Listeners on the ErrorOccurred event of the daq.Session object will
    % receive a call to their listener function with a
    % daq.ErrorOccurredInfo object as the second/EVENTINFO parameter.
    %
    % Example:
    %
    % See also: daq.Session.ErrorOccurred, handle.addlistener
    
    % Copyright 2010 The MathWorks, Inc.
    % $Revision: 1.1.6.2 $  $Date: 2010/08/07 07:25:39 $
    
    %% -- Public methods, properties, and events --
    % Read only properties
    properties(SetAccess=private)
        % The MException associated with the error
        Error
    end
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = ErrorOccurredInfo(error)
            obj.Error = error;
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

