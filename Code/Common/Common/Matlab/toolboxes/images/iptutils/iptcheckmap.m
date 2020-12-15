function iptcheckmap(map, function_name, variable_name, argument_position)
%IPTCHECKMAP Check validity of colormap.
%   IPTCHECKMAP(MAP,FUNC_NAME,VAR_NAME,ARG_POS) checks to see if
%   MAP is a valid MATLAB colormap and issues a formatted error
%   message if it is invalid. 
%
%   FUNC_NAME is a string that specifies the name used in the formatted
%   error message to identify the function checking the colormap.
%
%   VAR_NAME is a string that specifies the name used in the formatted
%   error message to identify the argument being checked.
%
%   ARG_POS is a positive integer that indicates the position of
%   the argument being checked in the function argument list. 
%   IPTCHECKMAP includes this information in the formatted error message.
%
%   Example
%   -------
%    
%       bad_map = ones(10);
%       iptcheckmap(bad_map,'func_name','var_name',2)
%
%   See also IPTCHECKHANDLE

%   Copyright 1993-2011 The MathWorks, Inc.

if ~isa(map,'double') || isempty(map) || ...
      (ndims(map) ~= 2) || (size(map,2) ~= 3) || ...
      issparse(map)
    compose_error('images:validate:badMapMatrix', upper( function_name ), argument_position, variable_name)
end

if any(map(:) < 0) || any(map(:) > 1)
    compose_error('images:validate:badMapValues', upper( function_name ), argument_position, variable_name)
end

%-----------------------------------------------------------------------------------
function specific_msg = compose_error(id, function_name, arg_position, variable_name)

bad_map_msg = message('images:validate:badMap', upper(function_name), arg_position, variable_name);
specific_msg = message(id,bad_map_msg.getString());

ME = MException(id,'%s',specific_msg.getString());
ME.throwAsCaller()
