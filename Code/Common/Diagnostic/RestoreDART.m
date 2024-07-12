classdef RestoreDART < handle
    
    % properties
    properties
    
        % main object class fields
        hFig
        
        % other object class fields
        hPanelD
        hTableD
        jTableD
        hPanelC
        hButC
        
        % fixed object dimensions
        dX = 10;
        widFig = 500;
        hghtFig = 300;
        hghtPanelC = 40;
        hghtBut = 25;
        
        % calculated object dimensions
        widPanel
        hghtPanelD
        hghtTableD
        widTableD
        widButC
        
        % figure property fields
        fObj
        fObjName
        
        % scalar class fields
        iSel
        nButC        
        fSzT = 12;
        fSz = 10 + 2/3;
        
        % text class fields
        tagStr = 'hFigRestore';
        figName = 'DART Figure Restore';
        bStrC = {'Show','Hide','Delete','Close Window'};
        
    end
    
    % --- class methods
    methods
        
        % --- class constructor
        function obj = RestoreDART()
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initClassObjects();
            
            % clears the output object (if not required)
            if (nargout == 0) && ~isdeployed
                clear obj
            end
            
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)            
            
            % memory calculation
            obj.nButC = length(obj.bStrC);
            obj.hButC = cell(obj.nButC,1);
            
            % -------------------------------------- %
            % --- OBJECT DIMENSIONS CALCULATIONS --- %
            % -------------------------------------- %                        
            
            % main object dimension calculations
            obj.widPanel = obj.widFig - 2*obj.dX;
            obj.widButC = (obj.widPanel - (obj.nButC+1)*obj.dX)/obj.nButC;            
            
            % calculates the other object dimensions
            obj.hghtPanelD = obj.hghtFig - (3*obj.dX + obj.hghtPanelC);            
            obj.hghtTableD = obj.hghtPanelD - 2*obj.dX;
            obj.widTableD = obj.widPanel - 2*obj.dX;
            
        end
        
        % --- initialises the class fields
        function initClassObjects(obj)
            
            % deletes any previous GUIs
            hPrev = findall(0,'tag',obj.tagStr);
            if ~isempty(hPrev); delete(hPrev); end
            
            % --------------------------- %
            % --- MAIN FIGURE OBJECTS --- %
            % --------------------------- %
            
            % creates the figure object
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % creates the figure object
            obj.hFig = createUIObj('figure','Position',fPos,...
                'tag',obj.tagStr,'MenuBar','None','Toolbar','None',...
                'Name',obj.figName,'Resize','off','NumberTitle','off',...
                'Visible','off'); 
            
            % retrieves the figure objects
            fObj0 = findall(0,'type','figure');
            obj.fObj = fObj0(~arrayfun(@(x)(isequal(x,obj.hFig)),fObj0));
            
            % retrieves the figure names
            [obj.fObjName,iS] = sort(...
                arrayfun(@(x)(get(x,'Name')),obj.fObj,'un',0));
            obj.fObj = obj.fObj(iS);
            
            % removes any empty tag figure
            ii = ~cellfun('isempty',obj.fObjName);
            [obj.fObj,obj.fObjName] = deal(obj.fObj(ii),obj.fObjName(ii));
            
            % ---------------------------- %
            % --- CONTROL BUTTON PANEL --- %
            % ---------------------------- %
            
            % button property fields
            bFcnC = {@obj.showFigure,...
                     @obj.hideFigure,...
                     @obj.deleteFigure,...
                     @obj.closeWindow};            
            
            % creates the control button panel
            pPosC = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelC];
            obj.hPanelC = createUIObj('panel',obj.hFig,...
                'Title','','Position',pPosC);
            
            % creates the control button objects
            for i = 1:length(obj.hButC) 
                lPosBC = (1+(i-1)/2)*obj.dX + (i-1)*obj.widButC;
                pPosBC = [lPosBC,obj.dX-2,obj.widButC,obj.hghtBut];
                obj.hButC{i} = createUIObj('pushbutton',obj.hPanelC,...
                    'Position',pPosBC,'FontWeight','Bold',...
                    'FontSize',obj.fSzT,'String',obj.bStrC{i},...
                    'Callback',bFcnC{i});
            end            
            
            % sets the other object properties
            cellfun(@(x)(setObjEnable(x,0)),obj.hButC(1:3));
            
            % sets the figure close request function
            obj.hFig.CloseRequestFcn = @obj.closeWindow;
            
            % ---------------------------- %
            % --- FIGURE LISTBOX PANEL --- %
            % ---------------------------- %
            
            % creates the control button panel
            yPosD = sum(pPosC([2,4])) + obj.dX;
            pPosD = [obj.dX,yPosD,obj.widPanel,obj.hghtPanelD];
            obj.hPanelD = createUIObj('panel',obj.hFig,...
                'Title','','Position',pPosD);            
                        
            % creates the table object       
            cWid = {380,80};
            cForm = {'char','char'};
            cName = {'Figure Name','Status'};
            fObjStat = arrayfun(@(x)(obj.getFigStatus(x)),obj.fObj,'un',0);
            tDataD = [obj.fObjName,fObjStat];
            
            pPosTD = [obj.dX*[1,1],obj.widTableD,obj.hghtTableD];            
            obj.hTableD = createUIObj('table',obj.hPanelD,...
                'Data',[],'Position',pPosTD,'ColumnName',cName,...
                'ColumnEditable',false(1,2),'ColumnFormat',cForm,...
                'RowName',[],'ColumnWidth',cWid,'Data',tDataD,...
                'CellSelectionCallback',@obj.selectFigTable,...
                'BackgroundColor',ones(1,3));        
            autoResizeTableColumns(obj.hTableD);            
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % centers and refreshes the figure
            centerfig(obj.hFig);
            refresh(obj.hFig);
            
            % makes the window visible
            setObjVisibility(obj.hFig,1);            
            
            % retrieves the table java handle
            obj.jTableD = getJavaTable(obj.hTableD);            
            
        end
        
        % ----------------------------------------- %
        % --- GENERAL OBJECT CALLBACK FUNCTIONS --- %
        % ----------------------------------------- %        
        
        % --- listbox selection callback function
        function selectFigTable(obj,~,evnt)
            
            % field retrieval
            if isempty(evnt.Indices)
                return
            else
                obj.iSel = evnt.Indices(1);
            end
            
            % sets the enable/disable button indices
            if strcmp(obj.hTableD.Data{obj.iSel,2},'Showing')
                % case is the figure is currently showing
                [indE,indD] = deal([2,3],1);
                
            else
                % case is the figure is currently hidden
                [indE,indD] = deal([1,3],2);                
            end
            
            % ensure the main DART figure can't be deleted
            if strcmp(get(obj.fObj(obj.iSel),'Tag'),'figDART')
                [indE,indD] = deal(indE(1),[indD,3]);
            end
            
            % sets the button properties
            cellfun(@(x)(setObjEnable(x,0)),obj.hButC(indD))
            cellfun(@(x)(setObjEnable(x,1)),obj.hButC(indE))
            
        end
        
        % ----------------------------------------- %
        % --- CONTROL BUTTON CALLBACK FUNCTIONS --- %
        % ----------------------------------------- %
       
        % --- show figure callback function
        function showFigure(obj,~,~)
            
            % updates the table value
            tVal = java.lang.String('Showing');
            setObjVisibility(obj.fObj(obj.iSel),1);
            obj.jTableD.setValueAt(tVal,obj.iSel-1,1);
            
            % sets the button properties
            setObjEnable(obj.hButC{1},0);
            setObjEnable(obj.hButC{2},1);     
            
            % places the dialog window on top again
            figure(obj.hFig);
            
        end
        
        % --- hide figure callback function
        function hideFigure(obj,~,~)
            
            % updates the table value
            tVal = java.lang.String('Hidden');            
            setObjVisibility(obj.fObj(obj.iSel),0);
            obj.jTableD.setValueAt(tVal,obj.iSel-1,1);  
            
            % sets the button properties
            setObjEnable(obj.hButC{1},1);
            setObjEnable(obj.hButC{2},0);
            
            % places the dialog window on top again
            figure(obj.hFig);            
            
        end        
        
        % --- delete figure callback function
        function deleteFigure(obj,~,~)            
            
            % prompts the user if they want to delete the figure
            tStr = 'Confirm Figure Deletion?';
            qStr = 'Are you sure you want to delete the selected figure?';
            uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
            
            % if the user confirm then exit
            if strcmp(uChoice,'Yes')
                % deletes the figure
                delete(obj.fObj(obj.iSel));
                
                % resets the other arrays
                B = ~setGroup(obj.iSel,size(obj.fObj));
                obj.fObj = obj.fObj(B);
                obj.fObjName = obj.fObjName(B);
                
                % sets the other figure properties
                obj.iSel = [];
                obj.hTableD.Data = obj.hTableD.Data(B,:);
                cellfun(@(x)(setObjEnable(x,0)),obj.hButC(1:3));
            end            
            
        end
        
        % --- close window callback function
        function closeWindow(obj,~,~)
            
            delete(obj.hFig);
            
        end
        
    end
    
    % static class fields
    methods (Static)
        
        % --- retrieves the figure status string
        function fStat = getFigStatus(fObjS)
            
            if strcmp(fObjS.Visible,'on')
                fStat = 'Showing';
            else
                fStat = 'Hidden';                
            end
            
        end
        
    end
    
end