classdef ProgBar < handle
    % class properties
    properties
        % main object properties
        hFig
        wStr
        tStr
        hObj
        hBut     
        hPanel
        
        % boolean flags
        hasCancel = true;
        isVisible = true;
        isCancel = false; 
        
        % figure object dimensions
        dY = 50;
        bOfs = 10;                  % panel border offset
        xyOfs = 20;                 % x/y offset
        bWid = 400;                 % box width
        btWid = 80;                 % button width
        bHgt = 20;                  % box/edit height                        
        
        % other properties
        cProp = 0;
        mxProp = 1;
        fSz = 10;
        wImg = ones(1,1000,3);      
        fldNames = {'wStr','wAxes','wImg'};
    end
    
    % class methods
    methods
        % class constructor
        function obj = ProgBar(wStr,tStr,pType)
           
            % ensures the field strings are stored in a cell array
            if ~iscell(wStr); wStr = {wStr}; end            
            
            % sets the input arguments
            obj.wStr = wStr;
            obj.tStr = tStr;
            
            % if provided, then set the visibility/cancel flags
            if exist('pType','var')
                if pType > 0
                    obj.hasCancel = mod(pType,2) == 0;
                    obj.isVisible = mod(pType,2) == 1;
                end
            end
            
            % initialises the progress bar
            obj.initProgBar();
            
        end
        
        % --- initialises the progressbar
        function initProgBar(obj)
            
            % initialisations
            [x0,y0] = deal(400);
            hObj0 = struct('wStr',[],'wAxes',[],'wImg',[],'wProp',[]);
            
            % memory allocation
            nStr = length(obj.wStr);
            obj.hObj = repmat(hObj0,nStr,1);

            % sets the figure and cancel button position vectors
            if obj.hasCancel
                fPos = [x0,y0,(2*(obj.bOfs+obj.xyOfs)+obj.bWid),...
                            (2*(obj.bOfs+nStr*obj.bHgt)+...
                            (nStr-1)*obj.bOfs+(3*obj.bOfs+obj.bHgt))];      
                pPos = [obj.bOfs,(2*obj.bOfs+obj.bHgt),...
                     (fPos(3)-2*obj.bOfs),(fPos(4)-(3*obj.bOfs+obj.bHgt))];
            else
                fPos = [x0,y0,(2*(obj.bOfs+obj.xyOfs)+obj.bWid)....
                            (2*(obj.bOfs+nStr*obj.bHgt)+...
                            (nStr-1)*obj.bOfs+(2*obj.bOfs))];      
                pPos = [obj.bOfs,obj.bOfs,(fPos(3)-2*obj.bOfs),...
                            (fPos(4)-(2*obj.bOfs))];            
            end

            % creates the dialog box
            if obj.isVisible                
                obj.hFig = dialog('position',fPos,'tag','ProgBar',...
                                  'name',obj.tStr);
            else
                obj.hFig = dialog('position',fPos,'tag','ProgBar',...
                                  'name',obj.tStr,'visible','off');
            end

            % creates the inner panel
            obj.hPanel = uipanel(obj.hFig,'units','pixels','position',pPos);

            % creates a cancel button (if required)
            if obj.hasCancel
                btPos = [(fPos(3)-(obj.btWid+obj.bOfs)),...
                          obj.bOfs,obj.btWid,obj.bHgt];                             
                      
                obj.hBut = uicontrol(obj.hFig,'style','togglebutton',...
                            'string','Cancel','tag','buttonCancel',...
                            'position',btPos,'Callback',@obj.cancelClick);
            else
                obj.hBut = [];
            end
            
            % sets the dialog windowstyle
            set(obj.hFig,'windowstyle','normal')

            % sets up the waitbar statuses for each of the figure items
            for i = 1:nStr
                % sets the positions of the current waitbar objects        
                posAx = [obj.xyOfs,(i*obj.bOfs)+(i-1)*(2*obj.bHgt),...
                         obj.bWid,obj.bHgt];
                posStr = posAx + [0,obj.bHgt,0,0];

                % creates the waitbar objects
                j = nStr - (i-1);    
                obj.hObj(j).wAxes = axes('parent',obj.hPanel,...
                            'units','pixels','position',posAx);    
                obj.hObj(j).wStr = uicontrol(obj.hPanel,'style','text',...
                            'position',posStr,'FontSize',obj.fSz,...
                            'string',obj.wStr{j});                                   
                obj.hObj(j).wImg = ...
                            image(obj.wImg,'parent',obj.hObj(j).wAxes);
                obj.hObj(j).wProp = 0;
                
                % sets the axes properties
                set(obj.hObj(j).wAxes,'xtick',[],'ytick',[],...
                                      'xticklabel',[],'yticklabel',[],...
                                      'xcolor','k','ycolor','k','box','on')    

                % fixes a small bug in the new release where the box line 
                % on the upper limit is missing for the last waitbar axes
                if i == 1
                    % retrieves the axes limits
                    xL = get(obj.hObj(j).wAxes,'xlim');
                    yL = get(obj.hObj(j).wAxes,'ylim');
                    
                    % plots the outer line
                    hold(obj.hObj(j).wAxes,'on')
                    plot(obj.hObj(j).wAxes,xL,yL(1)*[1 1],'k','linewidth',2)
                end

                % updates the dialog window handles
                guidata(obj.hFig,obj.hObj(j))
            end

            % sets the object data into the gui
            set(obj.hFig,'windowstyle','normal')
            
        end
        
        % --- callback function for clicking the cancel button
        function cancelClick(obj,hObject,eventdata)
            
            % updates the cancellation flag
            obj.isCancel = true;
            
            % resets the button properties so the user can't un-cancel
            setObjEnable(hObject,'inactive');
            
        end       
        
        % --- updates the progressbar
        function isCancel = Update(obj,ind,wStrNw,wPropNw)

            % if the user cancelled (or the figure was deleted) then return
            % a true values for cancellation
            if obj.isCancel || ~isvalid(obj.hFig)
                % sets the cancel flag and closes the progressbar
                isCancel = true;
                obj.closeProgBar();
                
                % exits the function
                return
            else
                % otherwise, flag that the user didn't cancel
                isCancel = false;
            end            

            % sets the new image
            wLen = roundP(wPropNw*1000,1);
            obj.wImg(:,1:wLen,2:3) = 0;
            obj.wImg(:,(wLen+1):end,2:3) = 1;

            % updates the proportional value
            obj.hObj(ind).wProp = wPropNw;

            % updates the status bar and the string
            set(obj.hObj(ind).wImg,'cdata',obj.wImg);
            set(obj.hObj(ind).wStr,'string',wStrNw)
            drawnow;                        
            
        end
        
        % --- gets the class field values, pStr
        function pVal = getClassField(obj,pStr)
            
            pVal = eval(sprintf('obj.%s;',pStr));
            
        end
        
        % --- sets the class field, pStr, with the value pVal
        function setClassField(obj,pStr,pVal)
            
            eval(sprintf('obj.%s = pVal;',pStr));
            
        end
        
        % --- collapses the progress bar by nLvl rows
        function collapseProgBar(obj,nLvl)

            % sets the indices
            [sLvl,nLvl] = deal(sign(nLvl),abs(nLvl));
            [nObj,mlt] = deal(length(obj.hObj),1-2*(sLvl > 0));

            % resets the figure/panel heights
            try
                resetObjPos(obj.hPanel,'height',mlt*obj.dY*nLvl,1)
                resetObjPos(obj.hFig,'height',mlt*obj.dY*nLvl,1)   
            catch
                return
            end

            % determines the number of rows in the new waitbar figure
            hPos = get(obj.hPanel,'Position');
            hRow = roundP((hPos(4) - 10)/obj.dY);

            % resets the locations of all the sub-units
            for i = 1:nObj        
                % retrieves the new object handles for the current row
                A = cellfun(@(x)(...
                        sprintf('obj.hObj(i).%s',x)),obj.fldNames,'un',0);
                hObjNw = cellfun(@eval,A,'un',0);    

                % sets the properties based on the new values
                try
                    resetObjPos(hObjNw(1:2),'bottom',mlt*obj.dY*nLvl,1)
                    cellfun(@(x)(setObjVisibility(x,i <= hRow)),hObjNw) 
                catch
                    return
                end
            end

            % makes the waitbar figure visible again
            pause(0.05);            
            
        end
        
        % --- expands the progress bar by nLvl rows
        function expandProgBar(obj,nLvl)
            
            obj.collapseProgBar(-abs(nLvl))
            
        end        
        
        % --- closes the progress bar (if not already deleted)
        function closeProgBar(obj)
            
            try
                delete(obj.hFig)
            end
            
        end                
            
        % -- sets the progressbar visibility
        function setVisibility(obj,state)

            if islogical(state)
                eStr = {'off','on'};
                setObjVisibility(obj.hFig,eStr{1+state});
            else
                setObjVisibility(obj.hFig,state);
            end

            % pause to allow update
            pause(0.05);
        end            
    end
    
    % static class methods
    methods (Static)
        
    end
end
