classdef PlotObj < handle 
    
    % class properties
    properties        
        % main object fields
        Img
        fPos                
        
        % object handles
        hAx        
        hFig
        hImage
        hTitle
        hMark
        
        % phase/frame fields
        iPh = 1;   
        iFrm
        nPh
        nFrm                
        nApp = 1;        
        pOfs = [0,0];
        
    end
    
    % class methods
    methods   
        % --- class constructor
        function obj = PlotObj(Img,fPos,pOfs)
           
            % ensures the image is stored properly
            if ~iscell(Img)
                Img = {Img};
            end         
            
            % ensures the image is stored as a cell array
            if ~exist('fPos','var'); fPos = []; end
            if exist('pOfs','var'); obj.pOfs = pOfs; end
            
            % sets the input arguments
            obj.Img = Img;
            obj.fPos = fPos;            
            
            % initialises the class objects
            obj.initClassFields()
            
        end
        
        % --- initialises the class fields
        function initClassFields(obj)
                        
            % creates the figure object
            obj.hFig = figure('Position',[100 100 700 500],...
                              'WindowKeyPressFcn',@obj.plotKeyPress);            
            
            % sets the other fields
            obj.nPh = length(obj.Img);
            obj.nFrm = max(1,cellfun(@length,obj.Img));
            obj.iFrm = ones(obj.nPh,1);            

            % updates the image
            obj.updateImage();
            obj.updateTitle();         
            
            % sets up the plot marker array (if position data provided)
            if ~isempty(obj.fPos)
                obj.nApp = size(obj.fPos,1);
                obj.hMark = cell(obj.nApp,1);                
                obj.updatePlotMarkers();
            end            
            
        end
        
        % --- updates the image on the plot axes
        function updateImage(obj)            
            
            % retrieves the new frame
            if isempty(obj.Img{obj.iPh})
                ImgNw = NaN;
            else
                iFrmNw = obj.iFrm(obj.iPh);
                ImgNw = obj.Img{obj.iPh}{iFrmNw};
            end
            
            % updates the image figure
            if isempty(obj.hImage)
                % if there is no image object, then create it
                if size(ImgNw,3) == 1
                    imagesc(ImgNw);
                    colormap(gray)
                else
                    image(uint8(ImgNw));
                end
                
                % retrieves the axes/image objects
                obj.hAx = findall(obj.hFig,'Type','Axes');
                obj.hImage = findall(obj.hAx,'Type','Image');
                
                % updates the axis properties
                set(obj.hAx,'xticklabel',[],'yticklabel',[],...
                            'xtick',[],'ytick',[]);
                axis equal
                
            else
                %
                if size(ImgNw,3) == 1
                    set(obj.hImage,'CData',ImgNw)
                else
                    set(obj.hImage,'CData',uint8(ImgNw))
                end
            end                    
            
            % resets the axis limits
            xLim = [0,size(ImgNw,2)] + 0.5;
            yLim = [0,size(ImgNw,1)] + 0.5;
            set(obj.hAx,'xlim',xLim,'yLim',yLim);
            
        end
        
        % --- updates the frame plot markers
        function updatePlotMarkers(obj)                        
            
            % if there is no positional data, then exit the function
            if isempty(obj.fPos{1,obj.iPh})
                if ~isempty(obj.hMark{1})
                    cellfun(@(x)(setObjVisibility(x,0)),obj.hMark)
                end
                
                % exits the function
                return
            end
            
            % plots the markers for all regions
            for iApp = 1:obj.nApp
                % sets the x/y pixel offset
                fP = obj.fPos{iApp,obj.iFrm};
                xPlt = fP(:,1) + obj.pOfs(1);
                yPlt = fP(:,2) + obj.pOfs(2);
                
                % updates/creates the plot markers
                if isempty(obj.hMark{iApp})
                    % if missing, then create the markers
                    hold(obj.hAx,'on')
                    obj.hMark{iApp} = plot(obj.hAx,xPlt,yPlt,'go',...
                                           'UserData',iApp);
                    hold(obj.hAx,'off')
                else
                    % otherwise, update the marker locations
                    set(obj.hMark{iApp},'xData',xPlt,'yData',yPlt,...
                                        'Visible','on');
                end
            end
            
        end        
    
        % --- the plot figure key press callback function 
        function plotKeyPress(obj,~,event)    
       
            % initialisations
            [diPh,diFrm] = deal(0);            
        
            switch event.Key
                case 'rightarrow'
                    % determines if the frame count can be incremented
                    nFrmT = obj.nFrm(obj.iPh);
                    if obj.iFrm(obj.iPh) == nFrmT
                        % if not, then exit
                        return
                    else
                        % otherwise, set the increment value
                        diFrm = 1;
                    end
                    
                case 'leftarrow'
                    % determines if the frame count can be decremented
                    if obj.iFrm(obj.iPh) == 1
                        % if not, then exit
                        return
                    else
                        % otherwise, set the increment value
                        diFrm = -1;
                    end                    
                    
                case 'uparrow'
                    % determines if the phase count can be incremented
                    if obj.iPh == obj.nPh
                        % if not, then exit
                        return
                    else
                        diPh = 1;
                    end                    
                    
                case 'downarrow'
                    % determines if the phase count can be decremented
                    if obj.iPh == 1
                        % if not, then exit
                        return
                    else
                        diPh = -1;
                    end                    
                    
            end
            
            % applies the phase/frame increment
            obj.iPh = obj.iPh + diPh;
            obj.iFrm(obj.iPh) = obj.iFrm(obj.iPh) + diFrm;            
            
            % updates the title string
            obj.updateImage() 
            obj.updateTitle();            
            
            % updates the plot markers
            if ~isempty(obj.fPos)
                obj.updatePlotMarkers();
            end
            
        end
            
        % --- updates the figure title
        function updateTitle(obj)
            
            % sets the title string
            iFrmNw = obj.iFrm(obj.iPh);
            if obj.nPh == 1
                % case is there is only one phase
                tStrNw = sprintf('Frame %i',iFrmNw);
            else
                % case is there are multiple phases
                tStrNw = sprintf('Phase %i (Frame %i)',obj.iPh,iFrmNw);
            end
            
            % updates the title string
            if isempty(obj.hTitle)
                obj.hTitle = title(tStrNw);
            else
                set(obj.hTitle,'String',tStrNw);
            end
            
        end
        
    end
    
end