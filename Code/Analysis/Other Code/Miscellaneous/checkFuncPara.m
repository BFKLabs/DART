% --- checks that the function parameters are correct
function ok = checkFuncPara(Type,cP,varargin)

% initialisations
[ok,eStr] = deal(true,[]);

% sets the input arguments
for i = 1:length(varargin)
    eval(sprintf('%s = varargin{i};',inputname(i+2)))
end

% performs the check based on the Type string
for i = 1:length(Type)
    switch Type{i}
        case ('AnalysisTimeCheck')             
            % checks the analysis timing parameters
            
            % checks if the "useAll" field is contained in the parameters
            if isfield(cP,'useAll')
                % if so, check the value of this field
                ifStr = '~cP.useAll';
            else
                % otherwise, always check 
                ifStr = '1';
            end
                
            % sets the input arguments   
            if eval(ifStr)
                if all(Tf < cP.T0)
                    % all finish times are greater than the specified start time.
                    % exit the function with an error
                    eStr = sprintf(['Error! Analysis start time exceeds all experiment finish times.\n',...
                                    'To use this function, the "Start Time" must less that "%i" mins.'],floor(max(Tf)));
                    eTitle = 'Input Parameter Error';
                elseif any(Tf < (cP.T0 + cP.Tdur))
                    % some experiments finish past the analysis time. prompt the
                    % user if they still want to continue
                    qStr = sprintf(['Warning! "Start Time"/"Analysis Duration" sum exceeds ',...
                                    'some experiment finish times. The sum of these two values ',...
                                    'must be less than "%i" mins.\n\nDo you still wish to continue?'],...
                                    floor(min(Tf)));
                    uChoice = questdlg(qStr,'Continue Analysis?','Yes','No','Yes');

                    % returns an empty array and exits the function
                    if (~strcmp(uChoice,'Yes'))
                        ok = false; return
                    end
                end
            end
            
        case ('HasSubRegionStruct') % checks the existence of the sub-region data struct            
            % sets the input arguments
            if exist('snTot','var')
                hasMov = arrayfun(@(x)(isfield(x,'iMov')),snTot);
            else
                hasMov = isfield(snTotL,'iMov');
            end
            
            if any(~hasMov)
                % if the sub-region data struct is missing, then output error
                eStr = sprintf(['Error! This is an old solution file version!\n',...
                                'Recombine the solution file and retry the analysis.']);
                eTitle = 'Old Solution File Format';
            end            
            
        case ('PeriodicityExptDur')
            ii = Texp(:,1) < TminD;
            if any(ii)
                % sets up the warning string
                wStr = sprintf(['The following experiments are too short ',...
                                'for analysing periodicity:\n']);
                for j = find(ii)'
                    % sets the details for the anomalous experiments
                    wStr = sprintf(['%s\n  => Experiment #%i (Duration = %i ',...
                                    'Days, %i Hours %i Mins)'],wStr,j,Texp(1,1),...
                                    Texp(j,2),Texp(j,3));
                end
                
                % sets the minimum duration string
                wStr = sprintf('%s\n\nNote - Minimum experiment duration = %i Days',wStr,TminD);
                
                % outputs a warning only
                waitfor(warndlg(wStr,'Periodicity Calculations','Modal'))
            end
            
        case ('ExtnDataField')
            % check to see if specific data field strings have been set
            
            % determines if the external data fields have been set
            hasExD = arrayfun(@(x)...
                            (isfield(x,'exD') && ~isempty(x.exD)),snTot);
            
            % case is determining if an external data field has been set
            if any(~hasExD)
                % if the sub-region data struct is missing, then output error
                eStr = sprintf(['Error! The external data fields for the selected ',...
                                'experiment(s) is empty.\nEnsure the external data ',...
                                'fields are set before using this function.']);
                eTitle = 'External Data Missing';
            else
                % retrieves the data fields from external data structs
                exD = field2cell(snTot,'exD');
                pStrEx = cellfun(@(x)(cellfun...
                                    (@(y)(y.pStr),x,'un',0)),exD,'un',0);
                                
                for j = 1:length(exVar)
                    hasExD = all(cellfun(@(x)...
                                    (any(strcmp(x,exVar(j).Name))),pStrEx));
                    if ~all(hasExD)
                        % if the external data field is missing, then 
                        % set the output error string
                        eStr = sprintf(['Error! The selected experiment(s) is ',...
                                        'missing the external data field:\n\n',...
                                        '\t%s"%s"\n\n',...
                                        'Ensure this external data field ',...
                                        'is present before using this function.'],...
                                        char(8594),exVar(j).Name);
                        eTitle = 'Missing External Data Field';
                        
                        % exits the loop
                        break
                    end
                end
            end
            
    end
    
    % if there is an error then exit the loop
    if ~isempty(eStr); break; end
end
    
% outputs the error (if one is set)
if ~isempty(eStr)
    waitfor(errordlg(eStr,eTitle,'modal'))
    ok = false;
end
    