classdef DataOutputSetup < handle
    
    % class properties
    properties
        
        % main class fields
        hFig
        showLB
        
        % data array fields
        mInd
        Data
        DataN
        
        % other class fields
        iData
        iSel        
        msgObj
        
        % boolean flag fields
        ok = true;        
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = DataOutputSetup(hFig,showLB)
        
            % sets the input arguments
            obj.hFig = hFig;
            obj.showLB = showLB;
            
            % initialises the class fields
            obj.initClassFields();
            obj.setupOutputDataArray();
            
        end
        
        % --- initialises the class object fields
        function initClassFields(obj)
            
            % retrieves the main class object fields
            obj.iData = getappdata(obj.hFig,'iData');
            
            % sets the selection/metric indices
            obj.iSel = obj.iData.tData.iSel(obj.iData.cTab);
            obj.mInd = obj.iData.tData.mInd{obj.iData.cTab}{obj.iSel};
            
        end
        
        % --- sets up the output data array
        function setupOutputDataArray(obj)
            
%             % creates the load bar    
%             if obj.showLB
%                 h = ProgressLoadbar('Initialising Data Table Array...');
%             end

            % updates the GUI
            pause(0.05);                
            
            try
                switch obj.iSel
                    case (1) 
                        % case is the statistical test
                        dataObj = StatsTestData(obj.hFig);

%                         % determines the output variables indices 
%                         stInd = obj.iData.tData.stInd{obj.iData.cTab};
%                         isHorz = get(handles.radioAlignHorz,'value');
%                         DataT = get(handles.tableStatTest,'Data');
% 
%                         % for each of the 
%                         for j = 1:length(A)
%                             % retrieves the new statistical output data
%                             i = A(j);
%                             ATnw = setupStatsDataArray(handles,iData,pData,...
%                                               plotD,Y{i}{stInd(i,1)},stInd(i,2),i);    
% 
%                             % appends the new data to the table
%                             if (j == 1)
%                                 Data = ATnw;
%                             else
%                                 Data = combineCellArrays(Data,ATnw,isHorz);
%                             end   
% 
%                             %
%                             if (isempty(DataT{i,3}))
%                                 DataT{i,3} = setStatTestString(iData,iData.pStats{i},i);
%                                 set(handles.tableStatTest,'Data',DataT)
%                             end
%                         end

                    case 2
                        % case is the population metric output
                        dataObj = MetricPopData(obj.hFig);

                    case 3 
                        % case is the population metric (fixed) output
                        dataObj = MetricFixedData(obj.hFig);

                    case 4
                        % case is the individual metric output
                        dataObj = MetricIndivData(obj.hFig);

                    case 5 
                        % case is the population signal output 
                        dataObj = SigPopData(obj.hFig);

                    case 6 
                        % case is the individual signal output 
                        dataObj = SigIndivData(obj.hFig);

                    case 7 
                        % case is the general population data array
                        dataObj = GenPopData(obj.hFig);

                    case 8
                        % case is the general individual data array
                        dataObj = GenIndivData(obj.hFig);

                    otherwise
                        % case is the calculation parameter
                        dataObj = CalcParaData(obj.hFig);
                        
                end
                
                % retrieves the final data array
                obj.Data = dataObj.Data;
                
%                 % removes any non-numerical fields
%                 if ~any(obj.iSel == [5 6])
%                     isN = find(cellfun(@isnumeric,obj.Data));
%                     obj.Data(isN(cellfun(@isnan,obj.Data(isN)))) = {''}; 
%                 end
                
                % re-adds any manually entered values
                if ~isempty(obj.mInd)
                    % removes any manual indices not within the sheet frame
                    [m,n] = size(obj.Data);
                    inFrm = (obj.mInd(:,1) < m) & (obj.mInd(:,2) < n);
                    obj.mInd = obj.mInd(inFrm,:);

                    if ~isempty(obj.mInd)
                        % if any indices remain, remove any of the manual 
                        % indices for the cells which are not empty                        
                        ii = cellfun(@(x)(isempty(obj.Data...
                                    {x(1),x(2)})),num2cell(obj.mInd+1,2));
                        obj.mInd = obj.mInd(ii,:);

                        % if there are still manual indices, then set the 
                        % cell entries from the previous data array into 
                        % the new one
                        if ~isempty(obj.mInd)
                            [szD,indM] = deal(size(obj.Data),obj.mInd+1);
                            jj = sub2ind(szD,indM(:,1),indM(:,2));
                            obj.Data(jj) = Data0(jj);
                        end
                    end
                end                
                
            catch ME
                % if there was an error, then store the error message
                [obj.msgObj,obj.ok] = deal(ME,false);
                
            end
            
%             % deletes the loadbar
%             if obj.showLB; delete(h); end
            
        end
        
    end
    
end
