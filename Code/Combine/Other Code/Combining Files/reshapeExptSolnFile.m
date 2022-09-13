% --- reshapes the data from the experimental solution files so that
%     the data values (position, angle etc) are grouped properly
function snTot = reshapeExptSolnFile(snTot)

% determines if the orientation angles were calculated
iMov = snTot.iMov;
if isfield(iMov,'calcPhi')
    calcPhi = iMov.calcPhi;
else
    calcPhi = false;
end

% sets up the fly configuration ID flags for each grouping
snTot.cID = setupFlyLocID(iMov,true);

% memory allocation
nGrp = length(snTot.cID);
[Px,Py] = deal(cell(nGrp,1));
[Px0,Py0] = deal(snTot.Px,snTot.Py);
isMltTrk = detMltTrkStatus(iMov);

% initialises data for the orientation angle data values
if calcPhi
    [Phi,AxR] = deal(cell(nGrp,1)); 
    [Phi0,AxR0] = deal(snTot.Phi,snTot.AxR);
end

%
for i = 1:nGrp
    % groups the data values based on setup type
    [iRow,iCol] = deal(snTot.cID{i}(:,1),snTot.cID{i}(:,2));
    if isMltTrk
        % case is a multi-tracking expt
        Px{i} = getGroupValuesMT(Px0,iRow,iCol);
        Py{i} = getGroupValuesMT(Py0,iRow,iCol);

        % retrieves the orientation angle data values
        if calcPhi
            Phi{i} = getGroupValuesMT(Phi0,iRow,iCol);
            AxR{i} = getGroupValuesMT(AxR0,iRow,iCol);
        end                      
        
    elseif iMov.is2D
        % case is a 2D expt setup  
        
        % retrieves the positional values (if they exist)
        Px{i} = getGroupValues2D(Px0,iRow,iCol); 
        Py{i} = getGroupValues2D(Py0,iRow,iCol); 
        
        % retrieves the orientation angle data values
        if calcPhi
            Phi{i} = getGroupValues2D(Phi0,iRow,iCol);
            AxR{i} = getGroupValues2D(AxR0,iRow,iCol);
        end              
        
    else
        % case is a 1D expt setup
        
        % retrieves the sub-region indices for each fly
        iFly = snTot.cID{i}(:,3);
        iReg = (iRow-1)*snTot.iMov.pInfo.nCol + iCol;
        
        % retrieves the positional values 
        Px{i} = getGroupValues1D(Px0,iReg,iFly);
        if ~isempty(Py0)
            Py{i} = getGroupValues1D(Py0,iReg,iFly);            
        end
    end
end

% updates the metric values into the experimental solution file data struct
if ~isempty(snTot.Px); snTot.Px = Px; end
if ~isempty(snTot.Py); snTot.Py = Py; end
if calcPhi; [snTot.Phi,snTot.AxR] = deal(Phi,AxR); end

% --- retrieves the values from the array, Z for the grid row/column
%     indices, iRow/iCol (for a 2D expt setup)
function Zf = getGroupValuesMT(Z,iRow,iCol)

Zf = cell2mat(arrayfun(@(ir,ic)(Z{ir}(:,ic)),iRow,iCol,'un',0)');

% --- retrieves the values from the array, Z for the grid row/column
%     indices, iRow/iCol (for a 2D expt setup)
function Zf = getGroupValues2D(Z,iRow,iCol)

Zf = cell2mat(arrayfun(@(ir,ic)(Z{ic}(:,ir)),iRow,iCol,'un',0)');

% --- retrieves the values from the array, Z for the grid row/column and
%     sub-region indices, iRow/iCol/iFly (for a 1D expt setup)
function Zf = getGroupValues1D(Z,iReg,iFly)

% memory allocation
Zf = cell2mat(arrayfun(@(i,j)(Z{i}(:,j)),iReg,iFly,'un',0)');