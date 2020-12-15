classdef(Hidden) MemoryInfo
% MEMORYINFO provides scaling functionality.
%   
%   See also DAQMEM
%

%    Copyright 2009 The MathWorks, Inc.
%    $Revision: 1.1.6.2 $  $Date: 2011/05/13 17:03:27 $
    
    methods (Access = protected)
        function [scaledValue valueUnits] =  scaleBytes(obj, inputValue) %#ok<MANU>
        % SCALEBYTES scales the bytes in appropriate memory units. The 
        % input is the value in bytes and output is a 1-by-2 array in which
        % the scaledValue is the value scaled to match the appropriate 
        % units which are output in valueUnits. As the memory size 
        % available increases new scaling units can be added.
        
            if ~isscalar(inputValue)
                error(message('daq:general:inputMustBeScalar'));
            end
            
            unitsIdentifier = floor(log2(inputValue)/10);
            units = {'KB', 'MB', 'GB', 'TB', 'PB', 'EB'};
            
            % If the value is less than 1KB, return unscaled result 
            if unitsIdentifier <= 0
                scaledValue = inputValue;
                valueUnits = 'bytes';
                return
            end
            
            % If the value is greater than max units, use the max units
            if unitsIdentifier >= length(units)
                unitsIdentifier = length(units);
            end
            
            valueUnits = units{unitsIdentifier};
            scaledValue = inputValue/ (2^(unitsIdentifier*10));
                
        end
    end
    
     methods(Hidden)
        function out = isfield(obj, varargin) 
        % ISFIELD function is overloaded to maintain backward
        % compatibility. ISFIELD shall be deleted when geck g518060 is 
        % fixed. 
            % minimum input argument check
            if nargin < 2
                error(message('daq:general:notEnoughInputs'));
            end
                out = ismember(varargin, fieldnames(obj));
        end
    end

end