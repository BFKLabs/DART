% --- retrieves the directory suffix from a directory path, dirFull --- %
function dirSuf = getDirSuffix(dirFull)

% determines if the path is actually a directory path
if exist(dirFull,'dir')
    % if so, retrieve the directory suffix
    dirSuf = [];    
    while isempty(dirSuf)
        % keep looping until a valid suffix has been found
        [dirFull,dirSuf,~] = fileparts(dirFull);
        if isempty(dirFull)
            % if there is no more path to split, then exit the function
            return
        end
    end
else
    % if not a directory, then show an error
    eStr = sprintf('Error! "%s" is not a directory path!',dirFull);
    waitfor(errordlg(eStr,'Incorrect Directory Path','modal'))
end