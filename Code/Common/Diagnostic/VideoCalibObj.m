classdef VideoCalibObj < handle
    
    % class properties
    properties
        
        % main object handles
        hFig
        hGUI
        
        % panel object handles        
        hPanelO     % outer panel
        hPanelAx    % axes panel 
        hPanelI     % inner parameter panel
        hPanelT     % trace parameter panel
        hPanelH     % property history panel
        
        % other object handles
        hMenu
        hAx
        hTitle
        hEditT
        hButT 
        hListH
        
        % panel object dimensions
        widPanelO = 500;
        widPanelI        
        widPanelT = 235;
        widPanelH = 240;        
        hghtPanelAx = 415;        
        hghtPanelI = 145;            
        hghtPanelTH                
        
        % other object dimensions
        widTxtT = 120;
        widEditT = 95;   
        widAx = 470;  
        widBut
        widListH
        hghtTxtT = 16;
        hghtEditT = 21; 
        hghtAx = 370;
        hghtBut = 25;        
        hghtListH = 103;
        
        % trace values
        T0
        Tt        
        Yt
        Tm        
        FPS
        iStp
        nStp
        hMark
        hTrace

        % image row/column indices
        iRI
        iCI
        
        % boolean flags
        isOpen = false;
        isOldVer = verLessThan('matlab','9.10');

        % other objects
        iPara        
        dY = 2;
        dX = 10;
        nTX = 6;
        nTY = 6;        
        fSz = 13; 
        tSz = 12;
        lblSz = 12;
        Tmin = 10;  
        Tmax = 300;  
        lWid = 2;
        
    end
    
    % class methods
    methods
        
        % class contstructor
        function obj = VideoCalibObj(hFig)
            
            % sets the input arguments                        
            obj.hFig = hFig;  
            obj.hGUI = guidata(hFig);
            
            % initialises the calibration video
            obj.initCalibPara();            
            obj.initCalibObjects();
            
        end

        % --------------------------------------- %
        % --- OBJECT INITIALISATION FUNCTIONS --- %
        % --------------------------------------- %    s
        
        % --- initialises the video calibration objects
        function initCalibObjects(obj)
            
            % initialisations
            hMenuP = obj.hGUI.menuCalibrate;   
            
            % field initialisations
            obj.iStp = 0;
            obj.nStp = 50*obj.Tmax;
            
            % derived object property values
            obj.widPanelI = obj.widPanelO - obj.dX;
            obj.hghtPanelTH = obj.hghtPanelI - obj.dX;            
            obj.widBut = obj.widPanelT - 2*obj.dX;
            obj.widListH = obj.widPanelH - 2*obj.dX;
            
            % ------------------------- %
            % --- MENU ITEM OBJECTS --- %
            % ------------------------- %
            
            % creates the menu item
            obj.hMenu = uimenu(hMenuP,'Label','Calibrate Video',...
                                      'Callback',@obj.menuCalibVideo,...
                                      'tag','menuCalibrateVideo');
            
            % -------------------------- %
            % --- MAIN PANEL OBJECTS --- %
            % -------------------------- %       
            
            % sets up the panel position vector
            pPosPr = get(obj.hGUI.panelVidPreview,'Position');
            lPosO = sum(pPosPr([1,3])) + obj.dX;
            pPosO = [lPosO,obj.dX,obj.widPanelO,pPosPr(4)];
            
            % creates the outer panel object
            obj.hPanelO = uipanel(obj.hFig,'Title','','Units','Pixels',...
                                           'Position',pPosO);
                                       
            % --------------------------------------- %
            % --- PARAMETER/HISTORY PANEL OBJECTS --- %
            % --------------------------------------- % 
            
            % initalisations
            lPosH = obj.widPanelT + obj.dX;
            
            % panel title strings
            tStrT = 'TRACE PARAMETERS';
            tStrH = 'CAMERA PROPERTY HISTORY';
            
            % sets up the panel position vector
            pPosI = [(obj.dX/2)*[1,1],obj.widPanelI,obj.hghtPanelI];
            pPosT = [(obj.dX/2)*[1,1],obj.widPanelT,obj.hghtPanelTH];
            pPosH = [lPosH,(obj.dX/2),obj.widPanelH,obj.hghtPanelTH];
            
            % creates the inner panel object
            obj.hPanelI = uipanel(obj.hPanelO,'Title','','Units',...
                                              'Pixels','Position',pPosI);
                      
            % creates the trace/history panel objects
            obj.hPanelT = uipanel(obj.hPanelI,'Title',tStrT,'Units',...
                        'Pixels','Position',pPosT,'FontUnits','Pixels',...
                        'FontSize',obj.fSz,'FontWeight','bold');
            obj.hPanelH = uipanel(obj.hPanelI,'Title',tStrH,'Units',...
                        'Pixels','Position',pPosH,'FontUnits','Pixels',...
                        'FontSize',obj.fSz,'FontWeight','bold');                                        
                   
            % -------------------------------- %
            % --- TRACE AXES PANEL OBJECTS --- %
            % -------------------------------- %
            
            % initialisations
            tStr = 'Avg Intensity = N/A';
            
            % sets up the panel position vector
            yPosAx = obj.hghtPanelI + obj.dX;
            pPosAxO = [(obj.dX/2),yPosAx,obj.widPanelI,obj.hghtPanelAx];
                         
            % creates the trace/history panel objects
            obj.hPanelAx = uipanel(obj.hPanelO,'Title','','Units',...
                                              'Pixels','Position',pPosAxO);            
            
            % creates the axes object
            pPosAx = [obj.dX*[1,1],obj.widAx,obj.hghtAx];
            obj.hAx = axes(obj.hPanelAx,'Units','Pixels',...
                                        'Position',pPosAx,'box','on',...
                                        'XTickLabel',[],'YTickLabel',[]);
            grid(obj.hAx,'on')
            
            %
            obj.hTrace = plot(obj.hAx,NaN,NaN,'k','LineWidth',obj.lWid);
            obj.hTitle = title(obj.hAx,tStr,'FontWeight','Bold',...
                                            'FontSize',obj.tSz);
            
            % disables the axis interactivity
            if ~obj.isOldVer
                disableDefaultInteractivity(obj.hAx)
                obj.hAx.Toolbar.Visible = 'off';
            end

            % ------------------------------------- %
            % --- TRACE PARAMETER PANEL OBJECTS --- %
            % ------------------------------------- %
            
            % initialisations
            pStr = {'yHi','yLo','xL'};
            tStr = {'Trace Upper Limit: ',...
                    'Trace Lower Limit: ',...
                    'Trace Duration (s): '};
            eFcnC = @obj.editTracePara;
            bFcnC = @obj.buttonResetTrace;
            
            % creates the reset button
            bPos = [obj.dX*[1,1],obj.widBut,obj.hghtBut];
            obj.hButT = uicontrol(obj.hPanelT,'Style','Pushbutton',...
                        'Position',bPos,'Callback',bFcnC,'FontUnits',...
                        'Pixels','FontSize',12,'FontWeight','Bold',...
                        'String','Reset Trace Parameters');
                    
            % creates the trace parameter editbox
            obj.hEditT = cell(length(tStr),1);
            for i = 1:length(tStr)
                % sets the position offset
                yPos0 = sum(bPos([2,4]))+i*obj.dX/2+(i-1)*obj.hghtEditT;
                
                % creates the text object
                tPos = [obj.dX/2,yPos0+obj.dY,obj.widTxtT,obj.hghtTxtT];
                uicontrol(obj.hPanelT,'Style','Text','Position',tPos,...
                        'FontUnits','Pixels','FontWeight','Bold',...
                        'FontSize',obj.lblSz,'String',tStr{i},...
                        'HorizontalAlignment','right');
                
                % creates the editbox
                pVal = num2str(getStructField(obj.iPara,pStr{i}));
                lPosE = sum(tPos([1,3])) + obj.dX/2;
                ePos = [lPosE,yPos0,obj.widEditT,obj.hghtEditT];
                obj.hEditT{i} = uicontrol(obj.hPanelT,'Style','Edit',...
                        'Position',ePos,'Callback',eFcnC,'String',...
                        pVal,'UserData',pStr{i});
                
            end                                  
                       
            % ----------------------------------- %
            % --- TRACE HISTORY PANEL OBJECTS --- %
            % ----------------------------------- % 
            
            % initialisations
            lStr = {'Original Parameters'};                       
            lPosH = [obj.dX*[1,1],obj.widListH,obj.hghtListH];
            
            % creates the list callback function
            obj.hListH = uicontrol(obj.hPanelH,'Style','Listbox',...
                        'Units','Pixels','Position',lPosH,...
                        'String',lStr,'Enable','Inactive',...
                        'Max',2,'Value',[]);
            
        end        
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %
        
        % --- video calibration menu item callback
        function menuCalibVideo(obj,hObj,~)
        
            % initialisations
            eStr = {'off','on'};
            isCheck = strcmp(get(hObj,'Checked'),'on');                        

            % initialises the traces
            if ~isCheck
                obj.buttonResetTrace(obj.hButT,[]);
            end

            % updates the object properties
            set(hObj,'Checked',eStr{~isCheck+1})
            setObjEnable(obj.hGUI.menuExpt,isCheck)
            obj.isOpen = ~isCheck;

            % resets the width of the main figure
            dW = (1-2*isCheck)*(obj.widPanelO+obj.dX);
            resetObjPos(obj.hFig,'Width',dW,1);            
            
        end  
        
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
                    nwLim = [0,obj.iPara.yHi];

                case 'yHi'
                    % case is the trace upper limit
                    nwLim = [obj.iPara.yLo,255];
            end

            % determines if the new value is valid
            if chkEditValue(nwVal,nwLim,false)
                % if so, then update the 
                obj.iPara = setStructField(obj.iPara,pStr,nwVal);

                % resets the calibration axes limits    
                obj.resetCalibAxesLimits()
                
            else
                % otherwise, reset back to the previous valid value
                pVal = getStructField(obj.iPara,pStr);
                set(hObj,'String',num2str(pVal))
            end
            
        end
        
        % --- reset trace button callback function
        function buttonResetTrace(obj,~,~)
            
            % re-initialises the calibration parameters
            obj.initCalibPara();

            % resets the trace parameters
            for i = 1:length(obj.hEditT)
                pStr = get(obj.hEditT{i},'UserData');
                pVal = getStructField(obj.iPara,pStr);
                set(obj.hEditT{i},'String',num2str(pVal))
            end
            
            % clears the axes            
            set(obj.hAx,'xticklabel',[],'yticklabel',[],'box','on');
            set(obj.hTrace,'xData',NaN,'yData',NaN);
            obj.resetCalibAxesLimits()
            grid(obj.hAx,'on')

            % resets the trace fields
            obj.resetTraceFields();            
            
            % creates the title object
            obj.hTitle = title(obj.hAx,'Avg Intensity = N/A',...
                                       'FontWeight','Bold','FontSize',12);
                         
        end        

        % ------------------------------- %
        % --- OBJECT UPDATE FUNCTIONS --- %
        % ------------------------------- %
        
        % --- resets the video property history listbox
        function resetVideoProp(obj)
            
            set(obj.hListH,'String',{'Original Parameters'});
            
        end
        
        % --- appends a new video property to the list
        function appendVideoProp(obj,pName,pVal)
            
            % creates the new property string
            if isnumeric(pVal)
                % case is the value is numeric
                lStrNw = sprintf('%s (%s)',pName,num2str(pVal));
            else
                % case is the value is a string
                lStrNw = sprintf('%s (%s)',pName,pVal);
            end
            
            % retrieves the current time
            [Tnow,A] = deal(datevec(now),zeros(1,3));
            obj.Tm(end+1) = etime([A,Tnow(4:6)],[A,obj.T0(4:6)]);
            
            % create a new marker line for the property change
            hold(obj.hAx,'on')
            obj.hMark(end+1) = plot...
                            (obj.hAx,NaN,NaN,'r:','linewidth',obj.lWid);
            hold(obj.hAx,'off')
            
            % updates the listbox strings
            lStr = [get(obj.hListH,'String');{lStrNw}];
            set(obj.hListH,'String',lStr);
            
        end
        
        % --- appends the frame data and updates the axes
        function newCalibFrame(obj,eData,isCB)
            
            % determines if the max time step has been reached
            if obj.iStp == obj.nStp
                % shifts the values to account for the new values
                obj.Tt(1:end-1) = obj.Tt(2:end);
                obj.Yt(1:end-1) = obj.Yt(2:end);
            
            else
                % initialises the data vector (if first time step)
                if obj.iStp == 0                    
                    % sets the initial time stamp
                    obj.T0 = datevec(eData.Timestamp);
                    
                    % allocates memory for the new data                    
                    [obj.Tt,obj.Yt] = deal(NaN(obj.nStp,1));
                end
                
                % updates the camera video frame rate
                if isCB
                    fRateStr = strsplit(eData.FrameRate);
                    obj.FPS = ceil(str2double(fRateStr{1}));
                else
                    obj.FPS = ceil(eData.FrameRate);
                end
           
                % increment the step counter
                obj.iStp = obj.iStp + 1;
            end            
                    
            % sets the sub-image
            try
                Inw = rgb2gray(eData.Data(obj.iRI,obj.iCI,:));
            catch
                Inw = rgb2gray(eData.Data);
            end

            % updates the time/avg. intensity values  
            Tnw = datevec(eData.Timestamp);
            obj.Tt(obj.iStp) = etime(Tnw,obj.T0);            
            obj.Yt(obj.iStp) = mean(double(Inw(:)),'omitnan');            
            
            % updates the plot axes
            obj.updateTraceAxes();
            
        end
        
        % --- updates the trace plot axes
        function updateTraceAxes(obj)
                        
            % determines the feasible plot values
            Tf = obj.Tt(obj.iStp);
            tLim = (Tf - obj.iPara.xL);
            ii = obj.Tt >= tLim;             
            
            % updates the trace
            xPlt = obj.Tt(ii);
            yPlt = obj.Yt(ii);
            set(obj.hTrace,'xData',xPlt-xPlt(1),'yData',yPlt)
            
            % updates the marker lines
            if ~isempty(obj.hMark)
                % plot variables
                [yLim,t0] = deal([0,255],xPlt(1));

                % updates the plot markers
                xiM = 1:min(length(obj.hMark),length(obj.Tm));
                arrayfun(@(x,y)(set(x,'xdata',y*[1,1]-t0,'ydata',yLim)),...
                                obj.hMark(xiM),obj.Tm(xiM));
            end
            
            % updates the trace title (roughly every second)
            if mod(obj.iStp,obj.FPS) == 1                
                tStrNw = sprintf(['Avg Intensity = %.2f (Min = %.2f, ',...
                                  'Max = %.2f)'],yPlt(end),...
                                  min(yPlt),max(yPlt));
                set(obj.hTitle,'String',tStrNw);
            end            
            
        end
        
        % ----------------------- %
        % --- OTHER FUNCTIONS --- %
        % ----------------------- %
        
        % --- resets the calibration axes limits
        function resetCalibAxesLimits(obj)

            % calculates the axes limits/tick mark locations
            [xL,yL] = deal([0,obj.iPara.xL],[obj.iPara.yLo,obj.iPara.yHi]);
            xT = linspace(0,obj.iPara.xL,obj.nTX);
            yT = linspace(obj.iPara.yLo,obj.iPara.yHi,obj.nTY);

            % resets the axes limits
            set(obj.hAx,'xLim',xL,'yLim',yL,'xTick',xT,'yTick',yT);
            
        end
        
        % --- resets the object properties
        function resetObjProps(obj,dH)
            
            resetObjPos(obj.hPanelO,'Height',dH,1);
            resetObjPos(obj.hPanelAx,'Height',dH,1);
            resetObjPos(obj.hAx,'Height',dH,1);            
            
        end
        
        % --- initialises the calibration parameters
        function initCalibPara(obj)
            
            obj.iPara = struct('xL',60,'yLo',0,'yHi',255);
            
        end
        
        % --- resets the trace fields  
        function resetTraceFields(obj)
            
            % resets the time step counter
            obj.iStp = 0;
            obj.Tm = [];            
            
            % resets the trace title
            set(obj.hTitle,'String','Avg Intensity = N/A');
            set(obj.hTrace,'xData',NaN,'yData',NaN);
            set(obj.hListH,'String',{'Original Parameters'})
            
            % deletes any existing markers
            if ~isempty(obj.hMark)
                % clears the marker field
                hMark0 = obj.hMark;
                obj.hMark = [];
                
                try
                    % deletes any existing markers
                    arrayfun(@delete,hMark0)   
                catch
                end
            end            
            
        end
        
    end
    
end
