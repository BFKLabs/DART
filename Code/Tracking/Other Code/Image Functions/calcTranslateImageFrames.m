% --- calculates the x/y cross-correlation transition frames
function dPInfo = calcTranslateImageFrames(obj,iPh)

% initialisations
delFrm = 1;
dPInfo = [];
IL0 = obj.Img{iPh}{1};
iFrm = obj.indFrm{iPh};
dpOfs0 = obj.dpOfs{iPh};

% creates the progressbar
wStr = {'Overall Progress','Current Group','Group Width'};
h = ProgBar(wStr,'Frame Group Detection');
pause(0.05);

% ------------------------------------ %
% --- HORIZTONAL TRANSLATION CHECK --- %
% ------------------------------------ %

% updates the progresbar
h.Update(1,'Horizontal Translation Check...',1/3);

% determnes the dx change frame groupings
[xFrm,dX] = calcInitFrameGroups(iFrm,dpOfs0(:,1),delFrm);
for i = 1:size(xFrm,1)-1
    % updates the progressbar
    wStrNw = sprintf('Analysing Group (%i of %i)',i,size(xFrm,1));
    if h.Update(2,wStrNw,i/size(xFrm,1))
        % if the user cancelled, then exit
        return
    end
    
    % determines the transition frame limits
    xL0 = [xFrm(i,2),xFrm(i+1,1)];
    xi = find(xL0(1)==iFrm)+[0,1];
    xLnw = detFrameGroupLimits(obj,IL0,xL0,dpOfs0(xi,1),1,h);
    [xFrm(i,2),xFrm(i+1,1)] = deal(xLnw(1),xLnw(2));
end

% ------------------------------------ %
% --- VERTICAL TRANSLATION CHECK --- %
% ------------------------------------ %

% updates the progresbar
h.Update(1,'Vertical Translation Check...',2/3);

% determnes the dx change frame groupings
[yFrm,dY] = calcInitFrameGroups(iFrm,dpOfs0(:,2),delFrm);
for i = 1:size(yFrm,1)-1
    % updates the progressbar
    wStrNw = sprintf('Analysing Group (%i of %i)',i,size(yFrm,1));
    if h.Update(2,wStrNw,i/size(yFrm,1))
        % if the user cancelled, then exit
        return
    end
    
    % determines the transition frame limits
    yL0 = [yFrm(i,2),yFrm(i+1,1)];
    xi = find(yL0(1)==iFrm)+[0,1];
    yLnw = detFrameGroupLimits(obj,IL0,yL0,dpOfs0(xi,2),2,h);
    [yFrm(i,2),yFrm(i+1,1)] = deal(yLnw(1),yLnw(2));    
end

% sets the details into the final struct
dPInfo = struct('xFrm',[xFrm(:,2),dX],'yFrm',[yFrm(:,2),dY]);

% updates the closes the progressbar
h.Update(1,'Translation Check Complete!',1);
h.closeProgBar;

% --- determines the frame group limits
function fLim = detFrameGroupLimits(obj,IL0,fLim,dPL,iType,h)

% initialisations
iter = 1;
iterMx = 10;
fTol = 0.005;
idPL = roundP(dPL);

% keep looping until the solution has converged
while 1
    % updates the progressbar
    pComp = 1 - min(abs(dPL-mean(idPL)))/abs(mean(idPL));
    wStr = sprintf('Frame Range Check (%i%s Complete)',roundP(100*pComp),'%');
    if h.Update(3,wStr,pComp)
        return
    end
    
    % determines if the translation values are within tolerance
    if any(abs(dPL-mean(idPL)) < fTol) || (diff(fLim) == 1)
        % if the limit border has been found then return
        break
    else
        %
        diFrm = ((mean(idPL)-dPL(2))*diff(fLim))/diff(dPL);
        iFrmNw = roundP(fLim(2) + diFrm);
        
        % otherwise, read in the new image and determines
        ImgNw = obj.getImageStack(iFrmNw,1);        
        if obj.useFilt
            % filters the image (if required)
            ImgNw = imfilter(ImgNw,obj.hS);
        end        
        
        % calculates the image shift
        dPnw = -flip(fastreg(IL0,ImgNw));        
        iMx = roundP(dPnw(iType)) == roundP(dPL);
        [fLim(iMx),dPL(iMx)] = deal(iFrmNw,dPnw(iType));
        
        % increments the iteration counter
        iter = iter + 1;
        if iter > iterMx
            fLimMn = mean(fLim);
            fLim = floor(fLimMn)+[0,1];
            return
        end
    end
end

% returns the final limits
iMx = argMax(abs(dPL-mean(idPL)));
fLim(iMx) = fLim((1:2)~=iMx) + (1-2*(iMx==1));

% --- calculates the initial frame groups
function [jFrm,dPU] = calcInitFrameGroups(iFrm,dP,delFrm)

dP = roundP(dP,delFrm);
[dPU,~,iCX] = unique(dP,'rows','stable');
jFrm = cell2mat(arrayfun(@(x)([iFrm(find(iCX==x,1,'first')),...
                      iFrm(find(iCX==x,1,'last'))]),(1:iCX(end))','un',0));
