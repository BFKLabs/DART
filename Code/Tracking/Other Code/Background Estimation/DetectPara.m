classdef DetectPara
    
    methods (Static)
        % --- sets the detection parameter data struct
        function bgP = getDetectionPara(iMov)

            if isfield(iMov,'bgP') && ~isempty(iMov.bgP)
                % retrieves the background parameter field
                bgP = DetectPara.resetDetectParaStruct(iMov.bgP);
            else
                % otherwise, initialise the detection parameter struct
                bgP = DetectPara.initDetectParaStruct('All');
            end
        
        end

        % --- resets the detection parameter struct
        function bgP = resetDetectParaStruct(bgP)

            % initialisations
            fStr = fieldnames(bgP);

            % retrieves 
            bgP0 = DetectPara.initDetectParaStruct('All');
            fStr0 = fieldnames(bgP0);

            % removes any extraneous fields
            iRmv = cellfun(@(x)(~any(strcmp(fStr0,x))),fStr);
            for i = find(iRmv(:))'
                bgP = rmfield(bgP,fStr{i});
            end

            % determines if current parameter configuration is correct
            resaveFile = any(iRmv);
            for i = 1:length(fStr0)
                % sets the field update evaludation string
                fcnStr = sprintf(...
                    'DetectPara.initDetectParaStruct(''%s'')',fStr0{i});

                % determines if field exists within the parameter struct
                if ~any(strcmp(fStr,fStr0{i}))
                    % if not, then add the field to the struct
                    resaveFile = true;
                    bgP = setFieldValue(bgP,fStr0(i),fcnStr);
                else
                    % otherwise, determine if default field is struct field
                    sFld0 = getFieldValue(bgP0,fStr0{i});                       
                    if isstruct(sFld0)
                        % if so, determine if new sub-field is struct field
                        sFld = getFieldValue(bgP,fStr0{i});            
                        if ~isstruct(sFld)
                            % if not, then reset the sub-field in the struct
                            resaveFile = true;
                            bgP = setFieldValue(bgP,fStr0{i},fcnStr);            
                        else
                            % otherwise, determine if struct fields match
                            fStrS = fieldnames(sFld);
                            fStrS0 = fieldnames(sFld0);                     
                            if ~isequal(fStrS,fStrS0)
                                % if not, then add/remove the mis-matches
                                resaveFile = true;

                                % adds in any missing fields
                                iAdd = cellfun(@(x)(...
                                            ~any(strcmp(fStrS,x))),fStrS0);
                                for j = find(iAdd(:))'
                                    nwVal = getFieldValue(...
                                            sFld0,fStrS0{j});
                                    sFld0 = setFieldValue(...
                                            sFld0,fStrS0(j),nwVal);
                                end

                                % removes any extraneous fields
                                iRmv = cellfun(@(x)(...
                                            ~any(strcmp(fStrS0,x))),fStrS);
                                for j = find(iRmv(:))'
                                    if isfield(sFld0,fStrS{j})
                                        sFld0 = rmfield(sFld0,fStrS{j});
                                    end
                                end

                                % resets the sub-field of the data struct
                                bgP = setFieldValue(bgP,fStr0{i},sFld0);
                            end
                        end
                    end
                end
            end

            % updates the parameter file (if required)
            if resaveFile
                % retrieves the parameter file name
                pFile = getParaFileName('ProgPara.mat');  
                
                % updates the file with the new parameters
                A = load(pFile);
                A.bgP = bgP;
                save(pFile,'-struct','A')
            end
        
        end

        % --- initialises the background parameter struct
        function bgP = initDetectParaStruct(fType)                        

            switch fType
                case 'All' % case is initialising all parameter fields

                    %
                    A = load(getParaFileName('ProgPara.mat'));
                    
                    % initialisations
                    bgP = struct();
                    bgP0 = A.bgP;
                    fStr = {'algoType','pPhase','pInit',...
                            'pTrack','pSingle','pMulti'};

                    % sets all the sub-fields for the parameter struct
                    for i = 1:length(fStr)
                        % retrieves the sub-struct values
                        bgPnw = DetectPara.initDetectParaStruct(fStr{i});
                        switch fStr{i}
                            case 'algoType'
                                % case is the algorithm string
                                bgP.(fStr{i}) = bgPnw;
                                
                            otherwise
                                % case is the other sub-struct
                                fldNw = fieldnames(bgPnw);
                                if isfield(bgP0,fStr{i})
                                    fldNw0 = fieldnames(bgP0.(fStr{i}));
                                else
                                    fldNw0 = '';
                                end
                                
                                % if there is a mismatch between parameter
                                % structs, then use the original (otherwise
                                % use the saved values).
                                if isequal(fldNw,fldNw0)
                                    bgP.(fStr{i}) = bgP0.(fStr{i});
                                else
                                    bgP.(fStr{i}) = bgPnw;
                                end
                        end
                    end

                case 'algoType' 
                    % case is the algorithm type
                    bgP = 'bgs-single';

                case 'pPhase' 
                    % case is the phase detection parameters
                    bgP = struct('nImgR',10,'Dtol',2,'pTolLo',35,...
                                 'pTolHi',240,'nPhMax',7);

                case 'pInit' 
                    % case is initial detection parameters
                    bgP = struct('nFrmMin',3,'pYRngTol',3.5,'pIRTol',0.35);

                case 'pTrack' 
                    % case is full tracking parameters
                    bgP = struct('rPmxTol',0.8,'pTolPh',5,'pWQ',1,...
                                 'distChk',1);
                    
                case 'pSingle' 
                    % case is full tracking parameters
                    bgP = struct('hSz',3,'useFilt',true);
                    
                case 'pMulti'
                    % case is multi-tracking parameters
                    bgP = struct('isFixed',0,'hSz',3,'useFilt',true);
                    
            end        
        end
    
    end
end
