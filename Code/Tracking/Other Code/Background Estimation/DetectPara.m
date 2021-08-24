classdef DetectPara
    methods (Static)
        % --- sets the detection parameter data struct
        function bgP = getDetectionPara(iMov)

            if isfield(iMov,'bgP')
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
                                    sFld0 = rmfield(sFld0,fStrS{j});
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

                    % initialisations
                    bgP = struct();
                    fStr = {'algoType','pPhase','pSingle','pMulti'};

                    % sets all the sub-fields for the parameter struct
                    for i = 1:length(fStr)
                        eval(sprintf('bgP.%s = DetectPara.%s(''%s'');',...
                            fStr{i},'initDetectParaStruct',fStr{i}));
                    end

                case 'algoType' % case is the algorithm type

                    bgP = 'bgs-single';

                case 'pPhase' % case is the phase detection parameters

                    bgP = struct('histTol',0.125,'rsmeTol',0.04,...
                                 'nImgR',10,'nFrmMin',15);

                case 'pSingle' % case is single object detection parameters

                    bgP = struct('');

                case 'pMulti' % case is multi object detection parameters

                    bgP = struct();        
            end        
        end
    
    end
end