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
        
        % other fields
        is2D      
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
        Type = 1;
        dX = 10;
        Dmin = 3;
        tBin = 10;
        
    end
    
    % class methods
    methods
        % class custructor
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
            obj.is2D = is2DCheck(obj.iMov);
            
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
            ind = 1:length(obj.iMov.ok);
            obj.ok = obj.iMov.flyok(:,ind);
            if isempty(obj.snTot)
                % case is the bg calculation type
                obj.ok(:,~obj.iMov.ok) = false;                
                
            else
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
            if is2DCheck(obj.iMov)
                obj.bgCol = arrayfun(@(x)(...
                           getJavaColour(colArr(x+1,:))),obj.iGrp,'un',0);
            else
                nFly = size(obj.ok,1);
                iGrpC = arr2vec(obj.iGrp')';                
                bgCol0 = arrayfun(@(x)(repmat({getJavaColour(...
                                colArr(x+1,:))},nFly,1)),iGrpC,'un',0);
                obj.bgCol = cell2cell(bgCol0,0);
            end
            
            % sets up the table column names
            if obj.is2D
                obj.cHdr = cellfun(@(x)(sprintf('%s #%i','Column',x)),...
                                    num2cell(1:size(obj.Data,2)),'un',0); 
            else
                obj.cHdr = setup1DRegionNames(obj.iMov.pInfo,3);
            end
            
        end
        
        % --- sets up the data array (removes any missing/none regions)
        function DataArr = setupDataArray(obj, DataArr)
            
%             % sets the table data array
%             for i = 1:length(obj.iMov.ok)
%                 if obj.iMov.ok(i)
%                     DataArr((getSRCount(obj.iMov,i)+1):end,i) = {[]};
%                 end
%             end      
            
            % removes any None groups from the table
            DataArr(~obj.iMov.flyok) = {[]};
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
            wStr = warning('off','all');
            [~, hContainer] = javacomponent(jSP, [], obj.hPanelV);
            warning(wStr);     
            
            % updates the progress bar            
            
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
        end
        
        % --- creates the check table 
        function createCheckTable(obj, jSP)
            
            % Create table model
            modTypeStr = 'javax.swing.table.DefaultTableModel';
            jTabMod = javaObjectEDT(modTypeStr,obj.Data,obj.cHdr);
            jTabMod = handle(jTabMod,'callbackproperties');
                
            % creates the table objects
            obj.jTable = CondCheckTable(jTabMod,obj.Type,obj.bgCol);
                                
            % sets the java object callback functions
            cbFcn = {@obj.tableCellChange,obj};
            addJavaObjCallback(jTabMod,'TableChangedCallback',cbFcn)
            
            % resets the panel viewport
            if exist('jSP','var')
                try
                    jSP.setViewportView(obj.jTable);
                    jSP.repaint(jSP.getBounds());
                end
            end
            
            % creates the table row headers 
            obj.rTable = RowNumberTable(obj.jTable,obj.is2D);
            
        end
        
        % --- initialises the fly information for the table
        function initFlyInfo(obj)
            
            % retrieves the dimensions of the apparatus            
            [nFly,nApp] = deal(size(obj.ok,1),sum(obj.snTot.iMov.ok));
            [obj.nNaN,obj.tInact] = deal(zeros(nFly,nApp));
            nFrm = length(cell2mat(obj.snTot.T));
            
            % calculates the NaN counts/inactive times for each apparatus
            for i = 1:nApp
                % updates the waitbar figure
                wStrNw = sprintf(['Calculating Combined Dataset ',...
                                  'Metrics (Region %i of %i)'],i,nApp);
                obj.hProp.Update(1,wStrNw,0.7*(i/nApp));

                % retrieves the position/distance travelled values    
                if i == 1
                    T = cell2mat(obj.snTot.T);
                    indB = detTimeBinIndices(T,obj.tBin);    
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
                ii = ~cellfun(@isempty,jGrp);    
                tInactNw = cellfun(@(y)(max(cellfun(@length,y))),jGrp(ii))';                    
                obj.tInact(ii,i) = roundP(tInactNw*obj.tBin/60,1);

                % clears the arrays
                clear Px Dtot; pause(0.01);
            end
            
        end
        
        % --- gui close callback function
        function closeFigure(obj, ~)
            
            % deletes the GUI
            delete(obj.hFig);
            
        end
        
        % --- repositions the sub-gui
        function repositionGUI(obj)
            
            repositionSubGUI(obj.hFigMain,obj.hFig); 
            
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
        
        % --- table information cell change callback function
        function tableCellChange(hTable, evnt, obj)
            
            % global variables
            global isPlotAll tableUpdating
            tableUpdating = true;

            % sets the cell selection callback function (non background estimate)
            indNw = [evnt.getFirstRow+1,evnt.getColumn+1];

            % retrieves the ok flags and the indices of the altered cell
            newValue = obj.jTable.getValueAt(indNw(1)-1,indNw(2)-1);
            if isempty(newValue); newValue = false; end
            obj.ok(indNw(1),indNw(2)) = newValue;

            % updates the sub-region data struct
            if ~isempty(obj.snTot)
                % if the apparatus being updating is also being shown on 
                % the combined solution viewing GUI, then update the figure
                hFigM = obj.hGUI.figFlyCombine;
                if isPlotAll
                    hPos = findobj(hFigM,'UserData',indNw(2),'Tag','hPos');
                    setObjVisibility(hPos,evnt.NewData);        
                else
                    % determines if the grouping traces is selected
                    grpCheck = get(obj.hGUI.menuAvgSpeedGroup,'Checked');
                    if strcmp(grpCheck,'on')
                        % if so, then update the main trace again
                        updateFcn = getappdata(obj.hFigMain,'updatePlot');
                        updateFcn(obj.hGUI);
                                              
                    else 
                        % case is updating non-group trace fields
                        iApp = get(obj.hGUI.popupAppPlot,'value');    
                        if iApp == indNw(2)
                            % updates the trace object visibility field
                            hPos = findall(hFigM,'UserData',indNw(1),...
                                                 'Tag','hPos');
                            setObjVisibility(hPos,newValue);

                            % updates the fill object visibility field
                            hGrpF = findall(hFigM,'UserData',indNw(1),...
                                                  'tag','hGrpFill');
                            setObjVisibility(hGrpF,newValue);
                        end
                    end
                end
            else
                % updates the sub-region data struct
                [cbObj,hGUIM] = deal(obj.hGUI,obj.hGUI.hGUI);
                cbObj.iMov.flyok = obj.ok;    
                cbObj.iMov.ok(indNw(2)) = any(cbObj.iMov.flyok(:,indNw(2)));   

                % retrieves the tube show check callback function 
                cFuncStr = 'checkShowTube_Callback';
                cFunc = getappdata(hGUIM.figFlyTrack,cFuncStr);
                cFunc2 = get(hGUIM.checkFlyMarkers,'Callback');

                % updates the tubes visibility
                hGUIM.iMov = obj.iMov;
                cFunc(hGUIM.checkShowTube,num2str(...
                                get(hGUIM.checkTubeRegions,'value')),hGUIM)   
                cFunc2(hGUIM.checkFlyMarkers,[])    
            end
            
            % resets the update flag
            tableUpdating = false;
            
        end        
        
    end
end