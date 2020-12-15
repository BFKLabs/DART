% --- calculates the flies orientation based on the trajectories of the
%     flies given by the coordinates [Px,Py]. note that jittering effects, 
%     are removed such that only movements > dTol are counted in the
%     orientation calculations
function [Phi,Bear] = calcFlyOrientation(Px,Py)

% % smooths the path
% PxS = cell2mat(cellfun(@(x)(smooth(x)),num2cell(Px,1),'un',0));
% PyS = cell2mat(cellfun(@(x)(smooth(x)),num2cell(Py,1),'un',0));
% % [PxS([1 end],:),PyS([1 end],:)] = deal(Px([1 end],:),Py([1 end],:));
% [dPx,dPy] = deal(diff(PxS,[],1),diff(PyS,[],1));

% calculates the change in position. all positions less than tolerance are
% set to a value of zero
[dPx,dPy] = deal(diff(Px,[],1),diff(Py,[],1));
% [dPx(abs(dPx)<dTol),dPy(abs(dPy)<dTol)] = deal(0);

% calculates the inter-frame angles
Phi = atan2(dPy,dPx);

% determines the frames where both the change in x/y coordinates are equal
% to zero. these points will have their bearing set to the previous
% orientation
isZ = (dPx == 0) & (dPy == 0);

% for each group, 
for i = 1:size(Px,2)
    % determines the groups where there zero frames
    iGrp = getGroupIndex(isZ(:,i));
    
    % for each of these frame, set the orientation angle to be that of the
    % previous 
    for j = 1:length(iGrp)
        if ((iGrp{j}(1) == 1) && (iGrp{j}(end) ~= size(Phi,1)))
            % sets the zero frames to that of the next valid frame
            Phi(iGrp{j},i) = Phi(iGrp{j}(end)+1,i);
        else
            % sets the zero frames to that of the previous valid frame
            Phi(iGrp{j},i) = Phi(iGrp{j}(1)-1,i);
        end
    end
end

% % copies the first row of the array 
% Phi = [Phi(1,:);Phi];

% converts the angles to bearings (if required)
if (nargout == 2); Bear = deg2bear(Phi); end