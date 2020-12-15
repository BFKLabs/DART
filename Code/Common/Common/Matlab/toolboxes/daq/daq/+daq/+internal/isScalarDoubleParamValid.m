function meetsCriteria = isScalarDoubleParamValid(parameter,mustBePositive,zeroOK,infOK,mustBeIntegral)
    %isScalarDoubleParamValid Check that the input value is  isnumeric, non-nan
    %value that meets certain criteria
    %
    % isScalarDoubleParamValid(parameter,mustBePositive,zeroOK,infOK,mustBeIntegral)
    % returns true if parameter is scalar numeric and not nan, and meets the
    % specified criteria:
    %    mustBePositive: If true, value cannot be negative
    %    zeroOK: If true, the value of zero is acceptable
    %    infOK: If true, positive and negative infinity is acceptable
    %    mustBeIntegral: If true, the value must be an integer number
    %
    %    This undocumented class may be removed in a future release.
    
    %    Copyright 2010 The MathWorks, Inc.
    % $Revision: 1.1.6.1 $  $Date: 2011/01/28 18:48:40 $
    meetsCriteria = ~isempty(parameter) &&...
        isscalar(parameter) &&...
        isnumeric(parameter) &&...
        ~any(any(isnan(parameter)));
    
    if ~meetsCriteria
        return
    end
    
    if mustBePositive
        if zeroOK
            % Param must be positive or 0
            if parameter < 0
                meetsCriteria = false;
                return
            end
        else
            % Parameter must be positive
            if parameter <= 0
                meetsCriteria = false;
                return
            end
        end
    else
        if ~zeroOK && parameter == 0
            meetsCriteria = false;
            return
        end
    end
    if isinf(parameter) && ~infOK
        % Parameter was inf, and inf is not OK
        meetsCriteria = false;
        return
    end
    if mustBeIntegral && abs(parameter - floor(parameter)) > 0.001
        % Parameter required to be integral
        meetsCriteria = false;
        return
    end
    meetsCriteria = true;
end
