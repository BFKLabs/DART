% --- checks the video time stamps are feasible (removes any NaN values)
function A = checkSummFileTimeStamps(iData,sFile)

% loads the summary file
A = load(sFile);

% if there are no time-stamps, then exit
if ~isfield(A,'tStampV')
    A = [];
    return
end

% determines if any videos have NaN time-stamps
indN = cellfun(@(x)(find(isnan(x)|(x==0))),A.tStampV,'un',0);
hasN = ~cellfun('isempty',indN);

% if there are such videos, then reset the time values
if any(hasN)
    % interpolates the missing time values
    for i = find(hasN(:)')
        xi = find(~isnan(A.tStampV{i}) & (A.tStampV{i} > 0));
        if isempty(xi)
            % calculates the video offset
            if i == 1
                t0 = 0;
            else
                t0 = A.tStampV{1}(end)+A.iExpt.Timing.Tp;
            end
            
            % if there are no valid values, then create a mock array
            A.tStampV{i} = t0 + (0:(length(A.tStampV{i})-1))'/iData.exP.FPS;            
        else
            % otherwise, interpolate any of the infeasible time points
            A.tStampV{i}(indN{i}) = ...
                interp1(xi,A.tStampV{i}(xi),indN{i},'linear','extrap');
        end
    end
    
    % resaves the summary file
    save(sFile,'-struct','A')
end