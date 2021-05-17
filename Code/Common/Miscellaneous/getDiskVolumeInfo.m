% --- retrieves the disk information
function volInfo = getDiskVolumeInfo()

% initialisations
b2gb = 1/(1024^3);
sVol = char(64+(1:26));
volInfo = cell(length(sVol),3);

% determines if any of the feasible volumes are valid
for i = 1:length(sVol)
    % determines if the volume has any free-space
    volStr = sprintf('%s:\',sVol(i));    
    szTotal = b2gb*java.io.File(volStr).getTotalSpace();
    
    % if there is free space then add the info to the table
    if szTotal > 0
        szFree = b2gb*java.io.File(volStr).getFreeSpace();
        volInfo(i,:) = {volStr,szTotal,szFree};
    end
end

% removes the empty rows from the table
volInfo = volInfo(~cellfun(@isempty,volInfo(:,1)),:);