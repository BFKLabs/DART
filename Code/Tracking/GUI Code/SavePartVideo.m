classdef SavePartVideo < handle
    
    % properties
    properties
    
        % input variables
        hFigM
        hGUIM
        hEditI
        hCheckSM
        hCheckLV                
        hAx
        
        % function handles
        fcnI
        fcnSM
        fcnLV
        
        % main class fields
        T
        fPath
        nFPS
        ivProf
        nPath = 1;
        
        % object handle fields
        hFig
        hPanelO
        
        % file path object handle fields
        hPanelP
        hEditP
        hButP
        hCheckP
        hTxtPL
        hEditPL
        hTxtPF
        hEditPF
        
        % frame limit object handle fields
        hPanelF
        hEditF
        hLblF
        
        % time limit object handle fields
        hPanelT
        hEditT
        hLblT
        
        % control button object handle fields
        hPanelC
        hButC        
        
        % time/frame limit fields
        iFrm1
        iFrm2
        tFrm1
        tFrm2        
        nFrm
        tDur
        nFrmT
        tFrmT
        
        % fixed object dimensions
        dX = 10;
        hghtRow = 25;
        hghtTxt = 16;
        hghtEdit = 21;
        hghtCheck = 22;
        hghtBut = 25;
        hghtPanelP = 80;
        hghtPanelF = 55;
        hghtPanelT = 65;
        hghtPanelC = 40;        
        widPanelO = 520;        
        widCheckP = 145;
        widTxtPL = [90,110];
        widEditPL = 50;
        widTxtF = 85;
        widTxtFL = 50;        
        widTxtT = [85,85,65];
        widEditT = 25;
        widTxtTL = 75;
        
        % calculated object dimensions
        widFig
        hghtFig
        hghtPanelO
        widPanel
        widEditP
        widEditF
        widButC
        
        % boolean class fields
        useTrack = true;
        
        % static scalar fields
        fSzH = 13;
        fSzL = 12;
        fSzP = 16;
        fSz = 10 + 2/3;
        nButC = 2;
        
        % static character fields
        wStrT = 'MOVIE TIME LIMITS';    
        wStrF = 'MOVIE FRAME LIMITS';
        wStrP = 'OUTPUT FILE PROPERTIES';        
        tagStr = 'figSaveMovie';
        figName = 'Partial Video Output';
        
        % static array fields
        tStrG = {'H','M','S'};
        lStr = {'Start','Finish'};
        bStrC = {'Save Partial Movie','Close Window'};
        fMode = {'*.avi','AVI Video File (*.avi)';...
                 '*.mp4','MP4 Video File (*.mp4)'};        
        vProf = {'Motion JPEG AVI','MPEG-4'};
             
    end
    
    % class methods
    methods                
        
        % --- class constructor
        function obj = SavePartVideo(hFigM)
            
            % sets the input arguments
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
            
            % initialisations
            iData = obj.hFigM.iData;
            sRate = obj.hFigM.iMov.sRate;
            
            % field retrieval
            obj.nFrmT = obj.hFigM.iData.nFrm;
            obj.nFPS = obj.hFigM.iData.exP.FPS;
            obj.T = obj.hFigM.iData.Tv(iData.Frm0:sRate:end);            
            
            % sets the start/frame indices
            obj.iFrm1 = 1;
            obj.iFrm2 = obj.nFrmT;
            obj.tFrm1 = [0,0,0];
            [obj.tFrm2,obj.tFrmT] = deal(obj.setupTimeVec(obj.T(end)));
            
            % memory allocation
            obj.hButC = cell(obj.nButC,1);
            [obj.hEditF,obj.hEditT] = deal(cell(2,1));
            
            % main figure checkbox handles
            obj.hGUIM = guidata(obj.hFigM);
            obj.hAx = findall(obj.hFigM,'type','axes');
            obj.hEditI = findall(obj.hFigM,'tag','frmCountEdit');
            obj.hCheckSM = findall(obj.hFigM,'tag','checkShowMark');
            obj.hCheckLV = findall(obj.hFigM,'tag','checkLocalView');                        
            
            % main figure function handles
            obj.fcnI = obj.hFigM.dispImage;
            obj.fcnLV = obj.hFigM.checkLocalView_Callback;
            obj.fcnSM = obj.hFigM.checkShowMark_Callback;
            
            % ------------------------------------- %
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- %                        
            
            % minor panel dimension calculations
            obj.widPanel = obj.widPanelO - 2*obj.dX;            
            obj.hghtPanelO = (obj.hghtPanelP + obj.hghtPanelF + ...
                obj.hghtPanelT + obj.hghtPanelC) + 3*obj.dX;
            
            % other object dimension calculations            
            obj.widEditP = obj.widPanel - (2.5*obj.dX + obj.hghtBut);
            obj.widButC = (obj.widPanel - 2*obj.dX)/obj.nButC;            
            obj.widEditF = (obj.widPanel - ...
                (2.5*obj.dX + 3*obj.widTxtF + obj.widTxtFL))/2;
            
            % figure dimension calculations
            obj.widFig = obj.widPanelO + 2*obj.dX;
            obj.hghtFig = obj.hghtPanelO + 2*obj.dX;
            
        end
        
        % --- initalises the class objects
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
                'CloseReq',@obj.closeWindow);

            % creates the outer panel object
            pPosO = [obj.dX*[1,1],obj.widPanelO,obj.hghtPanelO];
            obj.hPanelO = createUIObj('panel',obj.hFig,...
                'Title','','Position',pPosO);

            % ------------------------------------ %
            % --- CONTROL BUTTON PANEL OBJECTS --- %
            % ------------------------------------ %
            
            % object properties
            cbFcnC = {@obj.saveMovie,@obj.closeWindow};            
            
            % creates the panel object
            pPosC = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelC];
            obj.hPanelC = createUIObj('panel',obj.hPanelO,...
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
            setObjEnable(obj.hButC{1},0);
            
            % --------------------------------- %
            % --- TIME LIMITS PANEL OBJECTS --- %
            % --------------------------------- %            
            
            % creates the panel object
            yPosT = sum(pPosC([2,4])) + obj.dX/2;
            pPosT = [obj.dX,yPosT,obj.widPanel,obj.hghtPanelT];
            obj.hPanelT = createUIObj('panel',obj.hPanelO,...
                'FontSize',obj.fSzH,'Title',obj.wStrT,...
                'FontWeight','Bold','Units','Pixels','Position',pPosT);
            
            % creates the frame limit text/edit groups
            for i = 1:length(obj.lStr)
                obj.hEditT{i} = obj.createTimeGroup(i); 
                setObjEnable(obj.hEditT{i}{1},obj.tFrmT(1)>0);
                obj.updateDurationFields(i);
            end            
            
            % creates the text label group
            xOfs = sum(obj.hEditT{end}{end}.Position([1,3])) + obj.dX/2;
            obj.hLblT = obj.createTextLabel(obj.hPanelT,...
                'Duration',xOfs,obj.widTxtT(end),obj.widTxtTL);             
            obj.updateDuration();            
            
            % ---------------------------------- %
            % --- FRAME LIMITS PANEL OBJECTS --- %
            % ---------------------------------- %

            % creates the panel object
            yPosF = sum(pPosT([2,4])) + obj.dX/2;
            pPosF = [obj.dX,yPosF,obj.widPanel,obj.hghtPanelF];
            obj.hPanelF = createUIObj('panel',obj.hPanelO,...
                'FontSize',obj.fSzH,'Title',obj.wStrF,...
                'FontWeight','Bold','Units','Pixels','Position',pPosF);
            
            % creates the frame limit text/edit groups
            for i = 1:length(obj.lStr)
                % group initialisations
                xOfs = (1+(i-1)/2)*obj.dX + ...
                    (i-1)*(obj.widTxtF + obj.widEditF);
                cbFcnF = {@obj.editFrameLimits,i};
                tStrTF = sprintf('%s %s',obj.lStr{i},'Frame'); 
                
                % creates the text/edit group
                obj.hEditF{i} = obj.createTextEdit(obj.hPanelF,...
                    tStrTF,xOfs,obj.widTxtF,obj.widEditF,cbFcnF);                   
                obj.updateFrameField(i);                                
            end
            
            % creates the text label group
            xOfs = sum(obj.hEditF{end}.Position([1,3])) + obj.dX/2;
            obj.hLblF = obj.createTextLabel(obj.hPanelF,...
                'Frame Count',xOfs,obj.widTxtF,obj.widTxtFL);             
            obj.updateFrameCount();
            
            % ------------------------------- %
            % --- FILE PATH PANEL OBJECTS --- %
            % ------------------------------- %
            
            % initialisations
            tStrT = 'Path Length';            
            tStrC = 'Display Object Paths';
            tStrF = 'Video Frame Rate';
            cbFcnPL = @obj.editPathLength;
            cbFcnPF = @obj.editFrameRate;
            
            % creates the panel object
            yPosP = sum(pPosF([2,4])) + obj.dX/2;
            pPosP = [obj.dX,yPosP,obj.widPanel,obj.hghtPanelP];
            obj.hPanelP = createUIObj('panel',obj.hPanelO,...
                'FontSize',obj.fSzH,'Title',obj.wStrP,...
                'FontWeight','Bold','Units','Pixels','Position',pPosP);
            
            % creates the checkbox object
            pPosCP = [obj.dX,obj.dX-2,obj.widCheckP,obj.hghtCheck];
            obj.hCheckP = createUIObj('checkbox',obj.hPanelP,...
                    'FontUnits','Pixels','FontWeight','Bold',...
                    'String',tStrC,'Callback',@obj.useTrackPath,...
                    'FontSize',obj.fSzL,'Value',obj.useTrack,...
                    'Position',pPosCP);
            
            % creates the path length text/editbox combo
            xOfs = sum(pPosCP([1,3]));
            [obj.hEditPL,obj.hTxtPL] = obj.createTextEdit(obj.hPanelP,...
                tStrT,xOfs,obj.widTxtPL(1),obj.widEditPL,cbFcnPL);   
            obj.hEditPL.String = num2str(obj.nPath);
            
            % creates the path length text/editbox combo
            xOfs = sum(obj.hEditPL.Position([1,3])) + obj.dX/2;
            obj.hEditPF = obj.createTextEdit(obj.hPanelP,...
                tStrF,xOfs,obj.widTxtPL(2),obj.widEditPL,cbFcnPF);   
            obj.hEditPF.String = num2str(obj.nFPS);            
            
            % creates the file path editbox
            pPosPE = [obj.dX+[0,obj.hghtRow],obj.widEditP,obj.hghtEdit];
            obj.hEditP = createUIObj('edit',obj.hPanelP,...
                'position',pPosPE,'FontSize',obj.fSz,...
                'Enable','Inactive','HorizontalAlignment','Left');
                
            % creates the pushbutton object
            xOfsPB = sum(pPosPE([1,3])) + obj.dX/2;
            pPosPB = [xOfsPB,pPosPE(2)-2,obj.hghtBut*[1,1]];
            obj.hButP = createUIObj('pushbutton',obj.hPanelP,...
                'Position',pPosPB,'FontSize',obj.fSzP,...
                'String','...','FontWeight','bold',...
                'ButtonPushedFcn',@obj.setFilePath);
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
                        
            % centers and refreshes the figure
            centerfig(obj.hFig);
            refresh(obj.hFig);
            
            % makes the window visible
            setObjVisibility(obj.hFig,1);
            pause(0.05);
            drawnow                        
            
        end

        % ----------------------------------------------- %        
        % --- GROUPED OBJECT INITIALISATION FUNCTIONS --- %
        % ----------------------------------------------- %
        
        % --- creates the text/edit object combination
        function [hEdit,hTxt] = ...
                createTextEdit(obj,hP,tStr,xOfs,tWid,eWid,cbFcn)
            
            % field retrieval
            pLbl = sprintf('%s: ',tStr);
            
            % creates the text label
            pPosT = [xOfs,obj.dX,tWid,obj.hghtTxt];
            hTxt = createUIObj('text',hP,'position',pPosT,...
                'FontUnits','Pixels','FontSize',obj.fSzL,...
                'String',pLbl,'HorizontalAlignment','right',...
                'FontWeight','Bold');   
            
            % creates the editbox object
            lPosE = sum(pPosT([1,3]));
            pPosE = [lPosE,obj.dX-2,eWid,obj.hghtEdit];
            hEdit = createUIObj('edit',hP,'position',pPosE,...
                'FontSize',obj.fSz,'Callback',cbFcn);
            
        end
        
        % --- creates the text/edit object combination
        function hTxt = createTextLabel(obj,hP,tStr,xOfs,tWid,eWid)
            
            % field retrieval
            pLbl = sprintf('%s: ',tStr);
            
            % creates the text label
            pPosT = [xOfs,obj.dX+2,tWid,obj.hghtTxt];
            createUIObj('text',hP,'position',pPosT,...
                'FontUnits','Pixels','FontSize',obj.fSzL,...
                'String',pLbl,'HorizontalAlignment','right',...
                'FontWeight','Bold');
            
            % creates the editbox object
            lPosE = sum(pPosT([1,3]));
            pPosE = [lPosE,obj.dX+2,eWid,obj.hghtTxt]; 
            hTxt = createUIObj('text',hP,'position',pPosE,...
                'FontUnits','Pixels','FontSize',obj.fSzL,...
                'FontWeight','Bold');            
            
        end        
        
        % --- creates the time editbox group
        function hEditG = createTimeGroup(obj,iType)
            
            % initialisations
            hP = obj.hPanelT;
            yPosT = obj.dX + obj.hghtEdit + 1;            
            pLbl = sprintf('%s Time: ',obj.lStr{iType});
            xOfs = (iType-1)*(2*obj.widTxtF + obj.dX/2) + obj.dX;
            
            % creates the text label
            pPosT = [xOfs,obj.dX+2,obj.widTxtT(iType),obj.hghtTxt];
            createUIObj('text',hP,'position',pPosT,...
                'FontUnits','Pixels','FontSize',obj.fSzL,...
                'String',pLbl,'HorizontalAlignment','right',...
                'FontWeight','Bold');            
            
            % creates the time label/editboxes
            xOfsG = sum(pPosT([1,3]));
            hEditG = cell(length(obj.tStrG),1);
            for i = 1:length(obj.tStrG)
                % creates the editbox
                pPosE = [xOfsG,obj.dX,obj.widEditT,obj.hghtEdit];
                hEditG{i} = createUIObj('edit',hP,'Position',pPosE,...
                    'FontSize',obj.fSz,'Callback',@obj.editDuration,...
                    'UserData',[iType,i]);                
                
                % creates the text label
                pPosT = [xOfsG,yPosT,obj.widEditT,obj.hghtTxt];
                createUIObj('text',hP,'position',pPosT,...
                    'FontUnits','Pixels','FontSize',obj.fSzL,...
                    'String',obj.tStrG{i},'FontWeight','Bold');
                
                % places the colon operator (except for last editbox)
                if i < length(obj.tStrG)
                    lPosC = sum(pPosE([1,3]));
                    pPosC = [lPosC,obj.dX+2,5,obj.hghtTxt];
                    createUIObj('text',hP,'position',pPosC,...
                        'FontUnits','Pixels','FontSize',obj.fSzL,...
                        'String',':','FontWeight','Bold');                                
                end
                
                % increments the horizontal offset
                xOfsG = xOfsG + hEditG{i}.Position(3) + obj.dX/2;
            end
            
        end
        
        % ---------------------c-------------------- %
        % --- CONTROL BUTTON CALLBACK FUNCTIONS --- %
        % ----------------------------------------- %
        
        % --- save movie button callback functions
        function saveMovie(obj, ~, ~)
            
            % deletes any existing files
            if exist(obj.fPath,'file')
                delete(obj.fPath);
            end                                
            
            % ensures the full image is being viewed
            if obj.hCheckLV.Value
                obj.hCheckLV.Value = false;
                obj.fcnLV(obj.hCheckLV,[],obj.hGUIM);
                drawnow
            end
            
            % ensures the path length has been set correctly
            if xor(obj.hCheckSM.Value,obj.useTrack)
                obj.hCheckSM.Value = ~obj.hCheckSM.Value;
                obj.fcnSM(obj.hCheckSM,[],obj.hGUIM);
                drawnow
            end
            
            % ensures the path length is set correctly
            if obj.useTrack
                a = 1;
            end
            
            % other pre-calculations
            wStr0 = 'Video Output';
            nFrmOut = (obj.iFrm2 - obj.iFrm1) + 1;

            % sets up the progressbar
            hProg = ProgBar(wStr0,'Multi-Tracking Video Output');
            pause(0.05);
            
            % ------------------------- %            
            % --- VIDEO FILE OUTPUT --- %
            % ------------------------- %                    
            
            % sets up the video object
            vObj = VideoWriter(obj.fPath,obj.vProf{obj.ivProf});
            vObj.FrameRate = obj.nFPS;
            open(vObj);            
            
            % outputs the frame for each frame
            for i = 1:nFrmOut
                % updates the progress bar
                wStr = sprintf('%s (Frame %i of %i)',wStr0,i,nFrmOut);
                if hProg.Update(1,wStr,i/(nFrmOut+1))
                    % closes and deletes the video file
                    close(vObj)
                    delete(obj.fPath);
                    
                    % exits the function
                    return
                end                
                
                % updates the main plot axes
                obj.hEditI.String = num2str(obj.iFrm1 + (i-1));
                obj.fcnI(obj.hGUIM);
                drawnow;
                
                % writes the frame to the video object
                writeVideo(vObj,getframe(obj.hAx));
            end                        
                        
            % closes the video object
            close(vObj)            
            
            % closes the loadbar (if still open)
            if ~hProg.Update(1,'Video Output Complete!',1)
                pause(0.5);
                hProg.closeProgBar;
            end            
            
        end
        
        % --- close window button callback functions
        function closeWindow(obj, ~, ~)
            
            delete(obj.hFig);
            
        end
                
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %
        
        % --- file path setting pushbutton callback function
        function setFilePath(obj, ~, ~)
            
            % initialisations
            tStr = 'Set Video Filename';            
            dDir = obj.hFigM.ppDef.DirMov;
            
            % prompts the user for the movie filename
            [fName,fDir,fIndex] = uiputfile(obj.fMode,tStr,dDir);
            if fIndex == 0
                % if the user cancelled, then exit the function
                return
            end
            
            % sets the file path
            obj.ivProf = fIndex;
            obj.fPath = fullfile(fDir,fName);
            
            % updates the properties for the other objects
            set(obj.hEditP,'String',obj.fPath);
            setObjEnable(obj.hButC{1},1);
                             
        end        
        
        % --- use track path checkbox callback function
        function useTrackPath(obj, hCheck, ~)
            
            % updates the use tracking field
            obj.useTrack = hCheck.Value;
            
            % sets the path length object properties
            setObjEnable(obj.hTxtPL,obj.useTrack);
            setObjEnable(obj.hEditPL,obj.useTrack);            
            
        end
        
        % --- frame path length callback function
        function editPathLength(obj, hEdit, ~)
            
            % field retrieval
            nwLim = [1,100];            
            nwVal = str2double(hEdit.String);
            
            % determines if the new value is valid
            if chkEditValue(nwVal,nwLim,1)
                % if so, then update the parameter
                obj.nPath = nwVal;
                
            else
                % otherwise, reset the parameter value
                hEdit.String = num2str(obj.nPath);
            end
            
        end        
        
        % --- frame rate editbox callback function
        function editFrameRate(obj, hEdit, ~)
            
            % field retrieval
            nwLim = [1,100];            
            nwVal = str2double(hEdit.String);
            
            % determines if the new value is valid
            if chkEditValue(nwVal,nwLim,1)
                % if so, then update the parameter
                obj.nFPS = nwVal;
                
            else
                % otherwise, reset the parameter value
                hEdit.String = num2str(obj.nFPS);
            end            
            
        end
        
        % --- frame limits editbox callback function
        function editFrameLimits(obj, hEdit, ~, iType)
            
            % field retrieval
            nwLim = [1,obj.nFrmT];            
            nwVal = str2double(hEdit.String);
            pStr = sprintf('iFrm%i',iType);
            
            % sets the limit based on the group type
            if iType == 1
                nwLim(2) = obj.iFrm2 - 1;
            else
                nwLim(1) = obj.iFrm1 + 1;
            end
            
            % determines if the new value is valid
            if chkEditValue(nwVal,nwLim,1)
                % if so, then update the parameter
                obj.(pStr) = nwVal;
                obj.recalcTimeLimit(iType);
                
                % updates the other object properties                
                obj.updateFrameCount();
                obj.updateDuration();
                obj.updateDurationFields(iType);                
                
            else
                % otherwise, reset the parameter value
                hEdit.String = num2str(obj.(pStr));
            end
            
        end
        
        % --- time limit editbox callback function
        function editDuration(obj, hEdit, ~)
            
            % field retrieval 
            iObj = hEdit.UserData;
            [iType,indT] = deal(iObj(1),iObj(2));
            nwVal = str2double(hEdit.String);
            pStr = sprintf('tFrm%i',iType);  
            
            % sets the parameter field limits
            if indT == 1
                % case is the hours editbox
                if iType == 1
                    nwLim = [0,obj.tFrm2(1)];
                else
                    nwLim = [obj.tFrm1(1),obj.tFrmT(1)];
                end
            else
                % case is the other editbox fields
                nwLim = [0,60];
            end
            
            % determines if the new value is valid
            [ok,eStr] = chkEditValue(nwVal,nwLim,1);            
            if ok
                % determines if the new duration is feasible
                [ok,eStr] = obj.checkDurField(nwVal,iType,indT);
                if ok
                    % if so, then update the parameter
                    obj.(pStr)(indT) = nwVal;
                    hEdit.String = obj.convertTimeString(nwVal);
                    obj.recalcFrameLimit(iType);
                    
                    % updates the other object properties
                    obj.updateFrameCount();
                    obj.updateDuration();
                    obj.updateFrameField(iType);                    
                end
                
            end
                
            % if there was an error, then reset the editbox
            if ~isempty(eStr)
                % outputs the error message to screen
                waitfor(msgbox(eStr,'Parameter Update Error','modal'));
            
                % otherwise, reset the parameter value
                hEdit.String = obj.convertTimeString(obj.(pStr)(indT));
            end            
            
        end

        % ------------------------------ %        
        % --- FIELD UPDATE FUNCTIONS --- %
        % ------------------------------ %
       
        % --- updates the frame count labels
        function updateFrameCount(obj)
            
            nFrmC = (obj.iFrm2 - obj.iFrm1) + 1;
            obj.hLblF.String = num2str(nFrmC);
            
        end
        
        % --- updates the frame limits for limit type, iType
        function updateFrameField(obj, iType)
            
            nwStr = num2str(obj.(sprintf('iFrm%i',iType)));
            obj.hEditF{iType}.String = nwStr;
            
        end

        % --- updates the video duration label
        function updateDuration(obj)
            
            dtDur = duration(obj.tFrm2) - duration(obj.tFrm1);
            obj.hLblT.String = char(dtDur);
            
        end        
        
        % --- updates the frame limits for limit type, iType
        function updateDurationFields(obj, iType)
            
            % field retrieval
            hEditG = obj.hEditT{iType};
            pStr = sprintf('tFrm%i',iType);
            pVal = strsplit(char(duration(obj.(pStr))),':');
                        
            % updates the time fields
            for i = 1:length(hEditG)
                hEditG{i}.String = pVal{i};
            end
            
        end        

        % ------------------------------ %
        % --- VIDEO OUTPUT FUNCTIONS --- %
        % ------------------------------ %
        
        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- determines if the new duration value is feasible
        function [ok,eStr] = checkDurField(obj,nwVal,iType,indT)
            
            % initialisations
            [ok,eStr] = deal(true,[]);
            
            % sets the temporary time values
            tFrm = {obj.tFrm1,obj.tFrm2};
            tFrm{iType}(indT) = nwVal;
            
            % calculates the time difference 
            tFrmF = seconds(duration(tFrm{2}));
            dT = tFrmF - seconds(duration(tFrm{1}));
            if (dT < 0) || (tFrmF > obj.T(end))
                % if not, then output an error to screen
                ok = false;
                eStr = ['The entered start/finish time limits ',...
                        'are not feasible.'];
            end
            
        end
        
        % --- recalculates the iType frame limit 
        function recalcFrameLimit(obj,iType)
            
            % sets the parameter strings
            pStrF = sprintf('iFrm%i',iType);
            pStrT = sprintf('tFrm%i',iType);
            
            % resets the frame index
            ii = obj.T <= seconds(duration(obj.(pStrT)));            
            if any(ii)
                obj.(pStrF) = find(ii,1,'last');
            else
                obj.(pStrF) = 1;
            end
            
        end
        
        % --- recalculates the time limits
        function recalcTimeLimit(obj,iType)
            
            % sets the parameter strings
            pStrF = sprintf('iFrm%i',iType);
            pStrT = sprintf('tFrm%i',iType);
            
            % updates the time vector and objects
            obj.(pStrT) = obj.setupTimeVec(obj.T(obj.(pStrF)));
            obj.updateDurationFields(iType);
            
        end
        
    end
    
    % static class methods
    methods (Static)
        
        % --- resets the time editbox value
        function tStr = convertTimeString(nwVal)
            
            if nwVal < 10
                tStr = sprintf('0%i',nwVal);
            else
                tStr = num2str(nwVal);
            end
            
        end
        
        % --- converts the time, Ts, to the time vector, Tv
        function Tv = setupTimeVec(Ts)
            
            Tf = duration(seconds(Ts),'Format','hh:mm:ss');
            Tv = cellfun(@str2double,strsplit(char(Tf),':'));
            
        end
        
    end
    
end