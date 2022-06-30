classdef InitPhaseStats < handle
    
    % class properties
    properties
        
        % main class objects
        bgObj
        phInfo
        
        % object handles
        hFig        
        hTool
        hToolB
        hMenuP
        hPanelO
        hPanelAx
        hPanelT
        hTabGrp
        hTab
        hTxt
        hAx
        hLg
        
        % info marker related object
        hP
        hZoom
        axPosXF
        axPosYF
        wmFunc
        hText
        hMark
        
        % other data array fields
        Imu
        hMu
        hMuL
        hMuM
        
        % fixed object dimensions    
        dX = 10;
        fSz = 8;
        lblSz = 12;
        widFig
        hghtFig
        widPanelI
        hghtPanelAx
        hghtTxt = 16;        
        hghtPanelT = 35;        
        widPanelO = 560;
        hghtPanelO = 450; 
        widTxtL = 130;
        widTxt = 35;
        iTab = 1;
        
        % object position vectors
        pTabGrp
        pPanelT
        pPanelAx
        pAx
        
        % other boolean/scalar fields
        isResizing = true;
        colStr = 'kr';
        dyLim = 0.05;
        
    end
    
    % class methods
    methods
        
        % class constructor
        function obj = InitPhaseStats(bgObj)
            
            % sets the input arguments
            obj.bgObj = bgObj;
            obj.phInfo = bgObj.iMov.phInfo;
            
            % initialises the object properties
            obj.initClassFields();
            obj.initObjProps();
            
            % centres the figure
            setObjVisibility(obj.hFig,1)
            centreFigPosition(obj.hFig,2)
            obj.isResizing = false;
            
        end
        
        % --- initialises the class object fields
        function initClassFields(obj)
            
            % calculates the figure dimensions
            obj.widFig = obj.widPanelO + 2*obj.dX;
            obj.hghtFig = obj.hghtPanelO + 2*obj.dX;
            
            % deletes any initial tracking stats figures
            hFig0 = findall(0,'tag','figInitTrackStats');
            if ~isempty(hFig0); delete(hFig0); end
            
            % sets the windows movement callback function
            obj.wmFunc = {@obj.showPlotMarkerInfo};
            
        end
        
        % --- initialises the object properties
        function initObjProps(obj)
            
            % initialisations
            hasF = obj.phInfo.hasF;
            hasT = any(obj.phInfo.hasT);  
            iPhase = obj.bgObj.iMov.iPhase;
            vPhase = obj.bgObj.iMov.vPhase;            
            nPhase = length(vPhase);
            nApp = length(obj.bgObj.iMov.iR);
            
            % patch object indices
            mType = 0;
            yP = 255*[-1,1];
            pInfo = obj.phInfo;
            pCol = {0.5*ones(1,3)};
            [ii,jj] = deal([1,1,2,2,1],[1,2,2,1,1]);
            isFeas = any(vPhase < 3);            
            
            % other memory allocation            
            obj.Imu = cell(1,3);
            
            % sets the frame index/avg. pixel intensity arrays 
            if ~isFeas
                % case is the video is untrackable
                iFrm = pInfo.iFrm0;
                obj.Imu{1} = NaN(size(iFrm));                
                
            elseif hasF
                % case is the video has high fluctuation
                [iFrm,obj.Imu{1}] = deal(pInfo.iFrm0,pInfo.Dimg0);

            else
                % case is the video has relatively steady intensity
                iFrm = pInfo.iFrmF;            
                
                % sets the overall pixel intensity trace
                obj.Imu{1} = mean(pInfo.DimgF,2);
                                
                % sets the region pixel intensity traces
                if isfield(obj.bgObj.iMov,'srData')
                    % sets the overall region traces
                    [srD,mType] = deal(obj.bgObj.iMov.srData,3);
                    obj.Imu{2} = cell(1,nApp);                    
                    for i = 1:nApp
                        iCol = srD.indG{i}(:,1) == i;
                        obj.Imu{2}{i} = mean(pInfo.DimgF(:,iCol),2);
                    end

                    % sets the individual sub-region traces
                    obj.Imu{3} = num2cell(pInfo.DimgF,1);                    
                    
                else
                    % sets the overall region values
                    mType = 2;
                    obj.Imu{2} = num2cell(pInfo.DimgF,1);
                end
                
                % sets the patch colours                
                vPhase = obj.bgObj.iMov.vPhase;
                pCol = arrayfun(@(x)(obj.getPatchColour(x)),vPhase,'un',0);
            end                
            
            % sets the x-axis limit
            xLim = iFrm([1,end]);
            xTickStr = arrayfun(@(x)(num2str(x)),xLim,'un',0);
            
            % -------------------------- %
            % --- MAIN FIGURE OBJECT --- %
            % -------------------------- %            
            
            % sets the figure position
            fPos = [100,100,obj.widFig,obj.hghtFig];            
            
            % creates the figure object
            cbFcn = @obj.closeGUI;
            obj.hFig = figure('Position',fPos,'tag','figInitTrackStats',...
                              'MenuBar','None','Toolbar','None',...
                              'Name','Initial Tracking Statistics',...
                              'NumberTitle','off','Visible','off',...
                              'Resize','on','CloseRequestFcn',cbFcn,...
                              'WindowButtonMotionFcn',obj.wmFunc,...
                              'SizeChangedFcn',@obj.resizeGUI);
                          
            % creates the toolbar objects
            obj.hTool = uitoolbar(obj.hFig);
            obj.hToolB = uitoolfactory(obj.hTool,'Exploration.ZoomIn');
            set(obj.hToolB,'ClickedCallback',{@obj.zoomToggle})
            
            % creates the table panel
            pPosO = [obj.dX*[1,1],obj.widPanelO,obj.hghtPanelO];
            obj.hPanelO = uipanel(obj.hFig,'Title','','Units','Pixels',...
                                           'Position',pPosO);                          
                         
            % creates the trace menu items (if required)
            if mType > 0
                % creates the main menu item
                menuStr = 'Pixel Intensity Trace';
                obj.hMenuP = uimenu(obj.hFig,'Label',menuStr);
                
                % creates the region menu items
                for i = 1:nApp
                    % creates the sub-region menu item
                    if mType == 2
                        % creates the 
                        cbFcn = {@obj.menuTrace,i};
                        rStr = sprintf('Region #%i Average',i);
                        uimenu(obj.hMenuP,'Label',rStr,...
                                    'Separator','Off','Callback',cbFcn);
                        
                    else
                        % creates the 
                        rStr = sprintf('Region #%i',i);
                        hMenuR = uimenu(obj.hMenuP,'Label',rStr);
                      
                        nSR = sum(srD.indG{i}(:,1) == i);
                        for j = 1:nSR
                            cbFcn = {@obj.menuTrace,[i,j]};
                            srStr = sprintf('Sub-Region #%i',j);
                            uimenu(hMenuR,'Label',srStr,'Callback',cbFcn);
                        end
                        
                        rStrT = 'Overall Average';
                        cbFcn = {@obj.menuTrace,[i,0]};
                        uimenu(hMenuR,'Label',rStrT,'Callback',cbFcn,...
                                      'Separator','on');
                    end
                end
                
                % creates the overall average item
                uimenu(obj.hMenuP,'Label','Overall Average',...
                          'Checked','On','Callback',{@obj.menuTrace,0},...
                          'Separator','On');
            end
                                       
            % ----------------------------- %
            % --- TAB GROUP PANEL SETUP --- %
            % ----------------------------- %   
            
            % sets the object positions
            y0Txt = 8;
            wState = warning('off','all');
            tStr = {'Image Intensity','Image Translation'};
            txtStr = {{'Fluctuation Detected: ',...
                       'Max. Intensity: ',...
                       'Min. Intensity: '},...
                      {'Translation Detected: ',...
                       'X-Movement Range: ',...
                       'Y-Movement Range: '}};            
            
            % calculates the other other object dimensions
            obj.setupObjDimensions();            

            % creates a tab panel group            
            obj.hTabGrp = createTabPanelGroup(obj.hPanelO,1);
            set(obj.hTabGrp,'position',obj.pTabGrp,'tag','hTabGrp')
                          
            % sets the colour strings   
            A = cell(length(tStr),1);
            obj.hP = cell(nPhase,length(tStr));
            [obj.hAx,obj.hTab,obj.hPanelT] = deal(A);
            [obj.hPanelAx,obj.hTxt] = deal(A);
            
            % sets up the tab objects (over all stimuli objects)            
            for i = 1:length(tStr)
                % sets up the tabs within the tab group
                obj.hTab{i} = createNewTab(obj.hTabGrp,...
                                    'Title',tStr{i},'UserData',i);
                set(obj.hTab{i},'ButtonDownFcn',{@obj.tabSelected})
                pause(0.1)
                
                % creates the axes panel object                
                obj.hPanelAx{i} = uipanel(obj.hTab{i},'Title','',...
                            'Units','Pixels','Position',obj.pPanelAx);
                                
                % creates the text information panel object                
                obj.hPanelT{i} = uipanel(obj.hTab{i},'Title','',...
                                'Units','Pixels','Position',obj.pPanelT);
                                
                % creates the axes object                
                obj.hAx{i} = axes(obj.hPanelAx{i},'Units','Pixels',...
                                'Position',obj.pAx,'box','on',...
                                'XTickLabel',xTickStr,'YTickLabel',[],...
                                'FontWeight','bold','xlim',xLim,...
                                'xtick',xLim);
                hold(obj.hAx{i},'on')
                grid(obj.hAx{i},'on')
                
                % creates the phase patch objects                
                for j = 1:nPhase
                    xP = [iPhase(j,1),iPhase(j,2)]+0.5*[-1,1];
                    obj.hP{j,i} = patch(obj.hAx{i},xP(ii),yP(jj),...
                                pCol{j},'FaceAlpha',0.2,'UserData',j);
                end
                
                % creates the text label objects
                x0L = obj.dX;
                obj.hTxt{i} = cell(length(txtStr{i}),1);
                for j = 1:length(txtStr{i})
                    % sets the text label string
                    widTxtNw = obj.widTxt + (j>1)*obj.dX;
                    
                    % creates the text object                    
                    tPosL = [x0L,y0Txt,obj.widTxtL,obj.hghtTxt];
                    uicontrol(obj.hPanelT{i},'Style','Text','Position',tPosL,...
                            'FontUnits','Pixels','FontWeight','Bold',...
                            'FontSize',obj.lblSz,'String',txtStr{i}{j},...
                            'HorizontalAlignment','right');
                    x0L = x0L + obj.widTxtL;
                        
                    % creates the text object
                    tPosT = [x0L,y0Txt,widTxtNw,obj.hghtTxt];
                    obj.hTxt{i}{j} = uicontrol(obj.hPanelT{i},...
                            'Style','Text','Position',tPosT,...
                            'FontUnits','Pixels','FontWeight','Bold',...
                            'FontSize',obj.lblSz,'String','N/A',...
                            'HorizontalAlignment','left');  
                    x0L = x0L + widTxtNw;
                end
            end    
            
            % resets the warning state
            warning(wState); 

            % ---------------------------- %
            % --- INTENSITY AXES SETUP --- %
            % ---------------------------- %                                 
            
            if isFeas
                [yLim,yLim0] = obj.getPixelAxisLimits(obj.Imu{1});
            else
                [yLim,yLim0] = deal([0,255]);
            end            
            
            % creates the plot markers
            obj.hMu = plot(obj.hAx{1},iFrm,obj.Imu{1},'k','linewidth',1);
            obj.hMuL = arrayfun(@(x)...
                    (plot(obj.hAx{1},xLim,x*[1,1],'r--')),yLim0,'un',0);
            obj.hMuM = plot(obj.hAx{1},iFrm,obj.Imu{1},'kx','tag','hMarker');
            
            % sets the axis properties
            yTickStr = arrayfun(@(x)(num2str(roundP(x,0.1))),yLim0,'un',0);
            set(obj.hAx{1},'xlim',xLim,'ylim',yLim,'ytick',yLim0,...
                           'yTickLabel',yTickStr)
                    
            % calculates the global x/y coordinates of the axes
            axPos = get(obj.hAx{1},'Position');
            pPos = getObjGlobalCoord(obj.hAx{1});            
            obj.axPosXF = pPos(1) + [0,axPos(3)];
            obj.axPosYF = pPos(2) + [0,axPos(4)]; 
            
            % sets up the marker line
            obj.hMark = plot(obj.hAx{1},NaN,NaN,'yo','linewidth',2,...
                    'MarkerSize',10);
            
            % sets the text label
            obj.hText = imtext(0,0,{''},'right');
            set(obj.hText,'tag','hText','parent',obj.hAx{1},'visible',...
                    'off','FontSize',obj.fSz,'FontWeight','bold',...
                    'EdgeColor','k','LineWidth',1,'BackgroundColor','y')  
                
            % creates the zoom object
            obj.hZoom = zoom(obj.hAx{1});
            set(obj.hZoom,'Enable','off','Motion','horizontal',...
                          'ActionPostCallback',{@obj.postZoomCallback});
            zoom(obj.hAx{1},'reset')

            % ------------------------------ %
            % --- TRANSLATION AXES SETUP --- %
            % ------------------------------ %      
            
            % memory allocation
            pW = 1.1;
            hPT = zeros(1,2);
            
            % sets up the axis limits based on whether there is translation
            if hasT
                % sets the y-axis limits
                pOfsT = calcImageStackFcn(obj.phInfo.pOfs);
                yLim = [min(-1,min(pOfsT(:))),max(1,max(pOfsT(:)))];
                
                % creates the lines
                xPlt = obj.phInfo.iFrm0;
                hPT(1) = plot(obj.hAx{2},xPlt,pOfsT(:,1),'b','linewidth',2);
                hPT(2) = plot(obj.hAx{2},xPlt,pOfsT(:,2),'r','linewidth',2);                
                
            else
                % case is there is no major translation
                yLim = [-1,1];
                
                % creates the lines
                hPT(1) = plot(obj.hAx{2},xLim,[0,0],'b','linewidth',2);
                hPT(2) = plot(obj.hAx{2},xLim,[0,0],'r','linewidth',2);
            end
            
            % plots the centre marker
            plot(obj.hAx{2},xLim,[0,0],'k');
            arrayfun(@(x)(plot(obj.hAx{2},xLim,x*[1,1],'k--')),yLim);
            
            % sets the tick location/strings
            yTick = [yLim(1),0,yLim(2)];
            yTickStr = arrayfun(@(x)(num2str(roundP(x,0.1))),yTick,'un',0);
            
            % sets the axis properties
            set(obj.hAx{2},'xlim',xLim,'ylim',pW*yLim,'ytick',yTick,...
                           'yTickLabel',yTickStr)
            obj.hLg = legend(hPT,{'X-Movement','Y-Movement'},'Location',...
                            'NorthWest','FontWeight','Bold','FontSize',10);
            
            % -------------------------------------- %
            % --- OTHER PROPERTY INITIALISATIONS --- %
            % -------------------------------------- %
            
            % question strings            
            qStr = {'No','Yes'};           
            
            % sets the translation range strings
            if hasT
                % case is there is major translation
                dxStr = sprintf('%.1f-%.1f',min(pOfsT(:,1)),max(pOfsT(:,1)));
                dyStr = sprintf('%.1f-%.1f',min(pOfsT(:,2)),max(pOfsT(:,2)));
            else
                % case is there is no major translation
                [dxStr,dyStr] = deal('N/A');
            end
           
            % updates the pixel information
            obj.updatePixelInfo(obj.Imu{1})            
            
            % image translation info label setting            
            cT = obj.colStr(1+hasT);
            set(obj.hTxt{2}{1},'String',qStr{1+hasT},'ForegroundColor',cT);
            set(obj.hTxt{2}{2},'String',dxStr,'ForegroundColor',cT);
            set(obj.hTxt{2}{3},'String',dyStr,'ForegroundColor',cT);            
            
        end

        % ----------------------- %
        % --- OTHER FUNCTIONS --- %
        % ----------------------- %
        
        % --- GUI resize callback function
        function resizeGUI(obj, ~, ~)
            
            if obj.isResizing
                % if already resizing, then exit
                return
            else
                % otherwise, reset the flag
                obj.isResizing = true;
            end            
            
            % determines when the figure has finished resizing
            fPos = getFinalResizePos(obj.hFig,obj.widFig,obj.hghtFig);            
            
            % resets the outer panel dimensions
            pPosO = [obj.dX*[1,1],fPos(3:4)-2*obj.dX];
            set(obj.hPanelO,'Position',pPosO);
            
            % calculates the other other object dimensions
            obj.setupObjDimensions();              
            
            % resets the other objects            
            set(obj.hTabGrp,'Position',obj.pTabGrp)
            cellfun(@(x)(resetObjPos(x,'Bottom',obj.pPanelT(2))),obj.hPanelT)
            cellfun(@(x)(set(x,'Position',obj.pPanelAx)),obj.hPanelAx);
            cellfun(@(x)(set(x,'Position',obj.pAx)),obj.hAx)
            
            % calculates the global x/y coordinates of the axes
            axPos = get(obj.hAx{1},'Position');
            pPos = getObjGlobalCoord(obj.hAx{1});            
            obj.axPosXF = pPos(1) + [0,axPos(3)];
            obj.axPosYF = pPos(2) + [0,axPos(4)];
            
            % flag that resizing is finished
            obj.isResizing = false;  
            
        end
        
        % --- deletes the GUI
        function closeGUI(obj, ~, ~)
                       
            % deletes the GUI
            delete(obj.hFig);
            
        end      

        % --- plot marker callback functions
        function zoomToggle(obj, hObject, ~)
           
            switch get(hObject,'State')
                case 'off'
                    zoom(obj.hAx{1},'out')
                    zoom(obj.hAx{1},'off')
                case 'on'
                    zoom(obj.hAx{1},'xon')
            end
            
        end        
        
        % --- trace menu item callback function
        function menuTrace(obj, hMenu, ~, uD)
            
            % toggles the menu item check marks
            hMenuPr = findall(obj.hMenuP,'Checked','on');
            set(hMenuPr,'Checked','off')
            set(hMenu,'Checked','on')
            
            % retrieves the trace data
            if length(uD) == 2
                % case is a sub-region 
                if uD(2) == 0
                    ImuT = obj.Imu{2}{uD(1)};
                else
                    indG = obj.bgObj.iMov.srData.indG{uD(1)}(:,[1,end]);
                    ImuT = obj.Imu{3}{sum(abs(indG - uD),2) == 0};
                end
                
            elseif uD == 0
                % case is the overall average trace
                ImuT = obj.Imu{1};
                
            else
                % case is a region average trace
                ImuT = obj.Imu{2}{uD};
            end
            
            % recalculates the y-axis limits
            [yLim,yLim0] = obj.getPixelAxisLimits(ImuT);
            
            % creates the plot markers
            set(obj.hMu,'yData',ImuT);
            set(obj.hMuM,'yData',ImuT);
            set(obj.hMuL{1},'yData',yLim0(1)*[1,1]);
            set(obj.hMuL{2},'yData',yLim0(2)*[1,1]);
            
            % sets the axis properties
            yTickStr = arrayfun(@(x)(num2str(roundP(x,0.1))),yLim0,'un',0);
            set(obj.hAx{1},'ylim',yLim,'ytick',yLim0,...
                           'yTickLabel',yTickStr)            
            
            % updates the pixel information
            obj.updatePixelInfo(ImuT);
            
        end
        
        % --- callback function for selecting the file type tab
        function tabSelected(obj, hObject, ~)
            
            % updates the selected tab
            obj.iTab = get(hObject,'UserData');

            switch obj.iTab
                case 1
                    % sets the mouse-motion function                     
                    set(obj.hFig,'WindowButtonMotionFcn',obj.wmFunc)
                case 2
                    % removes the mouse-movement function
                    set(obj.hFig,'WindowButtonMotionFcn',[])
            end
            
        end
        
        % --- post zoom callback function
        function postZoomCallback(~,~,event)
            
            xLim = roundP(get(event.Axes,'xlim'));
            xTickStr = arrayfun(@num2str,xLim,'un',0);
            set(event.Axes,'xLim',xLim,'xTick',xLim,'xTickLabel',xTickStr)
            
        end
        
        % ----------------------- %
        % --- OTHER FUNCTIONS --- %
        % ----------------------- %
        
        % --- retrieves the tab group position vector
        function setupObjDimensions(obj)
            
            % initialisations            
            [dtGrp,dnX,nOfs] = deal([5,5,-10,-5],[2.5,1],[4.5,3]);
            pAx0 = obj.dX*nOfs.*[1,1];
            
            % sets up the tab group position vector
            obj.pTabGrp = getTabPosVector(obj.hPanelO,dtGrp);
        
            % sets the inner panel width and axes panel height
            obj.widPanelI = obj.pTabGrp(3)-1.5*obj.dX;
            obj.hghtPanelAx = obj.pTabGrp(4)-(4.5*obj.dX+obj.hghtPanelT);
        
            % sets the axis position vector            
            obj.pPanelAx = [obj.dX/2*[1,1],obj.widPanelI,obj.hghtPanelAx];            
            obj.pAx = [pAx0,obj.pPanelAx(3:4)-(nOfs+dnX)*obj.dX];
        
            % sets the text panel vector
            y0T = sum(obj.pAx([2,4]))+2*obj.dX;
            obj.pPanelT = [obj.dX/2,y0T,obj.widPanelI,obj.hghtPanelT];            
            
        end
            
        % --- plot marker callback functions
        function showPlotMarkerInfo(obj,~,~)
            
            % retrieves the current mouse location
            infoOn = false;
            objType = {'tag','hMarker'};
            mP = get(obj.hFig,'CurrentPoint');
            
            % determines if the mouse if over the plot axes
            if isOverAxes(mP,obj.axPosXF,obj.axPosYF)
                % if so, then determine if the mouse is over any objects
                hHover = findAxesHoverObjects(obj.hFig,objType,obj.hAx{1});
                if ~isempty(hHover)
                    % cursor is inside axes, so turn on marker line
                    [infoOn,mP] = deal(true,get(obj.hAx{1},'CurrentPoint'));
                    
                    % resets the marker object
                    [xD,yD] = deal(get(hHover,'XData'),get(hHover,'YData'));
                    iMn = argMin(pdist2([xD(:),yD(:)],mP(1,1:2)));
                    set(obj.hMark,'xData',xD(iMn),'yData',yD(iMn))

                    % sets the normalised coordinates
                    xL = get(obj.hAx{1},'xlim');
                    yL = get(obj.hAx{1},'ylim');
                    mPN = [(mP(1,1)-xL(1))/diff(xL),...
                           (mP(1,2)-yL(1))/diff(yL)];                    

                    % updates the text-box position
                    ttStr = obj.setDataTipString(hHover,mP);
                    set(obj.hText,'String',ttStr,...
                                  'HorizontalAlignment','center');
                              
                    % updates the text object position
                    [dXT,dYT] = deal(0.02);
                    pExt = get(obj.hText,'Extent');                    
                    [xLT,yLT] = deal(1-pExt(3)-dXT,1-pExt(4)-dYT);
                    xD = (1 - 2*(mPN(1) > xLT))*(dXT + pExt(3)/2);
                    yD = (1 - 2*(mPN(2) > yLT))*(dYT + pExt(4)/2);
                    set(obj.hText,'Position',[mPN(1:2)+[xD,yD],0]);                           
                end
            end
            
            % sets the visibility flag
            setObjVisibility(obj.hMark,infoOn)
            setObjVisibility(obj.hText,infoOn)
            
        end
        
        % --- sets the data tip string
        function ttStr = setDataTipString(obj,hHover,mP)
            
            % determines the point that is currently being hovered over
            [xD,yD] = deal(get(hHover,'xData'),get(hHover,'yData'));
            iMn = argMin(pdist2([xD(:),yD(:)],mP(1,1:2)));
            iPhase = find(xD(iMn)>=obj.bgObj.iMov.iPhase(:,1),1,'last');
            
            % sets the video phase status flag
            vPhase = obj.bgObj.iMov.vPhase(iPhase);
            sStr = {'Low-Var','High-Var','Untrackable','Rejected'};
            
            % sets the string
            ttStr = {sprintf('Phase = %i',iPhase);...
                     sprintf('Frame = %i',xD(iMn));...
                     sprintf('Intensity = %.1f',yD(iMn));...
                     sprintf('Status = %s',sStr{vPhase})};
            
        end        
        
        % --- updates the patch colour 
        function updatePatchColour(obj,iPh)
            
            % video phase
            vPhase = obj.bgObj.iMov.vPhase(iPh);
            pCol = obj.getPatchColour(vPhase);
            
            % updates the patch colours
            cellfun(@(x)(set(x,'FaceColor',pCol)),obj.hP(iPh,:))
            
        end
        
        % --- updates the pixel information fields
        function updatePixelInfo(obj,ImuT)
            
            % initialisations
            qStr = {'No','Yes'};
            hasF = obj.phInfo.hasF;            
            
            % image fluctuation info label setting                        
            cF = obj.colStr(1+hasF);
            IavgMin = sprintf('%.1f',min(ImuT));
            IavgMax = sprintf('%.1f',max(ImuT));
            set(obj.hTxt{1}{1},'String',qStr{1+hasF},'ForegroundColor',cF);
            set(obj.hTxt{1}{2},'String',IavgMin,'ForegroundColor',cF);
            set(obj.hTxt{1}{3},'String',IavgMax,'ForegroundColor',cF);
            
        end     
        
        % --- retrieves the pixel y-axis limits
        function [yLim,yLim0] = getPixelAxisLimits(obj,ImuT)

            yLim0 = [min(ImuT),max(ImuT)];
            yLim = yLim0 + obj.dyLim*diff(yLim0)*[-1,1];                 

        end        
        
    end
    
    methods (Static)
        
        % --- retrieves the patch colour
        function pCol = getPatchColour(vPhase)

            pCol0 = {'g','y','r','k'};
            pCol = pCol0{vPhase};

        end        
        
    end
    
end
