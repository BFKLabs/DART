% --- calculates the midline cross-over for the frame indices, frmInd --- %
function [TBin,YBin,YRaw] = calcMidlineCrossover(snTot,tBin,pX,frmInd,ind)

% sets the total time vector
TT = cell2mat(snTot.T);

% sets the frame indices/apparatus indices
switch (nargin)
    case (2)
        pX = 0.5;
        ind = (1:length(snTot.Px{1}));
        frmInd = (1:length(TT))';        
    case (3)
        ind = (1:length(snTot.Px{1}));
        frmInd = (1:length(TT))';
    case (4)
        ind = (1:length(snTot.Px{1}));        
end

% reset sets the time vector
TT = TT(frmInd);

% parameters & memory allocations
[xDel,nApp] = deal(1,length(ind)); 
[YRaw,YBin] = deal(cell(1,nApp));

% creates the waitbar
h = findobj(0,'type','figure','tag','BatchProgress');
wStr = {'Calculating Time Bins...'};
if isempty(h)
    % if there isn't one, then create a new waitbar-figure
    [h,wOfs] = deal(ProgBar(wStr,'Speed Calculations'),0);    
else
    % retrieves the waitbar string
    wOfs = 2;
end

% retrieves the waitbar update function   
if wOfs > 0; h.Update(2+wOfs,'',0); end

% determines the bin indices and removes and bins that have not matches
h.Update(1+wOfs,wStr,0.125); pause(0.01)
iBin = floor((TT-TT(1))/tBin) + 1; 
indB = cellfun(@(x)(find(iBin==x)),num2cell((1:max(iBin))'),'un',0); 
indB = indB(~cellfun(@isempty,indB));

% sets the bin indices, and the time at the start of each bin
indB(2:end) = cellfun(@(x)([(x(1)-1);x]),indB(2:end),'un',0);
TBin = cellfun(@(x)(TT(x(1))),indB);

% loops through all the apparatus calculating the times at which the flies
% crossed the tube-centre line
for iApp = 1:nApp
    % updates the waitbar figure
    wStrNw = sprintf('Calculating Mid-Line Crossings (Group %i of %i)',...
                     iApp,nApp);
    if h.Update(1+wOfs,wStrNw,0.25+0.75*(iApp/nApp))
        [TBin,YBin,YRaw] = deal([]);
        return
    end
    
    % retrieves the x-locations of the flies over all frames, and retrieves
    % the min/max x-locations
    Px = cell2mat(cellfun(@(x)(x{iApp}),snTot.Px,'un',0)); 
        
    % sets the lower/uppder midline location   
    [PxMn,PxMx] = deal(min(Px(:)),max(Px(:)));     
    P0 = PxMn + pX*(PxMx - PxMn); 
    [xLo,xHi] = deal(P0-xDel,P0+xDel); 

    % determines the indices where the flies move from     
    indCross = cellfun(@(x)(calcMidlineCrossoverIndiv(x,xLo,xHi)),...
                            num2cell(Px(frmInd,:),1),'un',0);
                                    
    % sets the raw mid-line crossings (for each time-point)
    [YRaw{iApp},nFly] = deal(zeros(length(frmInd),1),length(indCross)); 
    for i = 1:nFly
        YRaw{iApp}(indCross{i}) = YRaw{iApp}(indCross{i}) + 1; 
    end
        
    % calculates the binned mid-line crossings per 
    YRaw{iApp} = YRaw{iApp}/nFly;
    YBin{iApp} = cellfun(@(x)...
                    (60*sum(YRaw{iApp}(x))/diff(TT(x([1 end])))),indB);
end

% closes the waitbar figure (if created within this function)
if wOfs == 0
    h.closeProgBar(); 
    pause(0.01);    
end

% --- determines the indices (within the x-location array, PxNw) where the
%     fly crosses the tube mid-line (given by the lower/upper limits
%     xLo/xHi) --- %
function indCross = calcMidlineCrossoverIndiv(PxNw,xLo,xHi)

% determines the locations where the flies travel from right to left, and
% from right to left (crossing the low/high points)
iR2L = find(diff(sign([PxNw(1);PxNw] - xLo)) < 0); 
iL2R = find(diff(sign([PxNw(1);PxNw] - xHi)) > 0);
    
% sets the crossing indices based on the results above
if (isempty(iR2L) && (isempty(iL2R)))
    % if are no crossings, then return an empty array
    indCross = [];
elseif (isempty(iR2L))
    % if there isn't any going from right to left, then set the first left
    % to right index
    indCross = iL2R(1);
elseif (isempty(iL2R))
    % if there isn't any going from left to right, then set the first right
    % to left index
    indCross = iR2L(1);    
else
    % sets the side index (based on the first x-location)
    if (PxNw(1) < xLo)
        % fly is initially on the left side
        [iSide,indCross] = deal(2,iL2R(1));
    else
        % fly is initially on the right side
        [iSide,indCross] = deal(1,iR2L(1));
    end
    
    % keep searching the 
    [cont,ind] = deal(true,[1 1]);        
    while (cont)
        %
        if (iSide == 1)
            % determines when the fly moves from the right to the left
            indNw = find(iL2R(ind(1):end) > indCross(end),1,'first');
            [iSide,iSidePr] = deal(2,1);
        else
            % determines when the fly moves from the left to the right
            indNw = find(iR2L(ind(2):end) > indCross(end),1,'first');
            [iSide,iSidePr] = deal(1,2);
        end                        
        
        %
        if (isempty(indNw))
            % if there are no new matches, then exit the loop
            cont = false;
        else
            ind(iSidePr) = ind(iSidePr) + (indNw-1);
            if (iSidePr == 1)
                indCross(end+1) = iL2R(ind(iSidePr));
            else
                indCross(end+1) = iR2L(ind(iSidePr));
            end
        end
    end
end