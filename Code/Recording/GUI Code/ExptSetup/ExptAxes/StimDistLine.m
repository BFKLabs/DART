classdef StimDistLine < handle & dynamicprops
    
    % class properties
    properties
        
        %
        hDL
        
        % fixed numerical class fields
        nDL = 2;
        fSzDL = 11;        
        
    end
    
    % private class properties
    properties (Access = private)
        
        objB
        
    end    
        
    % class methods
    methods
        
        % --- class constructor
        function obj = StimDistLine(objB)
    
            % input arguments
            obj.objB = objB;
            
            % initialises the class fields/objects
            obj.linkParentProps();
            obj.initClassFields();
            obj.initClassObjects();
            
        end
        
        % --- initialises the class object fields with that parent object
        function linkParentProps(obj)
            
            % parent fields strings
            fldStr = {'hFig','hAx','yGap','iChH',...
                      'objP','tDurTot','tDurTotU'};
                  
            % connects the base/child objects
            for propname = fldStr
                metaprop = addprop(obj, propname{1});
                metaprop.SetMethod = @(obj, varargin) ...
                    SetDispatch(obj, propname{1}, varargin{:});
                metaprop.GetMethod = @(obj)GetDispatch(obj, propname{1});
            end            
            
        end
        
        % --- initialises the class fields
        function initClassFields(obj)
           
            
            
        end
        
        % --- initialises the class objects
        function initClassObjects(obj)
                        
            % creates the distance line objects
            xiN = 1:obj.nDL;
            obj.hDL = arrayfun(@(x)(...
                obj.createDistLine()),xiN,'un',0);
                                    
        end        
        
        % --- creates the distance line object
        function hAPI = createDistLine(obj)
            
            % creates the distance line object
            hDLnw = imdistline(obj.hAx);
            
            % sets the object properties
            set(hDLnw,'tag','chDist','hittest','off','visible','off');
            
            % sets the individual component properties
            set(findobj(hDLnw,'type','Text'),'Margin',1)
            setObjVisibility(findobj(hDLnw,'tag','top line'),'off')
            set(findobj(hDLnw,'tag','bottom line'),...
                'LineWidth',1,'Color','k','hittest','off')
            set(findobj(hDLnw,'tag','end point 1'),...
                'Marker','.','Color','k','hittest','off')
            set(findobj(hDLnw,'tag','end point 2'),...
                'Marker','.','Color','k','hittest','off')
            set(findobj(hDLnw,'tag','distance label'),...
                'FontUnits','Pixels','FontSize',obj.fSzDL,...
                'FontWeight','bold','hittest','off')
            
            % returns the API object handle
            hAPI = iptgetapi(hDLnw);
            
        end
        
        % --- sets the distance line visibility properties
        function setLineVisible(obj,vState,indDL)
            
            % default input arguments
            if ~exist('indDL','var')
                indDL = 1:obj.nDL;
            end
            
            % sets the distance line visibility
            cellfun(@(x)(setObjVisibility(x,vState)),obj.hDL(indDL));
            
        end
        
        % --- sets the distance line position
        function setDistLinePos(obj,iL,xL)
            
            yL = ((obj.iChH - 1) + obj.yGap/2)*[1,1];
            obj.hDL{iL}.setPosition(xL,yL);
            
        end        
        
    end
    
    % private class methods
    methods (Access = private)
        
        % --- sets a class object field
        function SetDispatch(obj, propname, varargin)
            obj.objB.(propname) = varargin{:};
        end
        
        % --- gets a class object field
        function varargout = GetDispatch(obj, propname)
            varargout{:} = obj.objB.(propname);
        end
        
    end       
    
end