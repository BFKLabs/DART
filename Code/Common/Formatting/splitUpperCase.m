% --- splits up the strings in fName by their upper-case letters --- %
function fNameNw = splitUpperCase(fName)

% determines the locations of the 
indSplit = regexp(fName,'[A-Z]');
fNameNw = cell(length(fName),1);

% loops through all of the strings
for i = 1:length(fNameNw)
    % sets the new string name
    fNameNw{i} = fName{i};
        
    % adds in the gaps into the string names
    for j = length(indSplit{i}):-1:2
        indNw = indSplit{i}(j);
        fNameNw{i} = [fNameNw{i}(1:indNw-1),' ',fNameNw{i}(indNw:end)];
    end
end