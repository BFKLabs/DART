% --- appends a new dependent variable field to the output data struct
function oP = addYVarField(oP,Name,Var,Stats,Type,xDep,isRaw)

% output parameter convention
%
% Name - metric name
% Var - metric variable string
% Statistics - statistical test name
% Type - metric type vector
%  => element 1 - population metric 
%  => element 2 - fixed metric 
%  => element 3 - individual metric 
%  => element 4 - population signal 
%  => element 5 - individual signal 
%  => element 6 - 2D arrays (population)
%  => element 7 - 2D arrays (individual)

% number of output data types
nOut = 7;

% sets the new data struct
yVarNw = struct('Name',Name,'Var',Var,'Stats',[],'Type',[],...
                'xDep',[],'isRaw',false);

% sets the sub-fields
if exist('Stats','var'); yVarNw.Stats = Stats; end
if exist('xDep','var'); yVarNw.xDep = xDep; end
if exist('isRaw','var'); yVarNw.isRaw = isRaw; end

% sets the output type boolean vector
if exist('Type','var')
    yVarNw.Type = setGroup(Type(:),[1 nOut]);     
else
    yVarNw.Type = setGroup([],[1 nOut]); 
end    

% appends to the new metric data struct to the overall data struct
oP.yVar = [oP.yVar;yVarNw];