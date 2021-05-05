classdef VideoPreview < handle
    % class properties
    properties
        % object handles
        hFig
        hAx
        hGUI
        hImage
        objIMAQ
        
        % data structs
        iMov 
        
        % boolean flags
        isRecord
        isRot      
        isOn
        
        % other parameters
        tPause = 1;
    end
    
    % class methods
    methods
        % class contstructor
        function obj = VideoPreview(hFig,isRecord)
            
            % sets the main object handles
            obj.hFig = hFig;
            obj.hGUI = guidata(hFig);            
            
            % sets the boolean flags
            obj.isOn = false;
            obj.isRecord = isRecord;           
            
            % sets the other important field values
            if isRecord
                % case is the preview is run through the recording GUI
                obj.hAx = obj.hGUI.axesPreview;                 
                
            else
                % case is the preview is run through the tracking GUI
                obj.hAx = obj.hGUI.imgAxes;                
            end            
            
        end             

        % ------------------------------------------------- %
        % --- TRACKING VIDEO PREVIEW CALLBACK FUNCTIONS --- %
        % ------------------------------------------------- %      
        
        % --- starts the video preview
        function startTrackPreview(obj)
                        
            % resets the running flag
            obj.isOn = true;   
            obj.iMov = getappdata(obj.hFig,'iMov'); 
            obj.objIMAQ = getappdata(obj.hFig,'objIMAQ');
            
            % other initialisations
            initStr = 'Initialising...';
            hEditS = obj.hGUI.editVideoStatus;
            
            % sets the rotation flag
            obj.isRot = (abs(obj.iMov.rotPhi) > 45) && obj.iMov.useRot;
            
            % updates the video status
            set(hEditS,'string',initStr,'BackgroundColor',[0.93,0.69,0.13])                                    
            
            % initialises the preview image          
            set(obj.hGUI.checkShowTube,'Value',0)
            setObjEnable(obj.hGUI.menuAnalysis,'off');
            if obj.initPreviewImage(@obj.previewTrk)           
                % if the sub-regions have been set then recreate the markers
                if obj.iMov.isSet
                    initFcn = getappdata(obj.hFig,'initMarkerPlots');
                    initFcn(obj.hGUI,0)
                end      
                
                % updates the video status
                pause(obj.tPause)
                if obj.isOn
                    set(hEditS,'string','Running','BackgroundColor','g')
                end
            else
                % updates the video status
                set(obj.hGUI.editVideoStatus,'string','Stopped',...
                                             'BackgroundColor','r')                
            end
            
        end
        
        % --- stops the video preview
        function stopTrackPreview(obj)                  
            
            % resets the running flag
            obj.isOn = false;
            
            % stops the video preview
            setObjEnable(obj.hGUI.menuAnalysis,'on');
            closepreview(obj.objIMAQ)   
            
            % if the sub-regions have been set then recreate the markers
            if obj.iMov.isSet
                initFcn = getappdata(obj.hFig,'initMarkerPlots');
                initFcn(obj.hGUI,get(obj.hGUI.checkShowTube,'Value'))
                
                if get(obj.hGUI.checkShowTube,'Value')
                    chkFcn = getappdata(obj.hFig,'checkShowTube_Callback');
                    chkFcn(obj.hGUI.checkShowTube, 1, obj.hGUI)
                end                
            end
            
            % updates the image on the axis            
            Img = double(obj.hImage.CData);
            set(findobj(obj.hAx,'Type','Image'),'cData',Img);            
            
            % updates the video status
            set(obj.hGUI.editVideoStatus,'string','Stopped',...
                                         'BackgroundColor','r') 
            
        end        
        
        % -------------------------------------------------- %
        % --- RECORDING VIDEO PREVIEW CALLBACK FUNCTIONS --- %
        % -------------------------------------------------- %
        
        % --- starts the video preview
        function startVideoPreview(obj)

            % resets the running flag
            obj.isOn = true;            
            obj.objIMAQ = getappdata(obj.hFig,'objIMAQ');
            
            % updates the video status
            set(obj.hGUI.editVideoStatus,'string','Initialising...',...
                                        'BackgroundColor',[0.93,0.69,0.13])             
            
            % resets the start/stop preview button enabled properties
            set(obj.hGUI.toggleVideoPreview,'string','Stop Video Preview');            
                       
            % initialises the preview image
            if obj.initPreviewImage(@obj.previewRec)
                % enables the grid marker checkbox
                setObjEnable(obj.hGUI.checkShowGrid,'on')
                
                % updates the video status
                pause(obj.tPause);
                if obj.isOn
                    set(obj.hGUI.editVideoStatus,'string','Running',...
                                                 'BackgroundColor','g')
                end
            else
                % updates the video status
                set(obj.hGUI.editVideoStatus,'string','Stopped',...
                                             'BackgroundColor','r')                
            end
            
        end

        % --- stops the video preview
        function stopVideoPreview(obj)
            
            % resets the running flag
            obj.isOn = false;            
            
            % initialisations
            tStr = 'Start Video Preview'; 
            vRes = getVideoResolution(obj.objIMAQ);         

            % retrieves the show menu panel item
            hMenu = findall(obj.hFig,'tag','menuShowGrid');
            if ~isempty(hMenu)
                % if the menu item exists, and is checked, then remove the
                % grid-lines from the axes
                if strcmp(get(hMenu,'checked'),'on')
                    showGridLines(hMenu,'1'); 
                end
                
                % deletes the menu item
                delete(hMenu);
            end

            % stops the video preview
            closepreview(obj.objIMAQ)                           

            % resets the start/stop preview button enabled properties
            set(obj.hGUI.toggleVideoPreview,'string',tStr);                

            % resets the preview axes image to black            
            if obj.isRot
                Img = zeros(vRes);
            else
                Img = zeros(flip(vRes));
            end

            % updates the image on the axis            
            set(findobj(obj.hAx,'Type','Image'),'cData',Img);
            setObjEnable(obj.hGUI.checkShowGrid,'off')

%                 % enables the rt tracking (if background image is set)
%                 iMov = getappdata(obj.hFig,'iMov');  
%                 if ~isempty(iMov)
%                     if ~isempty(iMov.Ibg)
%                         setObjEnable(obj.hGUI.toggleStartTracking,'on')
%                     end
%                 end     

            % updates the video status
            set(obj.hGUI.editVideoStatus,'string','Stopped',...
                                         'BackgroundColor','r') 

        end
        
        % ------------------------------- %
        % --- IMAGE PREVIEW FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- initialises the preview image
        function ok = initPreviewImage(obj,cbFcn)           
            
            % ensures the camera is not running
            if strcmp(get(obj.objIMAQ,'Running'),'on')
                stop(obj.objIMAQ); pause(0.05);
            end                        
            
            % retrieves the position of the axes parent panel
            [dY,ok] = deal(10,true);
            pPos = get(get(obj.hAx,'Parent'),'Position');                        
            
            % resets the dimensions of the preview axes
            set(obj.hAx,'Units','Pixels');
            resetObjPos(obj.hAx,'Height',pPos(4)-2*dY);
            resetObjPos(obj.hAx,'Width',pPos(3)-2*dY);
            resetObjPos(obj.hAx,'Left',dY);
            resetObjPos(obj.hAx,'Bottom',dY);            
            
            % turns the axes off
            axis(obj.hAx,'off');
            pause(0.05);

            % resets the image axis     
            vRes = getVideoResolution(obj.objIMAQ);
            if obj.isRot
                obj.hImage = image(zeros(vRes),'Parent',obj.hAx);           
                [xL,yL] = deal([1 vRes(2)]+0.5,[1 vRes(1)]+0.5);        
            else
                obj.hImage = image(zeros(flip(vRes)),'Parent',obj.hAx);        
                [xL,yL] = deal([1 vRes(1)]+0.5,[1 vRes(2)]+0.5);
            end        

            % sets the image object    
            setappdata(obj.hImage,'UpdatePreviewWindowFcn',cbFcn)
            set(obj.hAx,'xtick',[],'ytick',[],'xticklabel',[],...
                        'yticklabel',[],'xLim',xL,'yLim',yL) 
                    
            % updates the axis to image format
            pause(0.05);
            axis(obj.hAx,'image');
            pause(0.05);    

            try
                % starts the video preview        
                preview(obj.objIMAQ,obj.hImage)
            catch
                % makes the loadbar invisible
                ok = false;
                setObjVisibility(h,'off');
                
                % an error occured while starting the preview, so close 
                % the loadbar and output an error function. 
                % exit the function after
                tStr = 'Video Preview Initialisation Error';
                eStr = [{'Error! Unable to start the camera preview.'};...
                        {['Suggest changing the camera USB-Port ',...
                          'and restart Matlab']}];
                waitfor(errordlg(eStr,tStr,'modal'))                
            end                                 
            
        end        

        % --- preview update for the tracking GUI
        function previewRec(obj, hObj, event, hImage)

            % updates preview image (based on whether the image is rotated)
            if obj.isRot
                set(obj.hImage, 'cdata', event.Data');
            else
                set(obj.hImage, 'cdata', event.Data);
            end        

        end
        
        % --- preview update for the tracking GUI
        function previewTrk(obj, hObj, event, hImage)
            
            % retrieves the rotated image
            Img = getRotatedImage(obj.iMov,event.Data);            
            
            % updates the image
            set(obj.hImage, 'cdata', Img);
            
        end
        
    end
    
end
