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
        
        % other important fields
        mainHdr 
        fexType
        fexInfo
        
        % objects dimensions
        dX = 10;
        dXH = 5;
        txtSz = 12;
        hghtFig = 420;
        widFig = 700;
        widPanelL = 250;
        widPanelD = 415;
        
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
            
        end
        
        % --- initialises the object class fields
        function initClassFields(obj)
            
            % explorer tree headings
            obj.mainHdr = {'Program Details','File Exchange References'};
            
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
                              'CloseRequestFcn',{@obj.closeGUI}); 
            
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
            obj.hPanelD = cell(2,1);
            
            % sets the position vectors
            x0D = sum(pPosL([1,3])) + obj.dXH;
            pPosD = [x0D,obj.dXH,obj.widPanelD,pPosL(4)];
            ePosD = [obj.dXH*[1,1],pPosD(3:4)-obj.dX];
            
            % creates the table panel
            for i = 1:2
                % creates the panel object
                obj.hPanelD{i} = uipanel(obj.hPanelO,'Title','',...
                                    'Units','Pixels','Position',pPosD);
            end
            
            % creates the editbox object
            obj.hEditD{i} = uicontrol(obj.hPanelD{i},'Style','Edit',...
                        'Position',ePosD,'Enable','Inactive',...
                        'FontUnits','Pixels','FontSize',obj.txtSz,...
                        'String','','HorizontalAlignment','left');            
                                         
        end
        
        % --- creates the explorer tree
        function createExplorerTree(obj, tPosL)
            
            % initialisations
            rStr = 'ABOUT DART';
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
        function treeSelectChng(obj, hObject, event)
            
            % retrieves the handle of the currently selected node
            hNode = obj.hTreeL.getSelectedNodes;
            
            % updates the description info based on the selection
            switch get(hNode(1),'Name')
                case 'Program Details'
                    % case is selecting the program details
                    a = 1;
                    
                case {'File Exchange References','ABOUT DART'}
                    % clears the description panel
                    
                otherwise
                    % case is the file exchange files
                    
                    %
                    iNode = hNode(1).getUserObject;
                    dStr = obj.getRefDescString(iNode);
                    
            end
            
        end
        
        % --- retrieves the code reference description string
        function dStr = getRefDescString(obj,iNode)
            
            %
            fStr = cell(5,1);
            dStr = '';
            
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
                            'bitmap formats'];
                    URL = '23629-export_fig';
                    Date = '20 Dec 2021';
                    Type = 'Package';
                    
                case 'fzsearch'
                    Author = 'Eduard Polityko';
                    Desc = ['The function finds substrings of a ',...
                            'reference string that match a pattern ',...
                            'string approximately'];
                    URL = '66271-fuzzy-search';
                    Date = '02 Mar 2018';
                    Type = 'Package';
                    
                case 'GUI Layout Toolbox'
                    Author = 'David Sampson';
                    Desc = ['Layout manager for MATLAB graphical ',...
                            'user interfaces'];
                    URL = '47982-gui-layout-toolbox';
                    Date = '29 Oct 2020';
                    Type = 'Package';
                    
                case 'jheapcl'
                    Author = 'Davide Tabarelli';
                    Desc = ['Simple function cleaning up, at runtime, ',...
                            'Java heap memory, thus preventing java ',...
                            'OutOfMemory error'];
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
                            'colors and tooltip messages'];
                    URL = ['https://undocumentedmatlab.com/files',...
                           '/ColoredFieldCellRenderer.zip'];
                    Date = 'Not Applicable';
                    Type = 'Package';
                    
                    % flag that not a special URL
                    fexURL = false;
                    
                case 'columnlegend'
                    Author = 'Simon Henin';
                    Desc = ['Creates a legend with a specified ',...
                            'number of columns'];
                    URL = '27389-simonhenin-columnlegend';
                    Date = '08 Jan 2020';
                    Type = 'File Only';
                    
                case 'distinguishable_colors'
                    Author = 'Tim Holy';
                    Desc = ['Choose a set of n colors that can be ',...
                            'readily distinguished from each other'];
                    URL = '29702-generate-maximally-perceptually-distinct-colors';
                    Date = '07 Feb 2011';
                    Type = 'File Only';
                    
                case 'fastreg'
                    Author = 'Min';
                    Desc = 'A very fast subpixel image registration';
                    URL = '46964-fastreg-zip';
                    Date = '06 Aug 2014';
                    Type = 'File Only';
                    
                case 'hex2rgb'
                    Author = 'Chad Greene';
                    Desc = 'Convert colors between rgb and hex values';
                    URL = '46289-rgb2hex-and-hex2rgb';
                    Date = '20 May 2019';
                    Type = 'File Only';
                    
                case 'rgb2hex'
                    Author = 'Chad Greene';
                    Desc = 'Convert colors between rgb and hex values';
                    URL = '46289-rgb2hex-and-hex2rgb';
                    Date = '20 May 2019';
                    Type = 'File Only';
                    
                case 'uiinspect'                    
                    Author = 'Yair Altman';
                    Desc = ['Inspect an object handle (Java/COM/HG); ',...
                            'display its methods/properties/callbacks ',...
                            'in a unified window'];
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
            fInfo = struct('Author',Author,'Desc',Desc,...
                           'URL',URLF,'Date',Date,'Type',Type);
            
            
        end
    end
    
end