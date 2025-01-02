classdef DiskSpace < handle
    
    % class properties
    properties
        
        % main class objects
        hFig
        
        % information panel objects
        hPanelI
        hTxtI
        hAxI
        
        % control button obects
        hPanelC
        hButC        
        
        % fixed dimension fields
        dX = 10;         
        hghtTxt = 16;
        hghtBut = 25;
        hghtHdr = 20;
        hghtRow = 25;
        hghtPanelI = 230;
        widLblI = 110;
        widTxtI = 70;
        
        % calculated dimension fields
        widFig
        hghtFig        
        widPanel
        hghtPanelC
        hghtAxI
        widAxI
        widButC
        
        % disk information class fields
        vInfo
        
        % static class fields
        nVol
        nLblI = 4;
        fSzH = 13;
        fSzL = 12;
        fSz = 10 + 2/3;
        
        % axes class fields
        fAlpha = 0.5;
        yTick = 0:20:100;        
        ix = [1,1,2,2];
        iy = [1,2,2,1];
        
        % static string fields
        tagStr = 'figDiskSpace';
        figName = 'Volume Disk Space';
        
    end
    
    % class methods
    methods
        
        % --- class constuctor
        function obj = DiskSpace()
                        
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
            
            % retrieves the disk volume information
            obj.vInfo = getDiskVolumeInfo(); 
            
            % array dimensioning
            obj.nVol = size(obj.vInfo,1);
            
            % memory allocation
            obj.hTxtI = cell(obj.nLblI,obj.nVol);
            
            % ------------------------------------- %
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- %
            
            % calculates the panel width
            obj.hghtPanelC = obj.dX + obj.hghtRow;
            obj.widPanel = obj.widLblI + ...
                (3+obj.nVol)*(obj.dX/2) + obj.nVol*obj.widTxtI;
            
            % calculates the figure dimensions
            obj.widFig = obj.widPanel + 2*obj.dX;
            obj.hghtFig = obj.hghtPanelI + obj.hghtPanelC + 3*obj.dX;
            
            % calculates the other object handles
            obj.hghtAxI = obj.hghtPanelI - ...
                (2*obj.dX + obj.nLblI*obj.hghtHdr);
            obj.widAxI = obj.widTxtI - obj.dX;
            obj.widButC = obj.widPanel - obj.dX;
            
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
                'DoubleBuffer','off','Renderer','painters');            
            
            % ----------------------- %
            % --- SUB-PANEL SETUP --- %
            % ----------------------- %
            
            % sets up the sub-panel objects
            obj.setupControlButtonPanel();            
            obj.setupVolumnInfoPanel();
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %            
                        
            % opens the class figure
            openClassFigure(obj.hFig);
            
        end
        
        % --- creates the axes object for volume, iVol
        function createAxesObject(obj,pFree,iVol)
            
            % precalculations
            xP = 0.5*[-1,1];
            [yFree,yUsed] = deal(100-[pFree,0],[0,100-pFree]);

            % sets up the position vector
            yPos = (3/2)*obj.dX + obj.nLblI*obj.hghtHdr;
            xPos = (iVol-1)*obj.widTxtI + obj.widLblI + (1+iVol)*obj.dX/2;
            axPos = [xPos,yPos,obj.widAxI,obj.hghtAxI];
            
            % creates the new axes object
            hAx = createUIObj('axes',obj.hPanelI,'Position',axPos,...
                'xticklabel',[],'yticklabel',[],'xtick',[],'box','on',...
                'ytick',obj.yTick,'xlim',xP,'ylim',[0,100],'YGrid','on');
            
            % creates the new axes objects
            hold(hAx,'on');
            hFree = patch(hAx,...
                xP(obj.ix),yFree(obj.iy),'g','FaceAlpha',obj.fAlpha);
            hUsed = patch(hAx,...
                xP(obj.ix),yUsed(obj.iy),'r','FaceAlpha',obj.fAlpha);
            
            % sets the legend (first volume only)
            if iVol == 1
                % creates the legend object
                hLg = legend([hFree,hUsed],{'Free Space','Used Space'},'box','off',...
                    'FontWeight','bold','FontSize',8,'Units','Pixels');
                
                % resets the legend location
                lgPos = get(hLg,'Position');
                yLg = axPos(2)+0.5*axPos(4)-lgPos(4)/2;
                set(hLg,'Position',[obj.dX/2,yLg,axPos(1)-obj.dX,lgPos(4)])
            end
        end
        
        % ------------------------------------ %
        % --- PANEL OBJECT SETUP FUNCTIONS --- %
        % ------------------------------------ %        
            
        % --- sets up the control button panel objects
        function setupControlButtonPanel(obj)
            
            % initialisations
            tStrB = 'Close Window';            
            cbFcnB = @obj.buttonCloseWindow;
            
            % creates the panel object
            pPos = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelC];
            obj.hPanelC = createPanelObject(obj.hFig,pPos);
            
            % creates the button object
            pPosB = [obj.dX*[1,1]/2,obj.widButC,obj.hghtBut];
            obj.hButC = createUIObj('pushbutton',obj.hPanelC,...
                'Position',pPosB,'FontUnits','Pixels',...
                'FontWeight','Bold','FontSize',obj.fSzL,...
                'String',tStrB,'Callback',cbFcnB);
            
        end
        
        % --- sets up the volume information panel objects
        function setupVolumnInfoPanel(obj)
           
            % initialisations
            pStr = cell(obj.nLblI,1+obj.nVol);
            tStrR = {'Volumn Name: ','Total Space (GB): ',...
                     'Free Space (GB): ','% Capacity: '};            
            wObj = [obj.widLblI,obj.widTxtI*ones(1,obj.nVol)];
                 
            % creates the panel object
            yPos = sum(obj.hPanelC.Position([2,4])) + obj.dX;
            pPos = [obj.dX,yPos,obj.widPanel,obj.hghtPanelI];
            obj.hPanelI = createPanelObject(obj.hFig,pPos);
            
            % sets up the text labels
            for i = 1:obj.nLblI
                % calculates the object vertical offset
                j = obj.nLblI - (i-1);
                yOfs = obj.dX + (j-1)*obj.hghtHdr;
                
                % creates the text object
                pStr{1} = tStrR{i};
                hObj = createObjectRow(obj.hPanelI,1+obj.nVol,...
                    'text',wObj,'xOfs',obj.dX/2,'yOfs',yOfs,...
                    'dxOfs',obj.dX,'pStr',pStr); 
                
                % sets the object properties
                obj.hTxtI(i,:) = hObj(2:end);
                set(hObj{1},'HorizontalAlignment','Right');
                
                % retrieves the volume data strings
                txtStr = obj.getVolumeDataStrings(i);                
                
                % sets the text properties
                cellfun(@(x,y,z)(set(x,'String',y)),obj.hTxtI(i,:)',txtStr)                
            end
            
            % sets up the text label colours
            pFree = cellfun(@(x)(x{3}/x{2}),num2cell(obj.vInfo,2));
            txtCol = arrayfun(@(x)(obj.getTextColour(100*x)),pFree,'un',0);
            
            % updates the volumn object properties
            for i = 1:obj.nVol
                % sets the text label colour
                cellfun(@(x)(set(...
                    x,'ForegroundColor',txtCol{i})),obj.hTxtI(:,i));
                
                % creates the axes object
                obj.createAxesObject(100*pFree(i),i);                
            end            
            
        end        
        
        % --------------------------------------- %
        % --- OTHER OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- close window button callback function
        function buttonCloseWindow(obj, ~, ~)
            
            delete(obj.hFig);
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- retrieves the volume data strings (based on row index)
        function tStrR = getVolumeDataStrings(obj,iRow)
        
            if iRow == obj.nLblI
                % case is the capacity fields
                tStr0 = cellfun(@(x)(100*x{3}/x{2}),num2cell(obj.vInfo,2));
                tStrR = arrayfun(@(x)(sprintf('%.1f%s',x,'%')),tStr0,'un',0);
                
            else
                % case is the other fields
                tStrR = obj.vInfo(:,iRow);
                
                % converts the numerical values to strings
                if iRow > 1
                    tStrR = cellfun(@(x)(sprintf('%.1f',x)),tStrR,'un',0);
                end
            end
            
        end
        
    end
    
    % class methods
    methods (Static)
        
        % --- retrieves text colour based on the volumes % capacity
        function txtCol = getTextColour(pFree)
            
            % sets the colour of the text based on the capacity %age
            if pFree < 10
                % case is free space is very low
                txtCol = 'r';
                
            elseif pFree < 25
                % case is free space is low
                txtCol = [0.9,0.3,0.0];
                
            else
                % case is free space is normal
                txtCol = 'k';
            end
            
        end
        
    end    
    
end