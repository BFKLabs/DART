classdef TempStimObj < InteractObj & dynamicprops
    
    % class properties
    properties
        
        % main class object handles
        rPos
        sLim
        
        % boolean class fields
        isProto
        isShow = false;
        isUpdating = false;
        
        % string cell array class fields
        eStr = {'off','on'};
        
    end
    
    % private class properties
    properties (Access = protected)
        
        objB
        
    end    
    
    % class methods
    methods
        
        % --- class constructor
        function obj = TempStimObj(objB,isProto)
            
            % creates the super-class object
            obj@InteractObj('rect',objB.hAx,[0,0,1,1]);
            
            % input arguments
            obj.objB = objB;
            obj.isProto =isProto;
            
            % initialises the class fields/objects
            obj.linkParentProps();
            obj.initClassObjects();
                        
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %        
        
        % --- initialises the class object fields with that parent object
        function linkParentProps(obj)
            
            % parent fields strings
            fldStr = {'yGap','objP','objR','objDL',...
                      'tDurTot','tDurTotU','iExpt'};
            
            % connects the base/child objects
            for propname = fldStr
                if isprop(obj.objB, propname{1})
                    metaprop = addprop(obj, propname{1});
                    metaprop.SetMethod = @(obj, varargin) ...
                        SetDispatch(obj, propname{1}, varargin{:});
                    metaprop.GetMethod = ...
                        @(obj)GetDispatch(obj, propname{1});
                end
            end
            
        end                
        
        % --- initialises the class objects
        function initClassObjects(obj)
            
            % sets the object properties
            obj.setFields('Color',0.8*[1,1,1],'ContextMenu',[],...
                          'FaceAlpha',0.5,'LineWidth',1,...
                          'MarkerSize',0.5,'Visible','off',...
                          'EdgeColor','k');
            obj.setLineProps('RemoveEnds',0)            
            
        end         
        
        % --- common stimuli object movement updates
        function moveStimObj(obj)
        
            % enables the edge lines
            obj.objDL.setLineVisible('on');
            
            % updates the distance-line positions
            obj.rPos = obj.getPosition();
            obj.objDL.setDistLinePos(1,[obj.sLim(1),obj.rPos(1)])
            obj.objDL.setDistLinePos(2,[sum(obj.rPos([1,3])),obj.sLim(2)]) 
            
        end
        
        % --- common stimuli object property field updates
        function updateStimObjProps(obj,rPosNw,sLim)
            
            % resets the stimuli object position (if overlapping limits)
            if rPosNw(1) < sLim(1)
                % overlaps with lower limit
                rPosNw(1) = sLim(1);
                
            elseif sum(rPosNw([1,3])) > sLim(2)
                % overlaps with upper limit
                rPosNw(1) = sLim(2) - rPosNw(3);
            end
            
            % updates the object position vector and limits
            obj.rPos = rPosNw;
            obj.sLim = sLim;
            
            % updates the object position
            obj.isUpdating = true;
            obj.setPosition(obj.rPos,true);
            obj.isUpdating = false;

            % sets the other object properties
            yL = obj.rPos(2) + [0,obj.rPos(4)];
            obj.setConstraintRegion(obj.sLim,yL);
            obj.setObjVisibility('on');            
            
        end
                
        % --- sets the object visibility state
        function setStimObjVisibility(obj,vState)
            
            % class field update
            if islogical(vState)
                [obj.isShow,vState] = deal(vState,obj.vStr{1+obj.isShow});
            else
                obj.isShow = strcmp(vState,'on');
            end            
            
            % updates the object visibility
            obj.setFields('Visible',vState)
            
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