classdef VideoClipper < handle
    
    % class properties
    properties
    
        % main object handle class fields
        hFig
        hPanelAx
        hPanelI
        hPanelC
        hPanelP
        
        % image axes class fields
        hAxI
        hImg
        
        % clipping axes class fields
        hAxC
        hButP
        hButC
        hButCS
        hButL
        
        % clipping axes class fields
        hPanelPI
        hTxtI
        
        % frame selection class fields
        hPanelPF
        hEditF
        hButF
        
        % clipped video info class fields
        hPanelPC
        hEditC
        hMarkL
        hMarkF
        hMarkP
        
        % video information class fields
        vObj
        vDir
        vName
        iFrm
        nFrm
        fRate
        indCF
        
        % fixed object dimension fields
        dX = 10;
        dHght = 20;
        hghtRow = 25;
        hghtBut = 25;
        hghtTxt = 16;
        hghtEdit = 21;
        hghtPanel = 800;
        hghtPanelC = 50;
        widPanel = 1200;
        widPanelP = 250;
        widTxtLI = 85;
        widTxtLC = 45;
        
        % calculated object dimension fields
        hghtFig
        hghtAxI
        hghtAxC
        hghtPanelI
        hghtPanelPI
        hghtPanelPF
        hghtPanelPC
        widFig
        widPanelAxC
        widPanelAxI
        widPanelI
        widAxI
        widAxC
        widTxtI
        widEditF
        widEditC   
        widButL
        
        % boolean flags
        isUpdating = false;
        isOutputting = false;
        
        % static numeric class fields
        fSzB = 16;
        fSzH = 13;
        fSzL = 12;
        fSz = 10 + 2/3;
        nRowI = 4;
        nRowC = 3;
        dnFrm = 5;
        
        % static string class fields
        vType = '*.mp4';
        vProf = 'MPEG-4';
        pChr = char(9654);
        tagStr = 'figVideoClip';
        bStr = {'<<','<','>','>>'};
        tStrB = 'Start Video Clipping';
        tStrBS = 'Cancel Video Output';
        figName = 'Video Clipping Program';
        fMode = {'*.mp4','MPEG-4 Videos (*.mp4)'};
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = VideoClipper()
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initClassObjects();
            
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

            % pre-calculations
            hght0 = obj.dX + obj.dHght;
            
            % ------------------------------------- %
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- %
            
            % image axes panel dimensions
            obj.hghtPanelI = obj.hghtPanel - (3*obj.dX + obj.hghtPanelC);
            obj.widPanelAxI = obj.widPanel - (3*obj.dX + obj.widPanelP);
            obj.widAxI = obj.widPanelAxI - 2*obj.dX;            
            obj.hghtAxI = obj.hghtPanelI - 2*obj.dX;
            
            % clipping parameter panel dimensions
            obj.widPanelAxC = obj.widPanel - 2*obj.dX;            
            obj.hghtAxC = obj.hghtPanelC - 2*obj.dX;
            obj.widAxC = obj.widPanelAxC - (3*obj.dX + obj.hghtAxC);
            
            % image properties panel dimensions
            obj.widPanelI = obj.widPanelP - 2*obj.dX;
            obj.hghtPanelPI = hght0 + 2*obj.nRowI*obj.dX;
            obj.hghtPanelPF = hght0 + obj.hghtRow + obj.dX/2;
            obj.hghtPanelPC = hght0 + obj.nRowC*obj.hghtRow + obj.dX;
            obj.widTxtI = obj.widPanelI - (obj.dX + obj.widTxtLI);
            obj.widEditF = obj.widPanelI - (2*obj.dX + 4*obj.hghtBut);
            obj.widEditC = (obj.widPanelI - 2*(obj.dX + obj.widTxtLC))/2;
            obj.widButL = (obj.widPanelI - 3*obj.dX)/2;
            
            % calculates the figure dimensions
            obj.hghtFig = 2*obj.dX + obj.hghtPanel;
            obj.widFig = 2*obj.dX + obj.widPanel;
            
        end
        
        % --- initialises the class objects
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
                'Resize','off','BusyAction','Cancel',...
                'CloseRequestFcn',@obj.closeWindow); 

            % creates the panel object
            pPosAx = [obj.dX*[1,1],obj.widPanel,obj.hghtPanel];
            obj.hPanelAx = createUIObj(...
                'Panel',obj.hFig,'Position',pPosAx,'Title','');

            % --------------------------------- %
            % --- VIDEO CLIPPING AXES PANEL --- %
            % --------------------------------- %
            
            % sets up the file menu items
            hMenuF = uimenu(obj.hFig,'Label','File');
            uimenu(hMenuF,'Label','Open Video','Accelerator','O',...
                        'Callback',@obj.openVideo);
            uimenu(hMenuF,'Label','Close Window','Accelerator','X',...
                        'Callback',@obj.closeWindow,'Separator','on');
            
            % --------------------------------- %
            % --- VIDEO CLIPPING AXES PANEL --- %
            % --------------------------------- %
            
            % creates the panel object
            pPosAxC = [obj.dX*[1,1],obj.widPanelAxC,obj.hghtPanelC];
            obj.hPanelC = createUIObj(...
                'Panel',obj.hPanelAx,'Position',pPosAxC,'Title','');

            % creates the play button object
            bPosP = [obj.dX*[1,1],obj.hghtAxC*[1,1]];
            obj.hButP = createUIObj('togglebutton',obj.hPanelC,...
                'Position',bPosP,'FontSize',obj.fSzB,...
                'FontWeight','Bold','String',obj.pChr,...
                'Callback',@obj.playButton);
            
            % creates the axes object
            lPosC = sum(bPosP([1,3])) + obj.dX/2;
            axPosC = [lPosC,obj.dX,obj.widAxC,obj.hghtAxC];
            obj.hAxC = createUIObj('axes',obj.hPanelC,'Position',axPosC);
            set(obj.hAxC,'XTickLabel',[],'YTickLabel',[],'Box','on',...
                         'TickLength',[0,0],'XColor','w','YColor','w');
                     
            % disables the panel
            setPanelProps(obj.hPanelC,0);
                     
            % ------------------------ %
            % --- IMAGE AXES PANEL --- %
            % ------------------------ %
            
            % creates the panel object
            yPosI = sum(pPosAxC([2,4])) + obj.dX;
            pPosAxI = [obj.dX,yPosI,obj.widPanelAxI,obj.hghtPanelI];
            obj.hPanelI = createUIObj(...
                'Panel',obj.hPanelAx,'Position',pPosAxI,'Title','');
            
            % creates the axes object
            axPosI = [obj.dX*[1,1],obj.widAxI,obj.hghtAxI];
            obj.hAxI = createUIObj('axes',obj.hPanelI,'Position',axPosI);
            set(obj.hAxI,'Box','On');            
            axis(obj.hAxI,'off');
            
            % ---------------------------- %
            % --- IMAGE PROPERTY PANEL --- %
            % ---------------------------- %
            
            % creates the panel object
            lPosP = sum(pPosAxI([1,3])) + obj.dX;
            pPosP = [lPosP,yPosI,obj.widPanelP,obj.hghtPanelI];
            obj.hPanelP = createUIObj(...
                'Panel',obj.hPanelAx,'Position',pPosP,'Title','');
            
            % creates the property information sub-panels
            obj.createSubPanels();
            obj.setSubPanelProps(0);            
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % centers the figure and makes it visible
            centerfig(obj.hFig);
            refresh(obj.hFig);
            pause(0.05);
            
            % makes the figure visible
            set(obj.hFig,'Visible','on');
            
        end
        
        % --- creates the information sub-panels
        function createSubPanels(obj)

            % -------------------------------------- %
            % --- VIDEO INFORMATION PANEL OBJECT --- %
            % -------------------------------------- %
            
            % initialisations
            hStrI = 'VIDEO INFORMATION';
            tTxtI = {'File Name','Frame Count','Frame Rate','Dimension'};            
            
            % creates the panel objects
            yPosI = obj.hghtPanelI - (obj.hghtPanelPI + obj.dX/2);
            pPosI = [obj.dX,yPosI,obj.widPanelI,obj.hghtPanelPI];
            obj.hPanelPI = createUIObj('panel',obj.hPanelP,...
                'Position',pPosI,'Title',hStrI,'FontSize',obj.fSzH,...
                'FontWeight','Bold');
            
            % creates the 
            obj.hTxtI = cell(length(tTxtI),1);
            for i = 1:length(tTxtI)
                j = length(tTxtI) - (i-1);
                yPos = obj.dX + 2*(j-1)*obj.dX; 
                obj.hTxtI{i} = obj.createLabelGroup(...
                    obj.hPanelPI,tTxtI{i},obj.widTxtLI,yPos);
            end            
            
            % ------------------------------------- %
            % --- FRAME SELECTION PANEL OBJECTS --- %
            % ------------------------------------- %
            
            % initialisations
            hStrF = 'FRAME SELECTION';
            obj.hButF = cell(length(obj.bStr),1);
            
            % creates the panel objects
            yPosF = yPosI - (obj.hghtPanelPF + obj.dX/2);
            pPosF = [obj.dX,yPosF,obj.widPanelI,obj.hghtPanelPF];
            obj.hPanelPF = createUIObj('panel',obj.hPanelP,...
                'Position',pPosF,'Title',hStrF,'FontSize',obj.fSzH,...
                'FontWeight','Bold');
            
            % other initialisations            
            for i = 1:length(obj.bStr)
                % sets up the button position vector
                lBut = obj.dX + (i-1)*obj.hghtBut + ...
                                (i>2)*(obj.widEditF);
                bPos = [lBut,obj.dX,obj.hghtBut*[1,1]]; 
                
                % creates the button object                
                obj.hButF{i} = createUIObj('Pushbutton',obj.hPanelPF,...
                    'Position',bPos,'Callback',@obj.frmSelect,...
                    'FontUnits','Pixels','FontSize',obj.fSz,...
                    'FontWeight','Bold','String',obj.bStr{i},...
                    'UserData',i);
            end            
            
            % creates the count editbox object
            lEdit = obj.dX + 2*obj.hghtBut;
            ePos = [lEdit,obj.dX+2,obj.widEditF,obj.hghtEdit];
            obj.hEditF = createUIObj('Edit',obj.hPanelPF,...
                'Position',ePos,'Callback',@obj.editSelect,...
                'FontUnits','Pixels','FontSize',obj.fSz);                        
            
            % ------------------------------------------ %
            % --- VIDEO CLIPPING INFORMATION OBJECTS --- %
            % ------------------------------------------ %
            
            % initialisations            
            hStrC = 'CLIPPED VIDEO DETAILS';
            tTxtC = {'Start','Finish'};
            tStrL = {'Reset Start','Reset Finish'};
            
            % creates the panel objects
            yPosC = yPosF - (obj.hghtPanelPC + obj.dX/2);
            pPosC = [obj.dX,yPosC,obj.widPanelI,obj.hghtPanelPC];
            obj.hPanelPC = createUIObj('panel',obj.hPanelP,...
                'Position',pPosC,'Title',hStrC,'FontSize',obj.fSzH,...
                'FontWeight','Bold');
            
            % creates the button object
            pPosBC = [obj.dX*[1,1],obj.widPanelI-2*obj.dX,obj.hghtBut];
            obj.hButC = createUIObj('pushbutton',obj.hPanelPC,...
                'Position',pPosBC,'FontSize',obj.fSzL,...
                'FontWeight','Bold','String',obj.tStrB,...
                'Callback',@obj.startClipButton);
            
            % creates the button object
            obj.hButCS = createUIObj('pushbutton',obj.hPanelPC,...
                'Position',pPosBC,'FontWeight','Bold',...
                'FontSize',obj.fSzL,'String',obj.tStrBS,...
                'Callback',@obj.stopClipButton,'Visible','off');
            
            % creates the frame limits button objects
            obj.hButL = cell(2,1);            
            yPosBL = sum(pPosBC([2,4])) + obj.dX/2;
            for i = 1:length(obj.hButL)
                xOfs = i*obj.dX + (i-1)*obj.widButL;
                pPosBL = [xOfs,yPosBL,obj.widButL,obj.hghtBut];
                obj.hButL{i} = createUIObj('pushbutton',obj.hPanelPC,...
                    'Position',pPosBL,'String',tStrL{i},'FontWeight','Bold',...
                    'FontSize',obj.fSzL,'Callback',@obj.resetLimit,...
                    'UserData',i);
            end
            
            % creates the editbox combo groups
            obj.hEditC = cell(2,1);
            yPos = sum(pPosBL([2,4])) + obj.dX/2;
            for i = 1:length(obj.hEditC)
                xOfs = (i-1)*(obj.dX/2 + obj.widTxtLC + obj.widEditC);
                obj.hEditC{i} = obj.createEditGroup(...
                    obj.hPanelPC,tTxtC{i},xOfs+obj.dX/2,yPos);
                set(obj.hEditC{i},'UserData',i,'Callback',@obj.editFrame);
            end
            
        end
        
        % --- creates the text label combo objects
        function hTxt = createLabelGroup(obj,hP,tTxt,widTxt,yPos)
            
            % initialisations
            tTxtL = sprintf('%s: ',tTxt);
            tWid = hP.Position(3) - (widTxt + obj.dX);
            
            % sets up the text label
            pPosL = [obj.dX/2,yPos,widTxt,obj.hghtTxt];
            createUIObj('text',hP,'Position',pPosL,'FontWeight','Bold',...
                'FontSize',obj.fSzL,'HorizontalAlignment','Right',...
                'String',tTxtL);
            
            % creates the text object
            lPosT = sum(pPosL([1,3]));
            pPosT = [lPosT,yPos,tWid,obj.hghtTxt];
            hTxt = createUIObj('text',hP,'Position',pPosT,...
                'FontSize',obj.fSz,'HorizontalAlignment','Left',...
                'String','N/A');
            
        end
        
        % --- creates the text label combo objects
        function hEdit = createEditGroup(obj,hP,tTxt,xOfs,yPos)
            
            % initialisations
            tTxtL = sprintf('%s: ',tTxt);
        
            % sets up the text label
            pPosL = [xOfs,yPos+2,obj.widTxtLC,obj.hghtTxt];
            createUIObj('text',hP,'Position',pPosL,'FontWeight','Bold',...
                'FontSize',obj.fSzL,'HorizontalAlignment','Right',...
                'String',tTxtL);
            
            % creates the text object
            lPosE = sum(pPosL([1,3]));
            pPosE = [lPosE,yPos,obj.widEditC-obj.dX/2,obj.hghtEdit];
            hEdit = createUIObj('edit',hP,'Position',pPosE,...
                'FontSize',obj.fSz);
            
        end

        % ------------------------------- %
        % --- MENU ITEM CLASS METHODS --- %
        % ------------------------------- %        
        
        % --- open video callback function
        function openVideo(obj, ~, evnt)
            
            % initialisations
            isInit = ~isempty(evnt);
            
            % field retrieval
            if isInit
                % field setup
                tStr = 'Select Video File';
                dDir = 'C:\Work\DART\Documents\Michael\Documentation\2.0 - Fly Tracking\Videos';
            
                % user is manually selecting file to open            
                [fName,fDir,fIndex] = uigetfile(obj.fMode,tStr,dDir);
                if ~fIndex
                    % if the user cancelled, then exit
                    return
                    
                else
                    % otherwise, update the video directory/name fields
                    obj.iFrm = 1;
                    [obj.vDir,obj.vName] = deal(fDir,fName);
                end
            end
            
            % opens the video file
            obj.vObj = VideoReader(fullfile(obj.vDir,obj.vName));
            
            % resets the dialog window/image axes
            if isInit
                % case is manually loading file
                obj.resetDialogWindow();
                obj.initImageAxes();
                
            else
                % case is reloading file
                obj.updateImageFrame(obj.iFrm);
            end
            
            % sets the video information fields
            obj.setVideoInfoFields(isInit);                       
            
            % initialises the image/clipping axes
            obj.initClippingAxes();            
            
        end        
        
        % --- close window callback function
        function closeWindow(obj, ~, ~)
            
            delete(obj.hFig);
            
        end        
        
        % ---------------------------------- %
        % --- OTHER OBJECT CLASS METHODS --- %
        % ---------------------------------- %        
        
        % --- play button callback function
        function playButton(obj, hToggle, ~)
            
            if get(hToggle,'Value')
                obj.setSubPanelProps(0);
                obj.showMovie();
            end
            
        end
        
        % --- start clip button callback function
        function startClipButton(obj, hBut, ~)
            
            % field update
            obj.isOutputting = true;
            setObjVisibility(hBut,'off');
            setObjVisibility(obj.hButCS,'on');
                            
            % starts the video clipping
            obj.clipVideo();
            
        end
        
        % --- stop clip button callback function
        function stopClipButton(obj, hBut, ~)
            
            % field update
            obj.isOutputting = false;
            setObjVisibility(hBut,'off');
            setObjVisibility(obj.hButC,'on');            
            drawnow
            
        end
        
        % --- video clipping function
        function clipVideo(obj)            
            
            % sets up the original sub-directory 
            vDirT = fullfile(obj.vDir,'Orig');
            if ~exist(vDirT,'dir')
                mkdir(vDirT);
            end
            
            % sets up the temporary file name
            vFile0 = fullfile(obj.vDir,obj.vName);
            vFileT = fullfile(vDirT,obj.vName);
            movefile(vFile0,vFileT);

            % disables the sub-panels
            obj.setSubPanelProps(0);  
            setObjEnable(obj.hButP,0);
            setObjEnable(obj.hButCS,1);            

            % refreshes the screen
            pause(0.01);
            drawnow            
            
            % ---------------------------- %
            % --- CLIPPED VIDEO OUTPUT --- %
            % ---------------------------- %            
            
            % initialisations
            iFrm0 = obj.iFrm;
            isCancel = false;
            
            % creates the temporary video read object
            vObjR = VideoReader(vFileT);
            
            % sets up the video writer object
            vObjW = VideoWriter(vFile0,obj.vProf);
            vObjW.FrameRate = obj.fRate;
            open(vObjW);
            
            % resets the video read current time
            vObjR.CurrentTime = (obj.indCF(1) - 1)/obj.fRate;
            obj.hMarkP.setPosition([obj.indCF(1),0,0,1]);
            obj.hMarkP.setLineProps('Visible','on');
            obj.hMarkF.setLineProps('Visible','off');
            
            % refreshes the screen
            pause(0.01);
            drawnow
            
            % creates the clipped video
            iFrmW = obj.indCF(1);
            while iFrmW <= obj.indCF(2)
                % determines if the user has cancelled video output
                if ~obj.isOutputting
                    % if so, then exit the loop
                    isCancel = true;
                    break
                end
                
                % updates the progressbar
                pWid = iFrmW - obj.indCF(1);
                obj.hMarkP.setPosition([obj.indCF(1),0,pWid,1]);
            
                % reads/writes the new frame
                writeVideo(vObjW,readFrame(vObjR,'Native'));
                
                % increments the count
                iFrmW = iFrmW + 1;
                drawnow();
            end            
            
            % resets the button properties
            obj.iFrm = iFrm0;                        
            setObjVisibility(obj.hButCS,'off');
            setObjVisibility(obj.hButC,'on');
            
            % closes the video write object
            close(vObjW);
            pause(0.1);            
            
            if isCancel
                % if cancelling, reset the original frame indices
                obj.hMarkP.setLineProps('Visible','off');
                obj.hMarkF.setLineProps('Visible','on');
                obj.hEditF.String = num2str(iFrm0);
                obj.editSelect(obj.hEditF,[]);                                                
                
                % re-enables the sub-panels
                obj.setSubPanelProps(1);
                
                % resets the button properties
                obj.setLimitButtonProps();
                obj.setSelectButtonProps();
                
                % then reset the original file
                delete(vFile0);
                movefile(vFileT,vFile0);                
                
            else
                % otherwise, reload the video file
                obj.openVideo([],[]);
            end                        
               
            % resets the common objects
            setObjEnable(obj.hButP,obj.iFrm < obj.nFrm);
            
        end        
        
        % --- frame selection editbox callback function
        function editSelect(obj, hEdit, ~)

            % field retrieval
            nwVal = str2double(hEdit.String);
            
            % determines if the new value is valid
            if chkEditValue(nwVal,[1,obj.nFrm],1)
                % if so, then update the frame index/button properties
                obj.iFrm = nwVal;
                
                % updates the frame image
                obj.updateImageFrame(true);
                
                % updates the markers
                obj.isUpdating = true;                
                obj.hMarkF.setPosition([obj.iFrm*[1;1],[0;1]]);
                obj.isUpdating = false;                
                
            else
                % otherwise, reset the editbox value
                set(hEdit,'String',num2str(obj.iFrm));
            end

        end

        % --- frame selection button callback function
        function frmSelect(obj, hBut, ~)
            
            % updates the frame index
            switch hBut.UserData
                case 1
                    % case is the first frame
                    obj.iFrm = 1;
                    
                case 2
                    % case is the previous frame
                    obj.iFrm = obj.iFrm - 1;
                    
                case 3
                    % case is the next frame
                    obj.iFrm = obj.iFrm + 1;                    
                    
                case 4
                    % case is the last frame
                    obj.iFrm = obj.nFrm;                    
            end
            
            % updates the editbox/button properties
            obj.isUpdating = true;
            obj.hMarkF.setPosition([obj.iFrm*[1;1],[0;1]]);
            obj.isUpdating = false;            
            
            % updates the frame image
            obj.hEditF.String = num2str(obj.iFrm);            
            obj.updateImageFrame(true);
            
        end
        
        % --- start/finish frame editbox callback function
        function editFrame(obj, hEdit, ~)
            
            % field retrieval
            iType = hEdit.UserData;
            nwVal = str2double(hEdit.String);
            
            % sets the limits
            switch iType
                case 1
                    % case is the start frame
                    nwLim = [1,obj.indCF(2)-1];
                    
                case 2
                    % case is the final frame
                    nwLim = [obj.indCF(1)+1,obj.nFrm];
            end
            
            % determines if the new value is valid
            if chkEditValue(nwVal,nwLim,1)
                % if so, the update the field 
                obj.indCF(iType) = nwVal;

                % updates the marker limits
                obj.isUpdating = true;
                pPosNw = [obj.indCF(1),0,diff(obj.indCF),1];
                obj.hMarkL.setPosition(pPosNw);
                obj.isUpdating = false;

                % resets the button properties
                obj.setLimitButtonProps();
                
            else
                % otherwise, reset the last valid value
                set(hEdit,'String',num2str(obj.indCF(iType)));
            end
            
        end

        % --- marker limit reset button callback function
        function resetLimit(obj, hBut, ~)
            
            % field retrieval
            iType = hBut.UserData;
            
            % resets the frame limit fields
            if iType == 1
                obj.indCF(1) = obj.iFrm;
            else
                obj.indCF(2) = (obj.iFrm + 1) - obj.indCF(1);
            end
            
            % resets the editbox value     
            set(obj.hEditC{iType},'String',num2str(obj.indCF(iType)))
            
            % updates the marker limits
            obj.isUpdating = true;
            pPosNw = [obj.indCF(1),0,diff(obj.indCF),1];
            obj.hMarkL.setPosition(pPosNw);
            obj.isUpdating = false;
            
            % resets the button properties
            obj.setLimitButtonProps();
        end
        
        % -------------------------------------- %
        % --- IMAGE VIEWING OBJECT FUNCTIONS --- %
        % -------------------------------------- %

        % --- initialises the clipping axes objects
        function initImageAxes(obj)
            
            % reads the first image frame
            I = obj.getImageFrameSlow(obj.iFrm);
            
            % clears the image axes
            cla(obj.hAxI);
            
            % sets up the image object
            obj.hImg = image(obj.hAxI,I);
            set(obj.hAxI,'XTickLabel',[],'YTickLabel',[],'XTick',[],...
                         'YTick',[],'Box','On');
            
        end        
        
        % --- plays the video frames in order
        function showMovie(obj)
            
            % sets up the frame index array
            xiF = (obj.iFrm+1):obj.dnFrm:obj.nFrm;
            if xiF(end) < obj.nFrm
                xiF = [xiF,obj.nFrm];
            end
            
            % resets the video current time
            obj.vObj.CurrentTime = (xiF(1)-1)/obj.fRate;
            
            % plays the video for the frame indices
            for i = xiF
                if ~obj.hButP.Value
                    % if the user cancels, then exit  
                    obj.setSubPanelProps(1);
                    return
                    
                else
                    % updates the frame index
                    obj.iFrm = i;                    
                end
                
                % updates the image frame (using fast frame update)
                obj.updateImageFrame(false);  
                obj.hEditF.String = num2str(obj.iFrm);                
                
                % updates the other properties                
                obj.isUpdating = true;
                obj.hMarkF.setPosition([obj.iFrm*[1;1],[0;1]]);
                obj.isUpdating = false;
            end
            
            % resets the other object properties
            obj.setSubPanelProps(1);
            obj.setLimitButtonProps();
            obj.setSelectButtonProps();
            set(obj.hButP,'Value',0,'Enable','off')            
            
        end
        
        % --- updates the image frame
        function updateImageFrame(obj,isSlow)
            
            % resets the image axes
            if isSlow
                % case slow frame update
                obj.hImg.CData = obj.getImageFrameSlow(obj.iFrm);
                
                % updates the button properties
                obj.setSelectButtonProps();
                obj.setLimitButtonProps(); 
                
            else
                % case is fast frame update
                obj.hImg.CData = obj.getImageFrameFast(obj.iFrm);
            end
                
            % updates the image axes
            drawnow();        
            
        end
        
        % --- slow image frame read
        function I = getImageFrameSlow(obj,iFrmNw)
            
            I = read(obj.vObj,iFrmNw);
            
        end        
        
        % --- fast image frame read
        function I = getImageFrameFast(obj,iFrmNw)
           
            while true                
                I = readFrame(obj.vObj,'Native');
                if obj.vObj.CurrentTime == iFrmNw/obj.fRate
                    break
                end
            end
            
        end
        
        % --------------------------------------- %
        % --- VIDEO CLIPPING OBJECT FUNCTIONS --- %
        % --------------------------------------- %        
        
        % --- initialises the clipping axes objects
        function initClippingAxes(obj)
            
            % resets the axes limits
            set(obj.hAxC,'xLim',[0.5,obj.nFrm+0.5],'yLim',[0,1]);
        
            % deletes the previous markers (if not initialising)
            if ~isempty(obj.hMarkP)
                obj.hMarkP.deleteObj();
                obj.hMarkL.deleteObj();
                obj.hMarkF.deleteObj();
            end
            
            % creates the progressbar marker
            pPosP = [1,0,0,1];
            obj.hMarkP = InteractObj('rect',obj.hAxC,pPosP);
            obj.hMarkP.setColour('g');
            obj.hMarkP.setLineProps('FaceAlpha',0.5)
            obj.hMarkP.setLineProps('InteractionsAllowed','None')
            obj.hMarkP.setLineProps('Visible','off')
            obj.hMarkP.setMarkerSize(0.5);            
            
            % creates the clipping limit marker
            pWidL = diff(obj.indCF);
            pPosL = [obj.indCF(1),0,pWidL,1];
            obj.hMarkL = InteractObj('rect',obj.hAxC,pPosL);
            obj.hMarkL.setColour('r');
            obj.hMarkL.setConstraintRegion([1,obj.nFrm],[0,1]);
            obj.hMarkL.setObjMoveCallback(@obj.frameLimitMove);            
            obj.hMarkL.setLineProps('LineWidth',0.5)
            obj.hMarkL.setMarkerSize(0.5);             
            
            % creates the frame line marker
            pPosC = {obj.iFrm*[1,1],[0,1]};
            obj.hMarkF = InteractObj('line',obj.hAxC,pPosC);
            obj.hMarkF.setColour('b');            
            obj.hMarkF.setConstraintRegion([1,obj.nFrm],[0,1]);            
            obj.hMarkF.setObjMoveCallback(@obj.frameMarkerMove);            
            obj.hMarkF.setLineProps('LineWidth',3)
            obj.hMarkF.setLineProps('InteractionsAllowed','Translate')
            obj.hMarkF.setMarkerSize(9);                         
            
            % enables the panel properties
            setPanelProps(obj.hPanelC,1);
            
        end
        
        % --- frame limit movement callback function
        function frameLimitMove(obj,~,evnt)
            
            if obj.isUpdating
                % if manually updating then exit
                return
                
            else
                % otherwise, set the update flag
                obj.isUpdating = true;
            end
            
            % updates the clipped video frame indices
            cPos = evnt.CurrentPosition([1,3]);
            obj.indCF = round(cPos(1)+[0,cPos(2)]);
            obj.hEditC{1}.String = num2str(obj.indCF(1));
            obj.hEditC{2}.String = num2str(obj.indCF(2));
            
            % resets the limit button properties
            obj.setLimitButtonProps()
            
            % resets the update flag
            obj.isUpdating = false;
            
        end
        
        % --- frame marker movement callback function
        function frameMarkerMove(obj,~,evnt)
            
            if obj.isUpdating
                % if manually updating then exit
                return
                
            else
                % otherwise, set the update flag
                obj.isUpdating = true;
            end
            
            % updates the frame index
            set(obj.hEditF,'String',num2str(obj.iFrm));            
            obj.iFrm = round(evnt.CurrentPosition(1));
            
            % updates the frame image
            obj.updateImageFrame(true);
                        
            % resets the update flag
            obj.isUpdating = false;
            
        end        
        
        % --------------------------------- %
        % --- PROPERTY UPDATE FUNCTIONS --- %
        % --------------------------------- % 
        
        % --- resets the dialog window to fit the video object
        function resetDialogWindow(obj)
            
            % field retrieval
            pDim0 = obj.hAxI.Position(3:4);
            widAxNw = pDim0(2)*obj.vObj.Width/obj.vObj.Height;
            dWid = widAxNw - pDim0(1);            
            
            % resets the object dimensions
            resetObjPos(obj.hAxI,'Width',dWid,1)
            resetObjPos(obj.hPanelI,'Width',dWid,1)
            resetObjPos(obj.hPanelAx,'Width',dWid,1)
            resetObjPos(obj.hPanelC,'Width',dWid,1)
            resetObjPos(obj.hAxC,'Width',dWid,1)
            resetObjPos(obj.hFig,'Width',dWid,1)
            resetObjPos(obj.hPanelP,'Left',dWid,1)
            
            % re-centers the figure
            centerfig(obj.hFig);
            
        end

        % --- sets the video file information
        function setVideoInfoFields(obj,isInit)
            
            % field retrieval
            fFile = obj.vName;
            [H,W] = deal(obj.vObj.Height,obj.vObj.Width);            
            
            % initialises the frame index
            obj.nFrm = obj.vObj.NumFrame;
            obj.iFrm = min(obj.iFrm,obj.nFrm);
            obj.fRate = round(obj.vObj.NumFrames/obj.vObj.Duration,3);
            
            % resets the frame limits (if initialising)
            if isInit
                obj.indCF = [1,obj.nFrm];
            end
            
            % enables all the sub-panels
            obj.setSubPanelProps(1);            
            
            % sets the video info fields
            set(obj.hTxtI{1},'String',fFile,'ToolTipString',fFile);
            set(obj.hTxtI{2},'String',num2str(obj.nFrm));
            set(obj.hTxtI{3},'String',num2str(obj.fRate));
            set(obj.hTxtI{4},'String',sprintf('%i x %i',H,W));
            
            % initialises the editbox values
            set(obj.hEditF,'String',num2str(obj.iFrm));
            set(obj.hEditC{1},'String',num2str(obj.indCF(1)))
            set(obj.hEditC{2},'String',num2str(obj.indCF(2)));             
            
            % updates the frame selection 
            obj.setSelectButtonProps();
            obj.setLimitButtonProps();
            
        end        
        
        % --- sets the sub-panel properties
        function setSubPanelProps(obj, isOn)
            
            % disables all the panels
            setPanelProps(obj.hPanelPI,isOn);
            setPanelProps(obj.hPanelPF,isOn);
            setPanelProps(obj.hPanelPC,isOn);
            
        end
        
        % --- sets the frame selection button properties
        function setSelectButtonProps(obj)
            
            % pre-calculations
            notLast = obj.iFrm < obj.nFrm;
            
            % update the button properties
            cellfun(@(x)(setObjEnable(x,obj.iFrm>1)),obj.hButF(1:2))
            cellfun(@(x)(setObjEnable(x,notLast)),obj.hButF(3:4))
            setObjEnable(obj.hButP,notLast);
            
        end 
        
        % --- sets the frame limit button properties
        function setLimitButtonProps(obj)
            
            % sets the limit reset button properties
            setObjEnable(obj.hButL{1},...
                (obj.iFrm < obj.indCF(2)) && (obj.iFrm ~= obj.indCF(1)));
            setObjEnable(obj.hButL{2},...
                (obj.iFrm > obj.indCF(1)) && (obj.iFrm ~= obj.indCF(2)));
            
            % sets the clipping button properties
            isAllFrm = diff(obj.indCF) == (obj.nFrm - 1);
            setObjEnable(obj.hButC,~isAllFrm);
            
        end
        
    end    
    
end