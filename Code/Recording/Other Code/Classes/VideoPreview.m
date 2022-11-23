classdef VideoPreview < handle
    
    % class properties
    properties
        
        % object handles
        hFig
        hGUI
        hAx
        hImage
        objIMAQ
        
        % other data structs/arrays
        iMov
        vcObj
        
        % boolean flags
        isRecord
        isRot      
        isOn
        isTest
        
        % other parameters
        tPause = 1;
        initMarkers = false;
        
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
                obj.vcObj = getappdata(hFig,'vcObj');
                
            else
                % case is the preview is run through the tracking GUI
                obj.hAx = obj.hGUI.imgAxes;
            end
            
        end
        
        % ------------------------------------------------- %
        % --- TRACKING VIDEO PREVIEW CALLBACK FUNCTIONS --- %
        % ------------------------------------------------- %      
        
        % --- starts the video preview
        function startTrackPreview(obj,createMark)
            
            % resets the running flag
            cbFcn = [];
            obj.isOn = true;   
            obj.iMov = get(obj.hFig,'iMov'); 
            
            % sets the image acquisition object handle
            obj.isTest = obj.hFig.infoObj.isTest;
            obj.objIMAQ = obj.hFig.infoObj.objIMAQ;            
            
            % other initialisations
            initStr = 'Initialising...';
            hEditS = obj.hGUI.editVideoStatus;
            colormap(obj.hGUI.imgAxes,'gray')
            
            % sets the preview callback function
            if obj.isTest                
                obj.objIMAQ.hAx = obj.hGUI.imgAxes;                
            else
                cbFcn = @obj.previewTrk;
            end
            
            % sets the rotation flag
            obj.isRot = (abs(obj.iMov.rotPhi) > 45) && obj.iMov.useRot;
            
            % updates the video status
            set(hEditS,'string',initStr,'BackgroundColor',[0.93,0.69,0.13])                                    
            
            % initialises the preview image          
            set(obj.hGUI.checkShowTube,'Value',0)
            setObjEnable(obj.hGUI.menuAnalysis,'off');
            if obj.initPreviewImage(cbFcn)           
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
            if obj.isTest
                obj.objIMAQ.stopVideo();
                obj.objIMAQ.previewUpdateFcn = [];
            else
                closepreview(obj.objIMAQ)  
            end
            
            % if the sub-regions have been set then recreate the markers
            if obj.iMov.isSet
                showTube = get(obj.hGUI.checkShowTube,'Value');
                obj.hFig.mkObj.initTrackMarkers(showTube);
                
                if get(obj.hGUI.checkShowTube,'Value')
                    chkFcn = get(obj.hFig,'checkShowTube_Callback');
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
            cbFcn = [];
            obj.isOn = true; 
            
            % retrieves the image acquisition object
            infoObj = getappdata(obj.hFig,'infoObj');
            obj.isTest = infoObj.isTest;
            obj.objIMAQ = infoObj.objIMAQ;
            
            % updates the video status
            set(obj.hGUI.editVideoStatus,'string','Initialising...',...
                                        'BackgroundColor',[0.93,0.69,0.13])             
            
            % resets the start/stop preview button enabled properties
            set(obj.hGUI.toggleVideoPreview,'string','Stop Video Preview');             
            
            % sets the preview callback function
            if obj.isTest
                obj.objIMAQ.hAx = obj.hGUI.axesPreview;
            else
                cbFcn = @obj.previewRec;
            end            
            
            % sets the video calibration start time
            if ~isempty(obj.vcObj)
                obj.vcObj.resetTraceFields();
            end            
            
            % initialises the preview image
            if obj.initPreviewImage(cbFcn)
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
            if obj.isTest
                obj.objIMAQ.stopVideo();
            else
                closepreview(obj.objIMAQ)
            end

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
            
            if ~obj.isTest
                % ensures the camera is not running                
                if strcmp(get(obj.objIMAQ,'Running'),'on')
                    stop(obj.objIMAQ); pause(0.05);
                end                        
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
            vRes = getVideoResolution(obj.objIMAQ,1);
            if obj.isRot
                obj.hImage = image(zeros(vRes),'Parent',obj.hAx);           
                [xL,yL] = deal([1 vRes(2)]+0.5,[1 vRes(1)]+0.5);        
            else
                obj.hImage = image(zeros(flip(vRes)),'Parent',obj.hAx);        
                [xL,yL] = deal([1 vRes(1)]+0.5,[1 vRes(2)]+0.5);
            end        
            
            % sets the axis properties
            set(obj.hImage,'CDataMapping','scaled')
            set(obj.hAx,'xtick',[],'ytick',[],'xticklabel',[],...
                        'yticklabel',[],'xLim',xL,'yLim',yL) 
        
            % if the sub-regions have been set then recreate the markers
            if obj.initMarkers
                obj.hFig.mkObj.initTrackMarkers(0)
                obj.initMarkers = false;
            end                    
                    
            % updates the axis to image format
            pause(0.05);
            axis(obj.hAx,'image');
            pause(0.05);

            try
                % starts the video preview  
                if obj.isTest
                    % case is the test case
                    obj.objIMAQ.iFrmT = 1;
                    obj.objIMAQ.hImage = obj.hImage;
                    obj.objIMAQ.startVideo(~obj.isRecord);                    
                else
                    % case is the camera object
                    setappdata(obj.hImage,'UpdatePreviewWindowFcn',cbFcn)
                    preview(obj.objIMAQ,obj.hImage)
                end
                
            catch
                % makes the loadbar invisible
                ok = false;
                
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
        function previewRec(obj, ~, event, ~)

            % updates preview image (based on whether the image is rotated)
            Inw = event.Data;
            if obj.isRot
                set(obj.hImage, 'cdata', Inw');
            else
                set(obj.hImage, 'cdata', Inw);
            end  
            
            % updates the video calibration trace data
            if ~isempty(obj.vcObj)
                obj.vcObj.newCalibFrame(event)
            end
                
        end
        
        % --- preview update for the tracking GUI
        function previewTrk(obj, ~, event, ~)
            
            % retrieves the rotated image
            Img = getRotatedImage(obj.iMov,event.Data);            
            
            % updates the image
            set(obj.hImage, 'cdata', Img);
            
            % updates the video calibration trace data
            if ~isempty(obj.vcObj)
                obj.vcObj.newCalibFrame(event)
            end            
            
        end
        
    end
    
end
