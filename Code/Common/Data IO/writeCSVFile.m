% --- writes the data in the cell array to the CSV file, fName --- %
function ok = writeCSVFile(fName,Data,h)

% closes all open file IDs
fclose('all');

%
if (nargin < 3)
    [h,hasWait] = deal(0,false);
else
    hasWait = isobject(h);
    if hasWait
        wStr = 'Writing CSV File';
    end
end

% opens the file for writing
if ~iscell(Data); Data = num2cell(Data); end
fid = fopen(fName,'w');

% creates the waitbar figure
[m,n] = size(Data);
if (m > 100)
    pW = 0.01;
else
    pW = 0.1;
end

% other initialisations
[dW,ok] = deal(max(1,ceil(m*pW)),true);

% writes the data to the csv file
for i = 1:m
    if (mod(i,dW)-1 == 0) && hasWait
        % updates the waitbar figure        
        wStrNw = sprintf('%s (%i%s Complete)',wStr,roundP(100*i/m),char(37));
        if ~updateLoadbar(h,wStrNw)      
            % if the user cancelled, then exit the function
            fclose(fid);
            delete(fName)
            return
        end
    end
    
    % write all the columns in the row
    try
        for j = 1:n
            printNewValue(fid,Data{i,j},j==1);
        end

        % prints the carriage return
        fprintf(fid,'\n');
    catch ME
        try fclose(fid); end
        if hasWait; try; close(h); end; end
        ok = false; 
        return
    end
end
    
% closes the file
fclose(fid);

% --- prints the new value to the CSV file --- %
function printNewValue(fid,Y,isFirst)

% sets the prefix string
if isFirst
    str0 = '';
else
    str0 = ','; 
end

% prints the new character
if isnumeric(Y)
    if isnan(Y)
        fprintf(fid,str0);    
    elseif mod(Y,1) == 0
        fprintf(fid,[str0,'%i'],Y);
    else
        fprintf(fid,[str0,'%.4f'],Y);
    end
else
    fprintf(fid,[str0,'%s'],Y);
end
