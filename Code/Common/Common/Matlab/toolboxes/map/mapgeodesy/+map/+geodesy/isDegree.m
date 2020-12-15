function tf = isDegree(angleUnit)
%map.geodesy.isDegree True if string matches 'degree' and false if 'radian'
%
%   TF = map.geodesy.isDegree(angleUnit) returns true if angleUnit is a
%   partial match for 'degree' (or 'degrees') and false if angleUnit is a
%   partial match for 'radian' (or 'radians'). If angleUnit matches neither
%   'degrees' or 'radians', an error is thrown.
%
%   Example
%   -------
%   map.geodesy.isDegree('degree')
%   map.geodesy.isDegree('radian')
%
%   Input Argument
%   --------------
%   angleUnit -- Unit of angle string, specified as 'degree' or
%     'radian'. Data Type: char.
%
%   Output Argument
%   ---------------
%   TF -- True/false flag, returned as a logical scalar.

% Copyright 2012-2013 The MathWorks, Inc.

% For efficiency, perform in-depth validation of angleUnit only if we first
% determine that it is a match for neither 'degrees' nor 'radians'.
n = max(1,numel(angleUnit));
if strncmpi(angleUnit,'degrees',n)
    tf = true;
elseif strncmpi(angleUnit,'radians',n)
    tf = false;
else
    % angleUnit matches neither 'degrees' nor 'radians'. Leverage
    % validateattributes and validatestring to construct an error.
    try
        % Call validateattributes first, in order to keep the error message
        % simple. If we don't do this, validatestring will throw an error
        % that includes an additional 'caused by' section, in the event of
        % empty, non-char, or non-row vector input.
        validateattributes(angleUnit,{'char'},{'nonempty','row'},'','angleUnit')
        validatestring(angleUnit,{'degrees','radians'},'','angleUnit')
    catch e
        % Make the error appear to come from the client function, which 
        % should also have an input variable named 'angleUnit'.
        throwAsCaller(e)
    end
end
