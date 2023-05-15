% --- creates the video object for the video file, vidFile
function [mObj,vObj,ok] = setupVideoObject(vidFile,varargin)

% initialisations
[~,~,fExtn] = fileparts(vidFile);
[mObj,vObj,ok] = deal([],[],false);

% attempts to determine if the movie file is valid
if exist(vidFile,'file')
    try
        % uses the later version of the function 
        switch fExtn
            case {'.mj2', '.mov','.mp4'}
                mObj = VideoReader(vidFile);
            case '.mkv'
                mObj = ffmsReader();
                [~,~] = mObj.open(vidFile,0);        
            otherwise
                mObj = VideoReader(vidFile);
                [vObj,~] = mmread(vidFile,inf,[],false,true,'');
        end
        
        % flag that the video object was a success
        ok = true;
        
    catch
        % if an error occured, then output an error and exit the function
        if nargin == 1
            eStr = ['Error! Video appears to be corrupted. ',...
                    'Suggest deleting file.'];
            waitfor(errordlg(eStr,'Corrupted Video File','modal'))
        end       
    end
    
end