classdef DataOutputStorage < DataReshapeSetup
    
    % class properties
    properties
        
        % main class fields
        mObj        
        mFile
        hTimer
                        
        % other scalar/boolean fields
        isMem = true;
        szMax = 100;
        tagStr = 'hDataReshape';
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = DataOutputStorage(hFig)
            
            % creates the super-class object
            obj@DataReshapeSetup(hFig);            
            
            % initialises the class fields
            obj.reshapeMetricData();
            obj.postMetricReshapeFunc();
            
        end
           
        % --- initialises the class fields
        function postMetricReshapeFunc(obj)
    
            % determines the size of the stored data. 
            YT = obj.Y; 
            A = whos('YT'); 
            clear YT;
            
            % if it is too large, then store the data on the hard drive 
            szMB = A.bytes/(1024^2);
            if szMB > obj.szMax                
                % deletes any existing timers
                hTimerPr = timerfind('tag',obj.tagStr);
                if ~isempty(hTimerPr); delete(hTimerPr); end
                
                % creates the timer object
                obj.hTimer = timer('StartDelay',0.1,...
                            'ExecutionMode','singleShot',...
                            'TimerFcn',@obj.timerCallback,...
                            'Tag',obj.tagStr);
                
                % sets up the temporary data file path
                iProg = getappdata(obj.hFig,'iProg');
                obj.mFile = fullfile(iProg.TempFile,'TempData.mat');                
                
                % reset the memory flag to false
                obj.isMem = false;
            end
            
        end 
        
        % ------------------------------- %
        % --- DELAYED TIMER FUNCTIONS --- %
        % ------------------------------- %
        
        % --- function that starts the timer object
        function startTimer(obj)
            
            if ~obj.isMem
                start(obj.hTimer);
            end
            
        end
        
        % --- timer callback function
        function timerCallback(obj,~,~)
            
            % sets up the output data struct
            yData = struct();
            for i = find(~cellfun('isempty',obj.Y))
                pFld = sprintf('Y%i',i);
                yData = setStructField(yData,pFld,obj.Y{i});
            end            
            
            % saves the temporary data file (deletes existing)
            if exist(obj.mFile,'var'); delete(obj.mFile); end
            save(obj.mFile,'-struct','yData','-V7','-nocompression');

            % creates the matfile object
            obj.mObj = matfile(obj.mFile,'Writable',true);
            obj.Y(:) = {[]};            
            
        end
        
        % -------------------------------- %
        % --- DATA RESHAPING FUNCTIONS --- %
        % -------------------------------- %
        
        % --- reshapes the calculated metric data
        function reshapeMetricData(obj)            
            
            % runs the reshape function for each metric type
            for iType = find(any(obj.Type,1))
                % determines the type count
                nType = sum(obj.Type(:,iType));

                % memory allocation
                switch iType
                    case 1
                        % case is the population metrics
                        obj.Y{iType+1} = cell(nType,obj.nMet,4);

                    case {2,4,6,7}
                        % case is a single column array
                        obj.Y{iType+1} = cell(nType,1);    

                    otherwise
                        % case is a double column array
                        obj.Y{iType+1} = cell(nType,2);
                end

                % runs the shape function
                obj.runReshapeFunc(iType);                    
            end
                
        end
        
        % --- runs the data reshape function
        function runReshapeFunc(obj,iType,varargin)

            % retrieves the reshape function
            rFcn = obj.getReshapeFunc(iType);
            
            % runs the data reshape function
            if isempty(varargin)
                feval(rFcn,obj,iType);
            else
                feval(rFcn,obj,iType,varargin{1});
            end

        end        
        
        % -------------------------- %
        % --- DATA I/O FUNCTIONS --- %
        % -------------------------- %
        
        % --- retrieves the data fields from the 
        function Ynw = getData(obj,iType,varargin)
            
            % retrieves the data based on the storage type
            if obj.isMem
                % data is stored in memory
                Ynw = obj.Y{iType};                
            else
                % data is stored on the hard-drive
                pFld = sprintf('Y%i',iType);
                Ynw = getStructField(obj.mObj,pFld);
            end
            
            % retrieves the sub-fields (if necessary)
            for i = 1:length(varargin)            
                Ynw = Ynw{varargin{i}};
            end
            
        end
        
        % --- retrieves the data fields from the 
        function setData(obj,Ynw,iType,varargin)
            
            % sets the data based on the storage type
            if obj.isMem
                % data is stored in memory
                switch length(varargin)
                    case 0
                        % case is updating a data field
                        obj.Y{iType} = Ynw;
                        
                    case 1
                        % case is updating a sub-data field
                        obj.Y{iType}{varargin{1}} = Ynw;
                        
                    case 2
                        % case is updating a sub-sub-data field
                        obj.Y{iType}{varargin{1}}{varargin{2}} = Ynw;
                end
            else
                % data is stored on the hard-drive
                pFld = sprintf('Y%i',iType);
                switch length(varargin)
                    case 0
                        % case is updating a data field
                        setStructField(obj.mObj,pFld,Ynw);

                    case 1
                        % case is updating a sub-data field
                        pFldS = sprintf('%s(%i,1)',pFld,varargin{1});
                        setStructField(obj.mObj,pFldS,Ynw);

                    case 2
                        % retrieves the sub-data field
                        pFldS = sprintf('%s(%i,1)',pFld,varargin{1});
                        YnwS = getStructField(obj.mObj,pFldS);
                        YnwS{varargin{2}} = Ynw;
                        
                        % updates the data field
                        setStructField(obj.mObj,pFldS,YnwS);
                end
            end
            
        end     
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- object delete function
        function closeObj(obj)
            
            % deletes the temporary file (if storing on hard drive)
            if ~obj.isMem
                delete(obj.mFile);
            end
            
        end
        
    end
        
end