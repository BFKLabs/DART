classdef VideoSplitObj < handle
    
    % class properties
    properties
        
        % main class fields
        hFigM
        hMainG
        iDataM
        iData
        iMov        
        
        % temporary class fields
        vGrp
        hTimer
        hLine
        tMove
        
        % temporary index fields
        iRowT
        iColT
        iRowS = NaN;
        
        % class object fields
        hFig        
        hPanelP
        hPanelAx
        hMenuC
        
        % plot axes objects
        hImg
        hPanelImg
        hAxImg
        hPanelGrp
        hAxGrp
        hGrpR
        
        % video group selection objects
        hPanelV
        hTxtV
        hButSV
        hEditSV
        hButLV
        hTableV
        jTableV
        
        % video group control button objects
        hPanelC
        hButC
        
        % frame selection objects
        hPanelF
        hButSF
        hEditSF
        
        % class object dimensions
        widFig
        hghtFig        
        hghtAxImg
        hghtAxGrp
        hghtPanelGrp
        hghtPanelV
        hghtPanelC
        hghtPanelF        
        widPanelAll        
        widAxAll
        widPanelS
        widPanelC
        widButLV               
        widEditS        
        widButC 
        hghtTableV
        y0PanelP
        
        % fixed object dimensions
        dX = 10;
        hghtHdr = 20;
        hghtBut = 25;
        hghtEdit = 22;
        hghtTxt = 16;
        hghtRow = 25;        
        widTxt = 90;
        widTxtL = 110;
        widTxtLV = 40;
        widEditLV = 55;
        widPanelP = 235;
        hghtPanelP = 350;        
        widPanelAx = 690;
        hghtPanelAx = 435;        
        hghtPanelImg = 350;                        
        
        % other static numerical fields        
        tP = 0.1;
        fSzH = 13;
        fSzT = 12;
        fSz = 10 + 2/3;        
        fAlphaOn = 0.6;
        fAlphaOff = 0.1;
        nFrmMin = 50;
        yOfs = 0.1;
        bgColS = [0.390,0.785,1.000];
        
        % boolean class fields
        isOld
        ignoreMove = false;        
        updateFrm = false;
        updateGrp = false;
        pressCtrl = false;
        isChange = false;
        isUpdating = false;
        isInit = false;
        
        % static string fields
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
            obj.hMainG = guidata(obj.hFigM);
            
            % initialisation of the program data struct
            obj.iData = obj.initDataStruct(obj.iDataM,obj.iMov);
            
            % sets the figure width/height dimensions
            obj.widFig = obj.widPanelAx + obj.widPanelP + 3*obj.dX;
            obj.hghtFig = obj.hghtPanelAx + 2*obj.dX;
            
            % sets the common axes/panel width dimensions
            obj.widPanelAll = obj.widPanelAx - 2*obj.dX;
            obj.widAxAll = obj.widPanelAll - 2*obj.dX;                                    
            
            % panel height dimension calculations
            obj.hghtPanelP = obj.hghtFig - 2*obj.dX;
            obj.hghtPanelF = obj.hghtHdr + obj.hghtRow + obj.dX;
            obj.hghtPanelV = obj.hghtPanelP - ...
                            (obj.hghtPanelF + 3*obj.dX);
            obj.hghtPanelGrp = obj.hghtPanelAx - ...
                            (obj.hghtPanelImg + 3*obj.dX);
            obj.hghtAxImg = obj.hghtPanelImg - 2*obj.dX;
            obj.hghtAxGrp = obj.hghtPanelGrp - 2*obj.dX;                                                
            obj.hghtPanelC = obj.hghtBut + obj.dX;
            
            obj.hghtTableV = obj.hghtPanelV - ...
                            (obj.hghtHdr + obj.hghtPanelC + obj.dX);
            
            % panel width dimension calculations
            obj.widPanelS = obj.widPanelP - 2*obj.dX;
            obj.widPanelC = obj.widPanelS - obj.dX;            
            
            % other object dimension calculations
            obj.widButC = (obj.widPanelC - obj.dX)/2;            
            obj.widButLV = (obj.widPanelS - 3*obj.dX)/2;
            obj.widEditS = obj.widPanelS - (2*obj.dX + 4*obj.hghtBut + 1);
            
            % other coordinate calculations
            obj.y0PanelP = obj.hghtFig - (obj.dX + obj.hghtPanelP);            
            
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
            obj.hMenuC = uimenu(hMenuP,'Label','Clear Groups',...
                          'Accelerator','C','Callback',@obj.menuClear);    
            uimenu(hMenuP,'Label','Close Window','Accelerator','X',...
                          'Separator','on','Callback',@obj.menuExit);    
            
            % ----------------------------------- %
            % --- VIDEO GROUP PARAMETER PANEL --- %
            % ----------------------------------- % 
            
            % creates the panel object
            tStrV = 'VIDEO GROUP INFORMATION'; 
            pPosV = [obj.dX*[1,1],obj.widPanelS,obj.hghtPanelV];
            obj.hPanelV = uipanel(obj.hPanelP,'Title',tStrV,'Units',...
                        'Pixels','Position',pPosV,'FontUnits','Pixels',...
                        'FontSize',obj.fSzH,'FontWeight','bold');                    
            
            % ------------------------------------ %
            % --- CONTROL BUTTON PANEL OBJECTS --- %
            % ------------------------------------ %
                    
            % initialisations
            cWidV = {50,80,80};
            cNameV = {'Group','Start','Finish'};            
            bStrC = {'Merge Groups','Split Group'};            
            obj.hButC = cell(length(bStrC),1);            
            
            % function handles
            cbFcnVE = @obj.tableCellEdit;            
            cbFcnVS = @obj.tableCellSelect;
            cbFcnB = {@obj.buttonMerge,@obj.buttonSplit};                        
            
            % creates the control button panel   
            pPosC = [obj.dX*[1,1]/2,obj.widPanelC,obj.hghtPanelC];
            obj.hPanelC = uipanel(obj.hPanelV,'Title','','Units',...
                                              'Pixels','Position',pPosC);                    
                    
            % creates the button objects
            for i = 1:length(bStrC)
                xPos = obj.dX/2 + (i-1)*obj.widButC;
                bPosC = [xPos,obj.dX/2,obj.widButC,obj.hghtBut];
                obj.hButC{i} = uicontrol(obj.hPanelC,'Style','Pushbutton',...
                        'Position',bPosC,'Callback',cbFcnB{i},'FontUnits',...
                        'Pixels','FontSize',obj.fSzT,'FontWeight','Bold',...
                        'String',bStrC{i});
            end
            
            % disables the merge button
            setObjEnable(obj.hButC{1},'off')                                                  
            
            % creates the table object
            yPosT = sum(pPosC([2,4])) + obj.dX/2;
            tPosV = [obj.dX/2,yPosT,obj.widPanelC,obj.hghtTableV];
            obj.hTableV = createUIObj('table',obj.hPanelV,...
                'Data',[],'Position',tPosV,'FontSize',obj.fSz,...
                'CellSelectionCallback',cbFcnVS,'ColumnName',cNameV,...
                'CellEditCallback',cbFcnVE,'ColumnWidth',cWidV,...
                'ColumnEditable',[false,true,true],'RowName',[]);            
            
            % other table property/field updates
            obj.jTableV = getJavaTable(obj.hTableV);
            autoResizeTableColumns(obj.hTableV)
            
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
                        obj.setupSelectionObj(obj.hPanelF,obj.dX/2 + 1,1);                                 
            
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
        
        % --- resets the figure object dimensions
        function resetFigureObjects(obj)
            
            % updates the image axes
            ImgNw = obj.updateImageAxes();
            pPos = get(obj.hPanelImg,'position');
            Wnw = roundP(pPos(4)*size(ImgNw,2)/size(ImgNw,1));
            dW = Wnw-pPos(3);
            
            % resets the dimensions of the axes objects
            resetObjPos(obj.hAxImg,'width',dW,1);
            resetObjPos(obj.hPanelImg,'width',dW,1);
            resetObjPos(obj.hAxGrp,'width',dW,1);
            resetObjPos(obj.hPanelGrp,'width',dW,1);
            resetObjPos(obj.hPanelAx,'width',dW,1);
            resetObjPos(obj.hFig,'width',dW,1);                        
            
        end
        
        % initialises the class fields/objects
        function initObjProps(obj)
            
            % field retrieval
            vG = obj.iData.vGrp;            
            xLim = [1 obj.iData.nFrm] + 0.5*[-1 1];
            
            % updates the table properties
            obj.resetTableData();            
            obj.resetTableHightlight(1);            
            
            % initialises the edit box values
            set(obj.hEditSF,'string',num2str(vG(1,1)));           
            
            % updates the selection properties
            obj.updateSelectionEnable(1, [vG(1,1), obj.iData.nFrm])            
            
            % sets up the video group axes
            cla(obj.hAxGrp)
            set(obj.hAxGrp,'xlim',xLim,'yLim',[0 1]);
            
            % initialises the frame/video group marker objects
            obj.initFrameMarker();
            obj.initGroupMarkers();            
            
            % resets the figure objects
            obj.resetFigureObjects();  
            setObjEnable(obj.hMenuC,size(vG,1)>1);
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            if ~obj.isInit
                % updates the GUI object properties
                obj.isInit = true;
                centreFigPosition(obj.hFig);            

                % makes the gui visible            
                start(obj.hTimer);
                setObjVisibility(obj.hFig,'on')
            end
            
        end

        % ------------------------------ %
        % --- FRAME MARKER FUNCTIONS --- %
        % ------------------------------ % 
        
        % --- initialises the frame marker
        function initFrameMarker(obj)

            % axis initialisations
            hold(obj.hAxGrp,'on')

            % creates the line object
            lCol = 'm';
            xL = [1 obj.iData.nFrm];
            pL = {obj.iData.vGrp(1,1)*[1 1],[0 1]};

            % creates the line object
            obj.hLine = InteractObj('line',obj.hAxGrp,pL);
            obj.hLine.setFields('tag','hLine','UserData',0,...
                                'LineWidth',2,'ContextMenu',[]);

            % updates the marker properties/callback function
            obj.hLine.setColour(lCol);
            obj.hLine.setObjMoveCallback(@obj.frmMove); 
            obj.hLine.setConstraintRegion(xL,[0 1]);    

            if ~obj.hLine.isOld
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

            % updates the corresponding editbox value
            set(obj.hEditSF,'string',num2str(cFrm));            
            obj.updateSelectionEnable(1, [cFrm, obj.iData.nFrm])            
            
        end
        
        % ------------------------------ %
        % --- GROUP MARKER FUNCTIONS --- %
        % ------------------------------ %        
        
        % --- initialises the markers for ea\ch video index group
        function initGroupMarkers(obj)
            
            % memory allocation
            nGrp = size(obj.iData.vGrp,1);            
            obj.hGrpR = cell(nGrp,1);

            % creates the group markers for each region
            for i = 1:nGrp
                obj.hGrpR{i} = ...
                    obj.createGroupMarker(i,obj.iData.vGrp(i,:),true);
                obj.setGroupFaceAlpha(obj.hGrpR{i},i==1);
            end

            % resets the groups markers into the correct order
            hAxG = obj.hAxGrp;
            set(hAxG, 'Children',flipud(get(hAxG, 'Children')))

        end
        
        % --- creates the group marker for the group index, cGrp
        function hRect = createGroupMarker(obj,cGrp,fLim,isInit)

            % initialisations
            grpCol = distinguishable_colors(size(obj.iData.vGrp,1));

            % axis initialisations
            hold(obj.hAxGrp,'on')            
            
            % creates the rectangle object
            rPos = [fLim(1) -obj.yOfs fLim(2)-fLim(1) 1+2*obj.yOfs];
            hRect = InteractObj('rect',obj.hAxGrp,rPos);
            
            % sets the position callback function
            hRect.setColour(grpCol(cGrp,:));
            hRect.setFields('tag','hGrp','UserData',cGrp,...
                            'Rotatable',0,'ContextMenu',[]);
            obj.setGroupFaceAlpha(hRect,0);
            hRect.setObjMoveCallback(@obj.grpMove);
            hRect.setObjClickCallback(@obj.grpClicked);
            
            % removes the hold on the axes
            hold(obj.hAxGrp,'on')

            % resets the order of the objects (frame marker on top then groups)
            if ~isInit
                hGrpT = findall(obj.hAxGrp, 'tag', 'hGrp');
                hLineT = findall(obj.hAxGrp, 'tag', 'hLine');
                set(obj.hAxGrp, 'Children', [hLineT;flipud(hGrpT)])
            end

        end
        
        % --- group roi clicked callback function
        function grpClicked(obj,hRect,evnt)
            
            % retrieves the currently selected group object
            if exist('evnt','var')
                % case is the newer format objects
                cGrp = hRect.UserData;                
            else
                % case is the older format objects
                cGrp = get(get(gco,'parent'),'UserData');                
            end
            
            % if control is pressed, add/remove the selected group
            if obj.pressCtrl
                if any(obj.iRowS == cGrp)
                    % removes the selection (if in the list)
                    cGrp = setdiff(obj.iRowS,cGrp);

                else
                    % otherwise, add to the list
                    cGrp = sort([obj.iRowS;cGrp]);
                end
            end
            
            % sets the group/table highlights
            obj.switchSelectedGroup(cGrp)
            obj.resetTableHightlight(cGrp);
            obj.resetButtonProps(cGrp);
            removeTableSelection(obj.hTableV);
            
        end        

        % --- group roi moved callback function
        function grpMove(obj,hRect,evnt)
            
            % global variables
            [obj.updateGrp,obj.tMove,obj.isChange] = deal(true,NaN,true);

            % exits the function if ignoring
            if obj.ignoreMove; return; end

            % retrieves the currently selected group object
            if exist('evnt','var')
                % case is the newer format objects
                cGrp = hRect.UserData;                
            else
                % case is the older format objects
                cGrp = get(get(gco,'parent'),'UserData');                
            end

            % updates the limits on the screen
            pPos = getIntObjPos(hRect);
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

                % resets the group marker position vector
                if (fLim(1) < nwLim(1)) || (fLim(2) > nwLim(2))
                    fLim = [max(fLim(1),nwLim(1)),min(fLim(2),nwLim(2))];
                    obj.iData.vGrp(cGrp,:) = ...
                        [max(obj.iData.vGrp(cGrp,1),nwLim(1)),...
                         min(obj.iData.vGrp(cGrp,2),nwLim(2))];
                    obj.resetGroupPosition(hRect,fLim)
                end
            end
            
            % resets the bottom location (if moved)
            if abs(pPos(2) + obj.yOfs) > 1e-6
                obj.resetGroupPosition(hRect,fLim);
            end
            
            % updates the table fields
            obj.isUpdating = true;
            obj.hTableV.Data(cGrp,2:3) = num2cell(fLim);
            obj.isUpdating = false;

            % resets the video group object properties
            setObjEnable(obj.hButC{2},diff(fLim)>obj.nFrmMin)            
            
        end
        
        % --- sets the group face-alpha 
        function setGroupFaceAlpha(obj,hRect,isOn)
            
            % sets the face alpha value based on type
            if isOn
                fAlpha = obj.fAlphaOn;
            else
                fAlpha = obj.fAlphaOff;
            end
           
            % sets the group marker face alpha
            if isOldIntObjVer
                hRectP = findall(hRect,'tag','patch');
                set(hRectP,'FaceAlpha',fAlpha);
            else
                hRect.setFields('FaceAlpha',fAlpha);
            end
            
        end        
        
        % --- switches the selected groups from cGrpC to cGrp
        function switchSelectedGroup(obj,cGrp)

            % removes the current selections
            cellfun(@(h)(obj.setGroupFaceAlpha(h,0)),obj.hGrpR(obj.iRowS))
            
            % sets the group highlights
            if ~isempty(cGrp)            
                cellfun(@(h)(obj.setGroupFaceAlpha(h,1)),obj.hGrpR(cGrp))
            end

        end        
        
        % --- resets the position of the video group object
        function resetGroupPosition(obj,hRect,fLim)

            % updates the group limits
            fLimNw = [fLim(1) -obj.yOfs max(1,diff(fLim)) 1+2*obj.yOfs];
            
            % resets the position of the group rectangle 
            obj.ignoreMove = true;
            setIntObjPos(hRect,fLimNw);
            obj.ignoreMove = false;

        end
        
        % --- updates the face alpha for a given group patch object
        function hP = updatePatchFaceAlpha(obj, cGrp, fAlpha)

            hP = arrayfun(@(x)(findall(...
                obj.hAxGrp,'tag','hGrp','UserData',x)),cGrp);
            
            if obj.isOld
                arrayfun(@(h)(set(findall(...
                    h,'tag','patch'),'facealpha',fAlpha)),hP)
            else
                arrayfun(@(h)(set(h,'facealpha',fAlpha)),hP);
            end

        end        
        
        % ------------------------------------------ %
        % --- SPLIT/MERGE GROUP MARKER FUNCTIONS --- %
        % ------------------------------------------ %        
        
        % --- splits the group markers
        function splitGroupMarkers(obj)
            
            % initialisations        
            cGrp = obj.iRowS;            
            vG = obj.iData.vGrp;
            obj.isChange = true;            
            hObjS = obj.hGrpR{cGrp}.hObj;           
            
            % recalculates the new limits
            fPos = getIntObjPos(hObjS);
            fLim = roundP(fPos(1)+[0 fPos(3)]);
            vGrpNw = fLim(1) + [0 floor(fPos(3)/2)];
            vGrpNw = [vGrpNw;[(vGrpNw(1,2)+1) fLim(2)]];

            % updates the video group index array            
            obj.iData.vGrp = [vG(1:(cGrp-1),:);vGrpNw;vG((cGrp+1):end,:)];

            % resets the table properties
            obj.resetTableData();            
            removeTableSelection(obj.hTableV);
            obj.switchSelectedGroup([]);
            obj.resetTableHightlight([]);
            
            % sets the other object properties
            cellfun(@(h)(setObjEnable(h,0)),obj.hButC);
            setObjEnable(obj.hMenuC,1);
            
            % resets the position of the first group, and creates another
            obj.resetGroupPosition(hObjS,vGrpNw(1,:));
            
            % creates the new group marker
            obj.hGrpR = obj.expandArray(obj.hGrpR,cGrp+1);
            obj.hGrpR{cGrp+1} = obj.createGroupMarker(cGrp+1,vGrpNw(2,:),0);             
            
        end        
        
        % --- merges the group markers given by the array, hPM
        function mergeGroupMarkers(obj)
            
            % initialisations
            cGrp = obj.iRowS; 
            nGrp = length(obj.hGrpR);
            obj.isChange = true;

            % removes the merged groups
            isOK = true(size(obj.iData.vGrp,1),1);
            isOK(cGrp(2:end)) = false;
            
            % merges the group indices
            obj.iData.vGrp(cGrp(1),2) = obj.iData.vGrp(cGrp(end),2);
            [obj.iData.vGrp,vG] = deal(obj.iData.vGrp(isOK,:));

            % resets the position of the merged group and deletes the others
            isKeep = true(nGrp,1);
            for i = cGrp(1):nGrp
                if i <= (nGrp - (length(cGrp)-1))
                    % resets the position of the group (if feasible)
                    obj.resetGroupPosition(obj.hGrpR{i}.hObj,vG(i,:));
                else
                    % otherwise, delete the marker object
                    obj.hGrpR{i}.deleteObj();
                    isKeep(i) = false;
                end
            end            
            
            % sets the group/table highlights
            obj.resetTableData()
            
            % sets the group/table highlights
            obj.switchSelectedGroup(cGrp(1));
            obj.resetTableHightlight(cGrp(1));
            obj.resetButtonProps(cGrp(1));
            
            % reduces the object handle array
            obj.hGrpR = obj.hGrpR(isKeep);            
            
            % resets the other GUI object properties
            setObjEnable(obj.hMenuC,size(vG,1)>1);
            
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
                lBut = obj.dX/2 + (i-1)*obj.hghtBut + ...
                                  (i>2)*(obj.widEditS + obj.dX);
                bPos = [lBut,y0,obj.hghtBut*[1,1]];                
                hBut{i} = uicontrol(hP,'Style','Pushbutton',...
                            'Position',bPos,'Callback',cbFcnB{i},...
                            'FontUnits','Pixels','FontSize',obj.fSzT,...
                            'FontWeight','Bold','String',obj.bStr{i},...
                            'UserData',uStr,'tag','hButS');                
            end            
            
            % creates the count editbox object
            lEdit = obj.dX + 2*obj.hghtBut;
            ePos = [lEdit,y0+1,obj.widEditS,obj.hghtEdit];
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
            end
            
        end
                
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %        
        
        % --- first frame/group button selection callback function
        function FirstButton(obj,~,~)
            
            % updates the selection properties
            set(obj.hEditSF,'string','1')
            obj.updateSelectionEnable(1,[1,obj.iData.nFrm])

            % updates the image axes
            obj.iData.cFrm = 1;
            obj.updateFrameMarkerPos()
            
        end
        
        % --- previous frame/group button selection callback function
        function PrevButton(obj,~,~)

            % updates the corresponding editbox value
            currVal = str2double(get(obj.hEditSF,'string'));
            set(obj.hEditSF,'string',num2str(currVal-1))
            obj.updateSelectionEnable(1, [currVal-1, obj.iData.nFrm])

            % updates the image axes
            obj.iData.cFrm = obj.iData.cFrm - 1;
            obj.updateFrameMarkerPos()
            
        end
        
        % --- next frame/group button selection callback function
        function NextButton(obj,~,~)

            % updates the corresponding editbox value
            currVal = str2double(get(obj.hEditSF,'string'));
            set(obj.hEditSF,'string',num2str(currVal+1))
            obj.updateSelectionEnable(1, [currVal+1, obj.iData.nFrm])

            % updates the image axes
            obj.iData.cFrm = obj.iData.cFrm + 1;
            obj.updateFrameMarkerPos()
            
        end
        
        % --- last frame/group button selection callback function
        function LastButton(obj,~,~)

            % updates the selection enabled properties
            valLim = obj.iData.nFrm;

            % updates the selection properties
            set(obj.hEditSF,'string',num2str(valLim))
            obj.updateSelectionEnable(1, [valLim, valLim])

            % updates the image axes
            obj.iData.cFrm = obj.iData.nFrm;
            obj.updateFrameMarkerPos()
            
        end
        
        % --- frame/group index editbox callba<ck function
        function CountEdit(obj,hObj,~)
            
            % retrieves the image data struct
            nwVal = str2double(get(hObj,'string'));
            
            % updates the frame/sub-movie index
            [nwLim,pStr] = deal([1 obj.iData.nFrm],'cFrm');

            % checks to see if the new value is valid
            if chkEditValue(nwVal,nwLim,1)
                % if so, then updates the counter and the image frame
                obj.iData = setStructField(obj.iData,pStr,nwVal);

                % updates the selection enabled properties
                obj.updateSelectionEnable(1, [nwVal, nwLim(2)])
                obj.updateFrameMarkerPos()
            else
                % resets the edit box string to the last valid value
                pStr0 = num2str(getStructField(obj.iData,pStr));
                set(hObj,'string',pStr0)
            end

        end                    
        
        % ------------------------------------------ %
        % --- VIDEO GROUP FRAME OBJECT CALLBACKS --- %
        % ------------------------------------------ %        
        
        % --- table cell edit callback function
        function tableCellEdit(obj, ~, evnt)

            % if updating elsewhere or infeasible then exit
            if obj.isUpdating || isempty(evnt.Indices)
                return
            end            
            
            % field retrieval
            vG = obj.iData.vGrp;
            nwVal = evnt.NewData;            
            nwLim = [1,obj.iData.nFrm];            
            [iRowNw,iColNw] = deal(evnt.Indices(1),evnt.Indices(2)); 
            
            % sets the lower/upper limits
            if (iRowNw > 1); nwLim(1) = vG(iRowNw-1,2) + 1; end
            if (iRowNw < size(vG,1)); nwLim(2) = vG(iRowNw+1,1) - 1; end
            
            % determines if the new value is valid
            if chkEditValue(nwVal,nwLim,1)
                % if so, then update video group limits/objects
                obj.iData.vGrp(iRowNw,iColNw-1) = nwVal;
                
                % resets the group position
                obj.resetGroupPosition(...
                    obj.hGrpR{iRowNw}.hObj,obj.iData.vGrp(iRowNw,:));
                obj.resetButtonProps()
                
            else
                % otherwise, reset to the previous value
                obj.hTableV.Data{iRowNw,iColNw} = evnt.PreviousData;
            end
            
        end
        
        % --- table cell selection callback function        
        function tableCellSelect(obj, ~, evnt)
                        
            % if updating elsewhere or infeasible then exit
            if obj.isUpdating || isempty(evnt.Indices)
                return
            end
            
            % field retrieval
            [iRowNw,iColNw] = deal(evnt.Indices(:,1),evnt.Indices(:,2));
            
            % appends/removes the selection
            if obj.pressCtrl                
                % resets the table update flag
                obj.isUpdating = true;
                removeTableSelection(obj.hTableV);

                % for multi-selected cells, determine the last selection
                if length(iRowNw) > 1
                    iB = sum(abs(evnt.Indices-[obj.iRowT,obj.iColT]),2)>0;
                    [iRowNw,iColNw] = deal(iRowNw(iB),iColNw(iB));
                end                                
                
                % resets the table selection
                setTableSelection(obj.hTableV,iRowNw-1,iColNw-1)                
                [obj.iRowT,obj.iColT] = deal(iRowNw,iColNw); 
                                
                if any(obj.iRowS == iRowNw)
                    % removes the selection (if in the list)
                    iRowNw = setdiff(obj.iRowS,iRowNw);
                    
                else
                    % otherwise, add to the list
                    iRowNw = sort([obj.iRowS;iRowNw]);
                end
                
                % resets the update flag
                pause(0.05);
                obj.isUpdating = false;
            else
                % updates the currently selected table indices
                [obj.iRowT,obj.iColT] = deal(iRowNw,iColNw);                 
            end                          
                        
            % resets the table highlight
            if ~isequal(iRowNw,obj.iRowS)
                obj.switchSelectedGroup(iRowNw);
                obj.resetTableHightlight(iRowNw);
                setObjEnable(obj.hButC{2},~isempty(iRowNw));
            end 
            
            % resets the other object properties
            obj.resetButtonProps()
            
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
            
            % otherwise, prompt the user if they want to merge 
            tStr = 'Merge Selected Video Groups?';                
            qStr = 'Are you sure you want to merge the selected groups?';
            uChoice = questdlg(qStr,tStr,'Yes','No','Yes');    
            if strcmp(uChoice,'Yes')
                % is so, then merges the selected groups
                obj.mergeGroupMarkers()
                setObjEnable(hObj,'off')
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
        
        % --- group clearing menu item callback function
        function menuClear(obj,~,~)
            
            % if so, prompt the user if they wish to update the changes
            tStr = 'Clear Video Groups';
            qStr = 'Do you wish to clear all the video groups?';
            uChoice = questdlg(qStr,tStr,'Yes','No','Yes');                        
            
            % initialisation of the program data struct
            if strcmp(uChoice,'Yes')
                % resets the data struct
                cFrm0 = obj.iData.cFrm;
                obj.iData = obj.initDataStruct(obj.iDataM,obj.iMov,1);      
                obj.iData.cFrm = cFrm0;
                
                % re-initialises the object properties
                obj.initObjProps();
                
                % resets the other fields/object properties
                obj.isChange = true;
                setObjEnable(obj.hMenuC,0);
                setObjEnable(obj.hButC{1},0);
                setObjEnable(obj.hButC{2},1);
            end
            
        end
        
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

        % --------------------------------------- %
        % --- TABLE PROPERTY UPDATE FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- resets the table highlight 
        function resetTableHightlight(obj,iRowNw)
            
            % flag that manual updating is taking place
            obj.isUpdating = true;
            
            % field updates
            obj.iRowS = iRowNw;                        
            
            % table background colour reset
            nRowT = size(obj.hTableV.Data,1);
            if size(obj.hTableV.BackgroundColor,1) == nRowT
                obj.hTableV.BackgroundColor(:) = 1;
            else
                obj.hTableV.BackgroundColor = ones(nRowT,3);
            end
                
            % sets the table colour highlight
            if ~isempty(iRowNw)
                bgColNw = repmat(obj.bgColS,length(iRowNw),1); 
                obj.hTableV.BackgroundColor(iRowNw,:) = bgColNw; 
            end
            
            % flag that manual updating is taking place
            pause(0.05);
            obj.isUpdating = false;            
            
        end
        
        % --- resets the table data
        function resetTableData(obj)
                
            vG = obj.iData.vGrp;                        
            obj.hTableV.Data = num2cell([(1:size(vG,1))',vG]);
            
        end            
        
        % ------------------------------------- %
        % --- OTHER OBJECT UPDATE FUNCTIONS --- %
        % ------------------------------------- %        
        
        % --- updates the selection object enabled flags
        function updateSelectionEnable(obj,Type,fLim)
            
            % sets the enabled flags
            isEnable = [repmat(fLim(1)>1,1,2),repmat(fLim(1)<fLim(2),1,2)];
            
            % sets the selection button enabled properties
            obj.resetFrameButtonProps('on',Type,find(isEnable));
            obj.resetFrameButtonProps('off',Type,find(~isEnable));
            
        end
        
        % --- sets up the enabled properties
        function resetFrameButtonProps(obj,State,Type,Index)
            
            % initialisations
            hP = {obj.hPanelF,obj.hPanelV};
            
            % sets the button enabled properties
            for i = Index(:)'
                hB = findall(hP{Type},'tag','hButS','String',obj.bStr{i});
                setObjEnable(hB,State)
            end
            
        end
        
        % --- resets the control button properties
        function resetButtonProps(obj,cGrp)
            
            % default input arguments
            if ~exist('cGrp','var'); cGrp = obj.iRowS; end
            
            % field retrieval
            vG = obj.iData.vGrp;
            
            % updates the control button properties
            if length(cGrp) == 1
                % case is only one group is selected
                setObjEnable(obj.hButC{1},0);
                setObjEnable(obj.hButC{2},diff(vG(cGrp,:)) > obj.nFrmMin);
                
            else
                % case is a non-unique button was selected
                setObjEnable(obj.hButC{2},0);
                if length(cGrp) > 1
                    % case is more than one group is selected
                    setObjEnable(obj.hButC{1},all(diff(cGrp)==1));
                    
                else
                    % case is no groups were selected
                    setObjEnable(obj.hButC{1},0);
                end
            end
            
        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %                
        
        % --- updates the main display image
        function ImgNw = updateImageAxes(obj)

            % initialisations
            hAx = obj.hAxImg;
            cFrm = str2double(get(obj.hEditSF,'string'));

            % retrieves the image for the current frame
            ImgNw = getDispImage(obj.iDataM,obj.iMov,cFrm,false,obj.hMainG);

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
        function iData = initDataStruct(iDataM,iMov,forceReset)
            
            % default input arguments
            if ~exist('forceReset','var'); forceReset = false; end

            % sets the video group indices
            if isfield(iMov,'vGrp') && ~forceReset
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
            iData = struct('cFrm',1,'nFrm',iDataM.nFrm,'vGrp',vGrp);
            
        end
        
        % --- expands the array, h, and the location iExp
        function h = expandArray(h,iExp)
            
            hGap = cell(1,size(h,2));
            h = [h(1:iExp-1,:);hGap;h(iExp:end,:)];
            
        end        
        
    end
        
end