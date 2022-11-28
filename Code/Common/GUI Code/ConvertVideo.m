classdef ConvertVideo < handle
    
    % class properties
    properties
        
        % main class fields
        iProg
        hProg
        
        % other important fields
        inDir
        inFile
        outDir        
        vComp
        iExtn
        useInDir = true;
        delFile = false;
        pStrF
        
        % gui object handles
        hFig
        hPanelI
        hPanelO
        hPanelC        
        
        % input video handles
        hRadioI        
        hPanelVD
        hEditVD
        hButVD
        hPanelVF
        hListVF
        hButVF        
        
        % output video handles
        hPanelDD
        hEditDD
        hButDD
        hChkO
        hTxtO
        hPopupO
        
        % control button handles
        hButC
        
        % main object derived dimension values    
        hghtFig
        widPanel
        widPanelI
        hghtPanelO
        hghtPanelI
        
        % minor object derived dimension values
        widRadio        
        widListVF
        hghtListVF
        widEditDD        
        widEditVD
        widPopupO 
        widButC
        
        % main object fixed dimension values            
        widFig = 495;                
        hghtPanelC = 40;
        hghtPanelVF = 155;
        hghtPanelDD = 55;        
        
        % minor object fixed dimension values        
        widChkO = 145;
        widTxtO = 125;

        % common fixed dimension values                    
        hghtTxt = 16;
        hghtChk = 22;
        hghtBut = 25;        
        hghtEdit = 25;
        hghtPopup = 25;
        hghtRadio = 20;        
        
        % other fixed parameter values
        dX = 10;
        lSz = 13;
        tSz = 12;
        bSz = 25;
        ltSz = 11;
        mStr = {'*.avi','*.mp4','*.mj2','*.mj2'};
                
    end
    
    % class methods
    methods
        
        % class constructor
        function obj = ConvertVideo(iProg)
            
            % sets the input arguments
            obj.iProg = iProg;
            
            % initialises the class fields
            obj.initClassFields();
            obj.initClassObjects();            
    
            % makes the figure visible
            setObjVisibility(obj.hFig,1);  
            
        end
            
        % --------------------------------------- %
        % --- CLASS OBJECT CREATION FUNCTIONS --- %
        % --------------------------------------- %        
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % field initialisations
            obj.pStrF = obj.setupVidCompressStrings();
            [obj.vComp,obj.iExtn] = deal(obj.pStrF{1},1);
            
            % precalculations
            widCT = (2*obj.dX + obj.widChkO + obj.widTxtO);
            hghtI = 2*obj.hghtRadio + obj.hghtPanelC + obj.hghtPanelVF;
            
            % main object derived dimension values                
            obj.widPanel = obj.widFig - 2*obj.dX;
            obj.widPanelI = obj.widPanel - 2*obj.dX;
            obj.hghtPanelO = (obj.hghtPanelDD + obj.hghtPopup) + 3.5*obj.dX;
            obj.hghtPanelI = hghtI + 5*obj.dX; 

            % minor object derived dimension values
            obj.widRadio = obj.widPanelI;
            obj.widListVF = obj.widPanelI - (2.5*obj.dX + obj.hghtBut);
            [obj.widEditDD,obj.widEditVD] = deal(obj.widListVF);
            obj.widPopupO = obj.widPanel - widCT;
            obj.widButC = (obj.widPanel - 3*obj.dX)/3;            
            obj.hghtListVF = obj.hghtPanelVF - 2*obj.dX;
            
            % sets the total figure height
            obj.hghtFig = 4*obj.dX + ...
                        (obj.hghtPanelC + obj.hghtPanelI + obj.hghtPanelO);
            
        end
        
        % --- initialises the class objects
        function initClassObjects(obj)
            
            % creates the figure object
            tagStr = 'figConvertVid';
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % removes any previous GUIs
            hFigPr = findall(0,'tag',tagStr);
            if ~isempty(hFigPr); delete(hFigPr); end
            
            % creates the figure object
            fStr = 'Video File Conversion';
            obj.hFig = figure('Position',fPos,'tag',tagStr,...
                              'MenuBar','None','Toolbar','None',...
                              'Name',fStr,'NumberTitle','off',...
                              'Visible','off','Resize','off',...
                              'CloseRequestFcn',@obj.closeFigure);   
                          
            % ------------------------------ %
            % --- CONTROL BUTTON OBJECTS --- %
            % ------------------------------ %  
            
            % initialisations
            bStrBC = {'Convert Videos','Clear All Fields','Close Window'};
            cFcnBC = {@obj.convertVideos,@obj.clearFields,@obj.closeFigure};
            
            % creates the control button panel
            pPosC = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelC];
            obj.hPanelC = uipanel(obj.hFig,'Title','','Units',...
                    'Pixel','Position',pPosC);  
                
            % creates the control button objects
            obj.hButC = cell(length(bStrBC),1);
            for i = 1:length(bStrBC)
                lPosC = obj.dX + (i-1)*(obj.dX/2 + obj.widButC);
                bPosC = [lPosC,obj.dX-2,obj.widButC,obj.hghtBut];
                obj.hButC{i} = uicontrol(obj.hPanelC,'Style','PushButton',...
                                'Units','Pixels','Position',bPosC,...
                                'Callback',cFcnBC{i},'FontWeight','Bold',...
                                'FontUnits','Pixels','FontSize',obj.tSz,...
                                'String',bStrBC{i});                
            end             
            
            % disables the convert button
            setObjEnable(obj.hButC(1:2),0);
            
            % ---------------------------------- %
            % --- VIDEO OUTPUT PANEL OBJECTS --- %
            % ---------------------------------- %            
            
            % initialisations
            tStrO = 'CONVERTED VIDEO OUTPUT';
            tStrDD = 'OUTPUT FILE DIRECTORY';
            chkStrO = 'Delete Original Files?';
            txtStrO = 'Video Compression: ';            
            
            % creates the control button panel
            yPosC0 = obj.dX + sum(pPosC([2,4]));
            pPosO = [obj.dX,yPosC0,obj.widPanel,obj.hghtPanelO];
            obj.hPanelO = uipanel('Title',tStrO,'Units',...
                    'Pixel','Position',pPosO,'Parent',obj.hFig,...
                    'FontUnits','Pixels','FontWeight','bold',...
                    'FontSize',obj.lSz);            
            
            % creates the checkbox object
            cPosO = [obj.dX-[0,2],obj.widChkO,obj.hghtChk];
            obj.hChkO = uicontrol(obj.hPanelO,'String',chkStrO,'Units',...
                    'Pixels','Position',cPosO,'FontUnits','Pixels',...
                    'Style','CheckBox','Callback',@obj.checkDeleteFiles,...
                    'FontWeight','bold','FontSize',obj.tSz);
                    
            % creates the text label object
            tPosO = [sum(cPosO([1,3])),obj.dX,obj.widTxtO,obj.hghtTxt];
            obj.hTxtO = uicontrol(obj.hPanelO,'String',txtStrO,'Units',...
                    'Pixels','Position',tPosO,'FontUnits','Pixels',...
                    'FontWeight','bold','FontSize',obj.tSz,'Style','Text'); 
            
            % creates the text label object
            ppPosO = [sum(tPosO([1,3])),obj.dX/2,obj.widPopupO,obj.hghtPopup];
            obj.hPopupO = uicontrol(obj.hPanelO,'String',obj.pStrF,'Units',...
                    'Pixels','Position',ppPosO,'FontUnits','Pixels',...
                    'Style','PopupMenu','Callback',@obj.popupVidCompress);   
                
            % creates the sub-panel object
            ypPosDO = sum(ppPosO([2,4])) + obj.dX/2;
            pPosDO = [obj.dX,ypPosDO,obj.widPanelI,obj.hghtPanelDD];
            obj.hPanelDD = uipanel(obj.hPanelO,'Title',tStrDD,'Units',...
                    'Pixel','Position',pPosDO,'FontUnits','Pixels',...
                    'FontWeight','bold','FontSize',obj.tSz);
                
            % creates the video directory editbox
            ePosDD = [obj.dX-2*[1,1],obj.widEditDD,obj.hghtEdit];
            obj.hEditDD = uicontrol(obj.hPanelDD,'Style','Edit',...
                    'String','','Position',ePosDD,'Enable','Inactive',...
                    'HorizontalAlignment','Left','FontUnits','Pixels',...
                    'FontSize',obj.ltSz);
                
            % creates the video directory editbox
            lbPosVD = sum(ePosDD([1,3])) + obj.dX/2;
            ePosVD = [lbPosVD,obj.dX-2,obj.hghtBut*[1,1]];
            obj.hButDD = uicontrol(obj.hPanelDD,'Style','PushButton',...
                    'String','...','Position',ePosVD,'FontUnits',...
                    'Pixels','FontWeight','Bold','FontSize',obj.tSz,...
                    'Callback',@obj.setDirectory,'UserData',2);                
                
            % --------------------------------- %
            % --- INPUT VIDEO PANEL OBJECTS --- %
            % --------------------------------- %  
            
            % initialisations
            eStr = {'off','on'};            
            bStrVF = {char(8722),'+'};
            tStrI = 'INPUT VIDEO FILES';
            rStr = {'Convert Specific Video Files',...
                    'Convert All Videos Within Directory'};            
            [obj.hRadioI,obj.hButVF] = deal(cell(2,1));                                      
            cbFcnVF = {@obj.removeFile,@obj.addFile};
            y0 = obj.hghtPanelVF/2 - (obj.dX/2 + obj.hghtBut);
            yOfs = (obj.dX + obj.hghtBut);            
            
            % creates the control button panel
            yPosI0 = obj.dX + sum(pPosO([2,4]));
            pPosI = [obj.dX,yPosI0,obj.widPanel,obj.hghtPanelI];
            obj.hPanelI = uibuttongroup(obj.hFig,'Title',tStrI,'Units',...
                    'Pixel','Position',pPosI,'FontUnits','Pixels',...
                    'FontWeight','bold','FontSize',obj.lSz,...
                    'SelectionChangedFcn',@obj.radioSelect);                        
                
            % creates the upper panel object
            pPosVD = [obj.dX*[1,1],obj.widPanelI,obj.hghtPanelVF]; 
            obj.hPanelVF = uipanel(obj.hPanelI,'Title','',...
                    'Units','Pixel','Position',pPosVD);
                
            % creates the listbox object
            lPosVF = [obj.dX*[1,1],obj.widListVF,obj.hghtListVF];
            obj.hListVF = uicontrol(obj.hPanelVF,'Style','ListBox',...
                    'Callback',@obj.listSelect,'Position',lPosVF,...
                    'FontUnits','Pixels','FontSize',obj.ltSz);
            
            % creates the add/remove buttons
            lbPosVF = sum(lPosVF([1,3])) + obj.dX/2;
            for i = 1:length(bStrVF)
                bPos = [lbPosVF,y0+(i-1)*yOfs,obj.hghtBut*[1,1]];
                obj.hButVF{i} = uicontrol(obj.hPanelVF,'Style','Pushbutton',...
                       'String',bStrVF{i},'Units','Pixels','Position',bPos,...
                       'FontUnits','Pixels','FontSize',obj.bSz,...
                       'FontWeight','bold','HorizontalAlignment',...
                       'Center','Callback',cbFcnVF{i},'Enable',eStr{i});              
            end
                
            % creates the radio button object
            yrPosVF = sum(pPosVD([2,4])) + obj.dX/2;
            rPosVF = [obj.dX,yrPosVF,obj.widRadio,obj.hghtRadio];
            obj.hRadioI{1} = uicontrol(obj.hPanelI,'Style','RadioButton',...
                    'String',rStr{1},'Position',rPosVF,'FontUnits',...
                    'pixels','FontWeight','bold','FontSize',obj.tSz,...
                    'UserData',1);
            
            % creates the lower panel object
            ypPosVD = sum(rPosVF([2,4])) + obj.dX/2;
            pPosVD = [obj.dX,ypPosVD,obj.widPanelI,obj.hghtPanelC];
            obj.hPanelVD = uipanel(obj.hPanelI,'Title','','Units',...
                    'Pixel','Position',pPosVD);            
            
            % creates the video directory editbox
            ePosVD = [obj.dX-2*[1,1],obj.widEditDD,obj.hghtEdit];
            obj.hEditVD = uicontrol(obj.hPanelVD,'Style','Edit',...
                    'String','','Position',ePosVD,'FontUnits','Pixels',...
                    'HorizontalAlignment','Left','Enable','Inactive',...
                    'FontUnits','Pixels','FontSize',obj.ltSz);
                
            % creates the video directory editbox
            lbPosVD = sum(ePosVD([1,3])) + obj.dX/2;
            ePosVD = [lbPosVD,obj.dX-2,obj.hghtBut*[1,1]];
            obj.hButVD = uicontrol(obj.hPanelVD,'Style','PushButton',...
                    'String','...','Position',ePosVD,'FontUnits',...
                    'Pixels','FontWeight','Bold','FontSize',obj.tSz,...
                    'Callback',@obj.setDirectory,'UserData',1);
                
            % creates the radio button object
            yrPosVD = sum(pPosVD([2,4])) + obj.dX/2;            
            rPosVD = [obj.dX,yrPosVD,obj.widRadio,obj.hghtRadio];
            obj.hRadioI{2} = uicontrol(obj.hPanelI,'Style','RadioButton',...
                    'String',rStr{2},'Position',rPosVD,'FontUnits',...
                    'Pixels','FontWeight','bold','FontSize',obj.tSz,...
                    'Value',1,'UserData',2);
                
                
            % initialises the button group properties
            obj.radioSelect(obj.hPanelI,[]);
                                       
        end

        % --------------------------------------------- %
        % --- INPUT VIDEO OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------------------- %
        
        % --- video file input buttongroup selection callback function
        function radioSelect(obj,hObj,evnt)
            
            % retrieves the selected radio button object
            if isempty(evnt)
                hRadio = findobj(hObj,'Value',1,'Style','RadioButton');
            else
                hRadio = evnt.NewValue;
            end
            
            % updates the properties based on the selection
            iType = get(hRadio,'UserData');
            switch iType
                case 1                    
                    % case is specific video files
                    setPanelProps(obj.hPanelVD,0);
                    setPanelProps(obj.hPanelVF,1);
                    setObjEnable(obj.hButVF{1},~isempty(obj.inFile))
                    
                case 2
                    % case is whole directory conversion
                    setPanelProps(obj.hPanelVD,1);
                    setPanelProps(obj.hPanelVF,0);
                    set(obj.hEditVD,'Enable','Inactive')
                    
            end            
            
            % updates the control button properties
            obj.useInDir = iType == 2;
            obj.updateContButton();
            
        end
        
        % --- file list selection callback function
        function listSelect(obj,hObj,~)
            
            % enables the remove button
            setObjEnable(obj.hButVF{1},~isempty(get(hObj,'Value')))
            
        end
        
        % --- add file selection callback function
        function addFile(obj,~,~)
           
            % retrieves the default directory
            if isempty(obj.iProg)
                dDir = pwd;
            else
                dDir = obj.iProg.DirMov;
            end

            % prompts the user for the output file name/directory
            fMode = {'*.avi;*.mp4;*.mj2;*.mj2',...
                     'Video Files (*.avi, *.mp4, *.mj2, *.mkv)'};
            [fName,fDir,fIndex] = uigetfile(fMode,'Load Video Files',dDir,...
                                            'MultiSelect','on');
            if fIndex == 0
                % if the user cancelled, then exit the function
                return
            elseif ~iscell(fName)
                fName = {fName};    
            end

            % sets the full file names
            fFileNw = cellfun(@(x)(fullfile(fDir,x)),fName,'un',0);            
            
            % determines which files can be added to the list            
            if isempty(obj.inFile)
                % if there are no existing files, then add all selected files
                isAdd = true(length(fFileNw),1);
            else
                % determines if the new files are not already in the existing list
                isAdd = cellfun(@(x)(~any(strcmp(obj.inFile,x))),fFileNw);

                % if there are no unique files, then exit the function
                if ~any(isAdd); return; end
            end

            % updates the video file details            
            obj.inFile = [obj.inFile;arr2vec(fFileNw(isAdd))];
            lStr = cellfun(@(x)(getFileName(x,1)),obj.inFile,'un',0);
            set(obj.hListVF,'String',lStr,'Value',[],'Max',2);          

            % updates the enable properties
            setObjEnable(obj.hButVF{1},0);
            obj.updateContButton();
            
        end        
        
        % --- remove file selection callback function
        function removeFile(obj,hObj,~)
           
            % prompts the user if they wish to remove the files?
            tStr = 'Remove Selected Files?';
            qStr = 'Are you sure you want to remove the selected files?';
            if ~strcmp(questdlg(qStr,tStr,'Yes','No','Yes'),'Yes')
                % if the user cancelled, then exit
                return
            end
            
            % determines which videos are to remain
            iSel = get(obj.hListVF,'Value');
            nVid = length(get(obj.hListVF,'String'));
            isOK = ~setGroup(iSel(:),[nVid,1]);
            
            % resets the video path/listbox strings
            obj.inFile = obj.inFile(isOK);
            fFile = cellfun(@(x)(getFileName(x,1)),obj.inFile,'un',0);
            set(obj.hListVF,'String',fFile,'Value',[])            
            
            % updates the button enabled properties
            setObjEnable(hObj,false);
            obj.updateContButton();
            
        end                
        
        % ---------------------------------------------- %
        % --- OUTPUT VIDEO OBJECT CALLBACK FUNCTIONS --- %
        % ---------------------------------------------- %
        
        % --- video deletion checkbox callback function
        function checkDeleteFiles(obj,hObj,~)
           
            obj.delFile = get(hObj,'Value');          
            
        end
        
        % --- video compression popupmenu callback function
        function popupVidCompress(obj,hObj,~)
           
            obj.iExtn = get(hObj,'Value');
            obj.vComp = obj.pStrF{obj.iExtn};
            
        end        
        
        % ----------------------------------------- %
        % --- CONTROL BUTTON CALLBACK FUNCTIONS --- %
        % ----------------------------------------- %

        % --- video conversion callback function
        function convertVideos(obj,~,~)
        
            % converts all the selected videos
            isOK = obj.convertAllVideos();
            if ~any(isOK); return; end
                
            % reduces the listbox strings (if converting specific files)
            if ~obj.useInDir
                % reduces the input file path strings
                obj.inFile = obj.inFile(~isOK);                
                lStr = cellfun(@(x)(getFileName(x,1)),obj.inFile,'un',0);
                set(obj.hListVF,'String',lStr,'Value',[],'Max',2); 
                
                % updates the enable properties
                setObjEnable(obj.hButC{1},any(~isOK));
                setObjEnable(obj.hButC{2},any(~isOK));
                obj.updateContButton();
            end
            
        end 
        
        % --- gui clear all field callback function
        function clearFields(obj,~,~)
            
            % prompts the user if they wish to clear all the fields
            qStr = 'Are you sure you want to clear all the fields?';
            tStr = 'Clear All Fields?';
            if ~strcmp(questdlg(qStr,tStr,'Yes','No','Yes'),'Yes')
                % if the user cancelled, then exit the function
                return
            end
            
            % clears the fields
            [obj.inDir,obj.inFile,obj.outDir] = deal([]);
            
            % resets the editbox/listbox strings
            set(obj.hEditVD,'String',[])            
            set(obj.hEditDD,'String',[])
            set(obj.hListVF,'String',[],'Value',[]);
            set(obj.hRadioI{2},'Value',1);
            
            % updates the button properites
            obj.radioSelect(obj.hPanelI,[]);
            obj.updateContButton();
            
        end
        
        % --- figure close callback function
        function closeFigure(obj,~,~)
        
            % deletes the gui
            delete(obj.hFig)            
            
        end
        
        % --------------------------------- %
        % --- COMMON CALLBACK FUNCTIONS --- %
        % --------------------------------- %        
        
        % --- directory setting button callback function
        function setDirectory(obj,hObj,~)

            % sets the default directory
            switch get(hObj,'UserData')
                case 1           
                    % case is the input video directory
                    dDir = obj.inDir;
                    
                case 2
                    % case is the output video directory
                    dDir = obj.outDir;
            end
                    
            % prompts the user for the new default directory
            if isempty(dDir); dDir = obj.iProg.DirMov; end
            dirName = uigetdir(dDir,'Set The Default Path');
            
            % updates the property values
            if dirName
                switch get(hObj,'UserData')
                    case 1
                        % case is the input video directory
                        if obj.isValidDir(dirName)
                            % case the directory is valid
                            obj.inDir = dirName;
                            hEdit = obj.hEditVD;
                            hBut = obj.hButVD;
                        else
                            % if not, then output an error to screen
                            eStr = ['The selected directory does not ',...
                                    'contain any vaild video files.'];
                            tStr = 'No Valid Video Files';
                            waitfor(msgbox(eStr,tStr,'modal'));
                            
                            % exits the function 
                            return
                        end
                        
                    case 2
                        % case is the output video directory
                        obj.outDir = dirName; 
                        hEdit = obj.hEditDD;
                        hBut = obj.hButDD;
                end
                
                % updates the continue button properties
                set(hBut,'TooltipString',dirName);
                set(hEdit,'string',['  ',dirName])
                obj.updateContButton();                
            end            
            
        end

        % ---------------------------------- %
        % --- VIDEO CONVERSION FUNCTIONS --- %
        % ---------------------------------- %
        
        % --- retrieves the conversion file list
        function fFile = getConvFile(obj)
                        
            if obj.useInDir
                % case is converting a whole directory
                fFile = cell2cell(obj.findAllVideoFiles(obj.inDir));
                
            else
                % case is specific video files
                fFile = obj.inFile;                    
            end
            
        end        
        
        % --- converts the selected video files
        function isOK = convertAllVideos(obj)
            
            % initialisations
            fFile = obj.getConvFile();                        
            nFile = length(fFile);
            isOK = false(nFile,1);            
            
            % memory allocation            
            tStr = 'Video Conversion';
            wStr0 = {'','Converting Current Video'};
            obj.hProg = ProgBar(wStr0((1+(nFile==1)):end),tStr);
            
            % converts all the list video files
            for iFile = 1:nFile
                % updates the overall progress (if more than one file to convert)
                if nFile > 1
                    wStrNw = sprintf('Overall Progress (File %i of %i)',iFile,nFile);
                    obj.hProg.Update(1,wStrNw,iFile/(nFile+1));
                end

                % converts the current video file
                if obj.convertCurrentVideo(fFile{iFile})
                    % if the conversion completed successfully, then update the flag
                    isOK(iFile) = true;
                else
                    % if the video conversion failed, then exit the loop
                    break
                end                
            end
            
            % closes the progressbar
            obj.hProg.closeProgBar();            
                        
        end
        
        % --- converts video file, vFile, to the compression type, vComp
        function ok = convertCurrentVideo(obj,fFile)
            
            % initialisations
            ok = true;
            nFrmW = 10;
            nW = length(obj.hProg.wStr);
            wStr0 = 'Converting Current Video';            
            
            % determines if the video file exists
            if ~exist(fFile,'file')
                % case is the file does not exist
                fName = getFileName(fFile,1);
                eStr = sprintf('The file "%s" does not exist!',fName);

            else
                % creates the video object
                [mObjR,fType,eStr] = obj.createVideoObj(fFile);
                if isempty(eStr)        
                    % if there was no error, then rename the original file 
                    [fDir,fName,fExtn] = fileparts(fFile);
                    nFrm = obj.getFrameCount(mObjR,fType);
                    fFileBase = fullfile(obj.outDir,fName);

                    % creates the output video
                    [fExtnOut,vFormat] = obj.getOutputFileFormat();
                    fFileOut = sprintf('%s (New)%s',fFileBase,fExtnOut);
                    fFileFinal = sprintf('%s%s',fFileBase,fExtnOut); 
                    
                    % if the output file already exists, then prompt the
                    % user if they wish to overwrite it?
                    if exist(fFileFinal,'file')
                        qtStr = 'Overwrite File?';
                        qStr = sprintf(['The following video already ',...
                                'exists:\n\n %s %s\n\nDo you wish to ',...
                                'overwrite this video files?'],...
                                char(8594),fFileFinal);
                        uChoice = questdlg(qStr,qtStr,'Yes','No','Yes');
                        if strcmp(uChoice,'Yes')
                            % if so, then delete the video file
                            delete(fFileFinal);
                        else
                            % otherwise close the reading video file & exit
                            obj.runHouseKeeping(mObjR,[]);
                            return
                        end
                    end
                    
                    % creates the output video object
                    mObjW = VideoWriter(fFileOut,vFormat);   
                    open(mObjW);

                    % reads/writes the frames for the new video
                    for iFrm = 1:nFrm
                        % updates the progress bar
                        if (mod(iFrm,nFrmW) == 1) || (iFrm == nFrm)
                            [pW,wStrNw] = deal(iFrm/nFrm,sprintf...
                                  ('%s (Frame %i of %i)',wStr0,iFrm,nFrm));
                            if obj.hProg.Update(nW,wStrNw,pW)
                                % if the user cancelled then delete the 
                                % video object and exit the function
                                ok = false;
                                obj.runHouseKeeping(mObjR,mObjW);
                                delete(fFileOut);
                                return
                            end
                        end                        
                        
                        % writes the new frame to the video object
                        writeVideo(mObjW,obj.getNewFrame(mObjR,fType,iFrm))
                    end                

                    % closes the video objects and deletes the oriinal video file
                    obj.runHouseKeeping(mObjR,mObjW);                    
                    if obj.delFile
                        % deletes the input file (if required)
                        delete(fFile); 
                        
                    elseif strcmp(fFile,fFileFinal)
                        % otherwise, if the input/output file names are the
                        % same then rename the original file
                        fNameNw = sprintf('%s (Orig)%s',fName,fExtn);
                        fFileTmp = fullfile(fDir,fNameNw);
                        movefile(fFile,fFileTmp,'f');
                    end

                    % renames the file to the original video file name        
                    movefile(fFileOut,fFileFinal,'f');
                end
            end            
            
            % determines if there was an error with the file conversion
            if ~isempty(eStr)
                % if there was an error then output a message to screen
                waitfor(msgbox(eStr,'Video Conversion Error','modal'))

                % sets the output flag to false
                ok = false;
            end            
            
        end        
        
        % --- retrieves the extn/format of the output file 
        function [fExtnOut,vFormat] = getOutputFileFormat(obj)
            
            A = cellfun(@strtrim,regexp(obj.vComp,'[^()]*','match'),'un',0);
            [vFormat,fExtnOut] = deal(A{1},A{2}(2:end));
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %         
        
        % --- updates the continue button properties
        function updateContButton(obj)
            
            % initialisations
            hasOut = ~isempty(obj.outDir);
            
            % retrieves the radio button object handle
            hRadio = findobj(obj.hPanelI,'Value',1,'Style','RadioButton');            
            switch get(hRadio,'UserData')
                case 1
                    % case is specific video files
                    hasIn = ~isempty(obj.inFile);
                    
                case 2
                    % case is whole directory conversion
                    hasIn = ~isempty(obj.inDir);                    
            end
            
            % updates the continue button
            setObjEnable(obj.hButC{1},hasIn && hasOut)
            setObjEnable(obj.hButC{2},hasIn || hasOut)
                
        end
        
        % --- determines if the selected directory is valid
        function isValid = isValidDir(obj,dirName)
        
            % initialisations
            fFile = obj.findAllVideoFiles(dirName);
            isValid = any(~cellfun('isempty',fFile));
                        
        end        
        
        % --- finds all the video files in the directory, dirName
        function fFile = findAllVideoFiles(obj,dirName)
            
            % memory allocation
            fFile = cell(length(obj.mStr),1);
            
            % determines if there are files of the selected type
            for i = 1:length(obj.mStr)
                dDir = dir(fullfile(dirName,obj.mStr{i}));
                if ~isempty(dDir)
                    fFile{i} = arrayfun(@(x)...
                                (fullfile(dirName,x.name)),dDir,'un',0);
                end
            end
            
        end
        
    end
    
    % static class methods
    methods (Static)
        
        % --- sets up the video compressions strings
        function pStrF = setupVidCompressStrings()
            
            % sets the rejected profile types
            rjType = {'Archival';'Grayscale AVI';...
                      'Indexed AVI';'Uncompressed AVI'};
            
            % retrieves the video profiles names/file extensions
            vidProf = num2cell(VideoWriter.getProfiles());
            pStr0 = cellfun(@(x)(x.Name),vidProf,'un',0)';
            
            % removes the rejected profile types and sets the final strings
            [pStr,iA] = setdiff(pStr0,rjType);
            uStr = cellfun(@(x)(x.FileExtensions{1}),vidProf(iA),'un',0)';            
            pStrF = cellfun(@(x,y)(sprintf('%s (*%s)',x,y)),pStr,uStr,'un',0);            
            
        end                
        
        % --- retrieves the new frame from the video object (based on type)
        function Img = getNewFrame(mObj,fType,iFrm)

            % reads the new frame dependent on the file type
            switch fType
                case 1
                    % case is either .mov, .mj2 or .mp4
                    Img = read(mObj,iFrm);

                case 2
                    % case is a .mkv file
                    Img = mObj.getFrame(iFrm-1);

                case 3        
                    % case is an .avi file
                    tFrm = iFrm/mObj.FPS + (1/(2*mObj.FPS))*[-1 1];
                    [V,~] = mmread(mObj.movStr,[],tFrm,false,true,'');            

                    % retrieves the image information (if it exists)
                    if isempty(V.frames)
                        Img = [];
                    else
                        Img = V.frames(1).cdata;        
                    end                
            end

            % converts the image to true-colour (if only 1 band)
            if ~isempty(Img)
                if size(Img,3) == 1
                    Img = repmat(Img,[1,1,3]);
                end
            end

        end
        
        % --- retrieves the frame count based on the file type
        function nFrm = getFrameCount(mObj,fType)

            switch fType
                case {1,2}
                    % case is the non-avi format videos
                    nFrm = mObj.NumberOfFrames;

                case 3
                    % case is avi format video
                    nFrm = mObj.nFrm;
            end

        end        
        
        % --- creates the video file object and retrieves the video compression
        %     for the video file, vFile
        function [mObj,fType,eStr] = createVideoObj(vFile)

            % initialisations
            [mObj,fType,eStr] = deal([]);
            [~,vName,vExtn] = fileparts(vFile);

            try
                % creates the video object based on the extension
                switch vExtn
                    case {'.mj2', '.mov','.mp4'}
                        % case is the videos that can be opened by VideoReader
                        [mObj,fType] = deal(VideoReader(vFile),1);

                    case '.mkv'
                        % case is an mkv file
                        [mObj,fType] = deal(ffmsReader(),2);
                        [~,~] = mObj.open(vFile,0); 

                    case '.avi'
                        % case is an avi video file
                        fType = 3;
                        mObj = struct('movStr',vFile,'nFrm',NaN,'FPS',NaN);

                        % retrieves the avi file information
                        [mObjT,~] = mmread(vFile,inf,[],false,true,'');   
                        mObj.FPS = mObjT.rate;
                        mObj.nFrm = abs(mObjT.nrFramesTotal);

                    otherwise
                        % otherwise, unable to open this video type
                        eStr = sprintf(['Unable to convert videos ',...
                                        'with "%s" extensions'],vExtn);
                end

            catch
                % if an error occured, then set the error string
                eStr = sprintf(['The video "%s" appears to be ',...
                                'corrupted.'],vName);
            end

        end
        
        % --- closes the video objects
        function runHouseKeeping(mObj,mObjW)

            % closes the progress bar and the video output object        
            if ~isempty(mObjW); close(mObjW); end

            % closes the file object (if .mj2 format)
            try; delete(mObj); end

        end        
        
    end
    
end