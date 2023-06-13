classdef FuncErrorLog < handle
    
    % class properties
    properties        
        
        % data struct fields
        pData
        fExpt0
        errInfo
        
        % scalar fields
        iExp
        iScope
        iFcn
        isCalc
        isErr        
        
    end
        
    % class methods
    methods
       
        % --- class constructor
        function obj = FuncErrorLog(fExpt0,ME,pData,iSF,isCalc,isErr)
        
            % sets the input arguments
            obj.errInfo = ME;
            obj.pData = pData;
            obj.fExpt0 = fExpt0;
            
            % sets the scalar/boolean fields            
            obj.iExp = iSF(1);
            obj.iScope = iSF(2);
            [obj.isCalc,obj.isErr] = deal(isCalc,isErr);
            
        end            
        
        % --- output error message details
        function outputErrorDetails(obj)
            
            % initialisations
            eType0 = {'Warning','Error'};
            fType0 = {'Plotting','Calculation'};
            fScope0 = {'Individual Fly','Single Expt','Multi-Expt'};
            endStr = sprintf('%s\n',repmat('*',1,50));
            
            % sets the error message (based on type)
            if obj.isErr
                % sets the error message
                eMsg = obj.errInfo.message;
                
            else
                % sets the warning message
                eMsg = obj.errInfo{1};
            end
            
            % sets the experiment string (based on scope)
            if obj.iScope == 3
                % case is multi-expt
                fExptS = 'Multi-Expt';
            else
                % case is single expt
                fExptS = obj.fExpt0{obj.iExp};
            end
            
            % sets the log/error types
            eType = sprintf('Log Type = %s',eType0{1+obj.isErr});
            fType = sprintf('Error Type = %s',fType0{1+obj.isCalc});
            fScope = sprintf('Scope Type = %s',fScope0{obj.iScope});
            fExpt = sprintf('Experiment Name = %s',fExptS);
            fName = sprintf('Function Name = %s',obj.pData.Name);
            
            % sets up the total error message
            eMsgTot = {...
                obj.setupErrorString(eType);...
                obj.setupErrorString(fType);...
                obj.setupErrorString(fScope);...
                obj.setupErrorString(fName);...
                obj.setupErrorString(fExpt);...
                obj.setupErrorMessage(eMsg);...
            };        
        
            % outputs the message to screen
            fprintf('\n%s\n%s',cell2cell(eMsgTot),endStr);
            
        end
        
    end
    
    % static class methods
    methods (Static)
        
        % --- sets up the error string
        function eStr = setupErrorString(sStr)
            
            eStr = sprintf('%s\n',sStr);
            
        end
        
        %
        function eStr = setupErrorMessage(eMsg)
            
            eStr = sprintf('\nError Message:\n%s\n',eMsg);
            
        end
        
    end
    
    
end