classdef BlobCNNProgBar < matlab.mixin.SetGet
   
    % class properties
    properties
     
        % input arguments
        pCNN
        isTrain
        wStrPh
        wStrS        
        
        % object handle class fields
        hFig
        hObjS
        hBut
        hPanel
        hPanelS
        
        % timer object class fields
        t0
        hTimer
        nIterT = NaN;
        
        % boolean flags
        hasCancel = true;
        isVisible = true;
        isCancel = false; 
        
        % fixed object dimensions
        dX = 10;
        dY = 50;
        bOfs = 10;                  % panel border offset
        xyOfs = 20;                 % x/y offset
        bWid = 400;                 % box width
        btWid = 80;                 % button width
        bHgt = 20;                  % box/edit height          
        
        % calculated object dimensions
        dHghtS
        hghtFig
        hghtPanel
        hghtPanelS        
        widFig
        widPanel
        widPanelS
        
        % other properties
        nLvl
        nLvlS
        pAccMx
        
        % static scalar fields
        iPhaseT = 1;
        iSelS = NaN;
        cProp = 0;
        mxProp = 1;
        fSz = 12;
        fSzH = 13;
        nPhaseT = 4;
        wImg = ones(1,1000,3);   
        
        % other static fields
        tagStr = 'figTrainCNN';
        tagStrT = 'hTrainProg';
        figName = 'Blob CNN Network Training';
        fldNames = {'wStr','wAxes','wImg'};        
        wStrS0 = {'Overall Training Progress','Training Accuracy'};
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = BlobCNNProgBar(pCNN,isTrain)
            
            % sets the input arguments
            obj.pCNN = pCNN;
            obj.isTrain = isTrain;
                        
            % initialises the progress bar
            obj.initClassFields();
            obj.initClassObjects();
            
        end

        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % sets the training waitbar strings
            if obj.isTrain
                % case is training and classification
                wStrPhT = {'INITIAL NETWORK TRAINING',...
                           'TRAINING ACCURACT CHECK',...
                           'FULL NETWORK TRAINING'};
                wStrST = {obj.wStrS0,{'INITIAL NETWORK CHECK'},obj.wStrS0};
                
            else
                % case is for classification only
                [wStrPhT,wStrST] = deal([]);
            end
            
            % sets the panel header/sub-level string fields             
            obj.wStrPh = [{'OVERALL TRAINING PROGRESS',...
                           'INITIAL MOVEMENT DETECTION'},wStrPhT,...  
                          {'POST-TRAINING CALCULATIONS'}];
            obj.wStrS = [{{'Initialising Tracking Objects...'}},...
                         {{'Reading Image Stack'}},wStrST,...
                         {{'Static Object Detection',...
                           'Quality Metric Calculations'}}];
                    
            % initialisations
            [nStr,obj.nLvl] = deal(length(obj.wStrPh));  
            obj.nLvlS = cellfun('length',obj.wStrS);            
            
            % memory allocation
            obj.hghtPanelS = zeros(nStr,1);

            % ---------------------------------------- %            
            % --- SUB-PANEL DIMENSION CALCULATIONS --- %
            % ---------------------------------------- %
            
            % sub-figure 
            dHghtP = 25;
            obj.dHghtS = obj.bOfs + obj.bHgt;      
            
            % sets the heights of the sub-regions
            for i = 1:obj.nLvl
                obj.hghtPanelS(i) = obj.nLvlS(i)*obj.dY + dHghtP;
            end
            
            % ---------------------------------------- %
            % --- FIGURE DIMENSIONING CALCULATIONS --- %
            % ---------------------------------------- %
            
            % sets the figure dimensions
            obj.widFig = 6*obj.dX + obj.bWid;
            obj.hghtFig = sum(obj.hghtPanelS) + ...
                obj.dHghtS + ((nStr-1)+8)*(obj.dX/2);
            
            % sets the outer panel dimensions
            obj.widPanel = obj.widFig - 2*obj.dX;
            obj.hghtPanel = obj.hghtFig - (2*obj.dX + obj.dHghtS);
            obj.widPanelS = obj.widPanel - 2*obj.dX;
            
            % -------------------------- %
            % --- TIMER OBJECT SETUP --- %
            % -------------------------- %            
            
            % stops and deletes any previous timer objects
            hTimerPr = timerfindall('tag',obj.tagStrT);
            if ~isempty(hTimerPr)
                stop(hTimerPr)
                delete(hTimerPr);
            end
            
            % sets up the timer object
            obj.hTimer = timer('ExecutionMode','fixedRate',...
                'BusyMode','drop','Period',1,'TasksToExecute',inf,...
                'tag',obj.tagStrT,'TimerFcn',@obj.timerProgBar);
            
        end        
        
        % --- initalises the class objects
        function initClassObjects(obj)
        
            % removes any previous GUIs
            hFigPr = findall(0,'tag',obj.tagStr);
            if ~isempty(hFigPr); delete(hFigPr); end
            
            % -------------------------- %
            % --- MAIN CLASS OBJECTS --- %
            % -------------------------- %
            
            % creates the figure object
            fPos = [100*[1,1],obj.widFig,obj.hghtFig];
            obj.hFig = dialog('Position',fPos,'tag',obj.tagStr,...
                              'Name',obj.figName,'Visible','off');            

            % sets the object data into the gui
            set(obj.hFig,'windowstyle','normal')                           
                          
            % creates the inner panel                  
            pPos = [obj.bOfs+[0,obj.dHghtS],obj.widPanel,obj.hghtPanel];
            obj.hPanel = uipanel(obj.hFig,'units','pixels','position',pPos);                        

            % ----------------------------------- %
            % --- SUB-PANEL PROGRESSBAR SETUP --- %
            % ----------------------------------- %
            
            % initialisations
            y0 = obj.dX;
            obj.hPanelS = cell(obj.nLvl,1);
            hObj0 = struct('wStr',[],'wAxes',[],'wImg',[],'wProp',[]);
            
            % memory allocation
            obj.hObjS = arrayfun(@(x)(repmat(hObj0,x,1)),obj.nLvlS,'un',0);
            
            % sets up the sub-panel objects
            for i = flip(1:obj.nLvl)
                % creates the panel object
                pPosP = [obj.dX,y0,obj.widPanelS,obj.hghtPanelS(i)];
                obj.hPanelS{i} = createUIObj('panel',obj.hPanel,...
                  'FontSize',obj.fSzH,'Title',obj.wStrPh{i},...
                  'FontWeight','Bold','Units','Pixels','Position',pPosP);
              
                % increments the bottom location
                y0 = sum(pPosP([2,4])) + obj.dX/2;
                
                %
                for j = flip(1:obj.nLvlS(i))
                    % sets the positions of the current waitbar objects
                    k = obj.nLvlS(i) - (j-1);                    
                    posAx = [obj.dX,(k*obj.dX)+(k-1)*(2*obj.bHgt),...
                             obj.bWid,obj.bHgt];
                    posStr = posAx + [0,obj.bHgt,0,0];                    

                    % creates the waitbar objects
                    obj.hObjS{i}(j).wAxes = createUIObj('axes',...
                        obj.hPanelS{i},'units','pixels','position',posAx);
                    obj.hObjS{i}(j).wStr = createUIObj('text',...
                        obj.hPanelS{i},'position',posStr,'FontUnits',...
                        'Pixels','FontSize',obj.fSz,...
                        'string',obj.wStrS{i}{j});                    
                    obj.hObjS{i}(j).wImg = ...
                        image(obj.wImg,'parent',obj.hObjS{i}(j).wAxes);
                    obj.hObjS{i}(j).wProp = 0;
                    
                    % sets the axes properties
                    set(obj.hObjS{i}(j).wAxes,'xtick',[],'ytick',[],...
                        'xticklabel',[],'yticklabel',[],'xcolor','k',...
                        'ycolor','k','box','on')
                    
                    % updates the dialog window handles
                    guidata(obj.hFig,obj.hObjS{i})                    
                end                
                
            end
            
            % disables the other levels
            cellfun(@(x)(setPanelProps(x,0)),obj.hPanelS(2:end))            
            
            % --------------------------- %
            % --- CANCEL BUTTON SETUP --- %
            % --------------------------- %
            
            % creates a cancel button (if required)
            btPos = [(fPos(3)-(obj.btWid+obj.bOfs)),...
                      obj.bOfs,obj.btWid,obj.bHgt];
            obj.hBut = uicontrol(obj.hFig,'style','togglebutton',...
                        'string','Cancel','tag','buttonCancel',...
                        'position',btPos,'Callback',@obj.cancelClick);
           
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % centers and refreshes the figure
            centerfig(obj.hFig);
            refresh(obj.hFig);  
            
            % makes the window visible
            setObjVisibility(obj.hFig,1);   
            pause(0.05);
            drawnow
                    
        end

        % ------------------------------------ %
        % --- PROGRESSBAR UPDATE FUNCTIONS --- %
        % ------------------------------------ %        
        
        % --- updates the progressbar 
        function isStop = Update(obj,iLvl,varargin)
            
            % if the user cancelled (or the figure was deleted) then return
            % a true values for cancellation
            if obj.isCancel || ~isvalid(obj.hFig)
                % sets the cancel flag and closes the progressbar
                isStop = true;
                obj.closeProgBar();
                
                % exits the function
                return
            else
                % otherwise, flag that the user didn't cancel
                isStop = false;
            end                        
            
            % sets the progressbar properties (based on type)
            switch iLvl
                case 2                    
                    % sets up the progressbar proportion/label strings
                    switch varargin{1}
                        case 1
                            % case is the image stack read
                            wStr0 = 'Reading Image Stack';
                            
                        case 2
                            % case is moving object detection
                            wStr0 = 'Moving Object Detection';
                    end
                    
                    % sets the progressbar proportion/label string
                    wPropNw = varargin{2};                    
                    wStrNw = {sprintf('%s (%i%%)',wStr0,round(100*wPropNw))};
                
                case 4
                    % case is the training accuracy check
                    switch varargin{1}
                        case 0
                            % case is search point setup
                            wStrNw = obj.wStrPh(2);
                        
                        case 1
                            % case is search point setup
                            wStrNw = {'Setting Up Search Grid'};
                            
                        case 2
                            % case is classification
                            wStrNw = {'Classifying Search Points'};
                            
                        case 3
                            % case is sub-image retrieval
                            wStrNw = {'Appending Misclassified Points'};
                            
                        case 4
                            % case is sub-image retrieval
                            wStrNw = {'Accuracy Check Complete!'};                            
                    end
                    
                    % sets the proportional value
                    wPropNw = varargin{1}/4;                    
                    
                case {3,5}
                    % case is the network training
                    
                    % memory allocation
                    if isempty(varargin)
                        % case is the training has completed
                        
                        % sets the label strings/proportions
                        wStrSP = obj.wStrS{iLvl};
                        wStrNw = cellfun(@(x)(sprintf(...
                            '%s (Complete)',x)),wStrSP(:),'un',0);
                        wPropNw = ones(2,1);
                        
                    elseif length(varargin) == 1
                        % case is initialising the network training
                        
                        % sets the label strings/proportions
                        wStrSP = obj.wStrS{iLvl};
                        wStrNw = cellfun(@(x)(sprintf(...
                            '%s (Initialising)',x)),wStrSP(:),'un',0);
                        wPropNw = zeros(2,1); 
                      
                        % resets the maximum accuracy
                        obj.pAccMx = 0;
                        
                    else
                        % field retrieval
                        [evnt,pCountT] = deal(varargin{1},varargin{2});
                        pAcc = evnt.TrainingAccuracy/100;
                        
                        % sets up the progress proportions
                        wPropNw = zeros(2,1);
                        wPropNw(1) = evnt.Iteration/obj.nIterT;
                        wPropNw(2) = 0.5*(pAcc + pCountT);
                        
                        % resets the maximum accuracy
                        obj.pAccMx = max(obj.pAccMx,wPropNw(2));
                        wPropNw2 = [NaN,obj.pAccMx];
                        
                        % sets up the progressbar label strings
                        wStrNw = cellfun(@(x,y)(sprintf('%s (%i%%)',...
                            x,round(100*y))),obj.wStrS{iLvl}(:),...
                            num2cell(wPropNw),'un',0);
                    end
                    
                case 6
                    % case is the stationary blob tracking
                    
                    % sets the proper level index
                    iLvl = 3*(1 + obj.isTrain);
                    wStrL = obj.wStrS{iLvl}{1};
                    
                    % sets the progress proportion/string
                    if isempty(varargin)
                        % case is house-keeping or completed
                        xiP = 2;                        
                        wPropNw = 1;
                        wStrNw = {'Initial Tracking Complete!'}; 
                        
                    elseif length(varargin) == 1
                        % case is house-keeping or completed
                        wPropNw = 1;
                        
                        %
                        switch varargin{1}
                            case 0
                                % case is house-keeping
                                wStrNw = {...
                                    sprintf('%s (Tracking Blobs)',wStrL)};
                                
                            case 1
                                % case is completion
                                wStrNw = {sprintf('%s (Complete)',wStrL)};
                        end
                        
                    else
                        % case is a frame update
                        xiP = 1;
                        iFrm = varargin{1};
                        nFrm = varargin{2};
                        
                        % calculates progress proportion
                        wPropNw = iFrm/(1+nFrm);
                        
                        % case is the 3rd input is the base string
                        if length(varargin) == 3
                            wStrL = varargin{3};
                            xiP = 2;
                        end                   

                        % sets the final level string
                        wPropStr = round(100*iFrm/nFrm);                        
                        wStrNw = {sprintf('%s (%i%%)',wStrL,wPropStr)};                        
                        
                    end
            end
            
            % retrieves the relevant progressbar objects
            if exist('xiP','var')
                hObjP = obj.hObjS{iLvl}(xiP);
            else
                hObjP = obj.hObjS{iLvl};
            end                    
            
            % initialises an empty NaN arrays for the 2nd proportion
            if ~exist('wPropNw2','var')
                wPropNw2 = NaN(size(wPropNw));
            end
            
            % updates the progressbar properties
            for i = 1:length(wPropNw)
                % updates the other progressbar fields
                obj.updateProgProp(hObjP(i),wPropNw(i),wPropNw2(i));
                set(hObjP(i).wStr,'String',wStrNw{i});
            end
            
            % pause for update
            drawnow
            pause(0.01);
            
        end
        
        % --- updates progress proportion for progress object, hObjP
        function updateProgProp(obj,hObjP,wPropNw,wPropNw2)
            
            % sets the default input arguments
            if ~exist('wPropNw2','var'); wPropNw2 = NaN; end
            
            % updates the image colour
            wLen = roundP(wPropNw*1000,1);
            xiP = 1:wLen;
            obj.wImg(:,xiP,1) = 1;
            obj.wImg(:,xiP,2:3) = 0;
            obj.wImg(:,(wLen+1):end,:) = 1;
            
            % updates the secondary colour (if required)
            if ~isnan(wPropNw2)
                wLen2 = roundP(wPropNw2*1000,1);
                xiP2 = (wLen+1):wLen2;
                obj.wImg(:,xiP2,2) = 1;
                obj.wImg(:,xiP2,[1,3]) = 0;       
                obj.wImg(:,(wLen2+1):end,:) = 1;
            end

            % updates the axes image object
            set(hObjP.wImg,'CData',obj.wImg);
            
            % updates the proportion field
            hObjP.wProp = wPropNw;            
            
        end
        
        % --- updates the training phase index
        function updateTrainPhase(obj,iPhaseNw,startTimer)
            
            % sets the input arguments
            if ~exist('startTimer','var'); startTimer = false; end
            
            % starts the progressbar timer object (first phase only)
            if startTimer
                obj.t0 = clock;
                start(obj.hTimer);
            end
            
            % updates the main phase
            obj.iPhaseT = iPhaseNw;
            obj.resetPhaseProps(iPhaseNw + 1);
            
            % updates the overall progressbar
            obj.updateProgProp(obj.hObjS{1}(1),iPhaseNw/(obj.nLvl-1));
            drawnow
            pause(0.01);            
            
        end
        
        % --- progressbar timer function
        function timerProgBar(obj, ~, evnt)
            
            % if the progressbar is deleted, then exit
            if ~isvalid(obj.hObjS{1}(1).wStr)
                stop(obj.hTimer)
                return
            end
            
            % sets up the time string
            dTime = seconds(etime(evnt.Data.time,obj.t0));
            timeStr = datestr(dTime,'HH:MM:SS');
            
            % updates the string
            wStrP0 = obj.wStrPh{obj.iPhaseT+1};
            wStrP = sprintf('%s (Elapsed Time: %s)',wStrP0,timeStr);                        
            obj.hObjS{1}(1).wStr.String = wStrP;  
            
        end        
        
        % --- callback function for clicking the cancel button
        function cancelClick(obj,hObject,~)
            
            % updates the cancellation flag
            obj.isCancel = true;
            
            % resets the button properties so the user can't un-cancel
            setObjEnable(hObject,'inactive');
            
        end          
        
        % ------------------------------- %        
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- sets the progressbar visibility
        function setVisibility(obj,vState)
            
            setObjVisibility(obj.hFig,vState);
            
        end
        
        % --- closes the progress bar (if not already deleted)
        function closeProgBar(obj)
            
            % stops and deletes the timer object
            if isvalid(obj.hTimer)
                if strcmp(get(obj.hTimer,'Running'),'on')
                    stop(obj.hTimer);
                end

                % deletes the timer object
                delete(obj.hTimer);            
            end
            
            % deletes the dialog window
            delete(obj.hFig)
            
        end          
        
        % --- resets the phase panel enabled properties
        function resetPhaseProps(obj,iSelNw)
            
            % resets the highlight on any enabled panel
            if ~isnan(obj.iSelS)
                if isequal(iSelNw,obj.iSelS)
                    return
                else
                    setPanelProps(obj.hPanelS{obj.iSelS},0);
                    obj.iSelS = NaN;
                end
            end
            
            % enables the new level 
            setPanelProps(obj.hPanelS{iSelNw},1);
            obj.iSelS = iSelNw;
            
        end
        
        % --- recalculates the network training iteration count
        function recalcIterCount(obj,nSample,nEpoch,mBatchSz)
            
            obj.nIterT = nEpoch*floor(nSample/mBatchSz);            
            
        end
        
    end
    
end