classdef AvgVidIntensity < handle
    
    % properties
    properties
        
        % class object fields
        fDir
        fName
        fExtn
        
        % video file dimensions      
        FPS 
        mObj
        nFrm
        nFrmT 
        fFile
        
        % other class fields
        Iavg
        hProg
        
        % scalar/boolean class fields
        ok = true;
        nFile = 0;
        sRate = 5;        
        
    end
    
    % class methods
    methods
        % class constructor
        function obj = AvgVidIntensity(fDir,fExtn)
            
            % sets the input arguments
            if ~exist('fDir','var'); fDir = pwd; end
            if ~exist('fExtn','var'); fExtn = '*.avi'; end
            
            % sets the class fields
            obj.fDir = fDir;
            obj.fExtn = fExtn;
            
            % searches the directory for the file type
            fFile0 = dir(fullfile(fDir,fExtn));
            if isempty(fFile0)
                % if there are no files then exit with an error
                obj.ok = false;
                return
            end
            
            % retrieves the file names
            obj.fName = arrayfun(@(x)(x.name),fFile0,'un',0);
            obj.nFile = length(obj.fName);            
            
        end
        
        % --- analyses all the video in the directory
        function analyseAllVid(obj)
           
            % exit if no valid files
            if obj.nFile == 0
                return
            end
            
            % deletes any previous progressbars
            if ~isempty(obj.hProg)
                obj.hProg.closeProgBar()
            end
            
            % memory allocation
            obj.Iavg = cell(obj.nFile,1);
            
            % creates the waitbar figure
            tStr = 'Video Intensity Analysis';
            wStr = {'Overall Progress','Current File Progress'};
            obj.hProg = ProgBar(wStr,tStr);
            
            % analyses each of the video files
            for i = 1:obj.nFile
                % updates the progressbar
                wStrNw = sprintf('%s (File %i of %i)',wStr{1},i,obj.nFile);
                if obj.hProg.Update(1,wStrNw,i/(1+obj.nFile))
                    % exit if the user cancelled
                    obj.ok = false;
                    return
                end
                
                % analyses the video file
                obj.analyseSingleVid(i);                
            end
            
            % updates and closes the progressbar
            obj.hProg.Update(1,'All Videos Analysed',1);
            pause(0.5);
            obj.hProg.closeProgBar();
            
        end
        
        % --- analyses a single video given by the file index, iFile
        function analyseSingleVid(obj,iFile)
           
            % updates the progress bar
            obj.hProg.Update(2,'Loading Video File...',0);
            
            % loads the video file
            obj.loadVideoFile(iFile);
            
            % memory allocation
            obj.Iavg{iFile} = NaN(obj.nFrm,1);
            
            % calculate the mean pixel intensity for each video frame
            for i = 1:obj.nFrm
                % updates the progressbar
                wStr = sprintf('Reading Video Frame (%i of %i)',i,obj.nFrm);
                if obj.hProg.Update(2,wStr,i/(1+obj.nFrm))
                    % exit if the user cancelled
                    obj.ok = false;
                    return
                end                
                
                % reads the image frame
                ImgNw = double(obj.readFrame(i));
                if ~isempty(ImgNw)
                    % if valid, then calculate the image mean
                    obj.Iavg{iFile}(i) = nanmean(ImgNw(:));
                end
            end
            
            % updates and closes the progressbar
            obj.hProg.Update(2,'All Video Frames Analysed',1); 
            pause(0.1)
            
        end
        
        % --- loads the video file given by the index, iFile
        function loadVideoFile(obj,iFile)
            
            % sets the full movie file name
            obj.fFile = fullfile(obj.fDir,obj.fName{iFile});

            % attempts to determine if the movie file is valid
            [~,~,fExtnF] = fileparts(obj.fFile);
            try
                % uses the later version of the function 
                switch fExtnF
                    case {'.mj2', '.mov','.mp4'}
                        obj.mObj = VideoReader(obj.fFile);
                    case '.mkv'
                        obj.mObj = ffmsReader();
                        [~,~] = obj.mObj.open(obj.fFile,0);        
                    otherwise
                        [V,~] = mmread(obj.fFile,inf,[],false,true,'');
                end

            catch
                % if an error occured, then output an error and exit 
                if ~isBatch
                    [eStr,tStr] = deal(eStr0,'Corrupted Video File');
                    waitfor(errordlg(eStr,tStr,'modal'))
                end

                % if there was an error, then exit the function
                obj.ok = false;
                return
            end
            
            % opens the movie file object
            wState = warning('off','all');
            switch fExtnF
                case {'.mj2','.mov','.mp4'}
                    obj.FPS = obj.mObj.FrameRate;
                    obj.nFrmT = obj.mObj.NumberOfFrames;

                    while 1            
                        try 
                            % reads a new frame. 
                            Img = read(obj.mObj,obj.nFrmT);
                            break
                        catch
                            % if there was an error, reduce the frame count
                            obj.nFrmT = obj.nFrmT - 1;
                        end
                    end

                case '.mkv'       
                    obj.nFrmT = obj.mObj.numberOfFrames;

                    % reads in a small sub-set of images 
                    % (to determine size/frame rate)
                    [tTmp,nFrmTmp] = deal([],5);
                    for i = 1:nFrmTmp
                        [~,tTmp(i)] = obj.mObj.getFrame(i-1);
                    end

                    % sets the image dimensions/video frame rate
                    obj.FPS = 1000/(mean(diff(tTmp)));                          

                    while 1            
                        try 
                            % reads a new frame. 
                            [~,~] = obj.mObj.getFrame(obj.nFrmT - 1);
                            break
                        catch
                            % if there was an error, reduce the frame count
                            obj.nFrmT = obj.nFrmT - 1;
                        end
                    end        

                otherwise        
                    obj.FPS = V.rate;
                    obj.nFrmT = abs(V.nrFramesTotal);

            end
            warning(wState);       
            
            % calculates the sampled frame rate
            obj.nFrm = length(1:obj.sRate:obj.nFrmT);
            
        end
       
        % --- reads the image frame given by the index, iFrm
        function Img = readFrame(obj,iFrm)
            
            % otherwise, retrieves the file extension
            [~,~,fExtnF] = fileparts(obj.fFile);
            cFrmT = obj.sRate*(iFrm-1) + 1;

            % loads the frame based on the movie type
            switch fExtnF    
                case {'.mj2','.mov','.mp4'} 
                    % case is a moving JPEG movie/quicktime movie
                    
                    % retrieves the current image frame
                    if cFrmT > obj.mObj.NumberOfFrames
                        Img = [];
                        return
                    end

                    Img = read(obj.mObj,cFrmT); 
                    if size(Img,3) == 3
                        Img = rgb2gray(Img);
                    end            

                case '.mkv' % case is matroska video format
                    
                    % retrieves the current image frame
                    Img = obj.mObj.getFrame(cFrmT-1);
                    if size(Img,3) == 3
                        Img = rgb2gray(Img);
                    end


                otherwise % case is the other movie types        
                    try
                        % sets the frame time-span reads it from file
                        tFrm = cFrmT/obj.FPS + (1/(2*obj.FPS))*[-1 1];
                        [V,~] = mmread(obj.fFile,[],tFrm,false,true,'');            

                        % converts the RGB image to grayscale
                        if isempty(V.frames)
                            Img = [];
                        else
                            Img = rgb2gray(V.frames(1).cdata);        
                        end
                        
                    catch
                        % if an error occured, then return an empty array
                        Img = [];
                        return
                    end
            end            
            
        end
        
        % --- plots the frame given by the frame index, iFrm
        function plotFrame(obj,iFrm)
            
            plotGraph('image',double(obj.readFrame(iFrm)))
            
        end
        
        % --- creates the avg. intensity plot
        function plotAvgIntensity(obj)
            
            % combines all the data values
            Tofs = 0;
            Tmlt = 1/3600;            
            dT = obj.sRate/obj.FPS;
            [axSz,lblSz] = deal(14,16);
            c = {0.5*[1,0,0],0.5*[0,1,0]};
            [ix,iy] = deal([1,1,2,2,1],[1,2,2,1,1]);
            
            % axis handles
            hAx = zeros(2,1);
            hFig = figure('Visible','off');    
            
            % calculates the axis limits
            IavgT = cell2mat(obj.Iavg);
            yLimT = prctile(IavgT,[0,100]);
            yLim = {[0,255],yLimT + 0.025*diff(yLimT)*[-1,1]};
            
            % creates the subplot axes
            for i = 1:length(hAx)
                hAx(i) = subplot(length(hAx),1,i);
                set(hAx(i),'ylim',yLim{i});
                hold(hAx(i),'on');
                grid(hAx(i),'on');
                
                set(hAx(i),'fontweight','bold','FontSize',axSz,...
                           'ticklength',[0,0]);
                ylabel(hAx(i),'Pixel Intensity','FontWeight','Bold',...
                              'FontSize',lblSz);
                xlabel(hAx(i),'Time (Hrs)','FontWeight','Bold',...
                              'FontSize',lblSz);                          
            end
            
            % creates the plot objects
            for i = 1:obj.nFile
                % sets up the time vector
                k = mod(i-1,2) + 1;
                Tnw = Tmlt*dT*((1:length(obj.Iavg{i}))'-1);
                Tplt = Tnw([1,end])+Tofs;
                
                % updates the plots/fill objects
                for j = 1:length(hAx)                    
                    fill(hAx(j),Tplt(ix),yLim{j}(iy),c{k},...
                                'FaceAlpha',0.1,'LineStyle','None');
                    plot(hAx(j),Tnw+Tofs,obj.Iavg{i},'k','linewidth',2)
                    
                    if i > 1
                        y0 = [obj.Iavg{i-1}(end),obj.Iavg{i}(1)];
                        plot(hAx(j),Tofs*[1,1],y0,'k','linewidth',2);
                    end
                end                
                
                % increments the time offset
                Tofs = Tofs + Tnw(end);
            end
            
            % updates the horizonal axis limits
            arrayfun(@(x)(set(x,'xlim',[0,Tofs])),hAx)
            
            % turns on the figure visiblility
            set(hFig,'visible','on');
        end
        
    end
    
end