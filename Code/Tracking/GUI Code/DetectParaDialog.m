classdef DetectParaDialog < handle
    
    % class properties
    properties
        
        % main class fields
        sObj
        bgP
        
        % initial class fields
        bgP0
        
        % class object handles
        hFig 
        hPanelP        
        hTabGrp
        hTab
        hEditP
        hPanelC
        hButC
        
        % parameter 
        tStrP
        pType
        tStr
        pStr
        ttStr
        tType
        nTab
        nParaMx
        
        % object dimensions
        dX = 10;
        dXH = 5;    
        fSz = 12;
        widFig
        widPanel
        widTxt
        widTxtP
        widPopup = 140;        
        widBut = 105;
        widEdit = 60;
        hghtFig 
        hghtPanelP
        hghtPanelC = 40;
        hghtTxt = 16;
        hghtEdit = 22;
        hghtBut = 25;        
        
        % other scalar fields                
        tSz = 12;
        isInit = false;        
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = DetectParaDialog(sObj)
            
            % sets the class fields
            obj.sObj = sObj;
            
            % initialises the class fields and object properties
            obj.initClassFields();
            obj.initObjProps();
            
            % centres the figure and makes it visible
            centreFigPosition(obj.hFig,2);
            setObjVisibility(obj.hFig,1);
            
        end
        
        % ----------------------------------- %
        % --- CLASS OBJECT INITIALISATION --- %
        % ----------------------------------- %
        
        % --- initialises the object class fields
        function initClassFields(obj)
            
            % initialisations
            isHT1 = isHT1Controller(obj.sObj.iData);
            
            % sets the main class fields            
            obj.bgP = DetectPara.getDetectionPara(obj.sObj.iMov,isHT1);
            obj.bgP0 = DetectPara.initDetectParaStruct('All',isHT1);
            
            % sets the tab field parameters
            obj.tStrP = {'Phase Detection',...
                         'Initial Detection',...
                         'Full Tracking'}; 
            obj.nTab = length(obj.tStrP);             
            
            % retrieves the tab parameter fields
            A = cell(obj.nTab,1);
            [obj.pType,obj.tStr,obj.pStr,obj.ttStr,obj.tType] = deal(A);
            for i = 1:obj.nTab
                [obj.pType{i},obj.tStr{i},obj.pStr{i},obj.ttStr{i},...
                        obj.tType{i}] = obj.getTabParaFields(obj.tStrP{i});
            end
            
            % sets the maximum parameter count
            obj.nParaMx = max(cellfun('length',obj.tStr));
            
            % calculates the parameter panel height
            obj.hghtPanelP = obj.hghtBut*obj.nParaMx + 50;
            obj.widPanel = 2*(obj.dX+obj.dXH) + 3*obj.widBut;
            obj.widTxt = obj.widPanel - (3*obj.dX + obj.widEdit);
            obj.widTxtP = obj.widPanel - (3*obj.dX + obj.widPopup);
            
            % calculates the figure 
            obj.widFig = obj.widPanel + 2*obj.dX;
            obj.hghtFig = obj.dX*3 + obj.hghtPanelP + obj.hghtPanelC;            
            
        end
        
        % --- class object property initialisation
        function initObjProps(obj)
            
            % deletes any previous GUIs
            hPrev = findall(0,'tag','figDetectPara');
            if ~isempty(hPrev); delete(hPrev); end             
            
            % -------------------------- %
            % --- MAIN FIGURE OBJECT --- %
            % -------------------------- %            
            
            % sets the figure position
            fPos = [100,100,obj.widFig,obj.hghtFig];                        
            
            % creates the figure object            
            obj.hFig = figure('Position',fPos,'tag','figDetectPara',...
                              'MenuBar','None','Toolbar','None',...
                              'Name','Detection Parameters',...
                              'NumberTitle','off','Visible','off',...
                              'Resize','off');
                          
            % creates the control button panel object
            pPosC = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelC];
            obj.hPanelC = uipanel(obj.hFig,'Title','','Units','Pixels',...
                                           'Position',pPosC);                          
            
            % creates the control button panel object
            yOfsP = sum(pPosC([2,4])) + obj.dX;
            pPosP = [obj.dX,yOfsP,obj.widPanel,obj.hghtPanelP];
            obj.hPanelP = uipanel(obj.hFig,'Title','','Units','Pixels',...
                                           'Position',pPosP);   
                                       
            % ----------------------------------- %
            % --- DETECTION PARAMETER OBJECTS --- %
            % ----------------------------------- %                        
            
            % turns off the warning messages
            wState = warning('off','all');
            
            % calculates the other other object dimensions
            eFcn = @obj.editPara;
            pFcn = @obj.popupPara;
            tabPos = getTabPosVector(obj.hPanelP,[5,5,-10,-5]);            
                                       
            % creates a tab panel group            
            obj.hTabGrp = createTabPanelGroup(obj.hPanelP,1);
            set(obj.hTabGrp,'position',tabPos,'tag','hTabGrp')  
            
            % sets up the tab objects (over all stimuli objects) 
            obj.hTab = deal(cell(obj.nTab,1));
            for i = 1:obj.nTab
                % sets up the tabs within the tab group
                obj.hTab{i} = createNewTab(obj.hTabGrp,...
                                'Title',obj.tStrP{i},'UserData',i);
                pause(0.1)    
                
                % creates the parameter fields (for the current tab)
                for j = 1:length(obj.tStr{i})
                    % calculates the vertical offset
                    y0 = obj.dXH + (obj.nParaMx - j)*obj.hghtBut;
                    uD = {obj.pType{i},obj.pStr{i}{j}};                                            
                    
                    % retrieves the parameter value
                    pVal = getTrackingPara...
                                    (obj.bgP,obj.pType{i},obj.pStr{i}{j});                     
                    
                    switch obj.tType{i}{j}
                        case 'e'
                            % creates the text label object
                            tStrNw = sprintf('%s :',obj.tStr{i}{j});
                            tPos = [obj.dXH,y0+2,obj.widTxt,obj.hghtTxt];
                            uicontrol(obj.hTab{i},'Style','text',...
                                'Position',tPos,'FontUnits','Pixels',...
                                'FontSize',obj.fSz,'FontWeight','bold',...
                                'String',tStrNw,'HorizontalAlignment',...
                                'right','ToolTipString',obj.ttStr{i}{j});

                            % creates the edit boxes
                            xEdit0 = sum(tPos([1,3])) + obj.dXH;
                            ePos = [xEdit0,y0,obj.widEdit,obj.hghtEdit];                           
                            
                            % case is the editbox parameter
                            uicontrol(obj.hTab{i},'Style',...
                                'edit','Position',ePos,'Callback',eFcn,...
                                'UserData',uD,'String',num2str(pVal),...
                                'ToolTipString',obj.ttStr{i}{j});
                            
                        case 'p'
                            % case is the popupmenu parameter
                            tStrNw = obj.tStr{i}{j};
                            
                            % creates the text label
                            tPos = [obj.dX,y0+2,obj.widTxtP,obj.hghtTxt];
                            uicontrol(obj.hTab{i},'Style','Text',...
                                'Position',tPos,'FontUnits','Pixels',...
                                'FontSize',obj.fSz,'FontWeight','bold',...
                                'String',tStrNw{1},'HorizontalAlignment',...
                                'right','ToolTipString',obj.ttStr{i}{j});                            
                            
                            % creates the popup menut
                            lPosPP = sum(tPos([1,3])) + obj.dX/2;
                            ppPos = [lPosPP,y0,obj.widPopup,obj.hghtEdit];
                            uicontrol(obj.hTab{i},'Style','popupmenu',...
                                'Position',ppPos,'Callback',pFcn,...
                                'UserData',uD,'Value',double(pVal)+1,...
                                'ToolTipString',obj.ttStr{i}{j},...
                                'String',tStrNw{2},'FontUnits','Pixels',...
                                'FontWeight','Bold','FontSize',obj.fSz);
                    end
                end
            end
                             
            % resets the warnings
            warning(wState);             
            
            % ------------------------------ %
            % --- CONTROL BUTTON OBJECTS --- %
            % ------------------------------ % 
            
            % initialisations
            bStr = {'Update Changes','Restore Default','Close Window'};
            bFcn = {@obj.updatePara,@obj.useDefaultPara,@obj.closeGUI};  
                        
            % creates the button objects
            obj.hButC = cell(length(bStr),1);
            for i = 1:length(bStr)
                xBut = obj.dX + (i-1)*(obj.widBut + obj.dXH);
                bPos = [xBut,obj.dX-2,obj.widBut,obj.hghtBut];
                obj.hButC{i} = uicontrol(obj.hPanelC,'Style','PushButton',...
                        'String',bStr{i},'Callback',bFcn{i},'FontWeight',...
                        'Bold','FontUnits','Pixels','FontSize',obj.tSz,...
                        'Units','Pixels','Position',bPos); 
                setObjEnable(obj.hButC{i},i==length(bStr))
            end
            
        end
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %  
        
        % --- callback function for update the editbox parameter
        function editPara(obj,hObject,~)
            
            % initialisations
            uD = get(hObject,'UserData');
            [pTypeP,pStrP] = deal(uD{1},uD{2});
            [nwLim,isInt] = obj.getParaLimits(pStrP);
            pS = getStructField(obj.bgP,pTypeP);
            
            % determines if the new value is valid
            nwVal = str2double(get(hObject,'String'));
            if chkEditValue(nwVal,nwLim,isInt)
                % if the value is valid, then update the parameter field
                obj.bgP = setTrackingPara(obj.bgP,pTypeP,pStrP,nwVal);
                
                % enables the update/reset buttons
                cellfun(@(x)(setObjEnable(x,1)),obj.hButC(1:2))
            else
                % otherwise, revert back to the previous valid value                
                set(hObject,'string',num2str(getStructField(pS,pStrP)));
            end
            
        end
        
        % --- callback function for update the editbox parameter
        function popupPara(obj,hObject,~)
            
            % initialisations
            uD = get(hObject,'UserData');
            nwVal = get(hObject,'Value');
            [pTypeP,pStrP] = deal(uD{1},uD{2});            
            
            % if the value is valid, then update the parameter field
            obj.bgP = setTrackingPara(obj.bgP,pTypeP,pStrP,nwVal-1);  
            
            % enables the update/reset buttons
            cellfun(@(x)(setObjEnable(x,1)),obj.hButC(1:2))            
            
        end
        
        % --- callback function for updating the detection parameters
        function updatePara(obj,~,~)
            
            % prompts the user if they wish to update the struct
            qStr = ['Do you want to make a temporary or ',...
                    'permanent update?'];
            uChoice = questdlg(qStr,'Parameter Update Type',...
                'Temporary','Permanent','Cancel','Temporary');
            if isempty(uChoice) || strcmp(uChoice,'Cancel')
                % if the user cancelled, then exit the function
                return
            end
            
            % updates the parameter struct into the main object            
            obj.sObj.iMov.bgP = obj.bgP;
            if isfield(obj.sObj,'isChange')
                obj.sObj.isChange = true;
            end
                
            % updates the parameter struct permanently (if required)
            if strcmp(uChoice,'Permanent')
                % retrieves the parameter file name
                pFile = getParaFileName('ProgPara.mat');  
                
                % updates the file with the new parameters
                A = load(pFile);
                A.bgP = obj.bgP;
                save(pFile,'-struct','A')                
            end
            
            % resets the update button enabled properties
            setObjEnable(obj.hButC{1},0)                
            
        end
        s
        % --- callback function for resetting the default parameters
        function useDefaultPara(obj,~,~)
            
            % prompts the user if they wish to update the struct
            qtStr = 'Reset Default Parameters?';
            qStr = ['Are sure you want to use the default ',...
                    'tracking parameters?'];
            uChoice = questdlg(qStr,qtStr,'Yes','No','Yes');            
            if ~strcmp(uChoice,'Yes')
                % if the user cancelled, then exit the function
                return
            end
            
            % resets the parameter struct
            obj.bgP = obj.bgP0;     
            obj.sObj.iMov.bgP = obj.bgP;
            if isfield(obj.sObj,'isChange')
                obj.sObj.isChange = true;
            end
            
            % resets the parameter editbox strings
            for i = 1:length(obj.pType)
                for j = 1:length(obj.pStr{i})
                    uD = {obj.pType{i},obj.pStr{i}{j}};
                    hEdit = findall(obj.hFig,'UserData',uD);
                    
                    % resets the editbox string
                    pVal = getTrackingPara...
                                    (obj.bgP,obj.pType{i},obj.pStr{i}{j});
                    set(hEdit,'String',num2str(pVal));
                end
            end
            
            % resets the update/reset button enabled properties
            cellfun(@(h)(setObjEnable(h,0)),obj.hButC(1:2))
            
        end        
         
        % --- callback function for closing the dialog window
        function closeGUI(obj,~,~)
            
            % determines if any changes were made to the parameters
            if strcmp(get(obj.hButC{1},'Enable'),'on')
                % if so, then prompt the user if the wish to update
                qStr = 'Do you want to update your changes before closing?';
                uChoice = questdlg(qStr,'Update Changes','Yes','No',...
                                        'Cancel','Yes');
                switch uChoice
                    case 'Yes'
                        % user chose to update
                        obj.updatePara(obj.hButC{1},[])
                        
                    case 'Cancel'
                        % user cancelled, so exit
                        return
                end
                
            end
            
            % closes the GUI
            delete(obj.hFig)
            
        end
                
    end
    
    % static class methods
    methods (Static)
        
        % --- retrieves the parameter limits (based on pStr)
        function [nwLim,isInt] = getParaLimits(pStr)
            
            % initialisations
            isInt = false;
            
            % sets the limits/integer flag based on parameter type
            switch pStr
                % ---------------------------------- %
                % --- PHASE DETECTION PARAMETERS --- %
                % ---------------------------------- %
                
                case 'nImgR'
                    % Initial Phase Detection Frame Count
                    [isInt,nwLim] = deal(true,[5,50]);
                    
                case 'Dtol'
                    % Max Phase Avg. Pixel Intensity Difference
                    nwLim = [2,10];
                    
                case 'pTolLo'
                    % Upper Avg. Pixel Intensity Limit
                    [isInt,nwLim] = deal(true,[0,55]);
                    
                case 'pTolHi'           
                    % Upper Avg. Pixel Intensity Limit
                    [isInt,nwLim] = deal(true,[200,255]);
                    
                case 'nPhMax'
                    % Upper Avg. Pixel Intensity Limit
                    [isInt,nwLim] = deal(true,[3,inf]);                    
                    
                % ------------------------------------ %
                % --- INITIAL DETECTION PARAMETERS --- %
                % ------------------------------------ %

                case 'nFrmMin'
                    % Min. Allowable BG Estimate Frame Count
                    [isInt,nwLim] = deal(true,[1,10]);
                    
                case 'pYRngTol'
                    % Min. Residual Range Signal Ratio
                    nwLim = [2,5];
                    
                case 'pIRTol'
                    % Min. Point-To-Peak Residual Ratio
                    nwLim = [0.2,0.5];                
                
                % -------------------------------- %
                % --- FULL TRACKING PARAMETERS --- %
                % -------------------------------- %                

                case 'rPmxTol'
                    % Max. Residual Prominent Peak Ratio
                    nwLim = [0.7,0.99];                    
                    
                case 'pTolPh'
                    % Max Ref. Image Pixel Intensity Offset
                    nwLim = [2,10];
                    
                case 'pWQ'
                    % Residual Image Weighting Threshold
                    nwLim = [0.1,1];                
                    
            end
            
        end
        
        % --- retrieves the tab parameter fields
        function [pType,tStr,pStr,ttStr,tType] = getTabParaFields(tStr)
            
            % initialisations
            a = char(8594);
            
            switch tStr
                case 'Phase Detection'
                    % case is the phase detection parameters
                    pType = 'pPhase';
                    tStr = {'Initial Phase Detection Frame Count',...
                            'Lower Avg. Pixel Intensity Limit',...
                            'Upper Avg. Pixel Intensity Limit',...
                            'Maximum Initial Video Phase Count'};
                    pStr = {'nImgR','pTolLo','pTolHi','nPhMax'};
                    ttStr = {
                         ['The initial number of frames used to ',...
                          'estimate the video phases.'],...
                         ['Images with Avg. Pixel intensities ',...
                          'below this value are considered too dark.'],...
                         ['Images with Avg. Pixel intensities ',...
                          'above this value are considered too bright.'],...
                         ['Maximum initial phase count. Videos with ',...
                          'phase counts above this value are ',...
                          'considered unstable.']                          
                    };

                    % sets the object type flags                
                    tType = {'e','e','e','e'};
                    
                case 'Initial Detection'
                    % case is the phase detection parameters
                    pType = 'pInit';
                    tStr = {'Min. Allowable BG Estimate Frame Count',...
                            'Min. Residual Range Signal Ratio',...
                            'Min. Point-To-Peak Residual Ratio'};
                    pStr = {'nFrmMin','pYRngTol','pIRTol'};                    
                    ttStr = {
                        sprintf(['Min phase frame count required to ',...
                        'calculate the background image estimate.\n %s ',...
                        'otherwise, background image estimate ',...
                        'calculation is skipped for this phase.'],a),...
                        sprintf(['The minimum signal to baseline ',...
                        'ratio for any blobs within a region to be ',...
                        'considered moving.\n %s otherwise, all region ',...
                        'blobs are considered to be stationary.'],a),...
                        sprintf(['Min phase frame count required to ',...
                        'calculate the BG Image.\n %s otherwise, ',...
                        'background image estimate calculation is ',...
                        'skipped for this phase.'],a)
                    };
                
                    % sets the object type flags                
                    tType = {'e','e','e'};
                    
                case 'Full Tracking'
                    % case is the phase detection parameters
                    pType = 'pTrack';
                    ppStr = {{'Inter-Frame Distance Check :'},...
                             {'No Distance Check';'Full Distance Check';...
                              'Left-Side Only';'Right-Side Only'}};                        
                    tStr = {'Max. Residual Prominent Peak Ratio',...
                            'Max Reference Image Pixel Intensity Offset',...
                            'Residual Image Weighting Threshold',ppStr};
                    pStr = {'rPmxTol','pTolPh','pWQ','distChk'};     
                    ttStr = {
                        sprintf(['the maximum ratio between the 1st ',...
                        'and 2nd ranked residual local maxima.\n %s ',...
                        'otherwise, the 1st ranked peak is no longer ',...
                        'considered the most "dominant" peak.'],a),...
                        sprintf(['max difference avg. pixel intensity ',...
                        'difference from the reference image.\n %s ',...
                        'otherwise, image is corrected by relative ',...
                        'median intensity.'],a),...
                        sprintf(['the residual image weight mask  ',...
                        'thresholding values.\n %s values approaching ',...
                        '1 will treat image pixels equally.\n %s',...
                        'lower parameter values will favour darker ',...
                        'image regions.'],a,a),...   
                        sprintf(['the inter-frame distance check ',...
                        'type.\n %s this check ensures the inter-frame ',...
                        'distance is not too large.'],a);                        
                    }; 
                
                    % sets the object type flags
                    tType = {'e','e','e','p'};
                    
            end
            
        end
            
    end
    
end
