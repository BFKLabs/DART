function varargout = getCirclePara(autoP,pStr)

%
if ~iscell(pStr); pStr = {pStr}; end
varargout = cell(1,length(pStr));

%
for i = 1:length(pStr)
    switch pStr{i}
        case {'X0','Y0'}
            if isfield(autoP,pStr{i})
                varargout{i} = getStructField(autoP,pStr{i});
            else
                varargout{i} = getStructField(autoP,pStr{i}(1));
            end
            
        otherwise
            varargout{i} = getStructField(autoP,pStr{i});
            
    end
end