% --- converts a vector (of format DD/hh/mm/ss) to time in seconds --- %
function S = vec2str(V)

% check to see the vector is of the correct dimensions (4 columns)
if size(V,2) ~= 4
    % if not, then 
    [eStr,S] = deal('Error! Time array must be have 4 columns.',[]);
    waitfor(errordlg(eStr,'Invalid Time Format','modal'))
    return
elseif any(V(:) < 0)
    % if not, then 
    [eStr,S] = deal('Error! Time vector can''t have negative values.',[]);
    waitfor(errordlg(eStr,'Invalid Time Format','modal'))
    return    
end

% determines which values to use
hasV = V > 0;
useV = false(size(V));

% sets the strings for each time field
S0 = cell(1,length(V));
for i = find(hasV,1,'first'):length(V)
    if i == length(V)
        if V(i) < 10
            S0{i} = sprintf('0%.3f',V(i));
        else
            S0{i} = sprintf('%.3f',V(i));
        end
        
    else
        if V(i) < 10
            S0{i} = sprintf('0%i',roundP(V(i)));
        else
            S0{i} = num2str(V(i));
        end
    end
    
    useV(i) = true;
end

% combines the final string
S = strjoin(S0(useV),':');