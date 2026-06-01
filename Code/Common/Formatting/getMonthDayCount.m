% --- gets the day count for each month
function dCount = getMonthDayCount(iSel)

% sets the days in the month (based on the month selected)
switch (iSel)
    case (2) 
        % case is February
        y = year(datetime('now'));
        dCount = 28 + (mod(y,4) == 0);
    
    case {4,6,9,11} 
        % case is the 30 day months
        dCount = 30;
    
    otherwise
        % case is the 31 day months
        dCount = 31;
        
end