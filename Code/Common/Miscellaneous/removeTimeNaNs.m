% --- removes any NaN vales from a time array
function T = removeTimeNaNs(T,FPS,T0,nanT)

% sets the NaN indices argument (if not provided)
if (nargin < 4)
    iszTv = (T == 0); iszTv(1) = false;   
    nanT = isnan(T) | iszTv; 
end

% determines if all of the time values are NaN values
if (all(nanT))
    % if so, then you will need to set the entire time vector
    T = T0 + ((0:(length(T)-1))/FPS)';
else
    % otherwise, determine NaN values from the vector and remove them
    iGrp = getGroupIndex(nanT);
    for i = 1:length(iGrp)
        if (iGrp{i}(1) == 1)
            % if first value is a NaN, then extrapolate
            jGrp = iGrp{i}(end) + 1;
            T(iGrp{i}) = T(jGrp) + (-length(iGrp{i}):-1)/FPS;
        elseif (iGrp{i}(end) == length(T))
            % if last value is a NaN, then extrapolate
            jGrp = iGrp{i}(1) - 1;
            T(iGrp{i}) = T(jGrp) + (1:length(iGrp{i}))/FPS;
        else
            % interpolates the NaN values
            jGrp = reshape(iGrp{i}([1 end]),[2 1]) + [-1;1];
            T(iGrp{i}) = interp1(jGrp,T(jGrp),iGrp{i});
        end
    end
end