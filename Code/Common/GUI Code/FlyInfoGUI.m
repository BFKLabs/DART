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
        jTable
        rTable
        hTick
        
        % other fields           
        isVis
        ok
        nRow
        nCol
        iGrp
        Data        
        nNaN
        tInact
        bgCol
        cHdr        
        
        % parameters
        iTab = NaN;
        Type = 1;
        dX = 10;
        Dmin = 3;
        tBin = 10;
        
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
            obj.initObjProps();
            obj.setupInfoTable();
            
            % repositions the sub-gui
            obj.repositionGUI();     
            pause(0.05);
            setObjVisibility(obj.hFig,isVis);
            
        end

        % ------------------------------------ %        
        % --- GUI INITIALISATION FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- initialises the object properties
        function initObjProps(obj)
           
            % creates the figure object
            fPos = [100,100,200,70];
            
            % creates the figure object
            obj.hFig = figure('Position',fPos,'tag','figFlyInfoCond',...
                              'MenuBar','None','Toolbar','None',...
                              'Name','Individual Fly Information',...
                              'NumberTitle','off','Visible','off',...
                              'Resize','off');  
            
            % creates the panel object
            pPos = [obj.dX*[1,1],fPos(3:4)-2*obj.dX];
            obj.hPanel = uipanel(obj.hFig,'Title','','Units','Pixels',...
                                          'Position',pPos);            
                                      
            % sets the acceptance flag array            
            obj.ok = obj.iMov.flyok;
            if ~isempty(obj.snTot)
                % calculates the other fly information
                obj.initFlyInfo()
                ppPos = [10,15,165,25];
                
                % creates the popup menu object (for data combining type)
                lStr = {'Accept/Reject','Longest Inactive','NaN Count'}';
                cbFcn = {@obj.popupChange,obj};
                obj.hPopup = uicontrol(obj.hPanel,'Units','Pixels',...
                                       'Position',ppPos,'String',lStr,...
                                       'Callback',cbFcn);                
            end
            
            % sets the grouping indices
            if isfield(obj.iMov,'pInfo')
                obj.iGrp = obj.iMov.pInfo.iGrp; 
            else
                obj.iGrp = ones(size(obj.ok));                
            end             
            
            % sets the data array and table column names
            obj.Data = obj.setupDataArray(num2cell(obj.ok));  
            [obj.nRow,obj.nCol] = size(obj.Data);
            
            % removes the close request function
            if isempty(obj.snTot)
                cbFcn = {@obj.closeGUI,obj};
                set(obj.hFig,'CloseRequestFcn',cbFcn);
            else
                set(obj.hFig,'CloseRequestFcn',[]);
            end
            
            % sets up the cell background colour array
            colArr = getAllGroupColours(max(obj.iGrp(:)));            
            if obj.iMov.is2D
                obj.bgCol = arrayfun(@(x)(...
                           getJavaColour(colArr(x+1,:))),obj.iGrp,'un',0);
            else
                % memory allocation
                nFly = size(obj.ok,1);
                iGrpC = arr2vec(obj.iGrp')'; 
                
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
                        iCol(1:nFlyR(i),i) = iGrpC(i);
                        obj.Data((nFlyR(i)+1):end,i) = {[]};
                    end
                end
                
                % sets the background colours
                obj.bgCol = arrayfun(@(x)(getJavaColour(...
                                        colArr(x+1,:))),iCol,'un',0);
            end
            
            % sets up the table column names
            if obj.iMov.is2D
                obj.cHdr = cellfun(@(x)(sprintf('%s #%i','Column',x)),...
                                    num2cell(1:size(obj.Data,2)),'un',0); 
            else
                obj.cHdr = setup1DRegionNames(obj.iMov.pInfo,3);
            end
            
            % sets the timer object
            obj.hTick = tic;

        end
        
        % --- sets up the data array (removes any missing/none regions)
        function DataArr = setupDataArray(obj, DataArr)
            
            %
            if ~isfield(obj.snTot,'cID'); return; end
            
            %
            szArr = size(DataArr);
            pC0 = cell2mat(obj.snTot.cID(:));
            
            % sets the row/column indices of the known sub-regions 
            if obj.snTot.iMov.is2D
                % case is for 2D expt setups
                pC = pC0(:,1:2);
            else
                % case is for 1D expt setups
                iCol = (pC0(:,1)-1)*obj.snTot.iMov.pInfo.nCol + pC0(:,2);
                pC = [pC0(:,3),iCol];
            end
            
            % removes the missing items
            isMiss = ~setGroup(sub2ind(szArr,pC(:,1),pC(:,2)),szArr);
            [DataArr(isMiss),obj.ok(isMiss)] = deal({[]},false);
            
        end
        
        % --- creates the information table
        function setupInfoTable(obj)
           
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
            
            % parameters
            [fPos,WT] = deal(get(obj.hFig,'Position'),0);            
            
            % updates the progress bar (if it exists)
            if ~isempty(obj.hProp)
                obj.hProp.Update(1,'Creating Information GUI Objects',0.8);
            end
            
            % creates the checkbox table
            obj.createCheckTable();             
            
            % Create the base panel
            obj.hPanelV = uipanel('Parent',obj.hPanel,'Clipping','on',...
                                 'BorderType','none','tag',...
                                 'hPanelView','Units','Normalized');
            
            % Draw table in scroll pane
            jTableH = handle(obj.jTable,'Callbackproperties');
            jSP = javaObjectEDT('javax.swing.JScrollPane',jTableH);
            jSP.setRowHeaderView(obj.rTable);
            jSP.setCorner(jSP.UPPER_LEFT_CORNER,...
                                        obj.rTable.getTableHeader());
                                    
            % retrieves the matlab handle
            [~, hContainer] = createJavaComponent(jSP, [], obj.hPanelV);
            
            % determines the overall maximum table width
            tFont = jTableH.getTableHeader.getFont();
            for i = 1:length(obj.cHdr)
                tFontObj = tFont.getStringBounds(obj.cHdr{i},fRC);
                WT = max(WT,tFontObj.getWidth());
            end

            % sets the table height/width
            hOfs = 2;
            H = jTableH.getPreferredSize.getHeight() + 4 + ...
                jTableH.getTableHeader().getPreferredSize().getHeight();            
            W = obj.rTable.getColumnModel.getColumn(0).getWidth() + ...
                jTableH.getPreferredSize.getWidth();
            pPos = round([obj.dX*[1,1] W (H+hOfs)]);
            
            % updates the progressbar
            if ~isempty(obj.hProp)
                obj.hProp.Update(1,'Repositioning GUI Objects',0.9);
            end
            
            % sets the object position and locations
            set(obj.hFig,'position',[fPos(1:2),pPos(3:4)+2*obj.dX])
            set(obj.hPanel,'position',[obj.dX*[1 1],pPos(3:4)]);
            set(obj.hPanelV,'position',[0 0 1 1],'Units','Pixels')
            set(hContainer,'Units','Normalized','position',[0 0 1 1])
            drawnow;

            % resets the finer locations of the table/figure position
            resetObjPos(obj.hPanelV,'left',obj.dX)
            resetObjPos(obj.hPanelV,'bottom',obj.dX)
            resetObjPos(obj.hPanel,'width',2*obj.dX,1)
            resetObjPos(obj.hPanel,'height',2*obj.dX,1)
            resetObjPos(obj.hFig,'width',2*obj.dX,1)
            resetObjPos(obj.hFig,'height',2*obj.dX,1)  
            
            %
            if obj.snTot.iMov.is2D

            else
                % removes any rejected groups from the table
                xiR = 1:obj.jTable.getRowCount;
                for i = find(~obj.snTot.iMov.ok(:)')
                    arrayfun(@(x)(obj.jTable.setValueAt([],x-1,i-1)),xiR)
                    obj.jTable.repaint;
                end
            end

        end
        
        % --- creates the check table 
        function createCheckTable(obj,jSP)
            
            % Create table model
            modTypeStr = 'javax.swing.table.DefaultTableModel';
            jTabMod = javaObjectEDT(modTypeStr,obj.Data,obj.cHdr);
            jTabMod = handle(jTabMod,'callbackproperties');
                
            % creates the table objects
            obj.jTable = CondCheckTable(jTabMod,obj.Type,obj.bgCol);
                                
            % sets the java object callback functions
            cbFcn = {@obj.tableCellChange};
            addJavaObjCallback(jTabMod,'TableChangedCallback',cbFcn)
            
            % resets the panel viewport
            if exist('jSP','var')
                try
                    jSP.setViewportView(obj.jTable);
                    jSP.repaint(jSP.getBounds());
                end
            end
            
            % creates the table row headers 
            obj.rTable = RowNumberTable(obj.jTable,double(obj.iMov.is2D));
            
        end
        
        % --- initialises the fly information for the table
        function initFlyInfo(obj)
            
            % retrieves the dimensions of the apparatus            
            [nFly,nApp] = deal(size(obj.ok,1),sum(obj.snTot.iMov.ok));
            [obj.nNaN,obj.tInact] = deal(zeros(nFly,nApp));
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
                                      'Metrics (Region %i of %i)'],i,nApp);
                    obj.hProp.Update(1,wStrNw,0.7*(i/nApp));
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
            iNw = [evnt.getFirstRow+1,evnt.getColumn+1];

            % retrieves the ok flags and the indices of the altered cell
            nwValue = obj.jTable.getValueAt(iNw(1)-1,iNw(2)-1);
            if isempty(nwValue); nwValue = false; end
            obj.ok(iNw(1),iNw(2)) = nwValue;

            % updates the sub-region data struct
            if ~isempty(obj.snTot)                
                % determines if the grouping traces is selected
                grpCheck = get(obj.hGUI.menuAvgSpeedGroup,'Checked');
                if strcmp(grpCheck,'on')
                    % if so, then update the main trace again
                    if hTimeNw > 0.1                    
                        pObj = getappdata(obj.hFigMain,'pltObj');
                        pObj.updatePosPlot();                    
                    end

                else 
                    % case is updating non-group trace fields
                    iApp = get(obj.hGUI.popupAppPlot,'value');    
                    if iApp == iNw(2)
                        % updates the trace object visibility field
                        hFigM = obj.hFigMain;
                        hPos = findall(hFigM,'UserData',iNw(1),...
                                             'Tag','hPos');
                        setObjVisibility(hPos,nwValue);

                        % updates the fill object visibility field
                        hGrpF = findall(hFigM,'UserData',iNw(1),...
                                              'tag','hGrpFill');
                        setObjVisibility(hGrpF,nwValue);
                        
                        bgC = obj.bgCol{iNw(1),iNw(2)};
                        set(hGrpF,'FaceColor',bgC.getColorComponents([]))
                    end
                    
                    % updates the flag within the solution data struct
                    iTabR = getappdata(obj.hFigMain,'iTab');
                    sInfo = getappdata(obj.hFigMain,'sInfo');
                    sInfo{iTabR}.snTot.iMov.flyok(iNw(1),iNw(2)) = nwValue;
                    setappdata(obj.hFigMain,'sInfo',sInfo)
                    
                end
            else
                % updates the sub-region data struct
                [cbObj,hGUIM] = deal(obj.hGUI,obj.hGUI.hGUI);
                [cbObj.iMov.flyok,cbObj.isChange] = deal(obj.ok,true);    
                cbObj.iMov.ok(iNw(2)) = any(cbObj.iMov.flyok(:,iNw(2)));   

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
                    vcObj.updateFillColour(fColT,iNw(2),iNw(1));
                    
                    % updates the plot marker visibility properties
                    hMarkT = cbObj.hFig.mkObj.hMark{iNw(2)}{iNw(1)};
                    setObjVisibility(hMarkT,nwValue);
                    pause(0.01);
                    
                else
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
        
        % --- gui close callback function
        function closeFigure(obj,~)
            
            % deletes the GUI
            setappdata(obj.hFigMain,'hGUIInfo',[])
            delete(obj.hFig);
            
        end
        
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
    
    % static class methods
    methods (Static)
        % --- popup menu selection callback function
        function popupChange(hPopup, evnt, obj)
            
            % REMOVE ME
            a = 1;
            
        end
        
        % --- closes the gui
        function closeGUI(hFig, evnt, obj)
            
            % removes the menu check
            hh = guidata(obj.hFigMain);
            set(hh.menuFlyAccRej,'Checked','off');
            
            % deletes the GUI
            delete(obj.hFig);
            
        end              
        
    end
end
