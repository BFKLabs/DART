% --- determines the experiment type based on the solution struct, and
%     returns the feasible function indices for the experiment solution
function isFeas = detExptType(snTot,fType)

% fType Format Key
%
% -> Element 1 - Function Classification
%   = 1 - Classical Type
%   = 2 - Non-Classical Type
%   = 3 - Speciality
% -> Element 2 - Stimuli Dependency
%   = 1 - Stimuli Independent
%   = 2 - Motor Dependent
%   = 3 - Opto Dependent
% -> Element 3 - Expt Duration
%   = 1 - Time Independent
%   = 2 - Short Experiment
%   = 3 - Long Experiment
% -> Element 4 - Data Dimensionality
%   = 1 - Dimension Independent
%   = 2 - 1D Data Only
%   = 3 - 2D Data Only
% -> Element 5 - Special Requirements
%   = 1 - Requires Multi Phase Stimuli Protocol
%   = 2 - Requires Orientation Angle Values

% if the special requirements are not specified then set a zero value
if size(fType,2) == 4; fType = [fType,zeros(size(fType,1),1)]; end

% memory allocation
isFeas = true(length(fType),1);

% determines the duration of the experiment
isLong = ~detIfShortExpt(field2cell(snTot,'T'));
if isLong
    % if long, all short experiments are removed
    isFeas(fType(:,3) == 2) = false;
else
    % otherwise, all long experiments are remove
    isFeas(fType(:,3) == 3) = false;
end
    
% determines the dimensionality of the dataset
if isfield(snTot,'iMov')
    is1D = ~is2DCheck(snTot.iMov);    
else
    is1D = all(cellfun(@isempty,field2cell(snTot,'Px'))) || ...
           all(cellfun(@isempty,field2cell(snTot,'Py')));
end
      
if is1D
    % if 1D, all 2D experiments are removed
    isFeas(fType(:,4) == 3) = false;    
else
    % if 2D, all 1D experiments are removed
    isFeas(fType(:,4) == 2) = false;    
end

% determines if there are any stimuli events in the solution file
stimP = field2cell(snTot,'stimP');

% determines if the experiment is an RT experiment
isRT = fType(:,1) == 4;
if isfield(snTot,'sData') && any(isRT)
    % retrieves the tracking parameter structs
    rtP = field2cell(cell2mat(field2cell(snTot,'iExpt')),'rtP');    
    
    % determines which connection type was used
    isC2A = any(cellfun(@(x)(strcmp(x.Stim.cType,'Ch2App')),rtP));
    if isC2A
        % case is connecting a channel to a sub-region
        isFeas(isRT & (fType(:,2) ~= 1)) = false;
    else
        % case is connecting a channel to an individual tube
        isFeas(isRT & (fType(:,2) ~= 2)) = false;
    end
else
    % is experiment is no an RT-experiment
    isFeas(isRT) = false;
end
    
% sets the feasibility of the stimuli dependent functions
dKey = any(cell2mat(cellfun(@(x)(getDevTypeKey(x)),stimP(:),'un',0)),1);
for i = 1:length(dKey)
    ii = ~isRT & (fType(:,2) == (i+1));
    isFeas(ii) = isFeas(ii) & dKey(i);
end

% determines which functions have special requirements
jj = find(fType(:,5) > 0);
for i = reshape(jj,1,length(jj))
    % sets the new conditional value based on the requirement
    switch (fType(i,5))
        case (1) % Requires Multi Phase Stimuli Protocol
            if (~isStim)
                % experiment has no stimuli (recording only)
                isFeasNw = false;
            else
                % determines if all experiments have multi-phase stimuli
                isFeasNw = all(cellfun(@(x)(length(...
                        x.iExpt.Stim(1).sigPara{1})>1),num2cell(snTot)));
            end
        case (2) % Requires Orientation Angle Values    
            isFeasNw = all(cellfun(@(x)(isfield(x,'Phi')),num2cell(snTot)));
    end      
    
    % appends the new condition value to the current
    isFeas(i) = isFeas(i) && isFeasNw;
end

% --- retrieves the device type keys
function devKey = getDevTypeKey(stimP)

% retrieves the device types
devType = {'Motor','Opto'};
devKey = false(1,length(devType));

if ~isempty(stimP)
    devStim = fieldnames(stimP);
    for iDev = 1:length(devKey)
        devKey(iDev) = any(strContains(devStim,devType{iDev}));
    end
end
