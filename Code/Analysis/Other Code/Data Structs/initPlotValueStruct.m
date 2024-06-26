% --- initialises the plotting values struct --- %
function plotD = initPlotValueStruct(snTot,pData,cP,varargin)

% parameters
tMin = 300;
tMinTol = 59;

% sets the number of input arguments (if already set)
if pData.useReg
    nApp = pData.nApp;
else
    nApp = length(snTot(1).iMov.ok);
end

% sets the input argument values (if special)
if ~ischar(varargin{1})
    Yr0 = varargin{1};
    varargin = varargin(2:end);
else
    Yr0 = [];
end

% initialises the basic plot value data struct (just the T/Y fields only)
plotD = struct();

% if the number of input arguments is correct, then loop through each of
% the arguments updating the fields with the field values, fVal
if mod(length(varargin),2) == 0
    for i = 1:length(varargin)/2
        % sets the new field/value from the inputs
        [fStr,fVal] = deal(varargin{(i-1)*2+1},varargin{2*i});
        plotD = setStructField(plotD,fStr,fVal);
    end
end

% if there are no dependent variables, then exit
if isempty(pData.oP.yVar)
    plotD = repmat(plotD,nApp,1);
    return; 
end

% allocates memory for metric raw data (if there are any)
isRaw = logical(field2cell(pData.oP.yVar,'isRaw',1));
if any(isRaw)
    % initialisations
    [nDay,nFly,nExp] = deal(1,1,1+(length(snTot)-1)*pData.oP.sepExp);
    
    % sets the day
    for i = 1:length(snTot)
        % calculates the number of days the experiment
        if pData.oP.sepDay
            % retrieves the experiment start time
            T0 = snTot(i).iExpt.Timing.T0;
            T0(4) = mod(T0(4) - cP.Tgrp0,24);
            if (T0(5) == tMinTol)
                % if the experiment starts > 59 min
                T0(4) = mod(T0(4)+1,24);
                T0(5) = 0;
            end
            
            % determines the number of days the expt runs for
            Texp = [0,T0(4:6)] + sec2vec(snTot(i).T{end}(end));
            Texp(1:2) = [Texp(1)+floor(Texp(2)/24),mod(Texp(2),24)];
            nDay = max(nDay,Texp(1)+(vec2sec([0,Texp(2:4)]) > tMin)); 
        end
        
        % sets the number of flies in the experiment
%         nFly = max(nFly,size(snTot(i).iMov.flyok,1));
        nFly = max(nFly,max(cellfun('length',snTot(i).iMov.flyok)));
    end
        
    % creates the raw arrays for     
    for i = reshape(find(isRaw),1,sum(isRaw))
        % sets the new array based on the parameter type
        if any(pData.oP.yVar(i).Type([3 5]))
            % case is an individual metric
            Anw = cell(nDay,nFly,nExp);
        else
            % case is a population metric
            Anw = cell(nDay,1,nExp);
        end
        
        % sets the default values (if any)
        if ~isempty(Yr0); Anw(:) = {Yr0}; end
           
        % stores the values into the array
        plotD = setStructField(plotD,pData.oP.yVar(i).Var,Anw);
    end
end

% sets up the plot data struct
plotD = repmat(plotD,nApp,1);
