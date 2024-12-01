classdef GenPara < handle
    
    % class properties
    properties
        
        % class input arguments
        iMov
        x0
        y0        
        B0
        nDil
        hProg            
        
        % main figure class fields
        hFig
        hFigM
        hAxM        
        
        % parameter object class fields
        hPanelP
        hEditP
        
        % control button object class fields
        hPanelC
        hButC
        
        % fixed object dimension fields
        dX = 10;
        hghtTxt = 16;
        hghtBut = 25;
        hghtEdit = 22;
        hghtPanel = 40;
        widPanel = 260;
        widTxtP = 175;
        
        % calculated object dimension fields
        hghtFig
        widFig
        widEditP
        widButC
        
        % other important class fields
        BC
        
        % boolean class fields
        calcOK = true;
        
        % static scalar fields
        nButC = 2;
        fSzL = 12;
        fSz = 10 + 2/3;
        
        % static string fields
        tagStr = 'figGenPara';
        figName = 'General Detection Parameters';
        
    end
    
    % class methods
    methods
    
        % --- class constructor
        function obj = GenPara(iMov,B0,nDil,x0,y0,hProg)
            
            % sets the input arguments
            obj.iMov = iMov;
            obj.B0 = B0;
            obj.nDil = nDil;
            obj.x0 = x0;
            obj.y0 = y0;
            obj.hProg = hProg;            
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initClassObjects();            
            
        end

        % -------------------------------------- %        
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % object field retrieval
            obj.hFigM = findall(0,'tag','figFlyTrack');
            obj.hAxM = findall(obj.hFigM,'type','axes');

            % ------------------------------------- %
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- %
            
            % figure dimension calculations
            obj.hghtFig = 2*obj.hghtPanel + 3*obj.dX;
            obj.widFig = obj.widPanel + 2*obj.dX;
            
            % other object dimension calculations
            obj.widEditP = obj.widPanel - (2*obj.dX + obj.widTxtP);
            obj.widButC = (obj.widPanel - 2.5*obj.dX)/obj.nButC;
            
        end
        
        % --- initialises the class objects
        function initClassObjects(obj)
            
            % deletes any previous GUIs
            hPrev = findall(0,'tag',obj.tagStr);
            if ~isempty(hPrev); delete(hPrev); end
            
            % --------------------------- %
            % --- MAIN FIGURE OBJECTS --- %
            % --------------------------- %
            
            % creates the figure object
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % creates the figure object
            obj.hFig = createUIObj('figure','Position',fPos,...
                'tag',obj.tagStr,'MenuBar','None','Toolbar','None',...
                'Name',obj.figName,'NumberTitle','off','Visible','off',...
                'AutoResizeChildren','off','CloseRequestFcn',[]);
            
            % ------------------------------ %
            % --- CONTROL BUTTON OBJECTS --- %
            % ------------------------------ %
            
            % initialisations
            bStrC = {'Continue','Cancel'};
            cbFcnC = {@obj.buttonContinue,@obj.buttonCancel};
            
            % creates the control button objects
            pPosC = [obj.dX*[1,1],obj.widPanel,obj.hghtPanel];
            obj.hPanelC = createUIObj(...
                'Panel',obj.hFig,'Position',pPosC,'Title',''); 
            
            % other initialisations
            obj.hButC = cell(length(bStrC),1);
            for i = 1:length(bStrC)
                % sets up the button position vector
                lBut = obj.dX + (i-1)*(obj.widButC + obj.dX/2);
                bPos = [lBut,obj.dX-2,obj.widButC,obj.hghtBut];
                
                % creates the button object
                obj.hButC{i} = createUIObj('Pushbutton',obj.hPanelC,...
                    'Position',bPos,'Callback',cbFcnC{i},...
                    'FontUnits','Pixels','FontSize',obj.fSzL,...
                    'FontWeight','Bold','String',bStrC{i});
            end            
            
            % ------------------------------- %
            % --- PARAMETER PANEL OBJECTS --- %
            % ------------------------------- %
            
            % initialisations
            yStrS = num2str(obj.nDil);
            tStrP = 'Binary Outline Dilation (pixels)';
            
            % creates the panel object
            yPosP = sum(pPosC([2,4])) + obj.dX;
            pPosP = [obj.dX,yPosP,obj.widPanel,obj.hghtPanel];
            obj.hPanelP = createUIObj(...
                'Panel',obj.hFig,'Position',pPosP,'Title','');             
            
            % creates the label/editbox combo
            obj.hEditP = obj.createEditGroup(obj.hPanelP,tStrP);
            set(obj.hEditP,'Callback',@obj.editBinaryDil,'String',yStrS);
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % centers the figure and makes it visible
            centerfig(obj.hFig);
            refresh(obj.hFig);
            pause(0.05);
            
            % makes the figure visible
            set(obj.hFig,'Visible','on');            
            
        end
        
        %---------------------------------- %
        % --- OBJECT CREATION FUNCTIONS --- %
        %---------------------------------- %
        
        % --- creates the text label combo objects
        function hEdit = createEditGroup(obj,hP,tTxt)
            
            % initialisations
            tTxtL = sprintf('%s: ',tTxt);
            widEdit = hP.Position(3) - (2*obj.dX + obj.widTxtP);
            
            % sets up the text label
            pPosL = [obj.dX+[0,2],obj.widTxtP,obj.hghtTxt];
            createUIObj('text',hP,'Position',pPosL,'FontWeight','Bold',...
                'FontSize',obj.fSzL,'HorizontalAlignment','Right',...
                'String',tTxtL);
            
            % creates the text object
            pPosE = [sum(pPosL([1,3])),obj.dX,widEdit,obj.hghtEdit];
            hEdit = createUIObj(...
                'edit',hP,'Position',pPosE,'FontSize',obj.fSz);
            
        end        
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %        
        
        % --- continue pushbutton callback function
        function buttonContinue(obj, ~, ~)
            
            % retrieves the current binary
            obj.BC = expandBinaryMask(handles);
            
            % updates the main axes and deletes the gui
            obj.deleteTempMarkers();
            delete(obj.hFig)
            
            % makes the progressbar visible again
            obj.hProg.setVisibility(true);
            
        end
        
        % --- cancel pushbutton callback function
        function buttonCancel(obj, ~, ~)
            
            % sets an empty binary mask
            obj.BC = [];
            
            % closes the progressbar
            obj.hProg.closeProgBar();
            
            % removes the temporary markers and deletes the figure
            obj.deleteTempMarkers();
            delete(obj.hFig);
            
        end        
        
        % --- binary size editbox callback function
        function editBinaryDil(obj, hEdit, ~)
            
            % field retrieval
            nwVal = str2double(hEdit.String);
            
            % determines if the new value is valid
            if chkEditValue(nwVal,[0 20],1)
                % if so, then update the field and main axes
                obj.nDil = nwVal;
                obj.updateMainAxes();
                
            else
                % otherwise, reset to the last valid value
                hEdit.String = num2str(obj.nDil);
            end
            
        end

        % ---------------------------------- %        
        % --- MAIN AXES MARKER FUNCTIONS --- %
        % ---------------------------------- %
    
        % --- updates the main tracking GUI axes
        function updateMainAxes(obj)
            
            % retrieves the main GUI axes handle data struct
            BC0 = expandBinaryMask(handles);
            [xC,yC] = getBinaryCoords(BC0);
            
            % retrieves the object handles of the outlines
            hOut = findall(obj.hAxM,'tag','hOuter');
            createMark = isempty(hOut);
            
            % sets the group colour array (based on the format)
            if isfield(obj.iMov,'pInfo')
                tCol = getAllGroupColours(length(obj.iMov.pInfo.gName));
            else
                tCol = getAllGroupColours(1);
            end
            
            % sets the hold on the main GUI image axes
            hold(obj.hAxM,'on');
            
            % loops through all the sub-regions plotting the circles
            for iCol = 1:obj.iMov.nCol
                % sets the row indices
                if isfield(obj.iMov,'pInfo')
                    iGrp = obj.iMov.pInfo.iGrp(:,iCol);
                    iRow = find(iGrp' > 0);
                else
                    iRow = 1:obj.iMov.nTubeR(iCol);
                    iGrp = ones(length(iRow),1);
                end
                
                % retrieves the global row/column index
                for j = iRow
                    % calculates the new coordinates and plots the circle
                    uD = [iCol,j];
                    [xP,yP] = deal(obj.x0(j,iCol)+xC,obj.y0(j,iCol)+yC);
                    
                    % creates/updates the marker coordinates
                    if createMark
                        % outline marker needs to be created
                        pCol = tCol(iGrp(j)+1,:);
                        fill(xP,yP,pCol,'tag','hOuter','UserData',uD,...
                            'facealpha',0.25,'LineWidth',1.5,'Parent',hAx)
                        
                    else
                        % otherwise, coordinates of outline
                        hP = findobj(hOut,'UserData',uD);
                        set(hP,'xData',xP,'yData',yP)
                    end
                end
            end
            
            % sets the hold off again
            hold(obj.hAxM,'off');
            
        end
        
        % --- deletes the temporary markers from the main gui axes
        function deleteTempMarkers(obj)
           
            hOut = findall(obj.hAxM,'tag','hOuter');
            if ~isempty(hOut); delete(hOut); end            
            
        end

        % ------------------------------ %        
        % --- BINARY SETUP FUNCTIONS --- %
        % ------------------------------ %
        
        % --- returns the expanded binary mask
        function BCex = expandBinaryMask(obj)
            
            % field retrieval
            B = obj.B0;
            szB = size(B);
            
            % sets the binary image for calculating the region outline coordinates
            while 1
                % dilates the original image
                BCex = bwmorph(B,'dilate',obj.nDil);
                
                % determines if any points lie on the image edge
                if any(BCex(bwmorph(true(szB),'remove')))
                    % if so, then expand the image
                    B = padarray(B,[1,1]);
                    
                else
                    % otherwise, exit the loop
                    break
                end
            end
            
        end
        
    end
    
    % static class methods
    methods (Static)
        
        % --- calculates the outline coordinate fo the binary mask, BC
        function [xC,yC,pOfs] = getBinaryCoords(B)
        
            % initialisations
            szL = size(B);
            pOfs = szL([2,1])/2;
            
            % calculates the final object outline coordinates
            c = contourc(double(B),0.5*[1,1]);
            xC = roundP(c(1,2:end)' - pOfs(1));
            yC = roundP(c(2,2:end)' - pOfs(2));
            
        end
                
    end
    
end