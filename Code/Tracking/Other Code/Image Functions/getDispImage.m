% --- retrieves the image to be displayed on the main image axes ----------
function Img = getDispImage(iData,iMov,cFrm,isSub,handles,varargin)

% global variables
global bufData

% checks if the movie file data has been set
frameSet = false;

% sets the use grayscale flag
if isempty(varargin)
    useRGB = false;
else
    if isfield(iMov,'useRGB')
        useRGB = iMov.useRGB;
    else
        useRGB = true;
    end
end

% check to see if the buffer data has been set. if so, then check to see if
% the frame stacks have been set correctly. if such data is available, then
% retrieve the frame from the image stack
if ~isempty(bufData)
    % pause until the array change has finished
    while bufData.changeArray
        pause(0.01);
    end
    
    % sets the image stack group index    
    try
        bufData.changeArray = true;        
        while (1)
            indGrp = floor(bufData.iL/bufData.fDel)+4;    
            if (~any(indGrp == [1 6]))
                break
            else
                pause(0.01);
            end
        end
                       
        if ~isempty(bufData.I{indGrp})
            % if the image stack has been set, then retrieve the image            
            Img = bufData.I{indGrp}{mod(bufData.iL,bufData.fDel)+1};
            frameSet = true;
        end

        % sets the check flag to false again
        bufData.changeArray = false;
    catch ME
        bufData.changeArray = false;
        a = 1;
    end
end
    
if ~frameSet
    if ~isfield(iData,'movStr')
        % data movie string not set, so exit the function
        Img = [];
        return
    end    
    
    % otherwise, retrieves the file extension
    [~,~,fExtn] = fileparts(iData.movStr);
    cFrmT = iMov.sRate*(cFrm-1) + iData.Frm0;
    
    % loads the frame based on the movie type
    switch fExtn    
        case {'.mj2','.mov','.mp4'} 
            % case is a moving JPEG movie/quicktime movie
            if isfield(iData,'mObj')
                % movie object is provided in the Data struct
                mObj = iData.mObj;
            else
                % retrieves the main gui handle (if not provided)
                if (nargin < 5) || isempty(handles)
                    handles = guidata(findall(0,'tag','figFlyTrack'));
                end
                
                % retrieves the movie object handle
                mObj = get(handles.figFlyTrack,'mObj');
            end
                
            % if the frame index exceeds the max frame count then exit
            if cFrmT > mObj.NumberOfFrames
                Img = [];
                return
            end
               
            % reads the new image (converts to grayscale if truecolor)
            Img = read(mObj,cFrmT); 
            if (size(Img,3) == 3) && ~useRGB
                Img = rgb2gray(Img); 
            end            
            
        case '.mkv' 
            % case is matroska video format
            if isfield(iData,'mObj')
                % movie object is provided in the Data struct
                mObj = iData.mObj;
            else
                % retrieves the main gui handle (if not provided)
                if nargin < 5
                    handles = guidata(findall(0,'tag','figFlyTrack'));
                end
                
                % retrieves the movie object handle
                mObj = get(handles.figFlyTrack,'mObj');
            end
            
            % reads the new image (converts to grayscale if truecolor)            
            Img = mObj.getFrame(cFrmT-1);
            if (size(Img,3) == 3) && ~useRGB
                Img = rgb2gray(Img); 
            end
            
            
        otherwise
            % case is the other movie types
            try
                % sets the time-span for the frame and reads it from file
                tFrm = cFrmT/iData.exP.FPS + (1/(2*iData.exP.FPS))*[-1 1];
                [V,~] = mmread(iData.movStr,[],tFrm,false,true,'');            

                % converts the RGB image to grayscale
                if isempty(V.frames)
                    Img = [];
                else 
                    Img = V.frames(1).cdata;
                    if (size(Img,3) == 3) && ~useRGB
                        Img = rgb2gray(Img);
                    end
                end
                
            catch ME
                % if an error occured, then return an empty array
                Img = [];
                return
            end
    end
end
    
% % rotates the image (if necessary)
% switch (iData.sgP.rType)
%     case (1) % case is rotating by 90 deg
%         Img = Img(end:-1:1,:); Img = Img';
%     case (2) % case is rotating by 270 deg
%         Img = Img(end:-1:1,:);
%         Img = Img(:,end:-1:1)'; 
%         Img = Img(:,end:-1:1);        
% end

% rotates the image (if required)
if isempty(Img)
    szImg = getCurrentImageDim();
    if any(isnan(szImg))
        Img = [];
    else
        Img = NaN(szImg);
    end
else
    Img = getRotatedImage(iMov,Img);
end

% if iMov.rot90; Img = rot90(Img,-1); end

% sets the image with the sub-image coordinates (if sub-image selected)
if isSub && ~isempty(Img)
    % retrieves the main gui object handles (if not provided)
    if ~exist('handles','var')
        handles = guidata(findall(0,'tag','figFlyTrack'));
    end
    
    % retrieves the sub-image
    Img = setSubImage(handles,Img);
end