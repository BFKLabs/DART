% --- appends a new independent variable field to the output data struct
function oP = addXVarField(oP,Name,Var,Type)

% output parameter convention
%
% Name - metric name
% Var - metric variable string
% Type - metric type 
%  => Group - time grouping parameter
%  => Time - time vector
%  => Dist - distance vector

% sets the new data struct
xVarNw = struct('Name',Name,'Var',Var,'Type','Other');
if (exist('Type','var')); xVarNw.Type = Type; end

% appends to the new metric data struct to the overall data struct
oP.xVar = [oP.xVar;xVarNw];