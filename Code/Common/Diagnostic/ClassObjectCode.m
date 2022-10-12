classdef ClassObjectCode < handle
    
    % class properties
    properties
        
        % main program fields
        fFile
        hProg

        % main class fields
        fCode0
        clName
        clType
        
        % class code fields
        fData
        isEmp
        isCom
        isFcn
        isEnd
        nGap
        nLine
        cBlk
        
        % dependency class fields
        Fcn
        iDep
        isFcnR   
        
        % boolean fields
        ok = true;  
        delLB = false;
        Tab = 9;
        Space = 32;
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = ClassObjectCode(fFile,hProg)

            % set the input arguments
            obj.fFile = fFile;            
            
            % determines if the class object file exists
            if ~exist(fFile,'file')
                % makes the progress loadbar invisible
                setObjVisibility(obj.hProg.Control,0);                
                
                % if not, output an error to screen
                tStr = 'Class File Doesn''t Exist';
                eStr = sprintf(['The following object class file does ',...
                        'not exist:\n\n %s %s\n\nRe-check the path of ',...
                        'the object class file.'],char(8594),fFile);
                waitfor(errordlg(eStr,tStr,'modal'))

                % exits the class
                obj.ok = false;
                return
            end
            
            % updates the loadbar
            wStr = 'Separating Class Object Code';
            if exist('hProg','var')
                % case is a loadbar is provided externally
                obj.hProg = hProg;
                obj.hProg.StatusMessage = wStr;
            else
                % otherwise, loadbar is created internally
                obj.delLB = true;
                obj.hProg = ProgressLoadbar(wStr);
            end

            % initialises the class fields
            obj.splitClassCode();            

            % deletes the progressbar (if created internally)
            if obj.delLB && obj.ok
                delete(obj.hProg);
            end
            
        end        
        
        % ---------------------------- %
        % --- CLASS CODE FUNCTIONS --- %
        % ---------------------------- %
        
        % --- splits the class code into its components
        function splitClassCode(obj)
            
            % opens the file, reads the data and closes it again
            fObj = fopen(obj.fFile,'r+');
            obj.fData = strsplit(fread(fObj,inf,'uint8=>char')','\n')';
            fclose(fObj);
            
            % determines the empty code lines
            fDataT = cellfun(@strtrim,obj.fData,'un',0);
            obj.fCode0 = cellfun(@(x)...
                            (getArrayVal(strsplit(x),1)),fDataT,'un',0);
            
            % determines the empty code lines
            obj.nLine = length(obj.fCode0);
            obj.isEmp = cellfun(@isempty,fDataT);
            obj.fCode0(obj.isEmp) = deal({' '});
            
            % determines the comment code lines
            obj.isCom = cellfun(@(x)(strcmp(x(1),'%')),obj.fCode0);
            obj.isFcn = strcmp(obj.fCode0,'function');
            obj.isEnd = strcmp(obj.fCode0,'end');
            
            % determines the gap size (removes empty code lines)
            obj.nGap = cellfun(@(x)(obj.detGapSize(x)),obj.fData);
            obj.nGap(obj.isEmp) = 0;
            
            % retrieves the class header and split the group code blocks
            obj.getMainClassProps();            
            
            % determines the function dependencies
            if obj.ok
                obj.getClassCodeGroups();
                obj.detFunctionDep();
            end
            
        end
        
        % --- retrieves the main class properties
        function getMainClassProps(obj)
            
            % splits the code 
            cBlk0 = strsplit(strtrim(obj.fData{1}));
            
            % determines if the file is a valid class object file
            if strcmp(cBlk0{1},'classdef')
                % if so, then set the class name/type
                obj.clName = cBlk0{2};
                obj.clType = cBlk0(4:2:end);
            else
                % makes the progress loadbar invisible
                setObjVisibility(obj.hProg.Control,0);
                
                % if not, output an error to screen
                tStr = 'Invalid Class Object File';
                eStr = sprintf(['The following file is not a valid ',...
                        'class object file:\n\n %s %s\n\nRetry adding ',...
                        'a valid object class file.'],char(8594),obj.fFile);
                waitfor(errordlg(eStr,tStr,'modal'))

                % exits the class
                obj.ok = false;
            end
            
        end
        
        % --- retrieves the main class properties
        function getClassCodeGroups(obj)
            
            % determines the code lines of the main class blocks
            iBlk = find((obj.nGap == 4) & ~obj.isCom);
            
            % memory allocation
            nBlk = length(iBlk)/2;
            A = struct('Type',[],'sType',[],'Lines',[],'Props',[],...
                       'Fcn',[],'iFcn0',[],'iFcnF',[]);
            obj.cBlk = repmat(A,nBlk,1);
            
            % sets the class code group blocks
            for i = 1:nBlk
                % sets the code block lines
                xi = (i-1)*2 + (1:2);
                obj.cBlk(i).Lines = iBlk(xi);
                
                % determines the class code block type
                cHdr0 = strtrim(obj.fData{iBlk(xi(1))});
                cHdr = obj.splitBlockHeader(cHdr0);
                obj.cBlk(i).Type = cHdr{1};
                obj.cBlk(i).sType = lower(cHdr{2});
                
                % splits the code block based on type
                switch obj.cBlk(i).Type
                    case 'properties'
                        % case is a properties code block
                        obj.splitPropsBlock(i);
                        
                    case 'methods'
                        % case is a methods code block
                        obj.splitMethodsBlock(i);
                end
            end
            
        end                
        
        % --- splits up a properties code block
        function splitPropsBlock(obj,iBlk)
            
            % determines the property code lines
            xiL = obj.getCodeBlockIndices(iBlk);
            isP = ~(obj.isCom(xiL) | obj.isEmp(xiL));            
            
            % retrieves the properties from the code block
            obj.cBlk(iBlk).Props = ...
                        cellfun(@strtrim,obj.fCode0(xiL(isP)),'un',0);
            
        end
        
        % --- splits up a methods code block
        function splitMethodsBlock(obj,iBlk)
            
            % initialisations
            pat0 = '\=(.*?)\(';
            patN = 'n (.*?)\(';
            
            % determines the function code lines
            xiL = obj.getCodeBlockIndices(iBlk);
            obj.cBlk(iBlk).iFcn0 = xiL(obj.isFcn(xiL));
            obj.cBlk(iBlk).iFcnF = zeros(size(obj.cBlk(iBlk).iFcn0));            
            fBlk0 = obj.fData(obj.cBlk(iBlk).iFcn0);  
            
            % determines the white-space gap count
            iFcn0 = [obj.cBlk(iBlk).iFcn0;obj.nLine];
            nGap0 = obj.nGap(iFcn0);
            
            % determines the end of the code block
            for i = 1:length(obj.cBlk(iBlk).iFcn0)
                xiL = iFcn0(i):obj.nLine;
                j0 = find(obj.isEnd(xiL) & ...
                                (obj.nGap(xiL) == nGap0(i)),1,'first');
                obj.cBlk(iBlk).iFcnF(i) = xiL(j0);
            end
            
            % joins up any multi-line function lines
            hasML = strContains(fBlk0,'...');
            for i = find(hasML(:)')
                % determines which 
                ii = obj.cBlk(iBlk).iFcn0(i) + [0,1];
                while strContains(obj.fData{ii(2)},'...')
                    ii(2) = ii(2) + 1;
                end
                
                % resets the full function line string
                fBlk0{i} = strjoin(cellfun(@(x)(strrep...
                        (strtrim(x),'...','')),obj.fData(ii),'un',0));
            end
            
            % determines the functions with equalities
            hasEq = strContains(fBlk0,'=');            
            
            % retrieves the function names from the code block
            FcnB = cell(size(fBlk0));
            FcnB(hasEq) = cellfun(@(x)(regexp...
                        (x,pat0,'match','once')),fBlk0(hasEq),'un',0);
            FcnB(~hasEq) = cellfun(@(x)(regexp...
                        (x,patN,'match','once')),fBlk0(~hasEq),'un',0);
                                
            % sets the final class code block function names        
            obj.cBlk(iBlk).Fcn = cellfun(@(x)...
                        (strtrim(x(2:end-1))),FcnB,'un',0);            
                                            
        end        
        
        % --- determines all the function dependencies
        function detFunctionDep(obj)
            
            % sets all the function names/code line indices
            obj.Fcn = cell2cell(field2cell(obj.cBlk,'Fcn'));            
            iFcn = [cell2cell(field2cell(obj.cBlk,'iFcn0')),...
                    cell2cell(field2cell(obj.cBlk,'iFcnF'))];
            
            % determines the indices of the function dependencies
            obj.iDep = cell(size(obj.Fcn));
            obj.isFcnR = setGroup(1,size(obj.Fcn));
            for i = find(~strcmp(obj.Fcn(:)',obj.clName))
                % determines the code lines which contain the function 
                try
                iL = find(strContains(obj.fData,obj.Fcn{i}));
                catch
                    a = 1;
                end
                
                % determines the use of the function within the class code
                % (not within its own function)
                isOK = prod(sign(iL - iFcn(i,:)),2) > 0;
                if any(isOK)
                    for j = find(isOK(:)')
                        % determines the dependent function
                        if obj.nGap(iFcn(i,1)) == 8
                            iFcnP = find(iL(j) > iFcn(:,1),1,'last');
                        else
                            iFcnP = find(obj.nGap(1:(i-1)) == ...
                                    (obj.nGap(iFcn(i,1)) - 4),1,'last');
                        end

                        % appends the dependency index
                        if iFcnP ~= i
                            obj.iDep{iFcnP} = [obj.iDep{iFcnP};i];
                        end
                    end
                else
                    obj.isFcnR(i) = true;
                end
            end
            
            % reduces down the dependency indices
            obj.iDep = cellfun(@unique,obj.iDep,'un',0);
            
        end     

        % ---------------------------- %
        % --- DIAGNOSTIC FUNCTIONS --- %
        % ---------------------------- %        
        
        % --- shows the dependency tree
        function showDepTree(obj)
            
            % clears the screen
            clc
            
            % outputs the dependency tree
            for i = find(obj.isFcnR(:)')
                % prints the parent function
                fprintf(' %s %s\n',char(8594),obj.Fcn{i});
                
                % prints the children function
                obj.printChildrenFunc(obj.iDep{i},1);                
                
                % adds a gap for the next parent function
                fprintf('\n');
            end
            
        end
        
        % --- prints the children function
        function printChildrenFunc(obj,iDepP,iLvl)
            
            % initialisations
            sGap = repmat(' ',1,2*iLvl);
            
            % if there are no dependencies then exit
            for i = 1:length(iDepP)
                j = iDepP(i);
                fprintf('%s%s %s\n',sGap,char(8594),obj.Fcn{j});
                obj.printChildrenFunc(obj.iDep{j},iLvl+1);
            end
            
        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- returns the code block line indices
        function xiL = getCodeBlockIndices(obj,iBlk)
            
            % sets the class properties code block
            iL = obj.cBlk(iBlk).Lines;
            xiL = ((iL(1)+1):(iL(2)-1))';
            
        end                
        
        % --- determines the white-space gap at the start
        function nGap = detGapSize(obj,cStr)
            
            % converts the string to ascii values
            nGap = 0;
            if isempty(cStr); return; end
            
            % determines if there is a space or tab at the start
            icStr = double(cStr);
            if any(icStr(1) == [obj.Tab,obj.Space])
                isWS = (icStr == obj.Tab) | (icStr == obj.Space);
                iGrp = getGroupIndex(isWS);
                nGap = sum(icStr(iGrp{1}) == obj.Space) + ...
                       4*sum(icStr(iGrp{1}) == obj.Tab);
            else
                nGap = 0;
            end
                
        end        
        
    end
    
    % static class methods
    methods (Static)        
        
        % --- splits up the class group block string
        function cHdr = splitBlockHeader(cHdr0)
            
            % splits the string into its components
            cHdr = strsplit(cHdr0);
            
            % removes the parenthesis around the 2nd term (if it exists)
            if length(cHdr) > 1
                ii = strContains(cHdr,')');
                cHdrT = strrep(strrep(cHdr{ii},')',''),'(','');
                cHdr = {cHdr{1},cHdrT};
            else
                cHdr = [cHdr,{[]}];
            end
        end
        
    end    
        
end