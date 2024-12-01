classdef SolnDiagCheck < handle
    
    % class properties
    properties
    
        % main class fields
        nNaN
        dFrm
        hFigM
        hGUIM
        
        % main object handle class fields
        hFig
        hTableS
        jTableS
        
        % failed segmentation frame class fields
        hPanelF
        hTableF
        jTableF
        hTxtFL
        
        % inter-frame displacement class fields
        hPanelD
        hTableD
        jTableD
        hEditD
        hTxtD
        hTxtDL
        
        % control button object class fields
        hPanelC
        hButC        
        
        % fixed object dimension fields
        dX = 10;
        dHght = 25;
        hghtTxt = 16;
        hghtBut = 25;
        hghtEdit = 22;
        hghtRow = 25;
        hghtPanelC = 40;
        widPanel = 380;
        widTxtD = 260;
        
        % calculated object dimension fields
        hghtFig
        widFig
        hghtPanelF
        hghtPanelD
        hghtTableF
        hghtTableD
        widTable
        widTxtL
        widButC
        
        % static scalar fields
        nRowF
        nRowD   
        nColT = 5;
        nButC = 2;
        dTol = 10;
        nRowMx = 10;
        fSzH = 13;
        fSzL = 12;
        fSz = 10 + 2/3;
        
        % static string fields
        tagStr = 'figDiagCheck';
        figName = 'Solution Diagnostic Check';
        tStrFL = 'All Video Frame Were Segmented Correctly';
        tStrDL = 'All Inter-Frame Displacements Within Tolerance';
        
    end
    
    % class methods
    methods
    
        % --- class constructor
        function obj = SolnDiagCheck(hFigM)
            
            % sets the input arguments
            obj.hFigM = hFigM;
            obj.hGUIM = obj.hFigM.hGUI;
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initClassObjects();            
            
        end

        % -------------------------------------- %        
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)            
            
            % field retrieval
            obj.nNaN = obj.hFigM.nNaN;
            obj.dFrm = obj.hFigM.Dfrm;
            
            % makes the main window invisible
            setObjVisibility(obj.hFigM,0);
            
            % ------------------------------------- %
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- % 
            
            % height offset
            hOfs = obj.dX + obj.dHght;
            
            % case is there is at least one failed frame
            obj.hghtTableF = calcTableHeight(obj.nRowMx);
            obj.hghtPanelF = obj.hghtTableF + hOfs;
            
            % case is there is at least 
            obj.hghtTableD = calcTableHeight(obj.nRowMx);
            obj.hghtPanelD = obj.hghtTableD + obj.hghtRow + hOfs;
            
            % calculates the object dimensions
            obj.hghtFig = obj.hghtPanelC + ...
                obj.hghtPanelD + obj.hghtPanelF + 4*obj.dX;
            obj.widFig = obj.widPanel + 2*obj.dX;
            
            % other object dimension calculations
            [obj.widTxtL,obj.widTable] = deal(obj.widPanel - 2*obj.dX);
            obj.widButC = (obj.widPanel - 2.5*obj.dX)/obj.nButC;
            
        end
        
        % --- initialises the class objects
        function initClassObjects(obj)
            
            % deletes any previous GUIs
            hPrev = findall(0,'tag',obj.tagStr);
            if ~isempty(hPrev); delete(hPrev); end
            
            % sets the table column widths
            cWid = {40,65,75,90,0};
            cWid{end} = obj.widTable - sum(cell2mat(cWid(1:end-1)));            
            
            % --------------------------- %
            % --- MAIN FIGURE OBJECTS --- %
            % --------------------------- %
            
            % creates the figure object
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % creates the figure object
            obj.hFig = createUIObj('figure','Position',fPos,...
                'tag',obj.tagStr,'MenuBar','None','Toolbar','None',...
                'Name',obj.figName,'NumberTitle','off','Visible','off',...
                'AutoResizeChildren','off','CloseRequestFcn',[]);            
            
            % ------------------------------ %
            % --- CONTROL BUTTON OBJECTS --- %
            % ------------------------------ %
            
            % initialisations
            bStrC = {'Goto Selected Frame','Close Window'};
            cbFcnC = {@obj.buttonGotoFrame,@obj.buttonClose};
            
            % creates the control button objects
            pPosC = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelC];
            obj.hPanelC = createUIObj(...
                'Panel',obj.hFig,'Position',pPosC,'Title',''); 
            
            % other initialisations
            obj.hButC = cell(length(bStrC),1);
            for i = 1:length(bStrC)
                % sets up the button position vector
                lBut = obj.dX + (i-1)*(obj.widButC + obj.dX/2);
                bPos = [lBut,obj.dX-2,obj.widButC,obj.hghtBut];
                
                % creates the button object
                obj.hButC{i} = createUIObj('Pushbutton',obj.hPanelC,...
                    'Position',bPos,'Callback',cbFcnC{i},...
                    'FontUnits','Pixels','FontSize',obj.fSzL,...
                    'FontWeight','Bold','String',bStrC{i});
            end            
            
            % disables the goto frame button
            setObjEnable(obj.hButC{1},0);
            
            % ---------------------------------------- %
            % --- INTER-FRAME DISPLACEMENT OBJECTS --- %
            % ---------------------------------------- %
            
            % initialisations
            cbFcnD = @obj.editFrameDist;
            tHdrD = 'INTER-FRAME DISPLACEMENT';            
            tStrD = 'Large Displacement Threshold Limit (mm)';
            cHdrD = {'#','Region','Sub Region','Frame Index','Distance'};
            cFormD = repmat({'numeric'},1,length(cHdrD));
            cEditD = false(1,length(cHdrD));                        
            
            % creates the panel object
            yPosD = sum(pPosC([2,4])) + obj.dX;
            pPosD = [obj.dX,yPosD,obj.widPanel,obj.hghtPanelD];
            obj.hPanelD = createUIObj('Panel',obj.hFig,...
                'Position',pPosD,'Title',tHdrD,'FontSize',obj.fSzH,...
                'FontWeight','Bold');
            
            % creates the table object
            pPosTD = [obj.dX*[1,1],obj.widTable,obj.hghtTableD];
            obj.hTableD = createUIObj('table',obj.hPanelD,...
                'Data',[],'Position',pPosTD,'ColumnName',cHdrD,...
                'ColumnEditable',cEditD,'ColumnFormat',cFormD,...
                'RowName',[],'ColumnWidth',cWid,...
                'CellSelectionCallback',@obj.tableDistSelect);
            
            % creates the parameter objects
            yPosD = sum(pPosTD([2,4])) + obj.dX/2;
            [obj.hEditD,obj.hTxtD] = ...
                obj.createEditGroup(obj.hPanelD,tStrD,yPosD);
            set(obj.hEditD,'Callback',cbFcnD,'String',num2str(obj.dTol));
            
            % creates the null text label object
            pPosDL = [obj.dX*[1,1],obj.widTxtL,obj.hghtTxt];
            obj.hTxtDL = createUIObj('text',obj.hPanelD,...
                'Position',pPosDL,'String',obj.tStrDL,...
                'FontWeight','Bold','FontSize',obj.fSzL,...
                'HorizontalAlignment','Center');            
            
            % auto-resizes the table columns
            obj.jTableD = getJavaTable(obj.hTableD);
            autoResizeTableColumns(obj.hTableD);            
            
            % ----------------------------------- %
            % --- FAILED SEGMENTATION OBJECTS --- %
            % ----------------------------------- %
            
            % initialisations
            tHdrF = 'FAILED SEGMENTATION FRAMES';
            cHdrF = {'#','Region','Sub Region','Start Frame','End Frame'};
            cFormF = repmat({'numeric'},1,length(cHdrF));
            cEditF = false(1,length(cHdrF));
            
            % creates the panel object
            yPosF = sum(pPosD([2,4])) + obj.dX;
            pPosF = [obj.dX,yPosF,obj.widPanel,obj.hghtPanelF];
            obj.hPanelF = createUIObj('Panel',obj.hFig,...
                'Position',pPosF,'Title',tHdrF,'FontSize',obj.fSzH,...
                'FontWeight','Bold');            
            
            % creates the table object
            pPosTF = [obj.dX*[1,1],obj.widTable,obj.hghtTableF];
            obj.hTableF = createUIObj('table',obj.hPanelF,...
                'Data',[],'Position',pPosTF,'ColumnName',cHdrF,...
                'ColumnEditable',cEditF,'ColumnFormat',cFormF,...
                'RowName',[],'ColumnWidth',cWid,...
                'CellSelectionCallback',@obj.tableNaNSelect);

            % creates the null text label object
            pPosFL = [obj.dX*[1,1],obj.widTxtL,obj.hghtTxt];
            obj.hTxtFL = createUIObj('text',obj.hPanelF,...
                'Position',pPosFL,'String',obj.tStrFL,...
                'FontWeight','Bold','FontSize',obj.fSzL,...
                'HorizontalAlignment','Center');
            
            % auto-resizes the table columns
            obj.jTableF = getJavaTable(obj.hTableF);
            autoResizeTableColumns(obj.hTableF);            
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % updates the NaN/distance tables
            obj.updateDistTable(false);
            obj.updateNaNTable(false);            
                        
            % centers the figure and makes it visible
            centerfig(obj.hFig);
            refresh(obj.hFig);
            pause(0.05);
            
            % makes the figure visible
            set(obj.hFig,'Visible','on');            
            
        end
        
        %---------------------------------- %
        % --- OBJECT CREATION FUNCTIONS --- %
        %---------------------------------- %
        
        % --- creates the text label combo objects
        function [hEdit,hTxt] = createEditGroup(obj,hP,tTxt,yOfs)
            
            % initialisations
            tTxtL = sprintf('%s: ',tTxt);
            widEdit = hP.Position(3) - (2*obj.dX + obj.widTxtD);
            
            % sets up the text label
            pPosL = [obj.dX,yOfs+2,obj.widTxtD,obj.hghtTxt];
            hTxt = createUIObj('text',hP,'Position',pPosL,...
                'FontSize',obj.fSzL,'HorizontalAlignment','Right',...
                'String',tTxtL,'FontWeight','Bold');
            
            % creates the text object
            pPosE = [sum(pPosL([1,3])),yOfs,widEdit,obj.hghtEdit];
            hEdit = createUIObj(...
                'edit',hP,'Position',pPosE,'FontSize',obj.fSz);            
            
        end
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %        
        
        % --- NaN count table selection callback function
        function tableNaNSelect(obj, ~, evnt)
            
            % if the indices are empty, then exit
            if isempty(evnt.Indices); return; end
            
            % removes the table selection for the other table
            if ~isequal(obj.jTableS,obj.jTableF)
                obj.jTableS.changeSelection(-1,-1, false, false);
                [obj.jTableS,obj.hTableS] = deal(obj.jTableF,obj.hTableF);
            end
            
            % updates the other object properties
            iColS = evnt.Indices(2);
            obj.jTableS = obj.jTableF;
            setObjEnable(obj.hButC{1},any(iColS == [4,5]));
            
        end
        
        % --- NaN count table selection callback function
        function tableDistSelect(obj, ~, evnt)
            
            % if the indices are empty, then exit
            if isempty(evnt.Indices); return; end
            
            % removes the table selection for the other table
            if ~isequal(obj.jTableS,obj.jTableD)
                obj.jTableS.changeSelection(-1,-1, false, false);
                [obj.jTableS,obj.hTableS] = deal(obj.jTableD,obj.hTableD);
            end
            
            % updates the other object properties
            iColS = evnt.Indices(2);
            obj.jTableS = obj.jTableD;
            setObjEnable(obj.hButC{1},iColS == 4);
            
        end        
        
        % --- frame distance editbox callback function
        function editFrameDist(obj, hEdit, ~)
            
            % field retrieval
            nwVal = str2double(hEdit.String);
            
            % determines if the new value is valid
            if chkEditValue(nwVal,[10,inf],0)
                % if so, update the parameter and table values
                obj.dTol = nwVal;
                obj.updateDistTable();
                
            else
                % otherwise, revert to the previous value
                hEdit.String = num2str(obj.dTol);
            end
            
        end        
        
        % --- goto frame pushbutton callback function
        function buttonGotoFrame(obj, hObj, ~)        
        
            % field retrieval
            iRow = obj.jTableS.getSelectedRows + 1;
            iCol = obj.jTableS.getSelectedColumns + 1;
            iFrm = obj.hTableS.Data{iRow,iCol};
            
            % updates the frame counter
            obj.hGUIM.frmCountEdit.String = num2str(iFrm);
            feval(obj.hGUIM.figFlyTrack.dispImage,obj.hGUIM);
            
            % disables the button
            setObjEnable(hObj,0);
            
        end
        
        % --- close window pushbutton callback function
        function buttonClose(obj, ~, ~)
            
            % deletes the main window
            delete(obj.hFig);
            
            % makes the main window visible again
            setObjVisibility(obj.hFigM,1);            
            
        end        

        % ------------------------------ %        
        % --- TABLE UPDATE FUNCTIONS --- %
        % ------------------------------ %

        % --- updates the distance tolerance table
        function updateDistTable(obj,hideFig)
            
            % sets the default input arguments
            if ~exist('hideFig','var'); hideFig = true; end
            
            % hides the figure (if required)
            if hideFig; setObjVisibility(obj.hFig,0); end            
            
            % initialisations            
            hghtPanel0 = obj.hPanelD.Position(4);
            hOfs = obj.dX + obj.hghtRow + obj.dHght;
            
            % determines frames where distance is greater than tolerance
            dFrmT = cellfun(@(x)(find(x > obj.dTol)),obj.dFrm,'un',0);
            nDCount = cellfun('length',dFrmT);
            
            % determines if the there any frames above tolerance
            if all(nDCount(:) == 0)
                % makes the table invisible
                setObjVisibility(obj.hTableD,0); 
                setObjVisibility(obj.hTxtDL,1); 
                
                % resets the other objects
                obj.hTxtDL.Position(2) = obj.dX;
                obj.hEditD.Position(2) = 3*obj.dX; 
                obj.hTxtD.Position(2) = 3*obj.dX + 2;
                
                % resets the panel height
                obj.hPanelD.Position(4) = hOfs + 2*obj.dX;                
                
            else
                % determines the regions which have NaN values
                nGrp = sum(nDCount(:));
                [iNaN,jNaN] = find(nDCount > 0);                
                
                % resets the table/panel dimensions
                hghtTab = calcTableHeight(min(obj.nRowMx,nGrp));
                obj.hTableD.Position(4) = hghtTab;
                obj.hPanelD.Position(4) = hghtTab + hOfs;
                obj.hTxtD.Position(2) = (3/2)*obj.dX + hghtTab + 2;
                obj.hEditD.Position(2) = (3/2)*obj.dX + hghtTab;
                
                % sets the data into the table
                [Data,tOfs] = deal(cell(length(jNaN),obj.nColT),0);
                for i = 1:length(jNaN)
                    dFrmNw = dFrmT{iNaN(i),jNaN(i)};
                    for j = 1:length(dFrmNw)
                        % sets the apparatus and tube indices
                        iFrmNw = dFrmNw(j);
                        Data{j+tOfs,2} = jNaN(i);
                        Data{j+tOfs,3} = iNaN(i);
                        Data{j+tOfs,4} = iFrmNw;
                        Data{j+tOfs,5} = obj.dFrm{iNaN(i),jNaN(i)}(iFrmNw);
                    end
                    
                    % increments the table offset counter
                    tOfs = tOfs + length(dFrmNw);                    
                end
                
                % sort arrays by distance (in descending order)
                [~,ii] = sort(cell2mat(Data(:,end)),'descend');
                Data = Data(ii,:); 
                Data(:,1) = num2cell(1:size(Data,1));                
                
                % resets the table properties
                set(obj.hTableD,'Data',Data,'Visible','on');
                setObjVisibility(obj.hTxtDL,'off')
            end
            
            % resets the position of the other objects
            dHghtNw = obj.hPanelD.Position(4) - hghtPanel0;
            resetObjPos(obj.hPanelF,'Bottom',dHghtNw,1);
            resetObjPos(obj.hFig,'Height',dHghtNw,1);
            
            % reshows the figure (if required)
            if hideFig; setObjVisibility(obj.hFig,1); end
            
        end        
        
        % --- updates the NaN count table
        function updateNaNTable(obj,hideFig)
            
            % sets the default input arguments
            if ~exist('hideFig','var'); hideFig = true; end
            
            % initialisations
            hghtPanel0 = obj.hPanelF.Position(4);            
                
            % hides the figure (if required)
            if hideFig; setObjVisibility(obj.hFig,0); end
            
            % determines array entries where NaN count is greater than zero
            nNaNCount = cellfun('length',obj.nNaN);
            
            if all(nNaNCount == 0)
                % resets the panel dimensions
                obj.hPanelF.Position(4) = 3*obj.dX + obj.hghtRow;

                % makes the table invisible
                setObjVisibility(obj.hTableF,0)
                setObjVisibility(obj.hTxtFL,1)
                
            else
                % determines the regions which have NaN values
                nGrp = sum(nNaNCount(:));
                [iNaN,jNaN] = find(nNaNCount > 0);
                hOfs = 3/2*obj.dX + obj.hghtRow;
                
                % resets the table/panel dimensions
                hghtTab = calcTableHeight(min(obj.nRowMx,nGrp));                
                obj.hTableF.Position(4) = hghtTab;
                obj.hPanelF.Position(4) = hghtTab + hOfs;
            
                % sets the data into the table
                [Data,tOfs] = deal(cell(length(jNaN),obj.nColT),0);
                for i = 1:length(jNaN)
                    nNaNnw = obj.nNaN{iNaN(i),jNaN(i)};
                    for j = 1:length(nNaNnw)
                        % sets the apparatus and tube indices
                        Data{j+tOfs,1} = j+tOfs;
                        Data{j+tOfs,2} = jNaN(i);
                        Data{j+tOfs,3} = iNaN(i);
                        Data{j+tOfs,4} = nNaNnw{j}(1);
                        Data{j+tOfs,5} = nNaNnw{j}(end);
                    end
                    
                    % increments the table offset counter
                    tOfs = tOfs + length(nNaNnw);
                end
                
                % resets the table properties
                set(obj.hTableF,'Visible','on','Data',Data);                
                setObjVisibility(obj.hTxtFL,0);
            end
            
            % resets the table position
            dHghtNw = obj.hPanelF.Position(4) - hghtPanel0;
            resetObjPos(obj.hFig,'Height',dHghtNw,1)            
            
            % reshows the figure (if required)
            if hideFig; setObjVisibility(obj.hFig,1); end            
            
        end
    
    end
    
end