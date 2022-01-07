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
        hPanelO
        hPanelAx
        hPanelT
        hTabGrp
        hTab
        hTxt
        hAx
        
        % info marker related object
        hZoom
        axPosXF
        axPosYF
        wmFunc
        hText
        hMark
        
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
            
            % patch object indices
            yP = 255*[-1,1];
            pInfo = obj.phInfo;
            [ii,jj] = deal([1,1,2,2,1],[1,2,2,1,1]);
            
            % sets the frame index/avg. pixel intensity arrays 
            if hasF
                % case is the video has high fluctuation
                if isempty(pInfo.DimgF)
                    [iFrm,Imu] = deal(pInfo.iFrm0,pInfo.Dimg0);
                else
                    [iFrm,Imu] = deal(pInfo.iFrmF,mean(pInfo.DimgF,2));
                end
                    
                pCol = 0.5*ones(1,3);
            else
                % case is the video has relatively steady intensity
                [iFrm,Imu] = deal(pInfo.iFrmF,mean(pInfo.DimgF,2));
                if nPhase == 1
                    pCol = [0,1,0];
                else
                    pCol = distinguishable_colors(nPhase);
                end
            end                
            
            % sets the x-axis limit
            xLim = iFrm([1,end]);
            xTickStr = arrayfun(@(x)(num2str(x)),xLim,'un',0);
            
            % ------------------------------- %
            % --- INFORMATION TABLE PANEL --- %
            % ------------------------------- %            
            
            % sets the figure position
            fPos = [100,100,obj.widFig,obj.hghtFig];            
            
            % creates the figure object
            cbFcn = {@obj.closeGUI,obj};
            obj.hFig = figure('Position',fPos,'tag','figInitTrackStats',...
                              'MenuBar','None','Toolbar','None',...
                              'Name','Initial Tracking Statistics',...
                              'NumberTitle','off','Visible','off',...
                              'Resize','off','CloseRequestFcn',cbFcn,...
                              'WindowButtonMotionFcn',obj.wmFunc);    
                          
            % creates the toolbar objects
            obj.hTool = uitoolbar(obj.hFig);
            obj.hToolB = uitoolfactory(obj.hTool,'Exploration.ZoomIn');
            set(obj.hToolB,'ClickedCallback',{@obj.zoomToggle})
            
            % creates the table panel
            pPosO = [obj.dX*[1,1],obj.widPanelO ,obj.hghtPanelO];
            obj.hPanelO = uipanel(obj.hFig,'Title','','Units','Pixels',...
                                           'Position',pPosO);                          
                          
            % ----------------------------- %
            % --- TAB GROUP PANEL SETUP --- %
            % ----------------------------- %   
            
            % sets the object positions
            y0Txt = 8;
            tStr = {'Image Intensity','Image Translation'};
            txtStr = {{'Fluctuation Detected: ',...
                       'Max. Intensity: ',...
                       'Min. Intensity: '},...
                      {'Translation Detected: ',...
                       'X-Movement Range: ',...
                       'Y-Movement Range: '}};            
            
            % calculates the other other object dimensions
            tabPos = getTabPosVector(obj.hPanelO,[5,5,-10,-5]);
            obj.widPanelI = tabPos(3)-1.5*obj.dX;
            obj.hghtPanelAx = tabPos(4)-(4.5*obj.dX+obj.hghtPanelT);

            % creates a tab panel group            
            obj.hTabGrp = createTabPanelGroup(obj.hPanelO,1);
            set(obj.hTabGrp,'position',tabPos,'tag','hTabGrp')
                          
            % sets the colour strings   
            A = cell(length(tStr),1);
            [obj.hAx,obj.hTab,obj.hPanelT] = deal(A);
            [obj.hPanelAx,obj.hTxt] = deal(A);
            
            % sets up the tab objects (over all stimuli objects)
            wState = warning('off','all');
            for i = 1:length(tStr)
                % sets up the tabs within the tab group
                obj.hTab{i} = createNewTab(obj.hTabGrp,...
                                    'Title',tStr{i},'UserData',i);
                set(obj.hTab{i},'ButtonDownFcn',{@obj.tabSelected})
                pause(0.1)
                
                % creates the axes panel object
                pPosAx = [obj.dX/2*[1,1],obj.widPanelI,obj.hghtPanelAx];
                obj.hPanelAx{i} = uipanel(obj.hTab{i},'Title','',...
                                    'Units','Pixels','Position',pPosAx);                                                             
                                
                % creates the text information panel object
                y0T = sum(pPosAx([2,4]))+obj.dX/2;
                pPosT = [obj.dX/2,y0T,obj.widPanelI,obj.hghtPanelT];
                obj.hPanelT{i} = uipanel(obj.hTab{i},'Title','',...
                                    'Units','Pixels','Position',pPosT);
                                
                % creates the axes object
                [nOfs,dnX] = deal([4.5,3],[2.5,1]);                
                pPosAx = [obj.dX*nOfs.*[1,1],pPosAx(3:4)-(nOfs+dnX)*obj.dX];
                obj.hAx{i} = axes(obj.hPanelAx{i},'Units','Pixels',...
                                    'Position',pPosAx,'box','on',...
                                    'XTickLabel',[],'YTickLabel',[],...
                                    'FontWeight','bold','xlim',xLim,...
                                    'xtick',xLim,'xticklabel',xTickStr);
                hold(obj.hAx{i},'on')
                grid(obj.hAx{i},'on')   
                
                % creates the phase patch objects                
                for j = 1:nPhase
                    xP = [iPhase(j,1),iPhase(j,2)]+0.5*[-1,1];
                    patch(obj.hAx{i},xP(ii),yP(jj),pCol(j,:),...
                                     'FaceAlpha',0.2,'EdgeColor','None');
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
            warning(wState); 

            % ---------------------------- %
            % --- INTENSITY AXES SETUP --- %
            % ---------------------------- %                                 
            
            % REMOVE ME LATER
            dyLim = 0.05;            
            yLim0 = [min(Imu),max(Imu)];
            yLim = max(0,min(255,yLim0 + dyLim*diff(yLim0)*[-1,1]));            
            
            % creates the plot markers
            plot(obj.hAx{1},iFrm,Imu,'k','linewidth',1)
            plot(obj.hAx{1},xLim,yLim0(1)*[1,1],'r--')
            plot(obj.hAx{1},xLim,yLim0(2)*[1,1],'r--')
            
            % plots the markers
            plot(obj.hAx{1},iFrm,Imu,'kx','tag','hMarker');
            
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
            set(obj.hZoom,'Enable','off','Motion','horizontal');
            zoom(obj.hAx{1},'reset')

            % ------------------------------ %
            % --- TRANSLATION AXES SETUP --- %
            % ------------------------------ %      
            
            % memory allocation
            pW = 1.1;
            hP = zeros(1,2);
            
            % sets up the axis limits based on whether there is translation
            if hasT
                % sets the y-axis limits
                pOfsT = calcImageStackFcn(obj.phInfo.pOfs);
                yLim = [min(-1,min(pOfsT(:))),max(1,max(pOfsT(:)))];
                
                % creates the lines
                xPlt = obj.phInfo.iFrm0;
                hP(1) = plot(obj.hAx{2},xPlt,pOfsT(:,1),'b','linewidth',2);
                hP(2) = plot(obj.hAx{2},xPlt,pOfsT(:,2),'r','linewidth',2);                
                
            else
                % case is there is no major translation
                yLim = [-1,1];
                
                % creates the lines
                hP(1) = plot(obj.hAx{2},xLim,[0,0],'b','linewidth',2);
                hP(2) = plot(obj.hAx{2},xLim,[0,0],'r','linewidth',2);
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
            legend(hP,{'X-Movement','Y-Movement'},'Location','Best',...
                      'FontWeight','Bold','FontSize',10);
            
            % -------------------------------------- %
            % --- OTHER PROPERTY INITIALISATIONS --- %
            % -------------------------------------- %
            
            % question strings
            colStr = 'kr';
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
           
            % image fluctuation info label setting                        
            cF = colStr(1+hasF);
            IavgMin = sprintf('%.1f',min(Imu));
            IavgMax = sprintf('%.1f',max(Imu));
            set(obj.hTxt{1}{1},'String',qStr{1+hasF},'ForegroundColor',cF);
            set(obj.hTxt{1}{2},'String',IavgMin,'ForegroundColor',cF);
            set(obj.hTxt{1}{3},'String',IavgMax,'ForegroundColor',cF);
            
            % image translation info label setting            
            cT = colStr(1+hasT);
            set(obj.hTxt{2}{1},'String',qStr{1+hasT},'ForegroundColor',cT);
            set(obj.hTxt{2}{2},'String',dxStr,'ForegroundColor',cT);
            set(obj.hTxt{2}{3},'String',dyStr,'ForegroundColor',cT);            
            
        end
        
        % --- deletes the GUI
        function closeGUI(~,~,obj)
                       
            % deletes the GUI
            delete(obj.hFig);
            
        end      

        % --- plot marker callback functions
        function zoomToggle(obj,hObject,~)
           
            switch get(hObject,'State')
                case 'off'
                    zoom(obj.hAx{1},'out')
                    zoom(obj.hAx{1},'off')
                case 'on'
                    zoom(obj.hAx{1},'xon')
            end
            
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
                    set(obj.hMark,'xData',mP(1,1),'yData',mP(2,1))

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
            
            % sets the string
            ttStr = {sprintf('Phase = %i',iPhase);...
                     sprintf('Frame = %i',xD(iMn));...
                     sprintf('Intensity = %.1f',yD(iMn))};
            
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
        
    end
    
end
