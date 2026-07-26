classdef StimObjManager < handle & dynamicprops
    
    % class properties
    properties
        
        % sub-class object fields
        objS
        objDL
        
        % plot handle class fields
        sBlkT        
        hFillCh               
        hFillSig
        
        % channel class fields
        iChH = -1;
        iSigH = -1;
        iSigS = [NaN,NaN];
        
        % distance line timer
        hTimerDL
        
        % boolean class fields
        isProto
        
        % fixed numerical class fields
        lWid = 3;
        pRnd = 0.001;
        ix = [1,1,2,2];
        iy = [1,2,2,1];      
        
        % fixed string/cell array fields
        tagStrDL
        sStr = 'LS';
        htStr = {'none','all'};        
        
    end    
    
    % private class properties
    properties (Access = private)
        
        objB
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = StimObjManager(objB,isProto)
            
            % input arguments
            obj.objB = objB; 
            obj.isProto = isProto;
            
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
            fldStr = {'hFig','hPanelAx','hAx','hButC','hButT',...
                      'nCh','chName','chID','chInfo','chCol','nChTot',...
                      'tDurTot','tDurTotU','mType','mpStrDef',...
                      'iExpt','tType','yGap','iTab','axPosX','axPosY',...
                      'isInit','isShort','isHLOn','isMouseDown',...
                      'isOverAxesFcn','defMouseCursor','sTrainP',...
                      'calcExptStimDurFcn','setPanelPropFcn','sName',...
                      'objR','objP','objT','clearTimerFcn'};
            
            % connects the base/child objects
            for propname = fldStr
                if isprop(obj.objB, propname{1})
                    metaprop = addprop(obj, propname{1});
                    metaprop.SetMethod = @(obj, varargin) ...
                        SetDispatch(obj, propname{1}, varargin{:});
                    metaprop.GetMethod = ...
                        @(obj)GetDispatch(obj, propname{1});
                end
            end
            
        end     
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % memory allocation
            [obj.objS,obj.hFillCh] = deal(cell(obj.nChTot,1));
           
            if obj.isProto
                obj.tagStrDL = 'hTimerDLEx';
            else
                obj.tagStrDL = sprintf('hTimerDL%s',obj.sStr(1+obj.isShort));
            end
            
            % deletes any previous timers
            obj.clearTimerFcn(obj.tagStrDL);
            
            % timer object
            obj.hTimerDL = timer(...
                'StartDelay',0.1,...
                'TimerFcn',@obj.displayDistLine,...
                'Tag',obj.tagStrDL);
            
        end        
        
        % --- initialises the class objects
        function initClassObjects(obj)
            
            % initialisations 
            pCol0 = [0,0,0];
            xx = [0,obj.tDurTot];
            
            % creates the stimuli channel objects
            for iCh = 1:obj.nChTot
                yy = [(iCh+obj.yGap),(iCh+1)] - 1;
                obj.hFillCh{iCh} = patch(obj.hAx,xx(obj.ix),...
                    yy(obj.iy),pCol0,'UserData',iCh,...
                    'EdgeColor',obj.chCol{iCh},'FaceAlpha',0,...
                    'LineWidth',2,'tag','chFill','visible','off');
            end
            
            % creates the distance line objects
            obj.objDL = StimDistLine(obj);  
            
            % creates the temporary stimuli objects
            if obj.isProto
                obj.sBlkT = TempBlockObj(obj);                
            else
                obj.sBlkT = TempTrainObj(obj);
            end
            
        end                

        % --------------------------------------------- %
        % --- CLASS EVENT/OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------------------- %        
        
        % --- display distance line timer function
        function displayDistLine(obj,varargin)
                        
            % displays the distance lines (if mouse is still down)
            if obj.isMouseDown
                obj.objDL.setLineVisible('on');
            end
            
        end        
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- resets the stimuli object index fields
        function resetObjectIndices(obj)
            
            obj.iSigS(:) = NaN;
            [obj.iChH,obj.iSigH] = deal(-1);
            
        end
        
        % --- resets the stimuli highlight
        function resetStimHighlight(obj,hHover)
            
            
            
        end
        
        % --- resets the custom mouse pointer
        function resetCustomMousePointer(obj)
                
            if obj.isProto
                obj.mpStrDef = 'arrow';
                return
            end
            
            % resets the custom points
            obj.mpStrDef = obj.getCustomMousePointer(obj.objP.tTabSel);            
            
            % updates the mouse pointer cdata
            if isempty(obj.mpStrDef)
                % if no data is set, then use the default cursor
                obj.mpStrDef = obj.defMouseCursor;
                set(obj.hFig,'Pointer',obj.mpStrDef)
            else
                % otherwise, update the custom mouse pointer
                set(obj.hFig,'PointerShapeCData',obj.mpStrDef,...
                    'Pointer','custom')
            end
            
        end
        
        % --- calculates the stimuli object horizontal offset
        function x0 = calcStimObjOffset(obj,mPX,tDurS,tDurEx)
            
            if mPX < tDurS/2
                % case is the mouse point is close to the start
                x0 = 0;
                
            elseif mPX > (tDurEx - tDurS/2)
                % case is the mouse point is close to the end
                x0 = roundP(tDurEx - tDurS,obj.pRnd);
                
            else
                % otherwise case
                x0 = roundP(mPX - tDurS/2,obj.pRnd);
            end
            
        end        
        
        % --- retrieves the total stimuli object count
        function nObjTot = getTotalStimCount(obj)
            
            xiCh = 1:length(obj.objS);
            nObjTot = sum(arrayfun(@(x)(obj.getChannelStimCount(x)),xiCh));
            
        end
        
        % --- retrieves the stimuli object count for channel, iCh
        function nObjCh = getChannelStimCount(obj,iCh)
            
            nObjCh = obj.objS{iCh}.nObj;
            
        end
        
        % --- resets the distance line visibility
        function setDistLineVisibility(obj,vState)
            
            obj.objDL.setLineVisible(vState)
            
        end        
        
        % --- determines if the new block is feasible
        function stimBlockFeasCheck(obj)
            
            % exit if hover channel is not set
            if obj.iChH < 1
                return
            end
            
%             % REMOVE ME LATER
%             waitfor(msgbox('Finish Me!','modal'));
            
        end       
        
        % --- sets the selected stimuli object properties
        function setSelectedObjProps(obj,sState,varargin)
            
            % initialisations
            isSel = strcmp(sState,'on');
            
            %
            if isSel
                % case is enabling the selected object properties
                
                % retrieves the currently selected train object handle
                if obj.isProto
                    % case is the experimental protocol tab
                    if obj.iSigH < 0
                        % case is no object is being hovered over
                        return
                    else
                        % otherwise, update the selected object fields
                        sBlkH = obj.sBlk{obj.iSigH};
                        obj.iSigS = obj.iSigH;
                        obj.objT{4}.hListB.Value = obj.iSigS;
                    end
                    
                else
                    % case is the stimuli protocol tabs
                    sBlkH = obj.getHoverTrain();
                    if isempty(sBlkH)
                        % case is no block is being hovered over
                        return
                    else
                        % otherwise, update the selected object fields
                        obj.iSigS = [obj.iChH,obj.iSigH];
                    end
                end
                
                % disables the signal object hit-test flags
                obj.setSignalObjHitTest('off');
                sBlkH.setStimObjProps('EdgeColor','r')
                
                % updates the parameter fields
                if obj.isProto
                    % case is the expt protocol tab
                    sTrainEx = obj.sTrainP.Ex{obj.iSigH};
                    obj.objR.resetSelectedBlockPara(sTrainEx);
                    
                else
                    % case is the stimuli protocol tab
                    obj.objP.resetSelectedTrainPara(sBlkH.sPara);
                end
                                
                % shows the distance line markers
                sBlkH.alterStimObjProps([],[],'rPos')
                if strcmp(get(obj.hTimerDL,'Running'),'off')
                    start(obj.hTimerDL);
                end
                
                % updates the mouse state value
                obj.mType = 1 + 2*(1 + obj.isProto);
                
            else
                % case is disabling the selected object properties                
                
                % updates the parameter fields
                if obj.isProto
                    % removes any selected block highlights
                    if ~isnan(obj.iSigS)
                        obj.setSignalBlockHighlight([],'off');                        
                    end
                    
                else
                    % re-enables the signal object hit-test flags
                    sBlkS = obj.getSelectedTrain();
                    if ~isempty(sBlkS)
                        obj.iSigH = obj.iSigS(2);
                        obj.setSignalBlockHighlight([],'off');
                    end
                end
                
                % resets the hit-test properties
                obj.setSignalObjHitTest('on');                
                
                % resets the mouse state/selected signal block index
                [obj.mType,obj.iSigS(:)] = deal(0,NaN);
            end
            
            % updates the signal panel object properties
            if obj.isProto
                obj.setPanelPropFcn('BlockProps',isSel,isempty(varargin))
            else
                obj.setPanelPropFcn('SignalProps',isSel,isempty(varargin))
            end
            
        end
        
        % --- stimuli object selection function
        function ok = selectStimObject(obj)
            
            % initialisations
            ok = true;
            mPos = get(obj.hFig,'CurrentPoint');            
            
            % determines if the mouse if hovering over
            if obj.isOverAxesFcn(mPos)
                % retrieves the hovered block index
                hHover = findAxesHoverObjects(obj.hFig);                 
                sRectB = findobj(hHover,'tag','hSigBlk');
                
                % determines if a signal block is being hovered over
                if isempty(sRectB)
                    % 
                    ok = false;
                    return
                    
                else
                    % determines if there is a change in channel index
                    if obj.isProto
                        % case is a expt stimuli block object
                        if obj.iSigH > 0
                            sBlkS = obj.sBlk{obj.iSigH};
                            isChange = ~isequal(sRectB,sBlkS.hRectS.hObj);
                        else
                            isChange = true;
                        end
                         
                        % determines the signal objects
                        isChB = obj.detFillHoverObj(hHover,'hSigBlk');
                        hHoverChB = hHover(isChB);
                        if length(hHoverChB) > 1
                            % determines the signal block which matches the
                            % hover signal block index
                            objExSM = obj.objT{4}.objSM;
                            idBlk = cell2mat(get(hHoverChB,'UserData'));

                            % determines the matching signal block
                            if ~isnan(objExSM.iSigS)
                                ii = objExSM.idBlkList(...
                                    objExSM.iSigS) == idBlk;
                            else
                                ii = objExSM.idBlkList(...
                                    objExSM.iSigH) == idBlk;
                            end
                            
                            % keeps the relevant block object handle
                            hHoverChB = hHoverChB(ii);                            
                        end                        
                        
                        % determines the mapped block index
                        iSigNw = obj.mapBlkIndex(hHoverChB.UserData);
                            
                    else
                        % case is a stimuli train object
                        sRectCh = findobj(hHover,'tag','chFill');
                        iSigNw = [sRectCh.UserData,sRectB.UserData];
                        isChange = ~isequal(iSigNw,obj.iSigS);                        
                    end

                    % updates the channel selection
                    if isChange
                        obj.toggleChannelSelection(iSigNw);
                    end
                end      
                
                % shows the distance line markers (if timer not running)
                isRunningT = get(obj.hTimerDL,'Running');
                if obj.isMouseDown && strcmp(isRunningT,'off')
                    start(obj.hTimerDL);
                end
            else
                ok = false;
            end
            
        end
        
        % --- toggles the channel selection tp the indices, iChR
        function toggleChannelSelection(obj,iSigNw)
            
            % turns off the current highlight
            if obj.isProto
                if ~isnan(obj.iSigS)
                    obj.iSigH = obj.iSigS;
                    obj.setSignalBlockHighlight([],'off');
                end                
                
                % turns on the new highlight (if valid)
                if ~isnan(iSigNw)
                    obj.iSigH = iSigNw;
                    sBlkH = obj.sBlk{iSigNw};
                    obj.setSignalBlockHighlight(sBlkH,'on');
                end                
                
            else
                if ~any(isnan(obj.iSigS))
                    [obj.iChH,obj.iSigH] = deal(obj.iSigS(1),obj.iSigS(2));
                    obj.setSignalBlockHighlight([],'off');
                end
                
                % turns on the new highlight (if valid)
                if ~any(isnan(iSigNw))
                    [obj.iChH,obj.iSigH] = deal(iSigNw(1),iSigNw(2));
                    sBlkH = obj.getHoverTrain();
                    obj.setSignalBlockHighlight(sBlkH,'on');
                end
            end
            
            % updates the channel index field
            obj.iSigS = iSigNw; 
            obj.setSelectedObjProps('on');
            
        end                           
        
        % --- updates the channel positions to match the signal duration
        function updateChannelPosition(obj)
            
            % initialisations 
            if obj.isProto
                Timing = obj.iExpt.Timing;
                xx = [0,vec2time(Timing.Texp,Timing.TexpU)];
            else
                xx = [0,obj.tDurTot];
            end
            
            % creates the stimuli channel objects
            for iCh = 1:obj.nChTot
                obj.hFillCh{iCh}.XData = xx(obj.ix);
            end                     
            
        end        
        
    end
    
    % static class methods
    methods (Static)
        
        % --- creates the custom mouse pointer based on the signal type
        function mpCData = getCustomMousePointer(sType)
            
            % initialisations
            N = 16;
            [mpCD,sz] = deal(false(N),N*[1,1]);
            
            % sets the binary mask (based on the signal type)
            switch sType
                case 'Square'
                    % case is the squarewave signal
                    
                    % sets the points
                    del = N/4 - 1;
                    pX = [2,2+del,2+del,3+3*del,3+3*del,N-1];
                    pY = [N-1,N-1,2,2,N-1,N-1];
                    
                    % creates the squarewave array
                    for i = 1:length(pX)-1
                        if pY(i) > pY(i+1)
                            mpCD(pY(i):-1:pY(i+1),pX(i):pX(i+1)) = true;
                        else
                            mpCD(pY(i):pY(i+1),pX(i):pX(i+1)) = true;
                        end
                    end
                    
                case 'Ramp'
                    % case is the ramp
                    
                    % sets the x/y data points
                    x = roundP(linspace(N-1,2,2*N));
                    
                    % creates the binary mask
                    mpCD(sub2ind(sz,(N+1)-x,x)) = true;
                    
                case 'Triangle'
                    % case is the signal waveform
                    
                    % sets the x/y data points
                    x1 = linspace(1,N/2,2*N);
                    x2 = linspace(N/2+1,N,2*N);
                    y1 = N - roundP(2*(x1-1)+1);
                    
                    % creates the binary mask
                    mpCD(sub2ind(sz,y1,roundP(x1))) = true;
                    mpCD(sub2ind(sz,y1(end:-1:1),roundP(x2))) = true;
                    
                case 'SineWave'
                    % case is the sinewave
                    
                    % sets the x/y data points
                    x = linspace(0,2*pi,200);
                    y = 1 + roundP((N-1) * 0.5 * (sin(x) + 1));
                    
                    % creates the binary mask
                    mpCD(sub2ind(sz,y,roundP(1+(N-1)*x/(2*pi)))) = true;
                    
                otherwise
                    % case is custom signal type
                    mpCData = [];
                    return
            end
            
            % dilates the mask and sets all zero points to NaNs
            mpCData = double(bwmorph(mpCD,'dilate'));
            mpCData(mpCData == 0) = NaN;
            
        end        
        
        % --- determines which objects in h are channel fill objects
        function isChP = detFillHoverObj(h,tagStr)
            
            if ~exist('tagStr','var')
                tagStr = 'chFill';
            end
            
            isChP = arrayfun(@(x)(strContains(get(x,'tag'),tagStr)),h);
            
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