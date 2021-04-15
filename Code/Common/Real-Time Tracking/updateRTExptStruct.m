% --- updates the real-time experiment data struct
function rtPos = updateRTExptStruct(rtPos,fPosNew,TNew)

% increments the counter
rtPos.ind = rtPos.ind + 1;

% determines if the current index is greater than maximum
if (rtPos.ind > rtPos.indMx)
    % initialisations
    [N,appData] = deal(1000,true);
    
    % expands the arrays and increments the max counter
    [rtPos.T,a] = deal([rtPos.T;NaN(N,1)],NaN(N,2));    
    rtPos.ind = rtPos.ind + N;
else
    % not necessary to expand the array
    appData = false;
end

% sets the time stamp into the time vector
rtPos.T(rtPos.ind) = TNew;

% sets the fly positions into the cell arrays
for i = 1:length(rtPos.fPos)
    for j = 1:length(rtPos.fPos{i})
        % appends rows to the arrays (if required)
        if (appData); rtPos.fPos{i}{j} = [rtPos.fPos{i}{j};a]; end
        
        % sets the 
        rtPos.fPos{i}{j}(rtPos.ind,:) = fPosNew{i}(j,:);
    end
end
