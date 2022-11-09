% --- determines the contours (specified by nLvl) from the sub-image, I
%     that surrounds the centre point of the sub-image
function [Pc,cLvl] = splitContourLevels(I,nLvl,fPO,useFirst)

% sets the default input arguments 
if ~exist('fPO','var'); fPO = []; end
if ~exist('useFirst','var'); useFirst = true; end

% parameters and memory allocation
cOfs = 1;
[iLvl,cLvl,Pc] = deal([]);

% other initalisations
sz = size(I);
Pm = 1+(sz(1)-1)/2;
hh = contourc(I,nLvl);

% if there are no contours, then exit
if isempty(hh)
    return
end

% retrieves the closed contours that surround the frame centre-point
while (1)
    % sets the number of indices for the current contour level
    [Nnw,cLvlNw] = deal(hh(2,cOfs),hh(1,cOfs));
    iCnw = cOfs + [1 Nnw];
    
    % determines if the contour start/end are coincident
    canUse = useFirst || (cLvlNw ~= nLvl(1));
    if (diff(hh(1,iCnw)) == 0) && (diff(hh(2,iCnw)) == 0) && canUse
        % if so, then determine if it surrounds the frame centre-point
        xNw = hh(1,iCnw(1):iCnw(2));
        yNw = hh(2,iCnw(1):iCnw(2));         
        canAdd = inpolygon(Pm,Pm,xNw,yNw);
        
        % if there are other points in the frame, then ensure these points
        % are not within the contour
        if ~isempty(fPO)
            canAdd = canAdd && ~any(inpolygon(fPO(:,1),fPO(:,2),xNw,yNw));
        end
        
        % if feasible, then append the contour indices/level values
        if canAdd
            [iLvl,cLvl] = deal([iLvl;iCnw],[cLvl;cLvlNw]);
        end
    end
    
    % increments the column offset counter
    cOfs = cOfs + (Nnw+1);
    if (cOfs > size(hh,2)); break; end
end

% if there are any 
if ~isempty(iLvl)
    % sets the x/y coordinates of the contour levels
    iC = cellfun(@(x)(x(1):x(2)),num2cell(iLvl,2),'un',0);
    Pc = cellfun(@(x)(hh(:,x)'),iC,'un',0);
    Ac = cellfun(@(x)(polyarea(x(:,1),x(:,2))),Pc);
    
    % sorts the levels by decreasing
    [~,iS] = sort(Ac);
    [Pc,cLvl] = deal(Pc(iS),cLvl(iS));
end