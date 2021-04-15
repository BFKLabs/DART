% --- brute-force reads in the data from a CSV file
function [Data,ok] = readCSVFile(fName)

% initialisations
[ok,Data] = deal(true,[]);

% retrieves the file ID number
try
    fid = fopen(fName);
catch
    % if there was an error, then exit the function
    ok = false; return
end

% keep reading the data file until the end of file is reached
while (1)
    % reads in the new line
    nwLine = fgetl(fid);   
    if (~ischar(nwLine))
        % if the new line is an end-of-file, then exit the loop
        break
    else
        % otherwise, split the line by the comma values
        A = splitStringRegExp(nwLine,',')';
        Data = combineCellArrays(Data,A,false);
    end
end

% closes the data file
a = fclose(fid);







