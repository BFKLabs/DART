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
        isSaving
        nExp
        
    end
    
    % class methods
    methods 
        % --- class contructor methods
        function obj = ExptCompObj(sInfo,isSaving)
            
            % sets the derived value fields
            obj.nExp = length(sInfo);   
            obj.isSaving = isSaving;
            
            % sets up the experiment criteria and compatibility flags
            obj.setupExptCriteriaData(sInfo);            
            obj.calcCompatibilityFlags();
            obj.setupExptInfo(sInfo);            
            
%             setupExptCriteriaData
            
        end
        
        % --- updates the experiment data and related compatibility fields
        function updateExptCompData(obj,sInfoNw)
            
            % updates the data related fields
            obj.nExp = length(sInfoNw);
            
            % updates the experiment criteria and compatibility flags
            obj.setupExptCriteriaData(sInfoNw);
%             obj.getInitCritCheck();
            obj.calcCompatibilityFlags();
            obj.setupExptInfo(sInfoNw)
            
        end
        
        % --- determines the initial criteria check
        function getInitCritCheck(obj)
            
            % fills in any empty field in the array
            crDT0 = obj.crData;
            if isempty(crDT0)
                return
            else
                crDT0(cellfun(@isempty,crDT0)) = {''};
            end
            
            % determines 
            [crDT,obj.iSel(:)] = deal(num2cell(crDT0,1),true);
            for i = 1:length(crDT)
                if i == length(crDT)
                    % case is a duration field
                    tDur = cell2mat(crDT{i});
                    obj.iSel(i) = 100*min(tDur)/max(tDur) > obj.pDur;
                elseif i > 1
                    % case is a non-duration field
                    if isstruct(crDT{i}{1})
                        % case is a struct field
                        if isfield(crDT{i}{1},'sTrain')
                            % case is the stimuli train fields
                            sT = cell(size(crDT{i}));
                            ii = ~cellfun(@isempty,sT);                            
                            
                            if (length(sT) > 1) && all(ii)
                                sT = cellfun(@(x)(x.sTrain),crDT{i},'un',0);
                                obj.iSel(i) = all(cellfun(@(x)...
                                        (isequal(x,sT{1})),sT(2:end)));
                            end
                        end                        
                    else
                        % case is a string field
                        obj.iSel(i) = length(unique(crDT{i})) == 1;
                    end
                end
            end
            
        end
        
        % --- sets up the experiment criteria data
        function setupExptCriteriaData(obj,sInfo)

            % memory allocation            
            crData0 = cell(obj.nExp,5);
            setupStr = {'1D','2D','MT'};            

            % loops through all experiments 
            for i = 1:obj.nExp    
                % sets the region string (based on type/detection method)
                isMT = detMltTrkStatus(sInfo{i}.snTot.iMov);
                regStr = getDetectionType(sInfo{i}.snTot.iMov);

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
                crData0{i,1} = setupStr{1+sInfo{i}.is2D+isMT};    
                crData0{i,2} = regStr;    
                crData0{i,3} = stimStr; 
                crData0{i,4} = sInfo{i}.snTot.sTrainEx;
                crData0{i,5} = sInfo{i}.tDur;
            end
            
            % stores the criteria data into the class object
            obj.crData = crData0;
            obj.iSel = true(size(obj.crData,2),1);
            
            % determines if all the 
            if ~isempty(sInfo)
                fName = cellfun(@(x)(getFileName(x.sFile)),sInfo,'un',0);
                fExtn = cellfun(@(x)(getFileExtn(x.sFile)),sInfo,'un',0);
                if obj.isSaving || (all(strcmp(fExtn,'.msol')) && ...
                                   (length(unique(fName)) == 1))
                    obj.getInitCritCheck();
                end
            end
            
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
            
            pVal = getStructField(obj,pStr);
            
        end
        
        % --- sets the class field, pStr, with the value pVal
        function setParaValue(obj,pStr,pVal)
            
            setStructField(obj,pStr,pVal);
            
        end
        
        % -- updates the criteria checkbox marker value
        function setCritCheck(obj,iChk,chkVal)
            
            obj.iSel(iChk) = chkVal;
            
            if iChk == length(obj.iSel)
                hFig = findall(0,'tag','figOpenSoln');
                hCheck = findall(hFig,'tag','editMaxDiff');
                setObjEnable(hCheck,chkVal)
            end
            
        end
        
    end
    
    methods (Static)
        
        % --- retrieves the expt duration string
        function durStr = getDurationString(sInfo)
            
            % calculates the duration of the experiment
            iPara = sInfo.iPara;
            tExptS = sec2vec(etime(iPara.Tf,iPara.Ts));
            
            % removes the day field (if less than one day)
            if (tExptS(1) == 0); tExptS = tExptS(2:end); end
            
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
