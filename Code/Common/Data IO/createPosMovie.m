% --- creates the position movie from the position array, P. it is assumed
%     that the data is stored in a cell array (with each element 
%     corresponding to a given movie solution file). Each element
%     consists of another cell array for each apparatus, with each 
%     element of the sub-cell array corresponding to the positions of
%     the flies within (over all flies within the apparatus). returned
%     is the mapping key, pMap, which is used to recalculate the 
%     positions and indices of the flies within the movie --- %
function [pMap,ok] = createPosMovie(P,mName,isPhi,h)

% global variables
global wOfs

% sets the output file name (if not provided)
if nargin == 1 
    mName = 'Test.mj2'; 
end

% sets up the waitbar figure properties
if nargin < 3
    % if not provided, 
    wOfs = 0;
    wStr = {'Current Experiment Progress','Output Data Field'};    
    h = ProgBar(wStr,'Position Movie Setup');  
else
    wOfs = 1;
end

% determines the number of apparatus to output the data for
[ok,nApp] = deal(true,length(mName));
pMap = cell(nApp,1);

% creates a movie object for each file
for i = 1:nApp
    % updates the waitbar figure
    wStrNw = sprintf('%s (Region %i of %i)',h.wStr{1},i,nApp);
    if h.Update(1+wOfs,wStrNw,i/(1+nApp))
        % closes the movie and deletes all temporary movies
        cellfun(@delete,mName(1:i)); 
        
        % returns a false flag
        ok = false;
        return        
    end
    
    % determines if there is data to output
    if isempty(P{i})
        % if not, then set an empty map data struct
        pMap{i} = initMapDataStruct([]);   
        
    else
        % creates and opens the movie object
        mObj = VideoWriter(mName{i},'Archival'); open(mObj); 

        % creates the position image stack
        pMap{i} = setupPosImageStack(mObj,P{i}',isPhi,h);
    end
end

% closes the waitbar figure (if created within the function)
pMap = cell2mat(pMap);
if nargin < 3
    h.closeProgBar()
else
    h.Update(2,'Position Movie Creation Complete!',1);
end
    
% --- sets up the position image stack for the position movie --- %
function [pMap,ok] = setupPosImageStack(mObj,P,isPhi,h)
                    
% if this is the first apparatus, then 
pMap = initMapDataStruct(P,isPhi);
mapInd = setupMappingArray(P,pMap);        

% sets the min/max x-values
if isPhi
    [nTube,Ymx] = deal(size(P,1),180-(1/2^16));
    [pMap.xMin,pMap.xMax] = deal(-Ymx*ones(nTube,1),Ymx*ones(nTube,1));
else
    pMap.xMin = min(P,[],2,'omitnan');
    pMap.xMax = max(P,[],2,'omitnan');
end

% normalises the pixel values
dX = pMap.xMax - pMap.xMin;
Xmin = repmat(pMap.xMin,1,pMap.nFrame);
Xmax = repmat(pMap.xMax,1,pMap.nFrame);
P = roundP(pMap.pScale*(P - Xmin)./(Xmax - Xmin),1) + 1;
P(dX==0,:) = 1;

% calculates the new image stack for the current apparatus
ok = setAppImageStack(mObj,P,mapInd,isPhi,h);

% closes the movie object
close(mObj)

% --- determines the mapping indices
function mapInd = setupMappingArray(Pnw,pMap)

% memory allocation
[nFlyNw,nFrame] = size(Pnw);
[indCol,indRow] = meshgrid(1:nFrame,1:nFlyNw);
indPos = sub2ind(size(Pnw),indRow,indCol);
Hmov = pMap.nRep*nFlyNw;
nStack = ceil(nFrame/(pMap.Wmov*pMap.nRep));

% clears extraneous variables
clear Pnw; pause(0.01);

% determines the column indices
indG = cellfun(@(x)(((x-1)*pMap.Wmov+1):min(nFrame,x*pMap.Wmov)),...
                    num2cell(1:ceil(nFrame/pMap.Wmov))','un',0);
                
% sets the index positions for each image width, and pads the last index 
% array with NaNs to ensure all the arrays are the same width
indPosG = cellfun(@(x)(indPos(:,x)),indG,'un',0);   
indPosG{end} = [indPosG{end},NaN(nFlyNw,pMap.Wmov-size(indPosG{end},2))];

% sets the mapping indices
indFrm = cellfun(@(x)(((x-1)*pMap.nRep+1):min(length(indPosG),x*pMap.nRep)),...
                    num2cell(1:nStack)','un',0);                
mapInd = cellfun(@(x)(cell2mat(indPosG(x))),indFrm,'un',0);
mapInd{end} = [mapInd{end};NaN(Hmov-size(mapInd{end},1),pMap.Wmov)];                

% --- sets the fly positions into the image stack --- %
function ok = setAppImageStack(mObj,P,mapInd,isPhi,h)

% global variables
global wOfs

% memory allocation
[nStack,ok] = deal(length(mapInd),true);

% sets the new image and adds the frame to the movie
for i = 1:nStack
    % updates the waitbar figure
    wStrNw = sprintf('Adding Movie Frame (%i of %i)',i,nStack);
    if h.Update(2+wOfs,wStrNw,i/nStack)
        % if the user cancelled, then exit the function
        ok = false;
        return
    end
    
    % sets up the new image
    [A,posImg] = deal(~isnan(mapInd{i}),zeros(size(mapInd{i})));
    posImg(A) = P(mapInd{i}(A));    
    
    % adds the frame to the movie
    if isPhi
        writeVideo(mObj,uint16(posImg))
    else
        writeVideo(mObj,uint8(posImg))
    end
end

% --- initialises the mapping data struct --- %
function pMap = initMapDataStruct(P,isPhi)

% allocates memory for the data struct
pMap = struct('Wmov',NaN,'nRep',NaN,'pScale',NaN,'nFly',[],'nFrame',NaN,...
              'xMin',[],'xMax',[]);

% if not an empty field, then set the fields          
if ~isempty(P)          
    % initialises the segmentation parameter struct
    [pMap.Wmov,pMap.nRep,pMap.pScale] = deal(1000,40,256^(1+isPhi));
    [pMap.nFly,pMap.nFrame] = size(P);
    
    % sets the min/max x-values
    pMap.xMin = min(P,[],2,'omitnan');    
    pMap.xMax = max(P,[],2,'omitnan');
end