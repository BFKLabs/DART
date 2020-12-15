classdef (Hidden) Range < daq.internal.ParameterLimit
    %Range Represents the one of the physical ranges supported by a
    %subsystem
    
    %    Copyright 2010-2012 The MathWorks, Inc.

    %% -- Constructor --
    methods
        % Constructor
        function obj = Range(min,max,units)
            narginchk(3,3)
            obj@daq.internal.ParameterLimit(min,max);
            %units must be a string.
            if ~ischar(units)
                obj.localizedError('daq:general:invalidRangeUnit');
            end
            obj.Units = units;
        end
    end
    
    %% -- Public methods, properties, and events --
    % Read only properties
    properties(SetAccess=private)
        Units
    end
    
    % Methods
    methods
        function disp(obj)
            disp(char(obj))
        end
        function result = char(obj)
            if isempty(obj)
                result = '';
                return
            end
            result = obj.getLocalizedText('daq:general:dispRange',...
                renderSingleValue(obj(1).Min),...
                renderSingleValue(obj(1).Max),...
                obj(1).Units);
            for iObj = 2:numel(obj)
                result = [result ',' obj.getLocalizedText('daq:general:dispRange',...
                    renderSingleValue(obj(iObj).Min),...
                    renderSingleValue(obj(iObj).Max),...
                    obj(iObj).Units)]; %#ok<AGROW>
            end
        
            function result = renderSingleValue(value)
                if value == 0
                    % Handle 0
                    result = '0';
                    return
                end
                order = floor(log10(abs(value)));
                if order < -2
                    % Use standard renderer for values below 0.010
                    result = num2str(value);
                elseif order > 1
                    % If it's above 10, do not include decimal
                    result = num2str(value,'%+0.0f');
                else
                    % Otherwise, generate an appropriate format string
                    result = num2str(value,['%+0.' num2str(1 - order) 'f']);
                end
            end
        end
    end
        
    % Superclass methods this class implements
    methods (Sealed, Access = protected)
        function result = getDispHook(obj)
            %getDispHook() returns a short string to be used in the display of this object in a getdisp operation.
            result = char(obj);
        end
        function result = setDispHook(obj)
            %setDispHook() returns a short string to be used in the display of this object in a setdisp operation.
            result = char(obj);
        end
    end

    
    %% -- Protected and private members of the class --
    % Hidden methods, which are typically used as friend methods
    methods(Hidden,Sealed)
        function result = locateClosestRange(obj,listOfRanges)
            % Return the smallest range from an array of ranges that could
            % encompass the range of obj.  The result must have the same
            % units.
            if ~isscalar(obj) || ~isa(listOfRanges,'daq.Range')
                obj.localizedError('daq:general:locateClosestRangeInvalidParam')
            end
            
            % Limit to ranges with the same units
            listOfRanges = listOfRanges.filterByUnits(obj.Units);
            if isempty(listOfRanges)
                obj.localizedError('daq:general:noRangeFound')
            end
            
            % Select the ranges that could contain obj, i.e. have a Min
            % less than or equal to obj, and a Max greater than or equal to
            % obj
            listOfRanges = listOfRanges([listOfRanges.Min] <= obj.Min&[listOfRanges.Max] >= obj.Max);
            if isempty(listOfRanges)
                obj.localizedError('daq:general:noRangeFound')
            end
            
            % Select the range with the smallest span (Max - Min) among
            % those remaining
            [~,indexResult] = min([listOfRanges.Max] - [listOfRanges.Min]);
            result = listOfRanges(indexResult);
            
        end
        
        function result = filterByUnits(obj,units)
            % Filter a list of daq.Range objects to those with the requested
            % units.
            if iscellstr(units)
                % Compare the Units to the list.  The results (a logical
                % array) of each compare ends up in a cell
                interimResultIndex = cellfun(@(x)strcmp({obj.Units},x),...
                    units,...
                    'UniformOutput',false);
                % Or the contents of the cells together
                resultIndex = interimResultIndex{1};
                for iInterimResultIndex = 2:numel(interimResultIndex)
                    resultIndex = resultIndex | interimResultIndex{iInterimResultIndex};
                end
                result = obj(resultIndex);
            elseif ischar(units)
                result = obj(strcmp({obj.Units},units));
            else
                obj.localizedError('daq:general:invalidUnitParam')
            end
        end
        
        function result = existsInList(obj,list)
            % Check if a range exists in the list of ranges provides. It
            % does an exact match and does not look for an intersection of
            % ranges.
            result = false;
            for i = 1:numel(list)
                if  obj.Min == list(i).Min && ...
                        obj.Max == list(i).Max && ...
                        strcmp(obj.Units,list(i).Units);
                    result = true;
                    return;
                end
            end
        end
    end
    
end
