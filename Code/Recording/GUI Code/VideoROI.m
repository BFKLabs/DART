classdef VideoROI < handle
    
    % class properties
    properties
        
        % main figure object handles
        hAxM
        hFigM
        
        % main class objects
        hFig
        hPanelO
        
        % device dimensions panel objects
        hPanelI
        hTxtI
        hButI
        
        % ROI dimension panel objects
        hPanelD
        hEditD
        hButD
        
        % large video dimension panel objects
        hPanelL
        hAxL
        hTxtL
        hPointL
        
        % panel axes panel object
        hPanelAx
        hAx        
        hImg
        
        % fixed dimension fields
        dX = 10;  
        hghtTxt = 16;
        hghtBut = 25;
        hghtEdit = 20;
        hghtRow = 25;
        hghtHdr = 20;
        hghtPanel = 580;
        widPanelO = 220;
        widPanelAx = 800;
        hghtAxL = 140;
        widLblI = 100;
        widLblL = 50;
        widObjD = [45,45,60,45];
        
        % calculated dimension fields
        widFig
        hghtFig
        hghtPanelI
        hghtPanelD
        hghtPanelL        
        widPanel
        widBut
        widAx
        hghtAx
        widAxL        
        
        % ROI dimension class fields
        rPos
        vRes
        Hmax
        Wmax
        
        % recording device class fields
        Img0
        Amap
        prObj
        infoObj
        
        % temporary object class fields
        pL
        hLoad
        
        % function handle class fields
        resetFcn
        
        % boolean class fields
        isLV
        isWebCam
        manualUpdate = false;
        
        % parameters
        szMin = 64;
        
        % static class fields
        nLblI = 2;
        nEditD = 4;
        fSzH = 13;
        fSzL = 12;
        fSz = 10 + 2/3;                
        
        % static string fields
        tagStr = 'figVideoROI';
        figName = 'Camera ROI Settings';
        tHdrI = 'IMAGE INFORMATION';
        tHdrD = 'ROI DIMENSIONS';
        tHdrL = 'LARGE VIDEO DIMENSIONS';
        
    end
    
    % class methods
    methods
        
        % --- class constuctor
        function obj = VideoROI(hFigM)
            
            % sets the input arguments
            obj.hFigM = hFigM;
            
            % creates the loadbar figure
            setObjVisibility(obj.hFigM,0); pause(0.05);
            obj.hLoad = ProgressLoadbar('Initialising GUI Objects...');
            pause(0.05);
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initClassObjects();            
            obj.initObjectProps();
            
            % deletes the loadbar
            delete(obj.hLoad)            
            
            % makes the main GUI visible
            setObjVisibility(obj.hFig,1);
            pause(0.05);
            
            % clears the output object (if not required)
            if (nargout == 0) && ~isdeployed
                clear obj
            end            
            
        end        
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % memory allocation
            obj.hTxtI = cell(obj.nLblI,1);
            obj.hEditD = cell(obj.nEditD,1);        
            
            % main window field retrieval
            obj.prObj = getappdata(obj.hFigM,'prObj');
            obj.infoObj = getappdata(obj.hFigM,'infoObj');
            obj.isWebCam = isa(obj.infoObj.objIMAQ,'webcam');
            
            % sets the main preview axes handle
            obj.hAxM = findall(obj.hFigM,'tag','axesPreview');            

            % ---------------------------------- %
            % --- VIDEO RESOLUTION RETRIEVAL --- %
            % ---------------------------------- %           
            
            % retrieves the current/full video resolution
            if obj.isWebCam
                vResS = get(obj.infoObj.objIMAQ,'Resolution');                
                obj.rPos = obj.infoObj.objIMAQ.pROI;                
                obj.vRes = cellfun(@str2double,strsplit(vResS,'x'));
            else
                obj.rPos = get(obj.infoObj.objIMAQ,'ROIPosition');
                obj.vRes = get(obj.infoObj.objIMAQ,'VideoResolution');
            end   
            
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
            
            % ------------------------------------- %
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- %
            
            % pre-calculations
            nRowD = ceil(obj.nEditD/2);
            
            % panel dimension calculations
            obj.hghtPanelI = obj.dX + ...
                obj.hghtRow + (1+obj.nLblI)*obj.hghtHdr;
            obj.hghtPanelD = obj.dX + ...
                (nRowD+1)*obj.hghtRow + obj.hghtHdr;
            obj.hghtPanelL = obj.dX + ...
                2*obj.hghtHdr + obj.hghtAxL;
            
            % figure dimension calculations
            obj.hghtFig = obj.hghtPanel + 2*obj.dX;            
            obj.widFig = obj.widPanelO + obj.widPanelAx + 3*obj.dX;
            
            % other object dimension calculations
            obj.widPanel = obj.widPanelO - obj.dX;
            obj.widBut = obj.widPanel - obj.dX;

            % ROI axes dimensions
            obj.widAx = obj.widPanelAx - 2*obj.dX;
            obj.hghtAx = obj.hghtPanel - 2*obj.dX;
            
            % large image axes dimensions
            obj.widAxL = obj.widPanel - obj.dX;
            
        end
        
        % --- initialises the class fields
        function initClassObjects(obj)
            
            % deletes any previous GUIs
            hPrev = findall(0,'tag',obj.tagStr);
            if ~isempty(hPrev); delete(hPrev); end
            
            % --------------------------- %
            % --- MAIN FIGURE OBJECTS --- %
            % --------------------------- %
            
            % creates the figure object
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % creates the figure object
            obj.hFig = createUIObj('figure','Position',fPos,...
                'tag',obj.tagStr,'MenuBar','None','Toolbar','None',...
                'Name',obj.figName,'Resize','off','NumberTitle','off',...
                'Visible','off','AutoResizeChildren','off',...
                'BusyAction','Cancel','GraphicsSmoothing','off',...
                'DoubleBuffer','off','Renderer','painters','CloseReq',[]);            
            
            % creates the outer panel object
            pPos = [obj.dX*[1,1],obj.widPanelO,obj.hghtPanel];
            obj.hPanelO = createPanelObject(obj.hFig,pPos);
            
            % ----------------------- %
            % --- SUB-PANEL SETUP --- %
            % ----------------------- %
                        
            % sets up the sub-panel objects
            obj.setupLargeVideoDimPanel();
            obj.setupROIDimensionPanel();
            obj.setupDeviceInfoPanel();
            obj.setupROIAxesPanels();
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %            
            
            % sets up the menu item objects
            obj.setupMenuItems();            
            
            % opens the class figure
            openClassFigure(obj.hFig,0);
            
        end      
        
        % --- initialises the object properties
        function initObjectProps(obj)
            
            % initialisations
            wState = warning('off','all');
            
            % resets the roi position to full region
            if obj.isWebCam
                % resets the axis limits
                xL = [0,obj.vRes(1)] + 0.5;
                yL = [0,obj.vRes(2)] + 0.5;                
                set(obj.hAxM,'xLim',xL,'yLim',yL);
            else
                % resets the roi position
                set(obj.infoObj.objIMAQ,'ROIPosition',[0,0,obj.vRes])
            end
            
            % pauses for a little bit...
            pause(0.1); 
            
            % -------------------------------------- %
            % --- OBJECT PROPERTY INITIALISATION --- %
            % -------------------------------------- %

            % sets the original resolution height/width
            obj.hTxtI{1}.String = num2str(obj.vRes(1));
            obj.hTxtI{2}.String = num2str(obj.vRes(2));
            
            % sets the editbox properties
            for i = 1:length(obj.rPos)
                obj.hEditD{i}.String = num2str(obj.rPos(i));
            end
            
            % ------------------------ %
            % --- IMAGE AXES SETUP --- %
            % ------------------------ %

            % get image snapshot
            obj.getInitSnapshot();

            % if there is no image object, then create a new one
            obj.hImg = image(obj.Img0,'parent',obj.hAx,...
                'CDataMapping','scaled');    
            set(obj.hAx,'xtick',[],'ytick',[],'xticklabel',[],...
                        'yticklabel',[],'ycolor','w','xcolor','w',...
                        'box','off','CLimMode','Auto')               
            
            % updates the alpha map
            obj.updateAlphaMap();
                    
            % creates the image markers
            for i = 1:2
                % sets the horizontal/vertical marker locations
                if i == 1
                    % case is the left/bottom side markers
                    xV = obj.rPos(1);
                    yH = size(obj.Img0,1) - sum(obj.rPos([2,4]));
                else
                    % case is the right/top side markers
                    xV = sum(obj.rPos([1,3]));
                    yH = yH + obj.rPos(4);
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
                set(obj.hAxL,'xtick',[],'ytick',[],'xticklabel',[],...
                             'yticklabel',[],'ycolor','k','xcolor','k',...
                             'box','on','linewidth',1)                         
                colormap(obj.hAxL,gray)   
                
                % case is the uncompressed region patch
                xLVR = [(obj.vRes(2)-C)/m,obj.vRes(1)*[1,1]];
                yLVR = [obj.vRes(2)*[1,1],polyval(obj.pL,obj.vRes(1))];                   
                
                % creates the patch object
                iiR = [(1:length(xLVR)),1];
                patch(obj.hAxL,xLVR(iiR),yLVR(iiR),'r','facealpha',0.2);
                
                % case is the compressed region patch
                xLVG = [0,0,xLVR(1:2),obj.vRes(1)];
                yLVG = [0,obj.vRes(2)*[1,1],yLVR(end),0];                
                
                % creates the patch object
                iiG = [(1:length(yLVG)),1];
                cbFcn = @obj.moveLargeVidMarker;
                patch(obj.hAxL,xLVG(iiG),yLVG(iiG),'g','facealpha',0.2);  
                
                % creates the marker point
                obj.hPointL = InteractObj('point',obj.hAxL,obj.rPos(3:4));
                obj.hPointL.setObjMoveCallback(cbFcn);
                
                % sets the object position constraint function
                obj.resetLargeVidAxisLimits();                   
                
                % updates the video status label
                obj.updateVideoStatus()
                
            else
                % if the video is not large, then disable the large
                % dimension axes panel
                setObjVisibility(obj.hPanelL,0)
            end   
            
            % --------------------------- %
            % --- GUI RE-DIMENSIONING --- %
            % --------------------------- %

            % resets the major gui dimensions
            pAR = obj.vRes(1)/obj.vRes(2);
            pPos = get(obj.hAx,'Position');

            % resets the axes, image panel and figure dimensions
            pPos(3) = roundP(pAR*pPos(4));
            obj.hAx.Position = [obj.dX*[1,1],pPos(3:4)];
            resetObjPos(obj.hPanelAx,'Width',pPos(3) + 2*obj.dX);
            
            % resets the figure width
            wPos = sum(obj.hPanelAx.Position([1,3])) + obj.dX;
            resetObjPos(obj.hFig,'Width',wPos)

            % resets the axis limits
            del = 10;
            [xLim,yLim] = deal([0,obj.vRes(1)],[0,obj.vRes(2)]);
            set(obj.hAx,'xlim',xLim+del*[-1,1],'ylim',yLim+del*pAR*[-1,1])
                    
            % resets the camera to the original ROI position
            if obj.isWebCam
                yOfs = size(obj.Img0,1) - sum(obj.rPos([2,4]));
                xL = (obj.rPos(1)+0.5) + [0,obj.rPos(3)];
                yL = (obj.rPos(2)+yOfs+0.5) + [0,obj.rPos(4)];                 
                set(obj.hAxM,'xLim',xL,'yLim',yL);                
            else
                set(obj.infoObj.objIMAQ,'ROIPosition',obj.rPos)
            end
            
            % resets the warnings
            warning(wState);            
                    
        end
        
        % --- sets up the menu item objects
        function setupMenuItems(obj)
            
            hMenuF = uimenu(obj.hFig,'Label','File');
            uimenu(hMenuF,'Label','Close Window','Accelerator','X',...
                          'Callback',@obj.closeWindow);
            
        end
        
        % ------------------------------------ %
        % --- PANEL OBJECT SETUP FUNCTIONS --- %
        % ------------------------------------ %

        % --- set up the large video dimensions panel objects        
        function setupLargeVideoDimPanel(obj)
           
            % creates the panel object
            yPos = obj.hghtPanel - ((3/2)*obj.dX + ...
                obj.hghtPanelI + obj.hghtPanelD + obj.hghtPanelL);
            pPos = [obj.dX/2,yPos,obj.widPanel,obj.hghtPanelL];
            obj.hPanelL = createPanelObject(obj.hPanelO,pPos,obj.tHdrL);
            
            % creates the text label
            obj.hTxtL = createObjectPair(obj.hPanelL,'Status',...
                obj.widLblL,'text','xOfs',obj.dX/2,'fSzM',obj.fSzL);
            obj.hTxtL.String = 'Compression Possible';
            
            % creates the axes object
            yPosAx = obj.dX + obj.hghtHdr;
            pPosAx = [obj.dX/2,yPosAx,obj.widAxL,obj.hghtAxL];
            obj.hAxL = createUIObj('axes',obj.hPanelL,...
                'Units','Pixels','Position',pPosAx,'Box','on');
            
        end
            
        % --- set up the device ROI dimensions panel objects        
        function setupROIDimensionPanel(obj)

            % initialisations
            nRowD = ceil(obj.nEditD/2);            
            tTxtB = 'Update Preview ROI';
            tTxtI = {'Left: ','Bottom: ','Width: ','Height: '};            
            pType = {'text','edit','text','edit'};
            cbFcnE = @obj.editUpdateROI;            
            
            % creates the panel object
            yPos = sum(obj.hPanelL.Position([2,4])) + obj.dX/2;
            pPos = [obj.dX/2,yPos,obj.widPanel,obj.hghtPanelD];
            obj.hPanelD = createPanelObject(obj.hPanelO,pPos,obj.tHdrD);            
            
            % creates the pushbutton object
            pPosB = [obj.dX*[1,1]/2,obj.widBut,obj.hghtBut];
            obj.hButD = createUIObj('pushbutton',obj.hPanelD,...
                'Position',pPosB,'FontUnits','Pixels',...
                'FontWeight','Bold','FontSize',obj.fSzL,...
                'Callback',@obj.buttonUpdateROI,'String',tTxtB);            

            % creates the ROI dimension editbox objects
            pStr = cell(1,4);
            yOfs0 = obj.dX + obj.hghtRow;
            for i = 1:nRowD
                % calculates the vertical offset
                j = nRowD - (i-1);
                ii = (1:2) + (i-1)*2;
                yOfs = yOfs0 + (j-1)*obj.hghtRow;
                pStr([1,3]) = tTxtI(ii);
                
                % creates the group objects
                hObj = createObjectRow(obj.hPanelD,length(pType),...
                    pType,obj.widObjD,'yOfs',yOfs,'dxOfs',0,...
                    'pStr',pStr,'xOfs',obj.dX/2);
                
                % sets the editbox properties
                cellfun(@(x)(...
                    set(x,'HorizontalAlignment','Right')),hObj([1,3]))
                cellfun(@(x,y)(set(x,'Callback',...
                    cbFcnE,'UserData',y)),hObj([2,4]),num2cell(ii(:)));
                obj.hEditD(ii) = hObj([2,4]);
            end
            
        end
        
        % --- set up the device information panel objects
        function setupDeviceInfoPanel(obj)
        
            % initialisations
            tTxtB = 'Reset Preview ROI';
            tTxtI = {'Original Width','Original Height'};
            
            % creates the panel object
            yPos = sum(obj.hPanelD.Position([2,4])) + obj.dX/2;
            pPos = [obj.dX/2,yPos,obj.widPanel,obj.hghtPanelI];
            obj.hPanelI = createPanelObject(obj.hPanelO,pPos,obj.tHdrI);
            
            % creates the pushbutton object
            pPosB = [obj.dX*[1,1]/2,obj.widBut,obj.hghtBut];
            obj.hButI = createUIObj('pushbutton',obj.hPanelI,...
                'Position',pPosB,'FontUnits','Pixels',...
                'FontWeight','Bold','FontSize',obj.fSzL,...
                'Callback',@obj.buttonResetROI,'String',tTxtB);
            
            % creates the 
            yOfs0 = obj.dX + obj.hghtRow;
            for i = 1:obj.nLblI
                j = obj.nLblI - (i-1);
                yOfs = yOfs0 + (j-1)*obj.hghtHdr;
                obj.hTxtI{i} = createObjectPair(obj.hPanelI,tTxtI{i},...
                    obj.widLblI,'text','yOfs',yOfs,'fSzM',obj.fSzL,...
                    'hghtEdit',obj.hghtEdit,'xOfs',obj.dX/2);
            end
            
        end
            
        % --- set up the roi axes panel objects        
        function setupROIAxesPanels(obj)
            
            % creates the panel object
            xPos = sum(obj.hPanelO.Position([1,3])) + obj.dX;
            pPos = [xPos,obj.dX,obj.widPanelAx,obj.hghtPanel];
            obj.hPanelAx = createPanelObject(obj.hFig,pPos);            
            
            % creates the axes object
            pPosAx = [obj.dX*[1,1],obj.widAx,obj.hghtAx];
            obj.hAx = createUIObj('axes',obj.hPanelAx,...
                'Units','Pixels','Position',pPosAx,'Box','on');            
            
        end
        
        % ------------------------------------ %
        % --- MENU ITEM CALLBACK FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- close window menu item callback function
        function closeWindow(obj, ~, ~)
            
            % resets the figure visibility flags
            setObjVisibility(obj.hFig,0);
            setObjVisibility(obj.hFigM,1);
            
            % deletes the figure
            delete(obj.hFig);
            
        end        
        
        % --------------------------------------- %
        % --- OTHER OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- reset preview ROI pushbutton callback function
        function buttonResetROI(obj,~,~)
            
            % updates all ROI markers
            rPos0 = [0,0,obj.vRes];
            obj.updateAllROIMarkers(rPos0)
            
            % resets the dimension edit box values
            for i = 1:obj.nEditD
                obj.hEditD{i}.String = num2str(rPos0(i));
            end
            
            % resets the main GUI dimensions
            obj.resetFcn(guidata(obj.hFigM),rPos0)
            
            % resets the alpha map
            obj.rPos = rPos0;
            obj.updateAlphaMap();
            
        end
        
        % --- update preview ROI editbox callback function
        function editUpdateROI(obj, hEdit, ~)
            
            % parameters            
            uData = hEdit.UserData;
            
            % retrieves the current ROI dimensions
            rPos0 = roundP(obj.getCurrentROIDim());  
            
            % determines the parameter limits (based on type
            switch uData
                case 1 
                    % case is the ROI left location
                    nwLim = [0,max(0,floor(obj.vRes(1)-rPos0(3)))];

                case 2 
                    % case is the ROI bottom location
                    nwLim = [0,max(0,floor(obj.vRes(2)-rPos0(4)))];

                case 3 
                    % case is the ROI width
                    nwLim = [obj.szMin,floor(obj.vRes(1)-rPos0(1))];

                case 4 
                    % case is the ROI height
                    nwLim = [obj.szMin,floor(obj.vRes(2)-rPos0(2))];
            end     
            
            % determines if the new value is valid
            nwVal = str2double(hEdit.String);
            if chkEditValue(nwVal,nwLim,1)
                % if so, then update the parameter value and the 
                obj.rPos(uData) = nwVal;
                obj.updateAllROIMarkers(obj.rPos);  
                obj.updateAlphaMap();
                
                if obj.isLV
                    obj.updateLargeVideoMarker(obj.rPos(3:4));
                    obj.resetLargeVidAxisLimits()
                end
            else
                % resets the back to the last visible
                hEdit.String = num2str(rPos0(uData));
            end            
            
        end        
        
        % --- update preview ROI pushbutton callback function
        function buttonUpdateROI(obj,~,~)
            
            % resets the ROI dimensions
            pROI = roundP((obj.getCurrentROIDim()-0.01));
            obj.resetFcn(guidata(obj.hFigM),pROI);            
            
        end        

        % ---------------------------- %        
        % --- ROI MARKER FUNCTIONS --- %
        % ---------------------------- %
        
        % --- creates the ROI marker object
        function createROIMarker(obj,pL,ind,isVert)
            
            % initialisations
            fCol = 0.75*[1,1,1];            
            xLim = get(obj.hAx,'xlim');
            yLim = get(obj.hAx,'ylim');
            uData = [isVert,ind];

            % sets the marker coordinates
            if isVert
                % case is a vertical marker
                yROI = yLim;
                xROI = pL*[1,1];

            else
                % case is a horizontal marker
                xROI = xLim;
                yROI = pL*[1,1];                
            end

            % creates a patch object object
            hLineS = InteractObj('line',obj.hAx,{xROI,yROI});
            hLineS.setFields('UserData',uData,'tag','hROILim')

            % case is the newer version interactive objects
            set(hLineS.hObj,'Color',fCol,'StripeColor','r');            
            
            % sets the constraint/position callback functions
            hLineS.setObjMoveCallback(@obj.moveROIMarker);
            hLineS.setConstraintRegion(xLim,yLim);
            hLineS.setLineProps('InteractionsAllowed','translate')
            
        end  
        
        % --- callback function for moving the ROI marker object
        function moveROIMarker(obj,varargin)

            % global variables
            if obj.manualUpdate; return; end

            % retrieves the ROI positional coordinates
            switch length(varargin)
                case 1
                    % case is old version roi callback
                    uData = get(get(gco,'Parent'),'UserData');
                    p = varargin{1};
                    
                case 2
                    % case is double input 
                    uData = varargin{2}.Source.UserData;
                    p = get(varargin{1},'Position');                    
            end            
            
            % retrieves the location of the opposite marker object
            uDataF = [uData(1),1+(uData(2)==1)];
            hPatchF = findall(obj.hAx,'tag','hROILim','UserData',uDataF);
            pF = getIntObjPos(hPatchF);                        
            
            if uData(1)
                % case is a vertical line

                % sets the length dimension parameter object  
                if uData(2) == 1
                    % case is the left line
                    obj.rPos(1) = roundP(p(1,1)-0.5); 
                    obj.rPos(3) = roundP(pF(1,1)-obj.rPos(1));
                    
                else
                    % case is the right line
                    obj.rPos(3) = min(obj.vRes(1),roundP(p(1,1)-pF(1,1)));
                end
                
                % sets the bottom coordinate
                obj.rPos = obj.resetRectPos(obj.rPos,uData);
                obj.hEditD{1}.String = num2str(obj.rPos(1));
                obj.hEditD{3}.String = num2str(obj.rPos(3));

            else
                % case is a horizontal line
                
                % sets the length dimension parameter object 
                if uData(2) == 2
                    % case is the bottom line
                    obj.rPos(2) = max(0,roundP((size(obj.Img0,1)-p(1,2))-0.5));
                    obj.rPos(4) = roundP(p(1,2)-pF(1,2));
                    
                else
                    % case is the top line
                    obj.rPos(4) = min(obj.vRes(2),roundP(pF(1,2)-p(1,2)));
                end
                
                % sets the bottom coordinate   
                obj.rPos = obj.resetRectPos(obj.rPos,uData);
                obj.hEditD{2}.String = num2str(obj.rPos(2));
                obj.hEditD{4}.String = num2str(obj.rPos(4));
            end
            
            % updates the image alphamap
            obj.updateAlphaMap();
            
            % updates the large
            if obj.isLV
                obj.updateLargeVideoMarker(obj.rPos(3:4))  
                obj.resetLargeVidAxisLimits()
            end

        end        
        
        % --- updates the image alphamap
        function updateAlphaMap(obj)
            
            obj.Amap(:) = 255;

            % resets the column alpha map fields
            obj.Amap(:,1:(obj.rPos(1)-1)) = 128;
            obj.Amap(:,(sum(obj.rPos([1,3]))+1):end) = 128;
            
            % resets the column alpha map fields
            iRHi = size(obj.Amap,1) - obj.rPos(2);
            iRLo = size(obj.Amap,1) - sum(obj.rPos([2,4]));
            obj.Amap(1:(iRLo-1),:) = 128;
            obj.Amap((iRHi+1):end,:) = 128;
            
            % updates the alpha mapping mask
            obj.hImg.AlphaData = uint8(obj.Amap);
            
        end
        
        % --- updates the large video marker position
        function updateLargeVideoMarker(obj,rPos)
            
            % global variables
            obj.manualUpdate = true;

            % updates the position of the marker
            obj.hPointL.setPosition(rPos);    
            obj.updateVideoStatus(rPos);
            
            % global variables
            obj.manualUpdate = false;            
            
        end

        % --- updates all the ROI markers given the ROI vector, rPos
        function updateAllROIMarkers(obj,rPos)

            % global variables
            obj.manualUpdate = true;

            % resets the ROI marker on the left side
            hLineX1 = findall(obj.hAx,'tag','hROILim','UserData',[1,1]);
            obj.updateROIMarker(hLineX1,1,rPos(1));

            % resets the ROI marker on the right side
            hLineX2 = findall(obj.hAx,'tag','hROILim','UserData',[1,2]);
            obj.updateROIMarker(hLineX2,1,sum(rPos([1,3])));

            % resets the ROI marker on the bottom side
            hLineY1 = findall(obj.hAx,'tag','hROILim','UserData',[0,2]);
            obj.updateROIMarker(hLineY1,2,obj.vRes(2)-rPos(2));

            % resets the ROI marker on the top side
            hLineY2 = findall(obj.hAx,'tag','hROILim','UserData',[0,1]);
            obj.updateROIMarker(hLineY2,2,obj.vRes(2)-sum(rPos([2,4])));

            % resets the manual update flag
            obj.manualUpdate = false;

        end        
        
        % --- callback function for the large video marker
        function moveLargeVidMarker(obj,p,varargin)
            
            % global variables
            if obj.manualUpdate; return; end            
            
            % updates the ROI position vector
            obj.rPos(3:4) = floor(p.Position);
            obj.updateAlphaMap;
            
            % sets the bottom coordinate
            obj.hEditD{3}.String = num2str(obj.rPos(3));
            obj.hEditD{4}.String = num2str(obj.rPos(4));
            
            % updates the position markers            
            obj.updateAllROIMarkers(obj.rPos);
            obj.updateVideoStatus(obj.rPos(3:4));
            
        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- retrieves the current ROI dimension vector
        function rPos = getCurrentROIDim(obj)
           
            % memory allocation
            hLine = cell(4,1);

            % retrieves the marker object handles
            for i = 1:2
                for j = 1:2
                    k = 2*(i-1)+j;
                    hLine{k} = findall(obj.hAx,...
                        'tag','hROILim','UserData',[(i-1),j]);
                end
            end

            % retrieves the position of the marker objects
            fPos = cellfun(@(x)(getIntObjPos(x)),hLine,'un',0);

            % sets up the position vector
            X = fPos{3}(1,1);
            W = round(fPos{4}(1,1) - fPos{3}(1,1));
            H = round(fPos{2}(1,2) - fPos{1}(1,2));
            Y = size(obj.Img0,1) - fPos{2}(1,2);
            rPos = [X,Y,W,H];            
            
        end                       
        
        % --- retrieves the initial snapshot image
        function getInitSnapshot(obj)
            
            % parameters
            iter = 0;
            dITol = 5;
            tPause = 0.25;  
            nIterMx = 10;
            pause(1)
            
            % sets 
            I = {double(obj.getSnapShot()),[]};
            pause(tPause);
            I{2} = double(obj.getSnapShot());
            
            % retrieves the initial image
            while mean(abs(I{2}(:) - I{1}(:))) > dITol
                % pauses for the required time
                pause(tPause);
                
                % retrieves the new image
                I{1} = I{2};
                I{2} = double(obj.getSnapShot());

                % if taking too long then exit the loop
                iter = iter + 1;
                if iter < nIterMx
                    break
                end
            end                            
            
            % sets the final image
            obj.Img0 = uint8(I{2});
            obj.Amap = 255*ones(size(obj.Img0(:,:,1)));
            
        end        
        
        % --- retrieves the image snapshot (converts to rgb)
        function Img = getSnapShot(obj)
            
            if obj.isWebCam
                ImgNw = double(snapshot(obj.infoObj.objIMAQ));
            else
                ImgNw = double(getsnapshot(obj.infoObj.objIMAQ));
            end
               
            % scales the image
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
            hTxt = findall(obj.hFigM,'tag','textVidStatus');
            set(hTxt,'string',mStr{1+uncompOnly},...
                     'Foregroundcolor',col(1+uncompOnly))
            
        end
        
        % --- resets the large video axis limits 
        function resetLargeVidAxisLimits(obj)
        
            % retrieves the x/y-axis limits
            xLimLV = [0,obj.vRes(1)-obj.rPos(1)];
            yLimLV = [0,obj.vRes(2)-obj.rPos(2)];
            
            % resets the axis limits and constraint region
            set(obj.hAxL,'xlim',xLimLV,'yLim',yLimLV)                      
            obj.hPointL.setConstraintRegion(xLimLV,yLimLV);
            
        end        
        
    end
    
    % class methods
    methods (Static)
        
        % --- updates the location of the ROI marker rectangle
        function updateROIMarker(hLine,iDim,nwVal)

            % retrieves the current marker position
            rPos = getIntObjPos(hLine);
            rPos(:,iDim) = nwVal;
            setIntObjPos(hLine,rPos);

        end        
        
        % --- resets the roi marker position vector (must be feasible and
        %     dimensions must be a multiple of 2)
        function p = resetRectPos(p,uData)
                        
            % determines the odd dimensions
            p = roundP(p);
            if uData(1)
                % case is a vertical marker
                if mod(p(3),2) == 1
                    if uData(2) == 1
                        % case is the left marker
                        p([1,3]) = p([1,3]) + [1,-1];
                        
                    else
                        % case is the right marker
                        p(3) = p(3) - 1;
                        
                    end                                        
                end
                
            else
                % case is a horizontal marker
                if mod(p(4),2) == 1   
                    if uData(2) == 2
                        % case is the bottom
                        p([2,4]) = p([2,4]) + [1,-1];
                        
                    else
                        % case is the top
                        p(4) = p(4) - 1;
                    end                    
                end                
            end
            
        end   
        
    end    
    
end