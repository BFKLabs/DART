classdef (Hidden) StringEnum < internal.SetGetRenderer
    %StringEnum abstract enumeration base class using strings
    %   StringEnum adds the ability for enumerations to look like
    %   strings to increase usability and ease the transition to the object
    %   oriented world.
    %
    %   Many users prefer to use strings to set enumeration values, but we'd
    %   like to be able to validate operations and list options.
    %   This allows designs that use enumerations internally, but
    %   externally use present a string interface.
    %
    %   Implementers of enumeration classes specialize this class.
    %
    %    This undocumented class may be removed in a future release.
    
    %    Copyright 2009-2011 The MathWorks, Inc.
    %   
    
    %Implementers of this class MUST implement a static version of
    %setValue, which is effectively a factory method.  Most
    %implementations simply call enumFactory on the base class with
    %their FULL class name.
    %
    % Example:
    % methods(Static,Hidden)
    %     function obj = setValue(value)
    %         obj = daq.internal.StringEnum.enumFactory(...
    %             'fake.testpackage.StringEnumTest1',...
    %             value);
    %     end
    % end
    %
    % methods(Access=protected)
    %    function resetImpl(obj)
    %        %resetImpl Handle daq.reset (which is usually delete)
    %        if isvalid(obj)
    %            delete(obj)
    %        end
    %    end
    % end
    
    %% -- Protected and private members of the class --
    % Hidden methods, which are typically used as friend methods
    methods(Hidden)
        function result = toCellArray(obj)
            if isempty(obj)
                result = '';
            elseif numel(obj) == 1
                result = char(obj);
            else
                for iObj = 1:numel(obj)
                    result{iObj} = char(obj(iObj)); %#ok<AGROW>
                end
            end
        end
        
        function result = getPossibleValues(obj)
            % getPossibleValues returns a cell array of strings representing possible values
            result = cellfun(@(x) x.Name,...
                meta.class.fromName(class(obj)).EnumeratedValues,...
                'UniformOutput',false);
        end
        
        % Use the built in "char" function to get a string version.
    end
    
    % Protected static methods for use by a subclass
    methods (Sealed,Static,Access=protected)
        function obj = enumFactory(classObj,value)
            %enumFactory returns the enumeration corresponding a string value
            % enumFactory(CLASS,VALUE) returns an enumeration of VALUE
            % associated with the CLASS specified.
            %
            % As an optimization, if VALUE is an enumeration of CLASSOBJ,
            % the VALUE is immediately returned.
            error(nargchk(2,2,nargin,'struct'))
            assert(ischar(classObj),'Class parameter must be a string.')
            
            if isa(value,classObj)
                % If the value is of the correct type, it's a fully
                % qualified enumeration.
                obj = value;
                return
            end
            
            if ~ischar(value)
                error(message('daq:general:valueMustBeString'));
            end
            
            if ~exist(classObj,'class')
                error(message('daq:general:invalidEnumeration',classObj));
            end
            
            try
                eval(sprintf('obj=%s.%s;',...
                    classObj,value))
            catch  %#ok<CTCH>
                possibleValues = daq.internal.StringEnum.getPossibleValuesFromClassName(classObj);
                error(message('daq:general:invalidMemberOfEnum',value,...
                    daq.internal.renderCellArrayOfStringsToString(possibleValues,''', ''')))
            end
        end
        
        function [result] = getPossibleValuesFromClassName(classObj)
            enumMetaInfoAsCellArray = meta.class.fromName(classObj).EnumeratedValues;
            enumMetaInfo = [enumMetaInfoAsCellArray{:}];
            result = {enumMetaInfo.Name};
        end
    end
    
    % Superclass methods this class implements
    methods (Access = protected)
        function result = getDispHook(obj)
            %getDispHook() returns a short string to be used in the display of this object in a getdisp operation.
            if numel(obj) == 1
                result = char(obj);
            else
                result = daq.internal.renderCellArrayOfStringsToString(...
                    obj.toCellArray(),',');
            end
        end
        function result = setDispHook(obj)
            %setDispHook() returns a short string to be used in the display of this object in a setdisp operation.
            result = ['[ ' daq.internal.renderCellArrayOfStringsToString(...
                obj.getPossibleValues,' | ') ' ]'];
        end
    end
end
