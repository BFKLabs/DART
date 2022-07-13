% --- sets the quadrant frame colour indices
function iColC = setQuadrantFrameCol(snTot,isGr)

% sets the default input arguments
if ~exist('isGr','var'); isGr = true; end

% memory allocation
qStr = 'BG';
nFrm = length(cell2mat(snTot.T(:)));
iColC = NaN(nFrm,4);

% retrieves the phase-timing external data struct
iP = strcmp(cellfun(@(x)(x.pStr),snTot.exD,'un',0),'PhaseTiming');
Data = snTot.exD{iP}.Data;
iFrm = cellfun(@str2double,Data(:,1:2));
DataC = Data(:,3:end);

% sets the colour indices for each frame/quadrant
for i = 1:size(iFrm,1)
    xiC = iFrm(i,1):iFrm(i,2);
    for j = 1:size(DataC,2)
        iColC(xiC,j) = strcmp(DataC{i,j},qStr(1+isGr));
    end
end