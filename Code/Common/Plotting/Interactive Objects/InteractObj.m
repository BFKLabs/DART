classdef InteractObj < handle
    
    % class properties
    properties
        
        % main clasos fields
        hAx
        Type
        pPos
        
        % object handle fields
        hObj
        hAPI
        tStr        
        
        % object indices
        hM
        iEP
        iTL
        
        % miscellaneous flags
        isOld = false;
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = InteractObj(Type,hAx,pPos,isOld)
                                    
            % sets the main class fields
            obj.hAx = hAx;
            obj.Type = lower(Type);
            if exist('pPos','var'); obj.pPos = pPos; end
            
            % sets the interactive object format flag 
            if exist('isOld','var') 
                obj.isOld = isOld; 
            else
                obj.isOld = isOldIntObjVer();
            end
            
            % initialises the class fields/objects
            obj.initClassObj();
            
        end        
        
        % --- initialises the class fields
        function initClassObj(obj)
            
            if obj.isOld
                % case is the old syntax version 
                
                % creates the interactive object based on type
                switch obj.Type
                    case 'point'
                        % case is point object
                        if isempty(obj.pPos)
                            % case is the user must draw the object
                            obj.hObj = impoint(obj.hAx);
                        else
                            % case is the position vector is provided
                            pPosP = obj.pPos;
                            obj.hObj = impoint(obj.hAx,pPosP(1),pPosP(2));
                        end  
                        
                        % sets the constraint/position callback functions
                        setObjVisibility(findall(obj.hObj,'tag','plus'),0);
                    
                    case 'line'
                        % case is a line object
                        if isempty(obj.pPos)
                            % case is the user must draw the object
                            hObjNw = imline(obj.hAx);
                        else
                            % case is the position vector is provided
                            pPosP = obj.pPos;
                            hObjNw = imline(obj.hAx,pPosP{1},pPosP{2});
                        end                           
                        
                        % removes the bottom line from the imline object
                        obj.hObj = hObjNw;
                        obj.hM = findall(obj.hObj);
                        hLineBL = findobj(obj.hObj,'tag','bottom line');
                        set(hLineBL,'visible','off');                        
                    
                        % determines the marker object indices
                        tStrM = get(obj.hM,'tag');
                        obj.iEP = find(strcmp(tStrM,'end point 1'));
                        obj.iTL = find(strcmp(tStrM,'top line'));
                        
                    case 'rect'
                        % case is a rectangle object
                        if isempty(obj.pPos)
                            % case is the user must draw the object
                            obj.hObj = imrect(obj.hAx);
                        else
                            % case is the position vector is provided
                            obj.hObj = imrect(obj.hAx,obj.pPos);
                        end
                        
                        % disables the bottom line of the imrect object
                        hBL = findobj(obj.hObj,'tag','bottom line');
                        setObjVisibility(hBL,0);                        
                        
                    case 'ellipse'
                        % case is an ellipse object                        
                        if isempty(obj.pPos)
                            % case is the user must draw the object
                            obj.hObj = imellipse(obj.hAx);
                        else
                            % case is the position vector is provided
                            obj.hObj = imellipse(obj.hAx,obj.pPos);
                        end                        
                end                
                
                % retrieves the api object
                obj.hAPI = iptgetapi(obj.hObj);
                obj.tStr = sprintf('im%s',obj.Type);
                
            else
                % case is the new syntax version
                
                % creates the interactive object based on type
                switch obj.Type
                    case 'rect'
                        % case is a rectangle object
                        if isempty(obj.pPos)
                            % case is the user must draw the object
                            obj.hObj = drawrectangle(obj.hAx);                            
                        else
                            % case is the position vector is provided
                            obj.hObj = ...
                                drawrectangle(obj.hAx,'Position',obj.pPos);
                        end                                                
                        
                        % makes the object transparent
                        set(obj.hObj,'FaceAlpha',0);                        
                        
                    case 'line'
                        % case is a line object
                        if isempty(obj.pPos)
                            % case is the user must draw the object
                            obj.hObj = drawline(obj.hAx);
                        else
                            % case is the position vector is provided
                            pPosL = [obj.pPos{1}(:)';obj.pPos{2}(:)']';
                            obj.hObj = drawline(obj.hAx,'Position',pPosL);
                        end
                        
                    case 'ellipse'
                        % case is an ellipse object
                        if isempty(obj.pPos)
                            % case is the user must draw the object
                            obj.hObj = drawellipse(obj.hAx);                            
                        else
                            % sets the ellipse parameters
                            pAx = obj.pPos(3:4)/2;
                            pC = obj.pPos(1:2) + pAx;                            
                            
                            % case is the position vector is provided
                            obj.hObj = drawellipse(...
                                    obj.hAx,'Center',pC,'SemiAxes',pAx);
                        end
                        
                        % makes the object transparent
                        set(obj.hObj,'FaceAlpha',0);                        
                        
                    case 'point'
                        % case is point object
                        if isempty(obj.pPos)
                            % case is the user must draw the object
                            obj.hObj = drawpoint(obj.hAx);                            
                        else
                            % case is the position vector is provided
                            obj.hObj = ...
                                drawpoint(obj.hAx,'Position',obj.pPos);
                        end
                        
                end
                
                % resets the base object properties
                set(obj.hObj,'Linewidth',1);
            end
            
        end      
        
        % -------------------------- %
        % --- CALLBACK FUNCTIONS --- %
        % -------------------------- %
        
        % --- sets the interactive object movement callback function
        function setObjMoveCallback(obj,cbFcn)
        
            if obj.isOld
                % case is the old format objects
                obj.hAPI.addNewPositionCallback(cbFcn);
            else
                % case is the new format objects                
                addlistener(obj.hObj,'MovingROI',cbFcn);
            end
            
        end
        
        % --- sets the object's constraint region
        function setConstraintRegion(obj,xLim,yLim)
            
            if obj.isOld
                % case is the old format objects
                
                % sets the position callback function
                fcnC = makeConstrainToRectFcn(obj.tStr,xLim,yLim);
                obj.hAPI.setPositionConstraintFcn(fcnC);
                
            else
                % case is the new format objects
                
                % sets the object drawing area
                xyLim = [xLim(1),yLim(1),diff(xLim),diff(yLim)];
                set(obj.hObj,'DrawingArea',xyLim);
            end
            
        end
        
        % --------------------------------- %
        % --- PROPERTY UPDATE FUNCTIONS --- %
        % --------------------------------- %   
        
        % --- deletes the interactive object
        function deleteObj(obj)
            
            delete(obj.hObj);
            
        end
        
        % --- disables the interactive object from selection
        function disableObj(obj)
            
            if obj.isOld
                % case is the old format objects
                
                % retrieves the marker object handles
                hObjC = get(obj.hObj,'Children');
                isM = strContains(get(hObjC,'Tag'),'marker');

                % turns off the object visibility/hit-test
                set(hObjC,'hittest','off')
                setObjVisibility(hObjC(isM),0)                                
            else
                % case is the new format objects    
                
                % removes object interaction
                set(obj.hObj,'InteractionsAllowed','none')
            end            
            
        end
        
        % --- sets the interactive object resize flag
        function setResizeFlag(obj,rFlag)
            
            if obj.isOld
                % case is the old format objects            
                obj.hAPI.setResizable(rFlag); 
                
            else
                % case is the new format objects                
                set(obj.hObj,'InteractionsAllowed','translate');
            end
            
        end
        
        % --- sets the interactive object resize flag
        function setAspectRatioFlag(obj,arFlag)
            
            if obj.isOld
                % case is the old format objects            
                setFixedAspectRatioMode(obj.hObj,arFlag); 
                
            else
                % case is the new format objects                
                set(obj.hObj,'FixedAspectRatio',arFlag);
            end            
            
        end
        
        % --- sets the interactive object marker sizes
        function setMarkerSize(obj,mSz)
            
            if obj.isOld
                % case is the old format objects            

                % retrieves the children objects and their tags
                hChild = get(obj.hObj,'Children');
                tStrC = get(hChild,'tag');

                % removes the marker objects                        
                hMarkC = hChild(strContains(tStrC,'marker'));
                arrayfun(@(x)(set(x,'MarkerSize',mSz)),hMarkC)                
                
            else
                % case is the new format objects                
                set(obj.hObj,'MarkerSize',mSz);
            end               
            
        end
        
        % --- sets the interactive object colour
        function setColour(obj,fCol)
            
            if obj.isOld
                % case is the old format objects
                obj.hAPI.setColor(fCol);
                
            else
                % case is the new format objects
                set(obj.hObj,'Color',fCol)
            end            
            
        end
        
        % --- sets the object fields from the 
        function setFields(obj,varargin)
            
            for i = 1:length(varargin)/2
                try
                    set(obj.hObj,varargin{2*i-1},varargin{2*i})
                end
            end
            
        end
        
        % --- retrieves the object's current position vector
        function pPos = getPosition(obj,hObjR)
            
            if obj.isOld
                % case is the old format objects
                pPos = obj.hAPI.getPosition();
                
            else
                % case is the new format objects

                % retrieves the position based on the object type
                switch obj.Type
                    case 'ellipse'
                        % case is the ellipse objects
                        pC = get(obj.hObj,'Center');
                        pAx = get(obj.hObj,'SemiAxes');                        
                        pPos = [(pC-pAx),2*pAx];
                        
                    otherwise
                        % case is the other object types
                        if exist('hObjR','var')
                            pPos = get(hObjR,'Position');
                        else
                            pPos = get(obj.hObj,'Position');
                        end
                end
            end 
                        
        end
        
        % --- sets the object's position vector
        function setPosition(obj,pPos,forceUpdate)
            
            if obj.isOld
                % case is the old format objects
                if exist('forceUpdate','var') && forceUpdate
                    % forces the update of the object manually (is required
                    % when updating position within the callback function)                    
                    switch obj.Type
                        case 'line'
                            % case is a line object
                            obj.forceResetLinePos(pPos);                            
                    end
                else
                    % otherwise, update position via the API
                    obj.hAPI.setPosition(pPos);
                end
                
            else               
                % retrieves the position based on the object type
                switch obj.Type
                    case 'ellipse'                
                        % case is the ellipse objects                        
                        
                        % resets the ellipses axes
                        pAx = pPos(3:4)/2;
                        pC = pPos(1:2) + pAx;
                        set(obj.hObj,'Center',pC,'SemiAxes',pAx)
                        
                    otherwise
                        % case is the other object types
                        set(obj.hObj,'Position',pPos);                                    
                end
            end 
                        
        end
        
        % --- retrieves the field value(s) provided by fStr
        function fVal = getFieldVal(obj,fStr)
        
            if iscell(fStr)
                % multiple fields are provided
                fVal = cell(length(fStr),1);
                for i = 1:length(fStr)
                    if obj.isOld
                        fVal{i} = get(obj.hObj,fStr{i});
                    else
                        fVal{i} = getStructField(obj.hObj,fStr{i});
                    end
                end
            else
                % single field is provided
                if obj.isOld
                    fVal = get(obj.hObj,fStr);                    
                else
                    fVal = getStructField(obj.hObj,fStr);
                end
            end
            
        end
       
        % --- 
        function forceResetLinePos(obj,pPos)
        
            set(obj.hM(obj.iEP),'xData',pPos(1,1),'yData',pPos(1,2));
            set(obj.hM(obj.iTL),'xData',pPos(:,1),'yData',pPos(:,2));
            
        end
            
        % --- 
        function setLineProps(obj,varargin)
            
            % field retrieval
            hObjS = obj.hObj;
            
            %
            if obj.isOld
                % sets the tag string cell array                
                tStrH = {'top line','bottom line',...
                         'end point 1','end point 2'};
                hC = cellfun(@(x)(findobj(hObjS,'tag',x)),tStrH,'un',0);
            end 

            for i = 1:length(varargin)/2
                % sets the property field/values
                [pFld,pVal] = deal(varargin{2*i-1},varargin{2*i});
                
                % updates the field based on the object type/field value
                if obj.isOld
                    % case is the older format interactive objects
                    switch pFld
                        case 'RemoveEnds'
                            % removes the end markers
                            cellfun(@(x)(setObjVisibility(x,0)),hC(3:end))

                        otherwise
                            for j = 1:length(hC)
                                if isprop(hC{j},pFld) 
                                    set(hC{j},pFld,pVal)
                                end
                            end
                    end
                else
                    % case is the newer format interactive objects
                    switch pFld
                        case 'RemoveEnds'                    
                            set(hObjS,'MarkerSize',1);    
                            
                        otherwise
                            % removes the end markers
                            if isprop(hObjS,pFld)
                                set(hObjS,pFld,pVal)
                            end
                    end
                end               
            end
            
        end
        
    end

    % static class methods
    methods (Static)
        
        
        
    end
    
end