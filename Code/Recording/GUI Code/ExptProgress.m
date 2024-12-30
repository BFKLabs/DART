classdef ExptProgress < dynamicprops & handle
    
    % class properties
    properties
        
        % main class objects
        hFig
        
        % progress panel objects
        hPanelP
        hAxP
        hTxtP
        
        % progress panel objects
        hPanelI
        hTxtI
        
        % other figure objects
        hPanelC
        hButC
        
        % fixed dimension fields
        dX = 10;    
        hghtTxt = 20;
        hghtBut = 25;
        hghtRow = 25;
        hghtHdr = 20;
        widPanel = 440;
        widPanelC = 190;
        hghtAx = 20;        
        widButC = 170;
        
        % calculated dimension fields
        widFig
        hghtFig        
        hghtPanelP
        hghtPanelI
        hghtPanelC
        widAx        
        
        % information text object property fields
        xTxtI = [10,135,230,290];
        wTxtI = [125,80,60,140];
        
        % progressbar class fields
        wImg
        hObj        
        mxProp = 1;
        cProp = 0;
        
        % stimuli information class fields
        chID
        nCount
        
        % miscellaneous class fields
        rtPos
                
        % static class fields
        nAx
        nLvlI
        nColI = 4;
        nPr = 1000;
        fSzH = 13;
        fSzL = 12;
        fSz = 10 + 2/3;
        
        % static string fields
        tagStr = 'figExptProg';
        figName = 'Experimental Progress Summary';
        
        % cell array fields
        exptTypeS = {'RecordOnly','StimOnly','RecordStim'};
        wStr = {'Current Experiment Progress','Current Video Progress'};                
        
    end
    
    % private class properties
    properties (Access = private)
        
        objB
        
    end     
    
    % class methods
    methods
        
        % --- class constuctor
        function obj = ExptProgress(objB)
            
            % sets the input arguments
            obj.objB = objB;
            
            % initialises the class fields/objects
            obj.linkParentProps();            
            obj.initClassFields();
            obj.initClassObjects();
            
        end        
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class object fields with that parent object
        function linkParentProps(obj)
            
            % parent fields strings
            fldStr = {'iExpt','hExptF','ExptSig','hasIMAQ','hasDAQ'};
            
            % connects the base/child objects
            for propname = fldStr
                metaprop = addprop(obj, propname{1});
                metaprop.SetMethod = @(obj, varargin) ...
                    SetDispatch(obj, propname{1}, varargin{:});
                metaprop.GetMethod = @(obj)GetDispatch(obj, propname{1});
            end
            
        end                
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % other field initialisations
            obj.nAx = 1 + obj.hasIMAQ; 
            
            % initialises the stimuli information 
            obj.initStimInfo();                                   
            
            % memory allocation
            obj.hTxtI = cell(obj.nLvlI,obj.nColI);
            [obj.hTxtP,obj.hAxP] = deal(cell(obj.nAx,1));
            
            % ------------------------------------- %
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- %
            
            % panel dimension calculations
            obj.hghtPanelC = obj.hghtRow + obj.dX;
            obj.hghtPanelP = 2*obj.hghtHdr*obj.nAx + 5*obj.dX;
            obj.hghtPanelI = (obj.nLvlI+1)*obj.hghtTxt + 2*obj.dX;            
            
            % calculates the figure dimensions
            obj.widFig = obj.widPanel + 2*obj.dX;
            obj.hghtFig = 4*obj.dX + ...
                obj.hghtPanelC + obj.hghtPanelI + obj.hghtPanelP; 
            
            % other object dimension calculations
            obj.widButC = obj.widPanelC - obj.dX;
            obj.widAx = obj.widPanel - 4*obj.dX;
            
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
                'DoubleBuffer','off','Renderer','painters',...
                'CloseReq',[]);            
            
            % ----------------------- %
            % --- SUB-PANEL SETUP --- %
            % ----------------------- %
                        
            % sets up the sub-panel objects
            obj.setupControlButtonPanel();
            obj.setupProgressInfoPanel();
            obj.setupProgressAxesPanel();                        
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %                                
            
            % opens the class figure
            openClassFigure(obj.hFig,0);
            
        end
        
        % --- initialises the stimuli information
        function initStimInfo(obj)
            
            % initialisations
            [obj.nCount,obj.chID] = deal([]);
            
            % if experiment type field has not been set, then initialise
            if isempty(obj.iExpt.Info.Type) || ~ischar(obj.iExpt.Info.Type)
                if obj.isRT
                    % case is real-time tracking
                    exptType = 'RTTrack';
                    
                else
                    % case is the other experiment types
                    iType = double(obj.hasIMAQ) + 2*double(obj.hasDAQ);
                    exptType = obj.exptTypeS{iType};                    
                end
                
                % resets the experiment type field
                obj.iExpt.Info.Type = exptType;
            end
            
            % sets the number of text objects to add
            switch obj.iExpt.Info.Type
                case {'RecordStim','StimOnly'}
                    % case is a stimuli-dependent experiment
                    ID = field2cell(obj.ExptSig,'ID');
                    chInfo = getappdata(obj.hExptF,'chInfo'); 
                    iOfs = double(obj.hasIMAQ);

                    % sets the channel/device ID flags
                    obj.chID = cell2mat(...
                        cellfun(@(x)(unique(x,'rows')),ID,'un',0));
                    obj.chID = [obj.chID,zeros(size(obj.chID,1),1)];
                    devID = cell2mat(chInfo(:,1));

                    % sets the final mapping values
                    obj.nLvlI = size(obj.chID,1) + iOfs;
                    obj.nCount = zeros(obj.nLvlI-iOfs,1);
                    for i = 1:obj.nLvlI - iOfs
                        % determines the matching channel ID flags
                        ii = find(devID == ...
                            obj.chID(i,1),obj.chID(i,2),'first');

                        % sets the channel ID/count flags
                        obj.chID(i,3) = ii(end);            
                        obj.nCount(i) = sum(cellfun(@(x)(...
                            isequal(x,obj.chID(i,1:2))),num2cell(...
                            obj.ExptSig(obj.chID(i,1)).ID,2)));
                    end    
                    
                otherwise
                    % case is RT tracking or recording only
                    obj.nLvlI = 1;
                    
            end
            
        end        
        
        % ------------------------------------ %
        % --- PANEL OBJECT SETUP FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- sets up the control button panel objects
        function setupControlButtonPanel(obj)
            
            % creates the panel object
            lPos = obj.widFig - (obj.dX + obj.widPanelC);
            pPos = [lPos,obj.dX,obj.widPanelC,obj.hghtPanelC];
            obj.hPanelC = createPanelObject(obj.hFig,pPos);
        
            % creates the button object
            pPosB = [obj.dX*[1,1]/2,obj.widButC,obj.hghtBut];
            obj.hButC = createUIObj('togglebutton',obj.hPanelC,...
                'Position',pPosB,'FontUnits','Pixels',...
                'FontWeight','Bold','FontSize',obj.fSzL,...
                'String','Abort Experiment');            
            
        end
        
        % --- sets up the progress information panel objects
        function setupProgressInfoPanel(obj)
            
            % creates the panel object
            yPos = sum(obj.hPanelC.Position([2,4])) + obj.dX;
            pPos = [obj.dX,yPos,obj.widPanel,obj.hghtPanelI];
            obj.hPanelI = createPanelObject(obj.hFig,pPos);

            % creates the text label objects
            wObjT = [obj.wTxtI(1:2),15,obj.wTxtI(3:4)];
            pStrT = {[],'Started',[],'Total','Time To Next Event'};            
            
            %
            for i = 1:(obj.nLvlI+1)
                % calculates the vertical offset
                j = (obj.nLvlI+1) - (i-1);
                yOfs = obj.dX + (j-1)*obj.hghtTxt;
                
                % sets the row string array
                if i == 1
                    % case is the header row
                    pStrR = pStrT;
                    
                else
                    % case is the other rows
                    pStrR = obj.getInfoRowString(i-1);
                end
                
                % sets up the text labels 
                hObjR = createObjectRow(obj.hPanelI,length(wObjT),...
                    'text',wObjT,'yOfs',yOfs,'xOfs',obj.dX,...
                    'dxOfs',0,'pStr',pStrR,'hghtTxt',obj.hghtTxt,...
                    'fSz',obj.fSzH);
                
                % stores the text objects into the class object
                if i > 1
                    set(hObjR{1},'HorizontalAlignment','Right');
                    obj.hTxtI(i-1,:) = hObjR([1,2,4,5]);
                end
            end            
            
        end
        
        % --- sets up the progress axes panel objects
        function setupProgressAxesPanel(obj)

            % initialisations
            p = struct('wStr',[],'wAxes',[],'wImg',[]);            
            
            % memory allocation
            obj.wImg = ones(obj.nAx,1000,3);            
            obj.hObj = repmat(p,obj.nAx,1);            
            
            % creates the panel object
            yPos = sum(obj.hPanelI.Position([2,4])) + obj.dX;
            pPos = [obj.dX,yPos,obj.widPanel,obj.hghtPanelP];
            obj.hPanelP = createPanelObject(obj.hFig,pPos);            
            
            % creates the progress axes objects
            for i = 1:obj.nAx
                % creates the axes object
                j = obj.nAx - (i-1);                
                yOfsAx = 2*obj.dX + (j-1)*(2*obj.hghtHdr + obj.dX);
                pPosAx = [2*obj.dX,yOfsAx,obj.widAx,obj.hghtAx];
                hAx = createUIObj('axes',obj.hPanelP,...
                    'Units','Pixels','Position',pPosAx);                    
                
                % creates the text label object
                yOfsT = yOfsAx + obj.hghtAx;
                pPosT = [2*obj.dX,yOfsT,obj.widAx,obj.hghtTxt];
                hTxt = createUIObj('text',obj.hPanelP,...
                    'Position',pPosT,'FontUnits','Pixels',...
                    'FontWeight','bold','FontSize',obj.fSzH,...
                    'String',obj.wStr{i});
                
                % sets the objects into the data struct
                obj.hObj(i).wImg = image(obj.wImg(i,:,:),'parent',hAx);
                [obj.hObj(i).wAxes,obj.hObj(i).wStr] = deal(hAx,hTxt);
                
                % updates the progress bar axes
                set(hAx,'XTick',[],'YTick',[],'XTicklabel',[],...
                      'YTicklabel',[],'Xcolor','k','Ycolor','k','Box','on')                    
            end
            
        end
        
        % --------------------------------------- %
        % --- OTHER OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- updates the stimuli information text labels
        function updateTextInfo(obj,ind,tStr,tCol)
            
            % sets the default input arguments
            if ~exist('tCol','var'); tCol = 'k'; end
            
            % updates the text label
            set(obj.hTxtI{ind(1),ind(2)},...
                'String',tStr,'ForegroundColor',tCol)
            
        end
        
        % --- updates the status string and progressbar axes
        function isCancel = updateBar(obj,ind,wStr,wProp)            
            
            % initialisation
            isCancel = false;
            
            % determines if the abort experiment button has been clicked
            if obj.hButC.Value
                % case is the user cancelled
                isCancel = true;
                
            else
                % updates the image array
                wLen = round(wProp*obj.nPr);
                obj.wImg(ind,1:wLen,2:3) = 0;
                obj.wImg(ind,(wLen+1):end,2:3) = 1;
                
                % updates the status bar/strings
                obj.hObj(ind).wImg.CData = obj.wImg(ind,:,:);
                obj.hObj(ind).wStr.String = wStr;
                drawnow
            end
            
        end
        
        % --- closes the dialog window
        function closeWindow(obj)
            
            try
                delete(obj.hFig);
            catch
            end
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- retrieves the row 
        function pStrR = getInfoRowString(obj,iRow)
            
            % initialisations
            iOfs = double(obj.hasIMAQ);
            pStrR = {[],'0',[],[],'N/A'};
            chInfo = getappdata(obj.hExptF,'chInfo');             
            
            % sets the device string field
            if iOfs && (iRow == 1)
                % case is the recording row
                pStrR{1} = 'Video Recordings: ';
                pStrR{4} = num2str(obj.iExpt.Video.nCount);
                
            else
                % case is a stimuli device
                j = iRow - iOfs;
                iID = obj.chID(j,3);
                pStrR{1} = sprintf('%s (%s)',chInfo{iID,3},chInfo{iID,3});
                pStrR{4} = num2str(obj.nCount(j));
            end
                
        end
        
    end   
    
    % private class methods
    methods (Access = private)
        
        % --- sets a class object field
        function SetDispatch(obj, propname, varargin)
            
            obj.objB.(propname) = varargin{:};
            
        end
        
        % --- gets a class object field
        function varargout = GetDispatch(obj, propname)
            
            varargout{:} = obj.objB.(propname);
            
        end
        
    end    
    
end