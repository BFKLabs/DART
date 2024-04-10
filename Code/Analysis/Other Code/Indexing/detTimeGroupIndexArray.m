% --- sets up the daily time bin index array
function indD = detTimeGroupIndexArray(T,iExpt,dT,Tgrp0)

% determines the daily time group indices from the time array
indD0 = detTimeGroupIndices(T,iExpt(1).Timing.T0,1,Tgrp0,1)';

% offsets the time to the start of the day       
dTime = datetime(iExpt(1).Timing.T0) - hours(Tgrp0);
dVec = datevec(dTime);
T0 = [0,dVec(4:end)];
T = T + vec2sec(T0) - dT/2;

% determines the start/end times and number of days the expt ran for
tDay = deal(convertTime(1,'d','s'));
[T0D,TfD] = deal(convertTime(T(1),'s','d'),convertTime(T(end),'s','d'));
nDay = length(indD0);

% sets the combined time group index array
if ((TfD-T0D) < 0.5) && (nDay == 1)
    indD = indD0{1};
else
    % memory allocation
    isN = ~isnan(T); T = T(isN);
    indD = NaN(roundP(convertTime(1,'day','sec')/dT),nDay);
    
    % calculates the day index offset (if the first index is not 1 or a NaN
    % then offset the day index by 1)
    iOfs = indD0{1}(1) > 1;
    
    % sets the day binned indices wrt to the start of the day
    for i = 1:nDay
        % determines the index of the time points wrt the start of the day
        dtDay = ((i+iOfs)-1)*tDay;
        dTT = convertTime(roundP(T(indD0{i})-dtDay,dT),'sec','day');

        %
        iTT = roundP(convertTime(dTT,'day','sec')/dT) + 1; 
        for j = find(diff(iTT(:)') == 0)
            if ((j+1) == length(iTT)) || (diff(iTT(j+(1:2))) == 1)
                iTT(j) = iTT(j) - 1;
            else
                iTT(j+1) = iTT(j+1) + 1;
            end
        end
            
        % sets the indices into the final array    
        ii = (iTT > 0) & (iTT <= size(indD,1));
        indD(iTT(ii),i) = indD0{i}(ii);
    end
end

%
isN = isnan(indD);
if any(isN(:, end)) && ~isN(end, end) 
    indD(find(isN(:, end), 1, 'last'):end, end) = NaN;
end
