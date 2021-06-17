% --- retrieves the disk information
function volInfo = getDiskVolumeInfo()

% initialisations
szTol = 1;              % minimum volume size
b2gb = 1/(1024^3);      % bytes to gigabytes conversion factor

% memory allocation
volObj = java.io.File.listRoots();
volInfo = cell(length(volObj),3);

% determines if any of the feasible volumes are valid
for i = 1:length(volObj)
    % determines if the volume has any free-space  
    szTotal = b2gb*volObj(i).getTotalSpace();
    
    % if there is free space then add the info to the table
    if szTotal > szTol
        szFree = b2gb*volObj(i).getUsableSpace();
        volInfo(i,:) = {char(volObj(i).getPath),szTotal,szFree};
    end
end

% removes the empty rows from the table
volInfo = volInfo(~cellfun(@isempty,volInfo(:,1)),:);