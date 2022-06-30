% --- reduces the stimuli timing data struct (combines devices and/or
%     channels within similar/exact timing protocols)
function stimP = reduceStimTimingStruct(stimP)

% initialisations
dtMaxTol = 0.1;
dTypeB = {'Motor','Opto'};
dType0 = fieldnames(stimP);

% for each device, determines if the channels can be reduced (i.e., remove
% any stimuli event repetition)
for i = 1:length(dTypeB)
    % determines if there are any devices matching the current type
    isDev = find(strContains(dType0,dTypeB{i}));
    if ~isempty(isDev)    
        % if so, then determine if the timing/device types can be reduced
        isChange = false;
        dTypeD = dType0(isDev);
        chName = cell(length(dTypeD),1);
        [Ts,Tf,iStim] = deal(cell(1,length(isDev)));
        
        % -------------------------------- %
        % --- DEVICE CHANNEL REDUCTION --- %
        % -------------------------------- %
    
        % reduces down the channel information for each device
        for j = 1:length(dTypeD)
            % retrieves the struct field (for the current device)
            pDev = getStructField(stimP,dTypeD{j});
            chName{j} = fieldnames(pDev);
            
            % sets the stimuli times/indices for each channel
            nCh = length(chName{j});
            [Ts{j},Tf{j},iStim{j}] = deal(cell(1,nCh));
            for k = 1:nCh
                pCh = getStructField(pDev,chName{j}{k});
                [Ts{j}{k},Tf{j}{k},iStim{j}{k}] = ...
                                        deal(pCh.Ts,pCh.Tf,pCh.iStim);
            end
            
            % combines the start times/indices into single arrays
            Ts{j} = combineNumericCells(Ts{j});
            Tf{j} = combineNumericCells(Tf{j});
            iStim{j} = combineNumericCells(iStim{j});
            
            % determines if the channel properties are similar across all
            % channels. if so, combine these similar channels            
            if nCh > 1
                % search the channels to determine if any are similar
                indM = NaN(1,nCh);
                while any(isnan(indM))
                    % determines the next channel to search
                    i0 = find(isnan(indM),1,'first');
                    indM(i0) = i0;
                    
                    % compares the information from the other channels
                    % to the search candidate
                    for k = (i0+1):nCh
                        if isequal(iStim{j}(:,i0),iStim{j}(:,k))
                            % if the stimuli protocols and timing are
                            % similar, then flag the channel for combining
                            dtMaxS = max(abs(Ts{j}(:,i0)-Ts{j}(:,k)));
                            dtMaxF = max(abs(Tf{j}(:,i0)-Tf{j}(:,k)));                            
                            if (dtMaxS < dtMaxTol) && (dtMaxF < dtMaxTol)
                                indM(k) = i0;
                            end
                        end
                    end
                end
                
                % reduces down the arrays to the unique channels
                [~,iB,~] = unique(indM);
                if length(iB) < length(indM)
                    isChange = true;
                    chName{j} = chName{j}(iB);
                    [Ts{j},Tf{j},iStim{j}] = ...
                            deal(Ts{j}(:,iB),Tf{j}(:,iB),iStim{j}(:,iB));
                end
            end
            
            % if there is only one unique channel, then reset the name
            if length(chName{j}) == 1 && strcmp(dTypeD{j},'Motor')
                [chName{j},isChange] = deal({'Ch'},true);
            end
        end
        
        % ------------------------ %
        % --- DEVICE REDUCTION --- %
        % ------------------------ %  
        
        % initialisations
        nDev = length(dTypeD);
        
        % compares the devices to determine if they have similar events
        if nDev > 1
            % search the devices to determine if any are similar
            indM = NaN(1,nDev);               
            while any(isnan(indM))
                % determines the next channel to search
                i0 = find(isnan(indM),1,'first');
                indM(i0) = i0;     
                
                % compares the information from the other channels
                % to the search candidate
                for k = (i0+1):nDev
                    if isequal(iStim{i0},iStim{k})
                        dT = max(abs(Ts{i0}-Ts{k}),abs(Tf{i0}-Tf{k}));
                        if max(dT) < dtMaxTol
                            indM(k) = i0;
                        end
                    end
                end
                
                % reduces down the arrays to the unique channels
                [~,iB,~] = unique(indM);
                if length(iB) < length(indM)
                    isChange = true;
                    [chName,dTypeD] = deal(chName(iB),dTypeD(iB));
                    [Ts,Tf,iStim] = deal(Ts(iB),Tf(iB),iStim(iB));
                end                
            end
        end
        
        % if there is only one device, then reduce the 
        if length(dTypeD) == 1
            [dTypeD,isChange] = deal(dTypeB(i),true);
        end
        
        % -------------------------- %
        % --- DATA STRUCT UPDATE --- %
        % -------------------------- %
        
        % resets the data struct (if necessary)
        if isChange
            % removes the original device fields
            for j = isDev(:)'
                stimP = rmfield(stimP,dType0{j});
            end
            
            % re-adds the device data structs back into the main struct    
            for j = 1:length(dTypeD)
                % sets the channel information for the current device
                stimPNw = struct();
                for k = 1:length(chName{j})
                    ii = ~isnan(Ts{j}(:,k));
                    p = struct('Ts',Ts{j}(ii,k),'Tf',Tf{j}(ii,k),...
                               'iStim',iStim{j}(ii,k));
                    stimPNw = setStructField(stimPNw,chName{j}{k},p);
                end
                
                % adds the new struct back into the main struct
                stimP = setStructField(stimP,dTypeD{j},stimPNw);
            end
        end
        
    end
end
