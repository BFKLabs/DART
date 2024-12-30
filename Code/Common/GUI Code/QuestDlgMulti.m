classdef QuestDlgMulti < handle
    
    % class properties
    properties
    
        % input class fields
        bStr
        mStr
        tStr
        fWid = NaN;
        
        % output class fields
        uChoice
        
        % object handles
        hFig        
        hLbl
        hButC
        hAx
        
        % fixed dimension fields
        dX = 10;
        dimAx = 50;        
        hghtBut = 23;
        hghtTxt = 16;
        widFig = 340;
        
        % calculated dimension fields        
        hghtFig
        
        % static scalar fields
        nBut
        fSz = 10 + 2/3;
        
        % static string fields
        tagStr = 'figQuestDlgMulti';
        
    end
    
    % class methods
    methods
    
        % --- class constructor
        function obj = QuestDlgMulti(bStr,mStr,tStr,fWid)
            
            % sets the input arguments
            obj.bStr = bStr;
            obj.mStr = mStr;
            obj.tStr = tStr;
            
            % sets the optional input arguments
            if exist('fWid','var')
                obj.fWid = fWid;
            end
            
            % initialises the class fields and objects
            obj.initClassFields();
            obj.initClassObjects();
            
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
           
            % field dimensioning
            obj.nBut = length(obj.bStr);
            
            % memory allocation
            obj.hButC = cell(obj.nBut,1);           
            
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
            fPos = [100*[1,1],obj.widFig,100];
            obj.hFig = figure('Position',fPos,'tag',obj.tagStr,...
                'Toolbar','None','Name',obj.tStr,'NumberTitle',...
                'off','Visible','off','Resize','off','MenuBar','None',...
                'CloseReq',@obj.forceClose,'WindowStyle','modal'); 
            
            % retrieves the figure properites
            fCol = get(obj.hFig,'Color');            
            
            % ------------------------ %
            % --- IMAGE AXES SETUP --- %
            % ------------------------ %            
            
            % creates the axes object
            pPosAx = [obj.dX*[1,1],obj.dimAx*[1,1]];
            obj.hAx = createUIObj('axes',obj.hFig,'units','pixels',...
                'position',pPosAx,'ticklength',[0,0],'ytick',[],...
                'xtick',[],'box','on');
            
            % sets up the question image (if available)
            A = load('ButtonCData.mat');
            if isfield(A.cDataStr,'IinfoBig')
                % retrieves the image (if it exists)
                Img = A.cDataStr.IinfoBig;
                sz = size(Img);
                
                % removes any dark spots within the image and replaces with white
                iGrp = cell2mat(getGroupIndex(all(Img < 220,3)));
                for i = 1:3
                    Img(iGrp+(i-1)*prod(sz(1:2))) = 255*fCol(i);
                end
                
                % shows the image within the axes object
                image(obj.hAx,Img);
            end
            
            % sets the question dialog axes properties
            set(obj.hAx,'xticklabel',[],'yticklabel',[],...
                        'xcolor',fCol,'ycolor',fCol);
            
            % ---------------------------- %
            % --- QUESTION LABEL SETUP --- %
            % ---------------------------- %
            
            % creates the text label object
            obj.hLbl = createUIObj('text',obj.hFig,'String',obj.mStr);            
            
            % -------------------------------------- %            
            % --- OBJECT DIMENSION RECALCULATION --- %
            % -------------------------------------- %
            
            % calculates/sets the figure width
            tPosL = get(obj.hLbl,'Extent');
            if isnan(obj.fWid)
                obj.widFig = sum(tPosL([1,3])) + 3*obj.dX;
            else
                obj.widFig = obj.fWid;
            end            
            
            % recalculates the axes/text position based on relative size
            y0 = 2*obj.dX + obj.hghtBut;
            obj.hghtFig = (obj.dX + y0) + max(tPosL(4),obj.dimAx);
            if obj.dimAx > tPosL(4)
                % case is the image axes is bigger                
                obj.hLbl.Position(2) = y0 + (obj.dimAx - tPosL(4))/2;
                obj.hAx.Position(2) = y0;
                
            else
                % case is the text label is bigger
                obj.hLbl.Position(2) = y0;
                obj.hAx.Position(2) = y0 + (tPosL(4) - obj.dimAx)/2;
            end
            
            % ------------------------------ %
            % --- CONTROL BUTTON OBJECTS --- %
            % ------------------------------ %
            
            % initialisations
            cbFcnB = @obj.buttonUserSelect;
            widButC = (obj.widFig - (obj.nBut+1)*obj.dX)/obj.nBut;
            
            % creates the button objects
            for i = 1:obj.nBut
                lPosB = i*obj.dX + (i-1)*widButC;
                pPosB = [lPosB,obj.dX,widButC,obj.hghtBut];
                obj.hButC{i} = createUIObj('pushbutton',obj.hFig,...
                    'Units','Pixels','Position',pPosB,...
                    'Callback',cbFcnB,'String',obj.bStr{i});
            end
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % sets the other label properties
            set(obj.hLbl,'HorizontalAlignment','Left');            
            
            % sets the position of the label 
            obj.hLbl.Position(1) = sum(pPosAx([1,3])) + obj.dX;
            obj.hLbl.Position(3:4) = tPosL(3:4);
            obj.hFig.Position([3,4]) = [obj.widFig,obj.hghtFig];
            
            % centers and refreshes the figure
            centerfig(obj.hFig);
            refresh(obj.hFig);
            
            % makes the window visible
            set(obj.hFig,'Visible','on');
            pause(0.05);
            drawnow            
            
            % places a hold on the figure
            uiwait(obj.hFig);
            
        end
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %        
        
        % --- dialog window force close callback function
        function forceClose(obj, ~, ~)
            
            % sets an empty field for the user choice
            obj.uChoice = '';
            
            % deletes the dialog window
            delete(obj.hFig);            
            
        end
        
        % --- choice button selection callback function
        function buttonUserSelect(obj, hBut, ~)
            
            % sets the user choice
            obj.uChoice = hBut.String;
            
            % deletes the dialog window
            delete(obj.hFig);
                        
        end
        
    end
    
end