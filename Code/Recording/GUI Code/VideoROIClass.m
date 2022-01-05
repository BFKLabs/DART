classdef VideoROIClass < handle
    % class properties
    properties
        % main class objects
        hFig
        hGUI
        hAx
        hAxLV
        hFigM
        hAxM
        hLoad
        
        % main gui class objects
        infoObj
        prObj
        resetFcn
        
        % large video points
        apiLV
        hPointLV
        isLV = false;
        
        % other class fields
        pL
        rPos
        vRes
        Img0
        Hmax
        Wmax
        
        % parameters
        dX = 10;  
        manualUpdate = false;        
        
    end
    
    % class methods
    methods
        % --- class constructor
        function obj = VideoROIClass(hFig)
        
            % sets the main class objects
            obj.hFig = hFig;
            obj.hGUI = guidata(hFig);
            obj.hFigM = getappdata(hFig,'hFigM');
            
            % retrieves the 
            obj.prObj = getappdata(obj.hFigM,'prObj');
            obj.infoObj = getappdata(obj.hFigM,'infoObj');
            
            % creates the loadbar figure
            obj.hLoad = ProgressLoadbar('Initialising GUI Objects...');
            
            % initialises the class/gui object properties
            obj.initClassFields();
            obj.initObjCallbacks();
            obj.initObjProps();
            
            % deletes the loadbar
            delete(obj.hLoad)
            
        end  
        
        % --- initialises the class object fields
        function initClassFields(obj)
            
            % initialisations
            handles = obj.hGUI;
            obj.hAx = handles.axesImg;
            obj.hAxLV = handles.axesLargeVideo;

            % sets up the main image axes handle
            hPanelP = findall(obj.hFigM,'tag','panelImg');
            obj.hAxM = findobj(obj.hFigM,'type','axes','Parent',hPanelP);             

            % retrieves the current/full video resolution
            obj.rPos = get(obj.infoObj.objIMAQ,'ROIPosition');
            obj.vRes = get(obj.infoObj.objIMAQ,'VideoResolution');
            
            % retrieves the video preview callback function
            obj.resetFcn = getappdata(obj.hFigM,'resetVideoPreviewDim');
            
            % sets the height/width dimensions
            [obj.Hmax,obj.Wmax] = getLargeVideoDim();
            
            % sets the large video line marker
            pL0 = polyfit(obj.Wmax,obj.Hmax,1);                        
            dHmax = obj.Hmax - polyval(pL0,obj.Wmax);
            obj.pL = [pL0(1),pL0(2)+min(dHmax)];
            
            % determines if the video is a large video
            obj.isLV = obj.vRes(2)-obj.pL(1)*obj.vRes(1) > obj.pL(2);
            
        end
        
        % --- initialises the class object fields
        function initObjCallbacks(obj)
            
            % objects with normal callback functions
            cbObj = {'buttonResetDim','buttonUpdateROI'};
            for i = 1:length(cbObj)
                hObj = getStructField(obj.hGUI,cbObj{i});
                cbFcn = eval(sprintf('@obj.%sCB',cbObj{i}));
                set(hObj,'Callback',cbFcn)
            end                        
            
        end
        
        % --- initialises the class object fields
        function initObjProps(obj)
            
            % object retrieval
            handles = obj.hGUI;
            wState = warning('off','all');
            
            % resets the roi position to full region
            set(obj.infoObj.objIMAQ,'ROIPosition',[0,0,obj.vRes])            

            % -------------------------------------- %
            % --- OBJECT PROPERTY INITIALISATION --- %
            % -------------------------------------- %

            % sets the original resolution height/width
            set(handles.textOrigWidth,'string',num2str(obj.vRes(1)))
            set(handles.textOrigHeight,'string',num2str(obj.vRes(2)))

            % sets the edit property
            for i = 1:length(obj.rPos)
                % retrieves the edit object handle
                hEdit = findall(handles.panelROIDim,'style','edit',...
                                                    'UserData',i);

                % sets the object properties
                cbFcn = @obj.editROIDim;
                set(hEdit,'string',num2str(obj.rPos(i)),'Callback',cbFcn)
            end

            % ------------------------ %
            % --- IMAGE AXES SETUP --- %
            % ------------------------ %

            % get image snapshot
            obj.getInitSnapshot();

            % if there is no image object, then create a new one
            image(uint8(obj.Img0),'parent',obj.hAx);    
            set(obj.hAx,'xtick',[],'ytick',[],'xticklabel',[],...
                        'yticklabel',[],'ycolor','w','xcolor','w',...
                        'box','off')   
            colormap(obj.hAx,gray)            
            
            % creates the image markers
            for i = 1:2
                % sets the horizontal/vertical marker locations
                if i == 1
                    % case is the left side markers
                    [xV,yH] = deal(obj.rPos(1),obj.rPos(2));
                else
                    % case is the right side markers
                    xV = sum(obj.rPos([1,3]));
                    yH = sum(obj.rPos([2,4]));
                end

                % creates the horizontal/vertical markers
                obj.createROIMarker(yH,i,0)
                obj.createROIMarker(xV,i,1)
            end

            % ------------------------------ %
            % --- LARGE VIDEO AXES SETUP --- %
            % ------------------------------ %            

            % determines if there camera is capable of large video sizes
            if obj.isLV        
                % sets the axis limits     
                [m,C] = deal(obj.pL(1),obj.pL(2));                                                          
                
                % initialises the plot axes
                set(obj.hAxLV,'xtick',[],'ytick',[],'xticklabel',[],...
                              'yticklabel',[],'ycolor','k','xcolor','k',...
                              'box','on','linewidth',1)                         
                colormap(obj.hAxLV,gray)   
                
                % case is the uncompressed region patch
                xLVR = [(obj.vRes(2)-C)/m,obj.vRes(1)*[1,1]];
                yLVR = [obj.vRes(2)*[1,1],polyval(obj.pL,obj.vRes(1))];                   
                
                % creates the patch object
                iiR = [(1:length(xLVR)),1];
                patch(obj.hAxLV,xLVR(iiR),yLVR(iiR),'r','facealpha',0.2);
                
                % case is the compressed region patch
                xLVG = [0,0,xLVR(1:2),obj.vRes(1)];
                yLVG = [0,obj.vRes(2)*[1,1],yLVR(end),0];                
                
                % creates the patch object
                iiG = [(1:length(yLVG)),1];
                patch(obj.hAxLV,xLVG(iiG),yLVG(iiG),'g','facealpha',0.2);  
                
                % creates the marker point
                obj.hPointLV = impoint(obj.hAxLV,obj.rPos(3),obj.rPos(4));
                                
                % sets the constraint/position callback functions
                cbFcn = @(p)(obj.moveLargeVidMarker(p));
                obj.hPointLV.addNewPositionCallback(cbFcn); 
                setObjVisibility(findall(obj.hPointLV,'tag','plus'),0)
                
                % sets the object position constraint function
                obj.apiLV = iptgetapi(obj.hPointLV);
                obj.resetLargeVidAxisLimits();                   
                
                % updates the video status label
                obj.updateVideoStatus()
                
            else
                % if the video is not large, then disable the large
                % dimension axes panel
                setObjVisibility(obj.hGUI.panelLargeDim,0)
            end            
            
            % --------------------------- %
            % --- GUI RE-DIMENSIONING --- %
            % --------------------------- %

            % resets the major gui dimensions
            pAR = obj.vRes(1)/obj.vRes(2);
            pPos = get(handles.panelImageAxes,'Position');

            % resets the axes, image panel and figure dimensions
            pPos(3) = roundP(pAR*pPos(4));
            set(handles.panelImageAxes,'Position',pPos)
            set(obj.hAx,'Position',[obj.dX*[1,1],pPos(3:4)-2*obj.dX])
            resetObjPos(obj.hFig,'Width',sum(pPos([1,3]))+obj.dX)

            % resets the axis limits
            del = 10;
            [xLim,yLim] = deal([0,obj.vRes(1)],[0,obj.vRes(2)]);
            set(obj.hAx,'xlim',xLim+del*[-1,1],'ylim',yLim+del*pAR*[-1,1])   
                    
            % resets the camera to the original ROI position
            set(obj.infoObj.objIMAQ,'ROIPosition',obj.rPos)            
            
            % resets the warnings
            warning(wState);
            
        end

        % ----------------------------------------- % 
        % --- CONTROL BUTTON CALLBACK FUNCTIONS --- %
        % ----------------------------------------- %        
        
        % --- callback function for clicking buttonResetDim
        function buttonResetDimCB(obj,~,~)

            % updates all ROI markers
            rPos0 = [0,0,obj.vRes];
            obj.updateAllROIMarkers(rPos0)

            % resets the dimension edit box values
            for i = 1:length(rPos0)
                hEdit = findall(obj.hGUI.panelROIDim,'UserData',i);
                set(hEdit,'String',num2str(rPos0(i)))
            end

            % resets the main GUI dimensions
            obj.resetFcn(guidata(obj.hFigM),rPos0)            
            
        end
        
        % --- callback function for clicking buttonResetDim
        function buttonUpdateROICB(obj,~,~)
                        
            % resets the ROI dimensions
            pROI = roundP(obj.getCurrentROIDim());
            obj.resetFcn(guidata(obj.hFigM),pROI);
            
        end        
        
        % ------------------------------ % 
        % --- ROI CALLBACK FUNCTIONS --- %
        % ------------------------------ %        
        
        % --- creates the ROI marker object
        function createROIMarker(obj,pL,ind,isVert)
            
            % initialisations          
            xLim = get(obj.hAx,'xlim');
            yLim = get(obj.hAx,'ylim');
            [uData,lWidL] = deal([isVert,ind],4);

            % sets the marker coordinates
            if isVert
                % case is a vertical marker
                yROI = yLim;
                if ind == 1
                    xROI = [xLim(1),pL];
                    lStr = 'maxx top line';
                else
                    xROI = [pL,xLim(2)];
                    lStr = 'minx top line';
                end
            else
                % case is a horizontal marker
                xROI = xLim;
                if ind == 1        
                    yROI = [yLim(1),pL];
                    lStr = 'maxy top line';
                else
                    yROI = [pL,yLim(2)];
                    lStr = 'miny top line';
                end
            end

            % sets the x/y ROI coordinates
            xROI = max(min(xROI,xLim(2)-0.5),xLim(1)+0.5);
            yROI = max(min(yROI,yLim(2)-0.5),yLim(1)+0.5);

            % creates a patch object object
            pROI = [xROI(1),yROI(1),diff(xROI),diff(yROI)];
            hRectS = imrect(obj.hAx,pROI);
            set(hRectS,'UserData',uData,'tag','hROILim')

            % creates the rectangular ROI object
            hRectL = findall(hRectS,'type','Line');
            set(hRectL,'Visible','off','HitTest','off');

            hRectLV = findall(hRectL,'tag',lStr);
            set(hRectLV,'Visible','on','LineWidth',lWidL,'HitTest','on',...
                        'Color','r','LineStyle',':')
            uistack(hRectLV,'top');

            % case is the ROI patch object
            hRectP = findall(hRectS,'type','Patch');
            set(hRectP,'FaceColor',0.75*[1,1,1],'FaceAlpha',0.25,...
                       'HitTest','off');

            % sets the constraint/position callback functions
            cbFcn = @(p)(obj.moveROIMarker(p,uData));
            hRectS.addNewPositionCallback(cbFcn);

            % sets the object position constraint function
            api = iptgetapi(hRectS);
            fcn = makeConstrainToRectFcn('imrect',xLim,yLim);
            api.setPositionConstraintFcn(fcn);              

        end
        
        % --- callback function for moving the ROI marker object
        function moveROIMarker(obj,p,uData)

            % global variables
            if obj.manualUpdate; return; end

            % retrieves the ROI positional coordinates
            handles = obj.hGUI;          

            % retrieves the location of the opposite marker object
            uDataF = [uData(1),1+(uData(2)==1)];
            hPatchF = findall(obj.hAx,'tag','hROILim','UserData',uDataF);
            hAPI = iptgetapi(hPatchF); 
            pF = hAPI.getPosition();

            % 
            if uData(1)       
                % sets the length dimension parameter object  
                if uData(2) == 1
                    obj.rPos(1) = roundP(p(3)-0.5); 
                    obj.rPos(3) = roundP(pF(1)-obj.rPos(1));
                else
                    obj.rPos(3) = min(obj.vRes(1),roundP(p(1)-pF(3)));
                end

                % sets the bottom coordinate
                set(handles.editLeft,'string',num2str(obj.rPos(1)));
                set(handles.editWidth,'string',num2str(obj.rPos(3)));

            else
                % sets the length dimension parameter object 
                if uData(2) == 2
                    obj.rPos(2) = max(0,roundP(p(4)-0.5));
                    obj.rPos(4) = roundP(p(2)-pF(4));
                else
                    obj.rPos(4) = min(obj.vRes(2),roundP(pF(2)-p(4)));
                end

                % sets the bottom coordinate    
                set(handles.editBottom,'string',num2str(obj.rPos(2)));
                set(handles.editHeight,'string',num2str(obj.rPos(4)));
            end
            
            % updates the large
            if obj.isLV
                obj.updateLargeVideoMarker(obj.rPos(3:4))  
                obj.resetLargeVidAxisLimits()
            end

        end
        
        % --- updates the large video marker position
        function updateLargeVideoMarker(obj,rPos)
            
            % global variables
            obj.manualUpdate = true;

            % updates the position of the marker
            obj.apiLV.setPosition(rPos);    
            obj.updateVideoStatus(rPos);
            
            % global variables
            obj.manualUpdate = false;            
            
        end

        % --- updates all the ROI markers given the ROI vector, rPos
        function updateAllROIMarkers(obj,rPos)

            % global variables
            obj.manualUpdate = true;

            % resets the ROI marker on the left side
            hRectX1 = findall(obj.hAx,'tag','hROILim','UserData',[1,1]);
            obj.updateROIMarker(hRectX1,'Width',rPos(1));

            % resets the ROI marker on the right side
            hRectX2 = findall(obj.hAx,'tag','hROILim','UserData',[1,2]);
            obj.updateROIMarker(hRectX2,'Left',sum(rPos([1,3])));
            obj.updateROIMarker(hRectX2,'Width',obj.vRes(1)-sum(rPos([1,3])));

            % resets the ROI marker on the bottom side
            hRectY1 = findall(obj.hAx,'tag','hROILim','UserData',[0,2]);
            obj.updateROIMarker(hRectY1,'Bottom',obj.vRes(2)-rPos(2));
            obj.updateROIMarker(hRectY1,'Height',rPos(2));

            % resets the ROI marker on the top side
            hRectY2 = findall(obj.hAx,'tag','hROILim','UserData',[0,1]);
            obj.updateROIMarker(hRectY2,'Height',obj.vRes(2)-sum(rPos([2,4])));

            % resets the manual update flag
            obj.manualUpdate = false;

        end
        
        % --- callback function on updating the ROI dimension editboxes
        function editROIDim(obj,hObject,~)

            % parameters
            szMin = 64;
            uData = get(hObject,'UserData');

            % retrieves the current ROI dimensions
            rPos0 = roundP(obj.getCurrentROIDim());

            % determines the parameter limits (based on type
            switch uData
                case 1 % case is the ROI left location
                    nwLim = [0,max(0,floor(obj.vRes(1)-rPos0(3)))];

                case 2 % case is the ROI bottom location
                    nwLim = [0,max(0,floor(obj.vRes(2)-rPos0(4)))];

                case 3 % case is the ROI width
                    nwLim = [szMin,floor(obj.vRes(1)-rPos0(1))];

                case 4 % case is the ROI height
                    nwLim = [szMin,floor(obj.vRes(2)-rPos0(2))];

            end

            % determines if the new value is valid
            nwVal = str2double(get(hObject,'string'));
            if chkEditValue(nwVal,nwLim,1)
                % if so, then update the parameter value and the 
                obj.rPos(uData) = nwVal;
                obj.updateAllROIMarkers(obj.rPos);    
                
                if obj.isLV
                    obj.updateLargeVideoMarker(obj.rPos(3:4));
                    obj.resetLargeVidAxisLimits()
                end
            else
                % resets the back to the last visible
                set(hObject,'String',num2str(rPos0(uData)))
            end

        end
        
        % --- callback function for the large video marker
        function moveLargeVidMarker(obj,p)
            
            % global variables
            if obj.manualUpdate; return; end            
            
            % updates the ROI position vector
            obj.rPos(3:4) = floor(p);
            
            % sets the bottom coordinate 
            handles = obj.hGUI;
            set(handles.editWidth,'string',num2str(obj.rPos(3)));
            set(handles.editHeight,'string',num2str(obj.rPos(4)));
            
            % updates the position markers            
            obj.updateAllROIMarkers(obj.rPos);
            obj.updateVideoStatus(obj.rPos(3:4));
            
        end
        
        % ----------------------- %        
        % --- OTHER FUNCTIONS --- %
        % ----------------------- %
        
        % --- retrieves the current ROI dimension vector
        function rPos = getCurrentROIDim(obj)
           
            % memory allocation
            hRect = cell(4,1);

            % retrieves the marker object handles
            for i = 1:2
                for j = 1:2
                    k = 2*(i-1)+j;
                    hRect{k} = findall(obj.hAx,'tag','hROILim',...
                                               'UserData',[(i-1),j]);
                end
            end

            % retrieves the position of the marker objects
            hAPI = cellfun(@(x)(iptgetapi(x)),hRect,'un',0);
            fPos = cell2mat(cellfun(@(x)(x.getPosition()),hAPI,'un',0));

            % returns the 
            [W,H] = deal(fPos(4,1)-fPos(3,3),fPos(2,2)-fPos(1,4));
            rPos = [fPos(3,3),fPos(2,4),W,H];            
            
        end
        
        % --- retrieves the initial snapshot image
        function getInitSnapshot(obj)
            
            % parameters
            ImgMdTol = 220;
            tPause = 0.25;            
            
            % retrieves the initial image
            obj.Img0 = obj.getSnapShot();
            while nanmedian(obj.Img0(:)) > ImgMdTol
                % pauses for the required time
                pause(tPause);
                
                % retrieves the new image
                obj.Img0 = obj.getSnapShot();
            end                            
            
        end

        % --- retrieves the image snapshot (converts to rgb)
        function Img = getSnapShot(obj)
            
            ImgNw = double(getsnapshot(obj.infoObj.objIMAQ));
            Img = 255*normImg(ImgNw);
            
        end      
        
        % --- updates the video status label string
        function updateVideoStatus(obj,rPos)
            
            % sets the default input arguments
            if ~exist('rPos','var')
                rPos = obj.rPos(3:4);
            end
            
            % other initialisations
            col = 'kr';
            mStr = {'Compression Possible','Uncompressed Only'};            
            
            % updates the status flag
            uncompOnly = rPos(2) - obj.pL(1)*rPos(1) > obj.pL(2);
            set(obj.hGUI.textVidStatus,'string',mStr{1+uncompOnly},...
                                       'Foregroundcolor',col(1+uncompOnly))
            
        end
        
        % --- resets the large video axis limits 
        function resetLargeVidAxisLimits(obj)
        
            % retrieves the x/y-axis limits
            xLimLV = [0,obj.vRes(1)-obj.rPos(1)];
            yLimLV = [0,obj.vRes(2)-obj.rPos(2)];
            
            % resets the axis limits
            set(obj.hAxLV,'xlim',xLimLV,'yLim',yLimLV)                      
            
            % resets the 
            fcn = makeConstrainToRectFcn('impoint',xLimLV,yLimLV);
            obj.apiLV.setPositionConstraintFcn(fcn);              
            
        end
        
    end        
    
    % static class methods
    methods (Static)
        
        % --- updates the location of the ROI marker rectangle
        function updateROIMarker(hRect,dimStr,nwVal)

            % retrieves the current marker position
            hAPI = iptgetapi(hRect);
            rPos = hAPI.getPosition();

            % updates the dimension corresponding to the dimension type
            iDim = strcmp({'Left','Bottom','Width','Height'},dimStr);
            rPos(iDim) = nwVal;

            % updates the position of the marker
            hAPI.setPosition(rPos);

        end        
        
    end
end