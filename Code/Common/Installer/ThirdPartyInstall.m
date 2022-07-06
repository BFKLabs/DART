classdef ThirdPartyInstall < handle
    
    % class properties
    properties
        
        % input arguments
        objM
        
        % class object handles
        hFig
        hTabGrpS
        jTabGrpS
        hTabS
        hButS
        hTxtS
        
        % other class fields
        txtStrS
        pStrS
        isInst
        
        % fixed object dimensions
        dX = 10;        
        tSzS = 13;
        tSzC = 12;
        butSz = 24;
        hghtBut = 25;
        widButC = 185;
        hghtButC = 25;
        hghtPanelC = 40;
        hghtTxt = 18;
        widButS = 34;
        dtOfs = 20;
        
        % derived object dimensions  
        widFig
        widTxt
        hghtTab
        hghtFig
        widPanel
        hghtPanelS
        
        % other parameters
        nTab
        iTab = 1;
        nButC = 2;        
        nProg = [3,4];
        isInit = true;
        txtArr = char(hex2dec('27A8'));
        
    end
    
    % class properties
    methods
        
        % --- class constructor
        function obj = ThirdPartyInstall(objM)
            
            % sets the input arguments
            obj.objM = objM;
            
            % initialises the class fields
            obj.initClassFields();            
            
        end
                
        % --- initialises the class fields
        function initClassFields(obj)
            
            % memory allocation            
            A = arrayfun(@(x)(cell(x,1)),obj.nProg,'un',0);
            obj.nTab = length(obj.nProg);
            obj.hTabS = cell(obj.nTab,1);
            [obj.hButS,obj.hTxtS] = deal(A);
            obj.isInst = arrayfun(@(x)(false(x,1)),obj.nProg,'un',0);                       

            % sets the text label/parameter string cell arrays
            obj.txtStrS = {
                      {'GitHub CLI (Required for submitting Git Issues)',...
                       'Meld (Diff/Mergetool Application)',...
                       'Git (Required for DART version control)'},...
                      {'Java (Required for Java objects within DART)',...
                       'XPDF (Required for writing .eps/.pdf files)',...
                       'Ghostscript (Required for writing .eps/.pdf files)',...                       
                       'FFMPEG (Required for reading/writing .mp4 files)'}};        
            obj.pStrS = {{'ghcli','meld','git'},...
                         {'java','xpdf','gs','ffmpeg'}};
                                  
            % checks the program installs
            for i = 1:obj.nTab
                % determines if the program are installed
                hasURL = false(obj.nProg(i),1);                
                for j = 1:obj.nProg(i)
                    % retrieves the program URL
                    fURL = getProgInstallURL(obj.pStrS{i}{j});
                    if ~isempty(fURL)
                        % if the URL exists 
                        hasURL(j) = true;
                        obj.checkProgInstall(i,j);
                    end
                end
                
                % shapes the arrays and program counts
                obj.nProg(i) = sum(hasURL);
                obj.pStrS{i} = obj.pStrS{i}(hasURL);                
                obj.txtStrS{i} = obj.txtStrS{i}(hasURL);
            end
                     
            % panel object dimensions
            nMax = max(obj.nProg);
            obj.hghtTab = nMax*(obj.dX + obj.widButS) + obj.dX + obj.dtOfs;
            obj.hghtPanelS = 2*obj.dX + obj.hghtTab;            
            obj.widPanel = (obj.nButC+1)*obj.dX + obj.nButC*obj.widButC;
            
            % sets the figure height/width
            obj.widFig = 2*obj.dX + obj.widPanel;
            obj.hghtFig = 3*obj.dX + obj.hghtPanelC + obj.hghtPanelS; 
            
        end
        
        % --- initialises the class fields
        function initClassObj(obj)
            
            % creates the figure object
            tagStr = 'figThirdPartyInstall';
            fPos = [100,100,obj.widFig,obj.hghtFig];            
        
            % removes any previous GUIs            
            hFigPr = findall(0,'tag',tagStr);
            if ~isempty(hFigPr); delete(hFigPr); end
            
            % creates the figure object
            fStr = 'THIRD PARTY SOFTWARE INSTALLER';
            obj.hFig = figure('Position',fPos,'tag',tagStr,...
                              'MenuBar','None','Toolbar','None',...
                              'Name',fStr,'NumberTitle','off',...
                              'Visible','off','Resize','off',...
                              'CloseRequestFcn',@obj.exitInstaller);
            
            % ------------------------------ %
            % --- CONTROL BUTTON OBJECTS --- %
            % ------------------------------ %
                          
            % initialisations
            cbFcnB = {@obj.backSelect,@obj.exitInstaller};
            bStr = {'Back','Exit Installer'};
            
            % creates the control button panel
            pPosC = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelC];
            hPanelC = uipanel(obj.hFig,'Title','','Units','Pixel',...
                                       'Position',pPosC);
            
            % creates the control button objects
            for i = 1:length(bStr)
                % sets the button position vector
                lPos = obj.dX + (i-1)*(obj.dX + obj.widButC);
                bPosC = [lPos,obj.dX-2,obj.widButC,obj.hghtButC];
                
                % creates the button objects
                uicontrol(hPanelC,'Style','PushButton','String',bStr{i},...
                            'Units','Pixels','Position',bPosC,...
                            'Callback',cbFcnB{i},'FontWeight','Bold',...
                            'FontUnits','Pixels','FontSize',obj.tSzC,...
                            'HorizontalAlignment','Center');                
            end
                                   
            % ------------------------------ %
            % --- TAB GROUP OBJECT SETUP --- %
            % ------------------------------ %
            
            % initialisations
            yPosS = sum(pPosC([2,4]))+obj.dX;
            tStr = {'Git Packages','Other Software'};             
            instReqd = cellfun(@(x)(any(~x)),obj.isInst);
            
            % creates the control button panel
            pPosS = [obj.dX,yPosS,obj.widPanel,obj.hghtPanelS];
            hPanelS = uipanel(obj.hFig,'Title','','Units','Pixel',...
                                       'Position',pPosS);                        
                                   
            % creates the tab group object
            tabPos = obj.getTabPosVector(hPanelS,[5,5,-10,-5]);
            obj.hTabGrpS = obj.createTabPanelGroup(hPanelS);
            set(obj.hTabGrpS,'Position',tabPos,'tag','hTabGrpS',...
                              'SelectionChangedFcn',@obj.tabChange)            
            obj.widTxt = tabPos(3) - (3*obj.dX + obj.widButS);
                          
            % creates the tab objects
            obj.iTab = find(instReqd,1,'first');
            for i = 1:obj.nTab
                % creates the tab object
                obj.hTabS{i} = obj.createNewTab(obj.hTabGrpS,...
                                       'Title',tStr{i},'UserData',i);                  
                if obj.iTab == i
                    % set at the selected tab (if the first valid tab)                    
                    set(obj.hTabGrpS,'SelectedTab',obj.hTabS{i})
                end
            end
            
            % retrieves the 
            obj.jTabGrpS = obj.getTabGroupJavaObj(obj.hTabGrpS);
            
            % ------------------------------- %
            % --- PROGRAM INSTALL BUTTONS --- %
            % ------------------------------- %            
            
            % initialisations
            eStr = {'off','on'};
            nMax = max(obj.nProg);
            cFcnBS = @obj.runInstaller;
            lPosTM = 1.5*obj.dX + obj.widButS; 
                 
            % creates the button/text label objects for each tab
            for i = 1:obj.nTab
                % calculates the button offset
                yOfs = (nMax-obj.nProg(i))*(obj.dX + obj.widButS);                
                for j = 1:obj.nProg(i)
                    % creates the pushbutton object   
                    y0 = obj.dX + (j-1)*(obj.dX + obj.widButS) + yOfs;
                    bPosS = [obj.dX,y0,obj.widButS*[1,1]];
                    obj.hButS{i}{j} = uicontrol(obj.hTabS{i},...
                                'Style','PushButton',...
                                'Units','Pixels','Position',bPosS,...
                                'Callback',cFcnBS,'FontWeight','Bold',...
                                'FontUnits','Pixels','FontSize',obj.butSz,...
                                'String',obj.txtArr,'UserData',[i,j]);                     
                    
                    % creates the label object
                    y0 = y0 + (obj.widButS - obj.hghtTxt)/2;
                    tPosM = [lPosTM,y0,obj.widTxt,obj.hghtTxt];
                    obj.hTxtS{i}{j} = uicontrol(obj.hTabS{i},...
                                'Style','Text','String',obj.txtStrS{i}{j},...
                                'Units','Pixels','Position',tPosM,...
                                'FontWeight','Bold','FontUnits','Pixels',...
                                'HorizontalAlignment','left',...
                                'FontSize',obj.tSzS);
                            
                    % sets the button enabled properties                    
                    set(obj.hButS{i}{j},'enable',eStr{~obj.isInst{i}(j)+1})
                    set(obj.hTxtS{i}{j},'enable',eStr{~obj.isInst{i}(j)+1})
                end
                
                % sets the enabled properties of the tab
                obj.jTabGrpS.setEnabledAt(i-1,instReqd(i))
            end
            
        end            
        
        % ------------------------------------- %
        % --- INSTALLER CLASS I/O FUNCTIONS --- %
        % ------------------------------------- %
        
        % --- opens the class installer
        function openInstaller(obj)
            
            % makes the main GUI installer
            set(obj.objM.hFig,'Visible','off');
            
            % initialises the GUI objects
            if obj.isInit
                % initialises the class field/objects
                obj.initClassObj();
                
                % updates the initialisation flag
                obj.isInit = false;
            end
            
            % makes the installer object visible
            obj.centreFigPosition();
            set(obj.hFig,'Visible','on');
            
        end    
        
        % --- closes the class installer
        function backSelect(obj,~,~)
            
            % makes the main GUI installer
            set(obj.hFig,'Visible','off');            
            set(obj.objM.hFig,'Visible','on');
                        
        end  
        
        % --- exit installer callback function
        function exitInstaller(obj,~,~)
            
            % prompts the user if they want to close the installer
            obj.objM.closeFigure();
                        
        end
        
        % -------------------------------- %
        % --- OTHER CALLBACK FUNCTIONS --- %
        % -------------------------------- %        
        
        % --- runs the installer for the selected button
        function runInstaller(obj,hObj,~)
            
            % runs the program installer
            uD = get(hObj,'UserData');
            FileInstall(obj,uD(2));
            
        end
        
        % --- program tab change callback function
        function tabChange(obj,hObj,~)
            
            obj.iTab = get(get(hObj,'SelectedTab'),'UserData');
            
        end
        
        % -------------------------------------- %
        % --- PROGRAM INSTALLATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- checks if the program is installed (given by iTab/iProg)
        function checkProgInstall(obj,iTab,iProg)
                    
            % performs the install search based on operating system type
            if ispc
                % case is pc
                
                % sets the executable file and sub-search folder
                switch obj.pStrS{iTab}{iProg}
                    case 'git'
                        % case is Git
                        subDir = 'Git';
                        exFile = 'git.exe';

                    case 'ghcli'
                        % case is Github-CLI
                        subDir = 'GitHub CLI';
                        exFile = 'gh.exe';
                        
                    case 'meld'
                        % case is Meld
                        subDir = 'Meld';
                        exFile = 'Meld.exe';
                        
                    case 'ffmpeg'
                        % case is FFMPEG
                        subDir = 'ffmpeg';
                        exFile = 'ffmpeg.exe';
                        
                    case 'gs'
                        % case is Ghostscript
                        subDir = 'gs';
                        exFile = 'gswin64.exe';
                        
                    case 'xpdf'
                        % case is XPDF
                        subDir = 'Xpdf';
                        exFile = 'pdftops.exe';
                        
                    case 'java'
                        % case is Java
                        subDir = 'Java';
                        exFile = 'java.exe';

                end

                % retrieves the program file directory paths
                pfDir0 = {obj.getProgramFileDir();...
                          obj.getProgramFileDir(1)};

                % searches to see if the program is installed
                for i = 1:length(pfDir0)                
                    % sets the sub-program file directory path
                    pfDir = fullfile(pfDir0{i},subDir);
                    if exist(pfDir,'dir')
                        % runs the search function
                        sStr = sprintf('WHERE /F /R "%s" %s',pfDir,exFile); 
                        [sResult, ~] = system(sStr);

                        % if there is a match, then exit with a true value
                        if sResult == 0
                            obj.isInst{iTab}(iProg) = true;
                            return
                        end
                    end
                end     
                
            elseif ismac
                % case is macOS                
                
%                 % USE ME!
%                 [status, path] = system('find ~/Documents/geoff -name myFile.m')
            end
            
            % returns a false value for 
            obj.isInst{iTab}(iProg) = false;
            
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
    
    % static class methods
    methods (Static)        
       
        % --- retrieves the tab group position (based on the surroundin panel)
        function tabPosD = getTabPosVector(hPanel,dPos)

            % retrieves the panel position vector
            pPos = get(hPanel,'Position');

            % sets the tab position vector
            tabPosD = [[9 10],pPos(3:4)-([10 8]+10)]  - dPos;
            
        end
        
        % --- creates the tab panel group object
        function hTabG = createTabPanelGroup(hParent)

            % creates the tab group object
            hTabG = uitabgroup(); 
            drawnow; 
            pause(0.05);            
            
            % sets the object properties
            set(hTabG,'Parent',hParent,'Units','pixels');   
            
        end

        % --- wrapper function for creating a new tab
        function hTab = createNewTab(hParent,varargin)

            % creates the tab object
            hTab = uitab(hParent); 

            % determines if the input arguments are correct
            for i = 1:2:length(varargin)
                set(hTab,varargin{i},varargin{i+1})
            end

        end
        
        % --- retrieves the program files directory
        function pfDir = getProgramFileDir(is32)
        
            % initialisations
            volS = {'C','D','E','F','G'};
            if ~exist('is32','var'); is32 = false; end

            % determines the program files directory path
            for i = 1:length(volS)
                % sets the program files directory
                pfDir = sprintf('%s:\\Program Files',volS{i});
                if is32
                    % appends the suffix for the 32-bit directory
                    pfDir = sprintf('%s (x86)',pfDir);
                end

                % exits the function if the directory 
                if exist(pfDir,'dir')
                    return
                end
            end
                
        end
            
        % --- retrieves the java object handle from a tab group
        function jTab = getTabGroupJavaObj(hTabGrp)

            % removes the warnings
            wState = warning('off','all');

            % attempts to retrieves the table group java object
            cType = 'MJTabbedPane';
            jTab = findjobj(hTabGrp,'class',cType);

            % if no match was made, then return all java objects for search
            if isempty(jTab)
                % retrieves all the java objects
                [~,~,~,~,handlesAll] = findjobj(hTabGrp);

                % retrieves the tabbed pane object
                objClass = arrayfun(@(x)(class(x)),handlesAll,'un',0)';
                jTab = handlesAll(contains(objClass,cType));

                %
                if length(jTab) > 1
                    % calculates the tab object aspect ratio
                    jTabAR = zeros(length(jTab),1);
                    for i = 1:length(jTab)
                        jTabAR(i) = get(jTab(i),'Width')/...
                                    get(jTab(i),'Height');
                    end

                    % retrieves the object which is most like the tab group object 
                    hPos = get(hTabGrp,'Position');
                    jTab = jTab(argMin(abs(jTabAR - hPos(3)/hPos(4))));      
                end
            end

            % resets the warning state
            warning(wState)

        end
        
    end
    
end