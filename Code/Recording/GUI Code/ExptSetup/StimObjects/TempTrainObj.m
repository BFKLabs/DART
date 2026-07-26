classdef TempTrainObj < TempStimObj
    
    % class properties
    properties
        
        % main class object handles
        sParaS
        sType
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = TempTrainObj(objB)
            
            % creates the super-class object
            obj@TempStimObj(objB,false);
            
            % sets the movement region/callback function
            obj.setObjMoveCallback(@obj.moveTrainObj,1);            
            
        end
        
        % --- stimuli object movement callback function
        function moveTrainObj(obj,varargin)
            
            if obj.isUpdating
                return
            end                        
            
            % runs the common movement updates
            obj.moveStimObj();            
            
            % updates the parameter field values
            tMltD = getTimeMultiplier(obj.tDurTotU,obj.sParaS.tOfsU);
            obj.sParaS.tOfs = obj.rPos(1)/tMltD;
            obj.objP.updateParaField('tOfs',obj.rPos(1));
            
        end        
        
        % --- resets the object properties
        function updateTrainObjProps(obj,rPosNw,sLim,sParaS,sType)
                        
            % updates the common stimuli object properties
            obj.updateStimObjProps(rPosNw,sLim);            
            
            % updates the class fields
            obj.sParaS = sParaS;
            obj.sType = sType;                        
            
        end  
        
        % --- resets the object visibility
        function setObjVisibility(obj,vState)
            
            obj.setStimObjVisibility(vState)
            
        end
        
    end
    
end