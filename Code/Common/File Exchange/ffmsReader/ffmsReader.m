% using class :
%
% obj = ffmsReader();
% res = obj.open('C:\DCI\C\tests\x264_encoder\test.mkv',1); %opens file in
%                                                           %rgb mode
% % if res is 0 then error occured when opening the file
%
% if (res != 0)
%  	error(obj.getLatestErrorMessage())
%	delete(obj)
% end
%
% nframes = obj.numberOfFrames(); % read number of frames
% 
% for i=0:nframes-1
%
%   [image, timeStamp] = obj.getFrame(i); % timeStamp is in msec
%   do something with the image
%
% end 
% obj.close() % closes the file
%
% delete(obj)

classdef ffmsReader < handle
    properties (Hidden = true, SetAccess = private)
        cpp_handle;
        
        
    end
%     properties
%         Name; % filename
%         NumberofFrames;
%         Duration;% Approximate Duration is in minutes,assuming fps as 30.
%     end
    methods
        
        % Constructor
        function this = ffmsReader()
            this.cpp_handle = ffms_mex;
        end
        
        % Destructor
        function delete(this)
            ffms_mex(this.cpp_handle);
        end
%        
        
        function [res,filename] = open(this,filename, rgb)
            if (rgb == 0)
                option =3;
            else
                option =0;
            end
            res=ffms_mex(this.cpp_handle,1,filename,option);
            nframes = ffms_mex(this.cpp_handle,4);
%             this.NumberofFrames = nframes;
%             this.Name = filename;
%             this.Duration = nframes/(30*60);
        end
       
        
        function close(this)
            ffms_mex(this.cpp_handle,2);
        end
        
        function msg = getLatestErrorMessage(this)
            msg = ffms_mex(this.cpp_handle,3)
        end
        
        function nframes = numberOfFrames(this)
            nframes = ffms_mex(this.cpp_handle,4);
        end
        
        function [image, timeStamp] = getFrame(this, framenumber)
            [image, timeStamp] = ffms_mex(this.cpp_handle,5,framenumber);

%          image = imcrop(image,[48,48,355,368]); Commented out for running
%          zebrafish video
            if (ndims(image) == 3)
                image = permute( image,[3,2,1] );
            end
           
            if (ndims(image) == 2)
                image = permute( image,[2,1] );
%               image = imcrop(image,[40,27,380,380]); Commented out for
%               running zebrafish video
            end
        end
    end
end