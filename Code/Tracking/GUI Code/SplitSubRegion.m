classdef SplitSubRegion < dynamicprops & handle
    
    % class properties
    properties
        
        % main class fields
        hAx
        hFig
        hFigM
        hFigT
        wFcn0
        
        % other fields
        iMov
        mShape
        iPara0
        
        % sub-region mapping parameters   
        ImapR
        iParaR
        
        % figure object handles
        hBut
        hButS
        hPanelC
        hPanelP
        hPanelT
        hTableP
        jTableP
        hButton
        hPopupP
        hCheckP
        hEdit
        hTxtT
        hTxtP
        hMarkR
        
        % scalar fields
        mSz0
        iAppS = 1;
        iFlyS = 1;
        isOpen = true;
        isInit = true;
        isUpdating = false;
        isFixed
        isOld
        isMTrk
        
        % object properties dimensions     
        dX = 10;
        pwMin = 0.01;
        dpOfs = 20;
        wTxtT = 190;
        wTxtP = 85;
        wBut = 125;
        wPanel = 270;
        wEdit = 50;
        wPopup = 35;
        hghtPanelP;
        hghtPanelT;
        hghtTxt = 16;
        hghtBut = 25;
        hghtEdit = 21;
        hghtPanelC = 40;
        
        % sub-region parameters
        pHghtF
        pHght
        pWidF
        pWid
        pPhiF        
        pPhi        
        
        % other static class fields
        tStr = {'end point 1','top line','bottom line'};
        
    end
    
    % private class properties
    properties (Access = private)
        
        objB
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = SplitSubRegion(objB)
            
            % creates a loadbar
            wStr = 'Setting Up Split Region Plot Objects...';
            hProg = ProgressLoadbar(wStr);
            
            % sets the input arguments
            obj.objB = objB;
            
            % sets the other class fields
            obj.hFigM = objB.hFig;            
            obj.iMov = objB.iMov;
            obj.mShape = obj.iMov.mShape;
            obj.isMTrk = objB.isMTrk;
            obj.isOld = isOldIntObjVer;            
            
            % sets the axes handles
            obj.hFigT = findall(0,'tag','figFlyTrack');
            hPanelI = findall(obj.hFigT,'Tag','panelImg');
            obj.hAx = findall(hPanelI,'Type','Axes');
            
            % determines if the sub-region split data field is set
            if isfield(obj.iMov,'srData') && ~isempty(obj.iMov.srData)
                % if so, then determine if the data is valid
                srData = obj.iMov.srData;
                switch obj.mShape
                    case 'Rect'
                        if isfield(srData,'pHght')
                            % flag that re-initialisation is unnecessary
                            obj.isInit = false;
                            obj.pHght = srData.pHght;
                            obj.pWid = srData.pWid;
                            
                            % sets up the parameter struct
                            p0 = struct('nRow',0,'nCol',0);
                            pVal = {cellfun('length',obj.pHght);...
                            	    cellfun('length',obj.pWid)}; 
                        end
                        
                    case 'Circ'
                        if isfield(srData,'pPhi')
                            % flag that re-initialisation is unnecessary
                            obj.isInit = false;
                            obj.pPhi = srData.pPhi;
                            
                            % sets up the parameter struct
                            p0 = struct('nSeg',0);
                            pVal = {cellfun('length',obj.pPhi)};                            
                        end
                end
                
                % sets up the parameter struct (if not initialising)
                if ~obj.isInit
                    pFld = fieldnames(p0);
                    obj.iParaR = repmat(p0,size(pVal{1}));
                    for i = 1:numel(obj.iParaR)
                        for j = 1:length(pFld)
                            obj.iParaR(i) = setStructField...
                                    (obj.iParaR(i),pFld{j},pVal{j}(i));
                        end
                    end
                end
            end
            
            % creates the figure 
            obj.initObjProps();
            
            % closes the loadbar
            delete(hProg);
            
        end
        
        % --- initialises the object properties
        function initObjProps(obj)
            
            % global variables
            global axPosX axPosY H0T HWT
            
            % sets the global axes limits
            axPos = getObjGlobalCoord(obj.hAx);
            axPosX = axPos(1) + [0,axPos(3)];
            axPosY = axPos(2) + [0,axPos(4)];
            
            % button name strings              
            obj.iPara0 = struct();
            bStr = {'Update','Close'};            
            bFcn = {@obj.updateButton,@obj.closeButton};                      
            
            % sets the figure properties
            switch obj.mShape
                case 'Rect'
                    % case is a rectangular region type
                    pVal = [2,2];
                    pStrP = {'nCol','nRow'};
                    tStrL = {'Rectangular Grid Column Count: ';...
                            'Rectangular Grid Row Count: '};
                    
                case 'Circ'
                    % case is a circle region type
                    pVal = 4;
                    pStrP = {'nSeg'};
                    tStrL = {'Circular Region Segment Count: '};
               
            end     
            
            if obj.isInit
                % retrieves the user data                
                hI = findall(obj.hAx,'tag','hInner');
                uD = cell2mat(arrayfun(@(x)(get(x,'UserData')),hI,'un',0));
                [nApp,nFly] = deal(max(uD(:,1)),max(uD(:,2)));                  
                
                % memory allocation
                szP = [nFly,nApp];                
                
                % sets up the 
                switch obj.mShape
                    case 'Rect'
                        % case is a rectangular region
                        
                        % sets the proportional height vectors
                        pH = diff(linspace(0,1,pVal(1)+1)');
                        obj.pHght = repmat({pH},szP);
                        
                        % sets the proportional width vectors
                        pW = diff(linspace(0,1,pVal(2)+1)');                        
                        obj.pWid = repmat({pW},szP);
                        
                    case 'Circ'
                        % case is a circular region
                        
                        % sets the segment angle vectors
                        phi0 = obj.convertAngle(linspace(0,2*pi,pVal+1)');
                        obj.pPhi = repmat({phi0(1:end-1)},szP);
                        
                end
            else
                % sets up the data values
                [nFly,nApp] = size(obj.iParaR);
            end       
            
            % fixed boolean flag array
            obj.isFixed = false(nFly,nApp);            
            
            % hide the region configuration GUI
            setObjVisibility(obj.hFigM,0);
            
            % -------------------- %
            % --- FIGURE SETUP --- %
            % -------------------- %
            
            % sets the figure height
            nRowMx = 4;
            nPara = length(tStrL);            
            pOfs = ((2.5+nPara)*obj.dX+obj.dpOfs);
            obj.hghtPanelP = obj.hghtBut*(nPara+2) + ...
                             pOfs + nPara*(nRowMx*HWT + H0T) + ...
                             ((nFly*nApp)>1)*(obj.hghtBut+obj.dX/2);
            hghtFig = obj.hghtPanelP + 3*obj.dX + obj.hghtPanelC;
            fPos = [obj.dX*[1,1],obj.wPanel+2*obj.dX,hghtFig];
            
            % deletes any previous figures
            hFigPr = findall(0,'tag','figSplitSubRegion');
            if ~isempty(hFigPr); delete(hFigPr); end
            
            % creates the objects
            obj.hFig = figure('Position',fPos,'tag','figSplitSubRegion',...
                              'MenuBar','None','Toolbar','None',...
                              'Name','Sub-Region Split','Resize','off',...
                              'NumberTitle','off','Visible','off');
                 
            % ---------------------------------- %
            % --- CONTROL BUTTON PANEL SETUP --- %
            % ---------------------------------- %                          
                          
            % creates the panel object
            pPosC = [obj.dX*[1,1],obj.wPanel,obj.hghtPanelC];
            obj.hPanelC = uipanel(obj.hFig,'Title','','Units','Pixels',...
                                           'Position',pPosC);
            
            % button object setup
            obj.hBut = cell(length(bStr),1);
            for i = 1:length(bStr)
                x0 = 3 - 4*(i-1);
                tagStr = sprintf('button%s',bStr{i});
                bPos = [obj.dX+(i-1)*obj.wBut-x0,7,obj.wBut,obj.hghtBut];
                obj.hBut{i} = uicontrol(obj.hPanelC,'Style','pushbutton',...
                            'Position',bPos,'Tag',tagStr,'Callback',...
                            bFcn{i},'FontUnits','Pixels','FontSize',12,...
                            'FontWeight','bold','String',bStr{i});
            end
            
            % sets the update button properties
            setObjEnable(obj.hBut{1},obj.isInit);
            
            % ----------------------------- %
            % --- PARAMETER PANEL SETUP --- %
            % ----------------------------- %              
                                       
            % creates the panel object
            y0P = 2*obj.dX+obj.hghtPanelC;
            tStrP = 'SUB-REGION SPLIT PARAMETERS';
            pPosP = [obj.dX,y0P,obj.wPanel,obj.hghtPanelP];
            obj.hPanelP = uipanel(obj.hFig,'Title',tStrP,'Units','Pixels',...
                                  'Position',pPosP,'FontWeight','Bold',...
                                  'FontUnits','Pixels','FontSize',13);
                 
            % creates the parameter table panel            
            obj.hghtPanelT = nPara*(nRowMx*H0T + HWT) + ...
                             obj.dX + (nPara+1)*obj.hghtBut;
            pPosT = [(obj.dX/2)*[1,1],obj.wPanel-obj.dX,obj.hghtPanelT];
            obj.hPanelT = uipanel(obj.hPanelP,'Title','','Units',...
                                  'Pixels','Position',pPosT);
                              
            % creates the checkbox object
            chkStr = 'Fix Split Regions To Have Equal Size';
            chkPos = [(obj.dX/2)*[3,1],obj.wPanel-2*obj.dX,obj.hghtEdit];
            obj.hCheckP = uicontrol(obj.hPanelT,'Units','Pixels',...
                                'Position',chkPos,'FontWeight','Bold',...
                                'FontUnits','pixels','Style','Checkbox',...
                                'FontSize',12,'String',chkStr,...
                                'Callback',@obj.fixRegionCheck);
            
            % parameter text/editboxs
            y0 = obj.dX/2+obj.hghtBut;
            [obj.hTxtT,obj.hEdit] = deal(cell(length(tStrL),1));
            [obj.hTableP,obj.jTableP] = deal(cell(length(tStrL),1));
            for i = 1:length(tStrL)
                % creates the text objects                
                tPosT = [obj.dX/2,y0+2,obj.wTxtT,obj.hghtTxt];
                obj.hTxtT{i} = uicontrol(obj.hPanelT,'String',tStrL{i},...
                                        'Position',tPosT,'FontWeight',...
                                        'Bold','FontUnits','Pixels',...
                                        'FontSize',12,'Style','text',...
                                        'HorizontalAlignment','right');
                                        
                % creates the edit objects
                pValS = num2str(pVal(i));     
                ePos = [(obj.dX+obj.wTxtT),y0,obj.wEdit,obj.hghtEdit];
                obj.hEdit{i} = uicontrol(obj.hPanelT,'String',pValS,...
                                         'Position',ePos,'FontUnits',...
                                         'Pixels','FontSize',11,...
                                         'UserData',pStrP{i},'Callback',...
                                         @obj.editUpdate,'Style','edit');
                                     
                % sets the parameter fields
                obj.iPara0 = setStructField(obj.iPara0,pStrP{i},pVal(i));                                
                [tData,cName] = obj.getTableData(i);
                
                % creates the data table 
                hghtTab = nRowMx*HWT + H0T;                
                cWid = num2cell((obj.wPanel-2.5*obj.dX)*[1,1]/2);   
                y1 = y0 + (obj.dX/2+obj.hghtBut);
                tPosP = [obj.dX/2,y1,obj.wPanel-2.5*obj.dX,hghtTab];
                obj.hTableP{i} = uitable(obj.hPanelT,'Data',tData,...
                                'Units','Pixels','Position',tPosP,...
                                'ColumnName',cName,'ColumnWidth',cWid,...
                                'CellEditCallback',@obj.tableUpdate,...
                                'ColumnEditable',[false,true],...
                                'UserData',i);
                autoResizeTableColumns(obj.hTableP{i});                
                                    
                % increments the table offset
                y0 = y0 + (obj.dX + obj.hghtBut + hghtTab);
            end    
            
            % ---------------------------------------- %
            % --- POPUP MENU OBJECT INITIALISATION --- %
            % ---------------------------------------- %           
            
            % 
            if obj.isMTrk
                pStrPp = {'Row #:','Column #:'};
            else
                pStrPp = {'Region #:','Sub-Region #:'};                
            end            
            
            % region/sub-region popup menu objects
            y0 = sum(pPosT([2,4]))+obj.dX/2;
            pValP = {(1:nApp)',(1:nFly)'};
            [obj.hPopupP,obj.hTxtP] = deal(cell(length(pStrPp),1));            
            
            % creates the update button object (if more than one region)
            if (nFly*nApp) > 1
                % creates the button object
                bStrS = 'Synchronise Region Configuration';
                tPosP = [obj.dX/2,y0,obj.wPanel-obj.dX,obj.hghtBut];
                obj.hButS = uicontrol(obj.hPanelP,'String',bStrS,...
                                    'Position',tPosP,'FontWeight',...
                                    'Bold','FontUnits','Pixels',...
                                    'FontSize',12,'Style','pushbutton',...
                                    'Callback',@obj.syncConfig); 
                
                % increments the offset
                y0 = y0 + (obj.hghtBut+obj.dX/2);
            end
            
            %
            for i = 1:length(pStrPp)
                % creates the text markers
                x0 = obj.dX/2 + (i-1)*(pPosT(3)/2);
                tPosP = [x0,y0,obj.wTxtP,obj.hghtTxt];
                obj.hTxtP{i} = uicontrol(obj.hPanelP,'String',pStrPp{i},...
                                        'Position',tPosP,'FontWeight',...
                                        'Bold','FontUnits','Pixels',...
                                        'FontSize',12,'Style','text',...
                                        'HorizontalAlignment','right');  
                setObjEnable(obj.hTxtP{i},length(pValP{i})>1);
                                    
                % creates the popup menu objects
                x1 = sum(tPosP([1,3])) + obj.dX/2;
                pPosP = [x1,tPosP(2),obj.wPopup,obj.hghtEdit];
                obj.hPopupP{i} = uicontrol(obj.hPanelP,'Style','popupmenu',...
                                'String',num2cell(pValP{i}),'Value',1,...
                                'Units','Pixels','Position',pPosP,...
                                'Callback',@obj.popupCallback,'UserData',i);
                setObjEnable(obj.hPopupP{i},length(pValP{i})>1);
            end            
                
            % parameter memory allocation (initialisation only)
            if obj.isInit            
                obj.iParaR = repmat(obj.iPara0,[nFly,nApp]);                
            end  
            
            % ---------------------------- %
            % --- OTHER PROPERTY SETUP --- %
            % ---------------------------- %             
            
            % sets the figure to be visible
            centreFigPosition(obj.hFig,2);
            setObjVisibility(obj.hFig,1);
            
            % turns the ROI highlight
            obj.setROIHighlight('on',1,1);
            obj.setROIResizeProps(false);
            obj.setROIProps(false);
            
            % sets the button down function
            obj.wFcn0 = get(obj.hFigT,'WindowButtonDownFcn');
            set(obj.hFigT,'WindowButtonDownFcn',@obj.buttonDownFcn);            
            
            % creates the region markers
            obj.hMarkR = cell(size(obj.iParaR));
            obj.updateRegionMarkers();
            
        end
        
        % --- sets the region ROI properties
        function setROIProps(obj,isOn)
            
            if ~obj.isOld
                hROI = findall(obj.hAx,'tag','hInner');
                if isOn
                    mSzNw = obj.mSz0;
                else                    
                    obj.mSz0 = get(hROI(1),'MarkerSize');
                    mSzNw = 1;
                end
                
                % sets the new marker size
                arrayfun(@(x)(set(x,'MarkerSize',mSzNw)),hROI)
            end
            
        end
        
        % -------------------------------- %
        % --- CLASS CALLBACK FUNCTIONS --- %
        % -------------------------------- %
        
        % --- update button callback function
        function updateButton(obj,~,~)

            % retrieves the fixed flag value
            [iP,jP] = deal(obj.iFlyS,obj.iAppS);
            isFix = obj.isFixed(iP,jP);
            
            % memory allocation for the split region data struct
            srData = struct('Type',obj.mShape,'isFix',isFix,'useSR',true);
            
            % sets the region shape specific fields
            switch obj.mShape
                case 'Rect'
                    % case is rectangular regions
                    if isFix                        
                        srData.pWid = obj.pWidF;
                        srData.pHght = obj.pHghtF;
                    else
                        srData.pWid = obj.pWid;
                        srData.pHght = obj.pHght;                        
                    end
                    
                case 'Circ'
                    % case is circular regions
                    if isFix
                        srData.pPhi = obj.pPhiF;
                    else
                        srData.pPhi = obj.pPhi;                        
                    end
                    
            end
            
            % updates the sub-region data struct within the main GUI            
            obj.iMov.srData = srData;
            obj.objB.iMov = obj.iMov;
            
            % enables the split region use menu item
            hMenuUS = findall(obj.hFigM,'tag','hMenuUseSplit');
            set(hMenuUS,'Checked','On','Enable','On');
            
            % enables the update button
            setObjEnable(obj.objB.hButC{1},1);
            
            % disables the update button
            setObjEnable(obj.hBut{1},0);            
            
        end
        
        % --- close button callback function
        function closeButton(obj,~,~)
            
            % determines if the update button is enabled
            if strcmp(get(obj.hBut{1},'Enable'),'on')
                % if so, then prompt the user if they want to update
                qStr = 'Do you want to update the sub-region split changes?';
                uChoice = questdlg(qStr,'Update Changes?',...
                                        'Yes','No','Cancel','Yes');
                switch uChoice
                    case 'Yes'
                        % if the user cancelled, then exit the function
                        obj.updateButton([],[]);
                        
                    case 'Cancel'
                        % if the user cancelled, then exit the function
                        return
                end
            end
            
            % turns off the ROI highlight
            obj.isOpen = false;
            obj.setROIHighlight('off')
            obj.setROIResizeProps(true)
            obj.setROIProps(true);
            
            % sets the button down function  
            set(obj.hFigT,'WindowButtonDownFcn',obj.wFcn0);
            
            % deletes any region markers            
            hMark = findall(obj.hAx,'tag','hMarkR');
            if ~isempty(hMark); delete(hMark); end
            
            % deletes the figure
            delete(obj.hFig)
            setObjVisibility(obj.hFigM,1);
            
        end        
        
        % --- parameter editbox update callback function
        function editUpdate(obj,hObj,~)
            
            % retrieves the current values
            iTable = 1;
            pStr = get(hObj,'UserData');
            nwVal = str2double(get(hObj,'String'));
            [i,j] = deal(obj.iFlyS,obj.iAppS);
            
            % determine if the parameter value if valid
            if chkEditValue(nwVal,[1,10],true)
                % if so, updates the parameter field                
                obj.iParaR(i,j) = setStructField(obj.iParaR(i,j),pStr,nwVal);
                setObjEnable(obj.hBut{1},'on');
                
                % resets the split region parameters (based on type)
                switch pStr
                    case 'nRow'
                        % case is row count
                        iTable = 2;
                        obj.pHght{i,j} = diff(linspace(0,1,nwVal+1)');
                        obj.pHghtF{i,j} = obj.pHght{i,j};
                        
                    case 'nCol'
                        % case is column count                        
                        obj.pWid{i,j} = diff(linspace(0,1,nwVal+1)');
                        obj.pWidF{i,j} = obj.pWid{i,j};
                        
                    case 'nSeg'                        
                        % case is a circular region
                        phi0 = obj.convertAngle(linspace(0,2*pi,nwVal+1)');
                        obj.pPhi{i,j} = phi0(1:end-1);
                        obj.pPhiF{i,j} = obj.pPhi{i,j};
                        
                end
                
                % updates the region markers
                indR = sub2ind(size(obj.iParaR),i,j);
                obj.updateRegionMarkers(indR);
                setObjEnable(obj.hBut{1},1);
                
                % updates the table
                set(obj.hTableP{iTable},'Data',obj.getTableData(iTable),...
                                'ColumnEditable',obj.getColEdit(iTable));
                set(obj.hCheckP,'Value',obj.isFixed(i,j));
                
            else
                % if not, reset the field values
                pVal0 = getStructField(obj.iParaR(i,j),pStr);
                set(hObj,'String',num2str(pVal0));
            end
            
        end
        
        % --- popupmenu object callback function
        function popupCallback(obj,hObj,~)
            
            % turns off the ROI highlight
            obj.setROIHighlight('off');
            
            % updates the selected region/sub-region index
            switch get(hObj,'UserData')
                case 1
                    % case is updating the region index
                    obj.iAppS = get(hObj,'Value');
                case 2
                    % case is updating the sub-region index
                    obj.iFlyS = get(hObj,'Value');
                    
            end
            
            % turns off the ROI highlight
            obj.setROIHighlight('on');      
            
            % updates the parameter table
            for i = 1:length(obj.hTableP)
                set(obj.hTableP{i},'Data',obj.getTableData(i),...
                                   'ColumnEditable',obj.getColEdit(i));
                
                % updates the editbox field
                pStr = get(obj.hEdit{i},'UserData'); 
                iPara = obj.iParaR(obj.iFlyS,obj.iAppS);
                nwVal = getStructField(iPara,pStr);
                set(obj.hEdit{i},'String',num2str(nwVal));
            end
            
            % updates the checkbox
            set(obj.hCheckP,'Value',obj.isFixed(obj.iFlyS,obj.iAppS));            
            
        end
        
        % --- configuration synchronisation callback function
        function syncConfig(obj,~,~)
            
            % prompts the user if they wish to continue
            qtStr = 'Synchronise Regions?';
            qStr = ['Are you sure you want to synchronise the ',...
                    'region configurations?'];
            uChoice = questdlg(qStr,qtStr,'Yes','No','Yes');
            if ~strcmp(uChoice,'Yes')
                % if the user cancelled, then exit the function
                return
            end
            
            % updates the parameters for all of the regions
            [iP,jP] = deal(obj.iFlyS,obj.iAppS);
            switch obj.mShape
                case 'Rect'
                    % case is rectangular regions
                    obj.pWid(:) = obj.pWid(iP,jP);
                    obj.pHght(:) = obj.pHght(iP,jP);
                    
                    
                case 'Circ'
                    % case is circular regions
                    obj.pPhi(:) = obj.pPhi(iP,jP);
            end
            
            % resets the parameter struct            
            obj.iParaR(:) = obj.iParaR(iP,jP);
            obj.isFixed(:) = obj.isFixed(iP,jP);
            
            % updates the button properties
            setObjEnable(obj.hBut{1},1);
            
            % recreates the region markers
            h = ProgressLoadbar('Updating Sub-Region Markers...');
            obj.updateRegionMarkers();    
            delete(h);
            
        end
        
        % --- fixed region size checkbox callback function
        function fixRegionCheck(obj,hObj,~)
            
            % updates the field value
            htStr = 'on';            
            [iP,jP] = deal(obj.iFlyS,obj.iAppS);
            obj.isFixed(iP,jP) = get(hObj,'Value');            
            
            % updates the parameter values
            if obj.isFixed(iP,jP) 
                % if fixing region size, then reset the split parameters
                switch obj.mShape
                    case 'Rect'
                        % case is rectangular regions
                        
                        % sets the proportional width values 
                        nCol = obj.iParaR(iP,jP).nCol;
                        obj.pWidF{iP,jP} = diff(linspace(0,1,nCol+1)');    
                        
                        % sets the proportional height values
                        nRow = obj.iParaR(iP,jP).nRow;
                        obj.pHghtF{iP,jP} = diff(linspace(0,1,nRow+1)'); 
                        
                    case 'Circ'
                        % case is circular regions
                        
                        % sets the segment angles                        
                        nSeg = obj.iParaR(iP,jP).nSeg;                      
                        phi0 = obj.convertAngle(linspace(0,2*pi,nSeg+1)');
                        obj.pPhiF{iP,jP} = phi0(1:end-1);                        
                        
                end
                
                % resets the object markers
                htStr = 'off';                            
            end            
            
            % updates the region markers
            indR = sub2ind(size(obj.iParaR),iP,jP);
            obj.updateRegionMarkers(indR)            
            
            % updates the parameter table
            for i = 1:length(obj.hTableP)
                set(obj.hTableP{i},'Data',obj.getTableData(i),...
                                   'ColumnEditable',obj.getColEdit(i));
            end             
            
            % sets the other object properties
            setObjEnable(obj.hBut{1},1);            
            if ~isempty(obj.hMarkR{iP,jP})
                % removes the marker hit-test
                if obj.isOld
                    % case is the old format interactive objects
                    
                    % sets the object tag
                    switch obj.mShape
                        case 'Rect'
                            tagStr = 'top line';
                        case 'Circ'
                            tagStr = 'end point 2';
                    end

                    % sets the marker line hit-test
                    ii = ~cellfun('isempty',obj.hMarkR{iP,jP});
                    hEnd1 = cellfun(@(x)(findall(x,'tag',tagStr)),...
                                         obj.hMarkR{iP,jP}(ii),'un',0);
                    cellfun(@(x)(set(x,'HitTest',htStr)),hEnd1)
                else
                    % case is the new format interactive objects
                    
                    % sets the interaction allowed string
                    if strcmp(htStr,'on')
                        iaStr = 'all';
                    else
                        iaStr = 'none';
                    end
                    
                    % sets the interaction flag
                    cellfun(@(x)(set(x.hObj,...
                           'InteractionsAllowed',iaStr)),obj.hMarkR{iP,jP})
                end
            end
                
        end
        
        % --- table update callback function
        function tableUpdate(obj,hObj,evnt)
            
            % if updating elsewhere, then exit
            if obj.isUpdating
                return
            end
            
            % retrieves the edit details
            iSeg = evnt.Indices(1);            
            tData = get(hObj,'Data'); 
            uData = get(hObj,'UserData');
            nwVal = str2double(evnt.EditData);    
            [iP,jP] = deal(obj.iFlyS,obj.iAppS);
            
            % sets the parameter limits
            switch obj.mShape
                case 'Rect'
                    % case is a rectangular sub-region
                    if uData == 1
                        pX = obj.pWid{iP,jP};
                    else
                        pX = obj.pHght{iP,jP};
                    end
                    
                    % sets the parameter limits
                    dLim = obj.pwMin*[-1,1];                    
                    if length(pX) == 2
                        % case is there are 2 regions
                        nwLim = [0,1] - dLim;                        
                        
                    elseif iSeg == 1
                        % case is the first row/column
                        nwLim = [0,sum(pX(1:iSeg+1))] - dLim;
                        
                    elseif iSeg == length(pX)
                        % case is the last row/column
                        nwLim = [0,1-sum(pX(1:(iSeg-2)))] - dLim;
                        
                    else
                        % case is the other row/columns
                        nwLim = [0,diff([sum(pX(1:(iSeg-1))),...
                                         sum(pX(1:(iSeg+1)))])] - dLim;
                    end

                case 'Circ'
                    % case is a circular sub-region
                    
                    % determines the direction bearing values                    
                    pX = obj.pPhi{iP,jP};
                    pBr = deg2bear(-[pX(end);pX;pX(1)]);
                    
                    % sets the limits based on the surrounding regions
                    jSeg = iSeg + 1;
                    if pBr(jSeg) < pBr(jSeg-1) || pBr(jSeg) > pBr(jSeg+1)
                        % previous region bearing is greater than current
                        nwLim = {[pBr(jSeg-1),360],[0,pBr(jSeg+1)]};                        
                        
                    else
                        % case is the other regions
                        nwLim = [pBr(jSeg-1),pBr(jSeg+1)];
                    end
                    
            end            
            
            % determines if the new value is valid            
            if chkEditValue(nwVal,nwLim,0)
                % sets the new parameter value
                switch obj.mShape
                    case 'Circ'
                        % case is the circular regions
                        obj.pPhi{iP,jP}(iSeg) = bear2deg(evnt.NewData);
                        updateFcn = @obj.updateCircMarker;
                        
                    case 'Rect'
                        % case is the other region types
                        updateFcn = @obj.updateRectMarker;
                        
                        % retrieves the stored proportional dimensions
                        pX = cell2mat(tData(:,2));
                        if uData == 1
                            % case is proportional width
                            pX0 = obj.pWid{iP,jP};                            
                        else
                            % case is proportional height
                            pX0 = obj.pHght{iP,jP};
                        end
                        
                        % recalculate the proportional dimensions of the
                        % surrounding split group region
                        if iSeg == length(pX)
                            % case is the last group in the row/column
                            pX(iSeg-1) = pX0(iSeg-1) + (pX0(iSeg)-nwVal);
                            iSeg = length(pX)-1;
                        else
                            % case is the first group in the row/column
                            pX(iSeg+1) = pX0(iSeg+1) + (pX0(iSeg)-nwVal);
                        end                     
                        
                        % resets the proportional dimensions
                        if uData == 1
                            obj.pWid{iP,jP} = pX;                         
                        else
                            obj.pHght{iP,jP} = pX;
                        end
                        
                        % resets the table data
                        tData(:,2) = num2cell(pX);
                        set(hObj,'Data',tData);
                end
                
                % updates the corresponding marker
                setObjEnable(obj.hBut{1},1);
                feval(updateFcn,iSeg,uData);
                
            else
                % otherwise, reset to the previous valid value
                tData{iSeg,2} = evnt.PreviousData;
                set(hObj,'Data',tData);
            end
            
        end
        
        % --- the main window button down function
        function buttonDownFcn(obj,~,~)
            
            % Modify mouse pointer over axes
            mPos = get(obj.hFigT,'CurrentPoint');
            if isOverAxes(mPos)
                % determines if the button is over any ROI objects
                tArr = {'tag','hInner';'tag','hMarkR'};
                hObj = findAxesHoverObjects(obj.hFigT,tArr);
                
                if isempty(hObj)
                    return
                else
                    switch get(hObj,'tag')
                        case 'hInner'
                            hROI = hObj;
                            
                        case 'hMarkR'
                            return
                            
                    end
                end                
                
                % if there is a change then update the flags
                uData = get(hROI,'UserData');
                if ~isequal(uData,[obj.iAppS,obj.iFlyS])                
                    % resets the ROI highlight
                    obj.setROIHighlight('off');
                    [obj.iAppS,obj.iFlyS] = deal(uData(1),uData(2));
                    obj.setROIHighlight('on');
                    
                    % resets the popupmenu item values
                    set(obj.hPopupP{1},'Value',obj.iAppS);
                    set(obj.hPopupP{2},'Value',obj.iFlyS);
                    
                    % retrieves the parameter field
                    iParaNw = obj.iParaR(obj.iFlyS,obj.iAppS);  
                    pStr = cellfun(@(x)(get(x,'UserData')),obj.hEdit,'un',0);
                    
                    % updates the edit parameter field values
                    pFld = fieldnames(iParaNw);
                    for i = 1:length(pFld)
                        ii = strcmp(pStr,pFld{i});
                        pVal = getStructField(iParaNw,pFld{i});
                        set(obj.hEdit{ii},'String',num2str(pVal))
                    end
                    
                    % updates the parameter table
                    for i = 1:length(obj.hTableP)
                        set(obj.hTableP{i},'Data',obj.getTableData(i),...
                                       'ColumnEditable',obj.getColEdit(i));
                    end    
                    
                    % updates the checkbox
                    set(obj.hCheckP,'Value',obj.isFixed(obj.iFlyS,obj.iAppS));                    
                end
            end
                
        end
        
        % --- circle marker movement callback function
        function circMarkerMove(obj,varargin)
            
            % if updating, then exit the function
            if obj.isUpdating
                return
            end
            
            % retrieves the input arguments
            switch length(varargin)
                case 1
                    % case is the old format interactive object
                    mPos = varargin{1};
                    hMarkS = get(gco,'Parent');
                    
                case 2
                    % case is the new format interactive object
                    mPos = varargin{2}.CurrentPosition;
                    hMarkS = varargin{1};                    
            end
           
            % retrieves the selected line marker object handle
            uDataS = get(hMarkS,'UserData');
            obj.isUpdating = true;
            
            % retrieves the ROI marker handle and userdata
            [hROI,iSeg] = deal(uDataS{1},uDataS{2});
            uDataR = get(hROI,'UserData');
            
            % retrieves the current parent ROI position
            rPos = getIntObjPos(hROI);
            [mP,phiP] = obj.calcNewMarkerCoords(rPos,mPos);
            obj.updateCircMarkerLine(hMarkS,mP)            
            
            % updates the segment angle
            obj.pPhi{uDataR(2),uDataR(1)}(iSeg) = phiP;
            
            % updates the table
            tData = get(obj.hTableP{1},'Data');
            tData{iSeg,2} = roundP(deg2bear(-phiP),0.1);
            set(obj.hTableP{1},'Data',tData);
            
            % updates the location of the marker
            setObjEnable(obj.hBut{1},1);
            obj.isUpdating = false;
            
        end       
            
        % --- rectangular marker movement callback function
        function rectMarkerMove(obj,varargin)
            
            % if updating, then exit the function
            if obj.isUpdating
                return
            end
            
            % retrieves the object handle and the index of the line
            switch length(varargin)
                case 1
                    % case is the older version interactive objects
                    mPos = varargin{1};
                    uDataS = get(get(gco,'Parent'),'UserData');
                    
                case 2
                    % case is the newer version interactive objects
                    mPos = varargin{2}.CurrentPosition;
                    uDataS = varargin{1}.UserData;
            end
            
            % retrieves the selected line marker object handle
            obj.isUpdating = true;    
            
            % retrieves the ROI marker handle and position
            [hROI,iType,iSeg] = deal(uDataS{1},uDataS{2},uDataS{3});
            rPos = getIntObjPos(hROI);            
            
            % calculates the 
            pStr = {'pWid','pHght'};
            tData = get(obj.hTableP{iType},'Data');
            pX = cell2mat(tData(:,2));            
            
            % calculates the proportional location of the marker
            prPos = (mPos(1,iType)-rPos(iType))/rPos(iType+2);  
            if iSeg > 1
                prPos = prPos - cumsum(pX(1:(iSeg-1)));
            end
            
            % re-calculates the proportional dimension values
            if iSeg == (length(pX)-1)
                % case is the last separator line in a row/column
                pX(iSeg) = prPos;
                pX(iSeg+1) = 1 - sum(pX(1:iSeg));
            else
                % case is the other rows/columns
                pX(iSeg+1) = pX(iSeg+1) + (pX(iSeg)-prPos);
                pX(iSeg) = prPos;
            end
            
            % updates the values within the class object
            uDataR = get(hROI,'UserData'); 
            [iFly,iApp] = deal(uDataR(2),uDataR(1));
            eval(sprintf('obj.%s{iFly,iApp} = pX;',pStr{iType}));
            
            % updates the table data
            tData(:,2) = num2cell(pX);
            set(obj.hTableP{iType},'Data',tData)
            
            % updates the location of the marker
            setObjEnable(obj.hBut{1},1);
            obj.isUpdating = false;            
            
        end                        
        
        % ---------------------------------------- %
        % --- SUB-REGION AXES UPDATE FUNCTIONS --- %
        % ---------------------------------------- %                
        
        % --- updates the region markers
        function updateRegionMarkers(obj,indR)
           
            % sets the region indices (if not provided)
            if ~exist('indR','var')
                indR = 1:numel(obj.iParaR);
            end
            
            % creates the region markers for each grouping
            for i = 1:length(indR)
                % sets the global index
                j = indR(i);
                
                % removes any previous markers
                if ~isempty(obj.hMarkR{j})
                    try
                        ii = ~cellfun('isempty',obj.hMarkR{j});
                        if obj.isOld
                            cellfun(@delete,obj.hMarkR{j}(ii)); 
                        else
                            cellfun(@(x)(delete(x.hObj)),obj.hMarkR{j}(ii))
                        end
                    end
                end                
                
                % creates the region markers
                obj.hMarkR{j} = obj.createRegionMarker(j);
            end
            
        end
        
        % --- creates the region markers
        function hMark = createRegionMarker(obj,indR)
           
            % determines the region/sub-region indices
            iPara = obj.iParaR(indR);
            [iFly,iApp] = ind2sub(size(obj.iParaR),indR);
            isFix = obj.isFixed(iFly,iApp);
            
            % retrieves the ROI api object
            hROI = obj.getROIObject(iApp,iFly);    
            pCol = obj.getROIColour(hROI);            
            
            % retrieves the ROI coordinates
            if obj.isOld
                hPatch = findall(hROI,'tag','patch');
                [xP,yP] = deal(get(hPatch,'xData'),get(hPatch,'yData'));
                pPos = [min(xP),min(yP),range(xP),range(yP)];
            else
                pPos = getIntObjPos(hROI,false);
            end                        
            
            % turns on the axes hold                    
            hold(obj.hAx,'on');            
            
            switch obj.mShape
                case 'Rect'
                    % case is a rectangular grid      
                    
                    % sets the rectangular dimensions
                    if isFix
                        pH = obj.pHghtF{iFly,iApp};
                        pW = obj.pWidF{iFly,iApp};
                    else
                        pH = obj.pHght{iFly,iApp};
                        pW = obj.pWid{iFly,iApp};
                    end                    
                    
                    % rectangle parameters
                    [p0,W,H] = deal(pPos(1:2),pPos(3),pPos(4));
                    [xV,yH] = deal(cumsum(pW)*W,cumsum(pH)*H);                    
                    
                    % sets up the constraint function
                    [xLim,yLim] = deal(p0(1)+[0,W],p0(2)+[0,H]);
                    
                    % memory allocation
                    nR = max(1,max(iPara.nRow,iPara.nCol)-1);
                    hMark = cell(nR,2);                    
                    
                    % creates the horizontal markers
                    for i = 1:(iPara.nRow-1)
                        % creates the line marker
                        uData = {hROI,2,i};
                        [xL,yL] = deal(p0(1)+[0,W],(p0(2)+yH(i))*[1,1]);
                        hMark{i,2} = InteractObj('line',obj.hAx,{xL,yL});
                        hMark{i,2}.setFields('tag','hMarkR','UserData',uData);   
                        
                        % updates the marker properties/callback function
                        hMark{i,2}.setColour(pCol);
                        hMark{i,2}.setObjMoveCallback(@obj.rectMarkerMove); 
                        hMark{i,2}.setConstraintRegion(xLim,yLim);                        
                    end  
                    
                    % creates the vertical markers
                    for i = 1:(iPara.nCol-1)
                        % creates the line marker
                        uData = {hROI,1,i};
                        [xL,yL] = deal((p0(1)+xV(i))*[1,1],p0(2)+[0,H]);
                        hMark{i,1} = InteractObj('line',obj.hAx,{xL,yL});                        
                        hMark{i,1}.setFields('tag','hMarkR','UserData',uData);
                                                
                        % updates the marker properties/callback function
                        hMark{i,1}.setColour(pCol);
                        hMark{i,1}.setObjMoveCallback(@obj.rectMarkerMove); 
                        hMark{i,1}.setConstraintRegion(xLim,yLim);                         
                    end                    
                    
                case 'Circ'
                    % case is a circular grid
                    
                    % sets the angular coordinates
                    if isFix
                        phi = obj.pPhiF{iFly,iApp};
                    else
                        phi = obj.pPhi{iFly,iApp};
                    end                    
                    
                    % circle parameters
                    lWid = 2;
                    R = pPos(3)/2;
                    p0 = pPos(1:2)+R;                                        
                    
                    % creates the line markers         
                    hMark = cell(iPara.nSeg,1);
                    for i = 1:iPara.nSeg
                        % sets the interactive object properties
                        uD = {hROI,i};
                        xL = p0(1)+[0,R*cos(phi(i))];
                        yL = p0(2)+[0,R*sin(phi(i))];
                        
                        % creates the interactive object
                        hMark{i} = InteractObj('line',obj.hAx,{xL,yL});
                        hMark{i}.setFields('Tag','hMarkR','UserData',uD);
                        hMark{i}.setLineProps('Linewidth',lWid);
                        hMark{i}.setObjMoveCallback(@obj.circMarkerMove)                        
                        hMark{i}.setColour(pCol);                        
                        
                        % removes the marker hit-tests (old format only)
                        if hMark{i}.isOld
                            cellfun(@(x)(set(findall(hMark{i}.hObj,...
                                    'tag',x),'hittest','off')),obj.tStr)
                        end                        
                    end                                     
                    
            end
            
            % turns off the axes hold
            hold(obj.hAx,'off');   
            
        end        
        
        % --- updates the circle marker
        function updateCircMarker(obj,iSeg,~)
            
            % returns the 
            [iP,jP] = deal(obj.iFlyS,obj.iAppS);
            pPhiNw = obj.pPhi{iP,jP}(iSeg);
            
            % retrieves the marker associated with the table entry
            hROI = obj.getROIObject(jP,iP);
            uData = {hROI,iSeg};
            hMark = findall(obj.hAx,'tag','hMarkR','UserData',uData);
            
            % calculates the circle centre
            if obj.isOld
                % case is the old interactive object format

                % determines the circle centre
                hObj = findall(hMark,'type','Line');            
                hC = findall(hObj,'tag','end point 1');
                p0 = [get(hC,'xData'),get(hC,'yData')];
                
                % calculates the circle radius
                hTL = findall(hObj,'tag','top line');
                R = sqrt(diff(get(hTL,'xData')).^2 + ...
                         diff(get(hTL,'yData')).^2);                
            else
                % case is the new interactive object format
                
                % sets the circle centre/radius
                [p0,R] = deal(hROI.Center,hROI.SemiAxes(1));
            end            
            
            % updates the marker line coordinates
            pNw = p0 + R*[cos(pPhiNw),sin(pPhiNw)];
            obj.updateCircMarkerLine(hMark,[p0;pNw])
            
        end
        
        % --- updates the rectangular marker
        function updateRectMarker(obj,iSeg,iType)
            
            % retrieves the row/column indices            
            [iP,jP] = deal(obj.iFlyS,obj.iAppS);
            hROI = obj.getROIObject(jP,iP);
            hMark = obj.hMarkR{iP,jP}{iSeg,iType};
            
            % retrieves the ROI location
            rPos = getIntObjPos(hROI);
            mPos = hMark.getPosition();
            
            % returns the            
            if iType == 1
                pNw = obj.pWid{iP,jP};                
            else
                pNw = obj.pHght{iP,jP};
            end                                  
            
            % updates the line locations
            obj.isUpdating = true;
            mPos(:,iType) = sum(pNw(1:iSeg))*rPos(iType+2)+rPos(iType);
            hMark.setPosition(mPos);
            obj.isUpdating = false;
            
        end        
        
        % -------------------------------- %
        % --- ROI HIGHTLIGHT FUNCTIONS --- %
        % -------------------------------- %        
        
        % --- retrieves the ROI object handle for a given region/fly index)
        function hROI = getROIObject(obj,iApp,iFly)
            
            hROI = findall(obj.hAx,'tag','hInner','UserData',[iApp,iFly]);
            
        end
        
        % --- sets the ROI highlight
        function setROIHighlight(obj,State,iApp,iFly)
            
            % sets the default region/sub-region indices
            if ~exist('iApp','var')
                [iApp,iFly] = deal(obj.iAppS,obj.iFlyS);
            end
            
            % retrieves the ROI object handle
            hROI = obj.getROIObject(iApp,iFly);                        
            cCol = obj.getROIColour(hROI);
            
            % updates the patch object properties
            switch State
                case 'on'
                    % case is turning the highlight on
                    fAlpha = 0.15;
                    
                case 'off'
                    % case is turning the highlight off
                    fAlpha = 0;
            end            
            
            % updates the face patch properties        
            if obj.isOld
                % case is the older format interactive object
                hPatch = findall(hROI,'type','Patch');
                set(hPatch,'FaceColor',cCol,'FaceAlpha',fAlpha)
            else
                % case is the newer format interactive object
                set(hROI,'Color',cCol,'FaceAlpha',fAlpha);
            end
            
        end        
        
        % ----------------------- %
        % --- OTHER FUNCTIONS --- %
        % ----------------------- %
        
        % --- resets the ROI resize properties
        function setROIResizeProps(obj,State)
        
            % retrieves the inner region object handles
            hROI = findall(obj.hAx,'tag','hInner');
            
            % sets the resizeable flags
            for i = 1:length(hROI)
                setIntObjResizeState(hROI(i),State,obj.isOld);                
            end
            
        end
        
        % --- retrieves the section table data
        function [tData,cName] = getTableData(obj,iType)
            
            % determines if the fixed coordinates are to be used
            isFix = obj.isFixed(obj.iFlyS,obj.iAppS);
            
            % sets the table data values
            switch obj.mShape
                case 'Rect'
                    % case is rectangular regions
                    if iType == 2
                        % case is the proportional height
                        cName = {'Row #','Height'};  
                        if isFix
                            Y = obj.pHghtF{obj.iFlyS,obj.iAppS};
                        else
                            Y = obj.pHght{obj.iFlyS,obj.iAppS};                            
                        end
                        
                    else
                        % case is the proportional width
                        cName = {'Column #','Width'};
                        if isFix
                            Y = obj.pWidF{obj.iFlyS,obj.iAppS};
                        else
                            Y = obj.pWid{obj.iFlyS,obj.iAppS};
                        end                        
                    end

                case 'Circ'
                    % case is circular regions
                    cName = {'Segment #','Angle (Deg)'};
                    if isFix
                        pPhiT = obj.pPhiF{obj.iFlyS,obj.iAppS};
                    else
                        pPhiT = obj.pPhi{obj.iFlyS,obj.iAppS};
                    end
                        
                    % calculates the corrected angle
                    Y = roundP(deg2bear(-pPhiT),0.1);  


            end

            % sets the table data
            tData = num2cell([(1:length(Y))',Y(:)]);            
            
        end
        
        % --- updates the marker line coordinates
        function updateCircMarkerLine(obj,hMarkS,mP)
            
            if obj.isOld
                % case is the old format interactive object
                
                % updates the line object locations
                hChild = hMarkS.Children;
                for i = 1:length(hChild)
                    switch get(hChild(i),'Tag')
                        case 'end point 1'
                            set(hChild(i),'xData',mP(1,1),'yData',mP(1,2));                    
                        case 'end point 2'
                            set(hChild(i),'xData',mP(2,1),'yData',mP(2,2));
                        otherwise
                            set(hChild(i),'xData',mP(:,1),'yData',mP(:,2));
                    end
                end
                
            else
                % case is the new format interactive object
                % ...?
            end
            
            % updates the object position
            obj.isUpdating = true;
            setIntObjPos(hMarkS,mP);
            obj.isUpdating = false;            
            
        end      
        
        % --- retrieves the table column edit array
        function cEdit = getColEdit(obj,iTable)
           
            % memory allocation
            cEdit = false(1,2); 
            
            % sets the 2nd column flag
            if ~obj.isFixed(obj.iFlyS,obj.iAppS)
                switch obj.mShape
                    case 'Rect'
                        % case is rectangular regions
                        if iTable == 1
                            % case is proportional width
                            pX = obj.pWid{obj.iFlyS,obj.iAppS};
                        else
                            % case is proportional height
                            pX = obj.pHght{obj.iFlyS,obj.iAppS};
                        end
                        
                    case 'Circ'
                        % case is circular regions
                        pX = obj.pPhi{obj.iFlyS,obj.iAppS};
                        
                end
                
                % sets the 2nd column flag
                cEdit(2) = length(pX) > 1;
            end
            
        end       
        
        % --- retrieves the colour of the current ROI objec
        function pCol = getROIColour(obj,hROI)
           
            if obj.isOld
                % case is the older version interactive object
                
                % sets the candidate object tag string
                switch obj.mShape
                    case 'Rect'
                        % case is rectangular regions
                        tagStr = 'maxx top line';

                    case 'Circ'
                        % case is circular regions
                        tagStr = 'top line';
                end

                % retrieves the object colour
                pCol = get(findall(hROI,'tag',tagStr),'Color');
                
            else
                % case is the newer version interactive object
                
                % retrieves the object colour
                pCol = get(hROI,'Color');
            end
            
        end        
        
    end
    
    % static class methods
    methods (Static)

        % --- calculates the new marker coordinates
        function [mPos,phiP] = calcNewMarkerCoords(rPos,mPos)
        
            % determines the circle radius and centre point 
            R = rPos(3)/2;
            p0 = rPos(1:2) + R;     
            
            % determines which point has moved
            dPos = mPos(2,:) - p0;
            phiP = atan2(dPos(2),dPos(1));
            
            % recalculates the point so that it is on the circle perimeter
            mPos(2,:) = p0 + R*[cos(phiP),sin(phiP)];
            
        end        
        
        % --- angle conversion function
        function phi = convertAngle(phi)
           
            phi = phi - pi/2;
            
        end        
        
    end
end