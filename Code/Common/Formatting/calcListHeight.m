% --- calculates a default uitable height
function [H,dL0] = calcListHeight(nRow,L0)

% global variables
global HWL

% determines the optimal listbox height
while (1)
    % calculates the new list height
    H = HWL*nRow;
    
    % determines if the list height is close enough to the original
    if ((L0-H)/HWL > 0.5)
        % if not, then increment the number of rows
        nRow = nRow + 1;
    else
        % otherwise, exit the loop
        dL0 = L0 - H;
        break
    end
end
