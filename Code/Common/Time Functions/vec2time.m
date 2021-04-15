% --- converts a time vector to the time given in tUnits. if tUnits is not
%     given, then the time units are determined automatically
function [t,tUnits] = vec2time(tVec,tUnits)

% converts 
i0 = 1;
tMax = [300,300,48,1e10];
tMlt = [60,60,24,NaN];
tUnitsStr = {'Seconds','Minutes','Hours','Days'};

% converts the time vector to seconds
t = sum(tVec(end:-1:1).*[1,60,60^2,24*60^2]);  
if nargin == 2
    % if the time units have been provided, then convert the values to the
    % specified units
    i0 = find(cellfun(@(x)(strcmpi(x(1),tUnits(1))),tUnitsStr));
    for i = 1:(i0-1)
        t = t/tMlt(i);
    end
else
    % loops through determining if the time is less than the max value
    for i = i0:length(tMax)
        if t < tMax(i)
            % if the time is below the maximum count, then return the value
            tUnits = tUnitsStr{i};
            return
        else
            % otherwise, scale the value to the next units type
            t = t/tMlt(i);
        end    
    end    
end
