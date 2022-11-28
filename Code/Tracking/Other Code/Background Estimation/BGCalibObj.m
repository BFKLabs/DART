classdef BGCalibObj < handle
    
    % class properties
    properties
    
        % input arguments
        hFigM
        iMov
        prObj
        
        % main GUI object handles
        hAxM
        hPanelM
        
        % dialog object handles
        hPanelO
        hPanel
        hAx        
        
        % parameter panel objects
        hPanelP
        hEditT
        
        % title header objects
        hTxtH
        hButH
        hChkH
        
        % range plot axes fields
        yScl
        hFillR                
        
        % video feed parameters
        iStp
        nStp
        T0
        T0S
        Tt
        yOfs
        
        % initial detection tracking fields
        Imu
        Imax
        Imin
        YRng
        dYRng
        fPos
        xLim
        yLim
        isMove
        pTol
        indR
        nOpen
        fStatus        
        rTol = 3.5;
        dTol = 3;
        DTol = 5;
        Tinit = 5;
        tStatus = 0;
        hasData = false;
        forceUpdate = false;
        hS = fspecial('disk',2);        
                
        % trace plot objects
        hMu
        hRng
        
        % main object dimensions        
        widPanelO = 515;
        widPanel
        widChk = 150;
        widAx   
        hghtPanelO
        hghtPanel        
        hghtPanelC = 65;
        hghtAx
        hghtAxRow = 50;
        hghtTxt = 16;
        hghtEdit = 21;
        hghtBut = 25;
        hghtChk = 22;
        axX0 = 50;
        fAlpha = 0.15;
        
        % title header object dimensions
        widTxtL = [90,115,45];
        widTxtH = [70,50,100];
        widButH = 180;
        
        % parameter object dimensions
        hghtPanelP = 40;
        widTxtP = 120;
        widEditP = 38;
        
        % other class array fields
        tStrH0
        toggleStr   
        frmPara
        
        % other class scalar fields        
        nApp
        iPara
        dX = 10;
        dXH = 5;        
        nFrm0 = 1;
        Tmin = 10;  
        Tmax = 300;
        lWid = 2;
        yGap = 0.1;
        nTX = 6;
        nTY = 6;   
        axSz = 11;
        lblSz = 15;
        txtSz = 12;
        nPosPr = 50;
        nAvgChk = 100;
        dAvgTol = 3;        
        
        % plot object colours
        fCol         
        sCol = 0.1*[1,1,1];        
        fCol0 = 0.5*[1,0,1];        
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = BGCalibObj(hFigM)
            
            % sets the input arguments
            obj.hFigM = hFigM;
            obj.iMov = hFigM.iMov;
            obj.prObj = hFigM.prObj;

            % makes the GUI visible again
            h = ProgressLoadbar('Initialising Calibration View...');
            
            % initialises the class fields and objects
            obj.initClassFields();
            obj.initObjProps();
            
            % resets the figure position
            centreFigPosition(obj.hFigM)
            
            % makes the GUI visible again
            delete(h)
            
        end
        
        % --------------------------------------- %
        % --- OBJECT INITIALISATION FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % field initialisations
            nPanel = 3;
            obj.iStp = 0;
            obj.nStp = 50*obj.Tmax;            
            obj.nApp = length(obj.iMov.iR);      
            obj.fCol = {[0,0,0],[1,0,0],[1,0.65,0],[0,1,0]};
            obj.hFillR = cell(size(obj.iMov.flyok));              
            
            % retrieves the main object handles
            obj.hAxM = findall(obj.hFigM,'type','axes');             
            obj.hPanelM = findall(obj.hFigM,'tag','panelImg');
            
            % sets the figure height
            fPosM = get(obj.hFigM,'Position');
            obj.hghtPanelO = fPosM(4) - 2*obj.dX;                      
            
            % sets the object widths            
            obj.widPanel = obj.widPanelO - 2*obj.dX; 
            obj.widAx = obj.widPanel - (obj.dX + obj.axX0);            
            
            % calculates the 
            hghtAx0 = [obj.nApp*obj.hghtAxRow,150];
            dHght = (nPanel+5)*obj.dX + obj.dXH + ...
                    (obj.hghtPanelC + obj.hghtPanelP);            
            H0 = (obj.hghtPanelO - dHght);
            obj.hghtAx = roundP(H0*hghtAx0/sum(hghtAx0));
            
            % calculates the object heights
            dhOfs = [0,obj.hghtPanelP+obj.dXH,0];
            obj.hghtPanel = [obj.hghtAx+2*obj.dX,obj.hghtPanelC] + dhOfs;
            
            % sets up the parameter struct
            obj.iPara = struct('xL',60,'yLo',0,'yHi',255);
            obj.frmPara = struct('Nframe',5,'wP',0.2);
            
            % sets the toggle string
            obj.tStrH0 = {'00:00:00';'N/A';'Stopped'};
            obj.toggleStr = {'Start Real-Time Detection',...
                             'Stop Real-Time Detection'}; 
                         
            % sets the calibration object field for the preview object
            obj.prObj.vcObj = obj;
            
            % calculates the vertical offset
            obj.yOfs = cellfun(@(x)(cellfun...
                            (@(y)(y(1)-1),x)),obj.iMov.iRT,'un',0);            
            obj.nOpen = cellfun(@(x)(roundP(2*median(cellfun...
                            (@length,x),'omitnan'))),obj.iMov.iRT);
                        
            % sets up the range values/index arrays
            [obj.indR,obj.YRng,obj.dYRng] = deal(cell(1,obj.nApp));
            for i = 1:obj.nApp
                % retrieves the row/column indices                                
                nCol = length(obj.iMov.iC{i});
                nRow = cellfun('length',obj.iMov.iRT{i}(:));
                nRowT = nCol*length(nRow);
                
                % calculates the range signal row indices
                [xiC,xiR] = deal(1:nCol,1:length(nRow));
                obj.indR{i} = arrayfun(@(x)((x-1)*nCol+xiC),xiR,'un',0);
                [obj.YRng{i},obj.dYRng{i}] = deal(NaN(nRowT,1));
            end                        
            
        end
        
        % --- initialises the class objects
        function initObjProps(obj)
            
            % memory allocation            
            nPanel = length(obj.hghtPanel);
            [obj.hAx,axPos] = deal(cell(nPanel,1),cell(nPanel-1,1));            
            
            % --------------------------- %
            % --- MAIN FIGURE OBJECTS --- %
            % --------------------------- %                                    

            % creates the outer panel objects
            pPosO = [obj.dX*[1,1],obj.widPanelO,obj.hghtPanelO];
            obj.hPanelO = uipanel(obj.hFigM,'Title','','Units',...
                                            'Pixels','Position',pPosO);                                                    
                          
            % resets the GUI dimensions
            obj.resetGUIDimensions();
                                  
            % ----------------------------- %
            % --- PLOT AXES PANEL SETUP --- %
            % ----------------------------- %            
            
            % creates the axes panel objects
            for i = 1:nPanel
                % creates vertical offset of the panel
                y0 = i*obj.dX + sum(obj.hghtPanel(1:i-1));
                
                % creates the panel object
                pPos = [obj.dX,y0,obj.widPanel,obj.hghtPanel(i)];
                obj.hPanel{i} = uipanel(obj.hPanelO,'Title','','Units',...
                                            'Pixels','Position',pPos);
                                             
                % creates the axes object
                if i < nPanel
                    % sets the vertical offset
                    switch i
                        case 1
                            y0ax = obj.dX;
                        case 2
                            y0ax = (obj.dX + obj.dXH) + obj.hghtPanelP;
                    end
                    
                    % creates the axis object
                    axPos{i} = [obj.axX0,y0ax,obj.widAx,obj.hghtAx(i)];                
                    obj.hAx{i} = axes('parent',obj.hPanel{i},...
                        'units','pixels','position',axPos{i},'box','on',...
                        'xticklabel',[],'xtick',[],'yticklabel',[],...
                        'ytick',[],'fontunits','Pixels','FontWeight','Bold',...
                        'FontSize',obj.axSz,'TickLength',[0,0]);
                    hold(obj.hAx{i},'on')
                end
            end

            % -------------------------------- %
            % --- TITLE HEADER PANEL SETUP --- %
            % -------------------------------- % 
            
            % initialisations
            x0 = obj.dXH;
            bFcnH = @obj.toggleDetect;             
            chkStr = {'Show Region Markers','Show Fly Markers'};
            cFcnH = {@obj.showRegion,@obj.showMarker};            
            tStrL = {'Elapsed Time: ','Avg. Pixel Intensity: ','Status: '};
                        
            % creates the object handles
            obj.hTxtH = cell(length(tStrL),1);
            for i = 1:length(obj.hTxtH)
                % creates the label string
                tPosL = [x0,obj.dX+1,obj.widTxtL(i),obj.hghtTxt];
                uicontrol(obj.hPanel{3},'Style','Text','Position',tPosL,...
                        'FontUnits','Pixels','FontWeight','Bold',...
                        'FontSize',obj.txtSz,'String',tStrL{i},...
                        'HorizontalAlignment','right');  
                    
                % creates the label object
                x0T = sum(tPosL([1,3]));
                tPos = [x0T,obj.dX+1,obj.widTxtH(i),obj.hghtTxt];
                obj.hTxtH{i} = uicontrol(obj.hPanel{3},'Style','Text',...
                        'Position',tPos,'FontUnits','Pixels',...
                        'FontWeight','Bold','FontSize',obj.txtSz,...
                        'String',obj.tStrH0{i},'HorizontalAlignment',...
                        'center','BackgroundColor',0.81*[1,1,1]); 
                    
                % increments the offset
                x0 = sum(tPos([1,3])) + obj.dXH;
            end
            
            % creates the reset button
            y0B = (obj.dX+obj.hghtBut) - 2;
            bPos = [obj.dX,y0B,obj.widButH,obj.hghtBut];
            obj.hButH = uicontrol(obj.hPanel{3},'Style','ToggleButton',...
                        'Position',bPos,'Callback',bFcnH,'FontUnits',...
                        'Pixels','FontSize',12,'FontWeight','Bold',...
                        'String',obj.toggleStr{1});                    
                    
            % creates the checkbox objects
            x0C = sum(bPos([1,3])) + obj.dX; 
            obj.hChkH = cell(length(chkStr),1);
            for i = 1:length(chkStr)
                % creates the checkbox object
                cPos = [x0C,y0B+1,obj.widChk,obj.hghtChk];
                obj.hChkH{i} = uicontrol(obj.hPanel{3},'Style','Checkbox',...
                        'Position',cPos,'Callback',cFcnH{i},'FontUnits',...
                        'Pixels','FontSize',12,'FontWeight','Bold',...
                        'String',chkStr{i});                        
                
                % increments the left position location
                x0C = sum(cPos([1,3])) + obj.dXH;
            end
            
            % disables the fly marker checkbox
            setObjEnable(obj.hChkH{2},0)
            obj.hFigM.mkObj.hChkBGM = obj.hChkH{2};
            
            % ----------------------------- %
            % --- PARAMETER PANEL SETUP --- %
            % ----------------------------- %   
            
            % initialisations
            x0 = 0;
            pStr = {'yHi','yLo','xL'};
            tStr = {'Trace Upper Limit: ',...
                    'Trace Lower Limit: ',...
                    'Trace Duration (s): '};
            eFcnC = @obj.editTracePara;            
            
            % creates the panel object
            pPos = [obj.dXH*[1,1],obj.widPanel-obj.dX,obj.hghtPanelP];
            obj.hPanelP = uipanel(obj.hPanel{2},'Title','','Units',...
                                                'Pixels','Position',pPos);            

            % creates the trace parameter editbox            
            obj.hEditT = cell(length(tStr),1);
            for i = 1:length(tStr)
                % sets the position offset
                tPos = [x0,obj.dX+2,obj.widTxtP,obj.hghtTxt];
                uicontrol(obj.hPanelP,'Style','Text','Position',tPos,...
                        'FontUnits','Pixels','FontWeight','Bold',...
                        'FontSize',obj.txtSz,'String',tStr{i},...
                        'HorizontalAlignment','right');  
                    
                % creates the editbox
                pVal = num2str(getStructField(obj.iPara,pStr{i}));
                lPosE = sum(tPos([1,3]));
                ePos = [lPosE,obj.dX,obj.widEditP,obj.hghtEdit];
                obj.hEditT{i} = uicontrol(obj.hPanelP,'Style','Edit',...
                        'Position',ePos,'Callback',eFcnC,'String',...
                        pVal,'UserData',pStr{i}); 
                    
                % increments the left offset
                x0 = sum(ePos([1,3]));
            end
                                            
            % ----------------------------- %
            % --- RANGE PLOT AXES SETUP --- %
            % ----------------------------- %    
                                    
            % memory allocation             
            [ix,iy] = deal([1,1,2,2,1],[1,2,2,1,1]);                        
            [obj.hRng,obj.yScl] = deal(cell(obj.nApp,1));

            % initialisations
            if obj.iMov.is2D
                yLbl = 'Column Index';
            else
                yLbl = 'Group Index';
            end
            
            % calculates the x-axis marker            
            nRow = cellfun('length',obj.iMov.iR);
            nRowMx = max(nRow);
            xLimAx = [1,nRowMx]+0.5*[-1,1];
            yLimAx = [0,obj.nApp-obj.yGap];
            
            % calculates the region y-scale range
            xiN = (obj.nApp:-1:1)';
            obj.yScl = arrayfun(@(x)((x-1)+[0,(1-obj.yGap)]),xiN,'un',0);            
            
            % creates the axes objects for each region
            for i = 1:obj.nApp
                % calculates the y-offset scale
                obj.hRng{i} = plot(obj.hAx{1},NaN,NaN,'b');
                
                % plots the region vertical markers
                [fok,yF] = deal(obj.iMov.flyok(:,i),obj.yScl{i});                
                xOfs = [0;cellfun(@(x)(x(end)),obj.iMov.iRT{i})];
                for j = 1:length(xOfs)-1
                    % set the region fill marker properties
                    xF = xOfs(j+(0:1));
                    if fok(j)
                        fColR = obj.fCol0;
                    else
                        fColR = obj.fCol{1};
                    end
                    
                    % creates the region fill marker object
                    obj.hFillR{j,i} = fill(obj.hAx{1},xF(ix),yF(iy),...
                            fColR,'FaceAlpha',obj.fAlpha,...
                            'EdgeColor','None');
                    
                    % creates the region end markers
                    plot(obj.hAx{1},xOfs(j+1)*[1,1],obj.yScl{i},'r:')
                end                
                
                % creates the separator fill objects
                if i > 1
                    % creates the fill object
                    yLF = obj.yScl{i}(2) + [0,obj.yGap];
                    fill(obj.hAx{1},xLimAx(ix),yLF(iy),obj.sCol,...
                                           'EdgeColor','none');
                    
                    % plots the black outlines
                    for j = 1:2
                        plot(obj.hAx{1},xLimAx,yLF(j)*[1,1],'r');
                    end
                end
                
                % creates the end fill objects
                if nRow(i) < nRowMx     
                    % creates the fill object
                    xLF = [xOfs(end),nRowMx];
                    yLF = obj.yScl{i};
                    fill(obj.hAx{1},xLF(ix),yLF(iy),obj.sCol,...
                                            'EdgeColor','none');
                    
                    % creates the final region vertical marker
                    plot(obj.hAx{1},xOfs(end)*[1,1],obj.yScl{i},'r:')
                end
            end    
            
            % sets the y-axis tick marks/labels
            yTick = flip(cellfun(@mean,obj.yScl));
            yTickLbl = flip(arrayfun(@num2str,(1:obj.nApp),'un',0));
            
            % sets the other axis properties            
            set(obj.hAx{1},'xlim',xLimAx,'ylim',yLimAx,'yTick',yTick,...
                           'yTickLabel',yTickLbl)      
            ylabel(obj.hAx{1},yLbl,'FontUnits','Pixels','FontWeight',...
                                   'Bold','FontSize',obj.lblSz);
            
            % -------------------------------- %
            % --- AVG INTENSITY AXES SETUP --- %
            % -------------------------------- %   
            
            % initialisations
            yLbl = 'Pixel Intensity';
            
            % sets the y-axis tick marks/labels
            yTick = [obj.iPara.yLo,obj.iPara.yHi]';
            yTickLbl = arrayfun(@num2str,yTick,'un',0);            
            
            % creates the trace marker object
            obj.hMu = plot(obj.hAx{2},NaN,NaN,'b');
            set(obj.hAx{2},'yTick',yTick,'yTickLabel',yTickLbl);
            ylabel(obj.hAx{2},yLbl,'FontUnits','Pixels','FontWeight',...
                                   'Bold','FontSize',obj.lblSz);                               
            grid(obj.hAx{2},'on')
            
            % resets the calibration axes limits    
            obj.resetAvgImgAxesLimits()                
            
        end  
        
        % --- region display checkbox callback function
        function showRegion(obj,hObject,~)
            
            % retrieves the tube show check callback function
            cFunc = get(obj.hFigM,'checkShowTube_Callback');

            % updates the tubes visibility
            hGUI = guidata(obj.hFigM);
            cFunc(hGUI.checkShowTube,num2str(get(hObject,'value')),hGUI)
            pause(0.01);
            
        end
        
        % --- marker display checkbox callback function
        function showMarker(obj,hObject,~)
                        
%             obj.hFigM.mkObj.checkShowMark();
            
%             % retrieves the fly marker object handles
%             isOK = get(hObject,'value');
%             fok = obj.iMov.flyok;
%             
%             % sets the marker visibility for all apparatus
%             for i = 1:length(obj.hMark)
%                 indFly = 1:getSRCount(obj.iMov,i);
%                 cellfun(@(x,isOn)(setObjVisibility(x,isOn)),...
%                         obj.hMark{i},num2cell(isOK & fok(indFly,i)))
%             end       
            
        end        
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %
        
        % --- trace parameter edit callback function
        function editTracePara(obj,hObj,~)
            
            % retrieves the new value
            pStr = get(hObj,'UserData');
            nwVal = str2double(get(hObj,'string'));

            % sets the parameter limits
            switch pStr
                case 'xL'
                    % case is the trace duration
                    nwLim = [obj.Tmin,obj.Tmax];

                case 'yLo'
                    % case is the trace lower limit
                    nwLim = [0,min(ceil(obj.Imu))];

                case 'yHi'
                    % case is the trace upper limit
                    nwLim = [max(ceil(obj.Imu)),255];
            end

            % determines if the new value is valid
            if chkEditValue(nwVal,nwLim,false)
                % if so, then update the 
                obj.iPara = setStructField(obj.iPara,pStr,nwVal);

                % resets the calibration axes limits    
                obj.resetAvgImgAxesLimits()
                
            else
                % otherwise, reset back to the previous valid value
                pVal = getStructField(obj.iPara,pStr);
                set(hObj,'String',num2str(pVal))
            end            
            
        end
        
        % --- detection toggle button callback function
        function toggleDetect(obj,hObj,~)
            
            % starts/stops the calibration based on the button value
            isOn = get(hObj,'Value');
            set(hObj,'String',obj.toggleStr{1+isOn});
            
            if isOn
                % case is starting the calibration
                obj.startFullCalibration();
            
            else
                % case is stopping the calibration
                obj.prObj.stopTrackPreview();  
                set(obj.hChkH{2},'Value',0,'Enable','off');
                set(obj.hTxtH{3},'String','Stopped');                
                
                % resets the tracking status flag
                obj.clearPlotAxes();
                obj.tStatus = 0;
            end
            
        end
        
        % --------------------------------------- %
        % --- DETECTION CALIBRATION FUNCTIONS --- %
        % --------------------------------------- %                
        
        % --- wrapper function for starting the full calibration
        function startFullCalibration(obj)
        
            % determines if there is previously calculated data
            if obj.hasData
                % if so, then prompt the user if they want to clear it
                tStr = 'Reset Tracking Info?';
                qStr = 'Do you want to reset the tracking information?';
                uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
                
                % resets the data flag
                obj.hasData = strcmp(uChoice,'No');
            end
            
            % updates the tracking string
            tStr0 = {'Initialising...','Tracking'};
            set(obj.hTxtH{3},'String',tStr0{1+obj.hasData});            
            
            % -------------------------------------- %
            % --- PRE-CALIBRATION INITIALIATIONS --- %
            % -------------------------------------- %
            
            % sets the initial time stamp
            obj.tStatus = 1 + obj.hasData;
            obj.iStp = obj.nFrm0;
            [obj.Tt,obj.Imu] = deal(NaN(obj.nStp,1));             
            
            % clears all plot axes
            obj.clearPlotAxes();  
            setObjEnable(obj.hChkH{2},obj.hasData)
            
            % resets the tracking fields
            if obj.hasData
                obj.forceUpdate = true;
                obj.isMove = obj.fStatus == 4;
            else
                obj.resetTrackingFields(1);
            end
                    
            % video object specific initialisations
            if obj.prObj.isTest
                % case is using a test video object

                % resets the dummy video object
                obj.prObj.objIMAQ.iFrmT = 1;
                obj.prObj.objIMAQ.previewUpdateFcn = @obj.newCalibFrame;                
                
                % sets the initial time
                [obj.T0,obj.T0S] = deal(obj.getStartTime());                                
                obj.prObj.objIMAQ.T0 = datenum(obj.T0);
                
            else
                % case is using the full camera object
    
                % sets the initial time
                [obj.T0,obj.T0S] = deal(obj.getStartTime());
            end              
            
            % -------------------------------------- %
            % --- PRE-CALIBRATION INITIALIATIONS --- %
            % -------------------------------------- %                                    
            
            % starts the video tracking preview object
            obj.prObj.initMarkers = true;
            obj.prObj.startTrackPreview();
                
%             % initialises the tracking markers
%             obj.hFigM.mkObj.initTrackMarkers(0);            
            
        end                                          
        
        % --- appends new trace data to the list
        function newCalibFrame(obj,eData)
            
            % updates the frame metric fields 
            obj.setNewFrameData(eData);
            obj.updateFieldInfo();            
            
            % updates the plot axes
            obj.updateAvgIntensityPlot();
            obj.updateRegionRangePlot();

            % analyses the region signals
            if obj.tStatus == 2                                
                % analyses the region signals and updates the markers
                obj.analyseRegionSignals()
                obj.updatePlotMarkers();
            end
            
        end
        
        % --- updates the main figure plot markers
        function updatePlotMarkers(obj)
            
            % updates the plot markers
            for i = 1:obj.nApp
                % retrieves the markers for the current region
                hMark = obj.hFigM.mkObj.hMark{i};
                if (i == 1) && ~isvalid(hMark{1})
                    % if they are invalid, then re-initialise them                    
                    hMark = obj.hFigM.mkObj.hMark{i};
                    pause(0.01);
                end                
                
                % updates the marker colours
                cellfun(@(x,f)(set(x,'Color',obj.fCol{f})),...
                                hMark,num2cell(obj.fStatus(:,i)))
            end
        
            % updates the plot fields
            obj.hFigM.fPosNew = cellfun(@(y)(cell2mat...
                        (cellfun(@(x)(x(1,:)),y,'un',0))),obj.fPos,'un',0);
            
            % updates the plot markers
            obj.hFigM.mkObj.updateTrackMarkers(1)        
        
        end
            
        % --- updates the metric fields with the incoming frame
        function setNewFrameData(obj,eData)

            % ----------------------------------------- %
            % --- AVG. IMAGE INTENSITY CALCULATIONS --- %
            % ----------------------------------------- %            
            
            % determines if the max time step has been reached
            if obj.iStp == obj.nStp
                % shifts the values to account for the new values
                obj.Tt(1:end-1) = obj.Tt(2:end);
                obj.Imu(1:end-1) = obj.Imu(2:end);
            
            else                
                % increment the step counter
                obj.iStp = obj.iStp + 1;
            end                     
            
            % calculates the new time/frame value
            Tnw = datevec(eData.Timestamp);
            ImgNw = double(eData.Data);
            obj.Tt(obj.iStp) = etime(Tnw,obj.T0);
            obj.Imu(obj.iStp) = mean(ImgNw(:),'omitnan');
            
            % determines if there has been a significant shift in the
            % average pixel intensity, then reset the fields
            if (obj.tStatus == 1) && (obj.iStp > 1)
                % sets the indices of the time 
                xiT = max(1,obj.iStp-obj.nAvgChk):obj.iStp;
                if range(obj.Imu(xiT)) > obj.dTol
                    % resets the tracking fields
                    obj.resetTrackingFields(0); 
                    obj.clearPlotAxes(2);
                    
                    % resets the check flag and exits the function
                    obj.T0S = obj.getStartTime();
                    setObjEnable(obj.hChkH{2},0);
                    set(obj.hTxtH{3},'String','Initialising...');
                    return
                end
            end           
            
            % determines if the initialisation phase has completed
            if obj.tStatus < 2
                if etime(Tnw,obj.T0S) >= obj.Tinit
                    % if so, the update the 
                    obj.tStatus = 2;
                    obj.hasData = true;
                    obj.forceUpdate = true;
                    set(obj.hTxtH{3},'String','Tracking');  

                    % enables the check marker (if there are valid tolerances)
                    setObjEnable(obj.hChkH{2},1);
                end
            end
                
            % ----------------------------------------- %
            % --- BACKGROUND DETECTION CALCULATIONS --- %
            % ----------------------------------------- %
            
            % calculates the min/max values from the new frame
            IL = cellfun(@(ir,ic)(ImgNw(ir,ic)),...
                                    obj.iMov.iR,obj.iMov.iC,'un',0);                                
                                
            % depending on whether the blob object has moved, either
            % calculate the new blob location, or update the other tracking
            % metrics (like the min/max image masks)
            for i = 1:obj.nApp                                                
                for j = find(obj.iMov.flyok(:,i)')
                    % retrieves the local row indices and image/max mask
                    iRT = obj.iMov.iRT{i}{j};
                    fStatus0 = obj.fStatus(j,i);
                    [ILT,ImaxL] = deal(IL{i}(iRT,:),obj.Imax{i}(iRT,:));
                    
                    % if not, then update the min/max values
                    nFlag = 'omitnan';
                    obj.Imin{i}(iRT,:) = min(ILT,obj.Imin{i}(iRT,:),nFlag);
                    obj.Imax{i}(iRT,:) = max(ILT,ImaxL,nFlag);

                    % updates the range values for the sub-region
                    obj.updateRangeValues(iRT,i,j);                        
                    
                    % determines if the blob has moved (and the initial
                    % detection has completed)
                    if ~isnan(obj.pTol(i)) && (obj.tStatus == 2)
                        % resets the previous location position array
                        xiL = 1:(obj.nPosPr-1);
                        obj.fPos{i}{j}(xiL+1,:) = obj.fPos{i}{j}(xiL,:);

                        % if so, the calculate the blob position
                        IRT = ImaxL - ILT;    
                        fP = getMaxCoord(imfiltersym(IRT,obj.hS));
                        if (obj.fStatus(j,i) > 2) || ...
                                        (IRT(fP(2),fP(1)) > obj.pTol(i))
                            % sets the coordinates wrt the region frame
                            pOfs = [obj.iMov.iC{i}(1)-1,0];
                            obj.fPos{i}{j}(1,:) = fP + ...
                                            [0,obj.yOfs{i}(j)] + pOfs;
                        
                            % resets the x/y movement limits
                            obj.xLim{i}(j,:) = ...
                                    [min(obj.xLim{i}(j,1),fP(1)),...
                                     max(obj.xLim{i}(j,2),fP(1))];
                            obj.yLim{i}(j,:) = ...
                                    [min(obj.yLim{i}(j,1),fP(2)),...
                                     max(obj.yLim{i}(j,2),fP(2))];
                                 
                            % updates the range flag
                            if ~obj.isMove(j,i)
                                if (range(obj.xLim{i}(j,:)) > obj.DTol) || ...
                                   (range(obj.yLim{i}(j,:)) > obj.DTol)
                                    obj.isMove(j,i) = true;                                                                    
                                end
                            end
                            
                            % updates the fill colour
                            iCol = 3 + obj.isMove(j,i);
                            obj.fStatus(j,i) = max(iCol,obj.fStatus(j,i));                            
                        end
                    else
                        % resets the fill colour
                        obj.fStatus(j,i) = 2;
                    end
                    
                    % updates the fill colour (if there is a change)
                    if obj.forceUpdate || (fStatus0 ~= obj.fStatus(j,i))
                        fColT = obj.fCol{obj.fStatus(j,i)};
                        obj.updateFillColour(fColT,i,j);
                    end                    
                end
            end
            
            % resets the force update flag
            if obj.forceUpdate
                obj.forceUpdate = false;
            end
            
        end       
        
        % --- updates the range values for the given sub-region
        function updateRangeValues(obj,iRT,iApp,iTube)
            
            % calculates and updates the range values for the sub-region
            IRng = obj.Imax{iApp}(iRT,:) - obj.Imin{iApp}(iRT,:);            
            obj.YRng{iApp}(obj.indR{iApp}{iTube}) = max(IRng,[],1);
            
        end
        
        % --- updates the information fields
        function updateFieldInfo(obj)
            
            % updates the fields
            tVec = [0,0,sec2vec(obj.Tt(obj.iStp))];
            set(obj.hTxtH{1},'String',datestr(datenum(tVec),'MM:SS:FFF'))
            set(obj.hTxtH{2},'String',sprintf('%.2f',obj.Imu(obj.iStp)))
                                
        end        
        
        % --- analyses the region signals
        function analyseRegionSignals(obj)
            
            % recalculates the residual tolerances
            for i = 1:obj.nApp
                % only recalculate the residual tolerance if A) the
                % residual tolerance is non-NaN and B) 
                if ~(any(obj.isMove(:,i)) || ~isnan(obj.pTol(i)))
                    obj.pTol(i) = obj.calcResidualTol(i);
                end
            end                                     
            
        end
        
        % --- calculates the residual tolerance from the range signal
        function pTol = calcResidualTol(obj,iApp)

            % parameters and other initialisations
            pW = 1.5;
            dTolCl = 0.075;            
            YRng0 = obj.YRng{iApp};
            
            % calculates the relative range signal
            obj.dYRng{iApp} = obj.calcRelRangeSignal(iApp); 
            if max(obj.dYRng{iApp}) < obj.rTol
                % if the relative range signal is too low in magnitude,
                % then probably all blobs haven't moved
                pTol = NaN;
                return
            end
            
            % calculates the normalised signals
            RngN = YRng0/max(YRng0);
            dRngN = obj.dYRng{iApp}/max(obj.dYRng{iApp},[],'omitnan');
            
            % determines the peaks from the signal
            [yP,tP,~,pP] = findpeaks(dRngN);

            % clusters these groups using the DBSCAN clustering algorithm
            QP = max(0,[yP,pP,RngN(tP)]);
            jdx = DBSCAN(QP,dTolCl,1);

            % determines the cluster most like to represent baseline peaks
            iGrp = arrayfun(@(x)(find(jdx==x)),(1:max(jdx))','un',0);
            RGrp = cellfun(@(x)(sum(mean(QP(x,:),1,'omitnan').^2)),iGrp);
            iMin = argMin(RGrp);

            % sets the indices of the peaks that are significant. from 
            % these peaks determines the threshold level
            iSig = sort(cell2mat(iGrp(~setGroup(iMin,size(iGrp)))));
            pTol0 = [max(YRng0(tP(iGrp{iMin}))),min(YRng0(tP(iSig)))];
            pTol = pW*mean(pTol0);
            
        end        
        
        % --- sets up the range signal
        function dYRng = calcRelRangeSignal(obj,iApp)
            
            % sets up the range mask
            iRT = obj.iMov.iRT{iApp};
            IRng = obj.Imax{iApp} - obj.Imin{iApp};            
            szOpen = ones(obj.nOpen(iApp),1);            
            
            % removes the baseline image from the image
            IRngMx = max(IRng,[],2);            
            IRngMx(isnan(IRngMx)) = median(IRngMx,'omitnan');
            IRngBL = repmat(imopen(IRngMx,szOpen),1,size(IRng,2));            
            dIRng = max(0,IRng - IRngBL)./max(1,IRngBL);
            
            % splits up the signal into sub-region components and
            % concatenates the row max signals into a single vector
            dYRng0 = cellfun(@(x)(max(dIRng(x,:),[],1)),iRT,'un',0);
            dYRng = arr2vec(cell2cell(dYRng0,0));
            
        end        
        
        % -------------------------------- %
        % --- SUBPLOT UPDATE FUNCTIONS --- %
        % -------------------------------- %
        
        % --- updates the average intensity plot axes
        function updateAvgIntensityPlot(obj)
            
            % determines the feasible plot values
            Tf = obj.Tt(obj.iStp);
            tLim = (Tf - obj.iPara.xL);
            ii = obj.Tt >= tLim;             
            
            % updates the trace
            xPlt = obj.Tt(ii);
            yPlt = obj.Imu(ii);
            set(obj.hMu,'xData',xPlt-xPlt(1),'yData',yPlt)            
                        
        end
        
        % --- updates the region range plot axes
        function updateRegionRangePlot(obj)
            
            % calculates the 
            IRng = cellfun(@(x,y)(x-y),obj.Imax,obj.Imin,'un',0);
            IRngMx = cellfun(@(x)(max(x,[],2)),IRng,'un',0);
            IRngMxT = ceil(1.05*max(cellfun(@max,IRngMx)));            
            
            % updates the traces            
            IRngS = cellfun(@(x,y)(y(1)+diff(y)*x/IRngMxT),...
                                        IRngMx(:),obj.yScl,'un',0);            
            cellfun(@(h,x)(set(h,'xdata',1:length(x),...
                                 'ydata',x)),obj.hRng,flip(IRngS));
            
        end
        
        % --- clears all the plot axes
        function clearPlotAxes(obj,ind)
            
            % sets the default input arguments
            if ~exist('ind','var'); ind = [1,2]; end
            
            % resets the traces
            for i = ind(:)'
                if i == 1
                    % removes the average intensity trace
                    set(obj.hMu,'xData',NaN,'yData',NaN)
                else
                    % removes the 
                    fok = obj.iMov.flyok;
                    hasF = ~cellfun('isempty',obj.hFillR);
                    [fCN,fC0] = deal(obj.fCol{1},obj.fCol0);
                    [xi1,xi2] = deal(~fok & hasF,fok & hasF);
                    cellfun(@(x)(set(x,'xData',NaN,'yData',NaN)),obj.hRng)
                    cellfun(@(x)(set(x,'FaceColor',fCN)),obj.hFillR(xi1))
                    cellfun(@(x)(set(x,'FaceColor',fC0)),obj.hFillR(xi2))
                end
            end
            
            % resets the strings
            cellfun(@(h,x)(set(h,'String',x)),obj.hTxtH,obj.tStrH0);
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- opens the calibration view 
        function openCalibView(obj)
           
            % resets the GUI dimensions
            obj.resetGUIDimensions()
            
            % toggles the panel visibility properties
            hPanelMO = findall(obj.hFigM,'tag','panelOuter');
            setObjVisibility(hPanelMO,0)
            setObjVisibility(obj.hPanelO,1)
            
        end
        
        % --- resets the GUI dimensions
        function resetGUIDimensions(obj)
            
            % resets the image panel position
            pPosO = get(obj.hPanelO,'Position');
            resetObjPos(obj.hPanelM,'Left',sum(pPosO([1,3]))+obj.dX);
            
            % resets the figure width
            pPosM = get(obj.hPanelM,'Position');
            resetObjPos(obj.hFigM,'Width',sum(pPosM([1,3]))+obj.dX)
            
        end        
        
        % --- resets the calibration axes limits
        function resetAvgImgAxesLimits(obj)

            % calculates the axes limits/tick mark locations
            [xL,yL] = deal([0,obj.iPara.xL],[obj.iPara.yLo,obj.iPara.yHi]);
            xT = linspace(0,obj.iPara.xL,obj.nTX);
            yT = linspace(floor(obj.iPara.yLo),ceil(obj.iPara.yHi),2);

            % resets the axes limits
            yTStr = arrayfun(@num2str,yT,'un',0);
            set(obj.hAx{2},'xLim',xL,'yLim',yL,'xTick',xT,...
                           'yTick',yT,'yTickLabel',yTStr);
            
        end        
        
        % --- resets the tracking fields
        function resetTrackingFields(obj,isInit)
            
            % field retrieval  
            nTube = arr2vec(getSRCount(obj.iMov)')';
            [iR,iC] = deal(obj.iMov.iR,obj.iMov.iC);            
            
            % min/max pixel intensity mask arrays
            A = cellfun(@(x,y)(NaN(length(x),length(y))),iR,iC,'un',0);
            [obj.Imax,obj.Imin] = deal(A);
            
            % resets the position storage arrays
            obj.fPos = arrayfun(@(x)(arrayfun(@(y)...
                        (NaN(obj.nPosPr,2)),(1:x)','un',0)),nTube,'un',0);
                    
            % initialises the other array fields
            obj.pTol = NaN(obj.nApp,1);
            obj.isMove = false(size(obj.iMov.flyok)); 
            
            % resets the x/y location limits
            A = arrayfun(@(x)(NaN(x,2)),nTube,'un',0);
            [obj.xLim,obj.yLim] = deal(A);  
            
            % sets the fly status flags
            obj.tStatus = 1;
            obj.hasData = false;
            obj.fStatus = 1 + double(obj.iMov.flyok);
            
            % resets the fill colours
            for i = 1:obj.nApp
                % region information
                fok = obj.iMov.flyok(:,i)';
                xiT = 1:getSRCount(obj.iMov,i);
    
                % resets the non-rejected sub-region fill colours
                if isInit
                    arrayfun(@(x)(obj.updateFillColour...
                                        (obj.fCol0,i,x)),xiT(~fok));                    
                else
                    arrayfun(@(x)(obj.updateFillColour...
                                        (obj.fCol{2},i,x)),xiT(~fok));                    
                end
                
                % sets the rejected sub-region fill colours
                arrayfun(@(x)(obj.updateFillColour...
                                        (obj.fCol{1},i,x)),xiT(~fok));
            end
            
            % disables the check marker
            set(obj.hChkH{2},'Value',0,'Enable','off');
            set(obj.hTxtH{3},'String','Initialising...');
            
        end                        
        
        % --- updates the region fill colour to fColNw
        function updateFillColour(obj,fColNw,iApp,iTube)

            set(obj.hFillR{iTube,iApp},'FaceColor',fColNw)

        end           
        
    end
    
    % static class methods
    methods (Static)
    
        % --- retrieves the start time
        function T0 = getStartTime()

            T0 = clock();
            T0(2:3) = 1;

        end    
        
    end
    
end

