classdef (Hidden) ParameterLimit < daq.internal.BaseClass
    %ParameterLimit Defines the limits of a numeric property
    %
    %    This undocumented class may be removed in a future release.
    
    %    Copyright 2011 The MathWorks, Inc.
    % $Revision: 1.1.6.3 $  $Date: 2011/03/02 14:39:06 $

    %% -- Constructor --
    methods
        % Constructor
        function obj = ParameterLimit(min,max)
            error(nargchk(2,2,nargin,'struct'))
            %max and min must be a scalar numeric. min must be less than
            %max
            
            % G687868: Allow case where min and max are equal (e.g.
            % on-demand only devices, with min = max = 0)
            if ~isscalar(min) || ~isnumeric(min) ||...
                    ~isscalar(max) || ~isnumeric(max) ||...
                    ~(min <= max)
                obj.localizedError('daq:general:invalidParameterLimit');
            end
            obj.Max = max;
            obj.Min = min;
        end
    end
    
    %% -- Public methods, properties, and events --
    % Methods
    methods
        function disp(obj)
            disp(char(obj));
        end
        function result = double(obj)
            if isempty(obj)
                result = [];
            else
                result = zeros(numel(obj),2);
                for iObj = 1:numel(obj)
                    result(iObj,:) = [obj(iObj).Min obj(iObj).Max];
                end
            end
        end
        function result = char(obj)
            if isempty(obj)
                result = '';
            else
                result = obj.getLocalizedText('daq:general:dispParameterLimit',...
                    num2str(obj.Min,'%0.1f'),...
                    num2str(obj.Max,'%0.1f'));
            end
        end
    end
    
    %% -- Protected and private members of the class --
    
    % Private properties
    properties(SetAccess=private)
        Max
        Min
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
    methods (Access = protected)
        function result = getDispHook(obj)
            %getDispHook() returns a short string to be used in the display of this object in a getdisp operation.
            result = obj.getLocalizedText('daq:general:dispParameterLimit',...
                num2str(obj.Min,'%0.1f'),...
                num2str(obj.Max,'%0.1f'));
        end
        function result = setDispHook(obj)
            %setDispHook() returns a short string to be used in the display of this object in a setdisp operation.
            result = obj.getLocalizedText('daq:general:dispParameterLimit',...
                num2str(obj.Min,'%0.1f'),...
                num2str(obj.Max,'%0.1f'));
        end
    end
    
end

