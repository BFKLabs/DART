classdef TimeSelect < handle
    
    % class properties
    properties
        
        % input arguments
        tVec
        
        %
        hFig
        hPanelT
        hPopupT
        hPanelC
        hButC
        
        % fixed object dimension fields
        dX = 10;
        hghtRow = 25;
        hghtTxt = 16;
        hghtPopup = 23;   
        hghtBut = 25;
        hghtPanelC = 40;
        hghtPanelT = 40;
        widFig = 270;
        widTxtT = 100;
        
        % calculated object dimension fields
        hghtFig
        widPanel
        widPopupT
        widButC
        
        % static class fields
        nButC = 2;
        fSzL = 12;
        fSz = 10 + 2/3;        
        
        % boolean class fields
        isOK = true;
        isChange = false;
        
        % static string fields
        tagStr = 'figTimeSelect';                
        figName = 'Cycle Time Select';                
        
    end
    
    % class methods
    methods
        
        % --- class consructor
        function obj = TimeSelect(tVec)
        
            % sets the input arguments
            obj.tVec = tVec;
            
            % initialises the class objects/fields
            obj.initClassFields();  
            obj.initClassObjects();
            
            % wait until closed
            uiwait(obj.hFig);
            
        end

        % ------------------------------------- %
        % --- CLASS INITALISATION FUNCTIONS --- %
        % ------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % calculated object dimension fields
            obj.hghtFig = obj.hghtPanelC + obj.hghtPanelT + 3*obj.dX;
            obj.widPanel = obj.widFig - 2*obj.dX;
            
            % calculates the other object dimensions
            obj.widPopupT = (obj.widPanel - (obj.widTxtT + 3*obj.dX))/3;
            obj.widButC = (obj.widPanel - ...
                (2 + (obj.nButC-1)/2)*obj.dX)/obj.nButC;
            
        end
        
        % --- initialises the class objects
        function initClassObjects(obj)
            
            % removes any previous GUIs
            hFigPr = findall(0,'tag',obj.tagStr);
            if ~isempty(hFigPr); delete(hFigPr); end
            
            % --------------------------- %
            % --- MAIN FIGURE OBJECTS --- %
            % --------------------------- % 
            
            % creates the figure object
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % creates the figure object
            obj.hFig = createUIObj('figure','Position',fPos,...
                'tag',obj.tagStr,'MenuBar','None','Toolbar','None',...
                'Name',obj.figName,'Resize','off','NumberTitle','off',...
                'Visible','off','CloseRequestFcn',[]);            
            
            % ------------------------------------ %
            % --- CONTROL BUTTON PANEL OBJECTS --- %
            % ------------------------------------ % 
            
            % initialisations
            bStrC = {'Update','Cancel'};
            cbFcnC = {@obj.buttonTimeUpdate,@obj.buttonCloseWindow};
            
            % creates the panel object
            pPosC = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelC];
            obj.hPanelC = createUIObj(...
                'Panel',obj.hFig,'Title','','Position',pPosC);
            
            % creates the button object
            for i = 1:obj.nButC
                % sets up the positional vector
                lPosB = obj.dX*(1+(i-1)/2) + (i-1)*obj.widButC;
                pPosB = [lPosB,obj.dX-2,obj.widButC,obj.hghtBut];
                
                % creates the button objects
                obj.hButC{i} = createUIObj('pushbutton',obj.hPanelC,...
                    'String',bStrC{i},'Position',pPosB,...
                    'FontWeight','Bold','FontSize',obj.fSzL,...
                    'ButtonPushedFcn',cbFcnC{i});
            end
            
            % -------------------------------- %
            % --- TIME POPUP PANEL OBJECTS --- %
            % -------------------------------- %
            
            % initialisations
            tStrP = 'Cycle Start Time: ';
            
            % creates the main panel object
            yPosT = sum(pPosC([2,4])) + obj.dX;            
            pPosT = [obj.dX,yPosT,obj.widPanel,obj.hghtPanelT];            
            obj.hPanelT = createUIObj(...
                'Panel',obj.hFig,'Title','','Position',pPosT);            
            
            % creates the text objects
            pPosT = [obj.dX*[1,1],obj.widTxtT,obj.hghtTxt];            
            createUIObj('text',obj.hPanelT,'Position',pPosT,...
                'FontWeight','Bold','FontUnits','Pixels',...
                'FontSize',obj.fSzL,'HorizontalAlignment','Right',...
                'String',tStrP);
            
            % creates the popup menu items
            lPosPP = sum(pPosT([1,3]));
            for i = 1:3
                % sets the popup menu strings
                switch i
                    case 3
                        % case is the am/pm field
                        pStrPP = {'AM';'PM'};
                        
                    otherwise
                        % case is the hours/minutes fields
                        if i == 1
                            xiT = (0:11)';
                        else
                            xiT = (0:59)';
                        end
                            
                        % sets the final popup menu strings
                        pStrPP = arrayfun(@(x)...
                            (obj.setupTimeValue(x)),xiT,'un',0);
                end
                
                % creates the popup menu items
                pPosPP = [lPosPP,obj.dX-3,obj.widPopupT,obj.hghtPopup];
                createUIObj('popupmenu',obj.hPanelT,'Position',pPosPP,...
                    'FontUnits','Pixels','FontSize',obj.fSz,...
                    'String',pStrPP,'Callback',@obj.popupTimeSelect,...
                    'UserData',i);
                
                % creates the hour/minute separator
                if i == 2
                    pPosG = [(lPosPP-4),yPosT,3,obj.hghtTxt];
                    createUIObj('text',obj.hPanelT,'Position',pPosG,...
                        'FontWeight','Bold','FontUnits','Pixels',...
                        'FontSize',obj.fSzL,'String',':',...
                        'HorizontalAlignment','Center');                    
                end
                
                % increments the left position
                lPosPP = sum(pPosPP([1,3])) + obj.dX/2;
            end
            
            % updates the popup menu item values
            obj.resetTimePopupValues();
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %            
            
            % disables the update/reset buttons
            setObjEnable(obj.hButC{1},0);
            
            % centers the figure and makes it visible
            centerfig(obj.hFig);
            refresh(obj.hFig);
            pause(0.05);
            
            % makes the figure visible
            set(obj.hFig,'Visible','on');               
            
        end
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %
        
        % --- time popupmenu update callback function
        function popupTimeSelect(obj,hPopup,~)
            
            % field retrieval
            iVec = hPopup.UserData;
            obj.tVec(iVec) = hPopup.Value - 1;
            
            % updates the other fields
            obj.isChange = true;
            setObjEnable(obj.hButC{1},1);
            
        end
        
        % ----------------------------------------- %
        % --- CONTROL BUTTON CALLBACK FUNCTIONS --- %
        % ----------------------------------------- %
        
        % --- time update button callback functions
        function buttonTimeUpdate(obj,~,~)
            
            % deletes the figure
            delete(obj.hFig);
            
        end
        
        % --- close window button callback functions
        function buttonCloseWindow(obj,~,~)            
            
            % deletes the figure
            obj.isOK = false;
            delete(obj.hFig);
            
        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- resets the time popup values
        function resetTimePopupValues(obj)
                        
            % resets the popupmenu values
            hPP = findall(obj.hPanelT,'style','popupmenu');
            for j = 1:length(hPP)
                % retrieves the popup menu item
                i = hPP(j).UserData;
                hPP(j).Value = obj.tVec(i) + 1;
            end
            
        end        
        
    end
    
    % static class methods
    methods (Static)
        
        % --- sets up the time value string
        function tStr = setupTimeValue(tVal)
            
            if tVal == 0
                % case is zero
                tStr = '00';
                
            elseif tVal < 10
                % case is time less than 10
                tStr = ['0',num2str(tVal)];
                
            else
                % other case types
                tStr = num2str(tVal);
            end
            
        end
        
    end
    
end