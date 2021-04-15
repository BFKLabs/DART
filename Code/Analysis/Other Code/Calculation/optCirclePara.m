% --- optimises the circle parameters from the background image
function [pCF,pC,R] = optCirclePara(iMov,indC0,Type)

if Type == 2
    % retrieves the circle outline coordinates
    indC = unique(indC0);
    [X0,Y0,XC,YC] = getCirclePara(iMov.autoP,{'X0','Y0','XC','YC'});
    
    % sets the output values
    R = iMov.autoP.R*ones(length(indC0),1);
    pC = [arr2vec(X0(:,indC)),arr2vec(Y0(:,indC))];    
    pCF = cellfun(@(x)([x(1)+XC,x(2)+YC]),num2cell(pC,2),'un',0);
    
else
    [pCF,pC,R] = optCircleParaOld(iMov,indC0);
end


% --- runs the old circle parameter 
function [pCF,pC,R] = optCircleParaOld(iMov,indC0)

% initialisations
[nTube,indC,sTol,dsTol,dR] = deal(iMov.nTube,unique(indC0),0.95,0.005,4);

% retrieves the background images
if iscell(iMov.Ibg{1})
    i0 = find(cellfun(@(x)(~isempty(x{1})),iMov.Ibg),1,'first');
    Ibg = iMov.Ibg{i0}(indC);
else
    Ibg = iMov.Ibg(indC);
end     

% initialisations
[Rrng,R0] = deal(iMov.autoP.R + 5*[-1 1],iMov.autoP.R);
[pC,pCF,R] = deal(cell(length(indC),1)); 
nReg = cellfun(@(x)(sum(indC0 == x)),num2cell(unique(indC0)));            

% sets the local background image for each fly 
IbgL = cell(length(Ibg),1);
for i = 1:length(Ibg)
    % sets the background image for the current column index group
    IbgL{i} = adapthisteq(uint8(Ibg{i}));

    % runs the circle finding algorithm for bright/dark polarity       
    [pB,RB] = imfindcircles(IbgL{i},Rrng,'Method','TwoStage',...
                        'ObjectPolarity','bright','Sensitivity',sTol);
    [pD,RD] = imfindcircles(IbgL{i},Rrng,'Method','TwoStage',...
                        'ObjectPolarity','dark','Sensitivity',sTol);                        

    % determine which polarities have the correct circle count
    [nB,nD] = deal(length(RB),length(RD));                
    switch ((nB >= nReg(i)) + 2*(nD >= nReg(i)))
        case (3) % both polarities have at least the correct count
            if (sum(abs(R0-RB)) < sum(abs(R0-RD)))
                % bright polarities have radii closer to original
                [p0nw,Rnw] = deal(pB,RB);    
            else
                % dark polarities have radii closer to original
                [p0nw,Rnw] = deal(pD,RD);    
            end
        case (2) % dark polarities have the correct count
            [p0nw,Rnw] = deal(pD,RD);
        case (1) % bright polarities have the correct count
            [p0nw,Rnw] = deal(pB,RB);
        otherwise % FINISH ME!!
            if (nB > 0) && (nD == 0)
                [p0nw,Rnw] = deal(pB,RB); 
            elseif (nB == 0) && (nD > 0)
                [p0nw,Rnw] = deal(pD,RD); 
            else
                disp('Finish Me!')
            end
    end

    % keep searching if the circle count is not the same as required
    while (length(Rnw) < nReg(i)) || (length(Rnw) > nTube)
        % applies the new sensitivity threshold to the circle detection
        sTol = sTol + (1-2*(length(Rnw)>nTube))*dsTol;
        [p0nw,Rnw] = imfindcircles(IbgL{i},Rrng,'Method','TwoStage',...
                        'ObjectPolarity','dark','Sensitivity',sTol);                                          
    end
    
    % sorts coordinates of the 
    [~,iSort] = sort(p0nw(:,2));
    [p0nw,R{i}] = deal(p0nw(iSort,:),Rnw(iSort));
    
    % matches the circle centres to the vertical location 
    [pos0,Rmx] = deal(iMov.pos{indC(i)},max(R{i}));
    pC{i} = [(p0nw(:,1)+pos0(1)),(p0nw(:,2)+pos0(2))];
    
    % calculates the circle coordinates
    pCF{i} = cellfun(@(x)...
                (setupCircleCoords(x,Rmx+dR)),num2cell(pC{i},2),'un',0);    
end   

% combines the cell arrays into a single array
[pC,pCF,R] = deal(cell2cell(pC),cell2cell(pCF),cell2cell(R));
