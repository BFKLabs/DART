% --- retrieves the channel colour array
function chCol = getChannelCol(devType0,nCh)

% memory allocation
nDev = length(nCh);
chCol = cell(nDev,1);
devType = cellfun(@(x)(removeDeviceTypeNumbers(x)),devType0,'un',0);

% sets the colour array based on type
for i = 1:nDev
    j = nDev - (i-1);
    switch devType{i}
        case 'Opto' 
            % case is/ the optogenetics device
            chCol{j} = {'y','b','g','r'}';

        case 'Motor'
            % case is a motor (with nCh motors)
            chCol0 = {'r','g','b','m','y','c'}';
            chCol{j} = flip(chCol0((1:nCh(i))'));

        case 'RecordOnly' 
            % case is recording only (no colours required)
            chCol{j} = [];

    end
end

% combines into a single array
chCol = cell2cell(chCol);
