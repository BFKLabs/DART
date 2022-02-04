classdef BGCalibObj < handle
    
    % class properties
    properties
    
        % input arguments
        iMov
        prObj
        
        % dialog object handles
        hFig
        hPanel
        hAx
        
        % parameter panel objects
        hPanelP
        hEditT
        
        % title header objects
        hTxtH
        hButH        
        
        % range plot axes fields
        Imax
        Imin     
        yScl
        hFillR
        
        % avg. intensity axes fields
        iStp
        nStp
        T0
        Tt
        Yt
        
        % trace plot objects
        hMu
        hRng
        
        % main object dimensions        
        widPanel
        widAx
        hghtFig
        hghtPanel
        hghtAx
        widFig = 600;
        hghtAxRow = 50;
        hghtTxt = 16;
        hghtEdit = 21;
        hghtBut = 25;
        axX0 = 50;
        fAlpha = 0.15;
        
        % title header object dimensions
        widTxtL = [90,120];
        widTxtH = [55,40];
        widButH = 235;
        
        % parameter object dimensions
        hghtPanelP = 40;
        widTxtP = 125;
        widEditP = 50;
        
        % other class array fields
        tStrH0
        toggleStr   
        frmPara
        
        % other class scalar fields        
        nApp
        iPara
        dX = 10;
        dXH = 5;        
        nFrm0 = 10;
        Tmin = 10;  
        Tmax = 300;
        lWid = 2;
        yGap = 0.1;
        nTX = 6;
        nTY = 6;   
        axSz = 11;
        lblSz = 15;
        txtSz = 12;           
        
        % plot object colours
        fCol
        sCol = 0.1*[1,1,1];        
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = BGCalibObj(iMov,prObj)
            
            % sets the input arguments
            obj.iMov = iMov;
            obj.prObj = prObj;
            
            % initialises the class fields and objects
            obj.initClassFields();
            obj.initObjProps();
            
            % makes the GUI visible again
            centreFigPosition(obj.hFig,2);
            setObjVisibility(obj.hFig,1);
            
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
            obj.fCol = {[0,0,0],[1,0,0],[0,1,1]};
            obj.hFillR = cell(size(obj.iMov.flyok));              
                    
            % sets the object widths            
            obj.widPanel = obj.widFig - 2*obj.dX; 
            obj.widAx = obj.widPanel - (obj.dX + obj.axX0);            
            
            % calculates the object heights
            dhOfs = [0,obj.hghtPanelP+obj.dXH,0];
            obj.hghtAx = [obj.nApp*obj.hghtAxRow,150];
            obj.hghtPanel = [obj.hghtAx+2*obj.dX,40] + dhOfs;            
            obj.hghtFig = sum(obj.hghtPanel) + (nPanel+1)*obj.dX;            
            
            % sets up the parameter struct
            obj.iPara = struct('xL',60,'yLo',0,'yHi',255);
            obj.frmPara = struct('Nframe',5,'wP',0.2);
            
            % sets the toggle string
            obj.tStrH0 = {'00:00:00';'N/A'};
            obj.toggleStr = {'Start Real-Time Detection',...
                             'Stop Real-Time Detection'}; 
                         
            % sets the calibration object field for the preview object
            obj.prObj.vcObj = obj;
            
        end
        
        % --- initialises the class objects
        function initObjProps(obj)
            
            % deletes any previous GUIs
            hPrev = findall(0,'tag','figCalibBG');
            if ~isempty(hPrev); delete(hPrev); end            
            
            % --------------------------- %
            % --- MAIN FIGURE OBJECTS --- %
            % --------------------------- %            
            
            % figure object parameters
            tStr = 'Real-Time Background Detection';
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % creates the figure object            
            obj.hFig = figure('Position',fPos,'tag','figCalibBG',...
                              'MenuBar','None','Toolbar','None',...
                              'Name',tStr,'Resize','off',...
                              'NumberTitle','off','Visible','off');            
            
            % ------------------------- %
            % --- MENU ITEM OBJECTS --- %
            % ------------------------- %            
            
            % creates the menu items
            hMenu = uimenu(obj.hFig,'Label','File','Tag','menuFile');
            uimenu(hMenu,'Label','Exit','Callback',{@obj.menuClose},...
                         'Accelerator','X');                            
                          
            % ----------------------------- %
            % --- PLOT AXES PANEL SETUP --- %
            % ----------------------------- %
            
            % memory allocation            
            nPanel = length(obj.hghtPanel);
            [obj.hAx,axPos] = deal(cell(nPanel,1),cell(nPanel-1,1));            
            
            % creates the axes panel objects
            for i = 1:nPanel
                % creates vertical offset of the panel
                y0 = i*obj.dX + sum(obj.hghtPanel(1:i-1));
                
                % creates the panel object
                pPos = [obj.dX,y0,obj.widPanel,obj.hghtPanel(i)];
                obj.hPanel{i} = uipanel(obj.hFig,'Title','','Units',...
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
            x0 = obj.dX;
            bFcnH = @obj.toggleDetect;                        
            tStrL = {'Elapsed Time: ','Avg. Pixel Intensity: '};
                        
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
                        'String',obj.tStrH0{i},'HorizontalAlignment','center'); 
                    
                % increments the offset
                x0 = sum(tPos([1,3])) + obj.dX;
            end
            
            % creates the reset button
            bPos = [x0,obj.dX-2,obj.widButH,obj.hghtBut];
            obj.hButH = uicontrol(obj.hPanel{3},'Style','ToggleButton',...
                        'Position',bPos,'Callback',bFcnH,'FontUnits',...
                        'Pixels','FontSize',12,'FontWeight','Bold',...
                        'String',obj.toggleStr{1});
            
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
                lPosE = sum(tPos([1,3])) + obj.dXH;
                ePos = [lPosE,obj.dX,obj.widEditP,obj.hghtEdit];
                obj.hEditT{i} = uicontrol(obj.hPanelP,'Style','Edit',...
                        'Position',ePos,'Callback',eFcnC,'String',...
                        pVal,'UserData',pStr{i}); 
                    
                % increments the left offset
                x0 = sum(ePos([1,3])) + obj.dX;
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
            nRow = cellfun(@length,obj.iMov.iR);
            nRowMx = max(nRow);
            xLim = [1,nRowMx]+0.5*[-1,1];
            yLim = [0,obj.nApp-obj.yGap];
            
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
                    % creates the region fill marker
                    xF = xOfs(j+(0:1));
                    obj.hFillR{j,i} = fill(obj.hAx{1},xF(ix),yF(iy),...
                            obj.fCol{1+fok(j)},'FaceAlpha',obj.fAlpha,...
                            'EdgeColor','None');
                    
                    % creates the region end markers
                    plot(obj.hAx{1},xOfs(j+1)*[1,1],obj.yScl{i},'r:')
                end
                
                % creates the separator fill objects
                if i > 1
                    % creates the fill object
                    yLF = obj.yScl{i}(2) + [0,obj.yGap];
                    fill(obj.hAx{1},xLim(ix),yLF(iy),obj.sCol,...
                                           'EdgeColor','none');
                    
                    % plots the black outlines
                    for j = 1:2
                        plot(obj.hAx{1},xLim,yLF(j)*[1,1],'r');
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
            set(obj.hAx{1},'xlim',xLim,'ylim',yLim,'yTick',yTick,...
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
                    nwLim = [0,min(ceil(obj.Yt))];

                case 'yHi'
                    % case is the trace upper limit
                    nwLim = [max(ceil(obj.Yt)),255];
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
            
            % starts/stops
            isOn = get(hObj,'Value');
            set(hObj,'String',obj.toggleStr{1+isOn});
            
            % toggles the 
            if isOn
                % case is starting the calibration
                obj.runCalibrationPhase();
            else
                % case is stopping the calibration
                obj.prObj.stopTrackPreview();  
                
                % clears all the plot axes
                obj.clearAllPlotAxes();
            end
            
        end
        
        % --------------------------------------- %
        % --- DETECTION CALIBRATION FUNCTIONS --- %
        % --------------------------------------- %        
        
        % --- reads in the initial image stack
        function runCalibrationPhase(obj)
            
            % sets the initial time stamp
            obj.iStp = obj.nFrm0;
            [obj.Tt,obj.Yt] = deal(NaN(obj.nStp,1));     
            obj.clearAllPlotAxes();
            
            % field initialisation
            [iR,iC] = deal(obj.iMov.iR,obj.iMov.iC);
            obj.Imax = cellfun(@(x,y)...
                        (zeros(length(x),length(y))),iR,iC,'un',0);                                
            obj.Imin = cellfun(@(x,y)...
                        (255*ones(length(x),length(y))),iR,iC,'un',0);            
            
            % video object specific initialisations
            if obj.prObj.isTest
                % case is using a test video object

                % resets the dummy video object
                obj.prObj.objIMAQ.iFrmT = 1;
                obj.prObj.objIMAQ.previewUpdateFcn = @obj.appendTraceData;                
                
                % sets the initial time
                obj.T0 = clock();
                obj.T0(2:3) = 1;
                obj.prObj.objIMAQ.T0 = datenum(obj.T0);
                
            else
                % case is using the full camera object
    
                % sets the initial time
                obj.T0 = clock();
                obj.T0(2:3) = 1;                
            end              
            
            % starts the video tracking preview object
            obj.prObj.startTrackPreview();
                
        end                        
        
        % --- appends new trace data to the list
        function appendTraceData(obj,eData)
            
            % determines if the max time step has been reached
            if obj.iStp == obj.nStp
                % shifts the values to account for the new values
                obj.Tt(1:end-1) = obj.Tt(2:end);
                obj.Yt(1:end-1) = obj.Yt(2:end);
            
            else                
                % increment the step counter
                obj.iStp = obj.iStp + 1;
            end                     
            
            % calculates the new time/frame value
            Tnw = datevec(eData.Timestamp);
            ImgNw = double(eData.Data);
            obj.Tt(obj.iStp) = etime(Tnw,obj.T0);
            obj.Yt(obj.iStp) = nanmean(ImgNw(:));
            
            % calculates the min/max values from the new frame
            IL = cellfun(@(ir,ic)(ImgNw(ir,ic)),...
                                    obj.iMov.iR,obj.iMov.iC,'un',0);
            for i = 1:obj.nApp
                obj.Imin{i} = min(IL{i},obj.Imin{i});
                obj.Imax{i} = max(IL{i},obj.Imax{i});                
            end            
            
            % updates the fields
            tVec = [0,0,sec2vec(obj.Tt(obj.iStp))];
            set(obj.hTxtH{1},'String',datestr(datenum(tVec),'MM:SS:FFF'))
            set(obj.hTxtH{2},'String',sprintf('%.2f',obj.Yt(obj.iStp)))
                                
            % updates the plot axes
            obj.updateAvgIntensityPlot();
            obj.updateRegionRangePlot();
            
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
            yPlt = obj.Yt(ii);
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
        function clearAllPlotAxes(obj)
            
            % resets the traces
            set(obj.hMu,'xData',NaN,'yData',NaN)
            cellfun(@(x)(set(x,'xData',NaN,'yData',NaN)),obj.hRng)            
            
            % resets the region fill object facecolours
            hasF = cellfun(@isempty,obj.hFillR);
            [fC,fok] = deal(obj.fCol{1},obj.iMov.flyok);
            cellfun(@(x)(set(x,'FaceColor',fC{1})),obj.hFillR(fok & hasF))
            cellfun(@(x)(set(x,'FaceColor',fC{2})),obj.hFillR(~fok & hasF))
            
            % resets the strings
            cellfun(@(h,x)(set(h,'String',x)),obj.hTxtH,obj.tStrH0);
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %                        

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
        
        % --- deletes the GUI
        function menuClose(obj,~,~)
            
            delete(obj.hFig);
            
        end                
        
    end
    
end

