classdef FlyInfoGUI < handle
    
    % class properties
    properties
        
        % input arguments
        hGUI
        snTot
        hProp
        iMov        
        
        % gui object handles
        hFig
        hFigMain
        hPanel
        hPanelV
        hPopup
        hTick
        
        % table object handle fields        
        jTable        
        rTable
        hPanelT         
        
        % other table class fields
        hTable
        Data
        bgCol
        cHdr
                
        % tracking metric fields
        nNaN
        tInact
        
        % other important class fields           
        ok
        iGrp        
        
        % variable dimension fields
        nRow
        nCol
        nApp  
        nTable

        % boolean class fields
        isVis      
        isTrans
        isMltTrk                
        
        % parameters
        iTab = NaN;
        Type = 1;
        hOfs = 2;
        dX = 10;
        Dmin = 3;
        tBin = 10;
        nColMax = 10;
        
        % static string fields
        tagStr = 'figFlyInfoCond';
        modType = 'javax.swing.table.DefaultTableModel'
        
    end
    
    % class methods
    methods
        
        % --- class custructor
        function obj = FlyInfoGUI(hGUI, snTot, hProp, isVis)
    
            % sets the default input arguments
            if ~exist('isVis','var'); isVis = true; end            
            
            % sets the input arguments
            obj.hGUI = hGUI;
            if ~exist('snTot','var')
                % case is running the gui from the background estimation
                obj.iMov = hGUI.iMov;
                obj.hFigMain = obj.hGUI.hFig;    
                
            else
                % case is running the gui through the data combining gui
                obj.hFigMain = hGUI.figFlyCombine;
                [obj.snTot,obj.hProp] = deal(snTot,hProp);
                obj.iMov = obj.snTot.iMov;
                
                % sets the currently selected tab
                hTabGrp = getappdata(obj.hFigMain,'hTabGrp');
                obj.iTab = get(get(hTabGrp,'SelectedTab'),'UserData');
            end            
            
            % initialises the object properties
            obj.initClassFields();
            obj.initClassObjects();
            
            % repositions the sub-gui
            obj.repositionGUI();
            pause(0.05);
            setObjVisibility(obj.hFig,isVis);
            
        end

        % ------------------------------------ %        
        % --- GUI INITIALISATION FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % acceptance flags
            obj.ok = obj.iMov.flyok;
            obj.nApp = length(obj.iMov.iR);
            obj.isMltTrk = detMltTrkStatus(obj.iMov);
            
            % sets the data array and table column names
            obj.calcOptimalConfig();
            obj.Data = obj.setupDataArray(num2cell(obj.ok));            
            
            % sets the grouping indices
            if isfield(obj.iMov,'pInfo')
                obj.iGrp = obj.iMov.pInfo.iGrp; 
            else
                obj.iGrp = ones(size(obj.ok));                
            end            
            
            % sets up the cell background colour array
            colArr = getAllGroupColours(max(obj.iGrp(:)));
            if obj.iMov.is2D || obj.isMltTrk
                % case is the 2D setup
                obj.bgCol = arrayfun(@(x)(...
                           getJavaColour(colArr(x+1,:))),obj.iGrp,'un',0);

            else
                % memory allocation
                nFly = size(obj.ok,1);
                iGrpC = arr2vec(obj.iGrp')';
                
                % sets the group ID flags (1D sub-grouped setup)
                if detIfCustomGrid(obj.iMov)
                    gID = arr2vec(obj.iMov.pInfo.gID')';
                    colArr = getAllGroupColours(max(cellfun(@max,gID)));
                end
                
                % retrieves the sub-region count for each region
                if isempty(obj.snTot) || isempty(obj.snTot.Px)
                    nFlyR = arr2vec(getSRCount(obj.iMov)')';
                else
                    nFlyR = cellfun(@(x)(size(x,2)),obj.snTot.Px);
                end
                
                % removes any rejected regions
                nFlyR(~obj.iMov.ok) = NaN;
                
                % sets the grouping indices
                iCol = zeros(nFly,length(iGrpC));
                for i = 1:size(iCol,2)
                    if ~isnan(nFlyR(i))
                        % sets the colour 
                        if detIfCustomGrid(obj.iMov)
                            iCol(1:nFlyR(i),i) = gID{i};
                        else
                            iCol(1:nFlyR(i),i) = iGrpC(i);
                        end
                           
                        % clears any extraneous fields
                        obj.Data((nFlyR(i)+1):end,i) = {[]};
                    end
                end
                
                % sets the background colours
                obj.bgCol = arrayfun(@(x)(getJavaColour(...
                                        colArr(x+1,:))),iCol,'un',0);
            end                                    
            
            % sets up the table column names
            if obj.isTrans
                % case is transposed data
                xiF = 1:size(obj.Data,1);
                obj.cHdr = arrayfun(@(x)(...
                    sprintf('Fly #%i',x)),xiF,'un',0); 
                
            elseif obj.iMov.is2D || obj.isMltTrk
                % case is 2D experimental setup
                xiH = 1:size(obj.Data,2);
                obj.cHdr = arrayfun(@(x)(...
                    sprintf('Column #%i',x)),xiH,'un',0); 
                
            else
                % case is 1D experimental setup
                obj.cHdr = setup1DRegionNames(obj.iMov.pInfo,3);
            end                        
            
            % transposes the array if necessary            
            if obj.isTrans
                obj.Data = obj.Data';
                obj.bgCol = obj.bgCol';                
            end            
            
        end
        
        % --- initialises the object properties
        function initClassObjects(obj)
           
            % removes any previous GUIs
            hFigPr = findall(0,'tag',obj.tagStr);
            if ~isempty(hFigPr); delete(hFigPr); end
                        
            % -------------------------- %
            % --- MAIN CLASS OBJECTS --- %
            % -------------------------- %            
            
            % creates the figure object
            fPos = [100,100,200,200];
            
            % creates the figure object
            obj.hFig = figure('Position',fPos,'tag',obj.tagStr,...
                              'MenuBar','None','Toolbar','None',...
                              'Name','Individual Fly Information',...
                              'NumberTitle','off','Visible','off',...
                              'Resize','off');  
            
            % creates the panel object
            pPos0 = [0,0,fPos(3:4)] + obj.dX*[1,1,-2,2];
            obj.hPanel = createUIObj('panel',...
                obj.hFig,'Title','','Units','Pixels','Position',pPos0);
                                      
            % sets the acceptance flag array                        
            if ~isempty(obj.snTot)
                % calculates the other fly information
                obj.initFlyInfo()
                ppPos = [10,15,165,25];
                
                % creates the popup menu object (for data combining type)
                lStr = {'Accept/Reject','Longest Inactive','NaN Count'}';
                cbFcn = @obj.popupChange;
                obj.hPopup = uicontrol(obj.hPanel,'Units','Pixels',...
                                       'Position',ppPos,'String',lStr,...
                                       'Callback',cbFcn);                
            end                        
            
            % removes the close request function
            if isempty(obj.snTot)
                set(obj.hFig,'CloseRequestFcn',@obj.hideFigure);
            else
                set(obj.hFig,'CloseRequestFcn',[]);
            end            
            
            % initialises the check table object
            obj.initCheckTable();
            
            % resets the panel/figure dimensions to fit the tables
            szDimP = obj.hPanelT.Position(3:4);
            obj.hPanel.Position(3:4) = szDimP + 2*obj.dX;
            obj.hFig.Position(3:4) = szDimP + 4*obj.dX;
            
            % sets the timer object
            obj.hTick = tic;

        end
        
        % --- calculates the optihmal table configuration
        function calcOptimalConfig(obj)
            
            % determines if the 
            obj.isTrans = size(obj.ok,2) > obj.nColMax;
                        
        end                           
                
        % --- initialises the fly information for the table
        function initFlyInfo(obj)
            
            % retrieves the dimensions of the apparatus            
            [nFly,nAppC] = deal(size(obj.ok,1),sum(obj.snTot.iMov.ok));
            [obj.nNaN,obj.tInact] = deal(zeros(nFly,nAppC));
            nFrm = length(cell2mat(obj.snTot.T));
            
            % sets the time bin
            T = cell2mat(obj.snTot.T);
            indB = detTimeBinIndices(T,obj.tBin);             
            hasData = ~cellfun('isempty',obj.snTot.Px);
            
            % calculates the NaN counts/inactive times for each apparatus
            for i = find(hasData(:))'
                % updates the waitbar figure
                if ~isempty(obj.hProp)
                    wStrNw = sprintf(['Calculating Combined Dataset ',...
                                      'Metrics (Region %i of %i)'],i,nAppC);
                    obj.hProp.Update(1,wStrNw,0.7*(i/nAppC));
                end

                % calculates the binned range values
                Px = obj.snTot.Px{i};
                Dtot0 = cellfun(@(x)(range(Px(x,:),1)),indB,'un',0);
                Dtot = cell2mat(Dtot0);

                % calculates the number of NaN locations
                obj.nNaN(1:size(Dtot,2),i) = ...
                                    roundP(100*sum(isnan(Px),1)/nFrm',0.1);

                % calculates the inactive times
                fInact = num2cell((Dtot < obj.Dmin) | isnan(Dtot),1);
                jGrp = cellfun(@(x)(getGroupIndex(x)),fInact,'un',false);

                % determines which flies were actually inactive, and 
                % calculates the inactive times
                ii = ~cellfun('isempty',jGrp);    
                tInactNw = cellfun(@(y)(max(cellfun('length',y))),jGrp(ii))';
                obj.tInact(ii,i) = roundP(tInactNw*obj.tBin/60,1);

                % clears the arrays
                clear Px Dtot; pause(0.01);
            end
            
        end

        % ----------------------------- %        
        % --- TABLE SETUP FUNCTIONS --- %
        % ----------------------------- %
        
        % --- initialises the class objects
        function initCheckTable(obj)
                        
            % java imports
            import java.awt.font.FontRenderContext;
            import java.awt.geom.AffineTransform;

            % creates the font render context object
            aTF = javaObjectEDT('java.awt.geom.AffineTransform');
            fRC = javaObjectEDT(...
                        'java.awt.font.FontRenderContext',aTF,true,true);
                   
            % Ensure all drawing is caught up before creating the table
            drawnow                        
            
            % ------------------------------------------- %
            % --- INITIALISATIONS & MEMORY ALLOCATION --- %
            % ------------------------------------------- %            
            
            % Create the base panel
            obj.hPanelT = createUIObj('panel',obj.hPanel,...
                         'BorderType','none','tag','hPanelView',...
                         'Clipping','on','Units','Normalized');                        

            % creates the check table object
            obj.createCheckTable();                     
                        
            % Draw table in scroll pane
            tHdr = obj.rTable.getTableHeader();
            jTableH = handle(obj.jTable,'Callbackproperties');
            jSP = javaObjectEDT('javax.swing.JScrollPane',jTableH);
            jSP.setRowHeaderView(obj.rTable);
            jSP.setCorner(jSP.UPPER_LEFT_CORNER,tHdr);
            
            % retrieves the matlab handle
            [~, hC] = createJavaComponent(jSP, [], obj.hPanelT);            
                     
            % determines the overall maximum table width            
            [tFont,WT] = deal(jTableH.getTableHeader.getFont(),0);
            for i = 1:length(obj.cHdr)
                tFontObj = tFont.getStringBounds(obj.cHdr{i},fRC);
                WT = max(WT,tFontObj.getWidth());
            end  
            
            % sets the table height/width            
            H = jTableH.getPreferredSize.getHeight() + 4 + ...
                jTableH.getTableHeader().getPreferredSize().getHeight();
            W = jTableH.getPreferredSize.getWidth() + ...
                obj.rTable.getColumnModel.getColumn(0).getWidth();
            pPos = round([obj.dX*[1,1] W (H+obj.hOfs)]);
            
            % sets the object position and locations            
            pPosT = [obj.dX,obj.dX,pPos(3:4)-4];
            set(obj.hPanelT,'Units','Pixels','Position',pPosT)
            set(hC,'Units','Normalized','Position',[0 0 1 1])
            drawnow;     
        
            % removes any rejected groups from the table (1D only)
            if ~isempty(obj.snTot)
                if ~obj.snTot.iMov.is2D
                    xiR = 1:obj.jTable.getRowCount;
                    for i = find(~obj.snTot.iMov.ok(:)')
                        % if the region is rejected, then remove the column
                        arrayfun(@(x)(...
                            obj.jTable.setValueAt([],x-1,i-1)),xiR)
                        obj.jTable.repaint;
                    end
                end
            end
            
        end        
        
        % --- creates the check table object
        function createCheckTable(obj)
            
            % Create table model
            jTabMod = javaObjectEDT(...
                obj.modType,obj.Data,obj.cHdr);
            jTabMod = handle(jTabMod,'callbackproperties');                
            
            % creates the table objects
            obj.jTable = ...
                CondCheckTable(jTabMod,obj.Type,obj.bgCol);
                                
            % sets the java object callback functions
            cbFcn = {@obj.tableCellChange};
            addJavaObjCallback(jTabMod,'TableChangedCallback',cbFcn)
            
            % sets the table type flag
            if obj.isTrans
                iType = -obj.iMov.pInfo.nCol;
            else
                iType = double(obj.iMov.is2D || obj.isMltTrk);
            end
            
            % creates the table row headers                         
            obj.rTable = RowNumberTable(obj.jTable,iType);
            
        end        
        
        % -------------------------- %
        % --- CALLBACK FUNCTIONS --- %
        % -------------------------- %
        
        % --- table information cell change callback function
        function tableCellChange(obj, ~, evnt)
            
            % global variables
            global tableUpdating
            tableUpdating = true;

            % determines the timer difference between last update
            hTimeNw = toc(obj.hTick);
            obj.hTick = tic;

            % sets the cell selection callback function (non background estimate)
            [iNw,iNwG] = deal([evnt.getFirstRow+1,evnt.getColumn+1]);
            if obj.isTrans; iNwG = flip(iNwG); end

            % retrieves the ok flags and the indices of the altered cell
            nwValue = obj.jTable.getValueAt(iNw(1)-1,iNw(2)-1);
            if isempty(nwValue); nwValue = false; end            
            obj.ok(iNwG(1),iNwG(2)) = nwValue;

            % updates the sub-region data struct
            if ~isempty(obj.snTot)                
                % determines if the grouping traces is selected
                grpCheck = get(obj.hGUI.menuAvgSpeedGroup,'Checked');
                if strcmp(grpCheck,'on') || obj.isMltTrk
                    % if so, then update the main trace again
                    if hTimeNw > 0.1                    
                        pObj = getappdata(obj.hFigMain,'pltObj');
                        pObj.updatePosPlot();                    
                    end

                else 
                    % case is updating non-grouping trace fields
                    
                    % retrieves the selected region index
                    iApp = get(obj.hGUI.popupAppPlot,'value');                    
                    
                    % retrieves the plot handle indices
                    if obj.isMltTrk
                        % case is for multi-tracking
                        [iPltH,iApp] = obj.getPlotIndices(iApp);
                                                
                    else
                        % case is the other setup types
                        iPltH = iNwG(1);    
                    end
                    
                    if any(iApp == iNwG(2))
                        % updates the trace object visibility field
                        hFigM = obj.hFigMain;
                        hPos = arrayfun(@(x)(findall(...
                            hFigM,'UserData',x,'Tag','hPos')),iPltH);
                        setObjVisibility(hPos,nwValue);

                        % updates the fill object visibility field
                        hGrpF = arrayfun(@(x)(findall(...
                            hFigM,'UserData',x,'Tag','hGrpFill')),iPltH);                        
                        setObjVisibility(hGrpF,nwValue);
                        
                        % resets the table background color
                        bgC = obj.bgCol{iNw(1),iNw(2)};
                        set(hGrpF,'FaceColor',bgC.getColorComponents([]))
                    end
                    
                    % updates the flag within the solution data struct
                    iTabR = getappdata(obj.hFigMain,'iTab');
                    sInfo = getappdata(obj.hFigMain,'sInfo');
                    sInfo{iTabR}.snTot.iMov.flyok(iNwG(1),iNwG(2)) = nwValue;
                    setappdata(obj.hFigMain,'sInfo',sInfo)
                    
                end
            else
                % updates the sub-region data struct
                [cbObj,hGUIM] = deal(obj.hGUI,obj.hGUI.hGUI);
                [cbObj.iMov.flyok,cbObj.isChange] = deal(obj.ok,true);   
                
                % updates the region flags (non multi-tracking only)
                if ~obj.isMltTrk
                    cbObj.iMov.ok(iNwG(2)) = ...
                        any(cbObj.iMov.flyok(:,iNwG(2)));
                end

                % retrieves the tube show check callback function
                if cbObj.isCalib
                    % field retrieval
                    vcObj = cbObj.vcObj;
                    
                    % updates the flags
                    vcObj.iMov.flyok = obj.ok;
                    vcObj.iMov.ok = cbObj.iMov.ok;
                    
                    % resets the sub-region outlines                       
                    hGUIM.output.iMov.flyok = obj.ok;
                    vcObj.showRegion(vcObj.hChkH{1})
                    
                    % resets the calibration fill region colours
                    if nwValue
                        fColT = vcObj.fCol0;
                    else
                        fColT = vcObj.fCol{1};
                    end
                    
                    % updates the fill colour
                    vcObj.updateFillColour(fColT,iNwG(2),iNwG(1));
                    
                    % updates the plot marker visibility properties
                    hMarkT = cbObj.hFig.mkObj.hMark{iNwG(2)}{iNwG(1)};
                    setObjVisibility(hMarkT,nwValue);
                    pause(0.01);
                    
                else
                    % field retrieval
                    cFunc = get(hGUIM.figFlyTrack,'checkShowTube_Callback');
                    cFunc2 = get(hGUIM.checkFlyMarkers,'Callback');

                    % updates the tubes visibility
                    hGUIM.output.iMov.flyok = obj.ok;
                    cFunc(hGUIM.checkShowTube,num2str(...
                                get(hGUIM.checkTubeRegions,'value')),hGUIM)   
                    cFunc2(hGUIM.checkFlyMarkers,[]) 
                end
            end
            
            % resets the update flag
            tableUpdating = false;
            
        end          
        
        % --- popup menu selection callback function
        function popupChange(obj, ~, ~)
            
            % REMOVE ME
            a = 1;
            
        end
        
        % --- closes the gui
        function hideFigure(obj, ~, ~)
            
            % removes the menu check
            hh = guidata(obj.hFigMain);
            set(hh.menuFlyAccRej,'Checked','off');
            
            % deletes the GUI
            delete(obj.hFig);
            
        end        

        % --- gui close callback function
        function closeFigure(obj,~)
            
            % deletes the GUI
            setappdata(obj.hFigMain,'hGUIInfo',[])
            delete(obj.hFig);
            
        end
                
        % --------------------------------------- %
        % --- IMPORTANT ARRAY SETUP FUNCTIONS --- %
        % --------------------------------------- %        
        
        % --- sets up the table column index array
        function indC = setupColIndices(obj,nCol)
            
            nRowT = ceil(obj.nApp/nCol);
            indC = arrayfun(@(x)(...
                ((x-1)*nCol+1):min(obj.nApp,x*nCol)),1:nRowT,'un',0)';
                        
        end
            
        % --- sets up the data array (removes any missing/none regions)
        function dArr = setupDataArray(obj, dArr)                    
            
            % memory allocation
            szArr = size(dArr);            
            isFT = strcmp(obj.hFigMain.Tag,'figFlyTrack');
            
            % figure specific properties
            if isFT
                % case is accessing via background estimation
                iGrpD = obj.iMov.pInfo.iGrp;
                
            else
                % case is accessing via data combining
                if isfield(obj.snTot,'cID')
                    pC0 = cell2mat(obj.snTot.cID(:));
                else
                    return
                end
            end
            
            % sets the row/column indices of the known sub-regions
            if obj.isMltTrk
                % case is for multi-tracking
                isMiss0 = true(szArr);
                if isFT
                    isMiss(iGrpD > 0) = false;
                else
                    isMiss0(unique(pC0(:,1))) = false;
                    isMiss = isMiss0';
                end
            
            elseif isFT
                % case is accessing via fly tracking
                if is2DCheck(obj.iMov)
                    % case is a 2D setup
                    isMiss = iGrpD == 0;
                
                elseif detIfCustomGrid(obj.iMov)
                    % case is 1D expt setup (custom grid)
                    gID = obj.iMov.pInfo.gID;
                    isMiss = cell2mat(arr2vec(gID')') == 0;
                    
                else
                    % case is 1D expt setup (fixed grid)
                    isMiss = false(szArr);
                    isMiss(:,arr2vec(iGrpD')' == 0) = true;
                end
                    
            else
                % case is accessing via data combining
                if obj.snTot.iMov.is2D
                    % case is for 2D expt setups
                    pC = pC0(:,1:2);
                else
                    % case is for 1D expt setups
                    pInfo = obj.snTot.iMov.pInfo;
                    iCol = (pC0(:,1)-1)*pInfo.nCol + pC0(:,2);
                    pC = [pC0(:,3),iCol];
                end
            
                % removes the missing items
                indM = sub2ind(szArr,pC(:,1),pC(:,2));
                isMiss = ~setGroup(indM,szArr);
            end
               
            % removes any missing values
            [dArr(isMiss),obj.ok(isMiss)] = deal({[]},false);
            
        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- repositions the sub-gui
        function repositionGUI(obj)
            
            repositionSubGUI(obj.hFigMain,obj.hFig); 
            
        end
        
        % --- updates the solution file accepatance flags
        function updateSolutionFlags(obj)
            
            % if the apparatus being updating is also being shown on 
            % the combined solution viewing GUI, then update the figure
            hFigM = obj.hGUI.figFlyCombine;

            % updates the flag within the corresponding solution data
            % field (within the main GUI)
            sInfo0 = getappdata(hFigM,'sInfo');
            sInfo0{obj.iTab}.snTot.iMov.flyok = obj.ok;
            setappdata(hFigM,'sInfo',sInfo0);
            
        end              
        
    end
    
end
