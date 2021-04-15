% --- retrieves the all fields from a struct
function p = getAllStructFields(sStr)

% memory allocation
fName = fieldnames(sStr);
p = cell(length(fName),1);

% retrieves the struct fields
for i = 1:length(fName)
    p(i) = field2cell(sStr,fName{i});
end