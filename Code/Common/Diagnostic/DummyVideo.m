classdef DummyVideo < handle
    
    % class properties
    properties
        
        % input arguments
        fName        
        hAx
        hImage
        
        % main field objects
        iMov
        iData
        hTimer        
        
        % function handles
        previewUpdateFcn
        
        % other scalar fields
        T0
        nFrm
        szImg
        isTrk
        iFrm 
        iFrmT = 1;               
        FPS = 5;
        dFrm = 1;        
        NumberOfBands = 3;
        isWebCam = false;
        
    end
    
    % class methods
    methods

        % --- class constructor
        function obj = DummyVideo(fName)
            
            % sets the file name
            obj.fName = fName;
            
            % initialises the class object fields
            obj.initClassFields();
            
        end
        
        % --- initialises the class object fields
        function initClassFields(obj)
            
            % initialises the temporary sub-region data struct
            obj.iMov = struct('sRate',1,'useRot',false);                        
            
            % initialises the temporary program data struct
            obj.iData = struct('movStr',[],'mObj',[],'Frm0',1,...
                               'exP',[],'nFrm',[]);
            obj.iData.exP = struct('FPS',NaN);
            obj.iData.movStr = obj.fName;
                           
            % attempts to determine if the movie file is valid
            [~,~,fExtn] = fileparts(obj.fName);
            switch fExtn
                case {'.mj2', '.mov','.mp4'}
                    % opens the video object and retrieves properties
                    obj.iData.mObj = VideoReader(obj.fName);
                    obj.iData.exP.FPS = mObj.FrameRate;
                    obj.nFrm = mObj.NumberOfFrames;
                    obj.szImg = [mObj.Height mObj.Width]; 
                    
                    % determines the final frame count (some frames at the
                    % end of videos sometimes are dodgy...)
                    while 1            
                        try 
                            % reads a new frame. 
                            read(obj.iData.mObj,obj.iData.nFrm);
                            break
                            
                        catch
                            % if there was an error, reduce the frame count
                            obj.iData.nFrm = obj.iData.nFrm - 1;
                        end
                    end                    
                    
                case '.mkv'
                    % opens the video object
                    obj.iData.mObj = ffmsReader();
                    [~,~] = obj.iData.mObj.open(obj.fName,0);
                    
                    % reads in a small sub-set of images (to determine size/frame rate)
                    [tTmp,nFrmTmp] = deal([],5);
                    for i = 1:nFrmTmp
                        [~,tTmp(i)] = obj.iData.mObj.getFrame(i-1);
                    end

                    % sets the image dimensions/video frame rate
                    obj.iData.exP.FPS = 1000/(mean(diff(tTmp)));                     
                    obj.nFrm = obj.iData.mObj.numberOfFrames;
                    obj.szImg = size(ITmp);
                    
                otherwise
                    % case is another video type
                    [V,~] = mmread(obj.fName,inf,[],false,true,'');
                    obj.iData.exP.FPS = V.rate;
                    obj.nFrm = abs(V.nrFramesTotal);
                    obj.szImg = [V.height V.width];
                    
            end            
                           
            
        end
        
        % --- start video object function
        function startVideo(obj,isTrk)
            
            % sets the tracking flag
            obj.isTrk = isTrk;
            
            % deletes any previous timer objects
            hTimerPr = timerfindall('Tag','hDummyTimer');
            if ~isempty(hTimerPr); delete(hTimerPr); end
            
            % creates the video object timer
            obj.hTimer = timer('Period',1/obj.FPS,'ExecutionMode',...
                               'fixedRate','TasksToExecute',inf,...
                               'TimerFcn',@obj.timerCallback,...
                               'Tag','hDummyTimer');
            
            % restarts the timer
            start(obj.hTimer);            
            
        end
        
        % --- stop video object function
        function stopVideo(obj)
            
            % stops the video timer
            stop(obj.hTimer)
            obj.previewUpdateFcn = [];
            
        end        
        
        % --- video timer callback function
        function timerCallback(obj,hObject,~)
            
            % increments the counter
            obj.incrementFrameCount();            
            
            % reads the new frame with the current frame
            Inw = obj.getCurrentFrame();            
            set(obj.hImage,'CData',Inw); 
            pause(0.005);
            
            % runs the preview update function (if set)
            if ~isempty(obj.previewUpdateFcn)
                % make sure Timestamp/FrameRate is correct
                iTask = get(hObject,'TasksExecuted');
                dT = roundP(1000*(iTask-1)/obj.FPS);
                Tnw = addtodate(obj.T0,dT,'millisecond');
                event = struct('Timestamp',datestr(Tnw,'HH:MM:SS.FFF'),...
                               'Data',double(Inw));
                feval(obj.previewUpdateFcn,event)
            end
            
        end
        
        % --- reads a frame stack of size, nFrmS
        function Img = getImageFrameStack(obj,nFrmS)
            
            % memory allocation
            Img = cell(nFrmS,1);
            
            % reads the frame stack
            for i = 1:nFrmS
                % reads the current frame
                Img{i} = double(obj.getCurrentFrame());
                
                % increments the counter
                obj.incrementFrameCount();
            end
            
        end
        
        % --- increments the frame counter
        function incrementFrameCount(obj)
            
            obj.iFrmT = obj.iFrmT + obj.dFrm;
            obj.iFrm = mod(obj.iFrmT-1,obj.nFrm) + 1;
            
        end        
        
        % --- retrieves the current frame from the video object
        function Img = getCurrentFrame(obj)
        
            Img = getDispImage(obj.iData,obj.iMov,obj.iFrm,0);
            
        end
        
        % --- returns the current frame index
        function iFrmC = getCurrentFrameIndex(obj)
           
            iFrmC = obj.iFrm;
            
        end
    end
        
end