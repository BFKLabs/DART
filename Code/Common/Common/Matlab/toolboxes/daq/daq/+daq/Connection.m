classdef (Hidden) Connection < daq.internal.BaseClass & daq.internal.UserDeleteDisabled
    %Connection All settings & operations for a connection added to a session.
    %    This class is specialized for each class of connection that is
    %    possible.  Vendors further specialize those to implement
    %    additional behaviors.
    
    % Copyright 2011-2012 The MathWorks, Inc.
    
    %% -- Protected and private members of the class --
    
    properties(SetAccess = protected)
        %Source A string of the form Device/Terminal pair specifying the 
        % source of the connection
        Source
        
        %Destination A string of the form Device/Terminal pair specifying
        % the destination of the connection
        Destination
        
        %Type A string enumeration specifying the connection type 
        Type
    end
    
    properties( Access = public, Hidden )
        %Session  The daq.Session object that this connection is part of.
        Session
    end
    
    % Non public-constructor
    methods(Hidden)
        function obj = Connection(session,source,destination,type)
            obj.Session = session;
            obj.Source = source;
            obj.Destination = destination;
            obj.Type = type;            
        end
    end
    
    methods (Access = public, Hidden)
        
        % Get the source device for the connection
        function sourceDevice = getSourceDevice(obj)
            % Default implementation is to parse device terminal pair to
            % get source device. Vendors can override this behaviour.
             sourceDevice = daq.DeviceTerminalPair.getDevice(obj.Source);
        end
        
        % Get the destination device for the connection 
        function destinationDevice = getDestinationDevice(obj)
            % Default implementation is to parse device terminal pair to
            % get destination device. Vendors can override this behaviour.
            destinationDevice = daq.DeviceTerminalPair.getDevice(obj.Destination);
        end
        
        function result = getConnectionDescriptionHook(obj) 
            % dispConnectionDescriptionHook A function that displays summary
            % for a connection.
            %
            %Default implementation is to display a generic string
            result = obj.getLocalizedText('daq:Conn:defaultConnectionDisplay');
        end
        
    end
    
    methods (Hidden, Sealed)
        function disp(obj)
            
            % In some contexts, such as publishing, you cannot use
            % hyperlinks.  If hotlinks is true, then you can.
            hotlinks = feature('hotlinks');
            
            fprintf('\n')
            if any(~isvalid(obj))
                % Invalid object: use default behavior of handle class
                obj.disp@handle
                return
            end
            
            if isempty(obj)
                result = obj.getLocalizedText('daq:Conn:dispTableHeaderNoConnection');
                result = [result '\n'];
                fprintf(result);
                fprintf('\n')
                obj.dispFooter(class(obj),inputname(1),hotlinks)
            elseif numel(obj) == 1
                %Single object -- do detailed display
                result = obj.getConnectionDescriptionHook();
                fprintf([ result '\n']);
                get(obj)
                fprintf('\n')
                obj.dispFooter(class(obj),inputname(1),hotlinks)
            else
                % It could be array of connections
                result = obj(1).Session.SyncManager.getConnectionDispSummaryText();
                fprintf([ result '\n']);
                
                table = internal.DispTable();
                table.Indent = daq.internal.BaseClass.StandardIndent;
                table.addColumn(obj.getLocalizedText('daq:Conn:dispTableIndexColumn'));
                table.addColumn(obj.getLocalizedText('daq:Conn:dispTableTypeColumn'));
                table.addColumn(obj.getLocalizedText('daq:Conn:dispTableSourceColumn'));
                table.addColumn(obj.getLocalizedText('daq:Conn:dispTableDestinationColumn'));
                for iObj=1:numel(obj)
                    table.addRow(iObj,...
                        char(obj(iObj).Type),...
                        obj(iObj).Source,...
                        obj(iObj).Destination);
                end
                
                result = table.getDisplayText();
                fprintf(result);
                fprintf('\n')
                obj.dispFooter(class(obj),inputname(1),hotlinks)
            end
            
        end
    end

    methods (Hidden)
        function deleteRemovedConnection(obj)
            delete(obj);
        end
    end
    
    methods (Access = protected)
        function resetImpl(obj)
            %resetImpl Handle daq.reset (which is usually delete)
            obj.Session = [];
            if ~isempty(obj) && isvalid(obj)
                delete(obj)
            end
        end
    end
    
end
