classdef FishEyeDistort < handle
    
    % class properties
    properties
    
        % main class objects
        hFig    
        hFigM
        hPanelO
        hPanelAx
        hMenuFD
        
        % image distortion parameter objects
        hPanelP
        
        % mapping coefficient panel objects
        hPanelM
        hSliderM
        hEditM

        % image rotation panel objects
        hPanelR
        hSliderR
        hEditR      
        
        % distortion center panel objects
        hPanelC
        hEditC
        hPointC
        
        % image alignment panel objects
        hPanelA
        hRadioA
        
        % best solution panel objects
        hPanelB
        hTxtB
        hButB
        jBarB
        
        % axes panel objects
        hPanelImg
        hAx
        hImage
        
        % fixed object dimensions
        dX = 10;
        hghtTxt = 16;
        hghtGrp = 20;
        hghtRow = 25;
        hghtBut = 25;
        hghtEdit = 22;
        hghtRadio = 23;
        hghtSlider = 20;
        widPanelO = 320;
        widTxt0 = 30;
        widTxt1 = 35;
        widSlider = 150;
        widTxtC = 90;
        widTxtBL = 100;
        widAx0 = 600;      
        
        % calculated object dimensions
        hghtFig
        widFig
        hghtPanel
        hghtPanelP
        hghtPanelR
        hghtPanelD
        hghtPanelM
        hghtPanelC
        hghtPanelA
        hghtPanelB
        hghtPanelImg
        widPanel
        widPanelP
        widPanelImg
        widPanelAx        
        widEdit
        widEditC
        widRadioA
        widButB
        widTxtB
        widAxB
        hghtAx
        widAx
        
        % camera/image class fields
        I
        vObj        
        imgSz        
        
        % undistortion parameters
        pPhi
        pDist                
        mCoeff        
        hIntrinsic
        fdPara0
        
        % optimisation parameters
        pOpt        
        pBest
        pDistL
        
        % boolean class fields
        isUseFD
        isHorz = true;
        isChange = false;
        isOptPara = false;
        
        % other fixed numerical fields
        nDS
        nAx = 2;
        nTxtB = 2;
        nParaM = 2;
        nParaC = 2;
        nRadioA = 2;
        nIterOpt = 200;
        fSzL = 12;
        fSzH = 13;
        fSz = 10 + 2/3;
        ix = [1,1,2,2,1];
        iy = [1,2,2,1,1];        
        
        % parameters
        dA1 = 5;
        dPhi = 10;        
        pRng = 0.1;        
        
        % string class fields
        outView = 'valid';
        tagStr = 'hFigFishEye';
        figName = 'Fisheye Distortion Calibration';
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = FishEyeDistort(hFigM)
            
            % input arguments
            obj.hFigM = hFigM;
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initClassObjects();
            
        end

        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % hides the tracking GUI
            setObjVisibility(obj.hFigM,0);
            pause(0.05);
            
            % menu item handle/property retrieval
            obj.hMenuFD = findobj(obj.hFigM,'tag','menuUndistortImage');            
            obj.isUseFD = strcmp(obj.hMenuFD.Checked,'on');
            
            % tracking GUI field retrieval
            obj.vObj = obj.hFigM.mObj;            
            if isfield(obj.hFigM.iMov,'fdPara')
                % retrieves the original parameter struct
                obj.fdPara0 = obj.hFigM.iMov.fdPara;
                
                % uses the original image (for undistortion purposes)
                if ~isempty(obj.fdPara0) && obj.fdPara0.useFD
                    obj.hFigM.menuUndistortImage(obj.hMenuFD)
                end
            end
            
            % converts the RGB image to grayscale
            obj.I = read(obj.hFigM.mObj,obj.hFigM.iData.cFrm);
            if size(obj.I,3) == 3
                obj.I = rgb2gray(obj.I);
            end
            
            % memory allocation
            obj.hAx = zeros(obj.nAx,1);
            obj.hTxtB = cell(obj.nTxtB,1);
            obj.hEditC = cell(obj.nParaC,1);            
            [obj.hAx,obj.hImage] = deal(cell(obj.nAx,1));
            [obj.hEditM,obj.hSliderM] = deal(cell(obj.nParaM,1));
            
            % memory allocation
            obj.imgSz = zeros(1,2);
            [obj.imgSz(1),obj.imgSz(2),~] = size(obj.I);
            obj.nDS = max(ceil(obj.imgSz/2000));
            
            % retrieves the distortion parameters
            obj.getParaStructFields();
            
            % best solution data struct
            obj.pBest = struct('S',-1,'mCoeff',[],'pDist',[],'pPhi',[]);
            obj.pDistL = flip(obj.imgSz).*(0.5 + obj.pRng*[-1;1]);            
            
            % optimisation parameters
            obj.pOpt = optimoptions('simulannealbnd');
            obj.pOpt.OutputFcn = @obj.optIterFcn;
            obj.pOpt.MaxIterations = obj.nIterOpt;
            obj.pOpt.Display = 'none';
            
            % ------------------------------------------- %
            % --- CLASS OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------------- %
            
            % precalculations
            hOfs = obj.hghtGrp + obj.dX;

            % calculates the axes height/width
            iScl = intersect(obj.getDivisors(obj.imgSz(1)),...
                             obj.getDivisors(obj.imgSz(2)));
            axScl = iScl(argMin(abs(obj.imgSz(2)./iScl - obj.widAx0))); 
            obj.widAx = obj.imgSz(2)/axScl;
            obj.hghtAx = obj.imgSz(1)/axScl;

            % axes panel height/width calculations
            obj.widPanelImg = 2*obj.dX + obj.widAx;
            obj.hghtPanelImg = 3.5*obj.dX + obj.hghtAx;
            
            % information panel calculations
            obj.hghtPanelM = hOfs + obj.nParaM*obj.hghtRow;
            obj.hghtPanelC = hOfs + obj.hghtRow;
            obj.hghtPanelR = hOfs + obj.hghtRow;
            obj.hghtPanelP = hOfs + (obj.hghtPanelR + ...
                obj.hghtPanelM + obj.hghtPanelC + obj.dX);
            obj.hghtPanelA = hOfs + obj.hghtRow;
            obj.hghtPanelB = hOfs + (obj.nTxtB+1)*obj.hghtRow;
            obj.widPanel = obj.widPanelO - obj.dX;
            obj.widPanelP = obj.widPanel - obj.dX;
            obj.widAxB = obj.widPanel - 2*obj.dX;
            
            % other object dimension calculations
            obj.widEdit = obj.widPanelP - ...
                (2.5*obj.dX + obj.widTxt0 + obj.widTxt1 + obj.widSlider);
            obj.widEditC = (obj.widPanelP - ...
                (1.5*obj.dX + 2*obj.widTxtC))/obj.nParaC;
            obj.widRadioA = (obj.widPanel - 2*obj.dX)/obj.nRadioA;                     
            obj.widButB = obj.widRadioA;
            obj.widTxtB = obj.widPanel - ...
                (2*obj.dX + obj.widButB + obj.widTxtBL);
            
            % calculates the figure dimensions
            obj.resetFigureDim(false);            
            
        end       
        
        % --- initialises the class objects
        function initClassObjects(obj)
            
            % removes any previous GUIs
            hFigPr = findall(0,'tag',obj.tagStr);
            if ~isempty(hFigPr); delete(hFigPr); end    
            
            % -------------------------- %
            % --- MAIN CLASS OBJECTS --- %
            % -------------------------- %
            
            % creates the figure object
            fPos = [100*[1,1],obj.widFig,obj.hghtFig];
            obj.hFig = figure('Position',fPos,'tag',obj.tagStr,...
                'MenuBar','None','Toolbar','None','Name',obj.figName,...
                'NumberTitle','off','Visible','off','Resize','off',...
                'CloseRequestFcn',[]);             
                        
            % outer information panel
            pPosO = [obj.dX*[1,1],obj.widPanelO,obj.hghtPanel];
            obj.hPanelO = createUIObj('panel',...
                obj.hFig,'Title','','Units','Pixels','Position',pPosO);

            % ----------------------- %            
            % --- MENU ITEM SETUP --- %
            % ----------------------- %
                        
            % file menu items
            hMenuF = uimenu(obj.hFig,'Label','File','Tag','hMenuFile');            
            uimenu(hMenuF,'Label','Convert Video','Accelerator','C',...
                'Callback',@obj.menuConvertVideo);
            uimenu(hMenuF,'Label','Reset Default Parameters',...
                'Accelerator','R','Callback',@obj.menuResetDefaultPara);            
            uimenu(hMenuF,'Label','Close Window','Accelerator','X',...
                'Callback',@obj.menuCloseWindow,'Separator','on');            
            
            % ------------------------------------------ %
            % --- DISTORTION PARAMETER PANEL OBJECTS --- %
            % ------------------------------------------ %            
            
            % initialisations
            pStrP = 'DISTORTION PARAMETERS';            
            
            % parameter information panel
            yPosP = obj.hghtPanel - (obj.dX/2 + obj.hghtPanelP);
            pPosP = [obj.dX/2,yPosP,obj.widPanel,obj.hghtPanelP];
            obj.hPanelP = createUIObj('panel',obj.hPanelO,...
                'FontSize',obj.fSzH,'Title',pStrP,'Position',pPosP,...
                'FontWeight','Bold','Units','Pixels');
                                    
            % ----------------------------------------- %
            % --- MAPPING COORDINATES PANEL OBJECTS --- %
            % ----------------------------------------- %
            
            % initialisations
            pStrM = 'MAPPING COORDINATES';
            tStrM = {'A0: ','A1: '};            
            
            % mapping coordinates parameter panel
            yPosM = obj.hghtPanelP - ...
                (obj.dX/2 + obj.hghtGrp + obj.hghtPanelM);
            pPosM = [obj.dX/2,yPosM,obj.widPanelP,obj.hghtPanelM];
            obj.hPanelM = createUIObj('panel',obj.hPanelP,...
                'FontSize',obj.fSzL,'Title',pStrM,'Position',pPosM,...
                'FontWeight','Bold','Units','Pixels');

            % creates the text/editbox groupings
            for i = 1:obj.nParaM
                % object vertical offset
                j = obj.nParaM - (i-1);
                yPos0 = (obj.dX/2 + 2) + (j-1)*obj.hghtRow;
                
                % creates the text object
                xPosT = obj.dX/2;
                pPosT = [xPosT,yPos0+2,obj.widTxt0,obj.hghtTxt];
                createUIObj('text',obj.hPanelM,'Position',pPosT,...
                    'FontWeight','Bold','FontUnits','Pixels',...
                    'FontSize',obj.fSzL,'HorizontalAlignment','Right',...
                    'String',tStrM{i});
                
                % creates the slider object
                xPosS = xPosT + obj.widTxt0 + obj.dX/2;
                pPosS = [xPosS,yPos0+2,obj.widSlider,obj.hghtSlider];
                obj.hSliderM{i} = createUIObj('slider',obj.hPanelM,...
                    'Position',pPosS,'Callback',@obj.sliderMappingCoord,...
                    'Value',obj.mCoeff(i),'UserData',i);
                
                % creates the editbox
                xPosE = xPosS + obj.widSlider + obj.dX/2;
                pStrE = num2str(obj.mCoeff(i));
                pPosE = [xPosE,yPos0,obj.widEdit,obj.hghtEdit];
                obj.hEditM{i} = createUIObj('edit',obj.hPanelM,...
                    'Position',pPosE,'FontUnits','Pixels',...
                    'FontSize',obj.fSz,'UserData',i,'String',pStrE,...
                    'Callback',@obj.editMappingCoord);
                
                % sets the slider min/max values
                switch i
                    case 1
                        % case is the linear component
                        pLim = obj.mCoeff(i)*(1 + obj.pRng*[-1,1]);
                        obj.hSliderM{i}.Min = pLim(1);
                        obj.hSliderM{i}.Max = pLim(2);
                        obj.hSliderM{i}.SliderStep = [5,20]/diff(pLim);
                        
                    otherwise
                        % case is the quadratic component
                        obj.hSliderM{i}.Min = -obj.dA1;
                        obj.hSliderM{i}.Max = obj.dA1;
                        obj.hSliderM{i}.SliderStep = [0.1,0.5]/(2*obj.dA1);
                        
                        % creates the suffix string
                        xPosAx = sum(pPosE([1,3]));                        
                        pPosAx = [xPosAx,yPos0,obj.widTxt1,obj.hghtBut];
                        hAxT = createUIObj('axes',obj.hPanelM,...
                            'Position',pPosAx,'xLim',[0,1],'yLim',[0,1],...
                            'Visible','off');
                        
                        % create the text label
                        tStrAx = ' x10^{-4}';
                        text(hAxT,0,0.5,tStrAx,'FontWeight','Bold',...
                            'FontUnits','Pixels','FontSize',obj.fSzL,...
                            'HorizontalAlignment', 'left',...
                            'VerticalAlignment','middle');                 
                end                
            end            
            
            % --------------------------------------- %
            % --- DISTORTION CENTRE PANEL OBJECTS --- %
            % --------------------------------------- %            
            
            % initialisations
            yPos0 = obj.dX/2 + 3;
            pStrC = 'DISTORTION CENTRE';
            tStrC = {'X-Coordinate: ','Y-Coordinate: '};
            
            % distortion center parameter panel
            yPosC = yPosM - (obj.dX/2 + obj.hghtPanelC);
            pPosC = [obj.dX/2,yPosC,obj.widPanelP,obj.hghtPanelC];
            obj.hPanelC = createUIObj('panel',obj.hPanelP,...
                'FontSize',obj.fSzL,'Title',pStrC,'Position',pPosC,...
                'FontWeight','Bold','Units','Pixels');
            
            % creates the text/editbox groupings
            for i = 1:obj.nParaC
                % creates the text object
                xPosT = obj.dX/2 + (i-1)*(obj.widTxtC + obj.widEditC);
                pPosT = [xPosT,yPos0+2,obj.widTxtC,obj.hghtTxt];
                createUIObj('text',obj.hPanelC,'Position',pPosT,...
                    'FontWeight','Bold','FontUnits','Pixels',...
                    'FontSize',obj.fSzL,'HorizontalAlignment','Right',...
                    'String',tStrC{i});
                 
                % creates the editbox
                xPosE = xPosT + obj.widTxtC;
                pStrE = num2str(obj.pDist(i));
                pPosE = [xPosE,yPos0,obj.widEditC,obj.hghtEdit];
                obj.hEditC{i} = createUIObj('edit',obj.hPanelC,...
                    'Position',pPosE,'FontUnits','Pixels',...
                    'FontSize',obj.fSz,'UserData',i,'String',pStrE,...
                    'Callback',@obj.editDistortCentre);                            
            end

            % ------------------------------------ %
            % --- IMAGE ROTATION PANEL OBJECTS --- %
            % ------------------------------------ %            
            
            % initialisations
            yPosR0 = obj.dX/2 + 2;
            pStrR = 'IMAGE ROTATION';
            tStrR = sprintf('%s :',char(981));
            
            % mapping coordinates parameter panel
            yPosR = yPosC - (obj.dX/2 + obj.hghtPanelR);
            pPosR = [obj.dX/2,yPosR,obj.widPanelP,obj.hghtPanelR];
            obj.hPanelR = createUIObj('panel',obj.hPanelP,...
                'FontSize',obj.fSzL,'Title',pStrR,'Position',pPosR,...
                'FontWeight','Bold','Units','Pixels');
                            
            % creates the text object
            xPosRT = obj.dX/2;
            pPosRT = [xPosRT,yPos0+2,obj.widTxt0,obj.hghtTxt];
            createUIObj('text',obj.hPanelR,'Position',pPosRT,...
                'FontWeight','Bold','FontUnits','Pixels',...
                'FontSize',obj.fSzL,'HorizontalAlignment','Right',...
                'String',tStrR);

            % creates the slider object
            xPosRS = xPosRT + obj.widTxt0 + obj.dX/2;
            pPosRS = [xPosRS,yPosR0+2,obj.widSlider,obj.hghtSlider];
            obj.hSliderR = createUIObj('slider',obj.hPanelR,...
                'Position',pPosRS,'Callback',@obj.sliderRotationAngle,...
                'Value',0,'Min',-obj.dPhi,'Max',obj.dPhi,...
                'SliderStep',[0.05,0.2]/(2*obj.dPhi));
            
            % creates the editbox
            xPosRE = xPosS + obj.widSlider + obj.dX/2;
            pPosRE = [xPosRE,yPos0,obj.widEdit,obj.hghtEdit];
            obj.hEditR = createUIObj('edit',obj.hPanelR,...
                'Position',pPosRE,'FontUnits','Pixels',...
                'FontSize',obj.fSz,'UserData',i,'String','0',...
                'Callback',@obj.editRotationAngle);            
 
            % creates the suffix string
            tStrRT1 = ' Deg.';
            xPosRT1 = sum(pPosRE([1,3]));
            pPosRT1 = [xPosRT1,yPos0+2,obj.widTxt1,obj.hghtTxt];
            createUIObj('text',obj.hPanelR,'Position',pPosRT1,...
                'FontWeight','Bold','FontUnits','Pixels',...
                'FontSize',obj.fSzL,'String',tStrRT1,...
                'HorizontalAlignment','Left');            
                        
            % -------------------------------------- %
            % --- OPTIMAL SOLUTION PANEL OBJECTS --- %
            % -------------------------------------- %
            
            % initialisations            
            pStrB = 'FITNESS SCORE';
            bTypeB = {'pushbutton','togglebutton'};
            tStrB = {'Current Score: ','Best Score: '};            
            bStrB = {'Reset Best Solution','Optimise Parameters'};            
            cbFcnB = {@obj.buttonResetPara,@obj.buttonOptPara};
            
            % axes alignment panel 
            yPosB = yPosP - (obj.dX/2 + obj.hghtPanelB);
            pPosB = [obj.dX/2,yPosB,obj.widPanel,obj.hghtPanelB];
            obj.hPanelB = createUIObj('buttongroup',obj.hPanelO,...
                'FontSize',obj.fSzH,'Title',pStrB,'Position',pPosB,...
                'FontWeight','Bold','Units','Pixels');            
            
            % creates the axes object
            pPosAxB = [obj.dX*[2,1]/2,obj.widAxB,obj.hghtRow];
            obj.jBarB = javax.swing.JProgressBar(0, obj.nIterOpt);
            createJavaComponent(obj.jBarB, pPosAxB, obj.hPanelB);            
            
            % creates the text label object
            yPos0 = obj.hghtRow + obj.dX + 2;
            for i = 1:obj.nTxtB
                j = obj.nTxtB - (i-1);
                pPosTL = [obj.dX/2,yPos0+3,obj.widTxtBL,obj.hghtTxt];
                createUIObj('text',obj.hPanelB,'Position',pPosTL,...
                    'FontWeight','Bold','FontUnits','Pixels',...
                    'FontSize',obj.fSzL,'HorizontalAlignment','Right',...
                    'String',tStrB{j});

                % creates the text object
                xPosT = sum(pPosTL([1,3]));
                pPosT = [xPosT,yPos0+3,obj.widTxtB,obj.hghtTxt];
                obj.hTxtB{j} = createUIObj('text',obj.hPanelB,...
                    'FontWeight','Bold','FontUnits','Pixels',...
                    'FontSize',obj.fSzL,'HorizontalAlignment','Left',...
                    'String','','Position',pPosT);
                
                % creates the button object                
                xPosB = sum(pPosT([1,3])) + obj.dX/2;
                pPosB = [xPosB,yPos0,obj.widButB,obj.hghtBut];
                obj.hButB{j} = createUIObj(bTypeB{j},obj.hPanelB,...
                    'Position',pPosB,'FontWeight','Bold',...
                    'FontSize',obj.fSzL,'String',bStrB{j},...
                    'Callback',cbFcnB{j});
                
                % increments the vertical offset
                yPos0 = yPos0 + obj.hghtRow;
            end
            
            % disables the best solution button
            setObjEnable(obj.hButB{1},0);
            
            % ------------------------------------- %
            % --- IMAGE ALIGNMENT PANEL OBJECTS --- %
            % ------------------------------------- %
            
            % initialisations
            pStrA = 'IMAGE ALIGNMENT';
            rStrA = {'Horizontally Aligned','Vertically Aligned'};
            
            % axes alignment panel 
            yPosA = yPosB - (obj.dX/2 + obj.hghtPanelA);
            pPosA = [obj.dX/2,yPosA,obj.widPanel,obj.hghtPanelA];
            obj.hPanelA = createUIObj('buttongroup',obj.hPanelO,...
                'FontSize',obj.fSzH,'Title',pStrA,'Position',pPosA,...
                'FontWeight','Bold','Units','Pixels');
            obj.hPanelA.SelectionChangedFcn = @obj.panelAlignChanged;
                        
            % creates the radio button objects
            for i = 1:obj.nRadioA
                xPosRA = i*obj.dX + (i-1)*obj.widRadioA;
                pPosRA = [xPosRA,obj.dX/2+2,obj.widRadioA,obj.hghtRadio];
                obj.hRadioA{i} = createUIObj('radiobutton',...
                    obj.hPanelA,'FontUnits','Pixels',...
                    'String',rStrA{i},'FontSize',obj.fSzL,...
                    'FontWeight','Bold','Position',pPosRA,...
                    'Value',i==1,'UserData',i);
            end            
            
            % -------------------------------- %
            % --- IMAGE AXES PANEL OBJECTS --- %
            % -------------------------------- %  
            
            % axis titles
            tStr = {'ORIGINAL IMAGE','CONVERTED IMAGE'};
            
            % creates the otuer panel object
            xPosAx = sum(pPosO([1,3])) + obj.dX;
            pPosAx = [xPosAx,obj.dX,obj.widPanelAx,obj.hghtPanel];
            obj.hPanelAx = createUIObj('panel',...
                obj.hFig,'Title','','Units','Pixels','Position',pPosAx);
            
            % creates the image panel objects
            obj.hPanelImg = cell(obj.nAx,1);
            for i = 1:obj.nAx
                % creates the panel object
                pPosImg = [obj.dX*[1,1]/2,obj.widPanelImg,obj.hghtPanelImg];
                obj.hPanelImg{i} = createUIObj('panel',obj.hPanelAx,...
                    'Title',tStr{i},'Units','Pixels','Position',pPosImg,...
                    'FontSize',obj.fSzH,'FontWeight','Bold');           
                
                % creates the panel image axes
                obj.setupImageAxes(i);
            end
            
            % resets the plot axes orientation
            obj.resetPlotAxes()
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % centres the figure and makes it visible
            centerfig(obj.hFig);
            setObjVisibility(obj.hFig,1);
            pause(0.05);
            
        end
        
        % --- sets up the image axes for panel, iAx
        function setupImageAxes(obj,iAx)
            
            % creates the image object
            pPosAx = [obj.dX*[1,1],obj.widAx,obj.hghtAx]; 
            obj.hAx{iAx} = createUIObj('axes',obj.hPanelImg{iAx},...
                'Units','Pixels','Position',pPosAx);
            
            % sets up the image object
            obj.hImage{iAx} = imagesc(obj.hAx{iAx},obj.I);
            set(obj.hAx{iAx},'XTickLabel',[],...
                'YTickLabel',[],'TickLength',[0,0],'Box','On');
            colormap(obj.hAx{iAx},'gray');
            
            % axes dependent updates
            switch iAx
                case 1
                    % case is the original image
                    
                    % creates the distortion center marker
                    obj.hPointC = ...
                        InteractObj('point',obj.hAx{iAx},obj.pDist);                        
                    obj.hPointC.setObjMoveCallback(@obj.moveMarker);
                    obj.hPointC.setConstraintRegion(...
                        obj.pDistL(:,1),obj.pDistL(:,2));
                    
                    % plots the centre region limits
                    hold(obj.hAx{iAx},'on')
                    plot(obj.hAx{iAx},...
                        obj.pDistL(obj.ix,1),obj.pDistL(obj.iy,2),'r--');
                    hold(obj.hAx{iAx},'off')
                    
                case 2
                    % case is the undistorted image
                    
                    % turns the gridlines on
                    grid(obj.hAx{iAx},'on');
                    obj.hAx{iAx}.GridColor = 'r';
                    obj.hAx{iAx}.LineWidth = 2;
                    
                    % un-distorts the image
                    obj.updateImage();
            end
            
        end
        
        % ------------------------------------ %
        % --- MENU ITEM CALLBACK FUNCTIONS --- %
        % ------------------------------------ %        
        
        % --- convert video menu item callback function
        function menuConvertVideo(obj,varargin)

            % field retrieval
            wStr = 'Overall Progress';
            nFrm = obj.vObj.NumFrames;
            [vPath,vName] = deal(obj.vObj.Path,obj.vObj.Name);
            
            % retrieves the video file compression
            [~,~,vExtn] = fileparts(vName);
            vComp = obj.getVideoFileCompression(vExtn);                        
            
            % sets up the video file name
            t0 = obj.vObj.CurrentTime;
            obj.vObj.CurrentTime = 0;            
            vFileNw = fullfile(obj.getOutputDir(vPath),vName);            
            
            % creates the video writer object
            vObjW = VideoWriter(vFileNw,vComp);
            open(vObjW);            
            
            % converts and re-writes each video frame
            h = ProgBar(wStr,'Video Conversion');
            for i = 1:nFrm
                % updates the progressbar
                wStrNw = sprintf('%s (Frame %i of %i)',wStr,i,nFrm);
                if h.Update(1,wStrNw,i/nFrm)
                    % closes the video object and exits
                    close(vObjW)
                    delete(vFileNw);
                    obj.vObj.CurrentTime = t0;
                    return
                end                
                
                % converts and writes the video frame
                Inw = obj.undistortImage(readFrame(obj.vObj));
                writeVideo(vObjW,Inw);
            end            
            
            % house-keeping exercises
            obj.vObj.CurrentTime = t0;
            h.closeProgBar();            
            close(vObjW);
            
        end

        % --- reset default parameter menu item callback function
        function menuResetDefaultPara(obj,varargin)
            
            % resets the original default parameters
            obj.getParaStructFields(true);
            
            % resets the parameter fields
            obj.pBest.S = -1;
            obj.updateImage();
            obj.buttonResetPara();
            
        end
        
        % --- close window menu item callback function
        function menuCloseWindow(obj,varargin)

            % retrieves the current parameter struct
            fdParaNw = obj.setupParaStructFields();
            
            % determines if there has been a change in parameters
            if ~isequal(fdParaNw,obj.fdPara0)
                % if so, prompt user if they want to accept the changes
                tStr = 'Update Changes?';
                qStr = 'Do you want to update the distortion parameters?';
                uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
                
                % updates the parameter struct fields
                if strcmp(uChoice,'Yes')
                    obj.hFigM.iMov.fdPara = fdParaNw;
                end
            end            

            % enables the corresponding menu item
            setObjEnable(obj.hMenuFD,~isempty(obj.hFigM.iMov.fdPara));                        
            if ~isempty(obj.hFigM.iMov.fdPara) || obj.isUseFD  
                % enables the properties
                set(obj.hMenuFD,'Checked','off');
                obj.hFigM.menuUndistortImage(obj.hMenuFD)
            end            
            
            % shows the tracking GUI window again
            setObjVisibility(obj.hFig,0);
            setObjVisibility(obj.hFigM,1);            
            pause(0.05);            
                        
            % deletes the dialog window
            delete(obj.hFig)

        end        
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %
        
        % --- axes alignment radio button callback function
        function panelAlignChanged(obj,~,evnt)
            
            % field update
            obj.isHorz = evnt.NewValue.UserData == 1;

            % updates the figure dimensions
            obj.resetFigureDim(true);
            
        end        
        
        % --- distortion centre editbox callback function
        function editDistortCentre(obj,hEdit,~)
            
            % field retrieval
            iEdit = hEdit.UserData;
            nwVal = str2double(hEdit.String);
            nwLim = round(obj.imgSz(3-iEdit)*(0.5 + obj.pRng*[-1,1]));
            
            % determines if the new value is valid
            if chkEditValue(nwVal,nwLim)
                % updates the parameter value
                prVal = obj.pDist(iEdit);
                obj.pDist(iEdit) = nwVal;
                
                % recalculates and updates the undistorted image
                obj.recalcIntrinsics()
                
                % updates the image
                if obj.updateImage()
                    obj.hPointC.setPosition(obj.pDist);
                    return
                else
                    obj.pDist(iEdit) = prVal;
                    obj.recalcIntrinsics();
                    obj.updateImage();
                end
            end    
            
            % resets to the last valid value
            hEdit.String = num2str(obj.pDist(iEdit));            
            
        end

        % --- mapping coordinates slider callback function
        function sliderMappingCoord(obj,hSlider,~)
            
            % field retrieval
            nwVal = hSlider.Value;
            iSlider = hSlider.UserData;

            % ensures the linear component is an integer
            if iSlider == 1
                [nwVal,hSlider.Value] = deal(round(nwVal));
            end
            
            % resets the associated editbox
            prVal = obj.mCoeff(iSlider);
            obj.mCoeff(iSlider) = nwVal;
            
            % recalculates and updates the undistorted image
            obj.recalcIntrinsics()
            if obj.updateImage()            
                % if successful, then update the other objects
                obj.hEditM{iSlider}.String = num2str(nwVal);
            else
                % otherwise, reset to the previous valid value
                [hSlider.Value,obj.mCoeff(iSlider)] = deal(prVal);
                obj.hEditM{iSlider}.String = num2str(prVal);

                % resets the image
                obj.recalcIntrinsics();
                obj.updateImage();
            end
            
        end
        
        % --- mapping coordinates editbox callback function
        function editMappingCoord(obj,hEdit,~)

            % field retrieval
            iEdit = hEdit.UserData;
            nwVal = str2double(hEdit.String);
            nwLim = [obj.hSliderM{iEdit}.Min,obj.hSliderM{iEdit}.Max];
            
            % determines if the new value is valid
            if chkEditValue(nwVal,nwLim,0)
                % updates the parameter value
                prVal = obj.mCoeff(iEdit);
                obj.mCoeff(iEdit) = nwVal;
                
                % recalculates and updates the undistorted image
                obj.recalcIntrinsics()
                if obj.updateImage()
                    % if successful, then update the slider value
                    obj.hSliderM{iEdit}.Value = nwVal;
                    return
                else
                    % resets the coefficient value
                    obj.mCoeff(iEdit) = prVal;
                    
                    % recalculates and updates the undistorted image
                    obj.recalcIntrinsics()
                    obj.updateImage();
                end
            end
            
            % otherwise, reset to the last valid value
            hEdit.String = num2str(obj.mCoeff(iEdit));
            
        end
                
        % --- image rotation angle slider callback function
        function sliderRotationAngle(obj,hSlider,~)
            
            % field retrieval
            nwVal = hSlider.Value;
            
            % resets the associated editbox
            prVal = obj.pPhi;
            obj.pPhi = nwVal;
            
            % recalculates and updates the undistorted image
            if obj.updateImage()            
                % if successful, then update the other objects
                obj.hEditR.String = num2str(nwVal);
            else
                % otherwise, reset to the previous valid value
                [hSlider.Value,obj.pPhi] = deal(prVal);
                obj.hEditR.String = num2str(prVal);

                % resets the image
                obj.updateImage();
            end            
            
        end
        
        % --- image rotation angle editbox callback function
        function editRotationAngle(obj,hEdit,~)
            
            % field retrieval
            nwVal = str2double(hEdit.String);
            nwLim = [obj.hSliderR.Min,obj.hSliderR.Max];
            
            % determines if the new value is valid
            if chkEditValue(nwVal,nwLim,0)
                % updates the parameter value
                prVal = obj.pPhi;
                obj.pPhi = nwVal;
                
                % recalculates and updates the undistorted image
                if obj.updateImage()
                    % if successful, then update the slider value
                    obj.hSliderR.Value = nwVal;
                    return
                else
                    % resets the coefficient value
                    obj.pPhi = prVal;
                    
                    % recalculates and updates the undistorted image
                    obj.updateImage();
                end
            end
            
            % otherwise, reset to the last valid value
            hEdit.String = num2str(obj.pPhi);            
            
        end
        
        % --- fisheye distortion parameter optimisation callback function
        function buttonOptPara(obj,hBut,~)
            
            if obj.isOptPara
                % resets the optimisation parameters
                obj.isOptPara = false;
                set(obj.hButB{2},'Value',0);
                pause(0.01);
                
            else
                % updates the button string
                hBut.String = 'Stop Optimisation';
                pause(0.05);
            
                % field retrieval
                pB = obj.pBest;
                mMin = cellfun(@(x)(x.Min),obj.hSliderM');
                mMax = cellfun(@(x)(x.Max),obj.hSliderM');            

                % sets the initial parameters + lower/upper bounds
                X0 = [pB.mCoeff(1:2),pB.pDist,pB.pPhi];
                LB = [mMin,obj.pDistL(1,:),-obj.dPhi];
                UB = [mMax,obj.pDistL(2,:),obj.dPhi];            

                % runs the optimsation solver
                obj.isOptPara = true;
                simulannealbnd(@obj.objFunc,X0,LB,UB,obj.pOpt);
                
                % resets the button/progressbar properties
                set(obj.hButB{2},'String','Optimise Parameters','Value',0)
                obj.jBarB.setValue(0)
            end
            
        end
        
        % --- resets the best solution parameters
        function buttonResetPara(obj,varargin)
            
            % resets the best solution parameters
            obj.pPhi = obj.pBest.pPhi;            
            obj.pDist = obj.pBest.pDist;
            obj.mCoeff = obj.pBest.mCoeff;
            
            % resets the mapping coefficient fields
            for i = 1:obj.nParaM
                obj.hSliderM{i}.Value = obj.mCoeff(i);                
                obj.hEditM{i}.String = num2str(obj.mCoeff(i));
            end
            
            % resets the distortion centre coordinates
            obj.hPointC.setPosition(obj.pDist);
            for i = 1:obj.nParaC
                obj.hEditC{i}.String = num2str(obj.pDist(i));
            end
            
            % resets the rotation angle fields
            obj.hSliderR.Value = obj.pPhi;
            obj.hEditR.String = num2str(obj.pPhi);
            
            if ~isempty(varargin)
                % resets the label text colour
                obj.hTxtB{2}.ForegroundColor = 'k';
                setObjEnable(obj.hButB{1},0);

                % recalculates and updates the undistorted image
                obj.recalcIntrinsics() 
                obj.updateImage();
            end
            
        end        
        
        % --- distortion centre marker movement callback function
        function moveMarker(obj,p,varargin)
            
            % resets the distortion centre
            obj.pDist = round(p.Position);
            
            % updates the editbox values
            obj.hEditC{1}.String = num2str(obj.pDist(1));
            obj.hEditC{2}.String = num2str(obj.pDist(2));
            
            % recalculates and updates the undistorted image
            obj.recalcIntrinsics();
            obj.updateImage();
            
        end        

        % ---------------------------------------- %
        % --- PARAMETER OPTIMISATION FUNCTIONS --- %
        % ---------------------------------------- %                
                
        % --- calculates the objective function values
        function F = objFunc(obj,X)
            
            % sets the optimisation parameters
            obj.setOptPara(X);
            
            % calculates the fitness scores
            try
                Inw = obj.undistortImage(obj.I);
                F = -obj.calcFitnessScore(Inw,obj.nDS);
            catch
                F = 0;
            end
                            
        end            
        
        % --- sets the optimisation parameters from the vector, X
        function setOptPara(obj,X)
            
            % parameter update
            obj.mCoeff(1:2) = X(1:2);
            obj.pDist = round(X(3:4));
            obj.pPhi = X(5);

            % recalculates the intrinsics array
            obj.recalcIntrinsics()
                        
        end        
        
        % --- optimisation iteration callback function
        function [isStop,optVals,optChanged] = ...
                        optIterFcn(obj,~,optVals,optFlag)
            
            % Set default return values
            optChanged = false;            
            
            % 
            switch optFlag
                case 'iter'
                    % if the best solution is better, then update the gui
                    if -optVals.bestfval > obj.pBest.S
                        % if solution is better, then update fields
                        obj.pBest.S = optVals.bestfval;
                        obj.pBest.pPhi = optVals.bestx(5);
                        obj.pBest.pDist = round(optVals.bestx(3:4));
                        obj.pBest.mCoeff(1:2) = optVals.bestx(1:2);

                        % updates the image
                        obj.setOptPara(optVals.bestx);
                        obj.updateImage();                        
                        
                        % updates the best solution fields
                        obj.updateBestSolnFields();
                        obj.buttonResetPara();
                        pause(0.05)                        
                    end
            end
            
            % updates the stop flag
            isStop = ~obj.isOptPara;
            
            % pauses for a little bit (reqd to register toggle button)
            obj.jBarB.setValue(optVals.iteration)
            pause(0.01);            
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %                
        
        % --- retrieves the fish-eye parameter struct fields
        function getParaStructFields(obj,useDef)
            
            % default input arguments
            if ~exist('useDef','var')
                useDef = false;
            end
            
            if isempty(obj.fdPara0) || useDef
                % fish-eye instrinsics parameters
                obj.pPhi = 0;
                obj.pDist = [obj.imgSz(2), obj.imgSz(1)]/2;
                
                % mapping coefficients
                obj.mCoeff = zeros(1,4);
                obj.mCoeff(1:2) = [round(obj.imgSz(1)/sqrt(2)),-1];

                % recalculates the fish-eye intrinsics
                obj.recalcIntrinsics();                
               
            else
                % otherwise, retrieve the stored parameters
                obj.pPhi = obj.fdPara0.pPhi;
                obj.pDist = obj.fdPara0.pDist;
                obj.mCoeff = obj.fdPara0.mCoeff;
                obj.hIntrinsic = obj.fdPara0.hInt;
            end
            
        end
        
        % --- sets up the fish-eye distortion parameter struct
        function fdPara = setupParaStructFields(obj)
            
            % sets up the parameter struct
            fdPara = struct('mCoeff',obj.mCoeff,'pDist',obj.pDist,...
                            'pPhi',obj.pPhi,'useFD',true,...
                            'hInt',obj.hIntrinsic);
                        
            % retrieves the use parameter value
            if ~isempty(obj.fdPara0)
                fdPara.useFD = obj.fdPara0.useFD;
            end
            
        end
        
        % --- updates the un-distorted image
        function ok = updateImage(obj,I0)
            
            % default input arguments
            ok = true;
            if ~exist('Inw','var'); I0 = obj.I; end            
            
            try
                % calculates the undistorted image
                Inw = obj.undistortImage(I0);
                obj.hImage{2}.CData = imresize(Inw,obj.imgSz);
                
            catch
                % if there is an error, then output a message
                tStr = 'Invalid Configuration';
                eStr = 'The current configuration parameters are invalid';
                waitfor(msgbox(eStr,tStr,'modal'));
                
                % returns a false flag
                ok = false;
                return
            end                
                
            % calculates the fitness score
            sNw = obj.calcFitnessScore(obj.hImage{2}.CData,obj.nDS);

            % updates the fitness score object fields
            obj.hTxtB{1}.String = num2str(sNw);
            if sNw > obj.pBest.S
                % if solution is better, then update fields
                obj.pBest.S = sNw;
                obj.pBest.pPhi = obj.pPhi;
                obj.pBest.pDist = obj.pDist;
                obj.pBest.mCoeff = obj.mCoeff;
                
                % updates the best solution fields
                obj.updateBestSolnFields()
            else
                % resets the best solution text-colour
                obj.hTxtB{2}.ForegroundColor = 'k';
                setObjEnable(obj.hButB{1},sNw ~= obj.pBest.S);
            end                                
            
        end        
        
        % --- applies undistortion image to the image, I0
        function I = undistortImage(obj,I0)
            
            I = imrotate(I0,obj.pPhi,'crop');            
            I = imresize(undistortFisheyeImage(...
                I,obj.hIntrinsic,'OutputView',obj.outView),obj.imgSz);
            
        end
        
        % --- recalculates the fish-eye intrinsics
        function recalcIntrinsics(obj)
             
            mCoeffF = obj.mCoeff.*[1,1e-4,0,0];
            obj.hIntrinsic = fisheyeIntrinsics(...
                mCoeffF,obj.imgSz,obj.pDist); 
        end        
        
        % --- resets the orientation of the plot axes
        function resetPlotAxes(obj)
            
            if obj.isHorz
                % case is horizontal alignment
                obj.hPanelImg{1}.Position(2) = obj.dX/2;
                obj.hPanelImg{2}.Position(1) = obj.dX + obj.widPanelImg;
            else
                %
                obj.hPanelImg{1}.Position(2) = obj.dX + obj.hghtPanelImg;
                obj.hPanelImg{2}.Position(1) = obj.dX/2;                
            end
            
        end
        
        % --- updates the best solution fields
        function updateBestSolnFields(obj)
                        
            % resets the text label fields
            obj.hTxtB{2}.String = num2str(obj.pBest.S);
            obj.hTxtB{2}.ForegroundColor = 'r';            
            
            % resets the object fields
            setObjEnable(obj.hButB{1},0);    
            
        end        
                
        % --- recalculates figure dimensions based on image orientation
        function resetFigureDim(obj,resetObj)
                       
            % panel dimension recalculations
            obj.hghtPanel = (2 - obj.isHorz)*(obj.dX/2 + ...
                obj.hghtPanelImg) + obj.dX/2;
            obj.widPanelAx = (1 + obj.isHorz)*(obj.dX/2 + ...
                obj.widPanelImg) + obj.dX;
            
            % figure calculations
            obj.widFig = 3*obj.dX + obj.widPanelO + obj.widPanelAx;
            obj.hghtFig = 2*obj.dX + obj.hghtPanel;            
            
            % resets the object dimensions
            if resetObj                
                % calculates the change in figure dimensions
                dFigX = obj.widFig - obj.hFig.Position(3);
                dFigY = obj.hghtFig - obj.hFig.Position(4);
                obj.hFig.Position(3:4) = [obj.widFig,obj.hghtFig];
                
                % resets the panel object dimensions
                resetObjPos(obj.hPanelO,'height',dFigY,1);
                resetObjPos(obj.hPanelP,'bottom',dFigY,1);
                resetObjPos(obj.hPanelB,'bottom',dFigY,1);
                resetObjPos(obj.hPanelA,'bottom',dFigY,1);
                resetObjPos(obj.hPanelAx,'height',dFigY,1);
                resetObjPos(obj.hPanelAx,'width',dFigX,1);
                
                % resets the plot axes
                obj.resetPlotAxes();
                centerfig(obj.hFig);
            end
            
        end                
        
    end
    
    % static class methods
    methods (Static)
        
        % --- calculates the image fitness score
        function S = calcFitnessScore(I0,nDS)
            
            % parameters
            pD = 5;
            N = 10;
            xi = -90:89;
            
            % downsamples the image
            I = imresize(I0,1/nDS);
            szI = flip(size(I));
            
            % calculates the image edge horz/vert hough transforms
            BW = bwmorph(edge(I, 'sobel') & (I > 0),'dilate');
            [H,T,R] = hough(BW,'Theta',xi);
            P = houghpeaks(H,N,'Threshold',max(H(:))/3);
            L = houghlines(BW,T,R,P);
            
            % removes any points on the edge
            P1 = cell2mat(field2cell(L,'point1')');
            P2 = cell2mat(field2cell(L,'point2')');
            isOK1 = all((P1 > pD) & (P1 < (szI - pD)),2);
            isOK2 = all((P2 > pD) & (P2 < (szI - pD)),2);
            L = L(isOK1 & isOK2);
            
            %
            [TT,RR] = field2cell(L,{'theta','rho'},1);
            HH = H(sub2ind(size(H),RR-(R(1)-1),TT-(T(1)-1)));
            
            %
            xiN = 1:min(length(TT),N);
            dTT = min(90-abs(TT),abs(TT));            
            S = mean(HH(xiN)./(1+dTT(xiN)));
            
%             % calculates angle difference between horizontal/vertical lines
%             TL = abs(field2cell(L,'theta',1)); 
%             TT = min(90-TL,TL); 
%             S = mean(TT);
            
        end
        
        % --- retrieves all divisors of the integer, n
        function d = getDivisors(n)
            
            i = 1:sqrt(n);
            divs = i(rem(n, i) == 0);
            d = sort(unique([divs, n ./ divs]));
            
        end
        
        % --- calculates the search grid paramter values
        function XG = calcSearchGridPara(X,dX,ndX)
            
            XG = arr2vec(X + [(-ndX:-1),(1:ndX)]*dX);
            
        end        
        
        % --- retrieves the video file extension
        function vComp = getVideoFileCompression(vExtn)
            
            switch vExtn
                case '.mj2'
                    % case is the mj2 video type
                    vComp = 'Motion JPEG 2000';
                    
                case '.mp4'
                    % case is the MPEG-4 video type
                    vComp = 'MPEG-4';
                    
                otherwise
                    % case is the other video file type
                    vComp = 'Motion JPEG AVI';
            end
                    
        end        
        
        % --- sets up the video output path
        function vPathNw = getOutputDir(vPath0)
            
            % sets up the video output path
            vPathNw = fullfile(vPath0,'Converted');
            
            % ensures the video path exists
            if ~exist(vPathNw,'dir')
                mkdir(vPathNw)
            end
            
        end
        
    end
    
end