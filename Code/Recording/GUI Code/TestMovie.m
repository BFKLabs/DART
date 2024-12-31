classdef TestMovie < handle
    
    % class properties
    properties
        
        % input arguments
        iProg
        infoObj        
        
        % output arguments
        vPara
        isSave
        
        % main class objects
        hFig
        
        % video properties panel objects
        hPanelP
        hEditP
        hTxtP
        hSliderP
        hPopupP
        hPopupPC
        
        % control button panel objects
        hPanelC
        hTxtC
        hButC
        
        % fixed dimension fields
        dX = 10;
        hghtTxt = 16;
        hghtBut = 25;
        hghtRow = 25;
        hghtHdr = 20;
        hghtEdit = 22;
        hghtPopup = 22;
        hghtSlider = 10;
        widObjP1 = 55;
        widObjP2 = 65;        
        widPanel = 450
        widTxtP1 = 155;
        widTxtP2 = 140;
        widLblC = 125;
        widTxtC = 80;
        widButC = 100;                
        
        % calculated dimension fields
        widFig
        hghtFig 
        hghtPanelP
        hghtPanelC
        widEditC
        
        % static class fields
        nRowP = 2;
        fSzH = 13;
        fSzL = 12;
        tMax = 3600;
        fSz = 10 + 2/3;
        bgCol = 0.5*ones(1,3);
        
        % static string fields
        tagStr = 'figTestMovie';
        figName = 'Record Test Movie';
        tHdrP = 'TEST VIDEO PROPERTIES';
        tStr = 'Select The Video Solution Files';
        
    end
    
    % class methods
    methods
        
        % --- class constuctor
        function obj = TestMovie(infoObj,iProg)            
            
            % sets the input arguments
            obj.infoObj = infoObj;
            obj.iProg = iProg;
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initClassObjects();
            
            % clears the output object (if not required)
            if (nargout == 0) && ~isdeployed
                clear obj
            end       
            
            % waits until the user responds...
            uiwait(obj.hFig);
            
        end        
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % memory allocation
            obj.vPara = struct('Dir',[],'Name',[],'Tf',10,'Ts',0,'FPS',[]);            
            
            % ------------------------------------- %
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- %
            
            % panel dimension calculations
            obj.hghtPanelP = obj.dX + ...
                obj.hghtHdr + obj.nRowP*(obj.hghtRow + obj.dX/2);
            obj.hghtPanelC = obj.dX + obj.hghtRow;
            
            % figure dimension calculations
            obj.widFig = obj.widPanel + 2*obj.dX;
            obj.hghtFig = obj.hghtPanelC + obj.hghtPanelP + 3*obj.dX; 
            
            % other object dimension calculations
            obj.widEditC = 2*obj.dX + obj.widLblC + obj.widTxtC;
            
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
                'Name',obj.figName,'Resize','on','NumberTitle','off',...
                'Visible','off','AutoResizeChildren','off',...
                'BusyAction','Cancel','GraphicsSmoothing','off',...
                'DoubleBuffer','off','Renderer','painters','CloseReq',[]);            
            
            % ----------------------- %
            % --- SUB-PANEL SETUP --- %
            % ----------------------- %
            
            % sets up the sub-panel objects
            obj.setupControlButtonPanel();
            obj.setupVideoPropertiesPanel();
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %            
                        
            % opens the class figure
            openClassFigure(obj.hFig);
            
        end
        
        % --- initialises the video parameter properties
        function initVideoParaProps(obj)
            
            % retrieves the camera frame rate
            if obj.infoObj.isWebCam
                % sets the frame rate values/selections    
                isVarFPS = false;
                [fRateN,fRateS,iSel] = ...
                    detWebcamFrameRate(obj.infoObj.objIMAQ,obj.vPara.FPS);                
                
            else
                % sets the frame rate values/selections
                isVarFPS = ...
                    detIfFrameRateVariable(obj.infoObj.objIMAQ);
                srcObj = getselectedsource(obj.infoObj.objIMAQ);
                [fRateN,fRateS,iSel] = ...
                    detCameraFrameRate(srcObj,obj.vPara.FPS);                
            end
            
            % sets the object visibility flags
            setObjVisibility(obj.hPopupP,~isVarFPS)
            setObjVisibility(obj.hTxtP,isVarFPS)
            setObjVisibility(obj.hSliderP,isVarFPS)
            
            % sets up the camera frame rate objects
            if isVarFPS
                % case is a variable frame rate camera
                initFrameRateSlider(obj.hSliderP,srcObj,fRateN);
                obj.sliderFrmRate([],[]);

            else
                % updates the video frame rate
                obj.vPara.FPS = fRateN(iSel);

                % initialises the frame rate listbox
                set(obj.hPopupP,'String',fRateS,'Value',iSel);
                setObjEnable(obj.hPopupP,length(fRateN) > 1);
                obj.popupFrmRate([],[]);
            end            
            
            % sets up the video compression popup box
            setupVideoCompressionPopup(obj.infoObj.objIMAQ,obj.hPopupPC,1)
            
        end        
        
        % ------------------------------------ %
        % --- PANEL OBJECT SETUP FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- sets up the control button panel objects
        function setupControlButtonPanel(obj)
            
            % initialisations
            tLblC = {'Video Frame Count: ',[],'Save Movie','Close Window'};
            pTypeC = {'text','text','pushbutton','pushbutton'};
            wObjC = [obj.widLblC,obj.widTxtC,obj.widButC*[1,1]];
            
            % function handles
            cbFcnB = {@obj.buttonSaveMovie;@obj.buttonCloseWindow};
            
            % creates the panel object
            pPos = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelC];
            obj.hPanelC = createPanelObject(obj.hFig,pPos);
            
            % creates the background editbox
            pPosE = [obj.dX*[1,1]/2,obj.widEditC,obj.hghtRow];
            createUIObj('edit',obj.hPanelC,'Position',pPosE,...
                'FontUnits','Pixels','FontSize',obj.fSz,...
                'Enable','inactive','BackgroundColor',obj.bgCol);
            
            % creates the objects
            hObjC = createObjectRow(obj.hPanelC,length(tLblC),pTypeC,...
                wObjC,'pStr',tLblC,'yOfs',obj.dX-2);
            
            % sets the text label properties
            set(hObjC{1},'HorizontalAlignment','Right');
            cellfun(@(x)(set(x,'ForegroundColor',ones(1,3),...
                'BackgroundColor',obj.bgCol)),hObjC(1:2))
            
            % sets the button object properties
            [obj.hButC,obj.hTxtC] = deal(hObjC(3:4),hObjC{2});
            cellfun(@(x,y)(set(x,'Callback',y)),obj.hButC,cbFcnB);
            cellfun(@(x)(resetObjPos(x,'Left',obj.dX,1)),obj.hButC);
            
        end        
        
        % --- sets up the video property panel objects
        function setupVideoPropertiesPanel(obj)
            
            % initialisations
            tLblPC = 'Video Compression Type';
            tLblP = {'Test Video Duration (sec): ',[],...
                     'Recording Frame Rate: ',[]};            
            wObjP = [obj.widTxtP1,obj.widObjP1,obj.widTxtP2,obj.widObjP2];
            pTypeP = {'text','edit','text','popupmenu'};              

            % function handles
            cbFcnPE = @obj.editFrmCount;
            cbFcnPP = @obj.popupFrmRate;
            cbFcnPS = @obj.sliderFrmRate;
            
            % creates the panel object
            yPos = sum(obj.hPanelC.Position([2,4])) + obj.dX;
            pPos = [obj.dX,yPos,obj.widPanel,obj.hghtPanelP];
            obj.hPanelP = createPanelObject(obj.hFig,pPos,obj.tHdrP);            
            
            % creates the compression type popup menu
            obj.hPopupPC = createObjectPair(obj.hPanelP,...
                tLblPC,obj.widTxtP1,'popupmenu');            
            resetObjPos(obj.hPopupPC,'Left',obj.dX/2,1);
            resetObjPos(obj.hPopupPC,'Width',-obj.dX/2,1);
            
            % creates the other objects
            yOfsP = (3/2)*obj.dX + obj.hghtRow;
            hObjP = createObjectRow(obj.hPanelP,length(pTypeP),pTypeP,...
                wObjP,'yOfs',yOfsP,'pStr',tLblP);
            cellfun(@(x)(set(x,'HorizontalAlignment','Right')),hObjP([1,3]))
            
            % sets the popup
            [obj.hEditP,obj.hPopupP] = deal(hObjP{2},hObjP{4});
            set(obj.hEditP,'Callback',cbFcnPE,...
                'FontSize',obj.fSz,'String',num2str(obj.vPara.Tf));
            set(obj.hPopupP,'Callback',cbFcnPP,'FontSize',obj.fSz);
            
            % creates the slider object
            yPosS = yOfsP - 2;
            xPosS = obj.hPopupP.Position(1);
            pPosS = [xPosS,yPosS,obj.widObjP2,obj.hghtSlider];
            obj.hSliderP = createUIObj('slider',obj.hPanelP,...
                'Position',pPosS,'Callback',cbFcnPS,'Visible','off');
            
            % creates the frame rate text object
            pPosS([2,4]) = [(yPosS+obj.hghtSlider),obj.hghtTxt];
            obj.hTxtP = createUIObj('text',obj.hPanelP,...
                'Position',pPosS,'String','Text',...
                'FontSize',obj.fSz,'Visible','off');
            
            % initialises the video parameter properties
            obj.initVideoParaProps();            
            
        end                
        
        % --------------------------------------- %
        % --- OTHER OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- frame count editbox callback function
        function editFrmCount(obj, hEdit, ~)
            
            % field retrieval
            nwVal = str2double(hEdit.String);
            
            % determines if the new value is valid
            if chkEditValue(nwVal,[5,obj.tMax],1)
                % if so, then update the parameter field and string
                obj.vPara.Tf = nwVal;
                obj.hTxtC.String = obj.detDurString();
                
            else
                % otherwise, reset to the last valid value
                hEdit.String = num2str(obj.vPara.Tf);
            end
            
        end
        
        % --- frame rate popupmenu callback function
        function popupFrmRate(obj, ~, ~)
            
            % field retrieval
            fList = obj.hPopupP.String;
            FPSnw = str2double(fList{obj.hPopupP.Value});            
            
            % if numerical, then update the frame rate field
            if ~isnan(FPSnw)
                obj.vPara.FPS = FPSnw;
            end
            
            % updates the duration string
            obj.hTxtC.String = obj.detDurString();
            
        end
        
        % --- frame rate slider callback function
        function sliderFrmRate(obj, ~, ~)
            
            % updates the frame rate
            obj.vPara.FPS = round(obj.hSliderP.Value,1);
            obj.hTxtP.String = num2str(obj.vPara.FPS);
            
            % sets the camera frame rate
            srcObj = get(obj.infoObj.objIMAQ,'Source');
            fpsFld = getCameraRatePara(srcObj);
            fpsInfo = propinfo(srcObj,fpsFld);
            fpsLim = fpsInfo.ConstraintValue;
            set(srcObj,fpsFld,max(min(obj.vPara.FPS,fpsLim(2)),fpsLim(1)));            
            
            % updates the duration string
            obj.hTxtC.String = obj.detDurString();            
            
        end        
                
        % --- save movie pushbutton callback function
        function buttonSaveMovie(obj, ~, ~)
            
            % field retrieval
            dDir = obj.iProg.DirMov;
            
            % retrieves the selected video file properties
            iSel = obj.hPopupPC.Value;
            vProf = get(obj.hPopupPC,'UserData');
            vExtn = vProf{iSel}.FileExtensions{1};
            vCompressM = vProf{iSel}.VideoCompressionMethod;
            
            % prompts the user for the solution file directory
            fMode = {['*',vExtn],sprintf('%s (*%s)',vCompressM,vExtn)};
            [fName,fDir,fIndex] = uiputfile(fMode,obj.tStr,dDir);
            if (fIndex == 0)
                % if the user cancelled, then exit
                return   
                
            else
                % sets the file name
                [~,obj.vPara.Name,~] = fileparts(fName);

                % otherwise, update the compression parameters    
                obj.vPara.Dir = fDir;
                obj.vPara.vCompress = vProf{iSel}.Name;
                obj.vPara.vExtn = vExtn;
            end                
            
            % sets the save flag
            obj.isSave = true;
            
            % deletes the dialog window
            delete(obj.hFig);            
            
        end
        
        % --- close window pushbutton callback function
        function buttonCloseWindow(obj, ~, ~)
            
            % sets the save flag
            obj.isSave = false;
            
            % deletes the dialog window
            delete(obj.hFig);
            
        end                
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- sets up the duration string           
        function durStr = detDurString(obj)

            % calculates time in (DD/HH/MM/SS) format 
            durStr = num2str(roundP(obj.vPara.Tf*obj.vPara.FPS));        
        
        end
        
    end 
    
end