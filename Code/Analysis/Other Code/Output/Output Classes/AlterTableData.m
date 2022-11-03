classdef AlterTableData < handle
    
    % class properties
    properties
        
        % main class fields        
        Type
        jTable
        hPanelD
        
        % gui object handles
        hFig
        hPanelS        
        hRadioS
        hPanelC
        hButC
        
        % other array fields
        iR
        iC
        iR0
        iC0
        iSel
        
        % fixed object dimensions
        dX = 10;
        hghtPanelC = 40;
        hghtRadio = 18;
        widRadio = 170;
        hghtButC = 25;        
        
        % derived object dimensions
        widFig
        hghtFig
        widPanel
        hghtPanelS
        widButC
        
        % other fixed parameters        
        tSz = 12;
        ok = true;
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = AlterTableData(tObj,Type)
            
            % sets the input arguments
            obj.Type = Type;
            obj.jTable = tObj.jTable;
            
            % initialises the class objects/fields
            obj.initClassFields();
            if obj.ok
                obj.initClassObjects();
            end
            
        end
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % retrieves the selected row/columns
            [obj.iR,obj.iR0] = deal(obj.jTable.getSelectedRows());
            [obj.iC,obj.iC0] = deal(obj.jTable.getSelectedColumns());
            
            if isempty(obj.iR0) || isempty(obj.iC0)
                % if no cell is selected, then output a message to screen
                mStr = ['No worksheet cell has been selected. ',...
                        'Retry by selecting at least one cell.'];
                waitfor(msgbox(mStr,'No Worksheet Cells Selected','modal'))
                
                % deletes the GUI and exits
                obj.ok = false;
                return
            end
            
            % derived object dimensions
            obj.hghtPanelS = 9.5*obj.dX;            
            obj.widPanel = 2*obj.dX + obj.widRadio;
            obj.widButC = (obj.widPanel - 3*obj.dX)/2;
            
            % sets the figure dimensions
            obj.widFig = obj.widPanel + 2*obj.dX;
            obj.hghtFig = 3*obj.dX + obj.hghtPanelS + obj.hghtPanelC;
            
        end
        
        % --- initialises the class fields
        function initClassObjects(obj)
            
            % creates the figure object
            tagStr = 'figAlterTableData';
            titleStr = 'Shift Table Data';            
            
            % sets the title/radio button strings
            switch obj.Type
                case 1
                    % case is insertion
                    titleStr = 'Insert';
                    rStrS = {'Shift Cells Right','Shift Cells Down',...
                             'Entire Column','Entire Row'};
                case 2
                    % case is deletion
                    titleStr = 'Delete';
                    rStrS = {'Shift Cells Left','Shift Cells Up',...
                             'Entire Column','Entire Row'};                    
            end            
            
            % removes any previous figures
            hFigPr = findall(0,'tag',tagStr);
            if ~isempty(hFigPr); delete(hFigPr); end                                    
            
            % --------------------------- %
            % --- FIGURE OBJECT SETUP --- %
            % --------------------------- %            
            
            % creates the figure object
            fPos = [100,100,obj.widFig,obj.hghtFig];
            obj.hFig = figure('Position',fPos,'tag',tagStr,...
                              'MenuBar','None','Toolbar','None',...
                              'Name',titleStr,'NumberTitle','off',...
                              'Visible','off','Resize','off');            
            
            % ---------------------------------- %
            % --- CONTROL BUTTON PANEL SETUP --- %
            % ---------------------------------- %
            
            % initialisations
            bStrC = {'OK','Cancel'};
            cbFcnC = {@obj.buttonApplyShift,@obj.buttonCancel};
            
            % creates the panel object
            pPosC = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelC];
            obj.hPanelC = uipanel(obj.hFig,'Title','','Units',...
                                           'Pixel','Position',pPosC);
            
            % creates the push button objects
            for i = 1:length(bStrC)
                lPosC = i*obj.dX + (i-1)*obj.widButC;
                bPosC = [lPosC,obj.dX-2,obj.widButC,obj.hghtButC];
                uicontrol(obj.hPanelC,...
                    'Style','Pushbutton','String',bStrC{i},...
                    'Units','Pixels','Position',bPosC,...
                    'FontUnits','Pixels','FontSize',obj.tSz,...
                    'FontWeight','bold','HorizontalAlignment',...
                    'Center','Callback',cbFcnC{i})
                
            end                                       
                                       
            % -------------------------------- %
            % --- RADIO BUTTON PANEL SETUP --- %
            % -------------------------------- %
            
            % initialisations
            cbFcnS = @obj.panelShiftType;            
            
            % creates the panel object
            yPosR = sum(pPosC([2,4])) + obj.dX;
            pPosR = [obj.dX,yPosR,obj.widPanel,obj.hghtPanelS];
            obj.hPanelS = uibuttongroup(obj.hFig,'Title','','Units',...
                'Pixel','Position',pPosR,'SelectionChangeFcn',cbFcnS);
            
            % creates the radio button objects
            nRadio = length(rStrS);
            obj.hRadioS = cell(nRadio,1);
            for i = 1:nRadio
                yPos = obj.dX + 2*(nRadio-i)*obj.dX - 2;
                rPosS = [obj.dX,yPos,obj.widRadio,obj.hghtRadio];
                obj.hRadioS{i} = uicontrol(obj.hPanelS,...
                    'Style','RadioButton','String',rStrS{i},...
                    'Units','Pixels','Position',rPosS,'UserData',i,...
                    'FontUnits','Pixels','FontSize',obj.tSz,...
                    'FontWeight','bold','HorizontalAlignment','Left');
            end
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %                                      
            
            % sets the figure visibility
            centreFigPosition(obj.hFig,2);
            setObjVisibility(obj.hFig,1);
            
            % wait until the figure closes
            uiwait(obj.hFig);
            
        end
        
        % -------------------------- %
        % --- CALLBACK FUNCTIONS --- %
        % -------------------------- %
        
        % --- executes when selecting the shift radio button type
        function panelShiftType(obj,~,~)
            
            % retrieves the table dimensions
            m = obj.jTable.getRowCount;
            n = obj.jTable.getColumnCount;
            
            % if they are empty, then re-read the row indices
            if isempty(obj.iR0)
                [obj.iR,obj.iR0] = deal(obj.jTable.getSelectedRows);
            end
            
            % retrieves the original column selection indices
            if isempty(obj.iC0)
                % if they are empty, then re-read the column indices
                [obj.iC,obj.iC0] = deal(obj.jTable.getSelectedColumns);
            end
            
            % retrieves the currently selected radio button
            hRadio = findall(obj.hPanelS,'style','radiobutton','value',1);
            switch get(hRadio,'UserData')
                case {1,2}
                    % case is inserting/deleting horizontally
                    [ii,jj] = deal(obj.iR0,obj.iC0);
                    obj.jTable.setRowSelectionInterval(ii(1),ii(end));
                    obj.jTable.setColumnSelectionInterval(jj(1),jj(end));
                    
                case 3
                    % case is inserting/deleting an entire row
                    jj = obj.iC0;
                    obj.jTable.setColumnSelectionInterval(jj(1),jj(end))
                    obj.jTable.setRowSelectionInterval(0, m-1);
                    
                case 4
                    % case is inserting/deleting an entire column
                    ii = obj.iR0;
                    obj.jTable.setColumnSelectionInterval(0, n-1);
                    obj.jTable.setRowSelectionInterval(ii(1),ii(end));                    
            end
            
        end
        
        % --- executes when clicking the apply shift button
        function buttonApplyShift(obj,~,~)

            % flag that the user chose to proceed
            obj.ok = true;
            obj.iSel = find(cellfun(@(x)(get(x,'Value')),obj.hRadioS));
            obj.resetTableSelection();
            
            % deletes the figure
            delete(obj.hFig);            
            
        end
        
        % --- executes when clicking the cancel button
        function buttonCancel(obj,~,~)
            
            % flag that the user cancelled
            obj.ok = false;
            obj.resetTableSelection();
            
            % deletes the figure
            delete(obj.hFig);
            
        end               
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- resets the table to the original selection
        function resetTableSelection(obj)
            
            % case is inserting/deleting horizontally
            [ii,jj] = deal(obj.iR0,obj.iC0);
            obj.jTable.setRowSelectionInterval(ii(1),ii(end));
            obj.jTable.setColumnSelectionInterval(jj(1),jj(end));            
            
        end        
        
    end
    
    % static class methods
    methods (Static)
        
        
    end
    
end
    