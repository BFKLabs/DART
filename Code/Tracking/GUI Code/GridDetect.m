classdef GridDetect < matlab.mixin.SetGet
    
    % class properties
    properties
        % main class objects
        hAx
        hFig
        hFigM
        hFigTrk
        trkObj
        iMov
        Img0
        hImg
        
        % filter parameter object handles        
        hPanelF
        hCheckF
        hTxtF
        hEditF
        
        % automatic detection object handles
        hPanelD
        hTxtP
        hTxtD
        hEditD
        hButD
        hSelS
        
        % control button object handles
        hPanelC
        hButC      
        
        % object dimensions
        dX = 10;
        hghtBut = 25;
        hghtEdit = 22;
        hghtCheck = 22;
        hghtTxt = 16;
        widCheckF = 150;
        widTxtF = 65;
        widEditF = 40;
        widButC = 85;
        widButD = 130;
        widPanel = 280;
        widTxtP = 210;
        widTxtS = [90,115];
        widEditS = 25;
        hghtPanelC = 40;
        hghtPanelD = 90;
        
        % other fields
        isSet
        iFlag = 1;
        iSelS = [1,1];  
        isClosing = false;
        
    end
    
    % class methods
    methods
        
        % class constructor
        function obj = GridDetect(hFigM)
           
            % sets the input parameters
            obj.hFigM = hFigM;
            
            % sets up the class objects and callback functions
            obj.initObjProps();                        
            
        end
        
        % --------------------------------------- %
        % --- OBJECT INITIALISATION FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- initialises the gui object properties
        function initObjProps(obj)
            
            % retrieves the main image
            obj.hFigTrk = findall(0,'tag','figFlyTrack');
            obj.hAx = findall(obj.hFigTrk,'type','axes');
            obj.hImg = findall(obj.hAx,'type','image');
            obj.Img0 = double(get(obj.hImg,'CData'));
            
            % sets the region set flag
            obj.iMov = obj.hFigM.iMov;
            obj.isSet = ~isempty(obj.iMov.iR);
            
            % deletes any existing grid detection guis
            hFigPr = findall(0,'tag','figGridDetect');
            if ~isempty(hFigPr); delete(hFigPr); end
            
            % sets the grid object into the region config GUI
            set(obj.hFigM,'gridObj',obj)
            
            % -------------------- %
            % --- FIGURE SETUP --- %
            % -------------------- %
            
            % sets the figure dimensions
            hghtFig = 4*obj.dX + (2*obj.hghtPanelC + obj.hghtPanelD);
            fPos = [200*[1,1],obj.widPanel+2*obj.dX,hghtFig];
            
            % creates the objects
            obj.hFig = figure('Position',fPos,'tag','figGridDetect',...
                              'MenuBar','None','Toolbar','None',...
                              'Name','1D Grid Detection','Resize','off',...
                              'NumberTitle','off','Visible','off');                        
            
            % ---------------------------------- %
            % --- CONTROL BUTTON PANEL SETUP --- %
            % ---------------------------------- %     
            
            % initialisations
            bStrC = {'Detect','Continue','Cancel'};
            bFcnC = {@obj.detectButton,@obj.contButton,@obj.cancelButton};            
            
            % creates the panel object
            pPosC = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelC];
            obj.hPanelC = uipanel(obj.hFig,'Title','','Units','Pixels',...
                                           'Position',pPosC);
                                       
            % button object setup
            obj.hButC = cell(length(bStrC),1);
            for i = 1:length(bStrC)
                x0 = obj.dX+(i-1)*obj.widButC - (2-4*(i-1));
                tagStr = sprintf('button%s',bStrC{i});
                bPos = [x0,8,obj.widButC,obj.hghtBut];
                obj.hButC{i} = uicontrol(obj.hPanelC,'Style','pushbutton',...
                            'Position',bPos,'Tag',tagStr,'Callback',...
                            bFcnC{i},'FontUnits','Pixels','FontSize',12,...
                            'FontWeight','bold','String',bStrC{i},...
                            'UserData',i,'ForegroundColor','k');
            end                                       
                                       
            % disables the continue button
            setObjEnable(obj.hButC{2},'off');
            
            % --------------------------------------- %
            % --- DETECTION PARAMETER PANEL SETUP --- %
            % --------------------------------------- %               
            
            % initialisations
            bStrD = {'Move Region Down','Move Region Up'};
            eStrD = {'Selected Row: ','Selected Column: '};
            bFcnD = @obj.moveButton;            
            eFcnD = @obj.editSelect;
            
            % creates the panel object
            y0D = 2*obj.dX + obj.hghtPanelC;
            pPosD = [obj.dX,y0D,obj.widPanel,obj.hghtPanelD];
            obj.hPanelD = uipanel(obj.hFig,'Title','','Units','Pixels',...
                                           'Position',pPosD);            
            
            % button object setup
            obj.hButD = cell(length(bStrD),1);
            for i = 1:length(bStrD)
                x0 = obj.dX+(i-1)*obj.widButD - (2-4*(i-1));
                bPos = [x0,8,obj.widButD,obj.hghtBut];
                obj.hButD{i} = uicontrol(obj.hPanelD,'Style','pushbutton',...
                            'Position',bPos,'Callback',bFcnD,'FontUnits',...
                            'Pixels','FontSize',12,'FontWeight','bold',...
                            'String',bStrD{i},'UserData',i);
            end     
            
            % creates the row/column selection objects
            y0Edit = 4*obj.dX;
            [obj.hEditD,obj.hTxtD] = deal(cell(length(eStrD),1));
            for i = 1:length(eStrD)
                % creates the text object
                x0 = obj.dX+(i-1)*obj.widEditS+sum(obj.widTxtS(1:(i-1)));
                tPosNw = [x0,y0Edit,obj.widTxtS(i),obj.hghtTxt];
                obj.hTxtD{i} = uicontrol(obj.hPanelD,'Style','text',...
                        'Position',tPosNw,'FontUnits','Pixels','FontSize',...
                        12,'FontWeight','bold','String',eStrD{i},...
                        'HorizontalAlignment','right');
                
                % creates the edit boxes
                x0 = x0 + obj.widTxtS(i);
                ePosNw = [x0,y0Edit-2,obj.widEditS,obj.hghtEdit];
                obj.hEditD{i} = uicontrol(obj.hPanelD,'Style','edit',...
                        'Position',ePosNw,'Callback',eFcnD,'UserData',i,...
                        'String','1');
            end
            
            % creates the period text label field
            y0Txt = 65;
            eStrP = 'Sub-Region Spacing Size (Pixels): ';
            tPosPL = [obj.dX,y0Txt,obj.widTxtP,obj.hghtTxt];
            uicontrol(obj.hPanelD,'Style','text',...
                    'Position',tPosPL,'FontUnits','Pixels','FontSize',...
                    12,'FontWeight','bold','String',eStrP,...
                    'HorizontalAlignment','right');            
            
            % creates the period text field
            tPosP = [obj.dX+obj.widTxtP,y0Txt,obj.widEditF,obj.hghtTxt];
            obj.hTxtP = uicontrol(obj.hPanelD,'Style','text',...
                    'Position',tPosP,'FontUnits','Pixels','FontSize',...
                    12,'FontWeight','bold','String','N/A',...
                    'HorizontalAlignment','left');
                     
            % disables the panel (if the regions are not set)
            setPanelProps(obj.hPanelD,obj.isSet);
                
            % ----------------------------- %
            % --- PARAMETER PANEL SETUP --- %
            % ----------------------------- %    
                        
            % creates the panel object
            y0F = y0D + obj.dX + obj.hghtPanelD;
            pPosF = [obj.dX,y0F,obj.widPanel,obj.hghtPanelC];
            obj.hPanelF = uipanel(obj.hFig,'Title','','Units','Pixels',...
                                           'Position',pPosF);
            
            % creates the checkbox object
            chkStr = 'Use Image Smoothing';
            chkPos = [obj.dX,obj.dX-2,obj.widCheckF,obj.hghtCheck];
            obj.hCheckF = uicontrol(obj.hPanelF,'Units','Pixels',...
                                'Position',chkPos,'FontWeight','Bold',...
                                'FontUnits','pixels','Style','Checkbox',...
                                'FontSize',12,'String',chkStr,...
                                'Callback',@obj.useFilter,...
                                'Value',obj.getFiltPara('useFilt'));
                            
            % creates the period text label field
            x0Txt = 165;
            eStrP = 'Filter Size: ';
            tPosFL = [x0Txt,obj.dX,obj.widTxtF,obj.hghtTxt];
            uicontrol(obj.hPanelF,'Style','text',...
                    'Position',tPosFL,'FontUnits','Pixels','FontSize',...
                    12,'FontWeight','bold','String',eStrP,...
                    'HorizontalAlignment','right');
                
            % creates the edit boxes
            x0Edit = 230;
            eFcnF = @obj.editFilter;
            ePosNw = [x0Edit,obj.dX-2,obj.widEditF,obj.hghtEdit];
            obj.hEditF = uicontrol(obj.hPanelF,'Style','edit',...
                    'Position',ePosNw,'Callback',eFcnF,...
                    'String',num2str(obj.getFiltPara('hSz')));                
            
            % --------------------- %
            % --- HOUSE-KEEPING --- %
            % --------------------- %                  
                
            % updates the move button enabled properties
            obj.updateMoveEnableProps();            
            
            % makes the gui visible
            setObjVisibility(obj.hFig,1);
            obj.useFilter(obj.hCheckF,[])  
            setPanelProps(obj.hPanelD,'off')
            
            % sets up the sub-regions
            obj.hFigM.rgObj.setupRegionConfig(obj.iMov,1,1);
            
            % turns on the region highlight
            obj.hSelS = findobj(obj.hAx,'tag','hInner','UserData',1);
            if obj.isSet; obj.setRegionHighlight('on'); end
            
            % repositions the sub-GUI
            repositionSubGUI(obj.hFigM,obj.hFig)
            
            % resumes the figure
            uiwait(obj.hFig);                
                
        end

        % -------------------------- %
        % --- CALLBACK FUNCTIONS --- %
        % -------------------------- %    

        % --- use filter callback function
        function useFilter(obj,hObj,event)
            
            % updates the parameter value
            useFilt = get(hObj,'Value');
            obj.setFiltPara('useFilt',useFilt);
            setObjEnable(obj.hButC{1},'on');
            
            % updates the detection panel properties
            setObjEnable([obj.hEditF,obj.hTxtF],useFilt)
            if ~isempty(event)
                set(obj.hFigM,'phObj',[]);
            end
            
            % updates the main image
            obj.updateMainImage()
            
        end
        
        % --- filter size callback function
        function editFilter(obj,hObj,~)
            
            % determines if the new value is valid
            nwVal = str2double(get(hObj,'String'));
            if chkEditValue(nwVal,[1,10],1)
                % if so, then update the field value
                obj.setFiltPara('hSz',nwVal);                
                setObjEnable(obj.hButC{1},'on');
                set(obj.hFigM,'phObj',[]);
                
                % updates the main image
                obj.updateMainImage()                
            else
                % resets the parameter value
                set(hObj,'String',num2str(obj.getFiltPara('hSz')));
            end
            
        end        
        
        % --- row/column selection index callback function
        function editSelect(obj,hObj,~)
        
            % initialisations
            iMov0 = obj.hFigM.iMov;
            iType = get(hObj,'UserData');
            nwVal = str2double(get(hObj,'String'));
            
            % sets the limit based on the type
            switch iType
                case 1
                    % case is the selected row 
                    nwLim = [1,iMov0.pInfo.nRow];
                    
                case 2
                    % case is the selected column
                    nwLim = [1,iMov0.pInfo.nCol];
                    
            end
            
            % determines if the new value is valid
            if chkEditValue(nwVal,nwLim,1)
                % if so, update the selection value
                obj.iSelS(iType) = nwVal;
                
                % updates the move button enabled properties
                obj.updateRegionHighlight();
                obj.updateMoveEnableProps();
                
            else
                % otherwise, reset to the previous valid value
                set(hObj,'String',num2str(obj.iSelS(iType)));
            end
        
        end
        
        % --- region move up/down button callback function
        function moveButton(obj,hObj,~)            
            
            % initialisations
            iApp = obj.getRegionIndex();     
            yMax = obj.iMov.posO{iApp}(4); 
            [nRow,nCol] = deal(obj.iMov.pInfo.nRow,obj.iMov.pInfo.nCol);
            
            % calculates the change in the vertical location
            yDir = 3 - 2*get(hObj,'UserData');
            dY = roundP(median(cellfun(@length,obj.iMov.iRT{iApp})));
            obj.iMov.pos{iApp}(2) = obj.iMov.pos{iApp}(2) + yDir*dY;            
            obj.iMov.iR{iApp} = min(yMax,max(0,obj.iMov.iR{iApp}+yDir*dY));
            
            % if there is more than one row grouping, then determine if the
            % new configuration is feasible (given the outer coords)
            if nRow > 1
                % if so, then retrieve the row/column indices
                updateOuter = false;
                [iCol,~,iRow] = getRegionIndices(obj.iMov,iApp);                
                if (iRow < nRow) && (yDir == 1)
                    % if moving down (and not the last row) then determine
                    % if the bottom overlaps the outer edge
                    updateOuter = sum(obj.iMov.pos{iApp}([2,4])) > ...
                                  sum(obj.iMov.posO{iApp}([2,4]));
                    
                elseif (iRow > 1) && (yDir == -1)
                    % if moving up (and not the first row) then determine
                    % if the top overlaps the outer edge                    
                    updateOuter = obj.iMov.pos{iApp}(2) < 0;
                end
                
                % updates the outer regions (if required)
                if updateOuter
                    uD = [iRow+(yDir==1),iCol];
                    hHorz = findall(obj.hAx,'tag','hHorz','UserData',uD);
                    apiH = iptgetapi(hHorz);
                    lPos = apiH.getPosition();
                    
                    % recalculates
                    iAppC = iApp + yDir*nCol;
                    if yDir == 1
                        % sets the location of the horizontal marker
                        yH = 0.5*(sum(obj.iMov.pos{iApp}([2,4])) + ...
                                      obj.iMov.pos{iAppC}(2));
                        yH0 = sum(obj.iMov.pos{iAppC}([2,4]));
                                  
                        % resets the region outer limits
                        obj.iMov.posO{iApp}(4) = yH-obj.iMov.posO{iApp}(2);
                        obj.iMov.posO{iAppC}(2) = yH;
                        obj.iMov.posO{iAppC}(4) = yH0-yH;
                        
                    else
                        % sets the location of the horizontal marker
                        yH = 0.5*(sum(obj.iMov.pos{iAppC}([2,4])) + ...
                                      obj.iMov.pos{iApp}(2));   
                        yH0 = sum(obj.iMov.pos{iApp}([2,4]));
                        
                        % resets the region outer limits
                        obj.iMov.posO{iAppC}(4) = ...
                                            yH-obj.iMov.posO{iAppC}(2);
                        obj.iMov.posO{iApp}(2) = yH;
                        obj.iMov.posO{iApp}(4) = yH0-yH;
                    end
                    
                    % resets the horizontal marker location
                    lPos(:,2) = yH;
                    obj.hFigM.rgObj.isUpdating = true;
                    apiH.setPosition(lPos); pause(0.05);
                    obj.hFigM.rgObj.isUpdating = false;
                end
            end            
            
            % updates the region grid position vector
            hInner = findall(obj.hAx,'tag','hInner','UserData',iApp);
            hAPI = iptgetapi(hInner);
            hAPI.setPosition(obj.iMov.pos{iApp});
            
            % updates the ROI coordinates
            obj.hFigM.rgObj.roiCallback(obj.iMov.pos{iApp},iApp);
            
            % updates the move button enabled properties
            setObjEnable(obj.hButC{2},'on')
            obj.updateMoveEnableProps();
            
        end        
        
        % --- automatic detection callback function
        function detectButton(obj,hObj,~)
            
            % resumes the figure
            obj.iFlag = get(hObj,'UserData');
            setObjVisibility(obj.hFig,'off');  
            
            % turns off the selection
            obj.setRegionHighlight('off');            
            
            % disables the button            
            setObjEnable(hObj,false);        
            uiresume(obj.hFig);
            
        end        
            
        % --- continue callback function
        function contButton(obj,hObj,~)
            
            % updates the status flag/callback function
            obj.iFlag = get(hObj,'UserData');
            set(obj.hFigTrk,'WindowButtonDownFcn',[])
            
            % flag that the calculations were successful            
            uiresume(obj.hFig);
            obj.closeGUI();            
            
        end
            
        % --- cancel callback function
        function cancelButton(obj,hObj,~)
            
            % flag that the calculations were unsuccessful
            obj.iFlag = get(hObj,'UserData');
            set(obj.hFigTrk,'WindowButtonDownFcn',[])
            
            % flag that the calculations were successful 
            uiresume(obj.hFig);
            obj.closeGUI();
            
        end
        
        % --- performs the post detection check
        function checkDetectedSoln(obj,iMovNw,trkObjNw)
            
            % creates a progress loadbar
            h = ProgressLoadbar('Setting Final Region Configuration'); 
            pause(0.05);
            
            % sets the incoming fields
            obj.isSet = true;
            [obj.trkObj,obj.iMov] = deal(trkObjNw,iMovNw);
            tPer = roundP(median(trkObjNw.tPerS,'omitnan'));
            
            % enables the detection parameter panel and continue button
            setPanelProps(obj.hPanelD,'on');
            set(obj.hButC{2},'enable','on','ForegroundColor','k')
            set(obj.hTxtP,'String',num2str(tPer));
            
            % sets up the sub-regions
            obj.hFigM.rgObj.setupRegionConfig(iMovNw,1,1);
            
            % removes the hit-test of the inner regions            
            hInner = findall(obj.hAx,'tag','hInner');
            if ~isempty(hInner)
                arrayfun(@(x)(set(findall(x),'HitTest','off')),hInner)
            end
            
            % finds the new inner region object and turns on the highlight
            iApp = obj.getRegionIndex();
            obj.hSelS = findobj(obj.hAx,'tag','hInner','UserData',iApp);
            obj.setRegionHighlight('on');  
            
            % updates the move button enabled properties
            obj.updateMoveEnableProps();
            set(obj.hFigTrk,'WindowButtonDownFcn',@obj.trackAxesClick)
            
            % deletes the loadbar
            delete(h);
            
            % pauses the process
            setObjVisibility(obj.hFig,'on');
            uiwait(obj.hFig);
            
        end
        
        % --- callback function for selecting the region axes
        function trackAxesClick(obj,~,~)
            
            % retrieves the current mouse click coordinates
            mPos = get(obj.hFigTrk,'CurrentPoint');
            
            % determines if the 
            if isOverAxes(mPos,obj.hFigM.axPosX,obj.hFigM.axPosY)
                % determines the plot objects the mouse is currently over
                mStr = {'tag','hInner'};
                hInner = findAxesHoverObjects(obj.hFigTrk,mStr,obj.hAx);  
                if ~isempty(hInner)
                    % recalculates the selected row/columns
                    nCol = obj.iMov.pInfo.nCol;
                    iApp = get(hInner,'UserData');                   
                    obj.iSelS = [floor((iApp-1)/nCol)+1,mod(iApp-1,nCol)+1];
                    
                    % resets the gui/axes properties
                    set(obj.hEditD{1},'String',num2str(obj.iSelS(1)))
                    set(obj.hEditD{2},'String',num2str(obj.iSelS(2)))
                    obj.updateRegionHighlight();
                    obj.updateMoveEnableProps();
                end
            end            
            
        end
        
        % ----------------------- %
        % --- OTHER FUNCTIONS --- %
        % ----------------------- % 
        
        % --- updates the region highlight
        function updateRegionHighlight(obj)
            
            % retrieves the index of the region
            iApp = obj.getRegionIndex();
            
            % if there is an existing selected region, then disable it
            if ~isempty(obj.hSelS)
                obj.setRegionHighlight('off');
            end
            
            % finds the new inner region object and turns on the highlight
            obj.hSelS = findobj(obj.hAx,'tag','hInner','UserData',iApp);
            obj.setRegionHighlight('on');
            
        end        
        
        % --- updates the region highlight
        function setRegionHighlight(obj,state)
            
            % if there is no selection then exit
            if isempty(obj.hSelS); return; end
            
            % sets the highlight size
            switch state
                case 'on'
                    lSize = 3;
                case 'off'
                    lSize = 1;
            end
            
            % updates the linewidth
            hLine = findall(obj.hSelS,'tag','wing line');
            set(hLine,'LineWidth',lSize)
            
        end
        
        % updates the move button enabled properties
        function updateMoveEnableProps(obj) 
            
            % if the regions are not set, then exit
            if ~obj.isSet; return; end
            
            % retrieves the current region position
            iApp = obj.getRegionIndex;
            
            % fills any missing elements with the outer region dimenions
            pPos = obj.iMov.pos;
            useOuter = cellfun(@isempty,pPos);
            pPos(useOuter) = obj.iMov.posO(useOuter);
            
            % sets the region local/outer region dimension vectors
            pos = pPos{iApp};
            posO = obj.iMov.posO{iApp};                         
            
            % determines the currently selected row 
            posO(1:2) = max(0,posO(1:2));
            [nRow,nCol] = deal(obj.iMov.pInfo.nRow,obj.iMov.pInfo.nCol);
            iRow = floor((iApp-1)/nCol) + 1;
            
            % sets the region lower limit
            yLo = posO(2);
            if iRow > 1
                yLo = sum(pPos{iApp-nCol}([2,4]));
            end
            
            % sets the region upper limit 
            yHi = sum(posO([2,4]));
            if iRow < nRow
                yHi = pPos{iApp+nCol}(2);
            end            
            
            % calculates the offset
            dY = roundP(median(cellfun(@length,obj.iMov.iRT{iApp})));
            
            % updates the button enabled properties
            setObjEnable(obj.hButD{1},yHi-sum(pos([2,4]))>dY);
            setObjEnable(obj.hButD{2},(pos(2)-yLo)>dY);            
            
        end        
        
        % --- gets the background filter parameter filter
        function pVal = getFiltPara(obj,pFld)
            
            pVal = getTrackingPara(obj.hFigM.iMov.bgP,'pSingle',pFld);
            
        end
        
        % --- sets the background filter parameter filter
        function setFiltPara(obj,pFld,pVal)
           
            bgP = obj.hFigM.iMov.bgP;
            obj.hFigM.iMov.bgP = setTrackingPara(bgP,'pSingle',pFld,pVal);
            
        end        
        
        % --- function that closes the gui 
        function closeGUI(obj)
            
            % turns off the selection
            obj.setRegionHighlight('off');
            
            % deletes the gui
            obj.updateMainImage(1);
            delete(obj.hFig)
            
        end
        
        % --- updates the main image
        function updateMainImage(obj,forceRaw)
            
            % sets the default input arguments
            if ~exist('forceRaw','var'); forceRaw = false; end
            
            % retrieves the original image
            ImgNw = obj.Img0;
            
            % applies the image filter (if required)
            if obj.getFiltPara('useFilt') && ~forceRaw
                hS = fspecial('disk',obj.getFiltPara('hSz'));
                ImgNw = imfiltersym(ImgNw,hS);
            end
            
            % updates the main image
            set(obj.hImg,'CData',ImgNw);
            
        end
        
        % --- retrieves the current region index
        function iApp = getRegionIndex(obj)
            
            iApp = (obj.iSelS(1)-1)*obj.iMov.pInfo.nCol + obj.iSelS(2);
            
        end        
        
    end
    
end
    
