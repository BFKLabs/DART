classdef ExtnDataHeader < handle
    
    % class properties
    properties
    
        % main class methods
        objM
        hStr
        nStr
        
        % class gui objects
        hFig
        hPanelH
        hPanelC
        hTable
        hButC
        
        % derived dimensions values                
        widFig
        hghtFig
        widTable
        hghtTable        
        hghtPanelH
        widButC
        
        % object dimensions
        dX = 10;
        hghtBut = 25;
        widPanel = 300;
        hghtPanelC = 40;
        
        % other scalar parameters
        tSz = 12;
        nRowMx = 10;        
        
    end
    
    % class methods
    methods
        
        % class constructor
        function obj = ExtnDataHeader(objM)
            
            % sets the input arguments
            obj.objM = objM;
            
            % initialises the class fields/gui objects
            obj.initClassFields()
            obj.initClassObjects()
            
            % centres the figurea and makes it visible
            centreFigPosition(obj.hFig);
            setObjVisibility(obj.hFig,1);            
            
        end
        
        % --- initialises the class object fields
        function initClassFields(obj)
            
            % global variables
            global H0T HWT
            
            % sets the original header strings
            [iExp,iPara] = deal(obj.objM.iExp,obj.objM.iPara);
            obj.hStr = obj.objM.exD{iExp}{iPara}.hStr;
            obj.nStr = length(obj.hStr);

            % calculates the derived object dimensions
            obj.hghtTable = H0T + min(obj.nRowMx,obj.nStr)*HWT;
            obj.hghtPanelH = obj.hghtTable + 2*obj.dX;
            obj.widTable = obj.widPanel - 2*obj.dX;
            obj.widButC = (obj.widPanel - 3*obj.dX)/2;
            
            % sets the figure dimensions
            obj.widFig = obj.widPanel + 2*obj.dX;
            obj.hghtFig = obj.hghtPanelC + obj.hghtPanelH + 3*obj.dX;
            
            % disables the close window menu item/buttons
            setObjEnable(obj.objM.hMenuX,0);
            setObjEnable(obj.objM.hButC{3},0);
            
        end
        
        % --- initialises the class gui objects
        function initClassObjects(obj)
            
            % creates the figure object
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % removes any previous GUIs
            hFigPr = findall(0,'tag','figExtnDataHdr');
            if ~isempty(hFigPr); delete(hFigPr); end
            
            % creates the figure object
            fStr = 'Data Column Header';
            obj.hFig = figure('Position',fPos,'tag','figExtnDataHdr',...
                              'MenuBar','None','Toolbar','None',...
                              'Name',fStr,'NumberTitle','off',...
                              'Visible','off','Resize','off',...
                              'WindowStyle','modal');
           
            % ------------------------------ %
            % --- CONTROL BUTTON OBJECTS --- %
            % ------------------------------ %
            
            % creates the control button 
            pPosC = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelC];
            obj.hPanelC = uipanel(obj.hFig,'Title','','Units',...
                                       'Pixel','Position',pPosC);            
            
            % button properties
            bStr = {'Update Changes','Close Window'};
            cbFcnB = {@obj.buttonUpdate,@obj.closeFigure};
            obj.hButC = cell(length(bStr),1);
            
            % creates the control buttons
            for i = 1:length(bStr)
                lPosC = obj.dX + (i-1)*(obj.dX + obj.widButC);
                bPosC = [lPosC,obj.dX-2,obj.widButC,obj.hghtBut];
                obj.hButC{i} = uicontrol(obj.hPanelC,'Style',...
                        'PushButton','Units','Pixels','Position',bPosC,...
                        'Callback',cbFcnB{i},'FontWeight','Bold',...
                        'FontUnits','Pixels','FontSize',obj.tSz,...
                        'String',bStr{i});
                
            end
            
            % disables the update button
            setObjEnable(obj.hButC{1},0)
                                   
            % ----------------------------------- %
            % --- HEADER STRING TABLE OBJECTS --- %
            % ----------------------------------- %

            % creates the panel
            y0 = sum(pPosC([2,4])) + obj.dX;
            pPosH = [obj.dX,y0,obj.widPanel,obj.hghtPanelH];            
            obj.hPanelH = uipanel(obj.hFig,'Title','','Units',...
                                       'Pixel','Position',pPosH);                        
            
            % creates the table object
            cbFcnT = @obj.tableChange;
            tPos = [obj.dX*[1,1],obj.widTable,obj.hghtTable];
            obj.hTable = uitable(obj.hPanelH,'Units','Pixels',...
                       'FontUnits','Pixels','FontSize',obj.tSz,...
                       'Data',obj.hStr(:),'CellEditCallback',cbFcnT,...
                       'ColumnEditable',true,'BackgroundColor',[1,1,1],...
                       'tag','hTableP','Position',tPos,...
                       'ColumnName','Column Header String');
            autoResizeTableColumns(obj.hTable);
                                   
        end
        
        % -------------------------- %
        % --- CALLBACK FUNCTIONS --- %
        % -------------------------- %
        
        % --- table cell update callback function
        function tableChange(obj,~,evnt)
            
            % updates the string and enables the update button
            obj.hStr{evnt.Indices(1)} = evnt.NewData;            
            setObjEnable(obj.hButC{1},1)            
            
        end
        
        % --- update button callback function
        function buttonUpdate(obj,hObj,~)
            
            % sets the original header strings
            [iExp,iPara] = deal(obj.objM.iExp,obj.objM.iPara);
            obj.objM.exD{iExp}{iPara}.hStr = obj.hStr;   
            
            % updates the parameter table
            hTabP = obj.objM.hTabP{iExp}{iPara};
            hTableP = findall(hTabP,'tag','hTableP');
            set(hTableP,'ColumnName',obj.hStr(:)')
            
            % disables the update button
            setObjEnable(hObj,0)
            
        end
        
        % --- close window callback function
        function closeFigure(obj,~,~)
            
            % determine if there have been any changes
            if strcmp(get(obj.hButC{1},'Enable'),'on')
                % if so, then prompt the user if they wish to update
                qStr = 'Do you want to update the changes?';
                uChoice = questdlg(qStr,'Update Changes?','Yes',...
                                        'No','Cancel','Yes');
                switch uChoice
                    case 'Yes'
                        % user chose to update solution
                        obj.buttonUpdate(obj.hButC{1},[]);
                        
                    case 'Cancel'
                        % if the user cancelled, then exit
                        return
                        
                end
            end
            
            % re-enables the close window menu item/buttons
            setObjEnable(obj.objM.hMenuX,1);
            setObjEnable(obj.objM.hButC{3},1);            
            obj.objM.updateButtonProps()
            
            % deletes the gui
            delete(obj.hFig);
            
        end        
        
    end
    
end
    
    