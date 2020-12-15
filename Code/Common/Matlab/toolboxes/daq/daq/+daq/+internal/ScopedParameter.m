classdef (Hidden) ScopedParameter < daq.internal.ParameterLimit
    %ScopedParameter Parameter that has a max and min limit
    %
    %    This undocumented class may be removed in a future release.
    
    %    Copyright 2011 The MathWorks, Inc.
    % $Revision: 1.1.6.4 $  $Date: 2011/03/02 14:39:07 $
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Constructor --
    methods
        % Constructor
        function obj = ScopedParameter(propertyName,initialValue,min,max)
            error(nargchk(4,4,nargin,'struct'))
            obj@daq.internal.ParameterLimit(min,max);
            %initialValue must be a scalar numeric. min must be less than
            %or equal to initialValue, and initialValue must be less than or equal to max
            if ~isscalar(initialValue) || ~isnumeric(initialValue) ||...
                    ~(min <= initialValue) || ~(initialValue <= max)
                obj.localizedError('daq:general:invalidScopedParameter');
            end
            if ~ischar(propertyName)
                obj.localizedError('daq:general:invalidScopedParameterName');
            end
            obj.PropertyName = propertyName;
            obj.Value = initialValue;
        end
    end
    
    %% -- Public methods, properties, and events --
    % Read/write properties
    properties
        Value
    end
    
    % Methods
    methods
        function disp(obj)
            if isempty(obj)
                disp('');
                return
            end
            disp([obj.Value])
        end
        function result = double(obj)
            if isempty(obj)
                result = [];
            else
                result = [obj.Value];
            end
        end
    end
        
    %% -- Protected and private members of the class --
    
    % Property access methods
    methods
        function set.Value(obj,newValue)
            if(newValue < obj.Min)
                obj.localizedError('daq:general:propertyBelowMin',...
                    obj.PropertyName,num2str(obj.Min))
            end
            if(newValue > obj.Max)
                obj.localizedError('daq:general:propertyAboveMax',...
                    obj.PropertyName,num2str(obj.Max))
            end
            obj.Value = newValue;
        end
    end
    
    % Private properties
    properties(GetAccess=private,SetAccess=private)
        PropertyName
    end
    
    % Superclass methods this class implements
    methods (Sealed, Access = protected)
        function result = getDispHook(obj)
            %getDispHook() returns a short string to be used in the display of this object in a getdisp operation.
            result = num2str(obj.Value);
        end
    end
end