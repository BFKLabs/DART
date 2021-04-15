% --- sets up the stimuli signal based on the parameters and waveform type
function [xS,yS] = setupStimuliSignal(sPara,sType,dT)

% scales the signal duration parameters
if strcmpi(sType,'square')
    % case is the squarewave signals
    [~,tDurOn,tDurOff] = scaleTimePara(sPara,true);
else
    % case is the non-squarewave signals
    [~,tCycle] = scaleTimePara(sPara,false);
end

% sets up the signals based on the signal type
switch lower(sType)
    case 'square' % case is a square-wave signal
        
        % sets up the base signals
        x0 = [[0,0],tDurOn*[1,1]];
        y0 = [0,sPara.sAmp*[1,1],0];
        
    case 'ramp' % case is a ramp
        
        % calculates the gradient of the ramp
        dAmp = (sPara.sAmp1-sPara.sAmp0); 
        m = dAmp*sPara.nCount/sPara.tDur;
        
        % determines the number of points
        x0 = (0:dT:sPara.tDur/sPara.nCount)';
        y0 = sPara.sAmp0 + m*mod(x0,sPara.tDur/sPara.nCount);
        
    case 'triangle' % case is a triangle-wave signal
        
        % calculates the gradient of the ramp
        dAmp = (sPara.sAmp1-sPara.sAmp0);
        m = 2*sPara.nCount*dAmp/sPara.tDur;
        
        % sets up x-values for both halves of the triangle
        tHalf = sPara.tDur/(2*sPara.nCount);
        x0_1 = (0:dT:tHalf)';
        x0_2 = (tHalf:dT:2*tHalf)';
        
        % calculates the y-values for both halved of the triangle-wave
        y0_1 = sPara.sAmp0 + m*x0_1;
        y0_2 = sPara.sAmp1 - m*(x0_2-tHalf);
        
        % sets x/y values for the base triangle wave
        [x0,y0] = deal([x0_1(:);x0_2(:)],[y0_1(:);y0_2(:)]);
        
    case 'sinewave' % case is a sine-wave signal
        
        % sets the y-values for the signal at max. possible spacing
        dAmp = sPara.sAmp1-sPara.sAmp0;
        
        % calculates the signal period and the inverse sine values at the
        % y-position calculated above
        T = sPara.tDur/sPara.nCount;
        
        % sets/calculates the final x/y-values
        x0 = (0:dT:T)';
        y0 = sPara.sAmp0 + dAmp/2*(sin(2*pi*(x0-T/4)/T)+1);
        
    otherwise % case is a custom signal type
        
        % sets the y-values for the signal at max. possible spacing
        dAmp = sPara.sAmp1-sPara.sAmp0;
        
        % calculates the signal period and the inverse sine values at the
        % y-position calculated above
        T = sPara.tDur/sPara.nCount;
        
        % sets/calculates the final x/y-values
        x0 = (0:dT:T)';
        y0 = sPara.sAmp0 + dAmp*sPara.sObj.calcSignal(x0/x0(end));
        
end

% memory allocation
nP = length(x0);
if strcmpi(sType,'square')
    % case is for a square waveform
    xS = zeros(nP*sPara.nCount,1);
    yS = repmat(y0(:),sPara.nCount,1);
else
    % case is for another wavefore type
    xS = zeros((nP-1)*sPara.nCount+1,1);
    yS = [y0(:);repmat(y0(2:end),sPara.nCount-1,1)];
end

% sets up the x/y signal components
for i = 1:sPara.nCount
    % sets the x-values based on the signal type
    if strcmpi(sType,'square')
        % case is the square waveform
        ii = (1:nP) + (i-1)*nP;
        xS(ii) = x0 + (i-1)*(tDurOff+tDurOn);
    else
        % case is the other waveform types
        if i == 1
            % case is for the first period
            ii = (1:nP) + (i-1)*nP;
            xS(ii) = x0 + (i-1)*tCycle;
        else
            % case is for sub-sequent periods
            ii = (1:(nP)-1) + (i-1)*(nP-1) + 1;
            xS(ii) = x0(2:end) + (i-1)*tCycle;
        end
    end
end

% ensures the start/end-points is zero
if (yS(1) ~= 0); [xS,yS] = deal([0;xS],[0;yS]); end
if (yS(end) ~= 0); [xS,yS] = deal([xS;xS(end)],[yS;0]); end
