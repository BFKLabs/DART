classdef AnalysisOpt < handle
    
    % class properties
    properties
        
        % main class fields        
        hAxM
        hFigM
        hGUIM
        
        % main struct fields
        iMov
        trkP
        pFile        
        
        % original struct fields
        iMov0        
        trkP0
        Img0
        
        % class object handles
        hFig
        hPanelT
        hPopT
        hEditT
        hChkT
        hPanelR
        hEditR
        hButR
        hPanelP
        hTableP
        hChkP
        hPanelC
        hButC
        
        % fixed object dimensions
        dX = 10;
        widFig = 670;
        hghtFig = 220;
        hghtBut = 25;
        widButC = 145;
        hghtTxt = 16;
        hghtChk = 20;
        hghtPop = 22;
        hghtEdit = 22;
        hghtPanelC = 40;
        hghtPanelR = 55;        
        widPopT = 170;
        widEditT = 80;
        widChkT = [165,NaN];
        widEditR = 70;
        widButR = 100;        
        
        % calculated object dimensions
        widPanel
        hghtPanelT
        widTxtTP
        widTxtTE
        widPanelR
        widTxtR
        hghtPanelP
        widTableP
        hghtTableP    
        
        % rotation gui marker objects 
        hAngle
        hGuideH
        hGuideV
        
        % scalar fields
        tSz = 13;
        fSz = 12;
        eSz = 11;
        nRow = 4;
        
        % other scalar fields
        is2D        
        isCalib
        isMltTrk
        phiRotM
        resetPData = false;
        isUpdating = false;
        updateReqd = false;
        
        % function handles
        dispImage
        showTubeFcn
        showMarkFcn
        showAngleFcn
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = AnalysisOpt(hFigM)
            
            % sets the input arguments
            obj.hFigM = hFigM;
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initTrackPara();
            obj.initClassObj();
            
        end
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % global variables
            global HWT H0T isCalib
            
            % sets the calibration flag
            obj.isCalib = isCalib;
            obj.hGUIM = guidata(obj.hFigM);            
            
            % calculates the dependent object dimensions
            obj.widPanel = (obj.widFig - 3*obj.dX)/2;
            obj.widPanelR = obj.widPanel - 2*obj.dX;
            
            % general tracking parameter objects
            dWidP = obj.widPanel - 2*obj.dX;
            obj.hghtPanelT = obj.hghtFig - 2*obj.dX;
            obj.widChkT(2) = dWidP - obj.widChkT(1);            
            obj.widTxtTP = dWidP - obj.widPopT;
            obj.widTxtTE = dWidP - obj.widEditT;
            
            % image rotation parameter objects
            dWidR = obj.widPanelR - 3*obj.dX;
            obj.widTxtR = dWidR - (obj.widEditR + obj.widButR);
            
            % activity classication parameter objects
            obj.hghtPanelP = obj.hghtFig - (3*obj.dX + obj.hghtPanelC);
            obj.widTableP = obj.widPanel - 2*obj.dX;
            obj.hghtTableP = H0T + obj.nRow*HWT;
           
            % other object handle fields
            obj.hAxM = findall(obj.hFigM,'Type','Axes');            
            [obj.iMov,obj.iMov0] = deal(obj.hFigM.iMov);  
            obj.pFile = getParaFileName('ProgPara.mat');
            
            % retrieves the currently shown image (calibration only)
            if obj.isCalib
                ImgT = get(findobj(obj.hAxM,'Type','Image'),'CData');
                obj.Img0 = getRotatedImage(obj.iMov,double(ImgT),1);
            end
            
            % function handles
            obj.dispImage = get(obj.hFigM,'dispImage');
            obj.showTubeFcn = get(obj.hFigM,'checkShowTube_Callback');
            obj.showMarkFcn = get(obj.hFigM,'checkShowMark_Callback');
            obj.showAngleFcn = get(obj.hFigM,'checkShowAngle_Callback');
            
        end
        
        % --- initialises the tracking parameter field
        function initTrackPara(obj)
            
            % determines if the tracking parameters have been set
            A = load(obj.pFile);
            if ~isfield(A,'trkP')
                % track parameters have not been set, so initialise
                obj.trkP = initTrackPara();
            else
                % track parameters have been set
                obj.trkP = A.trkP;
            end
            
            % flags whether the background parameter struct needs resetting
            if ~isfield(obj.iMov,'bgP')
                resetPara = true;
            else
                resetPara = isempty(obj.iMov.bgP);
            end
            
            % if the parameter struct doesn't need resetting then exit
            if resetPara
                % loads the parameter file
                A = load(obj.pFile);
                
                % ensures that the algorithm type field is set correctly
                if strcmp(A.bgP.algoType,'svm-single')
                    A.bgP.algoType = 'bgs-single';
                    save(obj.pFile,'-struct','A')
                end

                % ensures that the path duration field is set
                if ~isfield(A.trkP,'nPath')
                    A.trkP.nPath = 1;
                    save(obj.pFile,'-struct','A')        
                end

                % sets the background parameters
                obj.iMov.bgP = A.bgP;                
            else
                % ensures that the algorithm type field is set correctly
                if strcmp(obj.iMov.bgP.algoType,'svm-single')
                    obj.iMov.bgP.algoType = 'bgs-single';
                    obj.updateReqd = true;
                end

                % ensures that the path duration field is set
                if ~isfield(obj.iMov,'nPath')
                    obj.iMov.nPath = 1;
                    obj.updateReqd = true;
                end
            end       
            
            % retrieves the multi-tracking flags
            obj.is2D = is2DCheck(obj.iMov);
            obj.isMltTrk = detMltTrkStatus(obj.iMov);
            
        end
        
        % --- initialises the class fields
        function initClassObj(obj)
            
            % deletes any previous 
            hFigPr = findall(0,'tag','figAnalyOpt');
            if ~isempty(hFigPr); delete(hFigPr); end
            
            % --------------------------- %
            % --- MAIN FIGURE OBJECTS --- %
            % --------------------------- %            
            
            % figure dimensions
            fPos = [100,100,obj.widFig,obj.hghtFig];            
            
            % creates the figure object
            obj.hFig = figure('Position',fPos,'tag','figAnalyOpt',...
                              'MenuBar','None','Toolbar','None',...
                              'Name','Tracking GUI Parameters',...
                              'NumberTitle','off','Visible','off',...
                              'Resize','off');  
                          
            % ---------------------------------- %
            % --- TRACKING PARAMETER OBJECTS --- %
            % ---------------------------------- %
            
            % initialisations
            uData = {'nPath','nFrmS'};
            tStrT = 'GENERAL TRACKING PARAMETERS';
            cStrT = {'Calculate Fly Orientation','Use Rotated Image'};
            eStrTE = {'Tracking Path History Length: ',...
                      'Segmentation Sub-Image Stack Size: '};            
            cbFcnTC = {@obj.checkCalcAngle,@obj.checkUseRot};            
            
            % creates the panel object
            pPosR = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelT];            
            obj.hPanelT = uipanel(obj.hFig,'Title',tStrT,'Units',...
                       'Pixels','Position',pPosR,'FontUnits','Pixels',...
                       'FontSize',obj.tSz,'FontWeight','Bold');
                                                   
            % creates the checkbox objects
            yPosT0 = obj.hghtPanelR + 1.5*obj.dX;
            obj.hChkT = cell(length(cStrT),1);
            for i = 1:length(obj.hChkT)
                lPosT = obj.dX + sum(obj.widChkT(1:(i-1)));
                cPosT = [lPosT,yPosT0+2,obj.widChkT(i),obj.hghtChk];
                obj.hChkT{i} = uicontrol(obj.hPanelT,'Style','CheckBox',...
                       'String',cStrT{i},'Units','Pixels',...
                       'Position',cPosT,'FontUnits','Pixels',...
                       'FontSize',obj.fSz,'FontWeight','Bold',...
                       'Callback',cbFcnTC{i});
            end
            
            % creates the editbox objects
            yPosE0 = yPosT0 + (3*obj.dX - 2);
            obj.hEditT = cell(length(eStrTE),1);
            
            for i = 1:length(obj.hEditT)
                % creates the text object
                yPosE = yPosE0 + (i-1)*obj.hghtBut;
                tPosT = [obj.dX,yPosE+2,obj.widTxtTE,obj.hghtTxt];
                uicontrol(obj.hPanelT,'Style','Text',...
                       'String',eStrTE{i},'Units','Pixels',...
                       'Position',tPosT,'FontUnits','Pixels',...
                       'FontSize',obj.fSz,'FontWeight','Bold',...
                       'HorizontalAlignment','right');
                   
                % creates the editbox object
                lPosE = sum(tPosT([1,3]));
                editStr = getStructField(obj.trkP,uData{i});
                ePosT = [lPosE,yPosE,obj.widEditT,obj.hghtEdit];
                obj.hEditT{i} = uicontrol(obj.hPanelT,...
                       'Style','Edit','String',editStr,'Units',...
                       'Pixels','Position',ePosT,'FontUnits','Pixels',...
                       'HorizontalAlignment','center','FontSize',obj.eSz,...
                       'Callback',@obj.editSegPara,'UserData',uData{i});
            end
            
            % sets the checkbox values
            set(obj.hChkT{1},'Value',obj.iMov.calcPhi)
            set(obj.hChkT{2},'Value',obj.iMov.useRot)
            
            % ------------------------------ %
            % --- ALGORITHM TYPE OBJECTS --- %
            % ------------------------------ %
            
            % creates the text label object
            pStrP = 'Tracking Algorithm: ';
            yPosTP = sum(ePosT([2,4])) + obj.dX;
            tPosTP = [obj.dX,yPosTP+2,obj.widTxtTP,obj.hghtTxt];            
            uicontrol(obj.hPanelT,'Style','Text','String',pStrP,...
                        'Units','Pixels','Position',tPosTP,...
                        'FontUnits','Pixels','FontSize',obj.fSz,...
                        'FontWeight','Bold',...
                        'HorizontalAlignment','Right');
                    
            % creates the algorithm type popupmenu object
            pStrP = {'Dummy'};            
            lPosTP = sum(tPosTP([1,3]));
            pPosTP = [lPosTP,yPosTP,obj.widPopT,obj.hghtPop];
            obj.hPopT = uicontrol(obj.hPanelT,...
                        'Style','PopupMenu','String',pStrP,...
                        'Units','Pixels','Position',pPosTP,...
                        'FontUnits','Pixels','FontSize',obj.eSz,...
                        'Callback',@obj.popupAlgoType);
                   
            % ------------------------------ %
            % --- IMAGE ROTATION OBJECTS --- %
            % ------------------------------ %
                                    
            % creates the panel object
            tStrR = 'IMAGE ROTATION PARAMETERS';                        
            pPosR = [obj.dX*[1,1],obj.widPanelR,obj.hghtPanelR];            
            obj.hPanelR = uipanel(obj.hPanelT,'Title',tStrR,'Units',...
                       'Pixels','Position',pPosR,'FontUnits','Pixels',...
                       'FontSize',obj.tSz,'FontWeight','Bold');            
            
            % creates the text label object
            tStrR = 'Rotation Angle: ';
            tPosR = [obj.dX+[0,1],obj.widTxtR,obj.hghtTxt];
            uicontrol(obj.hPanelR,'Style','Text','String',tStrR,'Units',...
                       'Pixels','Position',tPosR,'FontUnits','Pixels',...
                       'FontSize',obj.fSz,'FontWeight','Bold',...
                       'HorizontalAlignment','right')
                   
            % creates the editbox object
            lPosRE = sum(tPosR([1,3]));
            ePosR = [lPosRE,obj.dX-1,obj.widEditR,obj.hghtEdit];  
            angStr = num2str(obj.iMov.rotPhi);
            uicontrol(obj.hPanelR,'Style','Edit','String',angStr,'Units',...
                       'Pixels','Position',ePosR,'FontUnits','Pixels',...
                       'HorizontalAlignment','center','FontSize',obj.eSz,...
                       'Callback',@obj.editSegPara,'UserData','rotPhi')
            
            % creates the togglebutton object
            lPosRB = sum(ePosR([1,3])) + obj.dX;            
            ePosR = [lPosRB,obj.dX-2,obj.widButR,obj.hghtBut];  
            obj.hButR = uicontrol(obj.hPanelR,...
                        'Style','ToggleButton','String','Use Guide',...
                        'Units','Pixels','Position',ePosR,'FontUnits',...
                        'Pixels','HorizontalAlignment','center',...
                        'FontSize',obj.fSz,'FontWeight','Bold',...
                        'Callback',@obj.useGuide);
                   
            % sets the panel properties
            setPanelProps(obj.hPanelR,obj.iMov.useRot,{obj.hPanelR});
                   
            % ------------------------------ %
            % --- CONTROL BUTTON OBJECTS --- %
            % ------------------------------ %
            
            % initialisations
            bStrC = {'Update','Close'};
            bFcnC = {@obj.updateButton,@obj.closeButton};            
            obj.hButC = cell(length(bStrC),1);
            
            % creates the panel object
            lPosC = 2*obj.dX + obj.widPanel;
            pPosC = [lPosC,obj.dX,obj.widPanel,obj.hghtPanelC];            
            obj.hPanelC = uipanel(obj.hFig,'Title','','Units',...
                                           'Pixels','Position',pPosC);
            
            % creates the control button objects
            for i = 1:length(bStrC)
                % sets up the position vector
                lPosC = i*obj.dX + (i-1)*obj.widButC;
                bPosC = [lPosC,obj.dX-2,obj.widButC,obj.hghtBut];

                % creates the button
                obj.hButC{i} = uicontrol(obj.hPanelC,...
                        'Style','PushButton','String',bStrC{i},...
                        'Callback',bFcnC{i},'FontWeight','Bold',...
                        'FontUnits','Pixels','FontSize',obj.fSz,...
                        'Units','Pixels','Position',bPosC);
                setObjEnable(obj.hButC{i},i>1);
            end
            
            % --------------------------------------- %
            % --- ACTIVITY CLASSIFICATION OBJECTS --- %
            % --------------------------------------- %
            
            % initialisations
            tStrP = 'ACTIVITY CLASSIFICATION PARAMETERS';
            
            % sets up the panel object
            yPosP = sum(pPosC([2,4]))+obj.dX;
            pPosP = [pPosC(1),yPosP,obj.widPanel,obj.hghtPanelP];
            obj.hPanelP = uipanel(obj.hFig,'Title',tStrP,'Units',...
                       'Pixels','Position',pPosP,'FontUnits','Pixels',...
                       'FontSize',obj.tSz,'FontWeight','Bold');
                      
            % creates the checkbox object
            cbFcnTC = @obj.useSepCol;
            widChkP = obj.widPanel - 2*obj.dX;
            cStrT = 'Use Separate Colours For Each Fly Marker';
            cPosT = [obj.dX*[1,0.5],widChkP,obj.hghtChk+3];
            obj.hChkP = uicontrol(obj.hPanelP,...
                        'Style','Checkbox','String',cStrT,...
                        'Callback',cbFcnTC,'FontWeight','Bold',...
                        'FontUnits','Pixels','FontSize',obj.fSz,...
                        'Units','Pixels','Position',cPosT,...
                        'Value',obj.iMov.sepCol);
            setObjEnable(obj.hChkP,obj.isMltTrk);
                   
            % creates the table object
            cEdit = [false(1,2),true(1,2)];
            yPosP = sum(cPosT([2,4])) + (obj.dX/2 - 1);
            tPosP = [obj.dX,yPosP,obj.widTableP,obj.hghtTableP];            
            cNames = {'Type','Colour','Marker Type','Marker Size'};
            obj.hTableP = uitable(obj.hPanelP,'Position',tPosP,...
                        'ColumnName',cNames,'ColumnEditable',cEdit,...
                        'RowName',[],'FontUnits','Pixels',...
                        'CellEditCallback',@obj.tableParaEdit,...
                        'CellSelectionCallback',@obj.tableParaSelect,...                        
                        'FontSize',obj.eSz);            
                    
            % -------------------------------- %
            % --- HOUSE-KEEPING OPERATIONS --- %
            % -------------------------------- %            
                        
            % initialises the classification table parameters        
            obj.initClassificationTable();
            obj.initAlgoTypePopup();
            
            % centers the figure and makes it visible
            centreFigPosition(obj.hFig,2);
            setObjVisibility(obj.hFig,1);
            
        end     
        
        % --- initialises the classifiction parameter table
        function initClassificationTable(obj)
            
            % initialisations
            Data = cell(4);
            fStr = {'pCol','pMark','mSz'};            
            cStr = {'pNC','pMov','pStat','pRej'};
            mSym = {'o','+','*','.','x','s','d'};
            mName = {'Circle','Plus','Asterisk','Point',...
                     'Cross','Square','Diamond'};
            
            % sets the classification parameters (based on the os type)
            if ispc
                % case is using PC
                cPara = obj.trkP.PC;
            else
                % case is using Mac
                cPara = obj.trkP.Mac;
            end

            % sets the table data            
            Data(:,1) = {'Non-Classified','Moving','Stationary','Rejected'};
            for i = 1:length(cStr)
                for j = 1:length(fStr)
                    % sets the parameter string
                    pStr = getStructField(cPara,cStr{i},fStr{j});

                    % sets the data field based on the parameter type
                    switch (fStr{j})
                        case ('pCol') 
                            % case is the classification colour
                            colStr = rgb2hex(pStr);
                            Data{i,j+1} = obj.setCellColourString(colStr);
                        
                        case ('pMark') 
                            % case is the fly marker type
                            Data{i,j+1} = mName{strcmp(mSym,pStr)};
                        
                        case ('mSz') 
                            % case is the fly marker size
                            Data{i,j+1} = pStr;
                    end

                end
            end            
            
            % sets the table parameters
            cForm = {'char','char',mName,'numeric'};
            set(obj.hTableP,'ColumnFormat',cForm,'Data',Data)
            autoResizeTableColumns(obj.hTableP);
            
        end
        
        % --- initialises the tracking algorithm type
        function initAlgoTypePopup(obj)
            
            % field setup
            uType = {'bgs-single';'dd-single'};            
            pStr = {'Single Fly (BG Subtraction)';...
                    'Single Fly (Direct Detection)'};
            
            % sets the popup-strings
            set(obj.hPopT,'String',pStr,'UserData',uType);
            feval('runExternPackage','MultiTrack',obj);            
                
            % sets the algorithm type popup list index
            uType = get(obj.hPopT,'UserData');
            iSel = find(strcmp(uType,obj.iMov.bgP.algoType));
            set(obj.hPopT,'Value',iSel)                
            
        end

        % --------------------------------------------- %
        % --- TRACKING PARAMETER CALLBACK FUNCTIONS --- %
        % --------------------------------------------- %
        
        % --- orientation angle checkbox callback function
        function checkCalcAngle(obj,hObj,~)
            
            % field retrieval
            if get(hObj,'Value')
                % determines if there is any currently tracked data
                if ~isempty(obj.hFigM.pData) || ...
                                            initDetectCompleted(obj.iMov)
                    % if so, then prompt the user if they wish to clear 
                    tStr = 'Clear Tracked Data?';
                    qStr = {['This action will clear the currently ',...
                            'tracked data.'];'';...
                            'Do you still wish to continue?'};
                    uChoice = questdlg(qStr,tStr,'Yes','No','Yes');                    
                    if ~strcmp(uChoice,'Yes')
                        % if not, then reset the checkbox and exit
                        set(hObj,'value',~get(hObj,'value'))
                        return
                    else
                        % otherwise, clear the tracked data/bg estimates
                        [obj.iMov.Ibg,obj.hFigM.pData] = deal([]);

                        % removes the markers (if they are visible)
                        if get(obj.hGUIM.checkShowMark,'value')
                            set(obj.hGUIM.checkShowMark,'value',0)
                            obj.showMarkFcn([],[],obj.hGUIM)
                        end

                        % disables the relevant objects
                        setObjEnable(obj.hGUIM.buttonDetectFly,'off') 
                        setObjEnable(obj.hGUIM.checkShowMark,'off')
                    end
                end
            else
                % removes the orientation angle fields
                if isfield(obj.hFigM.pData,'Phi')
                    % if so, then prompt the user if they wish to clear the data
                    qStr = {['This action will clear the currently tracked ',...
                             'orientation data.'];'';'Do you still wish to continue?'};
                    uChoice = questdlg(qStr,'Clear Tracked Data?',...
                                        'Yes','No','Yes');
                    if ~strcmp(uChoice,'Yes')      
                        % if not, then reset the checkbox and exit
                        set(hObj,'value',~get(hObj,'value'))
                        return            
                    else
                        % removes the orientation data fields
                        fStr = {'Phi','PhiF','axR','NszB'};
                        for i = 1:length(fStr)
                            if isfield(obj.hFigM.pData,fStr{i})
                                obj.hFigM.pData = ...
                                        rmfield(obj.hFigM.pData,fStr{i});
                            end
                        end

                        % removes the fields from the data struct
                        if isfield(obj.iMov,'NszP')
                            obj.iMov = rmfield(obj.iMov,'NszP'); 
                        end

                        % removes the markers (if they are visible)
                        if get(obj.hGUIM.checkShowAngle,'value')
                            set(obj.hGUIM.checkShowAngle,'value',0)                              
                            obj.showAngleFcn([],[],obj.hGUIM)
                        end            

                        % disables the relevant checkboxes                   
                        setObjEnable(obj.hGUIM.checkShowAngle,'off')         
                    end
                end
                
                % flag that the orientation calculations are not required
                obj.hFigM.pData.calcPhi = false;                
            end
            
            % updates the flag            
            setObjEnable(obj.hButC{1},1);            
            [obj.trkP.calcPhi,obj.iMov.calcPhi] = deal(get(hObj,'Value'));
            
        end
        
        % --- orientation angle checkbox callback function
        function checkUseRot(obj,hObj,~)
            
            % global variables
            global frmSz0
                        
            % removes the division figure
            obj.hFigM.rgObj.removeDivisionFigure();
            
            % sets the rotation flag value
            obj.iMov.useRot = get(hObj,'value');
            setPanelProps(obj.hPanelR,obj.iMov.useRot);
            
            % if the guide markers are present, then remove them
            if get(obj.hButR,'value')
                set(obj.hButR,'value',0)
                obj.useGuide(obj.hButR,[]);
            end
            
            % updates the frame size
            isRot90 = detIfRotImage(obj.iMov);
            if isRot90
                % case is the frame is rotated
                frmSz = flip(frmSz0);
            else
                % case is the frame is not rotated
                frmSz = frmSz0;
            end
            
            % rotates the region markers (if set)
            if obj.iMov.isSet
                obj.updateRegionMarkers(isRot90,frmSz);
            end
            
            % rotates the positional data (if calculated)
            if ~isempty(obj.hFigM.pData) && isfield(obj.hFigM.pData,'fPos')
                obj.rotatePosData(isRot90);
            end
            
            % updates the data structs in the main GUI
            obj.hFigM.iMov = obj.iMov;
            obj.hFigM.iData.sz = frmSz;  
            
            % updates the frame size string
            [m,n] = deal(frmSz(1),frmSz(2));
            dimStr = sprintf('%i %s %i',m,char(215),n);
            set(obj.hGUIM.textFrameSizeS,'string',dimStr);
            
            % initialises the tracking marker objects 
            if get(obj.hGUIM.checkSubRegions,'value')
                obj.hFigM.mkObj.initTrackMarkers()
            else
                obj.hFigM.mkObj.initTrackMarkers(1)
            end
            
            % updates the main image
            if obj.isCalib
                ImgR = getRotatedImage(obj.iMov,obj.Img0);
                feval(obj.dispImage,obj.hGUIM,ImgR,1)
            else
                feval(obj.dispImage,obj.hGUIM)
            end
            
            % shows the sub-regions (if the checkbox is selected)
            if get(obj.hGUIM.checkSubRegions,'value')
                obj.hFigM.rgObj.setupDivisionFigure(true);
            end

            % shows the tube regions (if the checkbox is selected)
            if get(obj.hGUIM.checkShowTube,'value')
                obj.showTubeFcn(obj.hGUIM.checkShowTube,[],obj.hGUIM);
            end      
            
            % enables the update button
            setObjEnable(obj.hButC{1},'on')

            % resizes the tracking GUI objects
            resizeFlyTrackGUI(obj.hFigM,frmSz)
            obj.hFigM.iMov = obj.iMov0;
            
        end        
        
        % --- tracking parameter editbox callback functions
        function editSegPara(obj,hObj,~)
            
            % global parameters
            global frmSz0
            
            % field retrieval
            uD = get(hObj,'UserData');
            isTrk = ~isfield(obj.iMov,uD) || strcmp(uD,'nPath');
            
            % sets the parameter field (based on which struct it belongs to)
            if isTrk
                pStr = sprintf('obj.trkP.%s',uD);
            else
                pStr = sprintf('obj.iMov.%s',uD);
            end           
            
            % retrieves the parameter string and the new value/limits
            nwVal = str2double(get(hObj,'string'));
            [nwLim,isInt] = obj.setParaLimits(uD);
            
            % checks to see if the new value is valid
            if chkEditValue(nwVal,nwLim,isInt)
                % if so, then update the parameter field and struct
                eval(sprintf('%s = nwVal;',pStr));
                setObjEnable(obj.hButC{1},'on')

                % updates the other fields (based on type)
                if strcmp(uD,'rotPhi')
                    % retains a copy of the original sub-region data struct from
                    % the main Fly Tracking GUI
                    iMovTmp = obj.hFigM.iMov;
                    obj.hFigM.iMov = obj.iMov;

                    % updates the frame size
                    if detIfRotImage(obj.iMov)
                        % case is the frame is rotated
                        frmSz = flip(frmSz0);
                    else
                        % case is the frame is not rotated
                        frmSz = frmSz0;
                    end            

                    % if the guide markers are present, then remove them
                    if get(obj.hButR,'value')
                        set(obj.hButR,'value',0)
                        obj.useGuide(obj.hButR,[]);
                    end            

                    % runs the image update function and reset the sub-region data
                    % struct
                    if obj.isCalib
                        ImgT = getRotatedImage(obj.iMov,obj.Img0);
                        feval(obj.dispImage,obj.hGUIM,ImgT,1) 
                    else
                        feval(obj.dispImage,obj.hGUIM) 
                    end

                    % resizes the image and the sub-region data struct
                    resizeFlyTrackGUI(obj.hFigM,frmSz)
                    obj.hFigM.iMov = iMovTmp;
                end
            else
                % otherwise, revert back to the previous valid value
                set(hObj,'string',num2str(eval(pStr)))
            end   
            
        end
        
        % --- algorithm type popupmenu callback function
        function popupAlgoType(obj,hObj,~)
            
            % retrieves the segmentation parameters
            uList = get(hObj,'UserData');
            algoType = uList{get(hObj,'Value')};

            % sets the algorithm type popup list index
            obj.iMov.bgP.algoType = algoType;
            obj.resetPData = true;
            
            % sets the enabled properties of the separation checkbox (only valid if the
            % user is using multi-tracking)
            setObjEnable(obj.hChkP,strContains(algoType,'multi'))
            setObjEnable(obj.hButC{1},'on')
            
        end
        
        % --------------------------------------------- %
        % --- ROTATION PARAMETER CALLBACK FUNCTIONS --- %
        % --------------------------------------------- %        
        
        % --- use guide toggle button callback function
        function useGuide(obj,hObj,~)

            % adds/removes the guide markers based on the toggle button value
            if get(hObj,'Value')
                % sets up the gui markers for the main GUI                
                obj.setupGuideMarkers()
            else
                % removes all guide markers from the main GUI
                obj.removeGuideMarkers()
            end            
            
        end                
        
        % -------------------------------------------------- %
        % --- ACTIVITY CLASSIFICATION CALLBACK FUNCTIONS --- %
        % -------------------------------------------------- %
        
        % --- parameter table cell selection callback function/
        function tableParaSelect(obj,hObj,evnt)
            
            % if no indices are provided, then exit the function
            if isempty(evnt.Indices)
                return; 
            else
                % sets the row/column indices (if colour column not
                % selected then exit the function)
                [iRow,iCol] = deal(evnt.Indices(1),evnt.Indices(2));
                if iCol ~= 2; return; end    
            end
            
            % retrieves the segmentation parameters            
            cStr = {'pNC','pMov','pStat','pRej'};
            
            % prompts the user for the new colour
            nwCol = uisetcolor;
            if (length(nwCol) > 1)
                % sets the classification parameters (based on the operating system type)
                if ispc
                    % case is using PC
                    [mMark,osStr] = deal(obj.trkP.PC,'PC');                
                else
                    % case is using Mac
                    [mMark,osStr] = deal(obj.trkP.Mac,'Mac');
                end    

                % determines if the colour has already been set for another marker
                pC0 = {mMark.pNC.pCol;mMark.pMov.pCol;...
                       mMark.pStat.pCol;mMark.pRej.pCol};
                if any(cellfun(@(x)...
                            (isequal(x,nwCol)),pC0((1:length(pC0)~=iRow))))
                    % if so, then output an error
                    tStr = 'Duplicate Classification Colours';
                    eStr = 'Error! Classification colour is already in use';
                    waitfor(errordlg(eStr,tStr,'modal'))
                else           
                    % otherwise, update the parameter value                    
                    eval(sprintf('obj.trkP.%s.%s.pCol = nwCol;',...
                                                        osStr,cStr{iRow}))

                    % updates the table
                    Data = get(hObj,'Data');
                    Data{iRow,iCol} = ...
                            obj.setCellColourString(rgb2hex(nwCol));
                    set(hObj,'Data',Data)

                    % updates the parameter struct
                    setObjEnable(obj.hButC{1},'on')
                end
            end            
            
        end
        
        % --- parameter table cell edit callback function
        function tableParaEdit(obj,hObj,evnt)
            
            % if no indices are provided, then exit the function
            if isempty(evnt.Indices)
                return; 
            else
                % sets the row/column indices (if colour column is
                % editted then exit the function)
                [iRow,iCol] = deal(evnt.Indices(1),evnt.Indices(2));
                if iCol == 2; return; end    
            end            
            
            % initialisations
            fStr = {'','','pMark','mSz'};
            cStr = {'pNC','pMov','pStat','pRej'};
            
            % sets the parameter string (based on the operating system)
            if ispc
                % case is using PC
                pStr = sprintf('obj.trkP.PC.%s.%s',cStr{iRow},fStr{iCol});
            else
                % case is using Mac
                pStr = sprintf('obj.trkP.Mac.%s.%s',cStr{iRow},fStr{iCol});
            end    
            
            % sets the parameter based on the type
            if iCol == 4
                % determines if the new value is valid
                nwVal = evnt.NewData;    
                if chkEditValue(nwVal,obj.setParaLimits('mSz'),1)
                    % updates the parameter values
                    eval(sprintf('%s = nwVal;',pStr));
                else
                    % resets the data within the table to the previous valid value
                    Data = get(hObj,'Data');
                    Data{iRow,iCol} = eval(pStr);
                    set(hObj,'Data',Data)

                    % exits the function
                    return
                end
            else
                % sets the marker name/symbol
                mSym = {'o','+','*','.','x','s','d'};
                mName = {'Circle','Plus','Asterisk',...
                         'Point','Cross','Square','Diamond'};   

                % sets the field value (based on the operating system type)
                eval(sprintf('%s = mSym{strcmp(mName,evnt.NewData)};',pStr))
            end
            
            % enables the update button
            setObjEnable(obj.hButC{1},'on')
            
        end        
        
        % --- colour separation checkbox callback function
        function useSepCol(obj,hObj,~)
            
            % updates the separation colour flag
            obj.iMov.sepCol = get(hObj,'value');
            setObjEnable(obj.hButC{1},'on')
            
        end        
        
        % ----------------------------------------- %
        % --- CONTROL BUTTON CALLBACK FUNCTIONS --- %
        % ----------------------------------------- %
        
        % --- update button callback function
        function updateButton(obj,hObj,~)
            
            % removes the video phase field (if resetting and is set)
            if obj.resetPData
                if isfield(obj.iMov,'vPhase')
                    obj.iMov = rmfield(obj.iMov,'vPhase');
                end
            end            
            
            % if the positional data needs to be updated, then prompt the 
            % user one more time if they still want to update the 
            % parameters. if not, then exit
            if obj.resetPData && ~isempty(get(obj.hFigM,'pData'))
                tStr = 'Continue Parameter Update?';
                uChoice = questdlg(['The action will clear any stored ',...
                                    'position data. Do you still want ',...
                                    'to continue updating?'],tStr,...
                                    'Yes','No','Yes');
                if strcmp(uChoice,'Yes')   
                    % clears the position data field and reset the
                    % sub-region data struct field
                    obj.hFigM.pData = [];
                    obj.iMov.isSet = false;
                    obj.hFigM.iMov.isSet = false;                    
                    
                    % retrieves the detection checkbox handles
                    hPanelI = obj.hGUIM.panelAppInfo;                    
                    hPanelD = obj.hGUIM.panelFlyDetect;
                    hCheck = [findall(hPanelD,'style','checkbox');...
                              findall(hPanelI,'style','checkbox')];                    
                          
                    % removes all detection markers from the main GUI
                    for i = 1:length(hCheck)
                        % if the checkbox is selected, then deselect and
                        % run the callback function
                        if get(hCheck(i),'Value')
                            set(hCheck(i),'Value',0)
                            cbFcn = get(hCheck(i),'Callback');
                            feval(cbFcn,hCheck(i),[])
                        end                        
                    end
                    
                    % disables the associated main gui properties
                    setPanelProps(hPanelI,'off',1)
                    setPanelProps(hPanelD,'off',1)
                    setObjEnable(obj.hGUIM.buttonDetectBackground,0);                    
                else
                    return
                end
            end            
            
            % updates the sub-region data struct into the main GUI
            obj.hFigM.iMov = obj.iMov;
            obj.hFigM.iMov.nPath = obj.trkP.nPath;            
            
            % updates the parameter file
            A = load(obj.pFile);
            [A.bgP.algoType,A.trkP] = deal(obj.iMov.bgP.algoType,obj.trkP);
            save(obj.pFile,'-struct','A');    
            
            % disables the update button
            setObjEnable(hObj,'off')
            
            % updates the checkbox values
            hChk = {obj.hGUIM.checkShowMark};
            for i = 1:length(hChk)
                set(hChk{i},'value',strcmp(get(hChk{i},'enable'),'on'))
            end            
            
            % deletes the existing tracking markers
            obj.hFigM.mkObj.deleteTrackMarkers()
            
            % creates the tracking marker class object
            if detMltTrkStatus(obj.iMov)
                obj.hFigM.mkObj = MultiTrackMarkerClass(obj.hFigM,obj.hAxM);
            else
                obj.hFigM.mkObj = TrackMarkerClass(obj.hFigM,obj.hAxM);    
            end
            
            % deletes/re-adds the markers                            
            obj.hFigM.mkObj.initTrackMarkers()
            obj.hFigM.mkObj.updateTrackMarkers(true);
            
        end
        
        % --- close button callback function
        function closeButton(obj,~,~)
            
            % prompts the user if they want to update (if change made)
            if strcmp(get(obj.hButC{1},'Enable'),'on')                
                tStr = 'Update Tracking GUI Parameters?';
                qStr = 'Do you want to update the tracking parameters?';
                uChoice = questdlg(qStr,tStr,'Yes','No','Cancel','Yes');
                
                switch uChoice
                    case ('Yes') 
                        % case is the user chose to update the parameters
                        obj.updateButton();
                        buttonUpdate_Callback(handles.buttonUpdate, '1', handles) 

                    case ('No') 
                        % case is the user to not update the parameters
                        obj.hFigM.iMov = obj.iMov0;

                        % resets the main GUI image
                        set(obj.hChkT{2},'Value',obj.iMov0.useRot);
                        obj.checkUseRot(obj.hChkT{2},[]);

                    case ('Cancel') 
                        % case is the user cancelled
                        return
                end                
            end
            
            % removes any guide markers and closes the GUI
            obj.removeGuideMarkers();            
            delete(obj.hFig)
            
        end                
        
        % --------------------------------------- %
        % --- ROTATION GUIDE MARKER FUNCTIONS --- %
        % --------------------------------------- %        
        
        % --- sets up the rotation guide markers on the main GUI axes
        function setupGuideMarkers(obj)

            % parameters
            yOfs = 15;
            mStr = 'Draw an initial line along the landmark feature.';
        
            % prompts the user to place the initial line on the main image
            axes(obj.hAxM)
            waitfor(msgbox(mStr,'','modal'))
            hLine = InteractObj('line',obj.hAxM);

            % retrieves the dimensions of the set line and deletes it
            lPos0 = hLine.getPosition();
            hLine.deleteObj();

            % sets the start/end points of the set line (sorts the points from L-to-R)
            [xP,iS] = sort(lPos0(:,1));
            yP = lPos0(iS,2);

            % sets up the angle text object
            obj.hAngle = text(xP(1),yP(1)+yOfs,'0');
            set(obj.hAngle,'fontweight','bold','color','r','BackgroundColor','w',...
                       'tag','hAngle','fontsize',16,'horizontalalignment','center')

            % creates the horizontal marker
            obj.hGuideH = InteractObj('line',obj.hAxM,{xP,yP(1)*[1;1]});
            obj.hGuideH.setFields('Tag','hGuideH');

            % creates the movable marker marker
            obj.hGuideV = InteractObj('line',obj.hAxM,{xP,yP});
            obj.hGuideV.setFields('Tag','hGuideV');

            % sets the guide line properties
            obj.setupGuideProps(obj.hGuideH,1)
            obj.setupGuideProps(obj.hGuideV,0)

            % runs the guide marker movement callback function
            obj.hGuideV.setObjMoveCallback(@obj.moveGuide);
            obj.moveGuide([xP,yP]);

        end        
            
        % --- removes the guide marker objects from the main axes
        function removeGuideMarkers(obj)
        
            % resets the update flag
            obj.isUpdating = false;
            
            % retrives the object handles of the guide markers
            hGuide = [findall(obj.hAxM,'tag','hAngle');...
                      findall(obj.hAxM,'tag','hGuideH');...
                      findall(obj.hAxM,'tag','hGuideV')];
            if ~isempty(hGuide)
                % if they exist, then delete them
                delete(hGuide)
            end
            
        end
        
        % ---- guide marker callback function
        function moveGuide(obj,varargin)
                        
            % if updating then exit
            if obj.isUpdating
                return
            else
                obj.isUpdating = true;
            end
            
            % retrieves the vertical line position vector
            switch length(varargin)
                case 1
                    % case is the old format interactive objects
                    pV = varargin{1};
                    
                case 2
                    %
                    pV = varargin{2}.CurrentPosition;
                    
            end
            
            % resets the horizontal line marker
            pH = obj.hGuideH.getPosition();
            pH(2,1) = pV(2,1);
            obj.hGuideH.setPosition(pH)
            
            % updates the vertical line marker guide
            if obj.hGuideV.isOld
                pV(1,:) = pH(1,:);            
                obj.hGuideV.setPosition(pV,1)
            end
            
            % updates the angle text label
            dpV = diff(pV(:,2))/diff(pV(:,1));
            obj.phiRotM = (180/pi)*atan(-dpV);
            set(obj.hAngle,'string',sprintf('%.2f',obj.phiRotM));
            
            % resets the update flag
            setObjEnable(obj.hButC{1},1);
            obj.isUpdating = false;
            
        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- updates the region markers
        function updateRegionMarkers(obj,isRot90,frmSz)
            
            % resets the sub-region parameters
            ii = [2,1,4,3];
            isDetect = initDetectCompleted(obj.iMov);
            [H,W,pDir] = deal(frmSz(1),frmSz(2),1-2*isRot90);                                             
            [obj.iMov.nRow,obj.iMov.nCol] = deal(obj.iMov.nCol,obj.iMov.nRow);
            
            % resets the global outline position    
            obj.iMov.posG = obj.iMov.posG(ii);
            if isRot90        
                obj.iMov.posG(1) = W - sum(obj.iMov.posG([1 3]));        
            else
                obj.iMov.posG(2) = H - sum(obj.iMov.posG([2 4]));
            end                
            
            % permutes the sub-region positional vectors
            obj.iMov.pos = cellfun(@(x)(x(ii)),obj.iMov.pos,'un',0);
            obj.iMov.posO = cellfun(@(x)(x(ii)),obj.iMov.posO,'un',0);
            
            % offsets the positional vectors for the image rotation
            for i = 1:length(obj.iMov.posO)
                if isRot90
                    % case is using the rotated image
                    obj.iMov.pos{i}(1) = W - sum(obj.iMov.pos{i}([1 3]));
                    obj.iMov.posO{i}(1) = W - sum(obj.iMov.posO{i}([1 3]));
                else
                    % case is using the normal image
                    obj.iMov.pos{i}(2) = H - sum(obj.iMov.pos{i}([2 4]));
                    obj.iMov.posO{i}(2) = H - sum(obj.iMov.posO{i}([2 4]));
                end       
            end            
            
            % determines if the background estimate has been calculated
            if isDetect
                % retrieves the current image
                iData = obj.hFigM.iData;
                obj.Img0 = getDispImage(iData,obj.iMov,1,false,obj.hGUIM);

                % sets the composite backgrounds for each phase
                Ibg0 = cell(length(obj.iMov.vPhase),1);
                for i = 1:length(Ibg0)
                    Ibg = obj.iMov.Ibg{i};
                    if ~isempty(Ibg)                        
                        Icomp = createCompositeImage(obj.Img0,obj.iMov,{Ibg});
                        Ibg0{i} = double(rot90(Icomp,pDir));
                    end
                end

                % sets the composite circular regions for each phase
                if obj.is2D
                    B0 = false(size(obj.Img0));
                    Bc0 = rot90(createCompositeImage...
                                    (B0,obj.iMov,obj.iMov.autoP.B),pDir);
                end        
            end     
            
            % updates the x/y-locations of the tube regions
            [iC,iR] = deal(obj.iMov.iR,obj.iMov.iC);            
            [iCT,iRT] = deal(obj.iMov.iRT,obj.iMov.iCT);
            [yTube,xTube] = deal(obj.iMov.xTube,obj.iMov.yTube);            
            
            % offsets the row/column indices and the x/y location of the 
            % turn regions for the rotation
            if isRot90
                % case is using the rotated image
                xTube = cellfun(@(x,y)...
                       (y(3)-x(end:-1:1,[2 1])),xTube,obj.iMov.pos,'un',0);
                iC = cellfun(@(x)(W-x(end:-1:1)),iC,'un',0);

                if iscell(iCT{1})
                    iCT = cellfun(@(x,y)(cellfun(@(yy)((length(x)+1)-...
                               yy(end:-1:1)),y,'un',0)),iC,iCT,'un',0);
                else
                    iCT = cellfun(@(x,y)...
                                ((length(x)+1)-y(end:-1:1)),iC,iCT,'un',0);
                end

                % reverses the column indices
                iCT = cellfun(@(x)(x(end:-1:1)),iCT,'un',0);

            else
                % case is using the normal image
                yTube = cellfun(@(x,y)...
                       (y(4)-x(end:-1:1,[2 1])),yTube,obj.iMov.pos,'un',0);
                iR = cellfun(@(x)(H-x(end:-1:1)),iR,'un',0);

                if iscell(iRT{1})
                    iRT = cellfun(@(x,y)(cellfun(@(yy)((length(x)+1)-...
                                   yy(end:-1:1)),y,'un',0)),iR,iRT,'un',0); 
                else
                    iRT = cellfun(@(x,y)((length(x)+1)-y(end:-1:1)),iR,iRT,'un',0);                     
                end

                % reverses the row indices
                iRT = cellfun(@(x)(x(end:-1:1)),iRT,'un',0);
            end    

            % resets the row/column tube region indices    
            [obj.iMov.xTube,obj.iMov.yTube] = deal(xTube,yTube); 
            [obj.iMov.iC,obj.iMov.iR] = deal(iC,iR); 
            [obj.iMov.iCT,obj.iMov.iRT] = deal(iCT,iRT);

            % determines if the background estimate has been calculated
            if initDetectCompleted(obj.iMov)
                % if so, rotates the background image estimate        
                for i = 1:length(obj.iMov.vPhase)
                    if ~isempty(Ibg0{i})
                        if obj.isMltTrk
                            obj.iMov.Ibg{i} = Ibg0{i};
                        else
                            obj.iMov.Ibg{i} = cellfun...
                                    (@(x,y)(Ibg0{i}(x,y)),iR,iC,'un',0);
                        end
                    end
                end

                % reverses the status/acceptance flags
                N = getSRCount(obj.iMov);
                for i = 1:length(obj.iMov.Status)
                    obj.iMov.Status{i}(1:N) = obj.iMov.Status{i}(N:-1:1);
                    obj.iMov.flyok(1:N,i) = obj.iMov.flyok(N:-1:1,i);
                end        
            end    

            % resets the x/y circle centre locations
            if obj.is2D
                % rotates the search region binary masks
                if isDetect
                    obj.iMov.autoP.B = cellfun(@(x,y)...
                                (Bc0(x,y)),obj.iMov.iR,obj.iMov.iC,'un',0);
                end

                % rotates the circle coordinates
                [XC,YC] = deal(obj.iMov.autoP.YC',obj.iMov.autoP.XC');

                % offsets the x/y coordinates of the circle centers for rotation
                if isRot90
                    % case is using the rotated image
                    XC = W - XC(:,end:-1:1);
                else
                    % case is using the normal image
                    YC = H - YC(:,end:-1:1);
                end

                % updates the x/y coordinates of the circle centres
                [obj.iMov.autoP.XC,obj.iMov.autoP.YC] = deal(XC,YC);
            end            
            
        end
        
        % --- rotates the positional data
        function rotatePosData(obj,isRot90)
            
            % updates the x/y-locations of the tube regions
            pDir = 1-2*isRot90;
            [iC,iR] = deal(obj.iMov.iR,obj.iMov.iC);
            [iCT,iRT] = deal(obj.iMov.iRT,obj.iMov.iCT);
            
            % if so, then set the orientation calculation flag
            if isfield(obj.hFigM.pData,'calcPhi')
                % flag is present, so return the value
                calcPhi = obj.hFigM.pData.calcPhi;
            else
                % no flag is set, so return a false flag
                calcPhi = false;
            end    

            % resets the x/y local/global coordinates
            for i = 1:length(obj.hFigM.pData.fPos)
                % sets a temporary copy of the local/global coordinates
                [x0,y0] = deal(iC{i}(1)-1,iR{i}(1)-1);
                fPosL = cellfun(@(x)...
                           (x(:,[2 1])),obj.hFigM.pData.fPosL{i},'un',0);

                % offsets the x/y coordinates for the rotation
                if isRot90
                    % case is using the rotated image
                    xL = length(iC{i});
                    fPosL = cellfun(@(x)...
                            ([xL-x(:,1),x(:,2)]),fPosL,'un',0);
                    fPos = cellfun(@(x,y)([x(:,1)+x0,...
                             x(:,2)+(y(1)-1)]),fPosL,iRT{i}','un',0);

                else
                    % case is using the normal image
                    yL = length(iR{i});
                    fPosL = cellfun(@(x)([x(:,1),yL-x(:,2)]),fPosL,'un',0);   
                    fPos = cellfun(@(x,y)...
                            ([x(:,1)+(y(1)-1),x(:,2)+y0]),fPosL,iCT{i}','un',0);            
                end

                % updates the local/global coordinates        
                obj.hFigM.pData.fPos{i} = fPos;
                obj.hFigM.pData.fPosL{i} = fPosL;

                % updates the orientation angles (if calculated)
                if calcPhi
                    % REMOVE ME LATER
                    waitfor(msgbox('Check Angle Rotation Calculations!'))

                    obj.hFigM.pData.Phi{i} = cellfun(@(x)(x-pDir*90),...
                                obj.hFigM.pData.Phi{i}(end:-1:1),'un',0);
                    obj.hFigM.pData.PhiF{i} = cellfun(@(x)(x-pDir*90),...
                                obj.hFigM.pData.PhiF{i}(end:-1:1),'un',0);
                end
            end
            
        end
            
    end
   
    % static class methods
    methods (Static)
    
        % --- sets the parameter limits (based on parameter string pStr)
        function [nwLim,isInt] = setParaLimits(pStr)

            % initialisations
            isInt = true;

            % sets the parameter limits
            switch pStr
                % --------------------------------------- %
                % --- GENERAL SEGMENTATION PARAMETERS --- %
                % --------------------------------------- %

                case ('nFrmS')
                    nwLim = [1,inf];

                case ('nPath')
                    nwLim = [1,10000];    

                case ('rotPhi')
                    [nwLim,isInt] = deal([-90,90],false);         

                % ------------------------------------------ %
                % --- ACTIVITY CLASSIFICATION PARAMETERS --- %
                % ------------------------------------------ %       

                case ('mSz')
                    nwLim = [2 20*(1+ispc)];
            end

        end

        % --- sets the cell colour string
        function cellStr = setCellColourString(pHex)

            % creates the colour string
            cellStr = sprintf(['<html><font color="%s"><span style=',...
                    '"background-color:%s;">''aaaaaaaaaaa''</span>',...
                    '</font></html>'],pHex,pHex);

        end

        % --- sets up the properties for the guide markers
        function setupGuideProps(hGuide,isHoriz)

            % sets the constraint function for the rectangle object
            frmSz = getCurrentImageDim();
            hGuide.setColour('r');
            hGuide.setConstraintRegion([0 frmSz(2)],[0 frmSz(1)]);

            % sets the interactive object properties
            if isOldIntObjVer() && isHoriz
                % case is the new interactive object format

                % updates the visibility of the given markers
                hGuideObj = hGuide.hObj;
                hGuideObjBL = findall(hGuideObj,'tag','bottom line');
                set(findall(hGuideObj,'tag','top line'),'hittest','off')
                setObjVisibility(hGuideObjBL,'off')

                % removes the hit-test for the first point
                set(findall(hGuideObj,'tag','end point 1'),'hittest','off')
                set(findall(hGuideObj,'tag','end point 2'),'hittest','off')
            end

        end        
        
    end
    
end