classdef DARTInstallerL < handle
    
    % class properties
    properties
        
        % input arguments
        hFigM
        
        % class object handles
        hFig
        hFigS
        hButM
        jButM
        hTxtM
        hPanelM
        
        % fixed object dimensions
        dX = 10;
        butSz = 24;
        txtSz = 18;
        widBut = 34;
        hghtTxt = 22;
        widTxt = 300;
        
        % derived object dimensions        
        widFig
        hghtFig
        widPanel
        hghtPanel
        
        % other class fields
        ttStr
        bEnable
        
        % other fixed parameters
        nBut = 3;
        nFig = 2;
        txtArr = char(hex2dec('27A8'));
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = DARTInstallerL(hFigM)
            
            % sets the input arguments (if provided)
            if exist('hFigM','var'); obj.hFigM = hFigM; end
            
            % initialises the class fields and objects
            obj.initClassFields();
            obj.initClassObj();

            % centres the figurea and makes it visible
            obj.centreFigPosition();
            set(obj.hFig,'Visible','on');  
            pause(0.01)
            
            % sets the button tooltip strings
            bEnableC = num2cell(obj.bEnable);
            cellfun(@(x,y)(x.setEnabled(y)),obj.jButM,bEnableC);
            cellfun(@(x,y)(x.setToolTipText(y)),obj.jButM,obj.ttStr);            
            
        end
        
        % --------------------------------------- %
        % --- OBJECT INITIALISATION FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % memory allocation            
            obj.hFigS = cell(obj.nFig,1);
            [obj.hButM,obj.hTxtM] = deal(cell(obj.nBut,1));  
            obj.bEnable = true(obj.nBut,1);
            
            % sets the button tooltip-string
            obj.ttStr = {
                'Closes the DART Installer.';...                                
                'Installs 3rd party software used by DART.';...
                'Installs one or more versions of DART.';...
            };
            
            % calculates the width/height of the inner panel
            obj.widPanel = 3*obj.dX + obj.widBut + obj.widTxt;
            obj.hghtPanel = (obj.nBut+1)*obj.dX + obj.nBut*obj.widBut;
            
            % calculates the width/height of the figure
            obj.widFig = obj.widPanel + 2*obj.dX;
            obj.hghtFig = obj.hghtPanel + 2*obj.dX;
            
            % sets up the sub-installer objects
            obj.hFigS{1} = DARTProgInstall(obj);
            obj.hFigS{2} = ThirdPartyInstall(obj);
            
        end
        
        % --- initialises the class fields
        function initClassObj(obj)
            
            % creates the figure object
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % removes any previous GUIs
            hFigPr = findall(0,'tag','figDARTInstaller');
            if ~isempty(hFigPr); delete(hFigPr); end
            
            % makes the main gui invisible (if provided)
            if ~isempty(obj.hFigM)
                setObjVisibility(obj.hFigM,'off');
            end            
            
            % creates the figure object
            fStr = 'DART SOFTWARE SUITE INSTALLER';
            obj.hFig = figure('Position',fPos,'tag','figDARTInstaller',...
                              'MenuBar','None','Toolbar','None',...
                              'Name',fStr,'NumberTitle','off',...
                              'Visible','off','Resize','off',...
                              'CloseRequestFcn',@obj.closeFigure);
            
            % --------------------------------- %
            % --- ADD/REMOVE BUTTON OBJECTS --- %
            % --------------------------------- %
            
            % initialisations
            cbFcnB = {@obj.closeFigure,...
                      @obj.installThirdParty,...
                      @obj.installDART};
            tStrM = {'Close DART Installer',...
                     'Third Party Software Installation',...
                     'DART Program Installation'};
            lPosTM = 2*obj.dX + obj.widBut;            
                 
            % creates the inner panel object
            pPosP = [obj.dX*[1,1],obj.widPanel,obj.hghtPanel];
            obj.hPanelM = uipanel(obj.hFig,'Title','','Units','Pixel',...
                                           'Position',pPosP);            
            
                                       
            % creates the button/label objects
            for i = 1:obj.nBut
                % calculates the vertical offset
                y0 = i*obj.dX + (i-1)*obj.widBut;
                
                % creates the button object
                bPosM = [obj.dX,y0,obj.widBut*[1,1]];
                obj.hButM{i} = uicontrol(obj.hPanelM,...
                            'Style','PushButton','String',obj.txtArr,...
                            'Units','Pixels','Position',bPosM,...
                            'Callback',cbFcnB{i},'FontWeight','Bold',...
                            'FontUnits','Pixels','FontSize',obj.butSz,...
                            'HorizontalAlignment','Center');                
                
                % creates the label object
                y0 = y0 + (obj.widBut - obj.hghtTxt)/2;
                tPosM = [lPosTM,y0,obj.widTxt,obj.hghtTxt];
                obj.hTxtM{i} = uicontrol(obj.hPanelM,...
                            'Style','Text','String',tStrM{i},...
                            'Units','Pixels','Position',tPosM,...
                            'FontWeight','Bold','FontUnits','Pixels',...
                            'HorizontalAlignment','left',...
                            'FontSize',obj.txtSz);                              
            end            
            
            % retrieves the button java objects
            obj.jButM = cellfun(@(x)(findjobj(x)),obj.hButM,'un',0);            
            
            % if all installed, then disable 3rd party install button
            if ~any(~cellfun(@all,obj.hFigS{2}.isInst))
                obj.ttStr{2} = ['All 3rd party software used by DART ',...
                                'has been installed.'];                
                set(obj.hTxtM{2},'Enable','off')
                obj.jButM{2}.setEnabled(false)
                obj.bEnable(2) = false;
            end
            
            % determines if git has been installed (which enables the
            % installation of DART)
            isGit = cellfun(@(x)...
                    (find(strcmp(x,'git'))),obj.hFigS{2}.pStrS,'un',0);
            iGrp = ~cellfun(@isempty,isGit);
            if ~obj.hFigS{2}.isInst{iGrp}(isGit{iGrp}(1))
                % if not, then disable the DART installation button
                obj.ttStr{3} = ['You must install Git before being ',...
                                'able to install DART.'];  
                set(obj.hTxtM{3},'Enable','off')
                obj.bEnable(3) = false;
            end                 
                
        end        
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %        

        % --- runs the DART installer
        function installDART(obj,~,~)
            
            obj.hFigS{1}.openInstaller();
            
        end
        
        % --- runs the 3rd party software installer
        function installThirdParty(obj,~,~)

            obj.hFigS{2}.openInstaller();            
            
        end        
        
        % --- closes the installer
        function isClose = closeFigure(obj,~,~)
            
            % initialisations
            isClose = true;
            qStr = 'Are you sure you want to close the DART Installer?';            
            
            % prompts the user if they really want to close the installer
            uChoice = questdlg(qStr,'Close Installer?','Yes','No','Yes');
            if ~strcmp(uChoice,'Yes')
                isClose = false;
                return
            end 
            
            % deletes the class figure
            delete(obj.hFig)   
            
            % makes the main gui invisible (if provided)
            if ~isempty(obj.hFigM)
                setObjVisibility(obj.hFigM,'on');
            end            
            
            % deletes the sub-guis
            for i = 1:obj.nFig
                if ~obj.hFigS{i}.isInit
                    delete(obj.hFigS{i}.hFig);
                end
            end                     
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- centres the figure position to the screen's centre
        function centreFigPosition(obj)

            % global variables
            scrSz = get(0,'ScreenSize');

            % retrieves the screen and figure position
            hPos = get(obj.hFig,'position');
            p0 = [(scrSz(3)-hPos(3))/2,(scrSz(4)-hPos(4))/2];
            if ~isequal(p0,hPos(1:2))
                set(obj.hFig,'position',[p0,hPos(3:4)])
            end

        end
        
    end
    
end