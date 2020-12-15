% --- converts a vector (of format DD/hh/mm/ss) to time in seconds --- %
function T = vec2sec(V)

% check to see the vector is of the correct dimensions (4 columns)
if (size(V,2) ~= 4)
    % if not, then 
    [eStr,T] = deal('Error! Time array must be have 4 columns.',[]);
    waitfor(errordlg(eStr,'Invalid Time Format','modal'))
    return
elseif (any(V(:)) < 0)
    % if not, then 
    [eStr,T] = deal('Error! Time vector can''t have negative values.',[]);
    waitfor(errordlg(eStr,'Invalid Time Format','modal'))
    return    
end

% sets the duration of the day, hour and mins in seconds
[dDay,dHour,dMin] = deal(24*60^2,60^2,60);

% calculates the time over the vector columns
T = dDay*V(:,1) + dHour*V(:,2) + dMin*V(:,3) + V(:,4);