% --- converts a string to an array
function Y = str2array(s)

% memory allocation
Y = zeros(size(s));

% converts the strings to the array values
for i = 1:size(Y,1)
    for j = 1:size(Y,2)
        Y(i,j) = str2double(s(i,j));
    end
end