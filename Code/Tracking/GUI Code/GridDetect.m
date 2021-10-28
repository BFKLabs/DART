classdef GridDetect < matlab.mixin.SetGet
    
    % class properties
    properties
        % main class objects
        hFig
        hFigM
        trkObj
        iMov
        Img0
        hImg
        
        % filter parameter object handles        
        hPanelF
        hCheckF
        hTxtF
        hEditF
        
        % automatic detection object handles
        hPanelD
        hTxtP
        hTxtD
        hEditD
        hButD
        
        % control button object handles
        hPanelC
        hButC      
        
        % object dimensions
        dX = 10;
        hghtBut = 25;
        hghtEdit = 22;
        hghtCheck = 22;
        hghtTxt = 16;
        widCheckF = 150;
        widTxtF = 65;
        widEditF = 40;
        widButC = 85;
        widButD = 130;
        widPanel = 280;
        widTxtP = 210;
        widTxtS = [90,115];
        widEditS = 25;
        hghtPanelC = 40;
        hghtPanelD = 90;
        
        % other fields
        iFlag = 1;
        iSelS = [1,1];
        
    end
    
    % class methods
    methods
        
        % class constructor
        function obj = GridDetect(hFigM)
           
            % sets the input parameters
            obj.hFigM = hFigM;
            
            % sets up the class objects and callback functions
            obj.initObjProps();                        
            
        end
        
        % --------------------------------------- %
        % --- OBJECT INITIALISATION FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- initialises the gui object properties
        function initObjProps(obj)
            
            % retrieves the main image
            hFigTrk = findall(0,'tag','figFlyTrack');
            hAx = findall(hFigTrk,'type','axes');
            obj.hImg = findall(hAx,'type','image');
            obj.Img0 = double(get(obj.hImg,'CData'));
            
            % -------------------- %
            % --- FIGURE SETUP --- %
            % -------------------- %
            
            % sets the figure dimensions
            hghtFig = 4*obj.dX + (2*obj.hghtPanelC + obj.hghtPanelD);
            fPos = [200*[1,1],obj.widPanel+2*obj.dX,hghtFig];
            
            % creates the objects
            obj.hFig = figure('Position',fPos,'tag','figSplitSubRegion',...
                              'MenuBar','None','Toolbar','None',...
                              'Name','1D Grid Detection','Resize','off',...
                              'NumberTitle','off','Visible','off');                        
            
            % ---------------------------------- %
            % --- CONTROL BUTTON PANEL SETUP --- %
            % ---------------------------------- %     
            
            % initialisations
            bStrC = {'Detect','Continue','Cancel'};
            bFcnC = {@obj.detectButton,@obj.contButton,@obj.cancelButton};            
            
            % creates the panel object
            pPosC = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelC];
            obj.hPanelC = uipanel(obj.hFig,'Title','','Units','Pixels',...
                                           'Position',pPosC);
                                       
            % button object setup
            obj.hButC = cell(length(bStrC),1);
            for i = 1:length(bStrC)
                x0 = obj.dX+(i-1)*obj.widButC - (2-4*(i-1));
                tagStr = sprintf('button%s',bStrC{i});
                bPos = [x0,8,obj.widButC,obj.hghtBut];
                obj.hButC{i} = uicontrol(obj.hPanelC,'Style','pushbutton',...
                            'Position',bPos,'Tag',tagStr,'Callback',...
                            bFcnC{i},'FontUnits','Pixels','FontSize',12,...
                            'FontWeight','bold','String',bStrC{i},...
                            'UserData',i,'ForegroundColor','k');
            end                                       
                                       
            % disables the panel
            setPanelProps(obj.hButC{2},'off');
            
            % --------------------------------------- %
            % --- DETECTION PARAMETER PANEL SETUP --- %
            % --------------------------------------- %               
            
            % initialisations
            bStrD = {'Move Region Down','Move Region Up'};
            eStrD = {'Selected Row: ','Selected Column: '};
            bFcnD = @obj.moveButton;            
            eFcnD = @obj.editSelect;
            
            % creates the panel object
            y0D = 2*obj.dX + obj.hghtPanelC;
            pPosD = [obj.dX,y0D,obj.widPanel,obj.hghtPanelD];
            obj.hPanelD = uipanel(obj.hFig,'Title','','Units','Pixels',...
                                           'Position',pPosD);            
            
            % button object setup
            obj.hButD = cell(length(bStrD),1);
            for i = 1:length(bStrD)
                x0 = obj.dX+(i-1)*obj.widButD - (2-4*(i-1));
                bPos = [x0,8,obj.widButD,obj.hghtBut];
                obj.hButD{i} = uicontrol(obj.hPanelD,'Style','pushbutton',...
                            'Position',bPos,'Callback',bFcnD,'FontUnits',...
                            'Pixels','FontSize',12,'FontWeight','bold',...
                            'String',bStrD{i},'UserData',i);
            end     
            
            % creates the row/column selection objects
            y0Edit = 4*obj.dX;
            [obj.hEditD,obj.hTxtD] = deal(cell(length(eStrD),1));
            for i = 1:length(eStrD)
                % creates the text object
                x0 = obj.dX+(i-1)*obj.widEditS+sum(obj.widTxtS(1:(i-1)));
                tPosNw = [x0,y0Edit,obj.widTxtS(i),obj.hghtTxt];
                obj.hTxtD{i} = uicontrol(obj.hPanelD,'Style','text',...
                        'Position',tPosNw,'FontUnits','Pixels','FontSize',...
                        12,'FontWeight','bold','String',eStrD{i},...
                        'HorizontalAlignment','right');
                
                % creates the edit boxes
                x0 = x0 + obj.widTxtS(i);
                ePosNw = [x0,y0Edit-2,obj.widEditS,obj.hghtEdit];
                obj.hEditD{i} = uicontrol(obj.hPanelD,'Style','edit',...
                        'Position',ePosNw,'Callback',eFcnD,'UserData',i,...
                        'String','1');
            end
            
            % creates the period text label field
            y0Txt = 65;
            eStrP = 'Sub-Region Spacing Size (Pixels): ';
            tPosPL = [obj.dX,y0Txt,obj.widTxtP,obj.hghtTxt];
            uicontrol(obj.hPanelD,'Style','text',...
                    'Position',tPosPL,'FontUnits','Pixels','FontSize',...
                    12,'FontWeight','bold','String',eStrP,...
                    'HorizontalAlignment','right');            
            
            % creates the period text field
            tPosP = [obj.dX+obj.widTxtP,y0Txt,obj.widEditF,obj.hghtTxt];
            obj.hTxtP = uicontrol(obj.hPanelD,'Style','text',...
                    'Position',tPosP,'FontUnits','Pixels','FontSize',...
                    12,'FontWeight','bold','String','N/A',...
                    'HorizontalAlignment','left');
                     
            % disables the panel (if the regions are not set)
            setPanelProps(obj.hPanelD,~isempty(obj.hFigM.iMov.iR));
                
            % ----------------------------- %
            % --- PARAMETER PANEL SETUP --- %
            % ----------------------------- %    
                        
            % creates the panel object
            y0F = y0D + obj.dX + obj.hghtPanelD;
            pPosF = [obj.dX,y0F,obj.widPanel,obj.hghtPanelC];
            obj.hPanelF = uipanel(obj.hFig,'Title','','Units','Pixels',...
                                           'Position',pPosF);
            
            % creates the checkbox object
            chkStr = 'Use Image Smoothing';
            chkPos = [obj.dX,obj.dX-2,obj.widCheckF,obj.hghtCheck];
            obj.hCheckF = uicontrol(obj.hPanelF,'Units','Pixels',...
                                'Position',chkPos,'FontWeight','Bold',...
                                'FontUnits','pixels','Style','Checkbox',...
                                'FontSize',12,'String',chkStr,...
                                'Callback',@obj.useFilter,...
                                'Value',obj.getFiltPara('useFilt'));
                            
            % creates the period text label field
            x0Txt = 165;
            eStrP = 'Filter Size: ';
            tPosFL = [x0Txt,obj.dX,obj.widTxtF,obj.hghtTxt];
            uicontrol(obj.hPanelF,'Style','text',...
                    'Position',tPosFL,'FontUnits','Pixels','FontSize',...
                    12,'FontWeight','bold','String',eStrP,...
                    'HorizontalAlignment','right');
                
            % creates the edit boxes
            x0Edit = 230;
            eFcnF = @obj.editFilter;
            ePosNw = [x0Edit,obj.dX-2,obj.widEditF,obj.hghtEdit];
            obj.hEditF = uicontrol(obj.hPanelF,'Style','edit',...
                    'Position',ePosNw,'Callback',eFcnF,...
                    'String',num2str(obj.getFiltPara('hSz')));                
            
            % --------------------- %
            % --- HOUSE-KEEPING --- %
            % --------------------- %                  
                
            % makes the gui visible
            setObjVisibility(obj.hFig,1);
            obj.useFilter(obj.hCheckF,[])
            
%             % sets up the sub-regions
%             setupRegionFcn = obj.hFigM.setupSubRegions;
%             setupRegionFcn(guidata(obj.hFigM),obj.hFigM.iMov,true,true);              
            
            % resumes the figure
            uiwait(obj.hFig);                
                
        end

        % -------------------------- %
        % --- CALLBACK FUNCTIONS --- %
        % -------------------------- %    

        % --- use filter callback function
        function useFilter(obj,hObj,~)
            
            % updates the parameter value
            obj.setFiltPara('useFilt',get(hObj,'Value'));
            setObjEnable(obj.hButC{1},'on');
            
            % updates the main image
            obj.updateMainImage()
            
        end
        
        % --- filter size callback function
        function editFilter(obj,hObj,~)
            
            % determines if the new value is valid
            nwVal = str2double(get(hObj,'String'));
            if chkEditValue(nwVal,[1,10],1)
                % if so, then update the field value
                obj.setFiltPara('hSz',nwVal);
                setObjEnable(obj.hButC{1},'on');
                
                % updates the main image
                obj.updateMainImage()                
            else
                % resets the parameter value
                set(hObj,'String',num2str(obj.getFiltPara('hSz')));
            end
            
        end        
        
        % --- row/column selection index callback function
        function editSelect(obj,hObj,~)
        
            % initialisations
            iMov0 = obj.hFigM.iMov;
            iType = get(hObj,'UserData');
            nwVal = str2double(get(hObj,'String'));
            
            % sets the limit based on the type
            switch iType
                case 1
                    % case is the selected row 
                    nwLim = [1,iMov0.pInfo.nRow];
                    
                case 2
                    % case is the selected column
                    nwLim = [1,iMov0.pInfo.nCol];
                    
            end
            
            % determines if the new value is valid
            if chkEditValue(nwVal,nwLim,1)
                % if so, update the selection value
                obj.iSelS(iType) = nwVal;
                
                % updates the selection regions?
                % updates the move up/down buttons?
                
            else
                % otherwise, reset to the previous valid value
                set(hObj,'String',num2str(obj.iSelS(iType)));
            end
        
        end
        
        % --- region move up/down button callback function
        function moveButton(obj,hObj,evnt)
                        
            % updates the selection regions?
            % updates the move up/down buttons?         
            
        end
        
        % --- automatic detection callback function
        function detectButton(obj,hObj,evnt)
            
            % resumes the figure
            obj.iFlag = get(hObj,'UserData');
            setObjVisibility(obj.hFig,'off');                                  
            
            % disables the button            
            setObjEnable(hObj,false);        
            uiresume(obj.hFig);
            
        end        
            
        % --- continue callback function
        function contButton(obj,hObj,evnt)
            
            % flag that the calculations were successful
            obj.iFlag = get(hObj,'UserData');
            uiresume(obj.hFig);
            obj.closeGUI();            
            
        end
            
        % --- cancel callback function
        function cancelButton(obj,hObj,evnt)
            
            % flag that the calculations were unsuccessful
            obj.iFlag = get(hObj,'UserData');
            uiresume(obj.hFig);
            obj.closeGUI();
            
        end
        
        % --- performs the post detection check
        function checkDetectedSoln(obj,iMovNw,trkObjNw)
            
            % sets the incoming fields
            [obj.trkObj,obj.iMov] = deal(trkObjNw,iMovNw);
            tPer = nanmedian(trkObjNw.tPerS);
            
            % enables the detection parameter panel and continue button
            setPanelProps(obj.hPanelD,'on');
            set(obj.hButC{2},'enable','on','ForegroundColor','k')
            set(obj.hTxtP,'String',num2str(tPer));
            
            % sets up the sub-regions
            setupRegionFcn = obj.hFigM.setupSubRegions;
            setupRegionFcn(guidata(obj.hFigM),iMovNw,true,true);     
            
            % removes the hit-test of the inner regions
            hAx = findall(obj.hFigM,'type','axes');
            hInner = findall(hAx,'tag','hInner');
            if ~isempty(hInner)
                arrayfun(@(x)(set(findall(x),'HitTest','off')),hInner)
            end
            
            % pauses the process
            setObjVisibility(obj.hFig,'on');
            uiwait(obj.hFig);
            
        end
        
        % ----------------------- %
        % --- OTHER FUNCTIONS --- %
        % ----------------------- %
        
        % --- gets the background filter parameter filter
        function pVal = getFiltPara(obj,pFld)
            
            pVal = getStructField(obj.hFigM.iMov.bgP.pSingle,pFld);
            
        end
        
        % --- sets the background filter parameter filter
        function setFiltPara(obj,pFld,pVal)
           
            bgP = obj.hFigM.iMov.bgP.pSingle;
            obj.hFigM.iMov.bgP.pSingle = setStructField(bgP,pFld,pVal);
            
        end        
        
        % --- function that closes the gui 
        function closeGUI(obj)
            
            % deletes the gui
            obj.updateMainImage(1);
            delete(obj.hFig)
            
        end
        
        % --- updates the main image
        function updateMainImage(obj,forceRaw)
            
            % sets the default input arguments
            if ~exist('forceRaw','var'); forceRaw = false; end
            
            % retrieves the original image
            ImgNw = obj.Img0;
            
            % applies the image filter (if required)
            if obj.getFiltPara('useFilt') && ~forceRaw
                hS = fspecial('disk',obj.getFiltPara('hSz'));
                ImgNw = imfilter(ImgNw,hS);
            end
            
            % updates the main image
            set(obj.hImg,'CData',ImgNw);
            
        end
        
    end
    
end
    