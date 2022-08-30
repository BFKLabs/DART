classdef VideoSplitObj < handle
    
    % class properties
    properties
        
        % main class fields
        hFigM
        iDataM
        iData
        iMov        
        
        % temporary class fields
        vGrp
        hTimer
        hLine
        
        % class object fields
        hFig        
        hPanelP
        hPanelAx
        hMenuX
        
        % plot axes objects
        hImg
        hPanelImg
        hAxImg
        hPanelGrp
        hAxGrp
        
        % video group selection objects
        hPanelV
        hTxtV
        hButSV
        hEditSV
        hButLV
        hEditLV
        
        % video group control button objects
        hPanelC
        hButC
        
        % frame selection objects
        hPanelF
        hTxtF
        hButSF
        hEditSF
        
        % class object dimensions
        widFig
        hghtFig
        widPanelAll        
        widAxAll 
        hghtPanelGrp
        hghtAxImg
        hghtAxGrp        
        widButLV
        widPanelS
        widPanelC
        hghtPanelC
        y0PanelP
        widButC                
        
        % fixed object dimensions
        dX = 10;
        fSzH = 13;
        fSzT = 12;
        hghtBut = 25;
        hghtEdit = 22;
        hghtTxt = 16;
        widEditS = 85;
        widTxt = 90;
        widTxtL = 110;
        widTxtLV = 40;
        hghtPanelV = 240;
        hghtPanelF = 80;
        widEditLV = 55;
        widPanelP = 235;
        hghtPanelP = 350;        
        widPanelAx = 690;
        hghtPanelAx = 435;        
        hghtPanelImg = 350;        
        
        % other class fields
        tMove
        isOld
        tP = 0.1;
        fAlphaOn = 0.6;
        fAlphaOff = 0.1;
        ignoreMove = false;        
        updateFrm = false;
        updateGrp = false;
        pressCtrl = false;
        isChange = false;
        tagFigStr = 'figVideoSplit';  
        bStr = {'<<','<','>','>>'};
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = VideoSplitObj(hFigM)
        
            % sets the input arguments
            obj.hFigM = hFigM;
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initClassObj();
            obj.initObjProps();
                        
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % initialises the class fields/objects
        function initClassFields(obj)
            
            % initialises the tic object
            obj.tMove = tic;
            obj.isOld = isOldIntObjVer();
            
            % retrieves the program data/sub-region structs 
            obj.iDataM = get(obj.hFigM,'iData');
            obj.iMov = get(obj.hFigM,'iMov');            
            
            % initialisation of the program data struct
            obj.iData = obj.initDataStruct(obj.iDataM,obj.iMov);
            
            % sets the figure width/height dimensions
            obj.widFig = obj.widPanelAx + obj.widPanelP + 3*obj.dX;
            obj.hghtFig = obj.hghtPanelAx + 2*obj.dX;
            
            % sets the common axes/panel width dimensions
            obj.widPanelAll = obj.widPanelAx - 2*obj.dX;
            obj.widAxAll = obj.widPanelAll - 2*obj.dX;                                    
            
            % set the group panel height dimensions
            obj.hghtPanelGrp = obj.hghtPanelAx - ...
                                    (obj.hghtPanelImg + 3*obj.dX);
            
            % sets the axes object height dimensions                    
            obj.hghtAxImg = obj.hghtPanelImg - 2*obj.dX;
            obj.hghtAxGrp = obj.hghtPanelGrp - 2*obj.dX;            
            obj.y0PanelP = obj.hghtFig - (obj.dX + obj.hghtPanelP);
            obj.widPanelS = obj.widPanelP - 2*obj.dX;                        
            obj.hghtPanelP = obj.hghtPanelF + obj.hghtPanelV + 3*obj.dX;            
            obj.widPanelC = obj.widPanelS - 2*obj.dX;
            obj.hghtPanelC = 2*obj.hghtBut + 2.5*obj.dX;
            obj.widButC = obj.widPanelC - 2*obj.dX;            
            obj.widButLV = (obj.widPanelS - 3*obj.dX)/2;
            
            % makes the main GUI invisible
            setObjVisibility(obj.hFigM,'off')
            
        end
           
        % initialises the class fields/objects
        function initClassObj(obj)
            
            % deletes any previous GUIs            
            hFigPrev = findall(0,'tag',obj.tagFigStr);
            if ~isempty(hFigPrev); delete(hFigPrev); end            
            
            % --------------------------- %
            % --- MAIN FIGURE OBJECTS --- %
            % --------------------------- %            
            
            % figure dimensions
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % creates the figure object
            obj.hFig = figure('Position',fPos,'tag',obj.tagFigStr,...
                              'MenuBar','None','Toolbar','None',...
                              'Name','Video Split GUI','Resize','off',...
                              'NumberTitle','off','Visible','off',...
                              'WindowButtonDownFcn',@obj.ButtonDownFcn,...
                              'WindowButtonUpFcn',@obj.ButtonUpFcn,...
                              'WindowKeyPressFcn',@obj.KeyPressFcn,...
                              'WindowKeyReleaseFcn',@obj.KeyReleaseFcn);                        
            
            % creates the experiment combining data panel
            pPosP = [obj.dX,obj.y0PanelP,obj.widPanelP,obj.hghtPanelP];
            obj.hPanelP = uipanel(obj.hFig,'Title','','Units',...
                                           'Pixels','Position',pPosP);
                                      
            % creates the experiment combining data panel
            lPosAx = sum(pPosP([1,3])) + obj.dX;
            pPosP = [lPosAx,obj.dX,obj.widPanelAx,obj.hghtPanelAx];
            obj.hPanelAx = uipanel(obj.hFig,'Title','','Units',...
                                            'Pixels','Position',pPosP);

            % ------------------------- %
            % --- MENU ITEM OBJECTS --- %
            % ------------------------- %                                        
                       
            % creates the parent menu item
            hMenuP = uimenu(obj.hFig,'Label','File');
            
            % creates the file menu items
            obj.hMenuX = uimenu(hMenuP,'Label','Close Window',...
                                       'Callback',@obj.menuExit);    
            
            % ----------------------------------- %
            % --- VIDEO GROUP PARAMETER PANEL --- %
            % ----------------------------------- % 
            
            % initialisations
            bStrLV = {'Set Lower','Set Upper'};
            eStrLV = {'Start: ','End: '};
            cbFcnBLV = {@obj.SetLowerLimit,@obj.SetUpperLimit};
            cbFcnELV = {@obj.EditGrpStart,@obj.EditGrpFinish};            
            
            % creates the panel object
            tStrV = 'VIDEO GROUP SELECTION'; 
            pPosV = [obj.dX*[1,1],obj.widPanelS,obj.hghtPanelV];
            obj.hPanelV = uipanel(obj.hPanelP,'Title',tStrV,'Units',...
                        'Pixels','Position',pPosV,'FontUnits','Pixels',...
                        'FontSize',obj.fSzH,'FontWeight','bold');
                    
            % sets up the bottom position of the button objects
            pPosC = [obj.dX*[1,1],obj.widPanelC,obj.hghtPanelC];
            yPosBLV = sum(pPosC([2,4])) + obj.dX/2;                        
            
            % createst the button object
            obj.hButLV = cell(length(bStrLV),1);            
            for i = 1:length(bStrLV)
                xPosLV = i*obj.dX + (i-1)*obj.widButLV;
                bPosLV = [xPosLV,yPosBLV,obj.widButLV,obj.hghtBut];
                obj.hButLV{i} = uicontrol(obj.hPanelV,'Style','Pushbutton',...
                        'Position',bPosLV,'Callback',cbFcnBLV{i},'FontUnits',...
                        'Pixels','FontSize',obj.fSzT,'FontWeight','Bold',...
                        'String',bStrLV{i});
            end
            
            % creates
            obj.hEditLV = cell(length(eStrLV),1);
            yPosELV = sum(bPosLV([2,4])) + obj.dX/2;
            for i = 1:length(eStrLV)
                % creates the text label object
                xtPosLV = obj.dX + (i-1)*(obj.widTxtLV + obj.widEditLV);
                tPosLV = [xtPosLV,yPosELV+2,obj.widTxtLV,obj.hghtTxt];
                uicontrol(obj.hPanelV,'Style','Text','Position',tPosLV,...
                        'FontUnits','Pixels','FontWeight','Bold',...
                        'FontSize',obj.fSzT,'String',eStrLV{i},...
                        'HorizontalAlignment','right');                
                
                % creates the editbox object
                pVal = '1';
                xePosLV = sum(tPosLV([1,3]));
                ePosLV = [xePosLV,yPosELV,obj.widEditLV,obj.hghtEdit];
                obj.hEditLV{i} = uicontrol(obj.hPanelV,'Style','Edit',...
                            'Position',ePosLV,'Callback',cbFcnELV{i},...
                            'String',pVal);                
            end
            
            % sets up the selection objects
            yPosSV = yPosELV + 3*obj.dX;
            [obj.hButSV,obj.hEditSV] = ...
                        obj.setupSelectionObj(obj.hPanelV,yPosSV,2);                    

            % sets up the text/label objects
            yPosTV = yPosSV + 3*obj.dX;
            tStrTV = {'Total Groups: ','Selected Groups: '};            
            obj.hTxtV = obj.setupTextLabels(obj.hPanelV,tStrTV,yPosTV);
            
            % ------------------------------------ %
            % --- CONTROL BUTTON PANEL OBJECTS --- %
            % ------------------------------------ %                     
                    
            % initialisations
            bStrC = {'Merge Selected Groups','Split Current Group'};
            cbFcnB = {@obj.buttonMerge,@obj.buttonSplit};
            obj.hButC = cell(length(bStrC),1);            
            
            % creates the experiment combining data panel            
            obj.hPanelC = uipanel(obj.hPanelV,'Title','','Units',...
                                              'Pixels','Position',pPosC);                    
                    
            % creates the button objects
            for i = 1:length(bStrC)
                yPos = obj.dX + (i-1)*(obj.hghtBut + obj.dX/2);
                bPosC = [obj.dX,yPos,obj.widButC,obj.hghtBut];
                obj.hButC{i} = uicontrol(obj.hPanelC,'Style','Pushbutton',...
                        'Position',bPosC,'Callback',cbFcnB{i},'FontUnits',...
                        'Pixels','FontSize',obj.fSzT,'FontWeight','Bold',...
                        'String',bStrC{i});
            end
            
            % disables the merge button
            setObjEnable(obj.hButC{1},'off')
                                          
            % ----------------------------------- %
            % --- VIDEO FRAME SELECTION PANEL --- %
            % ----------------------------------- % 
            
            % creates the panel object
            tStrF = 'VIDEO FRAME SELECTION'; 
            y0PosF = sum(pPosV([2,4])) + obj.dX;
            pPosF = [obj.dX,y0PosF,obj.widPanelS,obj.hghtPanelF];
            obj.hPanelF = uipanel(obj.hPanelP,'Title',tStrF,'Units',...
                        'Pixels','Position',pPosF,'FontUnits','Pixels',...
                        'FontSize',obj.fSzH,'FontWeight','bold');
            
            % sets up the selection objects
            [obj.hButSF,obj.hEditSF] = ...
                        obj.setupSelectionObj(obj.hPanelF,obj.dX,1);
                                 
            % sets up the text/label objects
            yPosTV = 4*obj.dX;
            tStrTV = {'Total Frames: '};            
            obj.hTxtF = obj.setupTextLabels(obj.hPanelF,tStrTV,yPosTV);
            
            % ---------------------------------------- %
            % --- VIDEO GROUP SELECTION AXES PANEL --- %
            % ---------------------------------------- % 
            
            % creates the experiment combining data panel
            pPosGrp = [obj.dX*[1,1],obj.widPanelAll,obj.hghtPanelGrp];
            obj.hPanelGrp = uipanel(obj.hPanelAx,'Title','','Units',...
                                         'Pixels','Position',pPosGrp);
            
            % creates the axes object
            obj.hAxGrp = axes();
            pPosAxGrp = [obj.dX*[1,1],obj.widAxAll,obj.hghtAxGrp];
            set(obj.hAxGrp,'parent',obj.hPanelGrp,'tag','axesGroup',...
                    'units','pixels','position',pPosAxGrp,'box','on',...
                    'xticklabel',[],'xtick',[],'yticklabel',[],'ytick',[]);             
            
            % ------------------------------ %
            % --- VIDEO IMAGE AXES PANEL --- %
            % ------------------------------ % 
            
            % creates the experiment combining data panel
            y0Img = sum(pPosGrp([2,4])) + obj.dX;
            pPosImg = [obj.dX,y0Img,obj.widPanelAll,obj.hghtPanelImg];
            obj.hPanelImg = uipanel(obj.hPanelAx,'Title','','Units',...
                                             'Pixels','Position',pPosImg);
            
            % creates the axes object
            obj.hAxImg = axes();
            pPosAxImg = [obj.dX*[1,1],obj.widAxAll,obj.hghtAxImg];
            set(obj.hAxImg,'parent',obj.hPanelImg,'tag','axesImg',...
                    'units','pixels','position',pPosAxImg,'box','on',...
                    'xticklabel',[],'xtick',[],'yticklabel',[],'ytick',[]);                                         
            
        end        
        
        % initialises the class fields/objects
        function initObjProps(obj)
            
            % field retrieval
            hAxG = obj.hAxGrp;
            [vG,nFrmS] = deal(obj.iData.vGrp,num2str(obj.iData.nFrm));            
            
            % initialises the edit box values
            set(obj.hEditSV,'string','1');
            set(obj.hTxtF{1},'string',nFrmS);
            set(obj.hEditSF,'string',num2str(vG(1,1)));
            set(obj.hEditLV{1},'string',num2str(vG(1,1)));
            set(obj.hEditLV{2},'string',num2str(vG(1,2)));  
            
            % updates the selection properties
            obj.updateSelectionEnable(1, [vG(1,1), obj.iData.nFrm])
            obj.updateSelectionEnable(2, [1, size(vG,1)])
            
            % updates the image axes
            ImgNw = obj.updateImageAxes();
            pPos = get(obj.hPanelImg,'position');
            Wnw = roundP(pPos(4)*size(ImgNw,2)/size(ImgNw,1));
            dW = Wnw-pPos(3);
            
            % resets the dimensiongs of the axes objects
            resetObjPos(obj.hAxImg,'width',dW,1);
            resetObjPos(obj.hPanelImg,'width',dW,1);
            resetObjPos(hAxG,'width',dW,1);
            resetObjPos(obj.hPanelGrp,'width',dW,1);
            resetObjPos(obj.hPanelAx,'width',dW,1);
            resetObjPos(obj.hFig,'width',dW,1);
            
            % sets up the video group axes
            cla(hAxG)
            set(hAxG,'xlim',[1 obj.iData.nFrm] + 0.5*[-1 1],'yLim',[0 1]);
            
            % initialises the frame/video group marker objects
            obj.initFrameMarker();
            obj.initGroupMarkers();
            
            % removes any previous timer object
            hTimerPr = timerfind('tag','hTimerF');
            if ~isempty(hTimerPr)
                arrayfun(@(x)(stop(x)),hTimerPr)
                delete(hTimerPr); 
            end
            
            % creates and starts the frame timer function
            timerCB = @obj.FrameTimerFcn;
            obj.hTimer = timer('StartDelay',0.5, 'TimerFcn',timerCB,...
                               'Period', 0.01, 'tag', 'hTimerF', ...
                               'ExecutionMode', 'fixedrate');
            start(obj.hTimer);
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % updates the GUI object properties
            setGUIFontSize(obj)
            centreFigPosition(obj.hFig);            
            
            % makes the gui visible            
            setObjVisibility(obj.hFig,'on')
            uiwait(obj.hFig);
            
        end                       

        % ------------------------------ %
        % --- FRAME MARKER FUNCTIONS --- %
        % ------------------------------ % 
        
        % --- initialises the frame marker
        function initFrameMarker(obj)

            % axis initialisations
            hAxG = obj.hAxGrp;
            hold(hAxG,'on')

            % creates the line object
            lCol = 'g';
            xL = [1 obj.iData.nFrm];
            pL = {obj.iData.vGrp(1,1)*[1 1],[0 1]};

            % creates the line object
            obj.hLine = InteractObj('line',hAxG,pL);
            obj.hLine.setFields('tag','hLine','UserData',0);

            % updates the marker properties/callback function
            obj.hLine.setColour(lCol);
            obj.hLine.setObjMoveCallback(@obj.frmMove); 
            obj.hLine.setConstraintRegion(xL,[0 1]);    

            if obj.hLine.isOld
%                 set(findall(hRect,'tag','patch'),'facealpha',obj.fAlphaOff)
            else
                obj.hLine.setFields('InteractionsAllowed','translate')
            end            
            
        end
        
        % --- frame marker line callback function
        function frmMove(obj,varargin)
            
            % global variables
            [obj.tMove,obj.updateFrm] = deal(tic,true);

            % exits the function if ignoring
            if obj.ignoreMove; return; end

            % retrieves the position vector
            switch length(varargin)
                case 1
                    pPos = varargin{1};
                    
                case 2
                    pPos = varargin{2}.CurrentPosition;
            end
            
            % updates the time object
            iFrm = obj.hLine.getFieldVal('UserData') + 1;
            obj.hLine.setFields('UserData',iFrm)
            cFrm = roundP(pPos(1,1));

            % updates the frame index
            set(obj.hEditSF,'string',num2str(cFrm));            
            
        end
        
        % ------------------------------ %
        % --- GROUP MARKER FUNCTIONS --- %
        % ------------------------------ %
        
        % --- initialises the markers for each video index group
        function initGroupMarkers(obj)

            % creates the group markers for each region
            nGrp = size(obj.iData.vGrp,1);
            for i = 1:nGrp
                hRect = obj.createGroupMarker(i,obj.iData.vGrp(i,:),true);
                if i == 1
                    if isOldIntObjVer
                        hRectP = findall(hRect,'tag','patch');
                        set(hRectP,'FaceAlpha',obj.fAlphaOn);                        
                    else
                        hRect.setFields('FaceAlpha',obj.fAlphaOn);
                    end
                end
            end

            % resets the groups markers into the correct order
            hAxG = obj.hAxGrp;
            set(hAxG, 'Children',flipud(get(hAxG, 'Children')))
            set(obj.hTxtV{2},'string','1')
            set(obj.hTxtV{1},'string',num2str(nGrp))

        end
        
        % --- creates the group marker for the group index, cGrp
        function hRect = createGroupMarker(obj,cGrp,fLim,isInit)

            % initialisations
            grpCol = distinguishable_colors(size(obj.iData.vGrp,1));

            % axis initialisations
            hAxG = obj.hAxGrp;
            hold(hAxG,'on')            
            
            % creates the rectangle object
            hRect = InteractObj('rect',hAxG,[fLim(1) 0 fLim(2)-fLim(1) 1]);
            
            % if moveable, then set the position callback function
            hRect.setColour(grpCol(cGrp,:));
            hRect.setFields('tag','hGrp','UserData',cGrp);
            hRect.setObjMoveCallback(@obj.grpMove);
            
            if hRect.isOld
                set(findall(hRect,'tag','patch'),'facealpha',obj.fAlphaOff)
            else
                hRect.setFields('FaceAlpha',obj.fAlphaOff);
                hRect.setFields('InteractionsAllowed','none')
            end
                
            % removes the hold on the axes
            hold(hAxG,'on')

            % resets the order of the objects (frame marker on top then groups)
            if ~isInit
                hGrpT = findall(hAxG, 'tag', 'hGrp');
                hLineT = findall(hAxG, 'tag', 'hLine');
                set(hAxG, 'Children', [hLineT;flipud(hGrpT)])
            end

        end

        % --- frame marker line callback function
        function grpMove(obj,varargin)
            
            % global variables
            [obj.updateGrp,obj.tMove,obj.isChange] = deal(true,NaN,true);

            % exits the function if ignoring
            if obj.ignoreMove; return; end

            % retrieves the currently selected group object
            switch length(varargin)
                case 1
                    % case is the older format objects
                    cGrp = get(get(gco,'parent'),'UserData');

                case 2
                    % case is the newer format objects
                    cGrp = varargin{1}.UserData;
            end

            % ensures the correct group has been selected
            cGrpPr = str2double(get(obj.hEditSF,'string'));
            if cGrpPr ~= cGrp
                obj.switchSelectedGroup(cGrp,cGrpPr)
            end

            % updates the limits on the screen
            fLim = roundP(pPos(1)+[0 pPos(3)])-[0 1];

            % updates the limits
            obj.iData.vGrp(cGrp,:) = fLim;
            if size(obj.iData.vGrp,1) > 1
                % sets the default frame limit vector
                nwLim = [1 obj.iData.nFrm];

                % sets the new lower/upper limits of the adjacent groups
                if cGrp > 1                    
                    nwLim(1) = obj.iData.vGrp(cGrp-1,2)+1;
                end

                % sets the new lower/upper limits of the adjacent groups
                if cGrp < size(obj.iData.vGrp,1)
                    nwLim(2) = obj.iData.vGrp(cGrp+1,1)-1;
                end

                %
                if (fLim(1) < nwLim(1)) || (fLim(2) > nwLim(2))
                    fLim = [max(fLim(1),nwLim(1)),min(fLim(2),nwLim(2))];
                    obj.iData.vGrp(cGrp,:) = ...
                        [max(obj.iData.vGrp(cGrp,1),nwLim(1)),...
                         min(obj.iData.vGrp(cGrp,2),nwLim(2))];
                    obj.resetGroupPosition(hRect,fLim)
                end
            end

            % resets the video group object properties
            set(obj.hEditLV{1},'string',num2str(fLim(1)))
            set(obj.hEditLV{2},'string',num2str(fLim(2)))
            setObjEnable(obj.hButC{2},diff(fLim)>50)            
            
        end
        
        % --- switches the selected groups from cGrpC to cGrp
        function switchSelectedGroup(obj,cGrp,cGrpC)

            % updates and initialisations            
            hAxG = obj.hAxGrp;
            vG = obj.iData.vGrp;
            obj.iData.cGrp = cGrp;            

            % if not, then update the group selection index
            set(obj.hEditSV,'string',num2str(cGrp))
            obj.updateSelectionEnable(2, [cGrp, size(vG,1)])

            % updates the patch colours
            obj.updatePatchFaceAlpha(cGrpC, obj.fAlphaOff);
            hPOn = obj.updatePatchFaceAlpha(cGrp, obj.fAlphaOn);

            % updates the start/finish frames for the new group
            set(obj.hEditLV{1},'string',num2str(vG(cGrp,1)))
            set(obj.hEditLV{2},'string',num2str(vG(cGrp,2)))

            % resets the order of the plot objects
            hP = findall(hAxG, 'tag', 'hGrp');
            hPOther = hP(hP ~= hPOn);
            hLineT = findall(hAxG, 'tag', 'hLine');
            set(hAxG, 'Children', [hLineT;hPOn;flipud(hPOther)])

        end
        
        % --- updates the face alpha for a given group patch object
        function hP = updatePatchFaceAlpha(obj, cGrp, fAlpha)

            hP = findall(obj.hAxGrp,'tag','hGrp','UserData',cGrp);
            
            if obj.isOld
                set(findall(hP,'tag','patch'),'facealpha',fAlpha);   
            else
                set(hP,'facealpha',fAlpha);   
            end

        end
        
        % --- resets the position of the video group object
        function resetGroupPosition(obj,hRect,fLim)

            % resets the position of the group rectangle 
            obj.ignoreMove = true;
            setIntObjPos(hRect,[fLim(1) 0 diff(fLim) 1]);
            obj.ignoreMove = false;

            % resets the group start/finish frame indices
            set(obj.hEditLV{1},'string',num2str(fLim(1)))
            set(obj.hEditLV{2},'string',num2str(fLim(2)))

        end
        
        % ------------------------------------------ %
        % --- SPLIT/MERGE GROUP MARKER FUNCTIONS --- %
        % ------------------------------------------ %        
        
        % --- splits the group markers
        function splitGroupMarkers(obj)
            
            % initialisations            
            hAxG = obj.hAxGrp;
            vG = obj.iData.vGrp;
            obj.isChange = true;            
            cGrp = str2double(get(obj.hEditSV,'string'));

            % updates the other group properties
            hGrp = findall(hAxG,'tag','hGrp');
            hGrpS = findall(hGrp,'UserData',cGrp);
            obj.resetOtherGroupProps(hGrp,cGrp,1);

            % recalculates the new limits
            fPos = getIntObjPos(hGrpS);
            fLim = roundP(fPos(1)+[0 fPos(3)]);
            vGrpNw = fLim(1) + [0 floor(fPos(3)/2)];
            vGrpNw = [vGrpNw;[(vGrpNw(1,2)+1) fLim(2)]];

            % updates the video group index array            
            obj.iData.vGrp = [vG(1:(cGrp-1),:);vGrpNw;vG((cGrp+1):end,:)];

            % resets the upper limit values
            set(obj.hEditLV{2},'string',num2str(vGrpNw(1,2)))

            % resets the position of the first group, and creates another
            obj.resetGroupPosition(hGrpS,vGrpNw(1,:));
            obj.createGroupMarker(cGrp+1,vGrpNw(2,:),false);
            obj.updateSelectionEnable(2,[cGrp(1),size(obj.iData.vGrp,1)])

            % updates the group selection/count
            nGrpS = num2str(size(obj.iData.vGrp,1));
            set(obj.hTxtV{1},'string',nGrpS)
            set(obj.hTxtV{2},'string','1')            
            
        end
        
        % --- merges the group markers given by the array, hPM
        function mergeGroupMarkers(obj,hMerge)
            
            % initialisations
            hAxG = obj.hAxGrp;
            obj.isChange = true;            

            % determines the groups which are currently selected
            cGrp = arrayfun(@(x)(get(x,'UserData')),hMerge);
            [cGrp,iSort] = sort(cGrp);
            hMerge = hMerge(iSort);

            % removes the merged groups
            isOK = true(size(obj.iData.vGrp,1),1);
            isOK(cGrp(2:end)) = false;
            
            % merges the group indices
            obj.iData.cGrp = cGrp(1);
            obj.iData.vGrp(cGrp(1),2) = obj.iData.vGrp(cGrp(end),2);
            [obj.iData.vGrp,vG] = deal(obj.iData.vGrp(isOK,:));

            % resets the position of the merged group and deletes the others
            obj.resetGroupPosition(hMerge(1),obj.iData.vGrp(cGrp(1),:));
            obj.updatePatchFaceAlpha(cGrp(1), obj.fAlphaOn);
            for i = 2:length(hMerge); delete(hMerge(i)); end

            % resets the other GUI object properties
            set(obj.hEditLV{1},'string',num2str(vG(cGrp(1),1)))
            set(obj.hEditLV{2},'string',num2str(vG(cGrp(1),2)))
            set(obj.hEditSV,'string',num2str(cGrp(1)))
            set(obj.hTxtV{1},'string',num2str(size(vG,1)))
            set(obj.hTxtV{2},'string','1')
            setObjEnable(obj.hButC{2},diff(vG(cGrp(1),:))>50)
            
            % updates the properties of the other groups and the selection buttons
            hGrp = findall(hAxG,'tag','hGrp');
            obj.resetOtherGroupProps(hGrp,cGrp(end),-diff(cGrp([1 end])))
            obj.updateSelectionEnable(2,[cGrp(1),size(vG,1)])            
            
        end
        
        % ------------------------------------ %
        % --- CLASS OBJECT SETUP FUNCTIONS --- %
        % ------------------------------------ %        
        
        % --- sets up the text labels fields
        function hTxt = setupTextLabels(obj,hP,tStr,y0)
            
            % memory allocation
            hTxt = cell(length(tStr),1);
            
            %
            for i = 1:length(tStr)
                % creates the text label
                tPosL = [obj.dX/2,y0+2*(i-1)*obj.dX,obj.widTxtL,obj.hghtTxt];
                uicontrol(hP,'Style','Text','Position',tPosL,...
                        'FontUnits','Pixels','FontWeight','Bold',...
                        'FontSize',obj.fSzT,'String',tStr{i},...
                        'HorizontalAlignment','right');                
                
                % creates the text information object
                tPos = [sum(tPosL([1,3])),tPosL(2),obj.widTxt,obj.hghtTxt];
                hTxt{i} = uicontrol(hP,'Style','Text','Position',tPos,...
                        'FontUnits','Pixels','FontWeight','Bold',...
                        'FontSize',obj.fSzT,'HorizontalAlignment','left');
            end
            
        end
        
        % --- sets up the frame/video group selection objects
        function [hBut,hEdit] = setupSelectionObj(obj,hP,y0,sType)
            
            % initialiations
            hBut = cell(4,1);
            
            % object callback functions
            cbFcnE = @obj.CountEdit;            
            cbFcnB = {@obj.FirstButton,@obj.PrevButton,...
                      @obj.NextButton,@obj.LastButton};
            
            % sets the type specific properties
            switch sType
                case 1
                    % case is the video group selection
                    uStr = 'Frame';
                    
                case 2
                    % case is the video frame selection                    
                    uStr = 'Group';
                         
            end
            
            % other initialisations            
            for i = 1:length(hBut)                
                % creates the button object
                lBut = obj.dX + (i-1)*obj.hghtBut + ...
                                            (i>2)*(obj.widEditS + obj.dX);
                bPos = [lBut,y0,obj.hghtBut*[1,1]];                
                hBut{i} = uicontrol(hP,'Style','Pushbutton',...
                            'Position',bPos,'Callback',cbFcnB{i},...
                            'FontUnits','Pixels','FontSize',obj.fSzT,...
                            'FontWeight','Bold','String',obj.bStr{i},...
                            'UserData',uStr,'tag','hButS');                
            end            
            
            % creates the count editbox object
            lEdit = (3/2)*obj.dX + 2*obj.hghtBut;
            ePos = [lEdit,y0+2,obj.widEditS,obj.hghtEdit];
            hEdit = uicontrol(hP,'Style','Edit',...
                        'Position',ePos,'Callback',cbFcnE,...
                        'UserData',uStr,'FontUnits','Pixels',...
                        'FontSize',obj.fSzT);
            
        end

        % -------------------------------------- %
        % --- FRAME TIMER CALLBACK FUNCTIONS --- %
        % -------------------------------------- %        
        
        % --- frame timer callback function
        function FrameTimerFcn(obj,varargin)
            
            % if updating (and sufficient time has passed) then update the 
            % image axes and check the group selection feasibility
            if obj.updateFrm
                if toc(obj.tMove) > obj.tP
                    obj.updateImageAxes();
                    obj.updateFrm = false;
                end
            elseif obj.updateGrp
                if ~isnan(obj.tMove)
                    if toc(obj.tMove) > obj.tP
                        obj.checkGroupFeas()
                        obj.updateGrp = false;
                    end    
                end
            end
            
        end
        
        % --- checks the video group feasibility
        function checkGroupFeas(obj)
            
            % initialisations
            hAxG = obj.hAxGrp;
            cGrp = str2double(get(obj.hEditSV,'string'));

            % retrieves the data structs from the GUI
            nwLim = obj.getGroupDomain(cGrp);

            % determines the current location of the limits
            hRect = findall(hAxG,'tag','hGrp','UserData',cGrp);
            fPos = getIntObjPos(hRect);
            fLim = roundP(fPos(1) + [0 fPos(3)])-[0 1];

            % updates the group position (if outside of limits
            if fLim(1) < nwLim(1) 
                fLim(1) = nwLim(1); 
                obj.resetGroupPosition(hRect,fLim)    
            elseif fLim(2) > nwLim(2)
                fLim(2) = nwLim(2); 
                obj.resetGroupPosition(hRect,fLim)
            end            
            
        end
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %        
        
        % --- first frame/group button selection callback function
        function FirstButton(obj,hObj,~)
            
            % retrieves the image data struct
            vG = obj.iData.vGrp;
            isGrp = strcmp(get(hObj,'UserData'),'Group');

            % updates the selection enabled properties
            hObj = {obj.hEditSF,obj.hEditSV};
            valLim = [obj.iData.nFrm,size(vG,1)];

            % updates the selection properties
            j = 1 + isGrp;
            set(hObj{j},'string','1')
            obj.updateSelectionEnable(j,[1,valLim(j)])

            % updates the appropriate axes (based on the type)
            if isGrp
                % updates the video group selection axes
                obj.switchSelectedGroup(1,obj.iData.cGrp)
                obj.iData.cGrp = 1;
            else
                % updates the image axes
                obj.iData.cFrm = 1;
                obj.updateFrameMarkerPos()
                obj.updateImageAxes();
            end
            
        end
        
        % --- previous frame/group button selection callback function
        function PrevButton(obj,hObj,~)

            % retrieves the image data struct
            vG = obj.iData.vGrp;
            isGrp = strcmp(get(hObj,'UserData'),'Group');

            % updates the selection enabled properties
            hObj = {obj.hEditSF,obj.hEditSV};
            valLim = [obj.iData.nFrm,size(vG,1)];

            % updates the corresponding editbox value
            j = 1 + isGrp;
            currVal = str2double(get(hObj{1+isGrp},'string'));
            set(hObj{1+isGrp},'string',num2str(currVal-1))
            obj.updateSelectionEnable(j, [currVal-1, valLim(j)])

            % updates the appropriate axes (based on the type)
            if isGrp
                % updates the video group selection axes
                obj.switchSelectedGroup(obj.iData.cGrp-1,obj.iData.cGrp)
                obj.iData.cGrp = obj.iData.cGrp - 1;
            else
                % updates the image axes
                obj.iData.cFrm = obj.iData.cFrm - 1;
                obj.updateFrameMarkerPos()
                obj.updateImageAxes();
            end           
            
        end
        
        % --- next frame/group button selection callback function
        function NextButton(obj,hObj,~)
            
            % retrieves the image data struct
            isGrp = strcmp(get(hObj,'UserData'),'Group');

            % updates the selection enabled properties
            vG = obj.iData.vGrp;
            hObj = {obj.hEditSF,obj.hEditSV};
            valLim = [obj.iData.nFrm,size(vG,1)];

            % updates the corresponding editbox value
            j = 1 + isGrp;
            currVal = str2double(get(hObj{j},'string'));
            set(hObj{j},'string',num2str(currVal+1))
            obj.updateSelectionEnable(j, [currVal+1, valLim(j)])

            % updates the appropriate axes (based on the type)
            if isGrp
                % updates the video group selection axes
                obj.switchSelectedGroup(obj.iData.cGrp+1,obj.iData.cGrp)
                obj.iData.cGrp = obj.iData.cGrp + 1;
            else
                % updates the image axes
                obj.iData.cFrm = obj.iData.cFrm + 1;
                obj.updateFrameMarkerPos()
                obj.updateImageAxes();
            end      
            
        end
        
        % --- last frame/group button selection callback function
        function LastButton(obj,hObj,~)

            % retrieves the image data struct
            vG = obj.iData.vGrp;
            isGrp = strcmp(get(hObj,'UserData'),'Group');

            % updates the selection enabled properties
            hObj = {obj.hEditSF,obj.hEditSV};
            valLim = [obj.iData.nFrm,size(vG,1)];

            % updates the selection properties
            j = 1+isGrp;
            set(hObj{j},'string',num2str(valLim(j)))
            obj.updateSelectionEnable(j, [valLim(j), valLim(j)])

            % updates the appropriate axes (based on the type)
            if isGrp
                % updates the video group selection axes
                obj.switchSelectedGroup(size(vG,1),obj.iData.cGrp)
                obj.iData.cGrp = size(vG,1);    
            else
                % updates the image axes
                obj.iData.cFrm = obj.iData.nFrm;
                obj.updateFrameMarkerPos()
                obj.updateImageAxes();
            end        
            
        end
        
        % --- frame/group index editbox callback function
        function CountEdit(obj,hObj,~)
            
            % retrieves the image data struct
            nwVal = str2double(get(hObj,'string'));
            isGrp = strcmp(get(hObj,'UserData'),'Group');
            
            % updates the frame/sub-movie index
            if isGrp
                nwLim = [1 size(obj.iData.vGrp,1)];
                [cGrp0,pStr] = deal(obj.iData.cGrp,'cGrp');                
            else
                [nwLim,pStr] = deal([1 obj.iData.nFrm],'cFrm');
            end

            % checks to see if the new value is valid
            if chkEditValue(nwVal,nwLim,1)
                % if so, then updates the counter and the image frame
                obj.iData = setStructField(obj.iData,pStr,nwVal);

                % updates the selection enabled properties
                obj.updateSelectionEnable(1+isGrp, [nwVal, nwLim(2)])
                if isGrp
                    % updates the video group selection axes
                    obj.switchSelectedGroup(nwVal,cGrp0)
                else
                    % updates the image axes
                    obj.updateFrameMarkerPos()
                    obj.updateImageAxes();
                end
            else
                % resets the edit box string to the last valid value
                pStr0 = num2str(getStructField(obj.iData,pStr));
                set(hObj,'string',pStr0)
            end

        end                    
        
        % ------------------------------------------ %
        % --- VIDEO GROUP FRAME OBJECT CALLBACKS --- %
        % ------------------------------------------ %        
        
        % --- set group lower limit frame button callback function
        function SetLowerLimit(obj,~,~)
            
            % initialisations
            eStr = [];
            cGrp = str2double(get(obj.hEditSV,'string'));
            cFrm = str2double(get(obj.hEditSF,'string'));

            % determines if the upper limit is valid
            if cFrm >= obj.iData.vGrp(cGrp,2)
                % if not, then exit after displaying an error
                eStr = 'Error! Lower limit can''t be more than or equal to lower limit.';
            else
                nwLim = obj.getGroupDomain(cGrp);
                if cFrm < nwLim(1)
                    eStr = 'Error! Lower limit can''t overlap another group.';
                end
            end

            % if there was an error, output the message and exit the function
            if ~isempty(eStr)
                waitfor(errordlg(eStr,'Invalid Lower Limit','modal'))
                return 
            end

            % updates the data struct
            [obj.iData.vGrp(cGrp,1),obj.isChange] = deal(cFrm,true);
            set(obj.hEditLV{1},'string',num2str(cFrm))

            % updates the group position
            hRect = findall(obj.hAxGrp,'tag','hGrp','UserData',cGrp);
            obj.resetGroupPosition(hRect,obj.iData.vGrp(cGrp,:))            
            
        end
        
        % --- set group upper limit frame button callback function
        function SetUpperLimit(obj,~,~)
            
            % initialisations
            eStr = [];
            cGrp = str2double(get(obj.hEditSV,'string'));
            cFrm = str2double(get(obj.hEditSF,'string'));

            % determines if the upper limit is valid
            if cFrm <= obj.iData.vGrp(cGrp,1)
                eStr = 'Error! Upper limit can''t be less than or equal to lower limit.';
            else
                nwLim = obj.getGroupDomain(cGrp);
                if cFrm > nwLim(2)
                    eStr = 'Error! Upper limit can''t overlap another group.';
                end
            end

            % if there was an error, output the message and exit the function
            if ~isempty(eStr)
                waitfor(errordlg(eStr,'Invalid Upper Limit','modal'))
                return 
            end

            % updates the data struct
            [obj.iData.vGrp(cGrp,2),obj.isChange] = deal(cFrm,true);
            set(obj.hEditLV{2},'string',num2str(cFrm))

            % updates the group position
            hRect = findall(obj.hAxGrp,'tag','hGrp','UserData',cGrp);
            obj.resetGroupPosition(hRect,obj.iData.vGrp(cGrp,:))            
            
        end
        
        % --- executes on updating the start frame index editbox
        function EditGrpStart(obj,hObj,~)
            
            % initialisations
            nwVal = str2double(get(hObj,'string'));
            cGrp = str2double(get(obj.hEditSV,'string'));            

            % checks to see if the new value is valid
            nwLim = obj.getGroupLimits(cGrp,true);
            if chkEditValue(nwVal,nwLim,1)
                % if so, then update the data struct
                obj.isChange = true;
                obj.iData.vGrp(cGrp,1) = nwVal;

                % resets the position of the group
                hRect = findall(obj.hAxGrp,'tag','hGrp','UserData',cGrp);
                obj.resetGroupPosition(hRect,obj.iData.vGrp(cGrp,:))
            else
                % if not, then revert the last value
                set(hObj,'string',num2str(obj.iData.vGrp(cGrp,1)))
            end            
            
        end
        
        % --- executes on updating the finish frame index editbox
        function EditGrpFinish(obj,hObj,~)
            
            % initialisations
            nwVal = str2double(get(hObj,'string'));
            cGrp = str2double(get(obj.hEditSV,'string'));
            nwLim = obj.getGroupLimits(cGrp,false);

            % checks to see if the new value is valid
            if chkEditValue(nwVal,nwLim,1)
                % if so, then update the data struct
                obj.isChange = true;
                obj.iData.vGrp(cGrp,2) = nwVal;

                % resets the position of the group
                hRect = findall(obj.hAxGrp,'tag','hGrp','UserData',cGrp);
                obj.resetGroupPosition(hRect,obj.iData.vGrp(cGrp,:))
            else
                % if not, then revert the last value
                set(hObj,'string',num2str(obj.iData.vGrp(cGrp,2)))
            end            
            
        end        
        
        % ------------------------------------------- %
        % --- VIDEO GROUP ACTION OBJECT CALLBACKS --- %
        % ------------------------------------------- %        
        
        % --- split group button callback function
        function buttonSplit(obj,~,~)
            
            % prompts the user if they want to split the current group
            tStr = 'Split Current Video Group?';
            qStr = 'Are you sure you want to split the current group?';
            uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
            if strcmp(uChoice,'Yes')
                % is so, then split the group into 2
                obj.splitGroupMarkers()
            end            
            
        end
        
        % --- merge group button callback function
        function buttonMerge(obj,hObj,~)
            
            % determines the currently selected groups
            hP = findall(obj.hAxGrp,'tag','hGrp');
            isOn = obj.getFaceAlpha(hP) == obj.fAlphaOn;
                        
            % if there are no matches, then exit
            if ~any(isOn); return; end            
            
            % determines if the group selection is feasible for merging
            indOn = arrayfun(@(x)(get(x,'UserData')),hP(isOn));            
            if any(diff(sort(indOn)) > 1)
                % if the selected blocks are not contiguous then output an error
                eStr = 'Error! Only contiguously selected groups blocks can be merged.';
                waitfor(errordlg(eStr,'Group Block Merge Error','modal'))
            else
                % otherwise, prompt the user if they want to merge 
                tStr = 'Merge Selected Video Groups?';                
                qStr = 'Are you sure you want to merge the selected groups?';
                uChoice = questdlg(qStr,tStr,'Yes','No','Yes');    
                if strcmp(uChoice,'Yes')
                    % is so, then merges the selected groups
                    obj.mergeGroupMarkers(hP(isOn))
                    setObjEnable(hObj,'off')
                end
            end            
            
        end          
        
        % --- updates the position of the frame marker
        function updateFrameMarkerPos(obj)

            % initialisations
            cFrm = str2double(get(obj.hEditSF,'string'));

            % resets the 
            obj.ignoreMove = true;
            hLineM = findall(obj.hAxGrp,'tag','hLine');
            setIntObjPos(hLineM,[cFrm 0;cFrm 1])
            obj.ignoreMove = false;

        end
        
        % --------------------------- %
        % --- MENU ITEM CALLBACKS --- %
        % --------------------------- %                
        
        % --- closes GUI menu item callback function
        function menuExit(obj,~,~)
           
            % determines if there were any changes made to the video 
            % split parameters
            if obj.isChange
                % if so, prompt the user if they wish to update the changes
                tStr = 'Update Video Split Properties';
                qStr = 'Do you wish to update the video split properties?';
                uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
                if isempty(uChoice)
                    % user cancelled so exit the function
                    return
                elseif strcmp(uChoice,'Yes')
                    % user decided to keep the changes
                    obj.vGrp = obj.iData.vGrp;
                else
                    % user decided not to keep changes
                    [obj.vGrp,obj.isChange] = deal([],false);
                end
            else
                % if no change, then return an empty array
                obj.vGrp = [];
            end            
            
            % stop and deletes the timer object
            try
                stop(obj.hTimer)
                delete(obj.hTimer)
            end
            
            % if change is flagged, then update the video group info
            if obj.isChange
                obj.hFigM.iMov.vGrp = obj.vGrp;
            end
            
            % deletes the main figure
            delete(obj.hFig)
            setObjVisibility(obj.hFigM,'on')
            
        end
        
        % --------------------------------------------- %
        % --- FIGURE INTERACTION CALLBACK FUNCTIONS --- %
        % --------------------------------------------- %        
        
        % --- executes on the mouse-button down click 
        function ButtonDownFcn(obj,hObj,~)
            
            % if the mouse pointer is not correct, then exit
            if ~strcmp(get(hObj,'Pointer'),'arrow')
                return
            end            
        
            % initialisations
            hAxG = obj.hAxGrp;
            vG = obj.iData.vGrp;
            mPos = get(hAxG,'currentpoint');
            
            % retrieves the current point and group limits
            axP = [roundP(mPos(1,1)), mPos(1,2)];
            xL = [vG(1,1),vG(end,2)];
            
            % if the selected point is not within the limits 
            % of groups then exit
            isIn = (axP(2)>=0) && (axP(2)<=1) && ...
                   (axP(1)>xL(1)) && (axP(1)<=xL(2));
            if ~isIn; return; end
            
            % if a new group is selected then switch the selected groups
            cGrp = find((axP(1) >= vG(:,1)) & (axP(1) <= vG(:,2)));
            if ~isempty(cGrp)            
                if obj.pressCtrl
                    % 
                    dfAlpha = 1;
                    hP = findall(hAxG,'tag','hGrp');
                    hPG = findall(hP,'UserData',cGrp);

                    %
                    fAlpha = obj.getFaceAlpha(hP(hP~=hPG));
                    fOtherOn = fAlpha == obj.fAlphaOn;
                    
                    % updates the selection groups facealpha values
                    if obj.getFaceAlpha(hPG) == obj.fAlphaOn 
                        % if the group is selected, then de-select 
                        if any(fOtherOn)
                            dfAlpha = 0;
                            obj.updatePatchFaceAlpha(cGrp,obj.fAlphaOff);
                        end
                    else
                        % if the group is de-selected, then re-select 
                        obj.updatePatchFaceAlpha(cGrp,obj.fAlphaOn);
                    end

                    % updates the object properties
                    canMerge = (sum(fOtherOn)+dfAlpha)>1;
                    nGrpS = num2str(sum(fOtherOn)+dfAlpha);
                    setObjEnable(obj.hButC{2},~canMerge)
                    setObjEnable(obj.hButC{1},canMerge)                    
                    set(obj.hTxtV{2},'string',nGrpS)
                    
                else
                    %
                    setObjEnable(obj.hButC{2},'on')
                    setObjEnable(obj.hButC{1},'off')
                    set(obj.hTxtV{2},'string','1')

                    % removes the selection for the other groups
                    fOff = obj.fAlphaOff;
                    indOff = find((1:size(vG,1)) ~= cGrp);
                    arrayfun(@(x)(obj.updatePatchFaceAlpha(x,fOff)),indOff,'un',0);

                    cGrpC = str2double(get(obj.hEditSV,'string'));
                    if cGrpC ~= cGrp
                        obj.switchSelectedGroup(cGrp,cGrpC)
                    end
                end                
            end
            
        end        
            
        % --- executes on the mouse-button up events
        function ButtonUpFcn(obj,~,~)
            
            if obj.updateGrp
                obj.tMove = tic;
            end
            
        end                
        
        % --- figure key press callback function
        function KeyPressFcn(obj,~,evnt)
            
            % flag whether control is currently being pressed
            obj.pressCtrl = strcmp(evnt.Key,'control');
            
        end
        
        % --- figure key relese callback function
        function KeyReleaseFcn(obj,~,~)
            
            % flag that control has been released
            obj.pressCtrl = false;
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %                
        
        % --- updates the main display image
        function ImgNw = updateImageAxes(obj)

            % initialisations
            hAx = obj.hAxImg;
            cFrm = str2double(get(obj.hEditSF,'string'));
            hMainG = guidata(obj.hFigM);

            % retrieves the new image
            ImgNw = getDispImage(obj.iDataM,obj.iMov,cFrm,false,hMainG);

            % updates the image axes with the new image            
            if isempty(obj.hImg)
                % if there is no image object, then create a new one
                imagesc(uint8(ImgNw),'parent',hAx);    
                set(hAx,'xtick',[],'ytick',[],'xticklabel',[],'yticklabel',[]);
                set(hAx,'ycolor','w','xcolor','w','box','off')           
                colormap(hAx,gray)
                axis(hAx,'image')

                % updates the foreground colour
                if isempty(ImgNw)
                    set(obj.hEditSF,'ForegroundColor','r')
                else
                    set(obj.hEditSF,'ForegroundColor','k')
                end    
                
                % retrieves the image object
                obj.hImg = findobj(hAx,'type','image');
                
            else
                % updates the axes image
                if max(get(hAx,'clim')) < 10
                    set(obj.hImg,'cData',double(ImgNw))    
                else
                    set(obj.hImg,'cData',uint8(ImgNw))    
                end

                % otherwise, update the image object with the new image    
                if isempty(ImgNw)
                    set(obj.hEditSF,'ForegroundColor','r')        
                else        
                    axis(hAx,[1 size(ImgNw,2) 1 size(ImgNw,1)]); 
                    set(obj.hEditSF,'ForegroundColor','k')
                end
            end

        end
        
        % --- retrieves the domain limits for the group, cGrp
        function nwLim = getGroupDomain(obj,cGrp)

            [nwLim,N] = deal([1 obj.iData.nFrm],size(obj.iData.vGrp,1));

            if (cGrp > 1); nwLim(1) = obj.iData.vGrp(cGrp-1,2)+1; end
            if (cGrp < N); nwLim(2) = obj.iData.vGrp(cGrp+1,1)-1; end

        end
        
        % --- updates the selection object enabled flags
        function updateSelectionEnable(obj,Type,fLim)
            
            % sets the enabled flags
            isEnable = [repmat(fLim(1)>1,1,2),repmat(fLim(1)<fLim(2),1,2)];
           
            % sets the selection button enabled properties
            obj.setSelectButtonEnable('on',Type,find(isEnable));
            obj.setSelectButtonEnable('off',Type,find(~isEnable));
            
        end
        
        % --- sets up the enabled properties
        function setSelectButtonEnable(obj,State,Type,Index)
            
            % initialisations
            hP = {obj.hPanelF,obj.hPanelV};
            
            % sets the button enabled properties
            for i = Index(:)'
                hB = findall(hP{Type},'tag','hButS','String',obj.bStr{i});
                setObjEnable(hB,State)
            end
            
        end   
        
        % --- resets the groups lower/upper frame limits
        function nwLim = getGroupLimits(obj,cGrp,isLower)

            % initialises the frame limits
            vG = obj.iData.vGrp;
            nwLim = [1+(~isLower) (obj.iData.nFrm-isLower)];

            % sets the upper/lower limits (based on the limit type)
            if isLower
                % case is the lower limit
                if (cGrp > 1); nwLim(1) = vG(cGrp-1,2)+1; end
                if (cGrp < size(vG,1)); nwLim(2) = vG(cGrp,2)-1; end
            else
                % case is the upper limit
                if (cGrp > 1); nwLim(1) = vG(cGrp,1)+1; end
                if (cGrp < size(vG,1)); nwLim(2) = vG(cGrp+1,1)-1; end
            end
            
        end
        
        % --- resets the properties of the other groups
        function resetOtherGroupProps(obj,hGrp,cGrp,iOfs)

            % re-orders the userdata flags of the other groups
            grpCol = distinguishable_colors(size(obj.iData.vGrp,1)+1);
            for i = 1:length(hGrp)
                cGrpNw = get(hGrp(i),'UserData');
                if cGrpNw > cGrp
                    % updates the group index
                    set(hGrp(i),'UserData',cGrpNw+iOfs)
                    
                    % updates the group facecolour
                    if obj.isOld
                        set(findall(hGrp(i),'tag','patch'),...
                                    'facecolor',grpCol(cGrpNw+iOfs,:))
                    else
                        set(hGrp(i),'Color',grpCol(cGrpNw+iOfs,:))
                    end
                end
            end

        end
        
        % --- retrieves the face-alpha values
        function fAlpha = getFaceAlpha(obj,hP)

            if obj.isOld
                fAlpha = arrayfun(@(x)(get(findall...
                        (x,'tag','patch'),'FaceAlpha')),hP);
            else
                fAlpha = arrayfun(@(x)(get(x,'FaceAlpha')),hP);
            end

        end        
        
    end
    
    % static class methods
    methods (Static)
        
        % --- initialisation of the program data struct
        function iData = initDataStruct(iDataM,iMov)

            % sets the video group indices
            if isfield(iMov,'vGrp')
                % if the video group indices exist,then retrieve them
                if isempty(iMov.vGrp)
                    vGrp = [1,iDataM.nFrm];        
                else
                    vGrp = iMov.vGrp;
                end
            else
                % if no such group exists, then initialise the 
                % video group array
                vGrp = [1,iDataM.nFrm];
            end

            % creates the gui data struct
            iData = struct('cFrm',1,'nFrm',iDataM.nFrm,'cGrp',1,'vGrp',vGrp);
            
        end
        
    end
        
end