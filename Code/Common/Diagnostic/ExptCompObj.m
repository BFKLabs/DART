classdef ExptCompObj < handle
    % class properties
    properties
        % data fields
        iSel
        crData
        cmpData
        expData        
        
        % parameters
        pDur = 50;
        nExp
    end
    
    % class methods
    methods 
        % --- class contructor methods
        function obj = ExptCompObj(sInfo)            
            
            % sets the derived value fields
            obj.nExp = length(sInfo);           
            
            % sets up the experiment criteria and compatibility flags
            obj.setupExptCriteriaData(sInfo);
            obj.calcCompatibilityFlags();
            obj.setupExptInfo(sInfo);
            
        end
        
        % --- updates the experiment data and related compatibility fields
        function updateExptCompData(obj,sInfoNw)
            
            % updates the data related fields
            obj.nExp = length(sInfoNw);
            
            % updates the experiment criteria and compatibility flags
            obj.setupExptCriteriaData(sInfoNw);
            obj.calcCompatibilityFlags();
            obj.setupExptInfo(sInfoNw)
            
        end
        
        % --- sets up the experiment criteria data
        function setupExptCriteriaData(obj,sInfo)

            % memory allocation            
            crData0 = cell(obj.nExp,5);
            setupStr = {'1D','2D'};

            % loops through all experiments 
            for i = 1:obj.nExp    
                % sets the region string (based on type/detection method)
                if isempty(sInfo{i}.snTot.iMov.autoP)
                    % case is there is no automatic detection
                    regStr = 'None';
                else
                    % case is there is automatic detection
                    regStr = sInfo{i}.snTot.iMov.autoP.Type;
                end    

                % determine if stimuli was delivered for the experiment
                if sInfo{i}.hasStim
                    % case is there is a stimuli device used
                    devStr = unique(fieldnames(sInfo{i}.snTot.stimP));
                    stimStr = strjoin(devStr,'/');
                else
                    % case is there was stimuli delivered
                    stimStr = 'No Stimuli';
                end

                % sets the experiment criteria data for the current expt                
                crData0{i,1} = setupStr{1+sInfo{i}.is2D};    
                crData0{i,2} = regStr;    
                crData0{i,3} = stimStr; 
                crData0{i,4} = sInfo{i}.snTot.sTrainEx;
                crData0{i,5} = sInfo{i}.tDur;
            end
            
            % stores the criteria data into the class object
            obj.crData = crData0;
            obj.iSel = true(size(obj.crData,2),1);
            
        end
        
        % --- calculates the compatibility flags
        function calcCompatibilityFlags(obj,indCr)

            % other initialisations and memory allocation
            iColStim = 4;
            tExp = cell2mat(obj.crData(:,end));
            nCr = size(obj.crData,2);

            % sets the criteria update index array
            if ~exist('indCr','var')
                [indCr,cmpData0] = deal(1:nCr,false(obj.nExp,nCr,obj.nExp)); 
            else
                cmpData0 = obj.cmpData;
            end
            
            if any(indCr == iColStim)
                % determines the experiments with stimuli
                hasStim = ~cellfun(@isempty,obj.crData(:,iColStim));
                [sTrain,sParaEx] = deal(cell(length(hasStim),1));
                
                % for the expts with stimuli, retrieve the train/expt data
                crD = obj.crData(hasStim,iColStim);                
                sTrain(hasStim) = cellfun(@(x)(x.sTrain),crD,'un',0);
                sParaEx(hasStim) = cellfun(@(x)(x.sParaEx),crD,'un',0);
            end

            % loops through each criteria index updating the compatibility
            % flags
            for iCr = indCr
                for iExp = 1:obj.nExp
                    switch iCr
                        case iColStim
                            % case is the stimuli structs
                            isEq1 = cellfun(@(x)(isequaln(x,...
                                        sTrain{iExp})),sTrain);
                            isEq2 = cellfun(@(x)(isequaln(x,...
                                        sParaEx{iExp})),sParaEx);
                            isEq = isEq1 & isEq2;
                                    
                        case 5
                            % case is the experiment duration
                            ptExp = min([tExp./tExp(iExp),...
                                         tExp(iExp)./tExp],[],2);
                            isEq = 100*(1-ptExp) <= obj.pDur;
                            
                        otherwise
                            % case is the string values
                            isEq = strcmp(obj.crData(:,iCr),...
                                          obj.crData{iExp,iCr});
                                                                        
                    end

                    % sets the final compatibility values
                    cmpData0(:,iCr,iExp) = isEq;
                end
            end
            
            % updates the comparison data field
            obj.cmpData = cmpData0;
            
        end
        
        % --- sets up the experiment info fields
        function setupExptInfo(obj,sInfo)
            
            % initialistions and memory allocation
            nHdr = 6;
            eStr = {'No','Yes'};
            expData0 = repmat({''},[obj.nExp,nHdr-1,obj.nExp]);            

            % loops through each experiment setting the expt 
            % data/comparison values
            for iExp = 1:obj.nExp
                for iHdr = 1:nHdr
                    % sets the data depending on the experimental header
                    switch iHdr
                        case 1
                            % case is the experiment number
                            expFile = sInfo{iExp}.expFile;
                            expData0(iExp,iHdr,:) = {expFile};

                        case {2,3,4}
                            % case is the setup type
                            expData0(iExp,iHdr,:) = obj.crData(iExp,iHdr-1);

                        case 5
                            % case is the stimuli protocol matches 
                            % (expt specific)
                            for i = 1:obj.nExp
                                expData0{i,iHdr,iExp} = eStr{1+isequaln(...
                                        obj.crData{iExp,iHdr-1},...
                                        obj.crData{i,iHdr-1})};
                            end
                            
                        case 6
                            % case is the expt duration
                            durStr = obj.getDurationString(sInfo{iExp});
                            expData0(iExp,iHdr,:) = {durStr};                            
                    end    
                end
                
                % sets the experiment data field
                obj.expData = expData0;
            end            
            
        end
        
        % --- determines the compatibility information 
        function [indG,isComp] = detCompatibleExpts(obj)
            
            % retrieves the comparison data
            [cData,cData0] = deal(obj.cmpData);

            % memory allocation
            [indG,isComp] = deal(cell(obj.nExp,1));

            % determines which experiments are compatible with the others 
            % (given the selected grouping criteria)
            for iExp = 1:obj.nExp
                % determines the individual criteria flags
                isComp{iExp} = all(cData0(:,obj.iSel,iExp),2);
                
                % determines the experiments which meet all critera
                if isempty(obj.iSel)
                    indG{iExp} = 1:obj.nExp;
                else
                    indG{iExp} = find(all(cData(:,obj.iSel,iExp),2));
                end
                
                % if a match was made, then remove them from other searches               
                if ~isempty(indG{iExp})
                    % NOTE - REMOVE ME (could stop other groups being
                    % formed by removing the flag values)
                    cData(indG{iExp},:,:) = false;
                end
            end

            % removes cells which have no grouping indices
            indG = indG(~cellfun(@isempty,indG));
            
            % sorts the groups in descending size order
            [~,iS] = sort(cellfun(@length,indG),'descend');
            indG = indG(iS);
        
        end
        
        % ------------------------------------ %
        % ---- CLASS OBJECT I/O FUNCTIONS ---- %
        % ------------------------------------ %        
        
        % --- gets the class field value, pStr
        function pVal = getParaValue(obj,pStr)
            
            pVal = eval(sprintf('obj.%s;',pStr));
            
        end
        
        % --- sets the class field, pStr, with the value pVal
        function setParaValue(obj,pStr,pVal)
            
            eval(sprintf('obj.%s = pVal;',pStr));
            
        end
        
        % -- updates the criteria checkbox marker value
        function setCritCheck(obj,iChk,chkVal)
            
            obj.iSel(iChk) = chkVal;
            
        end
        
    end
    
    methods (Static)
        
        % --- retrieves the expt duration string
        function durStr = getDurationString(sInfo)
            
            % calculates the duration of the experiment
            iPara = sInfo.iPara;
            tExptS = sec2vec(etime(iPara.Tf,iPara.Ts));
            
            % removes the day field (if less than one day)
            if (tExptS(4) == 0); tExptS = tExptS(2:end); end
            
            % sets the duration strings for each time field
            durStr0 = cell(1,length(tExptS));
            for i = 1:length(tExptS)
                if tExptS(i) < 10
                    durStr0{i} = sprintf('0%i',tExptS(i));
                else
                    durStr0{i} = num2str(tExptS(i));
                end
            end
            
            % sets the final string
            durStr = strjoin(durStr0,':');
            
        end        
        
    end
    
end
