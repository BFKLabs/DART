% --- retrieves the function comment string for a given functions
function cStr = getFuncCommentStr(fName)

% memory allocation
[A,cStr] = deal([]);

% reads the lines above the function line from the m-file
fid = fopen(fName);
while (1)
    % read the next line from the file
    Anw = fgetl(fid);    
    if (strcmp(Anw(1:8),'function'))
        % if the new line is the function line, then exit the loop
        break
    else
        % otherwise append the new row with the line
        A = [A;{Anw}];
    end
end
fid = fclose(fid);

% from the results
if (~isempty(A))
    % splits the line by the individual words
    ind = cellfun(@(x)(regexp(x,'[a-zA-Z0-9\(\)]')),A,'un',0);
    B = cellfun(@(x,y)(x(y(1):y(end))),A,ind,'un',0);
    C = cell2cell(cellfun(@(x,y)(splitString(x)),B,'un',0));
    
    % sets the final comment string
    for i = 1:length(C); cStr = sprintf('%s%s ',cStr,C{i}); end        
    cStr = cStr(1:end-1);
end