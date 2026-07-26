classdef ExptSetupDiag < handle
    
    % class properties
    properties
        
        %
        fCode
        fInfo
        fLineW
        nLineW
        iCodeF
        iCodeB        
        
        %
        iName
        fName
        fName0
        
        %
        iMapF        
        fMatch
        iMatch
        fcnDep
        fcnMap
        fcnChain
        
        % 
        nFcn
        nFcnMin
        iLvlMax = 2;
        
        % static class fields
        fFile = 'ExptSetupOrig.m';
        fExp = '"[^"]*"|''[^'']*''|(\w+)';
        
    end
    
    % class methods
    methods
    
        % --- class constructor
        function obj = ExptSetupDiag()
        
            % reads the code file
            fid = fopen(obj.fFile,'rb');
            fCodeFile = fread(fid,'uint8=>char');
            fclose(fid);
            
            % splits the code into separate lines
            obj.fCode = cellfun(@strtrim,strsplit(fCodeFile','\n'),'un',0)';
            nLine = length(obj.fCode);
            
            % sets the code/block limit indices
            obj.iCodeF = find(startsWith(obj.fCode,'function')); 
            obj.iCodeB = [(obj.iCodeF(:)+1),[obj.iCodeF(2:end)-1;nLine]];
            
            %
            obj.setupFuncNames()            
            
            %
            obj.initFuncDepSearch()
%             obj.getFuncDep()
            
        end        
        
        %
        function setupFuncNames(obj)
            
            % retrieves the function file names
            obj.fName0 = cellfun(@(x)(...
                obj.getFuncName(x)),obj.fCode(obj.iCodeF),'un',0);
            
            % determines the minumum function length
            nFcn0 = cellfun('length',obj.fName0);
            obj.nFcnMin = min(nFcn0);           
            
            % groups the function names/indices by string length
            [obj.nFcn,~,iC] = unique(nFcn0);
            obj.iName = arrayfun(...
                @(x)(find(iC == x)),1:length(obj.nFcn),'un',0)';
            obj.fName = cellfun(@(x)(obj.fName0(x)),obj.iName,'un',0);
            
        end
        
        % --- determines each of the function dependencies
        function initFuncDepSearch(obj)

            % memory allocation
            [obj.fLineW,obj.nLineW] = deal(cell(length(obj.fCode),1));
            
            % determines the searchable lines
            isOK = ~setGroup(obj.iCodeF,size(obj.fCode)) & ...
                   ~startsWith(obj.fCode,'%') & ...
                   (cellfun('length',obj.fCode) >= obj.nFcnMin);
                           
            % retrieves the 
            for i = 1:length(isOK)
                % continue if infeasible
                if ~isOK(i)
                    continue
                end
                
                % searches for all feasible words in a code line
                [~,T] = regexp(obj.fCode{i},obj.fExp,'match','tokens');
                fWord = [T{:}];
                fWord = fWord(cellfun('length',fWord) >= obj.nFcnMin);
                isOK(i) = ~isempty(fWord);
                
                % sorts the line words by length
                if isOK(i)
                    fWord = unique(fWord);
                    nWord = cellfun('length',fWord);
                    [obj.nLineW{i},iS] = sort(nWord);
                    obj.fLineW{i} = fWord(iS);                    
                end
            end 
            
            % sets up the function index mapping array
            obj.iMapF = NaN(length(obj.fCode),1);            
            for iFcn = 1:size(obj.iCodeB,1)
                xiL = obj.iCodeB(iFcn,1):obj.iCodeB(iFcn,2);
                obj.iMapF(xiL) = iFcn;
            end
            
        end   
        
        % --- determines the function dependencies
        function getFuncDep(obj)
            
            % determines the feasible code lines
            isOK = ~cellfun('isempty',obj.fLineW);
            
            % calculates the function length lower/upper limits
            nLim = NaN(length(isOK),2);
            nLim(isOK,1) = cellfun(@(x)(length(x{1})),obj.fLineW(isOK));
            nLim(isOK,2) = cellfun(@(x)(length(x{end})),obj.fLineW(isOK));
            
            %
            [obj.fMatch,obj.iMatch] = deal(cell(length(isOK),1));
            for i = find(isOK(:)')
                % determines the lower/upper function name counts
                i0 = find(obj.nFcn == nLim(i,1));
                i1 = find(obj.nFcn == nLim(i,2));
                
                % searches for function name matches for the current row
                for j = i0:i1
                    % determines any matching
                    ii = obj.nLineW{i} == obj.nFcn(j);
                    fTmp = obj.fLineW{i}(ii);
                    
                    % determines if there are any matches
                    [~,indA] = intersect(obj.fName{j},fTmp);
                    if ~isempty(indA)
                        obj.fMatch{i} = obj.fName{j}(indA);
                        obj.iMatch{i} = obj.iName{j}(indA);
                    end
                end
            end
            
            %
            obj.fcnDep = cell(length(obj.fName0),2);
            for iFcn = 1:size(obj.fcnDep,1)
                % sets the line indices for the function block
                xiL = obj.iCodeB(iFcn,1):obj.iCodeB(iFcn,2);
                
                % removes any non-empty cells from the function block
                xiL = xiL(~cellfun('isempty',obj.fMatch(xiL)));
                if ~isempty(xiL)
                    % determines the unique function calls in the function
                    fMatchNw = cell2cell(obj.fMatch(xiL));
                    [obj.fcnDep{iFcn,1},iB] = unique(fMatchNw,'stable');
                    
                    % if there are matches, then store the values
                    iMatchNw = cell2cell(obj.iMatch(xiL));
                    obj.fcnDep{iFcn,2} = iMatchNw(iB);
                    
                    % removes any recursive function calls
                    ii = strcmp(obj.fcnDep{iFcn,1},obj.fName0{iFcn});
                    if any(ii)
                        obj.fcnDep{iFcn,1} = obj.fcnDep{iFcn,1}(~ii);
                        obj.fcnDep{iFcn,2} = obj.fcnDep{iFcn,2}(~ii);
                    end
                end
            end
            
        end
        
        % --- sets up the function map
        function fcnMapF = setupFuncMap(obj)
            
            % memory allocation
            obj.fcnMap = {};
            
            % maps the functions
            for iFcn = 1:size(obj.fcnDep,1)
                obj.fcnChain = {};
                obj.addMapFunc(iFcn,1);
            end
            
            % memory allocation
            nLvl = cellfun('length',obj.fcnMap);
            fcnMapF = repmat({''},length(obj.fcnMap),max(nLvl));
            
            % stores the mapped values into the full array
            for i = 1:length(obj.fcnMap)
                fcnMapF(i,1:nLvl(i)) = obj.fcnMap{i};
            end
            
            % converts cell array to string array
            fcnMapF = string(fcnMapF);
            
        end
        
        %
        function addMapFunc(obj,iFcn,iLvl)
            

            if any(strcmp(obj.fcnChain,obj.fName0{iFcn}))
                return
            elseif iLvl == (obj.iLvlMax + 1)
                return
            end
            
            % appends the function to the overall map
            nwMap = repmat({''},1,iLvl+3);
            nwMap{end} = obj.fName0{iFcn};
            
            %
            if iLvl == 1
                nwMap{1} = string(iFcn);
                nwMap{2} = string(obj.iCodeB(iFcn,1));
                nwMap{3} = string(obj.iCodeB(iFcn,2));
            end

            % adds the function to the chain
            obj.fcnMap{end+1} = nwMap;            
            obj.fcnChain{end+1} = obj.fName0{iFcn};
            
            % appends the sub-function calls
            for i = 1:length(obj.fcnDep{iFcn,1})
                obj.addMapFunc(obj.fcnDep{iFcn,2}(i),iLvl+1);
            end
            
            % removes the function from the chain
            obj.fcnChain = obj.fcnChain(1:end-1);
            
        end
        
        % --- searches the code blocks for any functions
        function fInfoB = searchCodeBlock(obj,iFcn)
            
            %
            [cBlk,iBlk] = obj.getFuncCodeBlock(iFcn);            
            
            %
            okRow = ~(startsWith(cBlk,'%') | ...
                      cellfun('isempty',cBlk));
            
            a = 1;
                  
        end
        
        % --- retrieves the function code block given by, iFcn
        function [cBlk,iBlk] = getFuncCodeBlock(obj,iFcn)
            
            iBlk = obj.iCodeB(iFcn,1):obj.iCodeB(iFcn,2);
            cBlk = obj.fCode(iBlk);
            
        end        
        
    end
    
    % static class methods
    methods (Static)
        
        % --- splits the function name string
        function fcnName = getFuncName(fcnStr)
            
            % splits up the function string into its components
            fcnStrSp = strsplit(strtrim(fcnStr));
            ii = strContains(fcnStrSp,'(');
            fcnNameSp = strsplit(fcnStrSp{ii},'(');
            
            % retrieves the final function name string
            fcnName = fcnNameSp{1};
            
        end        
        
    end
    
end