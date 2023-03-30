classdef ExptCheck < handle
    
    % properties
    properties
        
        % main class fields
        fDir
        fExtn
        
        % array class fields
        T
        Imd
        Iavg
        
        % other scalar fields
        iFile = 0;
        wStr0 = {'Overall Progress','Video Progress'};
        
    end
    
    % methods
    methods
        
        % --- class constructor
        function obj = ExptCheck(fExtn,fDir)
            
            % sets the file extenstion
            obj.fExtn = fExtn;
            
            % sets the video file directory
            if exist('fDir','var')
                obj.fDir = fDir;
            else
                obj.fDir = pwd;
            end
            
        end
        
        % --- calculates the video properties
        function calcVideoDirProps(obj,isRestart)
            
            % sets the default input arguments
            if ~exist('isRestart','var'); isRestart = false; end
            
            % restarts the file count (if required)
            if isRestart
                obj.iFile = 0;
                [obj.Iavg,obj.Imd,obj.T] = deal([]);
            end
            
            % determines the video files
            fInfo = dir(fullfile(obj.fDir,obj.fExtn));
            
            % memory allocation
            nFile = length(fInfo);
            nFileAdd = nFile - obj.iFile;
            
            % loads the summary file
            sFile = fullfile(obj.fDir,'Summary.mat');
            A = load(sFile);
            obj.T = cellfun(@(x,y)(x(1:length(y))),...
                    A.tStampV(1:obj.iFile),obj.Iavg(:),'un',0);
            
            % creates the progressbar
            if nFileAdd == 0
                return
            else
                hProg = ProgBar(obj.wStr0,'Video Image Check');
            end
            
            % calculates the average pixel intensity for each video
            for i = (obj.iFile+1):nFile
                % updates the progress bar
                wStr = sprintf('Overall Progress (%i of %i)',i,nFile);
                if hProg.Update(1,wStr,i/(1+nFile))
                    % if the user cancelled, then exit
                    return
                else
                    % resets the 2nd progressbar line
                    hProg.Update(2,'Video Progress',0);
                end
                
                try
                    % opens the video file
                    fFileNw = fullfile(fInfo(i).folder,fInfo(i).name);
                    vObj = VideoReader(fFileNw);
                    
                    % calculates the video properties
                    [IavgNw,ImdNw,ok] = obj.calcVideoProps(hProg,vObj);
                    if ok
                        % resets the file count index
                        obj.iFile = i;
                        obj.Iavg{end+1} = IavgNw;
                        obj.Imd{end+1} = ImdNw;
                        obj.T{end+1} = A.tStampV{i}(1:length(ImdNw));
                    else
                        % if the user cancelled then exit
                        return
                    end
                    
                catch ME
                    % if still recording then exit the loop
                    eStr = 'MATLAB:audiovideo:VideoReader:Unexpected';
                    if strcmp(ME.identifier,eStr)
                        break
                    end
                end
            end
            
            % updates and deletes the progressbar
            hProg.Update(1,'All Videos Complete!',1);
            hProg.Update(2,'Video Complete!',1);
            pause(1)
            
            % closes the progressbar
            hProg.closeProgBar();
            
        end
        
        % --- plots the mean/median pixel intensities
        function plotIntensity(obj)
            
            % creates figure object
            figure;
            hold on
            hAx = gca;
            
            % sets up the time vector
            [axSz,fSz] = deal(20,28);
            Ttot = cell2mat(obj.T(:))/60^2;
            
            % creates the plots
            hPlt = zeros(2,1);
            hPlt(1) = plot(Ttot,cell2mat(obj.Iavg(:)),'r');
            hPlt(2) = plot(Ttot,cell2mat(obj.Imd(:)),'g');
            
            % sets the axes limits
            axis tight
            set(hAx,'ylim',get(gca,'ylim')+2*[-1,1])
            
            % sets the axis label properties
            ylabel(hAx,'Pixel Intensity','FontWeight','Bold','FontSize',fSz);
            xlabel(hAx,'Time (Hours)','FontWeight','Bold','FontSize',fSz);
            set(hAx,'FontWeight','Bold','FontSize',axSz);
            
            % plot legend
            legend(hPlt,{'Mean','Median'},'Location','Best');
            
        end
        
    end
    
    % static class methods
    methods (Static)
        
        % --- calculates the average pixel intensity for a full video
        function [Iavg,Imd,ok] = calcVideoProps(hProg,vObj)
            
            % memory allocation
            ok = true;
            nFrm = vObj.NumFrames;
            [Iavg,Imd] = deal(NaN(nFrm,1));
            
            % calculates avg pixel intensity for each frame
            for iFrm = 1:nFrm
                if (mod(iFrm,10) == 1) || (iFrm == nFrm)
                    % updates the progress bar
                    wStr = sprintf('Video Progress (%i of %i)',iFrm,nFrm);
                    if hProg.Update(2,wStr,iFrm/nFrm)
                        % if the user cancelled, then exit
                        ok = false;
                        return
                    end
                end
                
                % reads the frame and calculates the average
                Inw = readFrame(vObj);
                Iavg(iFrm) = mean(Inw(:));
                Imd(iFrm) = median(Inw(:));
            end
            
        end
        
    end
    
end