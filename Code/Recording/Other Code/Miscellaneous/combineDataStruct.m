% --- combines all the fields from the srcInfo struct into one array --- %
function [srcInfoNw,fName] = combineDataStruct(srcInfo)

% retrieves the field names
fName = fieldnames(srcInfo);
[srcInfoNw,ok] = deal(cell(length(fName),1),false(length(fName),1));

% sets all of the individual structs into the cell array
for i = 1:length(fName)
    if (~strcmp(fName{i},'Parent'))
        srcInfoNw{i} = eval(sprintf('srcInfo.%s',fName{i}));
        [srcInfoNw{i}.Name,ok(i)] = deal(fName{i},true);
    end
end

% converts the cell array back into a struct
[srcInfoNw,fName] = deal(cell2mat(srcInfoNw(ok)),fName(ok));