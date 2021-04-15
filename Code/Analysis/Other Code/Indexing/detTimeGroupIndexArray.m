% --- 
function indD = detTimeGroupIndexArray(T,iExpt,dT,Tgrp0)

% determines the daily time group indices from the time array
indD0 = detTimeGroupIndices(T,iExpt(1).Timing.T0,1,Tgrp0,1)';

% offsets the time to the start of the day       
T0 = [0,iExpt.Timing.T0(4:6)];
T0(2) = mod(T0(2) - Tgrp0,24);
T = T + vec2sec(T0) - dT/2;

%
[T0D,TfD] = deal(convertTime(T(1),'s','d'),convertTime(T(end),'s','d'));
nDay = length(indD0);

% sets the combined time group index array
if ((TfD-T0D) < 0.5) && (nDay == 1)
    indD = indD0{1};
else
    % memory allocation
    isN = ~isnan(T); T = T(isN);
    indD = NaN(roundP(convertTime(1,'day','sec')/dT),nDay);                
    
    % sets the day binned indices wrt to the start of the day
    for i = 1:nDay
        % determines the index of the time points wrt the start of the day
        if (i == 1)
            dTT = convertTime(roundP(T(indD0{i}),dT),'sec','day');
        else
            dTT = convertTime(roundP(T(indD0{i})-T(indD0{i}(1)),dT),'sec','day');
        end
        
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
        indD(iTT,i) = indD0{i};
    end
end

%
isN = isnan(indD);
if any(isN(:, end)) && ~isN(end, end) 
    indD(find(isN(:, end), 1, 'last'):end, end) = NaN;
end
