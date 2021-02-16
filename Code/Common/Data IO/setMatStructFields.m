% --- sets the matlab struct fields from the plot data struct into the
%     final matlab array
function Amat = setMatStructFields(plotD,pData)

% creates an empty struct
[ind,oP] = deal(getOutputIndices(pData,'BaseIndex'),pData.oP);
fNames = cellfun(@(x,y)(sprintf('%s - %s',x,y)),oP(:,2),oP(:,1),'un',0);
Amat = struct('GroupNames',{pData.appName},'FieldNames',{fNames});

% evaluates the parameters into the matlab data struct
for i = 1:size(oP,1)
    if (any(ind == i))
        % variable is a single variable type
        Pnw = eval(sprintf('plotD(1).%s;',oP{i,2}));
    else
        % case is the normal variables
        Pnw = field2cell(plotD,oP{i,2})';
        Pnw = reshape(Pnw,1,length(plotD));
    end
    
    % evaluates the new parameters
    eval(sprintf('Amat.%s = Pnw;',oP{i,2}));
end