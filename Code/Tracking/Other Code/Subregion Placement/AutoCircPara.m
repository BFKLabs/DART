classdef AutoCircPara < handle
    
    % properties
    properties
    
        % input argument fields
        iMov
        
        % main figure handles
        hFig
        hImg
        hProg
        
        % parameter object handles
        hPanelP
        hEditP
        
        % control button object handles
        hPanelC
        hButC
        
        % miscellaneous class fields
        hAxM
        phiC
        
        % calculated object dimension fields
        dX = 10;      
        hghtTxt = 16;
        hghtBut = 25;
        hghtEdit = 22;
        widTxtP = 180;
        hghtPanel = 40;
        widPanel = 250;
        
        % calculated object dimension fields
        hghtFig
        widFig
        widButC   
        
        % temporary class fields
        X
        Y
        R
        Rmin
        Rmax
        nGrp
        nApp
        tCol
        
        % boolean class fields
        calcOK = true;
        
        % fixed scalar fields
        pDel = 3;
        lWid = 1;
        nButC = 2;
        fSzL = 12;
        nPts = 101;
        fAlpha = 0.25;
        fSz = 10 + 2/3;
        
        % fixed string fields
        tagStr = 'figCircPara';
        figName = 'Circle Parameters';
    
    end
    
    % private class properties
    properties (Access = private)
        
        objB
        
    end     
    
    % class methods
    methods
        
        % --- class constructor
        function obj = AutoCircPara(objB,iMov,I)
            
            % sets the input arguments
            obj.objB = objB;
            obj.iMov = iMov;
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initClassObjects();
            
            % runs the automatic circle detection algorithm
            obj.runCircleDetectAlgo(I);
            
            % runs the post-detection (if successful)
            if obj.calcOK
                obj.postDetectionUpdate();
            end
            
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %        
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % field retrieval
            obj.hAxM = obj.objB.hAxM;            
            
            % other initialisations
            obj.nApp = length(obj.iMov.iR);
            obj.nGrp = length(obj.iMov.pInfo.gName);
            obj.phiC = linspace(0,2*pi,obj.nPts);
            
            % sets the group colour array (based on the format)
            if isfield(obj.iMov,'pInfo')
                obj.tCol = getAllGroupColours(obj.nGrp);
            else
                obj.tCol = getAllGroupColours(1);
            end            
            
            % retrieves the image object
            obj.hImg = findobj(get(obj.hAxM,'children'),'type','image');            
            
            % ------------------------------------- %
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- %            
            
            % calculates the figure dimensions
            obj.hghtFig = 3*obj.dX + 2*obj.hghtPanel;
            obj.widFig = 2*obj.dX + obj.widPanel;
            
            % calculates the other object dimensions
            obj.widButC = (obj.widPanel - 2.5*obj.dX)/obj.nButC;
            
        end
        
        % --- initialises the class fields
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
                'Name',obj.figName,'Resize','on','NumberTitle','off',...
                'Visible','off','AutoResizeChildren','off',...
                'Resize','off','BusyAction','Cancel',...
                'CloseRequestFcn',[]);
            
            % ------------------------------ %
            % --- CONTROL BUTTON OBJECTS --- %
            % ------------------------------ %
            
            % initialisations
            bStrC = {'Continue','Cancel'};
            cbFcnC = {@obj.buttonCont,@obj.buttonCancel};
            
            % creates the region config panel
            pPosC = [obj.dX*[1,1],obj.widPanel,obj.hghtPanel];
            obj.hPanelC = createUIObj(...
                'Panel',obj.hFig,'Position',pPosC,'Title','');
            
            % other initialisations
            obj.hButC = cell(obj.nButC,1);
            for i = 1:obj.nButC
                % sets up the button position vector
                lBut = obj.dX + (i-1)*(obj.widButC + obj.dX/2);
                bPos = [lBut,obj.dX-2,obj.widButC,obj.hghtBut]; 
                
                % creates the button object                
                obj.hButC{i} = createUIObj('Pushbutton',obj.hPanelC,...
                    'Position',bPos,'Callback',cbFcnC{i},...
                    'FontUnits','Pixels','FontSize',obj.fSzL,...
                    'FontWeight','Bold','String',bStrC{i});
            end            
            
            % -------------------------------- %
            % --- CIRCLE PARAMETER OBJECTS --- %
            % -------------------------------- %
            
            % initialisations
            cbFcnP = @obj.editCircPara;
            tStrP = 'Circle Region Radius (Pixels)';
            
            % creates the region config panel
            yPosP = sum(pPosC([2,4])) + obj.dX;
            pPosP = [obj.dX,yPosP,obj.widPanel,obj.hghtPanel];
            obj.hPanelP = createUIObj(...
                'Panel',obj.hFig,'Position',pPosP,'Title','');
                       
            % creates the editbox and set the properties
            obj.hEditP = obj.createEditGroup(obj.hPanelP,tStrP);
            set(obj.hEditP,'Callback',cbFcnP);            
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %           
            
            % centers the figure and makes it visible
            centerfig(obj.hFig);
            refresh(obj.hFig);            
            
        end
        
        % --- post-detection property updates
        function postDetectionUpdate(obj)
        
            % updates the parameter struct fields
            obj.hEditP.String = num2str(obj.R);
            
            % plots the circular regions on the main GUI axes
            obj.plotCircleRegions();            
            
            % makes the figure visible and waits for user response
            set(obj.hFig,'Visible','on');   
            figure(obj.hFig);
            uiwait(obj.hFig);            
                        
        end

        % --- creates the text label combo objects
        function hEdit = createEditGroup(obj,hP,tTxt)
            
            % initialisations
            yPos = obj.dX;
            tTxtL = sprintf('%s: ',tTxt);
            widEdit = hP.Position(3) - ((3/2)*obj.dX + obj.widTxtP);
            
            % sets up the text label
            pPosL = [obj.dX/2,yPos+2,obj.widTxtP,obj.hghtTxt];
            createUIObj('text',hP,'Position',pPosL,'FontWeight','Bold',...
                'FontSize',obj.fSzL,'HorizontalAlignment','Right',...
                'String',tTxtL);
            
            % creates the text object
            pPosE = [sum(pPosL([1,3])),yPos,widEdit,obj.hghtEdit];
            hEdit = createUIObj(...
                'edit',hP,'Position',pPosE,'FontSize',obj.fSz);
            
        end        
        
        % --------------------------------- %        
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %
        
        % --- circle parameter editbox callback function
        function editCircPara(obj, hObj, ~)
            
            % field retrieval
            nwVal = str2double(hObj.String);
            
            % determines if the new value is valid
            if chkEditValue(nwVal,[obj.Rmin,obj.Rmax],1)
                % if so, then update the parameter and circle regions
                obj.R = nwVal;
                obj.plotCircleRegions();
                
            else
                % otherwise, reset to the last valid value
                hObj.String = num2str(obj.R);
            end
                        
        end
        
        % --- continue button callback function
        function buttonCont(obj, ~, ~)
            
            % field retrieval            
            sz = size(obj.hImg.CData);
            nReg = obj.iMov.nRow*obj.iMov.nCol;
            
            % updates the sub-region data struct fields
            obj.iMov.isSet = true;
            obj.iMov.ok = true(nReg,1);
            
            % sets up the automatic detection parameters
            obj.iMov.autoP = struct('X0',obj.X,'Y0',obj.Y,...
                    'XC',cos(obj.phiC),'YC',sin(obj.phiC),'B',[],...
                    'R',obj.R*ones(size(obj.X)),'Type','Circle');
            obj.iMov.autoP.B = cell(nReg,1);   
            
            % determines lower bound of offset distance between arenas
            [dx,dy] = deal(diff(obj.X,[],2),diff(obj.Y,[],1));
            if isempty(dx)
                % case is there is only one column
                Dmin = min(dy(:));
                
            elseif isempty(dy)
                % case is there is only one row
                Dmin = min(dx(:));
                
            else
                % case is there are multiple rows and columns
                Dmin = min(min(dx(:)),min(dy(:)));
            end 
            
            % sets the maximum possible radius
            if isempty(Dmin)
                Rmx = obj.R;
            else
                Rmx = min(floor(Dmin/2)+1,obj.R);
            end
            
            % loops through each of the apparatus determining the new indices
            [nRow,nCol] = size(obj.X);
            for i = 1:nCol
                % sets the x/y coordinates of the apparatus
                [xApp,yApp] = deal(obj.X(:,i),obj.Y(:,i));
                
                % sets the new row/column indices for the current apparatus
                obj.iMov.iR{i} = roundP(max(1,min(yApp)-Rmx):...
                                        min(sz(1),max(yApp)+Rmx));
                obj.iMov.iC{i} = roundP(max(1,min(xApp)-Rmx):...
                                        min(sz(2),max(xApp)+Rmx));
                obj.iMov.iCT{i} = 1:length(obj.iMov.iC{i});
                obj.iMov.iRT{i} = cell(size(obj.X,1),1);
                
                % resets the location of the apparatus region
                obj.iMov.pos{i} = [obj.iMov.iC{i}(1),obj.iMov.iR{i}(1),...
                                   diff(obj.iMov.iC{i}([1 end])),...
                                   diff(obj.iMov.iR{i}([1 end]))];
                obj.iMov.xTube{i} = [0 obj.iMov.pos{i}(3)];
                
                % sets the sub-image binary mask
                nR = length(obj.iMov.iR{i});
                nC = length(obj.iMov.iC{i});
                obj.iMov.autoP.B{i} = false(nR,nC);
                [XB,YB] = meshgrid(1:nC,1:nR);                
                
                % loops through all of the tube regions setting the new values
                for j = 1:nRow
                    % sets the new row indices and y-coordinates for each tube
                    obj.iMov.iRT{i}{j} = roundP((...
                        yApp(j)+(-Rmx:Rmx))-(obj.iMov.iR{i}(1)-1));
                    
                    % ensures the row indices within the image frame
                    ii = (obj.iMov.iRT{i}{j}>0) & ...
                        (obj.iMov.iRT{i}{j} <= length(obj.iMov.iR{i}));
                    obj.iMov.iRT{i}{j} = obj.iMov.iRT{i}{j}(ii);
                    
                    % sets the vertical position of the tubes
                    obj.iMov.yTube{i}(j,:) = obj.iMov.iRT{i}{j}([1 end])-1;
                    
                    % sets the new search binary mask
                    D = ((XB - obj.X(j,i)+(obj.iMov.iC{i}(1)-1)).^2 + ...
                         (YB - obj.Y(j,i)+(obj.iMov.iR{i}(1)-1)).^2).^0.5;
                    obj.iMov.autoP.B{i} = obj.iMov.autoP.B{i} | (D < obj.R);
                end
            end
            
            % sets the global coordinates of the sub-image
            xMin = min(cellfun(@min,obj.iMov.iC));
            xMax = max(cellfun(@max,obj.iMov.iC));
            yMin = min(cellfun(@min,obj.iMov.iR));
            yMax = max(cellfun(@max,obj.iMov.iR));
            obj.iMov.posG = [[xMin yMin]-obj.pDel,...
                            [(xMax-xMin),(yMax-yMin)]+2*obj.pDel];            
                        
            % resets the outer region position array
            obj.iMov.posO = obj.iMov.pos;
            obj.iMov.posO{1}(1) = obj.iMov.posG(1);
            obj.iMov.posO{end}(3) = ...
                sum(obj.iMov.posG([1,3])) - obj.iMov.posO{end}(1);
                        
            % closes the window
            delete(obj.hFig)
            
        end
        
        % --- continue button callback function
        function buttonCancel(obj, ~, ~)
            
            % retrieves the main GUI handles data struct
            hOut = findall(obj.hAxM,'tag','hOuter');
            if ~isempty(hOut); delete(hOut); end
            
            % sets the user choice and closes the window
            obj.iMov = [];
            delete(obj.hFig)
            
        end    

        % ------------------------------------- %        
        % --- AUTOMATIC DETECTION FUNCTIONS --- %
        % ------------------------------------- %
        
        % --- runs the automatic region detection algorithm
        function runCircleDetectAlgo(obj,I)
            
            % runs the circle detection algorithm
            objDC = DetectCircle(I,obj.iMov);
            
            % if the calculations were successful, then update the fields
            if objDC.calcOK                
                [obj.X,obj.Y] = deal(objDC.X,objDC.Y);
                [obj.iMov,obj.R] = deal(objDC.iMov,objDC.R);                
                [obj.Rmin,obj.Rmax] = deal(objDC.Rmin,objDC.Rmax);
            end
            
        end
        
        % ------------------------------- %        
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- plots the circle regions on the main GUI
        function plotCircleRegions(obj)
            
            % sets the main axes hold on 
            hold(obj.hAxM,'on');                        
            
            % loops through all the sub-regions plotting the circles
            for iCol = 1:obj.nApp
                % sets the row indices
                if isfield(obj.iMov,'pInfo')
                    iGrp = obj.iMov.pInfo.iGrp(:,iCol);
                    iRow = find(iGrp' > 0);
                else
                    iRow = 1:obj.iMov.nTubeR(iCol);
                    iGrp = ones(length(iRow),1);
                end
                
                % creates the circle objects
                for j = iRow
                    % calculates the new coordinates and plots the circle
                    xP = obj.X(j,iCol) + obj.R*cos(obj.phiC);
                    yP = obj.Y(j,iCol) + obj.R*sin(obj.phiC);

                    % creates/updates the marker coordinates
                    uD = [iCol,j];
                    pCol = obj.tCol(iGrp(j)+1,:);
                    
                    % determines if the fill object exists
                    hFill = findall(obj.hAxM,'Tag','hOuter','UserData',uD);
                    if isempty(hFill)
                        % if not, then create a new object
                        fill(xP,yP,pCol,'tag','hOuter','UserData',uD,...
                            'FaceAlpha',obj.fAlpha,'LineWidth',obj.lWid,...
                            'Parent',obj.hAxM)
                    else
                        % otherwise, update the object coordinates
                        set(hFill,'XData',xP,'YData',yP);
                    end
                end                
            end
            
            % sets the main axes hold on 
            hold(obj.hAxM,'off');   
            
            % returns the figure to the top
            figure(obj.hFig);
            
        end
        
    end
    
end