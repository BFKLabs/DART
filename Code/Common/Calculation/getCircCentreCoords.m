function varargout = getCircCentreCoords(iMov,Type)

% initialisations
useX0 = isfield(iMov.autoP,'X0');

% ensures the type array is set correctly
if ~exist('Type','var')
    % if no input, output both type
    Type = {'X','Y'}; 
elseif ~iscell(Type)
    % ensures array is a cell array
    Type = {Type};
end

% retrieves the centre coordinates (based on type)
varargout = cell(length(Type),1);
if ~isfield(iMov,'autoP')
    return
elseif ~isfield(iMov.autoP,'X') && ~isfield(iMov.autoP,'X0')
    return
end

%
for i = 1:length(Type)
    if useX0
        varargout{i} = getStructField(iMov.autoP,sprintf('%s0',Type{i}));
    else
        varargout{i} = getStructField(iMov.autoP,Type{i});
    end
end