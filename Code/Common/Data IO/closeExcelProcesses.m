% --- closes any external Excel processes (if there are any running)
function closeExcelProcesses()

% determines the processes that are currently running
[~, a] = system('TASKLIST /v /fi "STATUS eq running');
runProg = strsplit(a, '\n');

% determines if there are any excel processes running
[isExcel,pID] = deal(false(length(runProg),1),zeros(length(runProg),1));
for i = 1:length(isExcel)
    if strContains(lower(runProg{i}),'excel')
        [lineSp,isExcel(i)] = deal(strsplit(runProg{i},' '),true);
        pID(i) = str2double(lineSp{2});
    end
end

% kills any excel processes (if there are any running)
if any(isExcel)
    % sets up the task kill string
    [pID,killStr] = deal(pID(isExcel),'taskkill /F');
    for i = 1:length(pID)
        killStr = sprintf('%s /pid %i',killStr,pID(i));
    end
    
    % runs the task kill string in DOS
    [~,b] = system(killStr);
end