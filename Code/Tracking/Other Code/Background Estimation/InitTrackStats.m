classdef InitTrackStats < handle

    % class properties
    properties
        
        % main class objects
        bgObj
        pStats
        
        % other class objects
        hAx
        hFig
        hPanel
        hPanelT
        hTextM
        hPopupM  
        hCheckM
        hCheckH
        hPanelI
        hTextR        
        hPopupR
        hTable        
        
        % table objects
        cHdr
        rHdr                
        tabCR
        jTable        
        Data        
        
        % fixed object dimensions        
        dY = 5;        
        dX = 10;  
        nMet = 3;
        txtSz = 12;
        widFig = 570;        
        hghtPanelI = 40;        
        widTxt = 110;
        hghtTxt = 16; 
        widPopup = 210; 
        hghtPopup = 22;
        widCheck = 190;
        hghtCheck = 22;
        expWid = 49; 
        pMax = 25;
        tPos
        
        % other miscellaneous fields
        hS
        aTF
        fRC
        bgCol
        nTube
        nPhase
        pData
        iMin
        iMax
        isOK = true;
        isUpdating = false;
        
        % sets the colour limits
        pL
        kL
        
        % variable object dimensions
        cWid0
        hghtFig
        widPanelP
        hghtPanelT     
        
        % java colours
        white = java.awt.Color.white;
        black = java.awt.Color.black;
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = InitTrackStats(bgObj)
            
            % sets the input arguments
            obj.bgObj = bgObj;
            obj.pStats = bgObj.pStats;
            
            % initialises the 
            obj.initClassFields();
            if ~obj.isOK
                return
            end
            
            % initialises the object properties
            obj.initObjProps();
            
            % centres the figure
            setObjVisibility(obj.hFig,1)
            centreFigPosition(obj.hFig,3)
            
        end
        
        % --- initialises the class object fields
        function initClassFields(obj)
            
            % java imports
            import java.awt.font.FontRenderContext;
            import java.awt.geom.AffineTransform;

            % creates the font render context object
            obj.aTF = javaObjectEDT('java.awt.geom.AffineTransform');
            obj.fRC = javaObjectEDT(...
                    'java.awt.font.FontRenderContext',obj.aTF,true,true);
                   
            % Ensure all drawing is caught up before creating the table
            drawnow                  
            
            % table data setup        
            obj.hAx = obj.bgObj.hGUI.imgAxes;
            obj.nPhase = length(obj.bgObj.iMov.vPhase); 
            [obj.iMin,obj.iMax] = deal(cell(obj.nMet,1));
            
            % sets the colour limits and shape factors
            obj.pL = {[2.00,5.00,8.00];...
                      [1.00,3.00,6.00];...
                      [0.10,0.85,0.90]};
            obj.kL = cellfun(@(x)(obj.calcShapeFactor(x)),obj.pL,'un',0);            
            
        end                
        
        % --- initialises the object properties
        function initObjProps(obj)
            
            % global parameters
            global HWT
            
            % calculates the table panel and figure height
            H0T = 52;
            H0 = 2*obj.dX + 3*obj.dY;
            hghtTable = obj.dX + H0T + HWT*max(obj.bgObj.nTube);
            obj.hghtPanelT = hghtTable + obj.hghtPanelI;
            obj.hghtFig = H0 + obj.hghtPanelI + obj.hghtPanelT;
            
            % creates the figure object
            fPos = [100,100,obj.widFig,obj.hghtFig];
            obj.widPanelP = obj.widFig - 3*obj.dX;
            
            % deletes any previous tracking statistics guis
            hFigPr = findall(0,'tag','figInitTrackStats');
            if ~isempty(hFigPr); delete(hFigPr); end
            
            % creates the figure object
            cbFcn = @obj.closeGUI;
            obj.hFig = figure('Position',fPos,'tag','figInitTrackStats',...
                              'MenuBar','None','Toolbar','None',...
                              'Name','Initial Tracking Statistics',...
                              'NumberTitle','off','Visible','off',...
                              'Resize','off','CloseRequestFcn',cbFcn); 
                                          
            % creates the outer panel object
            pPos = [obj.dX*[1,1],fPos(3:4)-2*obj.dX];            
            obj.hPanel = uipanel(obj.hFig,'Title','','Units','Pixels',...
                                          'Position',pPos);
            
            % ------------------------------- %
            % --- INFORMATION TABLE PANEL --- %
            % ------------------------------- %
                                      
            % creates the table panel
            pPosT = [obj.dY*[1,1],pPos(3)-obj.dX,obj.hghtPanelT];
            obj.hPanelT = uipanel(obj.hPanel,'Title','','Units','Pixels',...
                                             'Position',pPosT);
                                         
            % creates the table objects
            obj.tPos = [obj.dY*[1,1],pPosT(3)-obj.dX,hghtTable];             
                                         
            % creates the text label object
            txtStr = 'Display Metric: ';
            y0 = sum(obj.tPos([2,4])) + (obj.dY+2);
            txtPos = [obj.dY,y0+2,obj.widTxt,obj.hghtTxt];
            obj.hTextM = uicontrol(obj.hPanelT,'Units','Pixels',...
                            'Position',txtPos,'String',txtStr,...
                            'FontUnits','Pixels','FontWeight','bold',...
                            'FontSize',obj.txtSz,'HorizontalAlignment',...
                            'Right','Style','Text');             
            
            % creates the popupmenu object
            cbFcn = @obj.popupChangeMetric;
            ppPos = [sum(txtPos([1,3])),y0,obj.widPopup,obj.hghtPopup];
            lStr = {'Z-Score (Residual)','Z-Score (X-Corr)',...
                    'Template SSIM'}';
            obj.hPopupM = uicontrol(obj.hPanelT,'Units','Pixels',...
                                   'Style','PopupMenu','Value',1,...
                                   'Position',ppPos,'String',lStr,...
                                   'Callback',cbFcn);                        
            
            % creates the checkbox object
            x0 = obj.dX+sum(ppPos([1,3]));
            chkStr = 'Show Highlight Marker';
            chkPos = [x0,y0,obj.widCheck,obj.hghtCheck];
            cbFcn = @obj.checkShowHighlight;
            obj.hCheckH = uicontrol(obj.hPanelT,'Style','CheckBox',...
                            'Units','Pixels','Position',chkPos,...
                            'FontUnits','pixels','FontWeight','bold',...
                            'FontSize',obj.txtSz,'Callback',cbFcn,...
                            'String',chkStr,'Enable','off');
                               
            % ---------------------------- %
            % --- VIEWING OPTION PANEL --- %
            % ---------------------------- %
                                         
            % creates the table panel
            y0 = sum(pPosT([2,4])) + obj.dY;
            pPosI = [obj.dY,y0,obj.widPanelP,obj.hghtPanelI];
            obj.hPanelI = uipanel(obj.hPanel,'Title','','Units','Pixels',...
                                             'Position',pPosI);   
                                        
            % creates the text label object
            txtStr = 'Selected Region: ';
            txtPos = [obj.dY,obj.dX+2,obj.widTxt,obj.hghtTxt];            
            obj.hTextR = uicontrol(obj.hPanelI,'Units','Pixels',...
                            'Position',txtPos,'String',txtStr,...
                            'FontUnits','Pixels','FontWeight','bold',...
                            'FontSize',obj.txtSz,'HorizontalAlignment',...
                            'Right','Style','Text');             
            
            % creates the popupmenu object
            lStr = obj.setupRegionString();
            cbFcn = @obj.popupChangeRegion;
            ppPos = [sum(txtPos([1,3])),obj.dX,obj.widPopup,obj.hghtPopup];            
            obj.hPopupR = uicontrol(obj.hPanelI,'Units','Pixels',...
                                   'Style','PopupMenu','Value',1,...
                                   'Position',ppPos,'String',lStr,...
                                   'Callback',cbFcn);                                   
            
            % creates the checkbox object
            x0 = obj.dX+sum(ppPos([1,3]));
            chkStr = 'Show Statistics Summary';
            chkPos = [x0,obj.dX,obj.widCheck,obj.hghtCheck];
            cbFcn = @obj.checkShowSummary;
            obj.hCheckM = uicontrol(obj.hPanelI,'Style','CheckBox',...
                            'Units','Pixels','Position',chkPos,...
                            'FontUnits','pixels','FontWeight','bold',...
                            'FontSize',obj.txtSz,'Callback',cbFcn,...
                            'String',chkStr);                                 
                               
            % -------------------------- %
            % --- TABLE OBJECT SETUP --- %
            % -------------------------- %
            
            % creates the table object
            obj.setupTableData();   
            obj.createTableObject(true);                        
            
        end        
        
        % -------------------------- %
        % --- CALLBACK FUNCTIONS --- %
        % -------------------------- %            
        
        % --- popup menu region selection callback function
        function popupChangeRegion(obj, ~, ~)
            
            % updates the table data
            if get(obj.hCheckM,'Value')
                obj.setupSummaryData();
            else
                obj.setupTableData();
            end
            
            % updates the table with the new data            
            obj.resetTableData();
            
        end        
        
        % --- popup menu metric selection callback function
        function popupChangeMetric(obj, ~, ~)
            
            % updates the table with the new data
            obj.setupTableData();
            obj.resetTableData()
            
        end
        
        % --- checkbox show summary callback function
        function checkShowSummary(obj, hCheck, ~)
            
            % updates the other object enabled properties
            isShow = get(hCheck,'Value');
            setObjEnable(obj.hTextM,~isShow);
            setObjEnable(obj.hPopupM,~isShow);
            setObjEnable(obj.hCheckH,~isShow);
            
            % updates the table with the new data
            if isShow
                % sets the summary table data
                obj.setupSummaryData();
                
                % removes 
                set(obj.hCheckH,'Value',0)
                obj.checkShowHighlight(obj.hCheckH, [])
            else
                % sets the normal table data
                obj.setupTableData();
            end
            
            % updates the table with the new data
            obj.createTableObject(false);            
            
        end
        
        % --- checkbox show summary callback function
        function checkShowHighlight(obj, hCheck, ~) 
            
            hMarkH = findall(obj.hAx,'tag','hMarkH');
            setObjVisibility(hMarkH,get(hCheck,'Value'))
            
        end
        
        % --- table edit starting 
        function tableEditStart(obj, jTable, evnt)
            
            if get(evnt,'ClickCount') == 1
                obj.tableCellSelect([],[]);
            else
                obj.jTable.getCellEditor.stopCellEditing();               
            end
            
        end
        
        % --- table cell selection callback function
        function tableCellSelect(obj, ~, ~)
            
            % if the summary data is showing, then exit
            if get(obj.hCheckM,'Value'); return; end
            
            % parameters
            iColGap = 4;
            
            % retrieves the selected row/column indices
            iRow = obj.jTable.getSelectedRow + 1;
            iCol = obj.jTable.getSelectedColumn + 1;
                        
            % if the row/column indices is invalid, or a gap, then exit            
            if isempty(iRow) || isempty(iCol) || (iCol == iColGap)
                return
            end            
            
            % sets the global frame index
            switch iCol
                case 1
                    % case is the overall maximum
                    if iRow > length(obj.iMin)
                        return
                    else
                        iFrmG = obj.iMin(iRow);
                    end
                    
                case 2
                    % case is the overall minimum
                    if iRow > length(obj.iMax)
                        return
                    else
                        iFrmG = obj.iMax(iRow);
                    end
                    
                case 3
                    % case is the average 
                    return
                    
                otherwise
                    % case is the regular frame 
                    iFrmG = iCol - iColGap;
            end
                  
            % determines the phase/frame 
            iFrmT = [0;cumsum(cellfun('length',obj.bgObj.indFrm))];
            iPhase = find(iFrmG <= iFrmT(2:end),1,'first');
            iFrm = iFrmG - iFrmT(iPhase);   
            
            % updates the selected frame
            obj.bgObj.iPara.cFrm = iFrm;
            obj.bgObj.iPara.cPhase = iPhase;
            obj.bgObj.iPara.nFrm = length(obj.bgObj.indFrm{iPhase});
            
            % updates the display
            set(obj.bgObj.hGUI.editPhaseCount,'String',num2str(iPhase))
            set(obj.bgObj.hGUI.editFrameCount,'String',num2str(iFrm))            
            obj.bgObj.editPhaseCount(obj.bgObj.hGUI.editPhaseCount, [])
            
            % updates the highlight marker
            setObjEnable(obj.hCheckH,'on');
            obj.updateHighlightMarker(iPhase,iFrm,iRow);
            
        end
                
        % --- resets the table data values
        function tableCellChange(obj, ~, evnt)
            
            % if updating, then exit
            if obj.isUpdating; return; end
            
            % retrieves the altered row/column indices
            [iRow,iCol] = deal(evnt.getFirstRow,evnt.getColumn);            

            % resets the cell table value
            obj.isUpdating = true;
            pause(0.05);
            
            obj.jTable.setValueAt(obj.Data{iRow+1,iCol+1},iRow,iCol);
            obj.isUpdating = false;
            
        end
        
        % --- deletes the GUI
        function closeGUI(obj, ~, evnt)
            
            % deletes the marker 
            hMarkH = findall(obj.hAx,'tag','hMarkH');
            if ~isempty(hMarkH); delete(hMarkH); end
          
            % determines if calling the function directly
            if ~isempty(evnt)
                % if so, run the phases stats menu item
                hMenu = obj.bgObj.hGUI.menuShowStats;
                obj.bgObj.menuShowStats(hMenu,[]);                
            else
                % otherwise, delete the figure object
                delete(obj.hFig);
            end
            
        end        
        
        % -------------------------------------- %
        % --- TABLE INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- creates the table object
        function createTableObject(obj,isInit)
            
            % deletes any existing tables
            if ~isInit
                delete(obj.hTable);
            end
            
            % creates the table object
            obj.hTable = uitable(obj.hPanelT,'Units','Pixels',...
                                             'Position',obj.tPos);
            
            % initialises the other gui objects
            obj.initFuncDepTable();
            obj.initFuncCellComp();                           
            
        end
        
        % --- initialises the function dependency table
        function initFuncDepTable(obj)

            % other initialisations
            sGap = 2;                                 
            reqWid = 50*[1,1,1];
            obj.cWid0 = [reqWid,sGap];                   

            % sets the table header strings
            hdrStr = obj.cHdr;       

            % creates the java table object
            jSP0 = findjobj(obj.hTable);
            [jS, hContainer] = createJavaComponent(jSP0,[],obj.hPanelT);
            set(hContainer,'Units','Pixels','Position',obj.tPos)

            % creates the java table model
            obj.jTable = jS.getViewport.getView;
            jTableMod = ...
                  javax.swing.table.DefaultTableModel(obj.Data,hdrStr);
            obj.jTable.setModel(jTableMod);
            
            % sets the table callback function
            cbFcnE = @obj.tableEditStart;            
            jTM = handle(obj.jTable,'callbackproperties');            
            addJavaObjCallback(jTM,'MousePressedCallback',cbFcnE);
            
            % creates the table cell renderer
            obj.tabCR = ColoredFieldCellRenderer(obj.white);

            % sets the table text to black
            for i = 1:size(obj.Data,1)
                for j = 1:size(obj.Data,2)
                    obj.tabCR.setCellFgColor(i-1,j-1,obj.black);
                end
            end          
            
            % disables the smart alignment
            obj.tabCR.setSmartAlign(false);

            % sets the cell renderer horizontal alignment flags
            obj.tabCR.setHorizontalAlignment(0)

            % sets the column models for each table column
            for cID = 1:length(hdrStr)
                obj.updateColumnModel(cID);
            end

            % updates the table header colour
            gridCol = getJavaColour(0.5*ones(1,3));
            obj.jTable.getTableHeader().setBackground(gridCol);
            obj.jTable.setGridColor(gridCol);
            obj.jTable.setShowGrid(true);

            % disables the resizing
            jTableHdr = obj.jTable.getTableHeader(); 
            jTableHdr.setResizingAllowed(false); 
            jTableHdr.setReorderingAllowed(false);
            obj.jTable.setAutoCreateRowSorter(true);

            % repaints the table
            obj.jTable.repaint()
            obj.jTable.setAutoResizeMode(obj.jTable.AUTO_RESIZE_OFF)                        
            
        end              
        
        % --- initialises the function cell compatibility table colours
        function initFuncCellComp(obj)
            
            % sets the background colours based on the column indices
            for i = 1:size(obj.Data,1)
                for j = 1:size(obj.Data,2)
                    % case is the experiment compatibility columns
                    cCol = obj.bgCol{i,j};
                    obj.tabCR.setCellBgColor(i-1,j-1,cCol);
                end
            end

            % repaints the table
            obj.jTable.repaint(); 
            
        end
        
        % ------------------------------ %
        % --- TABLE UPDATE FUNCTIONS --- %
        % ------------------------------ %        
        
        % --- initialises the function cell compatibility table colours
        function resetTableData(obj)
            
            % flag that the table is updating
            obj.isUpdating = true;
            pause(0.05);
            
            % sets the column editable flags
            isEdit = false(1,size(obj.Data,2));
            set(obj.hTable,'ColumnEditable',isEdit)
            
            % sets the background colours based on the column indices
            for i = 1:size(obj.Data,1)
                for j = 1:size(obj.Data,2)
                    % case is the experiment compatibility columns
                    cCol = obj.bgCol{i,j};
                    obj.tabCR.setCellBgColor(i-1,j-1,cCol);
                    obj.jTable.setValueAt(obj.Data{i,j},i-1,j-1);
                end
            end

            % repaints the table
            obj.jTable.repaint();
            
            % flag that the table is updating
            obj.isUpdating = false;            
            
        end                            
        
        % --- updates the column model
        function updateColumnModel(obj,iCol,cWid)

            % sets the default input arguments
            if get(obj.hCheckM,'Value')
                if mod(iCol,4) == 0
                    cWid = 2;
                else
                    cWid = 82 + any(iCol == [1,4]);
                end
            else
                if ~exist('cWid','var')
                    if iCol > length(obj.cWid0)
                        cWid = obj.expWid;
                    else
                        cWid = obj.cWid0(iCol);
                    end
                end
            end
            
            % retrieves the column model
            cMdl = obj.jTable.getColumnModel.getColumn(iCol-1);
            
            % updates the column widths and renderer
            cMdl.setMinWidth(cWid)
            cMdl.setMaxWidth(cWid)
            
            % updates the column renderer
            cMdl.setCellRenderer(obj.tabCR);            

        end           
        
        % ----------------------- %
        % --- OTHER FUNCTIONS --- %
        % ----------------------- %
        
        % --- sets up the summary table data
        function setupSummaryData(obj)
            
            % retrieves the selected values
            iApp = get(obj.hPopupR,'Value');
            
            % sets the row count/indices
            iSR = 1:obj.bgObj.nTube(iApp);
            nMaxSR = max(obj.bgObj.nTube);
            
            % sets the base column header
            mStr = {'Z-Score (R)','Z-Score (XC)','SSIM'};
            sStr = {'Min','Max','Avg'};
            
            % sets the column header strings
            obj.cHdr = cell(1,length(mStr)*(length(sStr)+1)-1);
            for i = 1:length(mStr)
                % sets the main header string
                for j = 1:length(sStr)
                    k = (i-1)*(length(sStr)+1)+j;
                    obj.cHdr{k} = createTableHdrString({mStr{i},sStr{j}});
                end
                
                % sets the gap string
                if i < length(mStr)
                    obj.cHdr{i*(length(sStr)+1)} = '';
                end
            end                      
            
            % retrieves the metric values
            indOK = obj.getValidFrames();
            nCol = (length(sStr)+1)*obj.nMet - 1;            
            [obj.iMin,obj.iMax] = deal(NaN(nMaxSR,3));
            [obj.Data,obj.bgCol] = deal(cell(nMaxSR,nCol));            
            
            % sets the table data values
            for iMet = 1:obj.nMet
                % retrieves the metric values            
                yMet = cell2mat(obj.pStats(iApp,:,iMet));
                yMet(isnan(yMet)) = 0;
                yMet(:,~indOK) = NaN;                
                
                % determines the min/max metric values                
                [yMin,obj.iMin(iSR,iMet)] = min(yMet,[],2,'omitnan');
                [yMax,obj.iMax(iSR,iMet)] = max(yMet,[],2,'omitnan');
                yMean = mean(yMet,2,'omitnan');
            
                % sets the final table data
                isZ = iMet < obj.nMet;
                iCol = (iMet-1)*(length(sStr)+1);
                obj.Data(iSR,iCol+1) = obj.setValueStr(yMin,isZ);
                obj.Data(iSR,iCol+2) = obj.setValueStr(yMax,isZ);
                obj.Data(iSR,iCol+3) = obj.setValueStr(yMean,isZ);
                
                % removes any rejected regions
                obj.Data(~obj.bgObj.iMov.flyok(:,iApp),:) = {'---'};
                
                % sets up the background colours
                iC = max(1,iCol):(iCol+3);
                obj.bgCol(:,iC) = cellfun(@(x)...
                        (obj.getCellColour(x,iMet)),obj.Data(:,iC),'un',0);                            
            end
            
        end
        
        % --- sets up the table data
        function setupTableData(obj)
            
            % retrieves the selected values     
            indFrm = obj.bgObj.indFrm;
            iApp = get(obj.hPopupR,'Value');
            iMet = get(obj.hPopupM,'Value');
            
            % sets the row count/indices
            isZ = iMet < obj.nMet;
            iSR = 1:obj.bgObj.nTube(iApp);
            xiSR = 1:max(obj.bgObj.nTube);
            
            % sets the base column header
            obj.rHdr = arrayfun(@(x)(sprintf('Fly %i',x)),xiSR,'un',0)';
            colHdr = cellfun(@(x)(arrayfun(@(y)(sprintf('Frm %i',y)),...
                                    1:length(x),'un',0)),indFrm,'un',0);

            % appends the index to each phase
            for i = 1:obj.nPhase
                colHdr{i} = cellfun(@(x)(createTableHdrString(...
                        {x,sprintf('(P%i)',i)})),colHdr{i},'un',0);
            end

            % combines the column headers into a single cell array
            cHdr0 = cell2cell(colHdr(:)',0);
            
            % sets the final column header 
            obj.cHdr = [{createTableHdrString({'Overall','Min'}),...
                         createTableHdrString({'Overall','Max'}),...
                         createTableHdrString({'Overall','Avg'}),...
                         ' '},cHdr0];            
                     
            % retrieves the metric values
            indOK = obj.getValidFrames();
            yMet = cell2mat(obj.pStats(iApp,:,iMet));
            yMet(isnan(yMet)) = 0;
            yMet(:,~indOK) = NaN;
            
            % determines the min/max/mean metric values
            [yMin,obj.iMin] = min(yMet,[],2,'omitnan');
            [yMax,obj.iMax] = max(yMet,[],2,'omitnan');
            yMean = mean(yMet,2,'omitnan');
            
            % sets the final table data
            obj.Data = cell(xiSR(end),size(yMet,2)+4);
            obj.Data(iSR,1) = obj.setValueStr(yMin,isZ);
            obj.Data(iSR,2) = obj.setValueStr(yMax,isZ);
            obj.Data(iSR,3) = obj.setValueStr(yMean,isZ);
            obj.Data(iSR,5:end) = obj.setValueStr(yMet,isZ);
            
            % removes any rejected regions
            obj.Data(~obj.bgObj.iMov.flyok(:,iApp),:) = {'---'};            
            
            % retrieves the background colours
            obj.bgCol = cellfun(@(x)...
                        (obj.getCellColour(x,iMet)),obj.Data,'un',0);
            
        end        
        
        % --- retrieves the valid (low/hi-variance) phase frames
        function indOK = getValidFrames(obj)

            % determines the feasible (low/hi-variance) phases
            iAcc = [1,2,4];
            [iFrm,vPh] = deal(obj.bgObj.indFrm,obj.bgObj.iMov.vPhase);
            indOK = logical(cell2mat(cellfun(@(x,y)((any(y==iAcc))*ones...
                        (length(x),1)),iFrm,num2cell(vPh),'un',0)));            
            
        end
        
        % --- sets up the region strings
        function rStr = setupRegionString(obj)
            
            nApp = length(obj.bgObj.iMov.iR);
            rStr = arrayfun(@(x)(sprintf('Region #%i',x)),1:nApp,'un',0)';
            
        end        
        
        % --- retrieves the cell colour (based on the value, pVal)
        function pCol = getCellColour(obj,pStr,iMet)
            
            % sets the RGB colour array based on the value, pVal
            pVal = str2double(pStr);
            if isempty(pVal)
                % case is the cell is empty
                pRGB = 0.25*[1,1,1];
            elseif isnan(pVal)
                % case is the cell is a NaN value
                pRGB = 0.50*[1,1,1];
            else
                % case is a valid numeric value
                cMap = colormap('hsv');
                nCol = ceil(size(cMap,1)/3);
                

                pMap = 1 + (nCol-1)*obj.calcBoltzValue...
                                (obj.pL{iMet},obj.kL{iMet},pVal);
                pRGB = interp1(1:size(cMap,1),cMap,pMap,'linear');
            end
            
            % retrieves the java colour
            pCol = getJavaColour(pRGB);
            
        end       
        
        % --- calculates the cross-correlation image stack
        function Ixc = calcXCorrImgStack(obj,Img0)
            
            % memory allocation
            tP = obj.bgObj.iMov.tPara;

            % calculates the gradient correlation masks
            [Gx,Gy] = imgradientxy(Img0,'sobel');
            Ixc0 = max(0,calcXCorr(tP.GxT,Gx) + calcXCorr(tP.GyT,Gy));

            % applies the image filter (if required)
            if isempty(obj.hS)
                Ixc = Ixc0/2;
            else
                Ixc = imfilter(Ixc0,obj.hS)/2;
            end
            
        end      
        
        % updates the highlight marker
        function updateHighlightMarker(obj,iPhase,iFrm,iTube) 
        
            % initialisations
            iApp = get(obj.hPopupR,'Value');
            
            if iTube > getSRCount(obj.bgObj.iMov,iApp)
                fPos = NaN(1,2);
                set(obj.hCheckH,'Value',0,'Enable','on');                
            else
                fPos = obj.bgObj.fPos{iPhase}{iApp,iFrm}(iTube,:);
                set(obj.hCheckH,'Value',1,'Enable','on');
            end
            
            % retrieves the highlight marker handle
            hMarkH = findall(obj.hAx,'tag','hMarkH');
            if isempty(hMarkH)
                % if it doesn't exist, then create one
                hold(obj.hAx,'on')
                plot(obj.hAx,fPos(1),fPos(2),'yo','markersize',...
                               obj.bgObj.mSz,'linewidth',3,'tag','hMarkH');
                hold(obj.hAx,'on')                
            else
                % otherwise, update the marker position
                set(hMarkH,'xdata',fPos(1),'ydata',fPos(2),'Visible','on');
            end
        
        end
        
    end
    
    % static class methods
    methods (Static)
        
        % --- converts the numeric values to strings
        function yStr = setValueStr(yVal,isZ)
            
            if isZ
                yStr = arrayfun(@(x)(sprintf('%.1f',x)),yVal,'un',0);
            else
                yStr = arrayfun(@(x)(sprintf('%.3f',x)),yVal,'un',0);                
            end
            
        end
        
        % --- calculate the shape factors
        function kL = calcShapeFactor(pL)
            
            % initialisations
            pTol = 0.05;            
            [xH,x0] = deal(pL(2),pL([1,3]));
            
            % calculates the shape factors
            kL = -(1./(x0-xH)).*log((1./[pTol,(1-pTol)])-1);
            
        end
        
        % --- calculates the boltzmann function values
        function Y = calcBoltzValue(pL,kL,x)
            
            % initialisations
            xH = pL(2);
            
            % calculates the boltzmann function value
            if x <= xH
                Y = 1./(1 + exp(-kL(1)*(x-xH)));
            else
                Y = 1./(1 + exp(-kL(2)*(x-xH)));
            end
            
        end        
        
    end
    
end