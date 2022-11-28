% --- calculates the extremum of a signal, Ysig 
function [imx,imxBand] = calcSignalExtremumPeaks(Ysig,isCirc,kTol)

% --- SIGNAL INITIALISATION --- %
% ----------------------------- %

N = length(Ysig);
Ysig(isnan(Ysig)) = 0;

% thresholds the image such that the signal values less that kTol are zero
if (nargin > 2)
    ii = Ysig < kTol;
    if (all(ii))
        imx = [];
        return
    else
        Ysig(ii) = 0;
    end
end

% --- SIGNAL BAND CALCULATION --- %
% ------------------------------- %

% memory allocation
imxBand = [];

% sets the indices of the positive/zero values
iiZ = find(Ysig == 0);

% if the first value is not zero, then set the initial band to be the first
% point preceding the first zero point
if (iiZ(1) ~= 1)
    imxBand = [1 iiZ(1)];
end

% determines the middle signal non-zero bands
jjZ = find(diff(iiZ) > 1);
if (~isempty(jjZ))
    imxBand = [imxBand;[iiZ(jjZ) iiZ(jjZ+1)]];
end

% if final value is non-zero, then set the final band to be the last point
if (iiZ(end) ~= N)
    if (isempty(imxBand))
        % if the feasible band index array is empty, then initialise it
        imxBand = [iiZ(end) N];        
    else        
        if (imxBand(1,1) == 1) && (isCirc)
            % if the signal is circular, and the first band starts at the
            % first signal point, then reset the initial band to be the
            % last zero-point in the signal
            if (iiZ(end) == imxBand(end,2))
                imxBand(1,1) = imxBand(end,1);
            else
                imxBand(1,1) = iiZ(end);
            end
        else
            % otherwise, add the band on to the end of the list
            imxBand = [imxBand;[iiZ(end) N]];
        end
    end
end

% % loops through each of the bands closing the gaps for the bands that are
% % less than imxBandMin in distance from each other
% for i = size(imxBand,1):-1:2
%     if ((imxBand(i,1) - imxBand(i-1,2)) < imxBandMin)
%         imxBand = [imxBand(1:(i-2),:);...
%                   [imxBand(i-1,1) imxBand(i,2)];...
%                    imxBand((i+1):end,:)];
%     end
% end
% 
% % checks the end points to determine if there is wrap-around. if so, reduce
% % the gap and shrink the array size
% if (size(imxBand,1) > 1)
%     dEndInd = imxBand(1,1) - imxBand(end,2);
%     if ((dEndInd > 0) && (dEndInd < imxBandMin))
%         imxBand(1,1) = imxBand(end,1);
%         imxBand = imxBand(1:(end-1),:);
%     end
% end

% --- SIGNAL PEAK CALCULATION --- %
% ------------------------------- %

% memory allocation
imx = cell(size(imxBand,1),1);

% loops through each band determining the peaks 
for i = 1:size(imxBand,1)
    % sets the indices of the new band
    if (imxBand(i,1) > imxBand(i,2))
        % band wrap around, so use permutation index
        indNw = [(imxBand(i,1):N) (1:imxBand(i,2))];
    else
        % otherwise, use the indices formed by the band
        indNw = imxBand(i,1):imxBand(i,2);
    end
    
    % determines the locations within the signal band where the gradient
    % changes from being positive to negative
    jj = sign(diff(Ysig(indNw)));   
    while (any(jj == 0))
        kk = find(jj == 0);
        if (kk(1) == 1)
            [jj(1),kk] = deal(-1,kk(2:end));             
        end
        
        % 
        jj(kk) = jj(kk-1);
    end
    
    % calculates the indices where the sign changes from +ve -> -ve
    if (all(jj == -1))
        imx{i} = indNw(1);
    else
        imx{i} = mod(find(diff(jj) < -1) + indNw(1),N)+1;
    end
    
    % offsets the band (non-zero values only)
    ii = imx{i} > 1;
    imx{i}(ii) = imx{i}(ii) - 1;
end

% removes all non-feasible entries
imx = imx(~cellfun('isempty',imx));
