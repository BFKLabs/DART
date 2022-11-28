% adds the unique motor parameters to the calculation data struct
function cP = addUniqueMotorPara(cP,snTot)

% initialisations
nPara = length(cP);
tName = '3 - Device Para';
[devEnable,chEnable] = deal([]);

% retrieves the stimuli protocol data structs for each experiment
stimP = field2cell(snTot,'stimP');
stimP = stimP(~cellfun('isempty',stimP));

% if there are more than 
if isempty(stimP); return; end

% determines the unique device names (over all experiments)
devName0 = cellfun(@(x)(fieldnames(x)),stimP,'un',0);
devName = unique(cell2cell(devName0));

% determines the unique channel names (over all devices/experiments)
chName0 = cellfun(@(x,y)(cellfun(@(z)(fieldnames...
            (getStructField(x,z))),y,'un',0)),stimP,devName0,'un',0);
chNameT = cell2cell(cellfun(@(x)(cell2cell(x)),chName0,'un',0));
chName = unique(chNameT);

% if all device/channel names are unique, then exit
if length(devName)*length(chName) == 1
    return
end
    
% sets the enabled properties
if length(devName) == 1; devEnable = {NaN,0}; end
if length(chName) == 1; chEnable = {NaN,0}; end

% if there is more than one device type, then add a parameter field
pListD = {1,devName};
cP(end+1) = setParaFields(tName,'List',pListD,'devType',...
                                'Device Type',[],devEnable);
cP(end).TTstr = 'Name of device being used for analysis';

% if there is more than one channel type, then add a parameter field
pListC = {1,chName};
cP(end+1) = setParaFields(tName,'List',pListC,'chType',...
                                'Channel Type',[],chEnable);
cP(end).TTstr = 'Name of device channel being used for analysis';