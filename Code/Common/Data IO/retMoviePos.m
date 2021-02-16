% --- retrieves the fly locations, P, from the position movie object, nObj,
%     given the position mapping parameter struct, pMap. the positions are
%     returned as a cell array for each of the movie files, given in mName
function P = retMoviePos(pMap,mName,indFrm,h)

% if no frame/fly indices are specified, then set them all
nFile = length(mName);
P = cell(length(pMap),1);

% sets the number of frames
nFrameT = field2cell(pMap,'nFrame',1);
ii = find(~isnan(nFrameT));
if ~isempty(ii); nFrame = nFrameT(ii(1)); end

% sets the default frame indices (if not set)
if nargin < 3; indFrm = []; end
if isempty(indFrm); indFrm = 1:nFrame; end

% creates the waitbar figure/properties
try
    if nargin < 4
        [wStr,wOfs] = deal({'Loading Frames'},0);
        h = ProgBar(wStr,'Loading Movie Positions');
    else
        wOfs = 1 + (length(h.wStr) > 2);
    end
catch
    % user cancelled, so exit the function
    P = []; return
end
    
% loops through each file loading the position values
for i = 1:nFile
    % updates the waitbar figure
    wStrNw = sprintf('Loading Movie Positions (Region %i of %i)',i,nFile);
    if h.Update(1+wOfs,wStrNw,i/(nFile+1))
        % if the user cancelled, then exit
        P = []; return
    end
        
    try
        % sets the index of the position array to be used
        mStr = getFileName(mName{i});    
        j = str2double(mStr(3:end));
        if isnan(j); j = 1; end

        % reads the current file
        mObj = VideoReader(mName{i});
        P{j} = rescaleMoviePos(mObj,pMap(j),indFrm);
        
    catch ME
        if strContains(ME.message,'Out of memory')
            % updates the waitbar figure
            wStrNw = sprintf(['Retry Loading Movie Positions ',...
                              '(Region %i of %i)'],i,nFile);
            h.Update(1+wOfs,wStrNw,i/(nFile+1))
            
            % saves a temporary copy of the position data array and then
            % clears it from memory
            save('TempP','P');
            clear P;
            
            % retry reading the positional data from the solution file,
            % reload the positional data array and stores the data
            try
                Pnw = rescaleMoviePos(mObj,pMap(j),indFrm);
                load('TempP'); delete('TempP.mat');
                P{j} = Pnw;
            catch ME
                if (strContains(ME.message,'Out of memory'))
                    % if there is still a memory issue then output an error
                    % message stating the the user needs to free up memory
                    eStr = sprintf(['Error! Not enough memory to open ',...
                                    'solution file. Suggest closing and ',...
                                    'reopening DART to fix problem']);
                    waitfor(errordlg(eStr,'Insufficient Memory','modal'))
                    
                    % closes the waitbar figure and returns an empty array
                    close(h); P = []; return
                else
                    % otherwise, rethrow the error
                    close(h); rethrow(ME)                    
                end
            end
        else
            % otherwise, rethrow the error
            close(h); rethrow(ME)
        end
    end
end

% updates the waitbar figure
if nargin < 4
    h.closeProgBar()
else
    h.Update(1+wOfs,'Movie Position Loading Complete!',1);
end   

% --- rescales the position movie values --- %
function P = rescaleMoviePos(mObj,pMap,indFrm)

% fly/frame indices
indFly = (1:pMap.nFly);
nFrame = length(indFrm);

% determines the image frame range
A = floor((indFrm([1 end])-1)/pMap.Wmov)+1;
B = (A(1):A(2))';
C = pMap.Wmov*B(1:end-1);

% sets the column, row and image indices to be read
indCol = num2cell(mod([[indFrm(1);(C+1)],[C;indFrm(end)]]-1,pMap.Wmov)+1,2);
indRow = num2cell(mod(B-1,pMap.nRep) + 1);
indImg = num2cell(floor((B-1)/pMap.nRep) + 1);
clear A B C; pause(0.01);

% reads the image stack into a cell array stack
II = read(mObj,[indImg{1} indImg{end}]); 
Img = cellfun(@(x)(II(:,:,1,x)),num2cell(1:size(II,4)),'un',0); 
clear II indFrm mObj; pause(0.01)

% retrieves the indices from the frames
x0 = indImg{1} - 1;
PP = cellfun(@(x,y,z)(Img{x-x0}((y-1)*pMap.nFly+indFly,(z(1):z(2)))),...
                        indImg,indRow,indCol,'un',0)';
clear Img indCol indRow; pause(0.01)
                    
% converts the pixel values to the positional coordinates
Xmax = repmat(pMap.xMax,1,nFrame);
Xmin = repmat(pMap.xMin,1,nFrame);
Xi = ((double(cell2mat(PP))-1)/pMap.pScale);
clear PP Img indCol; pause(0.01)

% converts values to a cell array
if (iscell(Xmin))
    [Xmin,Xmax] = deal(cell2mat(Xmin),cell2mat(Xmax));	
end

% rescales the fly locations from normalised coordinates to actual
% coordinates. all Xi values less than zero are set as NaNs
dX = (Xmax - Xmin).*Xi;
clear Xmax; pause(0.01);

P = (Xmin + dX);
P(Xi<0) = NaN;
clear Xmin Xi; pause(0.01);

% transposes the array
P = P';
