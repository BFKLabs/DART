function [style, color, marker] = parseLineSpec(linespec)
%parseLineSpec Parse line style, color, and marker from LineSpec
%
%   [STYLE, COLOR, MARKER] = parseLineSpec(LINESPEC) parses line style,
%   color, and marker strings from the line specification string LINESPEC.
%   An error is issued if LINESPEC is not a LineSpec string.

% Copyright 2011 The MathWorks, Inc.

% This function wraps the semi-documented MATLAB function, colstyle,
% providing a simpler and more standard interface.

if isempty(linespec) && ischar(linespec)
    style = '';
    color = '';
    marker = '';
else
    % Ensure that non-string input isn't allowed into colstyle, which would
    % otherwise throw an error itself.
    if ~ischar(linespec)
        msg = message('map:validate:stringNotChar','LINESPEC',class(linespec));
        throwAsCaller(MException(msg.Identifier,'%s',msg.getString()))
    end
    
    if ~isrow(linespec)
        msg = message('map:validate:stringNotRow','LINESPEC');
        throwAsCaller(MException(msg.Identifier,'%s',msg.getString()))
    end

    % If we reach this step, we can be certain that linespec is a string.
    [style, color, marker, msgstruct] = colstyle(linespec);
    
    % If colystyle has successfully parsed linespec, then errmsg is empty
    % and there's nothing left to do.  Otherwise, msg is a struct with
    % fields 'identifier' and 'message', and this function should end with
    % an error. There are only two possible values for msg, and they are
    % similar except that one is slightly more general. At this level
    % one general messages will suffice.
    if ~isempty(msgstruct)
        msg = message('map:validate:invalidLineSpec','LINESPEC',linespec);
        throwAsCaller(MException(msg.Identifier,'%s',msg.getString()))
    end
end
