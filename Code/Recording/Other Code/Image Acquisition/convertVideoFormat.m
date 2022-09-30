% --- converts the video file, vFile, to the compression type, vComp
function isOK = convertVideoFormat(vFile,vComp)

% initialisations
if ~iscell(vFile); vFile = {vFile}; end

% memory allocation
nFile = length(vFile);
isOK = false(nFile,1);
wStr0 = {'','Converting Current Video'};
h = ProgBar(wStr0((1+(nFile==1)):end),'Video Conversion');

% converts all the list video files
for iFile = 1:nFile
    % updates the overall progress (if more than one file to convert)
    if nFile > 1
        wStrNw = sprintf('Overall Progress (File %i of %i)',iFile,nFile);
        h.Update(1,wStrNw,iFile/(nFile+1));
    end        
    
    % converts the current video file
    if convertCurrentVideo(vFile{iFile},vComp,h)
        % if the conversion completed successfully, then update the flag
        isOK(iFile) = true;
    else
        % if the video conversion failed, then exit the loop
        break
    end
end

% closes the progressbar
h.closeProgBar();

% --- converts the video file, vFile, to the compression type, vComp
function ok = convertCurrentVideo(vFile,vComp,h)

% initialisations
ok = true;
nFrmW = 10;
wStr0 = 'Converting Current Video';

% determines if the video file exists
if ~exist(vFile,'file')
    % case is the file does not exist
    eStr = sprintf('The file "%s" does not exist!',vName);
    
else    
    % creates the video object
    [mObj,fType,eStr] = createVideoObj(vFile);
    if isempty(eStr)        
        % if there was no error, then rename the original file 
        [fDir,fName,~] = fileparts(vFile);        
        vFileBase = fullfile(fDir,fName);                
        nFrm = getFrameCount(mObj,fType);
        
        % creates the output video
        fExtnOut = getVideoExtn(vComp);
        vFileOut = sprintf('%s (New)%s',vFileBase,fExtnOut);
        mObjW = VideoWriter(vFileOut,vComp);   
        open(mObjW);
        
        % reads/writes the frames for the new video
        for iFrm = 1:nFrm
            % updates the progress bar
            if (mod(iFrm,nFrmW) == 1) || (iFrm == nFrm)
                wStrNw = sprintf('%s (Frame %i of %i)',wStr0,iFrm,nFrm);
                if h.Update(length(h.wStr),wStrNw,iFrm/(nFrm+1))
                    % if the user cancelled close & delete the video object
                    ok = false;
                    closeVideoObjects(mObj,mObjW);
                    delete(vFileOut);

                    % exits the function
                    return
                end
            end
            
            % writes the new frame to the video object
            writeVideo(mObjW,getNewFrame(mObj,fType,iFrm))
        end                
        
        % closes the video objects and deletes the oriinal video file
        closeVideoObjects(mObj,mObjW);
        delete(vFile)
        
        % renames the file to the original video file name        
        vFileFinal = sprintf('%s%s',vFileBase,fExtnOut);
        movefile(vFileOut,vFileFinal,'f');
    end
end


% determines if there was an error with the file conversion
if ~isempty(eStr)
    % if there was an error then output a message to screen
    waitfor(msgbox(eStr,'Video Conversion Error','modal'))
    
    % sets the output flag to false
    ok = false;
end

% --- retrieves the frame count based on the file type
function nFrm = getFrameCount(mObj,fType)

switch fType
    case {1,2}
        % case is the non-avi format videos
        nFrm = mObj.NumberOfFrames;                      
        
    case 3
        % case is avi format video
        nFrm = mObj.nFrm;
end

% --- retrieves the new frame from the video object (based on type)
function Img = getNewFrame(mObj,fType,iFrm)

% reads the new frame dependent on the file type
switch fType
    case 1
        % case is either .mov, .mj2 or .mp4
        Img = read(mObj,iFrm);
        
    case 2
        % case is the .mkv values 
        Img = mObj.getFrame(iFrm-1);
        
    case 3        
        % sets the time-span for the frame and reads it from file
        tFrm = iFrm/mObj.FPS + (1/(2*mObj.FPS))*[-1 1];
        [V,~] = mmread(mObj.movStr,[],tFrm,false,true,'');            

        % retrieves the image information (if it exists)
        if isempty(V.frames)
            Img = [];
        else
            Img = V.frames(1).cdata;        
        end                
end

% converts the image to true-colour (if only 1 band)
if ~isempty(Img)
    if size(Img,3) == 1
        Img = repmat(Img,[1,1,3]);
    end
end
    
% --- retrieves the video file extension based on the compression, vComp
function fExtn = getVideoExtn(vComp)

switch vComp
    case {'Archival','Motion JPEG 2000'}
        % case is the motion jpeg 2 format
        fExtn = '.mj2';
        
    case 'MPEG-4'
        % case is mpeg-4 format
        fExtn = '.mp4';
        
    otherwise
        % case is avi format
        fExtn = '.avi';
end

% --- creates the video file object and retrieves the video compression
%     for the video file, vFile
function [mObj,fType,eStr] = createVideoObj(vFile)

% initialisations
[mObj,fType,eStr] = deal([]);

% retrieves the video file name/extension
[~,vName,vExtn] = fileparts(vFile);

try
    % creates the video object based on the extension
    switch vExtn
        case {'.mj2', '.mov','.mp4'}
            % case is the videos that can be opened by VideoReader
            [mObj,fType] = deal(VideoReader(vFile),1);
            
        case '.mkv'
            % case is an mkv file
            [mObj,fType] = deal(ffmsReader(),2);
            [~,~] = mObj.open(vFile,0); 
            
        case '.avi'
            % case is an avi video file
            fType = 3;
            mObj = struct('movStr',vFile,'nFrm',NaN,'FPS',NaN);
            
            % retrieves the avi file information
            [mObjT,~] = mmread(vFile,inf,[],false,true,'');   
            mObj.FPS = mObjT.rate;
            mObj.nFrm = abs(mObjT.nrFramesTotal);
            
        otherwise
            % otherwise, unable to open this video type
            eStr = sprintf(['Unable to convert videos with ',...
                            '"%s" extensions'],vExtn);
    end

catch
    % if an error occured, then output an error and exit the function
    eStr = sprintf('The video "%s" appears to be corrupted.',vName);
end

% --- closes the video objects
function closeVideoObjects(mObj,mObjW)

% closes the progress bar and the video output object        
close(mObjW);

% closes the file object (if .mj2 format)
try; delete(mObj); end