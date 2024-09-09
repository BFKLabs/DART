classdef BlobCNNParaDialog < dynamicprops & handle
    
    % properties
    properties
        
        % main class fields
        pTrain
        pTrain0
        
        % object handle class fields        
        hFig
        hPanelP        
        hPanelN
        hObjN
        hPanelE
        hObjP
        hPanelT
        hCheckT
        hPanelC
        hButC
        hPanelL
        
        % fixed object dimensions
        dX = 10;
        hdrHght = 20;
        rowHght = 25;
        hghtTxt = 18;
        hghtEdit = 21; 
        hghtChk = 20;
        hghtPopup = 22;
        hghtBut = 25;
        widPanelP = 250;
        widPanelL = 350; 
        widObj = 70;
        widPopupE = 70;
        hghtPanelC = 40;
        
        % calculated object dimensions
        widFig
        hghtFig
        hghtPanel
        hghtPanelN
        hghtPanelP
        hghtPanelT        
        widPanelI
        widTxt
        widCheckT
        widButC
             
        % parameter label fields
        tStrN
        tStrP
        tStrT
        
        % scalar class fields
        nParaN
        nParaP
        nParaT
        nParaC
        
        % network graph property class fields        
        pWid
        pHght
        pOfsX
        pOfsY
        axAR
        wMax = 80;
        wOfs = 20;                
        yOfsA = [0,0.01];
        mSz = 0.0125;                        
        
        % static scalar fields
        fSz = 10 + 2/3;
        fSzL = 12;
        fSzH = 13;
        fSzG = 8;
        
        % static character fields
        tagStrG = 'hDAG';        
        tagStr = 'figParaCNN';
        bStrC = {'Reset','Update','Close'};
        algoStr = {'sgdm','rmsprop','adam'};
        imgType = {'Raw Image','X-Gradient','Y-Gradient'};        
        figName = 'Blob CNN Network Model Parameters';        
        
    end
    
    % private class properties
    properties (Access = private)
        
        objB
        
    end    
    
    % class methods
    methods
        
        % --- class constructor
        function obj = BlobCNNParaDialog(objB)
            
            % sets the input arguments
            obj.objB = objB;
        
            % initialises the class fields and objects
            obj.linkParentProps();
            obj.initClassFields();
            obj.initClassObjects();
            
        end

        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class object fields with that parent object
        function linkParentProps(obj)
            
            % parent fields strings
            fldStr = {'pCNN','sTypeCNN'};
            
            % connects the base/child objects
            for propname = fldStr
                metaprop = addprop(obj, propname{1});
                metaprop.SetMethod = @(obj, varargin) ...
                    SetDispatch(obj, propname{1}, varargin{:});
                metaprop.GetMethod = @(obj)GetDispatch(obj, propname{1});
            end
            
        end                
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % initial fields
            algoList = {'sgdm','rmsprop','adam'};
            
            % parameter strings
            obj.tStrN = {...
                'Training Batch Size','batchSize','edit',[];...
                'Network Level Count','nLvl','edit',[];...
                'Convolution Filter Size','filtSize','edit',[]};
            obj.tStrP = {...
                'Training Algorithm','algoType','popup',algoList;...                
                'Update Momentum','Momentum','edit',[];...
                'Solver Stopping Count','nCountStop','edit',[];...
                'Maximum Epoch Count','maxEpochs','edit',[]};
            obj.tStrT = {'Raw Image','X-Gradient','Y-Gradient'};

            % parameter counts
            obj.nParaN = size(obj.tStrN,1);
            obj.nParaP = size(obj.tStrP,1);
            obj.nParaT = length(obj.tStrT);
            obj.nParaC = length(obj.bStrC);
            
            % memory allocation
            obj.hObjN = cell(obj.nParaN,1);
            obj.hObjP = cell(obj.nParaP,1);
            obj.hCheckT = cell(1,obj.nParaT);
            
            % other initialisations
            obj.pTrain = copy(obj.pCNN.pTrain);
            obj.pTrain0 = copy(obj.pTrain);            
            
            % ------------------------------------- %
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- %
    
            % calculates the object widths
            obj.widPanelI = obj.widPanelP - 2*obj.dX;
            obj.widTxt = obj.widPanelI - (2*obj.dX + obj.widObj);
            obj.widCheckT = obj.widPanelI - 2*obj.dX;            
            obj.widButC = (obj.widPanelI - 2*obj.dX)/obj.nParaC;
            
            % calculated object dimensions
            hght0 = obj.hdrHght + obj.dX;
            obj.hghtPanelN = hght0 + obj.nParaN*obj.rowHght;
            obj.hghtPanelP = hght0 + obj.nParaP*obj.rowHght;
            obj.hghtPanelT = hght0 + obj.nParaT*obj.hghtChk;
            obj.hghtPanel = (obj.hghtPanelN + obj.hghtPanelP + ...
                obj.hghtPanelT + obj.hghtPanelC) + 3.5*obj.dX;
                    
            % calculates the figure dimensions
            obj.hghtFig = obj.hghtPanel + 2*obj.dX;
            obj.widFig = obj.widPanelP + obj.widPanelL + 3*obj.dX;            
            
        end
        
        % --- initialises the class fields
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
                'CloseReq',@obj.closeWindow,'WindowStyle','modal');

            % creates the network parameter panel
            pPosP = [obj.dX*[1,1],obj.widPanelP,obj.hghtPanel];
            obj.hPanelP = createUIObj('panel',obj.hFig,...
                'Title','','Position',pPosP);            

            % ---------------------------- %
            % --- CONTROL BUTTON PANEL --- %
            % ---------------------------- %
            
            % object properties
            cbFcnC = {@obj.resetPara,@obj.updatePara,@obj.closeWindow};
            
            % creates the panel object
            pPosC = [obj.dX*[1,1],obj.widPanelI,obj.hghtPanelC];
            obj.hPanelC = createUIObj('panel',obj.hPanelP,...
                'Title','','Position',pPosC);     
            
            % creates the button objects
            for i = 1:length(obj.bStrC)
                lPosB = obj.dX + (i-1)*obj.widButC;
                pPosB = [lPosB,obj.dX-2,obj.widButC,obj.hghtBut];
                obj.hButC{i} = createUIObj('pushbutton',obj.hPanelC,...
                    'Position',pPosB,'FontSize',obj.fSzL,...
                    'String',obj.bStrC{i},'FontWeight','bold',...
                    'ButtonPushedFcn',cbFcnC{i});                
            end
            
            % disables the reset button
            cellfun(@(x)(setObjEnable(x,false)),obj.hButC(1:2))
            
            % ---------------------------------- %
            % --- CLASSIFICATION IMAGE PANEL --- %
            % ---------------------------------- %            

            % object properties            
            wStrT = 'INPUT IMAGE TYPES';
            indT = setGroup(obj.pTrain.iCh(:),[obj.nParaT,1]);
            
            % creates the panel object           
            yPosT = sum(pPosC([2,4])) + obj.dX/2;
            pPosT = [obj.dX,yPosT,obj.widPanelI,obj.hghtPanelT];
            obj.hPanelT = createUIObj('panel',obj.hPanelP,...
                'FontSize',obj.fSzH,'Title',wStrT,'FontWeight','Bold',...
                'Units','Pixels','Position',pPosT);
            
            % creates the checkbox objects
            for i = 1:obj.nParaT
                % sets up the positional vector
                yPosC = (obj.dX - 2) + (i-1)*obj.hghtChk;
                pPosC = [obj.dX,yPosC,obj.widCheckT,obj.hghtChk];
                
                % creates the checkbox object
                j = obj.nParaT - (i-1);
                obj.hCheckT{j} = createUIObj('checkbox',obj.hPanelT,...
                    'FontUnits','Pixels','FontWeight','Bold',...
                    'String',obj.tStrT{j},'UserData',j,...                    
                    'Callback',@obj.checkPara,'Position',pPosC,...
                    'FontSize',obj.fSzL,'Value',indT(j));
            end
            
            % -------------------------------- %
            % --- TRAINING PARAMETER PANEL --- %
            % -------------------------------- %
            
            % object properties            
            wStrE = 'TRAINING PARAMETERS';
            
            % creates the panel object
            yPosE = sum(pPosT([2,4])) + obj.dX/2;
            pPosE = [obj.dX,yPosE,obj.widPanelI,obj.hghtPanelP];
            obj.hPanelE = createUIObj('panel',obj.hPanelP,...
                'FontSize',obj.fSzH,'Title',wStrE,'FontWeight','Bold',...
                'Units','Pixels','Position',pPosE);
            
            % creates the enumeration parameters
            for i = 1:obj.nParaP
                % sets the global index                
                j = obj.nParaP - (i - 1);
                
                % creates the object based on type
                switch obj.tStrP{i,3}
                    case 'edit'
                        % case is an edit object                
                        obj.hObjP{j} = ...
                            obj.createTextEdit(obj.hPanelE,obj.tStrP,i);
                        
                    case 'popup'
                        % case is a popup object                
                        obj.hObjP{j} = ...
                            obj.createTextPopup(obj.hPanelE,obj.tStrP,i);
                end
            end
            
            % ------------------------------- %
            % --- NETWORK PARAMETER PANEL --- %
            % ------------------------------- %
            
            % object properties
            wStrN = 'NETWORK PARAMETERS';
            
            % creates the panel object                           
            yPosN = sum(pPosE([2,4])) + obj.dX/2;
            pPosN = [obj.dX,yPosN,obj.widPanelI,obj.hghtPanelN];
            obj.hPanelN = createUIObj('panel',obj.hPanelP,...
                'FontSize',obj.fSzH,'Title',wStrN,'FontWeight','Bold',...
                'Units','Pixels','Position',pPosN);

            % creates the enumeration parameters
            for i = 1:obj.nParaN
                % sets the global index
                j = obj.nParaN - (i - 1);
                
                % creates the object based on type
                switch obj.tStrN{i,3}
                    case 'edit'
                        % case is an edit object
                        obj.hObjN{j} = ...
                            obj.createTextEdit(obj.hPanelN,obj.tStrN,i);
                        
                    case 'popupmenu'
                        % case is a popup object                        
                        obj.hObjN{j} = ...
                            obj.createTextPopup(obj.hPanelN,obj.tStrN,i);
                end
            end
            
            % ---------------------------- %
            % --- NETWORK LAYERS PANEL --- %
            % ---------------------------- %       
            
            % creates the network parameter panel
            lPosL = sum(pPosP([1,3])) + obj.dX;
            pPosL = [lPosL,obj.dX,obj.widPanelL,obj.hghtPanel];
            obj.hPanelL = createUIObj('panel',obj.hFig,...
                'Title','','Position',pPosL,'BackgroundColor',[1,1,1]);
            
            % updates the network layer graph
            obj.updateNetworkGraph();
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % sets the moment field properties
            obj.updateMomentumFieldProps();
            
            % centers and refreshes the figure
            centerfig(obj.hFig);
            refresh(obj.hFig);
            
            % makes the window visible
            setObjVisibility(obj.hFig,1);
            pause(0.05);
            drawnow
            
        end
        
        % ----------------------------------------- %
        % --- CONTROL BUTTON CALLBACK FUNCTIONS --- %
        % ----------------------------------------- %        
        
        % --- solver parameter reset button update
        function resetPara(obj, ~, ~)
            
            % prompts the user if they want to reset the parameters
            tStr = 'Reset Parameters?';
            qStr = 'Are you sure you want to reset the solver parameters?';
            uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
            
            % if the user cancelled, then exit
            if ~strcmp(uChoice,'Yes'); return; end
            
            % resets the parameter fields
            obj.pTrain = copy(obj.pTrain0);
            obj.updateNetworkGraph()
            
            % resets the network/training parameter panel objects
            hP = [obj.hPanelN,obj.hPanelE];
            for i = 1:length(hP)
                % retrieves the objects from the current panel
                hObj = [findall(hP(i),'Style','edit');...
                        findall(hP(i),'Style','popup')];
                    
                % resets the field (based on object type)
                for j = 1:length(hObj)
                    pStr = hObj(j).UserData;                    
                    switch hObj(j).Style
                        case 'edit'
                            % case is an editbox
                            hObj(j).String = num2str(obj.pTrain.(pStr));
                            
                        case 'popupmenu'
                            % case is a popupmenu
                            pList = hObj(j).String;
                            iSelP = find(strcmp(pList,obj.pTrain.(pStr)));
                            hObj(j).Value = iSelP;
                    end
                end
            end
            
            % resets the checkbox values
            B = num2cell(setGroup(obj.pTrain.iCh(:),[1,obj.nParaT]));
            cellfun(@(x,y)(set(x,'Value',y)),obj.hCheckT,B);
            
            % disables the update/reset buttons
            cellfun(@(x)(setObjEnable(x,0)),obj.hButC(1:2))
            
        end
        
        % --- update parameters button callback function
        function updatePara(obj, ~, ~)

            % if there is an existing classifier, then prompt to clear
            if ~isempty(obj.pCNN.pNet)
                % prompts the user if they want to clear the classifier
                tStr = 'Confirm Parameter Update';
                qStr = ['Are you sure you want to update the ',...
                        'network parameters? This action will ',...
                        'clear the current CNN classifier.'];
                uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
                
                % if the user cancelled, then exit the function
                if ~strcmp(uChoice,'Yes'); return; end
            end
            
            % updates the base/original training parameters
            obj.pCNN.pNet = [];
            obj.pCNN.pTrain = copy(obj.pTrain);
            obj.pTrain0 = copy(obj.pTrain);   
            
            % disables the update/reset buttons
            cellfun(@(x)(setObjEnable(x,0)),obj.hButC(1:2))

            % disables the classifier menu items            
            obj.objB.objM.setMenuItemProps(0);
            
            % resets the menu item if using current network
            if obj.sTypeCNN == 1
                % resets the type flag
                obj.sTypeCNN = 2;
                
                % resets the menu item check
                tagStrM = [obj.objB.objM.mStr0,'2'];
                hMenu = findall(obj.objB.hFig,'tag',tagStrM);
                obj.objB.objM.resetMenuCheck(hMenu);
            end
            
            
        end            

        % --- close windo button callback function
        function closeWindow(obj, ~, ~)

            % determines if there are any changes to be updated
            if strcmp(obj.hButC{2}.Enable,'on')
                % if so, prompts the user if they want to update
                tStr = 'Update Changes?';
                qStr = 'Do you want to update the parameter changes?';
                uChoice = questdlg(qStr,tStr,'Yes','No','Cancel','Yes');
                
                % performs the actions based on the user choice
                switch uChoice
                    case 'Yes'
                        % case is the chose to update
                        obj.updatePara([],[]);
                        
                    case 'Cancel'
                        % case is the user cancelled
                        return
                end
            end
            
            % deletes the dialog window
            delete(obj.hFig);

        end                

        % --------------------------------------- %
        % --- OTHER OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- numerical parameter editbox update
        function editPara(obj, hEdit, ~)
            
            % field retrieval
            pStr = hEdit.UserData;
            nwVal = str2double(hEdit.String);
            nwLim = obj.getParaLimits(pStr);            
            isInt = obj.pTrain.isInitPara(pStr);
            
            % determines if the input is valid
            if chkEditValue(nwVal,nwLim,isInt)
                % if so, then update the parameter values
                obj.pTrain.(pStr) = nwVal;
                obj.updateResetProps();
                
                % * update the parameter field
                if any(strcmp(obj.tStrN(:,2),pStr))
                    obj.updateNetworkGraph();                    
                end
                
            else
                % otherwise, reset the editbox string
                hEdit.String = num2str(obj.pTrain.(pStr));
            end
            
        end
        
        % --- numerical parameter editbox update
        function popupPara(obj, hPopup, ~)
            
            % field retrieval
            pStr = hPopup.UserData;
            
            % updates the parameter values
            obj.pTrain.(pStr) = hPopup.String{hPopup.Value};
            obj.updateResetProps();
            
            % parameter specific updates
            switch pStr
                case 'algoType'
                    % case is the algorithm type
                    obj.updateMomentumFieldProps();
            end
            
        end
        
        % --- training image checkbox update
        function checkPara(obj, hCheck, ~)
            
            % retrieves the current checkbox values
            chkVal = cellfun(@(x)(get(x,'Value')),obj.hCheckT);
            
            % determines if at least one checkbox is selected
            if any(chkVal)
                % if so, then update the parameter value and network layer
                % * update iCh parameter field
                obj.pTrain.iCh = find(chkVal);
                obj.updateNetworkGraph();
                obj.updateResetProps();
                
            else
                % otherwise, output an error message to screen
                eStr = ['At least one classification image type must ',...
                        'be selected.'];
                tStr = 'Parameter Error!';
                waitfor(msgbox(eStr,tStr,'modal'));

                % resets the checkbox value
                hCheck.Value = true;
            end
                
        end                

        % ------------------------------------- %        
        % --- NETWORK LAYER IMAGE FUNCTIONS --- %
        % ------------------------------------- %
        
        % --- updates the network layers image
        function updateNetworkGraph(obj)
           
            % deletes any previous objects on the axes
            hObjPr = findall(obj.hPanelL,'Tag',obj.tagStrG);
            if ~isempty(hObjPr); delete(hObjPr); end            

            % ------------------------- %
            % --- NETWORK DAG SETUP --- %
            % ------------------------- %
            
            % field retrieval
            xiC = obj.pTrain.iCh(:);            
            
            % sets up the input/final daq graph strings
            gStrF = {'Concat';'FCF';'SoftMax';'Output'};            
            gStrI = arrayfun(@(x)(obj.setupInputDAG(x)),xiC,'un',0);
            
            % recalculates the graph/figure dimensions
            obj.calcGraphDimensions();
            
            % calculates the coordinates of the final graph components
            pXF = (1 - obj.pWid)/2;            
            pYF = obj.pHght*length(gStrI{1}) + obj.pOfsY;            
            
            % creates the input layer graph components
            for i = 1:length(xiC)
                % sets up the directed graph
                pX0 = i*obj.pOfsX + (i-1)*obj.pWid;
                pY0 = obj.plotComponentDAG(gStrI{i},pX0,obj.pOfsY,1);
                
                % plots the arrow to the final graph components
                [xP,yP] = deal([pX0,pXF],[pY0,1-pYF]);
                hArrF = obj.createArrow(xP,yP);
                uistack(hArrF,'bottom');
            end
            
            % plots the final graph components
            obj.plotComponentDAG(gStrF,pXF,pYF,0);
            
        end
        
        % --- calculates the graph dimensions
        function calcGraphDimensions(obj)
            
            % field retrieval
            nCh = length(obj.pTrain.iCh);
            hghtP = obj.hPanelL.Position(4);
            
            % calculates the proportional width/x-offset
            widNw = (nCh+1)*obj.wOfs + nCh*obj.wMax;
            [obj.pOfsX,obj.pWid] = deal(obj.wOfs/widNw,obj.wMax/widNw);
            
            % calculates the proportional height/y-offset
            nRow = 3*(2 + obj.pTrain.nLvl);
            obj.pOfsY = obj.wOfs/hghtP; 
            obj.pHght = (1 - 2*obj.pOfsY)/(nRow-1);            
            
            % updates the figure dimensions for the graph
            dWid = widNw - obj.hPanelL.Position(3);
            resetObjPos(obj.hPanelL,'width',dWid,1);
            resetObjPos(obj.hFig,'width',dWid,1);
            
            % calculates the axes aspect ration
            obj.axAR = obj.hPanelL.Position(4)/obj.hPanelL.Position(3);            
            
        end
                
        % --- sets up the input directed graph
        function gStrI = setupInputDAG(obj,iCh)
            
            % initialisations
            inStr = {sprintf('%s',obj.imgType{iCh})};
            fcStr = {sprintf('FC%i',iCh)};
            grpStr = {sprintf('Conv2D_%i',iCh);...
                      sprintf('Relu_%i',iCh);...
                      sprintf('MaxPool_%i',iCh)};
            
            % combines the grouping components for each level
            xiG = (1:obj.pTrain.nLvl)';
            gStr0 = cell2cell(arrayfun(@(x)(cellfun(@(y)(...
                sprintf('%s%i',y,x)),grpStr,'un',0)),xiG,'un',0));
                  
            % combines the strings into a single array
            gStrI = [inStr;gStr0(:);fcStr];
            
        end
        
        % --- plots the dag for the component strings in gStr
        function yF = plotComponentDAG(obj,gStr,X0,Y0,isImg)
                        
            % memory allocation
            nG = length(gStr);
            hDAG = cell(nG,3);
            
            % sets the ellipse marker size
            mSzE = obj.mSz*[obj.axAR,1];            
            
            % other pre-calculations
            yOfsT = 0.01;
            xP = X0*[1,1];                       
                        
            % creates the objects
            for i = 1:nG                
                % sets the y-position
                yP = 1 - (Y0 + (i+[-1,0])*obj.pHght);
                
                % creates the textarrow annotation
                if i < nG
                    % creates the text arrow annotation
                    hDAG{i,1} = obj.createArrow(xP,yP+obj.yOfsA);
                end
                
                % sets up the textbox coordinates
                pT = [xP(1),yP(1)-(obj.pHght/2+yOfsT),obj.pWid,obj.pHght];
                if pT(2) < 0
                    dH = pT(2);
                    pT([2,4]) = pT([2,4]) - [1,-2]*dH;
                end
                
                % creates the text label                
                hDAG{i,2} = obj.createTextBox(pT,gStr{i});
                if ((i == 1) && isImg) || ((i == nG) && ~isImg)
                    hDAG{i,2}.FontWeight = 'Bold';
                end
                
                % creates the plot marker
                pE = [[xP(1),yP(1)]-mSzE/2,mSzE];
                hDAG{i,3} = obj.createCircle(pE);
            end
            
            % returns the final vertical location
            yF = yP(1);
                        
        end
        
        % ------------------------------------- %
        % --- ANNOTATION CREATION FUNCTIONS --- %
        % ------------------------------------- %
        
        % --- creates the arrow annotation object
        function hArr = createArrow(obj,xP,yP)
            
            % parameters
            hWid = 4;
            hLen = 4;
            
            % creates the arrow annotation
            hArr = annotation(obj.hPanelL,'arrow',...
                xP,yP,'HeadStyle','plain',...
                'HeadWidth',hWid,'HeadLength',hLen,...
                'tag',obj.tagStrG,'Units','Pixels');
            
        end        
         
        % --- creates the circle annotation object
        function hCirc = createCircle(obj,pE)
            
            % parameters
            gCol = 'r';
            
            % creates the circle annotation            
            hCirc = annotation(obj.hPanelL,'ellipse',pE,...
                'tag',obj.tagStrG,'Color',gCol,'FaceColor',gCol,...
                'Units','Pixels');
            
        end
        
        % --- creates the textbox annotation object
        function hText = createTextBox(obj,pT,gStr)
            
            hText = annotation(obj.hPanelL,'textbox',pT,'String',gStr,...
                'tag',obj.tagStrG,'FontSize',obj.fSzG,...
                'FitBoxToText','on','LineStyle','None',...
                'Units','Pixels','Interpreter','None');            
            
        end
        
        % ------------------------------- %        
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- creates the text/edit object combination
        function hEdit = createTextEdit(obj,hP,tStr,iRowN)
            
            % field retrieval
            pStr = tStr{iRowN,2};
            pLbl = sprintf('%s: ',tStr{iRowN,1});
            pValS = num2str(obj.pTrain.(pStr));
            
            % creates the text label
            yPosT = obj.dX + (iRowN-1)*obj.rowHght;
            pPosT = [obj.dX,yPosT,obj.widTxt,obj.hghtTxt];
            createUIObj('text',hP,'position',pPosT,...
                'FontUnits','Pixels','FontSize',obj.fSzL,...
                'String',pLbl,'HorizontalAlignment','right',...
                'FontWeight','Bold','UserData',pStr);
            
            % creates the editbox object
            lPosE = sum(pPosT([1,3]));
            pPosE = [lPosE,yPosT,obj.widObj,obj.hghtEdit];
            hEdit = createUIObj('edit',hP,'position',pPosE,...
                'FontSize',obj.fSz,'String',pValS,'UserData',pStr,...
                'Callback',@obj.editPara,'UserData',pStr);
            
        end
        
        % --- creates the text/popup object combination
        function hPopup = createTextPopup(obj,hP,tStr,iRowE)
            
            % field retrieval
            pStr = tStr{iRowE,2};            
            pList = tStr{iRowE,4};            
            pLbl = sprintf('%s: ',tStr{iRowE,1});
            iSelP = find(strcmp(pList,obj.pTrain.(pStr)));
            
            % creates the text label
            yPosT = obj.dX + (iRowE-1)*obj.rowHght;
            pPosT = [obj.dX,yPosT,obj.widTxt,obj.hghtTxt];
            createUIObj('text',hP,'position',pPosT,...
                'FontUnits','Pixels','FontSize',obj.fSzL,...
                'String',pLbl,'HorizontalAlignment','right',...
                'FontWeight','Bold');
            
            % creates the editbox object
            lPosP = sum(pPosT([1,3]));
            pPosP = [lPosP,yPosT,obj.widObj,obj.hghtPopup];
            hPopup = createUIObj('popup',hP,'position',pPosP,...
                'String',pList,'UserData',pStr,'FontSize',obj.fSz,...
                'Callback',@obj.popupPara,'Value',iSelP);
            
        end
        
        % --- updates the resets button properties
        function updateResetProps(obj)
            
            isParaEq = isequal(obj.pTrain,obj.pTrain0);
            cellfun(@(x)(setObjEnable(x,~isParaEq)),obj.hButC(1:2))
            
        end
        
        % --- updates the update momentum field properties
        function updateMomentumFieldProps(obj)
        
            isOn = strcmp(obj.pTrain.algoType,'sgdm');
            hObjM = findall(obj.hFig,'UserData','Momentum');
            arrayfun(@(x)(setObjEnable(x,isOn)),hObjM);
            
        end        
        
    end
    
    % static class methods
    methods (Static)
        
        % --- retrieves the numerical parameter parameter limits
        function nwLim = getParaLimits(pStr)
            
            % sets the limits based on parameter type
            switch pStr
                case 'nLvl'
                    % case is the level count
                    nwLim = [1,3];
                    
                case 'filtSize'
                    % case is the filter size
                    nwLim = [2,256];
                    
                case 'maxEpochs'
                    % case is the maximum epoch count
                    nwLim = [1,10];
                    
                case 'batchSize'
                    % case is the batch size
                    nwLim = [10,1000];
                    
                case 'nCountStop'
                    % case is the iteration stop count
                    nwLim = [1,10];
                    
                case 'Momentum'
                    % case is the update momentum
                    nwLim = [0,1];
                    
            end
            
        end
        
    end
    
    % private class methods
    methods (Access = private)
        
        % --- sets a class object field
        function SetDispatch(obj, propname, varargin)
            obj.objB.(propname) = varargin{:};
        end
        
        % --- gets a class object field
        function varargout = GetDispatch(obj, propname)
            varargout{:} = obj.objB.(propname);
        end
        
    end     
    
end