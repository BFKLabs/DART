classdef AxesContextMenu < handle
    
    % class properties
    properties
        % input objects
        hFig
        hAx
        mStr
        
        % created objects
        hMenu
        hLbl
        hMenuCB
        cbFcn
        mP0
        
        % parameters
        fSz = 11;

        % object dimensions
        dW = 6;
        dY = 2;
        dX = [3,6];
        wChk = 15;
        
        % other parameters
        nLbl = 0;
        iSel = 0;
        tickStr = char(hex2dec('2713'));
        tHght
        tWid        
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = AxesContextMenu(hFig,hAx,mStr)
            
            % sets the input parameters
            obj.hFig = hFig;
            obj.hAx = hAx;
            obj.mStr = mStr;            

            % creates the menu panel
            obj.hMenu = uipanel('Title','','Units','Pixels','tag',...
                                'hMenu','Visible','off');                           
                              
            % updates the menu labels
            obj.updateMenuLabels();
            
        end        
        
        % --- updates the menu labels 
        function updateMenuLabels(obj,mStrNw)
            
            % updates the menu label strings (if provided)
            if exist('mStrNw','var')
                obj.mStr = mStrNw;
            end
            
            % initialisations
            nLblNw = length(obj.mStr);
            obj.getTextDim();
            
            % updates the menu width
            pWid = sum(obj.dX)+obj.wChk+obj.tWid;
            resetObjPos(obj.hMenu,'Width',pWid);
            
            % updates the menu height
            pHght = (4+(nLblNw-1))*obj.dY+nLblNw*obj.tHght;            
            resetObjPos(obj.hMenu,'Height',pHght);
            
            %
            if obj.nLbl > nLblNw
                % case is there are more labels than required
                iDel = (nLblNw+1):obj.nLbl;
                
                % reduces the label array
                cellfun(@delete,obj.hLbl(iDel,:));
                obj.hLbl = obj.hLbl(1:nLblNw,:);
                
            elseif obj.nLbl < nLblNw
                % case is there are less labels than required
                nAdd = nLblNw-obj.nLbl;
                
                % expands the array
                obj.hLbl = [obj.hLbl;cell(nAdd,2)];                
                for i = (obj.nLbl+1):nLblNw
                    % calculates the object y-location
                    yTxt = (2+(i-1))*obj.dY + (i-1)*obj.tHght;   
                    
                    % creates the checkbox text label
                    tPos1 = [obj.dX(1),yTxt,obj.wChk,obj.tHght];
                    obj.hLbl{i,1} = uicontrol('Parent',obj.hMenu,...
                              'Style','text','Units','Pixels',...
                              'Position',tPos1,'FontUnits','Pixels',...
                              'FontSize',obj.fSz,'horizontalalignment',...
                              'left');   
                          
                    % creates the label text label
                    tPos2 = [obj.dX(1)+obj.wChk,yTxt,obj.tWid,obj.tHght];    
                    obj.hLbl{i,2} = uicontrol('Parent',obj.hMenu,...
                              'Style','text','Units','Pixels',...
                              'Position',tPos2,'FontUnits','Pixels',...
                              'FontSize',obj.fSz,'horizontalalignment',...
                              'left');  
                          
                end
            end
            
            % updates the label strings
            obj.nLbl = nLblNw;
            for i = 1:obj.nLbl
                % sets the global indices
                j = obj.nLbl - (i - 1);
                
                % updates the label strings
                set(obj.hLbl{i,1},'UserData',j);
                set(obj.hLbl{i,2},'UserData',j,'String',obj.mStr{j});                
            end
            
        end
        
        % --- sets the menu highlight colour
        function setMenuHighlight(obj,iLbl,isOn)
            
            % if the label index is zero, then exit the function
            if iLbl == 0
                return
            end
            
            % sets the 
            bCol = {0.94*[1,1,1],[0.30,0.75,0.93]};                   
            
            % updates the label colours
            jLbl = obj.getRevInd(iLbl);
            if jLbl <= size(obj.hLbl,1)
                set(obj.hLbl{jLbl,1},'BackgroundColor',bCol{1+isOn});
                set(obj.hLbl{jLbl,2},'BackgroundColor',bCol{1+isOn});
            end            
            
            % sets the currently selected label
            if isOn
                obj.iSel = iLbl;
            else
                obj.iSel = 0;
            end                 
            
        end
        
        % --- retrieves the text label strings
        function getTextDim(obj)
            
            % parameters
            N = 1000;
            
            % creates a dummy text object and retrieves the new width
            hTxt = cellfun(@(x)(text(N,N,x,'FontUnits','Pixel',...
                                'FontSize',obj.fSz,'Parent',obj.hAx,...
                                'Units','Pixel')),...
                                obj.mStr(:),'un',0);
            pExt = cell2mat(cellfun(@(x)(get(x,'extent')),hTxt,'un',0));
            
            % retrieves the object text width/height
            obj.tWid = ceil(max(pExt(:,3))) + obj.dW;   
            obj.tHght = ceil(pExt(1,4));
            
        end
        
        % --- updates the menu parent object
        function setMenuParent(obj,hP)
            
            set(obj.hMenu,'Parent',hP)
            
        end
        
        % --- updates the menu item label
        function setMenuLabel(obj,iLbl,nwLbl)
            
            % updates the menu label
            iLblR = obj.getRevInd(iLbl+1);
            set(obj.hLbl{iLblR,2},'String',nwLbl)
            
        end
        
        % --- updates the position of the context menu
        function updatePosition(obj,pNw)
            
            % parameters
            mnPos = get(obj.hMenu,'Position');
            pPos = get(get(obj.hMenu,'Parent'),'Position');            
            
            % sets the menu left position
            x0 = pNw(1) - pPos(1);
            if (x0 + mnPos(3)) > pPos(3)
                x0 = x0 - mnPos(3);
            end
            
            % sets the menu bottom position 
            y0 = pNw(2) - (pPos(2) + mnPos(4));
            if y0 < 0
                y0 = y0 + mnPos(4);
            end
            
            % updates the left/bottom position of the menu object
            resetObjPos(obj.hMenu,'Left',x0)
            resetObjPos(obj.hMenu,'Bottom',y0)
            
            % updates the current selection point
            mPC = ceil(get(obj.hAx,'CurrentPoint')-0.5);
            obj.mP0 = mPC(1,1:2);
            
        end
        
        % --- sets the context menu visibility
        function setVisibility(obj,isVisible)
           
            % sets the object visibility
            setObjVisibility(obj.hMenu,isVisible)
            
            % if made visible, then update the mouse-click callback funcs
            if isVisible
                % sets the callback function for each label/menu item
                cbFcnS = {@obj.menuSelect,obj};                
                for i = 1:size(obj.hLbl,1)                
                    for j = 1:2
                        jLbl = findjobj(obj.hLbl{i,j});
                        set(jLbl,'MouseClickedCallback',cbFcnS);
                    end 
                end
            end
            
        end        
        
        % --- sets the callback function
        function setCallbackFcn(obj,cbFcn)
            
            obj.cbFcn = cbFcn;
            
        end
        
        % --- updates the context menu item check marks
        function updateMenuCheck(obj,iSelNw)
            
            % retrieves the reverse array index value
            if iSelNw == 0
                % otherwise, reset the check strings
                cellfun(@(x)(set(x,'String','')),obj.hLbl(:,1))

            else
                iSelNwR = obj.getRevInd(iSelNw);
                if isempty(get(obj.hLbl{iSelNwR,1},'String'))
                    % if the check is not set for the menu item, then clear
                    % all tickmarks and update the currently selected item
                    cellfun(@(x)(set(x,'String','')),obj.hLbl(:,1))
                    set(obj.hLbl{iSelNwR,1},'String',obj.tickStr)
                end
            end
        
        end
    
        % --- calculates the reverse index value
        function indR = getRevInd(obj,ind)
            
            indR = obj.nLbl - (ind - 1);
           
        end
            
    end
    
    % class static methods
    methods (Static)
        
        % --- branch merge callback function
        function menuSelect(~,~,obj)
       
            % if there is no selection, then exit
            if obj.iSel == 0
                return
            end
            
            % updates the menu check mark
            obj.updateMenuCheck(obj.iSel);
            
            % runs the callback function (if one exists)
            if ~isempty(obj.cbFcn)
                feval(obj.cbFcn,obj)
            end
            
            % makes the menu invisible again
            obj.setVisibility(0);
            
        end
    
    end
end
