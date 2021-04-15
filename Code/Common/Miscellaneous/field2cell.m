function varargout = field2cell(Str,fName,varargin)

% if the struct is empty, then return empty fields
if (isempty(Str))
    if (nargin == 3)
        % case is numerical array output
        varargout = repmat([],1,length(fName));
    else
        % case is cell array output
        varargout = repmat({[]},1,length(fName));
    end
    
    % exits the function
    return
end

% converts the struct to a cell array and sets the struct field names
StrC = struct2cell(Str);
StrName = fieldnames(Str);
sz = size(Str);

% ensures that the filename array is a cell array
if (~iscell(fName))
    fName = {fName};
end

%
for i = 1:length(fName)
    % determines the field index for the current search name
    ii = find(strcmp(StrName,fName{i}));    
    if (~isempty(ii))        
        % if the field name exists, then set the output argument from the
        % matching line within the struct
        varargout{i} = StrC(ii,:)';
        
        % converts to a matrix (only if flagged)
        if (nargin == 3)
            try
                varargout{i} = cell2mat(varargout{i});
            catch
                if (islogical(varargout{i}{1}))
                    a = true(length(varargout{i}),1);
                    for j = 1:length(a)
                        a(j) = logical(varargout{i}{j});
                    end
                else
                    a = zeros(length(varargout{i}),1);
                    for j = 1:length(a)
                        a(j) = double(varargout{i}{j});
                    end                    
                end
                
                varargout{i} = a;
            end
        end
        
        % ensures the output has the same dimensions as the input struct
        if (prod(sz) > 1) 
            try
                varargout{i} = reshape(varargout{i},sz(1),sz(2));                    
            end
        end
    else
        % otherwise, output an empty variable and an error msg to screen
        varargout{i} = [];
        eStr = sprintf('Error! The field %s does not exist.',fName{i});
        waitfor(errordlg(eStr,'Incorrect Field Specified','modal'));
    end
end