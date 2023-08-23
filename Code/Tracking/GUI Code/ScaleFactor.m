classdef ScaleFactor < handle
    
    % class properties
    properties
        
        % main class fields
        hFigM
        hType
        hGUI
        
        % secondary class fields
        iData
        hProp0
        
        % main figure object handle fields
        hAxM
        hEditM
        
        % class object handle fields
        hFig
        hPanelS
        hPanelC
        hEditS
        hTxtS
        hButC
        
        % variable class object dimensions
        hghtFig
        widPanel
        widButC
        hghtPanelS
        widObjS
        
        % fixed class object dimensions
        dX = 10;
        tSz = 12;
        widFig = 260;
        hghtPanelC = 40;
        hghtEdit = 22;
        hghtBut = 25;
        hghtTxt = 16;
        widTxt = 140;                       
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = ScaleFactor(hFigM,hType)
            
            % sets the input arguments
            obj.hFigM = hFigM;
            obj.hType = hType;
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.createClassObj();
            obj.initObjProps();
            
        end
        
        % --------------------------------------- %
        % --- OBJECT INITIALISATION FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % initialisations
            nButC = 3;
            
            % sets the secondary fields
            obj.hGUI = guidata(obj.hFigM);
            obj.iData = struct('Lm',1,'Lp',0);
            obj.hAxM = findobj(obj.hFigM,'type','axes');
            obj.hEditM = findobj(obj.hFigM,'tag','editScaleFactor');
            
            % updates the scale factor value in the main GUI axes
            switch obj.hType
                case 'FlyTrack'
                    obj.hProp0 = disableAllTrackingPanels(obj.hGUI);
                case 'FlyAnalysis'
                    obj.hProp0 = [];
            end            
            
            % calculates the variable dimensions
            obj.hghtPanelS = 2*obj.dX + 2*obj.hghtBut;
            obj.widPanel = obj.widFig - 2*obj.dX;
            obj.widButC = (obj.widPanel - (nButC+1)*obj.dX)/nButC;
            obj.widObjS = obj.widPanel - (2*obj.dX + obj.widTxt);
            obj.hghtFig = 3*obj.dX + obj.hghtPanelC + obj.hghtPanelS;            
            
        end
           
        % --- creates the class objects
        function createClassObj(obj)
            
            % class function handles
            cbFcnE = @obj.editScale;
            cbFcnB = {@obj.buttonSet,@obj.buttonUpdate,@obj.buttonClose};  
            
            % deletes any previous GUIs
            hPrev = findall(0,'tag','figScaleFactor');
            if ~isempty(hPrev); delete(hPrev); end   
            
            % --------------------------- %
            % --- MAIN FIGURE OBJECTS --- %
            % --------------------------- %     
            
            % creates the figure object
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % creates the figure object
            obj.hFig = figure('Position',fPos,'tag','figScaleFactor',...
                              'MenuBar','None','Toolbar','None',...
                              'Name','Scale Factor','Resize','off',...
                              'NumberTitle','off','Visible','off');   
                          
            % ------------------------------ %
            % --- CONTROL BUTTON OBJECTS --- %
            % ------------------------------ %                          
                 
            % initialisations
            bStrC = {'Set','Update','Close'};
            obj.hButC = cell(length(bStrC),1);
            
            % creates the experiment combining data panel 
            pPosC = [obj.dX,obj.dX,obj.widPanel,obj.hghtPanelC];
            obj.hPanelC = uipanel(obj.hFig,'Title','','Units',...
                                           'Pixels','Position',pPosC);
                                       
            % creates the control button objects
            for i = 1:length(bStrC)
                lPosC = i*obj.dX + (i-1)*obj.widButC;
                bPosC = [lPosC,obj.dX-2,obj.widButC,obj.hghtBut];
                obj.hButC{i} = uicontrol(...
                        obj.hPanelC,'Style','PushButton',...
                        'String',bStrC{i},'Callback',cbFcnB{i},...
                        'FontWeight','Bold','FontUnits','Pixels',...
                        'FontSize',obj.tSz,'Units','Pixels',...
                        'Position',bPosC);
            end                                                                           
                                       
            % ------------------------------------- %
            % --- SCALE FACTOR PROPERTY OBJECTS --- %
            % ------------------------------------- %  
            
            % initialisations
            tStrS = {'Scale Factor (mm/pix): ','Scale Length (mm): '};
            
            % creates the experiment combining data panel 
            yPosS = obj.dX + sum(pPosC([2,4]));
            pPosS = [obj.dX,yPosS,obj.widPanel,obj.hghtPanelS];
            obj.hPanelS = uipanel(obj.hFig,'Title','','Units',...
                                           'Pixels','Position',pPosS);              
            
            %
            for i = 1:length(tStrS)
                % calculates the base bottom location
                yPos0 = obj.dX + (i-1)*obj.hghtBut;
                
                % creates the text labels
                tPos = [obj.dX,yPos0+2,obj.widTxt,obj.hghtTxt];
                uicontrol(obj.hPanelS,'Style','Text','String',tStrS{i},...
                        'Units','Pixels','Position',tPos,...
                        'FontWeight','Bold','FontUnits','Pixels',...
                        'HorizontalAlignment','right',...
                        'FontSize',obj.tSz);  
                
                % creates the secondary objects
                lPos = obj.widTxt + obj.dX;
                switch i
                    case 1
                        % case is the scale factor label
                        tPosS = [lPos,yPos0+2,obj.widObjS,obj.hghtTxt];
                        obj.hTxtS = uicontrol(obj.hPanelS,'Style',...
                            'Text','String','N/A','Units','Pixels',...
                            'Position',tPosS,'FontWeight','Bold',...
                            'FontUnits','Pixels','FontSize',obj.tSz);  
                        
                    case 2
                        % case is the scale length editbox
                        ePosS = [lPos,yPos0,obj.widObjS,obj.hghtEdit];
                        obj.hEditS = uicontrol(obj.hPanelS,'String','1',...
                            'Style','Edit','Units','Pixels',...
                            'Position',ePosS,'Callback',cbFcnE);
                        
                end
            end
        end
        
        % --- initialises the class object properties
        function initObjProps(obj)
            
            % disables the update button
            setObjEnable(obj.hButC{2},'off');
            setObjVisibility(obj.hFig,'on');
            
            % sets the other figure properties
            centreFigPosition(obj.hFig,2);            
            
        end
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %                
        
        % --- scale factor editbox callback function
        function editScale(obj,hObj,~)
           
            % determines if the new value is valid
            nwVal = str2double(get(hObj,'string'));
            if chkEditValue(nwVal,[0 inf],0)
                % updates the data struct with the new values
                obj.iData.Lm = nwVal;

                % updates the data length
                obj.calcNewLength();
                setObjEnable(obj.hButC{2},'on');
            else
                % otherwise, reset the last valid value
                set(hObj,'string',num2str(obj.iData.Lm));
            end            
            
        end
        
        % --- scale factor editbox callback function
        function buttonSet(obj,~,~)
            
            % sets focus to the main image axes
            cbFcn = @obj.moveScaleMarker;
            [xL,yL] = deal(get(obj.hAxM,'XLim'),get(obj.hAxM,'YLim'));

            % creates a new line object
            % axes(obj.hAxM)
            hScale = InteractObj('line',obj.hAxM);

            % sets the line object properties
            hScale.setColour('r');
            hScale.setFields('Tag','hScale');
            hScale.setConstraintRegion(xL,yL);
            hScale.setObjMoveCallback(cbFcn);

            % enables/disables the necessary buttons
            setObjEnable(obj.hButC{1},'off')
            setObjEnable(obj.hButC{2},'on')
            
            % updates the scale marker
            obj.moveScaleMarker(hScale.getPosition());

            % resets the figure stacks
            uistack(obj.hFig,'top');
            uistack(obj.hFigM,'down',1);            
            
        end
        
        % --- scale factor editbox callback function
        function buttonUpdate(obj,hObj,~)
           
            % global variables
            global isCalib isRTPChange

            % calculates the scale factor and updates the scale factor 
            sFac = obj.calcScaleFactor(obj.iData);

            % updates the scale factor value in the main GUI axes
            switch obj.hType
                case 'FlyTrack'
                    % updates the scale factor
                    obj.hFigM.iData.exP.sFac = sFac;

                    % updates the scale factor for the real-time tracking 
                    if isCalib
                        isRTPChange = true;
                        obj.hFigM.rtP.trkP.sFac = sFac;
                    end        

                case 'FlyAnalysis'
                    % updates the scale factor
                    vpObj = getappdata(obj.hFigM,'vpObj');
                    vpObj.sFac(vpObj.iExpt) = sFac;
                    vpObj.isChange = true;
                    setappdata(obj.hFigM,'vpObj',vpObj)
            end

            % disables the update button
            setObjEnable(hObj,'off')
            set(obj.hEditM,'string',num2str(sFac))            
            
        end
        
        % --- scale factor editbox callback function
        function buttonClose(obj,~,~)
            
            % deletes the scale marker
            hScale = findobj(obj.hAxM,'Tag','hScale');
            if ~isempty(hScale); delete(hScale); end
            
            % determines if the update button has been set
            if strcmp(get(obj.hButC{2},'enable'),'on')  
                % if so, then prompt the user if they wish to update 
                tStr = 'Update Scale Factor';
                qStr = 'Do you wish to update the scale factor?';
                uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
                switch uChoice
                    case ('Yes')
                        % the user chose to update
                        obj.buttonUpdate(obj.hButC{2},[]);
                end
            end

            % resets the tracking GUI properties
            if ~isempty(obj.hProp0)
                nwStr = get(obj.hEditM,'string');
                resetHandleSnapshot(obj.hProp0)
                set(obj.hEditM,'string',nwStr)
            end

            % closes the scale factor sub-GUI
            delete(obj.hFig)            
            
        end        

        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %   
        
        % --- callback for the scale length marker 
        function moveScaleMarker(obj,varargin)

            switch length(varargin)
                case 1
                    p = varargin{1};
                case 2
                    if isa(varargin{2},'double')
                        p = varargin{2};
                    else
                        p = varargin{2}.CurrentPosition();
                    end
            end

            % updates the marker line distance
            obj.iData.Lp = sqrt(sum(diff(p,1).^2));

            % updates the marker length string
            obj.calcNewLength();
            setObjEnable(obj.hButC{2},'on')

        end        
        
        % --- calculates and sets the new scale factor length 
        function sFac = calcNewLength(obj)

            % sets the scale factor depending if the value has been set
            if obj.iData.Lp == 0
                % if the data length has not been set, then set as NaN
                sFac = NaN;
                set(obj.hTxtS,'string','N/A')
            else
                % otherwise, calculate and update the scale factor string
                sFac = obj.calcScaleFactor(obj.iData);
                set(obj.hTxtS,'string',num2str(sFac))    
            end

        end
        
    end
    
    % static class methods
    methods (Static)
        
        % --- calcualtes the scale factor dependent on the scale lengths
        function sFac = calcScaleFactor(iData)

            % number of decimal places to round to
            nDP = 4;

            % calculates the scale factor
            sFac = roundP((10^nDP)*iData.Lm/iData.Lp,1)/(10^nDP);

        end
        
    end
    
end