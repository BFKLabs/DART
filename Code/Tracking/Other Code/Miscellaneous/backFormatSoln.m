% backformats the solution file for changes 
function [solnData,isChange] = backFormatSoln(solnData,iData)

% initialisations
isChange = false;

% sets the data struct
iMov = solnData.iMov;
fData = solnData.fData;
exP = solnData.exP;

% pData = solnData.pData;

% ---------------------------- %
% --- MOVIE STRUCT UPDATES --- %
% ---------------------------- %

% sets the sample rate (if not set)
if ~isfield(solnData,'Frm0')
    solnData.Frm0 = 1;
end

% sets the sample rate (if not set)
if ~isfield(iMov,'sRate')
    iMov.sRate = 5;
end

% sets the fly ok fields (if not set)
if ~isfield(iMov,'flyok')
    iMov.flyok = true(iMov.nTube,length(iMov.iR));
end

% sets the fly region parameters (if not set)
if ~isfield(iMov,'autoP')
    iMov.autoP = [];
end

% sets the use RGB flag (if not set)
if ~isfield(iMov,'useRGB')
    iMov.useRGB = false;
end

% sets the fly region parameters (if not set)
if ~isfield(iMov,'nPath')
    iMov.nPath = 1;
end

% sets the fly region parameters (if not set)
if ~isfield(iMov,'sepCol')
    iMov.sepCol = false;
end

% sets the fly region parameters (if not set)
if isfield(iMov,'pC')
    iMov = rmfield(iMov,'pC');
end

% removes the rotate 90 field (if set)
if isfield(iMov,'rot90')
    % if the field is set, then reset the rotation fields
    if iMov.rot90
        [iMov.useRot,iMov.rotPhi] = deal(true,90);
    end
    
    % removes the field
    iMov = rmfield(iMov,'rot90');
end

% adds in the use rotation field
if ~isfield(iMov,'useRot')
    [iMov.useRot,iMov.rotPhi] = deal(false,0);
end

% sets an empty direct-detection field (if not set)
if ~isfield(iMov,'ddD')
    iMov.ddD = [];
end

% resets/initialises the background parameter struct
if isfield(iMov,'bgP') && ~isempty(iMov.bgP)
    % retrieves the background parameter field
    iMov.bgP = DetectPara.resetDetectParaStruct(iMov.bgP);
else
    % otherwise, initialise the detection parameter struct
    iMov.bgP = DetectPara.initDetectParaStruct('All');
end

% resets any old format automatic detection fields
if ~isempty(iMov.autoP)
    iMov.autoP = backFormatRegionParaStruct(iMov.autoP);
end

% sets the fly region parameters (if not set)
if isfield(iMov,'Status')
    % resets the flags for all the frames
    for i = 1:length(iMov.Status)
        iMov.Status{i}(iMov.Status{i} == -1) = 2;
        iMov.Status{i}(iMov.Status{i} == -2) = 3;
    end
end

% if the video phase has not been accounted for, then include it in the
% sub-region data struct
if ~isfield(iMov,'vPhase')
    iMov.vPhase = 1;
    iMov.iPhase = [1 iData.nFrm];        
    if (length(iMov.Ibg) ~= 1) && initDetectCompleted(iMov)
        iMov.Ibg = {iMov.Ibg};
    end
end

% sets the regional fly tube flag/array if not set
if ~isfield(iMov,'dTube')
    [iMov.dTube,iMov.nTubeR] = deal(false,[]);
end

% sets the regional fly tube flag/array if not set
if ~isfield(iMov,'nFlyR')
    [iMov.nFly,iMov.nFlyR] = deal(1,[]);
end

% sets the fly ok fields (if not set)
if ~isfield(iMov,'nDS')
    iMov.nDS = 1;
end

% sets the orientation angle calculation flag (if not set)
if ~isfield(iMov,'calcPhi')
    iMov.calcPhi = false;
end

% sets the orientation angle calculation flag (if not set)
if ~isfield(iMov,'vGrp')
    iMov.vGrp = [];
end

% sets the 2D check field
if ~isfield(iMov,'is2D')
    iMov.is2D = is2DCheck(iMov);
end

% sets the 2D check field
if ~isfield(iMov,'szObj')
    iMov.szObj = 5*[1,1];
end

% sets the sub-region information struct
if ~isfield(iMov,'pInfo')
    iMov.pInfo = getRegionDataStructs(iMov);
end
    
% -------------------------------------- %
% --- POSITIONAL DATA STRUCT UPDATES --- %
% -------------------------------------- %

if isfield(solnData,'pData')
    % loads the data struct
    pData = solnData.pData;
    
    % updates the data struct
    solnData.pData = pData;        
end

% -------------------------------- %
% --- TUBE DATA STRUCT UPDATES --- %
% -------------------------------- %

% removes the tube-data structs
if isfield(solnData,'tData')
    % retrieves the necessary fields from the data struct
    tData = solnData.tData;
    iMov.Status = field2cell(tData,'Status');        
    if isfield(tData,'iC')
        [iRT,iCT] = field2cell(tData,[{'iR'},{'iC'}]);
    else
        [yEdge,iCTa] = field2cell(tData,[{'yEdge'},{'xEdge'}]);
        iCT = cellfun(@(x)(x(1):x(2)),iCTa,'un',0);        
        iRT = cellfun(@(x)(cellfun(@(y)(floor(y(1)):ceil(y(2))),...
                num2cell(x,2),'un',0)),yEdge,'un',0);
    end
        
    % sets the positional vector    
    for j = 1:length(iMov.iC)        
        % resets the sub-image horizontal dimensions
        iMov.pos{j}(1) = iMov.pos{j}(1) + (iCT{j}(1)-1);
        iMov.pos{j}(3) = length(iCT{j});
        
        % resets the sub-image vertical dimensions
        iRTall = cell2mat(iRT{j}'); 
        iMov.pos{j}(2) = iMov.pos{j}(2) + (iRTall(1)-1);
        iMov.pos{j}(4) = length(iRTall);
        
        % sets the row indices of the tubes
        iMov.iRT{j} = cellfun(@(x)(x-(iRTall(1)-1)),...
                                    iRT{j},'un',0);
        
        % sets the x/y range of the tube
        Yrange = iMov.pos{j}(2)+[0 iMov.pos{j}(4)];
        Xrange = iMov.pos{j}(1)+[0 iMov.pos{j}(3)];
    
        % sets the row/column indices to be y/x pixel range
        iMov.iR{j} = ceil(Yrange(1)):floor(Yrange(2));
        iMov.iC{j} = ceil(Xrange(1)):floor(Xrange(2));
        
        % sets the locations of the tubes
        yExt = Yrange(1) + (diff(Yrange)/iMov.nTube)*(0:iMov.nTube)';
        iMov.xTube{j} = Xrange - iMov.pos{j}(1);
        iMov.yTube{j} = [yExt(1:(end-1)) yExt(2:end)] - iMov.pos{j}(2);                
    end
        
    for i = 1:length(pData.fPos)
        for j = 1:length(pData.fPos{1})            
            pData.fPos{i}{j}(:,1) = pData.fPos{i}{j}(:,1) + (iMov.iC{i}(1)-(iCT{i}(1)+1));
            pData.fPos{i}{j}(:,2) = pData.fPos{i}{j}(:,2) - (iRT{i}{1}(1)-1);
        end
    end
    
    % loads the data struct
    solnData.pData = pData; 
    solnData = rmfield(solnData,'tData');
end

% --------------------------------- %
% --- DATA STRUCT HOUSE-KEEPING --- %
% --------------------------------- %

% resets the data struct
solnData.iMov = iMov;
solnData.fData = fData;
solnData.exP = exP;
