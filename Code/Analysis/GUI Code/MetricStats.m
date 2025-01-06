classdef MetricStats < handle
    
    % class properties
    properties
        
        % input arguments
        iData
        iRow
        pInd
        
        % metric class fields
        metInd
        metVar
        
        % main class objects
        hFig

        % control button panel
        hPanelM
        hChkM      
        
        % control button panel
        hPanelC
        hButC
        
        % fixed dimension fields
        dX = 10;
        hghtHdr = 20;
        hghtRow = 25;
        hghtBut = 25;
        hghtChk = 21;
        widPanel = 300;
        
        % calculated dimension fields
        widFig
        hghtFig
        hghtPanelM
        hghtPanelC
        widButC
        widChkM
        
        % boolean class fields
        isChange = false;
        
        % static class fields
        nChkM = 10;
        nButC = 2;
        fSzH = 13;
        fSzL = 12;
        fSz = 10 + 2/3;
        
        % static string fields
        tagStr = 'figStatMet';
        figName = 'Statistical Metrics & Tests';
        tHdrM = 'STATISTICAL METRICS';
        
        % cell array class fields
        pStr = {'mn','md','lq','uq','rng','ci','sd','sem','min','max'};        
        
    end
    
    % class methods
    methods
        
        % --- class constuctor
        function obj = MetricStats(iData,iRow,pInd)
            
            % sets the input arguments
            obj.iData = iData;
            obj.iRow = iRow;
            obj.pInd = pInd;
            
            % sets the metric indices
            obj.metInd = iData.tData.iPara{iData.cTab}{pInd}{2}(iRow,:);
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initClassObjects();            
            
            % clears the output object (if not required)
            if (nargout == 0) && ~isdeployed
                clear obj
            end            
            
            % waits for the user response
            uiwait(obj.hFig);            
            
        end        
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % pre-calculations
            nRow = ceil(obj.nChkM/2);
            
            % memory allocation
            obj.hChkM = cell(obj.nChkM,1);
            
            % sets the metric variables
            iVar = find(obj.metInd);
            obj.metVar = arrayfun(@(x)(ind2varStat(x)),iVar,'un',0);
            
            % ------------------------------------- %
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- %            
            
            % panel height dimension calculations
            obj.hghtPanelC = obj.dX + obj.hghtRow;            
            obj.hghtPanelM = obj.dX + nRow*obj.hghtRow + obj.hghtHdr;
            
            % figure dimension calculations
            obj.widFig = obj.widPanel + 2*obj.dX;
            obj.hghtFig = 3*obj.dX + obj.hghtPanelM + obj.hghtPanelC;
            
            % other dimension calculations
            obj.widButC = (obj.widPanel - 2*obj.dX)/obj.nButC;
            obj.widChkM = (obj.widPanel - 2*obj.dX)/2;
            
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
                'Name',obj.figName,'Resize','on','NumberTitle','off',...
                'Visible','off','AutoResizeChildren','off',...
                'BusyAction','Cancel','GraphicsSmoothing','off',...
                'DoubleBuffer','off','Renderer','painters','CloseReq',[]);
            
            % ----------------------- %
            % --- SUB-PANEL SETUP --- %
            % ----------------------- %
            
            % sets up the sub-panel objects
            obj.setupControlButtonPanel();
            obj.setupStatMetricsPanel();            
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %                        
            
            % opens the class figure
            openClassFigure(obj.hFig);
            
        end
        
        % ------------------------------------ %
        % --- PANEL OBJECT SETUP FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- sets up the statistical metrics panel
        function setupStatMetricsPanel(obj)
            
            % initialisations
            pStrC = {'Mean','Median','Lower Quartile','Upper Quartile',...
                     'Range','Confidence Interval','Standard Deviation',...
                     'Standard Error Mean','Minimum','Maximum'};
            cbFcnC = @obj.checkStatMetrics;
            
            % creates the panel object
            yPos = sum(obj.hPanelC.Position([2,4])) + obj.dX;
            pPos = [obj.dX,yPos,obj.widPanel,obj.hghtPanelM];
            obj.hPanelM = createPanelObject(obj.hFig,pPos,obj.tHdrM);
            
            % creates the checkbox objects
            nRow = ceil(obj.nChkM/2);
            for i = 1:nRow
                % determines the global row index
                j = nRow - (i-1);
                ii = (i-1)*2 + (1:2);
                
                % creates the checkbox objects
                yOfs = obj.dX + (j-1)*obj.hghtRow;
                hObj = createObjectRow(obj.hPanelM,2,'checkbox',...
                    obj.widChkM,'dxOfs',0,'yOfs',yOfs,'pStr',pStrC(ii));
                obj.hChkM(ii) = hObj;
                
                % sets the checkbox marker values
                for j = 1:length(ii)
                    obj.hChkM{ii(j)}.Value = ...
                        any(strcmp(obj.metVar,obj.pStr{ii(j)}));
                end
            end
            
            % updates the checkbox object properties
            cellfun(@(x,y)(set(...
                x,'UserData',y,'Callback',cbFcnC)),obj.hChkM,obj.pStr(:));
            
        end
                        
        % --- sets up the serial information panel
        function setupControlButtonPanel(obj)
            
            % initialisations
            bStrC = {'Update Metrics','Close Window'};
            cbFcnB = {@obj.buttonUpdateMetrics;@obj.buttonCloseWindow};
            
            % creates the panel object
            pPos = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelC];
            obj.hPanelC = createPanelObject(obj.hFig,pPos);
            
            % creates the button objects
            obj.hButC = createObjectRow(obj.hPanelC,obj.nButC,...
                'pushbutton',obj.widButC,'yOfs',obj.dX/2,...
                'pStr',bStrC,'xOfs',obj.dX/2,'dxOfs',0);
            
            % updates the other object properties
            cellfun(@(x,y)(set(x,'Callback',y)),obj.hButC,cbFcnB);
            setObjEnable(obj.hButC{1},0);
            
        end        
        
        % --------------------------------------- %
        % --- OTHER OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- statistical metrics checkbox callback function
        function checkStatMetrics(obj, hCheck, ~)
            
            % updates the 
            obj.isChange = true;
            iSel = obj.var2indStat(hCheck.UserData);
            obj.metInd(iSel) = hCheck.Value;
            
            % determines if any metrics have been selected
            if ~any(obj.metInd)
                % if not, then output an error to screen
                tStr = 'Incorrect Metric Selection';
                eStr = ['Error! At least one metric statistical ',...
                        'type has to be set'];
                waitfor(errordlg(eStr,tStr,'modal'))
                
                % reverts the check/field values
                [hCheck.Value,obj.metInd{iSel}] = deal(true);
                
            else
                % otherwise, update the object properties
                setObjEnable(obj.hButC{1},1);
            end
            
        end
        
        % --- set device name button callback functions
        function buttonUpdateMetrics(obj, ~, ~)
           
            % ensures that a change has been flagged
            obj.isChange = true;
            
            % deletes the figure
            delete(obj.hFig);
            
        end        
            
        % --- close window button callback functions
        function buttonCloseWindow(obj, ~, ~)
           
            % determines if there is an outstanding change
            if strcmp(obj.hButC{1}.Enable,'on')
                % prompts the user if they wish to update the changes
                tStr = 'Update Changes?';
                qStr = 'Do you want to update the changes before closing?';                
                uChoice = questdlg(qStr,tStr,'Yes','No','Cancel','Yes');
                switch (uChoice)
                    case ('Yes') 
                        % case is the user chose to update
                        buttonUpdate_Callback(handles.buttonUpdate, 1, handles)
                        return
                    
                    case ('No')
                        % case is the user chose not to update
                        obj.isChange = false;
                    
                    otherwise
                        % case is cancelling
                        % exit the function
                        return
                end
            end
            
            % deletes the GUI
            delete(obj.hFig)
            
        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- returns the index of a statistic metric variable
        function ind = var2indStat(obj,vName)
            
            ind = find(strcmp(obj.pStr,vName));
            
        end
        
        % --- class deletion function
        function deleteClass(obj)
            
            delete(obj)
            clear obj
            
        end
        
    end
    
end