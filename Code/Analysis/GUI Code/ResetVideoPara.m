classdef ResetVideoPara < handle
    
    % class properties
    properties
        
        % main properties
        fObj
        
        % object handles
        hFig
        hMenu
        hPanelO
        hPanelEx
        hPanelAx
        hAx
        hList
        hBut
        hEdit 
        hTxt0
        hImg
        
        % fixed object dimensions    
        dX = 10;
        dXH = 5;
        fSzP = 13;
        fSzT = 12;
        hMin
        wOfs0
        widFig
        hghtFig
        hghtPanel = 450;
        hghtPanelEx = [210,75];
        widPanelAx = 530;
        widPanelO = 240;
        widBut = 160;
        widEdit = 50;
        hghtBut = 25;
        hghtEdit = 22;
        hghtTxt = 16;
        y0Txt = 35;
        
        % other fields
        Ibg
        sFac
        sFac0
        iExpt
        nExpt
        rszImg
        expFile
        isInit = true;
        isChange = false;
        isResizing = false;
        
    end
    
    % class methods
    methods
        % --- class constructor
        function obj = ResetVideoPara(fObj)
   
            % sets the input arguments
            obj.fObj = fObj;
            
            % initialises the object properties
            obj.initClassFields();
            obj.initObjProps();
            
            % centres the figure
            setObjVisibility(obj.fObj.hFig,0)
            setObjVisibility(obj.hFig,1)
            centreFigPosition(obj.hFig,2)                        
            
        end
        
        % --------------------------------------- %
        % --- OBJECT INITIALISATION FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- initialises the class object fields
        function initClassFields(obj)
            
            % retrieves the region config structs
            obj.iExpt = 1;
            obj.nExpt = length(obj.fObj.sInfo);
            obj.Ibg = cell(obj.nExpt,1);
            obj.sFac = zeros(obj.nExpt,1);
            iMov = cellfun(@(x)(x.snTot.iMov),obj.fObj.sInfo,'un',0);
            
            % sets the             
            for i = 1:obj.nExpt        
                % retrieves the row/column limits
                [iR,iC] = deal(iMov{i}.iR,iMov{i}.iC);
                [iRT,iCT] = deal(cell2cell(iR),cell2cell(iC));
                [xL,yL] = deal([min(iCT),max(iCT)],[min(iRT),max(iRT)]);                                
                
                % sets the final 
                obj.Ibg{i} = NaN(diff(yL)+1,diff(xL)+1);
                Ibg0 = iMov{i}.Ibg{argMin(iMov{i}.vPhase)};                
                for j = 1:length(Ibg0)
                    if detMltTrkStatus(iMov{i})
                        obj.Ibg{i} = Ibg0;
                    else
                        iRL = iR{j} - (yL(1)-1);
                        iCL = iC{j} - (xL(1)-1);
                        obj.Ibg{i}(iRL,iCL) = Ibg0{j};
                    end
                end
                
                % fills in any gaps
                isN = isnan(obj.Ibg{i});
                obj.Ibg{i}(isN) = median(obj.Ibg{i}(~isN));
                
                % retrieves the experiment scale factor
                obj.sFac(i) = obj.fObj.sInfo{i}.snTot.sgP.sFac;                
            end
            
            % retrieves the other fields
            obj.sFac0 = obj.sFac;
            obj.expFile = cellfun(@(x)(x.expFile),obj.fObj.sInfo,'un',0);
            obj.hMin = sum(obj.hghtPanelEx) + 3*obj.dXH + 2*obj.dX;
            
            % calculates the other dimensions    
            obj.wOfs0 = obj.widPanelO + 2*obj.dX;
            obj.hghtFig = obj.hghtPanel + 2*obj.dX;
            obj.widFig = obj.widPanelO + obj.widPanelAx + 3*obj.dX;
            
        end
        
        % --- initialises the class object fields
        function initObjProps(obj)
            
            % deletes any previous figures
            hFigPr = findall(0,'tag','figResetPara');
            if ~isempty(hFigPr); delete(hFigPr); end
            
            % --------------------------- %
            % --- MAIN FIGURE OBJECTS --- %
            % --------------------------- %            
            
            % creates the figure object
            fPos = [100,100,obj.widFig,obj.hghtFig];
            rszFcn = {@obj.figResizeFcn};
            
            % creates the figure object
            obj.hFig = figure('Position',fPos,'tag','figResetPara',...
                              'MenuBar','None','Toolbar','None',...
                              'Name','Experiment Concatenation Info',...
                              'NumberTitle','off','Visible','off',...
                              'SizeChangedFcn',rszFcn);
                          
            % sets the class object into the figure
            setappdata(obj.hFig,'vpObj',obj)
                          
            % ------------------------- %
            % --- MENU ITEM OBJECTS --- %
            % ------------------------- %            
            
            % creates the menu items
            obj.hMenu = uimenu(obj.hFig,'Label','File','Tag','menuFile');
            uimenu(obj.hMenu,'Label','Exit','Callback',{@obj.menuExit},...
                             'Accelerator','X');                          
            
            % ------------------------------------- %
            % --- EXPERIMENT INFO PANEL OBJECTS --- %
            % ------------------------------------- %            
            
            % initialisations            
            obj.hPanelEx = cell(2,1);
            tStr = {'EXPERIMENT LIST';'EXPERIMENT PARAMETERS'};
            
            % creates the experiment combining data panel 
            pPosO = [obj.dX,obj.dX,obj.widPanelO,obj.hghtPanel];
            obj.hPanelO = uipanel(obj.hFig,'Title','','Units',...
                                       'Pixels','Position',pPosO);             
            
            % creates the experiment combining data panel
            for i = 1:length(tStr)                
                y0 = obj.hghtPanel - (i*obj.dXH + sum(obj.hghtPanelEx(1:i)));
                pPosEx = [obj.dXH,y0,pPosO(3)-obj.dX,obj.hghtPanelEx(i)];
                obj.hPanelEx{i} = uipanel(obj.hPanelO,'Title',tStr{i},'Units',...
                            'Pixels','Position',pPosEx,'FontUnits','Pixels',...
                            'FontWeight','Bold','FontSize',obj.fSzP); 
                        
                % creates the secondary objects
                switch i
                    case 1
                        % case is the experiment list
                        hP = obj.hghtPanelEx(1) - 3*obj.dX;
                        pList = [obj.dXH*[1,1],pPosEx(3)-obj.dX,hP];
                        
                        % creates the listbox object
                        cbFcn = {@obj.listExptSel};
                        obj.hList = uicontrol(obj.hPanelEx{i},'String',...
                               obj.expFile(:),'Style','list','Units',...
                               'Pixels','Callback',cbFcn,'Position',pList);
                                    
                        
                    case 2
                        % case is the experiment parameters
                        
                        % creates the label string
                        txtStr = 'Original Scale Factor: ';
                        pTxt = [obj.dX,obj.y0Txt,obj.widBut,obj.hghtTxt];
                        uicontrol(obj.hPanelEx{i},'String',txtStr,...
                                'Units','Pixels','Style','Text',...
                                'FontUnits','Pixels','FontWeight','bold',...
                                'FontSize',obj.fSzT,'Position',pTxt,...
                                'HorizontalAlignment','Right');                                
                            
                        % creates the scale factor toggle button
                        cbFcnB = {@obj.buttonScaleFac};
x                        bStr = 'Reset Scale Factor';
                        pBut = [obj.dX*[0.5,0.8],obj.widBut,obj.hghtBut];
                        obj.hBut = uicontrol(obj.hPanelEx{i},'Units',...
                                'Pixels','String',bStr,'FontUnits','Pixels',...
                                'FontWeight','bold','Callback',cbFcnB,...
                                'FontSize',obj.fSzT,'Position',pBut,...
                                'Style','PushButton');
                        
                        % creates the scale factor editbox
                        x0 = sum(pBut([1,3])) + obj.dXH;
                        sFacStr = num2str(obj.sFac(obj.iExpt));
                        cbFcnE = {@obj.editScaleFac};                        
                        pEdit = [x0,obj.dX,obj.widEdit,obj.hghtEdit];
                        obj.hEdit = uicontrol(obj.hPanelEx{i},'Style',...
                                'Edit','Units','Pixels','String',...
                                sFacStr,'Callback',cbFcnE,'tag',...
                                'editScaleFactor','Position',pEdit);
                            
                        % creates the label string
                        txtStr0 = num2str(obj.sFac(obj.iExpt));
                        pTxt0 = [x0,obj.y0Txt,obj.widEdit,obj.hghtTxt];
                        obj.hTxt0 = uicontrol(obj.hPanelEx{i},...
                                'String',txtStr,'Units','Pixels',...
                                'String',txtStr0,'FontUnits','Pixels',...
                                'FontWeight','bold','Position',pTxt0,...
                                'Style','Text','FontSize',obj.fSzT-1,...
                                'HorizontalAlignment','Center');                                                        
                end
            end            
                    
            % -------------------------------- %
            % --- IMAGE AXES PANEL OBJECTS --- %
            % -------------------------------- %            
            
            % creates the experiment combining data panel
            x0 = 2*obj.dX + obj.widPanelO;
            pPosAx = [x0,obj.dX,obj.widPanelAx,obj.hghtPanel];
            obj.hPanelAx = uipanel(obj.hFig,'Title','','Units',...
                                            'Pixels','Position',pPosAx);            
            
            % creates the image axes 
            axPos = [obj.dX*[1,1],pPosAx(3:4)-2*obj.dX];
            obj.hAx = axes(obj.hPanelAx,'Units','Pixels',...
                            'Position',axPos,'box','on');
            
            % creates the 
            obj.hImg = imagesc(obj.Ibg{1});
            set(obj.hAx,'ytick',[],'xtick',[],'xticklabel',[],...
                        'yticklabel',[],'clim',[0,255]);
            axis(obj.hAx,'normal')
                        
            % sets the axes properties
            colormap(obj.hAx,'gray');     
            
            % resets the axes dimensions
            obj.resetAxesDim()
            
            % resets the initialisation flag
            obj.isInit = false;
                        
        end
        
        % --- resets the image axes dimensions
        function resetAxesDim(obj)
            
            % retrieves the image dimensions
            szImg = size(obj.Ibg{obj.iExpt});
            axPos = get(obj.hAx,'Position');
            
            % calculates the new axes width
            obj.rszImg = szImg(2)/szImg(1);
            widNew = roundP(axPos(4)*obj.rszImg);
            dWid = widNew - axPos(3);
            set(obj.hAx,'xlim',[0,szImg(2)]+0.5,...
                        'ylim',[0,szImg(1)]+0.5);
        
            % resets the panel objects
            resetObjPos(obj.hAx,'Width',dWid,1);
            resetObjPos(obj.hPanelAx,'Width',dWid,1);
            resetObjPos(obj.hFig,'Width',dWid,1);
            
        end
        
        % -------------------------- %
        % --- CALLBACK FUNCTIONS --- %
        % -------------------------- %
        
        % --- close GUI menu item
        function menuExit(obj,~,~)
            
            % determines if there were any changes made
            if obj.isChange
                % prompts the user if they want to apply the changes
                qStr = 'Do you want to apply the changes?';
                uChoice = questdlg(qStr,'Apply Changes?','Yes','No',...
                                        'Cancel','Yes');
                switch uChoice
                    case 'Yes'
                        % if so, then reset the scale factor values
                        for i = 1:obj.nExpt
                            % retrieves the expt data struct
                            snTot = obj.fObj.sInfo{i}.snTot;
                            
                            % updates the scale factor
                            sFacPr = snTot.sgP.sFac;
                            snTot.sgP.sFac = obj.sFac(i);
                            rsFac = obj.sFac(i)/sFacPr;
                            
                            % rescales the x/y coordinates                            
                            if ~isempty(snTot.Px)
                                snTot.Px = cellfun(@(x)...
                                                (x*rsFac),snTot.Px,'un',0);
                            end
                            
                            % rescales the x/y coordinates
                            if ~isempty(snTot.Py)
                                snTot.Py = cellfun(@(x)...
                                                (x*rsFac),snTot.Py,'un',0);
                            end
                                        
                            % resets the expt data struct
                            obj.fObj.sInfo{i}.snTot = snTot;
                            obj.fObj.isChange = true;
                        end
                        
                    case 'Cancel'
                        % case is the user cancelled
                        return
                        
                end                
            end
            
            % deletes the GUI and makes the main GUI visible again
            setObjVisibility(obj.fObj.hFig,1);
            delete(obj.hFig);
            
        end
        
        % --- scale factor edit callback function
        function editScaleFac(obj,hObject,~)
           
            % determines if the new value is valid
            nwVal = str2double(get(hObject,'string'));
            if chkEditValue(nwVal,[0,100],0)
                % if so, update the relevant fields
                obj.sFac(obj.iExpt) = nwVal;
                obj.isChange = true;
                
            else
                % otherwise, reset to the previous valid value
                set(obj.hEdit,'String',num2str(obj.sFac(obj.iExpt)))
            end
                
            
        end
        
        % --- scale factor edit callback function
        function buttonScaleFac(obj,~,~)
           
            % runs the scale factor sub-GUI
            ScaleFactor(obj.hFig,'FlyAnalysis')
            
        end
        
        % --- experiment list selection callback function
        function listExptSel(obj,hObject,~)
           
            % retrieves the current             
            obj.iExpt = get(hObject,'Value');
            Inw = obj.Ibg{obj.iExpt};
            
            % resets the image dimensions and image             
            obj.resetAxesDim();
            set(obj.hImg,'cData',uint8(obj.Ibg{obj.iExpt}));
            
            % resets the colour limits
            dC = 10;
            [Imin,Imax] = deal(min(Inw(:)),max(Inw(:)));
            set(obj.hAx,'cLim',[max(0,Imin-dC),min(255,Imax+dC)]);
            
            % resets the editbox string
            set(obj.hEdit,'String',num2str(obj.sFac(obj.iExpt)));
            set(obj.hTxt0,'String',num2str(obj.sFac0(obj.iExpt)));
            
        end
        
        % --- figure resize function
        function figResizeFcn(obj,hObject,~)
            
            % exit if initialising
            if obj.isInit || obj.isResizing
                return 
            end

            % --------------------------------- %
            % --- FIGURE RESIZING DETECTION --- %
            % --------------------------------- %            
            
            % flag that the figure is being resized
            obj.isResizing = true;        
            
            % keep looping until the size stops changing
            sz0 = get(obj.hFig,'Position');
            while 1
                % pause of a short amount of time...
                pause(0.25)
                
                % determines if the figure size has changed
                sz = get(obj.hFig,'Position');
                if isequal(sz,sz0)
                    % if not, then exit the loop
                    break
                else
                    % otherwise, reset the figure size vector
                    sz0 = sz;
                end
            end
            
            % ensures the figure has a minimum height
            sz(4) = max(sz(4),obj.hMin);                
            
            % ------------------------------------ %
            % --- FIGURE OBJECT RE-POSITIONING --- %
            % ------------------------------------ %
            
            % calculates the new object dimensions
            hNew = sz(4) - 2*obj.dX;           
            hAxNew = hNew - 2*obj.dX;
            wAxNew = hAxNew*obj.rszImg;            
            
            % calculates the bottom location of the info panels
            yEx1 = hNew - (obj.dX + obj.hghtPanelEx(1));
            yEx2 = yEx1 - (obj.dX + obj.hghtPanelEx(2));
            
            % resets the experimental parameter panel
            resetObjPos(obj.hPanelO,'Height',hNew);
            resetObjPos(obj.hPanelEx{1},'Bottom',yEx1);
            resetObjPos(obj.hPanelEx{2},'Bottom',yEx2);
            
            % resets the axis panel objects
            resetObjPos(obj.hPanelAx,'Height',hNew);
            resetObjPos(obj.hPanelAx,'Width',wAxNew+2*obj.dX);
            resetObjPos(obj.hAx,'Height',hAxNew);
            resetObjPos(obj.hAx,'Width',wAxNew);
            
            % resets the figure width
            wFig = obj.wOfs0 + (wAxNew + 3*obj.dX);
            resetObjPos(obj.hFig,'Width',wFig);
            
            % flag that resizing has ended
            obj.isResizing = false;
            
        end
        
    end
    
end