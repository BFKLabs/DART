% --- retrieves the phase timing groupings
function iGrpExD = getPhaseTimingGroups(exD0)

% determines the "PhaseTiming" data field
ii = strcmp(cellfun(@(x)(x.pStr),exD0,'un',0),'PhaseTiming');
if ~any(ii)
    % if none exist, then return with an empty array
    iGrpExD = [];
    return
else
    % otherwise, retrieve the data frame
    Data = exD0{ii}.Data;
end

% retrieves the phase frame indices 
iFrmPh = cellfun(@str2double,Data(:,1:2));
if any(isnan(iFrmPh(:)))
    % if not all the indices are valid, then exit 
    iGrpExD = [];
    return    
end

% % REMOVE ME LATER
% DataCol = [Data(:,3:end);Data(:,3:end)];
% iFrmPh = [iFrmPh;(iFrmPh+iFrmPh(end,2))];

% determines the unique colour phases
DataCol = Data(:,3:end);
colPh0 = cellfun(@strjoin,num2cell(DataCol,2),'un',0);
[~,~,iC0] = unique(colPh0); 
indC = arrayfun(@(x)(getGroupIndex(iC0==x)),1:max(iC0),'un',0)';

% sets the final phase grouping data array
iFrmG = cellfun(@(z)(cell2mat(cellfun(@(x)...
        ([iFrmPh(min(x),1),iFrmPh(max(x),2)]),z,'un',0))),indC,'un',0);
colG = cellfun(@(x)(strjoin(DataCol(x{1}(1),:),'')),indC,'un',0);
iGrpExD = [colG,iFrmG];
    