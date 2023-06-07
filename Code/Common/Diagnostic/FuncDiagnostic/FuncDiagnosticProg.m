classdef FuncDiagnosticProg < handle
    
    % class properties
    properties
       
        % object handles
        hPanel
        hPanelP
        hAx
        hImg        
                
        % fixed object dimensions
        dX = 5;
        hghtTxt = 16;
        hghtAx = 20;
        widTxt = 105;
        
        % variable object dimensions        
        yPanel
        widPanel
        hghtPanel
        widAx
        
        % array fields
        pPr        
        
        % other scalar/string fields
        nAx = 3;        
        fSz = 10;
        ix = [1,1,2,2,1];
        iy = [1,2,2,1,1];
        wImg = ones(1,1000,3);  
        isOldVer = verLessThan('matlab','9.10');
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = FuncDiagnosticProg(hPanelPC)
            
            % retrieves the parent handles
            obj.hPanelP = get(hPanelPC,'Parent');
            
            % initialises the class fields and objects
            obj.initClassFields(get(hPanelPC,'Position'));
            obj.initObjProps();
            
        end
        
        % --- initialises the class fields
        function initClassFields(obj,pPosPC)
            
            % memory allocation
            obj.pPr = zeros(obj.nAx,1);
            [obj.hImg,obj.hAx] = deal(cell(obj.nAx,1));
            
            % variable object dimension calculations
            obj.yPanel = sum(pPosPC([2,4])) + obj.dX;
            obj.widPanel = pPosPC(3);
            obj.hghtPanel = obj.nAx*obj.hghtAx + (4+(obj.nAx-1))*obj.dX;
            
            % sets the other variable dimensions
            obj.widAx = obj.widPanel - (obj.widTxt + 3*obj.dX);
            
            % resets the font sizes (old version only)
            if obj.isOldVer
                obj.fSz = 12;
            end            
            
        end
        
        % --- initialises the class objects
        function initObjProps(obj)
        
            % creates the panel object
            pPos = [2*obj.dX,obj.yPanel,obj.widPanel,obj.hghtPanel];
            obj.hPanel = createUIObj('panel',obj.hPanelP,'Title','',...
                'Position',pPos);   
            
            % field initialisation
            tStr = {'Overall Progress',...
                    'Scope Progress',...
                    'Function Progress'};
            
            % creates the text label/axes objects
            for i = 1:obj.nAx
                % sets the global index
                j = obj.nAx - (i-1);
                yPos = (2 + (j-1))*obj.dX + (j-1)*obj.hghtAx;
                
                % creates the text labels
                tPos = [obj.dX,yPos+2,obj.widTxt,obj.hghtTxt];
                tStrAx = sprintf('%s: ',tStr{i});
                obj.hAx{i} = createUIObj...
                    ('Text',obj.hPanel,'Position',tPos,'String',tStrAx,...
                    'FontWeight','Bold','FontSize',obj.fSz,...
                    'HorizontalAlignment','Right');
                
                % sets up the left position of the axes object
                if i == 1
                    lPosAx = sum(tPos([1,3]))+1;
                end
                
                % creates the axes objects                
                axPos = [lPosAx,yPos,obj.widAx,obj.hghtAx];
                obj.hAx{i} = createUIObj...
                    ('axes',obj.hPanel,'Position',axPos);
                if isprop(obj.hAx{i},'InnerPosition')
                    set(obj.hAx{i},'InnerPosition',axPos);
                end
                
                % sets up the image objects
                obj.hImg{i} = image(obj.wImg,'parent',obj.hAx{i});                
                set(obj.hAx{i},'XTickLabel',[],'YTickLabel',[],...
                    'XTick',[],'YTick',[],'TickLength',[0,0],...
                    'XColor','k','YColor','k','Box','On');
                
                % sets the 
                xL = get(obj.hAx{i},'xlim');
                yL = get(obj.hAx{i},'ylim');
                hold(obj.hAx{i},'on');
                plot(obj.hAx{i},xL(obj.ix),yL(obj.iy),'k','linewidth',1);
            end
            
        end
            
        % --- updates the progress bar (for iLvl with proportion pPrNw)
        function update(obj,iLvl,pPrNw)        
            
            % sets the new image
            wLen = roundP(pPrNw*1000,1);
            obj.wImg(:,1:wLen,2:3) = 0;
            obj.wImg(:,(wLen+1):end,2:3) = 1;            
            
            % updates the status bar and the string
            obj.pPr(iLvl) = pPrNw;            
            set(obj.hImg{iLvl},'cdata',obj.wImg);
            drawnow;                                    
            
        end
        
    end
    
end