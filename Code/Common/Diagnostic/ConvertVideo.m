classdef ConvertVideo < handle

    % class properties
    properties

        % input arguments
        hFigP
        
        % object handle fields
        hFig                
        hPanelC
        hPanelTS
        
        % conversion file information panel objects        
        hPanelD
        hEditD
        hButD
        hListC
        hTxtC
        hButC
        hButS
        
        % temporal conversion panel objects
        hPanelT
        hObjT
        
        % spatial conversion panel objects
        hPanelS
        hObjS
        
        % conversion parameter fields
        fRate
        frmHght
        frmWid
        sData
        
        % fixed conversion value fields
        pAR
        frmRes
        fRateR
        fRateEst
        isAdded
        nFileTot
        nFileAdd
        
        % video file information fields
        fDir
        fFile
        fName
        
        % fixed object dimensions
        dX = 10;
        widFig = 515;
        hghtFig = 290;
        hghtBut = 25;
        hghtButS = 20;
        hghtTxt = 16;
        hghtChk = 21;
        hghtEdit = 20;
        hghtEditD = 25;
        hghtPanelI = 155;
        hghtPanelD = 40;
        hghtList = 74;
        widList = 130;
        widLblT = 125;
        widLblS = 115;
        widButS = 175;        
        widTxtCL = 145;
        widTxtC = 40;
        
        % calculated object dimensions
        widPanelO
        hghtPanelTSO
        widPanelTS
        hghtPanelTS     
        widPanelD
        widEditD
        widObjT
        widObjS
        
        % fixed scalar/text fields
        dDir
        hSz = 12;
        fSz = 11;
        lSz = 10;
        tagStr = 'figConvertVideo';
        figName = 'Video File Conversion';

    end

    % class methods
    methods

        % --- class constructor
        function obj = ConvertVideo(hFigP)
            
            % sets the input arguments (if they exist)
            if exist('hFigP','var')
                obj.hFigP = hFigP;
                setObjVisibility(obj.hFigP,0)
            end

            % initialises the class fields/objects
            obj.initClassFields();
            obj.initClassObjects();
            
        end
        
        % --- initialises the class fields
        function initClassFields(obj)
                        
            if isempty(obj.hFigP)
                % case is there is no parent figure
                obj.dDir = pwd;
            else
                % case is there is a parent figure
                switch get(obj.hFigP,'tag')
                    case 'figFlyRecord'
                        % case is the fly recording GUI
                        iProg = getappdata(obj.hFigP,'iProg');
                        obj.dDir = iProg.DirMov;
                        
                    case 'figFlyTrack'
                        % case is the fly tracking GUI
                        obj.dDir = obj.hFigP.iData.ProgDef.DirMov;
                end
            end
            
            % calculated object dimensions
            obj.hghtPanelTSO = obj.hghtFig - (3*obj.dX + obj.hghtPanelI);
            obj.widPanelO = obj.widFig - 2*obj.dX;
            obj.hghtPanelTS = obj.hghtPanelTSO - obj.dX; 
            obj.widPanelTS = (obj.widPanelO - 3/2*obj.dX)/2;
            
            % sets the other object dimensions
            obj.widPanelD = obj.widPanelO - 2*obj.dX;
            obj.widEditD = obj.widPanelD - (obj.hghtBut + 2*obj.dX);
            obj.widObjT = obj.widPanelTS - (2.5*obj.dX + obj.widLblT);
            obj.widObjS = obj.widPanelTS - (2.5*obj.dX + obj.widLblS);            
            
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
                'Name',obj.figName,'Resize','on','NumberTitle','off',...
                'Visible','off','AutoResizeChildren','off',...
                'Resize','off','BusyAction','Cancel',...
                'CloseRequestFcn',@obj.closeWindow);            
            
            % creates the temporal/spatial conversion panels
            pPosTS = [obj.dX*[1,1],obj.widPanelO,obj.hghtPanelTSO];
            obj.hPanelTS = uipanel(obj.hFig,'Title',[],'Units',...
                'Pixels','FontUnits','Pixels','Position',pPosTS);            
            
            % creates the temporal/spatial conversion panels
            yPosC = sum(pPosTS([2,4])) + obj.dX;
            tStrC = 'CONVERSION FILE INFORMATION';
            pPosC = [obj.dX,yPosC,obj.widPanelO,obj.hghtPanelI];
            obj.hPanelC = uipanel(obj.hFig,'Title',tStrC,'Units',...
                'Pixels','FontUnits','Pixels','Position',pPosC,...
                'FontSize',obj.hSz,'FontWeight','bold');             
            
            % ----------------------------------------- %
            % --- CONVERSION FILE INFORMATION PANEL --- %
            % ----------------------------------------- %
            
            % memory allocation
            bStrD = {char(9668),char(9654)};
            bStrS = {'Convert Videos','Clear All Fields'};
            cbFcnD = {@obj.removeVideoFiles,@obj.addVideoFiles};
            cbFcnS = {@obj.convertVideos,@obj.clearAllFields};
            [obj.hListC,obj.hButC,obj.hButS] = deal(cell(2,1));
            
            % sets the left coordinates of the objects
            lPosC = 3*obj.dX/2 + obj.widList;   
            lPosS = 2*obj.widList + 3*obj.dX + obj.hghtButS;
            
            % creates the button            
            for i = 1:length(obj.hListC)
                % creates the listbox objects
                lPosL = obj.dX + (i-1)*(3*obj.dX + obj.widList);
                pPosL = [lPosL,obj.dX-2,obj.widList,obj.hghtList];
                obj.hListC{i} = createUIObj('listbox',obj.hPanelC,...
                    'Position',pPosL,'Items',{},'Enable','off',...
                    'Value',{},'MultiSelect','on','FontSize',obj.lSz,...
                    'ValueChangedFcn',{@obj.listBoxSelect,i==1});

                % creates the button objects
                yPosD = 25 + (i-1)*(obj.dX/2 + obj.hghtButS);
                pPosD = [lPosC,yPosD,obj.hghtButS*[1,1]];
                obj.hButC{i} = createUIObj('pushbutton',obj.hPanelC,...
                    'FontSize',obj.fSz-2,'FontWeight','Bold',...
                    'Position',pPosD,'Text',bStrD{i},...
                    'ButtonPushedFcn',cbFcnD{i},'Enable','off');
                
                % creates the button objects
                yPosS = obj.dX + (i-1)*(obj.hghtBut + 2);
                pPosS = [lPosS,yPosS-2,obj.widButS,obj.hghtBut];
                obj.hButS{i} = createUIObj('pushbutton',obj.hPanelC,...
                    'FontSize',obj.fSz,'FontWeight','Bold',...
                    'Position',pPosS,'Text',bStrS{i},'Enable','off',...
                    'ButtonPushedFcn',cbFcnS{i},'Enable','off');                
            end            
            
            % creates the video counter text label object
            tStrL = 'Video Conversion Count: ';
            lPosLC = sum(pPosL([1,3])) + obj.dX/2; 
            yPosC = sum(pPosS([2,4])) + obj.dX/2;
            pPosLC = [lPosLC,yPosC,obj.widTxtCL,obj.hghtTxt];
            createUIObj('text',obj.hPanelC,'String',tStrL,...
                'FontSize',obj.fSz,'FontWeight','Bold','Enable','off',...
                'HorizontalAlignment','Right','Position',pPosLC);
            
            % creates the video counter text object
            lPosC = sum(pPosLC([1,3])) + obj.dX/2;            
            pPosC = [lPosC,yPosC,obj.widTxtC,obj.hghtTxt];
            obj.hTxtC = createUIObj('text',obj.hPanelC,...
                'String','N/A','FontSize',obj.fSz,'Enable','off',...
                'HorizontalAlignment','Left','Position',pPosC);            
            
            % creates the temporal/spatial conversion panels
            yPosD = sum(pPosL([2,4])) + obj.dX/2;
            pPosD = [obj.dX,yPosD,obj.widPanelD,obj.hghtPanelD];
            obj.hPanelD = uipanel(obj.hPanelC,'Title',[],'Units',...
                'Pixels','FontUnits','Pixels','Position',pPosD);            
 
            % creates the editbox object
            pPosE = [obj.dX,obj.dX-2,obj.widEditD,obj.hghtEditD];
            obj.hEditD = createUIObj('edit',obj.hPanelD,...
                'Position',pPosE,'FontSize',obj.fSz,...
                'Editable','off');
            
            % creates the button object
            lPosD = sum(pPosE([1,3])) + obj.dX/2;
            pPosD = [lPosD,obj.dX-2,obj.hghtBut*[1,1]];
            obj.hButD = createUIObj('pushbutton',obj.hPanelD,...
                'Position',pPosD,'FontSize',1.5*obj.fSz,...
                'String','...','FontWeight','bold',...
                'ButtonPushedFcn',@obj.setFileDir);            
            
            % sets other properties
            obj.hButS{1}.BackgroundColor = 'r';            
            
            % --------------------------------- %
            % --- TEMPORAL CONVERSION PANEL --- %
            % --------------------------------- %

            % initialisations
            tStrT = 'TEMPORAL CONVERSION';
            uData = {'fRate',''};            
            fTypeT = {'edit','text'};
            fStrT = {'Final','Estimated','Use Temporal Downsampling'};
            
            % creates the panel object
            pPosT = [obj.dX*[1,1]/2,obj.widPanelTS,obj.hghtPanelTS];
            obj.hPanelT = uipanel(obj.hPanelTS,'Title',tStrT,'Units',...
                'Pixels','FontUnits','Pixels','Position',pPosT,...
                'FontSize',obj.hSz,'FontWeight','bold');
            
            % creates the panel objects
            obj.hObjT = cell(length(fTypeT)+1,1);
            for i = 1:length(fTypeT)
                % creates the label strings
                yPos = obj.dX*(1 + 2*(i-1));
                pPosTL = [obj.dX,yPos,obj.widLblT,obj.hghtTxt];
                tStrTF = sprintf('%s Frame Rate: ',fStrT{i});
                createUIObj('text',obj.hPanelT,'Position',pPosTL,...
                    'FontWeight','Bold','FontSize',obj.fSz,...
                    'String',tStrTF,'HorizontalAlignment','Right');
                
                % sets up the position vector
                lPosO = sum(pPosTL([1,3])) + obj.dX/2;
                if strcmp(fTypeT{i},'edit')
                    pPosO = [lPosO,yPos-2,obj.widObjT,obj.hghtEdit];
                else
                    pPosO = [lPosO,yPos,obj.widObjT,obj.hghtTxt];
                end
                
                % creates the text/edit objects
                obj.hObjT{i} = createUIObj(fTypeT{i},obj.hPanelT,...
                    'String','N/A','FontSize',obj.fSz,'Position',pPosO,...
                    'HorizontalAlignment','Center','UserData',uData{i});
                if strcmp(fTypeT{i},'edit')
                    obj.hObjT{i}.ValueChangedFcn = @obj.editTempPara;
                end
            end
            
            % creates the checkbox object
            nR = 2*length(fTypeT) + 1;
            pPosChkT = [obj.dX*[1,nR],obj.widPanelTS-2*obj.dX,obj.hghtChk];
            obj.hObjT{end} = createUIObj('checkbox',obj.hPanelT,...
                'Position',pPosChkT,'FontSize',obj.fSz,...
                'FontWeight','Bold','String',fStrT{end},...
                'ValueChangedFcn',@obj.checkDownsample);
            
            % disables the panel's objects
            setPanelProps(obj.hPanelT,0,obj.hPanelT);            
            
            % -------------------------------- %
            % --- SPATIAL CONVERSION PANEL --- %
            % -------------------------------- %

            % initialisations
            tStrS = 'SPATIAL CONVERSION';
            fTypeS = {'edit','edit'};
            uData = {'frmHght','frmWid'};
            fStrS = {'Final Frame Height: ','Final Frame Width: ',...
                     'Use Spatial Downsampling'};
            
            % creates the panel object
            lPosS = sum(pPosT([1,3])) + obj.dX/2;
            pPosS = [lPosS,obj.dX/2,obj.widPanelTS,obj.hghtPanelTS];
            obj.hPanelS = uipanel(obj.hPanelTS,'Title',tStrS,'Units',...
                'Pixels','FontUnits','Pixels','Position',pPosS,...
                'FontSize',obj.hSz,'FontWeight','bold');                 
                 
            % creates the panel objects
            obj.hObjS = cell(length(fTypeS)+1,1);
            for i = 1:length(fTypeS)
                % creates the label strings
                yPos = obj.dX*(1 + 2*(i-1));
                pPosSL = [obj.dX,yPos,obj.widLblS,obj.hghtTxt];
                createUIObj('text',obj.hPanelS,'Position',pPosSL,...
                    'FontWeight','Bold','FontSize',obj.fSz,...
                    'String',fStrS{i},'HorizontalAlignment','Right');
                
                % sets up the position vector
                lPosO = sum(pPosSL([1,3])) + obj.dX/2;
                if strcmp(fTypeS{i},'edit')
                    pPosO = [lPosO,yPos-2,obj.widObjS,obj.hghtEdit];
                else
                    pPosO = [lPosO,yPos,obj.widObjS,obj.hghtTxt];
                end
                
                % creates the text/edit objects
                obj.hObjS{i} = createUIObj(fTypeS{i},obj.hPanelS,...
                    'String','N/A','FontSize',obj.fSz,'Position',pPosO,...
                    'HorizontalAlignment','Center','UserData',uData{i});
                if strcmp(fTypeS{i},'edit')
                    obj.hObjS{i}.ValueChangedFcn = @obj.editSpatPara;
                end                
            end       
            
            % creates the checkbox object
            nR = 2*length(fTypeS) + 1;            
            pPosChkS = [obj.dX*[1,nR],obj.widPanelTS-2*obj.dX,obj.hghtChk];
            obj.hObjS{end} = createUIObj('checkbox',obj.hPanelS,...
                'Position',pPosChkS,'FontSize',obj.fSz,...
                'FontWeight','Bold','String',fStrS{end},...
                'ValueChangedFcn',@obj.checkDownsample);
            
            % disables the panel's objects
            setPanelProps(obj.hPanelS,0,obj.hPanelS);
            
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
        
        % --- window closing callback function
        function closeWindow(obj,~,~)
            
            % deletes the figure window
            delete(obj.hFig);
            
            % makes the parent figure visible again
            if ~isempty(obj.hFigP)
                setObjVisibility(obj.hFigP,1)
                figure(obj.hFigP);
            end
            
        end
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %
        
        % --- video file direction selection button
        function setFileDir(obj,~,~)
            
            % prompts the user for the video file directory
            dirName = uigetdir(obj.dDir,'Set The File Directory');
            if dirName
                obj.scanSelectedDir(dirName)
            end
            
            % ensures the figure is visible
            figure(obj.hFig);
            
        end
        
        % --- adds video file callback function
        function addVideoFiles(obj,hBut,~)

            % if nothing is selected then exit
            if isempty(obj.hListC{1}.Value)
                return
            end            
            
            % determines the videos that were selected
            [~,iSel] = intersect(obj.fName,obj.hListC{1}.Value);
            obj.isAdded(iSel) = true;          
            obj.updateConvButtonProps();
            
            % updates the other object properties
            setObjEnable(hBut,0)
            set(obj.hListC{1},'Value',{});
            set(obj.hTxtC,'Text',num2str(sum(obj.isAdded)));
            set(obj.hListC{2},'Items',obj.fName(obj.isAdded))                        
            
        end        
        
        % --- remove video file callback function
        function removeVideoFiles(obj,hBut,~)
          
            % if nothing is selected then exit
            if isempty(obj.hListC{2}.Value)
                return
            end
            
            % determines the videos that were selected
            [~,iSel] = intersect(obj.fName,obj.hListC{2}.Value);
            obj.isAdded(iSel) = false;
            obj.updateConvButtonProps();
            
            % updates the other object properties
            setObjEnable(hBut,0)
            set(obj.hListC{1},'Value',{});            
            set(obj.hTxtC,'Text',num2str(sum(obj.isAdded)));
            set(obj.hListC{2},'Items',obj.fName(obj.isAdded));           
            
        end           
                
        % --- convert video callback functions
        function convertVideos(obj,~,~)
            
            % field retrieval
            iFileC = find(obj.isAdded);
            nFileC = length(iFileC);
            sDataOut = obj.sData;
            
            % if spatially downsampling, set the resize dimensions
            if obj.hObjS{end}.Value
                szD = [obj.frmHght,obj.frmWid];
            end
            
            % sets the output video file names
            outDir = fullfile(obj.fDir,'Converted');            
            vFile = cellfun(@(x)(fullfile(outDir,x)),obj.fName,'un',0);            
            
            % determines if any of the output files already exist
            hasV = cellfun(@(x)(exist(x,'file') > 0),vFile);            
            if any(hasV)
                % if so, then prompt the user if they want to continue
                tStr = 'Overwrite Video Files?';
                qStr = sprintf(['One or more converted files already ',...
                    'exist. Continuing the video conversion process ',...
                    'will overwrite these files.\n\nDo you still want ',...
                    'to continue with the video conversion?']);
                uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
                if ~strcmp(uChoice,'Yes')
                    % if the user cancelled, then exit the function
                    return
                end
            end
            
            % ensures the output file directory exists
            if ~exist(outDir,'dir')
                mkdir(outDir);
            end            
            
            % sets up the progress loadbar
            wStr = {'Overall Progress','Current Video Progress'};
            h = ProgBar(wStr,'Video Conversion');
            
            % converts all of the 
            for i = 1:nFileC
                % updates the main progressbar field
                wStrNw = sprintf('%s (File %i of %i)',wStr{1},i,nFileC);
                h.Update(1,wStrNw,i/(1+nFileC));
                                
                % creates the video reader/writer object
                k = iFileC(i);                
                vObjR = VideoReader(obj.fFile{k});                                
                vObjW = VideoWriter(vFile{k});                
                
                % determines if there is any temporal downsampling                
                if obj.hObjT{end}.Value
                    % if so, update the video frame rate
                    vObjW.FrameRate = obj.fRate;

                    % sets up the downsampling time vector
                    tRate = 1/obj.fRate;
                    T = sDataOut.tStampV{k};
                    tF = tRate*floor(T(end)/tRate);
                    if T(end)-tF > tRate/2
                        tF = tF + tRate;
                    end
                    
                    % calculates the frame indices array
                    TT = (tRate:tRate:tF)';                    
                    D = pdist2(TT,sDataOut.tStampV{k});
                    [~,indF] = min(D,[],2,'omitnan');
                    indF = unique(indF);
                    
                    % resets the time stamp array
                    sDataOut.tStampV{k} = sDataOut.tStampV{k}(indF);
                else
                    % case is there is no temporal downsampling
                    indF = 1:length(sDataOut.tStampV{k});
                end
                
                % opens the video object
                open(vObjW);
                
                % writes all frames within the video
                nFrmF = length(indF);
                for j = 1:nFrmF
                    % updates the progressbar
                    wStrNw = sprintf('%s (Frame %i of %i)',wStr{2},j,nFrmF);
                    if h.Update(2,wStrNw,j/nFrmF)
                        % closes the video object and exits
                        close(vObjW)
                        return
                    end
                    
                    % reads the new frame from the video
                    IfrmNw = read(vObjR,indF(j));
                    if obj.hObjS{end}.Value
                        IfrmNw = imresize(IfrmNw,szD);
                    end
                    
                    % writes the frame to the video output object
                    writeVideo(vObjW,IfrmNw);
                end
                
                % closes the video object
                close(vObjW);
            end
            
            % sets the final summary data struct                        
            sDataOut.tStampV = sDataOut.tStampV(iFileC);
            
            % outputs the summary file
            sFileOut = fullfile(outDir,'Summary.mat');
            save(sFileOut,'-struct','sDataOut');
            
            % deletes the progressbar
            h.closeProgBar();
            
        end
        
        % --- clear all field callback functions
        function clearAllFields(obj,~,~)
           
            % prompts the user if they actually want to continue
            tStr = 'Clear All Fields?';
            qStr = 'Are you sure you want to clear all window fields?';
            uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
            if ~strcmp(uChoice,'Yes')
                % if the user cancelled, then exit
                return
            end
            
            % clears the main fields
            set(obj.hTxtC,'Text','N/A');
            set(obj.hEditD,'Value','','Tooltip','');
            cellfun(@(x)(set(x,'Items',{},'Value',{})),obj.hListC);
            
            % clears the other panels
            obj.clearPanelObjects(obj.hObjS);
            obj.clearPanelObjects(obj.hObjT);
            
            % disables the panels
            hObjIgn = num2cell(findall(obj.hPanelD));
            obj.setPanelProps(obj.hObjS{end},0);
            obj.setPanelProps(obj.hObjT{end},0);
            setPanelProps(obj.hPanelC,0,hObjIgn)
            
        end
        
        % --- temporal parameter editbox callback function
        function editTempPara(obj,hEdit,~)
            
            % field retrieval
            pStr = get(hEdit,'UserData');
            nwVal = str2double(get(hEdit,'Value'));
            pLim = [1,floor(obj.fRateEst)];
            
            % determines if the new value is valid
            if chkEditValue(nwVal,pLim,1)
                % if so, then update the parameter value
                obj.(pStr) = nwVal;
            else
                % otherwise, revert back to the last valid value
                hEdit.Value = num2str(obj.(pStr));
            end
            
        end
        
        % --- spatial parameter editbox callback function
        function editSpatPara(obj,hEdit,~)
            
            % field retrieval            
            pStr = get(hEdit,'UserData');
            isHeight = strcmp(pStr,'frmHeight');
            nwVal = str2double(get(hEdit,'Value'));
            pLim = [50,obj.frmRes(1+isHeight)];
            
            % determines if the new value is valid
            if chkEditValue(nwVal,pLim,1)
                % if so, then update the parameter value
                obj.(pStr) = nwVal;             
                
                % resets the other image dimension
                if isHeight
                    obj.frmWid = roundP(obj.pAR*nwVal);
                    obj.hObjS{2}.Value = num2str(obj.frmWid);
                else
                    obj.frmHght = roundP(nwVal/obj.pAR);
                    obj.hObjS{1}.Value = num2str(obj.frmHght);                    
                end
                
            else
                % otherwise, revert back to the last valid value
                hEdit.Value = num2str(obj.(pStr));
            end
            
        end        
        
        % --- downsampling checkbox selection callback function
        function checkDownsample(obj,hCheck,~)
            
            % updates the panel properties
            obj.setPanelProps(hCheck,1);
            obj.updateConvButtonProps();
                        
        end
        
        % --- listbox selection callback function
        function listBoxSelect(obj,~,~,isLeft)
            
            % updates the selection button enabled properties
            setObjEnable(obj.hButC{1},~isLeft)
            setObjEnable(obj.hButC{2},isLeft)
            
            % removes the list selection for the other listbox
            set(obj.hListC{isLeft+1},'Value',{});
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- scans the selected video file directory 
        function scanSelectedDir(obj,dName)
            
            % determines if there is a valid summary file
            sFile = dir(fullfile(dName,'Summary.mat'));
            if isempty(sFile)
                % if there is no summary file then output an error
                eStr = ['The selected folder must contain a valid ',...
                        '"Summary.mat" file.'];
                waitfor(msgbox(eStr,'Missing Summary File','modal'));
                    
                % exits the function
                return
            end
            
            % determines if the summary file is valid
            obj.sData = load(fullfile(sFile.folder,sFile.name));
            if ~isfield(obj.sData,'iExpt') || ...
                    ~isfield(obj.sData.iExpt,'Video')
                % if there is no summary file then output an error
                eStr = ['The selected folder contains a "Summary.mat" ',...
                    'but it is not valid.'];
                waitfor(msgbox(eStr,'Invalid Summary File','modal'));
                
                % exits the function
                return
            end

            % determines if there are any valid video files
            vExtn = obj.getVideoFileExtn(obj.sData.iExpt.Video.vCompress);
            vFile = dir(fullfile(dName,vExtn));
            if isempty(vFile)
                % if there is no summary file then output an error
                eStr = sprintf(['The selected folder does not have ',...
                    'any "%s" videos files.'],vExtn);
                waitfor(msgbox(eStr,'Missing Summary File','modal'));
                
                % exits the function
                return                
            else
                % sets the objects to ignore
                hObjIgn = {obj.hButS{1},obj.hButC{1},obj.hButC{2}};                

                % checks the time stamps and calculates the frame rate
                obj.checkTimeStamps();
                fRateE = cellfun(@(x)...
                    (mean(1./diff(x),'omitnan')),obj.sData.tStampV);
            end
            
            % updates the data fields
            obj.fDir = dName;
            obj.fName = arrayfun(@(x)(x.name),vFile,'un',0);
            obj.fFile = cellfun(@(x)(fullfile(dName,x)),obj.fName,'un',0);

            % memory allocations
            [obj.nFileTot,obj.nFileAdd] = deal(length(obj.fFile),0);            
            obj.isAdded = false(obj.nFileTot,1);                                    
            
            % enables all panels 
            setPanelProps(obj.hPanelC,1,hObjIgn);
            obj.setPanelProps(obj.hObjS{end},1);
            obj.setPanelProps(obj.hObjT{end},1);
            
            % sets the video object properties
            vObj = VideoReader(obj.fFile{1});
            obj.fRateR = vObj.FrameRate;          
            obj.fRateEst = mean(fRateE);
            obj.fRate = max(1,floor(obj.fRateEst));
            obj.frmRes = [vObj.Width,vObj.Height];            
            frmSz = sprintf('%i x %i',vObj.Width,vObj.Height);            
            [obj.frmWid,obj.frmHght] = deal(vObj.Width,vObj.Height);
            obj.pAR = obj.frmRes(1)/obj.frmRes(2);
            
            % resets the listbox strings
            set(obj.hListC{1},'Items',obj.fName,'Value',{});
            set(obj.hListC{2},'Items',{},'Value',{});
            
            % sets the temporal conversion fields
            set(obj.hObjT{1},'Value',num2str(obj.fRate));
            set(obj.hObjT{2},'Text',sprintf('%.2f',obj.fRateEst));
            
            % sets the spatial conversion fields
            set(obj.hObjS{1},'Value',num2str(obj.frmHght));            
            set(obj.hObjS{2},'Value',num2str(obj.frmWid));
            
            % sets the other object properties
            obj.hTxtC.Text = '0';            
            set(obj.hEditD,'Tooltip',obj.fDir,'Value',[' ',obj.fDir]);
            
        end                        

        % --- updates the conversion button properties
        function updateConvButtonProps(obj)
            
            % updates the conversion button properties
            hasChk = any([obj.hObjS{end}.Value,obj.hObjT{end}.Value]);
            canConv = hasChk && any(obj.isAdded);
            setObjEnable(obj.hButS{1},canConv);
            
        end

        % --- checks on the video time stamps
        function checkTimeStamps(obj)

            %
            for i = 1:length(obj.sData.tStampV)
                % determines the gaps within the time vector
                T = obj.sData.tStampV{i};
                iGrpT = getGroupIndex(T == 0);

                % fills in any gaps within the time vector
                for j = 1:length(iGrpT)
                    if iGrpT{j}(1) == 1
                        % case is group encompasses the first point
                        xiE = iGrpT{j}(end);
                        T(iGrpT{j}) = interp1([0;xiE],[0;T(xiE)],iGrpT{j});

                    elseif iGrpT{j}(end) == length(T)
                        % case is group encompasses the last point
                        a = 1;  % FINISH ME!

                    else
                        % case is another group
                        xiE = arr2vec(iGrpT{j}([1,end])) + [-1;1];
                        T(iGrpT{j}) = interp1(xiE,T(xiE),iGrpT{j});
                    end
                end

                % resets the time vector
                obj.sData.tStampV{i} = T;
            end

        end
                
    end

    % static class methods
    methods (Static)
        
        % --- retrieves the video file extension
        function vExtn = getVideoFileExtn(vComp)
            
            switch vComp
                case {'Archival','Motion JPEG 2000'}
                    % case is the mj2 video type
                    vExtn = '*.mj2';
                    
                case 'MPEG-4'
                    % case is the MPEG-4 video type
                    vExtn = '*.mp4';
                    
                otherwise
                    % case is the other video file type
                    vExtn = '*.avi';
            end
                    
        end
        
        % --- sets the panel properties (local wrapper)
        function setPanelProps(hCheck,isOn)
            
            % retrieves the parent panel
            hPanel = get(hCheck,'Parent');
            
            if isOn
                % case is enabling panel objects
                if get(hCheck,'Value')
                    % case is the checkbox has been selected
                    setPanelProps(hPanel,1);
                else
                    % case is the checkbox has not been selected
                    setObjEnable(hCheck,1)
                    setPanelProps(hPanel,0,hCheck);
                end
            else
                % case is disabling all panel objects
                setPanelProps(hPanel,0);
            end
            
        end        
        
        % --- clears the panel objects
        function clearPanelObjects(hObj)
            
            for i = 1:length(hObj)
                switch hObj{i}.Type
                    case 'uieditfield'
                        % case is an edit field
                        set(hObj{i},'Value','N/A');
                        
                    case 'uilabel'
                        % case is a text label
                        set(hObj{i},'Text','N/A');
                        
                    case 'uicheckbox'
                        % case is a checkbox
                        set(hObj{i},'Value',0);
                end
            end
            
        end        
        
    end
    
end