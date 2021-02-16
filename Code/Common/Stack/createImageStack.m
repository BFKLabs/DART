% --- creates the image stack for the movie file, movFile, for the indices
%     [ind0 indF] sampled at the rate, sRate. if specified, the image stack
%     is output to the directory, outDir
function Istack = createImageStack(movFile,ind0,indF,sRate,outDir)

% if the numbers are characters, then convert them
if (ischar(ind0))
    [ind0,indF,sRate] = deal(str2double(ind0),str2double(indF),str2double(sRate));
end

% sets the video properties
wState = warning('off','all');
[V,~] = mmread(movFile,inf,[],false,true,'');
FPS = V.rate;
nFrmT = abs(V.nrFramesTotal);
nFrm = floor(nFrmT/sRate);

% determines the first feasible frame
[T0,Frm0] = deal(0,1);
while (1)
    [V,~] = mmread(movFile,[],T0+0.01*[-1 1],false,true,'');
    if (~isempty(V.frames))
        break
    end

    % otherwise, increment the time by the frame rate
    [T0,Frm0] = deal(T0 + 1/FPS,Frm0 + 1);
end

% memory allocation
indG = [ind0 indF];
indG = min(indG + (Frm0 - 1),nFrmT-(nFrm > 1000));         
[nStackNw,dT] = deal(diff(indG)+1,1/(2*FPS));

% sets the time of the frames and reads the image stacks
tFrm = indG/FPS + dT*[-1 1];

% retrieves the video frames from the file
[V,~] = mmread(movFile,[],tFrm,false,true,'');    
if (length(V.frames) ~= nStackNw)
    % if the incorrect number of frames were read, then re-read the frames
    % at the specified frame indices    
    [V,~] = mmread(movFile,[],tFrm,false,true,'',false);
end

% sets the frames data into the image stack
Istack = cell(length(V.frames),1);
for i = 1:length(V.frames)
    Istack{i} = double(rgb2gray(V.frames(i).cdata));    
end        
    
% turns off all warnings
warning(wState);

% if specified, the output the image stack to file (in outDir)
if (nargin == 5)
    save(fullfile(outDir,'Frame Stack.mat'),'Istack')
end