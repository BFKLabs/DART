classdef AboutDARTClass < handle
    
    % class properties
    properties
        % main class properties
        hFig
        hPanelO
        hPanelL
        hTreeL
        hRootL
        hPanelD
        hEditD
        
        hAxPD
        hPanelPD        
        hTxtPD        
        hTxtC
        
        % other important fields
        mainHdr 
        fexType
        fexInfo
        
        % objects dimensions
        dX = 10;
        dXH = 5;
        txtSz = 12;
        hghtFig = 420;
        widFig = 665;
        widPanelL = 250;
        widPanelD = 380;
        widTxtL = 180;
        widTxt = 165;
        widTxtCL = 90;
        widTxtC = 255;
        hghtTxt = 16;
        hghtAx = 290;
        dHght = 20;
        
        % java objects
        jTop = javax.swing.JLabel.TOP;
        jBold = java.awt.Font.BOLD;        
        
        % URL links
        feLink = 'https://mathworks.com/matlabcentral/fileexchange/';
        umLink = 'https://undocumentedmatlab.com/';
        
    end
    
    % class methods
    methods
        % --- class constructor
        function obj = AboutDARTClass()
            
            % initialises the object properties
            obj.initClassFields();
            obj.initObjProps();
            
            % makes the main GUI visible
            setObjVisibility(obj.hFig,1);
            set(obj.hFig,'WindowStyle','modal')
            
        end
        
        % --- initialises the object class fields
        function initClassFields(obj)
            
            % explorer tree headings
            obj.mainHdr = {'Program Details','External Code References'};
            
            % sets the file exchange function/package names
            obj.fexType = {'AnDartest',...
                           'export_fig',...
                           'fzsearch',...
                           'GUI Layout Toolbox',...
                           'jheapcl',...
                           'mat2clip',...
                           'mmread',...
                           'munkres',...
                           'ProgressDialog',...
                           'uigetdir2',...
                           'xlwrite',...
                           'ColoredFieldCellRenderer',...
                           'columnlegend',...
                           'distinguishable_colors',...
                           'fastreg',...
                           'hex2rgb',...
                           'rgb2hex',...
                           'uiinspect'};
            
            % sets the file exchange information for each file type
            obj.fexInfo = cellfun(@(x)...
                        (obj.getFileExchangeInfo(x)),obj.fexType,'un',0);
            
        end
        
        % --- class object initialisation function
        function initObjProps(obj)
            
            % other initialisations
            eStr = {'off','on'};            
            
            % ---------------------------- %
            % --- MAIN FIGURE CREATION --- %
            % ---------------------------- %
            
            % creates the figure object
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % creates the figure object
            obj.hFig = figure('Position',fPos,'tag','figAboutDART',...
                              'MenuBar','None','Toolbar','None',...
                              'Name','About DART','NumberTitle','off',...
                              'Visible','off','Resize','off',...
                              'CloseRequestFcn',{@obj.closeGUI},...
                              'WindowStyle','modal');             
                          
            % creates the outer panel object
            pPosO = [obj.dX*[1,1],fPos(3:4)-2*obj.dX];            
            obj.hPanelO = uipanel(obj.hFig,'Title','','Units','Pixels',...
                                           'Position',pPosO);                          
                          
            % ------------------------ %
            % --- LIST PANEL SETUP --- %
            % ------------------------ %                        
                          
            % sets the position vectors
            pPosL = [obj.dXH*[1,1],obj.widPanelL,pPosO(4)-obj.dX];
            tPosL = [obj.dXH*[1,1],pPosL(3:4)-obj.dX];
            
            % creates the table panel
            obj.hPanelL = uipanel(obj.hPanelO,'Title','','Units','Pixels',...
                                             'Position',pPosL);
            obj.createExplorerTree(tPosL);                               
            
            % -------------------------------- %
            % --- DESCRIPTION PANELS SETUP --- %
            % -------------------------------- %            
                          
            % memory allocation
            [obj.hPanelD,obj.hEditD] = deal(cell(2,1));
            
            % sets the position vectors
            x0D = sum(pPosL([1,3])) + obj.dXH;
            pPosD = [x0D,obj.dXH,obj.widPanelD,pPosL(4)];
            
            % creates the table panel
            for i = 1:2
                % creates the panel object
                obj.hPanelD{i} = uipanel(obj.hPanelO,'Title','',...
                                    'Units','Pixels','Position',pPosD,...
                                    'Visible',eStr{1+(i==1)});
            end                        
            
            % ----------------------------- %
            % --- PROGRAM DETAILS PANEL --- %
            % ----------------------------- %
            
            % text object strings
            tStr = {'DART Hardware Developer: ','Mr. Nicolas Burczyk';...
                    'DART Software Developer: ','Dr. Richard Faville';...
                    'Head DART Project Designer: ','Dr. Benjamin Kottler';...
                    'DART Version: ','2.0'};
            obj.hTxtPD = cell(size(tStr,1),1);
            hCursor = java.awt.Cursor.getPredefinedCursor...
                                        (java.awt.Cursor.HAND_CURSOR);
                
            % creates the image logo axes object
            y0Ax = pPosD(4) - (obj.hghtAx + obj.dXH);
            axPos = [obj.dXH,y0Ax,obj.widPanelD-obj.dX,obj.hghtAx];
            obj.hAxPD = axes(obj.hPanelD{1},'Units','Pixels',...
                                        'Position',axPos,'Visible','on');
            obj.setupLogoAxes();
                                        
            % creates the text label panel
            hghtPD = axPos(2) - obj.dX;
            pPosPD = [obj.dXH*[1,1],obj.widPanelD-obj.dX,hghtPD];
            obj.hPanelPD = uipanel(obj.hPanelD{1},'Title','','Units',...
                                   'Pixels','Position',pPosPD);
            
            % creates the text label objects
            for i = 1:size(tStr,1)
                % sets the vertical location of the text objects
                y0D = obj.dXH + (i-1)*obj.dHght;
                
                % creates the label text object
                pPosL = [obj.dXH,y0D,obj.widTxtL,obj.hghtTxt];
                uicontrol(obj.hPanelPD,'Style','text','Position',pPosL,...
                            'FontWeight','Bold','FontUnits','Pixels',...
                            'FontSize',obj.txtSz,'String',tStr{i,1},...
                            'HorizontalAlignment','right');
                
                % creates the information text object
                pPosL = [obj.dXH+obj.widTxtL,y0D,obj.widTxt,obj.hghtTxt];
                uicontrol(obj.hPanelPD,'Style','text','Position',pPosL,...
                            'FontWeight','Bold','FontUnits','Pixels',...
                            'FontSize',obj.txtSz,'String',tStr{i,2},...
                            'HorizontalAlignment','left');                        
                        
            end
            
            % ------------------------------------- %
            % --- EXTERNAL CODE REFERENCE PANEL --- %
            % ------------------------------------- %            
                      
            % sets the text strings            
            tStr = {'Package Title','fType';...
                    'Type','Type';...
                    'Author','Author';...
                    'Date','Date';...
                    'Address','URL';...
                    'Repository','Repo';...
                    'Description','Desc'};
            
            % other initialisations
            fName = 'MS Sans Serif';
            obj.hTxtC = cell(size(tStr,1),1);
            bgCol = javax.swing.plaf.ColorUIResource(1,1,1);
            set(obj.hPanelD{2},'BackgroundColor',[1,1,1]);
            
            % creates the external code reference text label objects
            for i = 1:size(tStr,1)
                % sets the bottom location of the text object
                y0C = pPosD(4) - (3*obj.dXH + i*obj.hghtTxt + (i-1)*obj.dX);
                
                % creates the label text object
                tStrF = sprintf('%s :',tStr{i,1});
                pPosC = [obj.dXH,y0C,obj.widTxtCL,obj.hghtTxt];
                uicontrol(obj.hPanelD{2},'Style','text','Position',pPosC,...
                            'FontWeight','Bold','FontUnits','Pixels',...
                            'FontSize',obj.txtSz,'String',tStrF,...
                            'HorizontalAlignment','right',...
                            'BackgroundColor',[1,1,1]);
                
                % sets up the text labels
                if strcmp(tStr{i,2},'Desc')
                    % case is the description label
                    [dy0C,y0C] = deal(y0C-obj.dX,obj.dX);
                    hghtTxtNw = obj.hghtTxt + dy0C;
                else
                    % otherwise, case is the other labels
                    hghtTxtNw = obj.hghtTxt;
                end
                        
                % creates the information text object
                pPosC = [obj.dX+obj.widTxtCL,y0C+1,obj.widTxtC,hghtTxtNw];
                jLabel = javaObjectEDT('javax.swing.JLabel', '');
                [hjLabel,~] = javacomponent(jLabel,pPosC,obj.hPanelD{2});
                    
                % updates the label java object properties
                switch tStr{i,2}
                    case {'URL','Repo'}
                        hjLabel.setCursor(hCursor)
                        
                    case 'Desc'
                        jLabel.setVerticalAlignment(obj.jTop);
                        jLabel.setVerticalTextPosition(obj.jTop);                        
                end
                
                % sets the text font                
                newFont = java.awt.Font(fName,obj.jBold,obj.txtSz);  % font name, style, size
                hjLabel.setFont(newFont)
                hjLabel.setBackground(bgCol);
                
                % updates the other object fields
                obj.hTxtC{i} = hjLabel;
                setappdata(obj.hTxtC{i},'UserData',tStr{i,2})
            end          
            
        end
        
        % --- initialises the logo axes object
        function setupLogoAxes(obj)
            
            % sets the button c-data values
            cdFile = 'ButtonCData.mat';
            if ~exist(cdFile,'file')
                cdFile = [];
            end
            
            % sets the DART logo (if available)
            if ~isempty(cdFile)
                A = load(cdFile);    
                image(A.cDataStr.Ilogo,'parent',obj.hAxPD)
                set(obj.hAxPD,'xtick',[],'xticklabel',[],...
                              'ytick',[],'yticklabel',[])
                axis(obj.hAxPD,'equal')
            end            
            
        end
        
        % --- creates the explorer tree
        function createExplorerTree(obj, tPosL)
            
            % initialisations
            rStr = 'About...';
            nStr = obj.mainHdr;
            
            % Root node creation
            obj.hRootL = createUITreeNode(rStr, rStr, [], false);
            set(0,'CurrentFigure',obj.hFig);
            
            % creates the program description node
            obj.hRootL.add(createUITreeNode(nStr{1},nStr{1},[],true));
            
            % creates the file description node
            hNodeD = createUITreeNode(nStr{2},nStr{2},[],false);
            obj.hRootL.add(hNodeD);
            
            % adds the file description nodes to the tree
            for i = 1:length(obj.fexType)
                dStr = obj.fexType{i};
                hNodeL = createUITreeNode(dStr,dStr,[],true);
                hNodeL.setUserObject(i);
                hNodeD.add(hNodeL)
            end
            
            % creates the tree object
            wState = warning('off','all');
            [obj.hTreeL,hC] = uitree('v0','Root',obj.hRootL,'position',...
                        tPosL,'SelectionChangeFcn',{@obj.treeSelectChng});
            set(hC,'Visible','off')
            set(hC,'Parent',obj.hPanelL,'visible','on')
            warning(wState);                        
            
            % retrieves the selected node
            obj.hTreeL.expand(obj.hRootL);
            
        end
        
        % --- retrieves the explorer tree node for the iExp
        function expandExplorerTreeNodes(obj)

            for i = 1:obj.hTreeL.getRoot.getLeafCount
                % sets the next node to search for
                if i == 1
                    % case is from the root node
                    hNodeP = obj.hTreeL.getRoot.getFirstLeaf;
                else
                    % case is for the other nodes
                    hNodeP = hNodeP.getNextLeaf;
                end

                % retrieves the selected node
                obj.hTreeL.expand(hNodeP.getParent);
            end
            
        end
        
        % --- explorer tree selection change update function
        function treeSelectChng(obj, ~, ~)
            
            % retrieves the handle of the currently selected node
            hNode = obj.hTreeL.getSelectedNodes;
            
            % updates the description info based on the selection
            switch get(hNode(1),'Name')
                case {'Program Details','About...',...
                      'External Code References'}
                    % case is selecting the program details
                    setObjVisibility(obj.hPanelD{1},1)
                    setObjVisibility(obj.hPanelD{2},0)
                                        
                otherwise
                    % case is the file exchange files
                    setObjVisibility(obj.hPanelD{1},0)
                    setObjVisibility(obj.hPanelD{2},1)
                    
                    % retrieves the package information struct
                    fInfo = obj.fexInfo{hNode(1).getUserObject};
                    
                    % updates the code description strings
                    for i = 1:length(obj.hTxtC)
                        % retrieves the struct field value  
                        cbFcn = [];
                        pFld = getappdata(obj.hTxtC{i},'UserData');
                        tStrC = getStructField(fInfo,pFld);
                        
                        % sets the label string based on the type
                        switch pFld
                            case 'URL'
                                % case is the URL string
                                cbFcn = @(h,e)web(tStrC, '-browser');                                
                                tStrC = obj.setHTMLString('Link');                                
                                
                            case 'Repo'  
                                % case is the repository string
                                switch tStrC
                                    case 'File Exchange'
                                        rLink = obj.feLink;
                                    case 'Undocumented Matlab'
                                        rLink = obj.umLink;
                                end
                                
                                % sets the callback function
                                tStrC = obj.setHTMLString(tStrC);
                                cbFcn = @(h,e)web(rLink, '-browser'); 
                                
                            case 'Desc'
                                % case is the description string
                                tStrC = sprintf...
                                        ('<html><p>%s</p></html>',tStrC);
                        end
                        
                        % updates the text string
                        set(obj.hTxtC{i},'Text',tStrC);
                        
                        % sets the callback function (if required)
                        if ~isempty(cbFcn)
                            set(obj.hTxtC{i},'MouseClickedCallback',cbFcn)
                        end
                    end
                        
            end
            
        end
        
        % --- function for closing the GUI
        function closeGUI(obj, ~, ~)
           
            % deletes the figure object
            delete(obj.hFig);
            
        end
        
    end
    
    % static class methods
    methods (Static)
        
        % --- retrieves the file exchange info struct (based on input)
        function fInfo = getFileExchangeInfo(fType)
            
            % sets the base file exchange url
            fexURL = true;
            Repo = 'File Exchange';
            URL0 = 'https://mathworks.com/matlabcentral/fileexchange/';
            
            % retrieves the file exchange info (based on file type)
            switch fType
                
                case 'AnDartest'
                    Author = 'Antonio Trujillo-Ortiz';
                    Desc = ['Anderson-Darling test for assessing ',...
                            'normality of a sample data.'];
                    URL = '14807-andartest';
                    Date = '01 Aug 2007';
                    Type = 'File Only';
                    
                case 'export_fig'
                    Author = 'Yair Altman';
                    Desc = ['Publication-quality export of Matlab ',...
                            'figures and axes to various vector & ',...
                            'bitmap formats.'];
                    URL = '23629-export_fig';
                    Date = '20 Dec 2021';
                    Type = 'Package';
                    
                case 'fzsearch'
                    Author = 'Eduard Polityko';
                    Desc = ['The function finds substrings of a ',...
                            'reference string that match a pattern ',...
                            'string approximately.'];
                    URL = '66271-fuzzy-search';
                    Date = '02 Mar 2018';
                    Type = 'Package';
                    
                case 'GUI Layout Toolbox'
                    Author = 'David Sampson';
                    Desc = ['Layout manager for MATLAB graphical ',...
                            'user interfaces.'];
                    URL = '47982-gui-layout-toolbox';
                    Date = '29 Oct 2020';
                    Type = 'Package';
                    
                case 'jheapcl'
                    Author = 'Davide Tabarelli';
                    Desc = ['Simple function cleaning up, at runtime, ',...
                            'Java heap memory, thus preventing java ',...
                            'OutOfMemory error.'];
                    URL = '36757-java-heap-cleaner';
                    Date = '23 Apr 2013';
                    Type = 'File Only';
                    
                case 'mat2clip'
                    Author = 'Jiro';
                    Desc = ['Copies the contents of a matrix to ',...
                            'the CLIPBOARD.'];
                    URL = '8559-mat2clip';
                    Date = '01 Sep 2016';
                    Type = 'File Only';
                    
                case 'mmread'
                    Author = 'Micah Richert';
                    Desc = ['Read virtually any media file in ',...
                            'Windows, Linux, or Mac.'];
                    URL = '8028-mmread';
                    Date = '12 Nov 2009';
                    Type = 'Package';
                    
                case 'munkres'
                    Author = 'Yi Cao';
                    Desc = ['An efficient implementation of the ',...
                            'Munkres algorithm for the assignment ',...
                            'problem.'];
                    URL = '20328-munkres-assignment-algorithm';
                    Date = '27 Jun 2008';
                    Type = 'File Only';
                    
                case 'ProgressDialog'
                    Author = 'Levente Hunyadi';
                    Desc = ['An elegant and easy-to-use progress bar ',...
                            'dialog utilizing the Swing GUI ',...
                            'class JProgressBar.'];
                    URL = '26773-progress-bar';
                    Date = '13 Mar 2010';
                    Type = 'Package';
                    
                case 'uigetdir2'
                    Author = 'Chris Cannell';
                    Desc = ['Directory selection dialog box which ',...
                            'remembers the last directory selected.'];
                    URL = '9521-uigetdir2';
                    Date = '18 Apr 2007';
                    Type = 'File Only';
                    
                case 'xlwrite'
                    Author = 'Alec de Zegher';
                    Desc = ['Generates .xls & .xlsx files on ',...
                            'Mac/Linux/Win without Excel, using same ',...
                            'syntax as xlswrite.'];
                    URL = ['38591-xlwrite-generate-xls-x-files-',...
                           'without-excel-on-mac-linux-win'];
                    Date = '27 Feb 2013';
                    Type = 'Package';
                    
                case 'ColoredFieldCellRenderer'                    
                    Author = 'Yair Altman';
                    Desc = ['A simple table cell renderer that enables ',...
                            'setting cell-specific foreground/background ',...
                            'colors and tooltip messages.'];
                    URL = ['https://https://undocumentedmatlab.com/',...
                           'articles/uitable-cell-colors'];
                    Date = 'Not Applicable';
                    Repo = 'Undocumented Matlab';
                    Type = 'Package';
                    
                    % flag that not a special URL
                    fexURL = false;
                    
                case 'columnlegend'
                    Author = 'Simon Henin';
                    Desc = ['Creates a legend with a specified ',...
                            'number of columns.'];
                    URL = '27389-simonhenin-columnlegend';
                    Date = '08 Jan 2020';
                    Type = 'File Only';
                    
                case 'distinguishable_colors'
                    Author = 'Tim Holy';
                    Desc = ['Choose a set of n colors that can be ',...
                            'readily distinguished from each other.'];
                    URL = '29702-generate-maximally-perceptually-distinct-colors';
                    Date = '07 Feb 2011';
                    Type = 'File Only';
                    
                case 'fastreg'
                    Author = 'Min';
                    Desc = 'A very fast subpixel image registration.';
                    URL = '46964-fastreg-zip';
                    Date = '06 Aug 2014';
                    Type = 'File Only';
                    
                case 'hex2rgb'
                    Author = 'Chad Greene';
                    Desc = 'Convert colors between rgb and hex values.';
                    URL = '46289-rgb2hex-and-hex2rgb';
                    Date = '20 May 2019';
                    Type = 'File Only';
                    
                case 'rgb2hex'
                    Author = 'Chad Greene';
                    Desc = 'Convert colors between rgb and hex values.';
                    URL = '46289-rgb2hex-and-hex2rgb';
                    Date = '20 May 2019';
                    Type = 'File Only';
                    
                case 'uiinspect'                    
                    Author = 'Yair Altman';
                    Desc = ['Inspect an object handle (Java/COM/HG); ',...
                            'display its methods/properties/callbacks ',...
                            'in a unified window.'];
                    URL = ['17935-uiinspect-display-methods-',...
                           'properties-callbacks-of-an-object'];
                    Date = '02 Mar 2015';
                    Type = 'File Only';                    
            end
            
            % sets the full URL string
            if fexURL                
                URLF = sprintf('%s%s',URL0,URL);
            else
                URLF = URL;
            end
            
            % sets the fields of the data struct
            fInfo = struct('Author',Author,'Desc',Desc,'URL',URLF,...
                       'Date',Date,'Type',Type,'Repo',Repo,'fType',fType);
            
        end
    end

    % static class methods
    methods (Static)
    
        function lStr = setHTMLString(lStr0)
            
            lStr = sprintf('<html><a href="">%s</a></html>',lStr0);
    
        end
        
    end
end